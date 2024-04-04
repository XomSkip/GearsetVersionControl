@isTest
private class CaseOpportunityHandlerTest {
    @isTest(seeAllData=false)
    static void keepRelationsUpdatedTest() {
        Quote_ERP__c testQuote = new Quote_ERP__C(
            Account_Domain__C = 'SuperAccount',
            ERP_PartPK__c = 'A1234-A5678',
            Quote_Price__c = 50.15,
            Xometry_ERP_ID__C = 'Q01-0000-1111',
            ERP_Contact__c = 'AAAAA',
            IS_Generic__c = false,
            Quote_Email__c = 'johndoe@superaccount.com',
            Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14),
            Requested_Manual_Quote_Flag__c = true,
            Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0)
        );
        insert testQuote;

        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Id testOppId = [SELECT Id FROM Opportunity WHERE Quote_ERP_XOM_CREATE_ID__c = 'Q01-0000-1111' LIMIT 1].Id;

        Test.startTest();

        insert new CaseOpportunity__c(Case__c = caseId, Xometry_ERP_ID__c = 'Q01-0000-1111');

        Test.stopTest();

        CaseOpportunity__c caseOppAfter = [SELECT Opportunity__c FROM CaseOpportunity__c LIMIT 1];
        System.assertEquals(
            testOppId,
            caseOppAfter.Opportunity__c,
            'Junction should be linked to the Opp with the same ERP Id'
        );
    }

    @isTest(seeAllData=false)
    static void renameOnCreateTest() {
        Quote_ERP__c testQuote = new Quote_ERP__C(
            Account_Domain__C = 'SuperAccount',
            ERP_PartPK__c = 'A1234-A5678',
            Quote_Price__c = 50.15,
            Xometry_ERP_ID__C = 'Q01-0000-1111',
            ERP_Contact__c = 'AAAAA',
            IS_Generic__c = false,
            Quote_Email__c = 'johndoe@superaccount.com',
            Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14),
            Requested_Manual_Quote_Flag__c = true,
            Requested_Manual_Quote_Time__C = DateTime.newInstance(2021, 5, 21, 6, 0, 0)
        );
        insert testQuote;

        Case testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        Id testOppId = [SELECT Id FROM Opportunity WHERE Quote_ERP_XOM_CREATE_ID__c = 'Q01-0000-1111' LIMIT 1].Id;

        Test.startTest();

        insert new CaseOpportunity__c(Case__c = testCase.Id, Xometry_ERP_ID__c = 'Q01-0000-1111');

        Test.stopTest();

        System.assertEquals(
            testCase.CaseNumber +
            '-' +
            testQuote.Xometry_ERP_ID__C,
            [SELECT Name FROM CaseOpportunity__c LIMIT 1]
            .Name,
            'Junction should be renamed'
        );
    }

    @isTest(seeAllData=false)
    static void renameOnCreate2Test() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);
        insert opp;

        Case testCase = new Case(Opportunity__c = opp.Id);

        Test.startTest();
        insert testCase;
        Test.stopTest();

        testCase = [SELECT Id, CaseNumber FROM Case LIMIT 1];

        System.assertEquals(
            testCase.CaseNumber,
            [SELECT Name FROM CaseOpportunity__c LIMIT 1]
            .Name,
            'Junction should be renamed'
        );
    }

    @isTest(seeAllData=false)
    static void testKeepTotalFieldsCase() {
        List<Opportunity> lstOpportunities = new List<Opportunity>();
        List<Case> lstCases = new List<Case>();

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Closed Won';
        opp.Amount = 100;
        opp.LineItemCount__c = 2;
        opp.Total_Amt_BinderJetting__c = 200;
        opp.Total_Amt_Carbon__c = 300;
        opp.Total_Amt_CNC__c = 400;
        opp.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp);

        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test1';
        opp1.StageName = 'Closed Lost';
        opp1.Amount = 100;
        opp1.LineItemCount__c = 2;
        opp1.Total_Amt_DieCasting__c = 200;
        opp1.Total_Amt_DirectSourced__c = 300;
        opp1.Total_Amt_DMLS__c = 400;
        opp1.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp1);

        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Test2';
        opp2.StageName = 'Closed Won';
        opp2.Amount = 100;
        opp2.LineItemCount__c = 2;
        opp2.Total_Amt_Extrusion__c = 100;
        opp2.Total_Amt_FDM__c = 200;
        opp2.Total_Amt_HPMultJetFusion__c = 300;
        opp2.Total_Amt_InjectionMolding__c = 400;
        opp2.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp2);

        Opportunity opp3 = new Opportunity();
        opp3.Name = 'Test3';
        opp3.StageName = 'Closed Lost';
        opp3.Amount = 100;
        opp3.LineItemCount__c = 2;
        opp3.Total_Amt_InjectionMoldingTool__c = 100;
        opp3.Total_Amt_PolyJet3D__c = 300;
        opp3.Total_Amt_SheetCutting__c = 400;
        opp3.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp3);

        Opportunity opp4 = new Opportunity(Name = 'Test4');
        opp4.StageName = 'Open';
        opp4.Amount = 100;
        opp4.LineItemCount__c = 2;
        opp4.Total_Amt_SheetMetal__c = 100;
        opp4.Total_Amt_SLA__c = 200;
        opp4.Total_Amt_SLS__c = 300;
        opp4.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp4);

        Opportunity opp5 = new Opportunity(Name = 'Test5');
        opp5.StageName = 'Open';
        opp5.Amount = 100;
        opp5.LineItemCount__c = 2;
        opp5.Total_Amt_Stamping__c = 100;
        opp5.Total_Amt_UrethaneCasting__c = 200;
        opp5.CloseDate = System.today().addDays(10);
        lstOpportunities.add(opp5);
        insert lstOpportunities;

        Case testCase = new Case(Opportunity__c = opp.Id);
        lstCases.add(testCase);

        Case testCase1 = new Case(Opportunity__c = opp1.Id);
        lstCases.add(testCase1);

        Case testCase2 = new Case(Opportunity__c = opp2.Id);
        lstCases.add(testCase2);

        Case testCase3 = new Case(Opportunity__c = opp.Id);
        lstCases.add(testCase3);

        Test.startTest();
        insert lstCases;

        lstCases[0].Opportunity__c = opp3.Id;
        update lstCases[0];

        lstCases[0].Opportunity__c = opp4.Id;
        update lstCases[0];

        lstCases[1].Opportunity__c = opp5.Id;
        update lstCases[1];
        Test.stopTest();

        testCase = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[0].Id
            LIMIT 1
        ];
        testCase1 = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[1].Id
            LIMIT 1
        ];
        testCase2 = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[2].Id
            LIMIT 1
        ];
        testCase3 = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :lstCases[3].Id
            LIMIT 1
        ];

        System.assertEquals(3, testCase.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            6,
            testCase.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(300, testCase.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            100,
            testCase.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );

        System.assertEquals(2, testCase1.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            4,
            testCase1.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(200, testCase1.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            0,
            testCase1.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            100,
            testCase1.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );

        System.assertEquals(1, testCase2.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            2,
            testCase2.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(100, testCase2.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase2.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            0,
            testCase2.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );

        System.assertEquals(1, testCase3.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            2,
            testCase3.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(100, testCase3.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            100,
            testCase3.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            0,
            testCase3.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );
    }

    @isTest(seeAllData=false)
    static void testKeepTotalFieldsCase_Delete() {
        List<Opportunity> lstOpportunities = new List<Opportunity>();

        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Closed Won';
        opp.Amount = 100;
        opp.LineItemCount__c = 2;
        opp.CloseDate = System.today().addDays(10);
        opp.Total_Amt_BinderJetting__c = 100;
        opp.Total_Amt_Carbon__c = 100;
        opp.Total_Amt_CNC__c = 100;
        opp.Total_Amt_DieCasting__c = 100;
        opp.Total_Amt_DirectSourced__c = 100;
        opp.Total_Amt_DMLS__c = 100;
        lstOpportunities.add(opp);

        Opportunity opp1 = new Opportunity(Name = 'Test1');
        opp1.StageName = 'Closed Lost';
        opp1.Amount = 100;
        opp1.LineItemCount__c = 2;
        opp1.CloseDate = System.today().addDays(10);
        opp1.Total_Amt_BinderJetting__c = 100;
        opp1.Total_Amt_Carbon__c = 100;
        opp1.Total_Amt_CNC__c = 100;
        opp1.Total_Amt_DieCasting__c = 100;
        opp1.Total_Amt_DirectSourced__c = 100;
        opp1.Total_Amt_DMLS__c = 100;
        lstOpportunities.add(opp1);

        insert lstOpportunities;

        Case testCase = new Case(Opportunity__c = opp.Id);
        insert testCase;

        testCase.Opportunity__c = opp1.Id;
        update testCase;

        testCase = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :testCase.Id
            LIMIT 1
        ];

        CaseOpportunity__c objCaseOppsDel = [
            SELECT Id
            FROM CaseOpportunity__c
            WHERE Case__c = :testCase.Id AND Opportunity__c = :lstOpportunities[0].Id
        ];

        Test.startTest();
        delete objCaseOppsDel;
        Test.stopTest();

        testCase = [
            SELECT
                Id,
                Total_Amount_Opps__c,
                Total_LineItem_Opps__c,
                Total_Quantity_Opps__c,
                TotalAmountClosedWonOpps__c,
                TotalAmountClosedLostOpps__c
            FROM Case
            WHERE Id = :testCase.Id
            LIMIT 1
        ];

        System.assertEquals(1, testCase.Total_Quantity_Opps__c, 'The number of opportunities does not match');
        System.assertEquals(
            2,
            testCase.Total_LineItem_Opps__c,
            'The total line item quantity of opportunities does not match'
        );
        System.assertEquals(100, testCase.Total_Amount_Opps__c, 'The total amount of opportunities does not match');
        System.assertEquals(
            0,
            testCase.TotalAmountClosedWonOpps__c,
            'The total amount of opportunities won does not match'
        );
        System.assertEquals(
            100,
            testCase.TotalAmountClosedLostOpps__c,
            'The total amount of opportunities lost does not match'
        );
    }

    @isTest(seeAllData=false)
    static void updateRelatedCaseTest() {
        Opportunity opp = new Opportunity(Name = 'Test');
        opp.StageName = 'Open';
        opp.CloseDate = System.today().addDays(10);
        opp.Last_Quote_Xometry_ERP_ID__c = 'AAAAA-00001';

        Opportunity opp2 = new Opportunity(Name = 'Test2');
        opp2.StageName = 'Open';
        opp2.CloseDate = System.today().addDays(11);
        opp2.Last_Quote_Xometry_ERP_ID__c = 'AAAAA-00002';

        insert new List<Opportunity>{ opp, opp2 };

        Case testCase = new Case(SuppliedEmail = 'test@xomtest.com');
        Case testCase2 = new Case(SuppliedEmail = 'test2@xomtest.com');
        insert new List<Case>{ testCase, testCase2 };

        CaseOpportunity__c caseOppTest = new CaseOpportunity__c(
            Xometry_ERP_ID__c = 'AAAAA-00002',
            IsPrimaryOppOnCase__c = true,
            Opportunity__c = opp2.Id,
            Case__c = testCase.Id
        );
        CaseOpportunity__c caseOppTest2 = new CaseOpportunity__c(
            Xometry_ERP_ID__c = 'AAAAA-00002',
            IsPrimaryOppOnCase__c = true,
            Opportunity__c = opp2.Id,
            Case__c = testCase2.Id
        );
        insert new List<CaseOpportunity__c>{ caseOppTest, caseOppTest2 };

        CaseOpportunity__c caseOppTest3 = new CaseOpportunity__c(
            Xometry_ERP_ID__c = 'AAAAA-00001',
            IsPrimaryOppOnCase__c = true,
            Opportunity__c = opp.Id,
            Case__c = testCase.Id
        );

        Test.startTest();
        insert caseOppTest3;
        Test.stopTest();

        Map<Id, Case> testCaseResult = new Map<Id, Case>([SELECT Id, Opportunity__c FROM Case]);

        System.assertEquals(opp.Id, testCaseResult.get(testCase.Id).Opportunity__c, 'Case should be updated');
        System.assertEquals(opp2.Id, testCaseResult.get(testCase2.Id).Opportunity__c, 'Case should not be updated');

        Map<Id, CaseOpportunity__c> testCaseOppResult = new Map<Id, CaseOpportunity__c>(
            [SELECT Id, IsPrimaryOppOnCase__c FROM CaseOpportunity__c]
        );
        System.assertEquals(
            true,
            testCaseOppResult.get(caseOppTest2.Id).IsPrimaryOppOnCase__c,
            'CaseOpp should be updated'
        );
        System.assertEquals(
            false,
            testCaseOppResult.get(caseOppTest.Id).IsPrimaryOppOnCase__c,
            'CaseOpp should be updated'
        );
    }
}