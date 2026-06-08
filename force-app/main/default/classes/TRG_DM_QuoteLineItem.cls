public with sharing class TRG_DM_QuoteLineItem {

    public static Map<String, Integer> mapQuoteToPricebookEntry(List<QuoteLineItem> triggerQuoteLineItems, Integer MINIMUM_DUPLICATE_COUNT) {
        Map<String, Integer> triggerQuotesToPricebookEntries = new Map<String,Integer>();
        for(QuoteLineItem newQli :triggerQuoteLineItems){
            String trgQuoteToPbeKey = String.valueOf(newQli.QuoteId) + '-' + String.valueOf(newQli.PricebookEntryId);
            triggerQuotesToPricebookEntries.put(trgQuoteToPbeKey, MINIMUM_DUPLICATE_COUNT);
        }

        return triggerQuotesToPricebookEntries;
    }
}