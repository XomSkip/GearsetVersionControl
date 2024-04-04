@isTest
public class XomEndpoint_CreateBoxFoldersTest {
    @isTest
    public static void callCreatesCase() {

        Case c = new Case(SuppliedEmail = 'test@email.com', origin = 'Workcenter', type = 'Partner Portal');

        insert c;

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
            'GET',
            'https://api.box.com/2.0/folders/12345',
            '{"total_count":1,"entries":[{"type":"folder","id":"207199824323","etag":"0","name":"Test01"}],"limit":30,"offset":0}'
        );

        mock.add(
            'callout:Box_Rest_API/2.0/collaborations',
            '{"type":"collaboration","id":"cascadePolicyId","created_by":null,"created_at":"2023-05-30T12:19:11-07:00","modified_at":"2023-05-30T12:19:11-07:00","expires_at":null,"status":"accepted",' +
            '"accessible_by":{"type":"group","id":"15522017485","name":"Salesforce_Box_User","group_type":"managed_group"},"invite_email":null,"role":"editor","acknowledged_at":"2023-05-30T12:19:11-07:00",' +
            '"item":{"type":"folder","id":"210257285694","sequence_id":"0","etag":"0","name":"02523762"},"is_access_only":false}'
        );

        mock.setMock();

        Test.startTest();
        CreateFolderResponse result = XomEndpoint_CreateBoxFolders.makeFolderStructure(c.Id);
        Test.stopTest();
        
        System.assertEquals('Success', result.status, 'folder should return a success status');
    }
}