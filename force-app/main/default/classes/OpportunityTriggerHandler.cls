public inherited sharing class OpportunityTriggerHandler extends TriggerHandler {
    // Uses trigger framework to delegate logic to service layer,
    // keeping the trigger thin and ensuring reusability/testability

    protected override void beforeUpdate() {
        DealFreezeService.validatePrimaryContactChanges(
            (List<Opportunity>) Trigger.new,
            (Map<Id, Opportunity>) Trigger.oldMap
        );
    }
}