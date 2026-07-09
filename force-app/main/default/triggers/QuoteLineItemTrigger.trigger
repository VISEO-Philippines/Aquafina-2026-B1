/**
 * Trigger for QuoteLineItem records.
 * Routes trigger events to QuoteLineItemTriggerHandler for processing.
 * Handles before insert, before update, and before delete events.
 */

trigger QuoteLineItemTrigger on QuoteLineItem(before insert, before update, before delete) {
    new QuoteLineItemTriggerHandler().run();
}
