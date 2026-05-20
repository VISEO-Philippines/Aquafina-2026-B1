@IsTest
public with sharing class TestDataFactory {

    public static User createSalesRepUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        String unique = String.valueOf(System.currentTimeMillis());

        User u = new User(
            Username = 'testuser' + unique + '@example.com',
            Email = 'testuser' + unique + '@example.com',
            LastName = 'Test',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Manila',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }

    //Create Account
    public static Account createAccount() {
        String unique = String.valueOf(System.currentTimeMillis());
        return createAccount('Test Account ' + unique);
    }

    public static Account createAccount(String name) {
        Account acc = new Account(
            Name = name
        );
        insert acc;
        return acc;
    }

    //Create Opportunity with reference to Account
    public static Opportunity createOpportunity(Id accountId){
    return createOpportunity(accountId, 'Prospecting');
    }

    public static Opportunity createOpportunity(Id accountId, String stage){
        String unique = String.valueOf(System.currentTimeMillis());
        Opportunity opp = new Opportunity(
             Name = 'Test Opportunity ' + unique,
             StageName = stage,
             CloseDate = Date.today(),
             AccountId = accountId
        );
        insert opp;
        return opp;
    }


    //Create Product
    
    public static Product2 createProduct() {
        return createProduct('Test Product');
    }

    public static Product2 createProduct(String name) {
        String unique = String.valueOf(System.currentTimeMillis());
        Product2 prod = new Product2(
            Name = name + ' ' + unique,
            IsActive = true
        );
        insert prod;
        return prod;
    }

    //Create PricebookEntry for the Product
    public static PricebookEntry createPricebookEntry(Id productId){
        return createPricebookEntry(productId, 100);
    }
    
    public static PriceBookEntry createPricebookEntry(Id productId, Decimal unitPrice){
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }
    

    //Create Quote
    public static Quote createQuote(Id opportunityId){
        return createQuote(opportunityId, 'Draft');
    }

    public static Quote createQuote(Id opportunityId, String status){
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunityId,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = status
        );
        insert q;
        return q;
    }

    

    //Create QuoteLineItem
    public static QuoteLineItem createQuoteLineItem(Id quoteId, Id pbeId){
    return createQuoteLineItem(quoteId, pbeId, 100);
    }

    public static QuoteLineItem createQuoteLineItem(Id quoteId, Id pbeId, Decimal unitPrice){
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quoteId,
            Quantity = 1,
            UnitPrice = unitPrice,
            PricebookEntryId = pbeId
        );
        insert qli;
        return qli;
    }
}