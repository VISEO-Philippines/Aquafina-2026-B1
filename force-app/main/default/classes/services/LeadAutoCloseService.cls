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
     * @return the number of Leads actually closed (may be less than scope.size()
     *         if some records failed to save)
     */
    public Integer closeStagnantLeads(List<Lead> scope) {
        if (scope == null || scope.isEmpty()) {
            return 0;
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
                List<String> errorMessages = new List<String>();
                for (Database.Error err : results[i].getErrors()) {
                    errorMessages.add(err.getMessage());
                }
                Logger.error('LeadAutoCloseService: failed to auto-close Lead - '
                        + String.join(errorMessages, '; ')).setRecord(scope[i]);
            }
        }

        notifyOwners(closedLeads);
        Logger.saveLog();
        return closedLeads.size();
    }

    private String buildClosureReason(Lead ld) {
        return 'Automatically closed by nightly cleanup job on ' + Date.today().format()
                + ' (no updates since ' + ld.LastModifiedDate.date().format() + ').';
    }

    /**
     * Sends one in-app custom notification per owner, listing every Lead of
     * theirs that was closed. Leads are grouped by owner instead of notifying
     * once per Lead so a single large batch chunk can't drive send() calls
     * past the org's custom notification limits. Queue/Group-owned Leads are
     * skipped since custom notifications can only target Users. A failure to
     * notify never blocks or rolls back the Lead closure that already happened.
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

        Map<Id, List<Lead>> closedLeadsByOwnerId = new Map<Id, List<Lead>>();
        for (Lead ld : closedLeads) {
            if (ld.Owner.Type != OWNER_TYPE_USER) {
                continue;
            }
            if (!closedLeadsByOwnerId.containsKey(ld.OwnerId)) {
                closedLeadsByOwnerId.put(ld.OwnerId, new List<Lead>());
            }
            closedLeadsByOwnerId.get(ld.OwnerId).add(ld);
        }

        for (Id ownerId : closedLeadsByOwnerId.keySet()) {
            List<Lead> ownerLeads = closedLeadsByOwnerId.get(ownerId);
            try {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle(NOTIF_TITLE);
                notification.setBody(buildNotificationBody(ownerLeads));
                notification.setNotificationTypeId(notificationTypeId);
                notification.send(new Set<String>{ ownerId });
            } catch (Exception e) {
                Logger.warn('LeadAutoCloseService: failed to notify owner of auto-closed Leads - ' + e.getMessage())
                        .setRecord(ownerLeads[0]);
            }
        }
    }

    private String buildNotificationBody(List<Lead> ownerLeads) {
        List<String> leadNames = new List<String>();
        for (Lead ld : ownerLeads) {
            leadNames.add(ld.Name);
        }
        return String.format(
            'The following Lead(s) were automatically closed after 60 days of inactivity:\n\n{0}',
            new List<String>{ String.join(leadNames, '\n') }
        );
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
