public with sharing class LeadService {
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