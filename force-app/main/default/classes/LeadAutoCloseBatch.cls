/**
 * Nightly batch for AP2-US-0003: scans every Lead in the org and auto-closes
 * the ones that have been stagnant (not updated) for 60 days or more.
 * Scheduled to run via LeadAutoCloseScheduler.
 */
public without sharing class LeadAutoCloseBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer STAGNANT_DAYS = 60;

    private Integer closedCount = 0;
    private Date cutoffDate;

    public LeadAutoCloseBatch() {
        this.cutoffDate = Date.today().addDays(-STAGNANT_DAYS);
    }

    /**
     * Allows tests to control which Leads count as stagnant without having
     * to fake LastModifiedDate (a system audit field Apex cannot backdate).
     */
    @TestVisible
    private LeadAutoCloseBatch(Date cutoffDate) {
        this.cutoffDate = cutoffDate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return new LeadSelector().getStagnantLeadsQueryLocator(this.cutoffDate);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Lead> leads = (List<Lead>) scope;
        new LeadAutoCloseService().closeStagnantLeads(leads);
        closedCount += leads.size();
    }

    public void finish(Database.BatchableContext bc) {
        Logger.info('LeadAutoCloseBatch: processed ' + closedCount + ' stagnant Lead(s)');
        Logger.saveLog();
    }
}
