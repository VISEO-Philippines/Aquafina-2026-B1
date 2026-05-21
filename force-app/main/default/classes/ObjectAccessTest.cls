@IsTest
public with sharing class ObjectAccessTest {

    // This test checks if record level access is implemented
    // correctly by checking if a salesrep in a territory can
    // access records from another territory.

    private static void switchUser(User fromuser, User touser) {
        if (fromuser.IsActive) {
            fromuser.IsActive = true;
            update fromuser;
        }
        if (!touser.IsActive) {
            touser.IsActive = true;
            update touser;
        }
    }

    @TestSetup
    static void setupData(){
        User sRepFrance1 = TestDataFactory.createTestUserSalesRep('sRepFrance1@test.com', 'France'); //[SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];
        User sRepSpain1 = TestDataFactory.createTestUserSalesRep('sRepSpain1@test.com', 'Spain');    //[SELECT Id, IsActive FROM User WHERE Alias = 'ESEREP'];
        User sRepFrance2 = TestDataFactory.createTestUserSalesRep('sRepFrance2@test.com', 'France'); //[SELECT Id, IsActive FROM User WHERE Alias = 'FRSREP'];
        User sRepSpain2 = TestDataFactory.createTestUserSalesRep('sRepSpain2@test.com', 'Spain');    //[SELECT Id, IsActive FROM User WHERE Alias = 'ESWREP'];

        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }

        System.runAs(sRepFrance1) {
            Lead frenchTestLead1 = TestDataFactory.createTestLead('frtestlead1@example.com','France', sRepFrance1.Id);
            Lead frenchTestLead2 = TestDataFactory.createTestLead('frtestlead2@example.com','France', sRepFrance1.Id);
        }        

        switchUser(sRepFrance1, sRepSpain1);

        System.runAs(sRepSpain1) {
            Lead spanishTestLead1 = TestDataFactory.createTestLead('estestlead1@example.com','Spain', sRepSpain1.Id);
        }
        
        switchUser(sRepSpain1, sRepSpain2);
		
        System.runAs(sRepSpain2) {
            Lead spanishTestLead2 = TestDataFactory.createTestLead('estestlead2@example.com','Spain', sRepSpain2.Id);
        }
        
        if(sRepSpain2.IsActive) {
            sRepSpain2.IsActive = false;
            update sRepFrance2;
        }
    }
    
    // This test ensures that leads are shared within their respective regions (France or Spain) using the Territory field
    @IsTest
    public static void testSalesRepAccessOnLeads() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance1@test.com'];
        User sRepSpain1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepSpain1@test.com'];
        User sRepFrance2 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance2@test.com'];
        User sRepSpain2 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepSpain2@test.com'];


        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }

        System.runAs(sRepFrance1) {
            List<Lead> leads_f1 = [SELECT Id FROM Lead WHERE Email = 'frtestlead1@example.com' OR Email = 'frtestlead2@example.com'];

            Assert.areEqual(2, leads_f1.size(), 'FRNREP leads not properly initialized.');
        }

        switchUser(sRepFrance1, sRepSpain1);

        System.runAs(sRepSpain1) {
            List<Lead> leads_s1 = [SELECT Id FROM Lead WHERE Email = 'estestlead1@example.com'];

            Assert.areEqual(1, leads_s1.size(), 'ESEREP lead not properly initialized.');
        }

        Test.startTest();
        switchUser(sRepSpain1, sRepFrance2);
        // FRANCE REP ONE SHOULD HAVE 2 LEADS FROM THE 2 LEADS ADDED BY FRANCE REP ONE
        System.runAs(sRepFrance2) {
            Integer leads = [SELECT Count() FROM Lead WHERE Territory__c='France'];
            Integer spainLeads = [SELECT COUNT() FROM Lead WHERE Territory__c = 'Spain'];

            Assert.areEqual(2, leads, 'Initialized leads are not visible to Sales Rep in the same region (sRepFrance2 cannot see leads from sRepFrance1).');
            Assert.areEqual(0,spainLeads, 'Initialized leads are visible to users who shouldn\'t have visibility. (sRepFrance2 can see leads from Spanish teams)');
        }
        switchUser(sRepFrance2, sRepSpain2);
        // ADD ONE LEAD TO SPAIN, MUST SEE 2 LEADS FROM 1 LEAD ADDED BY SPAIN REP ONE AND ANOTHER ADDED BY SELF
        System.runAs(sRepSpain2) {
            List<Lead> leads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE Territory__c = 'Spain'];
                        
            Assert.areEqual(2, leads.size(), 'Initialized leads don\t have the correct visibility (sRepSpain2 must see two leads but currently sees more OR less than it should)');
            System.debug('Leads visible to sRepSpain2: ' + leads);

            Integer franceLeads = [SELECT COUNT() FROM Lead WHERE Territory__c = 'France'];
            Assert.areEqual(0,franceLeads, 'Initialized leads don\t have the correct visibility (sRepSpain2 must not see leads from French reps)');
        }
        if(sRepSpain2.IsActive) {
            sRepSpain2.IsActive = false;
            update sRepSpain2;
        }
    }

    // This test ensures that Accounts, Contacts, and Opportunities are not shared.
    @IsTest
    public static void testSalesRepAccessOnAccOppCon() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance1@test.com'];
        User sRepSpain1 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepSpain1@test.com'];
        User sRepFrance2 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepFrance2@test.com'];
        User sRepSpain2 = [SELECT Id, IsActive FROM User WHERE Username = 'sRepSpain2@test.com'];
        
        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }
        if(!sRepFrance2.IsActive) {
            sRepFrance2.IsActive = true;
            update sRepFrance2;
        }
        
        Id accountId;
        Id contactId;
        Id opportunityId;

        // Get a Lead not owned by sRepFrance1 but by his co-role in the same region
        // convert the lead and check if the original lead owner can see the resulting opportunity, account, contact
        System.runAs(sRepFrance2) {
            List<Lead> leads = [SELECT Id FROM Lead WHERE Email = 'frtestlead1@example.com'];

            Assert.areEqual(1, leads.size(), 'No available leads passing criteria: sRepFrance2(FRSREP) must see a Lead owned by sRepFrance1(FRNREP)');
            
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leads[0].Id);
            lc.setConvertedStatus('Qualified');
            lc.setOwnerId(sRepFrance2.Id);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
			
			Assert.isTrue(lcr.isSuccess(), 'Conversion Error. Was not able to convert lead.');
            
            accountId = lcr.getAccountId();
            contactId = lcr.getContactId();
            opportunityId = lcr.getOpportunityId();
            
            System.debug('Account Created: ' + accountId);
            System.debug('Contact Created: ' + contactId);
            System.debug('Opportunity Created: ' + opportunityId);
        }

        Test.startTest();
        // Check if sRepFrance1 can see the Opp, Account, Contact converted by sRepFrance1
        System.runAs(sRepFrance1) {
            List<Opportunity> matched_opp = [SELECT OwnerId FROM Opportunity WHERE Id = :opportunityId];
            List<Account> matched_acc = [SELECT OwnerId FROM Account WHERE Id = :accountId];
            List<Contact> matched_con = [SELECT OwnerId FROM Contact WHERE Id = :contactId];
            
            if (matched_opp.size() > 0) {
                System.debug('ERROR: sRepFrance1 with ID: '+ sRepFrance1.Id +' found a matched opp with ownerID ' + matched_opp[0].OwnerId);
            }
            
            Assert.areEqual(0, matched_opp.size(), 'Found opp when opp should not be visible.');
            Assert.areEqual(0,matched_acc.size(), 'Found acc when acc should not be visible.');
            Assert.areEqual(0,matched_con.size(), 'Found con when con should not be visible.');
        }

        // Check if it still exists in sRepFrance1 just to be sure
        
        System.runAs(sRepFrance2) {
            Integer matched_opp = [SELECT COUNT() FROM Opportunity WHERE Id = :opportunityId];
            Integer matched_acc = [SELECT COUNT() FROM Account WHERE Id = :accountId];
            Integer matched_con = [SELECT COUNT() FROM Contact WHERE Id = :contactId];
			
            Assert.areEqual(1,matched_opp, 'Created opportunity disappeared between user switches on ObjectAccessTest');
            Assert.areEqual(1,matched_acc, 'Created account disappeared between user switches on ObjectAccessTest');
            Assert.areEqual(1,matched_con, 'Created contact disappeared between user switches on ObjectAccessTest');
        }

        Test.stopTest();
        
        if(sRepFrance1.IsActive) {
            sRepFrance1.IsActive = false;
            update sRepFrance1;
        }
        if(sRepFrance2.IsActive) {
            sRepFrance2.IsActive = false;
            update sRepFrance2;
        }
    }

}