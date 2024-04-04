@isTest
private class acctFYHierarchyCalcTest {
    @TestSetup
    private static void setup() {

        Map<String,Account> myTestAccountMap = TestDataFactory.createTestAccountHierarchy();
        System.debug('Past the Test Data Factory');

        Account lDragonKeepers = myTestAccountMap.get('Dragon Keepers');
        Account lHellkite = myTestAccountMap.get('HellKite Dragons');
        Account lFireball = myTestAccountMap.get('Fireball Dragons');

        Integer thisYear = Date.today().year();
        List<SObject> testOrderList = new List<SObject>();

        Order_ERP__C order = TestDataFactory.createOrderERP(
            false,
            'Q00-00-0000',
            'AAAAC-00123',
            lFireball.Email_Domain__C,
            lFireball.Name,
            'amyadam@' + lFireball.Email_Domain__C,
            true,
            false
        );
        order.ERP_PartPk__c = '44444-555123';
        order.Order_ERP_CreatedDate__c = Date.newInstance(thisYear - 2, 12, 5);
        order.Order_ERP_Time__c = Datetime.newInstanceGMT(thisYear - 2, 12, 5, 18, 0, 0);
        testOrderList.add(order);

        Order_ERP__C order1 = TestDataFactory.createOrderERP(
            false,
            'Q11-1111-1111',
            'AAAAB-00001',
            lDragonKeepers.Email_Domain__C,
            lDragonKeepers.Name,
            'amyadam@' + lDragonKeepers.Email_Domain__C,
            true,
            false
        );
        order1.ERP_Contact__c = 'AAAAB';
        order1.Order_ERP_CreatedDate__c = date.newInstance(thisYear - 2, 11, 5);
        order1.Order_ERP_Time__c = datetime.newInstanceGMT(thisYear - 2, 11, 5, 18, 0, 0);
        testOrderList.add(order1);

        Order_ERP__C order2 = TestDataFactory.createOrderERP(
            false,
            'Q22-2222-2222',
            'AAAAB-00002',
            lDragonKeepers.Email_Domain__C,
            lDragonKeepers.Name,
            'amyadam@' + lDragonKeepers.Email_Domain__C,
            true,
            false
        );
        order2.ERP_Contact__c = 'AAAAB';
        order2.Order_ERP_CreatedDate__c = date.newInstance(thisYear - 2, 11, 5);
        order2.Order_ERP_Time__c = datetime.newInstanceGMT(thisYear - 2, 11, 5, 18, 0, 0);
        testOrderList.add(order2);

        Order_ERP__C order3 = TestDataFactory.createOrderERP(
            false,
            'Q33-3333-3333',
            'AAAAC-00001',
            lFireball.Email_Domain__C,
            lFireball.Name,
            'amyadam@' + lFireball.Email_Domain__C,
            true,
            false
        );
        testOrderList.add(order3);

        Order_ERP__C order4 = TestDataFactory.createOrderERP(
            false,
            'Q44-4444-4444',
            'AAAAC-00002',
            lFireball.Email_Domain__C,
            lFireball.Name,
            'amyadam@' + lFireball.Email_Domain__C,
            true,
            false
        );
        testOrderList.add(order4);

        Order_ERP__C order5 = TestDataFactory.createOrderERP(
            false,
            'Q55-5555-5555',
            'AAAAD-00001',
            lHellkite.Email_Domain__C,
            lHellkite.Name,
            'amyadam@' + lHellkite.Email_Domain__C,
            true,
            false
        );
        order5.ERP_Contact__c = 'AAAAD';
        order5.Order_ERP_CreatedDate__c = date.newInstance(thisYear - 1, 12, 6);
        order5.Order_ERP_Time__c = datetime.newInstanceGMT(thisYear - 1, 12, 6, 18, 0, 0);
        order5.Order_Subtotal__c = 950.00;
        order5.Order_Total__c = 1000.00;
        testOrderList.add(order5);

        // This year
        Order_ERP__C order6 = TestDataFactory.createOrderERP(
            false,
            'Q66-6666-6666',
            'AAAAB-00003',
            lDragonKeepers.Email_Domain__C,
            lDragonKeepers.Name,
            'amyadam@' + lDragonKeepers.Email_Domain__C,
            true,
            false
        );
        order6.ERP_Contact__c = 'AAAAB';
        order6.Order_ERP_CreatedDate__c = date.newInstance(thisYear, 11, 5);
        order6.Order_ERP_Time__c = datetime.newInstanceGMT(thisYear, 11, 5, 18, 0, 0);
        testOrderList.add(order6);

        Order_ERP__C order7 = TestDataFactory.createOrderERP(
            false,
            'Q77-7777-7777',
            'AAAAC-00004',
            lFireball.Email_Domain__C,
            lFireball.Name,
            'amyadam@' + lFireball.Email_Domain__C,
            true,
            false
        );
        order7.Order_ERP_CreatedDate__c = date.newInstance(thisYear, 12, 5);
        order7.Order_ERP_Time__c = datetime.newInstanceGMT(thisYear, 12, 5, 18, 0, 0);
        testOrderList.add(order7);

        Order_ERP__C order8 = TestDataFactory.createOrderERP(
            false,
            'Q88-8888-8888',
            'AAAAD-00005',
            lHellkite.Email_Domain__C,
            lHellkite.Name,
            'amyadam@' + lHellkite.Email_Domain__C,
            true,
            false
        );
        order8.ERP_Contact__c = 'AAAAD';
        order8.Order_ERP_CreatedDate__c = date.newInstance(thisYear, 12, 6);
        order8.Order_ERP_Time__c = datetime.newInstanceGMT(thisYear, 12, 6, 18, 0, 0);
        order8.Order_Subtotal__c = 950.00;
        order8.Order_Total__c = 1000.00;
        testOrderList.add(order8);
        // insert testOrderList;

        Date dtthisYear = Date.today();
        Date lastYear = Date.today().addYears(-1);
        Date yearBeforeLast = Date.today().addYears(-2);
        Datetime thisYearDatetime = Datetime.now();
        Datetime lastYearDatetime = Datetime.now().addYears(-1);
        Datetime yearBeforeLastDatetime = Datetime.now().addYears(-2);
        List<Supplies_Quote__C> lstSuppliesQuote = new List<Supplies_Quote__C>();
        Supplies_Quote__C sQuoteTest = TestDataFactory.createSuppliesQuote(
            false,
            'amyadam@' + lDragonKeepers.Email_Domain__C,
            lDragonKeepers.Email_Domain__C,
            'Amy',
            'Adams',
            dtthisYear,
            thisYearDateTime
        );
        sQuoteTest.P21_Order_OE_ERP_ID__C = 'AAAAD-00001';
        Supplies_Quote__C sQuoteTest2 = TestDataFactory.createSuppliesQuote(
            false,
            'amyadam@' + lFireball.Email_Domain__C,
            lFireball.Email_Domain__C,
            'Amy',
            'Adams',
            dtthisYear,
            thisYearDateTime
        );
        sQuoteTest2.P21_ERP_ID__c = 'OE23478';
        sQuoteTest2.P21_Order_OE_ERP_ID__C = 'AAAAD-00002';
        Supplies_Quote__C sQuoteTest3 = TestDataFactory.createSuppliesQuote(
            false,
            'amyadam@' + lDragonKeepers.Email_Domain__C,
            lDragonKeepers.Email_Domain__C,
            'Amy',
            'Adams',
            lastYear,
            lastYearDateTime
        );
        sQuoteTest3.P21_ERP_ID__c = 'OE23479';
        sQuoteTest3.P21_Order_OE_ERP_ID__C = 'AAAAD-00003';
        Supplies_Quote__C sQuoteTest4 = TestDataFactory.createSuppliesQuote(
            false,
            'amyadam@' + lFireball.Email_Domain__C,
            lFireball.Email_Domain__C,
            'Amy',
            'Adams',
            lastYear,
            lastYearDateTime
        );
        sQuoteTest4.P21_ERP_ID__c = 'OE23480';
        sQuoteTest4.P21_Order_OE_ERP_ID__C = 'AAAAD-00004';
        Supplies_Quote__C sQuoteTest5 = TestDataFactory.createSuppliesQuote(
            false,
            'amyadam@' + lDragonKeepers.Email_Domain__C,
            lDragonKeepers.Email_Domain__C,
            'Amy',
            'Adams',
            yearBeforeLast,
            yearBeforeLastDateTime
        );
        sQuoteTest5.P21_ERP_ID__c = 'OE23481';
        sQuoteTest5.P21_Order_OE_ERP_ID__C = 'AAAAD-00005';
        Supplies_Quote__C sQuoteTest6 = TestDataFactory.createSuppliesQuote(
            false,
            'amyadam@' + lFireball.Email_Domain__C,
            lFireball.Email_Domain__C,
            'Amy',
            'Adams',
            yearBeforeLast,
            yearBeforeLastDateTime
        );
        sQuoteTest6.P21_ERP_ID__c = 'OE23482';
        sQuoteTest6.P21_Order_OE_ERP_ID__C = 'AAAAD-00006';

        testOrderList.add(sQuoteTest);
        testOrderList.add(sQuoteTest2);
        testOrderList.add(sQuoteTest3);
        testOrderList.add(sQuoteTest4);
        testOrderList.add(sQuoteTest5);
        testOrderList.add(sQuoteTest6);
        insert testOrderList;

        ID oppSupplierRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Supplies')
            .getRecordTypeID();
        List<Opportunity> lstOpp = [
            SELECT AccountId, CloseDate, StageName
            FROM Opportunity
            WHERE RecordTypeId = :oppSupplierRTypeID
        ];
        lstOpp[0].StageName = 'Closed Won';
        lstOpp[0].CloseDate = System.today();
        lstOpp[1].StageName = 'Closed Won';
        lstOpp[1].CloseDate = System.today();
        lstOpp[2].StageName = 'Closed Won';
        lstOpp[2].CloseDate = System.today().addYears(-1);
        lstOpp[3].StageName = 'Closed Won';
        lstOpp[3].CloseDate = System.today().addYears(-1);
        lstOpp[4].StageName = 'Closed Won';
        lstOpp[4].CloseDate = System.today().addYears(-2);
        lstOpp[5].StageName = 'Closed Won';
        lstOpp[5].CloseDate = System.today().addYears(-2);
        update lstOpp;

        //monthlyAcctAggReCalc batch = new monthlyAcctAggReCalc();
        //Database.executeBatch(batch);

        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>(myTestAccountMap.values());        
        monthlyAcctAggReCalc.calcOppRecords(accountsToUpdateMap);
        monthlyAcctAggReCalc.calcNumberOfContacts(accountsToUpdateMap);
        monthlyAcctAggReCalc.processRecords(accountsToUpdateMap);

    }

    @isTest(seeAllData=false)
    private static void acctFYHierarchyCalcTest() {

        Test.startTest();
        acctFYHierarchyCalc batch2 = new acctFYHierarchyCalc();
        Database.executeBatch(batch2);
        Test.stopTest();

        Account resultAccount = [
            SELECT
                This_Year_Corporate_Hierarchy_Spend__c,
                Last_Year_Corporate_Hierarchy_Spend__c,
                Year_Before_Last_Corp_Hierarchy_Spend__c,
                Corporate_Hierarchy_Lifetime_Spend__c,
                Corporate_Hierarchy_Lifetime_N_of_Orders__c
            FROM Account
            WHERE Hierarchy_Type__c = :'Corporate Parent'
            LIMIT 1
        ];
        System.assertEquals(
            2000,
            resultAccount.This_Year_Corporate_Hierarchy_Spend__c,
            'This_Year_Corporate_Hierarchy_Spend__c was wrong'
        );
        System.assertEquals(
            2000,
            resultAccount.Last_Year_Corporate_Hierarchy_Spend__c,
            'Last_Year_Corporate_Hierarchy_Spend__c was wrong'
        );
        System.assertEquals(
            1500,
            resultAccount.Year_Before_Last_Corp_Hierarchy_Spend__c,
            'Year_Before_Last_Corp_Hierarchy_Spend__c was wrong'
        );
        System.assertEquals(
            5500,
            resultAccount.Corporate_Hierarchy_Lifetime_Spend__c,
            'Corporate_Hierarchy_Lifetime_Spend__c was wrong'
        );
        System.assertEquals(
            9,
            resultAccount.Corporate_Hierarchy_Lifetime_N_of_Orders__c,
            'Corporate_Hierarchy_Lifetime_N_of_Orders__c was wrong'
        );

    }

}