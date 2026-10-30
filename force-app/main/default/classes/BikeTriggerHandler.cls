public with sharing class BikeTriggerHandler {
    // Zámky proti rekurzi
    public static Boolean hasRunBeforeUpdate = false;
    public static Boolean hasRunAfterInsert = false;

    public static void handleBeforeInsert(List<Bike__c> newBikes) {
        // Insert rekurzi obvykle nedělá, zámek není nutný
        BikeService.validateBikes(newBikes);
        BikeService.validateRelatedContacts(newBikes);
        BikeService.setDefaultStatus(newBikes);
    }

    public static void handleBeforeUpdate(List<Bike__c> newBikes, Map<Id,Bike__c> oldBikesMap) {
        // ZÁMEK: Zamkne dveře předtím, než zavoláme Servisu
        if (!hasRunBeforeUpdate) {
            hasRunBeforeUpdate = true;

            BikeService.validateBikes(newBikes);
            BikeService.validateRelatedContacts(newBikes);
            BikeService.handleStatusChange(newBikes, oldBikesMap);
        }
    }

    public static void handleAfterInsert(List<Bike__c> newBikes) {
        if (!hasRunAfterInsert) {
            hasRunAfterInsert = true;

            BikeService.registerNewBikes(newBikes);
        }
    }
}

/**
 * Proč insert nedělá rekurzi a nepotřebuje zámek?
Když zakládáš nové kolo, událost insert proběhne jen jednou. 
Jakmile se kolo poprvé zapíše do databáze, dostane své Id. Kdyby na pozadí zafungovalo nějaké Flow 
a to kolo dodatečně upravilo, vyvolá tím už událost update, nikoliv insert (stejný záznam se nedá vytvořit dvakrát).
Zacyklit insert jde jedině tehdy, kdyby tvůj kód zakládal úplně nové kolo
v reakci na založení nového kola, což by byla špatná byznys logika.
 */

/**
Jak fyzicky funguje zabránění rekurze v Handleru?

Trik je v tom, že static proměnná v Salesforce nežije navždy (jako v .NETu), 
ale žije přesně po dobu jednoho kliknutí uživatele na tlačítko Uložit (jedné transakce).

Krok 1: Uživatel upraví kolo a klikne na Uložit.
Krok 2: Spustí se tvůj kód. Proměnná hasRunBeforeUpdate je false. Kód projde IFem.
Krok 3: Kód okamžitě přehodí proměnnou na true (zamkne dveře) a vykoná tvou logiku.
Krok 4: Záznam se uloží. Na pozadí se probudí administrátorské Flow, 
        to upraví pole na kole a řekne databázi "Ulož to znovu".
Krok 5: Databáze v rámci stejné transakce podruhé spustí tvůj Trigger.
Krok 6: Trigger volá Handler. Ten se podívá na hasRunBeforeUpdate. 
        Jelikož proměnná stále žije v paměti z Kroku 3, je nyní true. IF neprojde, logika se přeskočí.
        Zacyklení (rekurze) je zastaveno.
 */