public with sharing class LeadTriggerHandler {
    public static void afterInsert(List<Lead> leads) {
        // pass IDs instead of objects because this will 
        // probably be serialized somewhere within salesforce
        List<Id> leadsToConvert = new List<Id>();
        for (Lead l : leads) {
            if(l.LeadSource == 'Web' && l.Rating == 'Hot') {
                leadsToConvert.add(l.Id);
            }
        }
        if(!leadsToConvert.isEmpty()) {
            System.enqueueJob(new AsyncJobLeadConvert(leadsToConvert));
        }
    }
}