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
     * Blocks any DML on QuoteLineItem records when their parent Quote is frozen.
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

        if (isCurrentUserExemptForQuotes(frozenQuoteIds)) {
            Logger.info('FrozenQuoteService: current user is exempt from freeze enforcement (role hierarchy)');
            return;
        }

        for (QuoteLineItem qli : lines) {
            if (frozenQuoteIds.contains(qli.QuoteId)) {
                qli.addError(FROZEN_ERROR_MSG);
            }
        }

        Logger.warn('FrozenQuoteService: blocked QuoteLineItem DML — quote is In Review');
    }

    /**
     * Blocks add/remove of Primary Contact (IsPrimary = true) on Opportunities
     * whose synced Quote is frozen.
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

        if (isCurrentUserExemptForOpps(frozenOppIds)) {
            Logger.info('FrozenQuoteService: current user is exempt from freeze enforcement (role hierarchy)');
            return;
        }

        for (OpportunityContactRole ocr : primaryRoles) {
            if (frozenOppIds.contains(ocr.OpportunityId)) {
                ocr.addError(FROZEN_ERROR_MSG);
            }
        }

        Logger.warn('FrozenQuoteService: blocked OpportunityContactRole DML — quote is In Review');
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
     * Checks exemption by resolving the Opportunity owners for the given frozen Quote IDs.
     */
    private Boolean isCurrentUserExemptForQuotes(Set<Id> frozenQuoteIds) {
        Set<Id> oppIds = new Set<Id>();
        for (Quote q : this.quoteSelector.getQuotesByIds(frozenQuoteIds)) {
            if (q.OpportunityId != null) {
                oppIds.add(q.OpportunityId);
            }
        }
        return isCurrentUserExempt(getOwnerIdsFromOpps(oppIds));
    }

    /**
     * Checks exemption by resolving the Opportunity owners for the given frozen Opp IDs.
     */
    private Boolean isCurrentUserExemptForOpps(Set<Id> frozenOppIds) {
        return isCurrentUserExempt(getOwnerIdsFromOpps(frozenOppIds));
    }

    private Set<Id> getOwnerIdsFromOpps(Set<Id> oppIds) {
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : this.oppSelector.getOpportunitiesByIds(oppIds)) {
            ownerIds.add(opp.OwnerId);
        }
        return ownerIds;
    }

    /**
     * Returns true only if the current running user's role is strictly above
     * EVERY Opportunity owner's role in the hierarchy (manager or higher).
     * A user with no role, or at the same role level as an owner, is not exempt.
     * Uses per-transaction caches to minimise SOQL queries.
     */
    @TestVisible
    private Boolean isCurrentUserExempt(Set<Id> ownerIds) {
        if (ownerIds.isEmpty()) {
            return false;
        }

        Id currentUserId = UserInfo.getUserId();

        Set<Id> allUserIds = new Set<Id>(ownerIds);
        allUserIds.add(currentUserId);

        Map<Id, Id> userToRole = new Map<Id, Id>();
        for (User u : this.roleSelector.getUsersByIds(allUserIds)) {
            userToRole.put(u.Id, u.UserRoleId);
        }

        Id currentUserRoleId = userToRole.get(currentUserId);
        if (currentUserRoleId == null) {
            return false;
        }

        Map<Id, Id> parentMap = buildRoleParentMap();

        for (Id ownerId : ownerIds) {
            if (exemptionCache.containsKey(ownerId)) {
                if (!exemptionCache.get(ownerId)) {
                    return false;
                }
                continue;
            }

            Id ownerRoleId = userToRole.get(ownerId);
            Boolean exempt = isRoleAtOrAbove(currentUserRoleId, ownerRoleId, parentMap);
            exemptionCache.put(ownerId, exempt);

            if (!exempt) {
                return false;
            }
        }
        return true;
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
