public with sharing class OAuthServicesUtils {
    /**
     * @description Sends request to Auth0.com 
     * for an access token to Xometry  for Salesforce App
     */
    public static String getAccessTokenCredentials() {

    	String response = '';

		Map<String,String> payloadMap = new Map<String,String>();
		payloadMap.put('client_id','{!$Credential.UserName}');
		payloadMap.put('client_secret','{!$Credential.Password}');
		payloadMap.put('audience','https://services.xometry.com');
		payloadMap.put('grant_type','client_credentials');

		// define transaction variables
		HttpRequest req = new HttpRequest();

		// Configure the request
		//calling auth0.com/oauth/token
		req.setEndpoint('callout:XometryServicesOAuth/oauth/token');
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setBody( JSON.serialize(payloadMap) );
		HttpResponse res = new Http().send(req);

        if (
            (res.getStatusCode() == 200 ||
            res.getStatusCode() == 201) &&
            res.getBody() != null &&
            res.getBody() != null
        ) {
            Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (responseBodyMap.containsKey('access_token')) {
                response = (String) responseBodyMap.get('access_token');
            }
        }

        return response;
    }

}