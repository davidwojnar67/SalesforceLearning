public class BikeRegistryQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Bike__c> bikesToRegister;
    
    public BikeRegistryQueueable(List<Bike__c> bikes) {
        this.bikesToRegister = bikes;
    }

    public void execute(QueueableContext context) {
        System.debug('Začínám asynchronně odesílat ' + bikesToRegister.size() + ' kol do externího registru...');

        // obdoba HttpClient
        Http http = new Http(); 

        for (Bike__c bike : bikesToRegister) {
            // System.debug('Simuluji HTTP POST do registru pro kolo: ' + bike.Name);

            HttpRequest req = new HttpRequest();
            
            // veřejné testovací API (postman-echo nám vrátí zpět to, co pošleme)
            // req.setEndpoint('https://postman-echo.com/post');

            // Načteme konfiguraci z paměti pomocí Developer Name našeho záznamu (Custom Metadata Types)
            Integration_Setting__mdt config = Integration_Setting__mdt.getInstance('Bike_Registry_API');
            req.setEndpoint(config.Endpoint_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            // Sestavení JSON payloadu
            // Map = nejrychlejší způsob, jak vytvořit JSON strukturu
            Map<String, Object> payload = new Map<String, Object>{
                'bikeId' => bike.Id,
                'bikeName' => bike.Name,
                'source' => 'ČSOB Bike Service'
            };

            // JSON.serialize() funguje podobně jako JsonConvert.SerializeObject() v C#
            req.setBody(JSON.serialize(payload));

            try {
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    // System.debug('✅ Úspěch pro kolo ' + bike.Name + '. Odpověď serveru: ' + res.getBody());

                    String responseBody = res.getBody();

                    // 2. Deserializace (vrací obecný Object, musíme přetypovat na Mapu)
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

                    // 3. Postman-echo vrací naše data ve vnořeném uzlu "json". 
                    // Opět musíme přetypovat, protože get() vrací obecný Object.
                    Map<String,Object> jsonNode = (Map<String, Object>) parsedResponse.get('json');

                    String returnedBikeName = (String) jsonNode.get('bikeName');

                    System.debug('✅ Registrace potvrzena! Server vrátil jméno kola: ' + returnedBikeName);
                } else {
                    System.debug('❌ Chyba API. HTTP Status: ' + res.getStatusCode());
                }                
            } catch (Exception e) {
                System.debug('⚠️ Výjimka při volání API: ' + e.getMessage());
            }
        }

        System.debug('Odesílání do registru dokončeno.');
    }
}