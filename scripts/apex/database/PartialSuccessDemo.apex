Contact rider = new Contact(FirstName = 'Test', LastName = 'Rider', Email = 'test@rider.com');
insert rider;

List<Bike__c> bikesToInsert = new List<Bike__c>();

bikesToInsert.add(new Bike__c(Name = 'Správné Kolo', Brand__c = 'Kololo', Status__c = 'New', Contact__c = rider.Id));
bikesToInsert.add(new Bike__c(Status__c = 'New'));

Database.SaveResult[] results = Database.insert(bikesToInsert, false);

for (Integer i = 0; i < results.size(); i++) {
    Database.SaveResult sr = results[i];

    if (sr.isSuccess()) {
        System.debug('Úspěšně uloženo kolo ID: ' + sr.getId());
    } else {
        for (Database.Error err : sr.getErrors()) {
            System.debug('Chyba u záznamu na indexu ' + i + ': ' + err.getMessage());
            System.debug('Chyba na polích ' + err.getFields());
        }
    }
}

/*

Bez Contact

09:36:24.34 (63920622)|USER_DEBUG|[15]|DEBUG|Chyba u záznamu na indexu 0: Required fields are missing: [Contact__c]
09:36:24.34 (63998242)|USER_DEBUG|[16]|DEBUG|Chyba na polích (Contact__c)
09:36:24.34 (64237865)|USER_DEBUG|[15]|DEBUG|Chyba u záznamu na indexu 1: Kolo musí mít vyplněnou značku! Zastaveno v BikeService.
09:36:24.34 (64278488)|USER_DEBUG|[16]|DEBUG|Chyba na polích () 


S insert rider

09:40:29.53 (473888828)|USER_DEBUG|[15]|DEBUG|Úspěšně uloženo kolo ID: a00gK00001SK8TqQAL
09:40:29.53 (474429363)|USER_DEBUG|[18]|DEBUG|Chyba u záznamu na indexu 1: Kolo musí mít vyplněnou značku! Zastaveno v BikeService.
09:40:29.53 (474489856)|USER_DEBUG|[19]|DEBUG|Chyba na polích ()

V Salesforce existují dva způsoby, jak přes kód vyhodit validační chybu:

1. Chyba na úrovni záznamu (Tvoje aktuální situace)
Pokud jsi v Apexu napsal kolo.addError('Kolo musí mít vyplněnou značku...');, 
říkáš tím systému, že je z byznysového pohledu nevalidní celý objekt jako celek.

V logu je pak getFields() prázdné ().

V uživatelském rozhraní (UI) se tato chyba zobrazí v červeném vyskakovacím boxu úplně nahoře na stránce.

2. Chyba na úrovni pole (Pokud bys to chtěl cílit přesně)
Kdybys v kódu napsal kolo.Brand__c.addError('Kolo musí mít vyplněnou značku...');, 
navážeš chybu přímo na ten jeden konkrétní chybějící údaj.

V logu by pak getFields() vypsalo (Brand__c).

V UI by tato chyba nevyskakovala nahoře, ale svítila by elegantně jako červený text
 přímo pod políčkem "Brand" ve formuláři, což je pro uživatele často přívětivější.

U té předchozí systémové chyby (chybějící Kontakt) zasáhl přímo databázový engine Salesforce.
Ten sám moc dobře věděl, že mu chybí povinné pole Contact__c, a proto ho do závorky automaticky doplnil.
U tvé vlastní byznys logiky si tu granularitu řídíš ty sám.

*/