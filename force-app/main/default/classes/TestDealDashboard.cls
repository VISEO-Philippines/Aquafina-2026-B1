@IsTest
private class TestDealDashboard {

    @TestSetup
    static void setupData(){
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];
        
        Id opportunityId;

        Lead testLead = new Lead(
            FirstName = 'Juan',
            LastName = 'Dela Cruz',
            Company = 'Tech Solutions Inc.',
            Status = 'To Contact',
            LeadSource = 'Web',
            Email = 'juantestlead@example.com',
            Territory__c = 'France',
            OwnerId = sRepFrance1.Id
        );
        insert testLead;


        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setOwnerId(sRepFrance1.Id);
        lc.setOpportunityName('Tech Solutions Inc.-');
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        if (lcr.isSuccess()) {
            opportunityId = lcr.getOpportunityId();
            
            System.debug('Opportunity Created: ' + opportunityId);
        } else {
            System.debug('Conversion Error. Was not able to convert lead.');
        }

        Product2 prod = new Product2(Name = 'Test Water Bottle', IsActive = true);
        insert prod;

        Id stdPbId = Test.getStandardPricebookId();
    
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = stdPbId, 
            Product2Id = prod.Id, 
            UnitPrice = 3, 
            IsActive = true
        );
        insert stdPbe;

        Pricebook2 pb = new Pricebook2(
            Name = 'Special Discount PB',
            IsActive = true
        );
        insert pb;



        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id, Product2Id = prod.Id, 
            UnitPrice = 3, IsActive = true
        );

        insert pbe;
    }

    @IsTest
    private static void DealDashboardEmptyOpportunityTest() {
        
        User sRepFrance1 = [SELECT Id, IsActive FROM User WHERE Alias = 'FRNREP'];

        DealDashboard.DealData dd;

        List<Lead> leads = [SELECT Id FROM Lead WHERE Email = 'juantestlead@example.com'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Water Bottle'];
        Opportunity opp = [SELECT Id FROM Opportunity Where Name = 'Tech Solutions Inc.-'];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 Where Name = 'Special Discount PB'];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry Where Pricebook2Id = :pb.Id];

        if (leads.size() < 1) {
            System.debug('Lead was not initialized properly in setup.');
            return;
        }

        if(!sRepFrance1.IsActive) {
            sRepFrance1.IsActive = true;
            update sRepFrance1;
        }

        Quote new_quote;

        System.runAs(sRepFrance1) {
            new_quote = new Quote(
                Name = 'Test Opportunity Quote for 100 Bottles',
                OpportunityId = opp.Id,
                Pricebook2Id = pb.Id
            );

            insert new_quote;
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = new_quote.Id,
                PricebookEntryId = pbe.Id, 
                Quantity = 100,
                UnitPrice = 3.00
            );
            insert qli;

            
            update new Opportunity(
                Id = opp.Id,
                SyncedQuoteId = new_quote.Id
            );

            Test.startTest();
            // Test Deal Dashboard for created opportunity
            dd = DealDashboard.getDealData(opp.Id);

            Boolean isError = false;
            // Test Deal Dashboard using non existent opportunity
            try {
                DealDashboard.DealData dd2 = DealDashboard.getDealData('006gL000A0ZyjtAQAJ'); // This hardcoded id is not valid
            } catch (AuraHandledException e) {
                isError = true;
            }
            Test.stopTest();
            
            // Check if the struct was populated - opportunity contact role wasnt added.
            System.assertEquals(opp.Id, dd.opp.Id);
            System.assertEquals(new_quote.Id, dd.quote.Id);
            System.assertEquals(1, dd.lineItems.size());
            System.assert(isError, 'AuraHandledException thrown as expected from nonexistent oppID.');
        }
    }
}