public class DealSummarySelector {
    
    /*
     * Centralizes all data access for the deal summary.
     * Encapsulates SOQL queries to maintain separation of concerns
     * and keep business logic out of data retrieval.
     */

    public static Opportunity getOpportunity(Id oppId) {
        return [
            SELECT Id, Name, StageName, CloseDate, Amount, Account.Name
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
    }

    /*
     * Retrieves the synced (primary) quote for the opportunity.
     * Using the synced quote ensures calculations are based on the
     * finalized pricing state.
     */

    public static Quote getPrimaryQuote(Id oppId) {
        List<Quote> quotes = [
            SELECT Id, Name, Status, Discount, Effective_Discount__c
            FROM Quote
            WHERE OpportunityId = :oppId
            AND IsSyncing = true
            LIMIT 1
        ];
        return quotes.isEmpty() ? null : quotes[0];
    }

    
    /*
     * Retrieves all line items for the given quote.
     * These are required for pricing calculations such as totals and discounts.
     */
    public static List<QuoteLineItem> getQuoteLineItems(Id quoteId) {
        return [
            SELECT Quantity, UnitPrice, TotalPrice, PricebookEntry.UnitPrice
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ];
    }

    
    /*
     * Retrieves the primary contact for the opportunity.
     * Used for readiness checks such as validating required contact details (e.g., email).
     */
    public static List<OpportunityContactRole> getPrimaryContact(Id oppId) {
        return [
            SELECT Contact.Email
            FROM OpportunityContactRole
            WHERE OpportunityId = :oppId
            AND IsPrimary = true
            LIMIT 1
        ];
    }
}