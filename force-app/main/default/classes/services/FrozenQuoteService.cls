/**
 * Enforces the "frozen quote" business rule for AP2-US-002.
 * When a Quote's Status is 'In Review', the deal is considered frozen and
 * changes to Quote Line Items or the Primary Contact are blocked at the data layer.
 * Opportunity owner's manager and higher-ups in the role hierarchy are exempt.
 */
public with sharing class FrozenQuoteService {

    @TestVisible
    private static final String FROZEN_ERROR_MSG = 'This quote is currently In Review. Changes are not permitted.';
    private static final String FROZEN_STATUS = 'In Review';

    // Per-transaction caches to avoid redundant queries
    @TestVisible
    private static Map<Id, Id> cachedRoleParentMap;
    @TestVisible
    private static Map<Id, Boolean> exemptionCache = new Map<Id, Boolean>();

    private QuoteSelector       quoteSelector;
    private OpportunitySelector oppSelector;
    private UserRoleSelector    roleSelector;

    public FrozenQuoteService() {
        this.quoteSelector = new QuoteSelector();
        this.oppSelector   = new OpportunitySelector();
        this.roleSelector  = new UserRoleSelector();
    }

    public FrozenQuoteService(
        QuoteSelector quoteSelector,
        OpportunitySelector oppSelector,
        UserRoleSelector roleSelector
    ) {
        this.quoteSelector = quoteSelector;
        this.oppSelector   = oppSelector;
        this.roleSelector  = roleSelector;
    }

    // ─── Public Entry Points ─────────────────────────────────────────────────

    /**
     * Blocks any DML on QuoteLineItem records when their parent Quote is frozen
     * and the current user is not exempt for that specific Quote's Opportunity owner.
     * Called from beforeInsert, beforeUpdate, and beforeDelete on QuoteLineItem.
     *
     * @param lines Trigger.new (insert/update) or Trigger.old (delete)
     */
    public void enforceFreezeOnQuoteLineItems(List<QuoteLineItem> lines) {
        if (lines == null || lines.isEmpty()) {
            return;
        }

        Set<Id> quoteIds = new Set<Id>();
        for (QuoteLineItem qli : lines) {
            quoteIds.add(qli.QuoteId);
        }

        Set<Id> frozenQuoteIds = getFrozenQuoteIds(quoteIds);
        if (frozenQuoteIds.isEmpty()) {
            return;
        }

        Map<Id, Boolean> exemptByQuoteId = exemptionByQuoteId(frozenQuoteIds);

        Boolean anyBlocked = false;
        for (QuoteLineItem qli : lines) {
            if (frozenQuoteIds.contains(qli.QuoteId) && exemptByQuoteId.get(qli.QuoteId) != true) {
                qli.addError(FROZEN_ERROR_MSG);
                anyBlocked = true;
            }
        }

        if (anyBlocked) {
            Logger.warn('FrozenQuoteService: blocked QuoteLineItem DML — quote is In Review');
        }
    }

    /**
     * Blocks add/remove of Primary Contact (IsPrimary = true) on Opportunities
     * whose synced Quote is frozen, unless the current user is exempt for that
     * specific Opportunity's owner.
     * Called from beforeInsert and beforeDelete on OpportunityContactRole.
     *
     * @param roles Trigger.new (insert) or Trigger.old (delete)
     */
    public void enforceFreezeOnContactRoles(List<OpportunityContactRole> roles) {
        if (roles == null || roles.isEmpty()) {
            return;
        }

        // Only primary-contact changes are subject to the freeze
        List<OpportunityContactRole> primaryRoles = new List<OpportunityContactRole>();
        for (OpportunityContactRole ocr : roles) {
            if (ocr.IsPrimary) {
                primaryRoles.add(ocr);
            }
        }
        if (primaryRoles.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        for (OpportunityContactRole ocr : primaryRoles) {
            oppIds.add(ocr.OpportunityId);
        }

        Set<Id> frozenOppIds = getFrozenOppIds(oppIds);
        if (frozenOppIds.isEmpty()) {
            return;
        }

        Map<Id, Boolean> exemptByOppId = exemptionByOppId(frozenOppIds);

        Boolean anyBlocked = false;
        for (OpportunityContactRole ocr : primaryRoles) {
            if (frozenOppIds.contains(ocr.OpportunityId) && exemptByOppId.get(ocr.OpportunityId) != true) {
                ocr.addError(FROZEN_ERROR_MSG);
                anyBlocked = true;
            }
        }

        if (anyBlocked) {
            Logger.warn('FrozenQuoteService: blocked OpportunityContactRole DML — quote is In Review');
        }
    }

    // ─── Freeze Detection ────────────────────────────────────────────────────

    /**
     * Returns the subset of quoteIds whose Quote.Status is 'In Review'.
     */
    @TestVisible
    private Set<Id> getFrozenQuoteIds(Set<Id> quoteIds) {
        Set<Id> frozen = new Set<Id>();
        for (Quote q : this.quoteSelector.getQuotesByIds(quoteIds)) {
            if (FROZEN_STATUS.equals(q.Status)) {
                frozen.add(q.Id);
            }
        }
        return frozen;
    }

    /**
     * Returns the subset of oppIds whose synced Quote (IsSyncing = true) is frozen.
     */
    @TestVisible
    private Set<Id> getFrozenOppIds(Set<Id> oppIds) {
        Set<Id> frozenOppIds = new Set<Id>();
        for (Quote q : this.quoteSelector.getSyncingQuotesByOppIds(oppIds)) {
            if (FROZEN_STATUS.equals(q.Status)) {
                frozenOppIds.add(q.OpportunityId);
            }
        }
        return frozenOppIds;
    }

    // ─── Exemption Checks ────────────────────────────────────────────────────

    /**
     * Returns a map of quoteId -> isExempt for the current user, evaluated
     * per Quote against the owner of that Quote's Opportunity.
     */
    private Map<Id, Boolean> exemptionByQuoteId(Set<Id> frozenQuoteIds) {
        Map<Id, Id> quoteToOpp = new Map<Id, Id>();
        for (Quote q : this.quoteSelector.getQuotesByIds(frozenQuoteIds)) {
            if (q.OpportunityId != null) {
                quoteToOpp.put(q.Id, q.OpportunityId);
            }
        }

        Map<Id, Id> oppToOwner    = ownerByOppId(new Set<Id>(quoteToOpp.values()));
        Map<Id, Boolean> exemptByOwner = isCurrentUserExemptPerOwner(new Set<Id>(oppToOwner.values()));

        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (Id quoteId : frozenQuoteIds) {
            Id oppId   = quoteToOpp.get(quoteId);
            Id ownerId = oppId != null ? oppToOwner.get(oppId) : null;
            result.put(quoteId, ownerId != null && exemptByOwner.get(ownerId) == true);
        }
        return result;
    }

    /**
     * Returns a map of oppId -> isExempt for the current user, evaluated
     * per Opportunity against that Opportunity's owner.
     */
    private Map<Id, Boolean> exemptionByOppId(Set<Id> frozenOppIds) {
        Map<Id, Id> oppToOwner        = ownerByOppId(frozenOppIds);
        Map<Id, Boolean> exemptByOwner = isCurrentUserExemptPerOwner(new Set<Id>(oppToOwner.values()));

        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (Id oppId : frozenOppIds) {
            Id ownerId = oppToOwner.get(oppId);
            result.put(oppId, ownerId != null && exemptByOwner.get(ownerId) == true);
        }
        return result;
    }

    private Map<Id, Id> ownerByOppId(Set<Id> oppIds) {
        Map<Id, Id> oppToOwner = new Map<Id, Id>();
        for (Opportunity opp : this.oppSelector.getOpportunitiesByIds(oppIds)) {
            oppToOwner.put(opp.Id, opp.OwnerId);
        }
        return oppToOwner;
    }

    /**
     * Returns a map of ownerId -> isExempt for the current running user.
     * The current user is exempt from a given owner's record when their role
     * is strictly above that owner's role in the hierarchy (manager or higher).
     * A user with no role, or at the same level as the owner, is NOT exempt.
     * Uses per-transaction exemptionCache keyed by ownerId.
     */
    @TestVisible
    private Map<Id, Boolean> isCurrentUserExemptPerOwner(Set<Id> ownerIds) {
        if (ownerIds.isEmpty()) {
            return new Map<Id, Boolean>();
        }

        Set<Id> uncachedOwnerIds = new Set<Id>();
        for (Id ownerId : ownerIds) {
            if (!exemptionCache.containsKey(ownerId)) {
                uncachedOwnerIds.add(ownerId);
            }
        }

        if (!uncachedOwnerIds.isEmpty()) {
            Id currentUserId = UserInfo.getUserId();

            Set<Id> allUserIds = new Set<Id>(uncachedOwnerIds);
            allUserIds.add(currentUserId);

            Map<Id, Id> userToRole = new Map<Id, Id>();
            for (User u : this.roleSelector.getUsersByIds(allUserIds)) {
                userToRole.put(u.Id, u.UserRoleId);
            }

            Id currentUserRoleId = userToRole.get(currentUserId);
            Map<Id, Id> parentMap = buildRoleParentMap();

            for (Id ownerId : uncachedOwnerIds) {
                Boolean exempt;
                if (currentUserRoleId == null) {
                    exempt = false;
                } else {
                    exempt = isRoleAtOrAbove(currentUserRoleId, userToRole.get(ownerId), parentMap);
                }
                exemptionCache.put(ownerId, exempt);
            }
        }

        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (Id ownerId : ownerIds) {
            result.put(ownerId, exemptionCache.get(ownerId));
        }
        return result;
    }

    /**
     * Builds and caches a Map<roleId, parentRoleId> from all UserRole records.
     * Cached for the lifetime of the transaction to avoid repeated queries.
     */
    private Map<Id, Id> buildRoleParentMap() {
        if (cachedRoleParentMap != null) {
            return cachedRoleParentMap;
        }
        cachedRoleParentMap = new Map<Id, Id>();
        for (UserRole role : this.roleSelector.getAllRoles()) {
            cachedRoleParentMap.put(role.Id, role.ParentRoleId);
        }
        return cachedRoleParentMap;
    }

    /**
     * Traverses from ownerRoleId UP the hierarchy starting at the owner's PARENT.
     * Returns true if candidateRoleId is found anywhere above the owner's role.
     * Peers (same role) are NOT exempt — only "manager and higher" per the user story.
     *
     * @param candidateRoleId Role of the current running user
     * @param ownerRoleId     Role of the Opportunity owner
     * @param parentMap       Map<roleId, parentRoleId> for the full hierarchy
     */
    @TestVisible
    private Boolean isRoleAtOrAbove(Id candidateRoleId, Id ownerRoleId, Map<Id, Id> parentMap) {
        if (ownerRoleId == null) {
            return false;
        }

        // Start one level above the owner (the owner themselves are not exempt)
        Id cursor = parentMap.get(ownerRoleId);
        Set<Id> visited = new Set<Id>();

        while (cursor != null && !visited.contains(cursor)) {
            if (cursor == candidateRoleId) {
                return true;
            }
            visited.add(cursor);
            cursor = parentMap.get(cursor);
        }
        return false;
    }
}
