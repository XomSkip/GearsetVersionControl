public class CustomMockResponse implements HttpCalloutMock {

    Map<String,String> mockBodyResponseMap = new Map<String,String>();
    Map<String,Integer> mockStatusResponseMap = new Map<String,Integer>();

    public CustomMockResponse(){
    }

    public CustomMockResponse(String endpoint, String body){
    	add(endpoint, body);
    }

    public CustomMockResponse(String method, String endpoint, String body, Integer statusCode){
    	add(method, endpoint, body, statusCode);
    }

    public void add(String endpoint, String body){
    	add('POST', endpoint, body, 200);
    }
    public void add(String method, String endpoint, String body){
    	add(method, endpoint, body, 200);
    }

    public void add(String method, String endpoint, String body, Integer statusCode){

    	String endpointMethodKey = method + '_' + endpoint;
    	mockBodyResponseMap.put(endpointMethodKey, body);
    	mockStatusResponseMap.put(endpointMethodKey, statusCode);

    	System.debug(LoggingLevel.ERROR, '*** add endpointMethodKey: ' + endpointMethodKey);

    }

    public void setMock(){

        Test.setMock(
            HttpCalloutMock.class,
            this
        );

    }

    public HTTPResponse respond(HTTPRequest req) {

        HTTPResponse res = new HTTPResponse();

        String endpoint = req.getEndpoint();
        String method = req.getMethod();
    	String endpointMethodKey = method + '_' + endpoint;

    	System.debug(LoggingLevel.ERROR, '*** endpointMethodKey: ' + endpointMethodKey);
    	System.debug(LoggingLevel.ERROR, '*** contains: ' + endpointMethodKey);

    	for( String key : mockBodyResponseMap.keySet() ){

    		if(endpointMethodKey.contains(key)){
    			System.debug(LoggingLevel.ERROR, endpointMethodKey.contains(key));
            	res.setBody( mockBodyResponseMap.get(key) );
            	res.setStatusCode( mockStatusResponseMap.get(key) );
            	break;
    		}
    	}

        if( mockBodyResponseMap.containsKey(endpointMethodKey) ){
        }

    	System.debug(LoggingLevel.ERROR, '*** endpointMethodKey res: ' + res);
        System.debug(LoggingLevel.ERROR, '*** res.getBody: ' + res.getBody());


        return res;

    }
    
}