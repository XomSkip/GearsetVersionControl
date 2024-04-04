/**
 * @description Query all ContentVersion recods avoiding SOQL limits
 * and creates a document txt with results
 * @param libraryName folder on wich our document result will be created 
 */

 global class SumarizeDocumentsBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    public String query = 'SELECT ContentDocumentId, ContentSize FROM ContentVersion USING SCOPE Team WHERE IsLatest = TRUE';
    public String queryCDL = 'SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId';

    private Map<String,Map<String,Long>> objSumaryMap = new Map<String,Map<String,Long>>();

    public String libraryName = 'Batch Documents';
    Long totalLinks = 0;
    Long totalSize = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, list<ContentVersion> scope) {
        
        Map<Id,ContentVersion> cvMap = new Map<Id,ContentVersion>();
        for(ContentVersion oneCV : scope){
            cvMap.put(oneCV.ContentDocumentId, oneCV);
        }

        Set<Id> cvIdSet = cvMap.keySet();
        for( ContentDocumentLink cdl : Database.query( queryCDL + ' IN :cvIdSet ORDER BY ContentDocumentId' ) ){
            
            String objPrefix = String.valueOf(cdl.LinkedEntityId).substring(0,3);
            
            if( !objSumaryMap.containsKey(objPrefix) ){
                objSumaryMap.put( objPrefix, new Map<String,Long>() );
                objSumaryMap.get( objPrefix ).put( 'NLinks', 0 );
                objSumaryMap.get( objPrefix ).put( 'SizeMB', 0 );
            }

            Long nlinks = objSumaryMap.get( objPrefix ).get( 'NLinks' ) + 1;
            Long sizemb = objSumaryMap.get( objPrefix ).get( 'SizeMB' ) + cvMap.get(cdl.ContentDocumentId).ContentSize;
            totalSize += cvMap.get(cdl.ContentDocumentId).ContentSize;
            totalLinks++;

            objSumaryMap.get( objPrefix ).put( 'NLinks', nlinks );
            objSumaryMap.get( objPrefix ).put( 'SizeMB', sizemb );
        }

    }

    global void finish(Database.BatchableContext BC) {
        createSumarizeDocument();
    }

    private void createSumarizeDocument(){
        String fileOutput = 'objPrefix,objName,NLinks,%Links,SizeMB,Size%\n';

        if(!objSumaryMap.isEmpty()){

            for ( String objPrefix : objSumaryMap.keySet() ) {
                Map<String,Long> sumaryMap = objSumaryMap.get(objPrefix);
                String objName = ProcessExceptionViewController.findObjectNameFromRecordIdPrefix(objPrefix);
                fileOutput += objPrefix + ',' + objName + ',';
                fileOutput += sumaryMap.get('NLinks') + ',' + ( (100 * sumaryMap.get('NLinks')) / totalLinks ) + ',';
                fileOutput += ( sumaryMap.get('SizeMB') / 1048576 ) + ',' + ( (100 * sumaryMap.get('SizeMB')) / totalSize ) + '\n';
            }

            for(ContentWorkspace cw : [SELECT Name FROM ContentWorkspace WHERE Name = :libraryName LIMIT 1]){

                if(cw != null){
                    String fileName = 'SumarizeDocumentsBatch - ' + System.now().format('YYYYMMdd');
                    String searchFileName = fileName + '%';
                    Integer batchNumber = [SELECT Id FROM ContentVersion WHERE Title LIKE :searchFileName].size() + 1;

                    //Creating text document
                    fileName += ' - ' + String.valueOf(batchNumber);  
                    ContentVersion cv = new ContentVersion(
                        Title = fileName,
                        VersionData = Blob.valueOf(fileOutput),
                        PathOnClient = fileName + '.csv'
                    );

                    DatabaseUtilities.insertToDatabase(
                        new List<ContentVersion>{ cv },
                        'SumarizeDocumentsBatch',
                        'Creating sumary document as ContentVersion'
                    );

                    //Link document to Library
                    ContentVersion cvResult = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cvResult.ContentDocumentId;
                    cdl.LinkedEntityId = cw.Id;
                    cdl.Sharetype = 'I';

                    DatabaseUtilities.insertToDatabase(
                        new List<ContentDocumentLink>{ cdl },
                        'SumarizeDocumentsBatch',
                        'Sharing ContentVersion document on library'
                    );
                }
            }

        }

    }

    //Schedule
    global void execute(SchedulableContext sc) {
        SumarizeDocumentsBatch b = new SumarizeDocumentsBatch();
        b.libraryName = this.libraryName;
        Database.executebatch(b);
    }

}