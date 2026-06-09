public inherited sharing class QuoteLineItemValidationService {

    private static final String ERROR_EXISTING =
        'Product "{0}" already exists on this Quote.';

    private static final String ERROR_IN_MEMORY =
        'Product "{0}" is added more than once on this Quote.';

    public static void validateDuplicateProducts(List<QuoteLineItem> newQLIs) {

        if (newQLIs == null || newQLIs.isEmpty()) {
            return;
        }

        Set<Id> quoteIds = collectQuoteIds(newQLIs);
        Set<Id> incomingQLIIds = collectQuoteLineItemIds(newQLIs);
        Set<Id> pricebookEntryIds = collectPricebookEntryIds(newQLIs);

        List<PricebookEntry> pricebookEntries =
            QuoteLineItemSelector.getPricebookEntriesByIds(
                pricebookEntryIds
            );

        Map<Id, PricebookEntry> pricebookEntriesById =
            new Map<Id, PricebookEntry>(pricebookEntries);

        Map<Id, String> productNamesById =
            buildProductNamesByIdFromPricebookEntries(pricebookEntries);

        List<QuoteLineItem> existingQLIs =
            QuoteLineItemSelector.getByQuoteIds(quoteIds);

        Map<Id, Map<Id, String>> existingProductNamesByQuoteId =
            buildExistingProductNamesByQuoteId(
                existingQLIs,
                incomingQLIIds
            );

        addErrorsForProductsAlreadyOnQuote(
            newQLIs,
            existingProductNamesByQuoteId,
            pricebookEntriesById
        );

        Map<Id, Map<Id, List<QuoteLineItem>>> qlisByQuoteAndProduct =
            groupQuoteLineItemsByQuoteAndProduct(
                newQLIs,
                pricebookEntriesById
            );

        addErrorsForDuplicateProductsInTransaction(
            qlisByQuoteAndProduct,
            productNamesById
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

    private static Set<Id> collectPricebookEntryIds(
        List<QuoteLineItem> quoteLineItems
    ) {
        Set<Id> pricebookEntryIds = new Set<Id>();

        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.PricebookEntryId != null) {
                pricebookEntryIds.add(qli.PricebookEntryId);
            }
        }

        return pricebookEntryIds;
    }

    private static Id getProductId(
        QuoteLineItem qli,
        Map<Id, PricebookEntry> pricebookEntriesById
    ) {
        if (qli.Product2Id != null) {
            return qli.Product2Id;
        }

        if (
            qli.PricebookEntryId == null ||
            !pricebookEntriesById.containsKey(qli.PricebookEntryId)
        ) {
            return null;
        }

        return pricebookEntriesById
            .get(qli.PricebookEntryId)
            .Product2Id;
    }

    private static Map<Id, String> buildProductNamesByIdFromPricebookEntries(
        List<PricebookEntry> pricebookEntries
    ) {
        Map<Id, String> productNamesById = new Map<Id, String>();

        for (PricebookEntry pricebookEntry : pricebookEntries) {
            if (pricebookEntry.Product2Id == null) {
                continue;
            }

            productNamesById.put(
                pricebookEntry.Product2Id,
                pricebookEntry.Product2.Name
            );
        }

        return productNamesById;
    }

    private static Map<Id, Map<Id, String>> buildExistingProductNamesByQuoteId(
        List<QuoteLineItem> existingQLIs,
        Set<Id> incomingQLIIds
    ) {
        Map<Id, Map<Id, String>> existingProductNamesByQuoteId =
            new Map<Id, Map<Id, String>>();

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

            if (!existingProductNamesByQuoteId.containsKey(existingQLI.QuoteId)) {
                existingProductNamesByQuoteId.put(
                    existingQLI.QuoteId,
                    new Map<Id, String>()
                );
            }

            existingProductNamesByQuoteId
                .get(existingQLI.QuoteId)
                .put(
                    existingQLI.Product2Id,
                    existingQLI.Product2.Name
                );
        }

        return existingProductNamesByQuoteId;
    }

    private static void addErrorsForProductsAlreadyOnQuote(
        List<QuoteLineItem> newQLIs,
        Map<Id, Map<Id, String>> existingProductNamesByQuoteId,
        Map<Id, PricebookEntry> pricebookEntriesById
    ) {
        for (QuoteLineItem qli : newQLIs) {
            Id productId = getProductId(qli, pricebookEntriesById);

            if (qli.QuoteId == null || productId == null) {
                continue;
            }

            Map<Id, String> existingProductNames =
                existingProductNamesByQuoteId.get(qli.QuoteId);

            Boolean productAlreadyExistsOnQuote =
                existingProductNames != null &&
                existingProductNames.containsKey(productId);

            if (productAlreadyExistsOnQuote) {
                String productName =
                    existingProductNames.get(productId);

                qli.addError(
                    formatErrorMessage(ERROR_EXISTING, productName)
                );
            }
        }
    }

    private static Map<Id, Map<Id, List<QuoteLineItem>>>
        groupQuoteLineItemsByQuoteAndProduct(
            List<QuoteLineItem> quoteLineItems,
            Map<Id, PricebookEntry> pricebookEntriesById
        ) {

        Map<Id, Map<Id, List<QuoteLineItem>>> qlisByQuoteAndProduct =
            new Map<Id, Map<Id, List<QuoteLineItem>>>();

        for (QuoteLineItem qli : quoteLineItems) {
            Id productId = getProductId(qli, pricebookEntriesById);

            if (qli.QuoteId == null || productId == null) {
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

            if (!qlisByProduct.containsKey(productId)) {
                qlisByProduct.put(
                    productId,
                    new List<QuoteLineItem>()
                );
            }

            qlisByProduct
                .get(productId)
                .add(qli);
        }

        return qlisByQuoteAndProduct;
    }

    private static void addErrorsForDuplicateProductsInTransaction(
        Map<Id, Map<Id, List<QuoteLineItem>>> qlisByQuoteAndProduct,
        Map<Id, String> productNamesById
    ) {
        for (Map<Id, List<QuoteLineItem>> qlisByProduct :
            qlisByQuoteAndProduct.values()
        ) {
            for (Id productId : qlisByProduct.keySet()) {

                List<QuoteLineItem> qliGroup =
                    qlisByProduct.get(productId);

                if (qliGroup.size() <= 1) {
                    continue;
                }

                String productName =
                    productNamesById.get(productId);

                for (QuoteLineItem qli : qliGroup) {
                    qli.addError(
                        formatErrorMessage(ERROR_IN_MEMORY, productName)
                    );
                }
            }
        }
    }

    private static String formatErrorMessage(
        String messageTemplate,
        String productName
    ) {
        String displayName = String.isBlank(productName)
            ? 'selected product'
            : productName;

        return String.format(
            messageTemplate,
            new List<String>{ displayName }
        );
    }
}
