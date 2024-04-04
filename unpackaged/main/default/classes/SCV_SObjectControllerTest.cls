@isTest
public without sharing class SCV_SObjectControllerTest {
    static testMethod void test() {
        User testUser = new User(
            LastName = 'Testing',
            FirstName = 'NeuraFlash',
            alias = 'nf_test',
            Email = 'testing@neuraflash.com',
            Username = 'test1234' + Math.random() + '@gmail.com',
            CommunityNickname = 'happy' + Math.random(),
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = [SELECT Id FROM Profile WHERE Name = :'System Administrator']
            .Id
        );
        insert testUser;
        System.runAs(testUser) {
            Test.startTest();
            Contact a1 = new Contact(
                FirstName = 'Test',
                LastName = 'Contact1',
                Phone = '+2223459876',
                Email = 'test@neuraflash.com'
            );
            insert a1;
            Contact a2 = new Contact(
                FirstName = 'Test2',
                LastName = 'Contact2',
                Phone = '+1112349876',
                Email = 'test1@neuraflash.com'
            );
            insert a2;

            Contact[] accts = [SELECT Id, Name, OwnerId FROM Contact];
            String fieldnames = 'Name,Id,OwnerId,CreatedDate,LastActivityDate';
            String testResponse = SCV_SObjectController.getReturnResults(accts, fieldnames);
            System.assert(testResponse.contains('"noEditFieldList":['));
            System.assert(testResponse.contains('"lookupFieldList":["OwnerId"]'));

            Contact[] empty = [SELECT Id, Name, OwnerId FROM Contact WHERE Name = 'NotInContacts'];
            String testEmpty = SCV_SObjectController.getReturnResults(empty, fieldnames);
            System.assert(testEmpty.contains('"objectName":"EmptyCollection"'));
            Test.stopTest();
        }
    }
}