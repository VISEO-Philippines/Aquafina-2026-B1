@IsTest(SeeAllData=true)
public with sharing class TestObjectAccess {

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
    // This test ensures that leads are shared within their respective regions (France or Spain)
    @IsTest
    public static void testSalesRepAccessOnLeads() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];// TestDataFactory.TestUserSalesRep('France');

        User sRepSpain1 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESEREP'];//TestDataFactory.TestUserSalesRep('Spain');

        User sRepFrance2 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRSREP'];//TestDataFactory.TestUserSalesRep('France');
        
        User sRepSpain2 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESWREP'];

        Integer baselineCount = 0;
        Integer baselineCountFrance = 0;
        Integer baselineCountSpain = 0;

        Test.startTest();

        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }
        // GET COUNT FROM FRANCE REP ONE, ADD TWO LEADS
        baselineCount = [SELECT Count() FROM Lead];
        System.runAs(sRepFrance1) {
            baselineCountFrance = [SELECT Count() FROM Lead WHERE Territory__c='France'];
            System.debug('Baseline count for FRANCE: ' + baselineCountFrance);
            Lead l = new Lead(LastName='Smith', Company='TestCo', Territory__c='France', OwnerId=sRepFrance1.Id);
            insert l;
            
            Lead l2 = new Lead(LastName='Smitheee', Company='TestCo23', Territory__c='France', OwnerId=sRepFrance1.Id);
            insert l2;
        }

        System.debug('Total Leads in DB AFTER INSERT: ' + baselineCount);

        switchUser(sRepFrance1, sRepSpain1);
        // GET COUNT FROM SPAIN REP ONE, ADD 1 LEAD
        System.runAs(sRepSpain1) {
            baselineCountSpain = [SELECT Count() FROM Lead WHERE Territory__c='Spain'];
            Lead l2 = new Lead(LastName='Wesson', Company='TesCo', Territory__c='Spain', OwnerId=sRepSpain1.Id);
            insert l2;

        }
        Test.stopTest();


        switchUser(sRepSpain1, sRepFrance2);
        // FRANCE REP ONE SHOULD HAVE BASELINE+2 LEADS FROM THE TWO LEADS ADDED BY FRANCE REP ONE
        System.runAs(sRepFrance2) {
            Integer leads = [SELECT Count() FROM Lead WHERE Territory__c='France'];
            Integer spainLeads = [SELECT COUNT() FROM Lead WHERE Territory__c = 'Spain'];
            // Second france salesrep must be able to see leads inserted by first france sales rep.
            System.debug('Leads visible to sRepFrance2 with Territory Match: ' + leads);

            System.assertEquals(baselineCountFrance+2, leads);
            System.assertEquals(0,spainLeads);
        }
        switchUser(sRepFrance2, sRepSpain2);
        // ADD ONE MORE LEAD TO SPAIN, MUST SEE BASELINE+2 LEADS FROM 1 LEAD ADDED BY SPAIN REP ONE AND ANOTHER ADDED BY SELF
        System.runAs(sRepSpain2) {
            Lead l2 = new Lead(LastName='Wesson2', Company='TestCo2', Territory__c='Spain', OwnerId=sRepSpain2.Id);
            insert l2;
            List<Lead> leads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE Territory__c = 'Spain'];
            
            // leads should only have a length of 1 containing the lead inserted in this code block. the two leads inserted by sRepFrance should've been excluded
            System.assertEquals(baselineCountSpain+2, leads.size());
            System.debug('Leads visible to sRepSpain2: ' + leads);

            Integer franceLeads = [SELECT COUNT() FROM Lead WHERE Territory__c = 'France'];
            System.assertEquals(0,franceLeads);
        }
        if(sRepSpain2.IsActive) {
            sRepSpain2.IsActive = false;
            update sRepSpain2;
        }


    }

    // This test ensures that Accounts, Contacts, and Opportunities are not shared.
    @IsTest
    public static void testSalesRepAccessOnAccOppCon() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];// TestDataFactory.TestUserSalesRep('France');
        User sRepSpain1 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESEREP'];//TestDataFactory.TestUserSalesRep('Spain');
        User sRepFrance2 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRSREP'];//TestDataFactory.TestUserSalesRep('France');
        User sRepSpain2 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESWREP'];

        Test.startTest();
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
        System.runAs(sRepFrance1) {
            List<Lead> leads = [SELECT Id FROM Lead WHERE OwnerId = :sRepFrance2.Id AND Territory__c = 'France' AND Status = 'In Progress' LIMIT 1];

            if (leads.size() < 1) {
                System.debug('No available leads passing criteria: sRepFrance1(FRNREP) must see a Lead owned by sRepFrance2(FRSREP)');
                return;
            }
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leads[0].Id);
            lc.setConvertedStatus('Qualified');
            lc.setOwnerId(sRepFrance1.Id);
            Database.LeadConvertResult lcr = Database.convertLead(lc);

            if (lcr.isSuccess()) {
                accountId = lcr.getAccountId();
                contactId = lcr.getContactId();
                opportunityId = lcr.getOpportunityId();
                
                System.debug('Account Created: ' + accountId);
                System.debug('Contact Created: ' + contactId);
                System.debug('Opportunity Created: ' + opportunityId);
            } else {
                System.debug('Conversion Error. Was not able to convert lead.');
            }

        }

        // Check if sRepFrance2 can see the Opp, Account, Contact converted by sRepFrance1
        System.runAs(sRepFrance2) {
            List<Opportunity> matched_opp = [SELECT OwnerId FROM Opportunity WHERE Id = :opportunityId];
            List<Account> matched_acc = [SELECT OwnerId FROM Account WHERE Id = :accountId];
            List<Contact> matched_con = [SELECT OwnerId FROM Contact WHERE Id = :contactId];
            
            if (matched_opp.size() > 0) {
                System.debug('ERROR: sRepFrance2 with ID: '+ sRepFrance2.Id +' found a matched opp with ownerID ' + matched_opp[0].OwnerId);
            }
            
            System.assertEquals(0,matched_opp.size());
            System.assertEquals(0,matched_acc.size());
            System.assertEquals(0,matched_con.size());
        }

        // Check if it still exists in sRepFrance1 just to be sure
        
        System.runAs(sRepFrance1) {
            Integer matched_opp = [SELECT COUNT() FROM Opportunity WHERE Id = :opportunityId];
            Integer matched_acc = [SELECT COUNT() FROM Account WHERE Id = :accountId];
            Integer matched_con = [SELECT COUNT() FROM Contact WHERE Id = :contactId];

            System.assertEquals(1,matched_opp);
            System.assertEquals(1,matched_acc);
            System.assertEquals(1,matched_con);
        }
        
        if(sRepFrance1.IsActive) {
            sRepFrance1.IsActive = false;
            update sRepFrance1;
        }
        if(sRepFrance2.IsActive) {
            sRepFrance2.IsActive = false;
            update sRepFrance2;
        }

        Test.stopTest();
    }

}