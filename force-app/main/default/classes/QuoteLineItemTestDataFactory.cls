@IsTest

public with sharing class QuoteLineItemTestDataFactory {

    public static Account createAccount() {
        Account accountRecord = new Account(
            Name = 'Test Account'
        );

        insert accountRecord;
        return accountRecord;
    }

    public static Opportunity createOpportunity(Id accountId) {
        Opportunity opportunityRecord = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accountId,
            Pricebook2Id = Test.getStandardPricebookId()
        );

        insert opportunityRecord;
        return opportunityRecord;
    }

    public static Quote createQuote(Id opportunityId) {
        Quote quoteRecord = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunityId,
            Pricebook2Id = Test.getStandardPricebookId()
        );

        insert quoteRecord;
        return quoteRecord;
    }

    public static Product2 createProduct(String productName){
        Product2 productRecord = new Product2(
            Name = productName,
            IsActive = true
        );
        insert productRecord;
        return productRecord;
    }

    public static PricebookEntry createPricebookEntry(Id productId, Decimal unitPrice){
        PricebookEntry pricebookEntryRecord = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );

        insert pricebookEntryRecord;
        return pricebookEntryRecord;
    }

    public static QuoteLineItem buildQuoteLineItem(
        Id quoteId,
        Id pricebookEntryId,
        Decimal unitPrice,
        Integer quantity
    ){
        return new QuoteLineItem(
            QuoteId = quoteId,
            PricebookEntryId = pricebookEntryId,
            UnitPrice = unitPrice,
            Quantity = quantity
        );
    }
}