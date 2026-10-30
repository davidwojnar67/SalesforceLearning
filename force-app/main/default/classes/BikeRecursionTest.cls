public with sharing class BikeRecursionTest {
    // Naše paměť v rámci jedné transakce
    public static Integer pocetSpusteni = 0;
    public static Boolean jeZamceno = false;

    public static void testAfterUpdate() {
        pocetSpusteni++;
        System.debug('⚠️ TRIGGER (After Update) BĚŽÍ! Pokus číslo: ' + pocetSpusteni);

        // ZÁMEK (zatím vypnutý)
        
        if (jeZamceno) {
            System.debug('🛑 REKURZE ZASTAVENA ZÁMKEM! Kód nepokračuje.');
            return; // Ukončí metodu
        }
        jeZamceno = true; // Zamkneme pro případný další oběh
        

        System.debug('✅ TĚŽKÁ LOGIKA PROVEDENA (např. volání externího API).');
    }
}

/**
Bez ZÁMKU

12:38:47.0 (67403373)|USER_DEBUG|[8]|DEBUG|⚠️ TRIGGER (After Update) BĚŽÍ! Pokus číslo: 1
12:38:47.0 (67436326)|USER_DEBUG|[19]|DEBUG|✅ TĚŽKÁ LOGIKA PROVEDENA (např. volání externího API).
12:38:47.111 (113484737)|USER_DEBUG|[8]|DEBUG|⚠️ TRIGGER (After Update) BĚŽÍ! Pokus číslo: 2
12:38:47.111 (113500339)|USER_DEBUG|[19]|DEBUG|✅ TĚŽKÁ LOGIKA PROVEDENA (např. volání externího API). 

Představ si, že by ta tvá "Těžká logika" byl reálný callout na externí účetní API.
Bez zámku bys jim během zlomku vteřiny poslal dvě identické žádosti, čímž bys jim vytvořil duplicitu v systému.


Se ZÁMKEM

12:42:47.134 (193708204)|USER_DEBUG|[8]|DEBUG|⚠️ TRIGGER (After Update) BĚŽÍ! Pokus číslo: 1
12:42:47.134 (193791594)|USER_DEBUG|[19]|DEBUG|✅ TĚŽKÁ LOGIKA PROVEDENA (např. volání externího API).
12:42:47.216 (217533414)|USER_DEBUG|[8]|DEBUG|⚠️ TRIGGER (After Update) BĚŽÍ! Pokus číslo: 2
12:42:47.216 (217569030)|USER_DEBUG|[13]|DEBUG|🛑 REKURZE ZASTAVENA ZÁMKEM! Kód nepokračuje.

*/