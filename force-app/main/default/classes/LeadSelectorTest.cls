@IsTest
private class LeadSelectorTest {

    private static final String STATUS_OPEN = 'Open - Not Contacted';
    private static final String STATUS_CLOSED_NOT_CONVERTED = 'Closed - Not Converted';
    private static final String STATUS_DISQUALIFIED = 'Disqualified';

    @IsTest
    static void testGetStagnantOpenLeads_NullCutoffDate() {

        List<Lead> result = LeadSelector.getStagnantOpenLeads(
            null,
            new Set<String>{ STATUS_CLOSED_NOT_CONVERTED }
        );

        Assert.isTrue(
            result.isEmpty(),
            'A null cutoff date should return an empty list'
        );
    }

    @IsTest
    static void testGetStagnantOpenLeads_ExcludesConvertedAndClosedStatuses() {

        Lead openLead = TestDataFactory.createLead(STATUS_OPEN);
        Lead closedLead = TestDataFactory.createLead(STATUS_CLOSED_NOT_CONVERTED);
        Lead disqualifiedLead = TestDataFactory.createLead(STATUS_DISQUALIFIED);

        // Apex tests cannot backdate LastModifiedDate, so the cutoff is
        // shifted into the future to treat freshly inserted Leads as stagnant.
        DateTime cutoffDate = System.now().addDays(1);

        Test.startTest();
        List<Lead> result = LeadSelector.getStagnantOpenLeads(
            cutoffDate,
            new Set<String>{ STATUS_DISQUALIFIED, STATUS_CLOSED_NOT_CONVERTED }
        );
        Test.stopTest();

        Set<Id> resultIds = new Map<Id, Lead>(result).keySet();

        Assert.isTrue(
            resultIds.contains(openLead.Id),
            'Open Lead past the cutoff should be included'
        );
        Assert.isFalse(
            resultIds.contains(closedLead.Id),
            'Already closed Lead should be excluded'
        );
        Assert.isFalse(
            resultIds.contains(disqualifiedLead.Id),
            'Disqualified Lead should be excluded'
        );
    }
}
