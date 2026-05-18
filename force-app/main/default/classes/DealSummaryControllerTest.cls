@IsTest
public class DealSummaryControllerTest {
    //negative test cases can be added to validate handling of null/invalid Ids, missing quotes, etc.
    /*
     * Creates shared base test data for all test methods.
     * This includes Account, multiple Opportunities, Product, 
     * and PricebookEntry. Using @testSetup ensures data is created 
     * once and reused, improving test efficiency and consistency.
     */
    @testSetup
    static void setup() {

        // Create Account (parent record for Opportunities)
        Account acc = new Account(Name = 'Bulk Test Account');
        insert acc;

        // Create multiple Opportunities to support bulk/repeated execution testing
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Test Opp ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                AccountId = acc.Id
            ));
        }
        insert opps;

        // Create Product used in Quote Line Items
        Product2 prod = new Product2(
            Name = 'Standard Product',
            IsActive = true
        );
        insert prod;

        // Create PricebookEntry (required for QuoteLineItem)
        insert new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
    }

    /*
     * Validates that the controller correctly:
     * - Retrieves the synced quote
     * - Calculates pricing values (discount)
     * - Returns a fully populated DTO
     */
    @IsTest
    static void testDealSummaryWithSyncedQuote() {

        // Retrieve base test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create a synced Quote for the Opportunity
        Quote q = new Quote(
            Name = 'Synced Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert q;

        // Create a discounted Quote Line Item (10% discount)
        insert new QuoteLineItem(
            QuoteId = q.Id,
            Quantity = 1,
            UnitPrice = 90, // Discount from $100 list price
            PricebookEntryId = pbe.Id
        );

        // Link the Quote as the synced quote on the Opportunity
        opp.SyncedQuoteId = q.Id;
        update opp;

        // Execute the method under test within limit-reset block
        Test.startTest();
        DealSummaryDTO result = DealSummaryController.getDealSummary(opp.Id);
        Test.stopTest();

        // Assertions: validate correctness of returned data
        System.assertNotEquals(null, result, 'DTO should not be null');
        System.assertEquals(q.Id, result.quote.Id, 'Should return the synced quote');
        System.assertEquals(100, result.totalList, 'Total list price should match');
        System.assertEquals(90, result.totalDiscounted, 'Discounted total should match');
        System.assertEquals(10, result.discountPercent, 'Discount percentage should be 10%');

        //note: scenario based testing
    }

    /*
     * Validates that the controller can handle repeated execution
     * within a single transaction without hitting governor limits.
     * Ensures the logic is bulk-safe even if invoked multiple times.
     */
    @IsTest
    static void testRepeatedExecutionDoesNotHitLimits() { //hindi valid.

        // Retrieve all Opportunities created in test setup
        Map<Id, Opportunity> oppMap =
            new Map<Id, Opportunity>([SELECT Id FROM Opportunity]);

        Test.startTest();

        // Simulate repeated calls to the controller method
        for (Id oppId : oppMap.keySet()) {
            DealSummaryDTO result = DealSummaryController.getDealSummary(oppId);

            // Basic validation to ensure method returns valid data each time
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertNotEquals(null, result.totalAmount, 'Total amount should be populated');
        }

        Test.stopTest();

        // If execution completes without limit exceptions,
        // the method is safe under repeated execution
    }


}