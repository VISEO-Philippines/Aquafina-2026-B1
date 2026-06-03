/**
 * Service for validating and detecting duplicate products in Quote Line Items.
 * Prevents adding the same product multiple times to a quote.
 * Uses QuoteLineItemSelector for data access.
 */
public with sharing class DuplicateProductService
{

    private QuoteLineItemSelector qliSelector;

    private static final String DEFAULT_DUPLICATE_ERROR_MSG = 'Product already exists in this quote';

    private static String formatDuplicateError(String productName) {
        if (productName == null) {
            return DEFAULT_DUPLICATE_ERROR_MSG;
        }
        return 'Product "' + productName + '" already exists in this quote';
    }

    /**
     * Default constructor initializing the service with a new QuoteLineItemSelector instance.
     */
    public DuplicateProductService()
    {
        this.qliSelector = new QuoteLineItemSelector();
    }

    /**
     * Constructor allowing dependency injection for testing.
     *
     * @param qliSelector QuoteLineItemSelector instance
     */
    public DuplicateProductService(QuoteLineItemSelector qliSelector)
    {
        this.qliSelector = qliSelector;
    }

    /**
     * Validates quote line items for duplicate products by loading existing
     * quote line items and comparing them with the incoming records.
     *
     * @param newLines List of new or updated QuoteLineItem records
     */
    public void checkDuplicateProducts(List<QuoteLineItem> newLines)
    {
        if (newLines == null || newLines.isEmpty())
        {
            return;
        }

        // Collect every Quote ID touched by this transaction
        Set<Id> quoteIds = new Set<Id>();
        for (QuoteLineItem line : newLines)
        {
            quoteIds.add(line.QuoteId);
        }

        // Ask the database what products are already on those quotes
        Map<Id, Set<Id>> existingProductMap = getExistingProductsByQuote(quoteIds);

        // Run all three validation phases
        validate(newLines, existingProductMap);
    }

    // Queries existing lines and reshapes them into a Map<QuoteId, Set<ProductId>>
    // so the validation step can do O(1) lookups instead of looping repeatedly.
    private Map<Id, Set<Id>> getExistingProductsByQuote(Set<Id> quoteIds)
    {
        List<QuoteLineItem> existingLines = this.qliSelector.getExistingLinesByQuoteIds(quoteIds);
        return this.qliSelector.groupByQuoteAndProduct(existingLines);
    }

    // Orchestrates the three phases of duplicate detection.
    private void validate(List<QuoteLineItem> newLines, Map<Id, Set<Id>> existingMap)
    {
        Map<Id, String>     productNames   = fetchProductNames(newLines);
        Map<String, Integer> incomingCounts = countIncomingPairs(newLines);
        flagDuplicates(newLines, existingMap, incomingCounts, productNames);
    }

    // Phase 1 — fetch the display name of every product in the incoming batch
    // so error messages read "Product 'Laptop' already exists..." instead of a generic fallback.
    private Map<Id, String> fetchProductNames(List<QuoteLineItem> newLines)
    {
        Set<Id> productIds = new Set<Id>();
        for (QuoteLineItem nl : newLines)
        {
            if (nl.Product2Id != null) productIds.add(nl.Product2Id);
        }

        Map<Id, String> productNames = new Map<Id, String>();
        if (!productIds.isEmpty())
        {
            for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Id IN :productIds WITH SECURITY_ENFORCED])
            {
                productNames.put(p.Id, p.Name);
            }
        }

        return productNames;
    }

    // Phase 2 — tally how many times each (QuoteId + ProductId) pair appears
    // within the current batch. Catches duplicates added in the same save operation
    // before anything reaches the database.
    private Map<String, Integer> countIncomingPairs(List<QuoteLineItem> newLines)
    {
        Map<String, Integer> incomingCounts = new Map<String, Integer>();
        for (QuoteLineItem newLine : newLines)
        {
            String pairKey     = getQuoteProductKey(newLine.QuoteId, newLine.Product2Id);
            Integer currentCount = incomingCounts.containsKey(pairKey) ? incomingCounts.get(pairKey) : 0;
            incomingCounts.put(pairKey, currentCount + 1);
        }
        return incomingCounts;
    }

    // Phase 3 — loop every incoming line and add an error if the product is a duplicate
    // either within the current batch (duplicateInBatch) or already saved in the database (duplicateInDatabase).
    private void flagDuplicates(
        List<QuoteLineItem>  newLines,
        Map<Id, Set<Id>>     existingMap,
        Map<String, Integer> incomingCounts,
        Map<Id, String>      productNames
    )
    {
        for (QuoteLineItem newLine : newLines)
        {
            String  pairKey           = getQuoteProductKey(newLine.QuoteId, newLine.Product2Id);
            Boolean duplicateInBatch    = incomingCounts.containsKey(pairKey) && incomingCounts.get(pairKey) > 1;
            Boolean duplicateInDatabase = existingMap.containsKey(newLine.QuoteId) && existingMap.get(newLine.QuoteId).contains(newLine.Product2Id);

            if (duplicateInBatch || duplicateInDatabase)
            {
                String prodName = productNames.containsKey(newLine.Product2Id) ? productNames.get(newLine.Product2Id) : null;
                newLine.addError(formatDuplicateError(prodName));
            }
        }
    }

    // Composite key used as a single map key for a (Quote, Product) pair.
    private String getQuoteProductKey(Id quoteId, Id productId)
    {
        return String.valueOf(quoteId) + '|' + String.valueOf(productId);
    }
}
