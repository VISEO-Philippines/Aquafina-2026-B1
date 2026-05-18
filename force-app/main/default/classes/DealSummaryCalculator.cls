public class DealSummaryCalculator {

   
    /*
     * Performs all pricing-related calculations for the deal summary.
     * Centralizing this logic ensures consistency, reusability,
     * and keeps business logic separate from data retrieval.
     */
    public class CalculationResult {
        public Decimal totalList = 0;
        public Decimal totalDiscounted = 0;
        public Decimal discountPercent = 0;
        public Decimal vatAmount = 0;
        public Decimal totalAmount = 0;
        public Decimal totalQty = 0;
    }

    
    /*
     * Calculates totals, discounts, VAT, and quantities based on quote line items.
     * Accepts pre-fetched data to keep this class focused purely on computation.
     */
    public static CalculationResult calculate(
        List<QuoteLineItem> qlis,
        Quote q
    ) {
        CalculationResult r = new CalculationResult();

        // Aggregate totals from all quote line items
        for (QuoteLineItem qli : qlis) {

            // Use list price from pricebook, default to 0 if not available
            Decimal listPrice = 
                qli.PricebookEntry != null && qli.PricebookEntry.UnitPrice != null
                ? qli.PricebookEntry.UnitPrice : 0;

            r.totalList += listPrice * qli.Quantity;

             // Use discounted unit price, default to 0 if null
            r.totalDiscounted += (qli.UnitPrice != null ? qli.UnitPrice : 0) * qli.Quantity;
            r.totalQty += qli.Quantity;
        }

        // Calculate discount percentage only if there is a valid list total
        if (r.totalList > 0) {
            r.discountPercent = ((r.totalList - r.totalDiscounted) / r.totalList) * 100;
        }

        // Fallback: use quote-level discount if no line-item discount was calculated
        if (r.discountPercent == 0 && q != null) { 
            r.discountPercent = q.Discount != null 
                ? q.Discount
                : (Decimal) q.get('Effective_Discount__c');
        }

        // Apply VAT and compute final total amount
        r.vatAmount = r.totalDiscounted * 0.20;
        r.totalAmount = r.totalDiscounted + r.vatAmount;

        return r;
    }
}