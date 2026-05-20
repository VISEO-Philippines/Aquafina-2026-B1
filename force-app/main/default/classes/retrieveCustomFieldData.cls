public with sharing class retrieveCustomFieldData {
    public static List<Account> retrieveCustomFieldData() {
        try {
            System.debug('nice');
            List<Account> acc = [SELECT Id, Customer_Type__c FROM Account WHERE Name='ABC, Inc.'];
            System.debug(acc);
            return acc;
            
        } catch (Exception e) {
            System.debug('couldnt retrieve object');
            return null;
        }
        
    }
}