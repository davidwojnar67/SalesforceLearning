/** Selector vrstva – veškeré SOQL
 * Jediné místo v aplikaci, odkud se čte objekt Bike_Service__c.
 * Vynucuje inherited sharing a WITH USER_MODE,
 * vždy pracuje s kolekcemi (Set<Id>) a vrací jednotnou sadu polí.
 */
public inherited sharing class BikeServicesSelector {

    public List<Bike_Service__c> selectById(Set<Id> serviceIds) {
        if (serviceIds == null || serviceIds.isEmpty()) {
            return new List<Bike_Service__c>();
        }
        return [
            SELECT Id, Name, Bike__c, Service_Type__c, Cost__c, Is_Completed__c, Completed_Date__c
            FROM Bike_Service__c
            WHERE Id IN :serviceIds
            WITH USER_MODE
        ];
    }

    public List<Bike_Service__c> selectByBikeId(Set<Id> bikeIds) {
        if (bikeIds == null || bikeIds.isEmpty()) {
            return new List<Bike_Service__c>();
        }
        return [
            SELECT Id, Name, Bike__c, Service_Type__c, Cost__c, Is_Completed__c, Completed_Date__c
            FROM Bike_Service__c
            WHERE Bike__c IN :bikeIds
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }
}