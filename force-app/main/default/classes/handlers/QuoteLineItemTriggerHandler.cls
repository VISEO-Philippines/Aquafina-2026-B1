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
        this.duplicateProductService.checkDuplicateProducts((List<QuoteLineItem>) Trigger.new);
    }

    public override void beforeUpdate()
    {
        this.duplicateProductService.checkDuplicateProducts(
            (List<QuoteLineItem>) Trigger.new,
            (Map<Id, QuoteLineItem>) Trigger.oldMap
        );
    }
}
