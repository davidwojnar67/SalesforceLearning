public with sharing class BikeService {
    public BikeService() {

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

    public static void validateBikes(List<Bike__c> newBikes){
        for (Bike__c bike : newBikes){
            if (String.isBlank(bike.Brand__c)){
                bike.addError('Kolo musí mít vyplněnou značku! Zastaveno v BikeService.');
            }
        }
    }

    public static void setDefaultStatus(List<Bike__c> newBikes){
        for (Bike__c bike : newBikes){
            if (String.isBlank(bike.Status__c)){
                bike.Status__c = 'New';
            }
        }
    }

    public static void handleStatusChange(List<Bike__c> updatedBikes, Map<Id, Bike__c> oldBikesMap){
        for (Bike__c newBike : updatedBikes) {
            Bike__c oldBike = oldBikesMap.get(newBike.Id);

            if (newBike.In_Service__c && !oldBike.In_Service__c) {
                newBike.Last_Service_Date__c = Date.today();
                System.debug('Kolo ' + newBike.Model__c + ' bylo zaškrtnuto do servisu dne: ' + Date.today());
            }
        }
    }

    public static void validateRelatedContacts(List<bike__c> newBikes) {
        Set<Id> allContactIds = new Set<id>();

        for (Bike__c bike : newBikes) {
            if (bike.Contact__c != null) {
                allContactIds.add(bike.Contact__c);
            }
            if (bike.Rider__c != null) {
                allContactIds.add(bike.Rider__c);
            }
        }

        if (allContactIds.isEmpty()) {
            return;
        }

        Map<Id, Contact> contactMap = new Map<Id, Contact>(
            [Select Id, Name, Email FROM Contact WHERE Id IN :allContactIds]
        );

        for (Bike__c bike : newBikes) {
            if (bike.Contact__c != null && contactMap.containsKey(bike.Contact__c)) {
                if (String.isBlank(contactMap.get(bike.Contact__c).Email)) {
                    bike.Contact__c.addError('Majitel kola nemá vyplněný e-mail!');
                }
            }

            if (bike.Rider__c != null && contactMap.containsKey(bike.Rider__c)) {
                if (String.isBlank(contactMap.get(bike.Rider__c).Email)) {
                    bike.Rider__c.addError('Jezdec na kole nemá vyplněný E-mail!');
                }
            }
        }
    }

    public static void registerNewBikes(List<Bike__c> newBikes) {
        if (!newBikes.isEmpty()) {
            System.enqueueJob(new BikeRegistryQueueable(newBikes));
        }
    }

    public static void checkBikeBeforeService(Bike__c b) {
        if (b.Status__c == 'New') {
            throw new BikeException('Nové kolo ještě nepotřebuje servis. Nedělejte zbytečnou práci!');
        }
    }
}