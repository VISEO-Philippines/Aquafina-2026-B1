public inherited sharing class DealFreezeService {

    private static final String STATUS_IN_REVIEW = 'In Review';

    private static final String ERROR_FROZEN_QUOTE =
        'Quote Line Items cannot be changed while the related Quote is In Review.';

    private static final String ERROR_PRIMARY_CONTACT_CHANGE =
        'Primary Contact cannot be changed while the related Quote is In Review.';

    private static final String LOG_TAG_DEAL_FREEZE =
        'AP2-US-002';

    private static final String LOG_TAG_QUOTE_LINE_ITEM =
        'Quote Line Item';

    private static final String LOG_TAG_PRIMARY_CONTACT =
        'Primary Contact';

    private static final String LOG_BLOCKED_QUOTE_LINE_ITEM_CHANGE =
        'Blocked unauthorized Quote Line Item change while the related Quote is In Review.';

    private static final String LOG_BLOCKED_PRIMARY_CONTACT_CHANGE =
        'Blocked unauthorized Primary Contact change while the related Quote is In Review.';

    // Validates Quote Line Item changes against the deal-freeze rule.
    // Changes are blocked when the related Quote is In Review, except for
    // users above the Opportunity owner in the Salesforce Role Hierarchy.
    public static void validateQuoteLineItemChanges(
        List<QuoteLineItem> quoteLineItems
    ) {
        if (quoteLineItems == null || quoteLineItems.isEmpty()) {
            return;
        }

        Set<Id> quoteIds = collectQuoteIds(quoteLineItems);

        if (quoteIds.isEmpty()) {
            return;
        }

        Map<Id, Quote> quotesById = QuoteSelector.getByIds(quoteIds);

        Set<Id> frozenQuoteOwnerIds =
            collectFrozenQuoteOwnerIds(quotesById.values());

        if (frozenQuoteOwnerIds.isEmpty()) {
            return;
        }

        // Retrieves the subset of Opportunity owners who are above the current user
        Set<Id> authorizedOwnerIds =
            RoleHierarchyService.getAuthorizedOwnerIds(
                frozenQuoteOwnerIds
            );

        Set<Id> blockedQuoteIds = addErrorsForFrozenQuotes(
            quoteLineItems,
            quotesById,
            authorizedOwnerIds
        );

        // Logs blocked QLI changes once per affected Quote.
        logBlockedChanges(
            blockedQuoteIds,
            LOG_BLOCKED_QUOTE_LINE_ITEM_CHANGE,
            LOG_TAG_QUOTE_LINE_ITEM
        );
    }

    // Validates Primary Contact changes against the deal-freeze rule.
    // Changes are blocked when the Opportunity has a related Quote in review,
    // except for users above the Opportunity owner in the Role Hierarchy.
    public static void validatePrimaryContactChanges(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldOpportunityMap
    ) {
        if (
            newOpportunities == null ||
            newOpportunities.isEmpty() ||
            oldOpportunityMap == null
        ) {
            return;
        }

        Set<Id> opportunityIdsWithPrimaryContactChange =
            collectOpportunityIdsWithPrimaryContactChange(
                newOpportunities,
                oldOpportunityMap
            );

        if (opportunityIdsWithPrimaryContactChange.isEmpty()) {
            return;
        }

        Set<Id> frozenOpportunityIds =
            QuoteSelector.getOpportunityIdsWithQuotesInReview(
                opportunityIdsWithPrimaryContactChange
            );

        if (frozenOpportunityIds.isEmpty()) {
            return;
        }

        Set<Id> frozenOpportunityOwnerIds =
            collectFrozenOpportunityOwnerIds(
                newOpportunities,
                frozenOpportunityIds
            );

        Set<Id> authorizedOwnerIds =
            RoleHierarchyService.getAuthorizedOwnerIds(
                frozenOpportunityOwnerIds
            );

        Set<Id> blockedOpportunityIds =
            addErrorsForFrozenPrimaryContactChanges(
                newOpportunities,
                oldOpportunityMap,
                frozenOpportunityIds,
                authorizedOwnerIds
            );

        // Logs blocked Primary Contact changes once per affected Opportunity.
        logBlockedChanges(
            blockedOpportunityIds,
            LOG_BLOCKED_PRIMARY_CONTACT_CHANGE,
            LOG_TAG_PRIMARY_CONTACT
        );
    }

    // Collects parent Quote Ids so Quote details can be queried once
    // for the full trigger transaction.
    private static Set<Id> collectQuoteIds(
        List<QuoteLineItem> quoteLineItems
    ) {
        Set<Id> quoteIds = new Set<Id>();

        for (QuoteLineItem quoteLineItem : quoteLineItems) {
            if (quoteLineItem.QuoteId != null) {
                quoteIds.add(quoteLineItem.QuoteId);
            }
        }

        return quoteIds;
    }

    // Collects Opportunity owners only from Quotes currently in review,
    // limiting hierarchy checks to records that are actually frozen.
    private static Set<Id> collectFrozenQuoteOwnerIds(
        List<Quote> quotes
    ) {
        Set<Id> opportunityOwnerIds = new Set<Id>();

        for (Quote quoteRecord : quotes) {
            if (!isQuoteFrozen(quoteRecord)) {
                continue;
            }

            Id opportunityOwnerId = getOpportunityOwnerId(quoteRecord);

            if (opportunityOwnerId != null) {
                opportunityOwnerIds.add(opportunityOwnerId);
            }
        }

        return opportunityOwnerIds;
    }

    // Collects Opportunities where Primary Contact has actually changed,
    // avoiding freeze validation for unrelated Opportunity updates.
    private static Set<Id> collectOpportunityIdsWithPrimaryContactChange(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldOpportunityMap
    ) {
        Set<Id> opportunityIds = new Set<Id>();

        for (Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity =
                oldOpportunityMap.get(newOpportunity.Id);

            Boolean primaryContactHasChanged =
                oldOpportunity != null &&
                newOpportunity.Primary_Contact__c !=
                oldOpportunity.Primary_Contact__c;

            if (primaryContactHasChanged) {
                opportunityIds.add(newOpportunity.Id);
            }
        }

        return opportunityIds;
    }

    // Collects owners of frozen Opportunities so hierarchy authorization
    // is evaluated once for the full trigger transaction.
    private static Set<Id> collectFrozenOpportunityOwnerIds(
        List<Opportunity> opportunities,
        Set<Id> frozenOpportunityIds
    ) {
        Set<Id> opportunityOwnerIds = new Set<Id>();

        for (Opportunity opportunityRecord : opportunities) {
            if (
                frozenOpportunityIds.contains(opportunityRecord.Id) &&
                opportunityRecord.OwnerId != null
            ) {
                opportunityOwnerIds.add(opportunityRecord.OwnerId);
            }
        }

        return opportunityOwnerIds;
    }

    // Adds a record-level error to each QLI that belongs to a frozen Quote
    // and is being changed by an unauthorized user.
    private static Set<Id> addErrorsForFrozenQuotes(
        List<QuoteLineItem> quoteLineItems,
        Map<Id, Quote> quotesById,
        Set<Id> authorizedOwnerIds
    ) {
        Set<Id> blockedQuoteIds = new Set<Id>();

        for (QuoteLineItem quoteLineItem : quoteLineItems) {
            Quote quoteRecord = quotesById.get(quoteLineItem.QuoteId);

            if (!isQuoteFrozen(quoteRecord)) {
                continue;
            }

            Id opportunityOwnerId = getOpportunityOwnerId(quoteRecord);

            Boolean canBypassFreeze =
                opportunityOwnerId != null &&
                authorizedOwnerIds.contains(opportunityOwnerId);

            if (!canBypassFreeze) {
                quoteLineItem.addError(ERROR_FROZEN_QUOTE);
                blockedQuoteIds.add(quoteRecord.Id);
            }
        }

        return blockedQuoteIds;
    }

    // Adds a record-level error when an unauthorized user changes
    // Primary Contact on an Opportunity with a Quote in review.
    private static Set<Id> addErrorsForFrozenPrimaryContactChanges(
        List<Opportunity> newOpportunities,
        Map<Id, Opportunity> oldOpportunityMap,
        Set<Id> frozenOpportunityIds,
        Set<Id> authorizedOwnerIds
    ) {
        Set<Id> blockedOpportunityIds = new Set<Id>();

        for (Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity =
                oldOpportunityMap.get(newOpportunity.Id);

            Boolean primaryContactHasChanged =
                oldOpportunity != null &&
                newOpportunity.Primary_Contact__c !=
                oldOpportunity.Primary_Contact__c;

            if (
                !primaryContactHasChanged ||
                !frozenOpportunityIds.contains(newOpportunity.Id)
            ) {
                continue;
            }

            Boolean canBypassFreeze =
                newOpportunity.OwnerId != null &&
                authorizedOwnerIds.contains(newOpportunity.OwnerId);

            if (!canBypassFreeze) {
                newOpportunity.addError(
                    ERROR_PRIMARY_CONTACT_CHANGE
                );

                blockedOpportunityIds.add(newOpportunity.Id);
            }
        }

        return blockedOpportunityIds;
    }

    // Logs governance violations without allowing logging failures
    // to change the deal-freeze validation outcome.
    private static void logBlockedChanges(
        Set<Id> recordIds,
        String logMessage,
        String changeTypeTag
    ) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        try {
            for (Id recordId : recordIds) {
                Logger.warn(
                    logMessage,
                    recordId
                )
                .addTag(LOG_TAG_DEAL_FREEZE)
                .addTag(changeTypeTag);
            }

            Logger.saveLog(
                Logger.SaveMethod.EVENT_BUS
            );
        } catch (Exception loggingException) {
            // Logging must not replace the intended business validation error.
            Logger.flushBuffer();

            System.debug(
                LoggingLevel.WARN,
                'Unable to save deal-freeze log entries: ' +
                loggingException.getMessage()
            );
        }
    }

    // Determines whether the Quote has reached the frozen review state.
    private static Boolean isQuoteFrozen(Quote quoteRecord) {
        return quoteRecord != null &&
            quoteRecord.Status == STATUS_IN_REVIEW;
    }

    // Retrieves the Opportunity owner selected by QuoteSelector.
    private static Id getOpportunityOwnerId(Quote quoteRecord) {
        return quoteRecord != null &&
                quoteRecord.Opportunity != null
            ? quoteRecord.Opportunity.OwnerId
            : null;
    }
}