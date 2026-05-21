public with sharing class DealDashboard {
    
    // The lwc component will receive a struct with the opportunityid and related objects 
    // we queried
    public class DealData {
        @AuraEnabled public Opportunity opp;
        @AuraEnabled public Quote quote;
        @AuraEnabled public OpportunityContactRole primaryContact;
        @AuraEnabled public List<QuoteLineItem> lineItems;
    }

    // We retrieve the Quote that is synced to the opportunity and the contact role that is primary to build
    // the dashboard.
    @AuraEnabled(cacheable=true)
    public static DealData getDealData(Id oppId){
        try {
            DealData data = new DealData();
            Id quoteId;
            data.opp = OpportunityModel.getOpportunity(oppId);
            
            if (data.opp == null) {
                throw new AuraHandledException('Failed to get Opportunity record for Deal Dashboard.');
            }

            // TODO: merge this with SOQL for Quote Line items
            // in this format-ish: SELECT Id, (SELECT Id FROM QuoteLineItems) FROM Quote where Id =: quoteId
            if (data.opp.SyncedQuoteId != null) {
                quoteId = data.opp.SyncedQuoteId;
                List<Quote> quotes = QuoteModel.getQuote(quoteId);
                if (!quotes.isEmpty()) {
                    data.quote = quotes[0];
                }
            }

            // --- PRIMARY CONTACT ---
            List<OpportunityContactRole> roles = OpportunityContactRoleModel.getPrimaryContactRoleFromOpportunity(oppId);
            
            if (!roles.isEmpty()) {
                data.primaryContact = roles[0];
            }

            List<QuoteLineItem> lineItems = QuoteModel.getQuoteLineItems(quoteId);

            if (!lineItems.isEmpty()) {
                data.lineItems = lineItems;
            }

            return data;


        } catch (Exception e) {
            throw new AuraHandledException('Failed to fetch DealData for Deal Dashboard. Error: ' + e.getMessage());
        }
    }
}