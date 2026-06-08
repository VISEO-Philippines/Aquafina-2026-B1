public class DM_QuoteLineItem { //Data Manager

    public static Map<String, Integer> mapQuoteToPricebookEntries(Integer MINIMUM_DUPLICATE_COUNT, Integer INCREMENT){

        Map<String, Integer> databaseQuotesToPricebookEntries = new Map<String, Integer>();
        List<QuoteLineItem> allQuoteLineItems = queryQuoteAndPricebookEntries();
        for(QuoteLineItem dbQli :allQuoteLineItems){
            String dbQuoteToPbeKey = String.valueOf(dbQli.QuoteId) + '-' + String.valueOf(dbQli.PricebookEntryId);
            if (!databaseQuotesToPricebookEntries.containsKey(dbQuoteToPbeKey)){
                databaseQuotesToPricebookEntries.put(dbQuoteToPbeKey, MINIMUM_DUPLICATE_COUNT);
            }
            else {
                databaseQuotesToPricebookEntries.put(dbQuoteToPbeKey, databaseQuotesToPricebookEntries.get(dbQuoteToPbeKey) + INCREMENT);
            }
        }

        return databaseQuotesToPricebookEntries;
    }

    public static Map<String, String> mapQuotePbesToPbeNames(Integer MINIMUM_DUPLICATE_COUNT, Integer INCREMENT){

        Map<String, String> databaseQuotePbeToPbeNames = new Map<String, String>();
        List<QuoteLineItem> allQuoteLineItems = queryQuoteAndPricebookEntries();
        for(QuoteLineItem dbQli :allQuoteLineItems){
            String dbQuoteToPbeKey = String.valueOf(dbQli.QuoteId) + '-' + String.valueOf(dbQli.PricebookEntryId);
            databaseQuotePbeToPbeNames.put(dbQuoteToPbeKey, dbQli.PricebookEntry.Name);
        }

        return databaseQuotePbeToPbeNames;
    }

    private static List<QuoteLineItem> queryQuoteAndPricebookEntries() {
        return [SELECT QuoteId, PricebookEntryId, PricebookEntry.Name FROM QuoteLineItem];
    }
}