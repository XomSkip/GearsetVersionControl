public with sharing class BoxIntegrationServiceHelper {

    public static void processEvents(List<Box_Integration_Service__e> eventList) {

        Map<String, List<Box_Integration_Service__e>> caseNumberEventsMap = new Map<String, List<Box_Integration_Service__e>>();
        Map<String, List<Box_Integration_Service__e>> caseIdEventsMap = new Map<String, List<Box_Integration_Service__e>>();
        Map<String, Contact> actorMap = new Map<String, Contact>();
        
        for(Box_Integration_Service__e e : eventList){

            if(e.Actor__c != null){

                actorMap.put(e.Actor__c, null);

            }

            if( String.isNotBlank(e.Action__c) && e.Action__c.equalsIgnoreCase('fileUploaded') ){

                if( String.isNotBlank(e.CaseId__c) ){
                    if(!caseIdEventsMap.containsKey(e.CaseId__c)){
                        caseIdEventsMap.put(e.CaseId__c, new List<Box_Integration_Service__e>());
                    }
                    caseIdEventsMap.get(e.CaseId__c).add(e);
                }

                if( String.isBlank(e.CaseId__c) && String.isNotBlank(e.CaseNumber__c) ){
                    if(!caseNumberEventsMap.containsKey(e.CaseNumber__c)){
                        caseNumberEventsMap.put(e.CaseNumber__c, new List<Box_Integration_Service__e>());
                    }
                    caseNumberEventsMap.get(e.CaseNumber__c).add(e);
                }

            }

        }
        
        if(!caseIdEventsMap.isEmpty() || !caseNumberEventsMap.isEmpty()){

            for(Contact oneContact : [SELECT Id, Name, Xometry_ERP_Contact_ID__c FROM Contact WHERE Xometry_ERP_Contact_ID__c IN :actorMap.keySet()]){
                actorMap.put(oneContact.Xometry_ERP_Contact_ID__c, oneContact);
            }

            List<FeedItem> feedList = new List<FeedItem>();
            List<Case> caseToUpdateList = new List<Case>();

            for(Case caseToUpdate : [SELECT Id, CaseNumber FROM Case WHERE CaseNumber IN :caseNumberEventsMap.keySet() OR Id IN :caseIdEventsMap.keySet()]){

                List<Box_Integration_Service__e> eList = new List<Box_Integration_Service__e>();
                if( caseIdEventsMap.containsKey(caseToUpdate.Id) ){
                    eList.addAll( caseIdEventsMap.get(caseToUpdate.Id) );
                }
                if( caseNumberEventsMap.containsKey(caseToUpdate.CaseNumber) ){
                    eList.addAll( caseNumberEventsMap.get(caseToUpdate.CaseNumber) );
                } 

                for( Box_Integration_Service__e e : eList ){

                    FeedItem newFeed = new FeedItem();

                    newFeed.ParentId = caseToUpdate.Id;
                    newFeed.Body = e.Action__c + ' occurred in box.com by user: ' + e.Actor__c + '\n';

                    if( actorMap.containsKey(e.Actor__c) && actorMap.get(e.Actor__c) != null ){
                        newFeed.Body += 'Contact Name: ' + actorMap.get(e.Actor__c).Name + '\n';
                    }

                    newFeed.Body += 'Filename: ' + e.Filename__c + '\n';
                    newFeed.Body += 'FilePath: ' + e.Filepath__c + '\n';
                    newFeed.Body += 'Additional Information: ' + (!String.isBlank(e.Additional_Information__c) ? e.Additional_Information__c : '');
                    
                    feedList.add(newFeed);

                    if( e.Actor__c.containsIgnoreCase('Workcenter') ){
                        caseToUpdate.AttachmentStatus__c = 'Upload Complete';
                    }

                }

                caseToUpdate.Status = 'Response Received';
                
                caseToUpdateList.add(caseToUpdate);

            }

            DatabaseUtilities.insertToDatabase(
                feedList,
                'BoxIntegrationServiceHelper',
                'FeedItem added on Case'
            );

            DatabaseUtilities.saveToDatabase(
                caseToUpdateList,
                'BoxIntegrationServiceHelper',
                'Case Status Change'
            );

        }

    }
    
}