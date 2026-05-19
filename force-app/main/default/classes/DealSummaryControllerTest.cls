@IsTest
    public class DealSummaryControllerTest {
    /*
     * Creates minimal baseline data shared across all tests.
     * Only includes reccords required for most scenarios:
     * - Account (parent object)
     * - Opportunitites (for testing different cases)
     * - Product and PricebookEntry (Requiered for Quote Line Items)
     */
    @testSetup
    static void setup() {

        // Minimal Shared data only
        Account acc = TestDataFactory.createAccount();

        // create a few opportunities (baseline only)
        for (Integer i = 0; i < 3; i++) {
            TestDataFactory.createOpportunity(acc.Id);
        }

        Product2 prod = TestDataFactory.createProduct();
        TestDataFactory.createPricebookEntry(prod.Id);
    }

    @IsTest
    static void testDealSummary_SyncedQuote() {

        /*
        * Scenario: Opp with a synced Quote and a Discount line Item
        * - Validates correct calculation of totals and discount percentage
        */

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create a quote linked to opportunity
        Quote q = TestDataFactory.createQuote(opp.Id);

        // Apply 10% discount (100 -> 90)
        TestDataFactory.createQuoteLineItem(q.Id, pbe.Id, 90);

        // Link quote as synced
        opp.SyncedQuoteId = q.Id;
        update opp;

        // Execute the method being tested
        Test.startTest();
        DealSummaryDTO result = 
            DealSummaryController.getDealSummary(opp.Id);
        Test.stopTest();

        // Assertions to validate expected outcomes
        System.assertNotEquals(null, result);
        System.assertEquals(q.Id, result.quote.Id);
        System.assertEquals(100, result.totalList);
        System.assertEquals(90, result.totalDiscounted);
        System.assertEquals(10, result.discountPercent);
    }

    @IsTest
    static void testDealSummary_NullOpportunityId() {

        Test.startTest();
        DealSummaryDTO result =
            DealSummaryController.getDealSummary(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null for null input');
    }

    @IsTest
    static void testDealSummary_NoSyncedQuote() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        DealSummaryDTO result =
            DealSummaryController.getDealSummary(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(null, result.quote);
    }
}


