@IsTest
private class DealSummaryControllerTest {

    // Shared dataset used by all test methods.
    @TestSetup
    static void setupData() {
        // Base account used by the primary happy-path opportunity.
        Account acc = new Account(Name = 'AQUAFINA Test Account');
        insert acc;

        // Use a dedicated active pricebook so Quote, Opportunity, and line items always align.
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'AQUAFINA Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        // Core opportunity with positive financials.
        Opportunity opp = new Opportunity(
            Name = 'AQUAFINA Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = acc.Id,
            Pricebook2Id = testPricebook.Id,
            Total_List_Amount__c = 1000,
            Total_Discounted_Amount__c = 900
        );
        insert opp;

        // Primary contact and role used by contact readiness checks.
        Contact primaryContact = new Contact(
            LastName = 'Primary Contact',
            Email = 'primary@example.com',
            AccountId = acc.Id
        );
        insert primaryContact;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = primaryContact.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );
        insert ocr;

        // Synced quote used by quote readiness checks.
        Quote q = new Quote(
            Name = 'AQUAFINA Synced Quote',
            OpportunityId = opp.Id,
            Status = 'Approved',
            ExpirationDate = Date.today().addDays(30),
            Pricebook2Id = testPricebook.Id
        );
        insert q;

        opp.SyncedQuoteId = q.Id;
        update opp;

        // Product and pricebook entry used to create at least one quote line.
        Product2 prod = new Product2(
            Name = 'AQUAFINA Product',
            IsActive = true
        );
        insert prod;

        // Salesforce requires a standard price before adding a custom pricebook entry.
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Quote line proves quoteHasProducts path.
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert qli;
    }

    @IsTest
    static void getDealSummary_returnsDefaultsWhenNoOpportunityFound() {
        // Null Id should return the default wrapper with false readiness flags.
        Test.startTest();
        DealSummaryController.DealSummaryWrapper result = DealSummaryController.getDealSummary(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected wrapper instance');
        System.assertEquals(false, result.hasQuote, 'Expected no quote when no opportunity is found');
        System.assertEquals(false, result.hasPrimaryContact, 'Expected no contact when no opportunity is found');
        System.assertEquals(false, result.financialsCalculable, 'Expected financialsCalculable to remain false');
    }

    @IsTest
    static void getDealSummary_returnsExpectedDataWhenRelatedRecordsExist() {
        // Load the seeded opportunity from @TestSetup.
        Opportunity opp = [
            SELECT Id, Name
            FROM Opportunity
            WHERE Name = 'AQUAFINA Test Opportunity'
            LIMIT 1
        ];

        // Execute the controller method for full happy-path validation.
        Test.startTest();
        DealSummaryController.DealSummaryWrapper result = DealSummaryController.getDealSummary(opp.Id);
        Test.stopTest();

        // Context checks.
        System.assertEquals(opp.Name, result.opportunityName, 'Opportunity name should match');
        System.assertEquals('AQUAFINA Test Account', result.accountName, 'Account name should match');
        System.assertEquals('Prospecting', result.stageName, 'Stage should match');

        // Quote checks.
        System.assertEquals(true, result.hasQuote, 'Expected synced quote to be detected');
        System.assertEquals(true, result.quoteAccepted, 'Expected approved quote status');
        System.assertEquals(true, result.quoteHasProducts, 'Expected quote to have at least one line item');

        // Contact checks.
        System.assertEquals(true, result.hasPrimaryContact, 'Expected primary contact to be detected');
        System.assertEquals('primary@example.com', result.primaryContactEmail, 'Primary contact email should match');
        System.assertEquals(true, result.contactHasEmail, 'Expected contact email flag to be true');

        // Financial readiness checks.
        System.assertNotEquals(null, result.totalListAmount, 'Total list amount should be populated');
        System.assertEquals(
            (result.totalListAmount > 0),
            result.financialsCalculable,
            'financialsCalculable should mirror whether total list amount is positive'
        );
    }

    @IsTest
    static void getDealSummary_financialsCalculableFalseWhenListAmountZero() {
        // Independent scenario proving the negative branch for financial readiness.
        Account acc = new Account(Name = 'AQUAFINA Zero Amount Account');
        insert acc;

        Opportunity zeroOpp = new Opportunity(
            Name = 'AQUAFINA Zero Amount Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Total_List_Amount__c = 0
        );
        insert zeroOpp;

        Test.startTest();
        DealSummaryController.DealSummaryWrapper result = DealSummaryController.getDealSummary(zeroOpp.Id);
        Test.stopTest();

        System.assertEquals(false, result.financialsCalculable, 'Expected false when total list amount is zero');
    }
}