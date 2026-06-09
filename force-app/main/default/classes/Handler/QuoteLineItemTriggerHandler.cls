public class QuoteLineItemTriggerHandler extends TriggerHandler {

    // Uses trigger framework to delegate logic to service layer,
    // keeping the trigger thin and ensuring reusability/testability
    protected override void beforeInsert() {
        QuoteLineItemValidationService.validateDuplicateProducts(
            (List<QuoteLineItem>) Trigger.new
        );
    }

    // Reuses the same validation logic for updates to enforce consistency
    protected override void beforeUpdate() {

        List<QuoteLineItem> qlisWithProductChange = filterQuoteLineItemsWithProductChange(
            (List<QuoteLineItem>) Trigger.new,
            (Map<Id,QuoteLineItem>) Trigger.oldMap
        );
        
        QuoteLineItemValidationService.validateDuplicateProducts(qlisWithProductChange);
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
