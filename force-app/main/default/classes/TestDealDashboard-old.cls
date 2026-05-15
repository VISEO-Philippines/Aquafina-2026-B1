@IsTest(SeeAllData=true)
public with sharing class TestDealDashboard {
    
    @IsTest
    public static void TestDealDashboardEmptyOpportunity() {
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];
        
        
        Id opportunityId;

        List<Lead> leads = [SELECT Id FROM Lead WHERE OwnerId = :sRepFrance1.Id AND Territory__c = 'France' AND Status = 'In Progress' LIMIT 1];

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
            opportunityId = lcr.getOpportunityId();
            
            System.debug('Opportunity Created: ' + opportunityId);
        } else {
            System.debug('Conversion Error. Was not able to convert lead.');
        }

        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }

        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Distributors' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE ProductCode='WB0001' AND Pricebook2Id=:pb.Id LIMIT 1];
        Quote new_quote;

        System.runAs(sRepFrance1) {
            new_quote = new Quote(
                Name = 'Test Opportunity Quote for 100 Bottles',
                OpportunityId = opportunityId,
                Pricebook2Id = pb.Id
            );

            insert new_quote;
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = new_quote.Id,
                PricebookEntryId = pbe.Id, 
                Quantity = 100,
                UnitPrice = 2.00
            );
            insert qli;

            
            update new Opportunity(
                Id = opportunityId,
                SyncedQuoteId = new_quote.Id
            );

            
        }

        // Test Deal Dashboard for created opportunity
        DealDashboard.DealData dd = DealDashboard.getDealData(opportunityId);

        // Check if the struct was populated - opportunity contact role wasnt added.

        System.assertEquals(opportunityId, dd.opp.Id);
        System.assertEquals(new_quote.Id, dd.quote.Id);
        System.assertEquals(1, dd.lineItems.size());

        // Test Deal Dashboard using non existent opportunity
        try {
            DealDashboard.DealData dd2 = DealDashboard.getDealData('006gL000A0ZyjtAQAJ'); // This hardcoded id is not valid

            System.assert(false, 'AuraHandledException should have been thrown due to non existent ID.');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException thrown as expected from nonexistent oppID.');
        }

    }
}