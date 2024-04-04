@RestResource(urlMapping='/boxUsers/*')
global with sharing class boxIntSearch {
    @HttpGet
    global static string boxIntSearch() {
        // grab the caseId from the end of the URL
        RestRequest request = RestContext.request;
        string boxUserId;
        String erpUser = request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        BoxUser.Entry myUser = BoxUtils.getBoxUser(erpUser);
        if (myUser != null) {
            boxUserId = myUser.id;
        }
        return boxUserId;
    }
}