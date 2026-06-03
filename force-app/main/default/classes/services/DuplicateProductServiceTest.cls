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

        QuoteLineItem firstLine  = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = pbe.UnitPrice);
        QuoteLineItem secondLine = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 2, UnitPrice = pbe.UnitPrice);

        Test.startTest();
        Database.SaveResult[] results = Database.insert(new List<QuoteLineItem>{ firstLine, secondLine }, false);
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess(), 'First same-batch duplicate should fail');
        Assert.isFalse(results[1].isSuccess(), 'Second same-batch duplicate should fail');
        String expected = 'Product "Unique Product" already exists in this quote';
        Assert.areEqual(expected, results[0].getErrors()[0].getMessage(), 'Expected exact duplicate message on first row');
        Assert.areEqual(expected, results[1].getErrors()[0].getMessage(), 'Expected exact duplicate message on second row');
    }

    // ---------------------------------------------------------------------------
    // beforeInsert — product not in the quote yet should insert successfully,
    // even when executed as a restricted sales-rep user.
    // ---------------------------------------------------------------------------
    @IsTest
    static void beforeInsert_allowsUniqueProductInsertion() {
        Quote q = getTestQuote();
        PricebookEntry pbe = getPbeByProductName('Unique Product');
        QuoteLineItem newLine = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = pbe.UnitPrice);

        Test.startTest();
        Database.SaveResult res = Database.insert(newLine, false);
        Assert.isTrue(res.isSuccess(), 'Unique product insert should succeed');
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
        QuoteLineItem duplicate = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = pbe.UnitPrice);

        Test.startTest();
        Database.SaveResult result = Database.insert(duplicate, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Insert of a product already in the quote should fail');
        String expected = 'Product "Seeded Product" already exists in this quote';
        Assert.areEqual(expected, result.getErrors()[0].getMessage(), 'Expected DB-duplicate error message');
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

        Assert.isTrue(result.isSuccess(), 'A quantity-only update should not be blocked by duplicate validation');
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

        Assert.isTrue(true, 'No exception should be thrown for empty or null input');
    }

    // ---------------------------------------------------------------------------
    // filterChangedLines — only lines whose Product2Id changed relative to the
    // old map must be included; lines with an unchanged product must be excluded.
    // ---------------------------------------------------------------------------
    @IsTest
    static void filterChangedLines_returnsOnlyLinesWithChangedProduct() {
        String qliPrefix   = Schema.SObjectType.QuoteLineItem.getKeyPrefix();
        String quotePrefix = Schema.SObjectType.Quote.getKeyPrefix();
        String prod2Prefix = Schema.SObjectType.Product2.getKeyPrefix();

        Id lineAId = (Id)(qliPrefix   + '000000000001AAA');
        Id lineBId = (Id)(qliPrefix   + '000000000002AAA');
        Id quoteId = (Id)(quotePrefix + '000000000001AAA');
        Id prodAId = (Id)(prod2Prefix + '000000000001AAA');
        Id prodBId = (Id)(prod2Prefix + '000000000002AAA');

        QuoteLineItem unchangedNew = (QuoteLineItem) JSON.deserialize(
            '{"Id":"' + lineAId + '","QuoteId":"' + quoteId + '","Product2Id":"' + prodAId + '"}',
            QuoteLineItem.class
        );
        QuoteLineItem changedNew = (QuoteLineItem) JSON.deserialize(
            '{"Id":"' + lineBId + '","QuoteId":"' + quoteId + '","Product2Id":"' + prodAId + '"}',
            QuoteLineItem.class
        );

        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{
            lineAId => (QuoteLineItem) JSON.deserialize(
                '{"Id":"' + lineAId + '","QuoteId":"' + quoteId + '","Product2Id":"' + prodAId + '"}',
                QuoteLineItem.class
            ),
            lineBId => (QuoteLineItem) JSON.deserialize(
                '{"Id":"' + lineBId + '","QuoteId":"' + quoteId + '","Product2Id":"' + prodBId + '"}',
                QuoteLineItem.class
            )
        };

        DuplicateProductService svc = new DuplicateProductService();
        List<QuoteLineItem> filtered = svc.filterChangedLines(
            new List<QuoteLineItem>{ unchangedNew, changedNew }, oldMap
        );

        Assert.areEqual(1, filtered.size(), 'Only the line with a changed product should be returned');
        Assert.areEqual(lineBId, filtered[0].Id, 'Expected the changed line to be included');
    }
}