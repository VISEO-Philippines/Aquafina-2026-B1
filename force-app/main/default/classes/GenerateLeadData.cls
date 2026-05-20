public with sharing class GenerateLeadData {

    //main method

    public static void GenerateAppropriateEmails() {
        List<Lead> leads = [SELECT Id, Email, LastName, Customer_Type__c, CountryCode, Company FROM Lead];
        for(Lead l : leads){
            String separator = '.';
            String atSign = '@';
            String emailPrefix = ParseStringForEmails(l.LastName); //bouchard
            String emailPostfix; 
            if (l.CountryCode == 'FR'){
                emailPostfix = ParseStringForEmails(l.Company) + '.fr'; //aquafina.fr
            } else if (l.CountryCode == 'ES'){
                emailPostfix = ParseStringForEmails(l.Company) + '.es'; //aquafina.es
            } else {
                emailPostfix = ParseStringForEmails(l.Company) + '.com'; //aquafina.com
            }
            l.Email = emailPrefix + atSign + emailPostfix; //bouchard@aquafina.fr/es/com
            //System.debug(l.Email);
        }
        update leads;
    }

    private static String ParseStringForEmails(String str){
        return str.toLowerCase().replace('é','e').replace(' ','').replace('è','e').replace('.','').replace(',','');
    }
}