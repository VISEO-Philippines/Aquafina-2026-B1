public inherited sharing class LeadTriggerHandler extends TriggerHandler {
    // Uses trigger framework to delegate logic to service layer,
    // keeping the trigger thin and ensuring reusability/testability

    protected override void beforeInsert() {
        LeadActivityService.stampLastModifiedDateOnInsert(
            (List<Lead>) Trigger.new
        );
    }

    protected override void beforeUpdate() {
        LeadActivityService.stampLastModifiedDateOnUpdate(
            (List<Lead>) Trigger.new,
            (Map<Id, Lead>) Trigger.oldMap
        );
    }
}
