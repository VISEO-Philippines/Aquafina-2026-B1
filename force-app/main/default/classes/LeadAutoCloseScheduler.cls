/**
 * Nightly cron entry point for AP2-US-0003. Kicks off LeadAutoCloseBatch.
 * Scheduled via anonymous Apex (no source representation for CronTrigger):
 *   System.schedule('Nightly Lead Auto-Close', '0 0 1 * * ?', new LeadAutoCloseScheduler());
 */
public without sharing class LeadAutoCloseScheduler implements Schedulable {

    private static final Integer BATCH_SIZE = 200;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadAutoCloseBatch(), BATCH_SIZE);
    }
}
