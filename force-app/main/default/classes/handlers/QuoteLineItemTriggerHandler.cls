/*
 * Trigger handler for QuoteLineItem records.
 * Extends TriggerHandler base class and implements duplicate product validation.
 * Uses DuplicateProductService to detect and prevent duplicate products in quotes.
 */
public with sharing class QuoteLineItemTriggerHandler extends TriggerHandler 
{

    private DuplicateProductService duplicateProductService;

    //Constructor initializing the handler with DuplicateProductService.
    public QuoteLineItemTriggerHandler() 
    {
        this.duplicateProductService = new DuplicateProductService();
    }

    /**
     * Constructor allowing dependency injection for testing.
     * 
     * @param duplicateProductService DuplicateProductService instance
     */

    public QuoteLineItemTriggerHandler(DuplicateProductService duplicateProductService) 
    {
        this.duplicateProductService = duplicateProductService;
    }

    /**
     * Executes before insert event.
     * Validates that new quote line items do not contain duplicate products.
     */
    public override void beforeInsert() 
    {
        validateDuplicateProducts(Trigger.new);
    }

    /**
     * Executes before update event.
     * Validates that updated quote line items do not contain duplicate products.
     */
    public override void beforeUpdate() 
    {
        validateDuplicateProducts(Trigger.new);
    }

    /**
     * Validates quote line items for duplicate products.
     * Retrieves existing quote line items and checks for duplicates.
     * 
     * @param newLines List of new or updated QuoteLineItem records
     * @throws DuplicateProductException if duplicate products are detected
     */

    private void validateDuplicateProducts(List<QuoteLineItem> newLines) 
    {
        if (newLines == null || newLines.isEmpty()) 
        {
            return;
        }

        // Collect all quote IDs from new lines
        Set<Id> quoteIds = new Set<Id>();
        for (QuoteLineItem line : newLines) 
        {
            quoteIds.add(line.QuoteId);
        }

        // Get existing quote line items
        List<QuoteLineItem> existingLines = this.duplicateProductService.getExistingProductsByQuote(quoteIds);

        // Group existing products by quote ID
        QuoteLineItemSelector selector = new QuoteLineItemSelector();
        Map<Id, Set<Id>> existingProductMap = selector.groupByQuoteAndProduct(existingLines);

        // Validate new lines against existing products
        this.duplicateProductService.validate(newLines, existingProductMap);
    }
}