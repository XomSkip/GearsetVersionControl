@isTest
public class CaseHandlerTest {
    static final ID casePSERecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('PSE_Case')
        .getRecordTypeId();
    static final Id caseSellerMarketplaceRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('SellerMarketplace')
        .getRecordTypeId();
    static final Id oppSellerMarketplaceRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();

    static final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeId();

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test', Email_Domain__c = 'Test@test.com');
        insert testAccount;

        List<Ops_Order__c> lstOpdOrder = new List<Ops_Order__c>();
        Ops_Order__c testOpsOrder;
        testOpsOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00001');
        lstOpdOrder.add(testOpsOrder);

        testOpsOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00002');
        lstOpdOrder.add(testOpsOrder);

        testOpsOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00003');
        lstOpdOrder.add(testOpsOrder);

        testOpsOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00004');
        lstOpdOrder.add(testOpsOrder);

        testOpsOrder = new Ops_Order__c(XometryOpsOrderID__c = 'AAAAA-00005');
        lstOpdOrder.add(testOpsOrder);
        insert lstOpdOrder;
    }

    @isTest
    static void caseTriggerTest() {
        RecordType pseCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'PSE_Case'
            LIMIT 1
        ];
        Case testCase = new Case(SuppliedEmail = 'test@test.com', RecordTypeId = pseCaseRecordType.Id);
        Test.startTest();
        insert testCase;
        Test.stopTest();
        List<Audit_Trail_Error__c> errorList = new List<Audit_Trail_Error__c>(
            [SELECT Id, errorMessage__c FROM Audit_Trail_Error__c]
        );
        System.assertEquals(0, errorList.size(), 'No errors should have been created');
    }

    @isTest
    static void populateProjectFromOppOnInsertTest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        map<String, List<SObject>> mapResult = TestDataFactory.createOppWithProject(testAccount);
        Opportunity testOpp = (Opportunity) mapResult.get('Opportunity')[0];

        Case testCase = new Case(Opportunity__c = testOpp.Id);
        Test.startTest();
        insert testCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Project__c FROM Case LIMIT 1];
        System.assertNotEquals(null, caseAfter.Project__c, 'Project should have been populated on Case');
    }

    @isTest
    static void populateProjectFromOppOnUpdateTest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        map<String, List<SObject>> mapResult = TestDataFactory.createOppWithProject(testAccount);
        Opportunity testOpp = (Opportunity) mapResult.get('Opportunity')[0];

        Case testCase = new Case();
        insert testCase;
        testCase.Opportunity__c = testOpp.Id;
        Test.startTest();
        update testCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Project__c FROM Case LIMIT 1];
        System.assertNotEquals(null, caseAfter.Project__c, 'Project should have been populated on Case');
    }

    @isTest
    static void populateLastOwnerChangeDateOnUpdateTest() {
        Id pseCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('PSE_Case')
            .getRecordTypeId();
        Case testCase = new Case(recordTypeId = pseCaseRecordTypeId);
        insert testCase;
        List<User> testUsers = TestDataFactory.createTestUsers();
        testCase.OwnerId = testUsers[0].Id;
        Test.startTest();
        update testCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Last_Owner_Change_Date__c FROM Case LIMIT 1];
        System.assertNotEquals(
            null,
            caseAfter.Last_Owner_Change_Date__c,
            'Last_Owner_Change_Date__c should have been populated on Case'
        );
    }

    @isTest
    static void assignSalesOpCasetoContactOwner() {
        //Create a Contact that is assigned to a Sales Rep
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 2);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        String testQueue = 'Sales Queue';
        Group validQueList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :testQueue];
        System.debug('Here is the que Name that was found ' + validQueList.Name);
        System.debug('Here is the id : ' + validQueList.Id);
        List<Contact> testContactList = [
            SELECT ID, AccountId, name, OwnerId, Primary_Email__C
            FROM Contact
            WHERE AccountID = :testAccountID
        ];
        String testEmail = testContactList[0].Primary_Email__C;
        ID expectedOwnerId = testContactList[0].OwnerID;
        //Create a Case and assign the Case to the Sales Operations Queue
        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = testEmail;
        testCase.OwnerID = validQueList.Id;

        test.StartTest();
        insert testCase;
        test.StopTest();

        Case testCaseResult = [SELECT ID, CaseNumber, OwnerID, Owner.Name FROM Case WHERE ID = :testCase.ID];
        System.debug('Here is the new case');
        System.debug(testCaseResult);
        System.assertEquals(expectedOwnerId, testCaseResult.OwnerID, 'The Case did not change the owner');
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityInsertTest() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);

        Opportunity opp2 = new Opportunity(Name = 'Test');
        opp2.StageName = 'Open';
        opp2.CloseDate = System.today().addDays(10);
        opp2.Last_Quote_Xometry_ERP_ID__c = 'AAAAA-00002';
        insert new List<Opportunity>{ opp, opp2 };

        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001', Opportunity__c = opp.Id);
        Case testCase2 = new Case(Opportunity__c = opp2.Id);

        Test.startTest();
        insert new List<Case>{ testCase, testCase2 };
        Test.stopTest();

        CaseOpportunity__c caseOppAfter = [
            SELECT Id, Xometry_ERP_ID__c, Opportunity__c
            FROM CaseOpportunity__c
            WHERE Case__c = :testCase.Id
        ];
        //opp.Last_Quote_Xometry_ERP_ID__c == null
        System.assertEquals(
            opp.Last_Quote_Xometry_ERP_ID__c,
            caseOppAfter.Xometry_ERP_ID__c,
            'Junction Xometry_ERP_ID__c should match opp.Last_Quote_Xometry_ERP_ID__c'
        );
        System.assertEquals(opp.Id, caseOppAfter.Opportunity__c, 'Junction should match the Case Opp');
        System.assertEquals(
            opp2.Last_Quote_Xometry_ERP_ID__c,
            [SELECT Id, Xometry_ERP_ID__c, Opportunity__c FROM CaseOpportunity__c WHERE Case__c = :testCase2.Id]
            .Xometry_ERP_ID__c,
            'Junction should match the Case ERP ID'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdateTest() {
        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        Test.startTest();

        testCase.Shadow_Xometry_ERP_ID__c = 'BBBBB-00002';
        update testCase;

        Test.stopTest();

        List<CaseOpportunity__c> caseOppAfter = [SELECT Id, Xometry_ERP_ID__c FROM CaseOpportunity__c ORDER BY Id];
        System.assertEquals(
            'AAAAA-00001',
            caseOppAfter[0].Xometry_ERP_ID__c,
            'Junction should match the old Case ERP ID'
        );
        System.assertEquals(
            'BBBBB-00002',
            caseOppAfter[1].Xometry_ERP_ID__c,
            'Junction should match the new Case ERP ID'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdateExtraTest() {
        Case testCase1 = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase1;

        Case testCase2 = new Case(Shadow_Xometry_ERP_ID__c = 'BBBBB-00002');
        insert testCase2;

        Test.startTest();

        testCase1.Shadow_Xometry_ERP_ID__c = 'BBBBB-00002';
        update testCase1;

        Test.stopTest();

        List<CaseOpportunity__c> caseOppAfter = [SELECT Id, Xometry_ERP_ID__c FROM CaseOpportunity__c ORDER BY Id];
        System.assertEquals(
            'AAAAA-00001',
            caseOppAfter[0].Xometry_ERP_ID__c,
            'Junction should match the old Case ERP ID'
        );
        System.assertEquals(
            'BBBBB-00002',
            caseOppAfter[1].Xometry_ERP_ID__c,
            'Junction should match the new Case ERP ID'
        );
        System.assertEquals(
            'BBBBB-00002',
            caseOppAfter[2].Xometry_ERP_ID__c,
            'Junction should match the new Case ERP ID'
        );
        System.assertEquals(3, caseOppAfter.size(), 'There should be 3 CaseOpportunity Records');
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdateExtraTestExpanded() {
        Case testCase1 = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase1;

        Case testCase2 = new Case(Shadow_Xometry_ERP_ID__c = 'BBBBB-00002');
        insert testCase2;

        Test.startTest();
        List<case> testCaseUpdateList = new List<case>();
        testCase1.Shadow_Xometry_ERP_ID__c = 'BBBBB-00002';
        testCaseUpdateList.add(testCase1);
        testCase2.Shadow_Xometry_ERP_ID__c = 'CCCCC-00003';
        testCaseUpdateList.add(testCase2);
        update testCaseUpdateList;

        Test.stopTest();

        CaseOpportunity__C newTestCase = [
            SELECT Id, Case__c, Xometry_ERP_ID__c
            FROM CaseOpportunity__C
            WHERE Xometry_ERP_ID__C = 'CCCCC-00003'
        ][0];
        System.assertEquals('CCCCC-00003', newTestCase.Xometry_ERP_ID__c, 'Junction should match the new Case ERP ID');
        List<CaseOpportunity__c> caseOppAfter = [SELECT Id, Xometry_ERP_ID__c FROM CaseOpportunity__C];
        System.assertEquals(4, caseOppAfter.size(), 'There should be 4 CaseOpportunity Records');
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityDeleteTest() {
        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        System.assertEquals(
            testCase.Id,
            [SELECT Id, Case__c FROM CaseOpportunity__c WHERE Xometry_ERP_ID__c = 'AAAAA-00001']
            .Case__c,
            'Junction should be created on Case insert.'
        );

        Test.startTest();

        delete testCase;

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT Id, Xometry_ERP_ID__c FROM CaseOpportunity__c WHERE Xometry_ERP_ID__c = 'AAAAA-00001'].size(),
            'Junction should be deleted on Case delete.'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityMergeTest() {
        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert new List<Case>{ testCase };

        Case testCase2 = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00002');
        insert new List<Case>{ testCase2 };

        System.assertEquals(
            1,
            [SELECT Id, Xometry_ERP_ID__c FROM CaseOpportunity__c WHERE Case__c = :testCase.Id].size(),
            'Each Case has one junction'
        );

        Test.startTest();

        Database.merge(testCase, testCase2);

        Test.stopTest();
        System.assertEquals(1, [SELECT Id FROM Case WHERE MasterRecordId != NULL].size(), 'Case was merged correctly');
        System.assertEquals(
            2,
            [SELECT Id, Xometry_ERP_ID__c FROM CaseOpportunity__c WHERE Case__c = :testCase.Id].size(),
            'Merged Junction should be relinked to Master Case.'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityIgnoreTest() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);
        insert opp;

        Case testCase = new Case();

        Test.startTest();
        insert testCase;
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT Id, Xometry_ERP_ID__c, Opportunity__c FROM CaseOpportunity__c].size(),
            'Junction should not be created'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdate2Test() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);
        insert opp;

        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        Test.startTest();
        testCase.Opportunity__c = opp.Id;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT Id, Xometry_ERP_ID__c, Opportunity__c FROM CaseOpportunity__c].size(),
            'One Junction should be created'
        );
        System.assertEquals(
            1,
            [SELECT Id, Xometry_ERP_ID__c, Opportunity__c FROM CaseOpportunity__c WHERE Opportunity__c = :opp.Id]
                .size(),
            'Junction should not be created'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdate3Test() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);

        Opportunity opp2 = new Opportunity(Name = 'Test2');
        opp2.StageName = 'Open';
        opp2.CloseDate = System.today().addDays(10);

        insert new List<Opportunity>{ opp, opp2 };

        Case testCase = new Case(Opportunity__c = opp.Id, Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        Test.startTest();
        testCase.Opportunity__c = opp2.Id;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT Id FROM CaseOpportunity__c WHERE Case__c = :testCase.Id].size(),
            'We would want an additional CaseOpportunity'
        );
        System.assertEquals(
            1,
            [SELECT Id FROM CaseOpportunity__c WHERE Opportunity__c = :opp.Id].size(),
            'There is a junction related to opp'
        );
        System.assertEquals(
            1,
            [SELECT Id FROM CaseOpportunity__c WHERE Opportunity__c = :opp2.Id].size(),
            'There is a junction related to opp'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdate4Test() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);

        insert new List<Opportunity>{ opp };

        Case testCase = new Case(Opportunity__c = opp.Id, Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        testCase.Shadow_Xometry_ERP_ID__c = null;
        update testCase;

        Test.startTest();
        testCase.Shadow_Xometry_ERP_ID__c = 'AAAAA-00001';
        update testCase;
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT Id FROM CaseOpportunity__c WHERE Case__c = :testCase.Id].size(),
            'We would want an additional CaseOpportunity'
        );
        System.assertEquals(
            1,
            [SELECT Id FROM CaseOpportunity__c WHERE Opportunity__c = :opp.Id].size(),
            'There is a junction related to opp'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdate5Test() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);

        insert new List<Opportunity>{ opp };

        Case testCase = new Case(Opportunity__c = opp.Id, shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        testCase.Shadow_Xometry_ERP_ID__c = null;
        update testCase;

        Test.startTest();
        testCase.Shadow_Xometry_ERP_ID__c = 'AAAAA-00001';
        testCase.Opportunity__c = null;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT Id FROM CaseOpportunity__c WHERE Case__c = :testCase.Id].size(),
            'We would want an additional CaseOpportunity'
        );
        System.assertEquals(
            1,
            [SELECT Id FROM CaseOpportunity__c WHERE Opportunity__c = :opp.Id].size(),
            'There is a junction related to opp'
        );
        System.assertEquals(
            1,
            [SELECT Id FROM CaseOpportunity__c WHERE Opportunity__c = NULL].size(),
            'There is a junction related to opp'
        );
    }

    @isTest
    static void createRecordHistory() {
        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        insert testOpp;
        Case testCase = new Case(SuppliedEmail = 'test@test.com', Opportunity__c = testOpp.Id);
        insert testCase;

        Integer intQuntityCaseHistry = [SELECT COUNT() FROM CaseHistory__c];

        System.assertEquals(0, intQuntityCaseHistry);

        Group objQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' LIMIT 1];

        testCase.OwnerId = objQueue.Id;
        update testCase;

        List<CaseHistory__c> lstCaseHistry = [
            SELECT Id, OldOwnerText__c, NewOwnerText__c, OldUserOwner__c, NewUserOwner__c, DurationMinutes__c
            FROM CaseHistory__c
            ORDER BY Id DESC
        ];

        Test.setCreatedDate(lstCaseHistry[0].Id, Datetime.now().addDays(-10));

        testCase.OwnerId = UserInfo.getUserId();
        update testCase;

        lstCaseHistry = [
            SELECT Id, OldOwnerText__c, NewOwnerText__c, OldUserOwner__c, NewUserOwner__c, DurationMinutes__c
            FROM CaseHistory__c
            ORDER BY Id DESC
        ];

        Test.setCreatedDate(lstCaseHistry[0].Id, Datetime.now().addDays(-7));

        test.StartTest();

        testCase.Status = 'Closed';
        update testCase;

        testCase.Status = 'Open';
        update testCase;

        test.StopTest();

        lstCaseHistry = [
            SELECT Id, OldOwnerText__c, NewOwnerText__c, OldUserOwner__c, NewUserOwner__c, DurationMinutes__c
            FROM CaseHistory__c
            ORDER BY Id DESC
        ];
        System.assertEquals(4, lstCaseHistry.size(), 'The CaseHistory created was not 4');

        System.assertEquals(
            UserInfo.getUserId(),
            lstCaseHistry[3].OldUserOwner__c,
            'The old owner field in CaseHistory record was not populated'
        );
        System.assertEquals(
            null,
            lstCaseHistry[3].NewUserOwner__c,
            'The new owner field in CaseHistory record was not populated'
        );
        System.assertEquals(
            0,
            lstCaseHistry[3].DurationMinutes__c,
            'The Duration of CaseHistory record was not populated'
        );

        System.assertEquals(
            null,
            lstCaseHistry[2].OldUserOwner__c,
            'The old owner field in CaseHistory record was not populated'
        );
        System.assertEquals(
            UserInfo.getUserId(),
            lstCaseHistry[2].NewUserOwner__c,
            'The new owner field in CaseHistory record was not populated'
        );
        System.assertEquals(
            0,
            lstCaseHistry[2].DurationMinutes__c,
            'The Duration of CaseHistory record was not populated'
        );

        System.assertEquals(
            UserInfo.getUserId(),
            lstCaseHistry[1].OldUserOwner__c,
            'The old owner field in CaseHistory record was not populated'
        );
        System.assertEquals(
            UserInfo.getUserId(),
            lstCaseHistry[1].NewUserOwner__c,
            'The new owner field in CaseHistory record was not populated'
        );
        System.assertNotEquals(
            0,
            lstCaseHistry[1].DurationMinutes__c,
            'The Duration of CaseHistory record was not populated'
        );
        System.assertEquals(
            0,
            lstCaseHistry[0].DurationMinutes__c,
            'The Duration of CaseHistory record was not populated'
        );
    }

    @isTest(seeAllData=false)
    static void syncJobOnInsertTest() {
        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.OrderDueDate__c = Date.today() + 7;
        insert testJob;
        System.assertEquals(
            0,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be initialized'
        );

        Test.startTest();

        Case testCase = new Case(Job__c = testJob.Id, RecordTypeId = sourcingCaseRecordType.Id);
        insert testCase;

        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );
    }

    @isTest(seeAllData=false)
    static void syncJobOnUpdateTest() {
        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.OrderDueDate__c = Date.today() + 7;

        Job__c testJob2 = new Job__c();
        testJob2.Name = 'Test-Job2';
        testJob2.XometryJobID__c = 'Test-Jo2';
        testJob2.XometryOpsOrderID__c = '1235';
        testJob2.OrderDueDate__c = Date.today() + 7;
        insert new List<Job__c>{ testJob, testJob2 };

        Case testCase = new Case(Job__c = testJob.Id, RecordTypeId = sourcingCaseRecordType.Id);
        insert testCase;

        System.assertEquals(
            0,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob2.Id]
            .Open_Cases__c,
            'Rollup should be initialized'
        );
        System.assertEquals(
            1,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );

        Test.startTest();

        testCase.Job__c = testJob2.Id;
        update testCase;

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );
        System.assertEquals(
            1,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob2.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );
    }

    @isTest(seeAllData=false)
    static void syncJobOnUpdate2Test() {
        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.OrderDueDate__c = Date.today() + 7;
        insert testJob;

        Case testCase = new Case(Job__c = testJob.Id, RecordTypeId = sourcingCaseRecordType.Id);
        insert testCase;

        System.assertEquals(
            1,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );

        Test.startTest();

        testCase.Job__c = null;
        update testCase;

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );
    }

    @isTest(seeAllData=false)
    static void syncJobOnDeleteTest() {
        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.OrderDueDate__c = Date.today() + 7;
        insert testJob;

        Case testCase = new Case(Job__c = testJob.Id, RecordTypeId = sourcingCaseRecordType.Id);
        insert testCase;

        System.assertEquals(
            1,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );

        Test.startTest();

        delete testCase;

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );
    }

    @isTest(seeAllData=false)
    static void syncJobOnDelete2Test() {
        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = '1234';
        testJob.OrderDueDate__c = Date.today() + 7;
        insert testJob;

        Case testCase = new Case(Job__c = testJob.Id, RecordTypeId = sourcingCaseRecordType.Id);
        insert testCase;

        System.assertEquals(
            1,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id]
            .Open_Cases__c,
            'Rollup should be updated with the amount of cases'
        );

        Test.startTest();

        delete testJob;

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT Open_Cases__c FROM Job__c WHERE Id = :testJob.Id].size(),
            'Delete should be succesfull.'
        );
    }

    @isTest
    static void validateBlackListDomain() {
        BlackList__mdt objBlackList = [SELECT MasterLabel FROM BlackList__mdt LIMIT 1];
        String strEmail = 'test@' + objBlackList.MasterLabel;

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;

        Test.startTest();
        insert testCase;
        Test.stopTest();

        testCase = [SELECT Status, RecordTypeId, Reason FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1];
        System.assertEquals(testCase.Status, 'Solved', 'The case was not closed by blacklist');
        System.assertEquals(
            testCase.Reason,
            'Domain is BlackListed',
            'The reason for the closure was not due to a blacklist'
        );
    }

    @isTest
    static void validateBlackListDomain_pass() {
        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;

        Test.startTest();
        insert testCase;
        Test.stopTest();

        testCase = [SELECT Status, Reason FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1];
        System.assertNotEquals(testCase.Status, 'Closed', 'The case was closed by blacklist');
        System.assertNotEquals(
            testCase.Reason,
            'Domain is BlackListed',
            'The reason for the closure was due to a blacklist'
        );
    }

    @isTest
    static void closeEmailCaseOnCreation() {
        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing 0';
        testCase.Origin = 'Email: Quotes@';
        testCase.Description = 'This is an automated message. We ask that you do not reply to this email.  For assistance, please contact Accounts Payable at ap@blueorigin.com or call (253) 437-2956.';
        testCase.recordTypeID = AppConstants.caseManagementRTypeId;

        Case testCase2 = new Case();
        testCase2.Subject = 'New Manual Refund Made 1';
        testCase2.Origin = 'Email: Quotes@';
        testCase2.Description = 'This is a test Case is created for email to case';
        testCase2.recordTypeID = AppConstants.caseManagementRTypeId;

        Case testCase3 = new Case();
        testCase3.Subject = 'Test Case Routing 2';
        testCase3.Origin = 'Email: Quotes@';
        testCase3.Description = null;
        testCase3.recordTypeID = AppConstants.caseManagementRTypeId;

        Case testCase4 = new Case();
        testCase4.Subject = 'Forecast 3D Notification 3';
        testCase4.Origin = 'Email: Quotes@';
        testCase4.Description = '#partrejected';
        testCase4.recordTypeID = AppConstants.caseManagementRTypeId;

        Test.startTest();
        insert testCase;
        insert testCase2;
        insert testCase3;
        insert testCase4;
        Test.stopTest();

        List<Case> lstCases = [SELECT Subject, RecordtypeID, Status, ID FROM Case];
        System.assertEquals(lstCases[0].Status, 'Closed', 'The case was closed for be created for email to case');
        System.assertEquals(lstCases[1].Status, 'Closed', 'The case was closed for be created for email to case');
        System.assertNotEquals(
            lstCases[2].Status,
            'Closed',
            'The case was not closed because dont meet the conditions'
        );
        System.assertEquals(lstCases[3].Status, 'Closed', 'The case was closed for be created for email to case');
    }

    @isTest
    static void setRecordTypeOnOwnerChange_MGMTTest() {
        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;
        insert testCase;

        Test.startTest();
        testCase.OwnerId = [
            SELECT UserOrGroupId, Group.Name, Group.Id
            FROM GroupMember
            WHERE Group.Name = 'Automotive'
            LIMIT 1
        ]
        .UserOrGroupId;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            'CaseMgmt',
            [SELECT RecordType.DeveloperName FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1]
            .RecordType.DeveloperName,
            'The case RecordType was updated.'
        );
    }

    @isTest
    static void setRecordTypeOnOwnerChange_PSETest() {
        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;
        insert testCase;

        Test.startTest();
        testCase.OwnerId = [
            SELECT UserOrGroupId, Group.Name, Group.Id
            FROM GroupMember
            WHERE Group.Name = 'Pre-Sales Engineering Queue'
            LIMIT 1
        ]
        .UserOrGroupId;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            'PSE_Case',
            [SELECT RecordType.DeveloperName FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1]
            .RecordType.DeveloperName,
            'The case RecordType was updated.'
        );
    }

    @isTest
    static void setRecordTypeOnOwnerChange_GeneralTest() {
        Group cpcQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'CPC Support'];

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            GroupMember member = new GroupMember();
            member.UserOrGroupId = UserInfo.getUserId();
            member.GroupId = cpcQueue.Id;
            insert member;
        }

        String strEmail = 'test@validdomain.com';

        Test.startTest();

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;
        testCase.RecordTypeId = AppConstants.caseManagementRTypeId;
        testCase.OwnerId = [
            SELECT UserOrGroupId, Group.Name, Group.Id
            FROM GroupMember
            WHERE Group.Name = 'Spacetechs'
            LIMIT 1
        ]
        .UserOrGroupId;
        insert testCase;

        testCase.OwnerId = UserInfo.getUserId();
        update testCase;
        Test.stopTest();

        System.assertNotEquals(
            'GeneralSupportCase',
            [SELECT RecordType.DeveloperName FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1]
            .RecordType.DeveloperName,
            'The case RecordType was changed back to General'
        );
    }

    @isTest
    static void setRecordTypeOnOwnerChange_ExcludedRoleTest() {
        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;
        insert testCase;

        Test.startTest();
        testCase.OwnerId = [SELECT Id FROM User WHERE IsActive = TRUE AND UserRole.Name = 'Seller Service' LIMIT 1].Id;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            'GeneralSupportCase',
            [SELECT RecordType.DeveloperName FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1]
            .RecordType.DeveloperName,
            'The case RecordType was updated for excluded marketplace role'
        );
    }

    @isTest
    static void setRecordTypeOnOwnerChange_RoleTest() {
        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;
        insert testCase;

        Test.startTest();
        testCase.OwnerId = [
            SELECT Id
            FROM User
            WHERE
                IsActive = TRUE
                AND UserRole.Name LIKE '%Service%'
                AND UserRole.Name NOT IN ('Seller Service', 'Seller Marketplace Service')
            LIMIT 1
        ]
        .Id;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            'GeneralSupportCase',
            [SELECT RecordType.DeveloperName FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1]
            .RecordType.DeveloperName,
            'The case RecordType was updated.'
        );
    }

    @isTest(seeAllData=false)
    static void setRecordTypeOnOwnerChange_ExcludedTypeTest() {
        String strEmail = 'test@validdomain.com';
        Group dfmQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'First_Impressions' LIMIT 1];

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.SuppliedEmail = strEmail;
        testCase.Type = 'Large Order Review';
        testCase.RecordTypeId = AppConstants.caseDFMRTypeId;
        testCase.OwnerID = dfmQueue.Id;
        insert testCase;

        User testUser = new User(
            LastName = 'Headroom',
            FirstName = 'Max',
            alias = 'MH_test',
            Email = 'testing@xomtest.com',
            Username = 'test1234' + Math.random() + '@xomtest.com',
            CommunityNickname = 'happy' + Math.random(),
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            ProfileId = [SELECT Id FROM Profile WHERE Name = :'System Administrator']
            .Id,
            UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'Service']
            .Id
        );

        User currentUser = new User(Id = UserInfo.getUserId());
        System.runAs(currentUser) {
            insert testUser;
        }

        Test.startTest();
        testCase.OwnerId = testUser.Id;
        update testCase;
        Test.stopTest();

        Case resultCase = [SELECT Id, RecordTypeID, OwnerId FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1][0];

        System.assertEquals(
            AppConstants.caseDFMRTypeId,
            resultCase.RecordTypeId,
            'The case RecordType was updated for Large Order case'
        );
        System.assertEquals(testUser.Id, resultCase.OwnerId, 'The owner was not updated for the Large Order case');
    }

    @isTest
    static void setRecordTypeOnRecordTypeChange_ExcludedTypeTest() {
        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.SuppliedEmail = strEmail;
        testCase.Type = 'Large Order Review';
        testCase.RecordTypeId = AppConstants.caseDFMRTypeId;
        insert testCase;

        Test.startTest();
        testCase.RecordTypeID = AppConstants.caseGeneralSupportRTypeId;
        update testCase;
        Test.stopTest();

        System.assertEquals(
            AppConstants.caseDFMRTypeId,
            [SELECT RecordTypeID FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1]
            .RecordTypeId,
            'The case RecordType was updated for Large Order case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderInsertTest() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstOpdOrder[0].Id, GNOOrder__c = lstOpdOrder[1].Id);

        Test.startTest();
        insert testCase;
        Test.stopTest();

        List<CaseOpsOrder__c> lstCaseOrders = [
            SELECT Id, Ops_Order__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :testCase.Id
        ];

        System.assertEquals(2, lstCaseOrders.size(), 'Each Case has one junction');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            lstCaseOrders[1].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderInsertTest_SameOrder() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstOpdOrder[0].Id, GNOOrder__c = lstOpdOrder[0].Id);

        Test.startTest();
        insert testCase;
        Test.stopTest();

        List<CaseOpsOrder__c> lstCaseOrders = [
            SELECT Id, Ops_Order__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :testCase.Id
        ];

        System.assertEquals(1, lstCaseOrders.size(), 'Each Case has one junction');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderUpdateTest() {
        List<Ops_Order__c> lstCaseOrders = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstCaseOrders[0].Id, GNOOrder__c = lstCaseOrders[1].Id);
        insert testCase;

        List<CaseOpsOrder__c> caseOppAfter = [SELECT Id FROM CaseOpsOrder__c];
        System.assertEquals(caseOppAfter.size(), 2, 'Only two junctions should be created');

        Test.startTest();
        testCase.ParentOpsOrder__c = lstCaseOrders[2].Id;
        testCase.GNOOrder__c = lstCaseOrders[3].Id;
        update testCase;

        Test.stopTest();

        caseOppAfter = [SELECT Id, Ops_Order__c FROM CaseOpsOrder__c];
        System.assertEquals(caseOppAfter.size(), 4, 'Only four junctions should be created');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            caseOppAfter[2].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            caseOppAfter[3].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderUpdateTest_updateGNOOrder() {
        List<Ops_Order__c> lstCaseOrders = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstCaseOrders[0].Id);
        insert testCase;
        List<CaseOpsOrder__c> caseOppAfter = [SELECT Id FROM CaseOpsOrder__c];
        System.assertEquals(caseOppAfter.size(), 1, 'Only one junction should be created');

        Test.startTest();
        testCase.GNOOrder__c = lstCaseOrders[1].Id;
        update testCase;

        Test.stopTest();

        caseOppAfter = [SELECT Id, Ops_Order__c FROM CaseOpsOrder__c];
        System.assertEquals(caseOppAfter.size(), 2, 'Only two junctions should be created');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            caseOppAfter[0].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            caseOppAfter[1].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderUpdateTest_updateParentOpsOrder() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(GNOOrder__c = lstOpdOrder[0].Id);
        insert testCase;
        List<CaseOpsOrder__c> caseOppAfter = [SELECT Id FROM CaseOpsOrder__c];
        System.assertEquals(caseOppAfter.size(), 1, 'Only one junction should be created');

        Test.startTest();
        testCase.ParentOpsOrder__c = lstOpdOrder[1].Id;
        update testCase;

        Test.stopTest();

        caseOppAfter = [SELECT Id, Ops_Order__c FROM CaseOpsOrder__c];
        System.assertEquals(caseOppAfter.size(), 2, 'Only two junctions should be created');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            caseOppAfter[1].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            caseOppAfter[0].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderUpdateTest_updateParentOpsOrderNull() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstOpdOrder[0].Id, GNOOrder__c = lstOpdOrder[1].Id);
        insert testCase;

        List<CaseOpsOrder__c> lstCaseOrders = [
            SELECT Id, Ops_Order__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :testCase.Id
        ];

        System.assertEquals(2, lstCaseOrders.size(), 'Each Case has two junctions');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            lstCaseOrders[1].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );

        testCase.ParentOpsOrder__c = null;
        Test.startTest();
        update testCase;
        Test.stopTest();

        lstCaseOrders = [SELECT Id, Ops_Order__c FROM CaseOpsOrder__c WHERE Case__c = :testCase.Id];

        System.assertEquals(1, lstCaseOrders.size(), 'Each Case has one junction');

        System.assertEquals(
            testCase.GNOOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderUpdateTest_updateGNOOrderNull() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstOpdOrder[0].Id, GNOOrder__c = lstOpdOrder[1].Id);
        insert testCase;

        List<CaseOpsOrder__c> lstCaseOrders = [
            SELECT Id, Ops_Order__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :testCase.Id
        ];

        System.assertEquals(2, lstCaseOrders.size(), 'Each Case has two junctions');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            lstCaseOrders[1].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );

        testCase.GNOOrder__c = null;
        Test.startTest();
        update testCase;
        Test.stopTest();

        lstCaseOrders = [SELECT Id, Ops_Order__c FROM CaseOpsOrder__c WHERE Case__c = :testCase.Id];

        System.assertEquals(1, lstCaseOrders.size(), 'Each Case has one junction');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderUpdateTest_updateParentOpsOrderNullSameOrder() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstOpdOrder[0].Id, GNOOrder__c = lstOpdOrder[0].Id);
        insert testCase;

        List<CaseOpsOrder__c> lstCaseOrders = [
            SELECT Id, Ops_Order__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :testCase.Id
        ];

        System.assertEquals(1, lstCaseOrders.size(), 'Each Case has one junction');

        testCase.ParentOpsOrder__c = null;
        Test.startTest();
        update testCase;
        Test.stopTest();

        lstCaseOrders = [SELECT Id, Ops_Order__c FROM CaseOpsOrder__c WHERE Case__c = :testCase.Id];

        System.assertEquals(1, lstCaseOrders.size(), 'Each Case has one junction');
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderUpdateTest_updateGNOOrderNullSameOrder() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstOpdOrder[0].Id, GNOOrder__c = lstOpdOrder[0].Id);
        insert testCase;

        List<CaseOpsOrder__c> lstCaseOrders = [
            SELECT Id, Ops_Order__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :testCase.Id
        ];

        System.assertEquals(1, lstCaseOrders.size(), 'Each Case has one junction');

        testCase.GNOOrder__c = null;
        Test.startTest();
        update testCase;
        Test.stopTest();

        lstCaseOrders = [SELECT Id, Ops_Order__c FROM CaseOpsOrder__c WHERE Case__c = :testCase.Id];

        System.assertEquals(1, lstCaseOrders.size(), 'Each Case has one junction');
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderDeleteTest() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];
        Ops_Order__c testOpsOrder = lstOpdOrder[0];

        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001', ParentOpsOrder__c = testOpsOrder.Id);
        insert testCase;

        System.assertEquals(
            testCase.Id,
            [SELECT Id, Case__c FROM CaseOpsOrder__c WHERE Ops_Order__c = :testOpsOrder.Id]
            .Case__c,
            'Junction should be created on Case insert.'
        );

        Test.startTest();

        delete testCase;

        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT Id FROM CaseOpsOrder__c WHERE Ops_Order__c = :testOpsOrder.Id].size(),
            'Junction should be deleted on Case delete.'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOrderMergeTest_twoOrders() {
        List<Ops_Order__c> lstOpdOrder = [SELECT Id FROM Ops_Order__c];

        Case testCase = new Case(ParentOpsOrder__c = lstOpdOrder[0].Id, GNOOrder__c = lstOpdOrder[1].Id);

        Test.startTest();
        insert testCase;
        Test.stopTest();

        List<CaseOpsOrder__c> lstCaseOrders = [
            SELECT Id, Ops_Order__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :testCase.Id
        ];

        System.assertEquals(2, lstCaseOrders.size(), 'Each Case has one junction');

        System.assertEquals(
            testCase.ParentOpsOrder__c,
            lstCaseOrders[0].Ops_Order__c,
            'CaseOrder must have the ParentOpsOrder__c of the Case'
        );

        System.assertEquals(
            testCase.GNOOrder__c,
            lstCaseOrders[1].Ops_Order__c,
            'CaseOrder must have the GNOOrder__c of the Case'
        );
    }
    @isTest
    static void noSystemOwnerTest() {
        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;
        testCase.ownerId = AppConstants.API_USER;

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case testCaseResult = [SELECT Id, OwnerID FROM Case WHERE ID = :testCase.ID];

        System.assertNotEquals(AppConstants.API_USER, testCaseResult.ownerId, 'The owner stayed Api Admin');
    }

    @isTest
    static void noSystemOwnerXomServiceTest() {
        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.ownerId = AppConstants.Xometry_Service_USER;

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case testCaseResult = [SELECT Id, OwnerID FROM Case WHERE ID = :testCase.ID];
        Id cpcQueue = [SELECT ID, DeveloperName FROM Group WHERE DeveloperName = 'CPC_Support' AND Type = 'Queue'].Id;

        System.assertEquals(cpcQueue, testCaseResult.ownerId, 'The owner stayed Xometry Service User');
    }

    @isTest
    static void notXometryTeamUserCaseTeamMember() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        map<String, List<SObject>> mapResult = TestDataFactory.createOppWithProject(testAccount);
        Opportunity testOpp = (Opportunity) mapResult.get('Opportunity')[0];
        testOpp.ownerId = AppConstants.API_USER;
        update testOpp;

        Case testCase = new Case(Opportunity__c = testOpp.Id, RecordTypeId = casePSERecordTypeId);
        Test.startTest();
        insert testCase;
        Test.stopTest();
        List<CaseTeamMember> lstCaseTeams = [
            SELECT Id
            FROM CaseTeamMember
            WHERE ParentId = :testCase.Id AND MemberId = :AppConstants.API_USER
        ];
        System.assertEquals(0, lstCaseTeams.size(), 'The Xometry Team user not should be how case team member');
    }

    @isTest
    public static void setPriorityFromAccountVIP() {
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 1);
        Account testAccount = testAccountList[0];
        testAccount.VIP__c = true;
        update testAccount;

        Contact testContact = [
            SELECT ID, AccountId, name, OwnerId, Primary_Email__C
            FROM Contact
            WHERE AccountID = :testAccount.Id
        ][0];

        Case testCase = new Case();
        testCase.Subject = 'Case priority test';
        testCase.Origin = 'Web';
        testCase.Comments = 'This should associate to an account';
        testCase.SuppliedEmail = testContact.Primary_Email__c;
        testCase.AccountId = testAccount.Id;

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case testCaseRes = [SELECT Id, AccountId, ContactId, Priority FROM Case WHERE Id = :testCase.Id][0];
        System.assertEquals('High', testCaseRes.Priority, 'The case priority is not high');
    }

    @isTest
    static void assignPSEQuotesEmailToCasetoContactOwner() {
        //Create a Contact that is assigned to a Sales Rep
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 2);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        String testQueue = 'Pre-Sales Engineering Queue';
        Group validQueList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :testQueue];
        System.debug('Here is the que Name that was found ' + validQueList.Name);
        System.debug('Here is the id : ' + validQueList.Id);
        List<Contact> testContactList = [
            SELECT ID, AccountId, name, OwnerId, Primary_Email__C
            FROM Contact
            WHERE AccountID = :testAccountID
        ];
        RecordType pseCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'PSE_Case'
            LIMIT 1
        ];

        Case caseToInsert = new Case();
        caseToInsert.Origin = 'Email: Quotes@';
        caseToInsert.Priority = 'High';
        caseToInsert.RecordTypeId = pseCaseRecordType.Id;
        caseToInsert.OwnerId = AppConstants.API_USER;
        caseToInsert.SuppliedEmail = testContactList[0].Primary_Email__c;

        Case caseToInsert2 = new Case();
        caseToInsert2.Origin = 'Email: getaquote@';
        caseToInsert2.Priority = 'High';
        caseToInsert2.RecordTypeId = pseCaseRecordType.Id;
        caseToInsert2.OwnerId = validQueList.Id;
        caseToInsert2.SuppliedEmail = testContactList[0].Primary_Email__c;

        Test.StartTest();
        insert new List<Case>{ caseToInsert, caseToInsert2 };
        Test.StopTest();

        System.assertEquals(
            testContactList[0].OwnerID,
            [SELECT OwnerID FROM Case WHERE ID = :caseToInsert.ID]
            .OwnerID,
            'The Case did not change the owner'
        );

        System.assertEquals(
            testContactList[0].OwnerID,
            [SELECT OwnerID FROM Case WHERE ID = :caseToInsert2.ID]
            .OwnerID,
            'The Case did not change the owner'
        );
    }

    @isTest
    static void assignPSEQuotesEmailToCasetoContactOwnerNotActive() {
        //Create a Contact that is assigned to a Sales Rep
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 2);
        Account testAccount = testAccountList[0];
        ID testAccountID = testAccount.ID;
        String testQueue = 'Pre-Sales Engineering Queue';
        Group validQueList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :testQueue];
        System.debug('Here is the que Name that was found ' + validQueList.Name);
        System.debug('Here is the id : ' + validQueList.Id);
        List<Contact> testContactList = [
            SELECT ID, AccountId, name, OwnerId, Primary_Email__C, Owner.IsActive
            FROM Contact
            WHERE AccountID = :testAccountID
        ];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            User u = [SELECT Id, IsActive FROM User WHERE Id = :testContactList[0].OwnerId];
            u.IsActive = false;
            update u;
        }

        System.debug([SELECT Id, IsActive FROM User WHERE Id = :testContactList[0].OwnerId]);
        RecordType pseCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'PSE_Case'
            LIMIT 1
        ];

        Case caseToInsert = new Case();
        caseToInsert.Origin = 'Email: Quotes@';
        caseToInsert.Priority = 'High';
        caseToInsert.RecordTypeId = pseCaseRecordType.Id;
        caseToInsert.OwnerId = AppConstants.API_USER;
        caseToInsert.SuppliedEmail = testContactList[0].Primary_Email__c;
        insert caseToInsert;

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseToInsert.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Hi there, I am have a question about </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'sample@test1.com';
        emailTest.ToAddress = 'Quotes@xometry.com';

        Test.StartTest();
        insert emailTest;
        Test.StopTest();

        Case testCaseResult = [
            SELECT ID, CaseNumber, OwnerID, Owner.Name, SuppliedEmail, Owner.IsActive
            FROM Case
            WHERE ID = :caseToInsert.ID
        ];
        System.debug('Here is the new case');
        System.debug(testCaseResult);
        ID expectedOwnerId = validQueList.Id;
        System.assertEquals(expectedOwnerId, testCaseResult.OwnerID, 'The Case did not change the owner');
    }

    @isTest
    public static void linkQuotetoExistingCaseOwnerPSE() {
        Group pseQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Pre-Sales Engineering Queue'];
        List<Case> caseList = TestDataFactory.createTestCases(1, 'Web', 'PSE_Case');
        Case testCase = caseList[0];
        //Update the Case with a test Quote ID and make owner Sales API

        String testXomId = 'AAAAA-00001';
        testCase.Shadow_Xometry_ERP_ID__c = testXomId;
        testCase.PSE_Quote_Link__c = true;
        testCase.OwnerId = AppConstants.SALES_API_USER;
        update testCase;

        //Insert the Quote
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

        test.startTest();
        insert myQuote;
        test.stopTest();

        Case caseResult = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE Id = :testCase.Id][0];

        System.assertEquals(pseQueue.Id, caseResult.OwnerId, 'Case owner should be PSE');
    }

    @isTest(seeAllData=false)
    static void createOutcomeRecordHistoryTest() {
        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        insert testOpp;

        System.assertEquals(0, [SELECT Id FROM CaseHistory__c].size(), 'The CaseHistory should be empty.');

        Case testCase = new Case(
            SuppliedEmail = 'test@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = casePSERecordTypeId
        );
        Case testCase2 = new Case(
            SuppliedEmail = 'test2@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = casePSERecordTypeId
        );
        Case testCase3 = new Case(
            SuppliedEmail = 'test3@test.com',
            Opportunity__c = testOpp.Id,
            PSEOutcome__c = '(PSE Option) - RFQ Needed',
            RecordTypeId = casePSERecordTypeId
        );
        Case testCase4 = new Case(
            SuppliedEmail = 'test4@test.com',
            Opportunity__c = testOpp.Id,
            SalesOpsOutcome__c = 'Information Needed',
            RecordTypeId = casePSERecordTypeId
        );
        insert new List<Case>{ testCase, testCase2, testCase3, testCase4 };

        System.assertEquals(
            1,
            [SELECT Id FROM CaseHistory__c WHERE Case__c = :testCase3.Id].size(),
            'CaseHistory should be created.'
        );

        System.assertEquals(
            1,
            [SELECT Id FROM CaseHistory__c WHERE Case__c = :testCase4.Id].size(),
            'CaseHistory should be created.'
        );

        test.StartTest();

        testCase.PSEOutcome__c = '(PSE Option) - RFQ Needed';
        testCase2.OutcomeSalesUse__c = 'Information Provided to PSE/SO/else';
        testCase4.SalesOpsOutcome__c = 'Quote Configured for AQ';
        update new List<Case>{ testCase, testCase2, testCase4 };

        test.StopTest();

        System.assertEquals(5, [SELECT Id FROM CaseHistory__c].size(), 'New CaseHistory should be created.');
    }

    @isTest(seeAllData=false)
    static void createTeamMemberTest() {
        User testContactOwnerUser = TestDataFactory.createTestUsers()[0];
        User testPreSalesUser = TestDataFactory.createTestUserSecond()[0];

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            testPreSalesUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Xometry Pre-Sales Engineering'].Id;
            update testPreSalesUser;
        }

        Contact contactTest = new Contact();
        contactTest.FirstName = 'TestMan';
        contactTest.LastName = 'LastNamington';
        contactTest.Primary_Email__c = 'TestMan@domain.com';
        contactTest.OwnerId = testContactOwnerUser.Id;
        insert contactTest;

        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        insert testOpp;

        Map<String, Id> rolesMap = new Map<String, Id>();
        for (CaseTeamRole tRole : [SELECT Id, Name FROM CaseTeamRole]) {
            rolesMap.put(tRole.Name, tRole.Id);
        }

        Id rolePSEId = rolesMap.get('PSE2.0-PSE');
        Id roleContactOwnerId = rolesMap.get('PSE2.0-Contact Owner');

        test.StartTest();

        Case testCase = new Case(
            SuppliedEmail = 'test@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = casePSERecordTypeId,
            ContactId = contactTest.Id
        );
        Case testCase2 = new Case(
            SuppliedEmail = 'test@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = casePSERecordTypeId
        );
        insert new List<Case>{ testCase, testCase2 };

        CaseTeamMember teamMember = new CaseTeamMember();
        teamMember.ParentId = testCase2.Id;
        teamMember.MemberId = testPreSalesUser.Id;
        teamMember.TeamRoleId = roleContactOwnerId;
        insert teamMember;

        testCase.OwnerId = testPreSalesUser.Id;
        testCase2.OwnerId = testPreSalesUser.Id;
        update new List<Case>{ testCase, testCase2 };

        test.StopTest();

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase.Id AND TeamRoleId = :roleContactOwnerId].size(),
            'New CaseTeamMember should be created.'
        );

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase.Id AND TeamRoleId = :rolePSEId].size(),
            'New CaseTeamMember should be created.'
        );

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase2.Id AND TeamRoleId = :roleContactOwnerId].size(),
            'Only one CaseTeamMember should be created.'
        );
    }

    @isTest(seeAllData=false)
    static void createSaleOpsTeamMemberTest() {
        User testContactOwnerUser = TestDataFactory.createTestUsers()[0];
        User testSaleOpsUser = TestDataFactory.createTestUserSecond()[0];

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            testSaleOpsUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Xometry Sales Ops'].Id;
            update testSaleOpsUser;
        }

        Contact contactTest = new Contact();
        contactTest.FirstName = 'TestMan';
        contactTest.LastName = 'LastNamington';
        contactTest.Primary_Email__c = 'TestMan@domain.com';
        contactTest.OwnerId = testContactOwnerUser.Id;
        insert contactTest;

        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        insert testOpp;

        Id roleId = [SELECT Id, Name FROM CaseTeamRole WHERE Name = 'PSE2.0-Sales Ops'].Id;

        test.StartTest();

        Case testCase3 = new Case(
            SuppliedEmail = 'test@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = casePSERecordTypeId
        );
        insert new List<Case>{ testCase3 };

        testCase3.OwnerId = testSaleOpsUser.Id;

        update new List<Case>{ testCase3 };

        test.StopTest();

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase3.Id AND TeamRoleId = :roleId].size(),
            'Only one CaseTeamMember should be created.'
        );
    }

    @isTest(seeAllData=false)
    static void createTSETeamMemberTest() {
        Map<String, Id> rolesMap = new Map<String, Id>();
        for (CaseTeamRole tRole : [SELECT Id, Name FROM CaseTeamRole]) {
            rolesMap.put(tRole.Name, tRole.Id);
        }

        Id roleTSEId = rolesMap.get('PSE2.0-TSE');

        User testUser = TestDataFactory.createTestUsers('TSE')[0];

        Id specialUserId;
        for (Admin_Ref_Variable__mdt adminRefVarValues : [
            SELECT Text_Ref_Var__c
            FROM Admin_Ref_Variable__mdt
            WHERE DeveloperName = 'createTSETeamMember'
        ]) {
            specialUserId = adminRefVarValues.Text_Ref_Var__c.split(';')[0];
        }
        User testUser2 = [SELECT Id FROM User WHERE Id = :specialUserId];

        test.StartTest();

        Case testCase = new Case(
            SuppliedEmail = 'test@test.com',
            RecordTypeId = casePSERecordTypeId,
            OwnerId = testUser.Id
        );
        Case testCase2 = new Case(SuppliedEmail = 'test2@test.com', RecordTypeId = casePSERecordTypeId);
        Case testCase3 = new Case(SuppliedEmail = 'test3@test.com', RecordTypeId = casePSERecordTypeId);
        insert new List<Case>{ testCase, testCase2, testCase3 };

        testCase2.OwnerId = testUser.Id;
        testCase3.OwnerId = testUser2.Id;
        update new List<Case>{ testCase2, testCase3 };

        test.StopTest();

        System.assertEquals(
            1,
            [SELECT Id, TeamRoleId FROM CaseTeamMember WHERE ParentId = :testCase.Id AND TeamRoleId = :roleTSEId]
                .size(),
            'TSE CaseTeamMember should be created.'
        );

        System.assertEquals(
            1,
            [SELECT Id, TeamRoleId FROM CaseTeamMember WHERE ParentId = :testCase2.Id AND TeamRoleId = :roleTSEId]
                .size(),
            'TSE CaseTeamMember should be created.'
        );

        System.assertEquals(
            1,
            [SELECT Id, TeamRoleId FROM CaseTeamMember WHERE ParentId = :testCase3.Id AND TeamRoleId = :roleTSEId]
                .size(),
            'TSE CaseTeamMember should be created.'
        );
    }

    @isTest(seeAllData=false)
    static void createOppOwnerTeamMemberTest() {
        User testContactOwnerUser = TestDataFactory.createTestUsers()[0];

        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        insert testOpp;

        Map<String, Id> rolesMap = new Map<String, Id>();
        for (CaseTeamRole tRole : [SELECT Id, Name FROM CaseTeamRole]) {
            rolesMap.put(tRole.Name, tRole.Id);
        }

        Case testCase2 = new Case(SuppliedEmail = 'test@test.com', RecordTypeId = casePSERecordTypeId);
        insert new List<Case>{ testCase2 };

        System.assertEquals(
            0,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase2.Id].size(),
            'CaseTeamMember should be empty.'
        );

        Case testCase = new Case(
            SuppliedEmail = 'test@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = casePSERecordTypeId
        );

        test.StartTest();

        testCase2.Opportunity__c = testOpp.Id;
        upsert new List<Case>{ testCase, testCase2 };

        test.StopTest();

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase.Id].size(),
            'Only one CaseTeamMember should be created.'
        );

        System.assertEquals(
            1,
            [SELECT Id FROM CaseTeamMember WHERE ParentId = :testCase2.Id].size(),
            'Only one CaseTeamMember should be created.'
        );
    }

    @isTest(seeAllData=false)
    static void createTeamMemberNoAuditErrorTest() {
        Map<String, Id> rolesMap = new Map<String, Id>();
        for (CaseTeamRole tRole : [SELECT Id, Name FROM CaseTeamRole]) {
            rolesMap.put(tRole.Name, tRole.Id);
        }

        Id rolePSEId = rolesMap.get('PSE2.0-PSE');
        Id roleOppOwnerId = rolesMap.get('PSE2.0-Opportunity Owner');

        User testContactOwnerUser = TestDataFactory.createTestUsers()[0];

        Contact contactTest = new Contact();
        contactTest.FirstName = 'TestMan';
        contactTest.LastName = 'LastNamington';
        contactTest.Primary_Email__c = 'TestMan@domain.com';
        contactTest.OwnerId = testContactOwnerUser.Id;
        insert contactTest;

        Id contOwnerId = [SELECT Id, OwnerId FROM Contact][0].ownerId;
        Opportunity testOpp = new Opportunity(Name = 'Test', CloseDate = Date.today(), StageName = 'Open');
        testOpp.OwnerId = contOwnerId;
        insert testOpp;

        test.StartTest();

        Case testCase = new Case(
            SuppliedEmail = 'test@test.com',
            Opportunity__c = testOpp.Id,
            RecordTypeId = casePSERecordTypeId,
            ContactId = contactTest.Id
        );
        insert new List<Case>{ testCase };

        test.StopTest();

        System.assertEquals(
            1,
            [SELECT Id, TeamRoleId FROM CaseTeamMember WHERE ParentId = :testCase.Id].size(),
            'Only one CaseTeamMember should be created.'
        );

        System.assertEquals(0, [SELECT Id FROM Audit_Trail_Error__c].size(), 'No error found.');
    }

    @isTest
    static void assignXomEmailToSalesStaff() {
        String testQueue = 'Pre-Sales Engineering Queue';
        Group validQueList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :testQueue];
        System.debug('Here is the que Name that was found ' + validQueList.Name);
        System.debug('Here is the id : ' + validQueList.Id);
        RecordType pseCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'PSE_Case'
            LIMIT 1
        ];
        List<User> uList = TestDataFactory.createTestUsersStaff();
        User u = [SELECT Id, Email, IsActive, Profile.Name FROM User WHERE ID = :uList[0].Id][0];
        System.debug(u);

        Case caseToInsert = new Case();
        caseToInsert.Origin = 'Email: Quotes@';
        caseToInsert.Priority = 'High';
        caseToInsert.RecordTypeId = pseCaseRecordType.Id;
        caseToInsert.OwnerId = AppConstants.API_USER;
        caseToInsert.SuppliedEmail = u.Email;
        insert caseToInsert;

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseToInsert.Id;
        emailTest.Subject = 'Random Question';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Hi there, I am have a question about </p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = u.Email;
        emailTest.ToAddress = 'Quotes@xometry.com';

        Test.StartTest();
        insert emailTest;
        Test.StopTest();

        Case testCaseResult = [
            SELECT ID, CaseNumber, OwnerID, Owner.Name, SuppliedEmail
            FROM Case
            WHERE ID = :caseToInsert.ID
        ][0];
        System.debug('Here is the new case');
        System.debug(testCaseResult);
        ID expectedOwnerId = u.Id;
        System.assertEquals(expectedOwnerId, testCaseResult.OwnerID, 'The Case is the users email');
    }
    @isTest
    public static void setPriorityFromAccountVIPUpdated() {
        List<Account> testAccountList = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 1);
        Account testAccount = testAccountList[0];
        testAccount.VIP__c = true;
        update testAccount;

        Contact testContact = [
            SELECT ID, AccountId, name, OwnerId, Primary_Email__C
            FROM Contact
            WHERE AccountID = :testAccount.Id
        ][0];

        Case testCase = new Case();
        testCase.Subject = 'Case priority test';
        testCase.Origin = 'Web';
        testCase.Comments = 'This should associate to an account';
        testCase.SuppliedEmail = testContact.Primary_Email__c;
        insert testCase;

        testCase.AccountId = testAccount.Id;

        Test.startTest();
        update testCase;
        Test.stopTest();

        Case testCaseRes = [SELECT Id, AccountId, ContactId, Priority FROM Case WHERE Id = :testCase.Id][0];
        System.assertEquals('High', testCaseRes.Priority, 'The case priority is not high');
    }

    @isTest
    public static void setPriorityFromAccountVIPEmail() {
        Id caseGeneralRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('GeneralSupportCase')
            .getRecordTypeID();
        User testUser = TestDataFactory.createCaseManager()[0];

        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Email: Support@';
        caseTest.RecordTypeId = caseGeneralRTypeId;
        insert caseTest;

        Ops_Order__c opsOrderTest = new Ops_Order__c();
        opsOrderTest.Stage__c = 'Partially Complete';
        opsOrderTest.XometryOpsOrderID__c = '440A1-15008';
        opsOrderTest.CaseManager__c = testUser.Id;
        insert opsOrderTest;

        Supplier__c supplierTest = new Supplier__c();
        supplierTest.PartnerID__c = 'P-Test';
        supplierTest.SupplierCompanyName__c = 'P-Test';
        supplierTest.EmailAddress__c = 'email@tester.com';
        supplierTest.LastName__c = 'Supplier';
        insert supplierTest;
        Supplier__c supplierTestRes = [SELECT Id, AccountId__c FROM Supplier__c WHERE Id = :supplierTest.Id][0];

        Account accountTest = [SELECT Id, VIP__c FROM Account WHERE Id = :supplierTestRes.AccountId__c][0];
        accountTest.VIP__c = true;
        update accountTest;
        Account accountTestRes = [SELECT Id, VIP__c FROM Account WHERE Id = :supplierTestRes.AccountId__c][0];
        System.debug(accountTestRes);

        Job__c jobTest = new Job__c();
        jobTest.Name = 'Test-Job';
        jobTest.XometryJobID__c = 'J0012345';
        jobTest.XometryOpsOrderID__c = opsOrderTest.XometryOpsOrderID__c;
        jobTest.Supplier__c = supplierTest.Id;
        insert jobTest;

        Test.startTest();

        EmailMessage emailTest = new EmailMessage();
        emailTest.Incoming = true;
        emailTest.ParentId = caseTest.Id;
        emailTest.Subject = 'Subject Test - Job ' + jobTest.XometryJobID__c + ' - More text';
        emailTest.HtmlBody = '<p>Body text</p><br/>';
        emailTest.HtmlBody += '<p>Order: ' + opsOrderTest.XometryOpsOrderID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>Job: ' + jobTest.XometryJobID__c + '</p><br/>';
        emailTest.HtmlBody += '<p>footer</p>';
        emailTest.FromAddress = 'partner-question@xometry.com';
        insert emailTest;

        Test.stopTest();

        Case caseTestRes = [
            SELECT RecordTypeId, Job__c, Supplier__c, AccountId, Account.VIP__c, Priority, Origin
            FROM Case
            WHERE Id = :caseTest.Id
        ][0];

        System.assertEquals('High', caseTestRes.Priority, 'The case priority is not high');
    }

    @isTest
    static void setReSourcingRecordTypeOnOwnerNotChange() {
        ID caseReSourceRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('ReSource')
            .getRecordTypeId();

        String strEmail = 'test@validdomain.com';

        Case testCase = new Case();
        testCase.Subject = 'Test Case Routing';
        testCase.Origin = 'Internal';
        testCase.Comments = 'This is a test Case that should be routed';
        testCase.SuppliedEmail = strEmail;
        testCase.RecordTypeId = caseReSourceRTypeId;
        insert testCase;
        Test.startTest();
        testCase.OwnerId = [
            SELECT UserOrGroupId, Group.Name, Group.Id
            FROM GroupMember
            WHERE Group.Name = 'Automotive'
            LIMIT 1
        ]
        .UserOrGroupId;
        update testCase;
        Test.stopTest();

        System.assertNotEquals(
            'CaseMgmt',
            [SELECT RecordType.DeveloperName FROM Case WHERE SuppliedEmail = :strEmail LIMIT 1]
            .RecordType.DeveloperName,
            'The case RecordType was updated.'
        );
    }

    @isTest
    public static void assignOppToCaseTest() {
        Account a = TestDataFactory.createTestAccountNonGenerics(1, 'AM', 1)[0];
        Opportunity opp = new Opportunity();
        opp.Name = 'Opp1';
        opp.CloseDate = Date.today();
        opp.AccountId = a.Id;
        opp.StageName = 'Open';
        opp.Shadow_JobId__c = 'J0036578';
        opp.RecordTypeId = oppSellerMarketplaceRecordTypeId;
        insert opp;

        Case c = new Case();
        c.Subject = 'test1';
        c.Status = 'New';
        c.Type = 'FinServ';
        c.Supplies_Xometry_Job__c = opp.Shadow_JobId__c;
        c.RecordTypeId = caseSellerMarketplaceRecordTypeId;
        Test.startTest();
        insert c;
        Test.stopTest();

        Case cResult = [SELECT Supplies_Xometry_Job__c, Opportunity__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(opp.Id, cResult.Opportunity__c, 'Supplies Opp was not associated to the case');
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdateOppOnCaseTest() {
        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        Opportunity oppTest = new Opportunity(
            Name = 'testOpp1',
            StageName = 'Open',
            CloseDate = System.today().addDays(10)
        );
        insert oppTest;

        CaseOpportunity__c caseOppTest = new CaseOpportunity__c(Case__c = testCase.Id);
        insert caseOppTest;

        Test.startTest();

        testCase.Opportunity__c = null;
        update testCase;

        testCase.Opportunity__c = oppTest.Id;
        update testCase;

        testCase.Opportunity__c = null;
        update testCase;

        Test.stopTest();

        List<CaseOpportunity__c> caseOppAfter = [
            SELECT Id, Xometry_ERP_ID__c, IsPrimaryOppOnCase__c, Opportunity__c
            FROM CaseOpportunity__c
            ORDER BY Id
        ];

        System.assertEquals(
            'AAAAA-00001',
            caseOppAfter[0].Xometry_ERP_ID__c,
            'Junction should match the old Case ERP ID'
        );
    }

    @isTest(seeAllData=false)
    static void syncCaseOpportunityUpdateOppOnCaseTest2() {
        Case testCase = new Case(Shadow_Xometry_ERP_ID__c = 'AAAAA-00001');
        insert testCase;

        Opportunity oppTest = new Opportunity(
            Name = 'testOpp1',
            StageName = 'Open',
            CloseDate = System.today().addDays(10),
            Last_Quote_Xometry_ERP_ID__c = 'AAAAA-00001'
        );
        Opportunity oppTest2 = new Opportunity(
            Name = 'testOpp2',
            StageName = 'Open',
            CloseDate = System.today().addDays(10)
        );
        insert new List<Opportunity>{ oppTest, oppTest2 };

        CaseOpportunity__c caseOppTest2 = new CaseOpportunity__c(
            Case__c = testCase.Id,
            Opportunity__c = oppTest2.Id,
            IsPrimaryOppOnCase__c = true
        );
        insert new List<CaseOpportunity__c>{ caseOppTest2 };

        List<CaseOpportunity__c> caseOppBefore = [
            SELECT Id, Xometry_ERP_ID__c, IsPrimaryOppOnCase__c, Opportunity__c
            FROM CaseOpportunity__c
            ORDER BY Id
        ];

        System.assertEquals(2, caseOppBefore.size(), 'First Junction should be updated');
        System.assertEquals('AAAAA-00001', caseOppBefore[0].Xometry_ERP_ID__c, 'Junction should match the Case ERP ID');
        System.assertEquals(false, caseOppBefore[0].IsPrimaryOppOnCase__c, 'Junction should not be Primary');

        Test.startTest();

        testCase.Opportunity__c = oppTest.Id;
        update testCase;

        Test.stopTest();

        List<CaseOpportunity__c> caseOppAfter = [
            SELECT Id, Xometry_ERP_ID__c, IsPrimaryOppOnCase__c, Opportunity__c
            FROM CaseOpportunity__c
            ORDER BY Id
        ];

        System.assertEquals(true, caseOppAfter[0].IsPrimaryOppOnCase__c, 'Junction should not be Primary');
    }

    @isTest
    public static void closeCollectionsCaseTest() {
        List<Case> casesToInsert = new List<Case>();
        Case c1 = new Case();
        c1.Subject = 'Collection 1';
        c1.Status = 'New';
        c1.Billing_Profile_ID__c = 'B1234';
        c1.Total_Past_Due__c = 5000.00;
        c1.RecordTypeId = AppConstants.collectionsRTypeId;
        casesToInsert.add(c1);

        Case c2 = new Case();
        c2.Subject = 'Collection 2';
        c2.Status = 'New';
        c2.Billing_Profile_ID__c = 'B1234';
        c2.Total_Past_Due__c = 1000.00;
        c2.RecordTypeId = AppConstants.collectionsRTypeId;
        casesToInsert.add(c2);

        Case c3 = new Case();
        c3.Subject = 'Collection 3';
        c3.Status = 'Response Received';
        c3.Billing_Profile_ID__c = 'B1234';
        c3.Total_Past_Due__c = 28.28;
        c3.RecordTypeId = AppConstants.collectionsRTypeId;
        casesToInsert.add(c3);

        Case c4 = new Case();
        c4.Subject = 'Other Case';
        c4.Status = 'New';
        c4.Billing_Profile_ID__c = 'B1234';
        c4.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        casesToInsert.add(c4);

        insert casesToInsert;

        Test.startTest();
        c1.Total_Past_Due__c = 0.00;
        c1.Status = 'Closed';
        update c1;
        Test.stopTest();

        Case c1Result = [SELECT Id, isClosed FROM Case WHERE ID = :c1.Id];
        Case c2Result = [SELECT Id, isClosed, Total_Past_Due__c FROM Case WHERE ID = :c2.Id];
        Case c3Result = [SELECT Id, isClosed, Description FROM Case WHERE ID = :c3.Id];
        Case c4Result = [SELECT Id, isClosed FROM Case WHERE ID = :c4.Id];
        System.assertEquals(true, c1Result.isClosed, 'The trigger collections case did not close');
        System.assertEquals(true, c2Result.isClosed, 'The open collections case did not close');
        System.assertEquals(0, c2Result.Total_Past_Due__c, 'The total past due was not updated');
        System.assertEquals(false, c3Result.isClosed, 'The collections case was closed');
        System.assertEquals(
            '$0.00 Total Due balance - COLLECTIONS CASE CLOSED',
            c3Result.Description,
            'The collections case description was not updated'
        );
        System.assertEquals(false, c4Result.isClosed, 'The non-collections case was closed');
    }

    @isTest
    public static void closeDupCollectionsCaseTest() {
        Case c1 = new Case();
        c1.Subject = 'Dup Collection 1';
        c1.Status = 'New';
        c1.Billing_Profile_ID__c = 'B4321';
        c1.Total_Past_Due__c = 28.28;
        c1.RecordTypeId = AppConstants.collectionsRTypeId;
        insert c1;

        Test.startTest();
        Case c2 = new Case();
        c2.Subject = 'Dup Collection 1';
        c2.Status = 'New';
        c2.Billing_Profile_ID__c = 'B4321';
        c2.Total_Past_Due__c = 23.23;
        c2.RecordTypeId = AppConstants.collectionsRTypeId;
        insert c2;

        Test.stopTest();

        Case c1Result = [SELECT Id, Status, Description, isClosed FROM Case WHERE ID = :c1.Id];
        Case c2Result = [SELECT Id, Status, isClosed FROM Case WHERE ID = :c2.Id];
        System.assertEquals(true, c1Result.isClosed, 'The old collections case did not close');
        System.assertEquals(false, c2Result.isClosed, 'The new collections case was unintentionally closed');
        System.assertEquals(
            'OUTDATED INFORMATION - COLLECTIONS CASE CLOSED',
            c1Result.Description,
            'The collections case description was not updated'
        );
    }

    @isTest
    public static void doNotAllowDupCollectionsCasesToOpenTest() {
        Case c1 = new Case();
        c1.Subject = 'Collection 1';
        c1.Status = 'New';
        c1.Billing_Profile_ID__c = 'B4321';
        c1.Total_Past_Due__c = 28.28;
        c1.RecordTypeId = AppConstants.collectionsRTypeId;
        insert c1;

        c1.Status = 'Solved';
        update c1;

        Case c2 = new Case();
        c2.Subject = 'Collection 2';
        c2.Status = 'New';
        c2.Billing_Profile_ID__c = 'B4321';
        c2.Total_Past_Due__c = 28.28;
        c2.RecordTypeId = AppConstants.collectionsRTypeId;
        insert c2;

        boolean exceptionThrown = false;
        Test.startTest();
        try {
            c1.Status = 'Open';
            update c1;
            System.debug('Just updated c1');
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Exception not encountered');

        Case c1Result = [SELECT Id, Status, Description, isClosed FROM Case WHERE ID = :c1.Id];
        Case c2Result = [SELECT Id, Status, isClosed FROM Case WHERE ID = :c2.Id];
        System.assertEquals(true, c1Result.isClosed, 'The old collections case did not remain closed');
        System.assertEquals(false, c2Result.isClosed, 'The current collections case was unintentionally closed');
    }

    @isTest(seeAllData=false)
    public static void updateStatusRollUpOnOrderTest() {
        Map<String, Ops_Order__C> opsOrderMap = TestDataFactory.createLargeOrderTestData(
            1,
            2,
            0,
            new List<Order_ERP__c>()
        );
        //Get the parent and child
        ID parentID = null;
        List<ID> childIdSet = new List<ID>();
        for (Ops_Order__c ord : opsOrderMap.values()) {
            System.debug('We have an ID of : ' + ord.ID);
            if (ord.ParentOpsOrder__c == null) {
                parentID = ord.ID;
            } else {
                childIdSet.add(ord.ID);
            }
        }
        ID child1ID = childIdSet[0];
        ID child2ID = childIdSet[1];

        Test.startTest();
        System.debug('Update the case');
        Case case2 = [SELECT ID, status FROM Case WHERE GNOOrder__c = :child2ID][0];
        case2.status = 'Solved';
        update case2;
        Test.stopTest();

        Map<Id, Ops_Order__c> opsOrderResultAfter = new Map<Id, Ops_Order__c>(
            [SELECT Cases_In_Progress__c, Cases_Completed__c FROM Ops_Order__c]
        );
        System.assertEquals(1, opsOrderResultAfter.get(child1ID).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResultAfter.get(child1ID).Cases_Completed__c, 'Rollup should be updated');

        System.assertEquals(0, opsOrderResultAfter.get(child2ID).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(1, opsOrderResultAfter.get(child2ID).Cases_Completed__c, 'Rollup should be updated');

        System.assertEquals(2, opsOrderResultAfter.get(parentID).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(1, opsOrderResultAfter.get(parentID).Cases_Completed__c, 'Rollup should be updated');
    }

    @isTest(seeAllData=false)
    public static void updateStatusRollUpOnOrderDeleteTest() {
        Map<String, Ops_Order__C> opsOrderMap = TestDataFactory.createLargeOrderTestData(
            1,
            2,
            0,
            new List<Order_ERP__c>()
        );
        //Get the parent and child
        ID parentID = null;
        List<ID> childIdSet = new List<ID>();
        for (Ops_Order__c ord : opsOrderMap.values()) {
            System.debug('We have an ID of : ' + ord.ID);
            if (ord.ParentOpsOrder__c == null) {
                parentID = ord.ID;
            } else {
                childIdSet.add(ord.ID);
            }
        }
        ID child1ID = childIdSet[0];
        ID child2ID = childIdSet[1];

        Test.startTest();
        List<Case> myCases = [SELECT ID, recordtype.name, type, status FROM case];
        System.debug('Here are my cases ' + myCases.size());
        System.debug(myCases);
        System.debug('Update the case');
        Case case1 = [SELECT ID, status FROM Case WHERE GNOOrder__c = :child1ID][0];
        case1.status = 'Solved';
        update case1;

        Case case2 = [SELECT ID, status FROM Case WHERE GNOOrder__c = :child2ID][0];
        case2.status = 'Solved';
        delete case2;
        Test.stopTest();

        Map<Id, Ops_Order__c> opsOrderResultAfter = new Map<Id, Ops_Order__c>(
            [SELECT Cases_In_Progress__c, Cases_Completed__c FROM Ops_Order__c]
        );
        System.assertEquals(0, opsOrderResultAfter.get(child1ID).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(1, opsOrderResultAfter.get(child1ID).Cases_Completed__c, 'Rollup should be updated');

        System.assertEquals(0, opsOrderResultAfter.get(child2ID).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResultAfter.get(child2ID).Cases_Completed__c, 'Rollup should be updated');

        System.assertEquals(1, opsOrderResultAfter.get(parentID).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(1, opsOrderResultAfter.get(parentID).Cases_Completed__c, 'Rollup should be updated');
    }

    // @isTest
    // public static void doNotAllowDupSourcingCases_separateInserts() {
    //     List<Case> casesToInsert = new List<Case>();
    //     String orderedPartID = 'tvsk2328jt21021cm12322';

    //     Case c1 = new Case();
    //     c1.Subject = 'NO TAKE - CASE1';
    //     c1.Status = 'New';
    //     c1.OrderedPartID__c = orderedPartID;
    //     c1.RecordTypeId = AppConstants.caseSourcingRTypeId;
    //     casesToInsert.add(c1);

    //     Case c2 = new Case();
    //     c2.Subject = 'NOT A SOURCING CASE';
    //     c2.Status = 'New';
    //     c2.OrderedPartID__c = orderedPartID;
    //     c2.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
    //     casesToInsert.add(c2);

    //     insert casesToInsert;

    //     Case c3 = new Case();
    //     c3.Subject = 'NO TAKE - CASE2';
    //     c3.Status = 'New';
    //     c3.OrderedPartID__c = orderedPartID;
    //     c3.RecordTypeId = AppConstants.caseSourcingRTypeId;

    //     insert c3;
    //     Test.startTest();
    //     CaseHandler.deleteDuplicateCasesFuture(new Set<String>{ orderedPartID });
    //     Test.stopTest();

    //     List<Case> sourcingCases = [
    //         SELECT ID, Subject, OrderedPartID__c
    //         FROM Case
    //         WHERE OrderedPartID__c = :orderedPartID
    //     ];

    //     System.assertEquals(2, sourcingCases.size(), 'The incorrect number of cases were created');
    // }

    @isTest
    public static void doNotAllowDupSourcingCases_simultaneousInserts() {
        List<Case> casesToInsert = new List<Case>();
        String orderedPartID = 'tvsk2328jt21021cm12322';
        DateTime caseCreatedDate = DateTime.newInstance(2022, 12, 3, 6, 28, 23);

        Case c1 = new Case();
        c1.Subject = 'NO TAKE - CASE1';
        c1.Status = 'New';
        c1.OrderedPartID__c = orderedPartID;
        c1.RecordTypeId = AppConstants.caseSourcingRTypeId;
        c1.CreatedDate = caseCreatedDate;
        casesToInsert.add(c1);

        Case c2 = new Case();
        c2.Subject = 'NO TAKE - CASE2';
        c2.Status = 'New';
        c2.OrderedPartID__c = orderedPartID;
        c2.RecordTypeId = AppConstants.caseSourcingRTypeId;
        c2.CreatedDate = caseCreatedDate.addSeconds(1);
        casesToInsert.add(c2);

        Test.startTest();
        insert casesToInsert;
        Test.stopTest();

        List<Case> sourcingCases = [
            SELECT ID, Subject, OrderedPartID__c
            FROM Case
            WHERE OrderedPartID__c = :orderedPartID
        ];

        System.assertEquals(1, sourcingCases.size(), 'The incorrect number of cases were created');
    }

    @isTest
    public static void closedCaseNotOwnedByCPCQueue() {
        Id cpcQueue = [SELECT ID, DeveloperName FROM Group WHERE DeveloperName = 'CPC_Support' AND Type = 'Queue'].Id;

        Case testCase = new Case();
        testCase.Subject = 'Test CPC Queue';
        testCase.Origin = 'Internal';
        testCase.Comments = 'Closing this case should change the owner to CPC House user';
        testCase.SuppliedEmail = 'test@email.com';
        testCase.ownerId = cpcQueue;
        insert testCase;

        Test.startTest();
        testCase.Status = 'Solved';
        update testCase;
        Test.stopTest();

        Case testCaseResult = [SELECT Id, IsClosed, OwnerID FROM Case WHERE ID = :testCase.ID];

        System.debug(testCaseResult);
        System.assertEquals(AppConstants.CPC_HOUSE_USER, testCaseResult.ownerId, 'The owner stayed CPC Queue');
    }

    @isTest
    public static void caseOpsOrderDuplication() {
        Id cpcQueue = [SELECT ID, DeveloperName FROM Group WHERE DeveloperName = 'CPC_Support' AND Type = 'Queue'].Id;

        Order_ERP__C o = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__C o2 = TestDataFactory.createDefaultOrderERP(false);
        o2.Xometry_ERP_ID__c = 'CCCCC-34567';
        o2.Xometry_Quote_ID__c = 'Q13-5555-6666';
        List<Order_ERP__c> oList = new List<Order_ERP__c>{ o, o2 };
        insert oList;
        List<Ops_Order__c> oo = [SELECT Id, XometryOpsOrderID__c FROM Ops_Order__c];

        Case c = new Case();
        c.Subject = 'No Take Case';
        c.Origin = 'iInternal';
        c.ownerId = cpcQueue;
        c.SuppliedEmail = 'johndoe@superaccount.com';
        c.GNOOrder__c = oo[0].Id;
        c.ShadowXometryOrderID__c = o.Xometry_ERP_ID__c;
        insert c;

        c.GNOOrder__c = oo[1].Id;
        c.ERPPartStatus__c = 'All Offers Expired';
        c.ShadowXometryOrderID__c = o2.Xometry_ERP_ID__c;
        update c;

        List<CaseOpsOrder__c> cooRes = [
            SELECT Id, CaseOpsOrderKey__c, Case__c, Xometry_Quote_ID__c, Xometry_Order_ID__c
            FROM CaseOpsOrder__c
            WHERE Case__c = :c.id
        ];

        Test.startTest();
        c.Status = 'Closed';
        c.GNOOrder__c = oo[0].Id;
        c.ShadowXometryOrderID__c = o.Xometry_ERP_ID__c;
        update c;
        Test.stopTest();

        List<audit_trail_error__c> auditList = [
            SELECT ID, name, module__C, dev_audit_notes__c, statusCode__c, errorFields__c, errorMessage__c, Createddate
            FROM audit_trail_error__c
        ];
        System.assertEquals(0, auditList.size(), 'There was a duplicated Case Ops Order');
    }
    @isTest
    public static void dupCaseOps() {
        Id cpcQueue = [SELECT ID, DeveloperName FROM Group WHERE DeveloperName = 'CPC_Support' AND Type = 'Queue'].Id;

        String poNumber = '45000176406';

        Case c = new Case();
        c.Subject = 'No Take Case';
        c.Origin = 'Internal';
        c.ownerId = cpcQueue;
        c.SuppliedEmail = 'johndoe@superaccount.com';
        c.ShadowXometryOrderID__c = '2D487-15045';
        c.PO_Number__c = poNumber;
        insert c;

        Order_ERP__C o = TestDataFactory.createDefaultOrderERP(false);
        o.Xometry_ERP_ID__c = '2D487-15045';
        o.Xometry_Quote_ID__c = 'Q17-4623-2416';
        o.PONumber__c = poNumber;
        insert o;

        List<Order_ERP__c> ordersToInsert = new List<Order_ERP__c>();
        Order_ERP__C o1 = TestDataFactory.createDefaultOrderERP(false);
        o1.Xometry_ERP_ID__c = '2D487-15046';
        o1.Xometry_Quote_ID__c = 'Q17-4623-2416';
        o1.PONumber__c = poNumber;
        ordersToInsert.add(o1);
        Order_ERP__C o2 = TestDataFactory.createDefaultOrderERP(false);
        o2.Xometry_ERP_ID__c = '2D487-15047';
        o2.Xometry_Quote_ID__c = 'Q91-5292-9924';
        o2.PONumber__c = poNumber;
        ordersToInsert.add(o2);

        insert ordersToInsert;
        Test.startTest();
        List<Ops_Order__c> oo = [
            SELECT Id, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = '2D487-15046'
        ];
        c.ShadowXometryOrderID__c = '2D487-15046';
        c.GNOOrder__c = oo[0].Id;
        update c;
        Test.stopTest();

        List<audit_trail_error__c> auditList = [
            SELECT ID, name, module__C, dev_audit_notes__c, statusCode__c, errorFields__c, errorMessage__c, Createddate
            FROM audit_trail_error__c
        ];

        System.assertEquals(0, auditList.size(), 'There was a duplicated Case Ops Order');
    }

    @isTest
    static void creditApplicationPoCaseTest() {
        // Create 3 PO Cases
        //Create 3 Credit Application Cases
        List<Account> testAccounts = TestDataFactory.createTestAccountNonGenerics(4, 'BDR', 2);
        List<Contact> testContactList = [SELECT ID, AccountID, account.Email_Domain__c, Primary_Email__c FROM Contact];
        Map<ID, Contact> accountToContactMap = new Map<ID, Contact>();
        Map<ID, Contact> nonPOContactMap = new Map<ID, Contact>();
        for (Contact c : testContactList) {
            //Take the 1st Contact for each Account to put on Cases
            if (!accountToContactMap.containsKey(c.AccountId)) {
                accountToContactMap.put(c.AccountID, c);
            } else {
                nonPOContactMap.put(c.AccountID, c);
            }
        }
        List<Case> poCaseList = new List<Case>();
        case c1 = new Case();
        c1.Category__c = 'PO';
        c1.Status = 'New';
        c1.AccountID = testAccounts[0].Id;
        c1.ContactID = accountToContactMap.get(c1.AccountId).Id;
        c1.SuppliedEmail = accountToContactMap.get(c1.AccountId).Primary_Email__c;
        c1.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        c1.PO_Amount__c = 5005.45;
        c1.PO_Number__c = '45566';
        poCaseList.add(c1);
        case c2 = new Case();
        c2.Category__c = 'PO';
        c2.Status = 'New';
        c2.AccountID = testAccounts[1].Id;
        c2.ContactID = accountToContactMap.get(c2.AccountId).Id;
        c2.SuppliedEmail = accountToContactMap.get(c2.AccountId).Primary_Email__c;
        c2.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        c2.PO_Amount__c = 6005.45;
        c2.PO_Number__c = '45568';
        poCaseList.add(c2);
        case c3 = new Case();
        c3.Category__c = 'PO';
        c3.Status = 'New';
        c3.AccountID = testAccounts[2].Id;
        c3.ContactID = accountToContactMap.get(c3.AccountId).Id;
        c3.SuppliedEmail = accountToContactMap.get(c3.AccountId).Primary_Email__c;
        c3.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        c3.PO_Amount__c = 7005.45;
        c3.PO_Number__c = '75568';
        poCaseList.add(c3);
        insert poCaseList;
        List<Case> caCaseList = new List<Case>();

        Test.startTest();
        //Match PO Case based on Contact
        case ca1 = new Case();
        ca1.Category__c = 'Credit Applications';
        ca1.Billing_Profile_ID__c = '550505';
        ca1.Status = 'New';
        ca1.ContactID = c1.ContactId;
        ca1.AccountID = c1.AccountId;
        ca1.SuppliedEmail = c1.SuppliedEmail;
        ca1.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        ca1.Subject = 'New Billing Application';
        caCaseList.add(ca1);
        //Match PO Case based on Account use a different contact
        case ca2 = new Case();
        ca2.Category__c = 'Credit Applications';
        ca2.Billing_Profile_ID__c = '650505';
        ca2.Status = 'New';
        ca2.AccountID = c2.AccountId;
        ca2.ContactID = c2.ContactId;
        ca2.SuppliedEmail = nonPOContactMap.get(ca2.AccountID).primary_email__c;
        ca2.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        ca2.Subject = 'New Billing Application';
        caCaseList.add(ca2);
        //Should Not Match a PO Case at all
        case ca3 = new Case();
        ca3.Category__c = 'Credit Applications';
        ca3.Billing_Profile_ID__c = '750505';
        ca3.Status = 'New';
        ca3.AccountID = testAccounts[3].Id;
        ca3.ContactID = accountToContactMap.get(ca3.AccountID).ID;
        ca3.SuppliedEmail = accountToContactMap.get(ca3.AccountID).Primary_Email__c;
        ca3.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;
        ca3.Subject = 'New Billing Application';
        caCaseList.add(ca3);
        insert caCaseList;
        Test.stopTest();
        List<Case> resultCaseList = [
            SELECT ID, Contact.name, SuppliedEmail, account.name, Billing_Profile_ID__c, ParentId
            FROM Case
            WHERE Category__c = 'Credit Applications'
        ];
        System.assertEquals(3, resultCaseList.size(), 'The right number of Cases were returned');
        for (Case c : resultCaseList) {
            if (c.Billing_Profile_ID__C == ca1.Billing_Profile_ID__c) {
                System.assertEquals(c1.Id, c.ParentID, 'The Case did not get the correct parent');
            }
            if (c.Billing_Profile_ID__C == ca2.Billing_Profile_ID__c) {
                System.assertEquals(c2.Id, c.ParentID, 'The Case did not get the correct parent');
            }
            if (c.Billing_Profile_ID__C == ca3.Billing_Profile_ID__c) {
                System.assertEquals(
                    true,
                    String.isblank(c.ParentID),
                    'There was a parent ID added to the case when it should be null'
                );
            }
        }
        //CA 1 should be linked a PO case

        //CA 2 should be linked to a PO case
        //CA 3 should not be linked to a PO case
    }

    @isTest(seeAllData=false)
    static void noSystemOwnerDoubleTest() {
        Case testCase = new Case(SuppliedName = 'test1', OwnerId = AppConstants.API_USER);
        Case testCase2 = new Case(SuppliedName = 'test2', OwnerId = AppConstants.API_USER);

        Test.startTest();
        insert new List<Case>{ testCase, testCase2 };
        Test.stopTest();

        Id cpcSystemOnlyID; //OmniChannel Queue with a routing configuration to nowhere and no members

        for (Group g : [
            SELECT ID, DeveloperName
            FROM Group
            WHERE DeveloperName IN ('CPC_System_Only') AND Type = 'Queue'
        ]) {
            if (g.DeveloperName == 'CPC_System_Only') {
                cpcSystemOnlyID = g.Id;
            }
        }

        Map<Id, Case> casesTestResult = new Map<Id, Case>([SELECT Id, OwnerId FROM Case]);

        System.assertEquals(cpcSystemOnlyID, casesTestResult.get(testCase.Id).OwnerId, 'Case Owner should be updated');
        System.assertEquals(cpcSystemOnlyID, casesTestResult.get(testCase2.Id).OwnerId, 'Case Owner should be updated');
    }

    @isTest
    static void notCPCuserCaseTeamMember() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        map<String, List<SObject>> mapResult = TestDataFactory.createOppWithProject(testAccount);
        Opportunity testOpp = (Opportunity) mapResult.get('Opportunity')[0];
        testOpp.ownerId = AppConstants.CPC_HOUSE_USER;
        update testOpp;

        Case testCase = new Case(Opportunity__c = testOpp.Id, RecordTypeId = casePSERecordTypeId);
        Test.startTest();
        insert testCase;
        Test.stopTest();
        List<CaseTeamMember> lstCaseTeams = [
            SELECT Id
            FROM CaseTeamMember
            WHERE ParentId = :testCase.Id AND MemberId = :AppConstants.CPC_HOUSE_USER
        ];
        System.assertEquals(0, lstCaseTeams.size(), 'The CPC user not should be how case team member');
    }

    @isTest
    static void populateOppAccountFromJob() {
        Opportunity testOpp = TestDataFactory.createOppWithAccContact(false, 'BDR');
        Contact c = [SELECT Id, AccountId, Account.OwnerId FROM Contact WHERE Id =: testOpp.Primary_Contact__C LIMIT 1];
        ID testOrigOwnerID = c.Account.OwnerId;
        Date testCloseDate = Date.today() + 5;
        testOpp.name = 'TestOpp';
        testOpp.Primary_Contact__c = c.Id;
        testOpp.OwnerID = testOrigOwnerID;
        testOpp.Amount = 400;
        testOpp.CloseDate = testCloseDate;
        testOpp.Order_ERP_Xom_ID__c = 'BBBBB-34569';
        insert testOpp;

        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.XometryOpsOrderID__c = 'BBBBB-34569';
        insert opsOrder;

        Job__c testJob = new Job__c();
        testJob.Name = 'Test-Job';
        testJob.XometryJobID__c = 'Test-Job';
        testJob.XometryOpsOrderID__c = 'BBBBB-34569';
        testJob.OrderDueDate__c = Date.today() + 7;
        insert testJob;

        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Test.startTest();
        Case testCase = new Case(Job__c = testJob.Id, RecordTypeId = sourcingCaseRecordType.Id);
        insert testCase;
        Test.stopTest();

        Case caseSourcing = [SELECT Opportunity__c, AccountId, Job__c, Job__r.OrderID__c, Job__r.OrderID__r.Opportunity__c, Job__r.OrderID__r.Opportunity__r.AccountId FROM Case WHERE Id =: testCase.Id];

        System.assertEquals(c.AccountId, caseSourcing.AccountId, 'The Account is not populated');
        System.assertEquals(testOpp.Id, caseSourcing.Opportunity__c, 'The Opportunity is not populated');
    }

    @isTest
    static void populateOppAccountFromOpsOrder() {
        Opportunity testOpp = TestDataFactory.createOppWithAccContact(false, 'BDR');
        Contact c = [SELECT Id, AccountId, Account.OwnerId FROM Contact WHERE Id =: testOpp.Primary_Contact__C LIMIT 1];
        ID testOrigOwnerID = c.Account.OwnerId;
        Date testCloseDate = Date.today() + 5;
        testOpp.name = 'TestOpp';
        testOpp.Primary_Contact__c = c.Id;
        testOpp.OwnerID = testOrigOwnerID;
        testOpp.Amount = 400;
        testOpp.CloseDate = testCloseDate;
        testOpp.Order_ERP_Xom_ID__c = 'BBBBB-34569';
        insert testOpp;

        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.XometryOpsOrderID__c = 'BBBBB-34569';
        insert opsOrder;

        RecordType sourcingCaseRecordType = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = 'Sourcing'
            LIMIT 1
        ];

        Test.startTest();
        Case testCase = new Case(OrderID__c = opsOrder.XometryOpsOrderID__c, RecordTypeId = sourcingCaseRecordType.Id);
        insert testCase;
        Test.stopTest();

        Case caseSourcing = [SELECT Opportunity__c, AccountId, Job__c, Job__r.OrderID__c, Job__r.OrderID__r.Opportunity__c, Job__r.OrderID__r.Opportunity__r.AccountId FROM Case WHERE Id =: testCase.Id];

        System.assertEquals(c.AccountId, caseSourcing.AccountId, 'The Account is not populated');
        System.assertEquals(testOpp.Id, caseSourcing.Opportunity__c, 'The Opportunity is not populated');
    }
}