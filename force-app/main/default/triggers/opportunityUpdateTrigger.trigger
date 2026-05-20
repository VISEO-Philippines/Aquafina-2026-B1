//naming not best practice
//one trigger per object
// no business logic on triggers; handlers to dispatch business logic
// state of data before and after context
// before context: account context use before; mutable
// after context: partially committed in DB; immutable
trigger opportunityUpdateTrigger on Opportunity (before update) {
    for (Opportunity opp :Trigger.new){
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id); // get old state
        //comparison not correct;
        if(oldOpp.StageName == 'New' && opp.SyncedQuote.Status == 'Approved' && opp.SyncedQuote.IsSyncing == true){
            opp.StageName = 'Negotiation';
        }
    }

    //OpportunityTriggerHandler

}