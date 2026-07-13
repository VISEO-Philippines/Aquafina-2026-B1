/**
 * Implements the nightly stagnant-lead cleanup for AP2-US-0003.
 * Leads that have not been updated in 60 days are auto-closed to
 * 'ClosedNotConverted', have a closure reason recorded, and their
 * owner is notified in-app. Converted, Disqualified, and already
 * closed Leads are left alone (filtered out by LeadSelector).
 * Runs without sharing since this is a system-level cleanup job that
 * must act on every stagnant Lead in the org, not just what the
 * scheduling user can see.
 */
public without sharing class LeadAutoCloseService {

    @TestVisible
    private static final String CLOSED_STATUS = 'ClosedNotConverted';
    private static final String NOTIF_TYPE_DEVELOPER_NAME = 'Lead_Auto_Closed';
    private static final String NOTIF_TITLE = 'Lead Auto-Closed';
    private static final String OWNER_TYPE_USER = 'User';

    private static Id cachedNotificationTypeId;

    private LeadSelector leadSelector;

    public LeadAutoCloseService() {
        this.leadSelector = new LeadSelector();
    }

    public LeadAutoCloseService(LeadSelector leadSelector) {
        if (leadSelector == null) {
            throw new IllegalArgumentException('leadSelector must not be null');
        }
        this.leadSelector = leadSelector;
    }

    /**
     * Closes every stagnant Lead in scope: sets Status and Auto_Close_Reason__c,
     * saves partial success so one bad record doesn't block the rest of the
     * batch chunk, then notifies the owners of the Leads that were closed.
     *
     * @param scope A chunk of stagnant Lead records (typically from LeadAutoCloseBatch)
     */
    public void closeStagnantLeads(List<Lead> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        for (Lead ld : scope) {
            ld.Status = CLOSED_STATUS;
            ld.Auto_Close_Reason__c = buildClosureReason(ld);
        }

        List<Database.SaveResult> results = Database.update(scope, false);

        List<Lead> closedLeads = new List<Lead>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                closedLeads.add(scope[i]);
            } else {
                Logger.error('LeadAutoCloseService: failed to auto-close Lead - '
                        + results[i].getErrors()[0].getMessage()).setRecord(scope[i]);
            }
        }

        notifyOwners(closedLeads);
        Logger.saveLog();
    }

    private String buildClosureReason(Lead ld) {
        return 'Automatically closed by nightly cleanup job on ' + Date.today().format()
                + ' (no updates since ' + ld.LastModifiedDate.date().format() + ').';
    }

    /**
     * Sends an in-app custom notification to the owner of each closed Lead.
     * Queue/Group-owned Leads are skipped since custom notifications can
     * only target Users. A failure to notify never blocks or rolls back
     * the Lead closure that already happened.
     */
    private void notifyOwners(List<Lead> closedLeads) {
        if (closedLeads.isEmpty()) {
            return;
        }

        Id notificationTypeId = getNotificationTypeId();
        if (notificationTypeId == null) {
            Logger.warn('LeadAutoCloseService: Lead_Auto_Closed CustomNotificationType not found - skipping notifications');
            return;
        }

        for (Lead ld : closedLeads) {
            if (ld.Owner.Type != OWNER_TYPE_USER) {
                continue;
            }
            try {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(NOTIF_TITLE);
                notification.setBody(ld.Name + ' was automatically closed after 60 days of inactivity.');
                notification.setNotificationTypeId(notificationTypeId);
                notification.setTargetId(ld.Id);
                notification.send(new Set<String>{ ld.OwnerId });
            } catch (Exception e) {
                Logger.warn('LeadAutoCloseService: failed to notify owner of auto-closed Lead - ' + e.getMessage())
                        .setRecord(ld);
            }
        }
    }

    private Id getNotificationTypeId() {
        if (cachedNotificationTypeId == null) {
            List<CustomNotificationType> types = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = :NOTIF_TYPE_DEVELOPER_NAME
                LIMIT 1
            ];
            cachedNotificationTypeId = types.isEmpty() ? null : types[0].Id;
        }
        return cachedNotificationTypeId;
    }
}
