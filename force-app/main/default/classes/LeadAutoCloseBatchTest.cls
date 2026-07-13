@IsTest
private class LeadAutoCloseBatchTest {

    // ─── Test Setup ──────────────────────────────────────────────────────────
    // LastModifiedDate cannot be backdated in Apex tests (Test.setCreatedDate
    // only affects CreatedDate), so "stagnant" vs "recent" is simulated by
    // injecting the batch's cutoffDate relative to "now" instead of faking
    // the Lead's audit fields.

    @TestSetup
    static void setupData() {
        TestDataFactory.createSalesRepUser();
    }

    private static User getSalesRep() {
        return [SELECT Id FROM User WHERE LastName = 'TestUser' LIMIT 1];
    }

    private static Lead getLead(String lastName) {
        return [SELECT Id, Status, IsConverted, Auto_Close_Reason__c FROM Lead WHERE LastName = :lastName LIMIT 1];
    }

    // ─── Stagnant vs Recent ──────────────────────────────────────────────────

    @IsTest
    static void execute_closesLeadWhenCutoffIsInTheFuture() {
        Lead ld = TestDataFactory.createLead('Stagnant', 'ToContact', getSalesRep().Id);

        Test.startTest();
        Database.executeBatch(new LeadAutoCloseBatch(Date.today().addDays(1)));
        Test.stopTest();

        Lead result = getLead('Stagnant');
        Assert.areEqual(LeadAutoCloseService.CLOSED_STATUS, result.Status, 'A cutoff after LastModifiedDate should mark the Lead stagnant and close it');
        Assert.isNotNull(result.Auto_Close_Reason__c, 'Closure reason should be populated');
    }

    @IsTest
    static void execute_leavesRecentLeadUntouchedWhenCutoffIsInThePast() {
        TestDataFactory.createLead('Recent', 'ToContact', getSalesRep().Id);

        Test.startTest();
        Database.executeBatch(new LeadAutoCloseBatch(Date.today().addDays(-1)));
        Test.stopTest();

        Lead result = getLead('Recent');
        Assert.areEqual('ToContact', result.Status, 'A cutoff before LastModifiedDate should leave the Lead untouched');
        Assert.isNull(result.Auto_Close_Reason__c, 'Closure reason should not be set for an untouched Lead');
    }

    // ─── Exclusions ──────────────────────────────────────────────────────────

    @IsTest
    static void execute_excludesDisqualifiedLead() {
        TestDataFactory.createLead('AlreadyDisqualified', 'Disqualified', getSalesRep().Id);

        Test.startTest();
        Database.executeBatch(new LeadAutoCloseBatch(Date.today().addDays(1)));
        Test.stopTest();

        Lead result = getLead('AlreadyDisqualified');
        Assert.areEqual('Disqualified', result.Status, 'Disqualified Leads should be left alone by the auto-close job');
    }

    @IsTest
    static void execute_excludesAlreadyClosedLead() {
        TestDataFactory.createLead('AlreadyClosed', 'ClosedNotConverted', getSalesRep().Id);

        Test.startTest();
        Database.executeBatch(new LeadAutoCloseBatch(Date.today().addDays(1)));
        Test.stopTest();

        Lead result = getLead('AlreadyClosed');
        Assert.areEqual('ClosedNotConverted', result.Status, 'Already-closed Leads should not be reprocessed');
        Assert.isNull(result.Auto_Close_Reason__c, 'Reason should not be (re)written for a Lead the job never touched');
    }

    @IsTest
    static void execute_excludesConvertedLead() {
        Lead ld = TestDataFactory.createLead('ToConvert', 'ToContact', getSalesRep().Id);

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Assert.isTrue(lcr.isSuccess(), 'Lead conversion must succeed for this test to be meaningful');

        Test.startTest();
        Database.executeBatch(new LeadAutoCloseBatch(Date.today().addDays(1)));
        Test.stopTest();

        Lead result = getLead('ToConvert');
        Assert.isTrue(result.IsConverted, 'Lead should remain converted');
        Assert.areEqual('Qualified', result.Status, 'Converted Leads should never be auto-closed');
    }
}
