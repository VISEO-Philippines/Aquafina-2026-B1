public inherited sharing class LeadActivityService {

    // Defaults the activity timestamp on newly created Leads so
    // every Lead starts with a valid inactivity baseline. Leaves an
    // explicitly provided value untouched (e.g. test data backdating
    // a Lead to simulate an already-stagnant record).
    public static void stampLastModifiedDateOnInsert(
        List<Lead> newLeads
    ) {
        if (
            newLeads == null ||
            newLeads.isEmpty()
        ) {
            return;
        }

        List<Lead> leadsWithoutTimestamp = new List<Lead>();

        for (Lead leadRecord : newLeads) {
            if (leadRecord.Last_Modified_Date__c == null) {
                leadsWithoutTimestamp.add(leadRecord);
            }
        }

        applyActivityTimestamp(leadsWithoutTimestamp);
    }

    // Stamps the activity timestamp only on Leads where a
    // meaningful field (Status or Owner) actually changed, so
    // unrelated system updates don't reset the inactivity clock.
    public static void stampLastModifiedDateOnUpdate(
        List<Lead> newLeads,
        Map<Id, Lead> oldLeadMap
    ) {
        List<Lead> leadsWithActivityChange =
            LeadActivityHelper.filterLeadsWithActivityChange(
                newLeads,
                oldLeadMap
            );

        if (leadsWithActivityChange.isEmpty()) {
            return;
        }

        applyActivityTimestamp(leadsWithActivityChange);
    }

    // Applies the activity timestamp to the given Leads.
    // Trigger context handles persistence, so no DML here.
    private static void applyActivityTimestamp(
        List<Lead> leads
    ) {
        DateTime activityTimestamp =
            System.now();

        for (Lead leadRecord : leads) {

            leadRecord.Last_Modified_Date__c =
                activityTimestamp;
        }
    }
}
