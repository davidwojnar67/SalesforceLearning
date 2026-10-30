Bike__c noveKolo = new Bike__c(Name = 'Leštěnka', Brand__c = 'Specialized', Status__c = 'New');

try {
    BikeService.checkBikeBeforeService(noveKolo);

    System.debug('Kolo prošlo kontrolou a může jít do servisu.');
} catch (BikeException bex) {
    System.debug('Byznys pravidlo porušeno: ' + bex.getMessage());
} catch (Exception ex) {
    System.debug('Fatální systémmová chyba: ' + ex.getMessage());
}