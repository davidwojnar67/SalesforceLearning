public with sharing class BikeRegistryCalloutStep extends BikePipelineStep implements Database.AllowsCallouts {

    protected override void process() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://postman-echo.com/post');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(10000);

        Map<String, Object> payload = new Map<String, Object>{
            'bikeId' => ctx.bikeId,
            'bikeName' => ctx.bikeRecord.Name,
            'eventType' => ctx.eventType,
            'rawPayload' => ctx.rawPayload
        };
        req.setBody(JSON.serialize(payload));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 200) {
            ctx.isRegistryClean = true;
            ctx.registryResponseMessage = 'Ověřeno přes async pipeline (HTTP 200)';
            System.debug('[STEP 2 - CALLOUT] Registr vrátil HTTP 200 pro kolo: ' + ctx.bikeRecord.Name);
        } else {
            ctx.errors.add('Externí registr vrátil chybu HTTP ' + res.getStatusCode());
        }
    }
}