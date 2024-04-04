/* **************************************************************************
* Copyright © 2015-2021, Neilon Technologies LLP
* All rights reserved
*
* Controller Class: S3LinkCustomActionImpl
* Created by Suresh Meghnathi: 22/04/2021
*
* - Used as interface for custom actions added for files and folders in S3-File Search and S3-File Explorer components.

* - Modifications:
* - Suresh Meghnathi, 22/04/2021 – Initial Development
************************************************************************** */
global without sharing class S3LinkCustomActionImpl implements NEILON.S3LinkCustomActionInterface {
    /**
     * @description To create Amazon S3 migration reports for large Salesforce files(>11 MB)
     * @param action selected action to perform
     * @param recordIds s3 file ids
     * @param parentRecordId case Id
     * @param data
     */
    public String execute(String action, List<String> recordIds, String parentRecordId, String data) {
        if (String.isNotBlank(parentRecordId) && action == 'add_to_account') {
            CustomActionResponse response = new CustomActionResponse();
            List<Case> cases = [SELECT Id, AccountId FROM Case WHERE Id = :parentRecordId];
            if (!cases.isEmpty()) {
                if (cases[0].AccountId != null) {
                    NEILON__Folder__c folder = NEILON.apGlobalUtils.buildFolderArchitecture(cases[0].AccountId);
                    NEILON.apGlobalUtils.copyFiles(new Set<String>(recordIds), folder.Id);
                    response.status = 'success';
                    response.message = 'The file is added to account successfully';
                } else {
                    response.status = 'error';
                    response.message = 'No account available for this case';
                }
            } else {
                response.status = 'error';
                response.message = 'We cannot find the case. Please contact support team';
            }
            return JSON.serialize(response);
        }
        return null;
    }

    public class CustomActionResponse {
        public String status;
        public String code;
        public String message;
        public String data;
    }
}