/** Domain vrstva – validace a stavové změny
 * Zapouzdřuje pravidla samotného servisního záznamu v paměti (bez DML a bez SOQL):
 * Záporná cena (Cost__c < 0) je neplatná.
 * Dokončení servisu nastaví Is_Completed__c = true
 * a automaticky doplní Completed_Date__c = Date.today(), pokud ještě není vyplněné.
 */
public inherited sharing class BikeServices {
    private List<Bike_Service__c> records;

    public BikeServices(List<Bike_Service__c> records) {
        this.records = records;
    }

    public void validateBeforeSave() {
        for (Bike_Service__c service : this.records) {
            if (service.Cost__c != null && service.Cost__c < 0) {
                throw new BikeException('Cena servisního úkonu nesmí být záporná.');
            }
        }
    }

    public void markAsCompleted() {
        for (Bike_Service__c service : this.records) {
            if (service.Is_Completed__c) {
                throw new BikeException('Servisní úkon ' + service.Name + ' už je označen jako dokončený.');
            }
            service.Is_Completed__c = true;
            if (service.Completed_Date__c == null) {
                service.Completed_Date__c = Date.today();
            }
        }
    }
}