global inherited sharing class LeadAutoCloseScheduler
    implements Schedulable {

    // Executes the nightly Lead auto-close batch.
    global void execute(
        SchedulableContext context
    ) {
        Database.executeBatch(
            new LeadAutoCloseBatch()
        );
    }
}