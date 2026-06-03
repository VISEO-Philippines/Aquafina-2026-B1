@IsTest
public class TestDataFactory {

    public static Account createAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    public static Pricebook2 createPricebook(String name) {
        Pricebook2 pb = new Pricebook2(Name = name, IsActive = true);
        insert pb;
        return pb;
    }

    public static Product2 createProduct(String name) {
        Product2 p = new Product2(Name = name, IsActive = true);
        insert p;
        return p;
    }

    public static PricebookEntry createPricebookEntry(Pricebook2 pb, Product2 p, Decimal unitPrice) {
        // ensure standard pricebook entry exists
        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry standardPbe = new PricebookEntry(Pricebook2Id = stdPbId, Product2Id = p.Id, UnitPrice = unitPrice, IsActive = true);
        insert standardPbe;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = p.Id, UnitPrice = unitPrice, IsActive = true);
        insert pbe;
        return pbe;
    }

    public static Opportunity createOpportunity(Account acc, Id pricebookId) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity ' + String.valueOf(Datetime.now().getTime()),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = pricebookId
        );
        insert opp;
        return opp;
    }

    public static Quote createQuote(Opportunity opp, Id pricebookId) {
        Quote q = new Quote(
            Name = 'Test Quote ' + String.valueOf(Datetime.now().getTime()),
            OpportunityId = opp.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Pricebook2Id = pricebookId
        );
        insert q;
        return q;
    }

    public static QuoteLineItem createQuoteLineItem(Quote q, PricebookEntry pbe, Integer qty, Decimal unitPrice) {
        QuoteLineItem li = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Product2Id = pbe.Product2Id, Quantity = qty, UnitPrice = unitPrice);
        insert li;
        return li;
    }

    public static User createSalesRepUser() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        if (profiles.isEmpty()) {
            profiles = [SELECT Id FROM Profile LIMIT 1];
        }

        List<UserRole> roles = [SELECT Id FROM UserRole WHERE DeveloperName = 'Sales_Rep_France_South' LIMIT 1];

        String unique = String.valueOf(Datetime.now().getTime());
        User u = new User(
            Alias = 'tst' + unique.substring(0, Math.min(4, unique.length())),
            Email = 'test+' + unique + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser+' + unique + '@example.com',
            ProfileId = profiles[0].Id,
            UserRoleId = roles.isEmpty() ? null : roles[0].Id
        );
        insert u;
        return u;
    }
}
