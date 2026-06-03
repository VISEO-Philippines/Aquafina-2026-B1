@IsTest
private class DuplicateProductServiceTest {

    // ---------------------------------------------------------------------------
    // Shared data — one account, pricebook, opportunity, quote, and two products:
    //   "Seeded Product"  — already has a line in the quote (for DB-duplicate tests)
    //   "Unique Product"  — has a PBE but is NOT yet in the quote (for positive-path tests)
    // ---------------------------------------------------------------------------
    @TestSetup
    static void setupData() {
        Account acc = TestDataFactory.createAccount('Duplicate Test Account');
        Pricebook2 pb = TestDataFactory.createPricebook('Duplicate Test Pricebook');

        Opportunity opp = new Opportunity(
            Name = 'Duplicate Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = pb.Id
        );
        insert opp;

        Quote q = new Quote(
            Name = 'Duplicate Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Pricebook2Id = pb.Id
        );
        insert q;

        Product2 seededProd = TestDataFactory.createProduct('Seeded Product');
        PricebookEntry seededPbe = TestDataFactory.createPricebookEntry(pb, seededProd, 100);
        TestDataFactory.createQuoteLineItem(q, seededPbe, 1, 100);

        Product2 uniqueProd = TestDataFactory.createProduct('Unique Product');
        TestDataFactory.createPricebookEntry(pb, uniqueProd, 200);
    }

    private static Quote getTestQuote() {
        return [SELECT Id FROM Quote WHERE Name = 'Duplicate Test Quote' LIMIT 1];
    }

    private static PricebookEntry getPbeByProductName(String productName) {
        return [
            SELECT Id, Product2Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2.Name = :productName
            AND Pricebook2.Name = 'Duplicate Test Pricebook'
            AND IsActive = true
            LIMIT 1
        ];
    }

    // ---------------------------------------------------------------------------
    // beforeInsert — two lines for the same product in one DML batch
    // Both rows must fail; the error message must name the product.
    // ---------------------------------------------------------------------------
    @IsTest
    static void beforeInsert_marksBothRowsWhenTheSameProductIsInsertedTwiceInOneBatch() {
        Quote q = getTestQuote();
        PricebookEntry pbe = getPbeByProductName('Unique Product');

        QuoteLineItem firstLine  = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = 1, UnitPrice = pbe.UnitPrice);
        QuoteLineItem secondLine = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = 2, UnitPrice = pbe.UnitPrice);

        Test.startTest();
        Database.SaveResult[] results = Database.insert(new List<QuoteLineItem>{ firstLine, secondLine }, false);
        Test.stopTest();

        TestAssert.isFalse(results[0].isSuccess(), 'First same-batch duplicate should fail');
        TestAssert.isFalse(results[1].isSuccess(), 'Second same-batch duplicate should fail');
        String expected = 'Product "Unique Product" already exists in this quote';
        TestAssert.equals(expected, results[0].getErrors()[0].getMessage(), 'Expected exact duplicate message on first row');
        TestAssert.equals(expected, results[1].getErrors()[0].getMessage(), 'Expected exact duplicate message on second row');
    }

    // ---------------------------------------------------------------------------
    // beforeInsert — product not in the quote yet should insert successfully,
    // even when executed as a restricted sales-rep user.
    // ---------------------------------------------------------------------------
    @IsTest
    static void beforeInsert_allowsUniqueProductInsertion() {
        Quote q = getTestQuote();
        PricebookEntry pbe = getPbeByProductName('Unique Product');
        QuoteLineItem newLine = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = 1, UnitPrice = pbe.UnitPrice);

        User salesRep = TestDataFactory.createSalesRepUser();
        Test.startTest();
        System.runAs(salesRep) {
            Database.SaveResult res = Database.insert(newLine, false);
            TestAssert.isTrue(res.isSuccess(), 'Unique product insert should succeed');
        }
        Test.stopTest();
    }

    // ---------------------------------------------------------------------------
    // beforeInsert — product already in the quote (DB duplicate) must be rejected
    // with the named-product error message.
    // ---------------------------------------------------------------------------
    @IsTest
    static void beforeInsert_blocksInsertWhenProductAlreadyExistsInDatabase() {
        Quote q = getTestQuote();
        PricebookEntry pbe = getPbeByProductName('Seeded Product');
        QuoteLineItem duplicate = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = 1, UnitPrice = pbe.UnitPrice);

        Test.startTest();
        Database.SaveResult result = Database.insert(duplicate, false);
        Test.stopTest();

        TestAssert.isFalse(result.isSuccess(), 'Insert of a product already in the quote should fail');
        String expected = 'Product "Seeded Product" already exists in this quote';
        TestAssert.equals(expected, result.getErrors()[0].getMessage(), 'Expected DB-duplicate error message');
    }

    // ---------------------------------------------------------------------------
    // beforeUpdate — changing a line's product to one that already exists in the
    // same quote must be blocked.
    // ---------------------------------------------------------------------------
    @IsTest
    static void beforeUpdate_blocksDuplicateWhenProductChangedToExistingProduct() {
        Quote q = getTestQuote();
        PricebookEntry uniquePbe = getPbeByProductName('Unique Product');
        PricebookEntry seededPbe = getPbeByProductName('Seeded Product');

        // Add a second line with the unique product, then try to change it to the seeded product (conflict)
        QuoteLineItem lineToChange = TestDataFactory.createQuoteLineItem(q, uniquePbe, 1, uniquePbe.UnitPrice);
        lineToChange.PricebookEntryId = seededPbe.Id;
        lineToChange.Product2Id      = seededPbe.Product2Id;

        Test.startTest();
        Database.SaveResult result = Database.update(lineToChange, false);
        Test.stopTest();

        TestAssert.isFalse(result.isSuccess(), 'Changing a line to a duplicate product should fail');
        String expected = 'Product "Seeded Product" already exists in this quote';
        TestAssert.equals(expected, result.getErrors()[0].getMessage(), 'Expected duplicate error on product change');
    }

    // ---------------------------------------------------------------------------
    // beforeUpdate — changing a line's product to one not yet in the quote
    // must succeed.
    // ---------------------------------------------------------------------------
    @IsTest
    static void beforeUpdate_allowsProductChangeToUniqueProduct() {
        Quote q = getTestQuote();
        PricebookEntry uniquePbe = getPbeByProductName('Unique Product');

        // Change the seeded line to the unique product (not yet in the quote)
        QuoteLineItem seededLine = [SELECT Id, Product2Id FROM QuoteLineItem WHERE QuoteId = :q.Id LIMIT 1];
        seededLine.PricebookEntryId = uniquePbe.Id;
        seededLine.Product2Id       = uniquePbe.Product2Id;

        Test.startTest();
        Database.SaveResult result = Database.update(seededLine, false);
        Test.stopTest();

        TestAssert.isTrue(result.isSuccess(), 'Changing a line to a non-duplicate product should succeed');
    }

    // ---------------------------------------------------------------------------
    // beforeUpdate — updating a non-product field (e.g., Quantity) must not
    // trigger duplicate validation at all.
    // ---------------------------------------------------------------------------
    @IsTest
    static void beforeUpdate_doesNotBlockWhenProductUnchanged() {
        Quote q = getTestQuote();
        QuoteLineItem seededLine = [SELECT Id, Quantity FROM QuoteLineItem WHERE QuoteId = :q.Id LIMIT 1];
        seededLine.Quantity = 5;

        Test.startTest();
        Database.SaveResult result = Database.update(seededLine, false);
        Test.stopTest();

        TestAssert.isTrue(result.isSuccess(), 'A quantity-only update should not be blocked by duplicate validation');
    }

    // ---------------------------------------------------------------------------
    // checkDuplicateProducts — empty and null inputs must return immediately
    // without throwing an exception or performing any SOQL.
    // ---------------------------------------------------------------------------
    @IsTest
    static void checkDuplicateProducts_doesNothingForEmptyOrNullList() {
        DuplicateProductService svc = new DuplicateProductService();

        Test.startTest();
        svc.checkDuplicateProducts(new List<QuoteLineItem>());
        svc.checkDuplicateProducts(null);
        Test.stopTest();

        TestAssert.isTrue(true, 'No exception should be thrown for empty or null input');
    }
}
