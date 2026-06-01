public with sharing class QuoteLineItemSelector{


    /*
     * Centralizes all data access for quote line items.
     * Encapsulates SOQL queries to maintain separation of concerns
     * and keep business logic out of data retrieval.
     */

    public static List<QuoteLineItem> getByQuoteIds(Set<Id> quoteIds) {
        
        if (quoteIds == null || quoteIds.isEmpty()) {
            return new List<QuoteLineItem>();
        }

        return[
            SELECT id, 
                QuoteId, 
                Product2Id, 
                Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId IN : quoteIds
        ];
    }

}
