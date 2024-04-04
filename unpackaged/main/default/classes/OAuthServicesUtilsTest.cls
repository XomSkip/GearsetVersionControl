@isTest
public class OAuthServicesUtilsTest {


	@isTest(seeAllData=false)
	public static void getAccessTokenCredentials(){

		CustomMockResponse cMockResponse = new CustomMockResponse(
			'callout:XometryServicesOAuth/oauth/token',
			'{"access_token":"XXXXXxxxXXXX.XXXXXxxxXXXX","scope":"manage:box","expires_in":900,"token_type":"Bearer"}'
		);

        cMockResponse.setMock();

		String testResponse;
        Test.startTest();
		testResponse = OAuthServicesUtils.getAccessTokenCredentials();
        Test.stopTest();

        Assert.areEqual('XXXXXxxxXXXX.XXXXXxxxXXXX', testResponse, 'AuthToken should be returned');

	}
    
}