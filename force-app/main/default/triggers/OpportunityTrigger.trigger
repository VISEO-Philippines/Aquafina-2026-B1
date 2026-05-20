trigger OpportunityTrigger on Opportunity (before update) {
    OpportunityTriggerHandler.runOppTrigger();
}