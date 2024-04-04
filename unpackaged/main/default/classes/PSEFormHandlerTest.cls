@isTest
public class PSEFormHandlerTest {

    @isTest
    static void populateQuoteLookup_QuoteExists() {
        Quote_ERP__c quote = new Quote_ERP__C(
            Account_Domain__C = 'SuperCompany2.com',
            ERP_PartPK__c = 'A1234-A5678',
            Quote_Price__c = 50.15,
            Xometry_ERP_ID__C = 'AAAAA-00001',
            ERP_Contact__c = 'AAAAA',
            IS_Generic__c = false,
            Quote_Email__c = 'johndoe@SuperCompany2.com',
            Quote_ERP_Created_Date__c = Date.newInstance(2019, 6, 14),
            ERP_Contact_Last_Name__c = 'Doe'
        );

        PSE_Form__c pse = new PSE_Form__c(Quote_ID__c = 'AAAAA-00001');

        Test.startTest();
        insert quote;
        insert pse;
        Test.stopTest();

        PSE_Form__c resultPSE = [SELECT Id, Quote_ID__c, Quote_ERP__c FROM PSE_Form__c WHERE ID = :pse.id];
        System.assertEquals('AAAAA-00001', resultPSE.Quote_ID__c, 'Quote Id does not match');
        System.assertNotEquals(null, resultPSE.Quote_ERP__c, 'Quote lookup should not be null');
    }

    @isTest
    static void populateQuoteLookup_NoQuoteExists() {
        PSE_Form__c pse = new PSE_Form__c(Quote_ID__c = 'AAAAA-00002');

        Test.startTest();
        insert pse;
        Test.stopTest();

        PSE_Form__c resultPSE = [SELECT Id, Quote_ID__c, Quote_ERP__c FROM PSE_Form__c WHERE ID = :pse.id];
        System.assertEquals('AAAAA-00002', resultPSE.Quote_ID__c, 'Quote Id does not match');
        System.assertEquals(null, resultPSE.Quote_ERP__c, 'Quote Id should be set to null');
    }

    @isTest
    static void populateQuoteLookup_NullQuoteId() {
        PSE_Form__c pse = new PSE_Form__c(Quote_ID__c = null);

        Test.startTest();
        insert pse;
        Test.stopTest();

        PSE_Form__c resultPSE = [SELECT Id, Quote_ID__c, Quote_ERP__c FROM PSE_Form__c WHERE ID = :pse.id];
        System.assertEquals(null, resultPSE.Quote_ID__c, 'Quote Id is not null');
        System.assertEquals(null, resultPSE.Quote_ERP__c, 'Quote Id should be set to null');
    }

    @isTest(seeAllData=false)
    static void updateAssociatedCase_QuoteExists() {
        Quote_ERP__c quote = new Quote_ERP__C(
            Account_Domain__C = 'SuperCompany2.com',
            ERP_PartPK__c = 'A1234-A5678',
            Quote_Price__c = 50.15,
            Xometry_ERP_ID__C = 'AAAAA-00001',
            ERP_Contact__c = 'AAAAA',
            IS_Generic__c = false,
            Quote_Email__c = 'johndoe@SuperCompany2.com',
            Quote_ERP_Created_Date__c = Date.newInstance(2021, 6, 14),
            ERP_Contact_Last_Name__c = 'Doe',
            Requested_Manual_Quote_Flag__c = true,
            Requested_Manual_Quote_Time__C = dateTime.newInstanceGMT(2021, 5, 21, 0, 0, 0)
        );

        PSE_Form__c pse = new PSE_Form__c(Quote_ID__c = 'AAAAA-00001');

        Test.startTest();
        insert quote;
        insert pse;
        Test.stopTest();

        Case resultCase = [
            SELECT Id, PSE_Form__c, Opportunity__r.Last_Quote_Xometry_ERP_ID__c
            FROM Case
            WHERE Opportunity__r.Last_Quote_Xometry_ERP_ID__c = :quote.Xometry_ERP_ID__C
        ];
        System.assertNotEquals(null, resultCase.PSE_Form__c, 'Lookup should not be null');
        System.assertEquals(pse.Id, resultCase.PSE_Form__c, 'Form Lookup should match newly inserted Form');

        PSE_Form__c resultPSE = [SELECT Case__c FROM PSE_Form__c WHERE Id =:pse.Id];
        System.assertEquals(resultCase.Id, resultPSE.Case__c, 'Case Lookup should match newly inserted Case');

    }

    @isTest(seeAllData=false)
    static void updateAssociatedCase_NoQuoteExists() {
        Case testCase = new Case();

        PSE_Form__c pse = new PSE_Form__c(Quote_ID__c = 'AAAAA-00002');

        Test.startTest();
        insert testCase;
        insert pse;
        Test.stopTest();

        Case testCaseResult = [SELECT PSE_Form__c FROM Case WHERE Id = :testCase.Id];

        System.assertEquals(null, testCaseResult.PSE_Form__c, 'Lookup should be null');
   
    }

    @isTest
    static void updateAssociatedCase_NullQuoteId() {
        Case testCase = new Case();

        PSE_Form__c pse = new PSE_Form__c();

        Test.startTest();
        insert testCase;
        insert pse;
        Test.stopTest();

        Case testCaseResult = [SELECT PSE_Form__c FROM Case WHERE Id = :testCase.Id];
        
        System.assertEquals(null, testCaseResult.PSE_Form__c, 'Lookup should be null');

    }
}