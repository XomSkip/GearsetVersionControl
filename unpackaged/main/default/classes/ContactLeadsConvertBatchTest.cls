@isTest
public class ContactLeadsConvertBatchTest {
    @isTest(seeAllData=false)
    public static void ContactLeadsConvertBatchTest1() {
        Account testAccount = new Account();
        testAccount.Name = 'NewAccount';
        testAccount.Email_Domain__c = 'mydomain.com';
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test123.com',
            FirstName = 'Test',
            LastName = 'Contact'
        );
        insert testContact;

        Lead l = new Lead(Primary_Email__c = testContact.Primary_Email__c, LastName = 'Test', Company = 'TestCompany');
        insert l;

        System.assertEquals(false, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted, 'Lead Initialized');

        Test.startTest();

        ContactLeadsConvertBatch b = new ContactLeadsConvertBatch('');
        Database.executeBatch(b);

        Test.stopTest();

        System.assertEquals(
            true,
            [SELECT isConverted FROM Lead WHERE Id = :l.Id]
            .isConverted,
            'Lead should be converted'
        );
    }

    @isTest(seeAllData=false)
    public static void ContactLeadsConvertNDaysBatchTest() {
        Account testAccount = new Account();
        testAccount.Name = 'NewAccount';
        testAccount.Email_Domain__c = 'mydomain.com';
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test123.com',
            FirstName = 'Test',
            LastName = 'Contact',
            CreatedDate = System.today().addDays(-8)
        );
        Contact testContact2 = new Contact(
            AccountId = testAccount.Id,
            Primary_Email__c = 'test@test456.com',
            FirstName = 'Test',
            LastName = 'Contact',
            CreatedDate = System.today().addDays(-7)
        );
        insert new List<Contact>{ testContact, testContact2 };

        Lead l = new Lead(Primary_Email__c = testContact.Primary_Email__c, LastName = 'Test', Company = 'TestCompany');
        Lead l2 = new Lead(
            Primary_Email__c = testContact2.Primary_Email__c,
            LastName = 'Test',
            Company = 'TestCompany'
        );
        insert new List<Lead>{ l, l2 };

        System.assertEquals(false, [SELECT isConverted FROM Lead WHERE Id = :l.Id].isConverted, 'Lead Initialized');
        System.assertEquals(false, [SELECT isConverted FROM Lead WHERE Id = :l2.Id].isConverted, 'Lead Initialized');

        Test.startTest();

        ContactLeadsConvertBatch b = new ContactLeadsConvertBatch(' WHERE CreatedDate = LAST_N_DAYS:8 ');
        Database.executeBatch(b);

        Test.stopTest();

        System.assertEquals(
            false,
            [SELECT isConverted FROM Lead WHERE Id = :l.Id]
            .isConverted,
            'Lead shouldnt convert'
        );
        System.assertEquals(
            true,
            [SELECT isConverted FROM Lead WHERE Id = :l2.Id]
            .isConverted,
            'Lead should be converted'
        );
    }

    @isTest(seeAllData=false)
    public static void ContactLeadsConvertSchedulerTest() {
        ContactLeadsConvertScheduler sc = new ContactLeadsConvertScheduler();
        String CRON_EXP = '0 0 23 * * ? *';
        Test.startTest();
        String jobID = System.schedule(
            'ContactLeadsConvertSchedulerTest',
            CRON_EXP,
            new ContactLeadsConvertScheduler()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}