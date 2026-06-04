public class QuoteLineItemTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){
        QuoteLineItemValidatorService.validateProducts(Trigger.new);
    }

    public override void beforeUpdate(){
        QuoteLineItemValidatorService.validateProducts(Trigger.new);
    }
}