public class DealSummaryService {
    
    
    /*
     * Orchestrates the full deal summary process:
     * 1. Retrieves Opportunity, Quote, and Quote Line Items
     * 2. Performs pricing calculations
     * 3. Evaluates deal readiness
     * 4. Returns a fully populated DTO for UI consumption
     */
    public static DealSummaryDTO getDealSummary(Id opportunityId) {

         // Retrieve core data required for the deal summary
        Opportunity opp = DealSummarySelector.getOpportunity(opportunityId);
        Quote quote = DealSummarySelector.getPrimaryQuote(opportunityId);

        // Retrieve line items only if a quote exists to avoid null reference errors
        List<QuoteLineItem> qlis = 
            quote != null ? DealSummarySelector.getQuoteLineItems(quote.Id) : new List<QuoteLineItem>();
            

        // Perform pricing calculations based on quote and line items
        DealSummaryCalculator.CalculationResult calc =
            DealSummaryCalculator.calculate(qlis, quote);
        
        
        // Evaluate readiness using all relevant data and computed values
        // This is done in the service layer to keep the DTO free of business logic
        Map<String, String> readiness =
            DealReadinessService.evaluate(quote, qlis, opportunityId, calc);//

        
        // Construct DTO with calculated values
        // DTO acts strictly as a data carrier to maintain separation of concerns
        DealSummaryDTO result = new DealSummaryDTO(
            opp,
            quote,
            calc.totalList,
            calc.totalDiscounted,
            calc.discountPercent,
            calc.vatAmount,
            calc.totalAmount,
            calc.totalQty
        );
        
        
        // Assign readiness after construction since it depends on computed values
        // Keeping it outside the constructor avoids unnecessary coupling and keeps it simple
        result.readiness = readiness;
        return result;
    }
}
