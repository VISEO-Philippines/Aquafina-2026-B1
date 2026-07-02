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
 
        List<QuoteLineItem> qlisWithProductChange = filterQuoteLineItemsWithProductChange(
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
 
    private static List<QuoteLineItem> filterQuoteLineItemsWithProductChange(
        List<QuoteLineItem> newQLIs,
        Map<Id, QuoteLineItem> oldQLIMap
    ) {
        List<QuoteLineItem> qlisWithProductChange = new List<QuoteLineItem>();
 
        for (QuoteLineItem newQLI : newQLIs) {
            QuoteLineItem oldQLI = oldQLIMap.get(newQLI.Id);
 
            Boolean productHasChanged = newQLI.Product2Id != oldQLI.Product2Id;
 
            if (productHasChanged) {
                qlisWithProductChange.add(newQLI);
            }
        }
 
        return qlisWithProductChange;
    }
}