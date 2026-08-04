public inherited sharing class LeadActivityHelper {
    /**
     *
     * Returns Leads where Status or OwnerId changed during update.
     *
     * this helper only performs record filtering.
     * */

    public static List<Lead> filterLeadsWithActivityChange(
        List<Lead> newLeads,
        Map<Id, Lead> oldLeadMap
    ){
        List<Lead> leadsWithActivityChange =
            new List<Lead>();

        if (
            newLeads == null ||
            newLeads.isEmpty() ||
            oldLeadMap == null ||
            oldLeadMap.isEmpty()
        ) {
            return leadsWithActivityChange;
        }

        for (Lead newLead : newLeads) {

            Lead oldLead =
                oldLeadMap.get(newLead.Id);

            if (
                oldLead != null &&
                (
                    newLead.Status != oldLead.Status ||
                    newLead.OwnerId != oldLead.OwnerId
                )
            ) {
                leadsWithActivityChange.add(newLead);
            }
        }

        return leadsWithActivityChange;
    }
}
