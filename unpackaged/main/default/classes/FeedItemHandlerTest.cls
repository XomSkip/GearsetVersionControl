@isTest
public with sharing class FeedItemHandlerTest {

    @isTest(seeAllData=false)
    static void InternalNotesTest() {

        Case caseTest = new Case();
        caseTest.Priority = 'Low';
        caseTest.Origin = 'Chat';
        caseTest.Status= 'Pending';
        caseTest.RecordTypeId = AppConstants.caseGeneralSupportRTypeId;

        
        insert caseTest;

        Test.startTest();

        FeedItem feedItem = new FeedItem(ParentId = caseTest.Id, Body = 'Test Body');
        insert feedItem;

        Test.stopTest();

        Case caseTestResult = [SELECT Status FROM Case WHERE Id = :caseTest.Id];
        System.assertEquals('Response Received', caseTestResult.Status, 'Case status should be updated');

    }
    
}