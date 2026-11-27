public inherited sharing class BikeManagementService {
    
    public static void registerNewBikes(List<Bike__c> newBikes) {
        if (newBikes == null || newBikes.isEmpty()) {
            return;
        }

        System.enqueueJob(new BikeRegistryQueueable(newBikes));
    }

    public static void checkBikeBeforeService(Bike__c bike) {
        if (bike == null) {
            return;
        }
        new Bikes(new List<Bike__c>{ bike }).validateEligibleForService();
    }

    public static void checkBikes(){
        List<Bike__c> allBikes = [
            SELECT Brand__c, Model__c, Contact__r.FirstName, Contact__r.LastName 
            FROM Bike__c
        ];

        for(Bike__c bike : allBikes){
            String ownerName = bike.Contact__r.FirstName + ' ' + bike.Contact__r.LastName;
            String bikeInfo = bike.Brand__c + ' ' + bike.Model__c;

            System.debug('Jezdec ' + ownerName + ' vlastní kolo: ' + bikeInfo);
        }
    }
}