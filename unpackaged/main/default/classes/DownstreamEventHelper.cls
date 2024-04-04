public with sharing class DownstreamEventHelper {
    static final ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final Set<String> teamRoleStringSet = accountTeamHandler.getAteamDownstreamRoles();

    public static void processEvents(List<Downstream_Event__e> eventList) {
        List<Downstream_Event__e> accountEventsToStart = new List<Downstream_Event__e>();
        List<Downstream_Event__e> contactEventsToStart = new List<Downstream_Event__e>();
        List<Downstream_Event__e> acctTeamEventsToStart = new List<Downstream_Event__e>();
        List<Downstream_Event__e> projectEventsToStart = new List<Downstream_Event__e>();
        List<Downstream_Event__e> aTeamDeleteEventsToStart = new List<Downstream_Event__e>();
        for (Downstream_Event__e e : eventList) {
            if (e.OldOwner__c != e.NewOwner__c) {
                if (e.Object__c == 'Account') {
                    accountEventsToStart.add(e);
                }
                if (e.Object__c == 'Contact') {
                    contactEventsToStart.add(e);
                }
                if (e.Object__c == 'Account_Team__C') {
                    acctTeamEventsToStart.add(e);
                }
                if (e.Object__C == 'Account_Team__C_Delete') {
                    aTeamDeleteEventsToStart.add(e);
                }
                if (e.Object__c == 'Project') {
                    projectEventsToStart.add(e);
                }
            }
        }

        if (!accountEventsToStart.isEmpty()) {
            Map<Id, Id> newOwnerIdByObjectIdMap = new Map<Id, Id>();
            Map<Id, Id> oldOwnerIdByObjectIdMap = new Map<Id, Id>();
            Set<Id> accountIdSet = new Set<Id>();
            for (Downstream_Event__e e : accountEventsToStart) {
                accountIdSet.add(e.SourceId__c);
                newOwnerIdByObjectIdMap.put(e.SourceId__c, e.NewOwner__c);
                oldOwnerIdByObjectIdMap.put(e.SourceId__c, e.OldOwner__c);
            }
            startAccountDownstream(newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap, accountIdSet);
        }
        if (!contactEventsToStart.isEmpty()) {
            Map<Id, Id> newOwnerIdByObjectIdMap = new Map<Id, Id>();
            Map<Id, Id> oldOwnerIdByObjectIdMap = new Map<Id, Id>();
            Set<Id> accountIdSet = new Set<Id>();
            for (Downstream_Event__e e : contactEventsToStart) {
                newOwnerIdByObjectIdMap.put(e.SourceId__c, e.NewOwner__c);
                oldOwnerIdByObjectIdMap.put(e.SourceId__c, e.OldOwner__c);
            }
            for (Contact c : [SELECT AccountId FROM Contact WHERE Id IN :newOwnerIdByObjectIdMap.keySet()]) {
                accountIdSet.add(c.AccountId);
            }
            startContactDownstream(newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap, accountIdSet);
        }
        if (!acctTeamEventsToStart.isEmpty()) {
            Map<Id, Id> newOwnerIdByObjectIdMap = new Map<Id, Id>();
            Map<Id, Id> oldOwnerIdByObjectIdMap = new Map<Id, Id>();
            Set<Id> accountIdSet = new Set<ID>();
            for (Downstream_Event__e e : acctTeamEventsToStart) {
                accountIdSet.add(e.SourceId__c);
                newOwnerIdByObjectIdMap.put(e.SourceId__c, e.NewOwner__c);
                oldOwnerIdByObjectIdMap.put(e.SourceId__c, e.OldOwner__c);
            }
            startAteamDownstream(newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap, accountIdSet);
        }
        if (!aTeamDeleteEventsToStart.isEmpty()) {
            Map<Id, Id> newOwnerIdByObjectIdMap = new Map<Id, Id>();
            Map<Id, Id> oldOwnerIdByObjectIdMap = new Map<Id, Id>();
            Set<Id> accountIdSet = new Set<ID>();
            for (Downstream_Event__e e : aTeamDeleteEventsToStart) {
                accountIdSet.add(e.SourceId__c);
                newOwnerIdByObjectIdMap.put(e.SourceId__c, e.NewOwner__c);
                oldOwnerIdByObjectIdMap.put(e.SourceId__c, e.OldOwner__c);
            }
            startAteamDeleteDownstream(newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap, accountIdSet);
        }
        if (!projectEventsToStart.isEmpty()) {
            Map<Id, Id> newOwnerIdByObjectIdMap = new Map<Id, Id>();
            Map<Id, Id> oldOwnerIdByObjectIdMap = new Map<Id, Id>();
            Set<Id> accountIdSet = new Set<Id>();
            for (Downstream_Event__e e : projectEventsToStart) {
                newOwnerIdByObjectIdMap.put(e.SourceId__c, e.NewOwner__c);
                oldOwnerIdByObjectIdMap.put(e.SourceId__c, e.OldOwner__c);
            }
            for (Project__c p : [SELECT AccountId__c FROM Project__c WHERE Id IN :newOwnerIdByObjectIdMap.keySet()]) {
                accountIdSet.add(p.AccountId__c);
            }
            startProjectDownstream(newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap, accountIdSet);
        }
    }

    /**
     * @description Queries child accounts owner is a CSAM where parents' owners have changed and owner is a CSAM,
     * updates owner to parent owner, adds account to newOwnerIdByObjectIdMap for processing
     * contacts and opps, then updates accounts
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Account Id
     */
    public static void processAteamAccounts(Map<Id, Id> newOwnerIdByObjectIdMap, Map<Id, Id> oldOwnerIdByObjectIdMap) {
        List<Account> accountsToUpdateList = new List<Account>();
        //Get a list of all child accounts that are owned by a CSAM
        Map<Id, Account> childAccountsToUpdateMap = new Map<Id, Account>(
            [
                SELECT Id, OwnerId, ParentId, Owner.UserRole.Name
                FROM Account
                WHERE ParentId IN :newOwnerIdByObjectIdMap.keySet()
                FOR UPDATE
            ]
        );
        for (Account thisAccount : childAccountsToUpdateMap.values()) {
            if (
                newOwnerIdByObjectIdMap.containsKey(thisAccount.ParentId) &&
                oldOwnerIdByObjectIdMap.containsKey(thisAccount.ParentId)
            ) {
                Id thisParentAccountOwnerId = newOwnerIdByObjectIdMap.get(thisAccount.ParentId);
                Id thisParentOldAccountOwnerId = oldOwnerIdByObjectIdMap.get(thisAccount.ParentId);

                oldOwnerIdByObjectIdMap.put(thisAccount.Id, thisParentOldAccountOwnerId);
                newOwnerIdByObjectIdMap.put(thisAccount.Id, thisParentAccountOwnerId);

                if (
                    thisAccount.OwnerId == thisParentOldAccountOwnerId &&
                    thisAccount.OwnerId != thisParentAccountOwnerId
                ) {
                    thisAccount.OwnerId = thisParentAccountOwnerId;
                    accountsToUpdateList.add(thisAccount);
                }
            }
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('accountDownstream');

        // Save to database for child accounts
        if (accountsToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                accountsToUpdateList,
                'AccountChangeEventHandler',
                'Account Ownership Change'
            );
        }
    }
    /**
     * @description Queries child accounts where parents' owners have changed and owner not CSAM,
     * updates owner to parent owner, adds account to newOwnerIdByObjectIdMap for processing
     * contacts and opps, then updates accounts
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Account Id
     */
    public static void processAccounts(Map<Id, Id> newOwnerIdByObjectIdMap, Set<Id> accountIdSet) {
        List<Account> accountsToUpdateList = new List<Account>();
        Map<Id, Account> childAccountsToUpdateMap = new Map<Id, Account>(
            [SELECT Id, OwnerId, ParentId FROM Account WHERE ParentId IN :newOwnerIdByObjectIdMap.keySet() FOR UPDATE]
        );
        for (Account thisAccount : childAccountsToUpdateMap.values()) {
            if (newOwnerIdByObjectIdMap.containsKey(thisAccount.ParentId)) {
                Id thisParentAccountOwnerId = newOwnerIdByObjectIdMap.get(thisAccount.ParentId);
                thisAccount.OwnerId = thisParentAccountOwnerId;
                accountsToUpdateList.add(thisAccount);
                newOwnerIdByObjectIdMap.put(thisAccount.Id, thisAccount.OwnerId);
                accountIdSet.add(thisAccount.Id);
            }
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('accountDownstream');

        // Save to database for child accounts
        if (accountsToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                accountsToUpdateList,
                'AccountChangeEventHandler',
                'Account Ownership Change'
            );
        }
    }

    /**
     * @description Queries contacts where accounts' owners have changed and owner not CSAM,
     * updates owner to account owner, adds contact Id to contactIdSet for processing
     * opps, then updates contacts
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Account Id
     * @param contactIdSet - set of contact id's used when querying opps
     */
    private static void processContacts(
        String Origin,
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet,
        Set<Id> contactIdSet,
        Map<ID, List<Account_Team__C>> accountTeamMap,
        Map<ID, Account> accountDataMap
    ) {
        List<Contact> contactsToUpdateList = new List<Contact>();
        List<Contact> contactsNeedingNewOwnerList = new List<Contact>(
            [
                SELECT
                    Id,
                    email,
                    OwnerId,
                    Owner.Name,
                    AccountId,
                    Account.OwnerId,
                    Account.ParentId,
                    Account.Owner.UserRole.Name,
                    Owner.UserRole.Name
                FROM Contact
                WHERE AccountId IN :newOwnerIdByObjectIdMap.keySet()
            ]
        );
        for (Contact thisContact : contactsNeedingNewOwnerList) {
            boolean updateContactFlag = true;
            ID newOwnerId = null;
            if (origin == 'aTeamDelete' || origin == 'aTeam') {
                if (
                    oldOwnerIdByObjectIdMap.containsKey(thisContact.AccountId) &&
                    thisContact.OwnerId == oldOwnerIdByObjectIdMap.get(thisContact.AccountId)
                ) {
                    newOwnerId = newOwnerIdByObjectIdMap.get(thisContact.AccountId);
                }
            } else {
                newOwnerId = newOwnerIdByObjectIdMap.get(thisContact.AccountId);
            }
            updateContactFlag = checkUpdateObjectLogic(
                Origin,
                teamRoleStringSet,
                accountTeamMap.get(thisContact.AccountId),
                accountTeamMap.get(thisContact.Account.ParentId),
                thisContact.OwnerId,
                oldOwnerIdByObjectIdMap.get(thisContact.AccountId),
                accountDataMap.get(thisContact.AccountId),
                accountDataMap.get(thisContact.Account.ParentId),
                newOwnerId
            );
            //Regardless if we are updating the Contact we need to look at the Contact's Projects for CSAM checks
            contactIdSet.add(thisContact.Id);
            if (updateContactFlag && newOwnerId != null) {
                thisContact.OwnerId = newOwnerId;
                contactsToUpdateList.add(thisContact);
            }
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('contactDownstream');

        // Save to database for contacts
        if (contactsToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                contactsToUpdateList,
                'AccountChangeEventHandler',
                'Contact Ownership Change'
            );
        }
    }

    /**
     * @description Queries opps where contacts' accounts' owners have changed, opp not closed, and Hold Opp to Prior Owner
     * field not checked, updates owner to account owner, adds opp Id to oppIdSet for processing
     * opps, then updates opps
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Account Id
     * @param contactIdSet - set of contact id's used when querying opps
     * @param oppIdSet - set of opp id's used when querying quotes and orders
     */
    private static void processOpps(
        String origin,
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet,
        Set<Id> contactIdSet,
        Set<Id> oppIdSet,
        Map<ID, List<Account_Team__C>> accountTeamMap,
        Map<ID, Account> accountDataMap
    ) {
        List<Opportunity> oppsToUpdateList = new List<Opportunity>();
        List<Opportunity> oppsNeedingNewOwnerList = new List<Opportunity>(
            [
                SELECT
                    Id,
                    OwnerId,
                    AccountId,
                    Account.ParentId,
                    Account.Owner.UserRole.Name,
                    Owner.UserRole.Name,
                    Primary_Contact__c
                FROM Opportunity
                WHERE
                    AccountId IN :accountIdSet
                    AND Primary_Contact__c IN :contactIdSet
                    AND Hold_Op_to_Prior_Owner__c = FALSE
                    AND IsClosed = FALSE
                    AND RecordTypeId = :oppManufacturingServRTypeID
            ]
        );
        for (Opportunity thisOpp : oppsNeedingNewOwnerList) {
            boolean updateOppFlag = true;
            ID newOwnerId = null;
            switch on origin {
                when 'Account' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisOpp.AccountId)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(thisOpp.AccountId);
                    }
                }
                when 'Contact' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisOpp.Primary_Contact__c)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(thisOpp.Primary_Contact__c);
                    }
                }
                when 'aTeam' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisOpp.AccountId)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(thisOpp.AccountId);
                    }
                }
                when 'aTeamDelete' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisOpp.AccountId)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(thisOpp.AccountId);
                    }
                }
            }
            updateOppFlag = checkUpdateObjectLogic(
                origin,
                teamRoleStringSet,
                accountTeamMap.get(thisOpp.AccountId),
                accountTeamMap.get(thisOpp.Account.ParentId),
                thisOpp.OwnerId,
                oldOwnerIdByObjectIdMap.get(thisOpp.AccountId),
                accountDataMap.get(thisOpp.AccountId),
                accountDataMap.get(thisOpp.Account.ParentId),
                newOwnerId
            );
            if (updateOppFlag && newOwnerId != null) {
                thisOpp.OwnerId = newOwnerId;
            }
            oppsToUpdateList.add(thisOpp);
            oppIdSet.add(thisOpp.Id);
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('oppsDownstream');

        // Save to database for changed opps
        if (oppsToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                oppsToUpdateList,
                'AccountChangeEventHandler.processOpps',
                'Opportunity Ownership Change'
            );
        }
    }

    /**
     * @description Queries opps where projects' owners have changed, opp not closed, and Hold Opp to Prior Owner
     * field not checked, updates owner to project owner, adds opp Id to oppIdSet for processing
     * quotes/orders, then updates opps
     * @param origin Downstream event start object
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Object Id
     * @param oppIdSet - set of opp id's used when querying quotes and orders
     */
    private static void processOpps(String origin, Map<Id, Id> newOwnerIdByObjectIdMap, Set<Id> oppIdSet) {
        List<Opportunity> oppsToUpdateList = new List<Opportunity>();
        List<Opportunity> oppsNeedingNewOwnerList = new List<Opportunity>(
            [
                SELECT Id, OwnerId, Project__c
                FROM Opportunity
                WHERE
                    Project__c IN :newOwnerIdByObjectIdMap.keySet()
                    AND Hold_Op_to_Prior_Owner__c = FALSE
                    AND IsClosed = FALSE
                    AND RecordTypeId = :oppManufacturingServRTypeID
            ]
        );
        for (Opportunity thisOpp : oppsNeedingNewOwnerList) {
            switch on origin {
                when 'Project' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisOpp.Project__c)) {
                        Id thisProjectOwnerId = newOwnerIdByObjectIdMap.get(thisOpp.Project__c);
                        thisOpp.OwnerId = thisProjectOwnerId;
                    }
                }
            }

            oppsToUpdateList.add(thisOpp);
            oppIdSet.add(thisOpp.Id);
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('oppsDownstream');

        // Save to database for changed opps
        if (oppsToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                oppsToUpdateList,
                'AccountChangeEventHandler.processOpps',
                'Opportunity Ownership Change by project'
            );
        }
    }

    /**
     * @description Queries projects where contacts' accounts' owners have changed, and Hold Project to Prior Owner
     * field not checked, updates owner to account owner
     * opps, then updates projects
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Account Id
     * @param contactIdSet - set of contact id's used when querying opps
     */
    private static void processProjects(
        String Origin,
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet,
        Set<Id> contactIdSet,
        Map<ID, List<Account_Team__C>> accountTeamMap,
        Map<ID, Account> accountDataMap
    ) {
        List<Project__c> projectsToUpdateList = new List<Project__c>();
        List<Project__c> projectsNeedingNewOwnerList = new List<Project__c>(
            [
                SELECT
                    Id,
                    OwnerId,
                    AccountId__c,
                    Primary_Contact__c,
                    AccountId__r.ParentId,
                    AccountId__r.Owner.UserRole.Name,
                    Owner.UserRole.Name
                FROM Project__c
                WHERE
                    AccountId__c IN :accountIdSet
                    AND Primary_Contact__c IN :contactIdSet
                    AND Stage__c NOT IN ('Closed Won', 'Closed Lost')
                    AND Hold_Project_to_Prior_Owner__c = FALSE
            ]
        );
        for (Project__c thisProject : projectsNeedingNewOwnerList) {
            boolean updateProjectFlag = true;
            ID newOwnerId = null;
            switch on origin {
                when 'Account' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisProject.AccountId__c)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(thisProject.AccountId__c);
                    }
                }
                when 'Contact' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisProject.Primary_Contact__c)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(thisProject.Primary_Contact__c);
                    }
                }
                when 'aTeam' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisProject.AccountId__c)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(thisProject.AccountId__c);
                    }
                }
                when 'aTeamDelete' {
                    if (newOwnerIdByObjectIdMap.containsKey(thisProject.AccountId__c)) {
                        if (thisProject.OwnerId == oldOwnerIdByObjectIdMap.get(thisProject.AccountId__c)) {
                            newOwnerId = newOwnerIdByObjectIdMap.get(thisProject.AccountId__c);
                        }
                    }
                }
            }
            updateProjectFlag = checkUpdateObjectLogic(
                origin,
                teamRoleStringSet,
                accountTeamMap.get(thisProject.AccountId__c),
                accountTeamMap.get(thisProject.AccountId__r.ParentId),
                thisProject.ownerId,
                oldOwnerIdByObjectIdMap.get(thisProject.AccountId__c),
                accountDataMap.get(thisProject.AccountId__c),
                accountDataMap.get(thisProject.AccountId__r.ParentId),
                newOwnerId
            );
            if (updateProjectFlag && newOwnerId != null) {
                thisProject.OwnerId = newOwnerId;
            }

            projectsToUpdateList.add(thisProject);
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('projectDownstream');

        // Save to database for projects
        if (projectsToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                projectsToUpdateList,
                'AccountChangeEventHandler',
                'Project__c Ownership Change'
            );
        }
    }

    /**
     * @description Queries quotes where opps owners have changed, updates owner to opp owner
     * then updates quotes
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Account Id
     * @param oppIdSet - set of opp id's used when querying quotes and orders
     */
    private static void processQuotes(Map<Id, Id> newOwnerIdByObjectIdMap, Set<Id> accountIdSet, Set<Id> oppIdSet) {
        List<Quote_ERP__c> quotesToUpdateList = new List<Quote_ERP__c>();
        List<Quote_ERP__c> quotesNeedingNewOwnerList = new List<Quote_ERP__c>(
            [
                SELECT Id, OwnerId, OpportunityID__c, OpportunityID__r.AccountId
                FROM Quote_ERP__c
                WHERE OpportunityID__c IN :oppIdSet
            ]
        );
        for (Quote_ERP__c thisQuote : quotesNeedingNewOwnerList) {
            if (newOwnerIdByObjectIdMap.containsKey(thisQuote.OpportunityID__r.AccountId)) {
                Id thisAccountOwnerId = newOwnerIdByObjectIdMap.get(thisQuote.OpportunityID__r.AccountId);
                thisQuote.OwnerId = thisAccountOwnerId;
                quotesToUpdateList.add(thisQuote);
            }
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('quotesDownstream');

        // Save to database for quotes
        if (quotesToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(quotesToUpdateList, 'AccountChangeEventHandler', 'Quote Ownership Change');
        }
    }

    /**
     * @description Queries orders where opps owners have changed, updates owner to opp owner
     * then updates orders
     * @param newOwnerIdByObjectIdMap - map of new Owner Id by Account Id
     * @param oppIdSet - set of opp id's used when querying quotes and orders
     */
    private static void processOrders(Map<Id, Id> newOwnerIdByObjectIdMap, Set<Id> accountIdSet, Set<Id> oppIdSet) {
        List<Order_ERP__c> ordersToUpdateList = new List<Order_ERP__c>();
        List<Order_ERP__c> ordersNeedingNewOwnerList = new List<Order_ERP__c>(
            [
                SELECT Id, OwnerId, OpportunityID__c, OpportunityID__r.AccountId
                FROM Order_ERP__c
                WHERE OpportunityID__c IN :oppIdSet
            ]
        );
        for (Order_ERP__c thisOrder : ordersNeedingNewOwnerList) {
            if (newOwnerIdByObjectIdMap.containsKey(thisOrder.OpportunityID__r.AccountId)) {
                Id thisAccountOwnerId = newOwnerIdByObjectIdMap.get(thisOrder.OpportunityID__r.AccountId);
                thisOrder.OwnerId = thisAccountOwnerId;
                ordersToUpdateList.add(thisOrder);
            }
        }

        // Don't create new downstream events
        EventBusBypass.ByPass('ordersDownstream');

        // Save to database for orders
        if (ordersToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(ordersToUpdateList, 'AccountChangeEventHandler', 'Order Ownership Change');
        }
    }

    /**
     * @description updates cases based on object owner
     * @param origin where the downstream event started
     * @param newOwnerIdByObjectIdMap map of new owner by start object id
     * @param accountIdSet accounts that have been updated
     * @param oldOwnerIdByObjectIdMap map of old owner by start object id
     * @param accountTeamMap map of accountTeamMembers by Account id
     */
    private static void processCases(
        String origin,
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Set<Id> accountIdSet,
        Set<Id> contactIdSet,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Map<ID, List<Account_Team__C>> accountTeamMap,
        Map<Id, Account> accountDataMap
    ) {
        List<Case> casesToUpdate = new List<Case>();
        Map<Id, Id> caseMapWithNewOwner = new Map<Id, Id>();
        Map<Id, Id> caseMapWithOldOwner = new Map<Id, Id>();
        Map<Id, Case> casesNeedingNewOwner = new Map<Id, Case>(
            [
                SELECT Id, OwnerId, ContactId, AccountId, Account.ParentId, isClosed, Owner.UserRole.Name
                FROM Case
                WHERE
                    AccountId IN :accountIdSet
                    AND ContactId IN :contactIdSet
                    AND OwnerId IN :oldOwnerIdByObjectIdMap.values()
                    AND isClosed = FALSE
            ]
        );
        for (Case c : casesNeedingNewOwner.values()) {
            boolean updateCaseFlag = true;
            ID newOwnerId = null;
            ID newOwnerIdByObjectIdMapTemp = null;
            ID oldOwnerIdByObjectIdMapTemp = null;
            switch on origin {
                when 'Account' {
                    if (newOwnerIdByObjectIdMap.containsKey(c.AccountId)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(c.AccountId);
                        newOwnerIdByObjectIdMapTemp = newOwnerIdByObjectIdMap.get(c.AccountId);
                        oldOwnerIdByObjectIdMapTemp = oldOwnerIdByObjectIdMap.get(c.AccountId);
                    }
                }
                when 'Contact' {
                    if (newOwnerIdByObjectIdMap.containsKey(c.ContactId)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(c.ContactId);
                        newOwnerIdByObjectIdMapTemp = newOwnerIdByObjectIdMap.get(c.ContactId);
                        oldOwnerIdByObjectIdMapTemp = oldOwnerIdByObjectIdMap.get(c.ContactId);
                    }
                }
                when 'aTeam' {
                    if (newOwnerIdByObjectIdMap.containsKey(c.AccountId)) {
                        newOwnerId = newOwnerIdByObjectIdMap.get(c.AccountId);
                        newOwnerIdByObjectIdMapTemp = newOwnerIdByObjectIdMap.get(c.AccountId);
                        oldOwnerIdByObjectIdMapTemp = oldOwnerIdByObjectIdMap.get(c.AccountId);
                    }
                }
                when 'aTeamDelete' {
                    if (newOwnerIdByObjectIdMap.containsKey(c.AccountId)) {
                        if (c.OwnerId == oldOwnerIdByObjectIdMap.get(c.AccountId)) {
                            newOwnerId = newOwnerIdByObjectIdMap.get(c.AccountId);
                        }
                    }
                }
            }
            updateCaseFlag = checkUpdateObjectLogic(
                origin,
                teamRoleStringSet,
                accountTeamMap.get(c.AccountId),
                accountTeamMap.get(c.Account.ParentId),
                c.OwnerId,
                oldOwnerIdByObjectIdMap.get(c.AccountId),
                accountDataMap.get(c.AccountId),
                accountDataMap.get(c.Account.ParentId),
                newOwnerId
            );
            if (updateCaseFlag && newOwnerId != null) {
                c.OwnerId = newOwnerId;
                casesToUpdate.add(c);
                //Commit to the caseMapRecords
                if (origin != 'aTeamDelete') {
                    caseMapWithNewOwner.put(c.Id, newOwnerIdByObjectIdMapTemp);
                    caseMapWithOldOwner.put(c.Id, oldOwnerIdByObjectIdMapTemp);
                }
            }
        }

        // don't need a bypass cases is last
        // Save to database for cases
        if (casesToUpdate.size() > 0) {
            DatabaseUtilities.saveToDatabase(casesToUpdate, 'AccountChangeEventHandler', 'Case Ownership Change');
            processCaseTeam(casesNeedingNewOwner.keySet(), caseMapWithNewOwner, caseMapWithOldOwner);
        }
    }

    /**
     * @description updates cases based on object owner overloaded for projects
     * @param origin where the downstream event started
     * @param newOwnerIdByObjectIdMap map of new owner by start object id
     * @param accountIdSet accounts that have been updated
     * @param oldOwnerIdByObjectIdMap map of old owner by start object id
     * @param accountTeamMap map of accountTeamMembers by Account id
     */
    private static void processCases(
        String origin,
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap
    ) {
        List<Case> casesToUpdate = new List<Case>();
        Map<Id, Id> caseMapWithNewOwner = new Map<Id, Id>();
        Map<Id, Id> caseMapWithOldOwner = new Map<Id, Id>();
        Map<Id, Case> casesNeedingNewOwner = new Map<Id, Case>(
            [
                SELECT
                    Id,
                    OwnerId,
                    Project__c,
                    Opportunity__r.Project__c,
                    AccountId,
                    Account.ParentId,
                    isClosed,
                    Owner.UserRole.Name
                FROM Case
                WHERE
                    (Project__c IN :oldOwnerIdByObjectIdMap.keySet()
                    OR Opportunity__r.Project__c IN :oldOwnerIdByObjectIdMap.keySet())
                    AND OwnerId IN :oldOwnerIdByObjectIdMap.values()
                    AND isClosed = FALSE
            ]
        );
        for (Case c : casesNeedingNewOwner.values()) {
            if (newOwnerIdByObjectIdMap.containsKey(c.Project__c)) {
                Id thisProjectId = newOwnerIdByObjectIdMap.get(c.Project__c);
                c.OwnerId = thisProjectId;
                casesToUpdate.add(c);
                caseMapWithNewOwner.put(c.Id, newOwnerIdByObjectIdMap.get(c.Project__c));
                caseMapWithOldOwner.put(c.Id, oldOwnerIdByObjectIdMap.get(c.Project__c));
            } else if (newOwnerIdByObjectIdMap.containsKey(c.Opportunity__r.Project__c)) {
                Id thisProjectId = newOwnerIdByObjectIdMap.get(c.Opportunity__r.Project__c);
                c.OwnerId = thisProjectId;
                casesToUpdate.add(c);
                caseMapWithNewOwner.put(c.Id, newOwnerIdByObjectIdMap.get(c.Project__c));
                caseMapWithOldOwner.put(c.Id, oldOwnerIdByObjectIdMap.get(c.Project__c));
            }
        }

        // don't need a bypass cases is last
        // Save to database for cases
        if (casesToUpdate.size() > 0) {
            DatabaseUtilities.saveToDatabase(casesToUpdate, 'AccountChangeEventHandler', 'Case Ownership Change');
            processCaseTeam(casesNeedingNewOwner.keySet(), caseMapWithNewOwner, caseMapWithOldOwner);
        }
    }

    /**
     * @description called from process case to update case teams when case owner is changed
     * @param caseIdSet A set of id's that need to be checked
     * @param caseMapWithNewOwner A map of case id's and new owner id
     * @param caseMapWithOldOwner A map of case id's and old owner id
     */
    private static void processCaseTeam(
        Set<Id> caseIdSet,
        Map<Id, Id> caseMapWithNewOwner,
        Map<Id, Id> caseMapWithOldOwner
    ) {
        List<CaseTeamMember> caseTeamsToDelete = new List<CaseTeamMember>();
        Map<Id, CaseTeamMember> caseTeamsToInsert = new Map<Id, CaseTeamMember>();

        for (CaseTeamMember tm : [
            SELECT Id, ParentId, MemberId, TeamRoleId
            FROM CaseTeamMember
            WHERE ParentId IN :caseIdSet
            WITH SECURITY_ENFORCED
        ]) {
            if (caseMapWithOldOwner.containsKey(tm.ParentId) && tm.MemberId == caseMapWithOldOwner.get(tm.ParentId)) {
                CaseTeamMember newTm = new CaseTeamMember(
                    ParentId = tm.ParentId,
                    MemberId = caseMapWithNewOwner.get(tm.ParentId),
                    TeamRoleId = tm.TeamRoleId
                );
                caseTeamsToInsert.put(newTm.MemberId, newTm);
                caseTeamsToDelete.add(tm);
            }
            if (caseTeamsToInsert.containsKey(tm.MemberId) && caseMapWithOldOwner.containsKey(tm.ParentId)) {
                caseTeamsToInsert.remove(tm.MemberId);
            }
        }
        DatabaseUtilities.deleteFromDatabase(caseTeamsToDelete, 'DownstreamEvent.caseTeam', 'case team did not delete');
        DatabaseUtilities.insertToDatabase(
            caseTeamsToInsert.values(),
            'DownstreamEvent.caseTeam',
            'case team did not update'
        );
    }

    /**
     * @description updates leads based on object owner
     * @param origin where the downstream event started
     * @param newOwnerIdByObjectIdMap map of new owner by start object id
     * @param accountIdSet accounts that have been updated
     * @param oldOwnerIdByObjectIdMap map of old owner by start object id
     * @param accountTeamMap map of accountTeamMembers by Account id
     * @param accountDataMap map of Accounts info
     */
    private static void processLeads(
        String origin,
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Set<Id> accountIdSet,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Map<ID, List<Account_Team__C>> accountTeamMap,
        Map<Id, Account> accountDataMap
    ) {

        List<Lead> leadsToUpdate = new List<Lead>();
        for (Lead l : [
            SELECT
                ID,
                Recommended_Account_LKP__c,
                Converted_Owner__c,
                OwnerId
            FROM Lead
            WHERE
                Recommended_Account_LKP__c IN :accountIdSet
                AND isConverted = FALSE
        ]) {

            Id accParentId = accountDataMap.get(l.Recommended_Account_LKP__c).ParentId;

            Boolean updateLeadOwnerFlag = checkUpdateObjectLogic(
                origin,
                teamRoleStringSet,
                accountTeamMap.get(l.Recommended_Account_LKP__c),
                accountTeamMap.get(accParentId),
                l.OwnerId,
                oldOwnerIdByObjectIdMap.get(l.Recommended_Account_LKP__c),
                accountDataMap.get(l.Recommended_Account_LKP__c),
                accountDataMap.get(accParentId),
                newOwnerIdByObjectIdMap.get( l.Recommended_Account_LKP__c )
            );

            Boolean updateLeadFlag = false;

            if(updateLeadOwnerFlag){
                l.OwnerId = newOwnerIdByObjectIdMap.get( l.Recommended_Account_LKP__c );
                updateLeadFlag = true;
            }
            if(oldOwnerIdByObjectIdMap.get( l.Recommended_Account_LKP__c ) == l.Converted_Owner__c){
                l.Converted_Owner__c = newOwnerIdByObjectIdMap.get( l.Recommended_Account_LKP__c );
                updateLeadFlag = true;
            }

            if( updateLeadFlag ){
                leadsToUpdate.add(l);
            }

        }

        DatabaseUtilities.saveToDatabase(leadsToUpdate, 'AccountChangeEventHandler', 'Lead Ownership Change');
    }



    /*
     * @Method for determining if we can update the source objects owner or not
     * The returned value indicates if we should update the source record
     * @param Origin the events object Origin
     * @param ownerRoleName the source objects current owner Role
     * @param accountTeamHasCSAM is the source objects Account Team
     * @param parentAccountTeamHasCSAM if the source objects parent account team
     * @param objOwnerId the owner of the object being check
     * @param the old owner from the downstream event
     * @param  boolean accountHouseRetainerFlag the Accounts House_Retainer__c
     * @param boolean parentAccountHouseRetainerFlag the Parent Accounts House_Retainer__c field
     * @param objnewOwnerId the Id of the new owner for the object to be update if checkupdateObjectLogic returns true
     */
    private static boolean checkUpdateObjectLogic(
        string Origin,
        Set<String> acctTeamRolesToKeepPriorOwner,
        List<Account_Team__C> hasAccountTeam,
        List<Account_Team__C> parentHasAccountTeam,
        Id objOwnerId,
        Id oldOwnerId,
        Account dataAccount,
        Account parentdataAccount,
        ID objnewOwnerId
    ) {
        boolean updateSourceObject = true;
        Set<String> acctTeamRoleList = new Set<String>();

        if (hasAccountTeam != null) {
            for (Account_Team__C aTeam : hasAccountTeam) {
                if (objOwnerId == aTeam?.Team_Member__c) {
                    acctTeamRoleList.add(aTeam.Team_Role__c);
                }
            }
        }
        if (parentHasAccountTeam != null) {
            for (Account_Team__C aTeam : parentHasAccountTeam) {
                if (objOwnerId == aTeam?.Team_Member__c) {
                    acctTeamRoleList.add(aTeam.Team_Role__c);
                }
            }
        }

        for (String acctTeamRole : acctTeamRoleList) {
            if (
                origin != 'aTeam' &&
                origin != 'aTeamDelete' &&
                acctTeamRolesToKeepPriorOwner.contains(acctTeamRole) &&
                (hasAccountTeam != null ||
                parentHasAccountTeam != null)
            ) {
                updateSourceObject = false;
            }
        }
        //When the origin is aTeam only change the owner when old owner was the account team CSAM
        if (origin == 'aTeam' && objOwnerId != oldOwnerId) {
            updateSourceObject = false;
        }
        if (origin == 'aTeamDelete' && objOwnerId != oldOwnerId) {
            updateSourceObject = false;
        }
        //If the origin is not aTeam or aTeamDelete and the new owner is the SuccessTeam and the account has House Retainer True then everything becomes the Success Team regardless of the Account Team.
        if (
            origin != 'aTeam' &&
            origin != 'aTeamDelete' &&
            objnewOwnerId == AppConstants.SALES_HOUSE_USER &&
            (dataAccount.House_Retainer__c == true ||
            parentdataAccount?.House_Retainer__c == true)
        ) {
            updateSourceObject = true; //explicit true so even acctTeamRole still override to the Success Team
        }
        return updateSourceObject;
    }

    /*
    @description get any needed account information for Downstream logic
    */
    public static Map<ID, Account> getAccountInfo(Set<ID> accountIDSet) {
        Map<ID, Account> accountDataMap = new Map<ID, Account>();
        for (Account a : [SELECT ID, House_Retainer__c, ParentId FROM Account WHERE ID IN :accountIdSet]) {
            accountDataMap.put(a.ID, a);
        }
        return accountDataMap;
    }
    /**
     * @description handles logic for downstream events that start at the account level
     * @param newOwnerIdByObjectIdMap new owner by object Id map
     * @param accountIdSet set of account id's for SOQL
     */
    @future
    private static void startAccountDownstream(
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet
    ) {
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();

        processAccounts(newOwnerIdByObjectIdMap, accountIdSet);

        Map<ID, List<Account_Team__C>> accountTeamMap = accountTeamHandler.createAccountTeamDownstreamApplyMap(
            accountIdSet,
            teamRoleStringSet
        );
        Map<ID, Account> accountDataMap = getAccountInfo(accountIdSet);
        //for the accountTeamMap if the Account or the Parent Account has an account team we need to include both
        processContacts(
            'Account',
            newOwnerIdByObjectIdMap,
            oldOwnerIdByObjectIdMap,
            accountIdSet,
            contactIdSet,
            accountTeamMap,
            accountDataMap
        );
        if (contactIdSet.size() > 0) {
            processProjects(
                'Account',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                accountTeamMap,
                accountDataMap
            );
            processOpps(
                'Account',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                oppIdSet,
                accountTeamMap,
                accountDataMap
            );
        }
        if (oppIdSet.size() > 0) {
            Admin_Ref_Variable__mdt quoteOrderAdminRefVar = [
                SELECT Id, DeveloperName, Change_Downstream_Order_Owner__c, Change_Downstream_Quote_Owner__c
                FROM Admin_Ref_Variable__mdt
                WHERE DeveloperName = :'Downstream_Quote_Order_Change'
            ];

            if (quoteOrderAdminRefVar.Change_Downstream_Quote_Owner__c) {
                processQuotes(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
            if (quoteOrderAdminRefVar.Change_Downstream_Order_Owner__c) {
                processOrders(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
        }
        processCases(
            'Account',
            newOwnerIdByObjectIdMap,
            accountIdSet,
            contactIdSet,
            oldOwnerIdByObjectIdMap,
            accountTeamMap,
            accountDataMap
        );
        processLeads(
            'Account',
            newOwnerIdByObjectIdMap,
            accountIdSet,
            oldOwnerIdByObjectIdMap,
            accountTeamMap,
            accountDataMap
        );
    }

    /**
     * @description handles logic for downstream events that start at the contact level
     * @param newOwnerIdByObjectIdMap new owner by object Id map
     * @param accountIdSet set of account id's for SOQL
     */
    @future
    private static void startContactDownstream(
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet
    ) {
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        for (Id i : newOwnerIdByObjectIdMap.keySet()) {
            contactIdSet.add(i);
        }
        Map<ID, List<Account_Team__C>> accountTeamMap = accountTeamHandler.createAccountTeamDownstreamApplyMap(
            accountIdSet,
            teamRoleStringSet
        );
        Map<ID, Account> accountDataMap = getAccountInfo(accountIdSet);
        //for the accountTeamMap if the Account or the Parent Account has an account team we need to include both
        if (contactIdSet.size() > 0) {
            processProjects(
                'Contact',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                accountTeamMap,
                accountDataMap
            );
            processOpps(
                'Contact',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                oppIdSet,
                accountTeamMap,
                accountDataMap
            );
        }
        if (oppIdSet.size() > 0) {
            Admin_Ref_Variable__mdt quoteOrderAdminRefVar = [
                SELECT Id, DeveloperName, Change_Downstream_Order_Owner__c, Change_Downstream_Quote_Owner__c
                FROM Admin_Ref_Variable__mdt
                WHERE DeveloperName = :'Downstream_Quote_Order_Change'
            ];

            if (quoteOrderAdminRefVar.Change_Downstream_Quote_Owner__c) {
                processQuotes(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
            if (quoteOrderAdminRefVar.Change_Downstream_Order_Owner__c) {
                processOrders(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
        }
        processCases(
            'Contact',
            newOwnerIdByObjectIdMap,
            accountIdSet,
            contactIdSet,
            oldOwnerIdByObjectIdMap,
            accountTeamMap,
            accountDataMap
        );
    }

    /**
     * @description handles logic for downstream events that start at the Account Team Level for CSAMS
     * @param newOwnerIdByObjectIdMap new owner by object Id map
     * @param accountIdSet set of account id's for SOQL
     */
    @future
    private static void startAteamDownstream(
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet
    ) {
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        //Different Method for Handling Child accounts with CSAM logic
        processAteamAccounts(newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap);
        accountIdSet.addAll(newOwnerIdByObjectIdMap.keySet());
        Map<ID, List<Account_Team__C>> accountTeamMap = accountTeamHandler.createAccountTeamDownstreamApplyMap(
            accountIdSet,
            teamRoleStringSet
        );
        Map<ID, Account> accountDataMap = getAccountInfo(accountIdSet);
        //for the accountTeamMap if the Account or the Parent Account has a team we need to include both
        processContacts(
            'aTeam',
            newOwnerIdByObjectIdMap,
            oldOwnerIdByObjectIdMap,
            accountIdSet,
            contactIdSet,
            accountTeamMap,
            accountDataMap
        );
        if (contactIdSet.size() > 0) {
            processProjects(
                'aTeam',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                accountTeamMap,
                accountDataMap
            );
            processOpps(
                'aTeam',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                oppIdSet,
                accountTeamMap,
                accountDataMap
            );
        }
        if (oppIdSet.size() > 0) {
            Admin_Ref_Variable__mdt quoteOrderAdminRefVar = [
                SELECT Id, DeveloperName, Change_Downstream_Order_Owner__c, Change_Downstream_Quote_Owner__c
                FROM Admin_Ref_Variable__mdt
                WHERE DeveloperName = :'Downstream_Quote_Order_Change'
            ];

            if (quoteOrderAdminRefVar.Change_Downstream_Quote_Owner__c) {
                processQuotes(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
            if (quoteOrderAdminRefVar.Change_Downstream_Order_Owner__c) {
                processOrders(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
        }
        processCases(
            'aTeam',
            newOwnerIdByObjectIdMap,
            accountIdSet,
            contactIdSet,
            oldOwnerIdByObjectIdMap,
            accountTeamMap,
            accountDataMap
        );
        processLeads(
            'aTeam',
            newOwnerIdByObjectIdMap,
            accountIdSet,
            oldOwnerIdByObjectIdMap,
            accountTeamMap,
            accountDataMap
        );
    }

    /**
     * @description handles logic for downstream events that start at the Account Team Level for CSAMS
     * @param newOwnerIdByObjectIdMap new owner by object Id map
     * @param accountIdSet set of account id's for SOQL
     */
    @future
    private static void startAteamDeleteDownstream(
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet
    ) {
        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        //Different Method for Handling Child accounts with CSAM logic
        processAteamAccounts(newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap);
        accountIdSet.addAll(newOwnerIdByObjectIdMap.keySet());

        Map<ID, List<Account_Team__C>> accountTeamMap = accountTeamHandler.createAccountTeamDownstreamApplyMap(
            accountIdSet,
            teamRoleStringSet
        );
        Map<ID, Account> accountDataMap = getAccountInfo(accountIdSet);
        //for the accountTeamMap if the Account or the Parent Account has a team we need to include both
        processContacts(
            'aTeamDelete',
            newOwnerIdByObjectIdMap,
            oldOwnerIdByObjectIdMap,
            accountIdSet,
            contactIdSet,
            accountTeamMap,
            accountDataMap
        );
        if (contactIdSet.size() > 0) {
            processProjects(
                'aTeamDelete',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                accountTeamMap,
                accountDataMap
            );
            processOpps(
                'aTeamDelete',
                newOwnerIdByObjectIdMap,
                oldOwnerIdByObjectIdMap,
                accountIdSet,
                contactIdSet,
                oppIdSet,
                accountTeamMap,
                accountDataMap
            );
        }
        if (oppIdSet.size() > 0) {
            Admin_Ref_Variable__mdt quoteOrderAdminRefVar = [
                SELECT Id, DeveloperName, Change_Downstream_Order_Owner__c, Change_Downstream_Quote_Owner__c
                FROM Admin_Ref_Variable__mdt
                WHERE DeveloperName = :'Downstream_Quote_Order_Change'
            ];

            if (quoteOrderAdminRefVar.Change_Downstream_Quote_Owner__c) {
                processQuotes(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
            if (quoteOrderAdminRefVar.Change_Downstream_Order_Owner__c) {
                processOrders(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
        }
        processCases(
            'aTeamDelete',
            newOwnerIdByObjectIdMap,
            accountIdSet,
            contactIdSet,
            oldOwnerIdByObjectIdMap,
            accountTeamMap,
            accountDataMap
        );
        processLeads(
            'aTeamDelete',
            newOwnerIdByObjectIdMap,
            accountIdSet,
            oldOwnerIdByObjectIdMap,
            accountTeamMap,
            accountDataMap
        );
    }

    /**
     * @description handles logic for downstream events that start at the project level
     * @param newOwnerIdByObjectIdMap new owner by object Id map
     * @param accountIdSet set of account id's for SOQL
     */
    @future
    private static void startProjectDownstream(
        Map<Id, Id> newOwnerIdByObjectIdMap,
        Map<Id, Id> oldOwnerIdByObjectIdMap,
        Set<Id> accountIdSet
    ) {
        Set<Id> oppIdSet = new Set<Id>();

        processOpps('Project', newOwnerIdByObjectIdMap, oppIdSet);

        if (oppIdSet.size() > 0) {
            Admin_Ref_Variable__mdt quoteOrderAdminRefVar = [
                SELECT Id, DeveloperName, Change_Downstream_Order_Owner__c, Change_Downstream_Quote_Owner__c
                FROM Admin_Ref_Variable__mdt
                WHERE DeveloperName = :'Downstream_Quote_Order_Change'
            ];

            if (quoteOrderAdminRefVar.Change_Downstream_Quote_Owner__c) {
                processQuotes(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
            if (quoteOrderAdminRefVar.Change_Downstream_Order_Owner__c) {
                processOrders(newOwnerIdByObjectIdMap, accountIdSet, oppIdSet);
            }
        }
        processCases('Project', newOwnerIdByObjectIdMap, oldOwnerIdByObjectIdMap);
    }
}