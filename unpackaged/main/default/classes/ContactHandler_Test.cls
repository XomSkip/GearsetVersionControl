@IsTest
public with sharing class ContactHandler_Test {
    @IsTest
    public static void ContactHandler_ContactWithSupplierAssociates() {
        Supplier__c s = TestDataFactory.createSupplier(true);

        Supplier__c sQueried = [SELECT Id, AccountID__c FROM Supplier__c WHERE Id = :s.Id];
        Contact c = new Contact();
        c.GNO_PartnerId__c = s.PartnerID__c;
        c.FirstName = 'Cool';
        c.LastName = 'Contact';
        c.Email = 'CoolC.Supplier@gmail.com';
        c.Xometry_ERP_Contact_ID__c = '230AE';

        Test.startTest();
        insert c;
        Test.stopTest();

        Contact cResult = [SELECT Id, AccountId, Supplier__c, OwnerId FROM Contact WHERE Id = :c.Id];
        System.assertEquals(s.Id, cResult.Supplier__c, 'Contact Supplier should be existing supplier');
        System.assertEquals(sQueried.AccountID__c, cResult.AccountId, 'Contact account should match supplier account');
        System.assertEquals(AppConstants.GNO_HOUSE_USER, cResult.OwnerId, 'Owner should be GNO House');
    }

    @IsTest
    public static void ContactHandler_MultipleContactWithSupplierAssociates() {
        Supplier__c s = TestDataFactory.createSupplier(true);

        Supplier__c sQueried = [SELECT Id, AccountID__c FROM Supplier__c WHERE Id = :s.Id];
        List<Contact> cList = new List<Contact>();
        Contact c = new Contact();
        c.GNO_PartnerId__c = s.PartnerID__c;
        c.FirstName = 'Cool';
        c.LastName = 'Contact';
        c.Email = 'CoolC.Supplier@gmail.com';
        c.Xometry_ERP_Contact_ID__c = '230AE';
        cList.add(c);

        Contact c1 = new Contact();
        c1.GNO_PartnerId__c = s.PartnerID__c;
        c1.FirstName = 'Cool';
        c1.LastName = 'Contact';
        c1.Email = 'CoolC1.Supplier@gmail.com';
        c1.Xometry_ERP_Contact_ID__c = '230AE';
        cList.add(c1);

        Test.startTest();
        insert cList;
        Test.stopTest();

        Contact cResult = [SELECT Id, AccountId, Supplier__c FROM Contact WHERE Id = :c.Id];
        Contact c1Result = [SELECT Id, AccountId, Supplier__c FROM Contact WHERE Id = :c1.Id];
        System.assertEquals(s.Id, cResult.Supplier__c, 'Contact Supplier should be existing supplier');
        System.assertEquals(sQueried.AccountID__c, cResult.AccountId, 'Contact account should match supplier account');
        System.assertEquals(s.Id, c1Result.Supplier__c, 'Contact1 Supplier should be existing supplier');
        System.assertEquals(
            sQueried.AccountID__c,
            c1Result.AccountId,
            'Contact1 account should match supplier account'
        );
    }

    @IsTest
    public static void ContactHandler_MultipleContactWithAndWithoutAccounts() {
        List<User> uList = TestDataFactory.createTestUsers();
        List<User> uList1 = TestDataFactory.createTestUserSecond();

        List<Contact> cList = new List<Contact>();
        String custDomain;
        //Contact without accounts
        Contact c = new Contact();
        c.FirstName = 'Cool1';
        c.LastName = 'Contact1';
        c.Primary_Email__c = 'CoolC.Supplier@gmail.com';
        cList.add(c);
        // Contact with lead
        Contact c2 = new Contact();
        c2.FirstName = 'Cool2';
        c2.LastName = 'Contact2';
        c2.Primary_Email__c = 'CoolC1.Supplier@gmail.com';
        cList.add(c2);

        Lead L2 = new Lead();
        L2.Email = 'CoolC1.Supplier@gmail.com';
        L2.LeadSource = 'Drift';
        L2.LastName = 'ABreu';
        L2.Company = 'Xometry';
        L2.OwnerId = uList[0].Id;
        insert L2;
        // Contact with an existing account
        Contact c3 = new Contact();
        c3.FirstName = 'Cool3';
        c3.LastName = 'Contact3';
        c3.Primary_Email__c = 'CoolC2.Supplier@gmail.com';
        cList.add(c3);
        Account acct = new Account();
        acct.Name = 'acct1';
        acct.Email_Domain__c = 'CoolC2.Supplier@gmail.com';
        acct.OwnerId = uList1[0].Id;
        insert acct;

        //Contact Non Generic
        Contact c4 = new Contact();
        c4.FirstName = 'Cool5';
        c4.LastName = 'Contact6';
        c4.Primary_Email__c = 'eat@ingmelec.com';
        cList.add(c4);
        Test.startTest();
        insert cList;
        Test.stopTest();
        custDomain = c4.Primary_Email__c.substring(c4.Primary_Email__c.indexOf('@') + 1);
        Account AResult = [SELECT Email_Domain__c FROM Account WHERE Email_Domain__c = :c.Primary_Email__c];
        Account A1Result = [SELECT Email_Domain__c FROM Account WHERE Email_Domain__c = :custDomain];
        Contact c1Result = [SELECT OwnerId, Primary_Email__c FROM Contact WHERE OwnerId = :L2.OwnerId][0];
        Contact c3Result = [SELECT OwnerId, Primary_Email__c FROM Contact WHERE OwnerId = :acct.OwnerId][0];
        System.assertEquals(
            AResult.Email_Domain__c.toLowerCase(),
            c.Primary_Email__c.toLowerCase(),
            'Contact has been created without an account'
        );
        System.assertEquals(
            A1Result.Email_Domain__c.toLowerCase(),
            custDomain.toLowerCase(),
            'Contact has been created without an account'
        );
        System.assertEquals(c1Result.OwnerId, L2.OwnerId, 'Contact created with an existing lead owner id');
        System.assertEquals(c3Result.OwnerId, acct.OwnerId, 'Contact created with an existing account owner id');
    }

    @IsTest
    static void driftContactExistingAccountOwner() {
        //Create an account with an owner different then the system user
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 1);
        Id testAccountID = testAccountList[0].Id;
        Id testAccountOwnerID = testAccountList[0].OwnerId;
        String testAccountEmailDomain = testAccountList[0].Email_Domain__c;
        //Create a Contact with a leadsource of drift with the the Account already attached.

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Contact testContact = new Contact();
        testContact.AccountId = testAccountID;
        testContact.LeadSource = 'Drift';
        testContact.Email = 'bflowers45@' + testAccountEmailDomain;
        testContact.OwnerId = thisUser.Id;
        testContact.LastName = 'Flowers';
        testContact.FirstName = 'Brandon';

        Test.startTest();
        insert testContact;
        Test.stopTest();
        Account confirmAccount = [SELECT Id, OwnerId, Owner.Name FROM Account WHERE Id = :testAccountID][0];
        System.debug('The result Account owner name is ' + confirmAccount.Owner.Name);
        Contact resultContact = [SELECT Id, AccountId, OwnerId, Owner.Name FROM Contact WHERE Id = :testContact.Id][0];
        System.debug('The result contact owner name is ' + resultContact.Owner.Name);
        //Confirm the owner matches the account owner
        System.assertEquals(testAccountID, resultContact.AccountId, 'The Account did not match');
        System.assertEquals(testAccountOwnerID, resultContact.OwnerId, 'The Contact Owners did not Match');
    }

    @IsTest
    static void newcpcContactExistingAccountAndLead() {
        //Create a Lead and Account Owned by a Sales Rep
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 0, 'BDR');
        Id testAccountID = testAccountList[0].Id;
        Account testA1 = [SELECT Id, Email_Domain__c, OwnerId FROM Account WHERE Id = :testAccountID];
        //Create the Lead with the Same owner as the Account
        String testEmail = 'jsmith@' + testA1.Email_Domain__c;
        String testName = 'Smith';
        Lead testLead = new Lead();
        testLead.OwnerId = testA1.OwnerId;
        testLead.LeadSource = 'Sales Generated';
        testLead.Email_Domain__c = testA1.Email_Domain__c;
        testLead.LastName = 'Smith';
        testLead.Email = testEmail;
        insert testLead;

        Test.startTest();
        //Create a test contact
        Contact testContact = new Contact();
        testContact.LeadSource = 'CPC';
        testContact.Email = testEmail;
        testContact.LastName = testName;

        insert testContact;
        Test.stopTest();
        // Contact is created and owned by CPC Pool
        // Contact has sales generated and leadsource that is not CPC Pool
        // Contact is still owned by CPC pool
        Contact testPostContact = [
            SELECT Id, AccountId, LeadSource, OwnerId, Owner.Name
            FROM Contact
            WHERE Id = :testContact.Id
        ];
        Lead testPostLead = [
            SELECT Id, Status, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :testLead.Id
        ];
        System.debug(testPostLead);
        System.assertEquals(
            testLead.LeadSource,
            testPostContact.LeadSource,
            'The Contact does not have the lead\'s leadsource'
        );
        System.assertEquals(
            testAccountID,
            testPostContact.AccountId,
            'The Contact was not assigned to the existing Account'
        );
        System.assertEquals(
            AppConstants.CPC_HOUSE_USER,
            testPostContact.OwnerId,
            'The Contact is not owned by the CPC house account'
        );
        System.assertEquals(true, testPostLead.IsConverted, 'The Lead was not converted');
        System.assertEquals(
            testAccountID,
            testPostLead.ConvertedAccountId,
            'The lead was not converted into the right Account'
        );
        System.assertEquals(
            true,
            String.isBlank(testPostLead.ConvertedOpportunityId),
            'The lead has a converted Opportunity'
        );
    }

    @IsTest
    static void cpcContactNoAccountExistingLead() {
        List<User> testUsers = TestDataFactory.createTestUsers();
        User testUser1 = testUsers[0];
        //Created a Lead that is owned by a Sales Rep
        String testdomain = 'testcompany.com';
        String testEmail = 'jsmith@' + testdomain;
        String testName = 'Smith';
        Lead testLead = new Lead();
        testLead.OwnerId = testUser1.Id;
        testLead.LeadSource = 'Sales Generated';
        testLead.Email_Domain__c = testdomain;
        testLead.LastName = 'Smith';
        testLead.Email = testEmail;
        insert testLead;

        Test.startTest();
        //Create a test contact
        Contact testContact = new Contact();
        testContact.LeadSource = 'CPC';
        testContact.Email = testEmail;
        testContact.LastName = testName;
        insert testContact;
        Test.stopTest();
        Contact testPostContact = [
            SELECT Id, AccountId, Account.OwnerId, LeadSource, OwnerId, Owner.Name
            FROM Contact
            WHERE Id = :testContact.Id
        ];
        Lead testPostLead = [
            SELECT Id, Status, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :testLead.Id
        ];

        // The Contact and Account Shall be owned by the CPC Pool User and not the Sales Rep
        System.assertEquals(
            testLead.LeadSource,
            testPostContact.LeadSource,
            'The Contact does not have the lead\'s leadsource'
        );
        System.assertEquals(
            AppConstants.CPC_HOUSE_USER,
            testPostContact.OwnerId,
            'The Contact is not owned by the CPC house account'
        );
        System.assertEquals(
            AppConstants.CPC_HOUSE_USER,
            testPostContact.Account.OwnerId,
            'The Account is not owned by the CPC house account'
        );
        System.assertEquals(true, testPostLead.IsConverted, 'The Lead was not converted');
        System.assertEquals(
            testPostContact.AccountId,
            testPostLead.ConvertedAccountId,
            'The lead was not converted into the right Account'
        );
        System.assertEquals(
            true,
            String.isBlank(testPostLead.ConvertedOpportunityId),
            'The lead has a converted Opportunity'
        );
    }

    @IsTest
    static void checkLeadSource_OrderTest() {
        Lead l = new Lead();
        l.LastName = 'Test';
        l.Company = 'Test';
        l.Generic_FLAG__c = true;
        l.Email = 'client@genericdomain.com';
        l.HS_Generated_by_Sales__c = 'True';

        insert l;

        Contact c = new Contact();
        c.FirstName = 'Cool1';
        c.LastName = 'Contact1';
        c.Primary_Email__c = 'client@genericdomain.com';

        Test.startTest();
        insert c;
        Test.stopTest();

        System.assertEquals(
            'TRUE',
            [SELECT Generated_by_Sales__c FROM Contact WHERE Primary_Email__c = 'client@genericdomain.com']
            .Generated_by_Sales__c,
            'Contact should get values from Lead'
        );
    }

    @IsTest
    static void createGenericContactWithoutAnAccount() {
        // arrange
        String genericDomain = 'gmail.com';
        String testEmail = 'bobbarker@gmail.com';

        Assert.isTrue([SELECT Email_Domains__c FROM Email_Domain__mdt WHERE Email_Domains__c = :genericDomain].size() > 0,
                String.format('{0} is in the generic domain list', new List<String>{ genericDomain }));

        // act
        Test.startTest();
            insert new Contact(LastName = 'Test', Primary_Email__c = testEmail);
        Test.stopTest();

        // assert
        Contact c = [SELECT Id, Generic_Contact__c FROM Contact WHERE Primary_Email__c = :testEmail];
        Assert.areEqual(true, c.Generic_Contact__c, 'This contact should be marked as generic');
    }

    @IsTest
    static void createGenericContactWithAnAccount() {
        // arrange
        String genericDomain = 'gmail.com';
        String testEmail = 'bobbarker@gmail.com';

        Assert.isTrue([SELECT Email_Domains__c FROM Email_Domain__mdt WHERE Email_Domains__c = :genericDomain].size() > 0,
                String.format('{0} is in the generic domain list', new List<String>{ genericDomain }));

        Account acct = new Account(Name='Test Account');
        insert acct;

        // act
        Test.startTest();
            insert new Contact(LastName = 'Test', Primary_Email__c = testEmail, AccountId = acct.Id);
        Test.stopTest();

        // assert
        Contact c = [SELECT Id, Generic_Contact__c FROM Contact WHERE Primary_Email__c = :testEmail];
        Assert.areEqual(true, c.Generic_Contact__c, 'This contact should be marked as generic');
    }
}