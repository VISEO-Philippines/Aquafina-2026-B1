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
        this.duplicateProductService.checkDuplicateProducts(Trigger.new);
    }

    /**
     * Executes before update event.
     * Validates that updated quote line items do not contain duplicate products.
     */
    public override void beforeUpdate() 
    {
        List<QuoteLineItem> updatedLines = new List<QuoteLineItem>();

        // Only re-check records whose product changed during the update.
        for (QuoteLineItem newLine : Trigger.new)
        {
            QuoteLineItem oldLine = Trigger.oldMap.get(newLine.Id);
            if (oldLine == null || oldLine.Product2Id != newLine.Product2Id)
            {
                updatedLines.add(newLine);
            }
        }

        this.duplicateProductService.checkDuplicateProducts(updatedLines);
    }
}