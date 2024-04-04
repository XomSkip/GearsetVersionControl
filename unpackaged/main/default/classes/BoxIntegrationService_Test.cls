@isTest
public class BoxIntegrationService_Test {

	@isTest(seeAllData=false)
    static void caseToPendingTest() {

    	Contact contactTest = new Contact();
        contactTest.FirstName = 'TestMan';
        contactTest.LastName = 'LastNamington';
        contactTest.Primary_Email__c = 'TestMan@domain.com';
        contactTest.Xometry_ERP_Contact_ID__c = '230AE';
        insert contactTest;

    	Case caseTest = new Case();
    	insert caseTest;

    	List<Box_Integration_Service__e> boxEventList = new List<Box_Integration_Service__e>();

    	Box_Integration_Service__e boxEvent = new Box_Integration_Service__e();
		boxEvent.Action__c = 'fileUploaded';
		boxEvent.Actor__c = '230AE';
		boxEvent.CaseId__c = caseTest.Id;
		boxEvent.Filename__c = 'Test.file';
		boxEvent.Filepath__c = 'Test/path';
		boxEvent.Time__c = System.now();

		boxEventList.add(boxEvent);

		Test.startTest();

		EventBus.publish(boxEventList);

		Test.stopTest();

		System.assertEquals('Response Received', [SELECT Status FROM Case WHERE Id = :caseTest.Id].Status );
		System.assertEquals(1, [SELECT Id FROM FeedItem WHERE ParentId = :caseTest.Id].size() );

    }
    
	@isTest(seeAllData=false)
    static void caseNumberToPendingTest() {

    	Contact contactTest = new Contact();
        contactTest.FirstName = 'TestMan';
        contactTest.LastName = 'LastNamington';
        contactTest.Primary_Email__c = 'TestMan@domain.com';
        contactTest.Xometry_ERP_Contact_ID__c = '230AE';
        insert contactTest;

    	Case caseTest = new Case();
    	insert caseTest;

    	caseTest = [SELECT CaseNumber FROM Case WHERE Id = :caseTest.Id];

    	List<Box_Integration_Service__e> boxEventList = new List<Box_Integration_Service__e>();

    	Box_Integration_Service__e boxEvent = new Box_Integration_Service__e();
		boxEvent.Action__c = 'fileUploaded';
		boxEvent.Actor__c = '230AE';
		boxEvent.CaseNumber__c = caseTest.CaseNumber;
		boxEvent.Filename__c = 'Test.file';
		boxEvent.Filepath__c = 'Test/path';
		boxEvent.Time__c = System.now();

		boxEventList.add(boxEvent);

		Test.startTest();

		EventBus.publish(boxEventList);

		Test.stopTest();

		System.assertEquals('Response Received', [SELECT Status FROM Case WHERE Id = :caseTest.Id].Status );
		System.assertEquals(1, [SELECT Id FROM FeedItem WHERE ParentId = :caseTest.Id].size() );

    }

}