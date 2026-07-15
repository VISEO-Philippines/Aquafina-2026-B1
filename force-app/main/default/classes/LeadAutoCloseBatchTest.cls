@IsTest
private class LeadAutoCloseBatchTest {

    private static final String STATUS_OPEN = 'Open - Not Contacted';

    private static final String STATUS_CLOSED_NOT_CONVERTED =
        'Closed - Not Converted';

    private static final Integer FULL_CHUNK_SIZE = 200;

    @IsTest
    static void testBatch_DoesNotCloseRecentlyModifiedLeads() {

        // Apex tests cannot backdate LastModifiedDate, so a freshly
        // inserted Lead never satisfies the 60-day inactivity cutoff.
        // This confirms the batch runs end-to-end and leaves
        // recently modified Leads untouched.
        Lead recentLead = TestDataFactory.createLead(STATUS_OPEN);

        Test.startTest();
        Database.executeBatch(new LeadAutoCloseBatch());
        Test.stopTest();

        Lead updatedLead = [
            SELECT Status
            FROM Lead
            WHERE Id = :recentLead.Id
        ];

        Assert.areEqual(
            STATUS_OPEN,
            updatedLead.Status,
            'Recently modified Lead should not be closed by the batch'
        );
    }

    
    @IsTest
    static void testBatch_ExecuteHandlesFullChunkVolume() {

        List<Lead> leads = createLeads(FULL_CHUNK_SIZE);

        Integer dmlStatementsBefore = Limits.getDmlStatements();

        Test.startTest();
        try {
            new LeadAutoCloseBatch().execute(null, leads);
        } catch (Exception e) {
            Assert.fail(
                'execute() threw at ' + leads.size() + ' records: ' +
                    e.getTypeName() + ' - ' + e.getMessage() +
                    ' | limits at failure -- DML statements: ' +
                    Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements() +
                    ', DML rows: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows() +
                    ', SOQL queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries() +
                    ', CPU time: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime()
            );
        }
        Test.stopTest();

        Integer dmlStatementsUsed =
            Limits.getDmlStatements() - dmlStatementsBefore;

        Assert.isTrue(
            dmlStatementsUsed <= 2,
            'Closing a full chunk should stay bulkified (used ' +
                dmlStatementsUsed + ' DML statements)'
        );

        List<Lead> updatedLeads = [
            SELECT Status, Closure_Reason__c
            FROM Lead
            WHERE Id IN :leads
        ];

        Assert.areEqual(
            FULL_CHUNK_SIZE,
            updatedLeads.size(),
            'All Leads in the chunk should have been queried back'
        );

        for (Lead updatedLead : updatedLeads) {
            Assert.areEqual(
                STATUS_CLOSED_NOT_CONVERTED,
                updatedLead.Status,
                'Every Lead in a full chunk should be closed as Not Converted'
            );
            Assert.isNotNull(
                updatedLead.Closure_Reason__c,
                'Closure reason should be populated for every Lead in the chunk'
            );
        }
    }

    // Load test: exercises the real start() -> execute() -> finish()
    // lifecycle through Database.executeBatch(), instead of calling
    // execute() directly. This is the first test able to stress the
    // actual query locator, since Last_Modified_Date__c (unlike the
    // standard LastModifiedDate) can be backdated in a test.
    //
    // Test context only allows a single execute() invocation per test
    // method regardless of scope size, so multiple real chunks can't be
    // simulated here -- this instead runs the maximum possible single
    // chunk (2,000, the largest batch scope Apex allows) to surface
    // per-chunk governor limits (DML, CPU time, notification fan-out)
    // at the worst case a production run could ever hit in one chunk.
    @IsTest
    static void testBatch_HandlesMaxScopeChunk() {

        Integer totalLeads = 2000;

        DateTime stagnantTimestamp =
            System.now().addDays(-61);

        List<Lead> leads = createStagnantLeads(
            totalLeads,
            stagnantTimestamp
        );

        Test.startTest();
        Database.executeBatch(
            new LeadAutoCloseBatch(),
            totalLeads
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT
                NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems,
                ExtendedStatus
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'LeadAutoCloseBatch'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        Assert.isFalse(
            jobs.isEmpty(),
            'LeadAutoCloseBatch job should have run'
        );

        Assert.areEqual(
            0,
            jobs[0].NumberOfErrors,
            'No batch chunk should error out: ' + jobs[0].ExtendedStatus
        );

        Integer closedCount = [
            SELECT COUNT()
            FROM Lead
            WHERE Id IN :leads
            AND Status = :STATUS_CLOSED_NOT_CONVERTED
        ];

        Assert.areEqual(
            totalLeads,
            closedCount,
            'Every stagnant Lead across all chunks should be closed'
        );
    }

    // Builds and inserts `count` Leads in a single DML statement.
    // Looping TestDataFactory.createLead() would burn one DML statement
    // per Lead and exceed the 150-statement test limit at this volume.
    private static List<Lead> createLeads(Integer count) {
        List<Lead> leads = new List<Lead>();

        for (Integer i = 0; i < count; i++) {
            String unique = String.valueOf(i) + '-' +
                String.valueOf(System.currentTimeMillis());

            leads.add(new Lead(
                LastName = 'Load Test Lead ' + unique,
                Company = 'Load Test Company ' + unique,
                Status = STATUS_OPEN
            ));
        }

        insert leads;

        // insert only backfills Id on the in-memory records, so OwnerId
        // must be re-queried to exercise the notification-sending path.
        return [
            SELECT Id, OwnerId, Status, IsConverted, Closure_Reason__c
            FROM Lead
            WHERE Id IN :leads
        ];
    }

    // Builds and inserts `count` Leads with Last_Modified_Date__c
    // explicitly backdated, so start()'s query locator actually
    // picks them up as stagnant -- LeadTriggerHandler only defaults
    // the field when it's left blank, so an explicit value here is
    // preserved through insert.
    private static List<Lead> createStagnantLeads(
        Integer count,
        DateTime lastModifiedDate
    ) {
        List<Lead> leads = new List<Lead>();

        for (Integer i = 0; i < count; i++) {
            String unique = String.valueOf(i) + '-' +
                String.valueOf(System.currentTimeMillis());

            leads.add(new Lead(
                LastName = 'Load Test Lead ' + unique,
                Company = 'Load Test Company ' + unique,
                Status = STATUS_OPEN,
                Last_Modified_Date__c = lastModifiedDate
            ));
        }

        insert leads;

        return leads;
    }
}
