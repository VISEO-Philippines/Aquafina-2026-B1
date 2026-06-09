@IsTest
private class QuoteLineItemDuplicateValidationTest {

    private static final String QUOTE_ONE_NAME = 'Test Quote One';
    private static final String QUOTE_TWO_NAME = 'Test Quote Two';

    private static final String LAPTOP_PRODUCT_NAME = 'Laptop';
    private static final String MOUSE_PRODUCT_NAME = 'Mouse';
    private static final String KEYBOARD_PRODUCT_NAME = 'Keyboard';

    private static Id salesRepUserId;

    @TestSetup
    static void setupData() {
        // Create a common sales rep user for all tests to run as
        User salesRepUser = TestDataFactory.createSalesRepUser();
        salesRepUserId = salesRepUser.Id;


        System.runAs(salesRepUser) {
            /*
             * Seed only shared parent/reference data here.
             * QuoteLineItem DML stays inside each test method so each test controls
             * the exact trigger scenario being validated.
             */
            Account accountRecord =
                TestDataFactory.createAccount();

            Opportunity opportunityRecord =
                TestDataFactory.createOpportunity(accountRecord.Id);

            Quote quoteOne =
                TestDataFactory.createQuote(opportunityRecord.Id);

            quoteOne.Name = QUOTE_ONE_NAME;

            Quote quoteTwo =
                TestDataFactory.createQuote(opportunityRecord.Id);

            quoteTwo.Name = QUOTE_TWO_NAME;

            update new List<Quote>{ quoteOne, quoteTwo };

            Product2 laptop =
                TestDataFactory.createProductWithExactName(LAPTOP_PRODUCT_NAME);

            Product2 mouse =
                TestDataFactory.createProductWithExactName(MOUSE_PRODUCT_NAME);

            Product2 keyboard =
                TestDataFactory.createProductWithExactName(KEYBOARD_PRODUCT_NAME);

            TestDataFactory.createPricebookEntry(
                laptop.Id,
                100
            );

            TestDataFactory.createPricebookEntry(
                mouse.Id,
                50
            );

            TestDataFactory.createPricebookEntry(
                keyboard.Id,
                75
            );
        }
    }

    @IsTest
    static void shouldAllowUniqueProductsOnSameQuote() {
        User salesRepUser = getSalesRepUser();

        System.runAs(salesRepUser) {
            Quote quoteRecord = getQuoteByName(QUOTE_ONE_NAME);

            PricebookEntry laptopPricebookEntry =
                getPricebookEntryByProductName(LAPTOP_PRODUCT_NAME);

            PricebookEntry mousePricebookEntry =
                getPricebookEntryByProductName(MOUSE_PRODUCT_NAME);

            List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    laptopPricebookEntry.Id,
                    100,
                    1
                ),
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    mousePricebookEntry.Id,
                    50,
                    1
                )
            };

            Test.startTest();

            Database.SaveResult[] results =
                Database.insert(quoteLineItems, false);

            Test.stopTest();

            Assert.isTrue(
                results[0].isSuccess(),
                'Laptop QLI should be inserted successfully.'
            );

            Assert.isTrue(
                results[1].isSuccess(),
                'Mouse QLI should be inserted successfully.'
            );
        }
    }

    @IsTest
    static void shouldBlockDuplicateProductAlreadyOnQuote() {
        User salesRepUser = getSalesRepUser();

        System.runAs(salesRepUser) {
            Quote quoteRecord = getQuoteByName(QUOTE_ONE_NAME);

            PricebookEntry laptopPricebookEntry =
                getPricebookEntryByProductName(LAPTOP_PRODUCT_NAME);

            QuoteLineItem existingQuoteLineItem =
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    laptopPricebookEntry.Id,
                    100,
                    1
                );

            insert existingQuoteLineItem;

            QuoteLineItem duplicateQuoteLineItem =
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    laptopPricebookEntry.Id,
                    100,
                    2
                );

            Test.startTest();

            Database.SaveResult result =
                Database.insert(duplicateQuoteLineItem, false);

            Test.stopTest();

            Assert.isFalse(
                result.isSuccess(),
                'Duplicate Product should be blocked on the same Quote.'
            );

            Assert.isTrue(
                result.getErrors()[0]
                    .getMessage()
                    .contains(LAPTOP_PRODUCT_NAME),
                'Error message should include the duplicate Product name.'
            );
        }
    }

    @IsTest
    static void shouldOnlyFailDuplicateRecordsDuringBulkInsert() {
        User salesRepUser = getSalesRepUser();

        System.runAs(salesRepUser) {
            Quote quoteRecord = getQuoteByName(QUOTE_ONE_NAME);

            PricebookEntry laptopPricebookEntry =
                getPricebookEntryByProductName(LAPTOP_PRODUCT_NAME);

            PricebookEntry mousePricebookEntry =
                getPricebookEntryByProductName(MOUSE_PRODUCT_NAME);

            List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    laptopPricebookEntry.Id,
                    100,
                    1
                ),
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    laptopPricebookEntry.Id,
                    100,
                    2
                ),
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    mousePricebookEntry.Id,
                    50,
                    1
                )
            };

            Test.startTest();

            /*
             * Partial success lets us verify row-level behavior:
             * duplicate rows fail while valid rows in the same transaction succeed.
             */
            Database.SaveResult[] results =
                Database.insert(quoteLineItems, false);

            Test.stopTest();

            Assert.areEqual(
                3,
                results.size(),
                'Bulk insert should return one SaveResult per QLI.'
            );

            Assert.isFalse(
                results[0].isSuccess(),
                'First Laptop QLI should fail because Laptop appears more than once in the same transaction.'
            );

            Assert.isFalse(
                results[1].isSuccess(),
                'Second Laptop QLI should fail because Laptop appears more than once in the same transaction.'
            );

            Assert.isTrue(
                results[2].isSuccess(),
                'Mouse QLI should succeed because it is not a duplicate.'
            );

            Assert.isTrue(
                results[0]
                    .getErrors()[0]
                    .getMessage()
                    .contains(LAPTOP_PRODUCT_NAME),
                'First duplicate error should include the duplicate Product name.'
            );

            Assert.isTrue(
                results[1]
                    .getErrors()[0]
                    .getMessage()
                    .contains(LAPTOP_PRODUCT_NAME),
                'Second duplicate error should include the duplicate Product name.'
            );
        }
    }

    @IsTest
    static void shouldValidateDuplicatesPerQuoteOnly() {
        User salesRepUser = getSalesRepUser();

        System.runAs(salesRepUser) {
            Quote quoteOne = getQuoteByName(QUOTE_ONE_NAME);
            Quote quoteTwo = getQuoteByName(QUOTE_TWO_NAME);

            PricebookEntry laptopPricebookEntry =
                getPricebookEntryByProductName(LAPTOP_PRODUCT_NAME);

            List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
                TestDataFactory.buildQuoteLineItem(
                    quoteOne.Id,
                    laptopPricebookEntry.Id,
                    100,
                    1
                ),
                TestDataFactory.buildQuoteLineItem(
                    quoteTwo.Id,
                    laptopPricebookEntry.Id,
                    100,
                    1
                )
            };

            Test.startTest();

            Database.SaveResult[] results =
                Database.insert(quoteLineItems, false);

            Test.stopTest();

            Assert.isTrue(
                results[0].isSuccess(),
                'Laptop should be allowed on Quote One.'
            );

            Assert.isTrue(
                results[1].isSuccess(),
                'Laptop should also be allowed on Quote Two because validation is scoped per Quote.'
            );
        }
    }

    @IsTest
    static void shouldAllowQuantityUpdateWhenProductDoesNotChange() {
        User salesRepUser = getSalesRepUser();

        System.runAs(salesRepUser) {
            Quote quoteRecord = getQuoteByName(QUOTE_ONE_NAME);

            PricebookEntry laptopPricebookEntry =
                getPricebookEntryByProductName(LAPTOP_PRODUCT_NAME);

            QuoteLineItem laptopQuoteLineItem =
                TestDataFactory.buildQuoteLineItem(
                    quoteRecord.Id,
                    laptopPricebookEntry.Id,
                    100,
                    1
                );

            insert laptopQuoteLineItem;

            laptopQuoteLineItem.Quantity = 5;

            Test.startTest();

            Database.SaveResult result =
                Database.update(laptopQuoteLineItem, false);

            Test.stopTest();

            Assert.isTrue(
                result.isSuccess(),
                'Quantity update should succeed because the Product did not change.'
            );
        }
    }

    @IsTest
    static void shouldHandleEmptyValidationInputs() {
        /*
         * These calls cover guard clauses for empty inputs.
         * Main business behavior is covered through real QuoteLineItem DML tests.
         */
        Test.startTest();

        QuoteLineItemValidationService.validateDuplicateProducts(
            new List<QuoteLineItem>()
        );

        List<QuoteLineItem> quoteLineItems =
            QuoteLineItemSelector.getByQuoteIds(new Set<Id>());

        List<PricebookEntry> pricebookEntries =
            QuoteLineItemSelector.getPricebookEntriesByIds(new Set<Id>());

        Test.stopTest();

        Assert.areEqual(
            0,
            quoteLineItems.size(),
            'Selector should return an empty QLI list when Quote Id input is empty.'
        );

        Assert.areEqual(
            0,
            pricebookEntries.size(),
            'Selector should return an empty Pricebook Entry list when input is empty.'
        );
    }

    private static User getSalesRepUser() {
        return [
            SELECT Id
            FROM User
            WHERE Id = :salesRepUserId
            LIMIT 1
        ];
    }

    private static Quote getQuoteByName(String quoteName) {
        return [
            SELECT
                Id,
                Name
            FROM Quote
            WHERE Name = :quoteName
            LIMIT 1
        ];
    }

    private static PricebookEntry getPricebookEntryByProductName(
        String productName
    ) {
        Id standardPricebookId = Test.getStandardPricebookId();

        return [
            SELECT
                Id,
                Product2Id,
                Product2.Name
            FROM PricebookEntry
            WHERE Product2.Name = :productName
            AND Pricebook2Id = :standardPricebookId
            LIMIT 1
        ];
    }
}