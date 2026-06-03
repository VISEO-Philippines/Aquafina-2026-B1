/**
 * Service for validating and detecting duplicate products in Quote Line Items.
 * Prevents adding the same product multiple times to a quote.
 * Uses QuoteLineItemSelector for data access.
 */
public with sharing class DuplicateProductService 
{

    private QuoteLineItemSelector qliSelector;

    /**
     * Constructor initializing the service with default selectors.
     */

    public DuplicateProductService() 
    {
        this.qliSelector = new QuoteLineItemSelector();
    }

    /**
     * Constructor allowing dependency injection for testing.
     * 
     * @param qliSelector QuoteLineItemSelector instance
     */

    public DuplicateProductService(QuoteLineItemSelector qliSelector) 
    {
        this.qliSelector = qliSelector;
    }

    /**
     * Validates that new quote line items do not contain duplicate products.
     * 
     * @param newLines List of new QuoteLineItem records to validate
     * @param existingMap Map of existing QuoteLineItem records by Quote ID and Product ID
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
                    newLine.addError('Product already exists in this quote');
                }
            }
        }
    }

    /**
     * Validates quote line items for duplicate products by loading the existing
     * quote line items and comparing them with the incoming records.
     *
     * @param newLines List of new or updated QuoteLineItem records
     */
    public void checkDuplicateProducts(List<QuoteLineItem> newLines)
    {
        if (newLines == null || newLines.isEmpty())
        {
            return;
        }

        Set<Id> quoteIds = new Set<Id>();
        for (QuoteLineItem line : newLines)
        {
            quoteIds.add(line.QuoteId);
        }

        Map<Id, Set<Id>> existingProductMap = this.getExistingProductsByQuote(quoteIds);

        this.validate(newLines, existingProductMap);
    }

    /**
     * Gets existing QuoteLineItem records for the given Quote IDs.
     * 
     * @param quoteIds Set of Quote IDs to retrieve line items for
     * @return Map of Quote IDs to Product ID sets
     */
    public Map<Id, Set<Id>> getExistingProductsByQuote(Set<Id> quoteIds) 
    {
        List<QuoteLineItem> existingLines = this.qliSelector.getExistingLinesByQuoteIds(quoteIds);
        return this.qliSelector.groupByQuoteAndProduct(existingLines);
    }
}