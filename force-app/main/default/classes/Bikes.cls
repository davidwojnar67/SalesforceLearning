public inherited sharing class Bikes {
    private List<Bike__c> records;

    public Bikes(List<Bike__c> records) {
        this.records = records;
    }

    public void setDefaultStatus() {
        for (Bike__c bike : this.records) {
            if (String.isBlank(bike.Status__c)) {
                bike.Status__c = 'New';
            }
        }
    }

    public void validateBeforeSave() {
        validateRequiredFields();
        validateRelatedContacts();
    }

    public void handleStatusChange(Map<Id, Bike__c> oldBikesMap) {
        for (Bike__c newBike : this.records) {
            Bike__c oldBike = oldBikesMap.get(newBike.Id);

            if (newBike.In_Service__c && !oldBike.In_Service__c) {
                newBike.Last_Service_Date__c = Date.today();
            }
        }
    }

    public void validateEligibleForService() {
        for (Bike__c bike : this.records) {
            if (bike.Status__c == 'New') {
                throw new BikeException('Nové kolo ještě nepotřebuje servis. Nedělejte zbytečnou práci!');
            }
        }
    }

    private void validateRequiredFields() {
        for (Bike__c bike : this.records) {
            if (String.isBlank(bike.Brand__c)) {
                bike.addError('Kolo musí mít vyplněnou značku!');
            }
        }
    }

    private void validateRelatedContacts() {
        Set<Id> allContactIds = new Set<Id>();

        for (Bike__c bike : this.records) {
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

        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, Name, Email
            FROM Contact
            WHERE Id IN :allContactIds
        ]);

        for (Bike__c bike : this.records) {
            if (bike.Contact__c != null && contactMap.containsKey(bike.Contact__c)) {
                if (String.isBlank(contactMap.get(bike.Contact__c).Email)) {
                    bike.Contact__c.addError('Majitel kola nemá vyplněný e-mail!');
                }
            }

            if (bike.Rider__c != null && contactMap.containsKey(bike.Rider__c)) {
                if (String.isBlank(contactMap.get(bike.Rider__c).Email)) {
                    bike.Rider__c.addError('Jezdec na kole nemá vyplněný e-mail!');
                }
            }
        }
    }
}