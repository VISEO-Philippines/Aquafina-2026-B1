public with sharing class GenerateContactData {

    public static void GenerateRandomFrenchData(Integer numberOfIterations){

        List<Account> accounts = [SELECT Id,Name,ShippingCountry FROM Account WHERE ShippingCountry='France'];
        List<User> salesUsers = [ SELECT Id, IsActive FROM User WHERE Id IN ('005dL00001juFrbQAE', '005dL00001juO5GQAU', '005dL00001juMEGQA2', '005dL00001juO5FQAU', '005dL00001juMEFQA2', '005dL00001juEU6QAM', '005dL00001juFraQAE') AND  IsActive=true ];

        //Usual data
        List<String> SALUTATIONS = new List<String>{'Mx.', 'Dr.', 'Prof.'};
        List<String> TITLES = new List<String> {'OWNER', 'LOGISTICS MANAGER', 'STAFF MANAGER', 'TEAM MEMBER', 'SECRETARY'};
        List <String> COUNTRIES = new List<String> {'France', 'Spain'};
        
        //FRENCH ADDRESSES
        List<String> FRENCH_STREETS = new List<String> {'Rue de l Église', 'Avenue du 4 Août', 'Rue du 11-Novembre-1918', 'Rue du Moulin', 'Place de la Mairie', 'Rue du Stade', 'Rue des Jardins', 'Rue des Écoles'};

        //Note: cities and zip codes are same length so use index to map them appropriately
        List<String> FRENCH_CITIES = new List<String>{'Paris','Marseilles', 'Nice','Lyon','Toulouse','Grenoble','Dijon','Angers','Saint-Denis','Amiens'};
        List<String> FRENCH_ZIP_CODES = new List<String> {'75020','13001','06100','69009','31200','38100','21231','49100','93200','80080'};


        List<String> FRENCH_LAST_NAMES = new List<String>{

            'More', 'Bernard', 'Dubois', 'Thomas', 'Robert', 'Richard', 'Petit', 'Durand', 'Leroy', 'Alix','Allaire','Allard','Alleman','Allemand','Alphonse','Altier','Amar','Ambroise','Amedee','Amiot','Amirault','Amy','Amyot','Ancar','Casavant','Casbon','Casimir','Cassin','Castile','Castille','Castonguay','Catherine','Cauchon','Cave','Cave','Caver','Cavin','Cay','Caye','Cayer','Cazes','Cazier','Cedotal','Celeste','Celestin','Cenac','Cerf','Cerise','Cerne' 

        };

        List<String> FRENCH_FIRST_NAMES = new List<String>{
            'Alex', 'Jeremie', 'Jerome', 'Alexandra', 'Beatrice', 'Charlot', 'Charlotte', 'Jean', 'Jeanne', 'Sara', 'Marie', 'Mary', 'Sandra', 'Trixie', 'Trix', 'Timothee', 'Timzee'
        };

        List<String> SPANISH_LAST_NAMES = new List<String>{

            'Garcia', 'Martinez', 'Rodriguez', 'Lopez', 'Hernandez', 'Gonzalez','Perez', 'Sanchez', 'Ramirez', 'Cruz', 'Diaz', 'Morales', 'Alvarez', 'Vazquez','Torres', 'Flores', 'Rivera', 'Gomez', 'Santos', 'Ramos', 'Castillo', 'Ortiz','Martinez','Laguardia','Laguna','Lagunas','Lainez','Lama','Lamora','Lana','Landa','Landaverde','Landeros','Landin','Langa','Lantigua','Lanza','Lanzo','Lara','Laredo','Lares','Larez','Larez','Largo','Larin','Larios','Laris','Lascano','Lasso','Lasso','Lastra','Laura','Laureano','Laurel','Laverde','Lavin','Lazaro','Lazcano','Lazo','Lazos','Leano','Leanos'

        };

        List <Contact> contacts = new List<Contact>();
        String atSign = '@';

        Integer numberToAppendEmail = 1;
        for (Integer i=0; i<numberOfIterations; i++){

            Integer randomNumForAccount = GenerateRandomNumberFromRange(accounts.size()-1);
            String emailEnding = accounts[randomNumForAccount].Name.toLowerCase().replace('é','e').replace(' ','').replace('è','e').replace('.','').replace(',','') + '.fr';

            List<String> usedEmails;

            
            String salutation = SALUTATIONS[GenerateRandomNumberFromRange(SALUTATIONS.size()-1)];
            String lastName = FRENCH_LAST_NAMES[GenerateRandomNumberFromRange(FRENCH_LAST_NAMES.size()-1)];
            String firstName = FRENCH_FIRST_NAMES[GenerateRandomNumberFromRange(FRENCH_FIRST_NAMES.size()-1)];
            
            Integer rawPhoneInteger = GenerateRandomPhoneNumber();
            String phone = '+33 ' + String.valueOf(GenerateRandomPhoneNumber()) +  ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber());

            String email = firstName + '.' + lastName + atSign + emailEnding;


            String title = TITLES[GenerateRandomNumberFromRange(TITLES.size()-1)].toLowerCase();
            String country = COUNTRIES[0]; //France
            
            String street = FRENCH_STREETS[GenerateRandomNumberFromRange(FRENCH_STREETS.size()-1)];
            Integer randomNumForCityAndZip = GenerateRandomNumberFromRange(FRENCH_CITIES.size()-1);
            String city = FRENCH_CITIES[randomNumForCityAndZip];
            String zipcode = FRENCH_ZIP_CODES[randomNumForCityAndZip];

            String ownerId = salesUsers[GenerateRandomNumberFromRange(salesUsers.size()-1)].Id;

            contacts.add(new Contact(
                Salutation = salutation, 
                LastName = lastName,
                FirstName = firstName,
                Phone = phone,
                Email = email,
                Title = title,
                MailingCountry = country,

                MailingStreet = street,
                MailingCity = city,
                MailingPostalCode = zipcode,
                
                AccountId = accounts[randomNumForAccount].Id,
                OwnerId = ownerId

                ));
        }
        insert contacts;
    }

    public static void GenerateRandomSpanishData(Integer numberOfIterations){

        List<Account> accounts = [SELECT Id,Name,ShippingCountry FROM Account WHERE ShippingCountry='Spain'];
        List<User> salesUsers = [ SELECT Id, IsActive FROM User WHERE Id IN ('005dL00001juFrbQAE', '005dL00001juO5GQAU', '005dL00001juMEGQA2', '005dL00001juO5FQAU', '005dL00001juMEFQA2', '005dL00001juEU6QAM', '005dL00001juFraQAE') AND  IsActive=true ];

        //Usual data
        List<String> SALUTATIONS = new List<String>{'Mx.', 'Dr.', 'Prof.'};
        List<String> TITLES = new List<String> {'OWNER', 'LOGISTICS MANAGER', 'STAFF MANAGER', 'TEAM MEMBER', 'SECRETARY'};
        List <String> COUNTRIES = new List<String> {'France', 'Spain'};
        

        //SPAIN ADDRESSES
        List<String> SPANISH_STREETS = new List<String> {'Calle Mayor', 'Calle Real', 'Calle Iglesia', 'Calle Nueva', 'Avenida del Mar', 'Camino de Santiago', 'Calle Cervantes', 'Avenida de la Libertad', 'Calle San Francisco'};

        //Note: cities and zip codes are same length so use index to map them appropriately
        List<String> SPANISH_CITIES = new List<String>{'Madrid','Barcelona', 'Valencia','Sevilla','Las Palmas','Murcia','Bilbao','Vitoria-Gasteiz'};
        List<String> SPANISH_ZIP_CODES = new List<String> {'75020','13001','06100','69009','31200','38100','21231','49100','93200','80080'};


        List<String> SPANISH_FIRST_NAMES = new List<String>{
            'Jose', 'Andres', 'Juan', 'Enrique', 'Roberto', 'Luis', 'Luiz', 'Alex', 'Alessia', 'Jakob', 'Marie', 'Mary', 'Maria', 'Zanisha', 'Hasni', 'Timothee', 'Sharmee','Lomi','Laura','Adrienne','Adri','Julian','Loreen','Julia','Louella','Lella'
        };

        List<String> SPANISH_LAST_NAMES = new List<String>{

            'Garcia', 'Martinez', 'Rodriguez', 'Lopez', 'Hernandez', 'Gonzalez','Perez', 'Sanchez', 'Ramirez', 'Cruz', 'Diaz', 'Morales', 'Alvarez', 'Vazquez','Torres', 'Flores', 'Rivera', 'Gomez', 'Santos', 'Ramos', 'Castillo', 'Ortiz','Martinez','Laguardia','Laguna','Lagunas','Lainez','Lama','Lamora','Lana','Landa','Landaverde','Landeros','Landin','Langa','Lantigua','Lanza','Lanzo','Lara','Laredo','Lares','Larez','Larez','Largo','Larin','Larios','Laris','Lascano','Lasso','Lasso','Lastra','Laura','Laureano','Laurel','Laverde','Lavin','Lazaro','Lazcano','Lazo','Lazos','Leano','Leanos'

        };

        List <Contact> contacts = new List<Contact>();
        String atSign = '@';

        Integer numberToAppendEmail = 1;
        for (Integer i=0; i<numberOfIterations; i++){

            Integer randomNumForAccount = GenerateRandomNumberFromRange(accounts.size()-1);
            String emailEnding = accounts[randomNumForAccount].Name.toLowerCase().replace('é','e').replace(' ','').replace('è','e').replace('.','').replace(',','') + '.fr';

            List<String> usedEmails;

            
            String salutation = SALUTATIONS[GenerateRandomNumberFromRange(SALUTATIONS.size()-1)];
            String lastName = SPANISH_LAST_NAMES[GenerateRandomNumberFromRange(SPANISH_LAST_NAMES.size()-1)];
            String firstName = SPANISH_FIRST_NAMES[GenerateRandomNumberFromRange(SPANISH_FIRST_NAMES.size()-1)];
            
            Integer rawPhoneInteger = GenerateRandomPhoneNumber();
            String phone = '+34 ' + String.valueOf(GenerateRandomPhoneNumber()) +  ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber());

            String email = firstName + '.' + lastName + atSign + emailEnding;


            String title = TITLES[GenerateRandomNumberFromRange(TITLES.size()-1)].toLowerCase();
            String country = COUNTRIES[0]; //France
            
            String street = SPANISH_STREETS[GenerateRandomNumberFromRange(SPANISH_STREETS.size()-1)];
            Integer randomNumForCityAndZip = GenerateRandomNumberFromRange(SPANISH_CITIES.size()-1);
            String city = SPANISH_CITIES[randomNumForCityAndZip];
            String zipcode = SPANISH_ZIP_CODES[randomNumForCityAndZip];

            String ownerId = salesUsers[GenerateRandomNumberFromRange(salesUsers.size()-1)].Id;

            contacts.add(new Contact(

                Salutation = salutation, 
                LastName = lastName,
                FirstName = firstName,
                Phone = phone,
                Email = email,
                Title = title,
                MailingCountry = country,

                MailingStreet = street,
                MailingCity = city,
                MailingPostalCode = zipcode,
                
                AccountId = accounts[randomNumForAccount].Id,
                OwnerId = ownerId

                ));
        }
        insert contacts;
    }




    private static Integer GenerateRandomNumberFromRange(Integer max){
        Integer min = 0;
        Integer randomNum = Integer.valueOf(Math.random() * (max - min + 1) + min);
        System.debug('random number is: '+ String.valueOf(randomNum));
        return randomNum;
    }

    private static Integer GenerateRandomPhoneNumber(){ // returns an int between 10 and 99
        Integer min = 10;
        Integer max = 99;
        
        Integer randomNum = Integer.valueOf(Math.random() * (max - min + 1) + min);
        return randomNum; 
    }

    public static void GenerateContactData() {
        
        List<Contact> contacts = [SELECT Id, Email, LastName, Account.Name, AccountId FROM Contact];
    }
}