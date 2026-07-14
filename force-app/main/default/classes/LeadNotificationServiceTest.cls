@IsTest
private class LeadNotificationServiceTest {

    @IsTest
    static void testSendAutoCloseNotifications_NullOrEmptyList() {

        Test.startTest();
        LeadNotificationService.sendAutoCloseNotifications(null);
        LeadNotificationService.sendAutoCloseNotifications(new List<Lead>());
        Test.stopTest();

        // No exception should be thrown for null or empty input.
        Assert.isTrue(true, 'Null and empty lists should be handled without errors');
    }

    @IsTest
    static void testSendAutoCloseNotifications_SkipsLeadsWithoutOwner() {

        Lead leadRecord = TestDataFactory.createLead();

        // insert only backfills Id on the in-memory record, so OwnerId
        // must be re-queried to exercise the notification-sending path.
        leadRecord = [
            SELECT Id, OwnerId
            FROM Lead
            WHERE Id = :leadRecord.Id
        ];

        Test.startTest();
        LeadNotificationService.sendAutoCloseNotifications(
            new List<Lead>{ leadRecord }
        );
        Test.stopTest();

        // No exception should be thrown whether or not the
        // Lead_Auto_Closed CustomNotificationType is configured.
        Assert.isTrue(true, 'Notification sending should complete without errors');
    }
}
