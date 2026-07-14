public inherited sharing class LeadAutoCloseService {

    private static final String CLOSED_STATUS =
        'Closed - Not Converted';

    private static final String AUTO_CLOSURE_REASON =
        'Automatically closed after 60 days of inactivity.';

    private static final String LOG_TAG_LEAD_AUTO_CLOSE =
        'AP2-US-003';

    private static final String LOG_LEAD_AUTO_CLOSED =
        'Automatically closed {0} inactive Lead(s) after 60 days without activity.';

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

        logAutoClosedLeads(
            inactiveLeads
        );

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

    // Logs a single summary entry per batch chunk rather than one entry
    // per Lead, keeping the log volume proportionate to the operation.
    // Logging failures never affect the outcome of the closure.
    private static void logAutoClosedLeads(
        List<Lead> leads
    ) {
        try {
            Logger.info(
                String.format(
                    LOG_LEAD_AUTO_CLOSED,
                    new List<Object>{ leads.size() }
                )
            )
            .addTag(LOG_TAG_LEAD_AUTO_CLOSE);

            Logger.saveLog(
                Logger.SaveMethod.EVENT_BUS
            );
        } catch (Exception loggingException) {
            Logger.flushBuffer();

            System.debug(
                LoggingLevel.WARN,
                'Unable to save Lead auto-close log entries: ' +
                loggingException.getMessage()
            );
        }
    }
}