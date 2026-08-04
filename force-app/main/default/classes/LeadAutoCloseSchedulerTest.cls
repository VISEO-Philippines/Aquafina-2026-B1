@IsTest
private class LeadAutoCloseSchedulerTest {

    @IsTest
    static void testScheduler_ExecutesBatch() {

        String cronExpression = '0 0 2 * * ?';

        Test.startTest();
        String jobId = System.schedule(
            'Lead Auto Close Nightly Job Test',
            cronExpression,
            new LeadAutoCloseScheduler()
        );
        Test.stopTest();

        CronTrigger triggerRecord = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        Assert.areEqual(
            cronExpression,
            triggerRecord.CronExpression,
            'Scheduled job should use the configured cron expression'
        );
    }
}
