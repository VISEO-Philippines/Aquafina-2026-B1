public class DealReadinessService {
    
    /*
     * Evaluates whether a deal meets key readiness criteria.
     * Encapsulates business rules to determine if the deal is ready
     * across different dimensions such as quote status, products,
     * contact information, and financial validity.
     */

    public static Map<String, String> evaluate(
        Quote q,
        List<QuoteLineItem> qlis,
        Id opportunityId,
        DealSummaryCalculator.CalculationResult calc
    ) {
        Map<String, String> readiness = new Map<String, String>();

        // Quote readiness: must exist and be in an acceptable status
        readiness.put('quote',
            q == null ? 'NO_QUOTE' :
            (q.Status == 'Accepted' || q.Status == 'Ready for Delivery Execution') ? 'READY' : 'QUOTE_NOT_ACCEPTED'
        );

        // Product readiness: at least one line item must exist
        readiness.put('products',
            qlis.isEmpty() ? 'NO_PRODUCTS' : 'READY'
        );

        // Retrieve primary contact for the opportunity
        List<OpportunityContactRole> ocr =
            DealSummarySelector.getPrimaryContact(opportunityId);


        // Contact readiness: must exist and have a valid email
        readiness.put('contact',
            ocr.isEmpty() ? 'NO_PRIMARY_CONTACT' :
            String.isBlank(ocr[0].Contact.Email) ? 'NO_EMAIL' : 'READY'
        );


        // Financial readiness: must have products and a valid total amount
        readiness.put('financials',
            qlis.isEmpty() || calc.totalList <= 0
            ? 'NOT_READY' : 'READY'
        );

        return readiness;
    }
}