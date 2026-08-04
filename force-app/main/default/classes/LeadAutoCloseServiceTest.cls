@IsTest
private class LeadAutoCloseServiceTest {

    private static final String CLOSED_STATUS = 'Closed - Not Converted';

    @IsTest
    static void testAutoCloseInactiveLeads_NullOrEmptyList() {

        Test.startTest();
        LeadAutoCloseService.autoCloseInactiveLeads(null);
        LeadAutoCloseService.autoCloseInactiveLeads(new List<Lead>());
        Test.stopTest();

        // No exception should be thrown for null or empty input.
        Assert.isTrue(true, 'Null and empty lists should be handled without errors');
    }

    @IsTest
    static void testAutoCloseInactiveLeads_UpdatesStatusAndReason() {

        Lead leadRecord = TestDataFactory.createLead();

        // insert only backfills Id on the in-memory record, so OwnerId
        // must be re-queried to exercise the notification-sending path.
        leadRecord = [
            SELECT Id, OwnerId, Status, IsConverted, Closure_Reason__c
            FROM Lead
            WHERE Id = :leadRecord.Id
        ];

        Test.startTest();
        LeadAutoCloseService.autoCloseInactiveLeads(
            new List<Lead>{ leadRecord }
        );
        Test.stopTest();

        Lead updatedLead = [
            SELECT Status, Closure_Reason__c
            FROM Lead
            WHERE Id = :leadRecord.Id
        ];

        Assert.areEqual(
            CLOSED_STATUS,
            updatedLead.Status,
            'Lead should be closed as Not Converted'
        );
        Assert.isNotNull(
            updatedLead.Closure_Reason__c,
            'Closure reason should be populated'
        );
    }

    @IsTest
    static void testAutoCloseInactiveLeads_BulkUpdate() {

        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 20; i++) {
            leads.add(TestDataFactory.createLead());
        }

        // Re-query so OwnerId is populated on the in-memory records.
        leads = [
            SELECT Id, OwnerId, Status, IsConverted, Closure_Reason__c
            FROM Lead
            WHERE Id IN :leads
        ];

        Test.startTest();
        LeadAutoCloseService.autoCloseInactiveLeads(leads);
        Test.stopTest();

        List<Lead> updatedLeads = [
            SELECT Status
            FROM Lead
            WHERE Id IN :leads
        ];

        for (Lead updatedLead : updatedLeads) {
            Assert.areEqual(
                CLOSED_STATUS,
                updatedLead.Status,
                'Every Lead in the batch should be closed as Not Converted'
            );
        }
    }

    // bagong custom field sa lead.
    // custom meta data store the statuses.
    // Testing batchable class the limit.
    // load testing
}
