@isTest
public class orderedPartHandlerTest {
    @isTest
    static void linkOrderedPartToOpsOrders() {
        //Create 4 OrderedParts
        // 2 OrderedParts belong to an Existing Ops Order
        // 2 OrderedParts need to have an Ops Order Created

        List<Ordered_Part__c> newOrderedPartsList = new List<Ordered_Part__c>();

        String xomOrder1Id = 'AAAA2-00004';
        String xomOrder2Id = 'AAAA2-00005';

        Ops_Order__c order1 = new Ops_Order__c();
        order1.name = xomOrder1Id;
        order1.XometryOpsOrderID__c = xomOrder1Id;
        insert order1;

        for (Integer i = 0; i < 4; i++) {
            Ordered_Part__C op = new Ordered_Part__C();
            op.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgt' + i;
            op.Xometry_Ordered_Part_ID__c = '12322AB' + i;
            if (i < 2) {
                op.Xometry_Order_ID__c = xomOrder1Id;
            } else {
                op.Xometry_Order_ID__c = xomOrder2Id;
            }
            newOrderedPartsList.add(op);
        }

        test.startTest();
        insert newOrderedPartsList;
        test.stopTest();

        List<Ordered_Part__c> orderedPartInsertList = [
            SELECT Id, Xometry_Order_ID__c, Ops_Order__c
            FROM Ordered_Part__C
        ];
        System.assertEquals(4, orderedPartInsertList.size(), 'There were not 4 ordered Parts');
        for (Ordered_Part__C op : orderedPartInsertList) {
            if (op.Xometry_Order_ID__c == xomOrder1Id) {
                System.assertEquals(order1.id, op.Ops_Order__c, 'The Ordered Part was linked to the wrong Ops Order');
            }
            if (op.Ops_Order__c == null) {
                System.assert(false, 'An Ordered Part did not get is Ops Order');
            }
        }
    }

    @isTest(seeAllData=false)
    static void fillProductTypesTest() {
        Case testCase = new Case();
        testCase.Category__c = 'End-use definition';
        testCase.ShadowXometryOrderID__c = 'AAAA2-00003';

        Case testCase2 = new Case();
        testCase2.Category__c = 'End-use definition';
        testCase2.ShadowXometryOrderID__c = 'AAAA2-00004';

        insert new List<Case>{ testCase, testCase2 };

        Ops_Order__c order1 = new Ops_Order__c();
        order1.name = 'AAAA2-00003';
        order1.XometryOpsOrderID__c = 'AAAA2-00003';

        Ops_Order__c order2 = new Ops_Order__c();
        order2.name = 'AAAA2-00004';
        order2.XometryOpsOrderID__c = 'AAAA2-00004';
        insert new List<Ops_Order__c>{ order1, order2 };

        Ordered_Part__c op = new Ordered_Part__c();
        op.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgt';
        op.Xometry_Ordered_Part_ID__c = '12322AB1';
        op.Xometry_Order_ID__c = 'AAAA2-00003';
        op.EUD_ProductionType__c = 'Prototype';

        Ordered_Part__c op2 = new Ordered_Part__c();
        op2.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgu';
        op2.Xometry_Ordered_Part_ID__c = '12322AB2';
        op2.Xometry_Order_ID__c = 'AAAA2-00003';
        op2.EUD_ProductionType__c = 'Production';

        Ordered_Part__c op3 = new Ordered_Part__c();
        op3.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgv';
        op3.Xometry_Ordered_Part_ID__c = '12322AB3';
        op3.Xometry_Order_ID__c = 'AAAA2-00004';
        op3.EUD_ProductionType__c = 'Prototype';

        Ordered_Part__c op4 = new Ordered_Part__c();
        op4.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgw';
        op4.Xometry_Ordered_Part_ID__c = '12322AB4';
        op4.Xometry_Order_ID__c = 'AAAA2-00004';
        op4.EUD_ProductionType__c = 'Prototype';

        test.startTest();
        insert new List<Ordered_Part__c>{ op, op2, op3, op4 };
        test.stopTest();

        Map<Id, Case> testResult = new Map<Id, Case>([SELECT EUD_ProductionType__c FROM Case]);
        System.assertEquals('Production, Prototype', testResult.get(testCase.Id).EUD_ProductionType__c);
        System.assertEquals('Prototype', testResult.get(testCase2.Id).EUD_ProductionType__c);
    }

    @isTest(seeAllData=false)
    static void fillProductTypesUpdateTest() {
        Case testCase = new Case();
        testCase.Category__c = 'End-use definition';
        testCase.ShadowXometryOrderID__c = 'AAAA2-00003';
        insert testCase;

        Ops_Order__c order1 = new Ops_Order__c();
        order1.name = 'AAAA2-00003';
        order1.XometryOpsOrderID__c = 'AAAA2-00003';
        insert order1;

        Ordered_Part__c op = new Ordered_Part__c();
        op.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgt';
        op.Xometry_Ordered_Part_ID__c = '12322AB1';
        op.Xometry_Order_ID__c = 'AAAA2-00003';
        op.EUD_ProductionType__c = 'Prototype';

        Map<Id, Case> testResult = new Map<Id, Case>([SELECT EUD_ProductionType__c FROM Case]);
        System.assertEquals(null, testResult.get(testCase.Id).EUD_ProductionType__c);

        insert op;

        testResult = new Map<Id, Case>([SELECT EUD_ProductionType__c FROM Case]);
        System.assertEquals('Prototype', testResult.get(testCase.Id).EUD_ProductionType__c);

        Ordered_Part__c op2 = new Ordered_Part__c();
        op2.Unique_Ordered_Part_ID__c = 'AAABBBCCaeidhgu';
        op2.Xometry_Ordered_Part_ID__c = '12322AB2';
        op2.Xometry_Order_ID__c = 'AAAA2-00003';
        op2.EUD_ProductionType__c = 'Production';

        test.startTest();
        insert op2;
        test.stopTest();

        testResult = new Map<Id, Case>([SELECT EUD_ProductionType__c FROM Case]);
        System.assertEquals('Production, Prototype', testResult.get(testCase.Id).EUD_ProductionType__c);
    }

    @isTest
    static void partExpiresOnInsert_noOpsOrder() {
        String xomOrderID = 'AAAA2-00001';

        Test.startTest();
        Ordered_Part__c part = TestDataFactory.createOrderedPart(true, 'All Offers Expired', xomOrderID, false, false);
        Test.stopTest();

        Ops_Order__c resultOpsOrder = [
            SELECT ID, ExpiredPart__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :xomOrderID
            LIMIT 1
        ][0];
        Ordered_Part__c resultPart = [
            SELECT ID, CurrentlyExpired__c
            FROM Ordered_Part__c
            WHERE Xometry_Order_ID__c = :xomOrderID
            LIMIT 1
        ][0];

        System.assertEquals(true, resultOpsOrder.ExpiredPart__c, 'The Ops Order was not updated when a part expired');
        System.assertEquals(
            true,
            resultPart.CurrentlyExpired__c,
            'CurrentlyExpired was not stamped once the part expired'
        );
    }

    @isTest
    static void partExpiresOnInsert_OpsOrderExists() {
        String xomOrderID = 'AAAA2-00001';

        Test.startTest();
        Ordered_Part__c part = TestDataFactory.createOrderedPart(true, 'All Offers Expired', xomOrderID, true, true);
        Test.stopTest();

        Ops_Order__c resultOpsOrder = [
            SELECT ID, ExpiredPart__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :xomOrderID
            LIMIT 1
        ][0];
        Ordered_Part__c resultPart = [
            SELECT ID, CurrentlyExpired__c
            FROM Ordered_Part__c
            WHERE Xometry_Order_ID__c = :xomOrderID
            LIMIT 1
        ][0];

        System.assertEquals(true, resultOpsOrder.ExpiredPart__c, 'The Ops Order was not updated when a part expired');
        System.assertEquals(
            true,
            resultPart.CurrentlyExpired__c,
            'CurrentlyExpired was not stamped once the part expired'
        );
    }

    @isTest
    static void partExpiresOnUpdate_OpsOrderExists() {
        String xomOrderID = 'AAAA2-00001';

        Ordered_Part__c part = TestDataFactory.createOrderedPart(true, 'Offers Made', xomOrderID, true, true);

        Test.startTest();
        part.PartStatus__c = 'All Offers Expired';
        update part;
        Test.stopTest();

        Ops_Order__c resultOpsOrder = [
            SELECT ID, ExpiredPart__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :xomOrderID
            LIMIT 1
        ][0];
        Ordered_Part__c resultPart = [
            SELECT ID, CurrentlyExpired__c
            FROM Ordered_Part__c
            WHERE Xometry_Order_ID__c = :xomOrderID
            LIMIT 1
        ][0];

        System.assertEquals(true, resultOpsOrder.ExpiredPart__c, 'The Ops Order was not updated when a part expired');
        System.assertEquals(
            true,
            resultPart.CurrentlyExpired__c,
            'CurrentlyExpired was not stamped once the part expired'
        );
    }

    @isTest
    static void partExpiresOnMissedETLUpdate_OpsOrderExists() {
        String xomOrderID = 'AAAA2-00001';

        Ordered_Part__c part = TestDataFactory.createOrderedPart(true, 'Offers Made', xomOrderID, true, true);

        Test.startTest();
        part.HasEverExpired__c = true;
        update part;
        Test.stopTest();

        Ops_Order__c resultOpsOrder = [
            SELECT ID, ExpiredPart__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :xomOrderID
            LIMIT 1
        ][0];
        Ordered_Part__c resultPart = [
            SELECT ID, CurrentlyExpired__c
            FROM Ordered_Part__c
            WHERE Xometry_Order_ID__c = :xomOrderID
            LIMIT 1
        ][0];

        System.assertEquals(
            true,
            resultOpsOrder.ExpiredPart__c,
            'The Ops Order was not updated when a part had expired but was missed in the ETL'
        );
        System.assertEquals(false, resultPart.CurrentlyExpired__c, 'The part should not be currently expired');
    }

    @isTest
    static void partIsNoLongerExpiredTest() {
        String xomOrderID = 'AAAA2-00001';

        Ordered_Part__c part = TestDataFactory.createOrderedPart(true, 'All Offers Expired', xomOrderID, true, true);

        Test.startTest();
        part.PartStatus__c = 'Offers Made';
        update part;
        Test.stopTest();

        Ops_Order__c resultOpsOrder = [
            SELECT ID, ExpiredPart__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c = :xomOrderID
            LIMIT 1
        ][0];
        Ordered_Part__c resultPart = [
            SELECT ID, CurrentlyExpired__c
            FROM Ordered_Part__c
            WHERE Xometry_Order_ID__c = :xomOrderID
            LIMIT 1
        ][0];

        System.assertEquals(
            true,
            resultOpsOrder.ExpiredPart__c,
            'The Ops Order was incorrectly updated when a previously expired part was resourced'
        );
        System.assertEquals(
            false,
            resultPart.CurrentlyExpired__c,
            'CurrentlyExpired was not updated once the part was resourced'
        );
    }

    @isTest
    static void eventConditionals_basicInsert_OrderOnly() {
        String xomOrderID = 'AAAA2-00001';

        Ordered_Part__c part = TestDataFactory.createOrderedPart(false, 'All Offers Expired', xomOrderID, true, true);
        part.Process__c = 'Die Casting';
        part.InspectionType__c = 'cust';

        Test.startTest();
        insert part;

        Test.stopTest();

        List<Ordered_Part_Event__c> opEventList = new List<Ordered_Part_Event__c>(
            [SELECT ID, Order_Event__c, Job_Event__c, Type__c FROM Ordered_Part_Event__c]
        );

        List<Order_Event__c> orderEventList = new List<Order_Event__c>(
            [SELECT ID, Ops_Order__c, Type__c, Qualifying_Object__c FROM Order_Event__c]
        );

        System.assertEquals(3, opEventList.size(), 'The incorrect number of Ordered Part Junction events were created');
        System.assertEquals(3, orderEventList.size(), 'The incorrect number of Order Events were created');

        for (Ordered_Part_Event__c opEvent : opEventList) {
            for (Integer i = 0; i < orderEventList.size(); i++) {
                if (opEvent.Type__c == orderEventList[i].Type__c) {
                    System.assertEquals(
                        orderEventList[i].ID,
                        opEvent.Order_Event__c,
                        'The Ordered Part Junction Event was associated to the wrong Order Event'
                    );
                }
            }
        }
    }

    @isTest
    static void eventConditionals_basicInsert_OrderAndJob() {
        String xomOrderID = 'AAAA2-00001';
        String xomJobID = 'J0012345';

        Job__c job = new Job__c();
        job.XometryOpsOrderID__c = xomOrderID;
        job.XometryJobID__c = xomJobID;
        insert job;

        Ordered_Part__c part = TestDataFactory.createOrderedPart(false, 'All Offers Expired', xomOrderID, true, false);
        part.Process__c = 'Die Casting';
        part.InspectionType__c = 'cust';
        part.CurrentJobID__c = xomJobID;

        Test.startTest();
        insert part;

        Test.stopTest();

        List<Ordered_Part_Event__c> opEventList = new List<Ordered_Part_Event__c>(
            [SELECT ID, Order_Event__c, Job_Event__c, Type__c FROM Ordered_Part_Event__c]
        );

        List<Order_Event__c> orderEventList = new List<Order_Event__c>(
            [SELECT ID, Ops_Order__c, Type__c FROM Order_Event__c]
        );

        List<Job_Event__c> jobEventList = new List<Job_Event__c>([SELECT ID, Job__c, Type__c FROM Job_Event__c]);

        System.assertEquals(3, opEventList.size(), 'The incorrect number of Ordered Part Junction events were created');
        System.assertEquals(3, orderEventList.size(), 'The incorrect number of Order Events were created');
        System.assertEquals(3, jobEventList.size(), 'The incorrect number of Job Events were created');

        for (Ordered_Part_Event__c opEvent : opEventList) {
            System.debug(opEvent);
            for (Integer i = 0; i < orderEventList.size(); i++) {
                if (opEvent.Type__c == orderEventList[i].Type__c) {
                    System.assertEquals(
                        orderEventList[i].ID,
                        opEvent.Order_Event__c,
                        'The Ordered Part Junction Event was associated to the wrong Order Event'
                    );
                }
            }
            for (Integer i = 0; i < jobEventList.size(); i++) {
                if (opEvent.Type__c == jobEventList[i].Type__c) {
                    System.assertEquals(
                        jobEventList[i].ID,
                        opEvent.Job_Event__c,
                        'The Ordered Part Junction Event was associated to the wrong Job Event'
                    );
                }
            }
        }
    }
}