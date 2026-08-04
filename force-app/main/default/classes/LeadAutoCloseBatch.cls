public inherited sharing class LeadAutoCloseBatch
    implements Database.Batchable<SObject>,
               Database.Stateful {

    private static final String STATUS_CLOSED_NOT_CONVERTED =
        'Closed - Not Converted';

    private static final String STATUS_DISQUALIFIED =
        'Disqualified';

    private static final String LOG_TAG_AUTO_CLOSE =
        'AP2-US-003';

    private static final String LOG_TAG_BATCH =
        'Lead Auto Close';

    private static final String LOG_BATCH_COMPLETED =
        'Lead auto-close batch completed successfully.';

    private Integer processedLeadCount = 0;

    // Retrieves all Leads eligible for automatic closure.
    public Database.QueryLocator start(
        Database.BatchableContext batchContext
    ) {
        Integer inactivityDays =
            LeadAutoCloseConfigSelector.getInactivityDays();

        DateTime cutoffDate =
            System.now().addDays(-inactivityDays);

        return LeadSelector.getStagnantOpenLeadsQueryLocator(
            cutoffDate,
            new Set<String>{
                STATUS_DISQUALIFIED,
                STATUS_CLOSED_NOT_CONVERTED
            }
        );
    }

    // Processes each batch of inactive Leads by delegating
    // the business logic to the service layer.
    public void execute(
        Database.BatchableContext batchContext,
        List<SObject> scope
    ) {
        List<Lead> leads =
            (List<Lead>) scope;

        LeadAutoCloseService.autoCloseInactiveLeads(
            leads
        );

        processedLeadCount += leads.size();
    }

    // Logs a summary after all batch chunks have completed
    // successfully. Logging failures must never affect the
    // completed batch execution.
    public void finish(
        Database.BatchableContext batchContext
    ) {
        try {
            Logger.info(
                LOG_BATCH_COMPLETED +
                ' Processed ' +
                processedLeadCount +
                ' Lead records.'
            )
            .addTag(LOG_TAG_AUTO_CLOSE)
            .addTag(LOG_TAG_BATCH);

            Logger.saveLog(
                Logger.SaveMethod.EVENT_BUS
            );
        } catch (Exception loggingException) {

            Logger.flushBuffer();

            System.debug(
                LoggingLevel.WARN,
                'Unable to save Lead auto-close batch log: ' +
                loggingException.getMessage()
            );
        }
    }
}