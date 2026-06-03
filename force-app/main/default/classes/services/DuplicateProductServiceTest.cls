@IsTest
private class DuplicateProductServiceTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Duplicate Product Test Account');
        insert acc;

        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Duplicate Product Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        Opportunity opp = new Opportunity(
            Name = 'Duplicate Product Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = acc.Id,
            Pricebook2Id = testPricebook.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Duplicate Product Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Pricebook2Id = testPricebook.Id
        );
        insert q;

        Product2 duplicateProduct = new Product2(
            Name = 'Duplicate Product A',
            IsActive = true
        );
        insert duplicateProduct;

        Product2 uniqueProduct = new Product2(
            Name = 'Unique Product B',
            IsActive = true
        );
        insert uniqueProduct;

        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry standardDuplicatePbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = duplicateProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardDuplicatePbe;

        PricebookEntry duplicatePbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = duplicateProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert duplicatePbe;

        PricebookEntry standardUniquePbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = uniqueProduct.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert standardUniquePbe;

        PricebookEntry uniquePbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = uniqueProduct.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert uniquePbe;

        QuoteLineItem existingLine = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = duplicatePbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert existingLine;
    }

    @IsTest
    static void beforeInsert_reportsEveryDuplicateRecordInTheBatch() {
        Quote quote = [
            SELECT Id
            FROM Quote
            WHERE Name = 'Duplicate Product Test Quote'
            LIMIT 1
        ];

        Map<String, Id> pbeByProductName = new Map<String, Id>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2.Name
            FROM PricebookEntry
            WHERE Pricebook2.Name = 'Duplicate Product Test Pricebook'
        ]) {
            pbeByProductName.put(pbe.Product2.Name, pbe.Id);
        }

        QuoteLineItem firstDuplicate = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbeByProductName.get('Duplicate Product A'),
            Quantity = 2,
            UnitPrice = 100
        );

        QuoteLineItem secondDuplicate = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbeByProductName.get('Duplicate Product A'),
            Quantity = 3,
            UnitPrice = 100
        );

        QuoteLineItem uniqueLine = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbeByProductName.get('Unique Product B'),
            Quantity = 1,
            UnitPrice = 200
        );

        Test.startTest();
        Database.SaveResult[] results = Database.insert(
            new List<QuoteLineItem>{ firstDuplicate, secondDuplicate, uniqueLine },
            false
        );
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Expected one result per attempted insert');
        System.assertEquals(false, results[0].isSuccess(), 'First duplicate should fail');
        System.assertEquals(false, results[1].isSuccess(), 'Second duplicate should also fail');
        System.assertEquals(true, results[2].isSuccess(), 'Unique record should still be inserted');
        System.assertEquals(
            'Product already exists in this quote',
            results[0].getErrors()[0].getMessage(),
            'Expected the duplicate error message on the first record'
        );
        System.assertEquals(
            'Product already exists in this quote',
            results[1].getErrors()[0].getMessage(),
            'Expected the duplicate error message on the second record'
        );
    }

    @IsTest
    static void beforeInsert_marksBothRowsWhenTheSameProductIsInsertedTwiceInOneBatch() {
        Account acc = new Account(Name = 'Batch Duplicate Account');
        insert acc;

        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Batch Duplicate Pricebook',
            IsActive = true
        );
        insert testPricebook;

        Opportunity opp = new Opportunity(
            Name = 'Batch Duplicate Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Pricebook2Id = testPricebook.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Batch Duplicate Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Pricebook2Id = testPricebook.Id
        );
        insert q;

        Product2 product = new Product2(Name = 'Batch Duplicate Product', IsActive = true);
        insert product;

        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = product.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert standardPbe;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert pbe;

        QuoteLineItem firstLine = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 150
        );

        QuoteLineItem secondLine = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 150
        );

        Test.startTest();
        Database.SaveResult[] results = Database.insert(
            new List<QuoteLineItem>{ firstLine, secondLine },
            false
        );
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess(), 'First same-batch duplicate should fail');
        System.assertEquals(false, results[1].isSuccess(), 'Second same-batch duplicate should fail');
        System.assertEquals(
            'Product already exists in this quote',
            results[0].getErrors()[0].getMessage(),
            'Expected the duplicate error message on the first same-batch row'
        );
        System.assertEquals(
            'Product already exists in this quote',
            results[1].getErrors()[0].getMessage(),
            'Expected the duplicate error message on the second same-batch row'
        );
    }
}
