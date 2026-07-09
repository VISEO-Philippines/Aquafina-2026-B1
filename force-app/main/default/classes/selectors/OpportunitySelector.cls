/**
 * Selector for Opportunity records.
 * Queries Opportunity data without sharing enforcement to ensure consistent
 * access regardless of the current user's visibility settings.
 */
public without sharing class OpportunitySelector {

    /**
     * Returns Opportunity records for the given IDs with OwnerId.
     *
     * @param oppIds Set of Opportunity IDs to fetch
     * @return List of Opportunity records
     */
    public List<Opportunity> getOpportunitiesByIds(Set<Id> oppIds) {
        return [
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
    }
}
