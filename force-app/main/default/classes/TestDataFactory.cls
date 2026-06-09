@IsTest
public with sharing class TestDataFactory {

    public static User createSalesRepUser() {
        Id profileId = getAnyProfileId();

        String unique = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String alias = 'tuser' + unique.substring(0, 3);
        if (alias.length() > 8) {
            alias = alias.substring(0, 8);
        }

        User userRecord = new User(
            Username = 'testuser' + unique + '@example.com',
            Email = 'testuser' + unique + '@example.com',
            LastName = 'Test',
            Alias = alias,
            TimeZoneSidKey = 'Asia/Manila',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profileId,
            LanguageLocaleKey = 'en_US'
        );

        insert userRecord;
        return userRecord;
    }

    private static Id getAnyProfileId() {
        Id profileId = UserInfo.getProfileId();

        if (profileId != null) {
            return profileId;
        }

        List<Profile> profiles = [
            SELECT Id
            FROM Profile
            LIMIT 1
        ];

        if (profiles.isEmpty()) {
            throw new System.AssertException('No Profile found in test org.');
        }

        return profiles[0].Id;
    }

    // Create Account
    public static Account createAccount() {
        String unique = String.valueOf(System.currentTimeMillis());
        return createAccount('Test Account ' + unique);
    }

    public static Account createAccount(String name) {
        Account accountRecord = new Account(
            Name = name
        );

        insert accountRecord;
        return accountRecord;
    }

    // Create Opportunity with reference to Account
    public static Opportunity createOpportunity(Id accountId) {
        return createOpportunity(accountId, 'Prospecting');
    }

    public static Opportunity createOpportunity(Id accountId, String stage) {
        String unique = String.valueOf(System.currentTimeMillis());

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Test Opportunity ' + unique,
            StageName = stage,
            CloseDate = Date.today(),
            AccountId = accountId,
            Pricebook2Id = Test.getStandardPricebookId()
        );

        insert opportunityRecord;
        return opportunityRecord;
    }

    // Create Product
    public static Product2 createProduct() {
        return createProduct('Test Product');
    }

    public static Product2 createProduct(String name) {
        String unique = String.valueOf(System.currentTimeMillis());

        Product2 productRecord = new Product2(
            Name = name + ' ' + unique,
            IsActive = true
        );

        insert productRecord;
        return productRecord;
    }

    public static Product2 createProductWithExactName(String name) {
        Product2 productRecord = new Product2(
            Name = name,
            IsActive = true
        );

        insert productRecord;
        return productRecord;
    }

    // Create PricebookEntry for the Product
    public static PricebookEntry createPricebookEntry(Id productId) {
        return createPricebookEntry(productId, 100);
    }

    public static PricebookEntry createPricebookEntry(
        Id productId,
        Decimal unitPrice
    ) {
        PricebookEntry pricebookEntryRecord = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );

        insert pricebookEntryRecord;
        return pricebookEntryRecord;
    }

    // Create Quote
    public static Quote createQuote(Id opportunityId) {
        return createQuote(opportunityId, 'Draft');
    }

    public static Quote createQuote(Id opportunityId, String status) {
        Quote quoteRecord = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunityId,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = status
        );

        insert quoteRecord;
        return quoteRecord;
    }

    // Create QuoteLineItem
    public static QuoteLineItem createQuoteLineItem(Id quoteId, Id pbeId) {
        return createQuoteLineItem(quoteId, pbeId, 100);
    }

    public static QuoteLineItem createQuoteLineItem(
        Id quoteId,
        Id pbeId,
        Decimal unitPrice
    ) {
        QuoteLineItem quoteLineItemRecord = buildQuoteLineItem(
            quoteId,
            pbeId,
            unitPrice,
            1
        );

        insert quoteLineItemRecord;
        return quoteLineItemRecord;
    }

    public static QuoteLineItem buildQuoteLineItem(
        Id quoteId,
        Id pbeId,
        Decimal unitPrice,
        Integer quantity
    ) {
        return new QuoteLineItem(
            QuoteId = quoteId,
            Quantity = quantity,
            UnitPrice = unitPrice,
            PricebookEntryId = pbeId
        );
    }
}