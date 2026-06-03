/*
 * Trigger handler for QuoteLineItem records.
 * Extends TriggerHandler base class and implements duplicate product validation.
 * Uses DuplicateProductService to detect and prevent duplicate products in quotes.
 */
public with sharing class QuoteLineItemTriggerHandler extends TriggerHandler
{

    private DuplicateProductService duplicateProductService;

    /**
     * Default constructor initializing the handler with a new DuplicateProductService instance.
     */
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

    @TestVisible
    private List<QuoteLineItem> filterChangedQuoteLineItems(
        List<QuoteLineItem> newLines,
        Map<Id, QuoteLineItem> oldLineMap
    )
    {
        List<QuoteLineItem> updatedLines = new List<QuoteLineItem>();

        for (QuoteLineItem newLine : newLines)
        {
            QuoteLineItem oldLine = oldLineMap.get(newLine.Id);
            if (oldLine == null || oldLine.Product2Id != newLine.Product2Id)
            {
                updatedLines.add(newLine);
            }
        }

        return updatedLines;
    }

    /**
     * Executes before insert event.
     * Validates that new quote line items do not contain duplicate products.
     */
    public override void beforeInsert()
    {
        this.duplicateProductService.checkDuplicateProducts((List<QuoteLineItem>) Trigger.new);
    }

    /**
     * Executes before update event.
     * Validates that updated quote line items do not contain duplicate products.
     */
    public override void beforeUpdate()
    {
        List<QuoteLineItem> updatedLines = this.filterChangedQuoteLineItems(
            (List<QuoteLineItem>) Trigger.new,
            (Map<Id, QuoteLineItem>) Trigger.oldMap
        );

        this.duplicateProductService.checkDuplicateProducts(updatedLines);
    }
}
