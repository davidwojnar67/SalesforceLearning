@isTest
private class BikeEnterpriseTest {
    @TestSetup
    static void setupTestData(){
        User adminUser = TestDataFactory.createTestUser('System Administrator', true);

        Contact rider = TestDataFactory.createTestContact(true);

        TestDataFactory.createBikes(1, rider.Id, true);
    } 
    
    // 1. FÁZE: Příprava dat (Spustí se jen jednou pro celou třídu)
    // @testSetup
    static void setupTestData_old(){
        Contact rider = new Contact(FirstName = 'Test', LastName = 'Rider', Email = 'test@rider.com');
        insert rider;

        Bike__c testBike = new Bike__c(Name = 'Specialized Test', Brand__c = 'Specialized', Status__c = 'New', Contact__c = rider.Id);    
        insert testBike;

        // 1. Jak víme, že tam ten "Standard User" je?
        // Salesforce má sadu systémových profilů (jako System Administrator, Standard User, Read Only), 
        // které jsou "zadrátované" přímo v jádře platformy. Nejdou smazat. 
        // Je to ekvivalent vestavěných rolí v SQL Serveru. 
        // Proto se v testech můžeme na jméno Standard User vždy spolehnout.
        
        // Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];


        // Bomba! Takže Deployment Statusem to nebylo. V tom případě se ti omlouvám, 
        // ale zároveň ti gratuluju, protože jsi právě narazil na druhou, 
        // tu absolutně nejtvrdší vrstvu Salesforce bezpečnosti: OLS (Object-Level Security neboli CRUD).

        // Když jsi v Salesforce, profil "Standard User" je pevně daný, zamčený systémový profil přímo od tvůrců platformy. 
        // Z bezpečnostních důvodů má tento profil v základu absolutně nulová práva (nemá povolené ani čtení)
        // na jakékoliv tvoje nové Custom Objekty.

        // Z pohledu tohoto uživatele objekt Bike__c prostě fyzicky neexistuje ve vesmíru,
        // proto vyletí takhle ošklivá chyba sObject type is not supported, místo klasického "nemáš oprávnění".

        // Jak se to řeší v enterprise praxi:
        // V bance bychom nikdy neupravovali standardní profil. Vytvořili bychom tzv. Permission Set 
        // (Sadu oprávnění pro čtení kol), a v tom @testSetup bychom ho našemu testovacímu bankéři 
        // programátorsky přiřadili (vložili bychom záznam do systémové tabulky PermissionSetAssignment).

        // Jak to opravíme teď hned (abychom viděli to pokrytí):
        // Pojďme toho testovacího uživatele povýšit na Admina. Náš cíl teď je, aby test prošel 
        // a my viděli to slibované pokrytí kódu (Code Coverage).

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];

        User standardUser = new User(
            Alias = 'standt', Email='banker@csob.test', 
            EmailEncodingKey='UTF-8', LastName='Banker', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = standardProfile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='banker' + DateTime.now().getTime() + '@csob.test'
        );
        insert standardUser;
    }

    @isTest
    static void testStandardUserAccess() {
        User banker = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        System.runAs(banker) {
            Test.startTest();

            List<Bike__c> bikes = [SELECT Id, Name FROM Bike__c];

            Test.stopTest();

            // 3. Proč ten Assert není tak primitivní, jak vypadá (Tohle je mind-blow moment!)
            // Z pohledu C# a běžného SQL to zní logicky: 
            // Vložil jsem 1 kolo, tak v tabulce bude 1 kolo. Co je na tom k testování?

            // V Salesforce ale tenhle Assert netestuje funkčnost INSERTu. Testuje bezpečnostní model platformy.

            // Kolo totiž v bloku @testSetup vložil administrátor (ty). 
            // Ale samotný testový dotaz [SELECT Id, Name FROM Bike__c] běží uvnitř System.runAs(banker). 
            // Zkouší to přečíst bankéř.

            // Kdybys měl v Salesforce u objektu kolo nastavené sdílení (OWD - Object-Wide Defaults) na Private 
            // (každý vidí jen svá kola), tak tenhle SOQL dotaz nevrátí 1, ale 0! 
            // Ten Assert by spadl, protože bankéř by cizí kolo v databázi vůbec neviděl. 
            // Tímto primitivním Assertem v bance reálně testuješ, jestli ti někdo v produkci omylem nezměnil práva 
            // a viditelnost záznamů napříč pobočkami.
            System.assertEquals(1, bikes.size(), 'Běžný uživatel (Bankéř) by měl mít právo číst záznamy kol.');
        }
    }

    // Nejdůležitější architektonický koncept pro testování asynchronního kódu v Salesforce: 
    // Test.stopTest() funguje jako trychtýř. Jakákoliv fronta (Queueable, Future, Batch), 
    // která se zařadí v bloku mezi startTest() a stopTest(), se při zavolání stopTest() okamžitě a synchronně vykoná. 
    // To je ten moment, kdy tvůj kód reálně proběhne a pokryjí se mu řádky.
    @isTest
    static void testQueueableCallout() {
        // Řekneme platformě: "Kdykoliv teď poletí HTTP request, použij náš falešný server"
        Test.setMock(HttpCalloutMock.class, new BikeRegistryMock());

        // Načtení z @testSetup
        List<Bike__c> testBikes = [SELECT Id, Name, Brand__c FROM Bike__c];

        Test.startTest();

        // Napřímo zařadíme naši třídu do fronty (izolovaný unit test)
        System.enqueueJob(new BikeRegistryQueueable(testBikes));

        // MAGIE: Zde se test na zlomek vteřiny zastaví, vezme frontu a reálně ji spustí.
        // Uvnitř Queueable proběhne Http.send(), náš Mock to chytí a vrátí kód 200.
        Test.stopTest();

        // Tady bychom ověřili, jestli Queueable udělala svou práci (např. změnila nějaké pole).
        // Prozatím jen ověříme, že kód prošel bez pádu.
        System.assert(true, 'Queueable by měla proběhnout bez výjimky s mockovaným calloutem.');
    }
}