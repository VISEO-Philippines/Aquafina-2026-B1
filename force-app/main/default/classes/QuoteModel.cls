public with sharing class QuoteModel {
    // TODO: merge this with SOQL for Quote Line items
    // in this format-ish: SELECT Id, (SELECT Id FROM QuoteLineItems) FROM Quote where Id =: quoteId
    @AuraEnabled(cacheable=true)
    public static List<Quote> getQuote(Id quoteId){

        List<Quote> qs = [
            SELECT Id, Name, LineItemCount, Subtotal, 
            Total_Discounted_Amount__c, Discount, 
            Total_Amount__c, TotalPrice, VAT_Tax__c, 
            Status, Approval_Status__c, Initial_Quote_Sent__c
            FROM Quote
            WHERE Id =:quoteId
            LIMIT 1
            ];

        // Should not be empty since a quoteId was passed to this
        if (qs.size() == 0) {
            throw new AuraHandledException('No Quote found for the provided ID.');
        }

        return qs;
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLineItems(Id quoteId){
        // This can be empty if displaying dashboard for a 
        // quote without line items yet
        return [
            SELECT Id, Product2.Name, Quantity, Subtotal, Discount, TotalPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ];
    }
}