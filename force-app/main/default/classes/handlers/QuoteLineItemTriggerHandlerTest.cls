@IsTest
private class QuoteLineItemTriggerHandlerTest {

    // ---------------------------------------------------------------------------
    // filterChangedQuoteLineItems — only lines whose Product2Id changed compared
    // to the old map should be returned; unchanged lines must be excluded.
    // ---------------------------------------------------------------------------
    @IsTest
    static void filterChangedQuoteLineItems_returnsOnlyLinesWithChangedProduct() {
        Account acc = TestDataFactory.createAccount('Filter Test Account');
        Pricebook2 pb = TestDataFactory.createPricebook('Filter Test Pricebook');
        Opportunity opp = TestDataFactory.createOpportunity(acc, pb.Id);
        Quote q = TestDataFactory.createQuote(opp, pb.Id);

        Product2 prodA = TestDataFactory.createProduct('Filter Prod A');
        Product2 prodB = TestDataFactory.createProduct('Filter Prod B');
        PricebookEntry pbeA = TestDataFactory.createPricebookEntry(pb, prodA, 100);
        PricebookEntry pbeB = TestDataFactory.createPricebookEntry(pb, prodB, 200);

        // Two separate lines so each has a distinct Id in the old map
        QuoteLineItem lineA = TestDataFactory.createQuoteLineItem(q, pbeA, 1, 100);
        QuoteLineItem lineB = TestDataFactory.createQuoteLineItem(q, pbeB, 1, 200);

        // Simulate Trigger.new: lineA keeps its product, lineB's product changes to prodA
        QuoteLineItem unchangedNew = new QuoteLineItem(Id = lineA.Id, QuoteId = q.Id, Product2Id = prodA.Id, Quantity = 1, UnitPrice = 100);
        QuoteLineItem changedNew   = new QuoteLineItem(Id = lineB.Id, QuoteId = q.Id, Product2Id = prodA.Id, Quantity = 1, UnitPrice = 100);

        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{
            lineA.Id => lineA,
            lineB.Id => lineB
        };

        QuoteLineItemTriggerHandler handler = new QuoteLineItemTriggerHandler();
        List<QuoteLineItem> filtered = handler.filterChangedQuoteLineItems(
            new List<QuoteLineItem>{ unchangedNew, changedNew }, oldMap
        );

        TestAssert.equals(1, filtered.size(), 'Only the line with a changed product should be returned');
        TestAssert.equals(lineB.Id, filtered[0].Id, 'Expected the changed line to be included');
    }
}
