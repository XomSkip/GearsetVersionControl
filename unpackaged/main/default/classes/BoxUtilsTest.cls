@isTest
public class BoxUtilsTest {

    @isTest
    private static void getBoxUser_test() {

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'GET',
            'callout:Box_Rest_API/2.0/users?external_app_user_id=1234567',
            '{"total_count":1,"entries":[{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}],"limit":30,"offset":0}'
        );

        mock.setMock();

        Test.startTest();
        BoxUser.Entry boxUser = BoxUtils.getBoxUser('1234567');
        Test.stopTest();

        System.assertEquals(boxUser.type, 'user', 'The attribute type is incorrect');
        System.assertEquals(boxUser.id, '25468066000', 'The attribute id is incorrect');
        System.assertEquals(boxUser.name, 'Mr Test', 'The attribute name is incorrect');
        System.assertEquals(boxUser.login, 'test@gmail.com', 'The attribute login is incorrect');
        System.assertEquals(boxUser.created_at + '', '2023-05-04 11:34:12', 'The attribute created_at is incorrect');
        System.assertEquals(boxUser.modified_at + '', '2023-05-08 13:36:07', 'The attribute modified_at is incorrect');
        System.assertEquals(boxUser.language, 'en', 'The attribute language is incorrect');
        System.assertEquals(boxUser.timezone, 'America/Los_Angeles', 'The attribute timezone is incorrect');
        System.assertEquals(boxUser.space_amount + '', '999999999999999', 'The attribute space_amount is incorrect');
        System.assertEquals(boxUser.space_used, 9, 'The attribute space_used is incorrect');
        System.assertEquals(boxUser.max_upload_size + '', '5368709120', 'The attribute max_upload_size is incorrect');
        System.assertEquals(boxUser.status, 'active', 'The attribute status is incorrect');
        System.assertEquals(boxUser.job_title, '', 'The attribute job_title is incorrect');
        System.assertEquals(boxUser.phone, '3246800000', 'The attribute phone is incorrect');
        System.assertEquals(boxUser.address, '', 'The attribute address is incorrect');
        System.assertEquals(
            boxUser.avatar_url,
            'https://app.box.com/api/avatar/large/25468066666',
            'The attribute avatar_url is incorrect'
        );

        System.assertEquals(boxUser.code, null, 'The attribute code is incorrect');
        System.assertEquals(boxUser.help_url, null, 'The attribute help_url is incorrect');
        System.assertEquals(boxUser.message, null, 'The attribute message is incorrect');
        System.assertEquals(boxUser.request_id, null, 'The attribute request_id is incorrect');
    }


    @isTest
    private static void createFolder_test() {
        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );
        mock.add(
            'https://api.box.com/2.0/folders/123456',
            '{"type":"folder","id":"206830131043","sequence_id":"0","etag":"0","name":"TestClass","created_at":"2023-05-09T08:19:17-07:00","modified_at":"2023-05-09T08:19:17-07:00","description":""' +
            ',"size":0,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"25468066666",' +
            '"name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"modified_by":{"type":"user","id":"25468066666","name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"trashed_at":null,' +
            '"purged_at":null,"content_created_at":"2023-05-09T08:19:17-07:00","content_modified_at":"2023-05-09T08:19:17-07:00","owned_by":{"type":"user","id":"25468066666","name":"Cristian Mejia",' +
            '"login":"cdmejia531@gmail.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active",' +
            '"item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}'
        );
        mock.setMock();

        Test.startTest();
        BoxUtils.createFolder('0', 'Test');
        Test.stopTest();
    }

    @isTest
    private static void moveFolder_test() {

        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );
        mock.add(
            'https://api.box.com/2.0/folders/123456',
            '{"type":"folder","id":"206830131043","sequence_id":"0","etag":"0","name":"TestClass","created_at":"2023-05-09T08:19:17-07:00","modified_at":"2023-05-09T08:19:17-07:00","description":""' +
            ',"size":0,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"25468066666",' +
            '"name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"modified_by":{"type":"user","id":"25468066666","name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"trashed_at":null,' +
            '"purged_at":null,"content_created_at":"2023-05-09T08:19:17-07:00","content_modified_at":"2023-05-09T08:19:17-07:00","owned_by":{"type":"user","id":"25468066666","name":"Cristian Mejia",' +
            '"login":"cdmejia531@gmail.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active",' +
            '"item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}'
        );
        mock.setMock();

        Test.startTest();
        BoxUtils.moveFolder('0', '123456');
        Test.stopTest();
    }

    @isTest
    private static void shareFolder_test() {
        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'https://api.box.com/2.0/collaborations',
            '{"type":"folder","id":"206830131043","sequence_id":"0","etag":"0","name":"TestClass","created_at":"2023-05-09T08:19:17-07:00","modified_at":"2023-05-09T08:19:17-07:00","description":""' +
            ',"size":0,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"25468066666",' +
            '"name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"modified_by":{"type":"user","id":"25468066666","name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"trashed_at":null,' +
            '"purged_at":null,"content_created_at":"2023-05-09T08:19:17-07:00","content_modified_at":"2023-05-09T08:19:17-07:00","owned_by":{"type":"user","id":"25468066666","name":"Cristian Mejia",' +
            '"login":"cdmejia531@gmail.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active",' +
            '"item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}'
        );
        mock.setMock();

        Test.startTest();
        BoxUtils.shareFolderFile('folder', '0', 'Test@gmail.com', 'editor');
        Test.stopTest();
    }


    @isTest
    private static void shareFolderFileUserApp_test() {
        Contact objContact = new Contact();
        objContact.Email = 'Test@gmail.com';
        objContact.LastName = 'test';
        objContact.Xometry_ERP_Contact_ID__c = '1234567';
        insert objContact;

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'GET',
            'callout:Box_Rest_API/2.0/users?external_app_user_id=1234567',
            '{"total_count":1,"entries":[{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}],"limit":30,"offset":0}'
        );

        mock.add(
            'https://api.box.com/2.0/collaborations',
            '{"type":"folder","id":"206830131043","sequence_id":"0","etag":"0","name":"TestClass","created_at":"2023-05-09T08:19:17-07:00","modified_at":"2023-05-09T08:19:17-07:00","description":""' +
            ',"size":0,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"25468066666",' +
            '"name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"modified_by":{"type":"user","id":"25468066666","name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"trashed_at":null,' +
            '"purged_at":null,"content_created_at":"2023-05-09T08:19:17-07:00","content_modified_at":"2023-05-09T08:19:17-07:00","owned_by":{"type":"user","id":"25468066666","name":"Cristian Mejia",' +
            '"login":"cdmejia531@gmail.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active",' +
            '"item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}'
        );

        mock.setMock();

        Test.startTest();
        BoxUtils.shareFolderFileUserApp('folder', '0', 'Test@gmail.com', 'editor');
        Test.stopTest();
    }

    @isTest
    private static void shareFolderFileUserApp_UserNotFoundError_test() {
        
        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'GET',
            'callout:Box_Rest_API/2.0/users?external_app_user_id=1234567',
            '{"total_count":1,"entries":[{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}],"limit":30,"offset":0}'
        );

        mock.add(
            'https://api.box.com/2.0/collaborations',
            '{"type":"folder","id":"206830131043","sequence_id":"0","etag":"0","name":"TestClass","created_at":"2023-05-09T08:19:17-07:00","modified_at":"2023-05-09T08:19:17-07:00","description":""' +
            ',"size":0,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"25468066666",' +
            '"name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"modified_by":{"type":"user","id":"25468066666","name":"Cristian Mejia","login":"cdmejia531@gmail.com"},"trashed_at":null,' +
            '"purged_at":null,"content_created_at":"2023-05-09T08:19:17-07:00","content_modified_at":"2023-05-09T08:19:17-07:00","owned_by":{"type":"user","id":"25468066666","name":"Cristian Mejia",' +
            '"login":"cdmejia531@gmail.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active",' +
            '"item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}'
        );

        mock.setMock();

        Test.startTest();
        boolean exceptionThrown = false;
        try {
            BoxUtils.shareFolderFileUserApp('folder', '0', 'Test@gmail.com', 'editor');
        } catch (Exception ex) {
            System.assertEquals('Not found user with this email', ex.getMessage());
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception not encountered');
        Test.stopTest();
    }
    
    @isTest
    private static void shareFolderFileUserApp_UserCollaboratorError_test() {
        Contact objContact = new Contact();
        objContact.Email = 'Test@gmail.com';
        objContact.LastName = 'test';
        objContact.Xometry_ERP_Contact_ID__c = '1234567';
        insert objContact;

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'GET',
            'callout:Box_Rest_API/2.0/users?external_app_user_id=1234567',
            '{"total_count":1,"entries":[{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}],"limit":30,"offset":0}'
        );

        mock.add(
            'POST',
            'https://api.box.com/2.0/collaborations',
            '{"type":"error","status":400,"code":"user_already_collaborator","help_url":"http://developers.box.com/docs/#errors","message":"User is already a collaborator","request_id":"0000000000000"}',
            400 
        );

        mock.setMock();

        boolean exceptionThrown = false;
        Test.startTest();
        try {
            BoxUtils.shareFolderFileUserApp('folder', '0', 'Test@gmail.com', 'editor');    
        } catch (Exception ex) {
            System.assertEquals('User is already a collaborator', ex.getMessage());   
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Exception not encountered');
    }

    @isTest
    private static void shareFolderFileUserApp_invalidParameterError_test() {
        Contact objContact = new Contact();
        objContact.Email = 'Test@gmail.com';
        objContact.LastName = 'test';
        objContact.Xometry_ERP_Contact_ID__c = '1234567';
        insert objContact;

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'GET',
            'callout:Box_Rest_API/2.0/users?external_app_user_id=1234567',
            '{"total_count":1,"entries":[{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}],"limit":30,"offset":0}'
        );

        mock.add(
            'POST',
            'https://api.box.com/2.0/collaborations',
            '{"type":"error","status":400,"code":"bad_request","context_info":{"errors":[{"reason":"invalid_parameter","name":"role","message":"Invalid value \'Viewer Uploader\'."}]},"help_url":"http://developers.box.com/docs/#errors","message":"Bad Request","request_id":"0000000000000"}',
            400 
        );

        mock.setMock();

        boolean exceptionThrown = false;
        Test.startTest();
        try {
            BoxUtils.shareFolderFileUserApp('folder', '0', 'Test@gmail.com', 'editor');    
        } catch (Exception ex) {
            System.assertEquals('Invalid value \'Viewer Uploader\'.', ex.getMessage());   
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Exception not encountered');
    }

    @isTest
    private static void search_test() {
        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );
        mock.add(
            'GET',
            'https://api.box.com/2.0/search?TestFile',
            '{"total_count":1,"entries":[{"type":"folder","id":"207199824323","etag":"0","name":"Test01"}],"limit":30,"offset":0}'    
        );
        mock.setMock();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        ResultSearchBox.Root objResult = BoxUtils.search('TestFile');
        Test.stopTest();

        System.debug(objResult);
        System.debug(objResult.total_count);
        System.assertEquals(objResult.total_count, 1, 'The attribute total_count is incorrect');
    }

    @isTest
    private static void createUser_test() {

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/users',
            '{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}'     
        );

        mock.setMock();

        Test.startTest();
        BoxUser.CreateUserRequest reqCreateUser = new BoxUser.CreateUserRequest();
        reqCreateUser.name = 'Test';
        reqCreateUser.login = 'Test@gmail.com';
        reqCreateUser.external_app_user_id = 'Test@gmail.com';
        reqCreateUser.job_title = 'Test';
        BoxUtils.createUser(reqCreateUser);
        Test.stopTest();
    }

    @isTest
    private static void getItemsFolder_test() {

        CustomMockResponse mock = new CustomMockResponse();
        mock.add(
            'GET',
            'https://api.box.com/2.0/folders/0/items',
            '{"total_count":4,"entries":[{"type":"folder","id":"208237848937","sequence_id":"0","etag":"0","name":"500Dp000004B8wAIAS"},' +
            '{"type":"folder","id":"208121501684","sequence_id":"0","etag":"0","name":"500DT0000085oNHYAY"},' +
            '{"type":"folder","id":"207367730719","sequence_id":"0","etag":"0","name":"PartialDev - Xometry"},' +
            '{"type":"folder","id":"208239458835","sequence_id":"0","etag":"0","name":"testFolder"}],' +
            '"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}'
        );
        mock.setMock();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        BoxUtils.getItemsFolder('0');
        Test.stopTest();
    }

    @isTest
    private static void getFolderIdByRecordId_test() {
        // MockHttpResponseHandler mock = initMock();

        Test.startTest();
        // Test.setMock(HttpCalloutMock.class, mock);
        Case testCase = new Case(SuppliedEmail = 'test@test.com', RecordTypeId = AppConstants.casePSERecordTypeId);
        insert testCase;
        BoxUtils.getFolderIdByRecordId(testCase.Id);
        Test.stopTest();
    }

    @isTest
    private static void addCollaborator_test() {

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/collaborations',
            '{"type":"collaboration","id":"cascadePolicyId","created_by":null,"created_at":"2023-05-30T12:19:11-07:00","modified_at":"2023-05-30T12:19:11-07:00","expires_at":null,"status":"accepted",' +
            '"accessible_by":{"type":"group","id":"15522017485","name":"Salesforce_Box_User","group_type":"managed_group"},"invite_email":null,"role":"editor","acknowledged_at":"2023-05-30T12:19:11-07:00",' +
            '"item":{"type":"folder","id":"210257285694","sequence_id":"0","etag":"0","name":"02523762"},"is_access_only":false}'
        );

        mock.setMock();

        Test.startTest();
        BoxUtils.addCollaborator('B0xF0ld3rId', 'folder', 'Us3r0rGr0upId', 'group', 'editor');
        Test.stopTest();
    }

    @isTest
    private static void addLabelClassificationToFolder_test() {

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/folders/ITARInternal/metadata/enterprise/securityClassification-6VMVochwUWo',
            '{"type":"collaboration","id":"cascadePolicyId","created_by":null,"created_at":"2023-05-30T12:19:11-07:00","modified_at":"2023-05-30T12:19:11-07:00","expires_at":null,"status":"accepted",' +
            '"accessible_by":{"type":"group","id":"15522017485","name":"Salesforce_Box_User","group_type":"managed_group"},"invite_email":null,"role":"editor","acknowledged_at":"2023-05-30T12:19:11-07:00",' +
            '"item":{"type":"folder","id":"210257285694","sequence_id":"0","etag":"0","name":"02523762"},"is_access_only":false}'
        );

        mock.setMock();

        Test.startTest();
        BoxUtils.addLabelClassificationToFolder('nonITARInternal', 'label');
        Test.stopTest();
    }

    @isTest
    private static void addCascadePolicyToFolder_test() {

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/metadata_cascade_policies',
            '{"type":"collaboration","id":"cascadePolicyId","created_by":null,"created_at":"2023-05-30T12:19:11-07:00","modified_at":"2023-05-30T12:19:11-07:00","expires_at":null,"status":"accepted",' +
            '"accessible_by":{"type":"group","id":"15522017485","name":"Salesforce_Box_User","group_type":"managed_group"},"invite_email":null,"role":"editor","acknowledged_at":"2023-05-30T12:19:11-07:00",' +
            '"item":{"type":"folder","id":"210257285694","sequence_id":"0","etag":"0","name":"02523762"},"is_access_only":false}'
        );

        mock.setMock();

        Test.startTest();
        BoxUtils.addCascadePolicyToFolder('itarInternalFolderId');
        Test.stopTest();
    }

    @isTest
    private static void forceCascadePolicy_test() {

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/metadata_cascade_policies/cascadePolicyId/apply',
            '{"type":"collaboration","id":"cascadePolicyId","created_by":null,"created_at":"2023-05-30T12:19:11-07:00","modified_at":"2023-05-30T12:19:11-07:00","expires_at":null,"status":"accepted",' +
            '"accessible_by":{"type":"group","id":"15522017485","name":"Salesforce_Box_User","group_type":"managed_group"},"invite_email":null,"role":"editor","acknowledged_at":"2023-05-30T12:19:11-07:00",' +
            '"item":{"type":"folder","id":"210257285694","sequence_id":"0","etag":"0","name":"02523762"},"is_access_only":false}'
        );

        mock.setMock();

        Test.startTest();
        BoxUtils.forceCascadePolicy('cascadePolicyId');
        Test.stopTest();
    }

    @isTest
    private static void getAccessToken_test() {
        BoxAuthenticationSettings__c customSetting = new BoxAuthenticationSettings__c();
        customSetting.clientId__c = 'clientId';
        customSetting.clientSecret__c = 'clientSecret';
        customSetting.enterpriseId__c = 'enterpriseId';
        insert customSetting;

        CustomMockResponse mock = new CustomMockResponse(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );
        mock.setMock();

        Test.startTest();
        String strToken = BoxUtils.getAccessToken();
        Test.stopTest();

        System.assertEquals('*******************', strToken, 'Mock token expected');
    }

}