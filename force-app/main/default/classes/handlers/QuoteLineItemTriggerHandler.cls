public with sharing class QuoteLineItemTriggerHandler extends TriggerHandler
{

    private DuplicateProductService duplicateProductService;
    private FrozenQuoteService      frozenQuoteService;

    public QuoteLineItemTriggerHandler()
    {
        this.duplicateProductService = new DuplicateProductService();
        this.frozenQuoteService      = new FrozenQuoteService();
    }

    public QuoteLineItemTriggerHandler(
        DuplicateProductService duplicateProductService,
        FrozenQuoteService frozenQuoteService
    )
    {
        this.duplicateProductService = duplicateProductService;
        this.frozenQuoteService      = frozenQuoteService;
    }

    public override void beforeInsert()
    {
        List<QuoteLineItem> newLines = (List<QuoteLineItem>) Trigger.new;
        Logger.info('QuoteLineItem beforeInsert: validating ' + newLines.size() + ' record(s)')
            .addTag('QuoteLineItem');
        try
        {
            this.frozenQuoteService.enforceFreezeOnQuoteLineItems(newLines);
            this.duplicateProductService.checkDuplicateProducts(newLines);
        }
        catch (Exception e)
        {
            Logger.error('Unexpected error in QuoteLineItem beforeInsert', e);
            throw e;
        }
        finally
        {
            Logger.saveLog();
        }
    }

    public override void beforeUpdate()
    {
        List<QuoteLineItem> newLines = (List<QuoteLineItem>) Trigger.new;
        Logger.info('QuoteLineItem beforeUpdate: evaluating ' + newLines.size() + ' record(s)')
            .addTag('QuoteLineItem');
        try
        {
            this.frozenQuoteService.enforceFreezeOnQuoteLineItems(newLines);
            this.duplicateProductService.checkDuplicateProducts(
                newLines,
                (Map<Id, QuoteLineItem>) Trigger.oldMap
            );
        }
        catch (Exception e)
        {
            Logger.error('Unexpected error in QuoteLineItem beforeUpdate', e);
            throw e;
        }
        finally
        {
            Logger.saveLog();
        }
    }

    public override void beforeDelete()
    {
        List<QuoteLineItem> oldLines = (List<QuoteLineItem>) Trigger.old;
        Logger.info('QuoteLineItem beforeDelete: checking ' + oldLines.size() + ' record(s) against freeze')
            .addTag('QuoteLineItem');
        try
        {
            this.frozenQuoteService.enforceFreezeOnQuoteLineItems(oldLines);
        }
        catch (Exception e)
        {
            Logger.error('Unexpected error in QuoteLineItem beforeDelete', e);
            throw e;
        }
        finally
        {
            Logger.saveLog();
        }
    }
}
