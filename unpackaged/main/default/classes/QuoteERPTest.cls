@isTest
public class QuoteERPTest {
    static final String WEST_COAST_BDR = [
        SELECT UserOrGroupId
        FROM GroupMember
        WHERE GroupID = :AppConstants.WEST_COAST_BDR_GROUP
        LIMIT 1
    ]
    .UserOrGroupId;

    @TestSetup
    private static void setup() {
        //Empty Opportunity on Contact
        List<Account> newAccountList = TestDataFactory.createTestAccountNonGenericsStaffUser(5, 'AM', 1);

        Account testAccount = newAccountList[0];
        Account acc1 = newAccountList[1];
        Account acc2 = newAccountList[2];
        Id lOwnerID = acc2.ownerID;
        String testDomain = testAccount.Email_Domain__c;

        List<Account> newAccountListBR = TestDataFactory.createTestAccountNonGenerics(5, 'BDR', 1, 5);
    }

    //Test for all Manufacturing processes on Existing Account and Contact with new Contact no BDR
    @isTest
    static void singleQuotetest2() {
        List<Account> acctBeforeList = [
            SELECT Id, OwnerId
            FROM Account
            WHERE Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
        ];
        Account a = acctBeforeList[2];

        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.process_isCarbon__c = false;
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        Test.startTest();
        insert myQuote;
        Test.stopTest();

        List<Quote_ERP__C> QuoteList = [SELECT ID, Name, OwnerID, AccountID__C FROM Quote_ERP__C];
        List<Account> accountList = [
            SELECT ID, OwnerId, Account_Owner_Type__c, Email_Domain__c
            FROM Account
            ORDER BY name
        ];
        List<Contact> contactList = [
            SELECT Phone, Name, Xometry_ERP_Contact_ID__c
            FROM Contact
            WHERE Xometry_ERP_Contact_ID__c = :myQuote.ERP_Contact__c
        ];
        Quote_ERP__C q = QuoteList[0];
        System.assertEquals(a.ownerID, q.OwnerID);
        System.assertEquals(a.ID, q.AccountID__c);
    }

    //Test for Existing Account Generic
    @isTest
    static void createNewQuote_existingAccountGeneric_noOpp() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.IS_Generic__c = true;
        myQuote.process_isCarbon__c = false;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2019, 6, 14);
        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__C retrievedQuote = [SELECT OpportunityID__C FROM Quote_ERP__C WHERE ID = :myQuote.ID][0];
        ID newOppId = retrievedQuote.OpportunityID__C;
        System.assert(String.isblank(newOppId), 'Did not assign Opp to old Quote');
    }

    @isTest
    static void createNewQuote_existingAccountGeneric_Opp() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.IS_Generic__c = true;
        myQuote.process_isCarbon__c = false;

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__C retrievedQuote = [SELECT OpportunityID__C FROM Quote_ERP__C WHERE ID = :myQuote.ID][0];
        ID newOppId = retrievedQuote.OpportunityID__C;
        System.assert(!String.isblank(newOppId), 'Did not assign Opp to Quote');
    }

    // Old Test for Existing Generic Lead and that new Quote should not create a new Lead
    // Quote Routing Update -- Should now create 1 Contact and 2 Opportunities
    @isTest
    static void singleQuotetest4() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 3, 30, 0);
        insert myQuote;
        Quote_ERP__C firstQuote = [
            SELECT ID, OpportunityID__C, ContactID__C
            FROM Quote_ERP__C
            WHERE ID = :myQuote.ID
            LIMIT 1
        ];

        //Part Update
        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(false);
        myQuote2.Xometry_ERP_ID__C = 'Q12-3333-5555';
        myQuote2.ERP_PartPK__c = 'A1234-A5679';
        myQuote2.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 4, 0, 0);

        Test.startTest();
        insert myQuote2;
        Test.stopTest();
        Quote_ERP__C secondQuote = [
            SELECT ID, OpportunityID__C, ContactID__C
            FROM Quote_ERP__C
            WHERE ID = :myQuote2.ID
            LIMIT 1
        ];

        //Count Number of Contacts
        Integer lcount;
        AggregateResult[] myAggResults = [SELECT Count_Distinct(ContactID__C) myCount FROM Quote_ERP__C];
        for (AggregateResult aggres : myAggResults) {
            lcount = Integer.valueOf(String.valueOf(aggres.get('myCount')));
        }
        System.assertEquals(1, lcount);
        System.assertEquals(firstQuote.ContactID__C, secondQuote.ContactID__C, 'We Created Two Contacts!');
        AggregateResult[] myAggResults2 = [SELECT Count_Distinct(OpportunityID__C) myCount FROM Quote_ERP__C];
        for (AggregateResult aggres : myAggResults2) {
            lcount = Integer.valueOf(String.valueOf(aggres.get('myCount')));
        }
        System.assertEquals(2, lcount, 'The Opportunities created was not 2');
    }

    //Test for Existing Non Generic Contact and that new Quote should not create a new Contact Same Load
    @isTest
    static void singleQuotetest5b() {
        List<Quote_ERP__C> newQuoteList = new List<Quote_ERP__C>();
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-1111';
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 3, 30, 0);
        newQuoteList.add(myQuote);

        //Part Update
        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(false);
        myQuote2.Xometry_ERP_ID__C = 'Q12-3333-2222';
        myQuote2.ERP_PartPK__c = 'A1234-A5679';
        myQuote2.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 4, 0, 0);
        newQuoteList.add(myQuote2);

        Test.startTest();
        insert newQuoteList;
        Test.stopTest();

        //Count Number of Leads
        Integer lcount;
        AggregateResult[] myAggResults = [SELECT Count_Distinct(ContactID__C) myCount FROM Quote_ERP__C];
        for (AggregateResult aggres : myAggResults) {
            lcount = Integer.valueOf(String.valueOf(aggres.get('myCount')));
        }
        Integer lcount2 = [SELECT COUNT() FROM Quote_ERP__C];
        System.assertEquals(1, lcount, 'There should be One Contact');
        System.assertEquals(2, lcount2, 'There should be Two Quotes!');
    }

    //Test for Existing Generic Lead and that new Quote should still create Opps
    @isTest
    static void insertQuotes_createDistinctOpps() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 3, 30, 0);
        insert myQuote;

        //Part Update
        List<Quote_ERP__C> newQuoteList = new List<Quote_ERP__C>();

        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(false);
        myQuote2 = TestDataFactory.setTrueProcessFieldsQuote(myQuote2);
        myQuote2.Xometry_ERP_ID__C = 'Q12-3333-5555';
        myQuote2.ERP_PartPK__c = 'A1234-A5679';
        myQuote2.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 4, 0, 0);
        newQuoteList.add(myQuote2);

        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(false);
        myQuote3 = TestDataFactory.setTrueProcessFieldsQuote(myQuote3);
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-6666';
        myQuote3.ERP_PartPK__c = 'A1234-A5679';
        myQuote3.ERP_Contact_First_Name__c = 'John';
        myQuote3.ERP_Contact_Last_Name__c = 'Doe';
        myQuote3.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote3.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 4, 5, 50);
        newQuoteList.add(myQuote3);

        Test.startTest();
        insert newQuoteList;
        Test.stopTest();

        //Count Number of Leads
        Integer lcount;
        AggregateResult[] myAggResults = [SELECT Count_Distinct(OpportunityID__C) myCount FROM Quote_ERP__C];
        for (AggregateResult aggres : myAggResults) {
            lcount = Integer.valueOf(String.valueOf(aggres.get('myCount')));
        }
        System.assertEquals(3, lcount);
    }

    //Test for Existing Generic Lead and that new Quote should not create a new Lead Further information
    @isTest
    static void singleQuotetest6b() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 3, 30, 0);
        insert myQuote;

        //Part Update
        List<Quote_ERP__C> newQuoteList = new List<Quote_ERP__C>();
        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(false);
        myQuote2 = TestDataFactory.setTrueProcessFieldsQuote(myQuote2);
        myQuote2.Xometry_ERP_ID__C = 'Q12-3333-5555';
        myQuote2.ERP_PartPK__c = 'A1234-A5679';
        myQuote2.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 4, 0, 0);
        newQuoteList.add(myQuote2);

        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(false);
        myQuote3 = TestDataFactory.setTrueProcessFieldsQuote(myQuote3);
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-6666';
        myQuote3.ERP_PartPK__c = 'A1234-A5679';
        myQuote3.ERP_Contact_First_Name__c = 'John';
        myQuote3.ERP_Contact_Last_Name__c = 'Doe';
        myQuote3.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote3.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 4, 5, 50);
        newQuoteList.add(myQuote3);

        Test.startTest();
        insert newQuoteList;
        Test.stopTest();
        //Count Number of Leads
        Integer lcount;
        AggregateResult[] myAggResults = [SELECT Count_Distinct(ContactID__C) myCount FROM Quote_ERP__C];
        for (AggregateResult aggres : myAggResults) {
            lcount = Integer.valueOf(String.valueOf(aggres.get('myCount')));
        }
        System.assertEquals(1, lcount);
    }

    @isTest
    static void singleQuoteTest7() {
        //Empty Opportunity on Contact
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        //Create a an Opportunity on the Contact
        Opportunity newOpp = new Opportunity();
        newOpp.Primary_Contact__c = c.ID;
        newOpp.Name = 'TestOpp45';
        newOpp.AccountID = c.AccountID;
        newOpp.OwnerID = c.OwnerID;
        newOpp.Amount = 50.55;
        newOpp.Description = 'New Customer first Order!';
        newOpp.LeadSource = 'Website';
        newOpp.CloseDate = Date.newInstance(2021, 8, 27);
        newOpp.Stagename = 'Qualification Needed';
        insert newOpp;

        //Test Data
        Quote_ERP__c myQuote = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote = TestDataFactory.setTrueProcessFieldsQuote(myQuote);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 28, 4, 5, 50);
        myQuote.process_isUrethane_Casting__c = false;
        Test.StartTest();
        insert myQuote;
        Test.stopTest();

        //Check
        Quote_ERP__C myQuote2 = [SELECT ID, OpportunityID__C FROM Quote_ERP__C WHERE ID = :myQuote.ID][0];
        System.assertEquals(newOpp.ID, myQuote2.OpportunityID__C, 'Opportunity Ids did not match!');
    }

    @isTest
    static void insertNewQuote_OppReferencesCorrectQuote() {
        //Test Existing BDR Account Contact with Existing Quote. Then Add Two New Quotes for BDR
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'BDR'
            ORDER BY Id ASC
            LIMIT 1
        ];

        //Create a Quote
        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';
        insert myQuote3;

        Quote_ERP__C myTestQuote = [SELECT ID, OpportunityID__C FROM Quote_ERP__C WHERE ID = :myQuote3.ID][0];

        List<Quote_ERP__C> insertQuoteTestList = new List<Quote_ERP__C>();
        Quote_ERP__c myQuote4 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote4.Xometry_ERP_ID__C = 'Q12-3333-5555';
        myQuote4.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 27, 13, 5, 40);
        insertQuoteTestList.add(myQuote4);

        //Multi Quotes with the Same Parts
        Quote_ERP__c myQuote5 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote5 = TestDataFactory.setTrueProcessFieldsQuote(myQuote5);
        myQuote5.Xometry_ERP_ID__C = 'Q12-3333-6666';
        myQuote5.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 27, 13, 6, 40);
        insertQuoteTestList.add(myQuote5);

        Test.StartTest();
        insert insertQuoteTestList;
        Test.StopTest();
        //Check that Opportunity is has last Quote assigned correctly
        Opportunity resultOpp = [
            SELECT ID, Last_Quote_Xometry_ERP_ID__c, Quote_ERP_XOM_CREATE_ID__c
            FROM Opportunity
            WHERE ID = :myTestQuote.OpportunityID__C
            LIMIT 1
        ];
        System.assertEquals('Q12-3333-4444', resultOpp.Last_Quote_Xometry_ERP_ID__c, 'One to One Opp to Quote');
        System.assertEquals('Q12-3333-4444', resultOpp.Quote_ERP_XOM_CREATE_ID__c);
    }

    @isTest
    static void singleQuoteTest9() {
        //Test Existing BDR Account Contact with Existing Quote Opp. Then new Quote should reopen Opportunity
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'BDR'
            ORDER BY Id ASC
            LIMIT 1
        ];

        List<Quote_ERP__C> insertQuoteTestList = new List<Quote_ERP__C>();
        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';

        Test.StartTest();
        insert myQuote3;
        Test.StopTest();

        Quote_ERP__C myTestQuote = [SELECT ID, OpportunityID__C FROM Quote_ERP__C WHERE ID = :myQuote3.ID][0];
    }

    // Create Account. Then Create a Lead with that domain and a Quote. Ensure Lead is Converted
    @isTest
    static void leadThenQuoteAMTest1() {
        //Test Contact is John Doe
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
        testLead.Email = 'BobBuilder1@' + c.Account.Email_Domain__c;
        testLead.LeadSource = 'Lead Gen';
        testLead.Email_Domain__c = c.Account.Email_Domain__c;
        insert testLead;

        //Lead Quotes
        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            testLead.FirstName,
            testLead.LastName + '1',
            testLead.email
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';

        test.StartTest();
        insert myQuote3;
        test.StopTest();

        Lead convertedLead = [SELECT isConverted FROM Lead WHERE ID = :testLead.ID];
        System.assertEquals(true, convertedLead.isConverted, 'The Lead was not converted');
        Integer numofContonAccount = [SELECT COUNT() FROM Contact WHERE AccountID = :c.AccountId];
        System.assertEquals(2, numofContonAccount, 'The contacts did not macth');
    }

    @isTest
    static void leadThenQuoteBDRTest1() {
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'BDR'
            ORDER BY Id ASC
            LIMIT 1
        ];

        //Creating Lead
        Lead testLead = new Lead();
        testLead.Email_Domain__c = c.Account.Email_Domain__c;
        testLead.Email = 'BobBuilder1@' + c.Account.Email_Domain__c;
        testLead.Company = c.Account.Name;
        testLead.FirstName = 'Bob';
        testLead.LastName = 'Builder';
        testLead.LeadSource = 'Lead Gen';
        insert testLead;

        //Lead Quotes
        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            testLead.FirstName,
            testLead.LastName + '1',
            testLead.email
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';

        test.StartTest();
        insert myQuote3;
        test.StopTest();

        Lead convertedLead = [SELECT isConverted FROM Lead WHERE ID = :testLead.ID];
        System.assertEquals(true, convertedLead.isConverted, 'The Lead was not converted');
        Integer numofContonAccount = [SELECT COUNT() FROM Contact WHERE AccountID = :c.AccountId];
        System.assertEquals(2, numofContonAccount, 'The contacts did not macth');
    }

    //Test Update logic for ERP Phone Numbers
    @isTest
    static void updateERPPhoneTest() {
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'BDR'
            ORDER BY Id ASC
            LIMIT 1
        ];

        List<Quote_ERP__C> insertQuoteTestList = new List<Quote_ERP__C>();
        //Create a Quote
        Quote_ERP__c myQuote1 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote1.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote1.ERP_Contact_Phone__C = '4447778888';
        insert myQuote1;

        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote2.Xometry_ERP_ID__C = 'Q12-3333-5555';
        myQuote2.ERP_PartPK__c = 'A1234-A5680';
        myQuote2.Quote_Price__c = 5006;
        myQuote2.ERP_Contact_Phone__C = '5557778888';

        Test.startTest();
        insert myQuote2;
        Test.stopTest();

        Contact testContactChange = [SELECT ID, Name, ERP_CONTACT_PHONE__C FROM Contact WHERE ID = :c.Id];
        String testPhone = testContactChange.ERP_CONTACT_PHONE__C;
        System.assertEquals(testPhone, myQuote2.ERP_Contact_Phone__C);
    }

    @isTest
    static void updateERPAddressConTest() {
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'BDR'
            ORDER BY Id ASC
            LIMIT 1
        ];

        ID testAccountID = c.AccountID;
        List<Quote_ERP__C> insertQuoteTestList = new List<Quote_ERP__C>();
        //Create a Quote
        Quote_ERP__c myQuote1 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote1.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote1.ERP_Contact_Phone__C = '4447778888';
        myQuote1.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote1.ERP_Billing_City__c = 'Greenbelt';
        myQuote1.ERP_Billing_Country__c = 'United States';
        myQuote1.ERP_Billing_State_or_Province__c = 'Maryland';
        myQuote1.ERP_Billing_Zip_Code__c = '20770';
        myQuote1.ERP_Shipping_Address__c = '2 Unit E Northway';
        myQuote1.ERP_Shipping_City__c = 'Greenbelt';
        myQuote1.ERP_Shipping_Country__c = 'United States';
        myQuote1.ERP_Shipping_State_or_Province__c = 'Maryland';
        myQuote1.ERP_Shipping_Zip_Code__c = '20770';
        insert myQuote1;

        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        myQuote2.Xometry_ERP_ID__C = 'Q12-3333-5555';
        myQuote2.ERP_PartPK__c = 'A1234-A5680';
        myQuote2.Quote_Price__c = 5006;
        myQuote2.ERP_Contact_Phone__C = '5557778888';
        myQuote2.ERP_Billing_Address__c = '2 Unit F Northway';
        myQuote2.ERP_Billing_City__c = 'Bowie';
        myQuote2.ERP_Billing_Country__c = 'Mexico';
        myQuote2.ERP_Billing_State_or_Province__c = 'Chiapas';
        myQuote2.ERP_Billing_Zip_Code__c = '20770';
        myQuote2.ERP_Shipping_Address__c = 'Made Up Avenue';
        myQuote2.ERP_Shipping_City__c = 'Hollywood';
        myQuote2.ERP_Shipping_Country__c = 'United States';
        myQuote2.ERP_Shipping_State_or_Province__c = 'California';
        myQuote2.ERP_Shipping_Zip_Code__c = '20990';

        Test.startTest();
        insert myQuote2;
        Test.stopTest();

        Contact testContactChange = [SELECT ID, Name, ERP_CONTACT_PHONE__C FROM Contact WHERE ID = :c.Id];
        String testPhone = testContactChange.ERP_CONTACT_PHONE__C;
        System.assertEquals(testPhone, myQuote2.ERP_Contact_Phone__C);
        Contact testContact = [
            SELECT
                ID,
                Name,
                AccountID,
                Xometry_ERP_Contact_ID__c,
                ERP_Shipping_Address__c,
                ERP_Shipping_City__c,
                ERP_Shipping_Country__c,
                ERP_Shipping_State_or_Province__c,
                ERP_Shipping_Zip_Code__c
            FROM Contact
            WHERE ID = :c.Id
        ];
        String retConTest_Shipping_Address = testContact.ERP_Shipping_Address__c;
        String retConTest_Shipping_City = testContact.ERP_Shipping_City__c;
        String retConTest_Shipping_Country = testContact.ERP_Shipping_Country__c;
        String retConTest_Shipping_State = testContact.ERP_Shipping_State_or_Province__c;
        String retConTest_Shipping_Zip_Code = testContact.ERP_Shipping_Zip_Code__c;
        System.assertequals(
            retConTest_Shipping_Address,
            myQuote2.ERP_Shipping_Address__c,
            'The addresses did not match'
        );

        //Test the Address Changes on Account only first quote should update
        Account testAccountPost = [
            SELECT
                ID,
                Name,
                ERP_Billing_Address__c,
                ERP_Billing_City__c,
                ERP_Billing_Country__c,
                ERP_Billing_State_or_Province__c,
                ERP_Billing_Zip_Code__c
            FROM Account
            WHERE ID = :c.AccountId
        ];

        String retAcctTest_Billing_Address = testAccountPost.ERP_Billing_Address__c;
        String retAcctTest_Billing_City = testAccountPost.ERP_Billing_City__c;
        String retAcctTest_Billing_Country = testAccountPost.ERP_Billing_Country__c;
        String retAcctTest_Billing_State_or_Provinces = testAccountPost.ERP_Billing_State_or_Province__c;
        String retAcctTest_Billing_Zipcode = testAccountPost.ERP_Billing_Zip_Code__c;

        System.assertEquals(
            retAcctTest_Billing_Address,
            myQuote1.ERP_Billing_Address__c,
            'The addresses did not match'
        );
        System.assertEquals(retAcctTest_Billing_City, myQuote1.ERP_Billing_City__c, 'The cities did not match');
        System.assertEquals(
            retAcctTest_Billing_Country,
            myQuote1.ERP_Billing_Country__c,
            'The countries did not match'
        );
        System.assertEquals(
            retAcctTest_Billing_State_or_Provinces,
            myQuote1.ERP_Billing_State_or_Province__c,
            'The state or province did not match'
        );
        System.assertEquals(
            retAcctTest_Billing_Zipcode,
            myQuote1.ERP_Billing_Zip_Code__c,
            'The zipcodes did not match'
        );
    }

    @isTest
    static void leadthenQuote() {
        //Create Lead
        String testDomain = 'factorysails.edu';
        Lead testLead = new Lead();
        testLead.Company = 'Factory Sails';
        testLead.FirstName = 'Bob';
        testLead.LastName = 'Builder';
        testLead.Email = 'BobBuilder1@' + testDomain;
        testLead.LeadSource = 'Lead Gen';
        testLead.Email_Domain__c = testDomain;
        insert testLead;

        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            testDomain,
            testLead.FirstName,
            testLead.LastName + '1',
            testLead.email
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';

        test.startTest();
        insert myQuote3;
        test.stopTest();

        Lead convertedLead = [SELECT isConverted FROM Lead WHERE ID = :testLead.ID];
        System.assertEquals(true, convertedLead.isConverted, 'The Lead was not converted');
        Quote_ERP__C postInsertQuote = [SELECT ContactID__R.LastName FROM Quote_ERP__C WHERE ID = :myQuote3.ID];
        System.assertEquals(
            myQuote3.ERP_Contact_Last_Name__c,
            postInsertQuote.ContactID__R.LastName,
            'The contacts name did not macth'
        );
    }

    @isTest
    static void leadthenQuoteTest2() {
        //Lead then Quote same domain different email
        //Create Lead
        String testDomain = 'factorysails.edu';
        Lead testLead = new Lead();
        testLead.Company = 'Factory Sails';
        testLead.FirstName = 'Bob';
        testLead.LastName = 'Builder';
        testLead.Email = 'BobBuilder1@' + testDomain;
        testLead.LeadSource = 'Lead Gen';
        testLead.Email_Domain__c = testDomain;
        insert testLead;

        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            testDomain,
            testLead.FirstName,
            'Francis',
            'BobFrancis@' + testDomain
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';

        test.startTest();
        insert myQuote3;
        test.stopTest();

        Lead convertedLead = [SELECT isConverted FROM Lead WHERE ID = :testLead.ID];
        System.assertEquals(false, convertedLead.isConverted, 'The Lead was converted! Fail!');
        Quote_ERP__C postInsertQuote = [SELECT ContactID__R.LastName FROM Quote_ERP__C WHERE ID = :myQuote3.ID];
        System.assertEquals(
            myQuote3.ERP_Contact_Last_Name__c,
            postInsertQuote.ContactID__R.LastName,
            'The contacts name did not macth'
        );
        Integer numContact = [SELECT COUNT() FROM Contact WHERE Name = 'Bob Francis'];
        System.assertEquals(1, numContact, 'More than 1 Contact was created');
    }

    @isTest
    static void leadthenQuoteTest3() {
        //expected 2 contacts and 2 Opportunites
        // Lead then quote different email same domain and then lead quotes
        Set<ID> testQuoteIdSet = new Set<ID>();

        //Create Lead
        String testDomain = 'factorysails.edu';

        Lead testLead = new Lead();
        testLead.Company = 'Factory Sails';
        testLead.FirstName = 'Bob';
        testLead.LastName = 'Builder';
        testLead.Email = 'BobBuilder1@' + testDomain;
        testLead.LeadSource = 'Lead Gen';
        testLead.Email_Domain__c = testDomain;
        insert testLead;

        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            testDomain,
            testLead.FirstName,
            'Francis',
            'BobFrancis@' + testDomain
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';
        insert myQuote3;
        testQuoteIdSet.add(myQuote3.ID);

        Quote_ERP__c myQuote4 = TestDataFactory.createQuote(
            false,
            testDomain,
            testLead.FirstName,
            testLead.LastName + '1',
            testLead.email
        );
        myQuote4.Xometry_ERP_ID__C = 'Q12-3333-5555';

        test.startTest();
        insert myQuote4;
        testQuoteIdSet.add(myQuote4.ID);
        test.stopTest();

        Lead convertedLead = [SELECT isConverted, ConvertedAccountId FROM Lead WHERE ID = :testLead.ID];
        System.assertEquals(true, convertedLead.isConverted, 'The Lead was not converted');
        integer NumOpp = [SELECT COUNT() FROM Opportunity WHERE AccountId = :convertedLead.ConvertedAccountId];
        integer NumCont = [SELECT COUNT() FROM Contact WHERE AccountId = :convertedLead.ConvertedAccountId];
        integer NumAcct = [SELECT COUNT() FROM Account WHERE Id = :convertedLead.ConvertedAccountId];
        List<Quote_ERP__C> myQuoteList = [
            SELECT ContactID__C, ContactID__R.Name, Quote_Email__c, OpportunityID__R.Name, OpportunityID__C
            FROM Quote_ERP__C
            WHERE ID IN :testQuoteIdSet
        ];

        System.assertEquals(2, NumOpp, 'Wrong Opps');
        System.assertEquals(2, NumCont, 'Wrong Contacts');
        System.assertEquals(1, NumAcct, 'Wrong Accounts');
    }

    @isTest
    static void postQuoteOppCreateTest() {
        //Empty Opportunity on Contact
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        //Create a Quote with AM account
        Quote_ERP__C originQuote = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        originQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        originQuote.process_isUrethane_Casting__c = false;
        insert originQuote;

        //Create an Order with AM account
        Order_ERP__C myFirstOrder = new Order_ERP__C();
        myFirstOrder.Account_Domain__c = originQuote.Account_Domain__C;
        myFirstOrder.ERP_Contact_First_Name__c = originQuote.ERP_Contact_First_Name__c;
        myFirstOrder.ERP_Contact_Last_Name__c = originQuote.ERP_Contact_Last_Name__c;
        myFirstOrder.ERP_Contact__C = originQuote.ERP_Contact__C;
        myFirstOrder.ERP_PartPk__c = originQuote.ERP_PartPK__c;
        myFirstOrder.Is_Generic__c = originQuote.IS_Generic__c;
        myFirstOrder.Order_Canceled_Flag__c = false;
        myFirstOrder.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 27);
        myFirstOrder.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 27, 14, 0, 30);
        myFirstOrder.Order_Email__c = originQuote.Quote_Email__c;
        myFirstOrder.Order_Subtotal__c = 4500.00;
        myFirstOrder.Order_Total__c = 5000.50;
        myFirstOrder.Payment_Type__c = 'credit_card';
        myFirstOrder.Xometry_Quote_ID__c = originQuote.Xometry_ERP_ID__C;
        myFirstOrder.Xometry_ERP_ID__c = 'AAAAA-00001';
        myFirstOrder.process_isDMLS__c = true;
        insert myFirstOrder;

        //Create a Quote on Account with Order. Validate OpportunityID is Blank
        Quote_ERP__C secondQuote = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.email
        );
        secondQuote.Account_Domain__c = originQuote.Account_Domain__C;
        secondQuote.Xometry_ERP_ID__C = 'Q12-3333-5555';
        secondQuote.ERP_PartPK__c = 'A1234-A5680';
        secondQuote.Quote_Price__c = 0;
        secondQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 8, 28);
        secondQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 8, 28, 13, 0, 40);
        secondQuote.process_isCNC_Machining__c = true;
        secondQuote.process_isUrethane_Casting__c = false;

        Test.startTest();
        insert secondQuote;

        Quote_ERP__C checkQuote = [SELECT OpportunityID__C FROM Quote_ERP__C WHERE ID = :secondQuote.ID];
        secondQuote.Quote_Price__c = 3500;

        //Check that the Opportunity does not exists
        update secondQuote;
        Test.stopTest();

        // Now Update Quote Price and the status
        Quote_ERP__C resultQuote = [
            SELECT ID, OpportunityID__C, ContactID__R.Has_Ordered__c
            FROM Quote_ERP__C
            WHERE ID = :secondQuote.ID
        ];
        System.assertEquals(false, String.isblank(resultQuote.OpportunityID__C), 'Did not create Opportunity');
    }

    @isTest
    static void oppOn2DCreationAM() {
        //This test creates an AM Account that has ordered
        //We then create a Direct Source(2D) Quote and we should still have an opportunity created for the Direct Source Quote
        //Create an AM Account
        //Create an Order on the AM Account
        Contact myretContact = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];
        ID myretContactID = myretContact.ID;
        List<Order_ERP__C> preTestOrderList = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = myretContact.Account.Email_Domain__c;
        ord.ERP_Company_Name__C = myretContact.Account.Name;
        ord.ERP_Contact_First_Name__c = myretContact.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.Xometry_Quote_ID__c = 'Q12-3333-4444';
        ord.process_isPolyJet_3D__c = true;
        preTestOrderList.add(ord);
        //Create a Direct Source quote and confirm the Opportunity creation
        insert preTestOrderList;

        Quote_ERP__C testDSQuote = new Quote_ERP__C();
        testDSQuote.line_of_business__c = 'Marketplace';
        testDSQuote.Xometry_ERP_ID__C = 'R43A1DB';
        testDSQuote.bid_due_date__c = Date.newInstance(2021, 7, 30);
        testDSQuote.ERP_Status__C = 'Active';
        testDSQuote.erp_user_company_name__c = myretContact.Account.Name;
        testDSQuote.Account_Domain__C = myretContact.Account.Email_Domain__c;
        testDSQuote.ERP_Contact__c = 'BBBBB';
        testDSQuote.Quote_Email__c = myretContact.Email;
        testDSQuote.Quote_Count__C = 1;
        testDSQuote.order_time_flag__c = false;
        testDSQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        testDSQuote.Quote_ERP_Created_Time__c = DateTime.newInstance(2021, 6, 14, 5, 30, 0);

        Test.startTest();
        insert testDSQuote;
        Test.stopTest();

        List<Opportunity> testOpp = [
            SELECT ID, OwnerID, Primary_Contact__c, AccountID, Quote_ERP_XOM_CREATE_ID__c, Last_Quote_Xometry_ERP_ID__c
            FROM Opportunity
            WHERE Quote_ERP_XOM_CREATE_ID__c = :'R43A1DB'
        ];
        Quote_ERP__C resultQuote = [
            SELECT ID, Xometry_ERP_ID__C, OpportunityID__c
            FROM QUOTE_ERP__C
            WHERE Xometry_ERP_ID__C = :'R43A1DB'
            LIMIT 1
        ];
        Boolean resultQuoteOpp = !String.isBlank(resultQuote.OpportunityID__c);

        System.assertEquals(
            testOpp[0].Quote_ERP_XOM_CREATE_ID__c,
            'R43A1DB',
            'The Opportunity was not created from the RFQ'
        );
        System.assertEquals(resultQuoteOpp, true, 'No Opportunity Created');
    }
    @isTest
    static void mulitQuotesNoPartTest() {
        //This test class is put in place to ensure a bug related to multiple quotes with no parts at same transaction time with differen AM accounts
        //The Quotes and their opportunities should have a matching contact
        //Data setup create two 2 AM accounts and create an Order for each one so the quotes bypass the AM contact has not ordered logic
        //To properly test need to create 6 quotes with no parts with 3 quotes each assigned to each account
        List<Account> newAccountList = [
            SELECT Id, Email_Domain__c, Name
            FROM Account
            WHERE Account_Owner_Type__c = 'AM'
        ];
        Account testAccount1 = newAccountList[0];
        ID testAccount1ID = testAccount1.ID;
        Account testAccount2 = newAccountList[1];
        ID testAccount2ID = testAccount2.ID;
        Contact myretContact1 = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccount1ID
            ORDER BY Name
            LIMIT 1
        ];
        Contact myretContact2 = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccount2ID
            ORDER BY Name
            LIMIT 2
        ];

        //Create two Orders
        List<Order_ERP__C> preTestOrderList = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = testAccount1.Email_Domain__c;
        ord.ERP_Company_Name__C = testAccount1.Name;
        ord.ERP_Contact_First_Name__c = myretContact1.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact1.LastName;
        ord.Order_Email__c = myretContact1.Email;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 15, 10, 0, 30);
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.Xometry_Quote_ID__c = 'Q00-0000-0000';
        ord.process_isPolyJet_3D__c = true;
        preTestOrderList.add(ord);

        Order_ERP__C ord2 = new Order_ERP__C();
        ord2.Account_Domain__c = testAccount2.Email_Domain__c;
        ord2.ERP_Company_Name__C = testAccount2.Name;
        ord2.ERP_Contact_First_Name__c = myretContact2.FirstName;
        ord2.ERP_Contact_Last_Name__c = myretContact2.LastName;
        ord2.ERP_Contact__C = 'AAA33';
        ord2.ERP_PartPk__c = '56565-55667';
        ord2.Is_Generic__c = false;
        ord2.Order_Canceled_Flag__c = false;
        ord2.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 15);
        ord2.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 15, 10, 0, 30);
        ord2.Order_Email__c = myretContact2.Email;
        ord2.Order_Subtotal__c = 4500.00;
        ord2.Order_Total__c = 5000.50;
        ord2.Payment_Type__c = 'credit_card';
        ord2.Xometry_ERP_ID__c = 'AAA33-34567';
        ord2.Xometry_Quote_ID__c = 'Q01-0000-0000';
        ord2.process_isPolyJet_3D__c = true;
        preTestOrderList.add(ord2);
        insert preTestOrderList;

        //Create 6 quotes
        //no parts
        List<Quote_ERP__C> quoteTestList = new List<Quote_ERP__C>();
        Quote_ERP__C quote1 = TestDataFactory.createQuote(
            false,
            testAccount1.Email_Domain__c,
            myretContact1.FirstName,
            myretContact1.LastName,
            myretContact1.email
        );
        quote1.Quote_Price__c = 500;
        quote1.Xometry_ERP_ID__C = 'Q11-1111-1111';
        quote1.ERP_Contact__C = 'BBBBB';
        quote1.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote1.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quoteTestList.add(quote1);

        Quote_ERP__C quote2 = TestDataFactory.createQuote(
            false,
            testAccount1.Email_Domain__c,
            myretContact1.FirstName,
            myretContact1.LastName,
            myretContact1.email
        );
        quote2.Quote_Price__c = 600;
        quote2.Xometry_ERP_ID__C = 'Q22-2222-2222';
        quote2.ERP_Contact__C = 'BBBBB';
        quote2.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote2.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 1, 30);
        quoteTestList.add(quote2);

        Quote_ERP__C quote3 = TestDataFactory.createQuote(
            false,
            testAccount1.Email_Domain__c,
            myretContact1.FirstName,
            myretContact1.LastName,
            myretContact1.email
        );
        quote3.Xometry_ERP_ID__C = 'Q33-3333-3333';
        quote3.Quote_Price__c = 1050;
        quote3.ERP_Contact__C = 'BBBBB';
        quote3.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote3.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 2, 30);
        quoteTestList.add(quote3);

        Quote_ERP__C quote4 = TestDataFactory.createQuote(
            false,
            testAccount2.Email_Domain__c,
            myretContact2.FirstName,
            myretContact2.LastName,
            myretContact2.email
        );
        quote4.Xometry_ERP_ID__C = 'Q44-4444-4444';
        quote4.Quote_Price__c = 500;
        quote4.ERP_Contact__C = 'AAA33';
        quote4.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote4.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 2, 30);
        quoteTestList.add(quote4);

        Quote_ERP__C quote5 = TestDataFactory.createQuote(
            false,
            testAccount2.Email_Domain__c,
            myretContact2.FirstName,
            myretContact2.LastName,
            myretContact2.email
        );
        quote5.Quote_Price__c = 600;
        quote5.Xometry_ERP_ID__C = 'Q55-5555-5555';
        quote5.ERP_Contact__C = 'AAA33';
        quote5.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote5.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 3, 30);
        quoteTestList.add(quote5);

        Quote_ERP__C quote6 = TestDataFactory.createQuote(
            false,
            testAccount2.Email_Domain__c,
            myretContact2.FirstName,
            myretContact2.LastName,
            myretContact2.email
        );
        quote6.Xometry_ERP_ID__C = 'Q66-6666-6666';
        quote6.ERP_Contact__C = 'AAA33';
        quote6.Quote_Price__c = 1050;
        quote6.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote6.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 3, 15);
        quoteTestList.add(quote6);

        Test.StartTest();
        insert quoteTestList;
        Test.StopTest();
        //Confirm that the Quotes Contact matches the Opps primary contact
        Set<ID> resultQuoteIDSet = new Set<ID>();
        for (Quote_ERP__C q : quoteTestList) {
            resultQuoteIDSet.add(q.ID);
        }
        List<Quote_ERP__C> resultQuoteUpdateList = [
            SELECT Id, OpportunityID__C, OpportunityID__R.Primary_Contact__c, ContactID__C
            FROM Quote_ERP__C
            WHERE id IN :resultQuoteIDSet
        ];

        for (Quote_ERP__C q : resultQuoteUpdateList) {
            System.assertEquals(q.ContactID__C, q.OpportunityID__R.Primary_Contact__c, 'The contacts were not equal');
        }
    }

    @isTest
    static void mulitQuotesNoPartTestBDR() {
        //This test class is put in place to ensure a bug related to multiple quotes with no parts at same transaction time with differen AM accounts
        //The Quotes and their opportunities should have a matching contact
        //Data setup create two 2 AM accounts and create an Order for each one so the quotes bypass the AM contact has not ordered logic
        //To properly test need to create 6 quotes with no parts with 3 quotes each assigned to each account
        //No Price on any quotes for these
        List<Account> newAccountList = [
            SELECT Id, Email_Domain__c, Name
            FROM Account
            WHERE Account_Owner_Type__c = 'BDR'
        ];
        Account testAccount1 = newAccountList[0];
        ID testAccount1ID = testAccount1.ID;
        Account testAccount2 = newAccountList[1];
        ID testAccount2ID = testAccount2.ID;
        Contact myretContact1 = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccount1ID
            ORDER BY Name
            LIMIT 1
        ];
        Contact myretContact2 = [
            SELECT ID, FirstName, LastName, Email
            FROM Contact
            WHERE AccountID = :testAccount2ID
            ORDER BY Name
            LIMIT 2
        ];

        //Create two Orders
        List<Order_ERP__C> preTestOrderList = new List<Order_ERP__C>();
        Order_ERP__C ord = new Order_ERP__C();
        ord.Account_Domain__c = testAccount1.Email_Domain__c;
        ord.ERP_Company_Name__C = testAccount1.Name;
        ord.ERP_Contact_First_Name__c = myretContact1.FirstName;
        ord.ERP_Contact_Last_Name__c = myretContact1.LastName;
        ord.ERP_Contact__C = 'BBBBB';
        ord.ERP_PartPk__c = '56564-55667';
        ord.Is_Generic__c = false;
        ord.Order_Canceled_Flag__c = false;
        ord.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 15);
        ord.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 15, 10, 0, 30);
        ord.Order_Email__c = myretContact1.Email;
        ord.Order_Subtotal__c = 4500.00;
        ord.Order_Total__c = 5000.50;
        ord.Payment_Type__c = 'credit_card';
        ord.Xometry_ERP_ID__c = 'BBBBB-34567';
        ord.Xometry_Quote_ID__c = 'Q11-3333-4444';
        ord.process_isPolyJet_3D__c = true;
        preTestOrderList.add(ord);

        Order_ERP__C ord2 = new Order_ERP__C();
        ord2.Account_Domain__c = testAccount2.Email_Domain__c;
        ord2.ERP_Company_Name__C = testAccount2.Name;
        ord2.ERP_Contact_First_Name__c = myretContact2.FirstName;
        ord2.ERP_Contact_Last_Name__c = myretContact2.LastName;
        ord2.ERP_Contact__C = 'AAA33';
        ord2.ERP_PartPk__c = '56565-55667';
        ord2.Is_Generic__c = false;
        ord2.Order_Canceled_Flag__c = false;
        ord2.Order_ERP_CreatedDate__c = date.newInstance(2021, 8, 15);
        ord2.Order_ERP_Time__c = dateTime.newInstance(2021, 8, 15, 10, 0, 30);
        ord2.Order_Email__c = myretContact2.Email;
        ord2.Order_Subtotal__c = 4500.00;
        ord2.Order_Total__c = 5000.50;
        ord2.Payment_Type__c = 'credit_card';
        ord2.Xometry_ERP_ID__c = 'AAA33-34567';
        ord.Xometry_Quote_ID__c = 'Q22-3333-4444';
        ord2.process_isPolyJet_3D__c = true;
        preTestOrderList.add(ord2);
        insert preTestOrderList;

        //Create 6 quotes
        //no parts
        List<Quote_ERP__C> quoteTestList = new List<Quote_ERP__C>();
        Quote_ERP__C quote1 = TestDataFactory.createQuote(
            false,
            testAccount1.Email_Domain__c,
            myretContact1.FirstName,
            myretContact1.LastName,
            myretContact1.email
        );
        quote1.Xometry_ERP_ID__C = 'Q11-1111-1111';
        quote1.ERP_Contact__C = 'BBBBB';
        quote1.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote1.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quoteTestList.add(quote1);

        Quote_ERP__C quote2 = TestDataFactory.createQuote(
            false,
            testAccount1.Email_Domain__c,
            myretContact1.FirstName,
            myretContact1.LastName,
            myretContact1.email
        );
        quote2.Xometry_ERP_ID__C = 'Q22-2222-2222';
        quote2.ERP_Contact__C = 'BBBBB';
        quote2.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote2.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 1, 30);
        quoteTestList.add(quote2);

        Quote_ERP__C quote3 = TestDataFactory.createQuote(
            false,
            testAccount1.Email_Domain__c,
            myretContact1.FirstName,
            myretContact1.LastName,
            myretContact1.email
        );
        quote3.Xometry_ERP_ID__C = 'Q33-3333-3333';
        quote3.ERP_Contact__C = 'BBBBB';
        quote3.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote3.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 2, 30);
        quoteTestList.add(quote3);

        Quote_ERP__C quote4 = TestDataFactory.createQuote(
            false,
            testAccount2.Email_Domain__c,
            myretContact2.FirstName,
            myretContact2.LastName,
            myretContact2.email
        );
        quote4.Xometry_ERP_ID__C = 'Q44-4444-4444';
        quote4.ERP_Contact__C = 'AAA33';
        quote4.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote4.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 2, 30);
        quoteTestList.add(quote4);

        Quote_ERP__C quote5 = TestDataFactory.createQuote(
            false,
            testAccount2.Email_Domain__c,
            myretContact2.FirstName,
            myretContact2.LastName,
            myretContact2.email
        );
        quote5.Xometry_ERP_ID__C = 'Q55-5555-5555';
        quote5.ERP_Contact__C = 'AAA33';
        quote5.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote5.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 3, 30);
        quoteTestList.add(quote5);

        Quote_ERP__C quote6 = TestDataFactory.createQuote(
            false,
            testAccount2.Email_Domain__c,
            myretContact2.FirstName,
            myretContact2.LastName,
            myretContact2.email
        );
        quote6.Xometry_ERP_ID__C = 'Q66-6666-6666';
        quote6.ERP_Contact__C = 'AAA33';
        quote6.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote6.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 3, 15);
        quoteTestList.add(quote6);

        Test.StartTest();
        insert quoteTestList;
        Test.StopTest();

        //Confirm that the Quotes Contact matches the Opps primary contact
        Set<ID> resultQuoteIDSet = new Set<ID>();
        for (Quote_ERP__C q : quoteTestList) {
            resultQuoteIDSet.add(q.ID);
        }

        List<Quote_ERP__C> resultQuoteUpdateList = [
            SELECT Id, OpportunityID__C, OpportunityID__R.Primary_Contact__c, ContactID__C
            FROM Quote_ERP__C
            WHERE id IN :resultQuoteIDSet
        ];

        for (Quote_ERP__C q : resultQuoteUpdateList) {
            System.assertEquals(q.ContactID__C, q.OpportunityID__R.Primary_Contact__c, 'The contacts were not equal');
        }
    }

    @isTest
    static void createOpportunity_withQuoteFields() {
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        Quote_ERP__C newQuote = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.Email
        );

        newQuote.Is_Generic__c = false;
        newQuote.Quote_Email__c = 'johndoe@superaccount.com';
        newQuote.Xometry_ERP_ID__c = 'Q12-3333-4444';
        newQuote.process_isPolyJet_3D__c = false;
        newQuote.Quoted_Total_Amt_PolyJet3D__c = 0;
        newQuote.Quoted_Total_Qty_PolyJet3D__c = 0;
        newQuote.FDMSize__c = 'Large Size';
        newQuote.Quote_Type__c = 'Auto-Quoted';
        newQuote.LineItemCount__c = 0;
        newQuote.ConversionProbability__c = 0.95;
        newQuote.process_isPolyJet_3D__c = true;
        newQuote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        newQuote.Quoted_Total_Amt_Stamping__c = 1234.00;
        newQuote.Quoted_Total_Qty_PolyJet3D__c = 3;
        newQuote.Quoted_Total_Qty_Stamping__c = 1;
        newQuote.OriginatedInFusion360__c = true;

        Test.startTest();
        insert newQuote;
        Test.stopTest();

        Opportunity newOpp = [
            SELECT
                ID,
                Total_Amt_PolyJet3D__c,
                Total_Amt_Stamping__c,
                Total_Qty_PolyJet3D__c,
                Total_Qty_Stamping__c,
                Quote_Type__c,
                LineItemCount__c,
                ConversionProbability__c,
                OriginatedInFusion360__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :newQuote.Xometry_ERP_ID__C
        ];

        System.assertEquals(newQuote.Quoted_Total_Amt_PolyJet3D__c, newOpp.Total_Amt_PolyJet3D__c, 'PolyJet3D Amt');
        System.assertEquals(newQuote.Quoted_Total_Amt_Stamping__c, newOpp.Total_Amt_Stamping__c, 'Stamping Amt');
        System.assertEquals(newQuote.Quoted_Total_Qty_PolyJet3D__c, newOpp.Total_Qty_PolyJet3D__c, 'PolyJet3D Qty');
        System.assertEquals(newQuote.Quoted_Total_Qty_Stamping__c, newOpp.Total_Qty_Stamping__c, 'Stamping Qty');
        System.assertEquals(
            newQuote.Quote_Type__c,
            newOpp.Quote_Type__c,
            'Opp should be created with Quote Type equal to quote'
        );
        System.assertEquals(
            newQuote.OriginatedInFusion360__c,
            newOpp.OriginatedInFusion360__c,
            'Opp should be created with OriginatedInFusion360__c equal to quote'
        );
        System.assertEquals(
            newQuote.LineItemCount__c,
            newOpp.LineItemCount__c,
            'Opp should be created with LineItemCount__c equal to quote'
        );
    }

    @isTest
    static void updateOpportunity_withQuoteFields() {
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        Quote_ERP__C quote = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            c.FirstName,
            c.LastName,
            c.Email
        );
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'johndoe@superaccount.com';
        quote.process_isPolyJet_3D__c = false;
        quote.Quoted_Total_Amt_PolyJet3D__c = 0;
        quote.Quoted_Total_Qty_PolyJet3D__c = 0;
        quote.FDMSize__c = 'Large Size';
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.LineItemCount__c = 0;
        quote.ConversionProbability__c = 0.95;
        insert quote;

        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quote_Price__c = 10000;
        quote.process_isCarbon__c = true;
        quote.process_isCNC_Machining__c = true;
        quote.process_isDie_Casting__c = true;
        quote.process_isDirect_Sourced__C = true;
        quote.process_isDMLS__c = true;
        quote.process_isExtrusion__c = true;
        quote.process_isFDM__c = true;
        quote.process_isHPMultJetFusion__c = true;
        quote.process_isInjection_Molding__c = true;
        quote.process_isPolyJet_3D__c = true;
        quote.process_isSheet_metal__c = true;
        quote.process_isSLA__c = true;
        quote.process_isSLS__c = true;
        quote.process_isStamping__c = true;
        quote.process_isUrethane_Casting__c = false;
        quote.process_isTubeBending__c = true;
        quote.process_IsTubeCutting__c = true;
        quote.process_IsOther__c = true;
        quote.process_isPlasticExtrusion__c = true;
        quote.process_isOther_NotIncluded__c = true;
        quote.process_isLSPc__c = true;
        quote.process_isAssembly__c = true;
        quote.FDMSize__c = 'Small Size';
        quote.Quote_Type__c = 'Manually-Quoted';
        quote.LineItemCount__c = 2;
        quote.ConversionProbability__c = 0.01;
        quote.quote_Shipping__c = 1.50;
        quote.Manual_Quote_Prioritization_Score__c = 50.55;

        Test.startTest();
        update quote;
        Test.stopTest();

        Opportunity resultOpp = [
            SELECT
                ID,
                Last_Quote_Xometry_ERP_ID__c,
                Total_Amt_PolyJet3D__c,
                Total_Amt_Stamping__c,
                Total_Qty_PolyJet3D__c,
                Total_Qty_Stamping__c,
                Amount,
                most_recent_quote_Carbon__c,
                most_recent_quote_CNC_Machining__c,
                most_recent_quote_Die_Casting__c,
                most_recent_quote_Direct_Sourced__c,
                most_recent_quote_DMLS__c,
                most_recent_quote_Extrusion__c,
                most_recent_quote_FDM__c,
                most_recent_quote_HPMultiJetFusion__c,
                most_recent_quote_Injection_Molding__c,
                most_recent_quote_PolyJet_3D__c,
                most_recent_quote_Sheet_metal__c,
                most_recent_quote_SLA__c,
                most_recent_quote_SLS__c,
                most_recent_quote_Stamping__c,
                most_recent_quote_Urethane_Casting__c,
                most_recent_quote_TubeBending__c,
                most_recent_quote_TubeCutting__c,
                most_recent_quote_Other__c,
                most_recent_quote_PlasticExtrusion__c,
                most_recent_quote_Other_NotIncluded__c,
                most_recent_quote_LSPc__c,
                most_recent_quote_Assembly__c,
                FDMSize__c,
                Quote_Type__c,
                LineItemCount__c,
                ConversionProbability__c,
                Order_Shipping__c,
                Manual_Quote_Prioritization_Score__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :quote.Xometry_ERP_ID__C
        ];

        System.assertEquals(quote.Quoted_Total_Amt_PolyJet3D__c, resultOpp.Total_Amt_PolyJet3D__c, 'PolyJet3D Amt');
        System.assertEquals(quote.Quoted_Total_Qty_PolyJet3D__c, resultOpp.Total_Qty_PolyJet3D__c, 'PolyJet3D Qty');
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Carbon__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_CNC_Machining__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Die_Casting__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Direct_Sourced__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_DMLS__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Extrusion__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(true, resultOpp.most_recent_quote_FDM__c, 'Field should have changed due to updated Quote');
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_HPMultiJetFusion__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Injection_Molding__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_PolyJet_3D__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Sheet_metal__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(true, resultOpp.most_recent_quote_SLA__c, 'Field should have changed due to updated Quote');
        System.assertEquals(true, resultOpp.most_recent_quote_SLS__c, 'Field should have changed due to updated Quote');
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Stamping__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            false,
            resultOpp.most_recent_quote_Urethane_Casting__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_TubeBending__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_TubeCutting__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Other__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_PlasticExtrusion__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Other_NotIncluded__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_LSPc__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals(
            true,
            resultOpp.most_recent_quote_Assembly__c,
            'Field should have changed due to updated Quote'
        );
        System.assertEquals('Small Size', resultOpp.FDMSize__c, 'FDM Size should be different');
        System.assertEquals(quote.Quote_Type__c, resultOpp.Quote_Type__c, 'Quote Type should be updated');
        System.assertEquals(quote.LineItemCount__c, resultOpp.LineItemCount__c, 'Line Item Count should be updated');
        System.assertEquals(
            quote.ConversionProbability__c,
            resultOpp.ConversionProbability__c,
            'Conversion Probability should be updated'
        );
        System.assertEquals(quote.quote_Shipping__c, resultOpp.Order_Shipping__c, 'Order shipping should be updated');
        System.assertEquals(
            quote.Manual_Quote_Prioritization_Score__c,
            resultOpp.Manual_Quote_Prioritization_Score__c,
            'Opp should have Manual_Quote_Prioritization_Score'
        );
    }

    /*
    @isTest
    static void reassignWestCoast_maintainAMOwners() {
        Contact c = [SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId 
                        FROM Contact WHERE Account.Account_Owner_Type__c = 'AM' ORDER BY Id ASC Limit 1];

        //Create a Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = c.Account.Email_Domain__c;
        myQuote.Quote_Email__c = c.Email;
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        myQuote.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote.ERP_Billing_City__c = 'San Diego';
        myQuote.ERP_Billing_Country__c = 'United States';
        myQuote.ERP_Billing_State_or_Province__c = 'California';

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__c insertedQuote = [SELECT ID, OwnerID, ContactID__c, AccountID__c
            FROM Quote_ERP__c WHERE ID = :myQuote.ID];
        System.assertNotEquals(insertedQuote.OwnerID, WEST_COAST_BDR, 'Quote Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c
            FROM Contact WHERE ID = :insertedQuote.ContactID__c];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'AM', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [
            SELECT ID, OwnerID, Account_Owner_Type__c
            FROM Account
            WHERE ID = :insertedQuote.AccountID__c
        ];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'AM', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverNonWestCoastState() {
        Contact c = [SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId 
                        FROM Contact WHERE Account.Account_Owner_Type__c = 'BDR' ORDER BY Id ASC Limit 1];

        //Create a Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = c.Account.Email_Domain__c;
        myQuote.Quote_Email__c = c.Email;
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        myQuote.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote.ERP_Billing_City__c = 'Virginia Beach';
        myQuote.ERP_Billing_Country__c = 'United States';
        myQuote.ERP_Billing_State_or_Province__c = 'Virginia';

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__c insertedQuote = [SELECT ID, OwnerID, ContactID__c, AccountID__c
                                        FROM Quote_ERP__c WHERE ID = :myQuote.ID];
        System.assertNotEquals(insertedQuote.OwnerID, WEST_COAST_BDR, 'Quote Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Contact WHERE ID = :insertedQuote.ContactID__c];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Account WHERE ID = :insertedQuote.AccountID__c];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverNullState() {
        Contact c = [SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId 
                        FROM Contact WHERE Account.Account_Owner_Type__c = 'BDR' ORDER BY Id ASC Limit 1];

        //Create a Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = c.Account.Email_Domain__c;        
        myQuote.Quote_Email__c = c.Email;
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        myQuote.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote.ERP_Billing_City__c = 'Virginia Beach';
        myQuote.ERP_Billing_Country__c = 'United States';

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__c insertedQuote = [SELECT ID, OwnerID, ContactID__c, AccountID__c
                                        FROM Quote_ERP__c WHERE ID = :myQuote.ID];
        System.assertNotEquals(insertedQuote.OwnerID, WEST_COAST_BDR, 'Quote Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Contact WHERE ID = :insertedQuote.ContactID__c ];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Account WHERE ID = :insertedQuote.AccountID__c];

        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverNonUSCountry() {
        Contact c = [SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId 
                        FROM Contact WHERE Account.Account_Owner_Type__c = 'BDR' ORDER BY Id ASC Limit 1];

        //Create a Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = c.Account.Email_Domain__c;
        myQuote.Quote_Email__c = c.Email;
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        myQuote.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote.ERP_Billing_City__c = 'Paris';
        myQuote.ERP_Billing_Country__c = 'France';
        myQuote.ERP_Billing_State_or_Province__c = 'Alaska';

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__c insertedQuote = [SELECT ID, OwnerID, ContactID__c, AccountID__c
                                        FROM Quote_ERP__c WHERE ID = :myQuote.ID];
        System.assertNotEquals(insertedQuote.OwnerID, WEST_COAST_BDR, 'Quote Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Contact WHERE ID = :insertedQuote.ContactID__c];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Account WHERE ID = :insertedQuote.AccountID__c];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverNullCountry() {
        Contact c = [SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId 
                        FROM Contact WHERE Account.Account_Owner_Type__c = 'BDR' ORDER BY Id ASC Limit 1];

        //Create a Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = c.Account.Email_Domain__c;
        myQuote.Quote_Email__c = c.Email;
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        myQuote.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote.ERP_Billing_City__c = 'Virginia Beach';

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__c insertedQuote = [SELECT ID, OwnerID, ContactID__c, AccountID__c
                                        FROM Quote_ERP__c WHERE ID = :myQuote.ID];
        System.assertNotEquals(insertedQuote.OwnerID, WEST_COAST_BDR, 'Quote Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Contact WHERE ID = :insertedQuote.ContactID__c];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Account WHERE ID = :insertedQuote.AccountID__c];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }

    @isTest
    static void reassignWestCoast_skipOverGeneric() {
        Contact c = [SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId 
                        FROM Contact WHERE Account.Account_Owner_Type__c = 'BDR' ORDER BY Id ASC Limit 1];

        //Create a Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = c.Account.Email_Domain__c;
        myQuote.Quote_Email__c = c.Email;
        myQuote.ERP_Contact_First_Name__c = 'John';
        myQuote.ERP_Contact_Last_Name__c = 'Doe';
        myQuote.ERP_Contact_Phone__C = '+1 (419) 532-3121';
        myQuote.ERP_Billing_Address__c = '2 Unit E Northway';
        myQuote.ERP_Billing_City__c = 'Los Angels';
        myQuote.ERP_Billing_Country__c = 'United States';
        myQuote.ERP_Billing_State_or_Province__c = 'California';

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Quote_ERP__c insertedQuote = [SELECT ID, OwnerID, ContactID__c, AccountID__c
                                        FROM Quote_ERP__c WHERE ID = :myQuote.ID];
        System.assertNotEquals(insertedQuote.OwnerID, WEST_COAST_BDR, 'Quote Owner is incorrect!');

        Contact quoteContact = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Contact WHERE ID = :insertedQuote.ContactID__c];
        System.assertEquals(quoteContact.Account_Owner_Type__c, 'BDR', 'Contact Owner Type is incorrect!');
        System.assertNotEquals(quoteContact.OwnerID, WEST_COAST_BDR, 'Contact Owner is incorrect!');

        Account quoteAccount = [SELECT ID, OwnerID, Account_Owner_Type__c
                                FROM Account WHERE ID = :insertedQuote.AccountID__c];
        System.assertEquals(quoteAccount.Account_Owner_Type__c, 'BDR', 'Account Owner Type is incorrect!');
        System.assertNotEquals(quoteAccount.OwnerID, WEST_COAST_BDR, 'Account Owner is incorrect!');
    }
    */

    @isTest
    static void coalesceState_selectParentAccount() {
        Account parentAccount = new Account();
        parentAccount.Name = 'ParentCo';
        parentAccount.BillingState = 'Maine';
        parentAccount.Hierarchy_Type__c = 'Corporate Parent';
        insert parentAccount;

        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingState = 'Ohio';
        account.ParentId = parentAccount.Id;
        account.Hierarchy_Type__c = 'Account Subdivision';

        Test.startTest();
        insert account;
        Test.stopTest();

        Account passedAccount = [
            SELECT Id, Name, BillingState, Parent.BillingState
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals(
            QuoteERPHandler.coalesceState(passedAccount, 'Porto'),
            'Maine',
            'Expected parent account state'
        );
    }

    @isTest
    static void coalesceState_selectAccount() {
        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingState = 'Ohio';

        Test.startTest();
        insert account;
        Test.stopTest();

        System.assertEquals(QuoteERPHandler.coalesceState(account, 'Porto'), 'Ohio', 'Expected account state');
    }

    @isTest
    static void coalesceState_selectPassedString() {
        System.assertEquals(QuoteERPHandler.coalesceState(null, 'Porto'), 'Porto', 'Expected returned passed String');
    }

    @isTest
    static void coalesceState_selectNone() {
        System.assertEquals(QuoteERPHandler.coalesceState(null, null), '', 'Expected returned Empty String');
    }

    @isTest
    static void coalesceCountry_selectParentAccount() {
        Account parentAccount = new Account();
        parentAccount.Name = 'ParentCo';
        parentAccount.BillingCountry = 'Canada';
        parentAccount.BillingState = 'Ontario';
        parentAccount.Hierarchy_Type__c = 'Corporate Parent';
        insert parentAccount;

        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingCountry = 'United States';
        account.ParentId = parentAccount.Id;
        account.Hierarchy_Type__c = 'Account Subdivision';

        Test.startTest();
        insert account;
        Test.stopTest();

        Account passedAccount = [
            SELECT Id, Name, BillingCountry, Parent.BillingCountry
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals(
            QuoteERPHandler.coalesceCountry(passedAccount, 'Portugal'),
            'Canada',
            'Expected parent account country'
        );
    }

    @isTest
    static void coalesceCountry_selectAccount() {
        Account account = new Account();
        account.Name = 'TestCo';
        account.BillingCountry = 'Denmark';

        Test.startTest();
        insert account;
        Test.stopTest();

        System.assertEquals(QuoteERPHandler.coalesceCountry(account, 'Porto'), 'Denmark', 'Expected account country');
    }

    @isTest
    static void coalesceCountry_selectPassedString() {
        System.assertEquals(QuoteERPHandler.coalesceCountry(null, 'Porto'), 'Porto', 'Expected returned passed String');
    }

    @isTest
    static void coalesceCountry_selectNone() {
        System.assertEquals(QuoteERPHandler.coalesceCountry(null, null), '', 'Expected returned Empty String');
    }

    @isTest
    private static void getOppMaxCreationAmount_getValue_expectNonNullReturn() {
        double returnedValue;
        Test.startTest();
        returnedValue = QuoteERPHandler.getOppMaxCreationAmount();
        Test.stopTest();

        System.assertNotEquals(null, returnedValue, 'Value returned was null');
    }

    @isTest
    static void updatePSECaseTest() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = false;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);
        myQuote.QuickTurn__c = false;
        myQuote.Allow_EU_Quoting__c = true;
        insert myQuote;

        Test.startTest();
        List<Case> caseListBeforeUpdate = new List<Case>(
            [
                SELECT Id, DFM_Description__c, QuickTurn__c, Allow_EU_Quoting__c
                FROM Case
                WHERE Shadow_Xometry_ERP_ID__c = :myQuote.Xometry_ERP_ID__C
            ]
        );
        System.assertEquals(true, caseListBeforeUpdate[0].Allow_EU_Quoting__c, 'Allow EU Quothing should be true');
        String newDFMDescription = 'Sheet metal index out of bounds /n Need to provide better threading';
        myQuote.DFM_Description__c = newDFMDescription;
        myQuote.QuickTurn__c = true;
        myQuote.Allow_EU_Quoting__c = false;
        update myQuote;
        Test.stopTest();
        List<Case> caseList = new List<Case>(
            [
                SELECT Id, DFM_Description__c, QuickTurn__c, Allow_EU_Quoting__c
                FROM Case
                WHERE Shadow_Xometry_ERP_ID__c = :myQuote.Xometry_ERP_ID__C
            ]
        );

        System.assertEquals(newDFMDescription, caseList[0].DFM_Description__c, 'DFM_Description was not updated');
        System.assertEquals(true, caseList[0].QuickTurn__c, 'QuickTurn flag was updated');
        System.assertEquals(false, caseList[0].Allow_EU_Quoting__c, 'Allow EU Quothing should be false');
    }

    @isTest
    static void createCasesTest() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = false;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        insert myQuote;

        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        myQuote.Requote__c = true;
        Test.startTest();
        update myQuote;
        Test.stopTest();
        List<Case> caseList = new List<Case>([SELECT Id, Requote__c FROM Case]);

        System.assertNotEquals(0, caseList.size(), 'A case should have been created');
        System.assertEquals(true, caseList[0].Requote__c, 'Requote flag should have been updated');
    }

    @isTest(seeAllData=false)
    static void createCasesWithCaseOppTest() {
        Id pseCasetRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('PSE_Case')
            .getRecordTypeID();

        Case testCase = new Case(
            Shadow_Xometry_ERP_ID__c = 'AAAAA-00002',
            RecordTypeId = pseCasetRecordTypeID,
            PSE_Quote_Link__c = true
        );
        Case testCase2 = new Case(RecordTypeId = pseCasetRecordTypeID, PSE_Quote_Link__c = true);
        insert new List<Case>{ testCase, testCase2 };

        CaseOpportunity__c caseOppTest = new CaseOpportunity__c(
            Xometry_ERP_ID__c = 'AAAAA-00002',
            Case__c = testCase2.Id,
            Opportunity__c = null
        );
        insert caseOppTest;

        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'AAAAA-00002';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);

        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        myQuote = [SELECT OpportunityID__c FROM Quote_ERP__c WHERE Id = :myQuote.Id];
        testCase = [SELECT Id, Opportunity__c FROM Case WHERE Id = :testCase.Id];

        System.assertEquals(myQuote.OpportunityID__c, testCase.Opportunity__c, 'A case should have been linked');
    }

    @isTest
    static void createnoCasesTest() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = true;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);

        insert myQuote;

        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 19, 6, 0, 0);

        Test.startTest();
        update myQuote;
        Test.stopTest();

        List<Case> caseList = new List<Case>([SELECT Id FROM Case]);
        System.assertEquals(0, caseList.size(), 'A case should not have been created');
    }

    @isTest
    static void noNewCaseTest() {
        Case testCase = new Case();
        testCase.SuppliedEmail = 'test@test.com';
        testCase.Shadow_Xometry_ERP_ID__C = 'Q12-3333-4444';
        insert testCase;

        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = false;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);

        insert myQuote;

        myQuote.Requested_Manual_Quote_Flag__c = false;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        Test.startTest();
        update myQuote;
        Test.stopTest();

        List<Case> caseList = new List<Case>([SELECT Id FROM Case]);
        System.assertEquals(1, caseList.size(), 'There should be one case exactly');
    }

    @isTest
    private static void linkQuotetoExistingCase() {
        //This test checks that a new Case is not created if a case has a Quote ID assigned to it and the Request for manual quote is not added
        List<Case> caseList = TestDataFactory.createTestCases(5, 'Web', 'PSE_Case');
        Case testCase = caseList[0];
        //Update the first Case with a test Quote ID

        String testXomId = 'Q12-3333-4444';
        testCase.Shadow_Xometry_ERP_ID__c = testXomId;
        testCase.PSE_Quote_Link__c = true;
        update testCase;

        //Insert the Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = true;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.process_isCNC_Machining__c = true;
        myQuote.Quoted_Total_Amt_CNC__c = 50.15;
        myQuote.Quoted_Total_Qty_CNC__c = 1;
        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        test.startTest();
        insert myQuote;
        test.stopTest();
        //There should be 5 cases and only 1 case with the Shadow Xometry Erp Id

        AggregateResult[] caseCountResult = [SELECT count(id) caseCount FROM Case];
        Integer caseCount = Integer.valueOf(String.valueOf(caseCountResult[0].get('caseCount')));
        System.assertEquals(5, caseCount, 'The number of cases did not match as expected');
        AggregateResult[] caseWithQuoteIdResult = [
            SELECT count(id) caseCount
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :testXomId
        ];
        Integer caseWithQuoteId = Integer.valueOf(String.valueOf(caseWithQuoteIdResult[0].get('caseCount')));
        System.assertEquals(1, casewithQuoteId, 'Did not find exactly 1 case with the Quote Id');
    }

    @isTest
    private static void doNotLinkQuoteToGeneralSupportCase() {
        //Insert the Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = true;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.process_isCNC_Machining__c = true;
        myQuote.Quoted_Total_Amt_CNC__c = 50.15;
        myQuote.Quoted_Total_Qty_CNC__c = 1;
        myQuote.Requested_Manual_Quote_Flag__c = false;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        insert myQuote;

        //This test checks that a new Case is not created if a case has a Quote ID assigned to it and the Request for manual quote is not added
        List<Case> caseList = TestDataFactory.createTestCases(5, 'Web', 'GeneralSupportCase');
        Case testCase = caseList[0];
        //Update the first Case with a test Quote ID

        String testXomId = 'Q12-3333-4444';
        testCase.Shadow_Xometry_ERP_ID__c = testXomId;
        testCase.PSE_Quote_Link__c = false;
        update testCase;

        myQuote.ERP_Status__c = 'In Progress';

        test.startTest();
        update myQuote;
        test.stopTest();

        AggregateResult[] caseWithQuoteIdResult = [
            SELECT count(id) caseCount
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :testXomId
        ];
        Integer caseWithQuoteId = Integer.valueOf(String.valueOf(caseWithQuoteIdResult[0].get('caseCount')));
        System.assertEquals(1, casewithQuoteId, 'Did not find exactly 1 case with the Quote Id');

        Case updatedCase = [SELECT Id, Opportunity__c FROM Case WHERE Shadow_Xometry_ERP_ID__c = :testXomId];
        System.assertEquals(null, updatedCase.Opportunity__c, 'An opp was asocaited to the case');
    }

    @isTest
    private static void doNotLinkQuoteToGeneralSupportCaseAfterMQFlag() {
        //Insert the Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = true;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.process_isCNC_Machining__c = true;
        myQuote.Quoted_Total_Amt_CNC__c = 50.15;
        myQuote.Quoted_Total_Qty_CNC__c = 1;
        myQuote.Requested_Manual_Quote_Flag__c = false;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        insert myQuote;

        List<Case> caseList = TestDataFactory.createTestCases(5, 'Web', 'GeneralSupportCase');
        Case testCase = caseList[0];
        //Update the first Case with a test Quote ID

        String testXomId = 'Q12-3333-4444';
        testCase.Shadow_Xometry_ERP_ID__c = testXomId;
        testCase.PSE_Quote_Link__c = false;
        update testCase;

        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        test.startTest();
        update myQuote;
        test.stopTest();

        AggregateResult[] caseWithQuoteIdResult = [
            SELECT count(id) caseCount
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :testXomId
        ];
        Integer caseWithQuoteId = Integer.valueOf(String.valueOf(caseWithQuoteIdResult[0].get('caseCount')));
        System.assertEquals(2, casewithQuoteId, 'Did not find exactly 2 cases with the Quote Id');
    }

    @isTest
    private static void createPSECaseWithExistingCase() {
        /* This test links a sales case to an incoming quote and then creates a second case for PSE if it was updated accordingly.
           The real life scenario is that Sales Ops makes a case. Then makes a quote in get site. Links their case with quote id and the
           quote is marked as request for quote. We should have 2 cases for that quote. One marked for PSE.
        */
        List<Case> caseList = TestDataFactory.createTestCases(5, 'Web', 'PSE_Case');
        Case testCase = caseList[0];
        //Update the first Case with a test Quote ID
        String testXomId = 'Q12-3333-4444';
        testCase.Shadow_Xometry_ERP_ID__c = testXomId;
        update testCase;

        //Insert the Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.process_isCNC_Machining__c = true;
        myQuote.Quoted_Total_Amt_CNC__c = 50.15;
        myQuote.Quoted_Total_Qty_CNC__c = 1;
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);
        insert myQuote;

        myQuote.Quote_Price__c = 1050.15;
        myQuote.process_isFDM__c = true;
        myQuote.Quoted_Total_Amt_FDM__c = 1000;
        myQuote.Quoted_Total_Qty_FDM__c = 5;
        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        test.startTest();
        update myQuote;
        test.stopTest();
        //There should be 6 cases and and 12 cases with the Shadow Xometry Erp Id
        AggregateResult[] caseCountResult = [SELECT count(id) caseCount FROM Case];
        Integer caseCount = Integer.valueOf(String.valueOf(caseCountResult[0].get('caseCount')));
        System.assertEquals(6, caseCount, 'The number of cases did not match as expected');
        AggregateResult[] caseWithQuoteIdResult = [
            SELECT count(id) caseCount
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :testXomId
        ];
        Integer caseWithQuoteId = Integer.valueOf(String.valueOf(caseWithQuoteIdResult[0].get('caseCount')));
        System.assertEquals(2, casewithQuoteId, 'Did not find exactly 1 case with the Quote Id');
        List<Case> myCaseList = [
            SELECT
                ID,
                CaseNumber,
                Origin,
                Shadow_Xometry_ERP_ID__c,
                PSE_Quote_Link__c,
                Quote_Linked_by_Integration__c,
                Createddate
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :testXomId
        ];
        AggregateResult[] caseWithPSEQuoteIdResult = [
            SELECT count(id) caseCount
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :testXomId AND PSE_Quote_Link__c = TRUE
        ];
        Integer caseWithPSEQuoteId = Integer.valueOf(String.valueOf(caseWithPSEQuoteIdResult[0].get('caseCount')));
        System.assertEquals(1, caseWithPSEQuoteId, 'Did not find exactly 1 case with the Quote Id');
    }

    @isTest
    private static void linkQuotetoExistingCaseWithUpdate() {
        //This test checks that a new Case is not created if a case has a Quote ID assigned to it and tests a new Update does not spawn a new case
        List<Case> caseList = TestDataFactory.createTestCases(5, 'Web', 'PSE_Case');
        Case testCase = caseList[0];
        //Update the first Case with a test Quote ID
        String testXomId = 'Q12-3333-4444';
        testCase.Shadow_Xometry_ERP_ID__c = testXomId;
        update testCase;

        //Insert the Quote
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = true;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.process_isCNC_Machining__c = true;
        myQuote.Quoted_Total_Amt_CNC__c = 50.15;
        myQuote.Quoted_Total_Qty_CNC__c = 1;
        myQuote.Requested_Manual_Quote_Flag__c = false;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);
        insert myQuote;

        myQuote.Quote_Price__c = 1050.15;
        myQuote.process_isFDM__c = true;
        myQuote.Quoted_Total_Amt_FDM__c = 1000;
        myQuote.Quoted_Total_Qty_FDM__c = 5;

        test.startTest();
        update myQuote;
        test.stopTest();

        //There should be 5 cases and only 1 case with the Shadow Xometry Erp Id
        AggregateResult[] caseCountResult = [SELECT count(id) caseCount FROM Case];
        Integer caseCount = Integer.valueOf(String.valueOf(caseCountResult[0].get('caseCount')));
        System.assertEquals(5, caseCount, 'The number of cases did not match as expected');
        AggregateResult[] caseWithQuoteIdResult = [
            SELECT count(id) caseCount
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :testXomId
        ];
        Integer caseWithQuoteId = Integer.valueOf(String.valueOf(caseWithQuoteIdResult[0].get('caseCount')));
        System.assertEquals(1, casewithQuoteId, 'Did not find exactly 1 case with the Quote Id');
    }

    @isTest
    private static void updateOpportunity_WithQuoterEmails() {
        Contact c = [
            SELECT Id, AccountId, Account.OwnerId, Account.Email_Domain__c
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        User u = [SELECT Id, Email, IsActive FROM User WHERE Id = :c.Account.OwnerId];
        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = c.Account.Email_Domain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.AccountID__c = c.AccountId;
        quote.ContactID__c = c.Id;
        quote.Account_Domain__c = 'superaccount.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Quote_Email__c = 'johndoe@superaccount.com';
        quote.process_isPolyJet_3D__c = false;
        quote.Quoted_Total_Amt_PolyJet3D__c = 0;
        quote.Quoted_Total_Qty_PolyJet3D__c = 0;
        quote.FirstQuoterEmail__c = 'johndoe@superaccount.com';
        quote.ManualQuoterEmail__c = u.Email;

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote_ERP__C quoteFetch = [
            SELECT
                Id,
                OpportunityID__c,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Quote_ERP__C
            WHERE ID = :quote.ID
        ];

        ID oppID = quoteFetch.OpportunityID__c;
        Opportunity resultOpp = [
            SELECT
                ID,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Opportunity
            WHERE Id = :oppID
        ];

        System.assertEquals(false, quoteFetch.FirstQuoterStaffFlag__c, 'Flag should be false');
        System.assertEquals(
            quoteFetch.FirstQuoterEmail__c,
            resultOpp.FirstQuoterEmail__c,
            'Opp email should match quote'
        );
        System.assertEquals(
            quoteFetch.ManualQuoterEmail__c,
            resultOpp.ManualQuoterEmail__c,
            'Opp email should match quote'
        );
        System.assertEquals(false, resultOpp.FirstQuoterStaffFlag__c, 'Flag should be false');
        System.assertNotEquals(u.Id, quoteFetch.FirstQuoterUser__c, 'FirstQuoterUser should not associate');
        System.assertEquals(u.Id, quoteFetch.ManualQuoterUser__c, 'ManualQuoterUser should associate');
        System.assertNotEquals(u.Id, resultOpp.FirstQuoterUser__c, 'FirstQuoterUser should not associate');
        System.assertEquals(u.Id, resultOpp.ManualQuoterUser__c, 'User should associate');
    }

    @isTest
    private static void updateOpportunity_WithStaffAsQuoter() {
        // Account a = TestDataFactory.createTestAccountNonGenericsStaffUser(5, 'AM', 1)[0];
        Account a = [SELECT Id, Email_Domain__c, Name, OwnerId FROM Account WHERE Account_Owner_Type__c = 'AM' LIMIT 1];
        Contact c = [SELECT ID FROM Contact][0];
        User u = [SELECT Id, Email, IsActive FROM User WHERE Id = :a.OwnerId];

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = a.Email_Domain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.AccountID__c = a.Id;
        quote.ContactID__c = c.Id;
        quote.Account_Domain__c = 'superaccount.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'johndoe@superaccount.com';
        quote.process_isPolyJet_3D__c = false;
        quote.Quoted_Total_Amt_PolyJet3D__c = 0;
        quote.Quoted_Total_Qty_PolyJet3D__c = 0;
        quote.FirstQuoterEmail__c = u.Email;
        quote.ManualQuoterEmail__c = u.Email;

        Test.startTest();
        insert quote;
        Test.stopTest();

        ID testQuoteID = quote.ID;
        Quote_ERP__C quoteFetch = [
            SELECT
                Id,
                OpportunityID__c,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Quote_ERP__C
            WHERE ID = :testQuoteID
        ];

        ID oppID = quoteFetch.OpportunityID__c;
        Opportunity resultOpp = [
            SELECT
                ID,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Opportunity
            WHERE Id = :oppID
        ];

        System.assertEquals(true, quoteFetch.FirstQuoterStaffFlag__c, 'Flag should be true');
        System.assertEquals(
            quoteFetch.FirstQuoterEmail__c,
            resultOpp.FirstQuoterEmail__c,
            'Opp email should match quote'
        );
        System.assertEquals(
            quoteFetch.ManualQuoterEmail__c,
            resultOpp.ManualQuoterEmail__c,
            'Opp email should match quote'
        );
        System.assertEquals(true, resultOpp.FirstQuoterStaffFlag__c, 'Flag should be true');
        System.assertEquals(u.Id, quoteFetch.ManualQuoterUser__c, 'ManualQuoterUser should associate');
        System.assertEquals(u.Id, quoteFetch.FirstQuoterUser__c, 'FirstQuoterUser should associate');
        System.assertEquals(u.Id, resultOpp.FirstQuoterUser__c, 'FirstQuoterUser should associate');
        System.assertEquals(u.Id, resultOpp.ManualQuoterUser__c, 'ManualQuoterUser should associate');
    }

    @isTest
    private static void updateOpportunity_ManualQuoterUpdate() {
        Contact c = [
            SELECT
                ID,
                FirstName,
                LastName,
                Name,
                AccountID,
                Account.Name,
                Account.Email_Domain__c,
                Email,
                OwnerId,
                Account.OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];
        User u = [SELECT Id, Email, IsActive FROM User WHERE Id = :c.Account.OwnerId];

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = c.Account.Email_Domain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.AccountID__c = c.AccountId;
        quote.ContactID__c = c.Id;
        quote.Account_Domain__c = 'superaccount.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'johndoe@superaccount.com';
        quote.process_isPolyJet_3D__c = false;
        quote.Quoted_Total_Amt_PolyJet3D__c = 0;
        quote.Quoted_Total_Qty_PolyJet3D__c = 0;
        quote.FirstQuoterEmail__c = u.Email;
        quote.ManualQuoterEmail__c = null;
        quote.FirstQuoterUser__c = u.Id;
        insert quote;

        quote.ManualQuoterEmail__c = u.Email;
        quote.ManualQuoteTime__c = dateTime.newInstance(2021, 8, 7, 10, 0, 30);
        Test.startTest();
        update quote;
        Test.stopTest();

        Quote_ERP__C quoteFetch = [
            SELECT
                Id,
                OpportunityID__c,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                ManualQuoteTime__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Quote_ERP__C
            WHERE ID = :quote.ID
        ];

        Opportunity resultOpp = [
            SELECT
                ID,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                ManualQuoteTime__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Opportunity
            WHERE Id = :quoteFetch.OpportunityID__c
        ];

        System.assertEquals(
            quote.ManualQuoterEmail__c,
            quoteFetch.ManualQuoterEmail__c,
            'Manual quote time should update'
        );
        System.assertEquals(
            quoteFetch.ManualQuoterEmail__c,
            resultOpp.ManualQuoterEmail__c,
            'Opp manual quote time should match quote'
        );
        System.assertEquals(quote.ManualQuoteTime__c, quoteFetch.ManualQuoteTime__c, 'Manual quote time should update');
        System.assertEquals(
            quoteFetch.ManualQuoteTime__c,
            resultOpp.ManualQuoteTime__c,
            'Opp manual quote time should match quote'
        );
        System.assertEquals(u.Id, quoteFetch.FirstQuoterUser__c, 'FirstQuoterUser should associate');
        System.assertEquals(u.Id, quoteFetch.ManualQuoterUser__c, 'ManualQuoterUser should associate');
        System.assertEquals(u.Id, resultOpp.FirstQuoterUser__c, 'FirstQuoterUser should associate');
        System.assertEquals(u.Id, resultOpp.ManualQuoterUser__c, 'ManualQuoterUser should associate');
    }

    @isTest
    private static void createOpportunity_withConversionProbability() {
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = c.Account.Email_Domain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.AccountID__c = c.AccountId;
        quote.ContactID__c = c.Id;
        quote.Account_Domain__c = 'superaccount.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Quote_Email__c = 'johndoe@superaccount.com';
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.OriginatedInFusion360__c = true;
        quote.ConversionProbability__c = 0.95;

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote_ERP__C quoteFetch = [
            SELECT Id, OpportunityID__c, ConversionProbability__c
            FROM Quote_ERP__C
            WHERE ID = :quote.ID
        ];

        ID oppID = quoteFetch.OpportunityID__c;
        Opportunity resultOpp = [SELECT ID, ConversionProbability__c FROM Opportunity WHERE Id = :oppID];

        System.assertEquals(
            quote.ConversionProbability__c,
            resultOpp.ConversionProbability__c,
            'Opp should be created with ConversionProbability__c equal to quote'
        );
    }

    @isTest
    private static void createOpportunity_withCertificates() {
        Contact c = [
            SELECT ID, FirstName, LastName, Name, AccountID, Account.Name, Account.Email_Domain__c, Email, OwnerId
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = c.Account.Email_Domain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.AccountID__c = c.AccountId;
        quote.ContactID__c = c.Id;
        quote.Account_Domain__c = 'superaccount.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Quote_Email__c = 'johndoe@superaccount.com';
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.ConversionProbability__c = 0.95;
        quote.ITAR__c = true;
        quote.Hardware_Cert__c = true;
        quote.Conformance_Cert__c = true;
        quote.Material_Traceability_Cert__c = true;
        quote.Material_Cert__c = 'Domestic Compliant Material Cert';

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote_ERP__C quoteFetch = [
            SELECT Id, OpportunityID__c, ConversionProbability__c
            FROM Quote_ERP__C
            WHERE ID = :quote.ID
        ];

        ID oppID = quoteFetch.OpportunityID__c;
        Opportunity resultOpp = [
            SELECT ID, ITAR__c, Hardware_Cert__c, Conformance_Cert__c, Material_Traceability_Cert__c, Material_Cert__c
            FROM Opportunity
            WHERE Id = :oppID
        ];

        System.assertEquals(resultOpp.ITAR__c, quote.ITAR__c, 'Opp should be created with ITAR__c equal to true');
        System.assertEquals(
            resultOpp.Hardware_Cert__c,
            quote.Hardware_Cert__c,
            'Opp should be created with Hardware_Cert__c equal to true'
        );
        System.assertEquals(
            resultOpp.Conformance_Cert__c,
            quote.Conformance_Cert__c,
            'Opp should be created with Conformance_Cert__c equal to true'
        );
        System.assertEquals(
            resultOpp.Material_Traceability_Cert__c,
            quote.Material_Traceability_Cert__c,
            'Opp should be created with Material_Traceability_Cert__c equal to true'
        );
        System.assertEquals(
            resultOpp.Material_Cert__c,
            quote.Material_Cert__c,
            'The Opp Material Cert Text did no match the quote'
        );
    }

    @isTest(seeAllData=false)
    private static void linkInsQuotetoExistingCaseOpp() {
        Case testCase = new Case();
        testCase.PSE_Quote_Link__c = true;
        insert testCase;

        CaseOpportunity__c caseOpp = new CaseOpportunity__c(Case__c = testCase.Id, Xometry_ERP_ID__C = 'Q12-3333-4444');
        insert caseOpp;

        Quote_ERP__c myQuote = new Quote_ERP__C(
            Account_Domain__C = 'SuperAccount',
            ERP_PartPK__c = 'A1234-A5678',
            Quote_Price__c = 50.15,
            Xometry_ERP_ID__C = 'Q12-3333-4444',
            ERP_Contact__c = 'AAAAA',
            IS_Generic__c = false,
            Quote_Email__c = 'johndoe@superaccount.com',
            Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14),
            Requested_Manual_Quote_Flag__c = true,
            Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0)
        );

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Quote_ERP_XOM_CREATE_ID__c = 'Q12-3333-4444'];
        System.assertEquals(
            caseOpp.Id,
            [SELECT Id FROM CaseOpportunity__c WHERE Opportunity__c = :testOpp.Id]
            .Id,
            'The Opp from the updated Quote should be linked to the Existent junction'
        );

        System.assertEquals([SELECT Id FROM Case].size(), 1, 'Only one case should be created and updated');
    }

    @isTest(seeAllData=false)
    private static void linkUpdQuotetoExistingCaseOpp() {
        Case testCase = new Case();
        testCase.PSE_Quote_Link__c = true;
        insert testCase;

        CaseOpportunity__c caseOpp = new CaseOpportunity__c(Case__c = testCase.Id, Xometry_ERP_ID__C = 'Q12-3333-4444');
        insert caseOpp;

        Quote_ERP__c myQuote = new Quote_ERP__C(
            Account_Domain__C = 'SuperAccount',
            ERP_PartPK__c = 'A1234-A5678',
            Quote_Price__c = 50.15,
            Xometry_ERP_ID__C = 'Q12-3333-4444',
            ERP_Contact__c = 'AAAAA',
            IS_Generic__c = false,
            Quote_Email__c = 'johndoe@superaccount.com',
            Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14),
            Requested_Manual_Quote_Flag__c = false,
            Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0)
        );
        insert myQuote;

        Test.startTest();
        myQuote.Requested_Manual_Quote_Flag__c = true;
        update myQuote;
        Test.stopTest();

        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Quote_ERP_XOM_CREATE_ID__c = 'Q12-3333-4444'];
        System.assertEquals(
            caseOpp.Id,
            [SELECT Id FROM CaseOpportunity__c WHERE Opportunity__c = :testOpp.Id]
            .Id,
            'The Opp from the updated Quote should be linked to the Existent junction'
        );

        System.assertEquals([SELECT Id FROM Case].size(), 1, 'Only one case should be created and updated');
    }

    @isTest
    private static void accountUpdatesOwner_fromGNOHouse() {
        Account a = new Account();
        a.Name = 'Test Account';
        a.Account_Owner_Type__c = 'Ops';
        a.email_domain__c = 'coolcompany.com';
        a.OwnerId = AppConstants.GNO_HOUSE_USER;
        insert a;

        Contact c = new Contact();
        c.FirstName = 'Test';
        c.LastName = 'Contact';
        c.Primary_Email__c = 'contact@coolcompany.com';
        c.AccountId = a.Id;
        c.OwnerId = AppConstants.GNO_HOUSE_USER;
        insert c;

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = a.Email_Domain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.AccountID__c = a.Id;
        quote.ContactID__c = c.Id;
        quote.Account_Domain__c = 'coolcompany.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'contact@coolcompany.com';
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.ConversionProbability__c = 0.95;

        Test.startTest();
        insert quote;
        Test.stopTest();

        Account aResult = [SELECT Id, OwnerId FROM Account WHERE Id = :a.Id][0];
        Contact cResult = [SELECT Id, OwnerId FROM Contact WHERE Id = :c.Id][0];

        System.assertNotEquals(a.OwnerId, aResult.OwnerId, 'Account Owner should not be GNO House');
        System.assertEquals(AppConstants.SALES_HOUSE_USER, aResult.OwnerId, 'Account Owner should be Sales House');
        System.assertEquals(c.OwnerId, cResult.OwnerId, 'Contact Owner should be GNO House');
        System.assertNotEquals(
            AppConstants.SALES_HOUSE_USER,
            cResult.OwnerId,
            'Contact Owner should not be Sales House'
        );
    }

    @isTest
    private static void updateOpportunity_ManualQuoterNotActive() {
        Contact c = [
            SELECT Id, AccountId, Account.OwnerId, Account.Email_Domain__c
            FROM Contact
            WHERE Account.Account_Owner_Type__c = 'AM'
            ORDER BY Id ASC
            LIMIT 1
        ];

        User u = [SELECT Id, Email, IsActive FROM User WHERE Id = :c.Account.OwnerId];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            u.IsActive = false;
            update u;
        }

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = c.Account.Email_Domain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.AccountID__c = c.AccountId;
        quote.ContactID__c = c.Id;
        quote.Account_Domain__c = 'superaccount.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'johndoe@superaccount.com';
        quote.process_isPolyJet_3D__c = false;
        quote.Quoted_Total_Amt_PolyJet3D__c = 0;
        quote.Quoted_Total_Qty_PolyJet3D__c = 0;
        quote.FirstQuoterEmail__c = 'johndoe@superaccount.com';
        quote.ManualQuoterEmail__c = u.Email;

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote_ERP__C quoteFetch = [
            SELECT
                Id,
                OpportunityID__c,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Quote_ERP__C
            WHERE ID = :quote.ID
        ];

        ID oppID = quoteFetch.OpportunityID__c;
        Opportunity resultOpp = [
            SELECT
                ID,
                FirstQuoterEmail__c,
                FirstQuoterStaffFlag__c,
                ManualQuoterEmail__c,
                FirstQuoterUser__c,
                ManualQuoterUser__c
            FROM Opportunity
            WHERE Id = :oppID
        ];

        System.assertEquals(false, quoteFetch.FirstQuoterStaffFlag__c, 'Flag should be false');
        System.assertEquals(
            quoteFetch.FirstQuoterEmail__c,
            resultOpp.FirstQuoterEmail__c,
            'Opp email should match quote'
        );
        System.assertEquals(
            quoteFetch.ManualQuoterEmail__c,
            resultOpp.ManualQuoterEmail__c,
            'Opp email should match quote'
        );
        System.assertEquals(false, resultOpp.FirstQuoterStaffFlag__c, 'Flag should be false');
        System.assertNotEquals(u.Id, quoteFetch.FirstQuoterUser__c, 'FirstQuoterUser should not associate');
        System.assertNotEquals(u.Id, quoteFetch.ManualQuoterUser__c, 'ManualQuoterUser should not associate');
        System.assertNotEquals(u.Id, resultOpp.FirstQuoterUser__c, 'FirstQuoterUser should not associate');
        System.assertNotEquals(u.Id, resultOpp.ManualQuoterUser__c, 'ManualQuoterUser should not associate');
    }

    @isTest
    private static void quoteWithPartner_associatesNewPartnerContact() {
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P12345';
        s.EmailAddress__c = 'contact@coolcompany.com';
        s.AccountDomain__c = 'coolcompany.com';
        s.SupplierCompanyName__c = 'Cool Supplier';
        s.LastName__c = 'Supplier';
        s.FirstName__c = 'Cool';
        s.Phone__c = '1234567890';
        s.IsGeneric__c = false;
        insert s;

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Account_Domain__C = s.AccountDomain__c;
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.Account_Domain__c = 'coolcompany.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'contact@coolcompany.com';
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.ConversionProbability__c = 0.95;
        quote.MKP_PartnerId__c = 'P12345';

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote_ERP__c qResult = [SELECT Id, AccountID__c, ContactId__c FROM Quote_ERP__c WHERE Id = :quote.Id][0];
        Contact cResult = [SELECT Id FROM Contact WHERE Id = :qResult.ContactID__c];
        Supplier__c sResult = [SELECT Id, AccountID__c, ContactId__c FROM Supplier__c WHERE Id = :s.Id];

        System.assertEquals(
            sResult.AccountId__c,
            qResult.AccountId__c,
            'associated account should be with the matching partner account'
        );
        System.assertEquals(sResult.ContactId__c, cResult.Id, 'Existing Contact should associate');
    }

    @isTest
    public static void quoteWithPartner_contactUnderPartnerAccount() {
        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P12345';
        s.EmailAddress__c = 'contact@coolcompany.com';
        s.AccountDomain__c = 'coolcompany.com';
        s.SupplierCompanyName__c = 'Cool Supplier';
        s.LastName__c = 'Supplier';
        s.FirstName__c = 'Cool';
        s.Phone__c = '1234567890';
        s.IsGeneric__c = false;
        insert s;

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.Account_Domain__c = 'supplier@gmail.com';
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'supplier@gmail.com';
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.ConversionProbability__c = 0.95;
        quote.MKP_PartnerId__c = 'P12345';

        Test.startTest();
        insert quote;
        Test.stopTest();

        Supplier__c sResult = [SELECT Id, AccountId__c, ContactId__c FROM Supplier__c WHERE Id = :s.Id];
        Quote_ERP__c qResult = [
            SELECT Id, AccountId__c, ContactId__c, ContactId__r.AccountId
            FROM Quote_ERP__c
            WHERE Id = :quote.Id
        ];

        System.assertEquals(
            sResult.AccountId__c,
            qResult.ContactId__r.AccountId,
            'Account on quote contact should be supplier account'
        );
        System.assertNotEquals(sResult.ContactId__c, qResult.ContactId__c, 'New contact should be created');
    }

    @isTest
    public static void quoteWithDuns_relatesDUNSAccount() {
        DNBConnect__D_B_Connect_Company_Profile__c cRecord = new DNBConnect__D_B_Connect_Company_Profile__c();
        cRecord.DNBConnect__PrimName__c = 'Test';
        cRecord.DNBConnect__DUNSNumber__c = '012345678';

        insert cRecord;

        List<Account> aList = [SELECT Id, DNBConnect__D_B_Connect_Company_Profile__c, Email_Domain__c FROM Account];
        aList[0].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[1].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[2].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;

        update aList;
        Contact c = [SELECT ID FROM Contact][0];

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.Account_Domain__C = aList[4].Email_Domain__c;
        quote.ERP_Contact_First_Name__c = 'John';
        quote.ERP_Contact_Last_Name__c = 'Doe';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = 'contact@coolcompany.com';
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.ConversionProbability__c = 0.95;
        quote.UserDUNSNumber__c = '012345678';

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote_ERP__c qResult = [
            SELECT Id, AccountID__c, ContactID__c, ContactID__r.AccountID
            FROM Quote_ERP__c
            WHERE Id = :quote.Id
        ];
        System.assertEquals(aList[0].Id, qResult.AccountID__c, 'Account is not from duns');
        System.assertNotEquals(c.Id, qResult.ContactId__c, 'New contact was not created');
        System.assertEquals(
            qResult.AccountID__c,
            qResult.ContactID__r.AccountID,
            'Contact acct should match quote acct'
        );
    }

    @isTest
    public static void quoteWithDuns_relatesDUNSAccountAndContact() {
        DNBConnect__D_B_Connect_Company_Profile__c cRecord = new DNBConnect__D_B_Connect_Company_Profile__c();
        cRecord.DNBConnect__PrimName__c = 'Test';
        cRecord.DNBConnect__DUNSNumber__c = '012345678';

        insert cRecord;

        List<Account> aList = [SELECT Id, DNBConnect__D_B_Connect_Company_Profile__c, Email_Domain__c FROM Account];
        aList[0].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[1].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;
        aList[2].DNBConnect__D_B_Connect_Company_Profile__c = cRecord.Id;

        update aList;
        Contact c = [SELECT ID, FirstName, LastName, Email, AccountId FROM Contact][0];

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.Account_Domain__C = aList[1].Email_Domain__c;
        quote.ERP_Contact_First_Name__c = c.FirstName;
        quote.ERP_Contact_Last_Name__c = c.LastName;
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = c.Email;
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.ConversionProbability__c = 0.95;
        quote.UserDUNSNumber__c = '012345678';

        Test.startTest();
        insert quote;
        Test.stopTest();

        Quote_ERP__c qResult = [
            SELECT Id, AccountID__c, ContactID__c, ContactID__r.AccountID
            FROM Quote_ERP__c
            WHERE Id = :quote.Id
        ];
        System.assertEquals(aList[1].Id, qResult.AccountID__c, 'Account is not from duns');
        System.assertEquals(c.Id, qResult.ContactId__c, 'Contact was not correctly associated');
        System.assertEquals(
            qResult.AccountID__c,
            qResult.ContactID__r.AccountID,
            'Contact acct should match quote acct'
        );
    }

    @isTest
    public static void deletedQuoteAssociatesToExistingOpp() {
        Contact c = [SELECT ID, FirstName, LastName, Email, AccountId FROM Contact][0];

        Quote_ERP__c quote = new Quote_ERP__C();
        quote.Xometry_ERP_ID__C = 'Q12-333-4444';
        quote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        quote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        quote.ERP_Contact_First_Name__c = c.FirstName;
        quote.ERP_Contact_Last_Name__c = c.LastName;
        quote.Account_Domain__C = 'quickiemail.com';
        quote.ERP_Contact__C = 'BBBBB';
        quote.ERP_PartPk__c = '56564-55667';
        quote.Is_Generic__c = false;
        quote.Quote_Email__c = c.Email;
        quote.process_isPolyJet_3D__c = true;
        quote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        quote.Quoted_Total_Amt_Stamping__c = 1234.00;
        quote.Quoted_Total_Qty_PolyJet3D__c = 3;
        quote.Quoted_Total_Qty_Stamping__c = 1;
        quote.Quote_Type__c = 'Auto-Quoted';
        quote.ConversionProbability__c = 0.95;

        insert quote;

        delete quote;

        Quote_ERP__c newQuote = new Quote_ERP__C();
        newquote.Xometry_ERP_ID__C = 'Q12-333-4444';
        newQuote.Quote_ERP_Created_Date__c = date.newInstance(2021, 8, 1);
        newQuote.Quote_ERP_Created_Time__c = dateTime.newInstance(2021, 8, 1, 10, 0, 30);
        newQuote.ERP_Contact_First_Name__c = c.FirstName;
        newQuote.ERP_Contact_Last_Name__c = c.LastName;
        newQuote.Account_Domain__C = 'quickiemail.com';
        newQuote.ERP_Contact__C = 'BBBBB';
        newQuote.ERP_PartPk__c = '56564-55667';
        newQuote.Is_Generic__c = false;
        newQuote.Quote_Email__c = c.Email;
        newQuote.process_isPolyJet_3D__c = true;
        newQuote.Quoted_Total_Amt_PolyJet3D__c = 5678.00;
        newQuote.Quoted_Total_Amt_Stamping__c = 1234.00;
        newQuote.Quoted_Total_Qty_PolyJet3D__c = 3;
        newQuote.Quoted_Total_Qty_Stamping__c = 1;
        newQuote.Quote_Type__c = 'Auto-Quoted';
        newQuote.ConversionProbability__c = 0.95;

        Test.startTest();
        insert newQuote;
        Test.stopTest();

        List<Opportunity> oppResult = [SELECT Id FROM Opportunity];

        System.assertEquals(1, oppResult.size(), 'Opp should only exist once, not twice.');
    }

    @isTest
    private static void lastNameNull() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__c = 'Q12-333-4444';
        insert myQuote;

        ID quoteContactId = [SELECT Id, ContactId__c FROM Quote_ERP__c WHERE Id = :myQuote.Id][0].ContactID__c;
        System.debug(quoteContactId);
        Contact cPre2Quote = [SELECT Id, FirstName, LastName FROM Contact WHERE Id = :quoteContactId][0];

        Test.startTest();

        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(false);
        myQuote3.Xometry_ERP_ID__c = 'Q12-333-6666';
        myQuote3.ERP_Contact_Last_Name__c = null;
        insert myQuote3;

        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(false);
        myQuote2.Xometry_ERP_ID__c = 'Q12-333-5555';
        myQuote2.ERP_Contact_Last_Name__c = 'Last Name';
        insert myQuote2;

        Test.stopTest();

        ID quote2ContactId = [SELECT Id, ContactId__c FROM Quote_ERP__c WHERE Id = :myQuote.Id][0].ContactID__c;
        Contact cResult = [SELECT Id, FirstName, LastName FROM Contact WHERE Id = :quote2ContactId][0];
        System.assertEquals(
            myQuote2.ERP_Contact_Last_Name__c,
            cResult.LastName,
            'Contact last name should not be an email'
        );
        System.assertEquals(
            0,
            [
                    SELECT
                        ID,
                        name,
                        module__C,
                        dev_audit_notes__c,
                        statusCode__c,
                        errorFields__c,
                        errorMessage__c,
                        Createddate
                    FROM audit_trail_error__c
                ]
                .size(),
            'audit trail should be 0'
        );
    }

    @isTest
    static void ReqManualAndSuppressOpps() {
        Contact contactTest = [
            SELECT Id, Primary_Email__c, Suppress_Opps_and_Leads_Flag__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        System.debug('contactTest ' + contactTest);
        contactTest.Suppress_Opps_and_Leads_Flag__c = true;
        update contactTest;

        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe0@supercompany0.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = false;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);

        List<Case> caseList = [SELECT Id FROM Case];
        List<Opportunity> opportunityList = [SELECT Id FROM Opportunity];
        System.assertEquals(0, caseList.size(), 'There is already a case created');
        System.assertEquals(0, opportunityList.size(), 'There is already an opportunity created');

        Test.startTest();
        insert myQuote;
        Test.stopTest();

        Case updatedCase = [
            SELECT Id, Opportunity__c
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :myQuote.Xometry_ERP_ID__C
        ];
        System.assertNotEquals(null, updatedCase.Opportunity__c, 'The opp was not associated to the case');
    }

    @isTest
    static void PSECaseNotCreated() {
        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'AAAAA-00001';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe@superaccount.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = true;
        myQuote.Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14);
        myQuote.process_isCNC_Machining__c = true;
        myQuote.Quoted_Total_Amt_CNC__c = 50.15;
        myQuote.Quoted_Total_Qty_CNC__c = 1;
        myQuote.Requested_Manual_Quote_Flag__c = true;
        myQuote.Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0);
        insert myQuote;

        Case caseRelated = [
            SELECT Id, Opportunity__c
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c = :myQuote.Xometry_ERP_ID__C
        ];
        delete caseRelated;

        Test.startTest();
        myQuote.DFM_Description__c += ', modified record';
        update myQuote;
        Test.stopTest();

        List<Case> lstCaseRelated = [SELECT Id FROM Case WHERE Shadow_Xometry_ERP_ID__c = :myQuote.Xometry_ERP_ID__C];
        System.assertEquals(1, lstCaseRelated.size(), 'The case was not created in the update');
    }

    @isTest
    static void syncDFMOppsAndContactFields() {
        Contact contactTest = [
            SELECT Id, Primary_Email__c, Suppress_Opps_and_Leads_Flag__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        System.debug('contactTest ' + contactTest);

        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'AAAAA-00001';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe0@supercompany0.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = false;
        myQuote.Quote_ERP_Created_Date__c = System.today().addDays(-2);
        myQuote.Quote_ERP_Created_Time__c = System.now().addDays(-2);
        insert myQuote;

        contactTest = [
            SELECT Id, DFM_Description__c, DFM_Quote__c, Date_of_Last_DFM_Quote__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        List<Opportunity> opportunityList = [SELECT Id, DFM_Description__c FROM Opportunity];
        System.assertEquals(
            myQuote.Xometry_ERP_ID__C,
            contactTest.DFM_Quote__c,
            'The DFM_Quote__c not is fill correctly'
        );
        System.assertEquals(
            myQuote.DFM_Description__c,
            contactTest.DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        System.assertEquals(
            myQuote.Quote_ERP_Created_Time__c,
            contactTest.Date_of_Last_DFM_Quote__c,
            'The Quote_ERP_Created_Time__c not is fill correctly'
        );
        System.assertEquals(1, opportunityList.size(), 'Quantity of Opportunities not is correctly');
        System.assertEquals(
            myQuote.DFM_Description__c,
            opportunityList[0].DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );

        Test.startTest();
        Quote_ERP__c myQuote1 = TestDataFactory.createQuote(false);
        myQuote1.Xometry_ERP_ID__C = 'AAAAA-00002';
        myQuote1.Account_Domain__C = 'SuperAccount';
        myQuote1.Quote_Email__c = 'johndoe0@supercompany0.com';
        myQuote1.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that. Test 2';
        myQuote1.LineItemCount__c = 1;
        myQuote1.Reorder__c = true;
        myQuote1.Requote__c = false;
        myQuote1.Quote_ERP_Created_Date__c = System.today().addDays(-3);
        myQuote1.Quote_ERP_Created_Time__c = System.now().addDays(-3);
        insert myQuote1;

        contactTest = [
            SELECT Id, DFM_Description__c, DFM_Quote__c, Date_of_Last_DFM_Quote__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        opportunityList = [
            SELECT Id, DFM_Description__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :myQuote1.Xometry_ERP_ID__c
        ];
        System.assertEquals(
            myQuote.Xometry_ERP_ID__C,
            contactTest.DFM_Quote__c,
            'The Xometry_ERP_ID__C not is fill correctly'
        );
        System.assertEquals(
            myQuote.DFM_Description__c,
            contactTest.DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        System.assertEquals(
            myQuote.Quote_ERP_Created_Time__c,
            contactTest.Date_of_Last_DFM_Quote__c,
            'The Quote_ERP_Created_Time__c not is fill correctly'
        );
        System.assertEquals(1, opportunityList.size(), 'Quantity of Opportunities not is correctly');
        System.assertEquals(
            myQuote1.DFM_Description__c,
            opportunityList[0].DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );

        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(false);
        myQuote2.Xometry_ERP_ID__C = 'AAAAA-00003';
        myQuote2.Account_Domain__C = 'SuperAccount';
        myQuote2.Quote_Email__c = 'johndoe0@supercompany0.com';
        myQuote2.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that. Test 3';
        myQuote2.LineItemCount__c = 1;
        myQuote2.Reorder__c = true;
        myQuote2.Requote__c = false;
        myQuote2.Quote_ERP_Created_Date__c = System.today().addDays(-1);
        myQuote2.Quote_ERP_Created_Time__c = System.now().addDays(-1);
        insert myQuote2;

        contactTest = [
            SELECT Id, DFM_Description__c, DFM_Quote__c, Date_of_Last_DFM_Quote__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        opportunityList = [
            SELECT Id, DFM_Description__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :myQuote2.Xometry_ERP_ID__c
        ];
        System.assertEquals(
            myQuote2.Xometry_ERP_ID__C,
            contactTest.DFM_Quote__c,
            'The Xometry_ERP_ID__C not is fill correctly'
        );
        System.assertEquals(
            myQuote2.DFM_Description__c,
            contactTest.DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        System.assertEquals(
            myQuote2.Quote_ERP_Created_Time__c,
            contactTest.Date_of_Last_DFM_Quote__c,
            'The Quote_ERP_Created_Time__c not is fill correctly'
        );
        System.assertEquals(
            myQuote2.DFM_Description__c,
            opportunityList[0].DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );

        myQuote1.DFM_Description__c = 'New DFM_Description__c myQuote1';
        update myQuote1;

        contactTest = [
            SELECT Id, DFM_Description__c, DFM_Quote__c, Date_of_Last_DFM_Quote__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        opportunityList = [
            SELECT Id, DFM_Description__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :myQuote1.Xometry_ERP_ID__c
        ];
        System.assertEquals(
            myQuote2.Xometry_ERP_ID__C,
            contactTest.DFM_Quote__c,
            'The Xometry_ERP_ID__C not is fill correctly'
        );
        System.assertEquals(
            myQuote2.DFM_Description__c,
            contactTest.DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        System.assertEquals(
            myQuote2.Quote_ERP_Created_Time__c,
            contactTest.Date_of_Last_DFM_Quote__c,
            'The Quote_ERP_Created_Time__c not is fill correctly'
        );
        System.assertEquals(1, opportunityList.size(), 'Quantity of Opportunities not is correctly');
        System.assertEquals(
            myQuote1.DFM_Description__c,
            opportunityList[0].DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );

        myQuote2.DFM_Description__c = 'New DFM_Description__c myQuote2';
        update myQuote2;
        Test.stopTest();

        contactTest = [
            SELECT Id, DFM_Description__c, DFM_Quote__c, Date_of_Last_DFM_Quote__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        opportunityList = [
            SELECT Id, DFM_Description__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :myQuote2.Xometry_ERP_ID__c
        ];
        System.assertEquals(
            myQuote2.Xometry_ERP_ID__C,
            contactTest.DFM_Quote__c,
            'The Xometry_ERP_ID__C not is fill correctly'
        );
        System.assertEquals(
            myQuote2.DFM_Description__c,
            contactTest.DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        System.assertEquals(
            myQuote2.Quote_ERP_Created_Time__c,
            contactTest.Date_of_Last_DFM_Quote__c,
            'The Quote_ERP_Created_Time__c not is fill correctly'
        );
        System.assertEquals(
            myQuote2.DFM_Description__c,
            opportunityList[0].DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
    }

    @isTest
    static void syncDFMOppsAndContactFieldsMassive() {
        Contact contactTest = [
            SELECT Id, Primary_Email__c, Suppress_Opps_and_Leads_Flag__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        System.debug('contactTest ' + contactTest);

        List<Quote_ERP__c> lstQuotes = new List<Quote_ERP__c>();

        Quote_ERP__c myQuote = TestDataFactory.createQuote(false);
        myQuote.Xometry_ERP_ID__C = 'AAAAA-00001';
        myQuote.Account_Domain__C = 'SuperAccount';
        myQuote.Quote_Email__c = 'johndoe0@supercompany0.com';
        myQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        myQuote.LineItemCount__c = 1;
        myQuote.Reorder__c = true;
        myQuote.Requote__c = false;
        myQuote.Quote_ERP_Created_Date__c = System.today().addDays(-2);
        myQuote.Quote_ERP_Created_Time__c = System.now().addDays(-2);
        lstQuotes.add(myQuote);

        Quote_ERP__c myQuote1 = TestDataFactory.createQuote(false);
        myQuote1.Xometry_ERP_ID__C = 'AAAAA-00002';
        myQuote1.Account_Domain__C = 'SuperAccount';
        myQuote1.Quote_Email__c = 'johndoe0@supercompany0.com';
        myQuote1.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that. Test 2';
        myQuote1.LineItemCount__c = 1;
        myQuote1.Reorder__c = true;
        myQuote1.Requote__c = false;
        myQuote1.Quote_ERP_Created_Date__c = System.today().addDays(-1);
        myQuote1.Quote_ERP_Created_Time__c = System.now().addDays(-1);
        lstQuotes.add(myQuote1);

        Quote_ERP__c myQuote2 = TestDataFactory.createQuote(false);
        myQuote2.Xometry_ERP_ID__C = 'AAAAA-00003';
        myQuote2.Account_Domain__C = 'SuperAccount';
        myQuote2.Quote_Email__c = 'johndoe0@supercompany0.com';
        myQuote2.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that. Test 3';
        myQuote2.LineItemCount__c = 1;
        myQuote2.Reorder__c = true;
        myQuote2.Requote__c = false;
        myQuote2.Quote_ERP_Created_Date__c = System.today().addDays(-3);
        myQuote2.Quote_ERP_Created_Time__c = System.now().addDays(-3);
        lstQuotes.add(myQuote2);

        Test.startTest();
        insert lstQuotes;
        contactTest = [
            SELECT Id, DFM_Description__c, DFM_Quote__c, Date_of_Last_DFM_Quote__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        List<Opportunity> opportunityList = [
            SELECT Id, DFM_Description__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :myQuote2.Xometry_ERP_ID__c
        ];
        System.assertEquals(
            myQuote1.Xometry_ERP_ID__C,
            contactTest.DFM_Quote__c,
            'The Xometry_ERP_ID__C not is fill correctly'
        );
        System.assertEquals(
            myQuote1.DFM_Description__c,
            contactTest.DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        System.assertEquals(
            myQuote1.Quote_ERP_Created_Time__c,
            contactTest.Date_of_Last_DFM_Quote__c,
            'The Quote_ERP_Created_Time__c not is fill correctly'
        );
        System.assertEquals(
            myQuote2.DFM_Description__c,
            opportunityList[0].DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        lstQuotes[0].DFM_Description__c = 'Quote1 Description';
        lstQuotes[1].DFM_Description__c = 'Quote2 Description';
        lstQuotes[2].DFM_Description__c = 'Quote3 Description';
        update lstQuotes;
        Test.stopTest();

        contactTest = [
            SELECT Id, DFM_Description__c, DFM_Quote__c, Date_of_Last_DFM_Quote__c
            FROM Contact
            WHERE Primary_Email__c = 'johndoe0@supercompany0.com'
        ];
        System.debug('Post update Contacts');
        System.debug(contactTest);
        opportunityList = [
            SELECT Id, DFM_Description__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :myQuote2.Xometry_ERP_ID__c
        ];
        System.assertEquals(
            lstQuotes[1].Xometry_ERP_ID__C,
            contactTest.DFM_Quote__c,
            'The Xometry_ERP_ID__C not is fill correctly'
        );
        System.assertEquals(
            lstQuotes[1].DFM_Description__c,
            contactTest.DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
        System.assertEquals(
            lstQuotes[1].Quote_ERP_Created_Time__c,
            contactTest.Date_of_Last_DFM_Quote__c,
            'The Quote_ERP_Created_Time__c not is fill correctly'
        );
        System.assertEquals(
            lstQuotes[2].DFM_Description__c,
            opportunityList[0].DFM_Description__c,
            'The DFM_Description__c not is fill correctly'
        );
    }

    @isTest
    public static void lineOfBusiness_ExistingOpp() {
        Account acct = [SELECT Id, Email_Domain__c, OwnerId FROM Account][0];
        Contact con = [SELECT Id, FirstName, LastName, Email FROM Contact][0];
        Opportunity opp = TestDataFactory.createOpportunity(true, con.Id, acct.Id, acct.OwnerId, Date.today());

        Opportunity oppPreQuote = [SELECT Id, Line_of_Business__c FROM Opportunity WHERE Id = :opp.Id][0];
        System.assertEquals(null, oppPreQuote.Line_of_Business__c, 'Pre quote lob is not populated');
        Test.startTest();
        Quote_ERP__c quote = TestDataFactory.createQuote(
            false,
            acct.Email_Domain__c,
            con.FirstName,
            con.LastName,
            con.Email
        );
        quote.Line_of_Business__c = 'Instant Quote';
        quote.Xometry_ERP_ID__c = 'Q12-1234-1234';
        insert quote;
        Test.stopTest();

        Opportunity oppPostQuote = [SELECT Id, Line_of_Business__c FROM Opportunity WHERE Id = :opp.Id][0];
        System.assertEquals('Instant Quote', oppPostQuote.Line_of_Business__c, 'Post quote lob is not Instant Quote');
    }

    @isTest(seeAllData=false)
    static void cpcContactQuotes() {
        // Create an Account that is owned by a Sales Rep with an existing Contact
        List<Account> testAccountList = [SELECT ID, email_domain__c FROM Account LIMIT 1];
        Account testAccount = testAccountList[0];
        String testDomain = testAccount.email_domain__c;
        // Create a CPC contact
        String testEmail = 'johnsmith@' + testDomain;
        Contact testContact = new Contact();
        testContact.email = testEmail;
        testContact.leadsource = 'CPC';
        testContact.ownerId = AppConstants.CPC_HOUSE_USER;
        testContact.lastName = 'Smith';
        testContact.firstName = 'John';
        testContact.AccountID = testAccount.ID;
        insert testContact;
        Test.startTest();
        Quote_ERP__C testQuote = TestDataFactory.createQuote(false, testDomain, 'John', 'Smith', testEmail);
        testQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        testQuote.IS_Generic__c = false;
        insert TestQuote;
        Test.stopTest();
        Opportunity resultOpp = [
            SELECT ID, Account.OwnerId, OwnerId, Primary_Contact__r.First_Quote_Date__c, Last_Quote_Xometry_ERP_ID__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :testQuote.Xometry_ERP_ID__C
        ][0];
        // Have the CPC contact quote
        // Contact shall have date of first quote and still be owned by CPC
        // Opportunity shall be owned by CPC user
        System.assertEquals(AppConstants.CPC_HOUSE_USER, resultOpp.OwnerId, 'The Opp is not owned by CPC House');
        System.assertEquals(
            testQuote.Quote_ERP_Created_Date__c,
            resultOpp.Primary_Contact__r.First_Quote_Date__c,
            'The Opp is not owned by CPC House'
        );
    }

    @isTest
    public static void updateGetSiteDeletedTest() {
        Account acct = [SELECT Id, Email_Domain__c, OwnerId FROM Account][0];
        Contact con = [SELECT Id, FirstName, LastName, Email FROM Contact][0];

        Test.startTest();
        Quote_ERP__c quote = TestDataFactory.createQuote(
            false,
            acct.Email_Domain__c,
            con.FirstName,
            con.LastName,
            con.Email
        );
        quote.Xometry_ERP_ID__c = 'Q12-1234-1234';
        quote.getSite_Deleted__c = true;

        Quote_ERP__c quote2 = TestDataFactory.createQuote(
            false,
            acct.Email_Domain__c,
            con.FirstName,
            con.LastName,
            con.Email
        );
        quote2.Xometry_ERP_ID__c = 'Q12-1234-1235';
        quote2.getSite_Deleted__c = true;

        insert new List<Quote_ERP__c>{ quote, quote2 };

        quote2.getSite_Deleted__c = false;
        update quote2;
        Test.stopTest();

        Map<String, Opportunity> oppTestResultMap = new Map<String, Opportunity>();
        for (Opportunity oppTestResult : [SELECT Last_Quote_Xometry_ERP_ID__c, getSite_Deleted__c FROM Opportunity]) {
            oppTestResultMap.put(oppTestResult.Last_Quote_Xometry_ERP_ID__c, oppTestResult);
        }

        System.assertEquals(
            quote.getSite_Deleted__c,
            oppTestResultMap.get(quote.Xometry_ERP_ID__c).getSite_Deleted__c,
            'Opp getSite_Deleted__c should be equal to his Quote'
        );
        System.assertEquals(
            quote2.getSite_Deleted__c,
            oppTestResultMap.get(quote2.Xometry_ERP_ID__c).getSite_Deleted__c,
            'Opp getSite_Deleted__c should be equal to his Quote'
        );
    }

    @isTest
    static void leadThenQuoteInactiveOwnerTest() {
        //Test Contact is John Doe
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
        testLead.Email = 'BobBuilder1@' + c.Account.Email_Domain__c;
        testLead.LeadSource = 'Lead Gen';
        testLead.Email_Domain__c = c.Account.Email_Domain__c;
        insert testLead;

        User u = [SELECT Id FROM User WHERE isActive = false Limit 1];
        update new Account(Id = c.AccountID, OwnerId = u.Id);
        update new Contact(Id = c.Id, OwnerId = u.Id);
        update new Lead(Id = testLead.Id, OwnerId = u.Id);

        //Lead Quotes
        Quote_ERP__c myQuote3 = TestDataFactory.createQuote(
            false,
            c.Account.Email_Domain__c,
            testLead.FirstName,
            testLead.LastName + '1',
            testLead.email
        );
        myQuote3.Xometry_ERP_ID__C = 'Q12-3333-4444';

        test.StartTest();
        insert myQuote3;
        test.StopTest();

        Integer numErrors = [SELECT COUNT() FROM Audit_Trail_Error__c WHERE Module__c = 'QuoteERPHandler'];
        System.assertEquals(0, numErrors, 'The process have errors');
        Lead convertedLead = [SELECT isConverted, ownerId, ConvertedAccountId, ConvertedContactId FROM Lead WHERE ID = :testLead.ID];
        Quote_ERP__c objQuote = [SELECT AccountID__c,ContactID__c FROM Quote_ERP__c WHERE ID = :myQuote3.ID];
        System.assertEquals(true, convertedLead.isConverted, 'The Lead was not converted');
        System.assertEquals(u.Id, convertedLead.ownerId, 'The owner is not the inactive user');
        System.assertEquals(objQuote.AccountID__c, convertedLead.ConvertedAccountId, 'The owner is not the inactive user');
        System.assertEquals(objQuote.ContactID__c, convertedLead.ConvertedContactId, 'The owner is not the inactive user');
    }

    @isTest(seeAllData=false)
    static void QuoteSourcePunchout_Test() {

        Contact testContact = new Contact();
        testContact.email = 'laegolas@xomtest.com';
        testContact.leadsource = 'CPC';
        testContact.ownerId = AppConstants.CPC_HOUSE_USER;
        testContact.lastName = 'Sindarin';
        testContact.firstName = 'Laegolas';

        Contact testContact2 = new Contact();
        testContact2.email = 'gimli@xomtest.com';
        testContact2.leadsource = 'CPC';
        testContact2.ownerId = AppConstants.CPC_HOUSE_USER;
        testContact2.lastName = 'Gloin';
        testContact2.firstName = 'Gimli';

        insert new List<Contact>{testContact, testContact2};

        Test.startTest();

        Quote_ERP__C testQuote = TestDataFactory.createQuote(false, 'xomtest.com', 'Sindarin', 'Laegolas', testContact.email);
        testQuote.Xometry_ERP_ID__C = 'Q12-3333-4444';
        testQuote.IS_Generic__c = false;
        testQuote.Quote_Source__c = AppConstants.QSRC_Punchout;
        testQuote.ContactID__C = testContact.Id;
        testQuote.Quote_ERP_Created_Time__c = System.now();


        Quote_ERP__C testQuote2 = TestDataFactory.createQuote(false, 'xomtest.com', 'Gimli', 'Gloin', testContact2.email);
        testQuote2.Xometry_ERP_ID__C = 'Q12-3333-4445';
        testQuote2.IS_Generic__c = false;
        testQuote2.Quote_Source__c = 'NO' + AppConstants.QSRC_Punchout;
        testQuote2.ContactID__C = testContact2.Id;
        testQuote2.Quote_ERP_Created_Time__c = System.now();

        insert new List<Quote_ERP__c>{testQuote,testQuote2};

        Test.stopTest();

        Map<Id, Contact> testContactResultMap = new Map<Id, Contact>([
            SELECT Has_Used_Punchout__c, First_Quote_Punchout__c
            FROM Contact
        ]);

        System.assertEquals(
            true,
            testContactResultMap.get(testContact.Id).Has_Used_Punchout__c,
            'Contact should be marked as Used Punchout'
        );

        System.assertEquals(
            true,
            testContactResultMap.get(testContact.Id).First_Quote_Punchout__c,
            'Contact should be marked as First Punchout'
        );

        System.assertEquals(
            false,
            testContactResultMap.get(testContact2.Id).Has_Used_Punchout__c,
            'Contact shouldnt be marked as First Punchout'
        );

        System.assertEquals(
            false,
            testContactResultMap.get(testContact2.Id).First_Quote_Punchout__c,
            'Contact shouldnt be marked as First Punchout'
        );

    }

    @isTest(seeAllData=false)
    static void QuoteSourceNoPunchout_Test() {

        // Create a CPC contact
        String testEmail = 'laegolas@xomtest.com';
        Contact testContact = new Contact();
        testContact.email = testEmail;
        testContact.leadsource = 'CPC';
        testContact.ownerId = AppConstants.CPC_HOUSE_USER;
        testContact.lastName = 'Sindarin';
        testContact.firstName = 'Laegolas';
        insert testContact;

        Test.startTest();

        Quote_ERP__c testQuote = TestDataFactory.createQuote(false, 'xomtest.com', 'Sindarin', 'Laegolas', testEmail);
        testQuote.Xometry_ERP_ID__c = 'Q12-3333-4444';
        testQuote.IS_Generic__c = false;
        testQuote.Quote_Source__c = AppConstants.QSRC_Punchout;
        testQuote.ContactID__c = testContact.Id;
        testQuote.Quote_ERP_Created_Date__c = System.today().addDays(1);
        testQuote.Quote_ERP_Created_Time__c = System.now().addDays(1);


        Quote_ERP__c testQuote2 = TestDataFactory.createQuote(false, 'xomtest.com', 'Sindarin', 'Laegolas', testEmail);
        testQuote2.Xometry_ERP_ID__c = 'Q12-3333-4445';
        testQuote2.IS_Generic__c = false;
        testQuote2.Quote_Source__c = 'No' + AppConstants.QSRC_Punchout;
        testQuote2.ContactID__c = testContact.Id;
        testQuote2.Quote_ERP_Created_Date__c = System.today().addDays(-1);
        testQuote2.Quote_ERP_Created_Time__c = System.now().addDays(-1);


        insert new List<Quote_ERP__c>{testQuote,testQuote2};

        Test.stopTest();

        Contact testContactResult = [SELECT Has_Used_Punchout__c, First_Quote_Punchout__c
        FROM Contact
        WHERE Id = :testContact.Id];

        System.assertEquals(
            true,
            testContactResult.Has_Used_Punchout__c,
            'Contact should be marked as Punchout'
        );

        System.assertEquals(
            false,
            testContactResult.First_Quote_Punchout__c,
            'Contact shouldnt be marked as First Punchout'
        );

    }

    @isTest(seeAllData=false)
    static void QuoteSourceNoPunchout2_Test() {

        // Create a CPC contact
        Contact testContact = new Contact();
        testContact.email = 'laegolas@xomtest.com';
        testContact.leadsource = 'CPC';
        testContact.ownerId = AppConstants.CPC_HOUSE_USER;
        testContact.lastName = 'Sindarin';
        testContact.firstName = 'Laegolas';
        insert testContact;

        Quote_ERP__c testQuote = TestDataFactory.createQuote(false, 'xomtest.com', 'Sindarin', 'Laegolas', testContact.email);
        testQuote.Xometry_ERP_ID__c = 'Q12-3333-4444';
        testQuote.IS_Generic__c = false;
        testQuote.Quote_Source__c = 'No' + AppConstants.QSRC_Punchout;
        testQuote.ContactID__c = testContact.Id;
        testQuote.Quote_ERP_Created_Time__c = System.now().addSeconds(-1);

        insert testQuote;

        Test.startTest();

        Quote_ERP__c testQuote2 = TestDataFactory.createQuote(false, 'xomtest.com', 'Sindarin', 'Laegolas', testContact.email);
        testQuote2.Xometry_ERP_ID__c = 'Q12-3333-4445';
        testQuote2.IS_Generic__c = false;
        testQuote2.Quote_Source__c = AppConstants.QSRC_Punchout;
        testQuote2.ContactID__c = testContact.Id;
        testQuote2.Quote_ERP_Created_Time__c = System.now().addSeconds(1);

        insert testQuote2;

        Test.stopTest();

        Contact testContactResult = [SELECT Has_Used_Punchout__c, First_Quote_Punchout__c
        FROM Contact
        WHERE Id = :testContact.Id];

        System.assertEquals(
            true,
            testContactResult.Has_Used_Punchout__c,
            'Contact should be marked as Punchout'
        );

        System.assertEquals(
            false,
            testContactResult.First_Quote_Punchout__c,
            'Contact shouldnt be marked as First Punchout'
        );

    }

}