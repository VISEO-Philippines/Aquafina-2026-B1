public class QuoteLineItemTriggerHandler extends TriggerHandler {
 
    // Uses trigger framework to delegate logic to service layer,
    // keeping the trigger thin and ensuring reusability/testability
    protected override void beforeInsert() {
 
        // Prevents new Quote Line Items from being added
        // when the related Quote is frozen or In Review.
        DealFreezeService.validateQuoteLineItemChanges(
            (List<QuoteLineItem>) Trigger.new
        );
 
        QuoteLineItemValidationService.validateDuplicateProducts(
            (List<QuoteLineItem>) Trigger.new
        );
    }
 
    // Reuses the same validation logic for updates to enforce consistency
    protected override void beforeUpdate() {
 
        // Prevents Quote Line Item updates when the related
        // Quote is frozen or In Review.
        DealFreezeService.validateQuoteLineItemChanges(
            (List<QuoteLineItem>) Trigger.new
        );
 
        List<QuoteLineItem> qlisWithProductChange =
            QuoteLineItemHelper.filterQuoteLineItemsWithProductChange(
                (List<QuoteLineItem>) Trigger.new,
                (Map<Id, QuoteLineItem>) Trigger.oldMap
            );
 
        QuoteLineItemValidationService.validateDuplicateProducts(
            qlisWithProductChange
        );
    }
 
    // Prevents Quote Line Item deletion when the related
    // Quote is frozen or In Review.
    protected override void beforeDelete() {
        DealFreezeService.validateQuoteLineItemChanges(
            (List<QuoteLineItem>) Trigger.old
        );
    }
}
 