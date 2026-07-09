/**
 * Selector for Quote records.
 * Queries Quote data without sharing enforcement to ensure consistent access
 * regardless of the current user's visibility settings.
 */
public without sharing class QuoteSelector {

    /**
     * Returns Quote records for the given IDs with Status and OpportunityId.
     *
     * @param quoteIds Set of Quote IDs to fetch
     * @return List of Quote records
     */
    public List<Quote> getQuotesByIds(Set<Id> quoteIds) {
        return [
            SELECT Id, Status, OpportunityId
            FROM Quote
            WHERE Id IN :quoteIds
        ];
    }

    /**
     * Returns the syncing Quote for each given Opportunity ID (IsSyncing = true).
     * Used to find the currently active quote tied to an Opportunity.
     *
     * @param oppIds Set of Opportunity IDs
     * @return List of syncing Quote records with Status and OpportunityId
     */
    public List<Quote> getSyncingQuotesByOppIds(Set<Id> oppIds) {
        return [
            SELECT Id, OpportunityId, Status
            FROM Quote
            WHERE OpportunityId IN :oppIds
              AND IsSyncing = true
        ];
    }
}
