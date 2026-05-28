@isTest
private class QuoteLineItemValidationTest {

    // Opportunity A - 1 Quote - 2 QuoteLineItem (1 for each pbe)
    // Opportunity B - 3 Quotes (Quote A has 2 QLI, Quote B has 1 QLI, Quote C has no QLI) >>>>> TESTING DONE HERE ON QUOTE B and C
    // Opp A ensures logic does not mix between opportunities, Opp B Quote A ensures logic does not mix between quotes
    // tests: 
    // insert qlib on B to pass
    // insert qlia on B to reject
    // insert qlib, qlib on B to get rejected
    // insert qlia, qlib on C to pass
    // insert qlia, qlib on B to partial pass (qlib)
    // insert qlia, qlia, qlib on C to partial pass (qlib)

    @TestSetup
    static void setupData(){
        // TODO: Move setup here
        User sRepFrance1 = TestDataFactory.createTestUserSalesRep('sRepFrance1@test.com','France');

        System.runAs(sRepFrance1) {
            TestDataFactory.ProdSet prodSet = TestDataFactory.generateProdSet();

            List<Opportunity> opps = TestDataFactory.generateOpportunity('TestOpp', 2); // TestOpp1, TestOpp2

            // Opp A
            List<Quote> quoteA = TestDataFactory.generateQuote('OppAQuote', opps[0].Id, prodSet.pb.Id, 1); // OppAQuote1
            TestDataFactory.generateQuoteWithLineItems('OppAQuoteA', quoteA[0].Id, opps[0].Id, new List<PriceBookEntry>{prodSet.pbe, prodSet.pbe2});

            // Opp B
            List<Quote> quotesB = TestDataFactory.generateQuote('OppBQuote', opps[1].Id, prodSet.pb.Id, 3); // OppBQuote1
            TestDataFactory.generateQuoteWithLineItems('OppBQuoteA', quotesB[0].Id, opps[1].Id, new List<PriceBookEntry>{prodSet.pbe, prodSet.pbe2});
            TestDataFactory.generateQuoteWithLineItems('OppAQuoteA', quotesB[1].Id, opps[1].Id, new List<PriceBookEntry>{prodSet.pbe});
        }
    }

    @isTest
    static void testPreventDuplicateBatchProducts() {

        // TODO: Use System.runAs for these
        // TODO: Add creation of Opportunity, Quote to TestDataFactory

        // NOTE: DONT GENERATE A NEW PRODSET HERE, JUST COPY FROM OPPA IN THE SETUP. 
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

    // TODO: Bad test path. Oh wait the above is hybrid test path,
}