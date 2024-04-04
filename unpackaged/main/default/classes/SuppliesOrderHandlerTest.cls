@isTest
public with sharing class SuppliesOrderHandlerTest {
    @isTest
    public static void basicSuppliesOrderTest() {
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        test.startTest();
        insert sOrderTest;
        test.stopTest();
        ID testID = sOrderTest.ID;
        Supplies_Order__C testSOrderResult = [
            SELECT ID, AccountID__C, P21_Account_DetailsID__c, ContactID__C, OpportunityID__C
            FROM Supplies_Order__C
            WHERE ID = :testID
        ][0];
        system.assert(!String.isblank(testSOrderResult.OpportunityID__C), 'There was no OpportunityID');
        system.assert(!String.isblank(testSOrderResult.P21_Account_DetailsID__c), 'There was no P21 Customer Created');
    }
    @isTest
    public static void basicBulkLoadTest() {
        //Cannot hit 200 do to timeouts in the Account Process Builder
        List<User> myTestUsers = TestDataFactory.createSupTestReps(5, null, null, true);
        List<Supplies_Order__C> testSOrderList = new List<Supplies_Order__C>();
        Integer testSize = 50;
        for (Integer i = 0; i < testSize; i++) {
            Supplies_Order__C sOrderTest = new Supplies_Order__C();
            sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477' + i;
            sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455' + i;
            sOrderTest.P21_ContactID__c = 'A1265' + i;
            sOrderTest.P21_CustomerID__c = 'CA144';
            sOrderTest.Order_Email__c = 'bobsmith21' + i + '@gmail.com';
            sOrderTest.Account_Domain__c = 'bobsmith21' + i + '@gmail.com';
            sOrderTest.PartnerID__c = 'P33465';
            sOrderTest.Is_Generic__c = true;
            sOrderTest.P21_Contact_First_Name__c = 'Bob';
            sOrderTest.P21_Contact_Last_Name__c = 'Smith';
            sOrderTest.P21_Contact_Phone__c = '5553334444';
            sOrderTest.P21_OE_Status__c = 'Active';
            sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
            sOrderTest.P21_Physical_City__c = 'MadeupTown';
            sOrderTest.P21_Physical_Country__c = 'United States';
            sOrderTest.P21_Physical_State__c = 'Maryland';
            sOrderTest.P21_Physical_Zip_Code__c = '23455';
            sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
            sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
            sOrderTest.Order_Total__c = 500.50;
            testSOrderList.add(sOrderTest);
        }
        test.startTest();
        insert testSOrderList;
        test.stopTest();
        AggregateResult[] aggSOrderRslt = [SELECT count(id) newSOrders FROM Supplies_Order__C];
        Integer newSOrderCount = Integer.valueOf(aggSOrderRslt[0].get('newSOrders'));
        System.assertEquals(newSOrderCount, testSize, 'There were not ' + testSize + ' supplies order created');
    }

    // Test Scenario Big Kahuna Test
    // P21 Account has an Owner.
    // Existing Supplier with Account and P21 account
    // Existing Contact with P21 account linked
    // Create  Job1.
    // Create Job2.
    // Confirm that a Supplies Opp exists and has the right P21 Account and Owner
    // Create 3 Supplies Quotes
    // 2 Quotes both linked to Job1.
    // One brand new P21 Account with a Different Owner on the Zip Matching
    // There should be 4 Opportunities now.
    // Create 7 Orders
    // 3 Linked to Existing Quotes from above
    //  1 Linked to Job2
    // 3 Brand New Orders with no prexisting Jobs or Quotes
    // 2 on Two different Contacts with the same domain
    // Check that these have the same owner
    // Other order should have a different owner then the 2 above
    // Total Opps should be 7
    @isTest
    public static void supOrderMainRegressionTest() {
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
        for (Opportunity opp : testOppListJobStart) {
            System.assertEquals(testP21Account.OwnerId, opp.OwnerID, 'Opp owner did not match as expected');
            System.assertEquals(testP21Account.Id, opp.P21_Account_Details__c, 'Opp owner did not match as expected');
            System.assertEquals(testSupplier.ID, opp.Primary_Supplier__c, 'We are missing our supplier');
        }
        System.debug('Finished Job Creation: Starting Supplies Quotes');
        // Create 3 Supplies Quotes
        // 2 Quotes both linked to Job1.
        List<Supplies_Quote__C> sQuoteTestList = new List<Supplies_Quote__C>();
        Supplies_Quote__C sQuoteTest1 = new Supplies_Quote__C();
        sQuoteTest1.P21_ERP_ID__c = 'OE23477';
        sQuoteTest1.XometryJobID__c = testJob1.XometryJobID__c;
        sQuoteTest1.P21_ContactID__c = supplier1Contact.P21_ContactID__c;
        sQuoteTest1.P21_CustomerID__c = testP21Account.P21_CustomerID__c;
        sQuoteTest1.Quote_Email__c = supplier1Contact.Primary_Email__C;
        sQuoteTest1.Account_Domain__c = testAccount1.Email_Domain__c;
        sQuoteTest1.PartnerID__c = testP21Account.PartnerID__C;
        sQuoteTest1.Is_Generic__c = false;
        sQuoteTest1.P21_Contact_First_Name__c = supplier1Contact.FirstName;
        sQuoteTest1.P21_Contact_Last_Name__c = supplier1Contact.LastName;
        sQuoteTest1.P21_Contact_Phone__c = '5553334444';
        sQuoteTest1.P21_OE_Status__c = 'Active';
        sQuoteTest1.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest1.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest1.P21_Physical_Country__c = 'United States';
        sQuoteTest1.P21_Physical_State__c = 'Maryland';
        sQuoteTest1.P21_Physical_Zip_Code__c = rRouter1.ZipCode__c;
        sQuoteTest1.Quote_P21_Created_Date__c = date.Today();
        sQuoteTest1.Quote_P21_Last_Updated_Time__c = datetime.now();
        sQuoteTest1.Quote_Price__c = 300.50;
        sQuoteTestList.add(sQuoteTest1);
        //
        Supplies_Quote__C sQuoteTest2 = new Supplies_Quote__C();
        sQuoteTest2.P21_ERP_ID__c = 'OE23478';
        sQuoteTest2.XometryJobID__c = testJob1.XometryJobID__c;
        sQuoteTest2.P21_ContactID__c = supplier1Contact.P21_ContactID__c;
        sQuoteTest2.P21_CustomerID__c = testP21Account.P21_CustomerID__c;
        sQuoteTest2.Quote_Email__c = supplier1Contact.Primary_Email__C;
        sQuoteTest2.Account_Domain__c = testAccount1.Email_Domain__c;
        sQuoteTest2.PartnerID__c = testP21Account.PartnerID__C;
        sQuoteTest2.Is_Generic__c = false;
        sQuoteTest2.P21_Contact_First_Name__c = supplier1Contact.FirstName;
        sQuoteTest2.P21_Contact_Last_Name__c = supplier1Contact.LastName;
        sQuoteTest2.P21_Contact_Phone__c = '5553334444';
        sQuoteTest2.P21_OE_Status__c = 'Active';
        sQuoteTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest2.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest2.P21_Physical_Country__c = 'United States';
        sQuoteTest2.P21_Physical_State__c = 'Maryland';
        sQuoteTest2.P21_Physical_Zip_Code__c = rRouter1.ZipCode__c;
        sQuoteTest2.Quote_P21_Created_Date__c = date.Today();
        sQuoteTest2.Quote_P21_Last_Updated_Time__c = datetime.now();
        sQuoteTest2.Quote_Price__c = 250.50;
        sQuoteTestList.add(sQuoteTest2);
        // One brand new SQuote with a new P21 Account with and has a Zip Match
        Supplies_Quote__C sQuoteTest3 = new Supplies_Quote__C();
        sQuoteTest3.P21_ERP_ID__c = 'OE23479';
        sQuoteTest3.P21_ContactID__c = 'Con123';
        sQuoteTest3.P21_CustomerID__c = 'C1112';
        sQuoteTest3.Quote_Email__c = 'madeup5@kaijumakers.com';
        sQuoteTest3.Account_Domain__c = 'kaijumakers.com';
        sQuoteTest3.PartnerID__c = 'P1234';
        sQuoteTest3.Is_Generic__c = false;
        sQuoteTest3.P21_Contact_First_Name__c = 'Mecha';
        sQuoteTest3.P21_Contact_Last_Name__c = 'Metal';
        sQuoteTest3.P21_Contact_Phone__c = '5553334244';
        sQuoteTest3.P21_OE_Status__c = 'Active';
        sQuoteTest3.P21_Physical_Address__c = '555 Test Address Slow St.';
        sQuoteTest3.P21_Physical_City__c = 'MadeupTown2';
        sQuoteTest3.P21_Physical_Country__c = 'United States';
        sQuoteTest3.P21_Physical_State__c = 'Virginia';
        sQuoteTest3.P21_Physical_Zip_Code__c = rRouter2.ZipCode__c;
        sQuoteTest3.Quote_P21_Created_Date__c = date.Today();
        sQuoteTest3.Quote_P21_Last_Updated_Time__c = datetime.now();
        sQuoteTest3.Quote_Price__c = 200.55;
        sQuoteTestList.add(sQuoteTest3);
        // Create 7 Orders
        // 3 Linked to Existing Quotes from above
        List<Supplies_Order__C> sOrderTestList = new List<Supplies_Order__C>();
        Supplies_Order__C sOrderTest1 = new Supplies_Order__C();
        sOrderTest1.P21_Quote_OE_ERP_ID__C = 'OE23477';
        SOrderTest1.P21_Order_OE_ERP_ID__c = 'OE44445';
        sOrderTest1.XometryJobID__c = testJob1.XometryJobID__c;
        sOrderTest1.P21_ContactID__c = supplier1Contact.P21_ContactID__c;
        sOrderTest1.P21_CustomerID__c = testP21Account.P21_CustomerID__c;
        sOrderTest1.Order_Email__c = supplier1Contact.Primary_Email__C;
        sOrderTest1.Account_Domain__c = testAccount1.Email_Domain__c;
        sOrderTest1.PartnerID__c = testP21Account.PartnerID__C;
        sOrderTest1.Is_Generic__c = false;
        sOrderTest1.P21_Contact_First_Name__c = supplier1Contact.FirstName;
        sOrderTest1.P21_Contact_Last_Name__c = supplier1Contact.LastName;
        sOrderTest1.P21_Contact_Phone__c = '5553334444';
        sOrderTest1.P21_OE_Status__c = 'Active';
        sOrderTest1.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest1.P21_Physical_City__c = 'MadeupTown';
        sOrderTest1.P21_Physical_Country__c = 'United States';
        sOrderTest1.P21_Physical_State__c = 'Maryland';
        sOrderTest1.P21_Physical_Zip_Code__c = rRouter1.ZipCode__c;
        sOrderTest1.Order_Date__c = date.Today();
        sOrderTest1.Order_P21_Last_Updated_Time__c = datetime.now();
        sOrderTest1.Order_Total__c = 500.50;
        sOrderTestList.add(sOrderTest1);
        Supplies_Order__C sOrderTest2 = new Supplies_Order__C();
        sOrderTest2.P21_Quote_OE_ERP_ID__C = 'OE23478';
        sOrderTest2.P21_Order_OE_ERP_ID__c = 'OE44446';
        sOrderTest2.XometryJobID__c = testJob1.XometryJobID__c;
        sOrderTest2.P21_ContactID__c = supplier1Contact.P21_ContactID__c;
        sOrderTest2.P21_CustomerID__c = testP21Account.P21_CustomerID__c;
        sOrderTest2.Order_Email__c = supplier1Contact.Primary_Email__C;
        sOrderTest2.Account_Domain__c = testAccount1.Email_Domain__c;
        sOrderTest2.PartnerID__c = testP21Account.PartnerID__C;
        sOrderTest2.Is_Generic__c = false;
        sOrderTest2.P21_Contact_First_Name__c = supplier1Contact.FirstName;
        sOrderTest2.P21_Contact_Last_Name__c = supplier1Contact.LastName;
        sOrderTest2.P21_Contact_Phone__c = '5553334444';
        sOrderTest2.P21_OE_Status__c = 'Active';
        sOrderTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest2.P21_Physical_City__c = 'MadeupTown';
        sOrderTest2.P21_Physical_Country__c = 'United States';
        sOrderTest2.P21_Physical_State__c = 'Maryland';
        sOrderTest2.P21_Physical_Zip_Code__c = rRouter1.ZipCode__c;
        sOrderTest2.Order_Date__c = date.Today();
        sOrderTest2.Order_P21_Last_Updated_Time__c = datetime.now();
        sOrderTest2.Order_Total__c = 250.50;
        sOrderTestList.add(sOrderTest2);
        Supplies_Order__C sOrderTest3 = new Supplies_Order__C();
        sOrderTest3.P21_Quote_OE_ERP_ID__C = 'OE23479';
        SOrderTest3.P21_Order_OE_ERP_ID__c = 'OE44447';
        sOrderTest3.P21_ContactID__c = 'Con123';
        sOrderTest3.P21_CustomerID__c = 'C1112';
        sOrderTest3.Order_Email__c = 'madeup5@kaijumakers.com';
        sOrderTest3.Account_Domain__c = 'kaijumakers.com';
        sOrderTest3.PartnerID__c = 'P1234';
        sOrderTest3.Is_Generic__c = false;
        sOrderTest3.P21_Contact_First_Name__c = 'Mecha';
        sOrderTest3.P21_Contact_Last_Name__c = 'Metal';
        sOrderTest3.P21_Contact_Phone__c = '5553334244';
        sOrderTest3.P21_OE_Status__c = 'Active';
        sOrderTest3.P21_Physical_Address__c = '555 Test Address Slow St.';
        sOrderTest3.P21_Physical_City__c = 'MadeupTown2';
        sOrderTest3.P21_Physical_Country__c = 'United States';
        sOrderTest3.P21_Physical_State__c = 'Virginia';
        sOrderTest3.P21_Physical_Zip_Code__c = rRouter2.ZipCode__c;
        sOrderTest3.Order_Date__c = date.Today();
        sOrderTest3.Order_P21_Last_Updated_Time__c = datetime.now();
        sOrderTest3.Order_Total__c = 2000.55;
        sOrderTestList.add(sOrderTest3);
        //  1 Linked to Job2
        Supplies_Order__C sOrderTest4 = new Supplies_Order__C();
        SOrderTest4.P21_Order_OE_ERP_ID__c = 'OE44448';
        sOrderTest4.XometryJobID__c = testJob2.XometryJobID__c;
        sOrderTest4.P21_ContactID__c = supplier1Contact.P21_ContactID__c;
        sOrderTest4.P21_CustomerID__c = testP21Account.P21_CustomerID__c;
        sOrderTest4.Order_Email__c = supplier1Contact.Primary_Email__C;
        sOrderTest4.Account_Domain__c = testAccount1.Email_Domain__c;
        sOrderTest4.PartnerID__c = testP21Account.PartnerID__C;
        sOrderTest4.Is_Generic__c = false;
        sOrderTest4.P21_Contact_First_Name__c = supplier1Contact.FirstName;
        sOrderTest4.P21_Contact_Last_Name__c = supplier1Contact.LastName;
        sOrderTest4.P21_Contact_Phone__c = '5553334444';
        sOrderTest4.P21_OE_Status__c = 'Active';
        sOrderTest4.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest4.P21_Physical_City__c = 'MadeupTown';
        sOrderTest4.P21_Physical_Country__c = 'United States';
        sOrderTest4.P21_Physical_State__c = 'Maryland';
        sOrderTest4.P21_Physical_Zip_Code__c = rRouter1.ZipCode__c;
        sOrderTest4.Order_Date__c = date.Today() - 1;
        sOrderTest4.Order_P21_Last_Updated_Time__c = datetime.now() - 1;
        sOrderTest4.Order_Total__c = 5000.50;
        sOrderTestList.add(sOrderTest4);
        // 3 Brand New Orders with no prexisting Jobs or Quotes
        for (Integer i = 0; i < 3; i++) {
            Supplies_Order__C sOrderTest = new Supplies_Order__C();
            sOrderTest.P21_Order_OE_ERP_ID__C = 'OE94455' + i;
            sOrderTest.P21_ContactID__c = 'A1265' + i;
            sOrderTest.P21_CustomerID__c = 'CA144';
            sOrderTest.Order_Email__c = 'bobsmith21' + i + '@gmail.com';
            sOrderTest.Account_Domain__c = 'bobsmith21' + i + '@gmail.com';
            sOrderTest.PartnerID__c = 'P33465';
            sOrderTest.Is_Generic__c = true;
            sOrderTest.P21_Contact_First_Name__c = 'Bob';
            sOrderTest.P21_Contact_Last_Name__c = 'Smith';
            sOrderTest.P21_Contact_Phone__c = '5553334444';
            sOrderTest.P21_OE_Status__c = 'Active';
            sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
            sOrderTest.P21_Physical_City__c = 'MadeupTown';
            sOrderTest.P21_Physical_Country__c = 'United States';
            sOrderTest.P21_Physical_State__c = 'Maryland';
            sOrderTest.P21_Physical_Zip_Code__c = '23455';
            sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
            sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
            sOrderTest.Order_Total__c = 2500.55;
            sOrderTestList.add(sOrderTest);
        }
        insert sQuoteTestList;
        System.debug('Opps Retrieved after all processing');
        List<Opportunity> fullOppList = [
            SELECT ID, AccountID, JobId__c, Primary_Contact__c, Primary_Supplier__c, OwnerID, P21_Account_Details__c
            FROM Opportunity
        ];
        System.debug('Total Opps created at Squote : ' + fullOppList.size());
        System.assertEquals(4, fullOppList.size(), 'There was not a total of 4 Opportunities');
        System.debug(fullOppList);
        // Confirm that a Supplies Opp exists and has the right P21 Account and Owner
        List<Opportunity> testOppList1 = [
            SELECT ID, AccountID, JobId__c, Primary_Contact__c, Primary_Supplier__c, OwnerID, P21_Account_Details__c
            FROM Opportunity
            WHERE JobId__c IN :jobsIDSET
        ];
        // 2 Opps from the 2 Quotes with Job1 and Job2 should have an Opp
        System.assertEquals(3, testOppList1.size(), 'We did not have 3 opps for the 2 jobs');
        for (Opportunity opp : testOppList1) {
            System.assertEquals(testP21Account.OwnerId, opp.OwnerID, 'Opp owner did not match as expected');
            System.assertEquals(testP21Account.Id, opp.P21_Account_Details__c, 'Opp owner did not match as expected');
            System.assertEquals(testSupplier.ID, opp.Primary_Supplier__c, 'We are missing our supplier');
        }
        List<Opportunity> testOppList2 = [
            SELECT ID, AccountID, JobId__c, Primary_Contact__c, Primary_Supplier__c, OwnerID, P21_Account_Details__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :sQuoteTest3.P21_ERP_ID__c
        ];
        System.assertEquals(rRouter2.User__c, testOppList2[0].OwnerID, 'The new Opp did not find the ZipCode Match');

        System.debug('Finished Squote Processing');
        test.startTest();
        insert sOrderTestList;
        test.stopTest();
        fullOppList = [
            SELECT ID, AccountID, JobId__c, Primary_Contact__c, Primary_Supplier__c, OwnerID, P21_Account_Details__c
            FROM Opportunity
        ];
        System.debug('Total Opps created at sOrder : ' + fullOppList.size());
        System.debug(fullOppList);
        // Confirm that a Supplies Opp exists and has the right P21 Account and Owner
        List<Opportunity> testOppList3 = [
            SELECT
                ID,
                AccountID,
                StageName,
                JobId__c,
                Primary_Contact__c,
                Primary_Supplier__c,
                OwnerID,
                P21_Account_Details__c
            FROM Opportunity
            WHERE JobId__c IN :jobsIDSET
        ];
        // 2 Opps from the 2 Quotes with Job1 and Job2 should have an Opp
        System.assertEquals(3, testOppList1.size(), 'We did not have 3 opps for the 2 jobs');
        for (Opportunity opp : testOppList3) {
            System.assertEquals(testP21Account.OwnerId, opp.OwnerID, 'Opp owner did not match as expected');
            System.assertEquals(testP21Account.Id, opp.P21_Account_Details__c, 'Opp owner did not match as expected');
            System.assertEquals(testSupplier.ID, opp.Primary_Supplier__c, 'We are missing our supplier');
            System.assertEquals('Closed Won', opp.StageName, 'Stage was not closed won');
        }
        System.assertEquals(7, fullOppList.size(), 'We did not have the expected amount of opportunities');
        List<Opportunity> testOppList4 = [
            SELECT
                ID,
                AccountID,
                Stagename,
                Amount,
                JobId__c,
                Primary_Contact__c,
                Primary_Supplier__c,
                OwnerID,
                P21_Account_Details__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :sQuoteTest3.P21_ERP_ID__c
        ];
        //Why isn't this empty
        System.debug('Referencing this opp should be empty');
        System.assertEquals(0, testOppList4.size(), 'There was an Opp here');
        List<Opportunity> testOppList5 = [
            SELECT
                ID,
                AccountID,
                Stagename,
                Amount,
                JobId__c,
                Primary_Contact__c,
                Primary_Supplier__c,
                OwnerID,
                P21_Account_Details__c
            FROM Opportunity
            WHERE Last_Quote_Xometry_ERP_ID__c = :SOrderTest3.P21_Order_OE_ERP_ID__c
        ];
        System.assertEquals(rRouter2.User__c, testOppList5[0].OwnerID, 'The new Opp did not find the ZipCode Match');
        System.assertEquals('Closed Won', testOppList5[0].StageName, 'Stage was not closed won');
        System.assertEquals(
            sOrderTest3.Order_Total__c,
            testOppList5[0].Amount,
            'The new Opp did not have the update amount'
        );
    }

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

        // Create a Supplies Order
        // The existing Contact shall be linked to the P21 Account and the P21 Account shall link to the existing Contact
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = testMSQuote.Quote_Email__c;
        sOrderTest.Account_Domain__c = testMSQuote.Account_Domain__c;
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = false;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Processing';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        test.startTest();
        insert sOrderTest;
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
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        insert sOrderTest;

        sOrderTest.Order_Total__c = 123.45;

        test.startTest();
        update sOrderTest;
        test.stopTest();

        Opportunity oppResult = [
            SELECT ID, Amount
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest.P21_Order_OE_ERP_ID__C
        ];

        Supplies_Order__C ordResult = [
            SELECT Id, OpportunityID__c
            FROM Supplies_Order__c
            WHERE P21_Order_OE_ERP_ID__C = 'OE24455'
        ];

        System.assertEquals(123.45, oppResult.Amount, 'The opp Amount did not update when the order total changed');
        System.assertEquals(ordResult.OpportunityID__C, oppResult.ID);
    }

    @isTest
    static void cancelledOrderTest() {
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        insert sOrderTest;

        sOrderTest.P21_OE_Status__c = 'Canceled';

        test.startTest();
        update sOrderTest;
        test.stopTest();

        Opportunity oppResult = [
            SELECT ID, StageName
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest.P21_Order_OE_ERP_ID__C
        ];

        System.assertEquals(
            'Closed Lost',
            oppResult.StageName,
            'The opp stage did not change when the order was cancelled'
        );
    }

    @isTest
    static void uncancelledOrderTest() {
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        insert sOrderTest;

        sOrderTest.P21_OE_Status__c = 'Canceled';
        update sOrderTest;

        sOrderTest.P21_OE_Status__c = 'Active';

        test.startTest();
        update sOrderTest;
        test.stopTest();

        Opportunity oppResult = [
            SELECT ID, StageName
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest.P21_Order_OE_ERP_ID__C
        ];

        System.assertEquals(
            'Closed Won',
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

        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = testLead.Primary_Email__c;
        sOrderTest.Account_Domain__c = c.Account.Email_Domain__c;
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        test.startTest();
        insert sOrderTest;
        test.stopTest();

        Lead convertedLead = [SELECT isConverted FROM Lead WHERE ID = :testLead.ID];
        System.assertEquals(true, convertedLead.isConverted, 'The Lead was not converted');
    }
    @isTest
    static void SFPOrderTest() {
        // Scenario1:  Place a quote with a Case. Then place an order
        /* Scenario2: Create a Case that is SFP with no Opp 
        For this test Create a Case with has an Opp create an 
        Order-that has a base quote but quote is not in integration yet.
        */

        ID caseSuppliesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('SellerMarketplace')
            .getRecordTypeID();
        ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        List<User> testUserList = TestDataFactory.createSupTestReps(2, null, null, true);
        ID testRepID = testUserList[0].ID;

        //Scenario 1 Create a Case with an Opp. Add the sQuote. Then add the Order
        Opportunity preTestOpp = new Opportunity();
        preTestOpp.OwnerId = testRepID;
        preTestOpp.recordTypeID = oppSuppliesRecordTypeID;
        preTestOpp.Amount = 444.13;
        preTestOpp.name = 'Lets Get Aluminum';
        preTestOpp.StageName = 'Open';
        preTestOpp.CloseDate = date.today() + 30;
        insert preTestOpp;

        ID sce1OppID = preTestOpp.ID;

        List<Case> manQuoteCaseList = new List<Case>();
        Case manQuoteCase = new Case();
        manQuoteCase.RecordTypeID = caseSuppliesRecordTypeId;
        manQuoteCase.Shadow_P21_Quote_Id__c = 'OE23477';
        manQuoteCase.Subject = 'Looking for lots of good Aluminium';
        manQuoteCase.Origin = 'Manual';
        manQuoteCase.Type = 'RFQ-Quote';
        manQuoteCase.ownerId = testRepID;
        manQuoteCase.Opportunity__C = preTestOpp.ID;
        manQuoteCaseList.add(manQuoteCase);

        Case manQuoteCase1 = new Case();
        manQuoteCase1.RecordTypeID = caseSuppliesRecordTypeId;
        manQuoteCase1.Shadow_P21_Quote_Id__c = 'OE33477';
        manQuoteCase1.Subject = 'Looking for lots of good Aluminium and Steel';
        manQuoteCase1.Origin = 'Manual';
        manQuoteCase1.Type = 'RFQ-Quote';
        manQuoteCase1.ownerId = testRepID;
        manQuoteCaseList.add(manQuoteCase1);

        insert manQuoteCaseList;

        ID caseNoPreOPPID = manQuoteCaseList[1].ID;

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
        insert SQuoteTest;

        List<Supplies_Order__C> sOrderTestList = new List<Supplies_Order__C>();
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 600.50;
        sOrderTest.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest);

        Supplies_Order__C sOrderTest1 = new Supplies_Order__C();
        sOrderTest1.P21_Quote_OE_ERP_ID__C = 'OE33477';
        sOrderTest1.P21_Order_OE_ERP_ID__C = 'OE34455';
        sOrderTest1.P21_ContactID__c = 'A1265';
        sOrderTest1.P21_CustomerID__c = 'CA144';
        sOrderTest1.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest1.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest1.PartnerID__c = 'P33465';
        sOrderTest1.Is_Generic__c = true;
        sOrderTest1.P21_Contact_First_Name__c = 'Bob';
        sOrderTest1.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest1.P21_Contact_Phone__c = '5553334444';
        sOrderTest1.P21_OE_Status__c = 'Active';
        sOrderTest1.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest1.P21_Physical_City__c = 'MadeupTown';
        sOrderTest1.P21_Physical_Country__c = 'United States';
        sOrderTest1.P21_Physical_State__c = 'Maryland';
        sOrderTest1.P21_Physical_Zip_Code__c = '23455';
        sOrderTest1.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest1.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest1.Order_Total__c = 700.50;
        sOrderTest1.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest1);

        //Pre Order Check there should be 1 Opps
        List<AggregateResult> countOppsResult = [SELECT count(ID) FROM Opportunity];
        System.assertEquals(1, integer.valueof(countOppsResult[0].get('expr0')), 'More then 1 Opp exists');
        Test.startTest();
        insert sOrderTestList;
        Test.stopTest();

        List<AggregateResult> countOppsPostTestResult = [SELECT count(ID) FROM Opportunity];
        System.debug('Total Opps return : ' + countOppsPostTestResult);
        // Scenario 1
        Opportunity TestOpp1 = [
            SELECT
                ID,
                OwnerId,
                Amount,
                Quote_ERP_XOM_CREATE_ID__c,
                Last_Quote_Xometry_ERP_ID__c,
                Order_ERP_Xom_ID__c,
                Sup_Source_Category__c,
                StageName
            FROM Opportunity
            WHERE ID = :sce1OppID
        ];
        System.debug('Here is TestOpp1');
        System.debug(TestOpp1);
        System.assertEquals(sOrderTest.Order_Total__c, TestOpp1.Amount, 'The amount did not match the final order');
        System.assertEquals(
            sOrderTest.P21_Order_OE_ERP_ID__C,
            TestOpp1.Order_ERP_Xom_ID__c,
            'The Opp was not update with the Order information'
        );
        System.assertEquals('SFP', TestOpp1.Sup_Source_Category__c, 'The Opp did not become SFP');

        Case caseNoPreOPP = [SELECT ID, Opportunity__C FROM Case WHERE ID = :caseNoPreOPPID];
        ID caseNoPreOPPpostOppID = caseNoPreOPP.Opportunity__C;

        Opportunity TestOpp2 = [
            SELECT
                ID,
                OwnerId,
                Amount,
                Quote_ERP_XOM_CREATE_ID__c,
                Last_Quote_Xometry_ERP_ID__c,
                Order_ERP_Xom_ID__c,
                Sup_Source_Category__c,
                StageName
            FROM Opportunity
            WHERE ID = :caseNoPreOPPpostOppID
        ];

        System.assertEquals(
            sOrderTest1.Order_Total__c,
            TestOpp2.Amount,
            'Opp2 The amount did not match the final order'
        );
        System.assertEquals(
            sOrderTest1.P21_Order_OE_ERP_ID__C,
            TestOpp2.Order_ERP_Xom_ID__c,
            'Opp2 The Opp was not update with the Order information'
        );
        System.assertEquals('SFP', TestOpp2.Sup_Source_Category__c, 'Opp2 The Opp did not become SFP');

        System.assertEquals(
            2,
            integer.valueof(countOppsPostTestResult[0].get('expr0')),
            'There were not exactly 2 opps'
        );
    }

    @isTest
    static void SFPOrderBadLinkingTest() {
        /*This test assumes that a rep made a mistake with the Opp linking and assigned two manual quote cases by accident
         to the same Opp. The SFP Orders need to still resolve and still end with two Opps */

        ID caseSuppliesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('SellerMarketplace')
            .getRecordTypeID();
        ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        List<User> testUserList = TestDataFactory.createSupTestReps(2, null, null, true);
        ID testRepID = testUserList[0].ID;

        //Scenario 1 Create a Case with an Opp. Add the sQuote. Then add the Order
        Opportunity preTestOpp = new Opportunity();
        preTestOpp.OwnerId = testRepID;
        preTestOpp.recordTypeID = oppSuppliesRecordTypeID;
        preTestOpp.Amount = 444.13;
        preTestOpp.name = 'Lets Get Aluminum';
        preTestOpp.StageName = 'Open';
        preTestOpp.CloseDate = date.today() + 30;
        insert preTestOpp;

        ID sce1OppID = preTestOpp.ID;

        List<Case> manQuoteCaseList = new List<Case>();
        Case manQuoteCase = new Case();
        manQuoteCase.RecordTypeID = caseSuppliesRecordTypeId;
        manQuoteCase.Shadow_P21_Quote_Id__c = 'OE23477';
        manQuoteCase.Subject = 'Looking for lots of good Aluminium';
        manQuoteCase.Origin = 'Manual';
        manQuoteCase.Type = 'RFQ-Quote';
        manQuoteCase.ownerId = testRepID;
        manQuoteCase.Opportunity__C = preTestOpp.ID;
        manQuoteCaseList.add(manQuoteCase);

        Case manQuoteCase1 = new Case();
        manQuoteCase1.RecordTypeID = caseSuppliesRecordTypeId;
        manQuoteCase1.Shadow_P21_Quote_Id__c = 'OE33477';
        manQuoteCase1.Subject = 'Looking for lots of good Aluminium and Steel';
        manQuoteCase1.Origin = 'Manual';
        manQuoteCase1.Type = 'RFQ-Quote';
        manQuoteCase1.ownerId = testRepID;
        //Alert this single field is the difference between the test class above!
        manQuoteCase1.Opportunity__C = preTestOpp.ID;
        manQuoteCaseList.add(manQuoteCase1);

        insert manQuoteCaseList;

        ID caseNoPreOPPID = manQuoteCaseList[1].ID;

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
        insert SQuoteTest;

        List<Supplies_Order__C> sOrderTestList = new List<Supplies_Order__C>();
        Set<String> testOrderERPIDSet = new Set<String>();
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        testOrderERPIDSet.add(sOrderTest.P21_Order_OE_ERP_ID__C);
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 600.50;
        sOrderTest.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest);

        Supplies_Order__C sOrderTest1 = new Supplies_Order__C();
        sOrderTest1.P21_Quote_OE_ERP_ID__C = 'OE33477';
        sOrderTest1.P21_Order_OE_ERP_ID__C = 'OE34455';
        testOrderERPIDSet.add(sOrderTest1.P21_Order_OE_ERP_ID__C);
        sOrderTest1.P21_ContactID__c = 'A1265';
        sOrderTest1.P21_CustomerID__c = 'CA144';
        sOrderTest1.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest1.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest1.PartnerID__c = 'P33465';
        sOrderTest1.Is_Generic__c = true;
        sOrderTest1.P21_Contact_First_Name__c = 'Bob';
        sOrderTest1.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest1.P21_Contact_Phone__c = '5553334444';
        sOrderTest1.P21_OE_Status__c = 'Active';
        sOrderTest1.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest1.P21_Physical_City__c = 'MadeupTown';
        sOrderTest1.P21_Physical_Country__c = 'United States';
        sOrderTest1.P21_Physical_State__c = 'Maryland';
        sOrderTest1.P21_Physical_Zip_Code__c = '23455';
        sOrderTest1.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest1.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest1.Order_Total__c = 600.50;
        sOrderTest1.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest1);

        //Pre Order Check there should be 1 Opps
        List<AggregateResult> countOppsResult = [SELECT count(ID) FROM Opportunity];
        System.assertEquals(1, integer.valueof(countOppsResult[0].get('expr0')), 'More then 1 Opp exists');
        Test.startTest();
        insert sOrderTestList;
        Test.stopTest();

        Map<String, Opportunity> createdOppsMap = new Map<String, Opportunity>();
        for (Opportunity opp : [
            SELECT ID, Order_ERP_Xom_ID__c, amount, stagename
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c IN :testOrderERPIDSet
        ]) {
            createdOppsMap.put(opp.Order_ERP_Xom_ID__c, opp);
        }

        for (Supplies_Order__C sOrder : sOrderTestList) {
            Opportunity testOppResult = createdOppsMap.get(sOrder.P21_Order_OE_ERP_ID__C);
            System.assertEquals(sOrder.Order_Total__c, testOppResult.amount, 'The order and opp amount did not match');
            System.assertEquals('Closed Won', testOppResult.stagename, 'The Opp was not Closed Won');
        }
        // Check that each Opp with their Order has the right amount and is closed won
        List<AggregateResult> countOppsPostTestResult = [SELECT count(ID) FROM Opportunity];
        System.debug('Total Opps return : ' + countOppsPostTestResult);
        System.assertEquals(
            2,
            integer.valueof(countOppsPostTestResult[0].get('expr0')),
            'There were not exactly 2 opps'
        );
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

        List<Supplies_Order__C> sOrderTestList = new List<Supplies_Order__C>();
        Set<String> testOrderERPIDSet = new Set<String>();
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = manQuoteCase.Shadow_P21_Quote_Id__c;
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.XometryJobID__c = testJob1.XometryJobID__c;
        testOrderERPIDSet.add(sOrderTest.P21_Order_OE_ERP_ID__C);
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 600.50;
        sOrderTest.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest);

        test.startTest();
        //Create an Sorder for quote above link it to Job1
        insert sOrderTestList;
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
            SELECT
                Id,
                Stagename,
                JobId__c,
                Shadow_JobId__c,
                Quote_ERP_XOM_CREATE_ID__c,
                Last_Quote_Xometry_ERP_ID__c,
                Order_ERP_Xom_ID__c
            FROM Opportunity
            WHERE id = :testJobOpp1.ID
        ][0];
        System.assertEquals(testOppFinal.JobId__C, testJobMatchID, 'The Opp was not linked to the correct Job');
        System.assertEquals(testOppFinal.Shadow_JobId__c, sOrderTest.XometryJobID__c, 'The XomJobs did not match');
        System.assertEquals(testOppFinal.Stagename, 'Closed Won', 'The Opp was not closed won');
        System.assertEquals(
            testOppFinal.Order_ERP_Xom_ID__c,
            sOrderTest.P21_Order_OE_ERP_ID__C,
            'The Order was not on the Opp'
        );
        System.assertEquals(
            testOppFinal.Quote_ERP_XOM_CREATE_ID__c,
            sOrderTest.P21_Quote_OE_ERP_ID__C,
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
    static void removeJobonOrderUpdate() {
        //Create a Job
        // Create an Order that use Job
        // Update the order to use Job2

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
        insert jobsList;
        ID testJobMatchID = jobsList[0].Id;
        //Create a Supplies Order
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = null;
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.XometryJobID__c = testJob1.XometryJobID__c;
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 600.50;
        sOrderTest.SFP_FLAG__C = true;
        insert sOrderTest;
        test.startTest();
        Opportunity setupOpp = [
            SELECT ID, JobID__C, Shadow_JobId__c
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest.P21_Order_OE_ERP_ID__C
        ];
        //Test the data is populated at create
        system.assertEquals(testJobMatchID, setupOpp.JobId__C, 'The JobID did not match');
        system.assertEquals(testJob1.XometryJobID__c, setupOpp.Shadow_JobId__c, 'The Xometry JobID did not match');
        sOrderTest.XometryJobID__c = null;
        update sOrderTest;
        test.stopTest();
        Opportunity resultOpp1 = [
            SELECT ID, JobID__C, Shadow_JobId__c
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest.P21_Order_OE_ERP_ID__C
        ];
        system.assert(String.isblank(resultOpp1.JobId__C), 'The JobID was not set to null');
        system.assert(String.isblank(resultOpp1.Shadow_JobId__c), 'The Xometry JobID was not set to empty');
    }
    @isTest
    static void populateJobonOrderUpdate() {
        //Create a Job
        // Create Job2
        // Create an Order that use Job
        // Update the order to use Job2

        //Create a Order
        //Create Job3
        //Update order to use job3
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
        Job__C testJob3 = new Job__C();
        testJob3.XometryJobID__c = 'J00336';
        testJob3.XometryOpsOrderID__c = 'A1112-34567';
        testJob3.Name = 'Job 2 Bigger Axe';
        testJob3.AcceptedDateTime__c = DateTime.now();
        testJob3.OrderDueDate__c = Date.today() + 7;
        testJob3.AcceptedPartnerID__c = 'P1223';
        testJob3.AcceptedPrice__c = 500.35;
        testJob3.Supplier__c = testSupplier.ID;
        testJob3.OrderID__c = o.ID;
        testJob3.Stage__C = 'Accepted';
        jobsList.add(testJob3);
        insert jobsList;
        ID testJobMatchID = jobsList[0].Id;
        ID testJobUpdateID = jobsList[1].Id;
        ID testJob3UpdateID = jobsList[2].Id;
        //Create a Supplies Order
        List<Supplies_Order__C> sOrderTestList = new List<Supplies_Order__C>();
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = null;
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.XometryJobID__c = testJob1.XometryJobID__c;
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
        sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 600.50;
        sOrderTest.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest);
        Supplies_Order__C sOrderTest2 = new Supplies_Order__C();
        sOrderTest2.P21_Quote_OE_ERP_ID__C = null;
        sOrderTest2.P21_Order_OE_ERP_ID__C = 'OE24456';
        sOrderTest2.XometryJobID__c = testJob1.XometryJobID__c;
        sOrderTest2.P21_ContactID__c = 'A1265';
        sOrderTest2.P21_CustomerID__c = 'CA144';
        sOrderTest2.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest2.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest2.PartnerID__c = 'P33465';
        sOrderTest2.Is_Generic__c = true;
        sOrderTest2.P21_Contact_First_Name__c = 'Bob';
        sOrderTest2.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest2.P21_Contact_Phone__c = '5553334444';
        sOrderTest2.P21_OE_Status__c = 'Active';
        sOrderTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest2.P21_Physical_City__c = 'MadeupTown';
        sOrderTest2.P21_Physical_Country__c = 'United States';
        sOrderTest2.P21_Physical_State__c = 'Maryland';
        sOrderTest2.P21_Physical_Zip_Code__c = '23455';
        sOrderTest2.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest2.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest2.Order_Total__c = 600.50;
        sOrderTest2.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest2);
        insert sOrderTestList;
        test.startTest();
        sOrderTest.XometryJobID__c = testJob2.XometryJobID__c;
        sOrderTest2.XometryJobID__c = testJob3.XometryJobID__c;
        List<Supplies_Order__C> sOrderToUpdateList = new List<Supplies_Order__C>();
        sOrderToUpdateList.add(sOrderTest);
        sOrderToUpdateList.add(sOrderTest2);
        update sOrderToUpdateList;
        test.stopTest();
        Opportunity resultOpp1 = [
            SELECT ID, JobID__C, Shadow_JobId__c
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest.P21_Order_OE_ERP_ID__C
        ];
        system.assertEquals(testJobUpdateID, resultOpp1.JobId__C, 'The JobID did not match');
        system.assertEquals(testJob2.XometryJobID__c, resultOpp1.Shadow_JobId__c, 'The Xometry JobID did not match');
        Opportunity resultOpp2 = [
            SELECT ID, JobID__C, Shadow_JobId__c
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest2.P21_Order_OE_ERP_ID__C
        ];
        system.assertEquals(testJob3UpdateID, resultOpp2.JobID__C, 'Result2 The JobID was not added to the Opp');
        system.assertEquals(
            testJob3.XometryJobID__c,
            resultOpp2.Shadow_JobId__c,
            'Result 2 The Xometry JobID did not match'
        );
    }
      
    @isTest
    static void manyOrdersToOneQuotewithCaseTest() {
        //Have two cases that represent the same quote id
        // Create the Supplies Quote that is linked by supplies quote id to the cases above
        ID caseSuppliesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('SellerMarketplace')
            .getRecordTypeID();
        List<User> mySupTestUsers = TestDataFactory.createSupTestReps(5, null, null, true);
        List<Rep_Router__c> testRepRouteList = TestDataFactory.createRepRouterTestData(mySupTestUsers, 'Supplies', 1);
        Rep_Router__c rRouter1 = testRepRouteList[0];
        Rep_Router__c rRouter2 = testRepRouteList[1];
        Case testCase = new Case();
        testCase.Shadow_P21_Quote_Id__c = 'OE11115';
        testCase.RecordTypeID = caseSuppliesRecordTypeId;
        testCase.Subject = 'Looking for lots of good Aluminium';
        testCase.Origin = 'Manual';
        testCase.Type = 'RFQ-Quote';
        testCase.ownerId = rRouter1.User__c;
        Case testCase2 = new Case();
        testCase2.Shadow_P21_Quote_Id__c = 'OE11115';
        testCase2.RecordTypeID = caseSuppliesRecordTypeId;
        testCase2.Subject = 'Looking for lots of good AluminiumDup';
        testCase2.Origin = 'Manual';
        testCase2.Type = 'RFQ-Quote';
        testCase.ownerId = rRouter1.User__c;
        List<Case> testCaseList = new List<Case>();
        testCaseList.add(testCase);
        testCaseList.add(testCase2);
        insert TestCaseList;
        List<Supplies_Quote__C> sQuoteTestList = new List<Supplies_Quote__C>();
        Supplies_Quote__C sQuoteTest1 = new Supplies_Quote__C();
        sQuoteTest1.P21_ERP_ID__c = 'OE11115';
        sQuoteTest1.P21_ContactID__c = 'A1265';
        sQuoteTest1.P21_CustomerID__c = 'CA144';
        sQuoteTest1.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest1.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest1.PartnerID__c = 'P33465';
        sQuoteTest1.Is_Generic__c = true;
        sQuoteTest1.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest1.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest1.P21_Contact_Phone__c = '5553334444';
        sQuoteTest1.P21_OE_Status__c = 'Active';
        sQuoteTest1.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest1.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest1.P21_Physical_Country__c = 'United States';
        sQuoteTest1.P21_Physical_State__c = 'Maryland';
        sQuoteTest1.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest1.Quote_P21_Created_Date__c = date.Today();
        sQuoteTest1.Quote_P21_Last_Updated_Time__c = datetime.now();
        sQuoteTest1.Quote_Price__c = 300.50;
        sQuoteTestList.add(sQuoteTest1);
        insert sQuoteTestList;
        // Create two Supplies Orders that link to the same quote
        //Create a Supplies Order
        List<Supplies_Order__C> sOrderTestList = new List<Supplies_Order__C>();
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE11115';
            sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
            sOrderTest.Order_Date__c = date.Today();
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 600.50;
        sOrderTest.SFP_FLAG__C = false;
        sOrderTestList.add(sOrderTest);
        Supplies_Order__C sOrderTest2 = new Supplies_Order__C();
        sOrderTest2.P21_Quote_OE_ERP_ID__C = 'OE11115';
        sOrderTest2.P21_Order_OE_ERP_ID__C = 'OE24456';
        sOrderTest2.P21_ContactID__c = 'A1265';
        sOrderTest2.P21_CustomerID__c = 'CA144';
            sOrderTest2.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest2.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest2.PartnerID__c = 'P33465';
        sOrderTest2.Is_Generic__c = true;
        sOrderTest2.P21_Contact_First_Name__c = 'Bob';
        sOrderTest2.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest2.P21_Contact_Phone__c = '5553334444';
        sOrderTest2.P21_OE_Status__c = 'Active';
        sOrderTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest2.P21_Physical_City__c = 'MadeupTown';
        sOrderTest2.P21_Physical_Country__c = 'United States';
        sOrderTest2.P21_Physical_State__c = 'Maryland';
        sOrderTest2.P21_Physical_Zip_Code__c = '23455'; 
            sOrderTest2.Order_Date__c = date.Today();
        sOrderTest2.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest2.Order_Total__c = 600.50;
        sOrderTest2.SFP_FLAG__C = false;
        sOrderTestList.add(sOrderTest2);
        // Reproduce the error
        List<Case> testCasePostInsertList = [
            SELECT id, casenumber, Shadow_P21_Quote_Id__c, recordtype.name
            FROM case
            WHERE Shadow_P21_Quote_Id__c = 'OE11115'
        ];
        System.debug('Number of testcases with the shadow: ' + testCasePostInsertList.size());
        System.debug('Testcaselist');
        System.debug(testCasePostInsertList);
        Test.startTest();
        insert sOrderTestList;
        Test.stopTest();
        List<AggregateResult> numWonOpps = [SELECT count(id) numWon FROM Opportunity WHERE Stagename = 'Closed Won'];
        List<AggregateResult> numAuditErrors = [SELECT count(id) numExist FROM Audit_Trail_Error__c];
        List<Opportunity> resultOpps = [
            SELECT id, Order_ERP_Xom_ID__c, Quote_ERP_XOM_CREATE_ID__c, Stagename
            FROM Opportunity
        ];
        System.debug('Here are my resultOpps');
        System.debug(resultOpps);
        System.assertEquals(2, integer.valueof(numWonOpps[0].get('numWon')));
        System.assertEquals(0, integer.valueof(numAuditErrors[0].get('numExist')));
      }
    
      @isTest
    static void validateNotDuplicateAccount() {
       
        List<Supplies_Order__C> sOrderTestList = new List<Supplies_Order__C>();

        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = null;
            sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = 'P33465';
        sOrderTest.Is_Generic__c = true;
        sOrderTest.P21_Contact_First_Name__c = 'Bob';
        sOrderTest.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest.P21_Contact_Phone__c = '5553334444';
        sOrderTest.P21_OE_Status__c = 'Active';
        sOrderTest.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest.P21_Physical_City__c = 'MadeupTown';
        sOrderTest.P21_Physical_Country__c = 'United States';
        sOrderTest.P21_Physical_State__c = 'Maryland';
        sOrderTest.P21_Physical_Zip_Code__c = '23455';
            sOrderTest.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest.Order_Total__c = 600.50;
        sOrderTest.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest);
        
        Supplies_Order__C sOrderTest2 = new Supplies_Order__C();
        sOrderTest2.P21_Quote_OE_ERP_ID__C = null;
        sOrderTest2.P21_Order_OE_ERP_ID__C = 'OE24456';
        sOrderTest2.P21_ContactID__c = 'A1265';
        sOrderTest2.P21_CustomerID__c = 'CA145';
            sOrderTest2.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest2.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest2.PartnerID__c = 'P33465';
        sOrderTest2.Is_Generic__c = true;
        sOrderTest2.P21_Contact_First_Name__c = 'Bob';
        sOrderTest2.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest2.P21_Contact_Phone__c = '5553334444';
        sOrderTest2.P21_OE_Status__c = 'Active';
        sOrderTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest2.P21_Physical_City__c = 'MadeupTown';
        sOrderTest2.P21_Physical_Country__c = 'United States';
        sOrderTest2.P21_Physical_State__c = 'Maryland';
        sOrderTest2.P21_Physical_Zip_Code__c = '23455';
            sOrderTest2.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest2.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest2.Order_Total__c = 600.50;
        sOrderTest2.SFP_FLAG__C = true;
        sOrderTestList.add(sOrderTest2);
        
        test.startTest();
            insert sOrderTestList;
        test.stopTest();
        
        Opportunity resultOpp1 = [
            SELECT ID, JobID__C, Shadow_JobId__c,AccountId
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest.P21_Order_OE_ERP_ID__C
        ];
        
        Opportunity resultOpp2 = [
            SELECT ID, JobID__C, Shadow_JobId__c,AccountId
            FROM Opportunity
            WHERE Order_ERP_Xom_ID__c = :sOrderTest2.P21_Order_OE_ERP_ID__C
        ];

        List<Account> lstAcc = [SELECT Email_Domain__C FROM Account];
        
        system.assertEquals(
            1,
            lstAcc.size(),
            'Duplicate Account'
            );
            
        system.assertEquals(
            'bobsmith21@gmail.com',
            lstAcc[0].Email_Domain__C,
            'Email domain Account did not match'
        );

        system.assertEquals(
            resultOpp1.AccountId,
            resultOpp2.AccountId,
            'The Opportunities Accounts did not match'
        );

        Supplies_Order__C sOrderTest3 = new Supplies_Order__C();
        sOrderTest3.P21_Quote_OE_ERP_ID__C = null;
        sOrderTest3.P21_Order_OE_ERP_ID__C = 'OE24457';
        sOrderTest3.P21_ContactID__c = 'A1265';
        sOrderTest3.P21_CustomerID__c = 'CA146';
        sOrderTest3.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest3.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest3.PartnerID__c = 'P33465';
        sOrderTest3.Is_Generic__c = true;
        sOrderTest3.P21_Contact_First_Name__c = 'Bob';
        sOrderTest3.P21_Contact_Last_Name__c = 'Smith';
        sOrderTest3.P21_Contact_Phone__c = '5553334444';
        sOrderTest3.P21_OE_Status__c = 'Active';
        sOrderTest3.P21_Physical_Address__c = '555 Test Address Fast St.';
        sOrderTest3.P21_Physical_City__c = 'MadeupTown';
        sOrderTest3.P21_Physical_Country__c = 'United States';
        sOrderTest3.P21_Physical_State__c = 'Maryland';
        sOrderTest3.P21_Physical_Zip_Code__c = '23455';
        sOrderTest3.Order_Date__c = date.newInstance(2021, 10, 28);
        sOrderTest3.Order_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sOrderTest3.Order_Total__c = 600.50;
        sOrderTest3.SFP_FLAG__C = true;
        insert sOrderTest3;

        lstAcc = [SELECT Email_Domain__C FROM Account];
        
        system.assertEquals(
            1,
            lstAcc.size(),
            'Duplicate Account'
            );
      }
}