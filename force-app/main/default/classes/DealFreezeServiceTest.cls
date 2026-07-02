@IsTest
private class DealFreezeServiceTest {

    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_IN_REVIEW = 'In Review';

    private static final String ERROR_FROZEN_QUOTE =
        'Quote Line Items cannot be changed while the related Quote is In Review.';

    private static final String ERROR_PRIMARY_CONTACT_CHANGE =
        'Primary Contact cannot be changed while the related Quote is In Review.';

    private class FreezeTestData {
        User opportunityOwner;
        User actingUser;

        Account accountRecord;
        Opportunity opportunityRecord;

        Contact currentPrimaryContact;
        Contact replacementPrimaryContact;

        Quote quoteRecord;

        Product2 existingProduct;
        PricebookEntry existingPricebookEntry;
        QuoteLineItem existingQuoteLineItem;

        Product2 newProduct;
        PricebookEntry newPricebookEntry;
    }

    @IsTest
    static void shouldBlockQuoteLineItemInsertWhenQuoteIsInReview() {
        FreezeTestData testData = createFrozenQuoteTestData();

        System.runAs(testData.actingUser) {
            QuoteLineItem newQuoteLineItem =
                TestDataFactory.buildQuoteLineItem(
                    testData.quoteRecord.Id,
                    testData.newPricebookEntry.Id,
                    100,
                    1
                );

            Test.startTest();

            Database.SaveResult saveResult = Database.insert(
                newQuoteLineItem,
                false
            );

            Test.stopTest();

            assertSaveFailedWithMessage(
                saveResult,
                ERROR_FROZEN_QUOTE
            );
        }

        Integer quoteLineItemCount = [
            SELECT COUNT()
            FROM QuoteLineItem
            WHERE QuoteId = :testData.quoteRecord.Id
        ];

        Assert.areEqual(
            1,
            quoteLineItemCount,
            'Blocked QLI insert must not add a new Quote Line Item.'
        );
    }

    @IsTest
    static void shouldBlockQuoteLineItemUpdateWhenQuoteIsInReview() {
        FreezeTestData testData = createFrozenQuoteTestData();

        System.runAs(testData.actingUser) {
            QuoteLineItem updatedQuoteLineItem = new QuoteLineItem(
                Id = testData.existingQuoteLineItem.Id,
                Quantity = 2
            );

            Test.startTest();

            Database.SaveResult saveResult = Database.update(
                updatedQuoteLineItem,
                false
            );

            Test.stopTest();

            assertSaveFailedWithMessage(
                saveResult,
                ERROR_FROZEN_QUOTE
            );
        }

        QuoteLineItem quoteLineItemAfterUpdate = [
            SELECT Quantity
            FROM QuoteLineItem
            WHERE Id = :testData.existingQuoteLineItem.Id
        ];

        Assert.areEqual(
            Decimal.valueOf(1),
            quoteLineItemAfterUpdate.Quantity,
            'Blocked QLI update must preserve the original Quantity.'
        );
    }

    @IsTest
    static void shouldBlockQuoteLineItemDeleteWhenQuoteIsInReview() {
        FreezeTestData testData = createFrozenQuoteTestData();

        System.runAs(testData.actingUser) {
            Test.startTest();

            Database.DeleteResult deleteResult = Database.delete(
                testData.existingQuoteLineItem,
                false
            );

            Test.stopTest();

            assertDeleteFailedWithMessage(
                deleteResult,
                ERROR_FROZEN_QUOTE
            );
        }

        Integer quoteLineItemCount = [
            SELECT COUNT()
            FROM QuoteLineItem
            WHERE Id = :testData.existingQuoteLineItem.Id
        ];

        Assert.areEqual(
            1,
            quoteLineItemCount,
            'Blocked QLI delete must preserve the existing Quote Line Item.'
        );
    }

    @IsTest
    static void shouldBlockPrimaryContactChangeWhenQuoteIsInReview() {
        FreezeTestData testData = createFrozenQuoteTestData();

        System.runAs(testData.actingUser) {
            Opportunity updatedOpportunity = new Opportunity(
                Id = testData.opportunityRecord.Id,
                Primary_Contact__c = testData.replacementPrimaryContact.Id
            );

            Test.startTest();

            Database.SaveResult saveResult = Database.update(
                updatedOpportunity,
                false
            );

            Test.stopTest();

            assertSaveFailedWithMessage(
                saveResult,
                ERROR_PRIMARY_CONTACT_CHANGE
            );
        }

        Opportunity opportunityAfterUpdate = [
            SELECT Primary_Contact__c
            FROM Opportunity
            WHERE Id = :testData.opportunityRecord.Id
        ];

        Assert.areEqual(
            testData.currentPrimaryContact.Id,
            opportunityAfterUpdate.Primary_Contact__c,
            'Blocked Primary Contact update must preserve the current contact.'
        );
    }

    @IsTest
    static void shouldAllowQuoteLineItemInsertWhenQuoteIsDraft() {
        FreezeTestData testData = createDraftQuoteTestData();

        System.runAs(testData.actingUser) {
            QuoteLineItem newQuoteLineItem =
                TestDataFactory.buildQuoteLineItem(
                    testData.quoteRecord.Id,
                    testData.newPricebookEntry.Id,
                    100,
                    1
                );

            Test.startTest();

            Database.SaveResult saveResult = Database.insert(
                newQuoteLineItem,
                false
            );

            Test.stopTest();

            Assert.isTrue(
                saveResult.isSuccess(),
                'QLI insert should be allowed while the Quote is Draft.'
            );
        }

        Integer quoteLineItemCount = [
            SELECT COUNT()
            FROM QuoteLineItem
            WHERE QuoteId = :testData.quoteRecord.Id
        ];

        Assert.areEqual(
            2,
            quoteLineItemCount,
            'Draft Quote should contain both Quote Line Items.'
        );
    }

    @IsTest
    static void shouldAllowUnrelatedOpportunityUpdateWhenQuoteIsInReview() {
        FreezeTestData testData = createFrozenQuoteTestData();

        System.runAs(testData.actingUser) {
            Opportunity updatedOpportunity = new Opportunity(
                Id = testData.opportunityRecord.Id,
                Name = 'Updated Opportunity Name'
            );

            Test.startTest();

            Database.SaveResult saveResult = Database.update(
                updatedOpportunity,
                false
            );

            Test.stopTest();

            Assert.isTrue(
                saveResult.isSuccess(),
                'Updates unrelated to Primary Contact should remain allowed.'
            );
        }

        Opportunity opportunityAfterUpdate = [
            SELECT Name
            FROM Opportunity
            WHERE Id = :testData.opportunityRecord.Id
        ];

        Assert.areEqual(
            'Updated Opportunity Name',
            opportunityAfterUpdate.Name,
            'The unrelated Opportunity update should be saved.'
        );
    }

    @IsTest
    static void shouldAllowManagerOrHigherToInsertQuoteLineItemWhenQuoteIsInReview() {
        UserRole childRole = getChildRoleWithParent();

        User managerUser =
            TestDataFactory.createSalesRepUserWithRole(
                childRole.ParentRoleId
            );

        User salesRepUser =
            TestDataFactory.createSalesRepUserWithRole(
                childRole.Id
            );

        FreezeTestData testData = createFrozenQuoteTestData(
            salesRepUser,
            managerUser
        );

        System.runAs(managerUser) {
            QuoteLineItem newQuoteLineItem =
                TestDataFactory.buildQuoteLineItem(
                    testData.quoteRecord.Id,
                    testData.newPricebookEntry.Id,
                    100,
                    1
                );

            Test.startTest();

            Database.SaveResult saveResult = Database.insert(
                newQuoteLineItem,
                false
            );

            Test.stopTest();

            Assert.isTrue(
                saveResult.isSuccess(),
                'A manager or higher should bypass the QLI freeze.'
            );
        }

        Integer quoteLineItemCount = [
            SELECT COUNT()
            FROM QuoteLineItem
            WHERE QuoteId = :testData.quoteRecord.Id
        ];

        Assert.areEqual(
            2,
            quoteLineItemCount,
            'Manager bypass should allow a new Quote Line Item.'
        );
    }

    @IsTest
    static void shouldAllowManagerOrHigherToChangePrimaryContactWhenQuoteIsInReview() {
        UserRole childRole = getChildRoleWithParent();

        User managerUser =
            TestDataFactory.createSalesRepUserWithRole(
                childRole.ParentRoleId
            );

        User salesRepUser =
            TestDataFactory.createSalesRepUserWithRole(
                childRole.Id
            );

        FreezeTestData testData = createFrozenQuoteTestData(
            salesRepUser,
            managerUser
        );

        System.runAs(managerUser) {
            Opportunity updatedOpportunity = new Opportunity(
                Id = testData.opportunityRecord.Id,
                Primary_Contact__c = testData.replacementPrimaryContact.Id
            );

            Test.startTest();

            Database.SaveResult saveResult = Database.update(
                updatedOpportunity,
                false
            );

            Test.stopTest();

            Assert.isTrue(
                saveResult.isSuccess(),
                'A manager or higher should bypass the Primary Contact freeze.'
            );
        }

        Opportunity opportunityAfterUpdate = [
            SELECT Primary_Contact__c
            FROM Opportunity
            WHERE Id = :testData.opportunityRecord.Id
        ];

        Assert.areEqual(
            testData.replacementPrimaryContact.Id,
            opportunityAfterUpdate.Primary_Contact__c,
            'Manager bypass should allow the Primary Contact change.'
        );
    }

    // Creates frozen Quote data using separate users for the owner and acting user.
    private static FreezeTestData createFrozenQuoteTestData() {
        User opportunityOwner =
            TestDataFactory.createSalesRepUser();

        User actingUser =
            TestDataFactory.createSalesRepUser();

        return createQuoteTestData(
            opportunityOwner,
            actingUser,
            true
        );
    }

    // Creates Draft Quote data used to confirm normal updates remain allowed.
    private static FreezeTestData createDraftQuoteTestData() {
        User opportunityOwner =
            TestDataFactory.createSalesRepUser();

        User actingUser =
            TestDataFactory.createSalesRepUser();

        return createQuoteTestData(
            opportunityOwner,
            actingUser,
            false
        );
    }

    // Creates frozen Quote data using explicit owner and acting users.
    private static FreezeTestData createFrozenQuoteTestData(
        User opportunityOwner,
        User actingUser
    ) {
        return createQuoteTestData(
            opportunityOwner,
            actingUser,
            true
        );
    }

    // Creates data while the Quote is Draft, then changes the Quote status
    // only after the initial Quote Line Item has been created.
    private static FreezeTestData createQuoteTestData(
        User opportunityOwner,
        User actingUser,
        Boolean shouldFreezeQuote
    ) {
        FreezeTestData testData = new FreezeTestData();

        testData.opportunityOwner = opportunityOwner;
        testData.actingUser = actingUser;

        System.runAs(opportunityOwner) {
            testData.accountRecord =
                TestDataFactory.createAccount();

            testData.currentPrimaryContact =
                TestDataFactory.createContact(
                    testData.accountRecord.Id,
                    'Current Primary Contact'
                );

            testData.replacementPrimaryContact =
                TestDataFactory.createContact(
                    testData.accountRecord.Id,
                    'Replacement Primary Contact'
                );

            testData.opportunityRecord =
                TestDataFactory.createOpportunity(
                    testData.accountRecord.Id
                );

            update new Opportunity(
                Id = testData.opportunityRecord.Id,
                Primary_Contact__c = testData.currentPrimaryContact.Id
            );

            testData.existingProduct =
                TestDataFactory.createProduct(
                    'Existing Product'
                );

            testData.existingPricebookEntry =
                TestDataFactory.createPricebookEntry(
                    testData.existingProduct.Id
                );

            testData.newProduct =
                TestDataFactory.createProduct(
                    'New Product'
                );

            testData.newPricebookEntry =
                TestDataFactory.createPricebookEntry(
                    testData.newProduct.Id
                );

            testData.quoteRecord =
                TestDataFactory.createQuote(
                    testData.opportunityRecord.Id,
                    STATUS_DRAFT
                );

            testData.existingQuoteLineItem =
                TestDataFactory.createQuoteLineItem(
                    testData.quoteRecord.Id,
                    testData.existingPricebookEntry.Id,
                    100
                );

            if (shouldFreezeQuote) {
                TestDataFactory.updateQuoteStatus(
                    testData.quoteRecord.Id,
                    STATUS_IN_REVIEW
                );
            }
        }

        return testData;
    }

    // Retrieves a child Role so its parent can be assigned to a manager user.
    private static UserRole getChildRoleWithParent() {
        List<UserRole> childRoles = [
            SELECT
                Id,
                ParentRoleId
            FROM UserRole
            WHERE ParentRoleId != null
            LIMIT 1
        ];

        Assert.isFalse(
            childRoles.isEmpty(),
            'A parent-child Role Hierarchy pair is required for bypass tests.'
        );

        return childRoles[0];
    }

    // Verifies that an insert or update was blocked with the expected message.
    private static void assertSaveFailedWithMessage(
        Database.SaveResult saveResult,
        String expectedMessage
    ) {
        Assert.isFalse(
            saveResult.isSuccess(),
            'The DML operation should have been blocked.'
        );

        Assert.isTrue(
            saveResult.getErrors().size() > 0,
            'The blocked operation should return at least one error.'
        );

        Assert.isTrue(
            saveResult.getErrors()[0]
                .getMessage()
                .contains(expectedMessage),
            'Expected error message was not returned: ' + expectedMessage
        );
    }

    // Verifies that a delete was blocked with the expected message.
    private static void assertDeleteFailedWithMessage(
        Database.DeleteResult deleteResult,
        String expectedMessage
    ) {
        Assert.isFalse(
            deleteResult.isSuccess(),
            'The delete operation should have been blocked.'
        );

        Assert.isTrue(
            deleteResult.getErrors().size() > 0,
            'The blocked delete should return at least one error.'
        );

        Assert.isTrue(
            deleteResult.getErrors()[0]
                .getMessage()
                .contains(expectedMessage),
            'Expected error message was not returned: ' + expectedMessage
        );
    }
}