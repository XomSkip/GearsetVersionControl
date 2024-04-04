@isTest
private class SuppliesOppAggBatch_Test {
    @isTest
    static void updateSupplierFromOrderOppAgg() {
        List<Supplier__c> supplierList = new List<Supplier__c>();
        for (Integer i = 0, j = 0; i < 2; i++) {
            Supplier__c s = TestDataFactory.createSupplier(
                true,
                'P000' + i.format(),
                'Partner' +
                i.format() +
                '@company' +
                i.format() +
                '.com',
                'Company' +
                i.format() +
                '.com',
                'Company' + i.format(),
                'First' + i.format(),
                'Last' + i.format()
            );
            supplierList.add(s);
        }

        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23477';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = supplierList[0].PartnerId__c;
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

        Supplies_Order__C testSOrderResult = [
            SELECT
                ID,
                AccountID__C,
                P21_Account_DetailsID__c,
                ContactID__C,
                OpportunityID__C,
                OpportunityId__r.Primary_Supplier__c
            FROM Supplies_Order__C
            WHERE ID = :sOrderTest.Id
        ][0];

        Opportunity testOpp = [
            SELECT Id, Primary_Supplier__c, Amount, StageName
            FROM Opportunity
            WHERE Id = :testSOrderResult.OpportunityId__c
        ];

        test.startTest();
        SuppliesOppAggBatch sOppAggBatch = new SuppliesOppAggBatch();
        ID batchID = Database.executeBatch(sOppAggBatch);
        System.debug('The batchID is : ' + batchID);
        test.stopTest();

        Supplier__c sResult = [
            SELECT Id, Sup_Revenue__c, Sup_TotalQuotedRevenue__c, Sup_TotalPotentialRevenue__c
            FROM Supplier__c
            WHERE ID = :testOpp.Primary_Supplier__c
        ];

        Supplier__c sResultNull = [
            SELECT Id, Sup_Revenue__c, Sup_TotalQuotedRevenue__c, Sup_TotalPotentialRevenue__c
            FROM Supplier__c
            WHERE ID = :supplierList[1].Id
        ];

        System.assertEquals(
            testOpp.Amount,
            sResult.Sup_TotalQuotedRevenue__c,
            'Total Opp Amount did not equal total quoted revenue'
        );
        System.assertEquals(testOpp.Amount, sResult.Sup_Revenue__c, 'Total Opp Amount did not equal total revenue');
        System.assertEquals(null, sResultNull.Sup_Revenue__c, 'Supplier should not aggregate if no opps');
    }

    @isTest
    static void updateSupplierFromQuoteOppAgg() {
        List<Supplier__c> supplierList = new List<Supplier__c>();
        for (Integer i = 0, j = 0; i < 2; i++) {
            Supplier__c s = TestDataFactory.createSupplier(
                true,
                'P000' + i.format(),
                'Partner' +
                i.format() +
                '@company' +
                i.format() +
                '.com',
                'Company' +
                i.format() +
                '.com',
                'Company' + i.format(),
                'First' + i.format(),
                'Last' + i.format()
            );
            supplierList.add(s);
        }

        List<Supplies_Quote__C> testQuoteList = new List<Supplies_Quote__C>();
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.PartnerID__c = supplierList[0].PartnerId__c;
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
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        testQuoteList.add(sQuoteTest);
        Supplies_Quote__C sQuoteTest2 = new Supplies_Quote__C();
        sQuoteTest2.P21_ERP_ID__c = 'OE23478';
        sQuoteTest2.P21_ContactID__c = 'A1265';
        sQuoteTest2.P21_CustomerID__c = 'CA144';
        sQuoteTest2.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest2.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest2.PartnerID__c = supplierList[0].PartnerId__c;
        sQuoteTest2.Is_Generic__c = true;
        sQuoteTest2.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest2.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest2.P21_Contact_Phone__c = '5553334444';
        sQuoteTest2.P21_OE_Status__c = 'Active';
        sQuoteTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest2.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest2.P21_Physical_Country__c = 'United States';
        sQuoteTest2.P21_Physical_State__c = 'Maryland';
        sQuoteTest2.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest2.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest2.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest2.Quote_Price__c = 500.50;
        testQuoteList.add(sQuoteTest2);
        Supplies_Quote__C sQuoteTest3 = new Supplies_Quote__C();
        sQuoteTest3.P21_ERP_ID__c = 'OE23479';
        sQuoteTest3.P21_ContactID__c = 'A1265';
        sQuoteTest3.P21_CustomerID__c = 'CA144';
        sQuoteTest3.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest3.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest3.PartnerID__c = supplierList[0].PartnerId__c;
        sQuoteTest3.Is_Generic__c = true;
        sQuoteTest3.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest3.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest3.P21_Contact_Phone__c = '5553334444';
        sQuoteTest3.P21_OE_Status__c = 'Active';
        sQuoteTest3.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest3.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest3.P21_Physical_Country__c = 'United States';
        sQuoteTest3.P21_Physical_State__c = 'Maryland';
        sQuoteTest3.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest3.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest3.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest3.Quote_Price__c = 500.50;
        testQuoteList.add(sQuoteTest3);
        insert (testQuoteList);

        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23479';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = supplierList[0].PartnerId__c;
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

        Supplies_Order__C testSOrderResult = [
            SELECT
                ID,
                AccountID__C,
                P21_Account_DetailsID__c,
                ContactID__C,
                OpportunityID__C,
                OpportunityId__r.Primary_Supplier__c
            FROM Supplies_Order__C
            WHERE ID = :sOrderTest.Id
        ][0];

        Opportunity testOpp = [
            SELECT Id, Primary_Supplier__c, Amount, StageName
            FROM Opportunity
            WHERE Id = :testSOrderResult.OpportunityId__c
        ];

        test.startTest();
        SuppliesOppAggBatch sOppAggBatch = new SuppliesOppAggBatch();
        ID batchID = Database.executeBatch(sOppAggBatch);
        System.debug('The batchID is : ' + batchID);
        test.stopTest();

        Supplier__c sResult = [
            SELECT Id, Sup_Revenue__c, Sup_TotalQuotedRevenue__c, Sup_TotalPotentialRevenue__c
            FROM Supplier__c
            WHERE ID = :supplierList[0].Id
        ];

        Supplier__c sResultNull = [
            SELECT Id, Sup_Revenue__c, Sup_TotalQuotedRevenue__c, Sup_TotalPotentialRevenue__c
            FROM Supplier__c
            WHERE ID = :supplierList[1].Id
        ];

        System.assertEquals(
            testOpp.Amount +
            sQuoteTest.Quote_Price__c +
            sQuoteTest2.Quote_Price__c,
            sResult.Sup_TotalQuotedRevenue__c,
            'Total Opp Amount did not equal total quoted revenue'
        );
        System.assertEquals(testOpp.Amount, sResult.Sup_Revenue__c, 'Total Opp Amount did not equal total revenue');
        System.assertEquals(null, sResultNull.Sup_Revenue__c, 'Supplier should not aggregate if no opps');
        System.assertEquals(
            sQuoteTest.Quote_Price__c + sQuoteTest2.Quote_Price__c,
            sResult.Sup_TotalPotentialRevenue__c,
            'Potential Revenue should be calculated not closed won'
        );
    }

    @isTest
    static void oppYearlyAgg() {
        List<Supplier__c> supplierList = new List<Supplier__c>();
        for (Integer i = 0, j = 0; i < 2; i++) {
            Supplier__c s = TestDataFactory.createSupplier(
                true,
                'P000' + i.format(),
                'Partner' +
                i.format() +
                '@company' +
                i.format() +
                '.com',
                'Company' +
                i.format() +
                '.com',
                'Company' + i.format(),
                'First' + i.format(),
                'Last' + i.format()
            );
            supplierList.add(s);
        }

        List<Supplies_Order__C> sOrderList = new List<Supplies_Order__C>();
        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23479';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = supplierList[0].PartnerId__c;
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
        sOrderTest.Order_Date__c = date.newInstance(Date.today().year(), 1, 1);
        sOrderTest.Order_P21_Last_Updated_Time__c = datetime.newInstance(Date.today().year(), 1, 1, 1, 0, 30);
        sOrderTest.Order_Total__c = 500.50;
        sOrderList.add(sOrderTest);

        Supplies_Order__C sOrderTest1 = new Supplies_Order__C();
        sOrderTest1.P21_Quote_OE_ERP_ID__C = 'OE23480';
        sOrderTest1.P21_Order_OE_ERP_ID__C = 'OE24456';
        sOrderTest1.P21_ContactID__c = 'A1265';
        sOrderTest1.P21_CustomerID__c = 'CA144';
        sOrderTest1.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest1.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest1.PartnerID__c = supplierList[0].PartnerId__c;
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
        sOrderTest1.Order_Date__c = date.newInstance(Date.today().year() - 1, 1, 1);
        sOrderTest1.Order_P21_Last_Updated_Time__c = datetime.newInstance(Date.today().year() - 1, 1, 1, 1, 0, 30);
        sOrderTest1.Order_Total__c = 500.50;
        sOrderList.add(sOrderTest1);

        Supplies_Order__C sOrderTest2 = new Supplies_Order__C();
        sOrderTest2.P21_Quote_OE_ERP_ID__C = 'OE234781';
        sOrderTest2.P21_Order_OE_ERP_ID__C = 'OE24457';
        sOrderTest2.P21_ContactID__c = 'A1265';
        sOrderTest2.P21_CustomerID__c = 'CA144';
        sOrderTest2.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest2.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest2.PartnerID__c = supplierList[0].PartnerId__c;
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
        sOrderTest2.Order_Date__c = date.newInstance(Date.today().year() - 1, 1, 1);
        sOrderTest2.Order_P21_Last_Updated_Time__c = datetime.newInstance(Date.today().year() - 1, 1, 1, 1, 0, 30);
        sOrderTest2.Order_Total__c = 500.50;
        sOrderList.add(sOrderTest2);

        Supplies_Order__C sOrderTest3 = new Supplies_Order__C();
        sOrderTest3.P21_Quote_OE_ERP_ID__C = 'OE23482';
        sOrderTest3.P21_Order_OE_ERP_ID__C = 'OE24458';
        sOrderTest3.P21_ContactID__c = 'A1265';
        sOrderTest3.P21_CustomerID__c = 'CA144';
        sOrderTest3.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest3.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest3.PartnerID__c = supplierList[1].PartnerId__c;
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
        sOrderTest3.Order_Date__c = date.newInstance(Date.today().year(), 1, 1);
        sOrderTest3.Order_P21_Last_Updated_Time__c = datetime.newInstance(Date.today().year(), 1, 1, 1, 0, 30);
        sOrderTest3.Order_Total__c = 500.50;
        sOrderList.add(sOrderTest3);
        insert sOrderList;

        Test.startTest();
        SuppliesOppAggBatch sOppAggBatch = new SuppliesOppAggBatch();
        ID batchID = Database.executeBatch(sOppAggBatch);
        System.debug('The batchID is : ' + batchID);
        Test.stopTest();

        Supplier__c sResult = [
            SELECT Id, Sup_TotalRevenueLY__c, Sup_TotalRevenueTY__c
            FROM Supplier__c
            WHERE ID = :supplierList[0].Id
        ];
        Supplier__c sResult1 = [
            SELECT Id, Sup_TotalRevenueLY__c, Sup_TotalRevenueTY__c
            FROM Supplier__c
            WHERE ID = :supplierList[1].Id
        ];

        System.assertEquals(
            sOrderTest1.Order_Total__c + sOrderTest2.Order_Total__c,
            sResult.Sup_TotalRevenueLY__c,
            'Last Year Revenue did not calculate'
        );
        System.assertEquals(
            sOrderTest.Order_Total__c,
            sResult.Sup_TotalRevenueTY__c,
            'This Year Revenue did not calculate'
        );

        System.assertEquals(0, sResult1.Sup_TotalRevenueLY__c, 'Supplier without an opp last year was not 0');
        System.assertEquals(
            sOrderTest3.Order_Total__c,
            sResult1.Sup_TotalRevenueTY__c,
            'This Year Revenue did not calculate'
        );
    }

    @isTest
    static void updateSupplierOppAggNullArgument() {
        List<Supplier__c> supplierList = new List<Supplier__c>();
        for (Integer i = 0, j = 0; i < 2; i++) {
            Supplier__c s = TestDataFactory.createSupplier(
                true,
                'P000' + i.format(),
                'Partner' +
                i.format() +
                '@company' +
                i.format() +
                '.com',
                'Company' +
                i.format() +
                '.com',
                'Company' + i.format(),
                'First' + i.format(),
                'Last' + i.format()
            );
            supplierList.add(s);
        }

        List<Supplies_Quote__C> testQuoteList = new List<Supplies_Quote__C>();
        Supplies_Quote__C sQuoteTest = new Supplies_Quote__C();
        sQuoteTest.P21_ERP_ID__c = 'OE23477';
        sQuoteTest.P21_ContactID__c = 'A1265';
        sQuoteTest.P21_CustomerID__c = 'CA144';
        sQuoteTest.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest.PartnerID__c = supplierList[0].PartnerId__c;
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
        sQuoteTest.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest.Quote_Price__c = 500.50;
        testQuoteList.add(sQuoteTest);
        Supplies_Quote__C sQuoteTest2 = new Supplies_Quote__C();
        sQuoteTest2.P21_ERP_ID__c = 'OE23478';
        sQuoteTest2.P21_ContactID__c = 'A1265';
        sQuoteTest2.P21_CustomerID__c = 'CA144';
        sQuoteTest2.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest2.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest2.PartnerID__c = supplierList[0].PartnerId__c;
        sQuoteTest2.Is_Generic__c = true;
        sQuoteTest2.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest2.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest2.P21_Contact_Phone__c = '5553334444';
        sQuoteTest2.P21_OE_Status__c = 'Active';
        sQuoteTest2.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest2.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest2.P21_Physical_Country__c = 'United States';
        sQuoteTest2.P21_Physical_State__c = 'Maryland';
        sQuoteTest2.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest2.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest2.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest2.Quote_Price__c = 500.50;
        testQuoteList.add(sQuoteTest2);
        Supplies_Quote__C sQuoteTest3 = new Supplies_Quote__C();
        sQuoteTest3.P21_ERP_ID__c = 'OE23479';
        sQuoteTest3.P21_ContactID__c = 'A1265';
        sQuoteTest3.P21_CustomerID__c = 'CA144';
        sQuoteTest3.Quote_Email__c = 'bobsmith21@gmail.com';
        sQuoteTest3.Account_Domain__c = 'bobsmith21@gmail.com';
        sQuoteTest3.PartnerID__c = supplierList[0].PartnerId__c;
        sQuoteTest3.Is_Generic__c = true;
        sQuoteTest3.P21_Contact_First_Name__c = 'Bob';
        sQuoteTest3.P21_Contact_Last_Name__c = 'Smith';
        sQuoteTest3.P21_Contact_Phone__c = '5553334444';
        sQuoteTest3.P21_OE_Status__c = 'Active';
        sQuoteTest3.P21_Physical_Address__c = '555 Test Address Fast St.';
        sQuoteTest3.P21_Physical_City__c = 'MadeupTown';
        sQuoteTest3.P21_Physical_Country__c = 'United States';
        sQuoteTest3.P21_Physical_State__c = 'Maryland';
        sQuoteTest3.P21_Physical_Zip_Code__c = '23455';
        sQuoteTest3.Quote_P21_Created_Date__c = date.newInstance(2021, 10, 28);
        sQuoteTest3.Quote_P21_Last_Updated_Time__c = datetime.newInstance(2021, 10, 28, 10, 0, 30);
        sQuoteTest3.Quote_Price__c = 500.50;
        testQuoteList.add(sQuoteTest3);
        insert (testQuoteList);

        Supplies_Order__C sOrderTest = new Supplies_Order__C();
        sOrderTest.P21_Quote_OE_ERP_ID__C = 'OE23479';
        sOrderTest.P21_Order_OE_ERP_ID__C = 'OE24455';
        sOrderTest.P21_ContactID__c = 'A1265';
        sOrderTest.P21_CustomerID__c = 'CA144';
        sOrderTest.Order_Email__c = 'bobsmith21@gmail.com';
        sOrderTest.Account_Domain__c = 'bobsmith21@gmail.com';
        sOrderTest.PartnerID__c = supplierList[0].PartnerId__c;
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
        insert sOrderTest;

        Supplies_Order__C testSOrderResult = [
            SELECT
                ID,
                AccountID__C,
                P21_Account_DetailsID__c,
                ContactID__C,
                OpportunityID__C,
                OpportunityId__r.Primary_Supplier__c
            FROM Supplies_Order__C
            WHERE ID = :sOrderTest.Id
        ][0];

        Opportunity testOpp = [
            SELECT Id, Primary_Supplier__c, Amount, StageName
            FROM Opportunity
            WHERE Id = :testSOrderResult.OpportunityId__c
        ];

        test.startTest();
        SuppliesOppAggBatch sOppAggBatch = new SuppliesOppAggBatch();
        ID batchID = Database.executeBatch(sOppAggBatch);
        System.debug('The batchID is : ' + batchID);
        test.stopTest();

        AsyncApexJob a = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :batchID
        ];

        System.assertEquals(0, a.NumberOfErrors, 'The job should have no errors when opp amount is null');
    }
}