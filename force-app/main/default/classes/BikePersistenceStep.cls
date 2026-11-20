public without sharing class BikePersistenceStep extends BikePipelineStep {

    protected override void process() {
        ctx.bikeRecord.Service_Status__c = ctx.isRegistryClean ? 'Fixed' : 'Pending';
        update ctx.bikeRecord;

        // Publikujeme událost pro odběratele v prohlížeči (LWC empApi)
        EventBus.publish(new Bike_Service_Event__e(
            Bike_Id__c = ctx.bikeId,
            Event_Type__c = 'PIPELINE_FINISHED',
            Payload_Json__c = '{"newStatus":"' + ctx.bikeRecord.Service_Status__c + '"}'
        ));

        System.debug('[STEP 3 - PERSISTENCE] Kolo ' + ctx.bikeRecord.Name + ' aktualizováno na stav: ' + ctx.bikeRecord.Service_Status__c);
    }
}