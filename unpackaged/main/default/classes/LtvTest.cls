@isTest
private class LtvTest {
    @isTest
    private static void createNewLtv_nullLtvContact_expectLtvAssociation() {
        String testCustomerEmail = 'test@test.com';

        Contact nullLtvContact = new Contact();
        nullLtvContact.FirstName = 'TestMan';
        nullLtvContact.LastName = 'LastNamington';
        nullLtvContact.Primary_Email__c = testCustomerEmail;
        nullLtvContact.LTV_LKP__c = null;
        insert nullLtvContact;

        //create new ltv
        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = testCustomerEmail;
        associatedLtv.Customer_Email__c = testCustomerEmail;
        associatedLtv.LTV__c = 1234.00;

        Test.startTest();
        insert associatedLtv;
        Test.stopTest();

        Contact insertedContact = [
            SELECT Primary_Email__c, LTV_LKP__c
            FROM Contact
            WHERE Primary_Email__c = :testCustomerEmail
        ][0];

        System.assertEquals(
            associatedLtv.id,
            insertedContact.LTV_LKP__c,
            'New Ltv should have been associated to the contact.' + insertedContact.LTV_LKP__c
        );
    }

    @isTest
    private static void createNewLtv_nonNullLtvContact_expectOldLtvAssociation() {
        String testCustomerEmail = 'test@test.com';
        double oldLTV_val = 1234.00;
        double newLTV_val = 5678.00;

        Contact nullLtvContact = new Contact();
        nullLtvContact.FirstName = 'TestMan';
        nullLtvContact.LastName = 'LastNamington';
        nullLtvContact.Primary_Email__c = testCustomerEmail;
        nullLtvContact.LTV_LKP__c = null;
        insert nullLtvContact;

        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = testCustomerEmail;
        associatedLtv.Customer_Email__c = testCustomerEmail;
        associatedLtv.LTV__c = oldLTV_val;

        Test.startTest();
        insert associatedLtv;
        associatedLtv.LTV__c = newLTV_val;
        update associatedLtv;
        Test.stopTest();

        Contact insertedContact = [
            SELECT Primary_Email__c, LTV_LKP__c, LTV__c
            FROM Contact
            WHERE Primary_Email__c = :testCustomerEmail
        ][0];

        System.assertEquals(
            associatedLtv.id,
            insertedContact.LTV_LKP__c,
            'New Ltv should have been associated to the contact.'
        );
        System.assertNotEquals(oldLTV_val, insertedContact.LTV__c, 'Newly inserted ltv value should be updated.');
        System.assertEquals(newLTV_val, insertedContact.LTV__c, 'Original ltv value should be overwritten.');
    }

    @isTest
    private static void getContactUpdateList_withoutLtvs_returnsAssociatedContacts() {
        String testCustomerEmail = 'test@test.com';

        Contact nullLtvContact = new Contact();
        nullLtvContact.FirstName = 'TestMan';
        nullLtvContact.LastName = 'LastNamington';
        nullLtvContact.Primary_Email__c = testCustomerEmail;
        nullLtvContact.LTV_LKP__c = null;
        insert nullLtvContact;

        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = testCustomerEmail;
        associatedLtv.Customer_Email__c = testCustomerEmail;
        associatedLtv.LTV__c = 1234.00;

        List<LTV__c> addedLtvs = new List<LTV__c>();
        addedLtvs.add(associatedLtv);

        Test.startTest();
        insert addedLtvs;
        Test.stopTest();

        List<Contact> returnedContacts = [SELECT ID FROM Contact WHERE Primary_Email__c = :testCustomerEmail];

        System.assertEquals(nullLtvContact.id, returnedContacts[0].id, 'Contact should have been returned.');
    }

    @isTest
    private static void getContactUpdateList_withLtvs_returnsNoContacts() {
        String testCustomerEmail = 'test@test.com';

        Contact nullLtvContact = new Contact();
        nullLtvContact.FirstName = 'TestMan';
        nullLtvContact.LastName = 'LastNamington';
        nullLtvContact.Primary_Email__c = testCustomerEmail;
        nullLtvContact.LTV_LKP__c = null;
        insert nullLtvContact;

        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = testCustomerEmail;
        associatedLtv.Customer_Email__c = testCustomerEmail;
        associatedLtv.LTV__c = 1234.00;
        insert associatedLtv;

        List<LTV__c> addedLtvs = new List<LTV__c>();
        addedLtvs.add(associatedLtv);

        Test.startTest();
        List<Contact> returnedContacts = LTVHandler.getContactUpdateList(addedLtvs);
        Test.stopTest();

        System.assert(returnedContacts.isEmpty(), 'There should have been no contacts returned: ' + returnedContacts);
    }

    @isTest
    private static void createNewLtv_nullLtvAccount_expectLtvAssociation() {
        Account testAccount = new Account();
        testAccount.Name = 'domain.com';
        testAccount.Email_Domain__c = 'domain.com';
        testAccount.LTV_LKP__c = null;
        insert testAccount;

        //create new ltv
        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = 'LTV_' + testAccount.Email_Domain__c;
        associatedLtv.Account_Domain__c = testAccount.Email_Domain__c;
        associatedLtv.LTV__c = 1234.00;

        Test.startTest();
        insert associatedLtv;
        Test.stopTest();

        Account insertedAccount = [
            SELECT Email_Domain__c, LTV_LKP__c
            FROM Account
            WHERE Email_Domain__c = :testAccount.Email_Domain__c
        ][0];

        System.assertEquals(
            associatedLtv.id,
            insertedAccount.LTV_LKP__c,
            'New Ltv should have been associated to the account.' + insertedAccount.LTV_LKP__c
        );
    }

    @isTest
    private static void createNewLtv_nonNullLtvAccount_expectOldLtvAssociation() {
        Double oldLtv = 1234.00;
        Double newLtv = 5678.00;

        Account testAccount = new Account();
        testAccount.Name = 'domain.com';
        testAccount.Email_Domain__c = 'domain.com';
        testAccount.LTV_LKP__c = null;
        insert testAccount;

        //create new ltv
        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = 'LTV_' + testAccount.Email_Domain__c;
        associatedLtv.Account_Domain__c = testAccount.Email_Domain__c;
        associatedLtv.LTV__c = oldLtv;
        insert associatedLtv;

        Test.startTest();
        associatedLtv.LTV__c = newLtv;
        upsert associatedLtv;
        Test.stopTest();

        Account insertedAccount = [
            SELECT Email_Domain__c, LTV_LKP__c, LTV__c
            FROM Account
            WHERE Email_Domain__c = :testAccount.Email_Domain__c
        ][0];

        System.assertEquals(
            associatedLtv.id,
            insertedAccount.LTV_LKP__c,
            'New Ltv should have been associated to the account.' + insertedAccount.LTV_LKP__c
        );

        System.assertNotEquals(oldLtv, insertedAccount.LTV__c, 'Newly inserted ltv value should be updated.');
        System.assertEquals(newLtv, insertedAccount.LTV__c, 'Original ltv value should be overwritten.');
    }

    @isTest
    private static void getAccountUpdateList_withoutLtvs_returnsAssociatedAccounts() {
        String testAccountDomain = 'test.com';

        Account nullLtvAccount = new Account();
        nullLtvAccount.Name = 'LTV_' + testAccountDomain;
        nullLtvAccount.Email_Domain__c = testAccountDomain;
        nullLtvAccount.LTV_LKP__c = null;
        insert nullLtvAccount;

        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = testAccountDomain;
        associatedLtv.Account_Domain__c = testAccountDomain;
        associatedLtv.LTV__c = 1234.00;

        List<LTV__c> addedLtvs = new List<LTV__c>();
        addedLtvs.add(associatedLtv);

        Test.startTest();
        insert addedLtvs;
        Test.stopTest();

        List<Account> returnedAccounts = [SELECT ID FROM Account WHERE Email_Domain__c = :testAccountDomain];

        System.assertEquals(nullLtvAccount.id, returnedAccounts[0].id, 'Account should have been returned.');
    }

    @isTest
    private static void getAccountUpdateList_withLtvs_returnsNoAccounts() {
        String testAccountDomain = 'test.com';

        Account nullLtvAccount = new Account();
        nullLtvAccount.Name = 'LTV_' + testAccountDomain;
        nullLtvAccount.Email_Domain__c = testAccountDomain;
        nullLtvAccount.LTV_LKP__c = null;
        insert nullLtvAccount;

        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = testAccountDomain;
        associatedLtv.Account_Domain__c = testAccountDomain;
        associatedLtv.LTV__c = 1234.00;

        Test.startTest();
        insert associatedLtv;
        Test.stopTest();

        List<Account> returnedAccounts = [
            SELECT Id, LTV_LKP__c
            FROM Account
            WHERE Email_Domain__c = :testAccountDomain AND LTV_LKP__c = NULL
        ];

        System.assert(returnedAccounts.isEmpty(), 'There should have been no Accounts returned: ' + returnedAccounts);
    }

    @isTest
    private static void createNewLtv_Account_expectAccountRecordTypeId() {
        Account testAccount = new Account();
        testAccount.Name = 'domain.com';
        testAccount.Email_Domain__c = 'domain.com';
        testAccount.LTV_LKP__c = null;
        insert testAccount;

        //create new ltv
        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = 'LTV_' + testAccount.Email_Domain__c;
        associatedLtv.Account_Domain__c = testAccount.Email_Domain__c;
        associatedLtv.LTV__c = 1234.00;

        Test.startTest();
        insert associatedLtv;
        Test.stopTest();

        Id accountRecordTypeId = Schema.SObjectType.LTV__c.getRecordTypeInfosByDeveloperName()
            .get('Account_LTV')
            .getRecordTypeID();
        Id insertedLtvRecordTypeId = [SELECT RecordTypeId FROM LTV__c WHERE Id = :associatedLtv.Id].RecordTypeId;

        System.assertEquals(
            accountRecordTypeId,
            insertedLtvRecordTypeId,
            'RecordTypeId should be equal to Account Record Type Id. ' + insertedLtvRecordTypeId
        );
    }

    @isTest
    private static void createNewLtv_Contact_expectContactRecordTypeId() {
        String testCustomerEmail = 'test@test.com';
        Contact testContact = new Contact();
        testContact.FirstName = 'TestMan';
        testContact.LastName = 'LastNamington';
        testContact.Primary_Email__c = testCustomerEmail;
        testContact.LTV_LKP__c = null;
        insert testContact;

        //create new ltv
        LTV__c associatedLtv = new LTV__c();
        associatedLtv.Name = 'LTV_' + testCustomerEmail;
        associatedLtv.Customer_Email__c = testCustomerEmail;
        associatedLtv.LTV__c = 1234.00;

        Test.startTest();
        insert associatedLtv;
        Test.stopTest();

        Id contactRecordTypeId = Schema.SObjectType.LTV__c.getRecordTypeInfosByDeveloperName()
            .get('Contact_LTV')
            .getRecordTypeID();
        Id insertedLtvRecordTypeId = [SELECT RecordTypeId FROM LTV__c WHERE Id = :associatedLtv.Id].RecordTypeId;

        System.assertEquals(
            contactRecordTypeId,
            insertedLtvRecordTypeId,
            'RecordTypeId should be equal to Contact Record Type Id. ' + insertedLtvRecordTypeId
        );
    }
}