trigger QuoteLineItemTrigger on SOBJECT (before insert, before update) {
    QuoteLineItemTriggerHandler.run();
}