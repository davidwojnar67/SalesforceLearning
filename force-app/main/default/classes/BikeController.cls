public with sharing class BikeController {
    // Anotace @AuraEnabled dovoluje JavaScriptu zavolat tuto metodu.
    // cacheable=true říká, že data se dají uložit do mezipaměti prohlížeče pro extrémní rychlost.
    @AuraEnabled(cacheable=true)
    public static Bike__c getBikeDetails(Id bikeId) {
        // 1. Zabezpečený SOQL dotaz:
        // Vynutí najednou: Sharing (řádky) + CRUD (tabulku) + FLS (všechny sloupce v SELECTu i WHERE)
        return [
            SELECT Id, Name, Service_Status__c
            FROM Bike__c
            WHERE Id = :bikeId
            WITH USER_MODE
        ];
    }

    @AuraEnabled
    public static void updateBikeServiceStatus(Id bikeId, String newBikeServiceStatus) {
        Bike__c bikeToUpdate = new Bike__c(
            Id = bikeId,
            Service_Status__c = newBikeServiceStatus
        );

        // 2. Zabezpečené DML (namísto obyčejného 'update bike;'):
        // Pokud uživatel nemá právo Edit na pole Service_Status__c, vyhodí System.NoAccessException
        update as user bikeToUpdate;
    }

    @AuraEnabled
    public static void updateBikeServiceStatus_ExceptionTest(Id bikeId, String newBikeServiceStatus) {
        try {
            // Simulace byznysového pravidla: Pokud chceme kolo "Opravit", provedeme nějaký check
            if (newBikeServiceStatus == 'Fixed') {
                throw new BikeException('Kolo nelze označit jako opravené, chybí výstupní kontrola tlumičů.');
            }

            Bike__c bikeToUpdate = new Bike__c(Id = bikeId, Service_Status__c = newBikeServiceStatus);
            update bikeToUpdate;

        } catch (BikeException e) {
            // Tohle je KLÍČOVÉ: Aby se text naší byznysové chyby dostal až k uživateli do LWC,
            // musíme ji zabalit do AuraHandledException.
            
            // AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            // auraEx.setMessage(e.getMessage()); // Nutný hack, jinak to na frontend hodí generický text "Script-thrown exception"
            // throw auraEx;

            // Prý tam byl kdysi bug, tak se to obcházelo přes getMessage(), dnes stačí takto
            throw new AuraHandledException(e.getMessage());

        } catch (Exception e) {
            // Ostatní systémové chyby (např. spadlá databáze) skryjeme pod generickou hlášku
            throw new AuraHandledException('Neočekávaná chyba systému: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getBikeParts(Id bikeId) {
        // V reálu by tady byl SOQL dotaz: [SELECT Name FROM Servisni_Ukon__c WHERE Bike__c = :bikeId]
        // My si pro ukázku iterace vrátíme fixní seznam
        return new List<String>{
            'Výměna oleje ve vidlici RockShox',
            'Odvzdušnění brzd SRAM Maven',
            'Nová zadní pneu'
        };
    }


    // DTO pro přenos dat do LWC (každá property MUSÍ mít @AuraEnabled!)
    public class RegistryCheckResult {
        @AuraEnabled public Boolean isClean;
        @AuraEnabled public String registryMessage;
        @AuraEnabled public Integer statusCode;
    }
    
    @AuraEnabled
    public static RegistryCheckResult verifyBikeInRegistry(Id bikeId) {
        Bike__c bike = [
            SELECT Id, Name, Service_Status__c
            FROM Bike__c
            WHERE Id = :bikeId
            WITH USER_MODE
            LIMIT 1
        ];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://postman-echo.com/post');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(10000);

        Map<String, Object> payload = new Map<String, Object>{
            'bikeId' => bike.Id,
            'bikeName' => bike.Name,
            'checkedBy' => UserInfo.getUserName()
        };
        req.setBody(JSON.serialize(payload));
        
        // bike.Service_Status__c = 'Pending';
        // update as user bike; // <-- Zápis do DB PŘED HTTP calloutem!

        // Po nasazení a kliknutí na tlačítko okamžitě spadneš na nejslavnější chybu v Salesforce:

        // System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out

        // Proč to jádro Salesforce tvrdě zakazuje?
        // V multi-tenant databázi otevře DML operace (update) databázový zámek (row lock) na daném záznamu. 
        // Kdyby Salesforce dovolil po zamčení řádku zavolat externí HTTP API (které může viset až 120 sekund),
        // ten zámek by blokoval ostatní procesy a vyčerpával databázová spojení.

        Http http = new http();
        HttpResponse res = http.send(req);

        // Čistý transakční pattern po návratu z HTTP calloutu:
        SavePoint sp = Database.setSavepoint();
        try {
            bike.Service_Status__c = 'Pending';
            update as user bike;
            // Tady by následoval další DML zápis, např. vytvoření auditního logu...
        } catch (Exception e) {
            // Pokud selže druhý DML zápis, vrátíme databázi přesně do stavu před try blokem
            Database.rollback(sp);
            throw new AuraHandledException('Transakce byla vrácena zpět: ' + e.getMessage());
        }

        RegistryCheckResult result = new RegistryCheckResult();
        result.statusCode = res.getStatusCode();

        if (res.getStatusCode() == 200) {
            result.isClean = true;
            result.registryMessage = 'Kolo "' + bike.Name + '" není v registru kradených kol (HTTP 200).';
        } else {
            throw new AuraHandledException('Externí registr vrátil chybu: HTTP ' + res.getStatusCode());
        }

        // // Simulace selhání druhého DML a řízený Rollback
        // if (res.getStatusCode() == 200) {
        //     SavePoint sp = Database.setSavepoint();

        //     try {
        //         bike.Service_Status__c = 'Pending';
        //         update as user bike;

        //         Contact invalidAuditContact = new Contact(FirstName = 'TestRollback');
        //         insert invalidAuditContact;

        //         result.isClean = true;
        //         result.registryMessage = 'Kolo "' + bike.Name + '" ověřeno a uloženo.';
        //     } catch (Exception e) {
        //         Database.rollback(sp);

        //         result.isClean = false;
        //         result.registryMessage = 'ROLLBACK PROVEDEN! Změna stavu byla vrácena zpět kvůli chybě: ' + e.getMessage();
        //     }
        // }

        System.debug('--- TELEMETRIE TRANSAKCE ---');
        System.debug('SOQL dotazy: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());
        System.debug('DML operace: ' + Limits.getDmlStatements() + ' / ' + Limits.getLimitDmlStatements());
        System.debug('CPU čas (ms): ' + Limits.getCpuTime() + ' / ' + Limits.getLimitCpuTime());
        System.debug('Heap (bytes): ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());

        return result;
    }
}