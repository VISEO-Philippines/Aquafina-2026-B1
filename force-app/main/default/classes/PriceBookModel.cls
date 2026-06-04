public with sharing class PriceBookModel {
    // public static PriceBook getPriceBook() {
    //}

    public static List<PriceBookEntry> getPriceBookEntry(List<Id> recordIds) {
        if (recordIds.isEmpty()) {
            Logger.error('Attempted to retrieve PriceBookEntry with empty recordId argument.');
            return new List<PriceBookEntry>();
        } else {
            return [SELECT Id, Product2Id FROM PriceBookEntry WHERE Id IN :recordIds];
        }
    }
}