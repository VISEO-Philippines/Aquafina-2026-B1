/* Main feedback here was to remove SeeAllData,
- to use TestSetup, and
- create users accordingly

Beyond this, I also approached Sir Mario and Sir Cedric before approaching you po Sir Melvin; the more the merrier,,, they'd say eme */

@IsTest
private with sharing class RevisedRoleVisibilityTest {
    @TestSetup
    private static void setupData(){

        //SOQL admin user na active
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive=true LIMIT 1];

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        List<UserRole> salesRoles = [SELECT Id, Name FROM UserRole WHERE Name IN ('CEO', 'Sales Director', 'Sales Operations Director, France', 'Sales Operations Director, Spain', 'Sales Representative, North', 'Sales Representative, South', 'Sales Representative, East', 'Sales Representative, West')];

        List<User> testSalesUsers = new List<User>();
        for (Integer counter=0; counter < salesRoles.size(); counter++){
            User newSalesUser = new User
            (
                Alias = 'testU' + String.valueOf(counter+1), 
                Email='standarduser' + String.valueOf(counter+1) + '@aquafina-sf-test.com',
                UserName='standarduser' + String.valueOf(counter+1) + '@aquafina-sf-test.com', 
                EmailEncodingKey='UTF-8', 
                LastName='Test' + String.valueOf(counter+1), 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US',  
                TimeZoneSidKey='Europe/Paris', 
                IsActive = true,
                ProfileId = standardProfile.Id,
                UserRoleId = salesRoles[counter].Id
            );
            testSalesUsers.add(newSalesUser);
        }

        /* key insight from Sir Cedric: SF is mainly about how you handle collection sObject like Lists (especially lists), Sets, and Maps, to name a few; this is due to the limits bestowed upon by governor limits (150  DMLs per transaction and 10k records per transaction) */
        insert testSalesUsers;

        // loop sales users -> runAs admin
        // gawa accounts based testsalesusers -> runAs admin

        
        // avoid mixed DML error
        System.runAs(adminUser){
            List<Account> accountsToInsert = new List<Account>();
            for (User salesUser: testSalesUsers){
                String testAccount = salesUser.Name + ' test account';
                // accountNames.add(testAccount);
                accountsToInsert.add(new Account(Name = testAccount, OwnerId= salesUser.Id));
            }
            insert accountsToInsert;
        }


    }

    /* Instantiates ceo role and a list of all other roles afterward, using the same method, the ceo queries the created test account to check visibility finally, the boolean canAccess is updated to reflect whether the test has passsed/ failed */
    @IsTest
    private static void checkVisibilityCeo() {

        // in the future, we can query the roles of the subordinates we are checking for -> scalability purposes
        // answers the question: "What if we add accounts in the setup data?"
        List<String> allSalesRoles = new List<String>{'CEO', 'Sales Director', 'Sales Operations Director, France', 'Sales Operations Director, Spain', 'Sales Representative, North', 'Sales Representative, South', 'Sales Representative, East', 'Sales Representative, West'};

        // System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name IN :allSalesRoles AND Owner.IsActive = true];

        // Query Test Ceo
        List<Account> accessibleAccounts = new List<Account>();
        User testCeoUser = [SELECT Id FROM User WHERE UserRole.Name='CEO' AND IsActive=true];
        System.runAs(testCeoUser){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: CEO must be able to access all records');

    }

    @IsTest
    private static void checkVisibilitySalesDirector(){

        List<String> allSalesRolesExceptCeo = new List<String>{'Sales Director', 'Sales Operations Director, France', 'Sales Operations Director, Spain', 'Sales Representative, North', 'Sales Representative, South', 'Sales Representative, East', 'Sales Representative, West'};

        //System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name IN :allSalesRolesExceptCeo AND Owner.IsActive = true];

        // Query Test Sales Director
        List<Account> accessibleAccounts = new List<Account>();
        User testSalesDirectorUser = [SELECT Id FROM User WHERE UserRole.Name='Sales Director' AND IsActive=true];
        System.runAs(testSalesDirectorUser){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: Sales Director must be able to access records except the CEO\'s');

    }

    @IsTest
    private static void checkVisibilitySodFrance(){
        List<String> allNonUpperFrenchSalesRoles = new List<String>{'Sales Operations Director, France', 'Sales Representative, North', 'Sales Representative, South'};

        //System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name IN :allNonUpperFrenchSalesRoles AND Owner.IsActive = true];

        // Query Test SOD France
        List<Account> accessibleAccounts = new List<Account>();
        User testSodFranceUser = [SELECT Id FROM User WHERE UserRole.Name='Sales Operations Director, France' AND IsActive=true];
        System.runAs(testSodFranceUser){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: Sales Operations Director, France must be able to access records only from Non-upper French Sales Roles');
    }

    @IsTest
    private static void checkVisibilitySodSpain(){
        List<String> allNonUpperFrenchSalesRoles = new List<String>{'Sales Operations Director, Spain', 'Sales Representative, West', 'Sales Representative, East'};

        //System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name IN :allNonUpperFrenchSalesRoles AND Owner.IsActive = true];

        // Query Test SOD Spain
        List<Account> accessibleAccounts = new List<Account>();
        User testSodSpainUser = [SELECT Id FROM User WHERE UserRole.Name='Sales Operations Director, Spain' AND IsActive=true];
        System.runAs(testSodSpainUser){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: Sales Operations Director, Spain must be able to access records only from Non-upper Spanish Sales Roles');
    }

    @IsTest
    private static void checkVisibilitySalesRepNorth(){
        //System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name='Sales Representative, North' AND Owner.IsActive = true];

        // Query Test SOD Spain
        List<Account> accessibleAccounts = new List<Account>();
        User testSalesRepNorth = [SELECT Id FROM User WHERE UserRole.Name='Sales Representative, North' AND IsActive=true];
        System.runAs(testSalesRepNorth){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: Sales Reps must be able to access only their own records');

    }

    @IsTest
    private static void checkVisibilitySalesRepSouth(){
        //System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name='Sales Representative, South' AND Owner.IsActive = true];

        // Query Test SOD Spain
        List<Account> accessibleAccounts = new List<Account>();
        User testSalesRepSouth = [SELECT Id FROM User WHERE UserRole.Name='Sales Representative, South' AND IsActive=true];
        System.runAs(testSalesRepSouth){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: Sales Reps must be able to access only their own records');

    }

    @IsTest
    private static void checkVisibilitySalesRepWest(){
        //System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name='Sales Representative, West' AND Owner.IsActive = true];

        // Query Test SOD Spain
        List<Account> accessibleAccounts = new List<Account>();
        User testSalesRepWest = [SELECT Id FROM User WHERE UserRole.Name='Sales Representative, West' AND IsActive=true];
        System.runAs(testSalesRepWest){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: Sales Reps must be able to access only their own records');

    }

    @IsTest
    private static void checkVisibilitySalesRepEast(){
        //System Query
        List<Account> expectedAccounts =  [SELECT Id FROM Account WHERE Owner.UserRole.Name='Sales Representative, East' AND Owner.IsActive = true];

        // Query Test SOD Spain
        List<Account> accessibleAccounts = new List<Account>();
        User testSalesRepEast = [SELECT Id FROM User WHERE UserRole.Name='Sales Representative, East' AND IsActive=true];
        System.runAs(testSalesRepEast){
            Test.startTest();
            accessibleAccounts = [SELECT Id FROM Account];
            Test.stopTest();
        }
        Assert.areEqual(expectedAccounts.size(), accessibleAccounts.size(), 'ERROR: Sales Reps must be able to access only their own records');

    }
}