public with sharing class OpportunitySyncedQuotesController {
    @AuraEnabled(cacheable=true)
    public static List<Quote> checkForQuotes(String oppId){

        List<Quote> lstQuotes = [SELECT Id, IsSyncing, Opportunity.Total_Amount__c FROM Quote WHERE OpportunityId = :oppId LIMIT 1];
        return lstQuotes;
    }

    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuoteRecord(String quoteId){
        List<Quote> lstQuotes = [SELECT Id, Name, Status, Discount FROM Quote WHERE Id = :quoteId];
        return lstQuotes;
    }

    @AuraEnabled(cacheable=true)
    public static List<Quote> checkForQuoteStatus(String oppId){
        List<Quote> lstSyncedQuote = [SELECT Id, Status FROM Quote WHERE Quote.OpportunityId = :oppId AND Status != null LIMIT 1];
        if (lstSyncedQuote[0].Status != null){
            List<Quote> lstSyncedQuoteWithStatus = [SELECT Id, Status FROM Quote WHERE Quote.OpportunityId = :oppId AND Status != null LIMIT 1];
            return lstSyncedQuoteWithStatus;
        }
        return lstSyncedQuote;
    }
}