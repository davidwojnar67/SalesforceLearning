trigger BikeServiceEventTrigger on Bike_Service_Event__e (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        BikeServiceEventTriggerHandler.handleAfterInsert(Trigger.new);
    }
}