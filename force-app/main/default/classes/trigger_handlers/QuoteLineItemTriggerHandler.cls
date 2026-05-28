public with sharing class QuoteLineItemTriggerHandler extends TriggerHandler {
    // Filtration rule 
    // Handler validation must meet three strict rules:
    // - It operates strictly in-memory (zero SOQL queries).
    // - It evaluates only the current record (it doesn't look at other records in the batch or compare fields across records).
    // - It checks for PRESENCE (Is the record here?) or SHAPE (how the current record is shifting shape from its previous state), not business meaning.
    
    private void enforceProductNotRepeated(List<QuoteLineItem> triggernew) {
        // DONE: Filter contents of triggernew here, only check if the fields required for business validation in the service are populated properly
        List<QuoteLineItem> t_new = new List<QuoteLineItem>();
        for (QuoteLineItem qli : triggernew) {
            // Is this even possible?
            if (qli.QuoteId == null) {
                qli.addError('QuoteLineItem must be associated to a Quote.');
                continue;
            }
            if (qli.PriceBookEntryId == null) {
                qli.addError('QuoteLineItem must have a PriceBookEntry.');
                continue;
            }
            t_new.add(qli);
        }
        // call QuoteLineItemValidationService
        QuoteLineItemValidationService.enforceProductNotRepeated(t_new);
    }
    
    public override void beforeInsert() {
        Logger.info('QuoteLineItem-beforeInsert triggered with ' + Trigger.new.size() + ' records.');
        // FOR AP2-US-0002 call QuoteLockService(Trigger.new) - must filter out records that are inserting to Quote records that are locked due to Quote Status = In Review - has to return filtered list potential problem is this does not propagate, if for example we are locking opportunity, only the objects that reference the opportunityId can cleanly reuse this. Quote Line item for example cannot be locked since it has a reference to quote which references opportunity.
        enforceProductNotRepeated(Trigger.new);
    }

    public override void beforeUpdate() {
        Logger.info('QuoteLineItem-beforeUpdate triggered with ' + Trigger.new.size() + ' records.');
        // FOR AP2-US-0002 call QuoteLockService(Trigger.new) - must filter out records that are inserting to Quote records that are locked due to Quote Status = In Review - has to return filtered list
        enforceProductNotRepeated(Trigger.new);
    }
}