trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update) {
    QuoteLineItemTriggerHandler.run();
}