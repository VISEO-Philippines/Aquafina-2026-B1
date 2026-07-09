public inherited sharing class QuoteLineItemHelper {
    /** 
     * 
     * Returns Quote Line Items where Product2Id changed during update. 
     * 
     * this helper only performs record filtering.
     * */

    public static List<QuoteLineItem> filterQuoteLineItemsWithProductChange(
        List<QuoteLineItem> newQLIs,
        Map<Id, QuoteLineItem> oldQLIMap
    ){
        List<QuoteLineItem> qlisWithProductChange =
            new List<QuoteLineItem>();

        if (
            newQLIs == null ||
            newQLIs.isEmpty() ||
            oldQLIMap == null ||
            oldQLIMap.isEmpty()
        ) {
            return qlisWithProductChange;
        }

        for (QuoteLineItem newQLI : newQLIs) {

            QuoteLineItem oldQLI =
                oldQLIMap.get(newQLI.Id);

            if (
                oldQLI != null &&
                newQLI.Product2Id != oldQLI.Product2Id
            ) {
                qlisWithProductChange.add(newQLI);
            }
        }

        return qlisWithProductChange;
    }
}