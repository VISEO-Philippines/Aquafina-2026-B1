@isTest
private class QuoteLineItemValidationTest {

    @TestSetup
    static void setupData(){
        // TODO: Move setup here
    }

    @isTest
    static void testPreventDuplicateBatchProducts() {

        // TODO: Use System.runAs for these
        // TODO: Add creation of Opportunity, Quote to TestDataFactory
        Opportunity testOpp = new Opportunity(
            Name = 'Test Freeze Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        TestDataFactory.ProdSet prodSet = TestDataFactory.generateProdSet();

        Quote testQuote = new Quote(
            Name = 'Test Duplicate Quote',
            OpportunityId = testOpp.Id,
            Pricebook2Id = prodSet.pb.Id
        );
        insert testQuote;

        List<QuoteLineItem> batchOfQLIs = new List<QuoteLineItem>();

        batchOfQLIs.add(new QuoteLineItem(QuoteId = testQuote.Id, PricebookEntryId = prodSet.pbe.Id, Quantity = 1, UnitPrice = 4));
        batchOfQLIs.add(new QuoteLineItem(QuoteId = testQuote.Id, PricebookEntryId = prodSet.pbe2.Id, Quantity = 5, UnitPrice = 8));
        batchOfQLIs.add(new QuoteLineItem(QuoteId = testQuote.Id, PricebookEntryId = prodSet.pbe2.Id, Quantity = 2, UnitPrice = 8));
        batchOfQLIs.add(new QuoteLineItem(QuoteId = testQuote.Id, PricebookEntryId = prodSet.pbe2.Id, Quantity = 10, UnitPrice = 8));


        Test.startTest();
        Database.SaveResult[] results = Database.insert(batchOfQLIs, false);
        Test.stopTest();

        Assert.areEqual(true, results[0].isSuccess(), 'First QLI should save successfully but it didnt: ' + results[0].getErrors());
        
        for (Integer i = 1; i <= 3; i++) {
            Assert.areEqual(false, results[i].isSuccess(), 'Row ' + i + ' should have failed because it is a duplicate.');
            Assert.areEqual(1, results[i].getErrors().size(), 'Row ' + i + ' should have exactly 1 error attached.');
            String actualErrorMessage = results[i].getErrors()[0].getMessage();
        }
    }

    // TODO: Bad test path
}