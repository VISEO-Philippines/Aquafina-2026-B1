public inherited sharing class LeadNotificationService {

    private static final String NOTIFICATION_TITLE =
        'Lead Automatically Closed';

    private static final String NOTIFICATION_BODY =
        'This Lead was automatically closed after 60 days of inactivity.';

    private static final String LOG_TAG_LEAD_AUTO_CLOSE =
        'AP2-US-003';

    private static final String LOG_NOTIFICATION_TYPE_MISSING =
        'Lead_Auto_Closed CustomNotificationType is not configured; ' +
        'skipping auto-close notifications.';

    private static final String LOG_NOTIFICATION_SEND_FAILED =
        'Unable to send Lead auto-close notification.';

    public static void sendAutoCloseNotifications(
        List<Lead> leads
    ) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        CustomNotificationType notificationType =
            NotificationSelector.getLeadAutoClosedNotificationType();

        if (notificationType == null) {
            Logger.warn(
                LOG_NOTIFICATION_TYPE_MISSING
            )
            .addTag(LOG_TAG_LEAD_AUTO_CLOSE);

            Logger.saveLog(
                Logger.SaveMethod.EVENT_BUS
            );

            return;
        }

        Integer failureCount = 0;

        for (Lead leadRecord : leads) {

            if (leadRecord.OwnerId == null) {
                continue;
            }

            Boolean notificationSent = sendNotification(
                notificationType.Id,
                leadRecord
            );

            if (!notificationSent) {
                failureCount++;
            }
        }

        // Only publish log entries when there is something worth
        // surfacing, avoiding a platform event publish on the common,
        // fully-successful path.
        if (failureCount > 0) {
            Logger.saveLog(
                Logger.SaveMethod.EVENT_BUS
            );
        }
    }

    // Returns whether the notification was sent successfully so the
    // caller can decide whether a log entry needs to be published.
    private static Boolean sendNotification(
        Id notificationTypeId,
        Lead leadRecord
    ) {
        try {
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

            return true;
        } catch (Exception notificationException) {
            Logger.error(
                LOG_NOTIFICATION_SEND_FAILED,
                leadRecord.Id
            )
            .addTag(LOG_TAG_LEAD_AUTO_CLOSE)
            .setExceptionDetails(notificationException);

            return false;
        }
    }
}