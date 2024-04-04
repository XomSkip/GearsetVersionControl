@RestResource(urlMapping='/boxUsers/v2/*')
global with sharing class boxIntSearch_v2 {
    global class SearchResponse {
        public SearchResponse() {
        }
        public string boxUserId { get; set; }
        public string status { get; set; }
        public string error { get; set; }
    }
    @HttpGet
    global static SearchResponse boxIntSearch() {
        // grab the caseId from the end of the URL
        RestRequest request = RestContext.request;
        SearchResponse resp = new SearchResponse();
        string boxUserId;
        String erpUser = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        BoxUser.Entry myUser = BoxUtils.getBoxUser(erpUser);
        if (myUser != null) {
            resp.boxUserId = myUser.id;
            resp.status = 'Success';
        } else {
            resp.boxUserId = null;
            resp.status = 'Error';
            resp.error = 'No Box User found';
        }
        return resp;
    }
}