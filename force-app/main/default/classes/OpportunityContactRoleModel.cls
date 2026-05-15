public with sharing class OpportunityContactRoleModel {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityContactRole> getPrimaryContactRoleFromOpportunity(Id oppId) {

        return [
        SELECT Id, ContactId, Contact.Email
        FROM OpportunityContactRole
        WHERE OpportunityId = :oppId
        AND IsPrimary = true
        LIMIT 1
        ];

    }
}