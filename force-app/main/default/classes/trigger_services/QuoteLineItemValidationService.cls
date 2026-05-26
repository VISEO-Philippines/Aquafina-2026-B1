public with sharing class QuoteLineItemValidationService {
    public static void enforceProductNotRepeated(List<QuoteLineItem> qlis) {
        // check duplicates within incoming batch by checking if (QuoteId. ProductId) pair is unique in within the batch
        // query existing quote line items and see if there are repeated pairs in the incoming batch
        
    }
}