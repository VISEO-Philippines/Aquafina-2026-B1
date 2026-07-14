public inherited sharing class LeadSelector {

    // Centralizes all data access for Lead auto-closure.

    public static List<Lead> getStagnantOpenLeads(
        DateTime cutoffDate,
        Set<String> excludedStatuses
    ) {
        if (cutoffDate == null) {
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
        ];
    }

    // Batch Apex requires the query to be passed to
    // Database.getQueryLocator() directly within this method's
    // scope, so the WHERE clause is duplicated from
    // getStagnantOpenLeads() rather than reused.
    public static Database.QueryLocator getStagnantOpenLeadsQueryLocator(
        DateTime cutoffDate,
        Set<String> excludedStatuses
    ) {
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
