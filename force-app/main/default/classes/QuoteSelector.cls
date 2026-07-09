public inherited sharing class QuoteSelector {

    // Retrieves related Quote details needed to determine whether
    // Quote Line Item changes should be blocked during review.
    public static Map<Id, Quote> getByIds(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) {
            return new Map<Id, Quote>();
        }

        return new Map<Id, Quote>([
            SELECT
                Id,
                Status,
                OpportunityId,
                Opportunity.OwnerId
            FROM Quote
            WHERE Id IN :quoteIds
        ]);
    }

    // Identifies Opportunities with at least one related Quote
    // that is currently in the frozen In Review status.
    public static Set<Id> getOpportunityIdsWithQuotesInReview(
        Set<Id> opportunityIds
    ) {
        Set<Id> frozenOpportunityIds = new Set<Id>();

        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return frozenOpportunityIds;
        }

        for (Quote quoteRecord : [
            SELECT OpportunityId
            FROM Quote
            WHERE OpportunityId IN :opportunityIds
            AND Status = 'In Review'
        ]) {
            frozenOpportunityIds.add(quoteRecord.OpportunityId);
        }

        return frozenOpportunityIds;
    }
}