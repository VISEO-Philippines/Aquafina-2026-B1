/*
 * Custom exception thrown when attempting to add duplicate products to a Quote.
 * Provides context about the product, quote, and line item involved in the duplicate.
 */
public class DuplicateProductException extends Exception {
    
    public String productName { get; set; }
    public Id quoteId { get; set; }
    public Id lineItemId { get; set; }
    public Id productId { get; set; }
}
