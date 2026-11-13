public class BikeServiceReminderBatch implements Database.Batchable<sObject> {
    // 1. START: Spustí se jen jednou na začátku. 
    // Připraví Query (až pro 50 milionů záznamů!), ale nenačte je do paměti.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Hledáme kola, která nebyla v servisu déle než 1 rok (365 dní) a zároveň právě teď v servisu nejsou.
        // Zahrneme kola starší 1 roku a kola bez servisu, která jsou u nás déle než rok
        return Database.getQueryLocator([
            SELECT Id, Status__c, Last_Service_Date__c
            FROM Bike__c
            WHERE In_Service__c = false
            AND (
                Last_Service_Date__c < LAST_N_DAYS:365
                OR (Last_Service_Date__c = null AND CreatedDate < LAST_N_DAYS:365)
            )
        ]);
    }

    // 2. EXECUTE: Spouští se opakovaně. Salesforce ti sem automaticky 
    // posílá záznamy po dávkách (tzv. chunks, výchozí velikost je 200).
    public void execute(Database.BatchableContext bc, List<Bike__c> scope) {
        // Tady děláme byznys logiku jen pro aktuálních 200 kol
        for (Bike__c bike : scope) {
            bike.Status__c = 'Used';
            // Mohli bychom tu plnit i nějaké pole "Requires_Service__c" apod.
        }

        // Uložíme celou dávku naráz (DML operace se počítá jen jednou na dávku)
        update scope;

        // Pozor na update scope; vs Database.update(scope, false);:
        // V téhle dávce děláš klasické update scope;. Pokud by z 200 kol v jedné dávce mělo 199 kol data v pořádku,
        // ale u 1 kola by selhal nějaký validační rule nebo trigger (např. nevalidní stav),
        // update scope; hodí DmlException a zhodí celou dávku 200 záznamů (rollback).
    }

    // 3. FINISH: Spustí se jen jednou na úplný závěr, když jsou všechny dávky hotové.
    public void finish(Database.BatchableContext bc) {
        // Tady se obvykle posílá e-mail administrátorovi, že dávka doběhla,
        // nebo se zřetězí další Batch job.
        System.Debug('Batch BikeServiceReminderBatch úspěšně dokončen.');
    }
}