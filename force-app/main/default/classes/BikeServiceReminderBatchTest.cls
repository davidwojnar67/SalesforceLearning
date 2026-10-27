@isTest
private class BikeServiceReminderBatchTest {
    
    @testSetup
    static void setupData() {
        Contact rider = new Contact(LastName = 'TestRider', Email = 'test@rider.com');
        insert rider;

        List<Bike__c> bikes = new List<Bike__c>{
            // Staré kolo - splňuje podmínku batche (servis před 400 dny)
            new Bike__c(Brand__c = 'Old', Name = 'Stare Kolo', Contact__c = rider.Id, In_Service__c = false, Status__c = 'New', Last_Service_Date__c = Date.today().addDays(-400)),
            // Nové kolo - nesplňuje podmínku batche
            new Bike__c(Brand__c = 'New', Name = 'Nové Kolo', Contact__c = rider.Id, In_Service__c = false, Status__c = 'New', Last_Service_Date__c = Date.today())
        };
        insert bikes;
    }

    @isTest
    static void testBatchExecutesSuccessfully() {
        Test.startTest();

        Database.executeBatch(new BikeServiceReminderBatch(), 200);

        Test.stopTest();

        Bike__c stareKolo = [SELECT Status__c FROM Bike__c WHERE Name = 'Stare Kolo'];
        Bike__c noveKolo = [SELECT Status__c FROM Bike__c WHERE Name = 'Nové Kolo'];

        System.assertEquals('Used', stareKolo.Status__c, 'Batch měl změnit stav u starého kola na Used.');
        System.assertEquals('New', noveKolo.Status__c, 'Batch neměl upravovat nově servisované kolo.');
    }
}