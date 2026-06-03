/**
 * Trigger for QuoteLineItem records.
 * Routes trigger events to QuoteLineItemTriggerHandler for processing.
 * Handles before insert, before update events to validate duplicate products.
 */

trigger QuoteLineItemTrigger on QuoteLineItem(before insert, before update) {
    new QuoteLineItemTriggerHandler().run();
}
