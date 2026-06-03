/*
 * Selector for QuoteLineItem records.
 * Provides methods to query quote line items from the database.
 */
public without sharing class QuoteLineItemSelector
{

    /**
     * Retrieves all existing QuoteLineItem records for a set of Quote IDs.
     *
     * @param quoteIds Set of Quote IDs to query
     * @return List of QuoteLineItem records
     */
    public List<QuoteLineItem> getExistingLinesByQuoteIds(Set<Id> quoteIds)
    {
        return
        [
            SELECT Id, QuoteId, Product2Id
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ];
    }

}
