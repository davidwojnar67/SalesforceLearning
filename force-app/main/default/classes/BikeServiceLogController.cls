/** tenký vstupní adaptér pro LWC
 * Žádný SOQL, žádné DML, žádná byznys logika — jen převod parametrů a zabalení chyb do AuraHandledException.
 */
public with sharing class BikeServiceLogController {

    @AuraEnabled(cacheable=true)
    public static List<Bike_Service__c> getServicesForBike(Id bikeId) {
        return new BikeServicesSelector().selectByBikeId(new Set<Id>{ bikeId });
    }

    @AuraEnabled
    public static Id createServiceLog(Id bikeId, String serviceType, Decimal cost) {
        try {
            return BikeServiceLogService.logNewService(bikeId, serviceType, cost);
        } catch (BikeException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Chyba při zakládání servisu: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void completeServiceLog(Id serviceId) {
        try {
            BikeServiceLogService.completeServices(new Set<Id>{ serviceId });
        } catch (BikeException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Chyba při dokončování servisu: ' + e.getMessage());
        }
    }
}