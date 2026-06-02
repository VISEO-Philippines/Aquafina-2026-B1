/**
 * Service for validating and detecting duplicate products in Quote Line Items.
 * Prevents adding the same product multiple times to a quote.
 * Uses PriceBookEntrySelector and QuoteLineItemSelector for data access.
 */
public with sharing class DuplicateProductService 
{

    private PriceBookEntrySelector pbeSelector;
    private QuoteLineItemSelector qliSelector;

    /**
     * Constructor initializing the service with default selectors.
     */

    public DuplicateProductService() 
    {
        this.pbeSelector = new PriceBookEntrySelector();
        this.qliSelector = new QuoteLineItemSelector();
    }

    /**
     * Constructor allowing dependency injection for testing.
     * 
     * @param pbeSelector PriceBookEntrySelector instance
     * @param qliSelector QuoteLineItemSelector instance
     */

    public DuplicateProductService(PriceBookEntrySelector pbeSelector, QuoteLineItemSelector qliSelector) 
    {
        this.pbeSelector = pbeSelector;
        this.qliSelector = qliSelector;
    }

    /**
     * Validates that new quote line items do not contain duplicate products.
     * 
     * @param newLines List of new QuoteLineItem records to validate
     * @param existingMap Map of existing QuoteLineItem records by Quote ID and Product ID
     * @throws DuplicateProductException if a duplicate product is detected
     */

    public void validate(List<QuoteLineItem> newLines, Map<Id, Set<Id>> existingMap) 
    {
        for (QuoteLineItem newLine : newLines) 
        {
            if (existingMap.containsKey(newLine.QuoteId)) 
            {
                Set<Id> existingProducts = existingMap.get(newLine.QuoteId);
                if (existingProducts.contains(newLine.Product2Id)) 
                {
                    DuplicateProductException ex = new DuplicateProductException('Product already exists in this quote');
                    ex.productName = 'Product with ID: ' + newLine.Product2Id;
                    ex.quoteId = newLine.QuoteId;
                    ex.lineItemId = newLine.Id;
                    ex.productId = newLine.Product2Id;
                    throw ex;
                }
            }
        }
    }

    /**
     * Gets existing QuoteLineItem records for the given Quote IDs.
     * 
     * @param quoteIds Set of Quote IDs to retrieve line items for
     * @return List of existing QuoteLineItem records
     */
    public List<QuoteLineItem> getExistingProductsByQuote(Set<Id> quoteIds) 
    {
        return this.qliSelector.getExistingLinesByQuoteIds(quoteIds);
    }

    /**
     * Gets PriceBook entries by their IDs.
     * 
     * @param pbeIds Set of PriceBookEntry IDs
     * @return List of PriceBookEntry records
     */
    
    public List<PriceBookEntry> getPriceBookEntries(Set<Id> pbeIds) 
    {
        return this.pbeSelector.getPriceBookEntriesByIds(pbeIds);
    }

    /**
     * Checks for duplicate products across a list of line items and a product map.
     * 
     * @param lines List of QuoteLineItem records to check
     * @param p2Map Map of Product IDs to their details
     * @return Map with composite key format to identify duplicates
     */

    public Map<Id, Set<Id>> checkDuplicateProducts(List<QuoteLineItem> lines, Map<Id, Set<Id>> p2Map) 
    {
        return this.qliSelector.groupByQuoteAndProduct(lines);
    }
}