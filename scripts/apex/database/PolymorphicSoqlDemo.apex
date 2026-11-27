// // 1. Vytvoření ukázkových dat (1 Contact, 1 Lead a 2 polymorfní úkoly)
// Contact c = new Contact(FirstName = 'Petr', LastName = 'Dvořák', Email = 'petr.dvorak@text.cz');
// Lead l = new Lead(FirstName = 'Lucie', LastName = 'Králová', Company = 'TrailTech s.r.o.');
// insert new List<SObject>{ c, l };

// List<Task> sampleTasks = new List<Task>{
//     new Task(Subject = 'Zavolat ohledně servisu vidlice', WhoId = c.Id),
//     new Task(Subject = 'Nabídnout testovací jízdu', WhoId = l.Id)
// };
// insert sampleTasks;

// 2. Polymorfní SOQL dotaz s klauzulí TYPEOF
List<Task> tasks = [
    SELECT Id, Subject,
        TYPEOF Who
            WHEN Contact THEN FirstName, LastName, Email
            WHEN Lead THEN FirstName, LastName, Company
        END
    FROM Task
    LIMIT 10
];

// 3. Zpracování v Apexu přes instanceof
for (Task t : tasks) {
    if (t.Who instanceof Contact) {
        Contact foundContact = (Contact) t.Who;
        System.debug('Úkol pro Kontakt: ' + foundContact.FirstName + ' ' + foundContact.LastName + ' (' + foundContact.Email + ') ');
        System.debug('Předmět úkolu: ' + t.Subject);
    } else if (t.Who instanceof Lead) {
        Lead foundLead = (Lead) t.who;
        System.debug('Úkol pro Lead: ' + foundLead.FirstName + ' ' + foundLead.LastName + ' (' + foundLead.Company + ') ');
        System.debug('Předmět úkolu: ' + t.Subject);
    }
}