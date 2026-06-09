public with sharing class LogisticsNotificationController {
    //pag nag trigger ang flow ng email alert, the record Id will be passed into this variable
    public Id recordId { get; set; } // this will hold the recordId passed from the LWC

    public Quote QuoteDetails {
        get {
            //first check if the recordId exists, to prevent it from attempting to query without an ID, avoid run time error
            if(recordId == null) return null;

            List<Quote> quotes = [SELECT Contact.Name, ShippingStreet, ShippingCity,
                    ShippingState, ShippingPostalCode
                    FROM Quote WHERE Id = :recordId LIMIT 1]; //we query the quote based on the recordId passed from the LWC

            //return first record if found, otherwise return null/empty quote
            return !quotes.isEmpty() ? quotes[0] : new Quote();
        }
    }



    public List<QuoteLineItem> LineItems {
        //since ang standard template cant natively loop sa related list
        get {
            //return empty list instead of  null
            if(recordId == null) return new List<QuoteLineItem>();

            // This query pulls the Name and Quantity for the specific Quote
            return [SELECT Product2.Name, Quantity
                    FROM QuoteLineItem
                    WHERE QuoteId = :recordId];
        }
    }
}
