@isTest
public with sharing class SuppliesQuoteHandlerTest {
    @isTest
    public static void createSimpleSQuote_Test() {
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        test.startTest();
        insert sQuoteTest;
        test.stopTest();
        ID testID = sQuoteTest.ID;
        Supplies_Quote__C testSQuoteResult = [
            SELECT ID, AccountID__C, P21_Account_DetailsID__c, ContactID__C, OpportunityID__C, OwnerId, owner.name
            FROM Supplies_Quote__C
            WHERE ID = :testID
        ][0];
        system.assert(!String.isblank(testSQuoteResult.OpportunityID__C), 'There was no OpportunityID');
        system.assert(!String.isblank(testSQuoteResult.P21_Account_DetailsID__c), 'There was no P21 Customer Created');
        System.assertNotEquals(
            UserInfo.getUserId(),
            testSQuoteResult.OwnerId,
            'Owner should not be user that ran test'
        );
    }
    @isTest
    public static void create2SQuote_Test() {
        List<Supplies_Quote__C> testQuoteList = new List<Supplies_Quote__C>();
        //This Test has 2 Supplies Contact belonging to the same P21 Customer
        //After Inserting records there should be only One Account
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        Supplies_Quote__C sQuoteTest2 = new Supplies_Quote__C();
        sQuoteTest2.P21_ERP_ID__c = 'OE23478';
        sQuoteTest2.P21_ContactID__c = 'A1266';
        sQuoteTest2.P21_CustomerID__c = 'CA144'; //Same CustomerID above
        sQuoteTest2.Quote_Email__c = 'bobsmith22@gmail.com';
        sQuoteTest2.Account_Domain__c = 'bobsmith22@gmail.com';
        sQuoteTest2.Is_Generic__c = true;
        sQuoteTest2.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest2.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest2.P21_Contact_Phone__c = '5553334444';
        sQuoteTest2.P21_OE_Status__c = 'Active';
        sQuoteTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest2.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest2.P21_Physical_Country__c = 'United States';
        sQuoteTest2.P21_Physical_State__c = 'Maryland';
        sQuoteTest2.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest2.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest2.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest2.Quote_Price__c = 1000.50;
        testQuoteList.add(sQuoteTest);
        testQuoteList.add(sQuoteTest2);
        test.startTest();
        insert testQuoteList;
        test.stopTest();
        AggregateResult[] aggAccts = [SELECT Count(ID) NumAccts FROM Account];
        Integer numAccounts = Integer.valueOf(aggAccts[0].get('NumAccts'));
        AggregateResult[] aggOpps = [SELECT Count(ID) oppNum FROM Opportunity];
        Integer numOpps = Integer.valueOf(aggOpps[0].get('oppNum'));
        system.assertEquals(numAccounts, 1, 'There was more then one account');
        system.assertEquals(numOpps, 2, 'There were not two opportunities');
    }

    @isTest
    public static void basicBulkLoadTest() {
        //Cannot hit 200 do to timeouts in the Account Process Builder
        List<Supplies_Quote__C> testQuoteList = new List<Supplies_Quote__C>();
        // Moving testSize down to 40 instead of 50 due to outreach process builder
        // 2022-06-25 update: Moving testSize down to 20 due to Large Order release
        Integer testSize = 20;
        for (Integer i = 0; i < testSize; i++) {
            Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
            sQuoteTest.P21_ERP_ID__c = 'OE23' + i;
            sQuoteTest.P21_ContactID__c = 'A126' + i;
            sQuoteTest.P21_CustomerID__c = 'CA144' + i;
            sQuoteTest.Quote_Email__c = 'bobsmith21' + i + '@gmail.com';
            sQuoteTest.Account_Domain__c = 'bobsmith21' + i + '@gmail.com';
            sQuoteTest.Is_Generic__c = true;
            sQuoteTest.P21_Contact_First_Name__c = 'Bob';
            sQuoteTest.P21_Contact_Last_Name__c = 'Smith' + i;
            sQuoteTest.P21_Contact_Phone__c = '5553334444';
            sQuoteTest.P21_OE_Status__c = 'Active';
            sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
            sQuoteTest.P21_Physical_City__c = 'MadeupTown';
            sQuoteTest.P21_Physical_Country__c = 'United States';
            sQuoteTest.P21_Physical_State__c = 'Maryland';
            sQuoteTest.P21_Physical_Zip_Code__c = '23455';
            sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
            sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
            sQuoteTest.Quote_Price__c = 500.50;
            testQuoteList.add(SQuoteTest);
        }
        test.startTest();
        insert testQuoteList;
        test.stopTest();
        AggregateResult[] aggSQuoteRslt = [SELECT count(id) newSQuotes FROM Supplies_Quote__C];
        Integer newSQuoteCount = Integer.valueOf(aggSQuoteRslt[0].get('newSQuotes'));
        System.assertEquals(newSQuoteCount, testSize, 'There were not ' + testSize + ' quotes created');
    }

    //Existing Managed Service Contact who then gets a Supplies Quote. That contact should be linked to the P21 Account. Then the Opp can make it to the territory rep.
    @isTest
    static void managedServiceAndSupplies() {
        //Create a simple MS Quote
        Quote_ERP__C testQuote = TestDataFactory.createQuoteWithAcc(true, 'BDR');
        ID testMSQuoteID = testQuote.ID;
        Quote_ERP__C testMSQuote = [
            SELECT ID, ContactID__C, ContactID__R.P21_Account_Details__c, Quote_Email__c, Account_Domain__c
            FROM Quote_ERP__C
            WHERE ID = :testMSQuoteID
        ];

        // Create a Supplies Quote
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        // The existing Contact shall be linked to the P21 Account and the P21 Account shall link to the existing Contact
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = testMSQuote.Quote_Email__C;
        sQuoteTest.Account_Domain__c = testMSQuote.Account_Domain__c;
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = false;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Processing';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        test.startTest();
        insert sQuoteTest;
        test.stopTest();
        Contact testConResult = [
            SELECT ID, AccountID, Primary_Email__C, P21_Account_Details__c, P21_Account_Details__r.AccountID__c
            FROM Contact
            WHERE ID = :testMSQuote.ContactID__C
        ];
        System.assert(!String.isblank(testConResult.P21_Account_Details__c), 'There was no P21 Account on the Contact');
        System.assertEquals(
            testConResult.AccountID,
            testConResult.P21_Account_Details__r.AccountID__c,
            'The contact and P21 Account Details did not have the same account'
        );
    }

    @isTest
    static void updateOppTest() {
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        insert sQuoteTest;

        sQuoteTest.Quote_Price__c = 123.45;

        test.startTest();
        update sQuoteTest;
        test.stopTest();

        Opportunity oppResult = [
            SELECT ID, Amount
            FROM Opportunity
            WHERE Quote_ERP_XOM_CREATE_ID__c = :sQuoteTest.P21_ERP_ID__c
        ];

        Supplies_Quote__C quoteResult = [
            SELECT Id, OpportunityID__c
            FROM Supplies_Quote__c
            WHERE P21_ERP_ID__c = 'OE23477'
        ];

        System.assertEquals(123.45, oppResult.Amount, 'The opp Amount did not update when the order total changed');
        System.assertEquals(quoteResult.OpportunityID__C, oppResult.ID);
    }

    @isTest
    static void cancelledQuoteTest() {
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        insert sQuoteTest;

        sQuoteTest.P21_OE_Status__c = 'Canceled';

        test.startTest();
        update sQuoteTest;
        test.stopTest();

        Opportunity oppResult = [
            SELECT ID, StageName
            FROM Opportunity
            WHERE Quote_ERP_XOM_CREATE_ID__c = :sQuoteTest.P21_ERP_ID__c
        ];

        System.assertEquals(
            'Closed Lost',
            oppResult.StageName,
            'The opp stage did not change when the quote was cancelled'
        );
    }

    @isTest
    static void uncancelledQuoteTest() {
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        insert sQuoteTest;

        sQuoteTest.P21_OE_Status__c = 'Canceled';
        update sQuoteTest;

        sQuoteTest.P21_OE_Status__c = 'Active';

        test.startTest();
        update sQuoteTest;
        test.stopTest();

        Opportunity oppResult = [
            SELECT ID, StageName
            FROM Opportunity
            WHERE Quote_ERP_XOM_CREATE_ID__c = :sQuoteTest.P21_ERP_ID__c
        ];

        System.assertEquals(
            'System Reopened',
            oppResult.StageName,
            'The opp stage did not change when the order was un-cancelled'
        );
    }
    @isTest
    public static void convertLead() {
        List<Account> newAccountList = TestDataFactory.createTestAccountNonGenericsStaffUser(5, 'AM', 1);

        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];
        //Creating Lead
        Lead testLead = new Lead();
        testLead.Company = c.Account.Name;
        testLead.FirstName = 'Bob';
        testLead.LastName = 'Builder';
        testLead.Email = c.Email;
        testLead.LeadSource = 'Lead Gen';
        testLead.Email_Domain__c = c.Account.Email_Domain__c;
        testLead.Primary_Email__c = c.Email;
        insert testLead;

        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = testLead.Primary_Email__c;
        sQuoteTest.Account_Domain__c = c.Account.Email_Domain__c;
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        test.startTest();
        insert sQuoteTest;
        test.stopTest();

        Lead convertedLead = [SELECT isConverted FROM Lead WHERE ID = :testLead.ID];
        System.assertEquals(true, convertedLead.isConverted, 'The Lead was not converted');
    }

    @isTest
    static void SFPCasenoPreOpp() {
        /* This test creates a Case for SFP that has no existing Opp
        Also confirms that category and name is SFP
    */
        ID caseSuppliesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('SellerMarketplace')
            .getRecordTypeID();
        List<User> testUserList = TestDataFactory.createSupTestReps(2, null, null, true);
        Case manQuoteCase = new Case();
        ID testRepID = testUserList[0].ID;
        manQuoteCase.RecordTypeID = caseSuppliesRecordTypeId;
        manQuoteCase.Shadow_P21_Quote_Id__c = 'OE23477';
        manQuoteCase.Subject = 'Looking for lots of good Aluminium';
        manQuoteCase.Origin = 'Manual';
        manQuoteCase.Type = 'RFQ-Quote';
        manQuoteCase.ownerId = testRepID;
        insert manQuoteCase;

        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.SFP_FLAG__C = true;
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        test.startTest();
        insert sQuoteTest;
        test.stopTest();
        ID testID = sQuoteTest.ID;
        Supplies_Quote__C testSQuoteResult = [
            SELECT ID, AccountID__C, P21_Account_DetailsID__c, ContactID__C, OpportunityID__C
            FROM Supplies_Quote__C
            WHERE ID = :testID
        ][0];
        Opportunity testOppResult = [
            SELECT ID, Sup_Source_Category__c, Name, OwnerId
            FROM Opportunity
            WHERE ID = :testSQuoteResult.OpportunityID__C
        ];

        Case testCaseResult = [SELECT ID, Opportunity__C FROM Case WHERE ID = :manQuoteCase.ID];
        system.debug(testCaseResult);
        System.assertEquals(
            testSQuoteResult.OpportunityID__C,
            testCaseResult.Opportunity__C,
            'The case did not link with the Opp'
        );
        System.assertEquals(testRepID, testOppResult.OwnerId, 'The Opp did not inherit the owner of the Case');
        System.assertEquals('SFP', testOppResult.Sup_Source_Category__c, 'The Opp did not get identified with SFP');
        System.assertEquals('SFP', testOppResult.name.substring(0, 3), 'The Opp did not get name starting with SFP');
    }

    /* This test creates an Opp and then links it to a Case with the manual Quote info filled in */
    @isTest
    static void SFPCaseWithPreOpp() {
        ID caseSuppliesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('SellerMarketplace')
            .getRecordTypeID();
        ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        List<User> testUserList = TestDataFactory.createSupTestReps(2, null, null, true);
        ID testRepID = testUserList[0].ID;
        Opportunity preTestOpp = new Opportunity();
        preTestOpp.OwnerId = testRepID;
        preTestOpp.recordTypeID = oppSuppliesRecordTypeID;
        preTestOpp.Amount = 444.13;
        preTestOpp.name = 'Lets Get Aluminum';
        preTestOpp.StageName = 'New';
        preTestOpp.CloseDate = date.today() + 30;
        insert preTestOpp;

        Case manQuoteCase = new Case();
        manQuoteCase.RecordTypeID = caseSuppliesRecordTypeId;
        manQuoteCase.Shadow_P21_Quote_Id__c = 'OE23477';
        manQuoteCase.Subject = 'Looking for lots of good Aluminium';
        manQuoteCase.Origin = 'Manual';
        manQuoteCase.Type = 'RFQ-Quote';
        manQuoteCase.ownerId = testRepID;
        manQuoteCase.Opportunity__C = preTestOpp.ID;
        insert manQuoteCase;

        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.SFP_FLAG__C = true;
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        test.startTest();
        insert sQuoteTest;
        test.stopTest();
        ID testID = sQuoteTest.ID;
        Supplies_Quote__C testSQuoteResult = [
            SELECT ID, AccountID__C, P21_Account_DetailsID__c, ContactID__C, OpportunityID__C
            FROM Supplies_Quote__C
            WHERE ID = :testID
        ][0];
        System.debug('Here is my testQuoteResult');
        System.debug(testSQuoteResult);
        Case testCaseResult = [SELECT ID, Opportunity__C, Opportunity__R.Name FROM Case WHERE ID = :manQuoteCase.ID];
        system.debug('Did the case get an Opp?');
        system.debug(testCaseResult);
        Opportunity testOppResult = [
            SELECT ID, Amount, Sup_Source_Category__c, Name, OwnerId
            FROM Opportunity
            WHERE ID = :testSQuoteResult.OpportunityID__C
        ];

        System.assertEquals(
            testSQuoteResult.OpportunityID__C,
            testCaseResult.Opportunity__C,
            'The case did not link with the Opp'
        );
        System.assertEquals(testRepID, testOppResult.OwnerId, 'The Opp did not inherit the owner of the Case');
        System.assertEquals('SFP', testOppResult.Sup_Source_Category__c, 'The Opp did not get identified with SFP');
        System.assertEquals('SFP', testOppResult.name.substring(0, 3), 'The Opp did not get name starting with SFP');
        System.assertEquals(
            sQuoteTest.Quote_Price__c,
            testOppResult.Amount,
            'The Opp Amounts did not match the new quote'
        );
        List<AggregateResult> countOppsResult = [SELECT count(ID) FROM Opportunity];
        System.assertEquals(1, integer.valueof(countOppsResult[0].get('expr0')), 'More then 1 Opp exists');
    }
    @isTest
    static void jobSupOppwithManualQuoteNoOppAttached() {
        /*
    This test checks that a Job that creates a Supplies Opp will map to the Case with the manual quote and map to the Job Opp
    */
        ID caseSuppliesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('SellerMarketplace')
            .getRecordTypeID();
        ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        List<User> mySupTestUsers = TestDataFactory.createSupTestReps(5, null, null, true);
        List<Rep_Router__c> testRepRouteList = TestDataFactory.createRepRouterTestData(mySupTestUsers, 'Supplies', 1);
        Rep_Router__c rRouter1 = testRepRouteList[0];
        Rep_Router__c rRouter2 = testRepRouteList[1];
        List<Account> accountTestData = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 2);
        Account testAccount1 = accountTestData[0];
        ID testAccount1ID = accountTestData[0].ID;

        List<Contact> testContactList = [
            SELECT Id, FirstName, LastName, AccountID, Primary_Email__C
            FROM Contact
            WHERE AccountID = :testAccount1ID
        ];
        Contact supplier1Contact = testContactList[0];
        // P21 Account has an Owner. Match the ZipCode to the 1st Router Owne
        System.debug('Starting P21 Account Insert');
        P21_Account_Details__C testP21Account = new P21_Account_Details__C();
        testP21Account.OwnerId = rRouter1.User__c;
        testP21Account.AccountID__C = testAccount1ID;
        testP21Account.Name = 'King Kong Machines';
        testP21Account.P21_CustomerID__c = 'C1111';
        testP21Account.PartnerID__C = 'P1223';
        testP21Account.Primary_Zip_Code__c = rRouter1.ZipCode__c;
        insert testP21Account;
        System.debug('Starting the Supplier Insert');
        // Existing Supplier with Account and P21 account
        Supplier__C testSupplier = new Supplier__C();
        testSupplier.P21_Account_Details__c = testP21Account.ID;
        testSupplier.PartnerID__c = testP21Account.PartnerID__C;
        testSupplier.SupplierCompanyName__c = 'King Kong Machine Supplier';
        testSupplier.EmailAddress__c = supplier1Contact.Primary_Email__C;
        testSupplier.AccountDomain__c = testAccount1.Email_Domain__c;
        testSupplier.LastName__c = supplier1Contact.LastName;
        testSupplier.FirstName__c = supplier1Contact.FirstName;
        testSupplier.IsGeneric__c = false;
        insert testSupplier;
        // Existing Contact with P21 account linked
        supplier1Contact.P21_Account_Details__c = testP21Account.ID;
        supplier1Contact.P21_ContactID__c = 'A1265';
        update supplier1Contact;

        Ops_Order__c o = new Ops_Order__c();
        o.XometryOpsOrderId__c = 'A1112-34567';
        o.Name = 'A1112-34567';
        insert o;
        //Create testJobs;
        System.debug('Staring the job creation');
        List<Job__C> jobsList = new List<Job__C>();
        Job__C testJob1 = new Job__C();
        testJob1.XometryJobID__c = 'J00334';
        testJob1.XometryOpsOrderID__c = 'A1112-34567';
        testJob1.Name = 'Job 1 Big Axe';
        testJob1.AcceptedDateTime__c = DateTime.now();
        testJob1.OrderDueDate__c = Date.today() + 7;
        testJob1.AcceptedPartnerID__c = 'P1223';
        testJob1.AcceptedPrice__c = 500.35;
        testJob1.Supplier__c = testSupplier.ID;
        testJob1.OrderID__c = o.ID;
        testJob1.Stage__C = 'Accepted';
        jobsList.add(testJob1);
        Job__C testJob2 = new Job__C();
        testJob2.XometryJobID__c = 'J00335';
        testJob2.XometryOpsOrderID__c = 'A1112-34567';
        testJob2.Name = 'Job 2 Bigger Axe';
        testJob2.AcceptedDateTime__c = DateTime.now();
        testJob2.OrderDueDate__c = Date.today() + 7;
        testJob2.AcceptedPartnerID__c = 'P1223';
        testJob2.AcceptedPrice__c = 500.35;
        testJob2.Supplier__c = testSupplier.ID;
        testJob2.OrderID__c = o.ID;
        testJob2.Stage__C = 'Accepted';
        jobsList.add(testJob2);
        insert jobsList;
        ID testJobMatchID = jobsList[0].Id;
        Set<ID> jobsIDSET = new Set<ID>();
        for (Job__C job : jobsList) {
            jobsIDSET.add(job.ID);
        }
        List<Opportunity> testOppListJobStart = [
            SELECT ID, AccountID, JobId__c, Primary_Contact__c, Primary_Supplier__c, OwnerID, P21_Account_Details__c
            FROM Opportunity
            WHERE JobId__c IN :jobsIDSET
        ];
        //
        System.assertEquals(2, testOppListJobStart.size(), 'We did not have 2 opps for the 2 jobs');
        Opportunity testJobOpp1 = [SELECT ID, AccountId, JobId__C FROM Opportunity WHERE JobID__C = :testJobMatchID][0];
        List<Case> manQuoteCaseList = new List<Case>();
        Case manQuoteCase = new Case();
        manQuoteCase.RecordTypeID = caseSuppliesRecordTypeId;
        manQuoteCase.Shadow_P21_Quote_Id__c = 'OE23477';
        manQuoteCase.Subject = 'Looking for lots of good Aluminium';
        manQuoteCase.Origin = 'Manual';
        manQuoteCase.Type = 'RFQ-Quote';
        manQuoteCase.ownerId = rRouter1.User__c;
        //The Opp is left blank intentionally with the assumption that the rep forgot to add it.
        manQuoteCaseList.add(manQuoteCase);

        insert manQuoteCaseList;

        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = manQuoteCase.Shadow_P21_Quote_Id__c;
        sQuoteTest.XometryJobID__c = testJob1.XometryJobID__c;
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.SFP_FLAG__C = true;
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;

        test.startTest();
        //Create an Sorder for quote above link it to Job1
        insert sQuoteTest;
        test.stopTest();
        //The Case should be linked to the JobOpportunity
        List<Case> testCaseResult = [
            SELECT ID, Opportunity__c
            FROM Case
            WHERE Shadow_P21_Quote_Id__c = :manQuoteCase.Shadow_P21_Quote_Id__c
        ];
        System.assertEquals(
            testCaseResult[0].Opportunity__c,
            testJobOpp1.ID,
            'The Case did not get linked to the right Opp'
        );
        // The testJobOpp should include the Order and Quote from above and be closed won
        Opportunity testOppFinal = [
            SELECT Id, Stagename, JobId__c, Shadow_JobId__c, Quote_ERP_XOM_CREATE_ID__c, Last_Quote_Xometry_ERP_ID__c
            FROM Opportunity
            WHERE id = :testJobOpp1.ID
        ][0];
        System.assertEquals(testOppFinal.JobId__C, testJobMatchID, 'The Opp was not linked to the correct Job');
        System.assertEquals(testOppFinal.Shadow_JobId__c, sQuoteTest.XometryJobID__c, 'The XomJobs did not match');
        System.assertEquals(
            testOppFinal.Quote_ERP_XOM_CREATE_ID__c,
            sQuoteTest.P21_ERP_ID__c,
            'The original quote did not match'
        );

        List<AggregateResult> countOppsPostTestResult = [SELECT count(ID) FROM Opportunity];
        // The total Opportunities in the system should be 2
        System.assertEquals(
            2,
            integer.valueof(countOppsPostTestResult[0].get('expr0')),
            'There were not exactly 2 opps'
        );
    }

    @isTest
    static void validateNotDuplicateAccount() {
        List<Supplies_Quote__C> sQuoteTestList = new List<Supplies_Quote__C>();

        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.PartnerID__c = 'P33465';
        sQuoteTest.Is_Generic__c = true;
        sQuoteTest.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest.P21_Contact_Phone__c = '5553334444';
        sQuoteTest.P21_OE_Status__c = 'Active';
        sQuoteTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest.P21_Physical_Country__c = 'United States';
        sQuoteTest.P21_Physical_State__c = 'Maryland';
        sQuoteTest.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest.SFP_FLAG__C = true;
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        sQuoteTestList.add(sQuoteTest);

        Supplies_Quote__C sQuoteTest2 = new Supplies_Quote__C();
        sQuoteTest2.P21_ContactID__c = 'A1265';
        sQuoteTest2.P21_CustomerID__c = 'CA144';
        sQuoteTest2.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest2.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest2.PartnerID__c = 'P33465';
        sQuoteTest2.Is_Generic__c = true;
        sQuoteTest2.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest2.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest2.P21_Contact_Phone__c = '5553334444';
        sQuoteTest2.P21_OE_Status__c = 'Active';
        sQuoteTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest2.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest2.P21_Physical_Country__c = 'United States';
        sQuoteTest2.P21_Physical_State__c = 'Maryland';
        sQuoteTest2.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest2.SFP_FLAG__C = true;
        sQuoteTest2.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest2.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest2.Quote_Price__c = 500.50;
        sQuoteTestList.add(sQuoteTest2);

        test.startTest();
        insert sQuoteTestList;
        test.stopTest();

        Opportunity resultOpp1 = [
            SELECT ID, JobID__C, Shadow_JobId__c, AccountId
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sQuoteTest.P21_Order_OE_ERP_ID__C
        ];

        Opportunity resultOpp2 = [
            SELECT ID, JobID__C, Shadow_JobId__c, AccountId
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sQuoteTest2.P21_Order_OE_ERP_ID__C
        ];

        List<Account> lstAcc = [SELECT Email_Domain__C FROM Account];

        system.assertEquals(1, lstAcc.size(), 'Duplicate Account');
        system.assertEquals('bobsmith21@gmail.com', lstAcc[0].Email_Domain__C, 'Email domain Account did not match');
        system.assertEquals(resultOpp1.AccountId, resultOpp2.AccountId, 'The Opportunities Accounts did not match');
    }
}