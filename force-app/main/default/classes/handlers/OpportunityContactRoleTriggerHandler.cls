public with sharing class OpportunityContactRoleTriggerHandler extends TriggerHandler
{

    private FrozenQuoteService frozenQuoteService;

    public OpportunityContactRoleTriggerHandler()
    {
        this.frozenQuoteService = new FrozenQuoteService();
    }

    public OpportunityContactRoleTriggerHandler(FrozenQuoteService frozenQuoteService)
    {
        this.frozenQuoteService = frozenQuoteService;
    }

    public override void beforeInsert()
    {
        List<OpportunityContactRole> newRoles = (List<OpportunityContactRole>) Trigger.new;
        Logger.info('OpportunityContactRole beforeInsert: checking ' + newRoles.size() + ' record(s) against freeze')
            .addTag('OpportunityContactRole');
        try
        {
            this.frozenQuoteService.enforceFreezeOnContactRoles(newRoles);
        }
        catch (Exception e)
        {
            Logger.error('Unexpected error in OpportunityContactRole beforeInsert', e);
            throw e;
        }
        finally
        {
            Logger.saveLog();
        }
    }

    public override void beforeDelete()
    {
        List<OpportunityContactRole> oldRoles = (List<OpportunityContactRole>) Trigger.old;
        Logger.info('OpportunityContactRole beforeDelete: checking ' + oldRoles.size() + ' record(s) against freeze')
            .addTag('OpportunityContactRole');
        try
        {
            this.frozenQuoteService.enforceFreezeOnContactRoles(oldRoles);
        }
        catch (Exception e)
        {
            Logger.error('Unexpected error in OpportunityContactRole beforeDelete', e);
            throw e;
        }
        finally
        {
            Logger.saveLog();
        }
    }
}
