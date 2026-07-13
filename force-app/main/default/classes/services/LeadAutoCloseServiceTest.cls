@IsTest
private class LeadAutoCloseServiceTest {

    // ─── Test Setup ──────────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        TestDataFactory.createSalesRepUser();
    }

    private static User getSalesRep() {
        return [SELECT Id FROM User WHERE LastName = 'TestUser' LIMIT 1];
    }

    private static Group createLeadQueue() {
        Group queueGroup;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queueGroup = new Group(Name = 'Test Lead Queue ' + Datetime.now().getTime(), Type = 'Queue');
            insert queueGroup;
            insert new QueueSobject(QueueId = queueGroup.Id, SobjectType = 'Lead');
        }
        return queueGroup;
    }

    // The service reads LastModifiedDate/Owner.Type off the Leads it's given
    // (normally populated by LeadSelector's query), so fixtures used to call
    // closeStagnantLeads directly must be re-queried after insert rather than
    // reusing the bare DML-returned sObject.
    private static Lead requeryLead(Id leadId) {
        return [SELECT Id, Name, Status, OwnerId, Owner.Type, LastModifiedDate, IsConverted FROM Lead WHERE Id = :leadId];
    }

    // ─── closeStagnantLeads ──────────────────────────────────────────────────

    @IsTest
    static void closeStagnantLeads_closesLeadAndSetsReason() {
        User salesRep = getSalesRep();
        Lead ld = requeryLead(TestDataFactory.createLead('Stagnant', 'ToContact', salesRep.Id).Id);

        Test.startTest();
        new LeadAutoCloseService().closeStagnantLeads(new List<Lead>{ ld });
        Test.stopTest();

        Lead closed = [SELECT Status, Auto_Close_Reason__c FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual(LeadAutoCloseService.CLOSED_STATUS, closed.Status, 'Lead should be closed');
        Assert.isTrue(
            closed.Auto_Close_Reason__c != null && closed.Auto_Close_Reason__c.contains('Automatically closed'),
            'Auto_Close_Reason__c should describe why the Lead was closed'
        );
    }

    @IsTest
    static void closeStagnantLeads_closesQueueOwnedLeadWithoutError() {
        Group queue = createLeadQueue();
        Lead ld = requeryLead(TestDataFactory.createLead('QueueOwned', 'InProgress', queue.Id).Id);

        Test.startTest();
        new LeadAutoCloseService().closeStagnantLeads(new List<Lead>{ ld });
        Test.stopTest();

        Lead closed = [SELECT Status FROM Lead WHERE Id = :ld.Id];
        Assert.areEqual(
            LeadAutoCloseService.CLOSED_STATUS,
            closed.Status,
            'Lead should still be closed even though notification is skipped for a queue owner'
        );
    }

    @IsTest
    static void closeStagnantLeads_handlesNullAndEmptyListGracefully() {
        Test.startTest();
        new LeadAutoCloseService().closeStagnantLeads(null);
        new LeadAutoCloseService().closeStagnantLeads(new List<Lead>());
        Test.stopTest();
        // No exception thrown is the assertion here
    }

    // ─── Constructor ─────────────────────────────────────────────────────────

    @IsTest
    static void constructor_throwsForNullSelector() {
        try {
            new LeadAutoCloseService(null);
            Assert.fail('Expected IllegalArgumentException for a null LeadSelector');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('leadSelector'), 'Exception should mention the null dependency');
        }
    }
}
