public class QuoteLineItemTriggerHandler extends TriggerHandler {

    // Uses trigger framework to delegate logic to service layer,
    // keeping the trigger thin and ensuring reusability/testability
    protected override void beforeInsert() {
        QuoteLineItemValidationService.validateDuplicateProducts(
            Trigger.new
        );
    }

    // Reuses the same validation logic for updates to enforce consistency
    protected override void beforeUpdate() {
        QuoteLineItemValidationService.validateDuplicateProducts(
            Trigger.new
        );
    }
}