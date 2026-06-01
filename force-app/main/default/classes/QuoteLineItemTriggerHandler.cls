public with sharing class QuoteLineItemTriggerHandler extends TriggerHandler {
    
    beforeInsert(){
        QuoteLineItemValidatorService.validateNewProducts();
    }

    beforeUpdate(){
        QuoteLineItemValidatorService.validateNewProducts();
    }
}