public with sharing class QuoteLineItemTriggerHandler extends TriggerHandler
{

    private DuplicateProductService duplicateProductService;

    public QuoteLineItemTriggerHandler()
    {
        this.duplicateProductService = new DuplicateProductService();
    }

    public QuoteLineItemTriggerHandler(DuplicateProductService duplicateProductService)
    {
        this.duplicateProductService = duplicateProductService;
    }

    public override void beforeInsert()
    {
        List<QuoteLineItem> newLines = (List<QuoteLineItem>) Trigger.new;
        Logger.info('QuoteLineItem beforeInsert: validating ' + newLines.size() + ' record(s) for duplicate products')
            .addTag('QuoteLineItem');
        try
        {
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
        Logger.info('QuoteLineItem beforeUpdate: evaluating ' + newLines.size() + ' record(s) for product changes')
            .addTag('QuoteLineItem');
        try
        {
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
}
