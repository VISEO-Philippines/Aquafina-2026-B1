/**
 * Trigger for OpportunityContactRole records.
 * Routes trigger events to OpportunityContactRoleTriggerHandler for processing.
 * Handles before insert and before delete to enforce the frozen quote rule on
 * primary contact changes.
 */

trigger OpportunityContactRoleTrigger on OpportunityContactRole(before insert, before delete) {
    new OpportunityContactRoleTriggerHandler().run();
}
