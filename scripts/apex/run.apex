Database.executeBatch(new BikeServiceReminderBatch(), 200);


// CRON formát: Sekunda Minuta Hodina Den Měsíc DenVTýdnu
// '0 0 2 * * ?' znamená: 0. sekunda, 0. minuta, 2:00 ráno, každý den v měsíci, každý měsíc, bez ohledu na den v týdnu
String cronExp = '0 0 2 * * ?';
// Naplánování úlohy pod názvem 'Nocni Kontrola Kol'
System.schedule('Noční kontrola kol', cronExp, new BikeServiceReminderScheduler());


List<Bike__c> bikes = [SELECT Id, Name FROM Bike__C LIMIT 2];
Id jobId = System.enqueueJob(new BikeRegistryQueueable(bikes));
// System.debug('Úloha byla úspěšně zařazena do fronty s ID ' + jobId);
// Kontrola logu >SFDX: GetApex Debug Logs
