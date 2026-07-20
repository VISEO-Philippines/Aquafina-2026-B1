public inherited sharing class LeadSelector {

    private static final Integer MAX_ROWS = 10000;

    // Centralizes all data access for Lead auto-closure.
    public static List<Lead> getStagnantOpenLeads(
        DateTime cutoffDate,
        Set<String> excludedStatuses
    ) {
        // Guard: empty excludedStatuses bound to NOT IN would
        // match every Lead; null cutoff has no valid meaning.
        if (
            cutoffDate == null
            || excludedStatuses == null
            || excludedStatuses.isEmpty()
        ) {
            return new List<Lead>();
        }
        return [
            SELECT
                Id,
                OwnerId,
                Status,
                IsConverted,
                Closure_Reason__c
            FROM Lead
            WHERE
                LastModifiedDate <= :cutoffDate
                AND IsConverted = false
                AND Status NOT IN :excludedStatuses
            LIMIT :MAX_ROWS
        ];
    }

    // Batch Apex requires the query to be passed to
    // Database.getQueryLocator() directly within this method's
    // scope, so the WHERE clause is duplicated from
    // getStagnantOpenLeads() rather than reused.
    //
    // Intentionally no LIMIT: QueryLocators consumed by batch
    // start() are exempt from the 50k query-row limit (up to
    // 50M rows), and a LIMIT would silently cap how many Leads
    // the nightly job can process.
    public static Database.QueryLocator getStagnantOpenLeadsQueryLocator(
        DateTime cutoffDate,
        Set<String> excludedStatuses
    ) {
        // Guard: batch start() cannot return null, so return an
        // empty-result locator instead.
        if (
            cutoffDate == null
            || excludedStatuses == null
            || excludedStatuses.isEmpty()
        ) {
            return Database.getQueryLocator(
                [SELECT Id FROM Lead WHERE Id = null]
            );
        }
        return Database.getQueryLocator([
            SELECT
                Id,
                OwnerId,
                Status,
                IsConverted,
                Closure_Reason__c
            FROM Lead
            WHERE
                LastModifiedDate <= :cutoffDate
                AND IsConverted = false
                AND Status NOT IN :excludedStatuses
        ]);
    }
}