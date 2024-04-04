public with sharing class emailLauncher implements Queueable {
    private set<ID> caseIDToEmailSet;
    private Map<ID, String> eudCaseToOrderMap;
    private List<Order_ERP__C> inOrdersList;
    private Integer retryCount;
    private final Integer retryMaxCount = 2;

    public emailLauncher(set<ID> caseIDToEmailSet, Map<ID, String> eudCaseToOrderMap, List<Order_ERP__C> inOrdersList, Integer retryCount) {
        this.CaseIDToEmailSet = caseIDToEmailSet;
        this.eudCaseToOrderMap = eudCaseToOrderMap;
        this.inOrdersList = inOrdersList;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        Integer emailChunkSize = 20;
        System.debug('Email launcher has fired');
        //Main Logic
        Set<ID> eudCaseIdNow = new Set<ID>();
        Set<ID> eudCaseIdLater = new Set<ID>();
        Map<ID, String> eudCaseToOrderMapLater = new Map<ID, String>();

        //Break apart the email chunks into emailChunkSize Limit and chunk the next set into a Later future call
        for (ID caseId : eudCaseToOrderMap.keySet()) {
            if (eudCaseIdNow.size() < emailChunkSize) {
                eudCaseIdNow.add(caseId);
            } else {
                eudCaseIdLater.add(caseId);
                eudCaseToOrderMapLater.put(caseId, eudCaseToOrderMap.get(caseId));
            }
        }

        //process some cases now
        if ( !eudCaseIdNow.isEmpty() ) {
            List<Id> caseProcessFailedResult = OrderERPHandler.sendEUDEmail(eudCaseIdNow);
            if(!caseProcessFailedResult.isEmpty()){
                retryCount++;
                for(Id caseId : caseProcessFailedResult){
                    eudCaseIdLater.add(caseId);
                    eudCaseToOrderMapLater.put(caseId, eudCaseToOrderMap.get(caseId));
                }
            }
        }

        if ( !eudCaseIdLater.isEmpty() && retryCount <= retryMaxCount ) {

            //chunk the next set into another future call
            if (!Test.isRunningTest()) {
                ID jobID = System.enqueueJob(new emailLauncher(eudCaseIdLater, eudCaseToOrderMapLater, inOrdersList, retryCount));
            }

        }else{

            if( !eudCaseIdLater.isEmpty() ){

                List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();
                for(Id caseId : eudCaseIdLater){
                    Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
                    auditError.Module__c = 'emailLauncher.execute';
                    auditError.Dev_Audit_Notes__c = 'Pending EUD Email';
                    auditError.SourceId__c = caseId;
                    auditError.errorMessage__c = 'RetryCount exceeded our limit.';
                    auditErrorList.add(auditError);
                }

                insert auditErrorList;

            }

            // pass empty set and map
            if (!Test.isRunningTest()) {
                orderQLauncherHelper.queLauncherFirer(
                    inOrdersList,
                    'emailComplete',
                    new Map<ID, String>(),
                    new List<Case>()
                );
            }

        }

    }
}