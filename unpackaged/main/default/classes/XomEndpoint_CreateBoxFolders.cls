@RestResource(urlMapping='/CreateBoxFolders/v1/*')
global with sharing class XomEndpoint_CreateBoxFolders {
    @HttpPost
    /**
     * @param caseId the id of the case to create the structure for
     */
    global static CreateFolderResponse makeFolderStructure(String caseId) {
        CreateFolderResponse result = BoxUserViewController.createFolder(caseId);
        return result;
    }
}