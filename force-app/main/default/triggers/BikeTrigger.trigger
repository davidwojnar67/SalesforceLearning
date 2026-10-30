// Třída má v rámci transakce paměť, Trigger má Alzheimera.
trigger BikeTrigger on Bike__c (before insert, before update, after insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        BikeTriggerHandler.handleBeforeInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        BikeTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        BikeTriggerHandler.handleAfterInsert(Trigger.new);
    }

    // if (Trigger.isAfter && Trigger.isUpdate) {
    //     BikeRecursionTest.testAfterUpdate();
    // }
}

/**
    Trigger Handler Pattern.

    Trigger jen ví, že se něco stalo v databázi.
    Handler hlídá, jestli se to nestalo dvakrát po sobě (rekurze), a rozděluje úkoly.
    Service vykonává samotnou záchranu světa (validace, statusy).
 */