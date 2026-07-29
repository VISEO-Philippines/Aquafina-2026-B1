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
        QuoteLineItem li = new QuoteLineItem(QuoteId = q.Id, PricebookEntryId = pbe.Id, Quantity = qty, UnitPrice = unitPrice);
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

    /**
     * Creates a manager-level user whose role is the direct parent of the given childRoleId.
     * If the child role has no existing parent, a synthetic parent role is created and
     * the child role is re-parented to it. If childRoleId is null, the manager is created
     * without a role (exemption checks will then return false in tests).
     *
     * @param childRoleId The UserRole Id representing the subordinate role (e.g. Sales Rep)
     * @return A new User inserted with the manager role assigned
     */
    public static User createManagerUser(Id childRoleId) {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        if (profiles.isEmpty()) {
            profiles = [SELECT Id FROM Profile LIMIT 1];
        }

        Id managerRoleId;

        if (childRoleId != null) {
            List<UserRole> childRoles = [SELECT Id, ParentRoleId FROM UserRole WHERE Id = :childRoleId LIMIT 1];
            if (!childRoles.isEmpty() && childRoles[0].ParentRoleId != null) {
                // Use the existing parent role
                managerRoleId = childRoles[0].ParentRoleId;
            } else {
                // Create a synthetic parent role and re-parent the child
                String unique = String.valueOf(Datetime.now().getTime());
                UserRole newParent = new UserRole(
                    Name = 'Test Manager Role ' + unique,
                    DeveloperName = 'Test_Manager_' + unique
                );
                insert newParent;
                managerRoleId = newParent.Id;

                if (!childRoles.isEmpty()) {
                    update new UserRole(Id = childRoles[0].Id, ParentRoleId = managerRoleId);
                }
            }
        }

        String unique = String.valueOf(Datetime.now().getTime());
        User mgr = new User(
            Alias            = 'mgr' + unique.substring(0, Math.min(4, unique.length())),
            Email            = 'manager+' + unique + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName         = 'ManagerUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey     = 'en_US',
            TimeZoneSidKey   = 'America/Los_Angeles',
            Username         = 'manager+' + unique + '@example.com',
            ProfileId        = profiles[0].Id,
            UserRoleId       = managerRoleId
        );
        insert mgr;
        return mgr;
    }

    /**
     * Creates a Lead with the given Status, optionally owned by ownerId
     * (a User or Queue Id). If ownerId is null, the running user owns it.
     */
    public static Lead createLead(String lastName, String status, Id ownerId) {
        String unique = String.valueOf(Datetime.now().getTime());
        Lead ld = new Lead(
            LastName         = lastName,
            Company          = 'Test Company ' + unique,
            Status           = status,
            OwnerId          = ownerId,
            Customer_Type__c = 'Restaurateur'
        );
        insert ld;
        return ld;
    }
}
