List<AggregateResult> results = [
    SELECT Brand__c, COUNT(Id) pocetKol, SUM(Total_Service_Cost__c) celkovaCena
    FROM Bike__c
    GROUP BY Brand__c
];

for (AggregateResult ar : results) {
    // Získání hodnoty přes Alias a její přetypování
    String znacka = (String) ar.get('Brand__c');
    Integer pocet = (Integer) ar.get('pocetKol');
    Decimal cena = (Decimal) ar.get('celkovaCena');

    // Ochrana proti null hodnotám
    Decimal bezpecnaCena = cena ?? 0;

    System.debug('Značka: ' + znacka + ' Počet: ' + pocet + ' Celková cena: $' + bezpecnaCena);
}