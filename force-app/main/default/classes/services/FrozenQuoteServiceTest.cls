@IsTest
private class FrozenQuoteServiceTest {

    // ─── Test Setup ──────────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        Account acc       = TestDataFactory.createAccount('Freeze Test Account');
        Pricebook2 pb     = TestDataFactory.createPricebook('Freeze Test Pricebook');
        User salesRep     = TestDataFactory.createSalesRepUser();

        // Opportunity owned by the sales rep
        Opportunity opp = new Opportunity(
            Name         = 'Freeze Test Opportunity',
            StageName    = 'Prospecting',
            CloseDate    = Date.today().addDays(30),
            AccountId    = acc.Id,
            Pricebook2Id = pb.Id,
            OwnerId      = salesRep.Id
        );
        insert opp;

        // Frozen quote — Status is set to 'In Review' after insert so the trigger
        // on QuoteLineItem does not fire during setup
        Quote frozenQuote = new Quote(
            Name           = 'Freeze Test Quote - Frozen',
            OpportunityId  = opp.Id,
            Status         = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Pricebook2Id   = pb.Id
        );
        insert frozenQuote;

        // Draft quote — always remains in Draft for positive-path tests
        Quote draftQuote = new Quote(
            Name           = 'Freeze Test Quote - Draft',
            OpportunityId  = opp.Id,
            Status         = 'Draft',
            ExpirationDate = Date.today().addDays(30),
            Pricebook2Id   = pb.Id
        );
        insert draftQuote;

        // Sync the frozen quote (sets IsSyncing = true on the quote) then freeze it
        opp.SyncedQuoteId = frozenQuote.Id;
        update opp;

        frozenQuote.Status = 'In Review';
        update frozenQuote;

        Product2 prod = TestDataFactory.createProduct('Freeze Test Product');
        TestDataFactory.createPricebookEntry(pb, prod, 100);

        Contact c = new Contact(LastName = 'Freeze Contact', AccountId = acc.Id);
        insert c;
    }

    // ─── Query Helpers ────────────────────────────────────────────────────────

    private static Quote getFrozenQuote() {
        return [SELECT Id, OpportunityId FROM Quote WHERE Name = 'Freeze Test Quote - Frozen' LIMIT 1];
    }

    private static Quote getDraftQuote() {
        return [SELECT Id, OpportunityId FROM Quote WHERE Name = 'Freeze Test Quote - Draft' LIMIT 1];
    }

    private static PricebookEntry getTestPbe() {
        return [
            SELECT Id, UnitPrice
            FROM PricebookEntry
            WHERE Product2.Name = 'Freeze Test Product'
              AND Pricebook2.Name = 'Freeze Test Pricebook'
              AND IsActive = true
            LIMIT 1
        ];
    }

    private static Opportunity getTestOpp() {
        return [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'Freeze Test Opportunity' LIMIT 1];
    }

    private static Contact getTestContact() {
        return [SELECT Id FROM Contact WHERE LastName = 'Freeze Contact' LIMIT 1];
    }

    // ─── QuoteLineItem — Insert ───────────────────────────────────────────────

    @IsTest
    static void enforceFreezeOnQli_blocksInsertWhenQuoteIsFrozen() {
        Quote frozenQ    = getFrozenQuote();
        PricebookEntry pbe = getTestPbe();

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId          = frozenQ.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = pbe.UnitPrice
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(qli, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Insert should be blocked when the quote is In Review');
        Assert.areEqual(
            FrozenQuoteService.FROZEN_ERROR_MSG,
            result.getErrors()[0].getMessage(),
            'Expected the frozen quote error message'
        );
    }

    @IsTest
    static void enforceFreezeOnQli_allowsInsertWhenQuoteIsDraft() {
        Quote draftQ       = getDraftQuote();
        PricebookEntry pbe = getTestPbe();

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId          = draftQ.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = pbe.UnitPrice
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(qli, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Insert on a Draft quote should succeed');
    }

    // ─── QuoteLineItem — Update ───────────────────────────────────────────────

    @IsTest
    static void enforceFreezeOnQli_blocksUpdateWhenQuoteIsFrozen() {
        // Seed a line item while the quote is still draft
        Quote draftQ       = getDraftQuote();
        PricebookEntry pbe = getTestPbe();
        QuoteLineItem existing = new QuoteLineItem(
            QuoteId          = draftQ.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = pbe.UnitPrice
        );
        insert existing;

        // Now freeze that quote
        draftQ.Status = 'In Review';
        update draftQ;

        existing.Quantity = 5;

        Test.startTest();
        Database.SaveResult result = Database.update(existing, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Update should be blocked when the quote is In Review');
        Assert.areEqual(FrozenQuoteService.FROZEN_ERROR_MSG, result.getErrors()[0].getMessage());
    }

    // ─── QuoteLineItem — Delete ───────────────────────────────────────────────

    @IsTest
    static void enforceFreezeOnQli_blocksDeleteWhenQuoteIsFrozen() {
        // Must seed the line item while the quote is in Draft (trigger would block it otherwise)
        Quote frozenQ      = getFrozenQuote();
        PricebookEntry pbe = getTestPbe();

        frozenQ.Status = 'Draft';
        update frozenQ;

        QuoteLineItem existing = new QuoteLineItem(
            QuoteId          = frozenQ.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = pbe.UnitPrice
        );
        insert existing;

        // Re-freeze
        frozenQ.Status = 'In Review';
        update frozenQ;

        Test.startTest();
        Database.DeleteResult result = Database.delete(existing, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Delete should be blocked when the quote is In Review');
        Assert.areEqual(FrozenQuoteService.FROZEN_ERROR_MSG, result.getErrors()[0].getMessage());
    }

    // ─── OpportunityContactRole — Insert ─────────────────────────────────────

    @IsTest
    static void enforceFreezeOnOcr_blocksPrimaryInsertWhenFrozen() {
        Opportunity opp = getTestOpp();
        Contact c       = getTestContact();

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId     = c.Id,
            IsPrimary     = true
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(ocr, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Primary OCR insert should be blocked when quote is In Review');
        Assert.areEqual(FrozenQuoteService.FROZEN_ERROR_MSG, result.getErrors()[0].getMessage());
    }

    @IsTest
    static void enforceFreezeOnOcr_allowsNonPrimaryInsertWhenFrozen() {
        Opportunity opp = getTestOpp();
        Contact c       = getTestContact();

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId     = c.Id,
            IsPrimary     = false,
            Role          = 'Influencer'
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(ocr, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Non-primary OCR insert should be allowed even when quote is frozen');
    }

    // ─── OpportunityContactRole — Delete ─────────────────────────────────────

    @IsTest
    static void enforceFreezeOnOcr_blocksPrimaryDeleteWhenFrozen() {
        Opportunity opp = getTestOpp();
        Contact c       = getTestContact();

        // Temporarily unsync the quote so the OCR trigger does not block the insert
        opp.SyncedQuoteId = null;
        update opp;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId     = c.Id,
            IsPrimary     = true
        );
        insert ocr;

        // Re-sync the frozen quote
        Quote frozenQ     = getFrozenQuote();
        opp.SyncedQuoteId = frozenQ.Id;
        update opp;

        Test.startTest();
        Database.DeleteResult result = Database.delete(ocr, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Primary OCR delete should be blocked when quote is In Review');
        Assert.areEqual(FrozenQuoteService.FROZEN_ERROR_MSG, result.getErrors()[0].getMessage());
    }

    // ─── Manager Exemption ────────────────────────────────────────────────────

    @IsTest
    static void enforceFreezeOnQli_allowsInsertForManagerUser() {
        Opportunity opp    = getTestOpp();
        PricebookEntry pbe = getTestPbe();
        Quote frozenQ      = getFrozenQuote();

        // Derive the sales rep's role so we can create a manager one level above
        List<User> ownerList  = [SELECT UserRoleId FROM User WHERE Id = :opp.OwnerId LIMIT 1];
        Id salesRepRoleId     = ownerList.isEmpty() ? null : ownerList[0].UserRoleId;
        User manager          = TestDataFactory.createManagerUser(salesRepRoleId);

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId          = frozenQ.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 1,
            UnitPrice        = pbe.UnitPrice
        );

        Test.startTest();
        Database.SaveResult result;
        System.runAs(manager) {
            result = Database.insert(qli, false);
        }
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Manager user should be exempt from the freeze enforcement');
    }

    // ─── Edge Cases ───────────────────────────────────────────────────────────

    @IsTest
    static void enforceFreezeOnQli_doesNothingForNullOrEmptyList() {
        FrozenQuoteService svc = new FrozenQuoteService(
            new QuoteSelector(),
            new OpportunitySelector(),
            new UserRoleSelector()
        );

        Test.startTest();
        svc.enforceFreezeOnQuoteLineItems(null);
        svc.enforceFreezeOnQuoteLineItems(new List<QuoteLineItem>());
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown for null or empty QuoteLineItem list');
    }

    @IsTest
    static void enforceFreezeOnOcr_doesNothingForNullOrEmptyList() {
        FrozenQuoteService svc = new FrozenQuoteService(
            new QuoteSelector(),
            new OpportunitySelector(),
            new UserRoleSelector()
        );

        Test.startTest();
        svc.enforceFreezeOnContactRoles(null);
        svc.enforceFreezeOnContactRoles(new List<OpportunityContactRole>());
        Test.stopTest();

        Assert.isTrue(true, 'No exception should be thrown for null or empty OpportunityContactRole list');
    }
}
