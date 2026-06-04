trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update) {
    new QuoteLineItemTriggerHandler().run();
}