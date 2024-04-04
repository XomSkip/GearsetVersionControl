@isTest
public class BoxUserViewControllerTest {
    @isTest
    static void getBoxUserContactTest() {
        Test.startTest();
        List<Contact> contactList = BoxUserViewController.getBoxUserContact('sample@test.com');
        Test.stopTest();

        System.assertEquals('123456', contactList[0].Xometry_ERP_Contact_ID__c, 'ERP external Id does not match');
    }

    @isTest
    static void searchFolderTest() {

        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );
        mock.add(
            'GET',
            'https://api.box.com/2.0/search?query=TestFile',
            '{"total_count":1,"entries":[{"type":"folder","id":"207199824323","etag":"0","name":"Test01"}],"limit":30,"offset":0}'
        );
        mock.setMock();

        Test.startTest();
        Boolean objResult = BoxUserViewController.searchFolder('TestFile');
        Test.stopTest();

        System.assertEquals(objResult, true, 'The attribute total_count is incorrect');
    }

    @isTest
    private static void createFolderTest() {

        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );
        mock.add(
            'GET',
            'https://api.box.com/2.0/search',
            '{"total_count":1,"entries":[{"type":"folder","id":"207199824323","etag":"0","name":"Test01"}],"limit":30,"offset":0}'    
        );
        mock.add(
            'PUT',
            'https://api.box.com/2.0/folders/12345',
            '{"type":"folder","id":"206830131043","sequence_id":"0","etag":"0","name":"TestClass","created_at":"2023-05-09T08:19:17-07:00","modified_at":"2023-05-09T08:19:17-07:00","description":""' +
            ',"size":0,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"25468066666",' +
            '"name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"modified_by":{"type":"user","id":"25468066666","name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"trashed_at":null,' +
            '"purged_at":null,"content_created_at":"2023-05-09T08:19:17-07:00","content_modified_at":"2023-05-09T08:19:17-07:00","owned_by":{"type":"user","id":"25468066666","name":"Cristian Mejia",' +
            '"login":"cdmejia531@gmail.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active",' +
            '"item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}'
        );
        mock.setMock();

        Case testCase = new Case(SuppliedEmail = 'test@test.com', RecordTypeId = AppConstants.casePSERecordTypeId);
        insert testCase;

        Test.startTest();
        String message = BoxUserViewController.createFolder(testCase.Id).status;
        Test.stopTest();

        System.assertEquals('Success', message, 'The folder was not created');
    }

    @isTest
    private static void createUserTest() {

        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/users',
            '{"total_count":1,"entries":[{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}],"limit":30,"offset":0}'
        );
        mock.setMock();

        Test.startTest();
        BoxUser.CreateUserRequest reqCreateUser = new BoxUser.CreateUserRequest();
        String message = BoxUserViewController.createUser('Test', 'Test@gmail.com', 'Test@gmail.com', 'Test');
        Test.stopTest();

        System.assertEquals('Success', message, 'User was not created');
    }

    @isTest(seeAllData=false)
    private static void createFolderPostProcessingFuture() {

        CustomMockResponse mock = new CustomMockResponse();

        String collabResponse =  '{"type":"collaboration","id":"cascadePolicyId","created_by":null,"created_at":"2023-05-30T12:19:11-07:00","modified_at":"2023-05-30T12:19:11-07:00","expires_at":null,"status":"accepted",' +
            '"accessible_by":{"type":"group","id":"15522017485","name":"Salesforce_Box_User","group_type":"managed_group"},"invite_email":null,"role":"editor","acknowledged_at":"2023-05-30T12:19:11-07:00",' +
            '"item":{"type":"folder","id":"210257285694","sequence_id":"0","etag":"0","name":"02523762"},"is_access_only":false}';

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/collaborations',
            collabResponse
        );

        mock.add(
            'callout:Box_Rest_API/2.0/folders/ITARInternal/metadata/enterprise/securityClassification-6VMVochwUWo',
            collabResponse
        );

        mock.add(
            'callout:Box_Rest_API/2.0/folders/nonITARInternal/metadata/enterprise/securityClassification-6VMVochwUWo',
            collabResponse
        );

        mock.add(
            'callout:Box_Rest_API/2.0/metadata_cascade_policies',
            collabResponse
        );

        mock.add(
            'callout:Box_Rest_API/2.0/metadata_cascade_policies/cascadePolicyId/apply',
            collabResponse
        );

        mock.setMock();

        Map<String, Object> response;

        Case testCase = new Case();
        insert testCase;

        Test.startTest();

        BoxUserViewController.createFolderPostProcessingFuture(
            testCase.Id,
            '0',
            'nonITARInternal',
            'ITARInternal',
            'nonITARConsumer',
            'ITARConsumer'
        );

        Test.stopTest();

        Case caseResult = [SELECT Box_Folder__c FROM Case WHERE Id = :testCase.Id];

        System.assertEquals('0', caseResult.Box_Folder__c, 'Case was not postprocessed');
    }

    @isTest(seeAllData=false)
    private static void addDefaultClassificationTest() {

        CustomMockResponse mock = new CustomMockResponse();

        String collabResponse =  '{"type":"collaboration","id":"cascadePolicyId","created_by":null,"created_at":"2023-05-30T12:19:11-07:00","modified_at":"2023-05-30T12:19:11-07:00","expires_at":null,"status":"accepted",' +
            '"accessible_by":{"type":"group","id":"15522017485","name":"Salesforce_Box_User","group_type":"managed_group"},"invite_email":null,"role":"editor","acknowledged_at":"2023-05-30T12:19:11-07:00",' +
            '"item":{"type":"folder","id":"210257285694","sequence_id":"0","etag":"0","name":"02523762"},"is_access_only":false}';

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/folders/ITARInternal/metadata/enterprise/securityClassification-6VMVochwUWo',
            collabResponse
        );

        mock.add(
            'callout:Box_Rest_API/2.0/folders/nonITARInternal/metadata/enterprise/securityClassification-6VMVochwUWo',
            collabResponse
        );

        mock.add(
            'callout:Box_Rest_API/2.0/metadata_cascade_policies',
            collabResponse
        );

        mock.add(
            'callout:Box_Rest_API/2.0/metadata_cascade_policies/cascadePolicyId/apply',
            collabResponse
        );

        mock.setMock();

        Case testCase = new Case();
        insert testCase;

        Test.startTest();

        String resp = BoxUserViewController.addDefaultClassification('nonITARInternal', 'ITARInternal');

        Test.stopTest();

        System.assertEquals('success', resp, 'Classification was not created');
    }

    @isTest
    private static void testSearchError() {
        Test.startTest();
        BoxUserViewController.addAuditError('test@email.com', 'does not have an ERP Id');
        Test.stopTest();

        List<Audit_Trail_Error__c> auditError = [
            SELECT Id, Dev_Audit_Notes__c, errorMessage__c
            FROM Audit_Trail_Error__c
        ];

        System.assertEquals(
            'Contact search from box',
            auditError[0].Dev_Audit_Notes__c,
            'the audit trail dev note should be Contact search from box'
        );
        System.assertEquals(
            'LWC BoxUser: does not have an ERP Id',
            auditError[0].errorMessage__c,
            'the audit trail should show missing erp error'
        );
    }

    @testSetup
    static void dataSetup() {
        Account accountToInsert = new Account();
        accountToInsert.Name = 'Sample Account';
        insert accountToInsert;

        Contact contactToInsert = new Contact();
        contactToInsert.LastName = 'Sample Last Name';
        contactToInsert.Email = 'sample@test.com';
        contactToInsert.Primary_Email__c = 'sample@test.com';
        contactToInsert.Xometry_ERP_Contact_ID__c = '123456';
        contactToInsert.Account = [SELECT Id FROM Account LIMIT 1];
        insert contactToInsert;
    }
}