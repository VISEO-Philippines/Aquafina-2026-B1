public with sharing class OpportunityModel {
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(Id recordId) {
        try {
            return [
                SELECT Id, Name, AccountId, Account.Name, SyncedQuoteId, SyncedQuote.Name, Pricebook2Id, Pricebook2.Name
                FROM Opportunity 
                WHERE Id = :recordId 
                LIMIT 1
                ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}