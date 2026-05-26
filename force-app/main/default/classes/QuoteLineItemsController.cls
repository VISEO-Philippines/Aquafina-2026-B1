public with sharing class QuoteLineItemsController {
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> checkForQuoteLineItems(String oppId){

        List<QuoteLineItem> lstQteLineItem = [SELECT Id, OpportunityLineItem.OpportunityId FROM QuoteLineItem WHERE QuoteLineItem.OpportunityLineItem.OpportunityId = :oppId LIMIT 1];
        return lstQteLineItem;
    }
}