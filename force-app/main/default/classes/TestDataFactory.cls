@isTest
public with sharing class TestDataFactory {
    // implement common test users to be used by tests here
    public static User createTestUserSalesRep(String uname, String region) {
        // Get User Profile for Sales Representative
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Profile' LIMIT 1];
        
        // Get User Role (== is case-insensitive)
        UserRole role;
        if (region == 'France') {
            role = [SELECT Id FROM UserRole WHERE Name = 'FR Sales Representative' LIMIT 1];
        } else if (region == 'Spain') {
            role = [SELECT Id FROM UserRole WHERE Name = 'ES Sales Representative' LIMIT 1];
        } else {
            role = [SELECT Id FROM UserRole WHERE Name = 'FR Sales Representative' LIMIT 1];
        }
        
        Integer rand = Math.mod(Math.abs(Crypto.getRandomInteger()), 9000) + 1000;
        // Create unique username
        String uniqueEmail = 'salesrep_' + region.replaceAll('\\s','') + '_' 
                                + rand
                                + '@example.com';

        // Create the user with all required fields
        User u = new User(
            FirstName = 'SalesRep',
            LastName = region,
            Alias = 'srep' + region.substring(0,1).toLowerCase(),
            Username = uname,
            Email = uniqueEmail,              // can be same as username
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Manila',
            ProfileId = p.Id,
            UserRoleId = role.Id
        );

        insert u;

        return u;
    }
	
    // TODO: Check if it is possible to refactor this to easily test role-based sharing instead of Territory__c field based sharing
    // perhaps allow territory to be null? <- recheck in org
    public static Lead createTestLead(String email, String territory, Id ownerId) {
        // substring is overloaded (start end) like python [start:end] , OR (start) [start:]
        String formattedTerritory = String.isNotBlank(territory) ? territory.substring(0, 1).toUpperCase() + territory.substring(1) : territory;
        Integer rand = Math.mod(Math.abs(Crypto.getRandomInteger()), 9000) + 1000;
        Lead testLead = new Lead(
            FirstName = 'Tessie' + rand,
            LastName = 'Coder' + rand,
            Company = 'Test Solutions Inc.' + rand,
            Status = 'In Progress',
            LeadSource = 'Web',
            Email = email,
            Territory__c = formattedTerritory,
            OwnerId = ownerId
        );

        insert testLead;

        return testLead;
    }
    
    // There might be some standards for making struct-like classes like these.
    // also this might be visible to non-test classes which it shouldnt be for now
    public class ProdSet{
        public Product2 prod;
        public Product2 prod2;
        public PriceBookEntry stdpbe;
        public PriceBookEntry stdpbe2;
        public PriceBookEntry pbe;
        public PriceBookEntry pbe2;
        public PriceBook2 pb;
    }
    
    public static ProdSet generateProdSet() {
        ProdSet prodSet = new ProdSet();
        Product2 prod = new Product2(Name = 'Test Water Bottle', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Test Water Bottle Two', IsActive = true);
        insert new List<Product2>{prod, prod2};
        prodSet.prod = prod;
        prodSet.prod2 = prod2;
        Id stdPbId = Test.getStandardPricebookId();
    
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = stdPbId, 
            Product2Id = prod.Id, 
            UnitPrice = 3, 
            IsActive = true
        );
        PricebookEntry stdPbe2 = new PricebookEntry(
            Pricebook2Id = stdPbId, 
            Product2Id = prod2.Id, 
            UnitPrice = 6, 
            IsActive = true
        );
        insert new List<PriceBookEntry>{stdPbe, stdPbe2};
		prodSet.stdpbe = stdPbe;
        prodSet.stdpbe2 = stdPbe2;
        
        Pricebook2 pb = new Pricebook2(
            Name = 'Special Discount PB',
            IsActive = true
        );
        insert pb;
        prodSet.pb = pb;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = prod.Id, 
            UnitPrice = 4, IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = prod2.Id, 
            UnitPrice = 8, IsActive = true
        );
        insert new List<PriceBookEntry>{pbe, pbe2};
        prodSet.pbe = pbe;
        prodSet.pbe2 = pbe2;
        
		return prodSet;
    }
}