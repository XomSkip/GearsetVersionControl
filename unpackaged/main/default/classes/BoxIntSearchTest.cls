@isTest
private class BoxIntSearchTest {

    @isTest(seeAllData=false)
    static void boxIntSearch_Test() {

        CustomMockResponse mock = new CustomMockResponse();

        mock.add(
            'callout:Box_Rest_API/oauth2/token',
            '{"access_token":"*******************","expires_in":3960,"restricted_to":[],"token_type":"bearer"}'
        );

        mock.add(
            'GET',
            'callout:Box_Rest_API/2.0/users?external_app_user_id=US3RID',
            '{"total_count":1,"entries":[{"type":"user","id":"25468066000","name":"Mr Test","login":"test@gmail.com","created_at":"2023-05-04T04:34:12-07:00","modified_at":"2023-05-08T06:36:07-07:00","language":"en",' +
            '"timezone":"America/Los_Angeles","space_amount":999999999999999,"space_used":9,"max_upload_size":5368709120,"status":"active","job_title":"","phone":"3246800000","address":"",' +
            '"avatar_url":"https://app.box.com/api/avatar/large/25468066666","notification_email":[]}],"limit":30,"offset":0}'  
        );

        mock.setMock();

        RestRequest req = new RestRequest();
        
        req.requestURI = 'https://url.com/US3RID';
        RestContext.request = req;
            
        String boxUserId;

        Test.startTest();
        boxUserId = boxIntSearch.boxIntSearch();
        Test.stopTest();

        System.assertEquals('25468066000',boxUserId,'Box User Id not found');

    }

}