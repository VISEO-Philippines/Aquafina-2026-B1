public inherited sharing class LeadAutoCloseBatch
    implements Database.Batchable<SObject> {

    private static final Integer INACTIVITY_DAYS = 60;

    private static final String STATUS_CLOSED_NOT_CONVERTED =
        'Closed - Not Converted';

    private static final String STATUS_DISQUALIFIED =
        'Disqualified';

    private static final String LOG_TAG_LEAD_AUTO_CLOSE =
        'AP2-US-003';

    private static final String LOG_BATCH_SUMMARY =
        'Lead auto-close batch finished. Processed {0} of {1} batch(es) ' +
        'with {2} error(s).';

    // Retrieves all Leads eligible for automatic closure.
    public Database.QueryLocator start(
        Database.BatchableContext batchContext
    ) {
        DateTime cutoffDate =
            System.now().addDays(-INACTIVITY_DAYS);

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
        LeadAutoCloseService.autoCloseInactiveLeads(
            (List<Lead>) scope
        );
    }

    // Invoked after all batches have completed. Logs a summary of the
    // job outcome without allowing logging failures to surface as errors.
    public void finish(
        Database.BatchableContext batchContext
    ) {
        try {
            AsyncApexJob job = [
                SELECT
                    JobItemsProcessed,
                    TotalJobItems,
                    NumberOfErrors
                FROM AsyncApexJob
                WHERE Id = :batchContext.getJobId()
            ];

            String summary = String.format(
                LOG_BATCH_SUMMARY,
                new List<Object>{
                    job.JobItemsProcessed,
                    job.TotalJobItems,
                    job.NumberOfErrors
                }
            );

            // Surfaces failed batches as errors so they are actionable,
            // while a clean run is only informational.
            if (job.NumberOfErrors > 0) {
                Logger.error(summary).addTag(LOG_TAG_LEAD_AUTO_CLOSE);
            } else {
                Logger.info(summary).addTag(LOG_TAG_LEAD_AUTO_CLOSE);
            }

            Logger.saveLog(
                Logger.SaveMethod.EVENT_BUS
            );
        } catch (Exception loggingException) {
            Logger.flushBuffer();

            System.debug(
                LoggingLevel.WARN,
                'Unable to save Lead auto-close batch summary log: ' +
                loggingException.getMessage()
            );
        }
    }
}