@isTest
private class DatabaseUtilitiesTest {
    @isTest
    private static void saveToDatabase_nullMethodCalled_expectNullArgumentException() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            DatabaseUtilities.saveToDatabase(new List<SObject>(), '', 'Sample note');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }

    @isTest
    private static void saveToDatabase_nullDevAuditNote_expectNullArgumentException() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            DatabaseUtilities.saveToDatabase(new List<SObject>(), 'Sample Method', '');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }

    @isTest
    static void saveToDatabase_testSaveFailUpsert_Opp() {
        // This is missing a required Field
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity o = new Opportunity();
        oppList.add(o);
        DatabaseUtilities.saveToDatabase(oppList, 'MethodCalled', 'Dev Note');

        System.assert(true, 'Method called landed on Audit Error List');
    }

    @isTest
    static void saveToDatabase_testSaveFailUpsert_Project() {
        // This is missing a required Field
        List<Project__c> projectList = new List<Project__c>();
        Project__c p = new Project__c();
        projectList.add(p);
        DatabaseUtilities.saveToDatabase(projectList, 'MethodCalled', 'Dev Note');

        System.assert(true, 'Method called landed on Audit Error List');
    }

    @isTest
    static void saveToDatabase_testFailUpsert_Project() {
        // This is missing a required Field
        List<Project__c> projectList = new List<Project__c>();
        Project__c p = new Project__c();
        projectList.add(p);
        DatabaseUtilities.upsertToDatabase(projectList, 'MethodCalled', 'Dev Note');

        System.assert(true, 'Method called landed on Audit Error List');
    }

    @isTest
    static void saveTest_testSaveFailUpsert_Project_Contact() {
        // This is missing a required Field
        List<Project_Contact__c> junctionList = new List<Project_Contact__c>();
        Project_Contact__c junction = new Project_Contact__c();
        junctionList.add(junction);
        DatabaseUtilities.saveToDatabase(junctionList, 'MethodCalled', 'Dev Note');

        System.assert(true, 'Method called landed on Audit Error List');
    }

    @isTest
    private static void saveToDatabaseTracking_nullMethodCalled_expectNullArgumentException() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            DatabaseUtilities.saveToDatabaseTracking(new List<SObject>(), '', 'Sample note');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }

    @isTest
    private static void saveToDatabaseTracking_nullDevAuditNote_expectNullArgumentException() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            DatabaseUtilities.saveToDatabaseTracking(new List<SObject>(), 'Sample Method', '');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }

    @isTest
    static void saveToDatabaseTracking_testSaveFailUpsert_Project() {
        // This is missing a required Field
        List<Project__c> projectList = new List<Project__c>();
        Project__c p = new Project__c();
        projectList.add(p);
        DatabaseUtilities.saveToDatabaseTracking(projectList, 'MethodCalled', 'Dev Note');

        System.assert(true, 'Method called landed on Audit Error List');
    }

    @isTest
    static void saveToDatabaseTracking_testSaveSuccess_TrackerUpdated() {
        List<Contact> contactList = new List<Contact>();
        String testCustomerEmail = 'test@test.com';

        Contact c = new Contact();
        c.FirstName = 'TestMan';
        c.LastName = 'LastNamington';
        c.Primary_Email__c = testCustomerEmail;
        insert c;

        contactList.add(c);

        Integer results = DatabaseUtilities.saveToDatabaseTracking(contactList, 'MethodCalled', 'Dev Note');
        System.assertEquals(1, results, 'Tracker should be updated');
    }
    @isTest
    private static void deleteFromDatabase_nullMethodCalled_expectNullArgumentException() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            DatabaseUtilities.deleteFromDatabase(new List<SObject>(), '', 'Sample note');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }

    @isTest
    private static void deleteFromDatabase_nullDevAuditNote_expectNullArgumentException() {
        boolean exceptionEncountered = false;

        Test.startTest();
        try {
            DatabaseUtilities.deleteFromDatabase(new List<SObject>(), 'Sample Method', '');
        } catch (IllegalArgumentException caughtException) {
            exceptionEncountered = true;
        }
        Test.stopTest();

        System.assert(exceptionEncountered, 'Exception not encountered.');
    }

    @isTest
    static void deleteFromDatabase_testSaveFailUpsert() {
        // This is missing a required Field
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity o = new Opportunity();
        o.Name = 'test';
        o.StageName = 'Open';
        o.CloseDate = Date.newInstance(1999, 1, 1);
        insert o;
        oppList.add(o);
        Database.delete(oppList, false);
        DatabaseUtilities.deleteFromDatabase(oppList, 'MethodCalled', 'Dev Note');

        System.assert(true, 'Method called landed on Audit Error List');
    }

    @isTest
    static void leadConvert_test() {

        Account accTest = new Account(Name = 'Test');
        insert accTest;

        Contact conTest = new Contact(LastName = 'Test', AccountId = accTest.Id, Email = 'test@xometrytest.com');
        insert conTest;

        Lead leadTest = new Lead(LastName = 'Test', Company = 'Test', Primary_Email__c = 'test@xometrytest.com');
        insert leadTest;

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadTest.Id);
        lc.setAccountId(accTest.Id);
        lc.setContactId(accTest.Id);
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Test.startTest();
        DatabaseUtilities.leadConvert(new List<Database.LeadConvert>{ lc }, 'MethodCalled', 'Dev Note');
        Test.stopTest();

        System.assert(true, 'Method called landed on Audit Error List');
    }

    @isTest(seeAllData=false)
    static void logErrors_test() {

        Account accTest = new Account(Name = 'Test');
        insert accTest;

        Contact conTest = new Contact(LastName = 'Test', AccountId = accTest.Id, Email = 'test@xometrytest.com');
        insert conTest;

        String msg = 'problem with ' + accTest.Id + '.';
        conTest.addError('Name', msg);

        Test.startTest();
        List<Audit_Trail_Error__c> auditErrorList = DatabaseUtilities.logErrors(conTest.Id, conTest.getErrors(), 'methodCalled', 'devAuditNote');
        insert auditErrorList;
        Test.stopTest();

        Map<Id,Audit_Trail_Error__c> auditResultMap = new Map<Id,Audit_Trail_Error__c>();
        for(Audit_Trail_Error__c ate : [SELECT SourceId__c FROM Audit_Trail_Error__c]){
            auditResultMap.put(ID.valueOf(ate.SourceId__c), ate);
        }

        System.assertEquals(1, auditResultMap.size() ,'Audit Error should be created');
        System.assertEquals(true, auditResultMap.containskey(conTest.Id) ,'Audit Error should be created with Source Id ');

    }

    @IsTest
    static void updateToDatabase_happyPath() {
        // Arrange
        String originalName = 'Lastname' + String.valueOf(Datetime.now().getTime());
        String updatedName = 'Smith';
        Contact ct = new Contact(LastName = originalName, Email = 'test@fakeemail.com');
        insert ct;

        String method  = 'DatabaseUtilitiesTest.updateToDatabase';
        String humanFriendlyMsg = 'creating a contact record';

        List<Audit_Trail_Error__c> errors;

        // Act
        Test.startTest();
            ct.LastName = updatedName;
            errors
                = DatabaseUtilities.updateToDatabase(new List<Contact> { ct } ,method,humanFriendlyMsg);
        Test.stopTest();

        // Assert
        Assert.areEqual(0,errors.size(),'No errors occurred');

        ct = [SELECT Id, LastName FROM Contact WHERE Id = :ct.Id];
        Assert.areEqual(updatedName,ct.LastName,'Last name should be updated');
    }

    @IsTest
    static void updateToDatabase_errorPath() {
        // Arrange
        String originalName = 'Lastname' + String.valueOf(Datetime.now().getTime());
        Contact ct = new Contact(LastName = originalName, Email = 'test@fakeemail.com');
        insert ct;

        String methodCalled  = 'DatabaseUtilitiesTest.updateToDatabase';
        String humanFriendlyMsg = 'creating a contact record';

        List<Audit_Trail_Error__c> errors;

        // Act
        Test.startTest();
            ct.LastName = null;  // <--- THIS IS A REQUIRED FIELD PER SALESFORCE SCHEMA
            errors
                = DatabaseUtilities.updateToDatabase(new List<Contact> { ct } ,methodCalled,humanFriendlyMsg);
        Test.stopTest();

        // Assert
        Assert.areEqual(1,errors.size(),'An should have been recorded');
        errors = [SELECT Id, Module__c, Dev_Audit_Notes__c
                  FROM Audit_Trail_Error__c
                  WHERE Id = :errors[0].Id];
        Assert.areEqual(methodCalled,errors[0].Module__c,'Called method is recorded');
        Assert.areEqual(humanFriendlyMsg,errors[0].Dev_Audit_Notes__c,'audit notes are recorded recorded');
        ct = [SELECT Id, LastName
              FROM Contact
              WHERE Id = :ct.Id];
        Assert.areEqual(originalName,ct.LastName,'Last name should not be updated');
    }
}