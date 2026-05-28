public with sharing class PriceBookModel {
    // public static PriceBook getPriceBook() {
    //}

    public static List<PriceBookEntry> getPriceBookEntry(List<Id> recordIds) {
        try {
            return [SELECT Id, Product2Id FROM PriceBookEntry WHERE Id IN :recordIds];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}