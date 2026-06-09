public with sharing class DealSummaryController {
    
    
    /*
     * Acts as the entry point for LWC requests.
     * Delegates data retrieval and business logic to the service layer
     * to maintain separation of concerns and keep the controller lightweight.
     */
    @AuraEnabled(cacheable=true)
    public static DealSummaryDTO getDealSummary(Id opportunityId) {
        return DealSummaryService.getDealSummary(opportunityId);
    }

}
