public with sharing class QuoteLineItemValidatorService {

    private static final String DUPLICATE_PRODUCT_ERROR_MSG = 'ERROR: DUPLICATE PRODUCT Found in the same QUOTE. Product: ';
    private static final String DUPLICATE_PRODUCT_BATCH_ERROR_MSG = 'ERROR: MULTIPLE DUPLICATE PRODUCTS Found in the same QUOTE. Product: ';
    private static final Integer MINIMUM_INVALID_DUPLICATE_COUNT = 1;
    private static final Integer INCREMENT = 1;

    public static void validateNewProducts(List<QuoteLineItem> triggerQuoteLineItems) {

        //Get trigger quoteIds, pricebookEntryIds of to-be inserted QLIs
        Map<String, Integer> triggerQuotesToPricebookEntries = TRG_DM_QuoteLineItem.mapQuoteToPricebookEntry(triggerQuoteLineItems, MINIMUM_INVALID_DUPLICATE_COUNT);
        //Map database quoteIds to their respective QuoteIds
        Map<String, Integer> databaseQuotesToPricebookEntries  = DM_QuoteLineItem.mapQuoteToPricebookEntries(MINIMUM_INVALID_DUPLICATE_COUNT, INCREMENT);
        // Get map of quotePbes to respective pbeNames
        Map<String, String> databaseQuotePbeToPbeNames = DM_QuoteLineItem.mapQuotePbesToPbeNames(MINIMUM_INVALID_DUPLICATE_COUNT, INCREMENT);

        //validation
        Set<String> quoteToPbeHits = checkForHits(triggerQuotesToPricebookEntries, databaseQuotesToPricebookEntries);
        validateHits(triggerQuoteLineItems, databaseQuotePbeToPbeNames, quoteToPbeHits);
    }

    private static Set<String> checkForHits(Map<String, Integer> triggerQuotesToPricebookEntries, Map<String, Integer> databaseQuotesToPricebookEntries){
        Set<String> triggerKeys = triggerQuotesToPricebookEntries.keySet();
        Set<String> quoteToPbeHits = new Set<String>();
        for(String key :triggerKeys){
            if (databaseQuotesToPricebookEntries.get(key) > MINIMUM_INVALID_DUPLICATE_COUNT){
                quoteToPbeHits.add(key);
            }
        }

        return quoteToPbeHits;
    }

    private static void validateHits(List<QuoteLineItem> incomingQlis, Map<String, String> quotePbesToPbeNamesMap, Set<String> quoteToPbeHits){
        
        for (QuoteLineItem qliToValidate :incomingQlis){
            String qliPbeKey = String.valueOf(qliToValidate.quoteId) + '-' + String.valueOf(qliToValidate.PricebookEntryId);

            if 
            (quoteToPbeHits.contains(qliPbeKey) && quoteToPbeHits.size() == MINIMUM_INVALID_DUPLICATE_COUNT)
            {
                qliToValidate.addError(DUPLICATE_PRODUCT_ERROR_MSG + quotePbesToPbeNamesMap.get(qliPbeKey));
            } 
            else if 
            (quoteToPbeHits.contains(qliPbeKey) && quoteToPbeHits.size() > MINIMUM_INVALID_DUPLICATE_COUNT)
            {
                qliToValidate.addError(DUPLICATE_PRODUCT_BATCH_ERROR_MSG + quotePbesToPbeNamesMap.get(qliPbeKey));
            }
        }

        return;
    }


}