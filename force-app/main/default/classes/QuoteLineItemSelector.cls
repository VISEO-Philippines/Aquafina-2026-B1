public inherited sharing class QuoteLineItemSelector {

    /**
     * Centralizes all data access for quote line items.
     */

    public static List<QuoteLineItem> getByQuoteIds(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) {
            return new List<QuoteLineItem>();
        }

        return [
            SELECT Id, QuoteId, Product2Id, Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ];
    }

    public static List<Product2> getProductsByIds(Set<Id> productIds) {
        if (productIds == null || productIds.isEmpty()) {
            return new List<Product2>();
        }

        return [
            SELECT Id, Name
            FROM Product2
            WHERE Id IN :productIds
        ];
    }

}
