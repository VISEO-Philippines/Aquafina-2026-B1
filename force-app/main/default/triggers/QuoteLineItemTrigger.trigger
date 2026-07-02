trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update, before delete) {

new QuoteLineItemTriggerHandler().run();

}