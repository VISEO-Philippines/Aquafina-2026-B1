trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update) {

    QuoteLineItemTriggerHandler handler = new QuoteLineItemTriggerHandler();

   handler.run();
}