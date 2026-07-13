/**
 * Selector for Lead records.
 * Queries Lead data without sharing enforcement to ensure the nightly
 * auto-close job can see every Lead in the org, not just what the
 * scheduling/running user can access.
 */
public without sharing class LeadSelector {

    /**
     * Returns a QueryLocator over stagnant, still-open Leads:
     * not converted, not already Disqualified or ClosedNotConverted,
     * and not modified since cutoffDate. A QueryLocator (rather than a
     * List) is used so the caller can batch through the full Lead table
     * safely regardless of org size.
     *
     * @param cutoffDate Leads last modified on or before this date are stagnant
     * @return QueryLocator over the matching Lead records
     */
    public Database.QueryLocator getStagnantLeadsQueryLocator(Date cutoffDate) {
        return Database.getQueryLocator([
            SELECT Id, Name, Status, OwnerId, Owner.Type, LastModifiedDate, IsConverted
            FROM Lead
            WHERE IsConverted = false
            AND Status NOT IN ('Disqualified', 'ClosedNotConverted')
            AND LastModifiedDate <= :cutoffDate
        ]);
    }
}
