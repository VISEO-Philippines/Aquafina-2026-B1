public with sharing class LeadService {

    // Problem for this lead conversion is it fails silently such as when we didnt put a territory
    // in the territory field, this caused the conversion to fail since it was expecting a territory value to link to Account in the object mapping
    // should we disable this feature by allowing the mapping to map null values if possible or is it better to add a validation rule for lead to require a
    // Territory? for this one we are adding a validation rule

    // It might be better to add another trigger to update the territory field to the user's country OR better yet to the user's group as was used in the lead sharing rule
    
    public static void convertHotLeads(List<Id> leadIds) {
        Id currentUserId = UserInfo.getUserId();
        // from List<Id> to List<Lead> 
        List<Lead> leads = [SELECT Id, FirstName, LastName FROM Lead WHERE Id IN :leadIds];
        List<Database.LeadConvert> listlc = new List<Database.LeadConvert>();
        // List<Lead> to List<Database.LeadConvert>
        for(Lead l : leads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus('Qualified');
            lc.setOwnerId(currentUserId);
            lc.setOpportunityName('Hot Web Lead: ' + l.FirstName + ' ' + l.Lastname);

            listlc.add(lc);
        }

        // List<Database.LeadConvert> to List<Database.LeadConvertResults>
        List<Database.LeadConvertResult> lcrs = Database.convertLead(listlc, false); // false here is allOrNone, false = allow partial conversion
        List<Lead> leadsToUpdate = new List<Lead>();
        for(Database.LeadConvertResult lcr : lcrs) {
            if(!lcr.isSuccess()) {
                System.debug('Failed to convert lead: ' + lcr.getErrors());
            } else {
                Lead convertedLead = new Lead(
                    Id = lcr.getLeadId(),
                    Status = 'Qualified'
                );

                leadsToUpdate.add(convertedLead);
            }
        }

        if (!leadsToUpdate.isEmpty())
            update leadsToUpdate;

    }
}