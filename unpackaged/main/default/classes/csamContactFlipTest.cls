@isTest
public class csamContactFlipTest {
    //Customer_Type__c on the Contact is a Formula to get to RETENTION so setup data with Orders over 1 years ago.

    @isTest
    static void csamContactFlipTest1() {
        //Create an Account that is AM
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 2);
        Account testAccount = testAccountList[0];
        List<Order_ERP__C> testOrderList = new List<Order_ERP__C>();

        Order_ERP__C testOrder1 = TestDataFactory.createOrderERP(
            false,
            'Q11-1111-1111',
            'AAA22-00022',
            testAccount.Email_Domain__C,
            null,
            'mrsmith01@' + testAccount.Email_Domain__C,
            false,
            true
        );
        testOrder1.Is_Generic__c = testAccount.Generic_Account__c;
        testOrder1.Order_ERP_CreatedDate__c = date.newInstance(2019, 6, 30);
        testOrder1.Order_ERP_Time__c = dateTime.newInstanceGMT(2019, 6, 30, 18, 0, 0);
        testOrder1.Line_of_Business__c = 'Instant Quote';
        testOrder1.Order_Subtotal__c = 5000;
        testOrder1.Order_Total__c = 5000;
        testOrder1.Shipping__c = null;
        testOrder1.ERP_PartPk__c = '1111A';
        testOrder1.ERP_Contact__c = 'AAA22';
        testOrder1.ERP_Contact_First_Name__c = 'Michael';
        testOrder1.ERP_Contact_Last_Name__c = 'Smith';
        testOrderList.add(testOrder1);

        Order_ERP__C testOrder2 = TestDataFactory.createOrderERP(
            false,
            'Q22-2222-2222',
            'AAA23-00022',
            testAccount.Email_Domain__C,
            null,
            'msbetty01@' + testAccount.Email_Domain__C,
            false,
            true
        );
        testOrder2.Is_Generic__c = testAccount.Generic_Account__c;
        testOrder2.Order_ERP_CreatedDate__c = date.newInstance(2019, 6, 30);
        testOrder2.Order_ERP_Time__c = dateTime.newInstanceGMT(2019, 6, 30, 18, 0, 0);
        testOrder2.Line_of_Business__c = 'Instant Quote';
        testOrder2.Order_Subtotal__c = 5000;
        testOrder2.Order_Total__c = 5000;
        testOrder2.Shipping__c = null;
        testOrder2.ERP_PartPk__c = '1112A';
        testOrder2.ERP_Contact__c = 'AAA23';
        testOrder2.ERP_Contact_First_Name__c = 'Betty';
        testOrder2.ERP_Contact_Last_Name__c = 'Rocket';
        testOrderList.add(testOrder2);
        insert testOrderList;

        List<Contact> testContactList = [
            SELECT ID, AccountID, OwnerID
            FROM Contact
            WHERE AccountID = :testAccount.ID AND Customer_Type__c = 'RETENTION'
        ];
        //Test 1 a Contact with Retention_Exemption__c is True and Retention
        Contact ignoreCAFCon = testContactList[0];
        ignoreCAFCon.Retention_Exemption__c = true;
        update ignoreCAFCon;

        // Test 2 a Contact with  customer Type is Retention
        Contact conRetNoFlag = testContactList[1];
        //Create an Opportunity on Test 2 Contact and confirm that the Opportunity's Owner changes
        Opportunity testOpp = TestDataFactory.createOpportunity(
            true,
            testContactList[1].ID,
            testContactList[1].AccountID,
            testContactList[1].OwnerID,
            date.today() + 30
        );
        Project__c testProject = TestDataFactory.createProject(
            true,
            testContactList[1].ID,
            testContactList[1].AccountID,
            testContactList[1].OwnerID,
            null,
            'New'
        );

        //Test 3 a Contact with Customer Type!= Retention
        Contact custNoRet = TestDataFactory.createContact(false, testAccount);
        custNoRet.firstName = 'Bob';
        custNoRet.lastName = 'Nomad';
        custNoRet.email = 'bobnomad01@' + testAccount.Email_Domain__C;
        insert custNoRet;

        // Now create the second User who will act as the CSAM on the Parent
        User CSAMUser = TestDataFactory.createTestUserSecond()[0];
        Account_Team__c atmCSAM = new Account_Team__c();
        atmCSAM.Account__c = testAccount.ID;
        atmCSAM.Team_Member__c = CSAMUser.ID;
        atmCSAM.Team_Role__c = 'Enterprise Account Manager';
        insert atmCSAM;

        System.debug('Starting the batch job');
        Test.StartTest();
        csamContactFlip myBatchObject = new csamContactFlip();
        Id batchId = Database.executeBatch(myBatchObject);
        Test.StopTest();

        //Test 1 ignoreCAFCon The Account Owner should match this contact Owner
        Contact ignoreCAFConAfterBatch = [SELECT ID, OwnerID FROM Contact WHERE ID = :ignoreCAFCon.ID];
        System.assertEquals(
            ignoreCAFConAfterBatch.OwnerID,
            testAccount.OwnerID,
            'The Accounts Owner and the Contact with flag owner did not match'
        );

        // Test 2 a Contact with  customer Type is Retention
        Contact conRetNoFlagAfterBatch = [SELECT ID, OwnerID FROM Contact WHERE ID = :conRetNoFlag.ID];
        System.assertEquals(
            conRetNoFlagAfterBatch.OwnerID,
            atmCSAM.Team_Member__c,
            'The Contact\'s owner did not match the CSAM owner id'
        );
        System.assertNotEquals(
            conRetNoFlagAfterBatch.OwnerID,
            testAccount.OwnerID,
            'The Contact\'s owner matched the Main Account Owner'
        );

        // Test 2 Confirm that the Opp's Owner is updated
        Opportunity testOppPostBatch = [SELECT ID, OwnerID FROM Opportunity WHERE ID = :testOpp.ID];
        System.assertEquals(
            testOppPostBatch.OwnerID,
            atmCSAM.Team_Member__c,
            'The Opportunity\'s owner did not match the CSAM owner id'
        );

        // Test 2 Confirm that the Project's Owner is updated
        Project__c testProjectPostBatch = [SELECT ID, OwnerID FROM Project__c WHERE ID = :testProject.ID];
        System.assertEquals(
            testProjectPostBatch.OwnerID,
            atmCSAM.Team_Member__c,
            'The Projects\'s owner did not match the CSAM owner id'
        );

        //Test 3 a Contact with Customer Type!= Retention
        Contact custNoRetAfterBatch = [
            SELECT ID, OwnerID
            FROM Contact
            WHERE ID = :custNoRet.ID AND Customer_Type__c != 'RETENTION'
        ];
        System.assertEquals(
            custNoRetAfterBatch.OwnerID,
            testAccount.OwnerID,
            'The Accounts Owner and the Contact that is not Retention did not match'
        );
    }

    @isTest
    static void csamContactOrigTest() {
        //Create an Account that is AM with no Account Team
        //Create an Account that is AM
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 2);
        Account testAccount = testAccountList[0];
        List<Order_ERP__C> testOrderList = new List<Order_ERP__C>();
        String testEmail = 'mrsmith01@' + testAccount.Email_Domain__C;
        testEmail = testEmail.toLowerCase();
        System.debug(testEmail);
        //Create a Contact this is Retention with a different Owner
        Order_ERP__C testOrder1 = TestDataFactory.createOrderERP(
            false,
            'Q12-3333-4444',
            'AAA22-00022',
            testAccount.Email_Domain__C,
            null,
            testEmail,
            false,
            true
        );
        testOrder1.Is_Generic__c = testAccount.Generic_Account__c;
        testOrder1.Order_ERP_CreatedDate__c = date.newInstance(2019, 6, 30);
        testOrder1.Order_ERP_Time__c = dateTime.newInstanceGMT(2019, 6, 30, 18, 0, 0);
        testOrder1.Line_of_Business__c = 'Instant Quote';
        testOrder1.Order_Subtotal__c = 5000;
        testOrder1.Order_Total__c = 5000;
        testOrder1.Shipping__c = null;
        testOrder1.ERP_PartPk__c = '1111A';
        testOrder1.ERP_Contact__c = 'AAA22';
        testOrder1.ERP_Contact_First_Name__c = 'Michael';
        testOrder1.ERP_Contact_Last_Name__c = 'Smith';
        testOrderList.add(testOrder1);

        // Order_ERP__C testOrder1 = TestDataFactory.createOrderERP(false, 'Q22-2222-2222', 'AAA22-00022', testAccount.Email_Domain__C, null, testEmail, false, true);
        // testOrder1.Account_Domain__C = testAccount.Email_Domain__C;
        // testOrder1.Is_Generic__c = testAccount.Generic_Account__c;
        // testOrder1.Order_Email__c = testEmail;
        // testOrder1.Order_ERP_CreatedDate__c = date.newInstance(2019, 6, 30);
        // testOrder1.Order_ERP_Time__c = dateTime.newInstanceGMT(2019, 6, 30, 18, 0, 0);
        // testOrder1.Line_of_Business__c = 'Instant Quote';
        // testOrder1.Order_Subtotal__c = 5000;
        // testOrder1.Order_Total__c = 5000;
        // testOrder1.process_isSLS__c = true;
        // testOrder1.ERP_PartPk__c = '1111A';
        // testOrder1.ERP_Contact__c = 'AAA22';
        // testOrder1.ERP_Contact_First_Name__c = 'Michael';
        // testOrder1.ERP_Contact_Last_Name__c = 'Smith';
        // testOrderList.add(testOrder1);

        insert testOrderList;
        Contact testContact = [SELECT ID, OwnerID FROM Contact WHERE primary_email__c = :testEmail];
        //Confirm that the Account and Contact Owner Match

        System.assertEquals(testContact.OwnerID, testAccount.OwnerID, 'The contact\'s owner did not match');
        //Change the Contact Owner
        //Contact should flip back to Account Owner
        User CSAMUser = TestDataFactory.createTestUserSecond()[0];
        testContact.OwnerID = CSAMUser.ID;
        update testContact;
        System.debug('Starting the batch job');
        test.StartTest();
        csamContactFlip myBatchObject = new csamContactFlip();
        Id batchId = Database.executeBatch(myBatchObject);
        test.StopTest();
        Contact testContactAfterBatch = [SELECT ID, OwnerID FROM Contact WHERE ID = :testContact.ID];
        System.assertEquals(
            testContactAfterBatch.OwnerID,
            testAccount.OwnerID,
            'The Contact was updated to the Accounts Owner'
        );
    }
    @isTest
    static void csamHierarchyTest() {
        //For this Test assign a CSAM at the corporate Parent and flip a contact at the subdivision
        map<String, List<SObject>> mapResult = TestDataFactory.createHierarchyTestCustomATeam(false, false);

        Account accountParent = (Account) mapResult.get('Account')[0];
        Account accountChild = (Account) mapResult.get('Account')[1];
        Order_ERP__C parentOrder = (Order_ERP__C) mapResult.get('Order_ERP__C')[0];
        Order_ERP__C childOrder = (Order_ERP__C) mapResult.get('Order_ERP__C')[1];
        Account_Team__c atmCSAM = (Account_Team__c) mapResult.get('Account_Team__c')[0];
        User CSAMUser = (User) mapResult.get('User')[0];

        // Now create the second User who will act as the CSAM on the Parent
        System.debug('We have finished setting the orders up for tests.');
        System.debug(Limits.getQueries());
        System.debug('Starting the batch Job');
        System.debug('About to start the Tests');

        Contact testContactbeforeBatch;
        test.StartTest();

        insert atmCSAM;
        insert childOrder;
        testContactbeforeBatch = [
            SELECT ID, OwnerID, Account.OwnerID
            FROM Contact
            WHERE AccountID = :accountChild.ID
            LIMIT 1
        ];
        csamContactFlip myBatchObject = new csamContactFlip();
        Id batchId = Database.executeBatch(myBatchObject);
        System.debug('At the end of stop Test');
        System.debug(Limits.getQueries());
        test.StopTest();
        System.debug('Finished the Testing');
        System.debug(Limits.getQueries());
        Contact testContactafterBatch = [
            SELECT ID, OwnerID, Account.OwnerID
            FROM Contact
            WHERE AccountID = :accountChild.ID
        ][0];
        System.debug(testContactafterBatch);
        System.assertNotEquals(
            testContactbeforeBatch.OwnerID,
            testContactafterBatch.OwnerID,
            'The contacts owner did not change'
        );
        System.assertEquals(testContactafterBatch.OwnerID, CSAMUser.ID, 'The Contacts Owner was not the CSAM');
        System.assertNotEquals(
            testContactafterBatch.OwnerID,
            testContactafterBatch.Account.OwnerID,
            'The Contact and Account Owner Ids are the same'
        );
    }
}