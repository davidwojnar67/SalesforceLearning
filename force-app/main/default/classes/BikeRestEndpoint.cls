// Na rozdíl od běžného public musí být vystavené API třídy i metody global,
// jinak je firewall Salesforce nepustí ven.
@RestResource(urlMapping='/BikeAPI/*')
global with sharing class BikeRestEndpoint {

    // DTO
    global class BikeUpdateRequest {
        public String bikeId;
        public String newServiceStatus;
    }

    @HttpPost
    global static String handlePost() {
        // Obdoba HttpContext v .NETu
        // RestContext: Globální třída, přes kterou saháš na surový request (hlavičky, tělo, parametry)
        // a nastavuješ response (status kódy, tělo odpovědi).
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Deserializace příchozího JSON payloadu
            BikeUpdateRequest requestBody = (BikeUpdateRequest)JSON.deserialize(
                req.requestBody.toString(),
                BikeUpdateRequest.class
            );

            // Vyhledání a aktualizace záznamu v databázi
            Bike__c bikeToUpdate = [SELECT Id, Name FROM Bike__c WHERE Id = :requestBody.bikeId LIMIT 1];
            bikeToUpdate.Service_Status__c = requestBody.newServiceStatus;
            update bikeToUpdate;

            res.statuscode = 200;
            return 'Kolo ' + bikeToUpdate.Name + ' bylo úspěšně aktualizováno na: ' + requestBody.newServiceStatus;
        } catch (QueryException qe) {
            res.statuscode = 404;
            return 'Chyba: Kolo nebylo nalezeno.';
        } catch (Exception e) {
            res.statuscode = 500;
            return 'Interní chyba serveru: ' + e.getMessage();
        }
    }
}


/**
Raw Response
HTTP/2 200 
date: Fri, 30 Oct 2026 14:07:26 GMT
content-type: application/json;charset=UTF-8
cache-control: no-cache,must-revalidate,max-age=0,no-store,private
x-robots-tag: none
content-encoding: gzip
permissions-policy: unload=*
x-sfdc-trace-flags: 01
x-content-type-options: nosniff
strict-transport-security: max-age=63072000; includeSubDomains
set-cookie: CookieConsentPolicy=0:1; path=/; expires=Sat, 30-Oct-2027 14:07:26 GMT; Max-Age=31536000; secure
set-cookie: LSKey-c$CookieConsentPolicy=0:1; path=/; expires=Sat, 30-Oct-2027 14:07:26 GMT; Max-Age=31536000; secure
set-cookie: BrowserId=PDzp5NRrEfGG2IMSKpaOAA; domain=.salesforce.com; path=/; expires=Sat, 30-Oct-2027 14:07:26 GMT; Max-Age=31536000; secure; SameSite=None
vary: Accept-Encoding
server: sfdcedge
x-sfdc-request-id: c9298d37670c67ef544d96141298ea84
x-request-id: c9298d37670c67ef544d96141298ea84
x-sfdc-edge-cache: none


"Kolo Správné Kolo bylo úspěšně aktualizováno na: Fixed"
*/