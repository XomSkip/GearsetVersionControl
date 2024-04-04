public with sharing class AccountDunsHelper {
    /**
     * @description maps object to account based on DUNS Number
     * @param dunsObjToMap a list of DUNS numbers
     */
    public static Map<String, DUNSData> DunsAccountRouting(List<DUNSData> dunsObjToMap) {
        Set<String> DUNSNumberSet = new Set<String>();
        Map<String, DUNSData> objMapWithMatchedOwner = new Map<String, DUNSData>();

        for (DUNSData dd : dunsObjToMap) {
            if (!String.isBlank(dd.userDUNSNumber)) {
                DUNSNumberSet.add(dd.userDUNSNumber);
            }
            if (!String.isBlank(dd.userParentDUNSNumber)) {
                DUNSNumberSet.add(dd.userParentDUNSNumber);
            }
            if (!String.isBlank(dd.userUltimateDUNSNumber)) {
                DUNSNumberSet.add(dd.userUltimateDUNSNumber);
            }
            dd.domain = dd.domain.toLowerCase();
        }

        Map<String, Map<String, Account>> DUNSAcctRetMap = new Map<String, Map<String, Account>>();
        Map<String, Account> acctsWithMatchingDUNS = new Map<String, Account>();
        for (Account a : [
            SELECT Id, DNBConnect__D_B_Connect_Company_Profile__r.DNBConnect__DUNSNumber__c, Name, Email_Domain__c, OwnerId
            FROM Account
            WHERE DNBConnect__D_B_Connect_Company_Profile__r.DNBConnect__DUNSNumber__c IN :DUNSNumberSet
            ORDER BY CreatedDate ASC
        ]) {
            if (!String.isBlank(a.DNBConnect__D_B_Connect_Company_Profile__r.DNBConnect__DUNSNumber__c)) {
                if (a.Email_Domain__c == null && !acctsWithMatchingDUNS.containsKey('No Domain')) {
                    acctsWithMatchingDUNS.put('No Domain', a);
                } else if (a.Email_Domain__c != null) {
                    acctsWithMatchingDUNS.put(a.Email_Domain__c.toLowerCase(), a);
                }
            }
            DUNSAcctRetMap.put(a.DNBConnect__D_B_Connect_Company_Profile__r.DNBConnect__DUNSNumber__c, acctsWithMatchingDUNS);
        }

        for (DUNSData dd : dunsObjToMap) {
            Boolean matched = false;
            // DUNS
            if (DUNSAcctRetMap.containsKey(dd.userDUNSNumber)) {
                if (
                    DUNSAcctRetMap.get(dd.userDUNSNumber).size() > 1 &&
                    DUNSAcctRetMap.get(dd.userDUNSNumber).containsKey(dd.domain)
                ) {
                    Account a = DUNSAcctRetMap.get(dd.userDUNSNumber).get(dd.domain);
                    dd.OwnerId = a.OwnerId;
                    dd.accountId = a.Id;
                    dd.matchedDuns = dd.userDUNSNumber;
                    matched = true;
                    objMapWithMatchedOwner.put(dd.sourceId, dd);
                }
                if (matched == false) {
                    Account a = DUNSAcctRetMap.get(dd.userDUNSNumber).values()[0];
                    dd.OwnerID = a.OwnerID;
                    dd.accountId = a.Id;
                    dd.matchedDuns = dd.userDUNSNumber;
                    matched = true;
                    objMapWithMatchedOwner.put(dd.sourceId, dd);
                }
            }            
        }
        return objMapWithMatchedOwner;
    }
}