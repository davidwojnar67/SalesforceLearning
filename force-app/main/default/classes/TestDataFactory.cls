@IsTest
public class TestDataFactory {
    public static User createTestUser(String profileName, Boolean doInsert) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        String uniqueName = 'testuser' + Datetime.now().getTime() + '@agentforce.com';

        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Prague',
            Username = uniqueName
        );

        if (doInsert) {
            insert u;
        }
        return u;
    }

    public static Contact createTestContact(Boolean doInsert) {
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Rider',
            Email = 'test@rider.com'
        );
        if (doInsert) {
            insert c;
        }
        return c;
    }

    public static List<Bike__c> createBikes(Integer count, Id contactId, Boolean doInsert) {
        List<Bike__c> bikes = new List<Bike__c>();

        for (Integer i = 0; i < count; i++) {
            bikes.add(new Bike__c(
                Name = 'Test Bike ' + i,
                Brand__c = 'Specialized',
                Status__c = 'New',
                Contact__c = contactId
            ));
        }

        if (doInsert) {
            insert bikes;
        }
        return bikes;
    }
}