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
     * @return List of QuoteLineItem records with related product and quote information
     */
    
    public List<QuoteLineItem> getExistingLinesByQuoteIds(Set<Id> quoteIds) 
    {
        return 
        [
            SELECT Id, QuoteId, Product2Id, Quantity, UnitPrice, Description
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Retrieves QuoteLineItems grouped by Quote and Product.
     * Returns a map with composite key (Quote ID + Product ID) for easy duplicate detection.
     * 
     * @param lineItems List of QuoteLineItem records to group
     * @return Map with key format "quoteId|productId" mapped to Set of Product IDs
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
