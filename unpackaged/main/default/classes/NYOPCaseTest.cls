@isTest
public with sharing class NYOPCaseTest {
    @isTest
    static void nyopCaseFirstThenPSE() {
        //Create an NYOP Case
        //Create a PSE Case
        Quote_ERP__C testPseQuote = TestDataFactory.createQuote(false);
        String testQuoteNumber = 'Q21-300-4445';
        testPseQuote.Xometry_ERP_ID__C = testQuoteNumber;
        testPseQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        testPseQuote.LineItemCount__c = 1;
        testPseQuote.Reorder__c = true;
        testPseQuote.Quote_ERP_Created_Date__c = Date.today();
        testPseQuote.Requested_Manual_Quote_Flag__c = true;
        testPseQuote.Requested_Manual_Quote_Time__C = DateTime.now();
        Case nyopCase = new Case();
        nyopCase.recordTypeID = AppConstants.nyopRTypeID;
        nyopCase.Shadow_Xometry_ERP_ID__C = testQuoteNumber;
        insert nyopCase;
        insert testPseQuote;
        test.StartTest();
        List<Case> nyopCaseList = new List<Case>();
        nyopCaseList.add(nyopCase);
        updateNYOPCaseQue nyopQue = new updateNYOPCaseQue(nyopCaseList);
        ID jobID = System.enqueueJob(nyopQue);
        test.StopTest();
        //Get the PSE Case
        Case pseCase = [
            SELECT ID, Shadow_Xometry_ERP_ID__C, Opportunity__c
            FROM Case
            WHERE recordTypeID = :AppConstants.casePSERecordTypeId AND Shadow_Xometry_ERP_ID__C = :testQuoteNumber
        ][0];
        Case testNYOPCase = [
            SELECT ID, Shadow_Xometry_ERP_ID__C, Opportunity__c, ParentID
            FROM Case
            WHERE ID = :nyopCase.ID
        ];

        System.assertEquals(pseCase.Opportunity__c, testNYOPCase.Opportunity__c, 'The Opportunities did not match');
        System.assertEquals(pseCase.ID, testNYOPCase.ParentID, 'The NYOP case does not have the right parent');
    }

    @isTest
    static void pseFirstThenNYOP() {
        //Create a PSE Case
        //Create the NYOP Case
        Quote_ERP__C testPseQuote = TestDataFactory.createQuote(false);
        String testQuoteNumber = 'Q21-300-4445';
        testPseQuote.Xometry_ERP_ID__C = testQuoteNumber;
        testPseQuote.DFM_Description__c = 'This is a reason that this needs to be a dfm case, or something like that.';
        testPseQuote.LineItemCount__c = 1;
        testPseQuote.Reorder__c = true;
        testPseQuote.Quote_ERP_Created_Date__c = Date.today();
        testPseQuote.Requested_Manual_Quote_Flag__c = true;
        testPseQuote.Requested_Manual_Quote_Time__C = DateTime.now();
        Case nyopCase = new Case();
        nyopCase.recordTypeID = AppConstants.nyopRTypeID;
        nyopCase.Shadow_Xometry_ERP_ID__C = testQuoteNumber;
        insert testPseQuote;
        test.StartTest();
        insert nyopCase;
        test.StopTest();
        //Get the PSE Case
        Case pseCase = [
            SELECT ID, Shadow_Xometry_ERP_ID__C, Opportunity__c
            FROM Case
            WHERE recordTypeID = :AppConstants.casePSERecordTypeId AND Shadow_Xometry_ERP_ID__C = :testQuoteNumber
        ][0];
        Case testNYOPCase = [
            SELECT ID, Shadow_Xometry_ERP_ID__C, Opportunity__c, ParentID
            FROM Case
            WHERE ID = :nyopCase.ID
        ];

        System.assertEquals(pseCase.Opportunity__c, testNYOPCase.Opportunity__c, 'The Opportunities did not match');
        System.assertEquals(pseCase.ID, testNYOPCase.ParentID, 'The NYOP case does not have the right parent');
    }
}