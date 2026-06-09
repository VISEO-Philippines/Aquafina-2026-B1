/*
 * Selector for Product2 records.
 */
public without sharing class Product2Selector
{
    /**
     * Returns Product2 records matching the given IDs.
     *
     * @param productIds Set of Product2 IDs to fetch
     * @return List of Product2 records with Id and Name
     */
    public List<Product2> getProductsByIds(Set<Id> productIds)
    {
        return
        [
            SELECT Id, Name
            FROM Product2
            WHERE Id IN :productIds
        ];
    }
}
