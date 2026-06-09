@IsTest
private class DealSummaryControllerTest {
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

    // Helpty method to create sales rep user and run tests as that user
    private static User createAndValidateSalesRep() {
        User salesRep = TestDataFactory.createSalesRepUser();
        Assert.isNotNull(salesRep, 'Sales Rep should be created');
        Assert.isNotNull(salesRep.Id, 'Sales Rep should have an Id');
        return salesRep;
    }

    private static void assertRunningAs(User u) {
        Assert.areEqual(u.Id, UserInfo.getUserId(), 'code should be running as the sales rep user');
    }

    @IsTest
    static void testDealSummary_SyncedQuote() {

        /*
        * Scenario: Opp with a synced Quote and a Discount line Item
        * - Validates correct calculation of totals and discount percentage
        */

        // Create a test user to simulate a Sales Rep persona 
        User salesRep = createAndValidateSalesRep();
        
        System.runAs(salesRep) {
            assertRunningAs(salesRep);

            Account acc = [SELECT Id FROM Account LIMIT 1];
            Opportunity opp = TestDataFactory.createOpportunity(acc.Id);
           
            PricebookEntry pbe = [
                SELECT Id 
                FROM PricebookEntry 
                WHERE UnitPrice = 100 
                LIMIT 1
            ];

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
            Assert.isNotNull(result, 'Result should not be null');
            Assert.areEqual(q.Id, result.quote.Id, 'Quote should be correctly linked in the result');
            Assert.areEqual(100, result.totalList, 'Total list price should be correct');
            Assert.areEqual(90, result.totalDiscounted, 'Total discounted price should be correct');
            Assert.areEqual(10, result.discountPercent, 'Discount percentage should be correct');
        }
    }

    /*
    * Scenario: Null Opportunity Id is passed
    * Expected: Method should return null without errors
    */
    @IsTest
    static void testDealSummary_NullOpportunityId() {
        User salesRep = createAndValidateSalesRep();

        System.runAs(salesRep) {
            assertRunningAs(salesRep);

            Test.startTest();
            DealSummaryDTO result =
                DealSummaryController.getDealSummary(null);
            Test.stopTest();

            Assert.isNull(result, 'Result should be null for null input');
        }
    }

    @IsTest
    static void testDealSummary_NoSyncedQuote() {
        User salesRep = createAndValidateSalesRep();

        System.runAs(salesRep) {
            assertRunningAs(salesRep);

            Account acc = [SELECT Id FROM Account LIMIT 1];
            Opportunity opp = [
                SELECT Id
                FROM Opportunity 
                WHERE AccountId = :acc.Id
                LIMIT 1
            ];

            Test.startTest();
            DealSummaryDTO result =
                DealSummaryController.getDealSummary(opp.Id);
            Test.stopTest();

            Assert.isNotNull(result, 'Result should not be null');
            Assert.isNull(result.quote, 'Quote should be null when no synced quote exists');
        }
    }

    @IsTest
    static void testDealSummary_MissingQuoteLineItems() {
        User salesRep = createAndValidateSalesRep();

        System.runAs(salesRep) {
            assertRunningAs(salesRep);

            Account acc = [SELECT Id FROM Account LIMIT 1];

            Opportunity opp = [
                SELECT Id
                FROM Opportunity 
                WHERE AccountId = :acc.Id
                LIMIT 1
            ];

            Quote q = TestDataFactory.createQuote(opp.Id);

            // Link quote as synced without line items
            opp.SyncedQuoteId = q.Id;
            update opp;

            Test.startTest();
            DealSummaryDTO result =
                DealSummaryController.getDealSummary(opp.Id);
            Test.stopTest();

            Assert.isNotNull(result, 'Result should not be null');
            Assert.isNotNull(result.quote, 'Quote should not be null');
            Assert.areEqual(0, result.totalList, 'Total list price should be zero when no line items exist');
            Assert.areEqual(0, result.totalDiscounted, 'Total discounted price should be zero when no line items exist');
        }
    }
}
