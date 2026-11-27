@IsTest
private class BikeServiceTest {

    @IsTest
    static void testMissingEmailThrowsError() {
        Contact testContact = new Contact(
            FirstName = 'Lojta',
            LastName = 'Testovací'            
            // schválně bez emailu
        );
        insert testContact;
    
        Bike__c testBike = new Bike__c(
            Name = 'Testovací Kolo',
            Brand__c = 'Spešl',
            Contact__c = testContact.Id
        );

        Boolean exceptionThrown = false;
        try {
            insert testBike;
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('nemá vyplněný e-mail'), 'Neočekávaná chybová hláška: ' + e.getMessage());
        }

        System.assertEquals(true, exceptionThrown, 'Trigger měl vyhodit chybu, ale záznam se normálně uložil!');
    }

    @IsTest
    static void testValidBikeInsertsSuccessfully() {
        Contact testContact = new Contact(
            FirstName = 'Karel',
            LastName = 'Spokojený',
            Email = 'karel.spokojeny@email.cz'
        );
        insert testContact;

        Bike__c testBike = new Bike__c(
            Name = 'Gravel Kolo',
            Brand__c = 'CTM',
            Contact__c = testContact.Id
        );

        Test.startTest();
        insert testBike;
        Test.stopTest();

        System.assertNotEquals(null, testBike.Id, 'Kolo se mělo úspěšně uložit a získat ID!');
    }

    @IsTest
    static void testCheckBikesAndConstructor() {
        Contact testContact = new Contact(
            FirstName = 'Pavel',
            LastName = 'Novák',
            Email = 'pavel.novak@email.cz'
        );
        insert testContact;

        Bike__c testBike = new Bike__c(
            Name = 'Enduro Bike',
            Contact__c = testContact.Id,
            Brand__c = 'Specialized',
            Model__c = 'Status'
        );
        insert testBike;

        Test.startTest();
        BikeManagementService.checkBikes();
        Test.stopTest();

        System.assertNotEquals(null, testBike.Id);
    }

    @IsTest
    static void testHandleStatusChange() {
        Contact testContact = new Contact(
            FirstName = 'Honza',
            LastName = 'Servisák',
            Email = 'honza.servisak@csob.cz'
        );
        insert testContact;

        Bike__c testBike = new Bike__c(
            Name = 'Trail Bike',
            Contact__c = testContact.Id,
            Brand__c = 'Specialized',
            Model__c = 'Stumpjumper',
            In_Service__c = false,
            Status__c = 'Used'
        );
        insert testBike;

        // prý Dirty Memory Instance
        // testBike.In_Service__c = true;

        // realita: GPTa zapomněl na business logiku, kterou jsme si definovali (já taky, pak jsem si vzpomněl)
        // Bike__c bikeToUpdate = new Bike__c(
        //     Id = testBike.Id,
        //     In_service__c = true
        // );

        // 
        // testBike.In_Service__c = true;

        Bike__c bikeToUpdate = new Bike__c(
            Id = testBike.Id,
            In_service__c = true
        );

        Test.startTest();
        update bikeToUpdate;
        Test.stopTest();

        Bike__c updatedBike = [
            SELECT Last_Service_Date__c
            FROM Bike__c
            WHERE Id = :testBike.Id
        ];

        System.assertEquals(Date.today(), updatedBike.Last_Service_Date__c, 'Datum posledního servisu mělo být nastaveno na dnešek!');
    }
}