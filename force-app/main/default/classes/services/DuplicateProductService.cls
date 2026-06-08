/**
 * Service for validating and detecting duplicate products in Quote Line Items.
 * Prevents adding the same product multiple times to a quote.
 * Uses QuoteLineItemSelector and Product2Selector for data access.
 */
public with sharing class DuplicateProductService
{

    private QuoteLineItemSelector qliSelector;
    private Product2Selector      productSelector;

    private static final String DEFAULT_DUPLICATE_ERROR_MSG = 'Product already exists in this quote';

    @TestVisible
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
        this.qliSelector     = new QuoteLineItemSelector();
        this.productSelector = new Product2Selector();
    }

    /**
     * Constructor allowing dependency injection for testing.
     *
     * @param qliSelector     QuoteLineItemSelector instance
     * @param productSelector Product2Selector instance
     */
    public DuplicateProductService(QuoteLineItemSelector qliSelector, Product2Selector productSelector)
    {
        this.qliSelector     = qliSelector;
        this.productSelector = productSelector;
    }

    /**
     * Validates quote line items for duplicate products (insert path).
     *
     * @param newLines List of new QuoteLineItem records
     */
    public void checkDuplicateProducts(List<QuoteLineItem> newLines)
    {
        if (newLines == null || newLines.isEmpty())
        {
            return;
        }

        resolveMissingProduct2Ids(newLines);

        Set<Id> quoteIds = new Set<Id>();
        for (QuoteLineItem line : newLines)
        {
            quoteIds.add(line.QuoteId);
        }

        validate(newLines, getExistingProductsByQuote(quoteIds));
    }

    /**
     * Validates quote line items for duplicate products (update path).
     * Only lines whose Product2Id changed are evaluated.
     *
     * @param newLines List of updated QuoteLineItem records
     * @param oldMap   Map of QuoteLineItem records before the update
     */
    public void checkDuplicateProducts(List<QuoteLineItem> newLines, Map<Id, QuoteLineItem> oldMap)
    {
        if (newLines == null || newLines.isEmpty())
        {
            return;
        }

        checkDuplicateProducts(filterChangedLines(newLines, oldMap));
    }

    @TestVisible
    private List<QuoteLineItem> filterChangedLines(
        List<QuoteLineItem> newLines,
        Map<Id, QuoteLineItem> oldMap
    )
    {
        List<QuoteLineItem> changed = new List<QuoteLineItem>();

        for (QuoteLineItem newLine : newLines)
        {
            QuoteLineItem oldLine = oldMap.get(newLine.Id);
            if (oldLine == null || oldLine.Product2Id != newLine.Product2Id)
            {
                changed.add(newLine);
            }
        }

        return changed;
    }

    // In a before-insert trigger, Product2Id is null because the platform resolves it
    // from PricebookEntryId only after the trigger fires. Query PricebookEntry to populate it.
    private void resolveMissingProduct2Ids(List<QuoteLineItem> lines)
    {
        Set<Id> pbeIds = new Set<Id>();
        for (QuoteLineItem line : lines)
        {
            if (line.Product2Id == null && line.PricebookEntryId != null)
            {
                pbeIds.add(line.PricebookEntryId);
            }
        }

        if (pbeIds.isEmpty()) return;

        Map<Id, Id> pbeToProduct2 = new Map<Id, Id>();
        for (PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Id IN :pbeIds])
        {
            pbeToProduct2.put(pbe.Id, pbe.Product2Id);
        }

        for (QuoteLineItem line : lines)
        {
            if (line.Product2Id == null && line.PricebookEntryId != null)
            {
                line.Product2Id = pbeToProduct2.get(line.PricebookEntryId);
            }
        }
    }

    private Map<Id, Set<Id>> getExistingProductsByQuote(Set<Id> quoteIds)
    {
        List<QuoteLineItem> existingLines = this.qliSelector.getExistingLinesByQuoteIds(quoteIds);
        return groupByQuoteAndProduct(existingLines);
    }

    private Map<Id, Set<Id>> groupByQuoteAndProduct(List<QuoteLineItem> lineItems)
    {
        Map<Id, Set<Id>> groupedMap = new Map<Id, Set<Id>>();

        for (QuoteLineItem item : lineItems)
        {
            if (!groupedMap.containsKey(item.QuoteId))
            {
                groupedMap.put(item.QuoteId, new Set<Id>());
            }
            groupedMap.get(item.QuoteId).add(item.Product2Id);
        }

        return groupedMap;
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
            for (Product2 p : this.productSelector.getProductsByIds(productIds))
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
