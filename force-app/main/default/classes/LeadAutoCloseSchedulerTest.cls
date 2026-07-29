@IsTest
private class LeadAutoCloseSchedulerTest {

    @IsTest
    static void execute_enqueuesLeadAutoCloseBatch() {
        Test.startTest();
        String jobId = System.schedule('Nightly Lead Auto-Close Test', '0 0 1 * * ?', new LeadAutoCloseScheduler());
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name, JobType
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'LeadAutoCloseBatch'
        ];
        Assert.areEqual(1, jobs.size(), 'The scheduler should have enqueued exactly one LeadAutoCloseBatch run');
    }
}
