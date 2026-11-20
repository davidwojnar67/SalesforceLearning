public with sharing class BikeServiceEventTriggerHandler {

    public static void handleAfterInsert(List<Bike_Service_Event__e> newEvents) {
        for (Bike_Service_Event__e evt : newEvents) {
            // Notifikace určené čistě pro UI nespouštějí zpracovatelskou pipeline
            if (evt.Event_Type__c == 'PIPELINE_FINISHED') {
                continue;
            }

            BikePipelineContext ctx = new BikePipelineContext(evt);
            ctx.remainingSteps = new List<String>{
                'BikeValidationStep',
                'BikeRegistryCalloutStep',
                'BikePersistenceStep'
            };

            BikePipelineStep.enqueueNextStep(ctx);
        }
    }
}