public without sharing class AccountHandler {
    /**
     * @description updates Drift_Domain__c custom URL type field used in mappings with Drift
     *
     * @param newAccountList - List with triggered accounts new values
     * @param accOldMap - Map with triggered accounts old values
     */
    public static void updateDriftDomain(List<Account> newAccountList, Map<Id, Account> accOldMap) {
        List<Account> accToCheck = new List<Account>();
        for (Account acc : newAccountList) {
            Boolean cond = Trigger.isInsert;
            Boolean cond2 =
                Trigger.isUpdate &&
                ((acc.Email_Domain__c != accOldMap.get(acc.Id).Email_Domain__c) ||
                (acc.Generic_Account__c != accOldMap.get(acc.Id).Generic_Account__c));

            if (!String.isBlank(acc.Email_Domain__c) && acc.Generic_Account__c != true && (cond || cond2)) {
                accToCheck.add(acc);
            }
        }

        if (!accToCheck.isEmpty()) {
            Map<String, String> accDomains = new Map<String, String>();
            for (Account acc : accToCheck) {
                //clean domain from email
                acc.Email_Domain__c = acc.Email_Domain__c;
                String cleanDomain = acc.Email_Domain__c;
                if (cleanDomain.contains('@')) {
                    cleanDomain = cleanDomain.split('@')[1];
                }
                accDomains.put(acc.Email_Domain__c, cleanDomain);
            }

            Set<String> eDomains = new Set<String>();
            for (Email_Domain__mdt eDomain : [
                SELECT Email_Domains__c
                FROM Email_Domain__mdt
                WHERE Email_Domains__c IN :accDomains.values()
            ]) {
                eDomains.add(eDomain.Email_Domains__c.toLowercase());
            }

            for (Account acc : accToCheck) {
                //check match with metadata blacklist
                if (!eDomains.contains(accDomains.get(acc.Email_Domain__c).toLowercase())) {
                    acc.Drift_Domain__c = accDomains.get(acc.Email_Domain__c);

                    // example of valid formats
                    // www.nongenericdomain.com sub.nongenericdomain.com www.nongenericdomain.co.uk
                    if ((acc.Drift_Domain__c.split('\\.').size() == 2)) {
                        acc.Drift_Domain__c = 'www.' + acc.Drift_Domain__c;
                    }
                }
            }
        }
    }

    /**
     * @description centering Account classification to one picklist,
     * this trigger runs before insert and set the initial value.
     *
     * @param newAccountList - List with triggered accounts new values
     */
    public static void setClasification(List<Account> newAccountList) {
        for (Account acc : newAccountList) {
            if (acc.Generic_Account__c) {
                acc.Account_Classification__c = 'Generic';
            }
            if (acc.Generic_BDR_RR_FLAG__c) {
                acc.Account_Classification__c = 'BDR';
            }
        }
    }

    /**
     * @description Do not let ‘xometry.com’ be the domain on any Account.
     *
     * @param newAccountList - List with triggered Account new values
     */
    public static void cleanDomain(List<Account> newAccountList) {
        for (Account l : newAccountList) {
            if (l.Email_Domain__C == 'xometry.com') {
                l.Email_Domain__C = null;
            }
        }
    }

    /**
     * @description Starts downstream events
     *
     * @param newAccountList - List with triggered Account new values
     * @param oldAccountMap - Map of old account values
     */
    public static void accountDownstream(List<Account> newAccountList, Map<Id, Account> oldAccountMap) {
        if (!EventBusBypass.isByPassed('accountDownstream')) {
            List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();

            for (Account a : newAccountList) {
                Account oldAccount = oldAccountMap.get(a.Id);
                if (oldAccount.OwnerId != a.OwnerId) {
                    Downstream_Event__e e = new Downstream_Event__e();
                    e.SourceId__c = a.Id;
                    e.OldOwner__c = oldAccount.OwnerId;
                    e.NewOwner__c = a.OwnerId;
                    e.Object__c = 'Account';
                    downstreamEvents.add(e);
                }
            }
            EventBus.publish(downstreamEvents);
        }
    }

    /**
     * @description Set the House_Retainer__c flag anytime an account is being set to Owner Success Team
     * @param newAccountList - List with triggered Account new values
     */
    public static void setHouseRetainer(List<Account> newAccountList) {
        for (Account act : newAccountList) {
            if (act.OwnerId == AppConstants.SALES_HOUSE_USER) {
                act.House_Retainer__c = true;
            }
        }
    }

    /**
     * @description updates SLA_Entitlement_Levels__c matching value with Parent Account
     *
     * @param newAccountList - List with triggered accounts new values
     * @param accOldMap - Map with triggered accounts old values
     */
    public static void updateSLASegment(List<Account> newAccountList, Map<Id, Account> accOldMap) {
        Map<Id,Account> parentsMap = new Map<Id,Account>();
        Map<Id,List<Account>> parentIdsWithChildsMap = new Map<Id,List<Account>>();

        for (Account acc : newAccountList) {
            //check if Parent changed 
            Boolean cond = Trigger.isInsert && Trigger.isBefore;
            Boolean cond2 = Trigger.isUpdate && Trigger.isBefore && acc.ParentId != accOldMap.get(acc.Id).ParentId;

            if ( acc.ParentId != null && (cond || cond2) ){
                if( !parentIdsWithChildsMap.containskey(acc.ParentId) ){
                    parentIdsWithChildsMap.put(acc.ParentId, new List<Account>());
                }
                parentIdsWithChildsMap.get(acc.ParentId).add(acc);
            }

            //check if SLA Entitlements changed 
            Boolean cond3 = Trigger.isUpdate && Trigger.isAfter;
            cond3 = cond3 && acc.SLA_Entitlement_Levels__c != accOldMap.get(acc.Id).SLA_Entitlement_Levels__c;
            cond3 = cond3 && acc.SLAPopulateSameLeveltoChildAcct__c == true;
            if ( acc.ParentId == null && cond3 ){
                parentsMap.put(acc.Id, acc);
            }

        }

        if (!parentIdsWithChildsMap.isEmpty() || !parentsMap.isEmpty()) {

            List<Account> accountsToUpdateList = new List<Account>();
            for (Account acc : [
                SELECT Id, ParentId, SLA_Entitlement_Levels__c 
                FROM Account 
                WHERE Id IN :parentIdsWithChildsMap.keySet()
                OR ParentId IN :parentsMap.keySet()
            ]) {

                //update SLA_Entitlement_Levels__c on child with values from new Parent
                if( parentIdsWithChildsMap.containsKey(acc.Id) ){
                    for( Account childAccount : parentIdsWithChildsMap.get(acc.Id) ){
                        childAccount.SLA_Entitlement_Levels__c = acc.SLA_Entitlement_Levels__c;
                    }
                }

                //update SLA_Entitlement_Levels__c on child with new values on Parent
                if( parentsMap.containsKey(acc.ParentId) ){
                    acc.SLA_Entitlement_Levels__c = parentsMap.get(acc.ParentId).SLA_Entitlement_Levels__c;
                    accountsToUpdateList.add(acc);
                }

            }

            DatabaseUtilities.saveToDatabase(
                accountsToUpdateList,
                'AccountHandler.updateSLASegment',
                'Updating SLA_Entitlement_Levels__c on child Accounts'
            );

        }
    }

}