public with sharing class orderQLauncherHelper {

    public static String startContext = 'trigger';
    public static String emailComplete = 'emailComplete';
    public static String emailInProgress = 'emailInProgress';

    public static void queLauncherFirer(
        List<Order_ERP__C> inOrdersList,
        String queContext,
        Map<ID, String> eudCaseNeedEmailMap,
        List<Case> eudCaseNeedEmailCaseList
    ) {
        System.debug('Starting the queJob Context');
        System.debug('Here is the OrderList');
        System.debug('My queContext is : ' + queContext);
        System.debug(inOrdersList);

        if (queContext == startContext) {
            if (!eudCaseNeedEmailMap.isEmpty()) {
                System.debug('Getting ready to send future emails');
                Set<ID> caseIDToEmailSet = new Set<ID>();
                Map<ID, String> caseToOrderMiniMap = new Map<ID, String>();
                Integer counter = 0;
                for (Case myCase : eudCaseNeedEmailCaseList) {
                    caseIDToEmailSet.add(myCase.ID);
                    caseToOrderMiniMap.put(myCase.ID, eudCaseNeedEmailMap.get(myCase.ID));
                }
                ID jobID = System.enqueueJob(new emailLauncher(caseIDToEmailSet, caseToOrderMiniMap, inOrdersList, 0));
                eudCaseNeedEmailMap.clear();
                eudCaseNeedEmailCaseList.clear();
            } else {
                System.debug('No emails found Launching complete!');
                queLauncherFirer(inOrdersList, emailComplete, null, null);
            }
        }

        if (queContext == emailComplete) {
            if (!inOrdersList.isEmpty()) {
                // Check for Emails
                System.debug('Loading up the AggUpdates');
                ID jobID = System.enqueueJob(new ordAggUpdates(inOrdersList));
            }
        }

    }
}