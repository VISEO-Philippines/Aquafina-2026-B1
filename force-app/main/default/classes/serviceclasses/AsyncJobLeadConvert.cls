public with sharing class AsyncJobLeadConvert implements Queueable {
    private List<Id> leadIds;

    public AsyncJobLeadConvert(List<Id> leadIds) {
        this.leadIds = leadIds;
    }

    public void execute(QueueableContext context) {
        LeadService.convertHotLeads(leadIds);
    }

}