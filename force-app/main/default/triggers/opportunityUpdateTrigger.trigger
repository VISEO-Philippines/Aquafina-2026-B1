//naming not best practice
//one trigger per object
// no business logic on triggers; handlers to dispatch business logic
trigger opportunityUpdateTrigger on Opportunity (after update) {
    for (Opportunity opp :Trigger.new){
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id); // get old state
        if(oldOpp.StageName == 'New' && opp.SyncedQuote.Status == 'Approved' && opp.SyncedQuote.IsSyncing == true){
            opp.StageName = 'Negotiation';
        }
    }

}