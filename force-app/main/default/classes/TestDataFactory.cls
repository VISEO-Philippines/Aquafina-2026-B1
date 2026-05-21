@isTest
public with sharing class TestDataFactory {
    // implement common test users to be used by tests here
    public static User createTestUserSalesRep(String region) {
        // Get User Profile for Sales Representative
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Profile' LIMIT 1];
        // Get User Role (== is case-insensitive)
        if (region == 'france') {
            UserRole role = [SELECT Id FROM UserRole WHERE Name = 'FR Sales Representative' LIMIT 1];
        } else if (region == 'spain') {
            UserRole role = [SELECT Id FROM UserRole WHERE Name = 'ES Sales Representative' LIMIT 1];
        } else {
            UserRole role = [SELECT Id FROM UserRole WHERE Name = 'FR Sales Representative' LIMIT 1];
        }
        
        Integer rand = Math.mod(Math.abs(Crypto.getRandomInteger()), 9000) + 1000;
        // Create unique username
        String uniqueUsername = 'salesrep_' + region.replaceAll('\\s','') + '_' 
                                + rand
                                + '@example.com';

        // Create the user with all required fields
        User u = new User(
            FirstName = 'SalesRep',
            LastName = region,
            Alias = 'srep' + region.substring(0,1).toLowerCase(),
            Username = uniqueUsername,
            Email = uniqueUsername,              // can be same as username
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

    public static Lead createTestLead(String territory, Id ownerId) {
        // substring is overloaded (start end) like python [start:end] , OR (start) [start:]
        String formatted = String.isNotBlank(territory) ? original.substring(0, 1).toUpperCase() + original.substring(1) : original;
        Integer rand = Math.mod(Math.abs(Crypto.getRandomInteger()), 9000) + 1000;
        Lead testLead = new Lead(
            FirstName = 'Tessie' + rand,
            LastName = 'Coder' + rand,
            Company = 'Test Solutions Inc.' + rand,
            Status = 'To Contact',
            LeadSource = 'Web',
            Email = 'tcoder'+ rand +'@example.com',
            Territory__c = territory,
            OwnerId = ownerId
        );

        insert testLead;

        return testLead;
    }

}