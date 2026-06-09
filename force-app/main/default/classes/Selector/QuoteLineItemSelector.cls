public inherited sharing class QuoteLineItemSelector {

    /*
     * Centralizes data access for Quote Line Item duplicate validation.
     * Business logic should call selector methods instead of writing SOQL directly.
     */
    public static List<QuoteLineItem> getByQuoteIds(Set<Id> quoteIds) {

        if (quoteIds == null || quoteIds.isEmpty()) {
            return new List<QuoteLineItem>();
        }

        return [
            SELECT
                Id,
                QuoteId,
                Product2Id,
                Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ];
    }

    public static List<PricebookEntry> getPricebookEntriesByIds(
        Set<Id> pricebookEntryIds
    ) {

        if (pricebookEntryIds == null || pricebookEntryIds.isEmpty()) {
            return new List<PricebookEntry>();
        }

        return [
            SELECT
                Id,
                Product2Id,
                Product2.Name
            FROM PricebookEntry
            WHERE Id IN :pricebookEntryIds
        ];
    }
}
  