@isTest(SeeAllData=true)
private class FetchQuoteLineItemsTest {
    @IsTest
    static void fetchQuoteLineItemWrapperClassTest(){
        //Query random opportunity with quote
        List<Opportunity> listOpps = [SELECT Id FROM Opportunity WHERE Opportunity.SyncedQuoteId != NULL LIMIT 1];

        List<FetchQuoteLineItems.QuoteLineItemWrapperClass> wrapperList = FetchQuoteLineItems.fetchQuoteLineItemWrapperClass(listOpps[0].Id);

        System.assert(!wrapperList.isEmpty(), 'ERROR: Could not make quote line item');
    }

    @IsTest
    static void checkIfHasLineItemsTest(){
        Boolean isError;

        //query opportunity with quote line item
        List<Opportunity> listOpps = [SELECT Id FROM Opportunity WHERE Opportunity.SyncedQuoteId != NULL AND HasOpportunityLineItem = true LIMIT 1];

        List<QuoteLineItem> lstQuoteLineItem = FetchQuoteLineItems.checkIfHasLineItems(listOpps[0].Id);
        
        System.assert(!lstQuoteLineItem.isEmpty(), 'ERROR: Could not get quote line items object');
    }
}