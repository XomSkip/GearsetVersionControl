@isTest
public with sharing class supRoutingTest {
    @isTest
    public static void suppliesOppsNeedRR() {
        //This test will ensure that the round robin is working appropiately
        final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        //Create 3 valid reps
        List<User> myTestUsers = TestDataFactory.createSupTestReps(3, null, null, true);

        List<Account> accountTestData = TestDataFactory.createTestAccountNonGenerics(4, 'BDR', 2);
        ID testAccount1ID = accountTestData[0].ID;
        ID testAccount2ID = accountTestData[1].ID;
        List<Contact> testContacts = [SELECT ID, AccountID FROM Contact WHERE AccountID = :testAccount1ID];
        Contact testContact2 = [SELECT ID, AccountID FROM Contact WHERE AccountID = :testAccount2ID][0];

        List<Opportunity> testOpps = new List<Opportunity>();
        //2 Contact with 3 Opps each and one additional Opp. 6 Opps should be own by 1 Supply Rep and another by one opp.
        for (Integer i = 0; i < 7; i++) {
            Opportunity testOpp = new Opportunity();
            testOpp.recordTypeID = oppSuppliesRecordTypeID;
            testOpp.StageName = 'New';
            testOpp.CloseDate = Date.Today() + 30;
            testOpp.name = 'Sup Test: ' + i;
            if (i < 3) {
                testOpp.Primary_Contact__c = testContacts[0].ID;
                testOpp.AccountID = testAccount1ID;
            } else if (i < 6) {
                testOpp.Primary_Contact__c = testContacts[1].ID;
                testOpp.AccountID = testAccount1ID;
            } else {
                testOpp.AccountID = testAccount2ID;
                testOpp.Primary_Contact__c = testContact2.ID;
            }
            testOpps.add(testOpp);
        }
        Test.StartTest();
        testOpps = routingHelper.routeSuppliesOpps(testOpps);
        insert testOpps;
        Test.StopTest();
        AggregateResult[] testResults = [
            SELECT AccountID, OwnerId, Count(ID) THE_COUNT
            FROM Opportunity
            GROUP BY AccountID, OwnerId
        ];
        System.assert(!testResults.isEmpty(), 'There were no results');
        for (AggregateResult ar : testResults) {
            ID testAccountID = ID.valueOf(String.valueOf(ar.get('AccountID')));
            if (testAccountID == testAccount1ID) {
                System.assertEquals(
                    6,
                    Integer.valueOf(String.valueOf(ar.get('THE_COUNT'))),
                    'There were not 6 accounts under the first account'
                );
            } else if (testAccountID == testAccount2ID) {
                System.assertEquals(
                    1,
                    Integer.valueOf(String.valueOf(ar.get('THE_COUNT'))),
                    'There were not 1 accounts under the second account'
                );
            } else {
                //Something went wrong and we have an extra account so hard fail here.
                System.assertEquals(0, 2, 'We should never be here');
            }
        }
    }

    @isTest
    public static void suppliesOppsNeedRR2() {
        //This test assumes that an account exists and have an existing RR marked
        final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        //Create 3 valid reps
        List<User> myTestUsers = TestDataFactory.createSupTestReps(3, null, null, true);

        List<Account> accountTestData = TestDataFactory.createTestAccountNonGenerics(4, 'BDR', 2);
        ID testAccount1ID = accountTestData[0].ID;
        ID testAccount2ID = accountTestData[1].ID;
        List<Contact> testContacts = [SELECT ID, AccountID FROM Contact WHERE AccountID = :testAccount1ID];
        Contact testContact2 = [SELECT ID, AccountID FROM Contact WHERE AccountID = :testAccount2ID][0];

        List<User> eligible_RR_USERS = [
            SELECT ID
            FROM User
            WHERE Supplies_RR_Flag__c = TRUE AND ISACTIVE = TRUE
            ORDER BY ID
        ];
        User finalUser = eligible_RR_USERS[eligible_RR_USERS.size() - 1];
        ID testAccount4ID = accountTestData[3].ID;
        Account a = new Account();
        a.ID = testAccount4ID;
        a.Non_Managed_Services_RR_OwnerID__c = finalUser.ID;
        a.Supplies_RR_Flag__c = true;
        a.RR_Batch_Num__C = 1;
        a.RR_Batch_Num_Match_Group__C = 1;
        a.RR_AssignedDate__C = datetime.now();
        update a;
        List<Opportunity> testOpps = new List<Opportunity>();
        //2 Contact with 3 Opps each and one additional Opp. 6 Opps should be own by 1 Supply Rep and another by one opp.
        for (Integer i = 0; i < 7; i++) {
            Opportunity testOpp = new Opportunity();
            testOpp.recordTypeID = oppSuppliesRecordTypeID;
            testOpp.StageName = 'New';
            testOpp.CloseDate = Date.Today() + 30;
            testOpp.name = 'Sup Test: ' + i;
            if (i < 3) {
                testOpp.Primary_Contact__c = testContacts[0].ID;
                testOpp.AccountID = testAccount1ID;
            } else if (i < 6) {
                testOpp.Primary_Contact__c = testContacts[1].ID;
                testOpp.AccountID = testAccount1ID;
            } else {
                testOpp.AccountID = testAccount2ID;
                testOpp.Primary_Contact__c = testContact2.ID;
            }
            testOpps.add(testOpp);
        }
        Test.StartTest();
        testOpps = routingHelper.routeSuppliesOpps(testOpps);
        insert testOpps;
        Test.StopTest();
        AggregateResult[] testResults = [
            SELECT AccountID, OwnerId, Count(ID) THE_COUNT
            FROM Opportunity
            GROUP BY AccountID, OwnerId
        ];
        System.assert(!testResults.isEmpty(), 'There were no results');
        for (AggregateResult ar : testResults) {
            ID testAccountID = ID.valueOf(String.valueOf(ar.get('AccountID')));
            if (testAccountID == testAccount1ID) {
                System.assertEquals(
                    6,
                    Integer.valueOf(String.valueOf(ar.get('THE_COUNT'))),
                    'There were not 6 accounts under the first account'
                );
            } else if (testAccountID == testAccount2ID) {
                System.assertEquals(
                    1,
                    Integer.valueOf(String.valueOf(ar.get('THE_COUNT'))),
                    'There were not 1 accounts under the second account'
                );
            } else {
                //Something went wrong and we have an extra account so hard fail here.
                System.assertEquals(0, 2, 'We should never be here');
            }
        }
    }

    @isTest
    public static void testTerritoryRouting() {
        //This test will ensure that the round robin is working appropiately
        final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        //Create 3 valid reps
        List<User> myTestUsers = TestDataFactory.createSupTestReps(3, null, null, true);

        List<Account> accountTestData = TestDataFactory.createTestAccountNonGenerics(4, 'BDR', 2);

        //Territory Test Data
        List<Rep_Router__c> testZipList = new List<Rep_Router__c>();
        Rep_Router__c testZip = new Rep_Router__c();
        testZip.Business_Entity__C = 'Supplies';
        testZip.ZipCode__c = '20021';
        testZip.User__c = myTestUsers[0].ID;
        testZipList.add(testZip);
        Rep_Router__c testZip2 = new Rep_Router__c();
        testZip2.Business_Entity__C = 'Supplies';
        testZip2.ZipCode__c = '20022';
        testZip2.User__c = myTestUsers[1].ID;
        testZipList.add(testZip2);
        insert testZipList;

        List<routingAddress> testRoutingList = new List<routingAddress>();
        for (Integer i = 1; i < 4; i++) {
            String sourceID = 'A' + i;
            routingAddress myTestRouting = new routingAddress('2002' + i, null, null, null, sourceID);
            testRoutingList.add(myTestRouting);
        }

        Test.startTest();
        testRoutingList = routingHelper.suppliesTerritoryRouting(testRoutingList, 'Supplies');
        Test.stopTest();

        System.debug(testRoutingList);

        for (routingAddress tr : testRoutingList) {
            System.assert(tr.routedOwnerID != null, 'There was no ownerId');
            if (tr.routingZipCode == testZip.ZipCode__c) {
                System.assertEquals(testZip.User__c, tr.routedOwnerID, 'Did not match the owner on Zipcode1');
            } else if (tr.routingZipCode == testZip2.ZipCode__c) {
                System.assertEquals(testZip2.User__c, tr.routedOwnerID, 'Did not match the owner on Zipcode2');
            } else {
                System.assertEquals(
                    tr.routedOwnerID,
                    AppConstants.SUPPLIES_HOUSE_USER,
                    'Did not match the owner for no zipcode found'
                );
            }
        }
    }

    @isTest
    public static void testLastContact() {
        // Create an Opp and have the Opp be assigned to who owns the Contact
        //This test assumes that an account exists and have an existing RR marked
        final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        //Create 3 valid reps
        List<User> myTestUsers = TestDataFactory.createSupTestReps(3, null, null, true);
        List<Account> accountTestData = TestDataFactory.createTestAccountNonGenerics(4, 'BDR', 2);
        ID testAccount1ID = accountTestData[0].ID;
        List<Contact> testContacts = [SELECT ID, AccountID FROM Contact WHERE AccountID = :testAccount1ID];
        ID testUserId = myTestUsers[0].ID;
        Opportunity testOpp1 = new Opportunity();
        testOpp1.OwnerID = testUserId;
        testOpp1.RecordTypeID = oppSuppliesRecordTypeID;
        testOpp1.Primary_Contact__c = testContacts[0].Id;
        testOpp1.AccountId = testAccount1ID;
        testOpp1.StageName = 'New';
        testOpp1.CloseDate = Date.Today() + 30;
        testOpp1.name = 'Sup Test1: ';
        insert testOpp1;
        //Create Second Opp which should end up with the same Owner
        Opportunity testOpp2 = new Opportunity();
        testOpp2.OwnerID = null;
        testOpp2.RecordTypeID = oppSuppliesRecordTypeID;
        testOpp2.Primary_Contact__c = testContacts[0].Id;
        testOpp2.AccountId = testAccount1ID;
        testOpp2.StageName = 'New';
        testOpp2.CloseDate = Date.Today() + 30;
        testOpp2.name = 'Sup Test2: ';
        List<Opportunity> testOppList = new List<Opportunity>();
        testOppList.add(testOpp2);
        Test.startTest();
        routingHelper.routeSuppliesOpps(testOppList);
        insert testOppList;
        Test.stopTest();
        ID createdOppId = testOppList[0].Id;
        Opportunity resultOpp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :createdOppId];
        System.assertEquals(testUserId, resultOpp.OwnerID, 'The owners did not match');
    }

    @isTest
    public static void testLastContactWithUpdate() {
        // Create an Opp and have the Opp be assigned to who owns the Contact. Update the Opps Owner before inserting the second Opp.

        final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        //Create 3 valid reps
        List<User> myTestUsers = TestDataFactory.createSupTestReps(3, null, null, true);
        List<Account> accountTestData = TestDataFactory.createTestAccountNonGenerics(4, 'BDR', 2);
        ID testAccount1ID = accountTestData[0].ID;
        List<Contact> testContacts = [SELECT ID, AccountID FROM Contact WHERE AccountID = :testAccount1ID];
        ID testUserId = myTestUsers[0].ID;
        Opportunity testOpp1 = new Opportunity();
        testOpp1.OwnerID = testUserId;
        testOpp1.RecordTypeID = oppSuppliesRecordTypeID;
        testOpp1.Primary_Contact__c = testContacts[0].Id;
        testOpp1.AccountId = testAccount1ID;
        testOpp1.StageName = 'New';
        testOpp1.CloseDate = Date.Today() + 30;
        testOpp1.name = 'Sup Test1: ';
        insert testOpp1;
        //Create Second Opp which should end up with the same Owner
        Opportunity testOpp2 = new Opportunity();
        testOpp2.OwnerID = null;
        testOpp2.RecordTypeID = oppSuppliesRecordTypeID;
        testOpp2.Primary_Contact__c = testContacts[0].Id;
        testOpp2.AccountId = testAccount1ID;
        testOpp2.StageName = 'New';
        testOpp2.CloseDate = Date.Today() + 30;
        testOpp2.name = 'Sup Test2: ';
        List<Opportunity> testOppList = new List<Opportunity>();
        testOppList.add(testOpp2);
        Opportunity testOpp3 = new Opportunity();
        testOpp3.OwnerID = null;
        testOpp3.RecordTypeID = oppSuppliesRecordTypeID;
        testOpp3.Primary_Contact__c = testContacts[0].Id;
        testOpp3.AccountId = testAccount1ID;
        testOpp3.StageName = 'New';
        testOpp3.CloseDate = Date.Today() + 30;
        testOpp3.name = 'Sup Test3: ';
        testOppList.add(testOpp3);
        ID updateOppOwnerID = myTestUsers[1].ID;
        testOpp1.OwnerID = updateOppOwnerID;
        update testOpp1;
        Test.startTest();
        routingHelper.routeSuppliesOpps(testOppList);
        insert testOppList;
        Test.stopTest();
        ID createdOppId = testOppList[0].Id;
        ID createdOpp2Id = testOppList[1].Id;
        Opportunity resultOpp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :createdOppId];
        System.assertEquals(updateOppOwnerID, resultOpp.OwnerID, 'The owners did not match');
        Opportunity resultOpp2 = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :createdOpp2Id];
        System.assertEquals(updateOppOwnerID, resultOpp2.OwnerID, 'The owners did not match');
    }

    @isTest
    //Basic Constructors for Code Coverage on Apex Classes
    public static void basicRoutingAddress() {
        routingAddress rA = new routingAddress();
        routingAddress rA1 = new routingAddress('20220', 'TestCity', '20221', 'AltCity', 'A1');
    }

    @isTest
    public static void P21AccountDetailsRoutesBatch_Test() {
        List<User> userList = TestDataFactory.createSupTestReps(2, null, null, true);

        List<Rep_Router__c> router = new List<Rep_Router__c>();
        Rep_Router__c r1 = new Rep_Router__c();
        r1.User__c = userList[1].Id;
        r1.ZipCode__c = '12345';
        r1.Name = 'Supplies12345';
        r1.Business_Entity__C = 'Supplies';
        router.add(r1);
        Rep_Router__c r2 = new Rep_Router__c();
        r2.User__c = userList[1].Id;
        r2.ZipCode__c = '23456';
        r2.Name = 'Supplies23456';
        r2.Business_Entity__C = 'Supplies';
        router.add(r2);

        insert router;

        List<P21_Account_Details__C> p21Accounts = new List<P21_Account_Details__C>();
        P21_Account_Details__C p21Acct1 = new P21_Account_Details__C();
        p21Acct1.OwnerId = userList[1].Id;
        p21Acct1.Primary_Zip_Code__c = '12345';
        p21Acct1.P21_CustomerID__C = 'CA012';
        p21Acct1.Name = 'Supplies Account';
        p21Accounts.add(p21Acct1);
        P21_Account_Details__C p21Acct2 = new P21_Account_Details__C();
        p21Acct2.OwnerId = userList[1].Id;
        p21Acct2.Primary_Zip_Code__c = '23456';
        p21Acct2.P21_CustomerID__C = 'CA123';
        p21Acct2.Name = 'Supplies Account 2';
        P21Acct2.Override_Zipcode_Routing__c = true;
        p21Accounts.add(p21Acct2);

        insert p21Accounts;

        List<Rep_Router__c> routerUpdate = new List<Rep_Router__c>();
        Rep_Router__c r1Update = new Rep_Router__c();
        r1Update.Id = r1.Id;
        r1Update.User__c = userList[0].Id;
        r1Update.ZipCode__c = '12345';
        r1Update.Name = 'Supplies12345';
        r1Update.Business_Entity__C = 'Supplies';
        routerUpdate.add(r1Update);
        Rep_Router__c r2Update = new Rep_Router__c();
        r2Update.Id = r2.Id;
        r2Update.User__c = userList[0].Id;
        r2Update.ZipCode__c = '23456';
        r2Update.Name = 'Supplies23456';
        r2Update.Business_Entity__C = 'Supplies';
        routerUpdate.add(r2Update);

        Test.startTest();

        update routerUpdate;
        SuppliesTerritoryRoutingBatch sTerRouteBatch = new SuppliesTerritoryRoutingBatch();
        ID batchID = Database.executeBatch(sTerRouteBatch);
        System.debug('The batchID is : ' + batchID);

        Test.stopTest();

        P21_Account_Details__C acct1 = [SELECT id, OwnerId FROM P21_Account_Details__c WHERE id = :p21Acct1.id];
        P21_Account_Details__C acct2 = [SELECT id, OwnerId FROM P21_Account_Details__c WHERE id = :p21Acct2.id];

        System.assertEquals(userList[0].Id, acct1.OwnerId, 'P21 acct owner should be new rep');
        System.assertNotEquals(userList[0].Id, acct2.OwnerId, 'P21 acct owner should be old rep');
    }
}