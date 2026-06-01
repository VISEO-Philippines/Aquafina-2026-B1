@isTest
private class QuoteLineItemValidationTest {

    // Opportunity A - 1 Quote - 2 QuoteLineItem (1 for each pbe)
    // Opportunity B - 3 Quotes (Quote A has 2 QLI, Quote B has 1 QLI, Quote C has no QLI) >>>>> TESTING DONE HERE ON QUOTE B and C
    // Opp A ensures logic does not mix between opportunities, Opp B Quote A ensures logic does not mix between quotes
    // tests: 
    // insert qlib on B to pass ok
    // insert qlia on B to reject ok
    // insert qlib, qlib on B to get rejected redundant
    // insert qlia, qlib on C to pass redundant
    // insert qlia, qlib on B to partial pass (qlib) redundant
    // insert qlia, qlia, qlib on C to partial pass (qlib) ok

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
            TestDataFactory.generateQuoteWithLineItems('OppBQuoteA', quotesB[1].Id, opps[1].Id, new List<PriceBookEntry>{prodSet.pbe});
        }
    }

    @isTest
    static void productNotRepeatedInsertOneAcceptedQLItest() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance1@test.com'];

        System.runAs(sRepFrance1) {
            // Get OppA QuoteLineItems for copying
            Opportunity oppA = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp1'];
            Quote qt_c = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppAQuote1'];
            List<QuoteLineItem> qlistemp = [SELECT Id, PriceBookEntryId FROM QuoteLineItem WHERE QuoteId = :qt_c.Id];
            List<Id> pbeIds = new List<Id>();
            for (QuoteLineItem qli_i : qlistemp) {
                pbeIds.add(qli_i.PricebookEntryId);
            }
            
            // Get OppB
            Opportunity oppB = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp2'];

            // Get Quote where to test
            Quote qt = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppBQuote2'];

            // What pbeid is in B (quote where to test)? can't reference this specifically without querying
            QuoteLineItem bqli = [SELECT Id, PriceBookEntryId FROM QuoteLineItem WHERE QuoteId = :qt.Id];
            Id existingPbeId = bqli.PriceBookEntryId;

            // Attempt to add in batch - misnomer, we actually add only 1 in this test
            List<QuoteLineItem> batchOfQLIs = new List<QuoteLineItem>();


            if (pbeIds[0] != existingPbeId) {
                batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[0], Quantity = 10, UnitPrice = 4));
            } else {
                batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[1], Quantity = 10, UnitPrice = 4));
            }

            Test.startTest();
            Database.SaveResult[] results = Database.insert(batchOfQLIs, false);
            Test.stopTest();

            Assert.isTrue(results[0].isSuccess(), 'Insert of QLI with unique product should succeed.');
            
        }
    }

    @isTest
    static void productNotRepeatedInsertOneRejectedQLItest() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance1@test.com'];

        System.runAs(sRepFrance1) {
            // Get OppA QuoteLineItems for copying
            Opportunity oppA = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp1'];
            Quote qt_c = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppAQuote1'];
            List<QuoteLineItem> qlistemp = [SELECT Id, PriceBookEntryId FROM QuoteLineItem WHERE QuoteId = :qt_c.Id];
            List<Id> pbeIds = new List<Id>();
            for (QuoteLineItem qli_i : qlistemp) {
                pbeIds.add(qli_i.PricebookEntryId);
            }
            
            // Get OppB
            Opportunity oppB = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp2'];

            // Get Quote where to test
            Quote qt = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppBQuote2'];
            List<QuoteLineItem> dbqlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :qt.Id];

            Assert.areEqual(1, dbqlis.size(), 'OppBQuoteB not initialized properly.');

            // Attempt to add in batch
            List<QuoteLineItem> batchOfQLIs = new List<QuoteLineItem>();

            batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[0], Quantity = 10, UnitPrice = 4));
            batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[1], Quantity = 10, UnitPrice = 4));

            Test.startTest();
            Database.SaveResult[] results = Database.insert(batchOfQLIs, false);
            Test.stopTest();

            Assert.isFalse(results[0].isSuccess() && results[1].isSuccess(), 'An insert of a QLI with existing product in the database has succeeded but should have failed.');
        }
    }

    @isTest
    static void productNotRepeatedInsertMultipleQLItest() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance1@test.com'];

        System.runAs(sRepFrance1) {
            // Get OppA QuoteLineItems for copying
            Opportunity oppA = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp1'];
            Quote qt_c = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppAQuote1'];
            List<QuoteLineItem> qlistemp = [SELECT Id, PriceBookEntryId FROM QuoteLineItem WHERE QuoteId = :qt_c.Id];
            List<Id> pbeIds = new List<Id>();
            for (QuoteLineItem qli_i : qlistemp) {
                pbeIds.add(qli_i.PricebookEntryId);
            }
            
            // Get OppB
            Opportunity oppB = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp2'];

            // Get Quote where to test
            Quote qt = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppBQuote3'];

            List<QuoteLineItem> batchOfQLIs = new List<QuoteLineItem>();

            batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[0], Quantity = 1, UnitPrice = 4));
            batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[1], Quantity = 5, UnitPrice = 8));
            batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[1], Quantity = 2, UnitPrice = 8));
            batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[1], Quantity = 10, UnitPrice = 8));


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
    }

    // TODO: SWITCH THIS TO UPDATE, try inserting
    @isTest
    static void productNotRepeatedUpdateAndInsertAcceptedQLI() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance1@test.com'];

        System.runAs(sRepFrance1) {
            // Get OppA QuoteLineItems for copying
            Opportunity oppA = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp1'];
            Quote qt_c = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppAQuote1'];
            List<QuoteLineItem> qlistemp = [SELECT Id, PriceBookEntryId FROM QuoteLineItem WHERE QuoteId = :qt_c.Id];
            List<Id> pbeIds = new List<Id>();
            for (QuoteLineItem qli_i : qlistemp) {
                pbeIds.add(qli_i.PricebookEntryId);
            }
            
            // Get OppB
            Opportunity oppB = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp2'];

            // Get Quote where to test
            Quote qt = [SELECT Id, PriceBook2Id FROM Quote WHERE Name = 'OppBQuote2'];

            // What pbeid is in B (quote where to test)? can't reference this specifically without querying
            QuoteLineItem bqli = [SELECT Id, PriceBookEntryId, Quantity FROM QuoteLineItem WHERE QuoteId = :qt.Id];
            Id existingPbeId = bqli.PriceBookEntryId;

            // Attempt to add in batch - misnomer, we actually add only 1 in this test
            List<QuoteLineItem> batchOfQLIs = new List<QuoteLineItem>();

            bqli.Quantity = bqli.Quantity+3;
            
            if (pbeIds[0] == existingPbeId) {
                batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[1], Quantity = 10, UnitPrice = 4));
            } else {
                batchOfQLIs.add(new QuoteLineItem(QuoteId = qt.Id, PricebookEntryId = pbeIds[0], Quantity = 10, UnitPrice = 4));
            }
            batchOfQLIs.add(bqli);

            Test.startTest();
            Database.UpsertResult[] results = Database.upsert(batchOfQLIs, false);
            Test.stopTest();

            Assert.isTrue(results[0].isSuccess() && results[1].isSuccess(), 'Updated one QuoteLineItem to another Product, Inserted another QuoteLineItem to old Product, both must be accepted.');

        }
    }
}