/*
 * Selector for PriceBookEntry records.
 * Provides methods to query price book entries by IDs and retrieve associated products.
 */
public with sharing class PriceBookEntrySelector {

    /**
     * Retrieves PriceBookEntry records by a set of IDs.
     * 
     * @param ids Set of PriceBookEntry IDs to query
     * @return List of PriceBookEntry records with related Product information
     */
    public List<PriceBookEntry> getPricebookEntriesByIds(Set<Id> ids) {
        return [
            SELECT Id, Product2Id, UnitPrice, Pricebook2Id
            FROM PriceBookEntry
            WHERE Id IN :ids
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Retrieves a map of Product IDs to PriceBookEntry records.
     * Useful for quick product lookups from price book entries.
     * 
     * @param pbeIds Set of PriceBookEntry IDs
     * @return Map of Product2Id to PriceBookEntry
     */
    public Map<Id, Id> getProduct2IdMap(Set<Id> pbeIds) {
        Map<Id, Id> productMap = new Map<Id, Id>();
        List<PriceBookEntry> entries = getPricebookEntriesByIds(pbeIds);
        
        for (PriceBookEntry entry : entries) {
            productMap.put(entry.Id, entry.Product2Id);
        }
        
        return productMap;
    }
}
