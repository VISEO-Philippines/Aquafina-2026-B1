public with sharing class FetchQuoteLineItems {
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItemWrapperClass> fetchQuoteLineItemWrapperClass(String oppId){

        List <QuoteLineItemWrapperClass> lstQteLineItemWrapper = new List <QuoteLineItemWrapperClass>();
        for (QuoteLineItem qteLineItem: [SELECT Id, QuoteLineItem.OpportunityLineItem.Name, QuoteLineItem.Quantity, QuoteLineItem.Discount, QuoteLineItem.Subtotal FROM QuoteLineItem WHERE QuoteLineItem.OpportunityLineItem.OpportunityId = :oppId]){
            lstQteLineItemWrapper.add(new QuoteLineItemWrapperClass(qteLineItem));
        }
        return lstQteLineItemWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> checkIfHasLineItems(String oppId){
        List<QuoteLineItem> qli =  [SELECT Id FROM QuoteLineItem WHERE QuoteLineItem.OpportunityLineItem.OpportunityId = :oppId];
        return qli;
    }

    // Defining Class properties
    public class QuoteLineItemWrapperClass {
        @AuraEnabled
        public QuoteLineItem quoteLineItem;
        // @AuraEnabled
        // public Integer numberOfQuoteLineItems;
        @AuraEnabled
        public String quoteLineItemName;
        @AuraEnabled
        public String quoteLineItemLink;
        @AuraEnabled
        public Decimal quantity;
        @AuraEnabled
        public Double discount;
        @AuraEnabled
        public Double subtotal;
        @AuraEnabled
        public Double totalDiscounted;

        // class constructor... basically what the class will contain everytiem
        public QuoteLineItemWrapperClass(QuoteLineItem qteLineItem){
            this.quoteLineItem = qteLineItem;
            // this.numberOfQuoteLineItems = numberOfQteLineItems;
            this.quoteLineItemName = qteLineItem.OpportunityLineItem.Name;
            this.quoteLineItemLink = '/' + qteLineItem.Id;
            this.quantity = qteLineItem.Quantity;
            this.discount = qteLineItem.Discount;
            this.subtotal = qteLineItem.Subtotal;
            this.totalDiscounted = subtotal * (discount/100);
        }

    }
}