@IsTest
private class BikeServiceLayersTest {

    @TestSetup
    static void setupData() {
        Contact rider = new Contact(
            FirstName = 'Jakub',
            LastName = 'Malina',
            Email = 'malina@jakub.com'
        );
        insert rider;

        Bike__c testBike = new Bike__c(
            Name = 'Canyon Spectral CF 8',
            Brand__c = 'Canyon',
            Status__c = 'Used',
            Service_Status__c = 'Pending',
            Contact__c = rider.Id
        );
        insert testBike;
    }

    // 1. PURE UNIT TEST (Domain vrstva – čistě v paměti, 0 DML, 0 SOQL)
    @IsTest
    static void testDomainValidateNegativeCostThrowsException() {
        Bike_Service__c invalidService = new Bike_Service__c(
            Service_Type__c = 'Fork Service',
            Cost__c = -250
        );

        BikeServices domain = new BikeServices(New List<Bike_Service__c>{ invalidService });

        Test.startTest();
        try {
            domain.validateBeforeSave();
            Assert.fail('Očekávala se výjimka BikeException při záporné ceně.');
        } catch (BikeException e) {
            Assert.isTrue(
                e.getMessage().contains('nesmí být záporná'),
                'Neočekávaný text výjimky: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // 2. PURE UNIT TEST (Domain vrstva – dokončení nastaví příznak a dnešní datum)
    @IsTest
    static void testDomainMarkAsCompletedSetsFlagAndDate() {
        Bike_Service__c service = new Bike_Service__c(
            Service_Type__c = 'Brake Bleed',
            Cost__c = 950,
            Is_Completed__c = false
        );

        BikeServices domain = new BikeServices(New List<Bike_Service__c>{ service });

        Test.startTest();
        domain.markAsCompleted();
        Test.stopTest();

        Assert.isTrue(service.Is_Completed__c, 'Úkon měl být označen jako dokončený.');
        Assert.areEqual(Date.today(), service.Completed_Date__c, 'Mělo se doplnit dnešní datum.');
    }

    // 3. INTEGRATION TEST (Service vrstva – založení + dokončení + update rodičovského kola)
    @IsTest
    static void testServiceLogAndCompleteUpdatesParentBike() {
        Bike__c bike = [SELECT Id, Service_Status__c FROM Bike__c LIMIT 1];

        Test.startTest();
        Id serviceId = BikeServiceLogService.logNewService(bike.Id, 'Full Overhaul', 4800);
        BikeServiceLogService.completeServices(new Set<Id>{ serviceId });
        Test.stopTest();

        Bike_Service__c savedService = [
            SELECT Is_Completed__c, Completed_Date__c, Cost__c
            FROM Bike_Service__c
            WHERE ID = :serviceId
        ];
        Bike__c updatedBike = [
            SELECT Service_Status__c
            FROM Bike__c
            WHERE Id = :bike.Id
        ];

        Assert.isTrue(savedService.Is_Completed__c, 'Servis v DB musí být dokončený.');
        Assert.areEqual(Date.today(), savedService.Completed_Date__c, 'Datum dokončení musí být dnes.');
        Assert.areEqual('Fixed', updatedBike.Service_Status__c, 'Stav kola se měl přepnout na Fixed.');
    }

    // 4. INTEGRATION TEST (Service vrstva – inline editace ceny a smazání záznamu)
    @IsTest
    static void testServiceUpdateAndRemoveService() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
        Id serviceId = BikeServiceLogService.logNewService(bike.Id, 'Drivetrain', 1400);

        Test.startTest();
        BikeServiceLogService.updateServices(new List<Bike_Service__c>{
            new Bike_Service__c(Id = serviceId, Cost__c = 1750)
        });

        Bike_Service__c updated = [SELECT Cost__c FROM Bike_Service__c WHERE Id = :serviceId];
        Assert.areEqual(1750, updated.Cost__c, 'Cena se měla aktualizovat na 1750.');

        BikeServiceLogService.deleteServices(new Set<Id>{ serviceId });
        Test.stopTest();

        List<Bike_Service__c> remaining = [SELECT Id FROM Bike_Service__c WHERE Id = :serviceId];
        Assert.isTrue(remaining.isEmpty(), 'Servisní záznam měl být smazán.');
    }
}