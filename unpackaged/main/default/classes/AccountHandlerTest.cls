@isTest
public class AccountHandlerTest {
    @isTest(seeAllData=false)
    static void updateDriftDomainOnIgnoreTest() {
        Account acc = new Account();
        acc.Name = 'NewAccount';
        acc.Generic_Account__c = true;
        acc.Email_Domain__c = 'www.nongenericdomain.com';

        Test.startTest();
        insert acc;
        acc.Email_Domain__c = 'www.nongenericdomain2.com';
        update acc;
        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Drift_Domain__c FROM Account WHERE Id = :acc.Id]
            .Drift_Domain__c,
            'Field shouldnt be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void updateDriftDomainOnIgnore2Test() {
        Account acc = new Account();
        acc.Name = 'NewAccount';
        acc.Generic_Account__c = false;
        acc.Email_Domain__c = 'ignoregenericdomain@gmail.com';

        Test.startTest();
        insert acc;
        acc.Email_Domain__c = 'ignoregenericdomain2@gmail.com';
        update acc;
        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Drift_Domain__c FROM Account WHERE Id = :acc.Id]
            .Drift_Domain__c,
            'Field shouldnt be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void setClasificationTest() {
        Account acc = new Account(Name = 'Test1');
        acc.Generic_Account__c = true;

        Account acc2 = new Account(Name = 'Test2');
        acc2.Generic_BDR_RR_FLAG__c = true;

        Test.startTest();
        insert new List<Account>{ acc, acc2 };
        Test.stopTest();

        System.assertEquals(
            'Generic',
            [SELECT Account_Classification__c FROM Account WHERE Id = :acc.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
        System.assertEquals(
            'BDR',
            [SELECT Account_Classification__c FROM Account WHERE Id = :acc2.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void updateDriftDomainOnInsertTest() {
        Account acc = new Account();
        acc.Name = 'NewAccount';
        acc.Generic_Account__c = false;
        acc.Email_Domain__c = 'www.nongenericdomain.com';

        Account acc2 = new Account();
        acc2.Name = 'NewAccount';
        acc2.Generic_Account__c = false;
        acc2.Email_Domain__c = 'sub.nongenericdomain.com';
        Test.startTest();
        insert new List<Account>{ acc, acc2 };
        Test.stopTest();

        System.assertEquals(
            'www.nongenericdomain.com',
            [SELECT Drift_Domain__c FROM Account WHERE Id = :acc.Id]
            .Drift_Domain__c,
            'Field should be updated.'
        );
        System.assertEquals(
            'sub.nongenericdomain.com',
            [SELECT Drift_Domain__c FROM Account WHERE Id = :acc2.Id]
            .Drift_Domain__c,
            'Field should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void setClasificationFalseTest() {
        Account acc = new Account(Name = 'Test1');
        acc.Generic_Account__c = false;

        Account acc2 = new Account(Name = 'Test2');
        acc2.Generic_BDR_RR_FLAG__c = false;
        Test.startTest();
        insert new List<Account>{ acc, acc2 };
        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Account_Classification__c FROM Account WHERE Id = :acc.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
        System.assertEquals(
            null,
            [SELECT Account_Classification__c FROM Account WHERE Id = :acc2.Id]
            .Account_Classification__c,
            'Classification should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void updateDriftDomainOnUpdateTest() {
        Account acc = new Account();
        acc.Name = 'NewAccount';
        acc.Generic_Account__c = false;
        acc.Email_Domain__c = 'www.nongenericdomain.com';
        insert acc;

        Test.startTest();
        acc.Email_Domain__c = 'www.nongenericdomain2.com';
        update acc;
        Test.stopTest();

        System.assertEquals(
            'www.nongenericdomain2.com',
            [SELECT Drift_Domain__c FROM Account WHERE Id = :acc.Id]
            .Drift_Domain__c,
            'Field should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void updateDriftDomainOnUpdateEmailTest() {
        Account acc = new Account();
        acc.Name = 'NewAccount';
        acc.Generic_Account__c = false;
        acc.Email_Domain__c = 'client@nongenericdomain.com';
        insert acc;

        Test.startTest();
        acc.Email_Domain__c = 'client@nongenericdomain2.com';
        update acc;
        Test.stopTest();

        System.assertEquals(
            'www.nongenericdomain2.com',
            [SELECT Drift_Domain__c FROM Account WHERE Id = :acc.Id]
            .Drift_Domain__c,
            'Field should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void cleanDomainTest() {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Email_Domain__c = 'xometry.com';

        Account acc2 = new Account();
        acc2.Name = 'Test2';
        acc2.Email_Domain__c = 'xometry2.com';

        Account acc3 = new Account();
        acc3.Name = 'Test';
        acc3.Email_Domain__c = 'xometry3.com';

        Test.startTest();
        insert new List<Account>{ acc, acc2, acc3 };

        acc3.Email_Domain__c = 'xometry.com';
        update acc3;
        Test.stopTest();

        System.assertEquals(
            null,
            [SELECT Email_Domain__c FROM Account WHERE Id = :acc.Id]
            .Email_Domain__c,
            'Domain should be cleaned up.'
        );
        System.assertEquals(
            'xometry2.com',
            [SELECT Email_Domain__c FROM Account WHERE Id = :acc2.Id]
            .Email_Domain__c,
            'Domain should be updated.'
        );
        System.assertEquals(
            null,
            [SELECT Email_Domain__c FROM Account WHERE Id = :acc3.Id]
            .Email_Domain__c,
            'Domain should be cleaned up.'
        );
    }

    @isTest(seeAllData=false)
    static void updateSLASegmentChildInsertTest() {
        Account parentAccount = new Account();
        parentAccount.Name = 'ParentCo';
        parentAccount.BillingState = 'Maine';
        parentAccount.SLA_Entitlement_Levels__c = 'Platinum';
        parentAccount.Hierarchy_Type__c = 'Corporate Parent';
        insert parentAccount;

        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingState = 'Ohio';
        account.ParentId = parentAccount.Id;
        account.SLA_Entitlement_Levels__c = 'Essential';
        account.Hierarchy_Type__c = 'Account Subdivision';

        Test.startTest();

        insert account;

        Test.stopTest();

        System.assertEquals(
            parentAccount.SLA_Entitlement_Levels__c,
            [SELECT SLA_Entitlement_Levels__c FROM Account WHERE Id = :account.Id]
            .SLA_Entitlement_Levels__c,
            'Field should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void updateSLASegmentParentUpdateTest() {
        Account parentAccount = new Account();
        parentAccount.Name = 'ParentCo';
        parentAccount.BillingState = 'Maine';
        parentAccount.SLA_Entitlement_Levels__c = 'Platinum';
        parentAccount.Hierarchy_Type__c = 'Corporate Parent';
        parentAccount.SLAPopulateSameLeveltoChildAcct__c = true;
        insert parentAccount;

        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingState = 'Ohio';
        account.ParentId = parentAccount.Id;
        account.SLA_Entitlement_Levels__c = 'Essential';
        account.Hierarchy_Type__c = 'Account Subdivision';
        insert account;

        Test.startTest();

        parentAccount.SLA_Entitlement_Levels__c = 'Premier';
        update parentAccount;

        Test.stopTest();

        System.assertEquals(
            parentAccount.SLA_Entitlement_Levels__c,
            [SELECT SLA_Entitlement_Levels__c FROM Account WHERE Id = :account.Id]
            .SLA_Entitlement_Levels__c,
            'Field should be updated.'
        );
    }

    @isTest(seeAllData=false)
    static void updateSLASegmentChildUpdateTest() {
        Account parentAccount = new Account();
        parentAccount.Name = 'ParentCo';
        parentAccount.BillingState = 'Maine';
        parentAccount.SLA_Entitlement_Levels__c = 'Platinum';
        parentAccount.Hierarchy_Type__c = 'Corporate Parent';
        parentAccount.SLAPopulateSameLeveltoChildAcct__c = true;
        insert parentAccount;

        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingState = 'Ohio';
        account.SLA_Entitlement_Levels__c = 'Essential';
        insert account;

        Test.startTest();

        account.ParentId = parentAccount.Id;
        account.Hierarchy_Type__c = 'Account Subdivision';
        update account;

        Test.stopTest();

        System.assertEquals(
            parentAccount.SLA_Entitlement_Levels__c,
            [SELECT SLA_Entitlement_Levels__c FROM Account WHERE Id = :account.Id]
            .SLA_Entitlement_Levels__c,
            'Field should be updated.'
        );
    }
}