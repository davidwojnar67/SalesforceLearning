@isTest
private class BikeRegistryQueueableTest {
    @isTest
    static void testCallout() {
        Contact testContact = new Contact(
            FirstName = 'Karel',
            LastName = 'Kolář',
            Email = 'karel.kolar@email.cz'
        );
        insert testContact;

        List<Bike__c> bikes = new List<Bike__c>{
            new Bike__c(Name = 'Test Bike', Brand__c = 'Rava', Contact__c = testContact.Id)
        };
        insert bikes;

        // Přesměrování HTTP volání na náš falešný server
        Test.setMock(HttpCalloutMock.class, new PostmanEchoMock());

        // Vymezení asynchronního bloku
        Test.startTest();
        System.enqueueJob(new BikeRegistryQueueable(bikes));
        Test.stopTest();

        // Zde bys pomocí SOQL načetl kolo zpět z DB a ověřil přes System.assertEquals, 
        // zda Queueable např. změnil status na "Registrováno".
    }
}