String  targetName = 'ČSOB Test Org';

List<Account> accounts = [
    SELECT Id, Name, AnnualRevenue
    FROM Account
    WHERE Name = :targetName
    LIMIT 1
]; 

if(!accounts.isEmpty()) {
    Account acc = accounts[0];

    acc.AnnualRevenue = 1000000;
     update acc;
 
    Contact newContact = new Contact();
    newContact.FirstName = 'David';
    newContact.LastName = 'Wojnar';
    newContact.Email = 'david@example.com';
    newContact.AccountId = acc.Id;

    insert newContact;

    System.debug('Account updated and new Contact created with ID: ' + newContact.Id);
}
 