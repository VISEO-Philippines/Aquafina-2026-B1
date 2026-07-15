public inherited sharing class LeadAutoCloseBatch
    implements Database.Batchable<SObject> {

    private static final Integer INACTIVITY_DAYS = 60;

    private static final String STATUS_CLOSED_NOT_CONVERTED =
        'Closed - Not Converted';

    private static final String STATUS_DISQUALIFIED =
        'Disqualified';

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

        // return successful batch ids for logging or future enhancements.
    }

    // Invoked after all batches have completed.
    // Reserved for future enhancements such as summary logging
    // or administrator notifications.
    public void finish(
        Database.BatchableContext batchContext
    ) {
        // No post-processing required.
        // logger batch id.
     }
}

