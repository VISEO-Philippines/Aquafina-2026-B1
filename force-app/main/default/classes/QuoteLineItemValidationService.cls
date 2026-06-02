public inherited sharing class QuoteLineItemValidationService {

    private static final String ERROR_EXISTING =
        'Duplicate product already exists on this Quote.';

    private static final String ERROR_IN_MEMORY =
        'Duplicate product detected on this Quote.';

    public static void validateDuplicateProducts(List<QuoteLineItem> newQLIs) {

        if (newQLIs == null || newQLIs.isEmpty()) {
            return;
        }

        Set<Id> quoteIds = collectQuoteIds(newQLIs);
        Set<Id> incomingQLIIds = collectQuoteLineItemIds(newQLIs);

        List<QuoteLineItem> existingQLIs =
            QuoteLineItemSelector.getByQuoteIds(quoteIds);

        Map<Id, Set<Id>> existingProductsByQuoteId =
            buildExistingProductsByQuoteId(
                existingQLIs,
                incomingQLIIds
            );

        addErrorsForProductsAlreadyOnQuote(
            newQLIs,
            existingProductsByQuoteId
        );

        Map<Id, Map<Id, List<QuoteLineItem>>> qlisByQuoteAndProduct =
            groupQuoteLineItemsByQuoteAndProduct(newQLIs);

        addErrorsForDuplicateProductsInTransaction(
            qlisByQuoteAndProduct
        );
    }

    private static Set<Id> collectQuoteIds(
        List<QuoteLineItem> quoteLineItems
    ) {
        Set<Id> quoteIds = new Set<Id>();

        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.QuoteId != null) {
                quoteIds.add(qli.QuoteId);
            }
        }

        return quoteIds;
    }

    private static Set<Id> collectQuoteLineItemIds(
        List<QuoteLineItem> quoteLineItems
    ) {
        Set<Id> quoteLineItemIds = new Set<Id>();

        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.Id != null) {
                quoteLineItemIds.add(qli.Id);
            }
        }

        return quoteLineItemIds;
    }

    private static Map<Id, Set<Id>> buildExistingProductsByQuoteId(
        List<QuoteLineItem> existingQLIs,
        Set<Id> incomingQLIIds
    ) {
        Map<Id, Set<Id>> existingProductsByQuoteId =
            new Map<Id, Set<Id>>();

        for (QuoteLineItem existingQLI : existingQLIs) {

            /*
             * In before update, the query can return the same QLI being updated.
             * Skip incoming records so a QLI is not treated as a duplicate of itself.
             */
            if (incomingQLIIds.contains(existingQLI.Id)) {
                continue;
            }

            if (existingQLI.QuoteId == null || existingQLI.Product2Id == null) {
                continue;
            }

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

        return existingProductsByQuoteId;
    }

    private static void addErrorsForProductsAlreadyOnQuote(
        List<QuoteLineItem> newQLIs,
        Map<Id, Set<Id>> existingProductsByQuoteId
    ) {
        for (QuoteLineItem qli : newQLIs) {

            if (qli.QuoteId == null || qli.Product2Id == null) {
                continue;
            }

            Set<Id> existingProducts =
                existingProductsByQuoteId.get(qli.QuoteId);

            Boolean productAlreadyExistsOnQuote =
                existingProducts != null &&
                existingProducts.contains(qli.Product2Id);

            if (productAlreadyExistsOnQuote) {
                qli.addError(ERROR_EXISTING);
            }
        }
    }

    private static Map<Id, Map<Id, List<QuoteLineItem>>>
        groupQuoteLineItemsByQuoteAndProduct(
            List<QuoteLineItem> quoteLineItems
        ) {

        Map<Id, Map<Id, List<QuoteLineItem>>> qlisByQuoteAndProduct =
            new Map<Id, Map<Id, List<QuoteLineItem>>>();

        for (QuoteLineItem qli : quoteLineItems) {

            if (qli.QuoteId == null || qli.Product2Id == null) {
                continue;
            }

            if (!qlisByQuoteAndProduct.containsKey(qli.QuoteId)) {
                qlisByQuoteAndProduct.put(
                    qli.QuoteId,
                    new Map<Id, List<QuoteLineItem>>()
                );
            }

            Map<Id, List<QuoteLineItem>> qlisByProduct =
                qlisByQuoteAndProduct.get(qli.QuoteId);

            if (!qlisByProduct.containsKey(qli.Product2Id)) {
                qlisByProduct.put(
                    qli.Product2Id,
                    new List<QuoteLineItem>()
                );
            }

            qlisByProduct
                .get(qli.Product2Id)
                .add(qli);
        }

        return qlisByQuoteAndProduct;
    }

    private static void addErrorsForDuplicateProductsInTransaction(
        Map<Id, Map<Id, List<QuoteLineItem>>> qlisByQuoteAndProduct
    ) {
        for (Map<Id, List<QuoteLineItem>> qlisByProduct :
            qlisByQuoteAndProduct.values()
        ) {
            for (List<QuoteLineItem> qliGroup : qlisByProduct.values()) {

                if (qliGroup.size() <= 1) {
                    continue;
                }

                for (QuoteLineItem qli : qliGroup) {
                    qli.addError(ERROR_IN_MEMORY);
                }
            }
        }
    }
}