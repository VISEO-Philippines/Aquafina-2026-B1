public inherited sharing class NotificationSelector {

    private static final String LEAD_AUTO_CLOSED_NOTIFICATION =
        'Lead_Auto_Closed';

    public static CustomNotificationType
        getLeadAutoClosedNotificationType() {

        List<CustomNotificationType> notificationTypes = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :LEAD_AUTO_CLOSED_NOTIFICATION
            LIMIT 1
        ];

        return notificationTypes.isEmpty()
            ? null
            : notificationTypes[0];
    }
}