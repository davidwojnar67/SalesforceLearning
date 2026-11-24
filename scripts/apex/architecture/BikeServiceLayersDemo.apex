Bike__c bike = [SELECT Id FROM Bike__c LIMIT 1];
Id srvId = BikeServiceLogService.logNewService(bike.Id, 'Fork Service', 1500);
system.debug('Vytvořen servis: ' + srvId);

BikeServiceLogService.completeServices(new Set<Id> { srvId });
System.debug('Servis dokončen, kolo aktualizováno.');