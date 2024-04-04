@isTest
private class LeadConvertToContactBatchJobTest {
    @isTest
    static void LeadConvertToContactBatchJobTest() {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

        Account acc1 = new Account(Name = 'Acc1', Email_Domain__c = null);
        Account acc2 = new Account(Name = 'Acc2', Email_Domain__c = 'xomdomain.com');
        insert new List<Account>{ acc1, acc2 };

        Contact con1 = new Contact(
            FirstName = 'con1',
            LastName = 'Test',
            Email = 'contact1@xomdomain.com',
            AccountId = acc1.Id
        );
        Contact con2 = new Contact(
            FirstName = 'con2',
            LastName = 'Test',
            Email = 'contact2@xomdomain.com',
            AccountId = acc2.Id
        );
        insert new List<Contact>{ con1, con2 };

        Lead leadTest1 = new Lead(
            Lastname = 'leadTest1',
            Company = 'Test',
            Primary_Email__c = 'contact1@xomdomain.com',
            Email_Domain__c = 'xomdomain.com'
        );
        Lead leadTest2 = new Lead(
            Lastname = 'leadTest2',
            Company = 'Test',
            Primary_Email__c = 'contact2@xomdomain.com',
            Email_Domain__c = 'xomdomain2.com'
        );
        insert new List<Lead>{ leadTest1, leadTest2 };

        Test.startTest();
        Database.executeBatch(new LeadConvertToContactBatchJob(''));
        Test.stopTest();

        Map<Id, Lead> leadResult = new Map<Id, Lead>([SELECT Id, IsConverted FROM Lead]);

        System.assertEquals(false, leadResult.get(leadTest1.Id).IsConverted, 'Lead should not be converted');
        System.assertEquals(true, leadResult.get(leadTest2.Id).IsConverted, 'Lead should be converted');
        System.assertEquals(0, [SELECT Id FROM Audit_Trail_Error__c].size(), 'No audit records should be recorded');
    }

    @isTest
    static void LeadConvertToContactBatchJobTest2() {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

        Account acc1 = new Account(Name = 'Acc1', Email_Domain__c = null);
        Account acc2 = new Account(Name = 'Acc2', Email_Domain__c = 'xomdomain.com');
        insert new List<Account>{ acc1, acc2 };

        Lead leadTest1 = new Lead(
            Lastname = 'leadTest1',
            Company = 'Test',
            Primary_Email__c = 'contact1@xomdomain.com',
            Email_Domain__c = 'xomdomain.com',
            HS_Generated_by_Sales__c = 'True'
        );

        insert leadTest1;

        Contact con1 = new Contact(
            FirstName = 'con1',
            LastName = 'Test',
            Email = 'contact1@xomdomain.com',
            AccountId = acc1.Id
        );
        Contact con2 = new Contact(
            FirstName = 'con2',
            LastName = 'Test',
            Email = 'contact2@xomdomain.com',
            AccountId = acc2.Id
        );
        insert new List<Contact>{ con1, con2 };

        Lead leadTest2 = new Lead(
            Lastname = 'leadTest2',
            Company = 'Test',
            Primary_Email__c = 'contact2@xomdomain.com',
            Email_Domain__c = 'xomdomain2.com',
            HS_Generated_by_Sales__c = 'True'
        );

        insert leadTest2;

        Test.startTest();
        Database.executeBatch(new LeadConvertToContactBatchJob(''));
        Test.stopTest();

        Map<Id, Lead> leadResult = new Map<Id, Lead>([SELECT Id, IsConverted FROM Lead]);

        System.assertEquals(false, leadResult.get(leadTest1.Id).IsConverted, 'Lead should not be converted');
        System.assertEquals(true, leadResult.get(leadTest2.Id).IsConverted, 'Lead should be converted');
        System.assertEquals(0, [SELECT Id FROM Audit_Trail_Error__c].size(), 'No audit records should be recorded');

        Map<Id, Contact> contactResult = new Map<Id, Contact>([SELECT Id, Generated_by_Sales__c FROM Contact]);

        System.assertEquals('TRUE', contactResult.get(con1.Id).Generated_by_Sales__c);
        System.assertNotEquals('TRUE', contactResult.get(con2.Id).Generated_by_Sales__c);
    }

    @isTest
    static void LeadConvertToContactBatchJobTest_ownerGroup() {
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        Group lstG = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'MarketplaceLeadQueueGeneral' Limit 1];
        List<User> testUsers = [SELECT Id FROM User WHERE isActive = false];        

        Account acc1 = new Account(Name = 'Acc1', Email_Domain__c = null);
        Account acc2 = new Account(Name = 'Acc2', Email_Domain__c = 'xomdomain.com');
        insert new List<Account>{ acc1, acc2 };

        Contact con1 = new Contact(
            FirstName = 'con1',
            LastName = 'Test',
            Email = 'contact1@xomdomain.com',
            AccountId = acc1.Id
        );
        Contact con2 = new Contact(
            FirstName = 'con2',
            LastName = 'Test',
            Email = 'contact2@xomdomain.com',
            Generated_by_Sales__c = 'FALSE',
            AccountId = acc2.Id,
            ownerId = testUsers[0].id
        );
        insert new List<Contact>{ con1, con2 };

        Lead leadTest1 = new Lead(
            Lastname = 'leadTest1',
            Company = 'Test',
            Primary_Email__c = 'contact1@xomdomain.com',
            Email_Domain__c = 'xomdomain.com',
            HS_Generated_by_Sales__c  = 'TRUE',
            OwnerId = lstG.Id
        );
        Lead leadTest2 = new Lead(
            Lastname = 'leadTest2',
            Company = 'Test',
            Primary_Email__c = 'contact2@xomdomain.com',
            Email_Domain__c = 'xomdomain2.com',
            OwnerId = lstG.Id
        );
        insert new List<Lead>{ leadTest1, leadTest2 };

        Test.startTest();
        Database.executeBatch(new LeadConvertToContactBatchJob('Id != null'));
        Test.stopTest();

        Map<Id, Lead> leadResult = new Map<Id, Lead>([SELECT Id, IsConverted, OwnerId FROM Lead]);

        System.assertEquals(false, leadResult.get(leadTest1.Id).IsConverted, 'Lead should not be converted');
        System.assertEquals(true, leadResult.get(leadTest2.Id).IsConverted, 'Lead should be converted');
        System.assertEquals(0, [SELECT Id FROM Audit_Trail_Error__c].size(), 'No audit records should be recorded');
    }

    @isTest
    public static void LeadConvertToContactBatchJobSchedulerTest() {
        String CRON_EXP = '0 0 23 * * ? *';
        Test.startTest();
        String jobID = System.schedule(
            'LeadConvertToContactBatchJobSchedulerTest',
            CRON_EXP,
            new LeadConvertToContactBatchJobScheduler()
        );
        Test.stopTest();
        System.assertNotEquals(null, jobID, 'Job id is not null');
    }
}