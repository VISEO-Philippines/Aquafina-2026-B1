public with sharing class QuoteLineItemValidatorService {
    public static void validateProducts(List<QuoteLineItem> quoteLineItem) {
        
        //Query existing products
        String quoteId = quoteLineItem[0].quoteId;
        List<QuoteLineItem> quoteLineItemRecord = queryCurrentQuoteLineItems(quoteId);
        
        for (QuoteLineItem qli: quoteLineItem){
            for (QuoteLineItem qqli: quoteLineItemRecord){
                if (qli.PricebookEntryId == qqli.PricebookEntryId){
                    qli.addError('ERROR: ' + qqli.PriceBookEntry.Name + ' has already been added');
                }
            }
        }
    }

    private static List<QuoteLineItem> queryCurrentQuoteLineItems(String quoteId){
        return [SELECT PricebookEntryId, PricebookEntry.Name FROM QuoteLineItem WHERE QuoteId = :quoteId];
    }
}