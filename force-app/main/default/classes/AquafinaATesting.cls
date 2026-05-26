@IsTest(SeeAllData=true)
public with sharing class AquafinaATesting {

    @IsTest
    static void CheckVisibleCEO() {
        // Query si Charlotte (Sales Director, Lahat)
        User charlotteCEO = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'CEO' LIMIT 1];
        charlotteCEO.IsActive = true;
        update charlotteCEO;
        
        User julienSD = [SELECT Id, IsActive FROM User where UserRole.Name = 'Sales Director' LIMIT 1];
        julienSD.IsActive = true;
        update julienSD;
        
        User isabellaSODSpain = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, Spain' LIMIT 1];
        isabellaSODSpain.IsActive = true;
        update isabellaSODSpain;

        User jeromeSODFrance = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, France' LIMIT 1];
        jeromeSODFrance.IsActive = true;
        update jeromeSODFrance;
        
        User jeanSRNorth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, North' LIMIT 1];
        jeanSRNorth.IsActive = true;
        update jeanSRNorth;

        User francSRSouth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, South' LIMIT 1];
        francSRSouth.IsActive = true;
        update francSRSouth;

        User andresSRWest = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, West' LIMIT 1];
        andresSRWest.IsActive = true;
        update andresSRWest;

        User sergioSREast = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, East' LIMIT 1];
        sergioSREast.IsActive = true;
        update sergioSREast;

        System.runAs(julienSD){
            Account acc = new Account(Name = 'Test Account ni Julien');
            insert acc;
        }

        System.runAs(isabellaSODSpain){
            Account acc = new Account(Name = 'Test Account ni Isabella');
            insert acc;
        }

        System.runAs(jeromeSODFrance){
            Account acc = new Account(Name = 'Test Account ni Jerome');
            insert acc;
        }

        System.runAs(jeanSRNorth){
            Account acc = new Account(Name = 'Test Account ni Jean');
            insert acc;
        }

        System.runAs(francSRSouth){
            Account acc = new Account(Name = 'Test Account ni Franc');
            insert acc;
        }

        System.runAs(andresSRWest){
            Account acc = new Account(Name = 'Test Account ni Andres');
            insert acc;
        }

        System.runAs(sergioSREast){
            Account acc = new Account(Name = 'Test Account ni Sergio');
            insert acc;
        }

        Test.startTest();
        System.runAs(charlotteCEO){
            List<Account> accs = [SELECT Id, Name FROM Account WHERE Name IN ('Test Account ni Julien' , 'Test Account ni Jerome', 'Test Account ni Isabella', 'Test Account ni Jean', 'Test Account ni Franc', 'Test Account ni Andres', 'Test Account ni Sergio')];
            Assert.areEqual(false, accs.isEmpty(), 'CEO cannot see everything');
        }
        Test.stopTest();  
    }

    @IsTest
    static void CheckVisibleSalesDirector() {
        // Query si Charlotte (Sales Director, Lahat)
        User charlotteCEO = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'CEO' LIMIT 1];
        charlotteCEO.IsActive = true;
        update charlotteCEO;
        
        User julienSD = [SELECT Id, IsActive FROM User where UserRole.Name = 'Sales Director' LIMIT 1];
        julienSD.IsActive = true;
        update julienSD;
        
        User isabellaSODSpain = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, Spain' LIMIT 1];
        isabellaSODSpain.IsActive = true;
        update isabellaSODSpain;

        User jeromeSODFrance = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, France' LIMIT 1];
        jeromeSODFrance.IsActive = true;
        update jeromeSODFrance;
        
        User jeanSRNorth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, North' LIMIT 1];
        jeanSRNorth.IsActive = true;
        update jeanSRNorth;

        User francSRSouth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, South' LIMIT 1];
        francSRSouth.IsActive = true;
        update francSRSouth;

        User andresSRWest = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, West' LIMIT 1];
        andresSRWest.IsActive = true;
        update andresSRWest;

        User sergioSREast = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, East' LIMIT 1];
        sergioSREast.IsActive = true;
        update sergioSREast;

        System.runAs(charlotteCEO){
            Account acc = new Account(Name = 'Test Account ni Charlotte');
            insert acc;
        }

        System.runAs(isabellaSODSpain){
            Account acc = new Account(Name = 'Test Account ni Isabella');
            insert acc;
        }

        System.runAs(jeromeSODFrance){
            Account acc = new Account(Name = 'Test Account ni Jerome');
            insert acc;
        }

        System.runAs(jeanSRNorth){
            Account acc = new Account(Name = 'Test Account ni Jean');
            insert acc;
        }

        System.runAs(francSRSouth){
            Account acc = new Account(Name = 'Test Account ni Franc');
            insert acc;
        }

        System.runAs(andresSRWest){
            Account acc = new Account(Name = 'Test Account ni Andres');
            insert acc;
        }

        System.runAs(sergioSREast){
            Account acc = new Account(Name = 'Test Account ni Sergio');
            insert acc;
        }

        Test.startTest();
        System.runAs(julienSD){
            List<Account> accs = [SELECT Id, Name FROM Account WHERE Name IN ('Test Account ni Jerome', 'Test Account ni Isabella', 'Test Account ni Jean', 'Test Account ni Franc', 'Test Account ni Andres', 'Test Account ni Sergio')];
            Assert.areEqual(false, accs.isEmpty(), 'CEO cannot see everything');
            List<Account> accQueriedFromCharlotte = [SELECT Id, Name FROM Account WHERE Name = 'Test Account Ni Charlotte'];
            Assert.areEqual(true, accQueriedFromCharlotte.isEmpty(), 'Julien should not see accounts from the CEO');
        }
        Test.stopTest();
    }

    //Check Spain SOD's visibility
    @IsTest
    static void CheckVisibleSODSpain() {
        // Query si Isabella (Sales Director, France)
        User isabellaSODSpain = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, Spain' LIMIT 1];
        isabellaSODSpain.IsActive = true;
        update isabellaSODSpain;


        User francSRSouth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, South' LIMIT 1];
        francSRSouth.IsActive = true;
        update francSRSouth;

        System.runAs(francSRSouth){
            Account acc = new Account(Name = 'Test Account ni Franc');
            insert acc;
        }

        Test.startTest();
        System.runAs(isabellaSODSpain){
            List<Account> accQueriedFromFranc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account ni Franc' LIMIT 1];
            Assert.areEqual(true, accQueriedFromFranc.isEmpty(), 'Why can isabella see accounts from France');
        }
        Test.stopTest();
    }

    @IsTest
    static void CheckVisibleSODSpain2() {
        // Query si Isabella (Sales Director, France)
        User isabellaSODSpain = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, Spain' LIMIT 1];
        isabellaSODSpain.IsActive = true;
        update isabellaSODSpain;


        //Query naman si Sergio aka Sales rep from Spain
        User andresSRWest = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, West' LIMIT 1];
        andresSRWest.IsActive = true;
        update andresSRWest;

        //Create new account as andres the sales rep from Spain
        System.runAs(andresSRWest){
            Account acc = new Account(Name = 'Test Account ni Andres');
            insert acc;
        }

        Test.startTest();
        System.runAs(isabellaSODSpain){
            List<Account> accQueriedFromFranc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account ni Andres' LIMIT 1];
            Assert.areEqual(false, accQueriedFromFranc.isEmpty(), 'Why cant isabella see accounts from Spain');
        }
        Test.stopTest();
    }

    @IsTest
    static void CheckVisibleSODSpain3() {
        // Query si Isabella (Sales Director, France)
        User isabellaSODSpain = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, Spain' LIMIT 1];
        isabellaSODSpain.IsActive = true;
        update isabellaSODSpain;


        User jeanSRNorth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, North' LIMIT 1];
        jeanSRNorth.IsActive = true;
        update jeanSRNorth;

        System.runAs(jeanSRNorth){
            Account acc = new Account(Name = 'Test Account ni Jean');
            insert acc;
        }

        Test.startTest();
        System.runAs(isabellaSODSpain){
            List<Account> accQueriedFromFranc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account ni Jean' LIMIT 1];
            Assert.areEqual(true, accQueriedFromFranc.isEmpty(), 'Isabella can see accounts from France');
        }
        Test.stopTest();
    }

    //Check France SOD's visibility
    @IsTest
    static void CheckVisibleSODFrance() {
        
        //Query si Jerome aka SOD ng France
        User jeromeSODFrance = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, France' LIMIT 1];
        jeromeSODFrance.IsActive = true;
        update jeromeSODFrance;

        //Query naman si Sergio aka Sales rep from Spain
        User andresSRWest = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, West' LIMIT 1];
        andresSRWest.IsActive = true;
        update andresSRWest;

        //Create new account as andres the sales rep from Spain
        System.runAs(andresSRWest){
            Account acc = new Account(Name = 'Test Account ni Andres');
            insert acc;
        }

        //Check kung kita ba ni jeromeSodFra yung account na gawa ni andres
        Test.startTest();
        System.runAs(jeromeSODFrance){
            List<Account> accQueriedFromAndres = [SELECT Id, Name FROM Account WHERE Name = 'Test Account ni Andres' LIMIT 1];
            Assert.areEqual(true, accQueriedFromAndres.isEmpty(), 'Hala bat may nakikita si jerome galing kay Andres');

        }
        Test.stopTest();
    }

    @IsTest
    static void CheckVisibleSODFrance2() {
        
        //Query si Jerome aka SOD ng France
        User jeromeSODFrance = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, France' LIMIT 1];
        jeromeSODFrance.IsActive = true;
        update jeromeSODFrance;

        //Query naman si Sergio aka Sales rep from Spain
        User sergioSREast = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, East' LIMIT 1];
        sergioSREast.IsActive = true;
        update sergioSREast;

        //Create new account as andres the sales rep from Spain
        System.runAs(sergioSREast){
            Account acc = new Account(Name = 'Test Account ni Sergio');
            insert acc;
        }

        //Check kung kita ba ni jeromeSodFra yung account na gawa ni andres
        Test.startTest();
        System.runAs(jeromeSODFrance){
            List<Account> accQueriedFromSergio = [SELECT Id, Name FROM Account WHERE Name = 'Test Account ni Andres' LIMIT 1];
            Assert.areEqual(true, accQueriedFromSergio.isEmpty(), 'Hala bat may nakikita si jerome galing kay Sergio');

        }
        Test.stopTest();
    }

    @IsTest
    static void CheckVisibleSODFrance3() {
        
        //Query si Jerome aka SOD ng France
        User jeromeSODFrance = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Operations Director, France' LIMIT 1];
        jeromeSODFrance.IsActive = true;
        update jeromeSODFrance;

        User jeanSRNorth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, North' LIMIT 1];
        jeanSRNorth.IsActive = true;
        update jeanSRNorth;

        System.runAs(jeanSRNorth){
            Account acc = new Account(Name = 'Test Account ni Jean');
            insert acc;
        }

        //Check kung kita ba ni jeromeSodFra yung account na gawa ni andres
        Test.startTest();
        System.runAs(jeromeSODFrance){
            List<Account> accQueriedFromJean = [SELECT Id, Name FROM Account WHERE Name = 'Test Account ni Jean' LIMIT 1];
            Assert.areEqual(false, accQueriedFromJean.isEmpty(), 'Why cant Jerome see accounts from France');
        }
        Test.stopTest();
    }

    @IsTest
    static void CheckVisibleSalesRepFrance() {
        
        User jeanSRNorth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, North' LIMIT 1];
        jeanSRNorth.IsActive = true;
        update jeanSRNorth;

        User francSRSouth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, South' LIMIT 1];
        francSRSouth.IsActive = true;
        update francSRSouth;

        System.runAs(francSRSouth){
            Account acc = new Account(Name = 'Test Account ni Franc');
            insert acc;
        }

        //Check kung kita ba ni jean yung account na gawa ni franc
        Test.startTest();
        System.runAs(jeanSRNorth){
            List<Account> accQueriedFromFranc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account ni Franc' LIMIT 1];
            Assert.areEqual(true, accQueriedFromFranc.isEmpty(), 'Jean must not see records from Franc');
        }
        Test.stopTest();
    }

    @IsTest
    static void checkVisibilityNonSales(){
        
        // query sales users
        User jeanSRNorth = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, North' LIMIT 1];
        jeanSRNorth.IsActive = true;
        update jeanSRNorth;

        User andresSRWest = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Sales Representative, West' LIMIT 1];
        andresSRWest.IsActive = true;
        update andresSRWest;

        // query agent
        User timotheeAgent = [SELECT Id, IsActive FROM User WHERE UserRole.Name = 'Call Center Agent' LIMIT 1];
        timotheeAgent.IsActive = true;
        update timotheeAgent;

        List<String> newAcctNames = new List<String>();

        System.runAs(jeanSRNorth){
            Account newAcct = new Account(Name='Jean Test Account.');
            newAcctNames.add('Jean Test Account.');

            insert newAcct;
        }

        System.runAs(andresSRWest){
            Account newAcct = new Account (Name='Andres Test Account.');
            newAcctNames.add('Andres Test Account.');

            insert newAcct;

        }

        System.runAs(timotheeAgent){
            Account newAcct = new Account (Name='Timothee Test Account.');
            newAcctNames.add('Timothee Test Account.');

            insert newAcct;

        }

        //Visibility test
        Test.startTest();
        System.runAs(timotheeAgent){
            List<Account> accQuriedByAgent = [SELECT Id, Name FROM Account WHERE Name IN :newAcctNames];
            Assert.areEqual(false, accQuriedByAgent.isEmpty(), 'Agent must be able to view accounts made by sales');
        }
        Test.stopTest();


    }

}