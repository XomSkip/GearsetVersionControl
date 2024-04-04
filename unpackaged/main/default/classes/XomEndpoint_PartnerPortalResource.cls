@RestResource(urlMapping='/PartnerPortalResource/v1/*')
global with sharing class XomEndpoint_PartnerPortalResource {
    /**
     * @description Creates cases for Partner Portal Questions/Issues
     * @param replyAddress --Supplier provided email address
     * @param eventOrigin - Where was the request sent from (Currently Available: Issue or Question)
     * @param bucket - Main category selection
     * @param subbucket - Subcategory selection
     * @param subject - Subject of concatenated string (from sampleNotification.json)
     * @param message - Supplier provided message with more information
     * @param jobID - Job ID
     * @param orderedPartID - Xom Ordered Part ID (not used yet)
     * @param partID - Customer Part ID (not used yet)
     * @param orderID - Order ID
     * @param fabricationStarted - Supplier has indicated if they have started fabricating the part
     * @param xomMaterials - Supplier has indicated that they are using Xom materials to manufacture the part
     * @param thirdPartyCreationID - AWS Event ID for traceability
     */
    @HttpPost
    global static Id createPartnerPortalCase(
        String replyAddress,
        String eventOrigin,
        String bucket,
        String subbucket,
        String subject,
        String message,
        String jobID,
        String orderedPartID,
        String partID,
        String orderID,
        Boolean fabricationStarted,
        Boolean xomMaterials,
        String thirdPartyCreationID
    ) {
        //Future: Creation ID and last updated Event ID  (for upserts)
        Id returnCaseID,
            jobRecordID,
            supplierRecordID,
            supplierAccountRecordID,
            supplierContactRecordID,
            opsOrderRecordID;
        String podQueueName;

        List<Case> existingCase = new List<Case>(
            [SELECT ID FROM Case WHERE ThirdPartyCreationID__c = :thirdPartyCreationID]
        );
        if (existingCase.isEmpty()) {
            List<Job__c> jobFinder = [
                SELECT ID, Supplier__c, Supplier__r.AccountID__c, Supplier__r.ContactID__c
                FROM Job__c
                WHERE XometryJobID__c = :jobID
                LIMIT 1
            ];
            if (!jobFinder.isEmpty()) {
                //TODO: Create a shell job if the PP event comes in before the Job
                jobRecordID = jobFinder[0].Id;
                supplierRecordID = jobFinder[0].Supplier__c;
                supplierAccountRecordID = jobFinder[0].Supplier__r.AccountID__c;
                supplierContactRecordID = jobFinder[0].Supplier__r.ContactID__c;
            }
            List<Ops_Order__c> opsOrderFinder = [
                SELECT ID, POD__c
                FROM Ops_Order__c
                WHERE XometryOpsOrderID__c = :orderID
                LIMIT 1
            ];
            if (!opsOrderFinder.isEmpty()) {
                opsOrderRecordID = opsOrderFinder[0].ID;
                if (String.isBlank(opsOrderFinder[0].POD__c)) {
                    podQueueName = 'First_Impressions';
                } else {
                    podQueueName = opsOrderFinder[0].POD__c.replace(' ', '_');
                }
            } else {
                podQueueName = 'First_Impressions';
            }

            Id queueGroupId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :podQueueName].Id;

            Case ppCase = new Case(
                RecordTypeID = AppConstants.caseManagementRTypeId,
                OwnerId = queueGroupId,
                Subject = subject,
                Status = 'New',
                Origin = 'Partner Portal',
                Type = eventOrigin,
                Category__c = 'PPU',
                SuppliedEmail = replyAddress,
                PP_EventOrigin__c = eventOrigin,
                PP_Message__c = message,
                PP_Bucket__c = bucket,
                PP_SubBucket__c = subbucket,
                PP_XometryMaterials__c = xomMaterials,
                PP_FabricationStarted__c = fabricationStarted,
                GNOOrder__c = opsOrderRecordID,
                Supplier__c = supplierRecordID,
                Job__c = jobRecordID,
                Ordered_Part_ID__c = orderedPartID,
                ShadowXometryJobID__c = jobID,
                ShadowXometryOrderID__c = orderID,
                OrderedPartID__c = orderedPartID,
                PartID__c = partID,
                ContactId = supplierContactRecordID,
                AccountId = supplierAccountRecordID,
                ThirdPartyCreationID__c = thirdPartyCreationID
            );

            insert ppCase;
            returnCaseID = ppCase.Id;
        } else {
            returnCaseID = existingCase[0].Id;
        }

        return returnCaseID;
    }
}