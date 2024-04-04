public with sharing class updateNYOPCaseQue implements Queueable {
    private List<Case> casesToUpdateList = new List<Case>();
    private List<Case> nyopCaseCheckList = new List<Case>();
    Set<String> quoteIDCheckSet = new Set<String>();
    private String updateNYOPCaseName = 'updateNYOPCaseQue.execute';
    private String updateNYOPCaseQue_DEV_NOTE = 'Updating NYOP Cases with Parent Case';
    private Map<String, Case> xomQuoteIDCaseMap = new Map<String, Case>();
    public updateNYOPCaseQue(List<Case> inCaseList) {
        nyopCaseCheckList.addAll(inCaseList);
    }
    public void execute(QueueableContext context) {
        for (Case nyopCase : nyopCaseCheckList) {
            quoteIDCheckSet.add(nyopCase.Shadow_Xometry_ERP_ID__C);
        }
        if (!quoteIDCheckSet.isEmpty()) {
            xomQuoteIDCaseMap = CaseHandler.getPSECasebyXomQuote(quoteIDCheckSet);

            if (!xomQuoteIDCaseMap.isEmpty()) {
                CaseHandler.nyopAddParentCase(nyopCaseCheckList, xomQuoteIDCaseMap);
                for (Case c : nyopCaseCheckList) {
                    if (!String.isblank(c.ParentID)) {
                        casesToUpdateList.add(c);
                    }
                }
                DatabaseUtilities.saveToDatabase(casesToUpdateList, updateNYOPCaseName, updateNYOPCaseQue_DEV_NOTE);
            }
        }
    }
}