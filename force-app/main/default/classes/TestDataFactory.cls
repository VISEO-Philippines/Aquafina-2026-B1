@IsTest
public class TestDataFactory {

    //Create Account
    public static Account createAccount() {
        Account acc = new Account(Name='Test Account');
        insert acc;
        return acc;
    }

    //Create Opportunity with reference to Account
    public static Opportunity createOpportunity(Id accountId){
        Opportunity opp = new Opportunity(
             Name = 'Test Opportunity',
             StageName = 'Prospecting',
             CloseDate = Date.today(),
             AccountId = accountId
        );
        insert opp;
        return opp;
    }

    //Create Product
    public static Product2 createProduct() {
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;
        return prod;
    }

    //Create PricebookEntry for the Product
    public static PriceBookEntry createPricebookEntry(Id productId){
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    //Create Quote
    public static Quote createQuote(Id opportunityId){
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opportunityId,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;
        return q;
    }

    //Create QuoteLineItem
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