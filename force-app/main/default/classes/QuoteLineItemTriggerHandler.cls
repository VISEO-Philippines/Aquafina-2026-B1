public class QuoteLineItemTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){
        QuoteLineItemValidatorService.validateNewProducts(Trigger.new);
    }

    public override void beforeUpdate(){
        //to follow-up
        //QuoteLineItemValidatorService.validateProducts(Trigger.old);
    }
}