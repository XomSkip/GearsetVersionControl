@isTest
public with sharing class LeadHandler_Test {

    @isTest(seeAllData=false)
    static void setClasificationTest() {
        Lead l = new Lead();
        l.LastName = 'Test';
        l.Company = 'Test';
        l.Generic_FLAG__c = true;
        l.Email = 'client@genericdomain.com';

        Lead l2 = new Lead();
        l2.LastName = 'Test2';
        l2.Company = 'Test';
        l2.Generic_BDR_RR_FLAG__c = true;
        l2.Email = 'client2@genericdomain.com';

        Test.startTest();
        insert new List<Lead>{ l, l2 };
        Test.stopTest();

        System.assertEquals(
            'Generic',
            [SELECT Account_Classification__c FROM Lead WHERE Id = :l.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
        System.assertEquals(
            'BDR',
            [SELECT Account_Classification__c FROM Lead WHERE Id = :l2.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void setClasificationFalseTest() {
        Lead l = new Lead();
        l.LastName = 'Test';
        l.Company = 'Test';
        l.Generic_FLAG__c = false;
        l.Email = 'client@genericdomain.com';

        Lead l2 = new Lead();
        l2.LastName = 'Test2';
        l2.Company = 'Test';
        l2.Generic_BDR_RR_FLAG__c = false;
        l2.Email = 'client2@genericdomain.com';

        Test.startTest();
        insert new List<Lead>{ l, l2 };
        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Account_Classification__c FROM Lead WHERE Id = :l.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
        System.assertEquals(
            null,
            [SELECT Account_Classification__c FROM Lead WHERE Id = :l2.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void cleanDomainTest() {
        Lead l = new Lead();
        l.LastName = 'Test';
        l.Company = 'Test';
        l.Email = 'client@genericdomain.com';
        l.Email_Domain__c = 'xometry.com';

        Lead l2 = new Lead();
        l2.LastName = 'Test2';
        l2.Company = 'Test';
        l2.Email = 'client2@genericdomain.com';
        l2.Email_Domain__c = 'xometry2.com';

        Lead l3 = new Lead();
        l3.LastName = 'Test3';
        l3.Company = 'Test';
        l3.Email = 'client3@genericdomain.com';
        l3.Email_Domain__c = 'xometry3.com';

        Test.startTest();
        insert new List<Lead>{ l, l2, l3 };

        l3.Email_Domain__c = 'xometry.com';
        update l3;

        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Email_Domain__c FROM Lead WHERE Id = :l.Id]
            .Email_Domain__c,
            'Domain should be cleaned up.'
        );
        System.assertEquals(
            'xometry2.com',
            [SELECT Email_Domain__c FROM Lead WHERE Id = :l2.Id]
            .Email_Domain__c,
            'Domain should be updated.'
        );
        System.assertEquals(
            null,
            [SELECT Email_Domain__c FROM Lead WHERE Id = :l3.Id]
            .Email_Domain__c,
            'Domain should be cleaned up.'
        );
    }

    @isTest(seeAllData=false)
    static void outreachTest() {

        Lead l = new Lead();
        l.LastName = 'Test';
        l.Email = 'client@genericdomain.com';
        l.Email_Domain__c = 'genericdomain.com';
        l.LeadSource = 'Outreach';

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead outreachLead = [
            SELECT Email, Email_Domain__c, Company, RR_Flag__c,
            OwnerId, Ultimate_Created_By__c, Ultimate_Created_By_Role__c
            FROM Lead
            LIMIT 1
        ];

        System.assertEquals(
            outreachLead.Email_Domain__c,
            outreachLead.Company,
            'Company should be equal to Email Domain.'
        );
        System.assertEquals(
            false, 
            outreachLead.RR_Flag__c, 
            'RR Flag should be false.'
        );
        System.assertEquals(
            outreachLead.OwnerId,
            outreachLead.Ultimate_Created_By__c,
            'Ultimate Owner should be equal to the Lead Owner.'
        );
        System.assertEquals(
            [SELECT Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId()].Name,
            outreachLead.Ultimate_Created_By_Role__c,
            'Ultimate Owner Role should be equal to the Lead Owner Role Name.'
        );

    }

    @isTest
    public static void RecommendedAccountlooKUP() {

        DNBConnect__D_B_Connect_Company_Profile__c cRecord = new DNBConnect__D_B_Connect_Company_Profile__c();
        cRecord.DNBConnect__PrimName__c = 'Test';
        cRecord.DNBConnect__DUNSNumber__c = '012345678';

        insert cRecord;

        Account a = TestDataFactory.createTestAccountNonGenerics(5, 'AM', 1)[0];
        a.DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        update a;
        Contact c = [SELECT ID FROM Contact][0];

        Lead l = new Lead();
        l.LastName = 'Test';
        l.Company = a.Email_Domain__c;
        l.Email = 'email@' + a.Email_Domain__c;
        l.Email_Domain__c = a.Email_Domain__c;
        l.Recommended_Account__c = a.Name;
        l.HubspotDUNSNumber__c = '012345678';
        l.HubspotUltimateDUNSNumber__c = '123456789';
        l.HubspotParentDUNSNumber__c = '234567890';
        insert l;

        Lead lResult = [
            SELECT Id, AccountMatchMethod__c, Recommended_Account_LKP__C, OwnerId
            FROM Lead
            WHERE Id = :l.Id
        ];

        //Traction update remove the ownerID check
        System.assertEquals(a.Id, lResult.Recommended_Account_LKP__C, 'Should recommend the associated Id account');

        Account objAccount = [
            SELECT ID, GNO_PartnerID__c, Name, Email_Domain__C, OwnerId, Generic_Account__c
            FROM Account
            WHERE Id != :a.Id
            LIMIT 1
        ];

        Test.startTest();
        l.Recommended_Account_LKP__c = objAccount.Id;
        update l;
        Test.stopTest();

        lResult = [
            SELECT Id, Recommended_Account__c, Recommended_Account_LKP__C, OwnerId, Generic_FLAG__c, Email_Domain__c
            FROM Lead
            WHERE Id = :l.Id
        ];

        System.assertEquals(
            objAccount.Id,
            lResult.Recommended_Account_LKP__C,
            'Should recommend the associated Id account'
        );
        System.assertEquals(
            objAccount.Name,
            lResult.Recommended_Account__c,
            'Should recommend the associated Name account'
        );
        System.assertEquals(
            objAccount.Generic_Account__c,
            lResult.Generic_FLAG__c,
            'Should recommend the associated Generic FLAG account'
        );
        System.assertEquals(
            objAccount.Email_Domain__c,
            lResult.Email_Domain__c,
            'Should recommend the associated Email Domain account'
        );

        Account objAccount2 = [
            SELECT ID, GNO_PartnerID__c, Name, Email_Domain__C, OwnerId, Generic_Account__c
            FROM Account
            WHERE Id != :a.Id AND Id != :objAccount.Id
            LIMIT 1
        ];

        lResult.Recommended_Account__c = objAccount2.Name;
        update lResult;

        lResult = [
            SELECT Id, Recommended_Account__c, Recommended_Account_LKP__C, OwnerId, Generic_FLAG__c, Email_Domain__c
            FROM Lead
            WHERE Id = :l.Id
        ];

        System.assertEquals(
            objAccount2.Name,
            lResult.Recommended_Account__c,
            'Should recommend the associated Name account'
        );
        System.assertEquals(
            objAccount.Id,
            lResult.Recommended_Account_LKP__C,
            'Should recommend the associated Id account'
        );
        System.assertEquals(
            objAccount.Generic_Account__c,
            lResult.Generic_FLAG__c,
            'Should recommend the associated Generic FLAG account'
        );
        System.assertEquals(
            objAccount.Email_Domain__c,
            lResult.Email_Domain__c,
            'Should recommend the associated Email Domain account'
        );
        System.assertEquals(objAccount.OwnerId, lResult.OwnerId, 'Lead owner should be account owner');
    }

    @isTest(seeAllData=false)
    public static void fillCompanyRecommended() {
        Lead l = new Lead();
        l.LastName = 'Test';
        l.Company = '[not Provided]';
        l.Email_Domain__c = 'genericdomain.com';
        l.Email = 'client@genericdomain.com';

        Lead l2 = new Lead();
        l2.LastName = 'Test2';
        l2.Company = '';
        l2.Marketing_Recommended_Company__c = 'Company2';
        l2.Email = 'client2@genericdomain.com';

        Lead l3 = new Lead();
        l3.LastName = 'Test3';
        l3.Company = '[Sent from Intercom]';
        l3.Email = 'client3@commercialcompany.com';

        Test.startTest();
        insert new List<Lead>{ l, l2, l3 };
        Test.stopTest();

        Map<Id, Lead> leadResultList = new Map<Id, Lead>([SELECT Company FROM Lead]);

        System.assertEquals(l.Email_Domain__c, leadResultList.get(l.Id).Company, 'Company should be updated.');
        System.assertEquals(
            l2.Marketing_Recommended_Company__c,
            leadResultList.get(l2.Id).Company,
            'Company should be updated.'
        );

        System.assertEquals('commercialcompany.com', leadResultList.get(l3.Id).Company, 'Company should be updated');
    }
}