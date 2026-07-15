public inherited sharing class LeadNotificationService {

    private static final String NOTIFICATION_TITLE =
        'Lead Automatically Closed';

    private static final String NOTIFICATION_BODY =
        'This Lead was automatically closed after 60 days of inactivity.';

    public static void sendAutoCloseNotifications(
        List<Lead> leads
    ) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        CustomNotificationType notificationType =
            NotificationSelector.getLeadAutoClosedNotificationType(); //

        if (notificationType == null) {
            return;
        }

        for (Lead leadRecord : leads) {

            if (leadRecord.OwnerId == null) {
                continue;
            }

            sendNotification(
                notificationType.Id,
                leadRecord
            );
        }
    }

    private static void sendNotification(
        Id notificationTypeId,
        Lead leadRecord
    ) {
        Messaging.CustomNotification notification =
            new Messaging.CustomNotification();

        notification.setNotificationTypeId(
            notificationTypeId
        );

        notification.setTitle(
            NOTIFICATION_TITLE
        );

        notification.setBody(
            NOTIFICATION_BODY
        );

        notification.setTargetId(
            leadRecord.Id
        );

        notification.send(
            new Set<String>{ leadRecord.OwnerId }
        );
    }
}