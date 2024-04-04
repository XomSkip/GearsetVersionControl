@isTest
public with sharing class OpsOrderTest {
    static final ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Customer')
        .getRecordTypeID();

    @isTest
    static void associateOpportunity() {
        Opportunity testOpp = TestDataFactory.createOppWithAccContact(false, 'BDR');
        Contact c = [SELECT Id, AccountId, Account.OwnerId FROM Contact LIMIT 1];
        ID testOrigOwnerID = c.Account.OwnerId;
        Date testCloseDate = Date.today() + 5;
        testOpp.name = 'TestOpp';
        testOpp.Primary_Contact__c = c.Id;
        testOpp.OwnerID = testOrigOwnerID;
        testOpp.Amount = 400;
        testOpp.CloseDate = testCloseDate;
        testOpp.Order_ERP_Xom_ID__c = 'BBBBB-34567';
        insert testOpp;

        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.XometryOpsOrderID__c = 'BBBBB-34567';

        Test.startTest();
        insert opsOrder;
        Test.stopTest();

        Ops_Order__c existingOpsList = [SELECT Id, Opportunity__c FROM Ops_Order__c WHERE Id = :opsOrder.Id][0];

        System.assertEquals(existingOpsList.Opportunity__c, testOpp.Id, 'Ops Order not associated to Opportunity');
    }

    @isTest
    static void noOpportunity() {
        Opportunity testOpp = TestDataFactory.createOppWithAccContact(false, 'BDR');
        Contact c = [SELECT Id, AccountId, Account.OwnerId FROM Contact LIMIT 1];
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
        opsOrder.XometryOpsOrderID__c = 'BBBBB-34567';

        Test.startTest();
        insert opsOrder;
        Test.stopTest();

        Ops_Order__c existingOpsList = [SELECT Id, Opportunity__c FROM Ops_Order__c WHERE Id = :opsOrder.Id][0];

        System.assertNotEquals(
            existingOpsList.Opportunity__c,
            testOpp.Id,
            'Ops Order matched incorrectly to Opportunity'
        );
    }

    @isTest
    static void noOrderID() {
        Ops_Order__c opsOrder = new Ops_Order__c();

        Test.startTest();
        insert opsOrder;
        Test.stopTest();

        Ops_Order__c existingOpsList = [SELECT Id, Opportunity__c FROM Ops_Order__c WHERE Id = :opsOrder.Id][0];

        System.assertEquals(existingOpsList.Opportunity__c, null, 'Ops Order matched incorrectly to Opportunity');
    }

    @isTest
    public static void createPendingDFMCaseOnInsert() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        Date OrderPlacedDate = Date.today();
        ord.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        ord.Order_ERP_CreatedDate__c = OrderPlacedDate;
        Test.startTest();
        insert ord;
        Test.stopTest();

        Ops_Order__c opsOrd = [
            SELECT
                Id,
                XometryOpsOrderID__c,
                AllOrdersTotal__c,
                Is_Large_Order__c,
                ParentOpsOrder__c,
                LargeOrderStatus__c
            FROM Ops_Order__c
        ][0];
        System.assertEquals(ord.Xometry_ERP_Id__c, opsOrd.XometryOpsOrderID__c, 'Ops order should have same order id');
        System.assertEquals(
            ord.AllOrdersTOtal__c,
            opsOrd.AllOrdersTotal__c,
            'Ops order total should be the same as order'
        );
        System.assertEquals(
            'DFM-Pending Review',
            opsOrd.LargeOrderStatus__c,
            'Ops Order large order status should be Pending Review'
        );
        System.assertEquals(true, opsOrd.Is_Large_Order__c, 'Ops Order large order should be true');

        Case cRes = [
            SELECT Id, GNOOrder__c, ParentOpsOrder__c, Owner.Name, Status, Opportunity__c, BusinessHoursId
            FROM Case
        ][0];
        System.assertEquals(opsOrd.Id, cRes.GNOOrder__c, 'Case should have Ops Order Related');

        Map<String, BusinessHours> hoursMap = new Map<String, BusinessHours>();
        for (BusinessHours bHours : [SELECT Id, Name FROM BusinessHours]) {
            hoursMap.put(bHours.Name, bHours);
        }

        System.assertEquals(
            hoursMap.get('POD Business Hours - EST').Id,
            cRes.BusinessHoursId,
            'Case should have BusinessHours updated'
        );
    }

    @isTest
    public static void createPendingDFMCaseOnUpdate() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        Date OrderPlacedDate = Date.today();
        String orderId = '06928-15000';
        ord.Xometry_ERP_ID__c = orderId;
        ord.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c - 20;
        ord.Order_ERP_CreatedDate__C = OrderPlacedDate;
        insert ord;

        Job__c testJob = new Job__c(
            Name = 'Test-Job1',
            XometryOpsOrderID__c = orderId,
            Order_IDs_String__c = orderId,
            XometryJobID__c = 'TestJob1',
            RiskFactor__c = 'High',
            AcceptedPartnerID__c = 'P1234'
        );
        insert testJob;

        Ops_Order__c opsOrdPreUpdate = [
            SELECT Id, XometryOpsOrderID__c, AllOrdersTotal__c, Is_Large_Order__c, ParentOpsOrder__c
            FROM Ops_Order__c
        ][0];
        Job__c jobPreUpdate = [SELECT Id, Technical_Review_Status__c FROM Job__c][0];
        System.assertEquals(
            ord.Xometry_ERP_Id__c,
            opsOrdPreUpdate.XometryOpsOrderID__c,
            'Ops order should have same order id'
        );
        System.assertEquals(
            ord.AllOrdersTOtal__c,
            opsOrdPreUpdate.AllOrdersTotal__c,
            'Ops order total should be the same as order'
        );
        System.assertEquals(false, opsOrdPreUpdate.Is_Large_Order__c, 'Ops Order large order should be false');
        List<Case> cResPreUpdate = [
            SELECT Id, GNOOrder__c, ParentOpsOrder__c, Owner.Name, Status, Opportunity__c
            FROM Case
        ];
        System.assertEquals(0, cResPreUpdate.size(), 'No cases should be created');
        System.assertEquals(
            'No Technical Review Required',
            jobPreUpdate.Technical_Review_Status__c,
            'Job should not require review'
        );

        Test.startTest();
        ord.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 40;
        update ord;
        Test.stopTest();

        Ops_Order__c opsOrd = [
            SELECT
                Id,
                XometryOpsOrderID__c,
                AllOrdersTotal__c,
                Is_Large_Order__c,
                ParentOpsOrder__c,
                LargeOrderStatus__c
            FROM Ops_Order__c
        ][0];
        Job__c jobPostUpdate = [SELECT Id, Technical_Review_Status__c FROM Job__c][0];
        System.assertEquals(ord.Xometry_ERP_Id__c, opsOrd.XometryOpsOrderID__c, 'Ops order should have same order id');
        System.assertEquals(
            ord.AllOrdersTOtal__c,
            opsOrd.AllOrdersTotal__c,
            'Ops order total should be the same as order'
        );
        System.assertEquals(
            'DFM-Pending Review',
            opsOrd.LargeOrderStatus__c,
            'Ops Order large order should be Pending Review'
        );
        System.assertEquals(true, opsOrd.Is_Large_Order__c, 'Ops Order large order should be true');

        List<Case> cRes = [
            SELECT Id, GNOOrder__c, ParentOpsOrder__c, Owner.Name, Status, Opportunity__c, Job__c, RecordTypeId
            FROM Case
        ];
        System.assertEquals(2, cRes.size(), 'Incorrect number of cases were created');
        for (Case c : cRes) {
            if (c.RecordTypeID == AppConstants.caseDFMRTypeId) {
                System.assertEquals(opsOrd.Id, c.GNOOrder__c, 'Case should have Ops Order Related');
            }
            if (c.RecordTypeID == AppConstants.caseManagementRTypeId) {
                System.assertEquals(jobPostUpdate.Id, c.Job__c, 'Tech Review case was not created');
                System.assertEquals(
                    'Pending Technical Review',
                    jobPostUpdate.Technical_Review_Status__c,
                    'Tech Review status on job did not update'
                );
            }
        }
    }

    @isTest
    public static void associatePOCase() {
        List<Case> casesWithPOs = new List<Case>();
        Case case1 = new Case();
        case1.PO_Number__c = '1234567';
        case1.PO_Amount__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        case1.Stalled_PO__c = 'READY: PO is ready for processing';
        case1.Category__c = 'PO';
        case1.Type = 'Large Order Approval';
        casesWithPOs.add(case1);
        Case case2 = new Case();
        case2.PO_Number__c = '8901234';
        case2.PO_Amount__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 40;
        case2.Stalled_PO__c = 'READY: PO is ready for processing';
        case2.Category__c = 'PO';
        case2.Type = 'Large Order Approval';
        casesWithPOs.add(case2);
        insert casesWithPOs;

        List<Ops_Order__c> opsOrdersToInsert = new List<Ops_Order__c>();
        Ops_Order__c oo1 = new Ops_Order__c();
        oo1.XometryOpsOrderID__c = 'BBBBB-00001';
        oo1.PONumber__c = case1.PO_Number__c;
        opsOrdersToInsert.add(oo1);
        Ops_Order__c oo2 = new Ops_Order__c();
        oo2.XometryOpsOrderID__c = 'CCCCC-00002';
        oo2.PONumber__c = case2.PO_Number__c;
        opsOrdersToInsert.add(oo2);

        Test.startTest();
        insert opsOrdersToInsert;
        Test.stopTest();

        List<CaseOpsOrder__c> caseOpsRes = [SELECT Id, Name, Ops_Order__c, Case__c FROM CaseOpsOrder__c];

        System.debug(caseOpsRes);
        System.assertEquals(2, caseOpsRes.size(), 'Should have 2 CaseOps created');
        for (CaseOpsOrder__c caseOrder : caseOpsRes) {
            if (caseOrder.Case__c == case1.Id) {
                System.assertEquals(oo1.Id, caseOrder.Ops_Order__c, 'CaseOrder should link to correct ops Order');
                System.assertNotEquals(null, caseOrder.name, 'Name should be populated');
            }
            if (caseOrder.Case__c == case2.Id) {
                System.assertEquals(oo2.Id, caseOrder.Ops_Order__c, 'CaseOrder should link to correct ops Order');
                System.assertNotEquals(null, caseOrder.name, 'Name should be populated');
            }
        }
    }

    @isTest
    public static void associatePOCaseUpdate() {
        List<Case> casesWithPOs = new List<Case>();
        Case case1 = new Case();
        case1.PO_Number__c = '1234567';
        case1.PO_Amount__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        case1.Stalled_PO__c = 'READY: PO is ready for processing';
        case1.Category__c = 'PO';
        case1.Type = 'Large Order Approval';
        casesWithPOs.add(case1);
        Case case2 = new Case();
        case2.PO_Number__c = '8901234';
        case2.PO_Amount__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 40;
        case2.Stalled_PO__c = 'READY: PO is ready for processing';
        case2.Category__c = 'PO';
        case2.Type = 'Large Order Approval';
        casesWithPOs.add(case2);
        insert casesWithPOs;

        List<Ops_Order__c> opsOrdersToInsert = new List<Ops_Order__c>();
        Ops_Order__c oo1 = new Ops_Order__c();
        oo1.XometryOpsOrderID__c = 'BBBBB-00001';

        opsOrdersToInsert.add(oo1);
        Ops_Order__c oo2 = new Ops_Order__c();
        oo2.XometryOpsOrderID__c = 'CCCCC-00002';
        opsOrdersToInsert.add(oo2);
        insert opsOrdersToInsert;

        Case case3 = new Case();
        case3.PO_Number__c = '8901234';
        case3.PO_Amount__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 40;
        case3.Stalled_PO__c = 'READY: PO is ready for processing';
        case3.Category__c = 'PO';
        case3.Type = 'Large Order Review';
        insert case3;
        CaseOpsOrder__c cOpsOrderJunc = new CaseOpsOrder__c(Case__c = case3.Id, Ops_Order__c = oo2.Id);
        insert cOpsOrderJunc;

        Test.startTest();
        oo1.PONumber__c = case1.PO_Number__c;
        oo2.PONumber__c = case2.PO_Number__c;
        update new List<Ops_Order__c>{ oo1, oo2 };
        Test.stopTest();

        List<CaseOpsOrder__c> caseOpsRes = [SELECT Id, Name, Ops_Order__c, Case__c FROM CaseOpsOrder__c];

        System.assertEquals(3, caseOpsRes.size(), 'Should have 3 CaseOps created');
        for (CaseOpsOrder__c caseOrder : caseOpsRes) {
            if (caseOrder.Case__c == case1.Id) {
                System.assertEquals(oo1.Id, caseOrder.Ops_Order__c, 'CaseOrder should link to correct ops Order');
                System.assertNotEquals(null, caseOrder.name, 'Name should be populated');
            }
            if (caseOrder.Case__c == case2.Id) {
                System.assertEquals(oo2.Id, caseOrder.Ops_Order__c, 'CaseOrder should link to correct ops Order');
                System.assertNotEquals(null, caseOrder.name, 'Name should be populated');
            }
        }
    }

    @isTest(seeAllData=false)
    static void resetRollUpsTest() {
        ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('DFM_Case')
            .getRecordTypeId();

        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        Date OrderPlacedDate = Date.today();

        Supplier__c mySupplier = testDataFactory.createSupplier(true);
        Ops_Order__c parentOpsOrder = new Ops_Order__c();
        parentOpsOrder.Cases_In_Progress__c = 99;
        parentOpsOrder.Jobs_In_Progress__c = 99;
        parentOpsOrder.Cases_Completed__c = 99;
        parentOpsOrder.Jobs_Completed__c = 99;
        parentOpsOrder.AllOrdersTotal__c = largeOrderAmount + 1;
        parentOpsOrder.OrderTotal__c = largeOrderAmount + 1;
        parentOpsOrder.XometryOpsOrderID__c = 'AAAA1-12301';
        parentOpsOrder.Order_Date__c = OrderPlacedDate;
        insert parentOpsOrder;

        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.ParentOpsOrder__c = parentOpsOrder.Id;
        opsOrder.Cases_In_Progress__c = 99;
        opsOrder.Jobs_In_Progress__c = 99;
        opsOrder.Cases_Completed__c = 99;
        opsOrder.Jobs_Completed__c = 99;
        opsOrder.AllOrdersTotal__c = largeOrderAmount + 1;
        opsOrder.OrderTotal__c = largeOrderAmount + 1;
        opsOrder.XometryOpsOrderID__c = 'BBBBB-15100';
        opsOrder.Order_Date__c = OrderPlacedDate;
        insert opsOrder;

        Test.startTest();

        Job__c testJob = new Job__c(
            Name = 'Test-Job',
            XometryJobID__c = 'Test-Job',
            RiskFactor__c = 'High',
            XometryOpsOrderID__c = 'BBBBB-15100',
            Order_IDs_String__c = 'BBBBB-15100;',
            AcceptedPartnerID__c = mySupplier.PartnerID__c
        );
        insert testJob;

        Test.stopTest();

        Map<Id, Ops_Order__c> opsOrderResult = new Map<Id, Ops_Order__c>(
            [SELECT Cases_In_Progress__c, Jobs_In_Progress__c, Cases_Completed__c, Jobs_Completed__c FROM Ops_Order__c]
        );

        System.assertEquals(2, opsOrderResult.get(opsOrder.Id).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(1, opsOrderResult.get(opsOrder.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder.Id).Cases_Completed__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder.Id).Jobs_Completed__c, 'Rollup should be updated');

        System.assertEquals(3, opsOrderResult.get(parentOpsOrder.Id).Cases_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(1, opsOrderResult.get(parentOpsOrder.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(parentOpsOrder.Id).Cases_Completed__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(parentOpsOrder.Id).Jobs_Completed__c, 'Rollup should be updated');
    }

    @isTest
    static void testlargeOrderMaker() {
        //This test confirmed that the TestDataFactory is creating some large orders.
        Map<String, Ops_Order__C> testOpsOrders = TestDataFactory.createLargeOrderTestData(
            2,
            3,
            0, //cheat for Soql Query limits for now
            new List<Order_ERP__c>()
        );
        System.debug('The number of ops orders created are ' + testOpsOrders.size());
        for (Ops_Order__C ord : testOpsOrders.values()) {
            System.assertNotEquals(null, ord.ID, 'The Ops Order was not inserted correctly');
        }
        List<Job__c> createdJobList = [SELECT id, OrderID__c, XometryOpsOrderID__c, XometryJobID__c FROM Job__C];
        System.debug('The number of jobs created are ' + createdJobList.size());
        for (Job__C job : createdJobList) {
            System.assertNotEquals(null, job.OrderID__c);
        }
    }

    @isTest
    public static void worstOfWorst() {
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY StatusRank__c ASC
        ];

        Date OrderPlacedDate = Date.today();

        Ops_Order__c parentOpsOrder = new Ops_Order__c();
        parentOpsOrder.XometryOpsOrderID__c = 'BBBBB-00000';
        parentOpsOrder.LargeOrderStatus__c = largeOrderRankMtd[3].Label;
        parentOpsOrder.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        parentOpsOrder.Order_Date__c = OrderPlacedDate;
        insert parentOpsOrder;

        List<Ops_Order__c> opsOrdersToInsert = new List<Ops_Order__c>();
        Ops_Order__c oo1 = new Ops_Order__c();
        oo1.XometryOpsOrderID__c = 'BBBBB-00001';
        oo1.LargeOrderStatus__c = largeOrderRankMtd[1].Label;
        oo1.ParentOpsOrder__c = parentOpsOrder.Id;
        oo1.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        opsOrdersToInsert.add(oo1);
        Ops_Order__c oo2 = new Ops_Order__c();
        oo2.XometryOpsOrderID__c = 'BBBBB-00002';
        oo2.LargeOrderStatus__c = largeOrderRankMtd[0].Label;
        oo2.ParentOpsOrder__c = parentOpsOrder.Id;
        oo2.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        opsOrdersToInsert.add(oo2);
        Ops_Order__c oo3 = new Ops_Order__c();
        oo3.XometryOpsOrderID__c = 'BBBBB-00003';
        oo3.LargeOrderStatus__c = largeOrderRankMtd[1].Label;
        oo3.ParentOpsOrder__c = parentOpsOrder.Id;
        oo3.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        opsOrdersToInsert.add(oo3);

        Test.startTest();
        insert opsOrdersToInsert;
        Test.stopTest();

        List<Ops_Order__c> parentOrderRes = [
            SELECT Id, LargeOrderStatus__c
            FROM Ops_Order__c
            WHERE ID = :parentOpsOrder.Id
        ];

        System.assertEquals(
            largeOrderRankMtd[0].Label,
            parentOrderRes[0].LargeOrderStatus__c,
            'The parent should be the worst of worst'
        );
    }

    @isTest
    public static void worstOfWorstUpdate() {
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY StatusRank__c ASC
        ];
        Date OrderPlacedDate = Date.today();

        Ops_Order__c parentOpsOrder = new Ops_Order__c();
        parentOpsOrder.XometryOpsOrderID__c = 'BBBBB-00000';
        //parentOpsOrder.LargeOrderStatus__c = largeOrderRankMtd[3].Label;
        parentOpsOrder.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        parentOpsOrder.Order_Date__c = OrderPlacedDate;
        insert parentOpsOrder;

        List<Ops_Order__c> opsOrdersToInsert = new List<Ops_Order__c>();
        Ops_Order__c oo1 = new Ops_Order__c();
        oo1.XometryOpsOrderID__c = 'BBBBB-00001';
        oo1.LargeOrderStatus__c = largeOrderRankMtd[0].Label;
        oo1.ParentOpsOrder__c = parentOpsOrder.Id;
        oo1.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        oo1.Order_Date__c = OrderPlacedDate;
        opsOrdersToInsert.add(oo1);
        Ops_Order__c oo2 = new Ops_Order__c();
        oo2.XometryOpsOrderID__c = 'BBBBB-00002';
        oo2.LargeOrderStatus__c = largeOrderRankMtd[1].Label;
        oo2.ParentOpsOrder__c = parentOpsOrder.Id;
        oo2.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        oo2.Order_Date__c = OrderPlacedDate;
        opsOrdersToInsert.add(oo2);
        insert opsOrdersToInsert;

        Ops_Order__c parentBeforeTest = [
            SELECT Id, LargeOrderStatus__c
            FROM Ops_Order__c
            WHERE ID = :parentOpsOrder.Id
        ][0];
        System.assertEquals(
            largeOrderRankMtd[0].Label,
            parentBeforeTest.LargeOrderStatus__c,
            'Parent Ops Order has incorrect status'
        );

        ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('DFM_Case')
            .getRecordTypeId();

        List<Case> casesToInsert = new List<Case>();
        Case case1 = new Case();
        case1.Status = 'Solved';
        case1.RecordTypeId = caseDFMRTypeId;
        case1.GNOOrder__c = parentOpsOrder.Id;
        casesToInsert.add(case1);
        Case case2 = new Case();
        // status should match to update order
        case2.Status = 'New';
        case2.RecordTypeId = caseDFMRTypeId;
        // Left parent ops order lookup blank
        case2.GNOOrder__c = oo1.Id;
        casesToInsert.add(case2);
        Case case3 = new Case();
        case3.Status = 'New';
        case3.RecordTypeId = caseDFMRTypeId;
        case3.ParentOpsOrder__c = parentOpsOrder.Id;
        case3.GNOOrder__c = oo2.Id;
        casesToInsert.add(case3);
        insert casesToInsert;

        Test.startTest();
        Set<ID> opsIDtoUpdateSet = new Set<ID>{ parentOpsOrder.Id, oo1.Id };
        //Changing the status does not trigger an Order Change flipping this to update all Status to solved for the oo1
        List<Case> casesToUpdateList = [
            SELECT ID, Status, GnoOrder__c
            FROM Case
            WHERE GnoOrder__c IN :opsIDtoUpdateSet
        ];
        //oo1.LargeOrderStatus__c = largeOrderRankMtd[1].Label;
        for (Case c : casesToUpdateList) {
            c.status = 'Solved';
        }
        update casesToUpdateList;
        Test.stopTest();

        List<Ops_Order__c> parentOrderRes = [
            SELECT Id, LargeOrderStatus__c, Is_Large_Order__c
            FROM Ops_Order__c
            WHERE ID = :parentOpsOrder.Id
        ];

        System.assertEquals(
            largeOrderRankMtd[0].Label,
            parentOrderRes[0].LargeOrderStatus__c,
            'The parent should be the worst of worst'
        );
    }

    @isTest
    public static void worstOfWorstParent() {
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY StatusRank__c ASC
        ];
        Date orderCreatedDate = Date.today();
        Datetime orderCreatedTime = Datetime.now();
        Ops_Order__c parentOpsOrder = new Ops_Order__c();
        parentOpsOrder.XometryOpsOrderID__c = 'BBBBB-00000';
        parentOpsOrder.LargeOrderStatus__c = largeOrderRankMtd[0].Label;
        parentOpsOrder.Order_Date__c = orderCreatedDate;
        parentOpsOrder.Order_DateTime__c = orderCreatedTime;

        insert parentOpsOrder;

        List<Ops_Order__c> opsOrdersToInsert = new List<Ops_Order__c>();
        Ops_Order__c oo1 = new Ops_Order__c();
        oo1.XometryOpsOrderID__c = 'BBBBB-00001';
        oo1.ParentOpsOrder__c = parentOpsOrder.Id;
        oo1.Order_Date__c = orderCreatedDate;
        oo1.Order_DateTime__c = orderCreatedTime;
        opsOrdersToInsert.add(oo1);
        Ops_Order__c oo2 = new Ops_Order__c();
        oo2.XometryOpsOrderID__c = 'BBBBB-00002';
        oo2.ParentOpsOrder__c = parentOpsOrder.Id;
        oo2.Order_Date__c = orderCreatedDate;
        oo2.Order_DateTime__c = orderCreatedTime;
        opsOrdersToInsert.add(oo2);
        Ops_Order__c oo3 = new Ops_Order__c();
        oo3.XometryOpsOrderID__c = 'BBBBB-00003';
        oo3.ParentOpsOrder__c = parentOpsOrder.Id;
        oo3.Order_Date__c = orderCreatedDate;
        oo3.Order_DateTime__c = orderCreatedTime;
        opsOrdersToInsert.add(oo3);
        insert opsOrdersToInsert;

        Test.startTest();

        List<Ops_Order__c> updateLrgOrdStatus = new List<Ops_Order__c>();
        oo1.LargeOrderStatus__c = largeOrderRankMtd[1].Label;
        updateLrgOrdStatus.add(oo1);
        oo2.LargeOrderStatus__c = largeOrderRankMtd[0].Label;
        updateLrgOrdStatus.add(oo2);
        oo3.LargeOrderStatus__c = largeOrderRankMtd[1].Label;
        updateLrgOrdStatus.add(oo3);
        update updateLrgOrdStatus;
        Test.stopTest();

        List<Ops_Order__c> parentOrderRes = [
            SELECT Id, LargeOrderStatus__c
            FROM Ops_Order__c
            WHERE ID = :parentOpsOrder.Id
        ];

        System.assertEquals(
            largeOrderRankMtd[0].Label,
            parentOrderRes[0].LargeOrderStatus__c,
            'The parent should be the worst of worst'
        );
    }

    @isTest
    static void worstOfWorstNoStatus() {
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY StatusRank__c ASC
        ];
        Date orderCreatedDate = Date.today();
        Ops_Order__c parentOpsOrder = new Ops_Order__c();
        parentOpsOrder.XometryOpsOrderID__c = 'BBBBB-00000';
        parentOpsOrder.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        parentOpsOrder.Order_Date__c = orderCreatedDate;
        Test.startTest();
        insert parentOpsOrder;
        Test.stopTest();

        Ops_Order__c pOpsOrderRes = [SELECT Id, LargeOrderStatus__c FROM Ops_Order__c WHERE Id = :parentOpsOrder.Id][0];
        System.debug('Testing LargeOrderStatus : ' + pOpsOrderRes.LargeOrderStatus__c);
        System.assertEquals(largeOrderRankMtd[0].Label, pOpsOrderRes.LargeOrderStatus__c, 'Should be lowest');
    }

    @isTest
    static void testParentNoJobChildopenJobs() {
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY Label ASC
        ];
        final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('DFM_Case')
            .getRecordTypeId();

        final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('CaseMgmt')
            .getRecordTypeId();
        Set<Id> recordTypeSet = new Set<Id>{ caseManagementRTypeId, caseDFMRTypeId };
        Map<Integer, String> largeOrderStatusRankMap = new Map<Integer, String>();
        Map<String, Decimal> largeOrderRankMap = new Map<String, Decimal>();
        Decimal topRank = largeOrderRankMtd[largeOrderRankMtd.size() - 1].StatusRank__c;
        for (Large_Order_Status_Rank__mdt lor : largeOrderRankMtd) {
            largeOrderRankMap.put(lor.Label, lor.StatusRank__c);
            largeOrderStatusRankMap.put(lor.StatusRank__c.intValue(), lor.Label);
        }
        //Have child Jobs status should be at 3
        Map<String, Ops_Order__c> opsOrderMap = TestDataFactory.createLargeOrderTestData(
            1,
            2,
            0,
            new List<Order_ERP__c>()
        );
        Set<ID> parentIdSet = new Set<ID>();
        Set<ID> childIdSet = new Set<ID>();
        Set<ID> allOpsOrderIdSet = new Set<ID>();
        for (Ops_Order__c ord : opsOrderMap.values()) {
            allOpsOrderIdSet.add(ord.ID);
            if (ord.ParentOpsOrder__r.XometryOpsOrderID__c == null) {
                parentIdSet.add(ord.ID);
            } else {
                childIdSet.add(ord.ID);
            }
        }
        test.startTest();
        List<Job__c> jobsInserted = TestDataFactory.createJobsForLargeOrders(true, 2, opsOrderMap.values());
        System.debug('Here is the  jobInsertedSize' + jobsInserted.size());
        for (Job__C job : jobsInserted) {
            System.debug('Job :' + job.ID + '   Risk: ' + job.RiskFactor__c);
        }

        //Update all cases
        list<Case> caseList = [
            SELECT
                GNOOrder__c,
                RecordTypeId,
                Technical_Review_Status__c,
                Status,
                Type,
                isClosed,
                ParentOpsOrder__c,
                GNOOrder__r.ParentOpsOrder__c
            FROM Case
            WHERE
                (GNOOrder__c IN :allOpsOrderIdSet
                OR GNOOrder__r.ParentOpsOrder__c IN :allOpsOrderIdSet)
                AND RecordTypeId IN :recordTypeSet
        ];
        for (Case c : caseList) {
            System.debug('Here is the case');
            System.debug(c);
            if (c.Type == 'Large Order Review') {
                c.Status = 'Solved';
            }
            // if(Type == ''){
            //     c.Technical_Review_Status__c = 'Large Order Review Complete';
            //     c.Status = 'Solved';
            // }
        }
        update caseList;
        test.stopTest();

        list<Case> caseListAfter = [
            SELECT
                GNOOrder__c,
                RecordTypeId,
                Technical_Review_Status__c,
                Status,
                Type,
                isClosed,
                ParentOpsOrder__c,
                GNOOrder__r.ParentOpsOrder__c
            FROM Case
            WHERE
                (GNOOrder__c IN :allOpsOrderIdSet
                OR GNOOrder__r.ParentOpsOrder__c IN :allOpsOrderIdSet)
                AND RecordTypeId IN :recordTypeSet
        ];

        for (Case c : caseListAfter) {
            System.debug('Here is the caseAfter : ' + c);
        }
        //Check that all Large Order Statuses are at 3
        List<Ops_Order__c> resultList = [
            SELECT Id, LargeOrderStatus__c
            FROM Ops_Order__C
            WHERE id IN :allOpsOrderIdSet
        ];
        for (Ops_Order__c ord : resultList) {
            System.assertEquals(
                largeOrderStatusRankMap.get(3),
                ord.LargeOrderStatus__c,
                'The Large Order Status was not correct'
            );
        }
    }
    @isTest
    static void testParentNoJobChildCompleteJobs() {
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY Label ASC
        ];
        final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('DFM_Case')
            .getRecordTypeId();

        final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('CaseMgmt')
            .getRecordTypeId();
        Set<Id> recordTypeSet = new Set<Id>{ caseManagementRTypeId, caseDFMRTypeId };
        Map<Integer, String> largeOrderStatusRankMap = new Map<Integer, String>();
        Map<String, Decimal> largeOrderRankMap = new Map<String, Decimal>();
        Decimal topRank = largeOrderRankMtd[largeOrderRankMtd.size() - 1].StatusRank__c;
        for (Large_Order_Status_Rank__mdt lor : largeOrderRankMtd) {
            largeOrderRankMap.put(lor.Label, lor.StatusRank__c);
            largeOrderStatusRankMap.put(lor.StatusRank__c.intValue(), lor.Label);
        }
        //Have child Jobs status should be at 3
        Map<String, Ops_Order__c> opsOrderMap = TestDataFactory.createLargeOrderTestData(
            1,
            2,
            0,
            new List<Order_ERP__c>()
        );
        Set<ID> parentIdSet = new Set<ID>();
        Set<ID> childIdSet = new Set<ID>();
        Set<ID> allOpsOrderIdSet = new Set<ID>();
        for (Ops_Order__c ord : opsOrderMap.values()) {
            allOpsOrderIdSet.add(ord.ID);
            if (ord.ParentOpsOrder__r.XometryOpsOrderID__c == null) {
                parentIdSet.add(ord.ID);
            } else {
                childIdSet.add(ord.ID);
            }
        }
        test.startTest();
        List<Job__c> jobsInserted = TestDataFactory.createJobsForLargeOrders(true, 2, opsOrderMap.values());
        System.debug('Here is the  jobInsertedSize' + jobsInserted.size());
        for (Job__C job : jobsInserted) {
            System.debug('Job :' + job.ID + '   Risk: ' + job.RiskFactor__c);
        }

        //Update all cases
        list<Case> caseList = [
            SELECT
                GNOOrder__c,
                RecordTypeId,
                Technical_Review_Status__c,
                Status,
                Type,
                isClosed,
                ParentOpsOrder__c,
                GNOOrder__r.ParentOpsOrder__c
            FROM Case
            WHERE
                (GNOOrder__c IN :allOpsOrderIdSet
                OR GNOOrder__r.ParentOpsOrder__c IN :allOpsOrderIdSet)
                AND RecordTypeId IN :recordTypeSet
        ];
        for (Case c : caseList) {
            System.debug('Here is the case');
            System.debug(c);
            if (c.Type == 'Large Order Review') {
                c.Status = 'Solved';
            }
            if (c.Type == 'Technical Review') {
                c.Technical_Review_Status__c = 'Large Order Review Complete';
                c.Status = 'Solved';
            }
        }
        update caseList;
        test.stopTest();

        list<Case> caseListAfter = [
            SELECT
                GNOOrder__c,
                RecordTypeId,
                Technical_Review_Status__c,
                Status,
                Type,
                isClosed,
                ParentOpsOrder__c,
                GNOOrder__r.ParentOpsOrder__c
            FROM Case
            WHERE
                (GNOOrder__c IN :allOpsOrderIdSet
                OR GNOOrder__r.ParentOpsOrder__c IN :allOpsOrderIdSet)
                AND RecordTypeId IN :recordTypeSet
        ];

        for (Case c : caseListAfter) {
            System.debug('Here is the caseAfter : ' + c);
        }
        //Check that all Large Order Statuses are at 4
        List<Ops_Order__c> resultList = [
            SELECT Id, LargeOrderStatus__c
            FROM Ops_Order__C
            WHERE id IN :allOpsOrderIdSet
        ];
        for (Ops_Order__c ord : resultList) {
            System.assertEquals(
                largeOrderStatusRankMap.get(4),
                ord.LargeOrderStatus__c,
                'The Large Order Status was not correct'
            );
        }
    }

    @isTest
    static void createOrderWithChildrenDemoto3() {
        //This test inserts a parent Order
        //Child Order assigns a part to each Order
        // Inserts a Job on the parent
        // Inserts a Job the Child
        // Completes all cases for the Child
        // Child should go to 4
        // Parent should stay at 1

        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY Label ASC
        ];
        final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('DFM_Case')
            .getRecordTypeId();

        final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('CaseMgmt')
            .getRecordTypeId();
        Set<Id> recordTypeSet = new Set<Id>{ caseManagementRTypeId, caseDFMRTypeId };
        Map<Integer, String> largeOrderStatusRankMap = new Map<Integer, String>();
        Map<String, Decimal> largeOrderRankMap = new Map<String, Decimal>();
        Decimal topRank = largeOrderRankMtd[largeOrderRankMtd.size() - 1].StatusRank__c;
        for (Large_Order_Status_Rank__mdt lor : largeOrderRankMtd) {
            largeOrderRankMap.put(lor.Label, lor.StatusRank__c);
            largeOrderStatusRankMap.put(lor.StatusRank__c.intValue(), lor.Label);
        }
        Map<String, List<sObject>> testDataMap = TestDataFactory.largeOrderDemoDatawithChild();

        List<Order_Erp__c> ordersToInsert = testDataMap.get('order');
        insert ordersToInsert;
        String childXomOrderID = ordersToInsert[1].Xometry_ERP_ID__c;
        String parentXomOrderID = ordersToInsert[0].Xometry_ERP_ID__c;
        List<Ordered_Part__c> orderedPartToInsert = testDataMap.get('orderedPart');
        insert orderedPartToInsert;
        List<Job__c> jobsList = testDataMap.get('job');
        test.startTest();
        insert jobsList;
        list<Case> caseList = [
            SELECT
                GNOOrder__c,
                RecordTypeId,
                Technical_Review_Status__c,
                Status,
                Type,
                isClosed,
                ParentOpsOrder__c,
                GNOOrder__r.ParentOpsOrder__c
            FROM Case
            WHERE RecordTypeId IN :recordTypeSet AND GNOOrder__r.XometryOpsOrderID__c = :childXomOrderID
        ];
        for (Case c : caseList) {
            System.debug('Here is the case');
            System.debug(c);
            if (c.Type == 'Large Order Review') {
                c.Status = 'Solved';
            }
        }
        update caseList;
        test.stopTest();
        Set<String> xomOrderSet = new Set<String>();
        for (Order_ERP__C ord : ordersToInsert) {
            xomOrderSet.add(ord.Xometry_ERP_ID__c);
        }

        //Check that all Large Order Statuses are at 4
        List<Ops_Order__c> resultList = [
            SELECT Id, LargeOrderStatus__c, XometryOpsOrderID__c
            FROM Ops_Order__C
            WHERE XometryOpsOrderID__c IN :xomOrderSet
        ];
        System.debug('Size of the resultlis is ' + resultList.size());
        System.assertEquals(2, resultList.size(), 'we Should have 2 ops orders');
        for (Ops_Order__c ord : resultList) {
            if (ord.XometryOpsOrderID__c == childXomOrderID) {
                System.assertEquals(
                    largeOrderStatusRankMap.get(3),
                    ord.LargeOrderStatus__c,
                    'The Large Order Status was not correct'
                );
            }
            if (ord.XometryOpsOrderID__c == parentXomOrderID) {
                System.assertEquals(
                    largeOrderStatusRankMap.get(1),
                    ord.LargeOrderStatus__c,
                    'The Large Order Status was not correct'
                );
            }
        }
    }

    //This test inserts a parent Order
    //Child Order assigns a part to each Order
    // Inserts a Job on the parent
    // Inserts a Job the Child
    // Completes all cases
    @isTest
    static void createOrderWithChildrenDemoto4() {
        List<Large_Order_Status_Rank__mdt> largeOrderRankMtd = [
            SELECT Label, StatusRank__c
            FROM Large_Order_Status_Rank__mdt
            ORDER BY Label ASC
        ];
        final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('DFM_Case')
            .getRecordTypeId();

        final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
            .get('CaseMgmt')
            .getRecordTypeId();
        Set<Id> recordTypeSet = new Set<Id>{ caseManagementRTypeId, caseDFMRTypeId };
        Map<Integer, String> largeOrderStatusRankMap = new Map<Integer, String>();
        Map<String, Decimal> largeOrderRankMap = new Map<String, Decimal>();
        Decimal topRank = largeOrderRankMtd[largeOrderRankMtd.size() - 1].StatusRank__c;
        for (Large_Order_Status_Rank__mdt lor : largeOrderRankMtd) {
            largeOrderRankMap.put(lor.Label, lor.StatusRank__c);
            largeOrderStatusRankMap.put(lor.StatusRank__c.intValue(), lor.Label);
        }
        Map<String, List<sObject>> testDataMap = TestDataFactory.largeOrderDemoDatawithChild();

        List<Order_Erp__c> ordersToInsert = testDataMap.get('order');
        insert ordersToInsert;
        List<Ordered_Part__c> orderedPartToInsert = testDataMap.get('orderedPart');
        insert orderedPartToInsert;
        List<Job__c> jobsList = testDataMap.get('job');
        test.startTest();
        insert jobsList;
        list<Case> caseList = [
            SELECT
                GNOOrder__c,
                RecordTypeId,
                Technical_Review_Status__c,
                Status,
                Type,
                isClosed,
                ParentOpsOrder__c,
                GNOOrder__r.ParentOpsOrder__c
            FROM Case
            WHERE RecordTypeId IN :recordTypeSet
        ];
        for (Case c : caseList) {
            System.debug('Here is the case');
            System.debug(c);
            if (c.Type == 'Large Order Review') {
                c.Status = 'Solved';
            }
            if (c.Type == 'Technical Review') {
                c.Technical_Review_Status__c = 'Large Order Review Complete';
                c.Status = 'Solved';
            }
        }
        update caseList;
        test.stopTest();
        Set<String> xomOrderSet = new Set<String>();
        for (Order_ERP__C ord : ordersToInsert) {
            xomOrderSet.add(ord.Xometry_ERP_ID__c);
        }

        //Check that all Large Order Statuses are at 4
        List<Ops_Order__c> resultList = [
            SELECT Id, LargeOrderStatus__c
            FROM Ops_Order__C
            WHERE XometryOpsOrderID__c IN :xomOrderSet
        ];
        System.debug('Size of the resultlis is ' + resultList.size());
        for (Ops_Order__c ord : resultList) {
            System.assertEquals(
                largeOrderStatusRankMap.get(4),
                ord.LargeOrderStatus__c,
                'The Large Order Status was not correct'
            );
        }
    }
    @isTest
    public static void cancelledLargeOrder_Update() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        Date OrderPlacedDate = Date.today();
        ord.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        ord.Order_ERP_CreatedDate__c = OrderPlacedDate;

        insert ord;

        Ops_Order__c opsOrd = [
            SELECT
                Id,
                XometryOpsOrderID__c,
                AllOrdersTotal__c,
                Is_Large_Order__c,
                ParentOpsOrder__c,
                LargeOrderStatus__c
            FROM Ops_Order__c
        ][0];
        System.assertEquals(ord.Xometry_ERP_Id__c, opsOrd.XometryOpsOrderID__c, 'Ops order should have same order id');
        System.assertEquals(
            ord.AllOrdersTOtal__c,
            opsOrd.AllOrdersTotal__c,
            'Ops order total should be the same as order'
        );
        System.assertEquals(
            'DFM-Pending Review',
            opsOrd.LargeOrderStatus__c,
            'Ops Order large order status should be Pending Review'
        );
        System.assertEquals(true, opsOrd.Is_Large_Order__c, 'Ops Order large order should be true');

        Case cRes = [SELECT Id, GNOOrder__c, ParentOpsOrder__c, Owner.Name, Status, Opportunity__c FROM Case][0];
        System.assertEquals(opsOrd.Id, cRes.GNOOrder__c, 'Case should have Ops Order Related');

        Test.startTest();
        ord.ERP_Status__c = 'Order Cancelled';
        update ord;
        Test.stopTest();

        Ops_Order__c opsOrdAfter = [
            SELECT
                Id,
                XometryOpsOrderID__c,
                AllOrdersTotal__c,
                Is_Large_Order__c,
                ParentOpsOrder__c,
                LargeOrderStatus__c,
                ERPStatus__c
            FROM Ops_Order__c
        ][0];
        System.debug(opsOrdAfter);
        System.assertEquals(ord.ERP_Status__c, opsOrdAfter.ERPStatus__c, 'Status should be cancelled');
        System.assertEquals(
            'Large Order Review Process Complete',
            opsOrdAfter.LargeOrderStatus__c,
            'Status should be complete'
        );
    }

    @isTest
    public static void cancelledLargeOrder_CaseUpdate() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        Date OrderPlacedDate = Date.today();
        ord.AllOrdersTotal__c =
            [SELECT Number_Ref_Value__c FROM Admin_Ref_Variable__mdt WHERE DeveloperName = 'LargeOrderAmount'][0]
            .Number_Ref_Value__c + 20;
        ord.Order_ERP_CreatedDate__c = OrderPlacedDate;
        ord.ERP_Status__c = 'Order Cancelled';
        insert ord;

        Test.startTest();
        Case dfmCase = [SELECT Id, Status, IsClosed FROM Case][0];
        dfmCase.Status = 'Solved';
        update dfmCase;
        Test.stopTest();

        List<Case> cResList = [SELECT Id, Status, IsClosed FROM Case];
        System.debug(cResList);

        Ops_Order__c opsOrdAfter = [
            SELECT
                Id,
                XometryOpsOrderID__c,
                AllOrdersTotal__c,
                Is_Large_Order__c,
                ParentOpsOrder__c,
                LargeOrderStatus__c,
                ERPStatus__c
            FROM Ops_Order__c
        ][0];
        System.debug(opsOrdAfter);
        System.assertEquals(
            'Large Order Review Process Complete',
            opsOrdAfter.LargeOrderStatus__c,
            'Status should be complete'
        );
    }

    @isTest
    static void handleComplexOrders() {
        //The purpose of this test is to mimic a complex order where the order tree has more then 2 layers.
        // We want to avoid  a dereference null error.
        // Create an Order(Top Layer) with a child who then has 2 children. At least one part from each order on the bottom layer should share a job.
        // Close a tech review case on one of the bottom layer and not throw errors.
        //
        Date orderCreatedDate = Date.today();
        Datetime orderCreatedTime = Datetime.now();
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        List<Ops_Order__c> smallOrderList = new List<Ops_Order__c>();
        Map<String, Ops_Order__c> allOpsOrdersMap = TestDatafactory.createLargeOpsOrderTestData(
            1,
            1,
            1,
            smallOrderList
        );
        ID topOpsOrderID = allOpsOrdersMap.get('AAAA1-12300').ID;
        String MiddleParent = 'AAAA1-0AB00';
        Ops_Order__c midOpsOrder = allOpsOrdersMap.get(MiddleParent);
        midOpsOrder.ParentOpsOrder__c = topOpsOrderID;
        update midOpsOrder;
        //Link the middle to the parent
        ID midOpsOrderID = allOpsOrdersMap.get(MiddleParent).ID;
        Integer num1BottomChildOrders = 2;
        Map<String, String> bottomeTierMap = new Map<String, String>();
        test.startTest();
        List<Ops_Order__C> ordersToInsertList = new List<Ops_Order__C>();
        for (integer k = 0; k < num1BottomChildOrders; k++) {
            Ops_Order__c tier3OpsOrder = new Ops_Order__c();
            if (k < 10) {
                tier3OpsOrder.XometryOpsOrderID__c = 'AAAA1-' + String.valueof(0) + 'AC0' + String.valueOf(k);
            }
            tier3OpsOrder.ParentOpsOrderID__c = MiddleParent;
            tier3OpsOrder.ParentOpsOrder__c = midOpsOrderID;
            tier3OpsOrder.Order_Date__c = orderCreatedDate;
            tier3OpsOrder.Order_DateTime__c = orderCreatedTime;
            tier3OpsOrder.OrderTotal__c = largeOrderAmount + 1;
            tier3OpsOrder.AllOrdersTotal__c = largeOrderAmount * 2;
            ordersToInsertList.add(tier3OpsOrder);
            bottomeTierMap.put(tier3OpsOrder.XometryOpsOrderID__c, tier3OpsOrder.ParentOpsOrderID__c);
        }
        insert ordersToInsertList;
        SET<ID> largeOrderUpdateIDSet = new Set<ID>();
        largeOrderUpdateIDSet.add(ordersToInsertList[0].ID);
        // Call the Large Order Helper with only the bottom layer
        largeOrderHelper.updateLargeOrderSummaryRT(largeOrderUpdateIDSet);
        test.stopTest();
        Ops_Order__c bottomTierOpsOrder = [
            SELECT ID, XometryOpsOrderID__c, ParentOpsOrderID__c, ParentOpsOrder__c, ParentOpsOrder__r.ParentOpsOrder__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = 'AAAA1-0AC00'
        ];
        System.assertNotEquals(null, bottomTierOpsOrder.ParentOpsOrder__c, 'The bottom order did not get a parent');
        Ops_Order__c middleTierOpsOrder = [
            SELECT ID, XometryOpsOrderID__c, ParentOpsOrderID__c, ParentOpsOrder__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = 'AAAA1-0AB00'
        ];
        System.assertNotEquals(null, middleTierOpsOrder.ParentOpsOrder__c, 'The bottom order did not get a parent');
    }

    @isTest(seeAllData=false)
    public static void OpsOrderHandler_setOverdueFlagTest() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.XometryOpsOrderID__c = 'BBBBB-34567';
        opsOrder.OrderDueDate__c = System.today();

        Test.startTest();
        insert opsOrder;
        Test.stopTest();

        Ops_Order__c opsOrderTest = [SELECT Id, Order_OverDue_Flag__c FROM Ops_Order__c];

        System.assertNotEquals(
            null,
            opsOrderTest.Order_OverDue_Flag__c,
            'Order should be updated with overdue countdown'
        );
    }

    @isTest
    public static void stampOpsOrder_createdFromOrderERP() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(1, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        myTestAccount.Ops_Top_20_Customer__c = true;
        myTestAccount.Ops_Top_Quality_Customer__c = false;
        myTestAccount.Ops_CustomerServiceLevel__c = 'Gold';
        update myTestAccount;

        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;

        Test.startTest();
        insert ord;
        Test.stopTest();

        Ops_Order__c opsOrderResult = [
            SELECT
                Id,
                XometryOpsOrderID__c,
                Ops_Top20Customer__c,
                Ops_TopQualityCustomer__c,
                Ops_AccountCustomerServiceLevel__c
            FROM Ops_Order__c
            LIMIT 1
        ];
        System.assertEquals(true, opsOrderResult.Ops_Top20Customer__c, 'Top 20 Customer flag was not set correctly');
        System.assertEquals(
            false,
            opsOrderResult.Ops_TopQualityCustomer__c,
            'Top Quality Customer flag was not set correctly'
        );
        System.assertEquals(
            'Gold',
            opsOrderResult.Ops_AccountCustomerServiceLevel__c,
            'The Ops Customer Service Level was not set correctly'
        );
    }

    @isTest
    public static void stampOpsOrder_createdFromJob() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        myTestAccount.Ops_Top_20_Customer__c = false;
        myTestAccount.Ops_Top_Quality_Customer__c = true;
        myTestAccount.Ops_CustomerServiceLevel__c = 'Gold';
        update myTestAccount;

        String orderID = '01234-67890';

        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = orderID;
        insert j;

        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.Xometry_ERP_ID__c = orderID;

        Test.startTest();
        insert ord;
        Test.stopTest();

        Ops_Order__c opsOrderResult = [
            SELECT
                Id,
                XometryOpsOrderID__c,
                Ops_Top20Customer__c,
                Ops_TopQualityCustomer__c,
                Ops_AccountCustomerServiceLevel__c
            FROM Ops_Order__c
            LIMIT 1
        ];

        System.assertEquals(false, opsOrderResult.Ops_Top20Customer__c, 'Top 20 Customer flag was not set correctly');
        System.assertEquals(
            true,
            opsOrderResult.Ops_TopQualityCustomer__c,
            'Top Quality Customer flag was not set correctly'
        );
        System.assertEquals(
            'Gold',
            opsOrderResult.Ops_AccountCustomerServiceLevel__c,
            'The Ops Customer Service Level was not set correctly'
        );
    }

    @isTest
    public static void createOrderEvent_basicInsertTest() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        ord.OrderDueDate__c = Date.today() - 1;
        ord.processGroup_isAdditiveOnly__c = true;

        Test.startTest();
        insert ord;
        Test.stopTest();

        Ops_Order__c opsOrderResult = [SELECT Id, XometryOpsOrderID__c FROM Ops_Order__c LIMIT 1];

        Order_Event__c orderEventResult = [
            SELECT ID, Name, Ops_Order__c, Type__c, Qualifying_Object__c, Process_Group__c, Criteria__c
            FROM Order_Event__c
            LIMIT 1
        ];

        System.assertEquals(
            opsOrderResult.ID,
            orderEventResult.Ops_Order__c,
            'The ops order was not associated to the event'
        );
        System.assertEquals(
            'Additive Only & Past Due',
            orderEventResult.Type__c,
            'The type of order event is incorrect'
        );
        System.assertEquals(true, orderEventResult.Criteria__c, 'The order event was not flagged as a criteria');
    }

    @isTest
    public static void createOrderEvent_basicUpdateTest() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        ord.POD__c = 'Atomic Rocks';
        ord.processGroup_isMixed__c = true;
        insert ord;

        ord.OrderDueDate__c = System.today();

        Test.startTest();
        update ord;
        Test.stopTest();

        Ops_Order__c opsOrderResult = [SELECT Id, XometryOpsOrderID__c FROM Ops_Order__c LIMIT 1];

        List<Order_Event__c> orderEventResultList = new List<Order_Event__c>(
            [
                SELECT ID, Name, Ops_Order__c, Type__c, Qualifying_Object__c, Process_Group__c, Criteria__c
                FROM Order_Event__c
            ]
        );

        for (Order_Event__c oe : orderEventResultList) {
            System.assertEquals(opsOrderResult.ID, oe.Ops_Order__c, 'The ops order was not associated to the event');
        }
    }

    @isTest
    public static void createOrderEvent_nonCriteriaTest() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        ord.processGroup_isMixed__c = true;
        ord.OrderDueDate__c = System.today();
        insert ord;

        ord.ERP_Status__c = 'Delivered';

        Test.startTest();
        update ord;
        Test.stopTest();

        Ops_Order__c opsOrderResult = [SELECT Id, XometryOpsOrderID__c FROM Ops_Order__c LIMIT 1];

        List<Order_Event__c> orderEventResultList = new List<Order_Event__c>(
            [
                SELECT ID, Name, Ops_Order__c, Type__c, Qualifying_Object__c, Process_Group__c, Criteria__c
                FROM Order_Event__c
            ]
        );

        Integer numOfNonCriteriaEvents = 0;
        for (Order_Event__c oe : orderEventResultList) {
            System.assertEquals(opsOrderResult.ID, oe.Ops_Order__c, 'The ops order was not associated to the event');

            if (!oe.Criteria__c) {
                numOfNonCriteriaEvents++;
            }
        }
        System.assertEquals(2, numOfNonCriteriaEvents, 'Incorrect number of non-criteria event records were created');
    }

    @isTest
    public static void createBadOutcomes_criteria() {
        //This Test will insert 4orders one with High Bad Outcomes and Top 20, One With Medium Bad Outcomes(Meets Intial Criteria)(Not Top 20),
        // One With Bad Outcomes Low and Top 20
        // One whose BadOutcome data is not yet present
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccountTop20 = retAccounts[0];
        Account myTestAccountNoTop20 = retAccounts[1];
        //Top 20 Customer Criteria
        myTestAccountTop20.Ops_Top_20_Customer__c = true;
        update myTestAccountTop20;
        Order_ERP__c protoOrd = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord1 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord2 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord3 = TestDataFactory.createDefaultOrderERP(false);
        Order_ERP__c ord4 = TestDataFactory.createDefaultOrderERP(false);

        ord1.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord1.processGroup_isMixed__c = true;
        ord1.Xometry_ERP_ID__c = '00000-00001';
        ord1.Bad_Outcomes_Highest_Probability__c = .5111;
        ord1.Bad_Outcomes_Manage_Result__c = 'Manage';
        ord1.Bad_Outcomes_Type__c = 'LATE';
        ord1.Bad_Outcomes_Daily_Tier__c = 'High';
        ord1.Xometry_Quote_ID__c = 'Q12-3333-4445';

        ord2.Account_Domain__c = myTestAccountNoTop20.Email_Domain__c;
        ord2.processGroup_isMixed__c = true;
        ord2.Xometry_ERP_ID__c = '00000-00002';
        ord2.Bad_Outcomes_Highest_Probability__c = .5111;
        ord2.Bad_Outcomes_Manage_Result__c = 'Manage';
        ord2.Bad_Outcomes_Type__c = 'LATE';
        ord2.Bad_Outcomes_Daily_Tier__c = 'Medium';
        ord2.Xometry_Quote_ID__c = 'Q12-3333-4446';

        ord3.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord3.processGroup_isMixed__c = true;
        ord3.Xometry_ERP_ID__c = '00000-00003';
        ord3.Bad_Outcomes_Highest_Probability__c = .0111;
        ord3.Bad_Outcomes_Manage_Result__c = 'Do Not Manage';
        ord3.Bad_Outcomes_Type__c = 'LATE';
        ord3.Bad_Outcomes_Daily_Tier__c = 'Low';
        ord3.Xometry_Quote_ID__c = 'Q12-3333-4447';

        ord4.Account_Domain__c = myTestAccountTop20.Email_Domain__c;
        ord4.processGroup_isMixed__c = true;
        ord4.Xometry_ERP_ID__c = '00000-00004';
        ord4.Bad_Outcomes_Highest_Probability__c = null;
        ord4.Bad_Outcomes_Manage_Result__c = 'Daily Score Not Calculated Yet';
        ord4.Bad_Outcomes_Type__c = null;
        ord4.Bad_Outcomes_Daily_Tier__c = 'High';
        ord4.Xometry_Quote_ID__c = 'Q12-3333-4448';

        System.debug('Making BadOutcome Orders');
        List<Order_Erp__C> ordersToInsertList = new List<Order_Erp__C>();
        ordersToInsertList.add(ord1);
        ordersToInsertList.add(ord2);
        ordersToInsertList.add(ord3);
        ordersToInsertList.add(ord4);
        test.StartTest();
        insert ordersToInsertList;
        test.StopTest();
        List<Order_Event__c> orderEventResultList = new List<Order_Event__c>(
            [SELECT Ops_Order__c, OrderID__c, Type__c, Sub_Type__c, Criteria__c FROM Order_Event__c ORDER BY OrderID__c]
        );
        Map<String, Order_Event__c> badOutcomesOrderEventsMap = new Map<String, Order_Event__c>();
        for (Order_Event__c ordEvent : orderEventResultList) {
            System.debug(ordEvent);
            if (ordEvent.Type__c == 'Bad Outcomes - Order Bad Outcome') {
                badOutcomesOrderEventsMap.put(ordEvent.OrderID__c, ordEvent);
            }
        }
        Integer badOutcomesEventsSize = badOutcomesOrderEventsMap.values().size();
        System.assertEquals(3, badOutcomesEventsSize, 'There were not 3 BadOutcome Events created');
        Order_Event__c ordEvent1 = badOutcomesOrderEventsMap.get(ord1.Xometry_ERP_ID__c);
        System.assertEquals(true, ordEvent1.Criteria__c, 'This Bad Outcome was not listed as a Criteria');
        Order_Event__c ordEvent3 = badOutcomesOrderEventsMap.get(ord3.Xometry_ERP_ID__c);
        System.assertEquals(false, ordEvent3.Criteria__c, 'This Bad Outcome should not be listed as a Criteria');
    }

    @isTest
    public static void createOrderEvent_multipleEventsTest() {
        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        //Top 20 Customer Criteria
        myTestAccount.Ops_Top_20_Customer__c = true;
        update myTestAccount;

        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.processGroup_isMixed__c = true;
        // POD Event
        ord.POD__c = 'Atomic Rocks';
        //MQ > $ Threshold Criteria
        ord.Quote_Type__c = 'Manually-Quoted';
        ord.Order_Total__c =
            [SELECT ID, Currency_Ref_Value__c FROM Event_Threshold__mdt WHERE DeveloperName = 'order_MQEventQualAmount']
            .Currency_Ref_Value__c + 1;
        insert ord;

        //Expedited Event
        ord.PricingTier__c = 'Expedited';
        update ord;

        // T-minus Event
        ord.OrderDueDate__c = System.today();
        update ord;

        //Fully Shipped Event
        ord.ERP_Status__c = 'Shipped';

        Test.startTest();
        update ord;
        Test.stopTest();

        List<Order_Event__c> orderEventResultList = new List<Order_Event__c>([SELECT Criteria__c FROM Order_Event__c]);

        System.assertEquals(6, orderEventResultList.size(), 'Not all events were created');

        Integer numOfCriteriaEvents = 0;
        Integer numOfNonCriteriaEvents = 0;
        for (Order_Event__c oe : orderEventResultList) {
            if (oe.Criteria__c) {
                numOfCriteriaEvents++;
            } else {
                numOfNonCriteriaEvents++;
            }
        }

        System.assertEquals(2, numOfCriteriaEvents, 'Incorrect number of criteria event records were created');
        System.assertEquals(4, numOfNonCriteriaEvents, 'Incorrect number of non-criteria event records were created');
    }

    @isTest
    public static void createOrderEvent_multipleOpsOrderEventsTest() {
        List<Order_ERP__C> ordersToInsert = new List<Order_ERP__C>();

        List<Account> retAccounts = TestDataFactory.createTestAccountNonGenerics(2, 'BDR', 1);
        Account myTestAccount = retAccounts[0];
        //Top 20 Customer Event (Criteria)
        myTestAccount.Ops_Top_20_Customer__c = true;
        update myTestAccount;

        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(false);
        ord.Xometry_ERP_ID__c = '00000-00001';
        ord.Account_Domain__c = myTestAccount.Email_Domain__c;
        ord.processGroup_isMixed__c = true;
        // POD Event
        ord.POD__c = 'Atomic Rocks';
        //MQ w/ Custom Finish Event (Criteria)
        ord.Quote_Type__c = 'Manually-Quoted';
        ord.ContainsCustomFinish__c = true;
        ord.ERP_Status__c = 'In Progress';
        ordersToInsert.add(ord);

        Order_ERP__c additiveOrd = TestDataFactory.createDefaultOrderERP(false);
        additiveOrd.Xometry_ERP_ID__c = '00000-00002';
        additiveOrd.Account_Domain__c = 'differentDomain.com';
        additiveOrd.processGroup_isAdditiveOnly__c = true;
        //Expedited Event
        additiveOrd.PricingTier__c = 'Expedited';
        additiveOrd.ERP_Status__c = 'In Progress';
        //Late Additive Order Event (Criteria)
        additiveOrd.OrderDueDate__c = System.today().addDays(-1);
        ordersToInsert.add(additiveOrd);

        Test.startTest();
        insert ordersToInsert;
        Test.stopTest();

        List<Order_Event__c> orderEventResultList = new List<Order_Event__c>(
            [
                SELECT Ops_Order__c, OrderID__c, Type__c, Sub_Type__c, InitialCriteria__c
                FROM Order_Event__c
                ORDER BY OrderID__c
            ]
        );

        System.assertEquals(4, orderEventResultList.size(), 'Not all events were created');

        Set<ID> opsOrdersWithEventsSet = new Set<ID>();
        for (Order_Event__c oe : orderEventResultList) {
            opsOrdersWithEventsSet.add(oe.Ops_Order__c);
            System.debug(oe);
            if (oe.Type__c == 'Top 20 Customer') {
                System.assertEquals(true, oe.InitialCriteria__c, 'Order Event should be the initial criteria');
            }
            if (oe.Type__c == 'Additive Only & Past Due') {
                System.assertEquals(true, oe.InitialCriteria__c, 'Order Event should be the initial criteria');
            }
        }

        System.assertEquals(2, opsOrdersWithEventsSet.size(), 'Both Ops Orders did not get their events created');
    }

    @isTest
    public static void badOutcomesIdealPath() {
        Test.startTest();
        Map<String, List<SObject>> returnObjMap = TestDataFactory.badOutcomesIdealPath();
        Test.stopTest();

        Order_ERP__c ord1 = (Order_ERP__c) returnObjMap.get('Order')[0];
        Order_ERP__c ord2 = (Order_ERP__c) returnObjMap.get('Order')[1];
        Order_ERP__c ord3 = (Order_ERP__c) returnObjMap.get('Order')[2];
        Order_ERP__c ord4 = (Order_ERP__c) returnObjMap.get('Order')[3];
        Order_ERP__c ord5 = (Order_ERP__c) returnObjMap.get('Order')[4];

        Map<String, Integer> orderIdToEventCount = new Map<String, Integer>();
        for (Order_Event__c oe : [
            SELECT Qualifying_Object__c, Ops_Order__c, OrderID__c, Type__c, Sub_Type__c, InitialCriteria__c
            FROM Order_Event__c
            ORDER BY OrderID__c
        ]) {
            if (oe.OrderID__c == ord1.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Top 20 Customer') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
            }
            if (oe.OrderID__c == ord2.Xometry_ERP_ID__c) {
                System.assertEquals(
                    'Bad Outcomes - Order Bad Outcome',
                    oe.Type__c,
                    'Type should be Bad Outcomes - Order Bad Outcome'
                );
                System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
            }
            if (oe.OrderID__c == ord3.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Top 20 Customer') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
                if (oe.Type__c == 'Bad Outcomes - Order Bad Outcome') {
                    System.assertEquals(false, oe.InitialCriteria__c, 'InitialCriteria should be false');
                }
            }

            if (oe.OrderID__c == ord4.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Top 20 Customer') {
                    System.assertEquals(false, oe.InitialCriteria__c, 'InitialCriteria should be false');
                }
                if (oe.Type__c == 'Manufacturing Process') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
            }

            if (oe.OrderID__c == ord5.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Estimated Completion Date') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
            }
            if (!orderIdToEventCount.containsKey(oe.OrderID__c)) {
                orderIdToEventCount.put(oe.OrderID__c, 1);
            } else {
                orderIdToEventCount.put(oe.OrderID__c, orderIdToEventCount.get(oe.OrderID__c) + 1);
            }
        }
        System.assertEquals(2, orderIdToEventCount.get(ord1.Xometry_ERP_ID__c), 'Order 1 should have 2 order Events');
        System.assertEquals(1, orderIdToEventCount.get(ord2.Xometry_ERP_ID__c), 'Order 2 should have 1 order Events');
        System.assertEquals(2, orderIdToEventCount.get(ord3.Xometry_ERP_ID__c), 'Order 3 should have 2 order Events');
        System.assertEquals(6, orderIdToEventCount.get(ord4.Xometry_ERP_ID__c), 'Order 4 should have 6 order Events');
        System.assertEquals(3, orderIdToEventCount.get(ord5.Xometry_ERP_ID__c), 'Order 5 should have 3 order Events');

        Ordered_Part__c ordPart = (Ordered_Part__c) returnObjMap.get('Part')[0];
        List<Ordered_Part_Event__c> opeResult = [
            SELECT
                Xometry_Part_ID__c,
                Xometry_Order_ID__c,
                Xometry_Job_ID__c,
                Type__c,
                Criteria__c,
                Job_Event__c,
                Order_Event__c
            FROM Ordered_Part_Event__c
            WHERE Xometry_Part_ID__c = :ordPart.Xometry_Ordered_Part_ID__c
        ];

        System.assertEquals(3, opeResult.size(), 'Ordered Part Events should be 3');

        Job__c job = (Job__c) returnObjMap.get('Job')[0];
        List<Job_Event__c> jeResult = [
            SELECT Qualifying_Object__c, JobID__c, Xometry_Part_ID__c, Process_Group__c, Type__c, Criteria__c
            FROM Job_Event__c
            WHERE JobID__c = :job.XometryJobID__c
        ];
        System.assertEquals(2, jeResult.size(), 'Job Events should be 2');
    }

    @isTest
    public static void badOutcomesDelayPath() {
        Test.startTest();
        Map<String, List<SObject>> returnObjMap = TestDataFactory.badOutcomesDelayPath();
        Test.stopTest();

        Order_ERP__c ord1 = (Order_ERP__c) returnObjMap.get('Order')[0];
        Order_ERP__c ord2 = (Order_ERP__c) returnObjMap.get('Order')[1];
        Order_ERP__c ord3 = (Order_ERP__c) returnObjMap.get('Order')[2];
        Order_ERP__c ord4 = (Order_ERP__c) returnObjMap.get('Order')[3];
        Order_ERP__c ord5 = (Order_ERP__c) returnObjMap.get('Order')[4];

        Map<String, Integer> orderIdToEventCount = new Map<String, Integer>();
        for (Order_Event__c oe : [
            SELECT Qualifying_Object__c, Ops_Order__c, OrderID__c, Type__c, Sub_Type__c, InitialCriteria__c
            FROM Order_Event__c
            ORDER BY OrderID__c
        ]) {
            if (oe.OrderID__c == ord1.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Top 20 Customer') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
            }
            if (oe.OrderID__c == ord2.Xometry_ERP_ID__c) {
                System.assertEquals(
                    'Bad Outcomes - Order Bad Outcome',
                    oe.Type__c,
                    'Type should be Bad Outcomes - Order Bad Outcome'
                );
                System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
            }
            if (oe.OrderID__c == ord3.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Top 20 Customer') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
                if (oe.Type__c == 'Bad Outcomes - Order Bad Outcome') {
                    System.assertEquals(false, oe.InitialCriteria__c, 'InitialCriteria should be false');
                }
            }

            if (oe.OrderID__c == ord4.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Top 20 Customer') {
                    System.assertEquals(false, oe.InitialCriteria__c, 'InitialCriteria should be false');
                }
                if (oe.Type__c == 'Manufacturing Process') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
            }

            if (oe.OrderID__c == ord5.Xometry_ERP_ID__c) {
                if (oe.Type__c == 'Estimated Completion Date') {
                    System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
                }
            }
            if (!orderIdToEventCount.containsKey(oe.OrderID__c)) {
                orderIdToEventCount.put(oe.OrderID__c, 1);
            } else {
                orderIdToEventCount.put(oe.OrderID__c, orderIdToEventCount.get(oe.OrderID__c) + 1);
            }
        }
        System.assertEquals(2, orderIdToEventCount.get(ord1.Xometry_ERP_ID__c), 'Order 1 should have 2 order Events');
        System.assertEquals(1, orderIdToEventCount.get(ord2.Xometry_ERP_ID__c), 'Order 2 should have 1 order Events');
        System.assertEquals(2, orderIdToEventCount.get(ord3.Xometry_ERP_ID__c), 'Order 3 should have 2 order Events');
        System.assertEquals(6, orderIdToEventCount.get(ord4.Xometry_ERP_ID__c), 'Order 4 should have 6 order Events');
        System.assertEquals(3, orderIdToEventCount.get(ord5.Xometry_ERP_ID__c), 'Order 5 should have 3 order Events');

        Ordered_Part__c ordPart = (Ordered_Part__c) returnObjMap.get('Part')[0];
        List<Ordered_Part_Event__c> opeResult = [
            SELECT
                Xometry_Part_ID__c,
                Xometry_Order_ID__c,
                Xometry_Job_ID__c,
                Type__c,
                Criteria__c,
                Job_Event__c,
                Order_Event__c
            FROM Ordered_Part_Event__c
            WHERE Xometry_Part_ID__c = :ordPart.Xometry_Ordered_Part_ID__c
        ];

        System.assertEquals(3, opeResult.size(), 'Ordered Part Events should be 3');

        Job__c job = (Job__c) returnObjMap.get('Job')[0];
        List<Job_Event__c> jeResult = [
            SELECT Qualifying_Object__c, JobID__c, Xometry_Part_ID__c, Process_Group__c, Type__c, Criteria__c
            FROM Job_Event__c
            WHERE JobID__c = :job.XometryJobID__c
        ];
        System.assertEquals(2, jeResult.size(), 'Job Events should be 2');
    }

    @isTest
    public static void badOutcomesNoOrderCriteria() {
        Map<String, Integer> initialCriteriaCountByOrderId = new Map<String, Integer>();
        Test.startTest();
        Map<String, List<SObject>> returnObjMap = TestDataFactory.badOutcomesNoOrderCriteriaPath();
        Test.stopTest();

        Order_ERP__c ord1 = (Order_ERP__c) returnObjMap.get('Order')[0];
        Order_ERP__c ord2 = (Order_ERP__c) returnObjMap.get('Order')[1];
        Order_ERP__c ord3 = (Order_ERP__c) returnObjMap.get('Order')[2];
        Order_ERP__c ord4 = (Order_ERP__c) returnObjMap.get('Order')[3];
        Order_ERP__c ord5 = (Order_ERP__c) returnObjMap.get('Order')[4];

        for (Order_Event__c oe : [
            SELECT Qualifying_Object__c, Ops_Order__c, OrderID__c, Type__c, Sub_Type__c, InitialCriteria__c
            FROM Order_Event__c
            ORDER BY OrderID__c
        ]) {
            if (oe.Type__c == 'Non-Standard Inspection') {
                System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
            }
            if (oe.Type__c == 'Estimated Completion Date' && oe.OrderID__c == ord5.Xometry_ERP_ID__c) {
                System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
            }
            if (oe.Type__c == 'Bad Outcomes - Order Bad Outcome') {
                System.assertEquals(true, oe.InitialCriteria__c, 'InitialCriteria should be true');
            }
            if (oe.InitialCriteria__c) {
                if (initialCriteriaCountByOrderId.containsKey(oe.OrderID__c)) {
                    initialCriteriaCountByOrderId.put(
                        oe.OrderID__c,
                        initialCriteriaCountByOrderId.get(oe.OrderID__c) + 1
                    );
                } else {
                    initialCriteriaCountByOrderId.put(oe.OrderId__c, 1);
                }
            }
        }
        for (String ord : initialCriteriaCountByOrderId.keySet()) {
            System.assertEquals(1, initialCriteriaCountByOrderId.get(ord), 'Each order should only have 1 initial');
        }
    }
}