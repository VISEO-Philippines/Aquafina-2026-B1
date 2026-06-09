public class DealSummaryDTO {
   
    /*
     * Data Transfer Object used to package all deal summary data
     * into a single response for the LWC.
     * Keeps the UI layer decoupled from internal service and logic layers.
     */
    @AuraEnabled public Opportunity opportunity;
    @AuraEnabled public Quote quote;

    // Computed pricing values returned from the calculator
    @AuraEnabled public Decimal totalList;
    @AuraEnabled public Decimal totalDiscounted;
    @AuraEnabled public Decimal discountPercent;
    @AuraEnabled public Decimal vatAmount;
    @AuraEnabled public Decimal totalAmount;
    @AuraEnabled public Decimal totalQty;

    
    /*
     * Readiness status for different deal components.
     * Populated in the service layer after all data and calculations are completed.
     */
    @AuraEnabled public Map<String, String> readiness;

    
    
    /*
     * Constructor initializes core deal summary values.
     * Readiness is intentionally excluded since it depends on
     * additional evaluation logic handled in the service layer.
     */
    public DealSummaryDTO(
        Opportunity opportunity,
        Quote quote,
        Decimal totalList,
        Decimal totalDiscounted,
        Decimal discountPercent,
        Decimal vatAmount,
        Decimal totalAmount,
        Decimal totalQty
    ) {
        this.opportunity = opportunity;
        this.quote = quote;
        this.totalList = totalList;
        this.totalDiscounted = totalDiscounted;
        this.discountPercent = discountPercent;
        this.vatAmount = vatAmount;
        this.totalAmount = totalAmount;
        this.totalQty = totalQty;
    }
}
