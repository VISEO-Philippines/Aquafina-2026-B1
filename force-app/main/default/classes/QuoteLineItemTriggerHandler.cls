public class QuoteLineItemTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){
        QuoteLineItemValidatorService.validateNewProducts();
    }

    public override void beforeUpdate(){
        QuoteLineItemValidatorService.validateNewProducts();
    }
}