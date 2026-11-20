public without sharing class BikeValidationStep extends BikePipelineStep {
    
    protected override void process() {
        List<Bike__c> bikes = [
            SELECT Id, Name, Service_Status__c
            FROM Bike__c
            WHERE Id = :ctx.bikeId
            LIMIT 1
        ];

        if (bikes.isEmpty()) {
            ctx.errors.add('Kolo s ID ' + ctx.bikeId + ' nebylo v databázi nalezeno.');
            return;
        }

        ctx.bikeRecord = bikes[0];
        System.debug('[STEP 1 - VALIDATION] Načteno kolo: ' + ctx.bikeRecord.Name+ ' (stav: ' + ctx.bikeRecord.Service_Status__c + ')');
    }
}