@IsTest
private class LeadAutoCloseBatchTest {

    private static final String STATUS_OPEN = 'Open - Not Contacted';

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
}
