@isTest
public class westCoastContactFlipTest {
    static final String WEST_COAST_BDR = [
        SELECT UserOrGroupId
        FROM GroupMember
        WHERE GroupID = :AppConstants.WEST_COAST_BDR_GROUP
        LIMIT 1
    ]
    .UserOrGroupId;

    @isTest
    static void westCoastContactFlipTest_assignSingleContactToBDR() {
        //Create Account with Single BDR Contact
        List<Account> account = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);

        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(account[0].ID);

        Test.startTest();
        System.enqueueJob(new westCoastContactFlip(accountIdSet, WEST_COAST_BDR));
        Test.stopTest();

        List<Contact> contacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :account[0].Id];

        System.assertEquals(
            WEST_COAST_BDR,
            String.valueOf(contacts[0].OwnerId),
            'Did not set the contact to West Coast BDR'
        );
    }

    @isTest
    static void westCoastContactFlipTest_keepSingleContactAsAM() {
        // Create Account with Single AM Contact
        List<Account> account = TestDataFactory.createTestAccountNonGenerics(2, 'AM', 1, 'SAM');

        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(account[0].ID);

        Test.startTest();
        System.enqueueJob(new westCoastContactFlip(accountIdSet, WEST_COAST_BDR));
        Test.stopTest();

        List<Contact> contacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :account[0].Id];

        System.assertNotEquals(
            WEST_COAST_BDR,
            String.valueOf(contacts[0].OwnerId),
            'Did not set the contact to West Coast BDR'
        );
    }

    @isTest
    static void westCoastContactFlipTest_assignThreeContactsToBDR() {
        // Create Account with Three BDR contacts
        List<Account> account = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 3);

        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(account[0].ID);

        Test.startTest();
        System.enqueueJob(new westCoastContactFlip(accountIdSet, WEST_COAST_BDR));
        Test.stopTest();

        List<Contact> contacts = [SELECT Id, OwnerId FROM Contact WHERE AccountId = :account[0].Id];

        for (Contact c : contacts) {
            System.assertEquals(WEST_COAST_BDR, String.valueOf(c.OwnerId), 'Did not set the contact to West Coast BDR');
        }
    }

    @isTest
    static void westCoastContactFlipTest_assignOpenOpportunity() {
        Opportunity newOpp = TestDataFactory.createOppWithAccContact(false, 'BDR');

        Contact newContact = [SELECT Id, OwnerId, AccountId FROM Contact LIMIT 1];
        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(newContact.AccountId);

        newOpp.OwnerId = newContact.OwnerId;
        newOpp.Amount = 400;
        newOpp.CloseDate = Date.today() + 5;
        newOpp.Line_of_Business__c = null;

        Test.startTest();
        insert newOpp;

        System.enqueueJob(new westCoastContactFlip(accountIdSet, WEST_COAST_BDR));
        Test.stopTest();

        List<Opportunity> opportunities = [SELECT Id, OwnerId FROM Opportunity WHERE AccountID = :newContact.AccountId];

        System.assertEquals(opportunities[0].OwnerId, WEST_COAST_BDR, 'Not reassigned to west coast BDR');
    }
    @isTest
    static void westCoastContactFlipTest_assignQuoteProject() {
        List<Account> account = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);

        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(account[0].ID);

        Contact newContact = [
            SELECT ID, OwnerId, Account.Email_Domain__c, Email
            FROM Contact
            WHERE AccountId = :account[0].ID
        ];

        Quote_ERP__c myQuote = TestDataFactory.createQuote(
            false,
            newContact.Account.Email_Domain__c,
            'John',
            'Doe',
            newContact.Email
        );
        myQuote.ERP_PartPK__c = 'A1234-A5678';
        myQuote.Quote_Price__c = 50.15;
        myQuote.Xometry_ERP_ID__C = 'AAAAA-00001';
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        myQuote.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote.ERP_Billing_City__c = 'San Diego';
        myQuote.ERP_Billing_Country__c = 'United States';
        myQuote.ERP_Billing_State_or_Province__c = 'California';

        insert myQuote;

        Test.startTest();
        System.enqueueJob(new westCoastContactFlip(accountIdSet, WEST_COAST_BDR));
        Test.stopTest();

        List<Project__c> projects = [SELECT Id, OwnerId FROM Project__c WHERE AccountId__c = :account[0].Id];

        System.assertEquals(projects[0].OwnerId, WEST_COAST_BDR, 'Project owner should be in West Cost BDR group');
    }

    @isTest
    static void westCoastContactFlipTest_assignOrderProject() {
        List<Account> account = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);

        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(account[0].ID);

        Contact newContact = [
            SELECT ID, OwnerId, Account.Email_Domain__c, Account.Name, Email, FirstName, LastName
            FROM Contact
            WHERE AccountId = :account[0].ID
        ];

        Order_ERP__c newOrder = TestDataFactory.createOrderERPFromAccContact(
            false,
            'Q12-3333-4444',
            'AAAAA-00001',
            'A1234-A5678',
            account[0],
            newContact,
            date.newInstance(2019, 8, 15),
            dateTime.newInstance(2019, 8, 15, 10, 0, 30)
        );
        newOrder.ERP_Contact__c = 'AAAAA';
        newOrder.ERP_Contact_Last_Name__c = 'Doe';
        newOrder.ERP_Contact_First_Name__c = 'John';
        newOrder.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        newOrder.ERP_Billing_Address__c = '2 Unit E Northway';
        newOrder.ERP_Billing_City__c = 'San Diego';
        newOrder.ERP_Billing_Country__c = 'United States';
        newOrder.ERP_Billing_State_or_Province__c = 'California';

        insert newOrder;

        Test.startTest();
        System.enqueueJob(new westCoastContactFlip(accountIdSet, WEST_COAST_BDR));
        Test.stopTest();

        List<Project__c> projects = [SELECT Id, OwnerId FROM Project__c WHERE AccountId__c = :account[0].Id];

        System.assertEquals(projects[0].OwnerId, WEST_COAST_BDR, 'Project owner should be in West Cost BDR group');
    }

    @isTest
    static void westCoastContactFlipTest_skipClosedOpportunities() {
        List<Account> account = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);

        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(account[0].ID);

        Contact newContact = [SELECT ID, OwnerId FROM Contact WHERE AccountId = :account[0].ID];
        Opportunity newOpp = new Opportunity();
        newOpp.PRIMARY_CONTACT__C = newContact.Id;
        newOpp.name = 'TestOpp';
        newOpp.stagename = 'Closed Won';
        newOpp.AccountID = account[0].ID;
        newOpp.Amount = 400;
        newOpp.CloseDate = Date.today() + 5;
        newOpp.OwnerId = newContact.OwnerId;

        Test.startTest();
        insert newOpp;

        System.enqueueJob(new westCoastContactFlip(accountIdSet, WEST_COAST_BDR));
        Test.stopTest();

        List<Opportunity> opportunities = [SELECT Id, OwnerId FROM Opportunity WHERE AccountID = :account[0].Id];

        System.assertNotEquals(opportunities[0].OwnerId, WEST_COAST_BDR, 'Not reassigned to west coast BDR');
    }
}