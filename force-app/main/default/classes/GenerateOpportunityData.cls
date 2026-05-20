public with sharing class GenerateOpportunityData {
    public static void GenerateRandomOppRecords(Integer numberOfIterations) {
        //Account to use
        List<Account> accounts = [SELECT Id, Name FROM Account];
        // List<Product2> products = [SELECT Id, Name FROM Product2];
        List<User> salesUsers = [ SELECT Id, IsActive, Name FROM User WHERE Id IN ('005dL00001juFrbQAE', '005dL00001juO5GQAU', '005dL00001juMEGQA2', '005dL00001juO5FQAU', '005dL00001juMEFQA2', '005dL00001juEU6QAM', '005dL00001juFraQAE') AND  IsActive=true ];

        //list to use to populate DB
        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i=0; i< numberOfIterations; i++){

            List<String> STAGE_NAMES = new List<String>{'New', 'Quote Sent','Negotiation'};
            Date timeNow = Date.today();
            Date oneMonthFromNow = timeNow.addMonths(GenerateRandomNumberFromRange(12)); //adds 1 month to current month


            Integer randomNumberForAccount = GenerateRandomNumberFromRange(accounts.size()-1);

            // //VERSION 1
            // // Sample Record: Company ABC - 999 AQUAFINA Pack Of 5 Bottles
            // String opportunityName = accounts[randomNumberForAccount].Name + ' - ' + String.valueOf(GenerateRandomNumberFromRange(900)+10) + ' ' + products[GenerateRandomNumberFromRange(products.size()-1)].Name; // Company ABC - AQUAFINA Pack Of 5 Bottles

            // Version 2 more aligned with a more realistic scenario of having multiple quotes
            // Sample record: Company ABC - 999 AQUAFINA Bottles
            String opportunityName = accounts[randomNumberForAccount].Name + ' - ' + String.valueOf(GenerateRandomNumberFromRange(900)+10) + ' ' + 'AQUAFINA Water Bottles';


            String accountId = accounts[randomNumberForAccount].Id;
            String stageName = STAGE_NAMES[GenerateRandomNumberFromRange(STAGE_NAMES.size()-1)];
            String ownerId = salesUsers[GenerateRandomNumberFromRange(salesUsers.size()-1)].Id;
            

            opportunities.add(new Opportunity(

                Name = opportunityName,
                AccountId = accountId,
                StageName = stageName,
                CloseDate = oneMonthFromNow,
                OwnerId = ownerId

            ));
            
        } insert opportunities;
    }


    public static void GenerateRandomOppRecords(Integer numberOfIterations, String country) {
        //Account to use
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE ShippingCountry = :country];
        // List<Product2> products = [SELECT Id, Name FROM Product2];
        List<User> salesUsers = [ SELECT Id, IsActive, Name FROM User WHERE Id IN ('005dL00001juFrbQAE', '005dL00001juO5GQAU', '005dL00001juMEGQA2', '005dL00001juO5FQAU', '005dL00001juMEFQA2', '005dL00001juEU6QAM', '005dL00001juFraQAE') AND  IsActive=true ];

        //list to use to populate DB
        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i=0; i< numberOfIterations; i++){

            List<String> STAGE_NAMES = new List<String>{'New', 'Quote Sent','Negotiation'};
            Date timeNow = Date.today();
            Date oneMonthFromNow = timeNow.addMonths(GenerateRandomNumberFromRange(12)); //adds 1 month to current month


            Integer randomNumberForAccount = GenerateRandomNumberFromRange(accounts.size()-1);

            // Version 2 more aligned with a more realistic scenario of having multiple quotes
            // Sample record: Company ABC - 999 AQUAFINA Bottles
            String opportunityName = accounts[randomNumberForAccount].Name + ' - ' + String.valueOf(GenerateRandomNumberFromRange(900)+10) + ' ' + 'AQUAFINA Water Bottles';


            String accountId = accounts[randomNumberForAccount].Id;
            String stageName = STAGE_NAMES[GenerateRandomNumberFromRange(STAGE_NAMES.size()-1)];
            String ownerId = salesUsers[GenerateRandomNumberFromRange(salesUsers.size()-1)].Id;
            

            opportunities.add(new Opportunity(

                Name = opportunityName,
                AccountId = accountId,
                StageName = stageName,
                CloseDate = oneMonthFromNow,
                OwnerId = ownerId

            ));
            
        } insert opportunities;
    }

    

    private static Integer GenerateRandomNumberFromRange(Integer max){

        Integer min = 0;
        Integer randomNum = Integer.valueOf(Math.random() * (max - min + 1) + min);
        System.debug('random number is: '+ String.valueOf(randomNum));
        return randomNum;
    }
}