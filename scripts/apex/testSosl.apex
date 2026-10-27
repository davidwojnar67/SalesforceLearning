// SOSL vyhledávání napříč objekty (vrací List of Lists)

// FIND 'Specialized'
// Tohle je hlavní fulltextový motor. Podporuje i divoké karty, např. FIND 'Special*' (najde Specialized, Special, atd.).
// IN ALL FIELDS
// Tady říkáš, co se má indexovat. Kdybys chtěl šetřit výkon, můžeš hledat jen v názvech (IN NAME FIELDS) nebo e-mailech (IN EMAIL FIELDS).
// RETURNING Bike__c(Name, Status__c), Contact(FirstName, LastName, Email)
// Tohle je to nejdůležitější. Říkáš platformě: "Zajímají mě POUZE kola a kontakty. Všechno ostatní, co to slovo obsahuje (třeba úkoly nebo poznámky), ignoruj."
// Zároveň v závorce definuješ, které konkrétní sloupce chceš u daného objektu načíst (jinak by se načtlo jen holé Id).

List<List<SObject>> searchList = [FIND 'Specialized' IN ALL FIELDS RETURNING Bike__c(Name, Status__c), Contact(FirstName, LastName, Email)];

List<Bike__c> foundBikes = (List<Bike__c>)searchList[0];
List<Contact> foundContacts = (List<Contact>)searchList[1];

System.debug('Nalezena kola: ' + foundBikes.size());
for (Bike__c b : foundBikes) {
    System.debug('Kolo: ' + b.Name);
}

System.debug('Nalezeny kontakty: ' + foundContacts.size());
for (Contact c : foundContacts) {
    System.debug('Kontakt: ' + c.LastName);
}

// Nalezena kola: 0.

// Přitom z našich včerejších logů z fronty víme stoprocentně, 
// že v databázi máš Specialized Demo 11 i Specialized Enduro Pro. Proč je SOSL nenašel?

// Tohle je přesně ta vlastnost SOSL (vyhledávacího enginu), o které jsme mluvili. 
// Zatímco SOQL se ptá přímo živé databáze, SOSL se ptá vyhledávacího indexu (podobně jako když Google indexuje weby).
// Tím, že jsi teprve před chvílí zaškrtl Allow Search, platforma zařadila tvůj objekt do fronty k přeindexování.
// Může to trvat 5 až 15 minut, než se ta existující kola do indexu reálně propíšou. 
// Když si ten skript pustíš za půl hodiny, najednou to to kolo najde. 
// To je daň za to, že je to vyhledávání pak tak extrémně rychlé.

// 2. Proč nenašel Kontakt? (SOSL nedělá SQL Joiny!)
// Tohle je obrovský chyták! Představ si to jako vyhledávací políčko na Google.
// Napsal jsi FIND 'Specialized'. SOSL se podívá na Kontakt a řekne si: "Jmenuje se ten člověk Specialized?
// Má v e-mailu Specialized? Nemá. Tak ho vyřadím."
// SOSL vůbec nezajímá, že ten člověk vlastní kolo značky Specialized.
// Pokud to slovo nemá ten daný objekt přímo fyzicky napsané ve svých vlastních textových polích, SOSL ho nevrátí.


// 1. Kódová finta: "SOSL to SOQL Pattern" (Nejpoužívanější)
// Funguje to jako kombo úder. Necháš ten bleskurychlý SOSL, ať ti najde záznamy (využiješ jeho fulltextovou sílu),
// a vytažená IDčka okamžitě pošleš do SOQL, který ti k nim "dozobne" ty relace (udělá ten JOIN).
List<List<SObject>> searchResult = [FIND 'Specialized' IN ALL FIELDS RETURNING Bike__c(Id)];
List<Bike__c> foundBikeIds = (List<Bike__c>)searchResult[0];

List<Bike__c> fullBikes = [
    SELECT Id, Name, Contact__r.FirstName, Contact__r.Email
    FROM Bike__c
    WHERE Id IN :foundBikeIds
];

for (Bike__c b : fullBikes) {
    System.debug('Našel jsem kolo: ' + b.Name + ', majitel: ' + b.Contact__r.Email);
}
