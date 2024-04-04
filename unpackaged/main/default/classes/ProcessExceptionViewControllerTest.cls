@isTest
private class ProcessExceptionViewControllerTest {
    @isTest
    static void getProExcRelOrder_Test() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'Ops-Order';
        opsOrder.OrderTotal__c = 1;
        insert opsOrder;

        Job__c j = new Job__c();
        j.Stage__c = 'Accepted';
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.OrderDueDate__c = Date.today() + 7;
        j.ShippingService__C = 'Fedex';
        j.ShippingMethod__c = 'Two Day Air';
        j.XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c;
        insert j;

        Order_Event__c orderEvent = new Order_Event__c();
        orderEvent.Name = 'Test order Event 01';
        orderEvent.OrderID__c = opsOrder.XometryOpsOrderID__c;
        orderEvent.Ops_Order__c = opsOrder.Id;
        insert orderEvent;

        Job_Event__c jobEvent = new Job_Event__c();
        jobEvent.Name = 'Test job Event 01';
        jobEvent.JobID__c = j.XometryJobID__c;
        jobEvent.Job__c = j.Id;
        insert jobEvent;

        ProcessException objProc1 = new ProcessException();
        objProc1.AttachedToId = orderEvent.Id;
        objProc1.Message = 'Test 01';
        insert objProc1;

        ProcessException objProc3 = new ProcessException();
        objProc3.AttachedToId = jobEvent.Id;
        objProc3.Message = 'Test 03';
        insert objProc3;

        ProcessException objProc2 = new ProcessException();
        objProc2.AttachedToId = orderEvent.Id;
        objProc2.Message = 'Test 02';
        insert objProc2;

        Test.startTest();
            List<ProcessException> processExceptionsList = ProcessExceptionViewController.getAllProcessExceptions(opsOrder.Id);
        Test.stopTest();

        System.assertEquals(3, processExceptionsList.size(), 'Not all process Exceptions related to the order have been found');
        System.assertEquals(objProc2.Message, processExceptionsList[0].Message, 'Record is not the expected');
        System.assertEquals(objProc1.Message, processExceptionsList[1].Message, 'Record is not the expected');
        System.assertEquals(objProc3.Message, processExceptionsList[2].Message, 'Record is not the expected');
    }

    @isTest
    static void getProExcRelOrderMass_Test() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'Ops-Order';
        opsOrder.OrderTotal__c = 1;
        opsOrder.pod__c = 'Automotive';
        insert opsOrder;

        Job__c j = new Job__c();
        j.Stage__c = 'Accepted';
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.OrderDueDate__c = Date.today() + 7;
        j.ShippingService__C = 'Fedex';
        j.ShippingMethod__c = 'Two Day Air';
        j.XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c;
        insert j;

        List<Order_Event__c> lstOrderEvents = new List<Order_Event__c>();
        List<Job_Event__c> lstJobEvents = new List<Job_Event__c>();
        for(Integer i = 0; i < 50 ; i++)
        {
            Order_Event__c orderEvent = new Order_Event__c();
            orderEvent.Name = 'Test order Event '+i;
            orderEvent.OrderID__c = opsOrder.XometryOpsOrderID__c;
            orderEvent.Ops_Order__c = opsOrder.Id;
            orderEvent.Qualifying_Object__c = 'Part';
            orderEvent.Type__c = 'Late Bad Outcome';
            lstOrderEvents.add(orderEvent);
            
            Job_Event__c jobEvent = new Job_Event__c();
            jobEvent.Name = 'Test job Event '+i;
            jobEvent.JobID__c = j.XometryJobID__c;
            jobEvent.Job__c = j.Id;
            jobEvent.Qualifying_Object__c = 'Part';
            jobEvent.Type__c = 'Late Bad Outcome';
            lstJobEvents.add(jobEvent);
        }

        insert lstOrderEvents;
        insert lstJobEvents;

        Test.startTest();
            List<ProcessException> processExceptionsList = ProcessExceptionViewController.getAllProcessExceptions(opsOrder.Id);
        Test.stopTest();

        System.assertEquals(100, processExceptionsList.size(), 'Not all process Exceptions related to the order have been found');
    }

    @isTest    
    static void getProExcRelJob_Test() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'Ops-Order';
        opsOrder.OrderTotal__c = 1;
        insert opsOrder;

        Job__c j = new Job__c();
        j.Stage__c = 'Accepted';
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.OrderDueDate__c = Date.today() + 7;
        j.ShippingService__C = 'Fedex';
        j.ShippingMethod__c = 'Two Day Air';
        j.XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c;
        insert j;

        Order_Event__c orderEvent = new Order_Event__c();
        orderEvent.Name = 'Test order Event 01';
        orderEvent.OrderID__c = opsOrder.XometryOpsOrderID__c;
        orderEvent.Ops_Order__c = opsOrder.Id;
        insert orderEvent;

        Job_Event__c jobEvent = new Job_Event__c();
        jobEvent.Name = 'Test job Event 01';
        jobEvent.JobID__c = j.XometryJobID__c;
        jobEvent.Job__c = j.Id;
        insert jobEvent;

        ProcessException objProc1 = new ProcessException();
        objProc1.AttachedToId = orderEvent.Id;
        objProc1.Message = 'Test 01';
        insert objProc1;

        ProcessException objProc2 = new ProcessException();
        objProc2.AttachedToId = orderEvent.Id;
        objProc2.Message = 'Test 02';
        insert objProc2;

        ProcessException objProc3 = new ProcessException();
        objProc3.AttachedToId = jobEvent.Id;
        objProc3.Message = 'Test 03';
        insert objProc3;

        Test.startTest();
            List<ProcessException> processExceptionsList = ProcessExceptionViewController.getAllProcessExceptions(j.Id);
        Test.stopTest();

        System.assertEquals(1, processExceptionsList.size(), 'Not all process Exceptions related to the Job have been found');
        System.assertEquals(objProc3.Message, processExceptionsList[0].Message, 'Record is not the expected');
    }

    @isTest
    static void getOrderInfo_Test() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'Ops-Order';
        opsOrder.OrderTotal__c = 1;
        insert opsOrder;

        Test.startTest();
            Ops_Order__c orderReturn = ProcessExceptionViewController.getOpsOrderInfo(opsOrder.Id);
        Test.stopTest();

        System.assertEquals(opsOrder.POD__c, orderReturn.POD__c, 'Not match the pod of the ops order');
    }

    @isTest
    static void getOrderInfoFromJob_Test() {
        Ops_Order__c opsOrder = new Ops_Order__c();
        opsOrder.POD__c = 'First Impressions';
        opsOrder.XometryOpsOrderID__c = 'Ops-Order';
        opsOrder.OrderTotal__c = 1;
        insert opsOrder;

        Job__c j = new Job__c();
        j.Stage__c = 'Accepted';
        j.Name = 'Test-Job';
        j.XometryJobID__c = 'Test-Job';
        j.OrderDueDate__c = Date.today() + 7;
        j.ShippingService__C = 'Fedex';
        j.ShippingMethod__c = 'Two Day Air';
        j.XometryOpsOrderID__c = opsOrder.XometryOpsOrderID__c;
        insert j;

        Test.startTest();
            Ops_Order__c orderReturn = ProcessExceptionViewController.getOpsOrderInfo(j.Id);
        Test.stopTest();

        System.assertEquals(opsOrder.POD__c, orderReturn.POD__c, 'Not match the pod of the ops order');
    }
}