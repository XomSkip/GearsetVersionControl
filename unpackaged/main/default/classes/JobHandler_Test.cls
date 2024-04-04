@isTest
public with sharing class JobHandler_Test {
    @isTest
    public static void JobHandler_associatesOpsOrder() {
        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = '01234-67890';

        Job__c j2 = new Job__c();
        j2.Name = 'Test-Job';
        j2.XometryJobID__c = 'TestJob2';
        j2.Order_IDs_String__c = '12345-67890;23456-78901';

        Test.startTest();
        insert new List<Job__c>{ j, j2 };
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, XometryOpsOrderID__c, XometryJobID__c, OrderID__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];
        Ops_Order__c opsOrder = [
            SELECT Id, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :j.XometryOpsOrderID__c
        ];

        System.assertNotEquals(null, insertedJob.OrderID__c, 'OpsOrderId should be associated');

        Ops_Order__c opsOrder2 = [
            SELECT Id, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = '23456-78901'
        ];
        System.assertNotEquals(null, opsOrder2.XometryOpsOrderID__c, 'Order should be created with order id');
    }

    @isTest(seeAllData=false)
    public static void JobHandler_associatesMultiOpsOrder() {
        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = '12304-23431';
        j.Order_IDs_String__c = '12357-43218;12365-17843';

        Test.startTest();
        insert j;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, XometryOpsOrderID__c, XometryJobID__c, OrderID__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];
        System.assertNotEquals(null, insertedJob.OrderID__c, 'OpsOrderId should be associated');

        List<Ops_Order__c> opsOrder = [
            SELECT Id, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE
                XometryOpsOrderID__c = '12365-17843'
                OR XometryOpsOrderID__c = '12357-43218'
                OR XometryOpsOrderID__c = '12304-23431'
        ];

        System.assertEquals(3, opsOrder.size(), 'Ops Orders list size should be 3');
    }

    @isTest
    public static void JobHandler_associatesExistingOpsOrder() {
        Ops_Order__c o = new Ops_Order__c();
        o.Stage__c = 'Partially Complete';
        o.XometryOpsOrderID__c = '01234-67890';
        insert o;

        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = '01234-67890';

        Test.startTest();
        insert j;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, XometryOpsOrderID__c, XometryJobID__c, OrderID__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];

        System.assertNotEquals(null, insertedJob.OrderID__c, 'OpsOrderId should be associated');
    }

    @isTest
    public static void JobHandler_associatesExistingOpsOrderComplete() {
        Ops_Order__c o = new Ops_Order__c();
        o.Stage__c = 'Complete';
        o.XometryOpsOrderID__c = '01234-67890';
        insert o;

        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = '01234-67890';

        Test.startTest();
        insert j;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, XometryOpsOrderID__c, XometryJobID__c, OrderID__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];

        Ops_Order__c opsOrderResult = [
            SELECT Id, Stage__c, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :o.XometryOpsOrderID__c
        ];

        System.assertNotEquals(null, insertedJob.OrderID__c, 'OpsOrderId should be associated');
        System.assertEquals(
            'Complete',
            opsOrderResult.Stage__c,
            'Stage should stay complete if a job comes in after stage is complete'
        );
    }

    @isTest
    public static void JobHandler_associatesSupplier() {
        Job__c j = TestDataFactory.createJobWithSupplier();
        j.AcceptedPartnerID__c = 'P-Test';

        Test.startTest();
        insert j;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, Supplier__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];

        System.assertNotEquals(null, insertedJob.Supplier__c, 'Supplier should be associated');
    }

    @isTest
    public static void JobHandler_associatesSupplier_AcceptedPartnerNull() {
        Job__c j = TestDataFactory.createJobWithSupplier();
        j.AcceptedPartnerID__c = '';

        Test.startTest();
        insert j;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, Supplier__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];

        System.assertEquals(null, insertedJob.Supplier__c, 'Supplier should not be associated');
    }

    @isTest
    public static void JobHandler_associatesSupplier_AcceptedPartnerUpdate() {
        Job__c j = TestDataFactory.createJobWithSupplier();
        j.AcceptedPartnerID__c = '';

        insert j;

        Test.startTest();
        j.AcceptedPartnerID__c = 'P-Test';
        update j;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, Supplier__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];

        System.assertNotEquals(null, insertedJob.Supplier__c, 'Supplier should be associated');
    }

    @isTest
    public static void JobHandler_associatesSupplier_MultipleExisting() {
        Job__c j = TestDataFactory.createJobWithSupplier();
        j.AcceptedPartnerID__c = 'P-Test1';

        Supplier__c s1 = new Supplier__c();
        s1.PartnerID__c = 'P-Test1';
        s1.SupplierCompanyName__c = 'P-Test1';
        s1.EmailAddress__c = 'email@tester1.com';
        s1.LastName__c = 'Supplier1';

        insert s1;

        Supplier__c s2 = new Supplier__c();
        s2.PartnerID__c = 'P-Test2';
        s2.SupplierCompanyName__c = 'P-Test2';
        s2.EmailAddress__c = 'email@tester2.com';
        s2.LastName__c = 'Supplier2';

        insert s2;

        Test.startTest();
        insert j;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, Supplier__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];

        Supplier__c associatedSupplier = [
            SELECT Id, PartnerID__C
            FROM Supplier__c
            WHERE PartnerID__c = :s1.PartnerID__c
        ];

        System.assertEquals(
            insertedJob.Supplier__c,
            associatedSupplier.Id,
            'Expected supplier id to equal to supplier Id'
        );
    }

    @isTest
    public static void jobHandler_multipleJobs_sameSupplier() {
        List<Job__c> insertList = TestDataFactory.createJobsWithSupplier(false);
        Job__c j = insertList[0];
        Job__c j1 = insertList[1];
        Job__c j2 = insertList[2];

        Test.startTest();
        insert insertList;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, Supplier__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];
        Job__c insertedJobOne = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, Supplier__c
            FROM Job__c
            WHERE XometryJobID__c = :j1.XometryJobID__c
        ];

        Supplier__c associatedSupplier = [SELECT Id, PartnerID__C FROM Supplier__c WHERE PartnerID__c = :'P-Test'];

        System.assertEquals(insertedJob.Supplier__c, associatedSupplier.Id, 'Job should be associated to supplier');
        System.assertEquals(
            insertedJobOne.Supplier__c,
            associatedSupplier.Id,
            'Second Job should be associated to same supplier'
        );
    }

    @isTest
    public static void jobHandler_multipleJobs_sameOrder() {
        List<Job__c> insertList = TestDataFactory.createJobsWithSupplier(true);
        Job__c j = insertList[0];
        Job__c j1 = insertList[1];
        // Note: Left this as 1234 because the test data factory is built like this
        j1.XometryOpsOrderID__c = '1234';
        Job__c j2 = insertList[2];

        Test.startTest();
        insert insertList;
        Test.stopTest();

        Job__c insertedJob = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, OrderID__c
            FROM Job__c
            WHERE XometryJobID__c = :j.XometryJobID__c
        ];
        Job__c insertedJobOne = [
            SELECT Id, AcceptedPartnerID__c, XometryJobID__c, OrderID__c
            FROM Job__c
            WHERE XometryJobID__c = :j1.XometryJobID__c
        ];

        Ops_Order__c opsOrderResult = [
            SELECT Id, Stage__c, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = '1234'
        ];

        System.assertEquals(insertedJob.OrderID__c, opsOrderResult.Id, 'Job should be associated to ops order');
        System.assertEquals(
            insertedJobOne.OrderID__c,
            opsOrderResult.Id,
            'Second Job should be associated to ops order'
        );
    }

    @isTest(seeAllData=false)
    public static void createJobOrderJunctionTest() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'BBBBB-15063';
        opsOrder.OrderTotal__c = 1;

        Ops_Order__c opsOrder2 = new Ops_Order__c();
        opsOrder2.POD__c = 'First Impressions';
        opsOrder2.XometryOpsOrderID__c = 'BBBBB-15019';
        opsOrder2.OrderTotal__c = 1;

        insert new List<Ops_Order__c>{ opsOrder, opsOrder2 };

        Job__c j = new Job__c();
        j.Stage__c = 'Accepted';
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.ShippingService__C = 'Fedex';
        j.ShippingMethod__c = 'Two Day Air';
        j.Order_IDs_String__c = 'BBBBB-15017;BBBBB-15063;BBBBB-1500B;BBBBB-15002;BBBBB-15001;BBBBB-15004;BBBBB-15014;0E5BB-1510B;BB969-15032';
        j.XometryOpsOrderID__c = 'BBBBB-34567';

        Job__c j2 = new Job__c();
        j2.Stage__c = 'Accepted';
        j2.Name = 'Test-Job2';
        j2.XometryJobID__c = 'TestJob2';
        j2.ShippingService__C = 'Fedex';
        j2.ShippingMethod__c = 'Two Day Air';
        j2.Order_IDs_String__c = 'BBBBB-15017;BBBBB-15063;BBBBB-15019;BBBBB-1500B;BBBBB-15002;BBBBB-15001;BBBBB-15004;BBBBB-15014;0E5BB-1510B;BB969-15032';
        j2.XometryOpsOrderID__c = 'BBBBB-34567';

        Test.startTest();
        insert new List<Job__c>{ j, j2 };
        Test.stopTest();

        System.assertEquals(10, [SELECT Id FROM Job_Order__c WHERE Job__c = :j.Id].size());

        System.assertEquals(11, [SELECT Id FROM Job_Order__c WHERE Job__c = :j2.Id].size());
    }

    @isTest(seeAllData=false)
    public static void updateJobOrderJunctionTest() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'BBBBB-15063';
        opsOrder.OrderTotal__c = 1;

        Ops_Order__c opsOrder2 = new Ops_Order__c();
        opsOrder2.POD__c = 'First Impressions';
        opsOrder2.XometryOpsOrderID__c = 'BBBBB-15019';
        opsOrder2.OrderTotal__c = 1;

        insert new List<Ops_Order__c>{ opsOrder, opsOrder2 };

        Job__c j = new Job__c();
        j.Stage__c = 'Accepted';
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.ShippingService__C = 'Fedex';
        j.ShippingMethod__c = 'Two Day Air';
        j.Order_IDs_String__c = 'BBBBB-15017;BBBBB-15063;BBBBB-1500B;BBBBB-15002;BBBBB-15001;BBBBB-15004;BBBBB-15014;0E5BB-1510B;BB969-15032';
        j.XometryOpsOrderID__c = 'BBBBB-34567';

        Job__c j2 = new Job__c();
        j2.Stage__c = 'Accepted';
        j2.Name = 'Test-Job2';
        j2.XometryJobID__c = 'TestJob2';
        j2.ShippingService__C = 'Fedex';
        j2.ShippingMethod__c = 'Two Day Air';
        j2.Order_IDs_String__c = 'BBBBB-15017;BBBBB-15063;BBBBB-15019;BBBBB-1500B;BBBBB-15002;BBBBB-15001;BBBBB-15004;BBBBB-15014;0E5BB-1510B;BB969-15032';
        j2.XometryOpsOrderID__c = 'BBBBB-34567';

        insert new List<Job__c>{ j, j2 };
        List<Job_Order__c> jobOrdersJunction = [SELECT Id FROM Job_Order__c WHERE Job__c = :j.Id];
        j.Order_IDs_String__c = 'BBBBB-15017;BBBBB-15063;BBBBB-1500B;BBBBB-15002;BBBBB-15001;BBBBB-15004;BBBBB-15014;0E5BB-1510B;BB969-15032;BB257-15003';

        Test.startTest();
        upsert j;
        Test.stopTest();

        System.assertEquals(11, [SELECT Id FROM Job_Order__c WHERE Job__c = :j.Id].size());
        String expectedNewKey = 'BB257-15003 : ' + j.Name;
        Job_Order__c newJunction = [
            SELECT Id, OrderAndJobId__c
            FROM Job_Order__c
            WHERE OrderAndJobId__c = :expectedNewKey
        ][0];
        System.assertEquals(expectedNewKey, newJunction.OrderAndJobId__c, 'did not have new key');

        System.assertEquals(11, [SELECT Id FROM Job_Order__c WHERE Job__c = :j2.Id].size());
    }

    @isTest(seeAllData=false)
    public static void updateStatusRollUpOnOrderTest() {
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        Date OrderPlacedDate = Date.today();
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.Cases_In_Progress__c = 99;
        opsOrder.Jobs_In_Progress__c = 99;
        opsOrder.Cases_Completed__c = 99;
        opsOrder.Jobs_Completed__c = 99;
        opsOrder.AllOrdersTotal__c = largeOrderAmount + 1;
        opsOrder.OrderTotal__c = largeOrderAmount + 1;
        opsOrder.XometryOpsOrderID__c = 'AAAA1-12301';
        opsOrder.Order_Date__c = OrderPlacedDate;

        Ops_Order__c opsOrder2 = new Ops_Order__c();
        opsOrder2.Cases_In_Progress__c = 99;
        opsOrder2.Jobs_In_Progress__c = 99;
        opsOrder2.Cases_Completed__c = 99;
        opsOrder2.Jobs_Completed__c = 99;
        opsOrder2.AllOrdersTotal__c = largeOrderAmount + 1;
        opsOrder2.OrderTotal__c = largeOrderAmount + 1;
        opsOrder2.XometryOpsOrderID__c = 'AAAA1-12302';
        opsOrder2.Order_Date__c = OrderPlacedDate;

        insert new List<Ops_Order__c>{ opsOrder, opsOrder2 };

        Job__c testJob2 = new Job__c(
            RiskFactor__c = 'High',
            Name = 'Test-Job2',
            //OrderID__c = opsOrder2.Id,
            XometryJobID__c = 'TestJob2',
            XometryOpsOrderID__c = opsOrder2.XometryOpsOrderID__c
        );
        testJob2.Order_IDs_String__c = opsOrder2.XometryOpsOrderID__c + ';';
        insert testJob2;

        Test.startTest();

        testJob2.OrderID__c = opsOrder2.Id;
        Job__c testJob = new Job__c(
            RiskFactor__c = 'High',
            Name = 'Test-Job1',
            //OrderID__c = opsOrder.Id,
            XometryJobID__c = 'TestJob1',
            XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c
        );
        testJob.Order_IDs_String__c = opsOrder.XometryOpsOrderID__c + ';';
        upsert new List<Job__c>{ testJob, testJob2 };

        Test.stopTest();

        Map<Id, Ops_Order__c> opsOrderResult = new Map<Id, Ops_Order__c>(
            [SELECT Jobs_In_Progress__c, Jobs_Completed__c FROM Ops_Order__c]
        );

        List<Job_Order__c> testJobOrdList = [
            SELECT
                XometryJobID__c,
                XometryOpsOrderID__c,
                OrderAndJobId__c,
                Ops_Order__c,
                Job__r.Technical_Review_Status__c,
                Job__r.DFM_Complete__c
            FROM Job_Order__c
        ];

        System.debug('Here are the jobOrders');
        System.debug(testJobOrdList);

        System.assertEquals(1, opsOrderResult.get(opsOrder.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder.Id).Jobs_Completed__c, 'Rollup should be updated');

        System.assertEquals(1, opsOrderResult.get(opsOrder2.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder2.Id).Jobs_Completed__c, 'Rollup should be updated');
    }

    @isTest(seeAllData=false)
    public static void updateStatusRollUpOnOrderDeleteTest() {
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        Date OrderPlacedDate = Date.today();
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.Cases_In_Progress__c = 99;
        opsOrder.Jobs_In_Progress__c = 99;
        opsOrder.Cases_Completed__c = 99;
        opsOrder.Jobs_Completed__c = 99;
        opsOrder.AllOrdersTotal__c = largeOrderAmount + 1;
        opsOrder.OrderTotal__c = largeOrderAmount + 1;
        opsOrder.XometryOpsOrderID__c = 'AAAA1-12301';
        opsOrder.Order_Date__c = OrderPlacedDate;

        Ops_Order__c opsOrder2 = new Ops_Order__c();
        opsOrder2.Cases_In_Progress__c = 99;
        opsOrder2.Jobs_In_Progress__c = 99;
        opsOrder2.Cases_Completed__c = 99;
        opsOrder2.Jobs_Completed__c = 99;
        opsOrder2.AllOrdersTotal__c = largeOrderAmount + 1;
        opsOrder2.OrderTotal__c = largeOrderAmount + 1;
        opsOrder2.XometryOpsOrderID__c = 'AAAA1-12302';
        opsOrder2.Order_Date__c = OrderPlacedDate;

        insert new List<Ops_Order__c>{ opsOrder, opsOrder2 };

        Job__c testJob = new Job__c(
            RiskFactor__c = 'High',
            Name = 'Test-Job1',
            OrderID__c = opsOrder.Id,
            XometryJobID__c = 'TestJob1',
            XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c
        );
        testJob.Order_IDs_String__c = opsOrder.XometryOpsOrderID__c + ';';
        Job__c testJob2 = new Job__c(
            RiskFactor__c = 'High',
            Name = 'Test-Job2',
            OrderID__c = opsOrder2.Id,
            XometryJobID__c = 'TestJob2',
            XometryOpsOrderID__c = opsOrder2.XometryOpsOrderID__c
        );
        testJob2.Order_IDs_String__c = opsOrder2.XometryOpsOrderID__c + ';';

        insert new List<Job__c>{ testJob, testJob2 };

        Test.startTest();

        delete testJob2;

        Test.stopTest();

        Map<Id, Ops_Order__c> opsOrderResult = new Map<Id, Ops_Order__c>(
            [SELECT Jobs_In_Progress__c, Jobs_Completed__c FROM Ops_Order__c]
        );

        System.assertEquals(1, opsOrderResult.get(opsOrder.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder.Id).Jobs_Completed__c, 'Rollup should be updated');

        System.assertEquals(0, opsOrderResult.get(opsOrder2.Id).Jobs_In_Progress__c, 'Rollup should be updated');
        System.assertEquals(0, opsOrderResult.get(opsOrder2.Id).Jobs_Completed__c, 'Rollup should be updated');
    }

    @isTest(seeAllData=false)
    public static void JobHandler_createTechnicalReviewCaseOnUpdate() {
        Map<String, Ops_Order__C> testOpsOrders = TestDataFactory.createLargeOpsOrderTestData(
            1,
            1,
            2,
            new List<Ops_Order__c>()
        );

        Test.startTest();
        List<Job__c> createdJobList = [SELECT id, OrderID__c, XometryOpsOrderID__c, XometryJobID__c FROM Job__c];

        Job__c highRiskJob = new Job__c();
        highRiskJob.Id = createdJobList[0].Id;
        highRiskJob.RiskFactor__c = 'High';
        highRiskJob.AcceptedPartnerID__c = 'P12345';

        Job__c lowRiskJob = new Job__c();
        lowRiskJob.Id = createdJobList[1].Id;
        lowRiskJob.RiskFactor__c = 'Low';
        lowRiskJob.AcceptedPartnerID__c = 'P12345';
        update new List<Job__c>{ highRiskJob, lowRiskJob };
        Test.stopTest();

        System.debug('Finished Test Stop Test so in out Section');
        System.debug('Before assertion queries we are at ' + Limits.getQueries());
        List<Case> techReviewCasesCreated = [
            SELECT Id, Status, Type
            FROM Case
            WHERE Type = 'Technical Review' AND Job__c IN (:highRiskJob.Id, :lowRiskJob.Id)
        ];

        System.assertEquals(1, techReviewCasesCreated.size(), 'Tech Review cases were created for non-high-risk jobs');
    }

    @isTest(seeAllData=false)
    public static void JobHandler_createTechnicalReviewCaseOnInsert() {
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;
        Date OrderPlacedDate = Date.today();

        Order_ERP__C testLargeOrder = new Order_ERP__C();
        testLargeOrder.Xometry_ERP_ID__c = 'AAAA1-12345';
        testLargeOrder.Account_Domain__c = 'pizzamakers.com';
        testLargeOrder.ERP_Company_Name__C = 'Ninja Pizza';
        testLargeOrder.ERP_Contact_First_Name__c = 'Hamato';
        testLargeOrder.ERP_Contact_Last_Name__c = 'Yoshi';
        testLargeOrder.ERP_Contact__C = 'BBBBB';
        testLargeOrder.ERP_PartPk__c = '56564-55667';
        testLargeOrder.Is_Generic__c = false;
        testLargeOrder.Order_Canceled_Flag__c = false;
        testLargeOrder.Order_ERP_CreatedDate__c = date.newInstance(2019, 8, 15);
        testLargeOrder.Order_ERP_Time__c = dateTime.newInstance(2019, 8, 15, 10, 0, 30);
        testLargeOrder.Order_Email__c = 'splinterspizza@pizzamakers.com';
        testLargeOrder.Order_Subtotal__c = largeOrderAmount + 1;
        testLargeOrder.Order_Total__c = largeOrderAmount + 1;
        testLargeOrder.AllOrdersTotal__c = largeOrderAmount * 2;
        testLargeOrder.Payment_Type__c = 'credit_card';
        testLargeOrder.process_isPolyJet_3D__c = true;
        testLargeOrder.Order_ERP_CreatedDate__C = OrderPlacedDate;
        insert testLargeOrder;

        Job__C testJob = new Job__C();
        testJob.Stage__c = 'Accepted';
        testJob.Name = 'TestJob';
        testJob.RiskFactor__c = 'High';
        testJob.XometryJobID__c = 'J0012345';
        testJob.ShippingService__C = 'Fedex';
        testJob.ShippingMethod__c = 'Two Day Air';
        testJob.Order_IDs_String__c = testLargeOrder.Xometry_ERP_ID__c + ';';
        testJob.XometryOpsOrderID__c = testLargeOrder.Xometry_ERP_ID__c;
        testJob.AcceptedPartnerID__c = 'P12345';

        Test.startTest();
        insert testJob;
        Test.stopTest();

        List<Case> techReviewCasesCreated = [
            SELECT Id, Status, Type, Job__c, GNOOrder__c, BusinessHoursId
            FROM Case
            WHERE Type = 'Technical Review'
        ];
        Job__c insertedJob = [
            SELECT Id, OrderID__c, Technical_Review_Status__c
            FROM Job__c
            WHERE XometryJobID__c = :testJob.XometryJobID__c
            LIMIT 1
        ];
        Ops_Order__c updatedOpsOrder = [
            SELECT Id, Stage__c
            FROM Ops_Order__c
            WHERE Id = :insertedJob.OrderID__c
            LIMIT 1
        ];

        System.assertEquals(1, techReviewCasesCreated.size(), 'Tech Review cases were created for non-high-risk jobs');
        System.assertEquals('New', techReviewCasesCreated[0].Status, 'Case status was not updated');
        System.assertEquals(
            updatedOpsOrder.Id,
            techReviewCasesCreated[0].GNOOrder__c,
            'Ops Order was not associated to case'
        );
        System.assertEquals(insertedJob.Id, techReviewCasesCreated[0].Job__c, 'High Risk Job was not Associated');

        Map<String, BusinessHours> hoursMap = new Map<String, BusinessHours>();
        for (BusinessHours bHours : [SELECT Id, Name FROM BusinessHours]) {
            hoursMap.put(bHours.Name, bHours);
        }

        System.assertEquals(
            hoursMap.get('POD Business Hours - EST').Id,
            techReviewCasesCreated[0].BusinessHoursId,
            'BusinessHoursId should be updated'
        );
    }

    @isTest(seeAllData=false)
    public static void JobHandler_createTechnicalReviewCase_JobsWithMultipleOrders() {
        admin_ref_variable__mdt largeOrderAmountRecord = [
            SELECT number_ref_Value__c
            FROM admin_ref_variable__mdt
            WHERE label = 'LargeOrderAmount'
        ][0];
        Double largeOrderAmount = largeOrderAmountRecord.number_ref_Value__c;

        List<Order_ERP__c> smallOrderList = new List<Order_ERP__c>();
        Order_ERP__C testSmallOrder = new Order_ERP__C();
        testSmallOrder.Xometry_ERP_ID__c = 'AAAAA-12345';
        testSmallOrder.Account_Domain__c = 'pizzamakers.com';
        testSmallOrder.ERP_Company_Name__C = 'Ninja Pizza';
        testSmallOrder.ERP_Contact_First_Name__c = 'Hamato';
        testSmallOrder.ERP_Contact_Last_Name__c = 'Yoshi';
        testSmallOrder.ERP_Contact__C = 'AAAAA';
        testSmallOrder.ERP_PartPk__c = '56564-55667';
        testSmallOrder.Is_Generic__c = false;
        testSmallOrder.Order_Canceled_Flag__c = false;
        testSmallOrder.Order_ERP_CreatedDate__c = System.today();
        testSmallOrder.Order_ERP_Time__c = dateTime.now();
        testSmallOrder.Order_Email__c = 'splinterspizza@pizzamakers.com';
        testSmallOrder.Order_Subtotal__c = largeOrderAmount - 1;
        testSmallOrder.Order_Total__c = largeOrderAmount - 1;
        testSmallOrder.AllOrdersTotal__c = largeOrderAmount - 1;
        testSmallOrder.Payment_Type__c = 'credit_card';
        testSmallOrder.process_isPolyJet_3D__c = true;
        smallOrderList.add(testSmallOrder);

        Map<String, Ops_Order__C> testOpsOrders = TestDataFactory.createLargeOrderTestData(1, 1, 2, smallOrderList);
        String testXomJobID = '';
        ID sfJOBIDResult;
        System.debug('Before Test Start Test so in out Section');
        System.debug('Before test section' + Limits.getQueries());
        Test.startTest();
        List<Job__c> createdJobList = [SELECT id, OrderID__c, XometryOpsOrderID__c, XometryJobID__c FROM Job__c];

        Job__c largeOrderJob = new Job__c();
        largeOrderJob.Id = createdJobList[0].Id;
        largeOrderJob.RiskFactor__c = 'High';
        largeOrderJob.AcceptedPartnerID__c = 'P12345';

        Job__c multipleOrderJob = new Job__c();
        multipleOrderJob.Id = createdJobList[1].Id;
        multipleOrderJob.RiskFactor__c = 'High';
        multipleOrderJob.AcceptedPartnerID__c = 'P12345';
        multipleOrderJob.Order_IDs_String__c =
            testSmallOrder.Xometry_ERP_ID__c +
            ';' +
            createdJobList[1].XometryOpsOrderID__c;
        update new List<Job__c>{ largeOrderJob, multipleOrderJob };
        sfJOBIDResult = createdJobList[1].ID;
        testXomJobID = createdJobList[1].XometryJobID__c;
        Test.stopTest();

        System.debug('Finished Test Stop Test so in out Section');
        System.debug('Before assertion queries we are at ' + Limits.getQueries());
        List<Case> techReviewCasesCreated = [
            SELECT Id, Status, Type, ShadowXometryJobID__c, Job__c
            FROM Case
            WHERE Type = 'Technical Review' AND Job__c IN (:largeOrderJob.Id, :multipleOrderJob.Id)
        ];

        System.assertEquals(
            2,
            techReviewCasesCreated.size(),
            'The incorrect number of high risk tech review cases were created'
        );
        for (Case techReviewCase : techReviewCasesCreated) {
            if (techReviewCase.ShadowXometryJobID__c == testXomJobID) {
                System.assertEquals(
                    sfJOBIDResult,
                    techReviewCase.Job__c,
                    'The incorrect order was associated to the tech review case'
                );
            }
        }
    }

    @isTest
    static void jobOrderedPartJunction_Insert() {
        List<Ordered_Part__c> newOrderedPartsList = new List<Ordered_Part__c>();
        List<String> orderedPartIds = new List<String>();
        for (Integer i = 0; i < 4; i++) {
            Ordered_Part__C op = new Ordered_Part__C();
            op.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgt' + i;
            op.Xometry_Ordered_Part_ID__c = '12322AB';
            newOrderedPartsList.add(op);
            orderedPartIds.add(op.Unique_Ordered_Part_ID__c);
        }

        insert newOrderedPartsList;

        List<Job__c> newJobList = new List<Job__c>();
        for (Integer i = 0; i < 2; i++) {
            Job__c j = new Job__c();
            j.Name = 'J32103' + String.valueOf(i);
            j.XometryJobID__c = 'J32103' + String.valueOf(i);
            j.Stage__c = 'Accepted';
            j.ORDERED_PART_Ids_String__c = String.join(orderedPartIds, ';');
            newJobList.add(j);
        }

        Test.startTest();
        insert newJobList;
        Test.stopTest();

        List<JobOrderedPart__c> jopRes = [SELECT Id, JobId__c, OrderedPartId__c FROM JobOrderedPart__c];
        System.assertEquals(8, jopRes.size(), 'The Ordered part size was incorrect');
    }

    @isTest
    static void jobOrderedPartJunction_Update() {
        List<Ordered_Part__c> newOrderedPartsList = new List<Ordered_Part__c>();
        List<String> orderedPartIds = new List<String>();
        for (Integer i = 0; i < 4; i++) {
            Ordered_Part__C op = new Ordered_Part__C();
            op.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgt' + i;
            op.Xometry_Ordered_Part_ID__c = '12322AB';
            newOrderedPartsList.add(op);
            orderedPartIds.add(op.Unique_Ordered_Part_ID__c);
        }

        insert newOrderedPartsList;

        List<Job__c> newJobList = new List<Job__c>();
        for (Integer i = 0; i < 3; i++) {
            Job__c j = new Job__c();
            j.Name = 'J32103' + String.valueOf(i);
            j.XometryJobID__c = 'J32103' + String.valueOf(i);
            if (i < 1) {
                j.Stage__c = 'Accepted';
            }
            if (i >= 1) {
                j.Stage__c = 'Offered';
            }
            j.ORDERED_PART_Ids_String__c = String.join(orderedPartIds, ';');
            newJobList.add(j);
        }

        insert newJobList;

        Test.startTest();
        newJobList[1].Stage__c = 'Accepted';
        newJobList[2].Stage__c = 'Accepted';
        update newJobList;
        Test.stopTest();

        List<JobOrderedPart__c> jopRes = [SELECT Id, name FROM JobOrderedPart__c];
        System.assertEquals(12, jopRes.size(), 'The Ordered part size was incorrect');
    }

    @isTest
    static void jobOrderedPartJunctionNoOrderedParts_Insert() {
        List<Ordered_Part__c> newOrderedPartsList = new List<Ordered_Part__c>();
        List<String> orderedPartIds = new List<String>();
        for (Integer i = 0; i < 4; i++) {
            Ordered_Part__C op = new Ordered_Part__C();
            op.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgt' + i;
            op.Xometry_Ordered_Part_ID__c = '12322AB' + i;
            orderedPartIds.add(op.Unique_Ordered_Part_ID__c);
            if (i < 3) {
                newOrderedPartsList.add(op);
            }
        }

        insert newOrderedPartsList;

        List<Job__c> newJobList = new List<Job__c>();
        for (Integer i = 0; i < 2; i++) {
            Job__c j = new Job__c();
            j.Name = 'J32103' + String.valueOf(i);
            j.XometryJobID__c = 'J32103' + String.valueOf(i);
            j.Stage__c = 'Accepted';
            j.ORDERED_PART_Ids_String__c = String.join(orderedPartIds, ';');
            j.XometryOpsOrderID__c = 'BBBBB-18000';
            newJobList.add(j);
        }

        Test.startTest();
        insert newJobList;
        Test.stopTest();

        List<JobOrderedPart__c> jopRes = [SELECT Id, JobId__c, OrderedPartId__c FROM JobOrderedPart__c];
        System.assertEquals(8, jopRes.size(), 'The Ordered part size was incorrect');

        JobOrderedPart__c jopFromShell = [
            SELECT Id, JobId__c, OrderedPartId__c
            FROM JobOrderedPart__c
            WHERE ERPOrderedPartId__c = :orderedPartIds[3] AND ERPJobId__c = :newJobList[1].XometryJobID__c
        ];
        System.assertNotEquals(null, jopFromShell.OrderedPartId__c, 'The lookup should be populated');

        Ordered_Part__c orderPartShell = [
            SELECT Id, Unique_Ordered_Part_ID__c, Ops_Order__c, Ops_Order__r.XometryOpsOrderID__c, Ops_Order__r.Name
            FROM Ordered_Part__c
            WHERE Unique_Ordered_Part_ID__c = :orderedPartIds[3]
        ];
        System.assertEquals(
            newJobList[1].XometryOpsOrderId__c,
            orderPartShell.Ops_Order__r.XometryOpsOrderID__c,
            'New ops order should match job order'
        );
    }

    @isTest
    static void expiredJobLargeOrdTest() {
        //Create a Large Order
        // Update the Job
        Map<String, Ops_Order__c> opsOrderMap = TestDataFactory.createLargeOpsOrderTestData(
            1,
            0,
            0,
            new List<Ops_Order__c>()
        );
        test.startTest();
        List<Job__c> jobsInserted = TestDataFactory.createJobsForLargeOrders(false, 2, opsOrderMap.values());
        Job__c testJob = [
            SELECT ID, XometryJobID__c, RiskFactor__c, Stage__c, XometryOpsOrderID__c, Technical_review_Status__c
            FROM Job__c
            WHERE RiskFactor__c = 'High' AND OrderID__r.Is_Large_Order__c = TRUE
        ][0];
        ID testJobSFID = testJob.ID;
        System.debug('Here is the test Job');
        System.debug(testJob);
        System.debug('Here is the Job tech review : ' + testJob.Technical_review_Status__c);
        //System.assertEquals('Pending Technical Review', testJob.Technical_review_Status__c,'The Job was not setup properly');
        List<Case> testCasePreList = [
            SELECT
                ID,
                Job__c,
                ShadowXometryJobID__c,
                isClosed,
                Status,
                Technical_Review_Status__c,
                Cancellation_Reason__c
            FROM Case
            WHERE RecordTypeId = :AppConstants.caseManagementRTypeId AND Type = 'Technical Review'
        ];
        System.debug('Here is the case');
        System.debug(testCasePreList);
        case testCasePre = testCasePreList[0];
        //System.assertEquals('Pending Technical Review', testCasePre.Technical_Review_Status__c);
        ID testCaseID = testCasePre.ID;
        testJob.Stage__c = 'Expired';
        system.debug('STARTINGTHEUPDATE!!!!!!!!!!!!!!!!!');
        update testJob;
        test.stopTest();

        Case testCasePost = [
            SELECT
                ID,
                Job__c,
                ShadowXometryJobID__c,
                isClosed,
                Status,
                Technical_Review_Status__c,
                Cancellation_Reason__c
            FROM Case
            WHERE ID = :testCaseID
        ];
        //Confirm all values are updated on the Case and Job
        System.assertEquals('Closed', testCasePost.Status, 'The case was not closed');
        System.assertEquals(
            'Large Order Review Complete',
            testCasePost.Technical_Review_Status__c,
            'The case Tech Review Status was not updated'
        );
        System.assertEquals(
            'Automation',
            testCasePost.Cancellation_Reason__c,
            'The case Cancellation Reason was not updated'
        );
        Job__c testJobPost = [
            SELECT ID, XometryJobID__c, Technical_review_Status__c, DFM_Complete__c
            FROM Job__c
            WHERE ID = :testJobSFID
        ];
        System.debug('Final Assertion');
        System.debug(testJobPost);
        System.assertEquals(
            'No Technical Review Required',
            testJobPost.Technical_review_Status__c,
            'The Tech Review Status was updated'
        );
    }

    @isTest(seeAllData=false)
    public static void JobHandler_setOverdueFlagTest() {
        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = '01234-67890';
        j.DueDate__c = System.today() - 7;

        Test.startTest();
        insert j;
        Test.stopTest();

        Job__c testJob = [SELECT Id, Job_OverDue_Flag__c FROM Job__c WHERE XometryJobID__c = :j.XometryJobID__c];

        System.assertNotEquals(null, testJob.Job_OverDue_Flag__c, 'Job should be updated with overdue countdown');
    }

    @isTest
    public static void createJobEvent_basicInsertTest() {
        List<Job__c> insertList = TestDataFactory.createJobsWithSupplier(true);

        String jobID = 'J0012345';

        Event_Threshold__mdt additiveQualAmount = [
            SELECT ID, DeveloperName, Currency_Ref_Value__c
            FROM Event_Threshold__mdt
            WHERE DeveloperName = 'additiveJob_EventQualAmount'
        ];

        Job__c j = insertList[0];
        j.XometryJobID__c = jobID;

        j.Order_IDs_String__c = '00000-00001;00000-00002';
        j.XometryOpsOrderID__c = '1234';
        //Event: New ECD
        j.EstimatedCompletionDate__c = date.newInstance(2022, 11, 11);
        //Critieria: Additive Only and over the Qualifying Amount
        j.processGroup_isAdditiveOnly__c = true;
        j.AcceptedPrice__c = additiveQualAmount.Currency_Ref_Value__c + 1;

        Test.startTest();
        insert j;
        Test.stopTest();

        ID jobRecordID = j.ID;

        List<Job_Event__c> jobEventList = new List<Job_Event__c>(
            [SELECT ID, JobID__c, Job__c, Type__c FROM Job_Event__c WHERE Job__c = :jobRecordID]
        );
        System.assertEquals(2, jobEventList.size(), 'The incorrect number of Job events were created');

        Set<String> jobEventTypeSet = new Set<String>();
        Set<String> orderEventTypeSet = new Set<String>();
        Set<String> orderQualObjectSet = new Set<String>();

        for (Job_Event__c je : jobEventList) {
            jobEventTypeSet.add(je.Type__c);
        }

        List<Order_Event__c> orderEventList = new List<Order_Event__c>(
            [SELECT ID, Type__c, Qualifying_Object__c FROM Order_Event__c]
        );
        System.assertEquals(6, orderEventList.size(), 'The incorrect number of Order Events were created');

        for (Order_Event__c oe : orderEventList) {
            orderEventTypeSet.add(oe.Type__c);
            orderQualObjectSet.add(oe.Qualifying_Object__c);
        }

        System.assertEquals(
            jobEventTypeSet,
            orderEventTypeSet,
            'The Job Event Types and Order Event Types do not match'
        );

        System.assertEquals(
            1,
            orderQualObjectSet.size(),
            'At last one Order Event has the incorrect qualifying object'
        );
    }

    @isTest
    public static void createJobEvent_basicUpdateTest() {
        Id currentUserId = UserInfo.getUserId();

        Supplier__c s = new Supplier__c();
        s.PartnerID__c = 'P-Test';
        s.SupplierCompanyName__c = 'P-Test';
        s.EmailAddress__c = 'email@tester.com';
        s.LastName__c = 'Supplier';
        s.SPOC_Supplier__c = false;
        insert s;

        String jobID = 'J0012345';
        Job__c newJob = new Job__c();
        newJob.XometryJobID__c = jobID;
        newJob.Order_IDs_String__c = '00000-00001';
        newJob.XometryOpsOrderID__c = '1234';
        newJob.Supplier__c = s.ID;
        insert newJob;

        Test.startTest();
        s.SPOC_Supplier__c = true;
        s.SPOC_Owner__c = currentUserId;
        update s;
        Test.stopTest();

        ID jobRecordID = newJob.ID;
        Job__c resultJob = [SELECT ID, SPOC_Owner__c, Accepted_by_SPOC_Supplier__c FROM Job__c WHERE ID = :jobRecordID];

        System.assertNotEquals(null, resultJob.Accepted_by_SPOC_Supplier__c, 'The SPOC Supplier flag was not updated');
        System.assertEquals(currentUserId, resultJob.SPOC_Owner__c, 'The SPOC Owner was not updated correctly');

        List<Job_Event__c> jobEventList = new List<Job_Event__c>(
            [SELECT ID, JobID__c, Job__c, Type__c FROM Job_Event__c WHERE Job__c = :jobRecordID]
        );
        System.assertEquals(1, jobEventList.size(), 'The incorrect number of Job events were created');

        Set<String> jobEventTypeSet = new Set<String>();
        Set<String> orderEventTypeSet = new Set<String>();
        Set<String> orderQualObjectSet = new Set<String>();

        for (Job_Event__c je : jobEventList) {
            jobEventTypeSet.add(je.Type__c);
        }

        List<Order_Event__c> orderEventList = new List<Order_Event__c>(
            [SELECT ID, Type__c, Qualifying_Object__c FROM Order_Event__c]
        );
        System.assertEquals(2, orderEventList.size(), 'The incorrect number of Order Events were created');

        for (Order_Event__c oe : orderEventList) {
            orderEventTypeSet.add(oe.Type__c);
            orderQualObjectSet.add(oe.Qualifying_Object__c);
        }

        System.assertEquals(
            jobEventTypeSet,
            orderEventTypeSet,
            'The Job Event Types and Order Event Types do not match'
        );

        System.assertEquals(
            1,
            orderQualObjectSet.size(),
            'At last one Order Event has the incorrect qualifying object'
        );
    }

    @isTest
    static void stampTopQualityFromAccount_Create() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(true);
        System.debug(
            [
                SELECT
                    Id,
                    XometryOpsOrderID__c,
                    Stage__c,
                    Is_Large_Order__c,
                    Opportunity__r.Account.OPS_Top_Quality_Customer__c
                FROM Ops_Order__c
            ]
        );
        System.debug(
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
        );
        Account acct = [SELECT Id, OPS_Top_Quality_Customer__c FROM Account];
        acct.OPS_Top_Quality_Customer__c = true;
        update acct;

        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = 'BBBBB-34567';
        Job__c j2 = new Job__c();
        j2.Name = 'Test-J2';
        j2.XometryJobID__c = 'TestJob2';
        j2.Order_IDs_String__c = '12345-67890;BBBBB-34567';
        Job__c j3 = new Job__c();
        j3.Name = 'Test-J3';
        j3.XometryJobID__c = 'TestJob3';
        j3.Order_IDs_String__c = '12345-06789;BBBBB-34590';

        Test.startTest();
        insert new List<Job__c>{ j, j2, j3 };
        Test.stopTest();

        for (Job__c job : [SELECT Id, Ops_TopQualityCustomer__c FROM Job__c]) {
            if (job.id == j.Id || job.id == j2.Id) {
                System.assertEquals(true, job.Ops_TopQualityCustomer__c, 'topQualityCustomer should be true');
            }
            if (job.Id == j3.Id) {
                System.assertEquals(false, job.Ops_TopQualityCustomer__c, 'topQualityCustomer should be false');
            }
        }
    }

    @isTest
    static void stampTopQualityFromAccount_Update() {
        Order_ERP__c ord = TestDataFactory.createDefaultOrderERP(true);
        System.debug(
            [
                SELECT
                    Id,
                    XometryOpsOrderID__c,
                    Stage__c,
                    Is_Large_Order__c,
                    Opportunity__r.Account.OPS_Top_Quality_Customer__c
                FROM Ops_Order__c
            ]
        );
        System.debug(
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
        );
        Account acct = [SELECT Id, OPS_Top_Quality_Customer__c FROM Account];
        acct.OPS_Top_Quality_Customer__c = true;
        update acct;

        Job__c j = new Job__c();
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.XometryOpsOrderID__c = 'BBBBB-34567';
        Job__c j2 = new Job__c();
        j2.Name = 'Test-J2';
        j2.XometryJobID__c = 'TestJob2';
        j2.Order_IDs_String__c = '12345-67890;BBBBB-34567';
        Job__c j3 = new Job__c();
        j3.Name = 'Test-J3';
        j3.XometryJobID__c = 'TestJob3';
        j3.Order_IDs_String__c = '12345-06789;BBBBB-34590';

        insert new List<Job__c>{ j, j2, j3 };

        Test.startTest();
        j3.Order_IDs_String__c = '12345-06789;BBBBB-34590;BBBBB-34567';
        update j3;
        Test.stopTest();

        for (Job__c job : [SELECT Id, XometryJobID__c, Ops_TopQualityCustomer__c FROM Job__c]) {
            System.assertEquals(
                true,
                job.Ops_TopQualityCustomer__c,
                job.XometryJobID__c + 'topQualityCustomer should be true'
            );
        }
    }

    @isTest
    static void updateSourcingCaseTest() {
        String firstXomJobID = 'J0000001';
        String secondXomJobID = 'J0000002';
        String opsOrderID = '00000-00001';

        Job__c j = new Job__c();
        j.XometryJobID__c = firstXomJobID;
        j.XometryOpsOrderID__c = opsOrderID;
        insert j;

        ID firstJobID = [SELECT ID FROM Job__c WHERE XometryJobID__c = :firstXomJobID LIMIT 1][0].Id;

        Case c = new Case();
        c.RecordTypeID = AppConstants.caseSourcingRTypeId;
        c.AcceptedJobID__c = firstXomJobID;
        c.Job__c = firstJobID;
        insert c;

        c.AcceptedJobID__c = secondXomJobID;
        update c;

        Job__c newJob = new Job__c();
        newJob.XometryJobID__c = secondXomJobID;
        newJob.XometryOpsOrderID__c = opsOrderID;

        Test.startTest();
        insert newJob;
        Test.stopTest();

        ID secondJobID = [SELECT ID FROM Job__c WHERE XOMETRYJOBID__C = :secondXomJobID][0].Id;
        Case resultCase = [SELECT ID, AcceptedJobID__c, Job__c FROM Case LIMIT 1][0];

        System.assertEquals(secondJobID, resultCase.Job__c, 'The old job is still associated to the case');
    }
}