/*
 * Selector for QuoteLineItem records.
 * Provides methods to query quote line items and perform grouping operations.
 */
public with sharing class QuoteLineItemSelector
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
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Groups QuoteLineItem records into a map of Quote ID to the set of Product IDs on that quote.
     *
     * @param lineItems List of QuoteLineItem records to group
     * @return Map of Quote ID to Set of Product IDs
     */
    public Map<Id, Set<Id>> groupByQuoteAndProduct(List<QuoteLineItem> lineItems)
    {
        Map<Id, Set<Id>> groupedMap = new Map<Id, Set<Id>>();

        for (QuoteLineItem item : lineItems)
        {
            if (!groupedMap.containsKey(item.QuoteId))
            {
                groupedMap.put(item.QuoteId, new Set<Id>());
            }
            groupedMap.get(item.QuoteId).add(item.Product2Id);
        }

        return groupedMap;
    }
}
