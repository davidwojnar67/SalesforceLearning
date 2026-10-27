trigger BikeTrigger on Bike__c (before insert, before update, after insert) {
    if (trigger.isBefore) {
        BikeService.validateBikes(Trigger.new);
        BikeService.validateRelatedContacts(Trigger.new);

        if (Trigger.isInsert) {
            BikeService.setDefaultStatus(Trigger.new);
        }

        if(Trigger.isUpdate) {
            BikeService.handleStatusChange(Trigger.new, Trigger.oldMap);
        }
    }

    if (trigger.isAfter) {
        if (trigger.isInsert) {
            BikeService.registerNewBikes(Trigger.new);
        }
    }
}