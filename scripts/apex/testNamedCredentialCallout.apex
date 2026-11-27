Bike__c bike = [SELECT Id, Name FROM Bike__c LIMIT 1];

BikePipelineContext ctx = new BikePipelineContext();
ctx.bikeId = bike.Id;
ctx.bikeRecord = bike;
ctx.eventType = 'ANON_APEX_NAMED_CREDENTIAL_TEST';
ctx.remainingSteps = new List<String>{ 'BikeRegistryCalloutStep' };

Id jobId = BikePipelineStep.enqueueNextStep(ctx);
System.debug('Zařezen Queueable job ID: ' + jobId);

// Ověření: V logu najdeš dva klíčové řádky — CALLOUT_REQUEST mířící na Endpoint=callout:BikeRegistry/post
// a tvůj výpis [STEP 2 - CALLOUT] Registr vrátil HTTP 200 pro kolo: ...