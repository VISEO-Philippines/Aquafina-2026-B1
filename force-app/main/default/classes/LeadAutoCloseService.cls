public inherited sharing class LeadAutoCloseService {

    private static final String CLOSED_STATUS =
        'Closed - Not Converted';

    private static final String AUTO_CLOSURE_REASON =
        'Automatically closed after 60 days of inactivity.';

    // Automatically closes inactive Leads by updating their Status
    // and recording the reason for automatic closure.
    public static void autoCloseInactiveLeads(
        List<Lead> inactiveLeads
    ) {
        if (
            inactiveLeads == null ||
            inactiveLeads.isEmpty()
        ) {
            return;
        }

        applyAutomaticClosure(
            inactiveLeads
        );

        update inactiveLeads;

        // Sends an in-app notification to each Lead owner after
        // the automatic closure has been successfully completed.
        LeadNotificationService.sendAutoCloseNotifications(
            inactiveLeads
        );
    }

    // Applies the automatic closure values before performing
    // the database update.
    private static void applyAutomaticClosure(
        List<Lead> leads
    ) {
        for (Lead leadRecord : leads) {

            leadRecord.Status =
                CLOSED_STATUS;

            leadRecord.Closure_Reason__c =
                AUTO_CLOSURE_REASON;
        }
    }
}