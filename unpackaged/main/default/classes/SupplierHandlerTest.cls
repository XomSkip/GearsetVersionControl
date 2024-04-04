@isTest
public class SupplierHandlerTest {
    //Test for a new supplier that does not already have an account or contact
    @isTest
    public static void newSupplierNewAccountGeneric() {
        Supplier__c s = TestDataFactory.createSupplier(false);

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE Id = :supplierResult.AccountId__c
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE Id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(
            supplierResult.SupplierCompanyName__c,
            accountResult.name,
            'Account Name should be Company Name'
        );
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(supplierResult.AccountId__c, accountResult.Id, 'Supplier should be related to new Account');
        System.assertEquals(supplierResult.ContactId__c, contactResult.Id, 'Supplier should be related to new Contact');
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.Generic_Account__c, 'Account should be marked generic');
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
    }

    //Test for a new supplier that does not have a domain on insert
    @isTest
    public static void newSupplierNewAccountGenericNoDomain() {
        Supplier__c s = TestDataFactory.createSupplier(false);
        string newDomain = s.EmailAddress__c;
        s.AccountDomain__c = '';
        s.IsGeneric__c = false; //should flip to true
        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, Email_Domain__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE Id = :supplierResult.AccountId__c
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE Id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(
            supplierResult.SupplierCompanyName__c,
            accountResult.name,
            'Account Name should be Company Name'
        );
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(supplierResult.AccountId__c, accountResult.Id, 'Supplier should be related to new Account');
        System.assertEquals(supplierResult.ContactId__c, contactResult.Id, 'Supplier should be related to new Contact');
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.Generic_Account__c, 'Account should be marked generic');
        System.assertEquals(newDomain, accountResult.Email_Domain__c, 'Account show have a domain');
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
    }

    @isTest
    public static void newSupplierNewAccountNonGeneric() {
        Supplier__c s = TestDataFactory.createSupplier(
            false,
            'P0000',
            'supplier@awesome.com',
            'awesome.com',
            'Awesome Company',
            'Doe',
            'John'
        );
        s.IsGeneric__c = false;

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE id = :s.Id
        ][0];
        Account accountResult = [
            SELECT id, name, RecordTypeID, generic_account__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE id = :supplierResult.AccountId__c
        ][0];
        Contact contactResult = [
            SELECT id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(
            supplierResult.SupplierCompanyName__c,
            accountResult.name,
            'Account Name should be Company Name'
        );
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(supplierResult.AccountId__c, accountResult.Id, 'Supplier should be related to new Account');
        System.assertEquals(supplierResult.ContactId__c, contactResult.Id, 'Supplier should be related to new Contact');
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(false, accountResult.Generic_Account__c, 'Account should not be marked generic');
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
    }

    @isTest
    public static void newSupplierNewAccountNonGenericNoDomain() {
        string testDomain = 'awesome.com';
        Supplier__c s = TestDataFactory.createSupplier(
            false,
            'P0000',
            'supplier@awesome.com',
            'awesome.com',
            'Awesome Company',
            'Doe',
            'John'
        );
        s.IsGeneric__c = true; //should flip to false
        s.AccountDomain__c = '';
        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE id = :s.Id
        ][0];
        Account accountResult = [
            SELECT id, name, RecordTypeID, generic_account__c, Email_Domain__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE id = :supplierResult.AccountId__c
        ][0];
        Contact contactResult = [
            SELECT id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(
            supplierResult.SupplierCompanyName__c,
            accountResult.name,
            'Account Name should be Company Name'
        );
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(supplierResult.AccountId__c, accountResult.Id, 'Supplier should be related to new Account');
        System.assertEquals(supplierResult.ContactId__c, contactResult.Id, 'Supplier should be related to new Contact');
        System.assertEquals(false, supplierResult.IsGeneric__c, 'Supplies should be generic false');
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(false, accountResult.Generic_Account__c, 'Account should not be marked generic');
        System.assertEquals(
            testDomain,
            accountResult.Email_Domain__c,
            'The domain was not set correctly on the account'
        );
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
    }

    @isTest
    public static void newSupplierExistingAccountGeneric() {
        Supplier__c s = TestDataFactory.createSupplier(false);

        Account a = new Account();
        a.Name = 'supplier@gmail.com';
        a.Account_Owner_Type__c = 'BDR';
        a.Email_Domain__c = 'supplier@gmail.com';

        insert a;

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE Id = :a.Id
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE Id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(
            supplierResult.AccountId__c,
            accountResult.Id,
            'Supplier should be related to existing Account'
        );
        System.assertEquals(
            false,
            String.isBlank(supplierResult.ContactId__c),
            'Supplier should be related to a new Contact'
        );
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
    }

    @isTest
    public static void newSupplierExistingAccountNonGeneric() {
        Supplier__c s = TestDataFactory.createSupplier(
            false,
            'P0000',
            'supplier@company.com',
            'company.com',
            'Company Supplier',
            'Doe',
            'John'
        );
        s.IsGeneric__c = false;

        Account a = new Account();
        a.Name = 'Company Supplier';
        a.Account_Owner_Type__c = 'BDR';
        a.Email_Domain__c = 'company.com';

        insert a;

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE Id = :a.Id
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE Id = :supplierResult.ContactID__c
        ][0];

        System.assertEquals(
            supplierResult.AccountId__c,
            accountResult.Id,
            'Supplier should be related to existing Account'
        );
        System.assertEquals(
            false,
            String.isBlank(supplierResult.ContactId__c),
            'Supplier should be related to a new Contact'
        );
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
    }

    @isTest
    public static void newSupplierNewContact() {
        Supplier__c s = TestDataFactory.createSupplier(false);

        Account a = new Account();
        a.Name = 'supplier@gmail.com';
        a.Account_Owner_Type__c = 'BDR';
        a.Email_Domain__c = 'supplier@gmail.com';

        insert a;

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE Id = :a.Id
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId, Supplier__c
            FROM Contact
            WHERE Id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(
            supplierResult.AccountId__c,
            accountResult.Id,
            'Supplier should be related to existing Account'
        );
        System.assertEquals(
            false,
            String.isBlank(supplierResult.ContactId__c),
            'Supplier should be related to a Contact'
        );
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
        System.assertEquals(s.Id, contactResult.Supplier__c, 'Contact should associate to supplier');
    }

    @isTest
    public static void newSupplierExistingContact() {
        Supplier__c s = TestDataFactory.createSupplier(false);

        Account a = new Account();
        a.Name = 'supplier@gmail.com';
        a.Account_Owner_Type__c = 'BDR';
        a.Email_Domain__c = 'supplier@gmail.com';

        insert a;

        Contact c = new Contact();
        c.FirstName = 'Supplier';
        c.LastName = 'Contact';
        c.Primary_Email__c = 'supplier@gmail.com';
        c.AccountID = a.ID;
        s.Address1__c = '123 Supplier Lane';
        s.City__c = 'Lexington';
        s.State__c = 'Kentucky';
        s.ZipCode__c = '12345';

        insert c;

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE Id = :a.Id
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId, Supplier__c
            FROM Contact
            WHERE Id = :c.Id
        ][0];

        System.assertEquals(
            supplierResult.AccountId__c,
            accountResult.Id,
            'Supplier should be related to existing Account'
        );
        System.assertEquals(supplierResult.ContactId__c, c.Id, 'Supplier should be related to existing Contact');
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(
            supplierResult.PartnerId__c,
            accountResult.GNO_PartnerId__c,
            'Account should have Partner Id'
        );
        System.assertEquals(s.Id, contactResult.Supplier__c, 'Contact should associate to supplier');
    }

    @isTest
    public static void newSupplierNewContactNoLastName() {
        Supplier__c s = TestDataFactory.createSupplier(false);
        s.LastName__c = '';

        Account a = new Account();
        a.Name = 'supplier@gmail.com';
        a.Account_Owner_Type__c = 'BDR';
        a.Email_Domain__c = 'supplier@gmail.com';

        insert a;

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c
            FROM Account
            WHERE Id = :a.Id
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId, LastName
            FROM Contact
            WHERE Id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(
            supplierResult.AccountId__c,
            accountResult.Id,
            'Supplier should be related to existing Account'
        );
        System.assertEquals(
            false,
            String.isBlank(supplierResult.ContactId__c),
            'Supplier should be related to a Contact'
        );
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
        System.assertEquals(s.EmailAddress__c, contactResult.LastName, 'Last name should be email address');
    }

    @isTest
    public static void newSupplierNewAccountGenericNoPartnerName() {
        Supplier__c s = TestDataFactory.createSupplier(false);
        s.SupplierCompanyName__c = '';

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c
            FROM Account
            WHERE Id = :supplierResult.AccountId__c
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE Id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(s.AccountDomain__c, accountResult.Name, 'Account Name should be domain or email');
        System.assertEquals(
            false,
            String.isBlank(supplierResult.AccountId__c),
            'Supplier should be related to to a new Account'
        );
        System.assertEquals(
            false,
            String.isBlank(supplierResult.ContactId__c),
            'Supplier should be related to a new Contact'
        );
        System.assertEquals(true, contactResult.IsSupplier__c, 'Contact should be marked as supplier');
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
    }

    @isTest
    public static void supplierIdOnAccount() {
        Supplier__c s = TestDataFactory.createSupplier(true);

        Test.startTest();
        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];
        Test.stopTest();

        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c, GNO_PartnerId__c
            FROM Account
            WHERE Id = :supplierResult.AccountId__c
        ][0];
        Contact contactResult = [
            SELECT Id, Primary_Email__c, IsSupplier__c, AccountId
            FROM Contact
            WHERE Id = :supplierResult.ContactId__c
        ][0];

        System.assertEquals(s.PartnerId__c, AccountResult.GNO_PartnerId__c, 'PartnerId should be on account');
    }

    @isTest
    public static void supplierUpdate_changesLastReadDate() {
        Supplier__c s = TestDataFactory.createSupplier(false);
        s.JobOffersRead__c = 20;
        s.LastReadJobDate__c = Date.today() - 10;
        insert s;

        Test.startTest();
        s.JobOffersRead__c = 21;
        update s;
        Test.stopTest();

        Supplier__c supplierResult = [SELECT Id, LastReadJobDate__c FROM Supplier__c WHERE Id = :s.Id][0];

        System.assertEquals(
            Date.today(),
            supplierResult.LastReadJobDate__c,
            'Last read date should be updated because read jobs increased'
        );
    }

    @isTest
    public static void supplierUpdate_doesNotChangeLastReadDate() {
        Supplier__c s = TestDataFactory.createSupplier(false);
        s.JobOffersRead__c = 20;
        s.LastReadJobDate__c = Date.today() - 10;
        insert s;

        Test.startTest();
        s.JobOffersRead__c = 20;
        update s;
        Test.stopTest();

        Supplier__c supplierResult = [SELECT Id, LastReadJobDate__c FROM Supplier__c WHERE Id = :s.Id][0];

        System.assertEquals(
            s.LastReadJobDate__c,
            supplierResult.LastReadJobDate__c,
            'Last read date should not change'
        );
    }

    @isTest
    public static void newSupplierNullDomainExistingAccount() {
        Supplier__c s = TestDataFactory.createSupplier(false);

        Account a = new Account();
        a.Name = 'supplier@gmail.com';
        a.Account_Owner_Type__c = 'BDR';

        insert a;

        Test.startTest();
        insert s;
        Test.stopTest();

        Supplier__c supplierResult = [
            SELECT Id, AccountId__c, ContactId__c, PartnerId__c, EmailAddress__c, IsGeneric__c, SupplierCompanyName__c
            FROM Supplier__c
            WHERE Id = :s.Id
        ][0];

        Account accountResult = [
            SELECT Id, Name, RecordTypeID, Generic_Account__c, IsSupplier__c
            FROM Account
            WHERE Id = :supplierResult.AccountId__c
        ][0];

        System.assertEquals(supplierResult.AccountId__c, accountResult.Id, 'Supplier should be related to new Account');
        System.assertNotEquals(a.Id, supplierResult.AccountId__c, 'Supplier should be related to new Account');
        System.assertEquals(
            false,
            String.isBlank(supplierResult.ContactId__c),
            'Supplier should be related to a new Contact'
        );
        System.assertEquals(true, accountResult.IsSupplier__c, 'Account should be marked as supplier');
    }

    @isTest
    public static void onboardingParentCaseCreationTest() {
        List<Supplier__c> suplierList = new List<Supplier__c>();
        Supplier__c s = TestDataFactory.createSupplier(false);
        s.DateApproved__c = null;
        s.SupplierStatus__c = 'registered';
        s.SupplierStatusLastUpdated__c = Date.newInstance(2021, 5, 1).addDays(1);

        suplierList.add(s);

        Supplier__c s2 = TestDataFactory.createSupplier(false);
        s2.PartnerID__c = 'P0001';
        s2.SupplierStatus__c = 'registered';
        s2.DateApproved__c = null;
        s2.SupplierStatusLastUpdated__c = Date.newInstance(2021, 5, 1);
        suplierList.add(s2);

        Test.startTest();
        insert suplierList;
        Test.stopTest();

        Supplier__c supplierResult = [SELECT Id, OnboardingParentCase__c FROM Supplier__c WHERE Id = :s.Id][0];
        Case caseResult = [SELECT Supplier__c FROM Case WHERE Supplier__c = :s.Id][0];

        System.assertEquals(supplierResult.OnboardingParentCase__c, caseResult.Id);

        Supplier__c supplierResult2 = [SELECT Id, OnboardingParentCase__c FROM Supplier__c WHERE Id = :s2.Id][0];

        System.assertEquals(supplierResult2.OnboardingParentCase__c, null);
        System.assertEquals([SELECT Supplier__c FROM Case WHERE Supplier__c = :s2.Id], new List<Case>());
    }

    @isTest
    public static void newSuppliersWithSameDomain() {
        List<Supplier__c> sList = new List<Supplier__c>();
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P0000';
        s.EmailAddress__c = 'supplier@company.com';
        s.AccountDomain__c = 'company.com';
        s.SupplierCompanyName__c = 'Company Supplier';
        s.LastName__c = 'Doe';
        s.FirstName__c = 'John';
        s.Phone__c = '1234567890';
        s.IsGeneric__c = false;
        sList.add(s);

        Supplier__c s1 = new Supplier__c();
        s1.PartnerID__c = 'P1234';
        s1.EmailAddress__c = 'supplier2@company.com';
        s1.AccountDomain__c = 'company.com';
        s1.SupplierCompanyName__c = 'Company Supplier';
        s1.LastName__c = 'Doe';
        s1.FirstName__c = 'Jane';
        s1.Phone__c = '5555555555';
        s1.IsGeneric__c = false;
        sList.add(s1);

        Test.startTest();
        insert sList;
        Test.stopTest();

        List<Account> accts = [SELECT Id, GNO_PartnerID__c FROM Account];

        System.assertEquals(1, accts.size(), 'Only one account should create');
    }

    @isTest(seeAllData=false)
    public static void updateObjectsFromSupplierChangesTest() {
        Supplier__c s = TestDataFactory.createSupplier(false);
        s.AccountDomain__c = 'supplier@xometrytest.com';
        s.SupplierCompanyName__c = 'Generic Supplier';
        s.Address1__c = '123 Supplier Lane';
        s.City__c = 'Lexington';
        s.State__c = 'Kentucky';
        s.ZipCode__c = '12345';

        Supplier__c s2 = new Supplier__c(
            PartnerID__c = 'P0001',
            EmailAddress__c = 'supplier2@xometrytest.com',
            AccountDomain__c = 'supplier2@xometrytest.com',
            SupplierCompanyName__c = '',
            LastName__c = 'Supplier2',
            FirstName__c = 'Generic2',
            Phone__c = '1234567899',
            Address1__c = '124 Supplier Lane',
            City__c = 'Lexington',
            State__c = 'Kentucky',
            ZipCode__c = '12345',
            IsGeneric__c = true
        );

        Account a = new Account();
        a.Name = 'supplier1@xometrytest.com';
        a.Email_Domain__c = 'supplier1@xometrytest.com';
        a.OwnerId = AppConstants.GNO_HOUSE_USER;

        Account a2 = new Account();
        a2.Name = 'supplier2@xometrytest.com';
        a2.Email_Domain__c = 'supplier2@xometrytest.com';
        insert new List<Account>{ a, a2 };

        Contact c = new Contact();
        c.FirstName = 'Supplier1';
        c.LastName = 'Contact1';
        c.Primary_Email__c = 'supplier1@xometrytest.com';
        c.AccountID = a.ID;
        c.OwnerId = AppConstants.GNO_HOUSE_USER;

        Contact c2 = new Contact();
        c2.FirstName = 'Supplier2';
        c2.LastName = 'Contact2';
        c2.Primary_Email__c = 'supplier2@xometrytest.com';
        c2.AccountID = a2.ID;
        c2.OwnerId = AppConstants.GNO_HOUSE_USER;

        insert new List<Contact>{ c, c2 };

        s.AccountID__C = a.Id;
        s.ContactID__C = c.Id;
        s2.AccountID__C = a2.Id;
        s2.ContactID__C = c2.Id;
        insert new List<Supplier__c>{ s, s2 };

        Test.startTest();

        s.ZipCode__c = '12344';
        s.SupplierCompanyName__c = 'Generic Supplier New Name';
        s.AccountDomain__c = 'supplier@xometrytestnew.com';
        s2.ZipCode__c = '12346';
        s.AccountDomain__c = 'supplier2@xometrytestnew.com';
        update new List<Supplier__c>{ s, s2 };

        Test.stopTest();

        Map<Id, Account> accResultMap = new Map<Id, Account>(
            [SELECT Name, ERP_Billing_Zip_Code__c FROM Account WHERE Id = :a.Id OR Id = :a2.Id]
        );
        Map<Id, Contact> conResultMap = new Map<Id, Contact>(
            [SELECT Name, ERP_Shipping_Zip_Code__c FROM Contact WHERE Id = :c.Id OR Id = :c2.Id]
        );

        System.assertEquals(
            s.ZipCode__c,
            conResultMap.get(c.Id).ERP_Shipping_Zip_Code__c,
            'Contact should be updated with new value'
        );
        System.assertEquals(
            s2.ZipCode__c,
            conResultMap.get(c2.Id).ERP_Shipping_Zip_Code__c,
            'Contact should be updated with new value'
        );

        System.assertEquals(
            s.ZipCode__c,
            accResultMap.get(a.Id).ERP_Billing_Zip_Code__c,
            'Account should be updated with new value'
        );
        System.assertNotEquals(
            s2.ZipCode__c,
            accResultMap.get(a2.Id).ERP_Billing_Zip_Code__c,
            'Account should not be updated with new value'
        );

        System.assertEquals(
            s.SupplierCompanyName__c,
            accResultMap.get(a.Id).Name,
            'Account should be updated with new value'
        );
        System.assertNotEquals(
            s.AccountDomain__c,
            accResultMap.get(a.Id).Name,
            'Account should be updated but not with this value'
        );
        System.assertEquals(
            s2.AccountDomain__c,
            accResultMap.get(a2.Id).Name,
            'Account should be updated with new value'
        );
    }
}