// 1. Označ jen tento blok a spusť: Execute Anonymous Apex with Currently Selected Text
System.debug(JSON.serializePretty([
    SELECT Id, Name, Status__c, Contact__r.FirstName, Contact__r.Email
    FROM Bike__c
]));

// 2. Nebo označ tento blok:
System.debug(JSON.serializePretty([
    SELECT ParentId, Parent.Name, Field, OldValue, NewValue, CreatedDate, CreatedBy.Name
    FROM Bike__History
    ORDER BY CreatedDate DESC
]));