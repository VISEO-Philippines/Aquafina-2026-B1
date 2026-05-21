@IsTest
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

    @TestSetup
    static void setupData(){
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];
        User sRepSpain1 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESEREP'];
        User sRepFrance2 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRSREP'];
        User sRepSpain2 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESWREP'];

        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }

        System.runAs(sRepFrance1) {
            Lead l = new Lead(LastName='Smith', Company='TestCo', Territory__c='France', Email='smith@example.com' ,Status = 'In Progress', OwnerId=sRepFrance1.Id);
            insert l;
            
            Lead l2 = new Lead(LastName='Smitheee', Company='TestCo23', Territory__c='France',Email='smithee@example.com' ,Status = 'In Progress', OwnerId=sRepFrance1.Id);
            insert l2;
        }        

        switchUser(sRepFrance1, sRepSpain1);

        System.runAs(sRepSpain1) {
            Lead l2 = new Lead(LastName='Wesson', Company='TesCo', Territory__c='Spain',Email='wesson@example.com',Status = 'In Progress' ,OwnerId=sRepSpain1.Id);
            insert l2;
        }

        if(sRepSpain1.IsActive) {
            sRepSpain1.IsActive = false;
            update sRepFrance1;
        }
    }
    
    // This test ensures that leads are shared within their respective regions (France or Spain)
    @IsTest
    public static void testSalesRepAccessOnLeads() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];
        User sRepSpain1 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESEREP'];
        User sRepFrance2 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRSREP'];
        User sRepSpain2 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESWREP'];


        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }

        System.runAs(sRepFrance1) {
            List<Lead> leads_f1 = [SELECT Id FROM Lead WHERE Company = 'TestCo' OR Company = 'TestCo23'];

            System.assertEquals(2, leads_f1.size(), 'FRNREP leads not properly initialized.');
        }

        switchUser(sRepFrance1, sRepSpain1);

        System.runAs(sRepSpain1) {
            List<Lead> leads_s1 = [SELECT Id FROM Lead WHERE Company = 'Tesco'];

            System.assertEquals(1, leads_s1.size(), 'ESEREP lead not properly initialized.');
        }

        Test.startTest();
        switchUser(sRepSpain1, sRepFrance2);
        // FRANCE REP ONE SHOULD HAVE BASELINE+2 LEADS FROM THE TWO LEADS ADDED BY FRANCE REP ONE
        System.runAs(sRepFrance2) {
            Integer leads = [SELECT Count() FROM Lead WHERE Territory__c='France'];
            Integer spainLeads = [SELECT COUNT() FROM Lead WHERE Territory__c = 'Spain'];

            System.assertEquals(2, leads);
            System.assertEquals(0,spainLeads);
        }
        switchUser(sRepFrance2, sRepSpain2);
        // ADD ONE MORE LEAD TO SPAIN, MUST SEE BASELINE+2 LEADS FROM 1 LEAD ADDED BY SPAIN REP ONE AND ANOTHER ADDED BY SELF
        System.runAs(sRepSpain2) {
            Lead l2 = new Lead(LastName='Wesson2', Company='TestCo2', Territory__c='Spain', OwnerId=sRepSpain2.Id);
            insert l2;
            List<Lead> leads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE Territory__c = 'Spain'];
            
            // leads should only have a length of 1 containing the lead inserted in this code block. the two leads inserted by sRepFrance should've been excluded
            System.assertEquals(2, leads.size());
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
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];
        User sRepSpain1 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESEREP'];
        User sRepFrance2 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRSREP'];
        User sRepSpain2 = [SELECT Id, IsActive FROM User WHERE Alias = 'ESWREP'];

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
            List<Lead> leads = [SELECT Id FROM Lead WHERE OwnerId = :sRepFrance1.Id AND Territory__c = 'France' AND Status = 'In Progress' LIMIT 1];

            System.assertEquals(1, leads.size(), 'No available leads passing criteria: sRepFrance2(FRSREP) must see a Lead owned by sRepFrance1(FRNREP)');
            
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leads[0].Id);
            lc.setConvertedStatus('Qualified');
            lc.setOwnerId(sRepFrance2.Id);
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

        Test.startTest();
        // Check if sRepFrance1 can see the Opp, Account, Contact converted by sRepFrance1
        System.runAs(sRepFrance1) {
            List<Opportunity> matched_opp = [SELECT OwnerId FROM Opportunity WHERE Id = :opportunityId];
            List<Account> matched_acc = [SELECT OwnerId FROM Account WHERE Id = :accountId];
            List<Contact> matched_con = [SELECT OwnerId FROM Contact WHERE Id = :contactId];
            
            if (matched_opp.size() > 0) {
                System.debug('ERROR: sRepFrance1 with ID: '+ sRepFrance1.Id +' found a matched opp with ownerID ' + matched_opp[0].OwnerId);
            }
            
            System.assertEquals(0,matched_opp.size(), 'Found opp when opp should not be visible.');
            System.assertEquals(0,matched_acc.size(), 'Found acc when acc should not be visible.');
            System.assertEquals(0,matched_con.size(), 'Found con when con should not be visible.');
        }

        // Check if it still exists in sRepFrance1 just to be sure
        
        System.runAs(sRepFrance2) {
            Integer matched_opp = [SELECT COUNT() FROM Opportunity WHERE Id = :opportunityId];
            Integer matched_acc = [SELECT COUNT() FROM Account WHERE Id = :accountId];
            Integer matched_con = [SELECT COUNT() FROM Contact WHERE Id = :contactId];

            System.assertEquals(1,matched_opp);
            System.assertEquals(1,matched_acc);
            System.assertEquals(1,matched_con);
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