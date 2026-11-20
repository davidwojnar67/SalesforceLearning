/*
 * ROLE V ARCHITEKTUŘE: Manuální producent (simulátor)
 * --------------------------------------------------
 * Tento skript je čistě testovací ekvivalent Record-Triggered Flow (Bike Publish Service Event).
 * Oba dělají totéž: publikují událost Bike_Service_Event__e do společné sběrnice (EventBus)
 * a vůbec netuší, co se s ní stane dál.
 *
 * Odběratel (Subscriber) je v systému jen jeden – BikeServiceEventTrigger (Automated Process).
 * Ten zprávu vyzvedne a odpálí 3krokovou Queueable pipeline vždy právě jednou.
 */

Bike__c bike = [SELECT Id, Name, Service_Status__c FROM Bike__c LIMIT 1];
bike.Service_Status__c = 'Pending';
update bike;

Bike_Service_Event__e evt = new Bike_Service_Event__e(
    Bike_Id__c = bike.Id,
    Event_Type__c = 'PIPELINE_TEST',
    Payload_Json__c = '{"triggeredBy":"AnonymousApex"}'
);
EventBus.publish(evt);
System.debug('Odeslána událost pro kolo: ' + bike.Name + ' (' + bike.Id + ')');

/**
 * (Pozor při spouštění tohoto skriptu od chvíle, kdy máš aktivní Record-Triggered Flow: řádek
 * update bike; se stavem 'Pending' ti teď automaticky odpálí událost přes Flow (
 * FLOW_STATUS_PENDING) a řádek EventBus.publish(evt); hned pod ním pošle druhou
 * událost (PIPELINE_TEST). Pro ruční testovací skript ti tedy odteď stačí jen samotné
 * EventBus.publish(evt); bez update bike;.)
 */