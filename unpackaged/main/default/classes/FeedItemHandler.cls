public with sharing class FeedItemHandler {

    /**
     * @description change Case status when new post is added to chatter
     *
     * @param newFeedItemsList - List with new values on triggered FeedItems
     */
    public static void InternalNotes(List<FeedItem> newFeedItemsList) {

        Set<String> systemUserIdSet = new Set<String>();
        systemUserIdSet.add(AppConstants.API_USER);
        systemUserIdSet.add(AppConstants.SALES_API_USER);
        String casePrefix = Case.sobjecttype.getDescribe().getKeyPrefix();

        Set<Id> caseIds = new Set<Id>();
        for(FeedItem newFeedItem:newFeedItemsList){
            if(String.valueOf(newFeedItem.ParentId).substring(0,3) == casePrefix && !systemUserIdSet.contains(newFeedItem.CreatedById) ){
                caseIds.add(newFeedItem.ParentId);
            }
        }

        if(!caseIds.isEmpty()){
            Set<Id> rTypeIdSet = new Set<Id>{
                AppConstants.casePSERecordTypeId, 
                AppConstants.collectionsRTypeId,
                AppConstants.caseSellerMarketPlaceRTypeId,
                AppConstants.caseFinServRTypeId 
            };

            List<Case> casesToUpList = new List<Case>();
            for (Case caseToUp : [SELECT Id FROM Case WHERE Id IN :caseIds AND Status = 'Pending' AND RecordTypeId NOT IN :rTypeIdSet]) {
                caseToUp.Status = 'Response Received';
                casesToUpList.add(caseToUp);
            }

            DatabaseUtilities.saveToDatabase(
                casesToUpList, 
                'FeedItemHandler.InternalNotes', 
                'Case from Pending to Response Received'
            );
        }
    
    }

}