/**
 * Controller for Deal Summary LWC.
 * Provides deal context, quote status, contact info, and readiness checks for a given Opportunity.
 *
 * Note: cacheable=true is intentionally omitted so Logger.saveLog() can execute (it performs DML via
 * platform events, which is prohibited in cacheable AuraEnabled methods). If wire-based caching is
 * more important than persistent observability, re-add cacheable=true and remove Logger.saveLog().
 */
public with sharing class DealSummaryController {

    /**
     * Retrieves deal summary data for a single Opportunity.
     * Queries Opportunity, Quote, and Contact details in a single database call.
     * Returns a wrapper object with all needed context for the UI to render and compute checks.
     */
    @AuraEnabled
    public static DealSummaryWrapper getDealSummary(Id opportunityId) {
        Logger.info('getDealSummary invoked').setRecord(opportunityId);
        try
        {
            DealSummaryWrapper wrapper = new DealSummaryWrapper();

            // Single SOQL query to fetch Opportunity, child Quote (syncing only), and primary Contact.
            // Reduces network round-trips and improves performance.
            List<Opportunity> opps = [
                SELECT Id, Name, StageName, AccountId, Account.Name,
                       Total_List_Amount__c, Total_Discounted_Amount__c,
                       Effective_Deal_Discount__c, Net_Amount__c,
                       VAT_Amount__c, Total_Amount__c,
                       (SELECT Id, Name, Status, TotalPrice, Discount,
                               (SELECT Id FROM QuoteLineItems LIMIT 1)
                        FROM Quotes
                        WHERE IsSyncing = true
                        LIMIT 1),
                       (SELECT Id, ContactId, Contact.Name, Contact.Email,
                               IsPrimary
                        FROM OpportunityContactRoles
                        WHERE IsPrimary = true
                        LIMIT 1)
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            if (opps.isEmpty())
            {
                Logger.warn('getDealSummary: no Opportunity found').setRecord(opportunityId);
                return wrapper;
            }

            Opportunity opp = opps[0];

            // ========== DEAL & ACCOUNT CONTEXT ===========
            wrapper.opportunityName = opp.Name;
            wrapper.accountName = opp.Account?.Name;
            wrapper.stageName = opp.StageName;
            wrapper.totalListAmount = opp.Total_List_Amount__c;
            wrapper.totalDiscountedAmount = opp.Total_Discounted_Amount__c;
            wrapper.effectiveDiscount = opp.Effective_Deal_Discount__c;
            wrapper.netAmount = opp.Net_Amount__c;
            wrapper.vatAmount = opp.VAT_Amount__c;
            wrapper.totalAmount = opp.Total_Amount__c;

            // ========== QUOTE VALIDATION ===========
            if (!opp.Quotes.isEmpty())
            {
                Quote q = opp.Quotes[0];
                wrapper.quoteId = q.Id;
                wrapper.quoteName = q.Name;
                wrapper.quoteStatus = q.Status;
                wrapper.hasQuote = true;
                wrapper.quoteAccepted = (q.Status == 'Approved');
                wrapper.quoteHasProducts = q.QuoteLineItems != null && !q.QuoteLineItems.isEmpty();
            }
            else
            {
                Logger.warn('getDealSummary: no syncing quote found for Opportunity').setRecord(opp.Id);
            }

            // ========== CONTACT VALIDATION ===========
            if (!opp.OpportunityContactRoles.isEmpty())
            {
                OpportunityContactRole role = opp.OpportunityContactRoles[0];
                wrapper.primaryContactName = role.Contact?.Name;
                // Contact email is populated in the wrapper but intentionally excluded from log entries
                // to avoid storing PII in Nebula Logger logs.
                wrapper.primaryContactEmail = role.Contact?.Email;
                wrapper.hasPrimaryContact = true;
                wrapper.contactHasEmail = String.isNotBlank(role.Contact?.Email);
            }
            else
            {
                Logger.warn('getDealSummary: no primary contact role found for Opportunity').setRecord(opp.Id);
            }

            // ========== FINANCIAL READINESS ===========
            wrapper.financialsCalculable = (
                wrapper.totalListAmount != null && wrapper.totalListAmount > 0
            );

            Logger.info('getDealSummary completed: hasQuote=' + wrapper.hasQuote
                + ', hasPrimaryContact=' + wrapper.hasPrimaryContact
                + ', financialsCalculable=' + wrapper.financialsCalculable)
                .setRecord(opp.Id);

            return wrapper;
        }
        catch (Exception e)
        {
            Logger.error('Unexpected error in getDealSummary', e);
            throw new AuraHandledException(e.getMessage());
        }
        finally
        {
            Logger.saveLog();
        }
    }

    public class DealSummaryWrapper {
        // ---- Opportunity & Account Identity ----
        @AuraEnabled public String opportunityName;
        @AuraEnabled public String accountName;
        @AuraEnabled public String stageName;
        // ---- Quote Details ----
        @AuraEnabled public Id quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public String quoteStatus;
        // ---- Financial Values ----
        @AuraEnabled public Decimal totalListAmount;
        @AuraEnabled public Decimal totalDiscountedAmount;
        @AuraEnabled public Decimal effectiveDiscount;
        @AuraEnabled public Decimal netAmount;
        @AuraEnabled public Decimal vatAmount;
        @AuraEnabled public Decimal totalAmount;
        // ---- Readiness Check Flags (used by UI for validation checklist) ----
        @AuraEnabled public Boolean hasQuote = false;
        @AuraEnabled public Boolean quoteAccepted = false;
        @AuraEnabled public Boolean quoteHasProducts = false;
        @AuraEnabled public Boolean hasPrimaryContact = false;
        @AuraEnabled public Boolean contactHasEmail = false;
        @AuraEnabled public Boolean financialsCalculable = false;
        // ---- Primary Contact Details ----
        @AuraEnabled public String primaryContactName;
        @AuraEnabled public String primaryContactEmail;
    }
}
