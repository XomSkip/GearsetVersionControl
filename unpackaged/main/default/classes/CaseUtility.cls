public with sharing class CaseUtility {
    private static CaseUtility instance = null;
    private List<CaseStatus> caseStatuses = null;

    private CaseUtility() {
        this.caseStatuses = [SELECT Id, ApiName, IsClosed FROM CaseStatus];
        System.debug('Using CaseUtility');
    }

    public static CaseUtility getInstance() {
        if (instance == null) {
            instance = new CaseUtility();
        }
        return instance;
    }

    public Boolean isClosed(String status) {
        Boolean isClosed = false;

        for (CaseStatus caseStatus : this.caseStatuses) {
            if (status == caseStatus.ApiName && caseStatus.IsClosed) {
                isClosed = true;
            }
        }

        return isClosed;
    }
}