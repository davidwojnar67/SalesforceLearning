public with sharing class BikeController {
    // Anotace @AuraEnabled dovoluje JavaScriptu zavolat tuto metodu.
    // cacheable=true říká, že data se dají uložit do mezipaměti prohlížeče pro extrémní rychlost.
    @AuraEnabled(cacheable=true)
    public static Bike__c getBikeDetails(Id bikeId) {
        return [
            SELECT Id, Name, Service_Status__c
            FROM Bike__c
            WHERE Id = :bikeId
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static void updateBikeServiceStatus(Id bikeId, String newBikeServiceStatus) {
        Bike__c bikeToUpdate = new Bike__c(
            Id = bikeId,
            Service_Status__c = newBikeServiceStatus
        );

        update bikeToUpdate;
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
}