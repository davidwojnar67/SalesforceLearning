@IsTest
private class BikePipelineTest {

    // =========================================================================
    // 1. MOCK PRO EXTERNÍ HTTP CALLOUT (obdoba Moq / HttpMessageHandler v .NET)
    // =========================================================================
    private class RegistryCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public RegistryCalloutMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            res.setBody(this.responseBody);
            return res;
        }
    }

    // =========================================================================
    // 2. PŘÍPRAVA TEST DATA (běží 1x pro celou třídu, pak se stav vždy resetuje)
    // =========================================================================
    @TestSetup
    static void setupTestData() {
        Contact rider = new Contact(
            FirstName = 'Test',
            LastName = 'Jezdec',
            Email = 'test.jezdec@example.cz'
        );
        insert rider;

        Bike__c bike = new Bike__c(
            Name = 'Specialized Enduro Pro Test',
            Brand__c = 'Specialized',
            Model__c = 'Enduro Pro',
            Service_Status__c = 'Pending',
            Contact__c = rider.Id
        );
        insert bike;
    }

    // =========================================================================
    // 3. TEST VSTUPNÍ BRÁNY (Platform Event Trigger + ochrana proti smyčce)
    // =========================================================================
    @IsTest
    static void testPlatformEventTriggerAndLoopGuard() {
        Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];

        Test.startTest();
        // 1. Standardní událost -> musí zařadit 1. krok pipeline do fronty
        Database.SaveResult srStart = EventBus.publish(new Bike_Service_Event__e(
            Bike_Id__c = bike.Id,
            Event_Type__c = 'FLOW_STATUS_PENDING',
            Payload_Json__c = '{"source":"UnitTest"}'
        ));

        // 2. Notifikační událost pro UI -> handler ji musí přeskočit (continue)
        Database.SaveResult srFinished = EventBus.publish(new Bike_Service_Event__e(
            Bike_Id__c = bike.Id,
            Event_Type__c = 'PIPELINE_FINISHED',
            Payload_Json__c = '{"newStatus":"Fixed"}'
        ));
        Test.stopTest();

        Assert.isTrue(srStart.isSuccess(), 'Publikování startovací události musí uspět.');
        Assert.isTrue(srFinished.isSuccess(), 'Publikování PIPELINE_FINISHED musí uspět.');

        // Ověříme, že ve frontě vznikl přesně 1 Queueable job (ne 2 – PIPELINE_FINISHED bylo ignorováno)
        List<AsyncApexJob> jobs = [
            SELECT Id, ApexClass.Name, Status
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'BikeValidationStep'
        ];
        Assert.areEqual(1, jobs.size(), 'Měl se spustit pouze jeden Queueable job.');
        Assert.areEqual('BikeValidationStep', jobs[0].ApexClass.Name, 'První krok musí být BikeValidationStep.');
    }

    // =========================================================================
    // 4. TEST KROKU 1: BikeValidationStep (načtení záznamu z DB)
    // =========================================================================
    @IsTest
    static void testValidationStepSuccess() {
        Bike__c bike = [SELECT Id, Name FROM Bike__c LIMIT 1];

        BikePipelineContext ctx = new BikePipelineContext();
        ctx.bikeId = bike.Id;
        ctx.remainingSteps = new List<String>{ 'BikeValidationStep' };

        Test.startTest();
        BikePipelineStep.enqueueNextStep(ctx);
        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BikeValidationStep'
        ];
        Assert.areEqual(1, jobs.size(), 'BikeValidationStep měl doběhnout.');
        Assert.areEqual('Completed', jobs[0].Status, 'Job musí skončit ve stavu Completed.');
        Assert.areEqual(0, jobs[0].NumberOfErrors, 'Job nesmí mít žádné chyby.');
    }

    // =========================================================================
    // 5. TEST KROKU 2: BikeRegistryCalloutStep (HTTP 200 i HTTP 500)
    // =========================================================================
    @IsTest
    static void testRegistryCalloutStepHttp200() {
        Bike__c bike = [SELECT Id, Name FROM Bike__c LIMIT 1];

        BikePipelineContext ctx = new BikePipelineContext();
        ctx.bikeId = bike.Id;
        ctx.bikeRecord = bike;
        ctx.eventType = 'PIPELINE_TEST';
        ctx.remainingSteps = new List<String>{ 'BikeRegistryCalloutStep' };

        // Zaregistrujeme falešný HTTP server vracející status 200 OK
        Test.setMock(HttpCalloutMock.class, new RegistryCalloutMock(200, '{"status":"clean"}'));

        Test.startTest();
        BikePipelineStep.enqueueNextStep(ctx);
        Test.stopTest();

        AsyncApexJob job = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BikeRegistryCalloutStep'
            LIMIT 1
        ];
        Assert.areEqual('Completed', job.Status, 'Callout krok musí při HTTP 200 doběhnout jako Completed.');
        Assert.areEqual(0, job.NumberOfErrors);
    }

    @IsTest
    static void testRegistryCalloutStepHttp500() {
        Bike__c bike = [SELECT Id, Name FROM Bike__c LIMIT 1];

        BikePipelineContext ctx = new BikePipelineContext();
        ctx.bikeId = bike.Id;
        ctx.bikeRecord = bike;
        ctx.remainingSteps = new List<String>{ 'BikeRegistryCalloutStep' };

        // Simulujeme výpadek externího registru (HTTP 500)
        Test.setMock(HttpCalloutMock.class, new RegistryCalloutMock(500, '{"error":"Internal Server Error"}'));

        Test.startTest();
        BikePipelineStep.enqueueNextStep(ctx);
        Test.stopTest();

        // Díky try/catch v BikePipelineStep nesmí job tvrdě havarovat (Failed), ale řízeně se zastaví
        AsyncApexJob job = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'BikeRegistryCalloutStep'
            LIMIT 1
        ];
        Assert.areEqual('Completed', job.Status, 'Chyba HTTP 500 musí být ošetřena bez pádu vlákna.');
    }

    // =========================================================================
    // 6. TEST KROKU 3: BikePersistenceStep (zápis do DB + push události)
    // =========================================================================
    @IsTest
    static void testPersistenceStepUpdatesBikeToFixed() {
        Bike__c bike = [SELECT Id, Name, Service_Status__c FROM Bike__c LIMIT 1];
        Assert.areEqual('Pending', bike.Service_Status__c, 'Výchozí stav v testu musí být Pending.');

        BikePipelineContext ctx = new BikePipelineContext();
        ctx.bikeId = bike.Id;
        ctx.bikeRecord = bike;
        ctx.isRegistryClean = true; // Simulujeme úspěšný výsledek z Kroku 2
        ctx.remainingSteps = new List<String>{ 'BikePersistenceStep' };

        Test.startTest();
        BikePipelineStep.enqueueNextStep(ctx);
        Test.stopTest();

        // Načteme kolo znovu z databáze a ověříme, že Krok 3 uložil stav 'Fixed'
        Bike__c updatedBike = [SELECT Service_Status__c FROM Bike__c WHERE Id = :bike.Id];
        Assert.areEqual('Fixed', updatedBike.Service_Status__c, 'Krok 3 měl přepsat stav kola na Fixed.');
    }
}