public with sharing class GenerateAccountData {

    public static void GenerateAccountData(String country, String custType) {
        
        // CODE STRUCTURE:
        // 1) variables
        // 2) main methods
        // 3) utility methods
        //

        //
        //ACCOUNT NAMES
        //
        List<String> FRENCH_RESTAURATEUR_ACCOUNTS = new List<String>{
            'Groupe Gastronomique Le Gourmet',
            'Restaurant La Belle Table',
            'Cuisine Francaise Dupont',
            'Bistro du Marche',
            'Maison de la Saveur',
            'Brasserie Le Coq Dore',
            'Restaurant Chez Antoine',
            'Les Saveurs de Provence',
            'Le Comptoir Parisien',
            'Cuisine et Terroir Martin',
            'La Table du Chef',
            'Bistro Saint Honore',
            'Restaurant Le Vieux Port',
            'Groupe Restauration Etoile',
            'L Art de la Table Francaise'
        };

        List<String> FRENCH_DISTRIBUTOR_ACCOUNTS = new List<String>{
            'Groupe Distribution Gourmet',
            'Distribution Alimentaire DuMarche',
            'Fournisseur Alimentaire Martin',
            'Grossiste de la Table',
            'Maison de Distribution Francaise',
            'Approvisionnement Restauration Pro',
            'Groupe Logistique Saveurs',
            'Distribution Agroalimentaire Paris',
            'Fournisseur Cuisine et Terroir',
            'Groupe Grossiste Etoile',
            'Distribution Provence Aliments',
            'Fournisseur Professionnel Dupont',
            'Distribution Alimentaire Centrale',
            'Groupe Restauration Supply',
            'Logistique Alimentaire Le Comptoir'
        };

        List<String> SPANISH_RESTAURATEUR_ACCOUNTS = new List<String>{
            'Grupo Gastronomico El Sol',
            'Restaurante La Buena Mesa',
            'Sabores de Espana Restaurante',
            'Casa del Mar Tapas',
            'El Rincon del Chef',
            'Bodega y Cocina San Miguel',
            'La Parrilla Iberica',
            'Comedor Tradicional Don Jose',
            'Restaurantes La Hacienda',
            'Cocina Mediterranea Santa Ana',
            'Meson El Camino',
            'La Cocina de Abuela Carmen',
            'Restaurante El Puerto',
            'Grupo Hosteleria La Plaza',
            'Sabores del Sur Andaluz'
        };

        List<String> SPANISH_DISTRIBUTOR_ACCOUNTS = new List<String>{
            'Distribuciones El Sol',
            'Grupo Distribuidor La Mesa',
            'Abastecimientos del Norte',
            'Distribuciones San Miguel',
            'Logistica y Suministros Iberia',
            'Distribuidor Alimentario La Hacienda',
            'Comercial de Alimentos Europa',
            'Distribuciones Mediterraneas',
            'Suministros Hosteleros El Camino',
            'Grupo Mayorista Don Jose',
            'Distribuciones Costa Mar',
            'Proveedor Alimentario Santa Ana',
            'Comercial Gastronomica Central',
            'Distribuciones La Plaza',
            'Mayorista de Alimentos del Sur'
        };

        
        //
        //USUAL
        //
        List<String> INDUSTRIES = new List<String>{
            
            'Beverage Distribution', 'Casual Dining', 'Catering Services', 'Cloud / Ghost Kitchens', 'Cold Chain & Logistics', 'Fine Dining', 'FMCG Distribution', 'Food & Beverage Services', 'Food Distribution', 'Food Import & Export', 'Hospitality', 'Hospitality Supplies', 'Quick Service Restaurants (QSR)', 'Restaurants', 'Restaurant Supply', 'Wholesale Trade'

        };

        List<String> CUSTOMER_TYPES = new List<String>{'Distributor', 'Restaurateur'};
        List<String> RATINGS = new List<String>{'Hot','Warm','Cold'};

        //
        //ADDRESSES
        //

        List <String> COUNTRIES = new List<String> {'France', 'Spain'};

        // FRENCH ADDRESSES
        List<String> FRENCH_STREETS = new List<String>{
            'Rue de l Eglise',
            'Avenue du 4 Aout',
            'Rue du 11 Novembre 1918',
            'Rue du Moulin',
            'Place de la Mairie',
            'Rue du Stade',
            'Rue des Jardins',
            'Rue des Ecoles',
            'Boulevard Saint Denis',
            'Rue de la Republique',
            'Rue Victor Hugo',
            'Avenue de la Gare',
            'Rue Pasteur',
            'Rue Nationale',
            'Rue du Chateau',
            'Rue Jean Jaures',
            'Rue de la Paix',
            'Avenue Malherbe',
            'Rue du General Leclerc',
            'Rue des Lilas'
        };

        List<String> FRENCH_CITIES = new List<String>{
            'Paris',
            'Marseille',
            'Nice',
            'Lyon',
            'Toulouse',
            'Grenoble',
            'Dijon',
            'Angers',
            'Saint Denis',
            'Amiens',
            'Bordeaux',
            'Nantes',
            'Lille',
            'Reims',
            'Tours',
            'Clermont Ferrand',
            'Rouen',
            'Orleans',
            'Metz',
            'Caen'
        };

        List<String> FRENCH_ZIP_CODES = new List<String>{
            '75020',
            '13001',
            '06100',
            '69009',
            '31200',
            '38100',
            '21000',
            '49100',
            '93200',
            '80080',
            '33000',
            '44000',
            '59000',
            '51100',
            '37000',
            '63000',
            '76000',
            '45000',
            '57000',
            '14000'
        };


        // SPANISH ADDRESSES
        List<String> SPANISH_STREETS = new List<String>{
            'Calle Mayor',
            'Avenida de la Constitucion',
            'Calle del Sol',
            'Calle de la Iglesia',
            'Plaza de Espana',
            'Calle del Mercado',
            'Avenida de Europa',
            'Calle San Miguel',
            'Calle del Mar',
            'Calle de la Estacion',
            'Calle Real',
            'Avenida del Puerto',
            'Calle Nueva',
            'Calle de la Paz',
            'Avenida de America',
            'Calle del Carmen',
            'Plaza Mayor',
            'Calle de Colon',
            'Avenida de Andalucia',
            'Calle de los Olivos'
        };

        List<String> SPANISH_CITIES = new List<String>{
            'Madrid',
            'Barcelona',
            'Valencia',
            'Sevilla',
            'Zaragoza',
            'Malaga',
            'Bilbao',
            'Alicante',
            'Granada',
            'Valladolid',
            'Murcia',
            'Cadiz',
            'Cordoba',
            'Salamanca',
            'Santander',
            'Oviedo',
            'Gijon',
            'Pamplona',
            'Logrono',
            'Huelva'
        };

        List<String> SPANISH_ZIP_CODES = new List<String>{
            '28013',
            '08002',
            '46001',
            '41001',
            '50001',
            '29001',
            '48001',
            '03001',
            '18001',
            '47001',
            '30001',
            '11001',
            '14001',
            '37001',
            '39001',
            '33001',
            '33201',
            '31001',
            '26001',
            '21001'
        };

        
        //
        //METHOD BEGINS
        //
        List<Account> accounts = new List<Account>();
        Integer numberOfIterations;
        if (country.toLowerCase() == 'france' && custType.toLowerCase() == 'distributor' ){
            numberOfIterations = FRENCH_DISTRIBUTOR_ACCOUNTS.size()-1;
        } else if (country.toLowerCase() == 'france' && custType.toLowerCase() == 'restaurateur'){
            numberOfIterations = FRENCH_RESTAURATEUR_ACCOUNTS.size()-1;
        } else if (country.toLowerCase() == 'spain' && custType.toLowerCase() == 'distributor'){
            numberOfIterations = SPANISH_DISTRIBUTOR_ACCOUNTS.size()-1;
        } else {
            numberOfIterations = SPANISH_RESTAURATEUR_ACCOUNTS.size()-1;
        }

        for(Integer currentIteration=0; currentIteration<numberOfIterations;currentIteration++){
            //Queries
            List<User> salesUsers = [ SELECT Id, IsActive FROM User WHERE Id IN ('005dL00001juFrbQAE', '005dL00001juO5GQAU', '005dL00001juMEGQA2', '005dL00001juO5FQAU', '005dL00001juMEFQA2', '005dL00001juEU6QAM', '005dL00001juFraQAE') AND  IsActive=true ];

            //variables to append to list
            String accountName;
            String customerType;
            String industry;
            String ownerId;
            String phone;
            String rating;
            String shippingCity;
            String shippingStreet;
            String shippingCountry;
            String shippingPostalCode;
            
            //List lengths
            Integer frenchDistributorLength = FRENCH_DISTRIBUTOR_ACCOUNTS.size()-1;
            Integer frenchRestaurateurLength = FRENCH_RESTAURATEUR_ACCOUNTS.size()-1;
            Integer spanishDistributorLength = SPANISH_DISTRIBUTOR_ACCOUNTS.size()-1;
            Integer spanishRestaurateurLength = SPANISH_RESTAURATEUR_ACCOUNTS.size()-1;

            Integer shippingCountryLength = COUNTRIES.size()-1;

            Integer frenchCityLength = FRENCH_CITIES.size()-1;
            Integer frenchStreetLength = FRENCH_CITIES.size()-1;
            Integer frenchPostalCodeLength = FRENCH_ZIP_CODES.size()-1;

            Integer spanishCityLength = SPANISH_CITIES.size()-1;
            Integer spanishStreetLength = SPANISH_STREETS.size()-1;
            Integer spanishPostalCodeLength = SPANISH_ZIP_CODES.size()-1;

            Integer customerTypeLength = CUSTOMER_TYPES.size()-1;
            Integer industryLength = INDUSTRIES.size()-1;
            Integer ratingsLength = RATINGS.size()-1;

            Integer salesUsersLength = salesUsers.size()-1;


            //Assignments
            customerType = CUSTOMER_TYPES[GenerateRandomNumberFromRange(customerTypeLength)];
            shippingCountry = country;

            if(customerType.toLowerCase() == 'distributor' && shippingCountry.toLowerCase() == 'france'){
                accountName = FRENCH_DISTRIBUTOR_ACCOUNTS[currentIteration];
            } else if (customerType.toLowerCase() == 'distributor' && shippingCountry.toLowerCase() == 'spain'){
                accountName = SPANISH_DISTRIBUTOR_ACCOUNTS[currentIteration];
            } else if (customerType.toLowerCase() == 'restaurateur' && shippingCountry.toLowerCase() == 'france'){
                accountName = FRENCH_RESTAURATEUR_ACCOUNTS[currentIteration];
            } else if (customerType.toLowerCase() == 'restaurateur' && shippingCountry.toLowerCase() == 'spain'){
                accountName = SPANISH_RESTAURATEUR_ACCOUNTS[currentIteration];
            } else {
                System.debug('ERROR invalid customer type.');
            }

            industry = INDUSTRIES[GenerateRandomNumberFromRange(industryLength)];
            ownerId = salesUsers[GenerateRandomNumberFromRange(salesUsersLength)].Id;
            rating = RATINGS[GenerateRandomNumberFromRange(ratingsLength)];

            if(shippingCountry.toLowerCase() == 'france'){
                phone = '+33 ' + String.valueOf(GenerateRandomPhoneNumber()) +  ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber());
                
                shippingCity = FRENCH_CITIES[GenerateRandomNumberFromRange(frenchCityLength)];
                shippingStreet = FRENCH_STREETS[GenerateRandomNumberFromRange(frenchStreetLength)];
                shippingPostalCode = FRENCH_ZIP_CODES[GenerateRandomNumberFromRange(frenchPostalCodeLength)];
            } else {
                phone = '+34 ' + String.valueOf(GenerateRandomPhoneNumber()) +  ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber()) + ' ' + String.valueOf(GenerateRandomPhoneNumber());

                shippingCity = SPANISH_CITIES[GenerateRandomNumberFromRange(spanishCityLength)];
                shippingStreet = SPANISH_STREETS[GenerateRandomNumberFromRange(spanishStreetLength)];
                shippingPostalCode = SPANISH_ZIP_CODES[GenerateRandomNumberFromRange(spanishPostalCodeLength)];
            }

            //
            //DML
            //
            accounts.add(new Account(
                
                Name = accountName,
                Customer_Type__c = customerType,
                Industry2__c = industry,
                OwnerId = ownerId,
                Phone = phone,
                Rating = rating,
                ShippingCity = shippingCity,
                ShippingStreet = shippingStreet,
                ShippingCountry = shippingCountry,
                ShippingPostalCode = shippingPostalCode

            ));

        } insert accounts;
    

    }

    // Customer_Type__c		
    // Industry2__c	
    // Name	
    // OwnerId	
    // Phone	
    // Rating	
    // ShippingCity	
    // ShippingCountry	
    // ShippingCountryCode	
    // ShippingPostalCode	
    // ShippingStreet


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
}