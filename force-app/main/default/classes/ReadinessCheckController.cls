public with sharing class ReadinessCheckController {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityContactRole> fetchPrimaryOppContactRoles(String opportunityId) {
        List<OpportunityContactRole> lstOppContRole = [SELECT Id, IsPrimary, Contact.Email FROM OpportunityContactRole WHERE OpportunityId=:opportunityId AND IsPrimary=true];

        return lstOppContRole;
    }

    @AuraEnabled(cacheable=true)
    public static List<Quote> fetchQuotes(String opportunityId){
        List<Quote> lstQuotes = [SELECT Id, Status, LineItemCount, Subtotal, IsSyncing  FROM Quote WHERE OpportunityId = :opportunityId];
        
        return lstQuotes;
    }

}