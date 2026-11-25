/** Service vrstva – orchestrace a transakce
 * Řídí celý byznysový proces napříč dvěma objekty
 * (Bike_Service__c a rodičovským Bike__c) v jedné atomické transakci:
 * 1. Vytvoření nového servisního úkonu (logNewService).
 * 2. Dokončení servisního úkonu (completeServices), které označí servis jako dokončený
 * a zároveň přepne rodičovské kolo (Bike__c) na stav 'Fixed').
 */
public inherited sharing class BikeServiceLogService {

    public static Id logNewService(Id bikeId, String serviceType, Decimal cost) {
        Bike_Service__c newService = new Bike_Service__c(
            Bike__c = bikeId,
            Service_Type__c = serviceType,
            Cost__c = cost,
            Is_Completed__c = false
        );

        List<Bike_Service__c> servicesToInsert = new List<Bike_Service__c>{ newService };
        BikeServices domain = new BikeServices(servicesToInsert);
        domain.validateBeforeSave();

        insert as user servicesToInsert;
        return newService.Id;
    }

    public static void completeServices(Set<Id> serviceIds) {
        List<Bike_Service__c> services = new BikeServicesSelector().selectById(serviceIds);
        if (services.isEmpty()) {
            throw new BikeException('Servisní záznam nebyl nalezen.');
        }

        // 1. Doménová logika nad servisními záznamy v paměti
        BikeServices domain = new BikeServices(services);
        domain.markAsCompleted();

        // 2. Příprava aktualizace rodičovských kol
        Map<Id, Bike__c> bikesToUpdate = new Map<Id, Bike__c>();
        for (Bike_Service__c service : services) {
            if (service.Bike__c != null) {
                bikesToUpdate.put(
                    service.Bike__c,
                    new Bike__c(Id = service.Bike__c, Service_Status__c = 'Fixed') // v Apexu nemusíš kolo předem načítat přes SOQL, pokud jen přepisuješ konkrétní pole podle známého Id
                );
            }
        }

        // 3. Atomický zápis obou objektů v jedné transakci
        SavePoint sp = Database.setSavepoint();
        try {
            update as user services;
            if (!bikesToUpdate.isEmpty()) {
                update as user bikesToUpdate.values(); // DML příkaz update neumí uložit Map přímo — umí uložit jen jednotlivý SObject nebo List<SObject>. Metoda .values() vytáhne z mapy čistý List<Bike__c> všech hodnot a uloží je najednou v jednom DML příkazu
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw new BikeException('Nepodařilo se dokončit servis: ' + e.getMessage());
        }
    }

    public static void deleteServices(Set<Id> serviceIds) {
        List<Bike_Service__c> services = new BikeServicesSelector().selectById(serviceIds);
        if (services.isEmpty()) {
            throw new BikeException('Servisní záznam nebyl nalezen.');
        }

        delete as user services;
    }

    public static void updateServices(List<Bike_Service__c> servicesToUpdate) {
        if (servicesToUpdate == null || servicesToUpdate.isEmpty()) {
            return;
        }

        BikeServices domain = new BikeServices(servicesToUpdate);
        domain.validateBeforeSave();

        update as user servicesToUpdate;
    }
}