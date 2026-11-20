@IsTest
private class BikeControllerTest {
    @testSetup
    static void setupData() {
        Contact ownerContact = new Contact(
            FirstName = 'Majitel',
            LastName = 'Kola',
            Email = 'majitel@kola.com'
        );
        insert ownerContact;

        Bike__c adminBike = new Bike__c(
            Name = 'Specialized Enduro Pro', 
            Brand__c = 'Specialized', 
            Status__c = 'Used',
            Service_Status__c = 'Pending', 
            Contact__c = ownerContact.Id
        );    
        insert adminBike;
    }

    @IsTest
    static void testMechanicCannotReadOtherUsersBike() {
        // Najdeme kolo založené Adminem
        Bike__c targetBike = [SELECT Id FROM Bike__c LIMIT 1];

        // 2. Vytvoříme v paměti testovacího uživatele (obdoba Karla Mechanika)
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User mechanic = new User(
            Alias = 'kmech',
            Email = 'karel.test@csob-bike.cz',
            EmailEncodingKey = 'UTF-8',
            LastName = 'MechanikTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'cs_CZ',
            ProfileId = stdProfile.Id,
            TimeZoneSidKey = 'Europe/Prague',
            UserName = 'karel.test.' + System.currentTimeMillis() + '@csob-bike.cz'
        );
        insert mechanic;

        // Přiřadíme mu Permission Set Mechanic Access
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Mechanic_Access' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = mechanic.Id, PermissionSetId = ps.Id);

        // 3. Spustíme kód v bezpečnostním kontextu mechanika
        System.runAs(mechanic) {
            Test.startTest();
            Boolean accessDenied = false;

            try {
                // BikeController je 'with sharing' + 'WITH USER_MODE' -> musí selhat!
                BikeController.getBikeDetails(targetBike.Id);
            } catch (Exception e) {
                accessDenied = true;
            }
            Test.stopTest();

            System.assertEquals(true, accessDenied, 'Mechanik nesmí přes with sharing vidět cizí kolo!');
        }
    }
}

// Poznámka k User a PermissionSetAssignment: Tyto objekty patří v Salesforce do tzv. Setup Objects.
// Pokud bys v jednom testu vložil User a hned po něm Bike__c (Non-Setup Object),
// Salesforce vyhodí MIXED_DML_OPERATION – přesně proto jsme Bike__c založili v @testSetup
// nebo zabalili vložení uživatele do samostatného System.runAs(new User(Id = UserInfo.getUserId())).
