public inherited sharing class QuoteLineItemValidationService {

    public static void validateDuplicateProducts(List<QuoteLineItem> newQLIs) {

        /*
         * Collect QuoteIds from incoming QLIs
         * Used for bulk SOQL query (avoid querying per record)
         */
        Set<Id> quoteIds = new Set<Id>();

        for (QuoteLineItem qli : newQLIs) {
            if (qli.QuoteId != null) {
                quoteIds.add(qli.QuoteId);
            }
        }

        /*
         * Query existing QLIs for those Quotes
         * Fetch existing product relationships per Quote
         */
        List<QuoteLineItem> existingQLIs =
            QuoteLineItemSelector.getByQuoteIds(quoteIds);

        /*
         * Build lookup map (QuoteId → Set of ProductIds)
         * lookup to detect existing duplicates
         */
        Map<Id, Set<Id>> existingProductsByQuoteId =
            new Map<Id, Set<Id>>();

        for (QuoteLineItem existingQLI : existingQLIs) {

            if (!existingProductsByQuoteId.containsKey(existingQLI.QuoteId)) {
                existingProductsByQuoteId.put(
                    existingQLI.QuoteId,
                    new Set<Id>()
                );
            }

            existingProductsByQuoteId
                .get(existingQLI.QuoteId)
                .add(existingQLI.Product2Id);
        }

        /*
         * Validate against existing database records
         * Product cannot already exist on the Quote
         */
        for (QuoteLineItem qli : newQLIs) {

            Set<Id> existingProducts =
                existingProductsByQuoteId.get(qli.QuoteId);

            if (existingProducts != null &&
                existingProducts.contains(qli.Product2Id)) {

                qli.addError(
                    'Duplicate product already exists on this Quote.'
                );
            }
        }

        /*
         * Build in-memory grouping for Trigger.new
         * Detect duplicates within same transaction
         * Structure: QuoteId → ProductId → List of QLIs
         */
        Map<Id, Map<Id, List<QuoteLineItem>>> qlisByQuoteAndProduct =
            new Map<Id, Map<Id, List<QuoteLineItem>>>();

        for (QuoteLineItem qli : newQLIs) {

            // Initialize Quote-level map if missing
            if (!qlisByQuoteAndProduct.containsKey(qli.QuoteId)) {
                qlisByQuoteAndProduct.put(
                    qli.QuoteId,
                    new Map<Id, List<QuoteLineItem>>()
                );
            }

            Map<Id, List<QuoteLineItem>> productsByQuote =
                qlisByQuoteAndProduct.get(qli.QuoteId);

            // Initialize Product bucket if missing
            if (!productsByQuote.containsKey(qli.Product2Id)) {
                productsByQuote.put(
                    qli.Product2Id,
                    new List<QuoteLineItem>()
                );
            }

            // Add QLI into its product group
            productsByQuote
                .get(qli.Product2Id)
                .add(qli);
        }

        /*
         * Validate in-memory duplicates (Trigger.new vs Trigger.new)
         * Same Product cannot appear multiple times in same Quote
         */
        for (Map<Id, List<QuoteLineItem>> productsByQuote :
                qlisByQuoteAndProduct.values()) {

            for (List<QuoteLineItem> qliGroup :
                    productsByQuote.values()) {

                if (qliGroup.size() > 1) {

                    // Block ALL duplicate records in the group
                    for (QuoteLineItem qli : qliGroup) {
                        qli.addError(
                            'Duplicate product detected on this Quote.'
                        );
                    }
                }
            }
        }
    }
}
 