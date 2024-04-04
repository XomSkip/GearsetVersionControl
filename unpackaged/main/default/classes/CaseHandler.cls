public with sharing class CaseHandler {
    static final ID caseSourcingRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('Sourcing')
        .getRecordTypeId();

    static final ID casePSERecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('PSE_Case')
        .getRecordTypeId();

    static final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('CaseMgmt')
        .getRecordTypeId();

    static final ID caseGeneralSupportRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('GeneralSupportCase')
        .getRecordTypeId();

    static final ID caseReSourceRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('ReSource')
        .getRecordTypeId();

    static final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeId();

    /**
     * @description populates project from an opportunity if associated to the case
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void populateProjectFromOpp(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Map<Id, List<Case>> caseListByOppIdMap = new Map<Id, List<Case>>();
        for (Case thisNewCase : newCaseList) {
            if (thisNewCase.Opportunity__c != null && thisNewCase.Project__c == null) {
                if (oldCaseMap == null) {
                    if (!caseListByOppIdMap.containsKey(thisNewCase.Opportunity__c)) {
                        caseListByOppIdMap.put(thisNewCase.Opportunity__c, new List<Case>{ thisNewCase });
                    } else {
                        caseListByOppIdMap.get(thisNewCase.Opportunity__c).add(thisNewCase);
                    }
                } else {
                    Case thisOldCase = oldCaseMap.get(thisNewCase.Id);
                    if (thisNewCase.Opportunity__c != thisOldCase.Opportunity__c) {
                        if (!caseListByOppIdMap.containsKey(thisNewCase.Opportunity__c)) {
                            caseListByOppIdMap.put(thisNewCase.Opportunity__c, new List<Case>{ thisNewCase });
                        } else {
                            caseListByOppIdMap.get(thisNewCase.Opportunity__c).add(thisNewCase);
                        }
                    }
                }
            }
        }
        if (caseListByOppIdMap.size() > 0) {
            List<Opportunity> oppList = new List<Opportunity>(
                [SELECT Id, Project__c FROM Opportunity WHERE Id IN :caseListByOppIdMap.keySet() AND Project__c != NULL]
            );
            for (Opportunity thisOpp : oppList) {
                List<Case> caseList = caseListByOppIdMap.get(thisOpp.Id);
                for (Case thisCase : caseList) {
                    thisCase.Project__c = thisOpp.Project__c;
                }
            }
        }
    }

    /**
     * @description populates Last Owner Change Date on Case if owner changed
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void populateLastOwnerChangeDate(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        for (Case thisNewCase : newCaseList) {
            Case thisOldCase = oldCaseMap.get(thisNewCase.Id);
            if (thisNewCase.OwnerId != thisOldCase.OwnerId) {
                thisNewCase.Last_Owner_Change_Date__c = System.now();
            }
        }
    }
    /**
     * @description calls linkAccountAndContactByEmailFuture
     * @param newCaseList - list of new cases
     */
    public static void linkAccountAndContactByEmail(List<Case> newCaseList) {
        List<Case> validCasesList = new List<Case>();
        for (Case thisCase : newCaseList) {
            if (thisCase.AccountId == null && thisCase.ContactId == null && thisCase.SuppliedEmail != null) {
                validCasesList.add(thisCase);
            }
        }
        if (!validCasesList.isEmpty()) {
            linkAccountAndContactByEmailFuture(JSON.serialize(validCasesList));
        }
    }

    /**
     * @description if a contact does not have an account or contact but has an email, split the email
     * domain and try to add an account through matching domain
     * @param jsonStr - JSON string of new Cases
     */
    @future
    public static void linkAccountAndContactByEmailFuture(String jsonStr) {
        List<Case> newCaseList = (List<Case>) JSON.deserialize(jsonStr, List<Case>.class);
        Set<String> emailDomainSet = new Set<String>();
        Map<String, List<Case>> caseListByEmailDomainMap = new Map<String, List<Case>>();
        Set<String> genericEmailDomainSet = getGenericEmailDomainSet();
        for (Case thisCase : newCaseList) {
            if (thisCase.AccountId == null && thisCase.ContactId == null && thisCase.SuppliedEmail != null) {
                String emailDomain = (thisCase.SuppliedEmail.split('@').get(1)).toLowerCase();
                if (genericEmailDomainSet.contains(emailDomain)) {
                    if (caseListByEmailDomainMap.get(thisCase.SuppliedEmail) == null) {
                        caseListByEmailDomainMap.put(thisCase.SuppliedEmail, new List<Case>{ thisCase });
                    } else {
                        caseListByEmailDomainMap.get(thisCase.SuppliedEmail).add(thisCase);
                    }
                } else {
                    if (caseListByEmailDomainMap.get(emailDomain) == null) {
                        caseListByEmailDomainMap.put(emailDomain, new List<Case>{ thisCase });
                    } else {
                        caseListByEmailDomainMap.get(emailDomain).add(thisCase);
                    }
                }
            }
        }
        if (caseListByEmailDomainMap.size() > 0) {
            processCaseMap(caseListByEmailDomainMap);
        }
    }

    /**
     * @description query for accounts with matching email domains, and populate lookup on matching cases
     * @param caseMap - Map of cases by either supplied email or domain
     */
    private static void processCaseMap(Map<String, List<Case>> caseMap) {
        List<Case> caseToUpdateList = new List<Case>();
        List<Account> accountList = new List<Account>(
            [SELECT Id, Email_Domain__c FROM Account WHERE Email_Domain__c IN :caseMap.keySet()]
        );
        if (accountList.size() > 0) {
            for (Account thisAccount : accountList) {
                String accountEmailDomain = (thisAccount.Email_Domain__c).tolowercase();
                if (caseMap.containsKey(accountEmailDomain)) {
                    for (Case thisCase : caseMap.get(accountEmailDomain)) {
                        thisCase.AccountId = thisAccount.Id;
                        caseToUpdateList.add(thisCase);
                    }
                }
            }
        }
        if (caseToUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(
                caseToUpdateList,
                'CaseHandler.linkAccountAndContactByEmail',
                'Linking Account and Contact to Case by Email'
            );
        }
    }

    /**
     * @description queries and returns generic email domain custom metadata records
     * @return Set<String> containing generic email domains
     */
    private static Set<String> getGenericEmailDomainSet() {
        Set<String> genericEmailDomainSet = new Set<String>();
        List<Email_Domain__mdt> genericEmailDomainList = new List<Email_Domain__mdt>(
            [SELECT Id, Email_Domains__c, Generic_FLAG__c FROM Email_Domain__mdt WHERE Generic_FLAG__c = TRUE]
        );
        for (Email_Domain__mdt thisDomain : genericEmailDomainList) {
            genericEmailDomainSet.add(thisDomain.Email_Domains__c.tolowercase());
        }
        return genericEmailDomainSet;
    }

    /**
     * @description if a Case is being Created and assigned to the Sales Operation Queue or PSE Queue check if the Contact exists
     * and assign it to the Contacts Owner
     * @param newCaseList - list of new cases to be created
     */
    public static void caseContactAssignment(List<Case> newCaseList) {
        List<Case> contactCheckCaseList = new List<Case>();
        System.debug('Found some Cases to Route to Contact Owner: ' + newCaseList.size());
        for (Case myCase : newCaseList) {
            if (!String.isBlank(myCase.SuppliedEmail)) {
                contactCheckCaseList.add(myCase);
            }
        }

        if (!contactCheckCaseList.isEmpty()) {
            Set<String> validQueueSet = new Set<String>();
            validQueueSet.add('Sales Queue');
            validQueueSet.add('Pre-Sales Engineering Queue');
            // Get the ID for the Sales Operations Queue and PSE Queue
            List<Group> validQueList = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN :validQueueSet];
            Map<String, ID> validQuesIDMap = new Map<String, ID>();

            for (Group myGroup : validQueList) {
                validQuesIDMap.put(mygroup.name, myGroup.Id);
            }

            Set<String> caseEmailSet = new Set<String>();
            for (Case myCase : newCaseList) {
                if (validQuesIDMap.get('Sales Queue') == myCase.OwnerId) {
                    caseEmailSet.add(myCase.SuppliedEmail);
                }
                if (
                    (validQuesIDMap.get('Pre-Sales Engineering Queue') == myCase.OwnerID ||
                    myCase.OwnerID == AppConstants.API_USER ||
                    myCase.OwnerId == AppConstants.SALES_API_USER) && myCase.Origin == 'Email: Quotes@'
                ) {
                    caseEmailSet.add(myCase.SuppliedEmail);
                }

                if (
                    (validQuesIDMap.get('Pre-Sales Engineering Queue') == myCase.OwnerID ||
                    myCase.OwnerID == AppConstants.API_USER ||
                    myCase.OwnerId == AppConstants.SALES_API_USER) && myCase.Origin == 'Email: getaquote@'
                ) {
                    caseEmailSet.add(myCase.SuppliedEmail);
                }
            }

            if (!caseEmailSet.isEmpty()) {
                // Search for Contacts with matching email
                List<Contact> existingContactList = [
                    SELECT ID, Primary_Email__C, AccountID, OwnerID, Owner.IsActive
                    FROM Contact
                    WHERE Primary_Email__C IN :caseEmailSet AND Owner.IsActive = TRUE
                ];
                Map<String, Contact> emailContactMap = new Map<String, Contact>();
                for (Contact myContact : existingContactList) {
                    emailContactMap.put(myContact.Primary_Email__C, myContact);
                }
                //Update the Owner from the Queue to the matching Contact
                for (Case myCase : contactCheckCaseList) {
                    if (emailContactMap.containsKey(myCase.SuppliedEmail)) {
                        myCase.OwnerID = emailContactMap.get(myCase.SuppliedEmail).OwnerID;
                        myCase.Contact_Match_Route_to_Sales_Owner_Flag__c = true;
                    }
                }
            }
        }
    }

    /**
     * @description keep junction object updated
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void syncCaseJunctions(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Set<Id> junctionToDelete = new Set<Id>();
        Map<Id, CaseOpportunity__c> casesWithNewQuote = new Map<Id, CaseOpportunity__c>();
        Map<Id, List<CaseOpsOrder__c>> casesWithNewOpsOrder = new Map<Id, List<CaseOpsOrder__c>>();
        Set<Id> setCaseFromDeleteOrder = new Set<Id>();
        Set<String> setCaseOrdersDelete = new Set<String>();

        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Case myCase : newCaseList) {
                Boolean caseInsertAndShadowOrOppNotNull =
                    Trigger.isInsert && (myCase.Shadow_Xometry_ERP_ID__c != null || myCase.Opportunity__c != null);
                Boolean caseUpdateAndShadowERPIdChanged =
                    Trigger.isUpdate &&
                    myCase.Shadow_Xometry_ERP_ID__c != null &&
                    (myCase.Shadow_Xometry_ERP_ID__c != oldCaseMap.get(myCase.Id).Shadow_Xometry_ERP_ID__c);
                Boolean caseUpdateAndOppChanged =
                    Trigger.isUpdate &&
                    myCase.Opportunity__c != null &&
                    (myCase.Opportunity__c != oldCaseMap.get(myCase.Id).Opportunity__c);

                Boolean caseUpdatesParentOrderToOrderNotAssociated =
                    Trigger.isUpdate &&
                    myCase.ParentOpsOrder__c != null &&
                    (myCase.ParentOpsOrder__c != oldCaseMap.get(myCase.Id).ParentOpsOrder__c) &&
                    !(myCase.GNOOrder__c == oldCaseMap.get(myCase.Id).GNOOrder__c &&
                    myCase.ParentOpsOrder__c == myCase.GNOOrder__c);

                Boolean caseUpdatesOrderAndParentIsNotOrder =
                    Trigger.isUpdate &&
                    myCase.GNOOrder__c != null &&
                    (myCase.GNOOrder__c != oldCaseMap.get(myCase.Id).GNOOrder__c) &&
                    (myCase.ParentOpsOrder__c != myCase.GNOOrder__c);

                Boolean caseUpdatesParentToOrderNotAssociatedToOldOrders =
                    Trigger.isUpdate &&
                    myCase.ParentOpsOrder__c != oldCaseMap.get(myCase.Id).ParentOpsOrder__c &&
                    myCase.ParentOpsOrder__c == null &&
                    (oldCaseMap.get(myCase.Id).ParentOpsOrder__c != oldCaseMap.get(myCase.Id).GNOOrder__c ||
                    (myCase.GNOOrder__c != oldCaseMap.get(myCase.Id).GNOOrder__c &&
                    myCase.GNOOrder__c == null));

                Boolean caseUpdatesOrderToDifferentOrderThatWasNotParent =
                    Trigger.isUpdate &&
                    myCase.GNOOrder__c != oldCaseMap.get(myCase.Id).GNOOrder__c &&
                    myCase.GNOOrder__c == null &&
                    oldCaseMap.get(myCase.Id).ParentOpsOrder__c != oldCaseMap.get(myCase.Id).GNOOrder__c;

                if (caseInsertAndShadowOrOppNotNull || caseUpdateAndShadowERPIdChanged || caseUpdateAndOppChanged) {
                    CaseOpportunity__c caseOpp = new CaseOpportunity__c();
                    caseOpp.Xometry_ERP_ID__c = myCase.Shadow_Xometry_ERP_ID__c;
                    caseOpp.Xometry_Order_ID__c = myCase.ShadowXometryOrderID__c;
                    caseOpp.Opportunity__c = myCase.Opportunity__c;
                    caseOpp.Case__c = myCase.Id;
                    if (caseUpdateAndShadowERPIdChanged || caseUpdateAndOppChanged) {
                        caseOpp.IsPrimaryOppOnCase__c = true;
                    }
                    casesWithNewQuote.put(myCase.Id, caseOpp);
                }

                if (
                    (Trigger.isInsert &&
                    myCase.ParentOpsOrder__c != null &&
                    myCase.ParentOpsOrder__c != myCase.GNOOrder__c) || caseUpdatesParentOrderToOrderNotAssociated
                ) {
                    CaseOpsOrder__c caseOppOrder = new CaseOpsOrder__c();
                    caseOppOrder.Ops_Order__c = myCase.ParentOpsOrder__c;
                    caseOppOrder.Case__c = myCase.Id;
                    if (!casesWithNewOpsOrder.containsKey(myCase.Id)) {
                        casesWithNewOpsOrder.put(myCase.Id, new List<CaseOpsOrder__c>());
                    }
                    casesWithNewOpsOrder.get(myCase.Id).add(caseOppOrder);
                }

                if ((Trigger.isInsert && myCase.GNOOrder__c != null) || caseUpdatesOrderAndParentIsNotOrder) {
                    CaseOpsOrder__c caseOppOrder = new CaseOpsOrder__c();

                    caseOppOrder.Ops_Order__c = myCase.GNOOrder__c;
                    caseOppOrder.Case__c = myCase.Id;
                    if (!casesWithNewOpsOrder.containsKey(myCase.Id)) {
                        casesWithNewOpsOrder.put(myCase.Id, new List<CaseOpsOrder__c>());
                    }
                    casesWithNewOpsOrder.get(myCase.Id).add(caseOppOrder);
                }

                if (caseUpdatesParentToOrderNotAssociatedToOldOrders) {
                    setCaseFromDeleteOrder.add(myCase.Id);
                    setCaseOrdersDelete.add(myCase.Id + '-' + oldCaseMap.get(myCase.Id).ParentOpsOrder__c);
                }

                if (caseUpdatesOrderToDifferentOrderThatWasNotParent) {
                    setCaseFromDeleteOrder.add(myCase.Id);
                    setCaseOrdersDelete.add(myCase.Id + '-' + oldCaseMap.get(myCase.Id).GNOOrder__c);
                }
            }

            if (!casesWithNewQuote.isEmpty() && CaseOpportunityHandler.processingPrimaryOppOnCase != true) {
                syncCaseOpportunityRecords(casesWithNewQuote);
            }

            if (!casesWithNewOpsOrder.isEmpty() || !setCaseFromDeleteOrder.isEmpty()) {
                syncCaseOrdersRecords(casesWithNewOpsOrder, setCaseFromDeleteOrder, setCaseOrdersDelete);
            }
        }

        if (Trigger.isDelete) {
            //looking for junction objects related to the deleted case and delete them too
            DatabaseUtilities.deleteFromDatabase(
                [SELECT Id FROM CaseOpportunity__c WHERE Case__c IN :oldCaseMap.keySet()],
                'CaseHandler.syncCaseQuote',
                'Delete junction object when his case is deleted'
            );

            DatabaseUtilities.deleteFromDatabase(
                [SELECT Id FROM CaseOpsOrder__c WHERE Case__c IN :oldCaseMap.keySet()],
                'CaseHandler.syncCaseQuote',
                'Delete junction object when his case is deleted'
            );
        }
    }

    /*
     * @description when the case changes owner, is closed or opened the case, a caseHistory record is created with the value of the previous owner,
     * the new one, and the duration since the case or the last caseHistory record was created
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void createRecordHistory(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        String strUserPrefix = User.sObjectType.getDescribe().getKeyPrefix();
        Timezone tz = Timezone.getTimeZone('America/New_York');
        Integer hoursToAddForDST = tz.getOffset(DateTime.now()) == 14400000 ? 2 : 1;

        Set<Id> setIdOwners = new Set<Id>();
        Map<Id, Case> caseMap = new Map<Id, Case>();

        for (Case thisCase : newCaseList) {
            if (
                thisCase.OwnerId != oldCaseMap.get(thisCase.Id).OwnerId ||
                thisCase.IsClosed != oldCaseMap.get(thisCase.Id).IsClosed
            ) {
                setIdOwners.add(thisCase.OwnerId);
                setIdOwners.add(oldCaseMap.get(thisCase.Id).OwnerId);
                caseMap.put(thisCase.Id, thisCase);
            }
        }

        if (!caseMap.isEmpty()) {
            Map<Id, Case> mapCasesWithHistory = new Map<Id, Case>(
                [
                    SELECT
                        Id,
                        (
                            SELECT Id, CreatedDate
                            FROM Case_history__r
                            WHERE NewUserOwner__c != NULL
                            ORDER BY CreatedDate DESC
                            LIMIT 1
                        )
                    FROM Case
                    WHERE Id IN :caseMap.keySet()
                ]
            );

            Map<Id, User> mapOwnersUsers = new Map<Id, User>([SELECT UserRole.Name FROM User WHERE Id IN :setIdOwners]);

            Map<Id, Group> mapQueue = new Map<Id, Group>(
                [SELECT Id, Name FROM Group WHERE Type IN ('Queue', 'Regular')]
            );

            Id businessHoursId = [SELECT Id FROM BusinessHours WHERE isdefault = TRUE].id;
            Map<Id, Integer> mapOwnerQuantityCases = new Map<Id, Integer>();

            for (AggregateResult objCaseOwner : [
                SELECT Owner.Id ownerId, COUNT(Id) Quantity
                FROM Case
                WHERE ClosedDate = NULL AND OwnerId IN :setIdOwners
                GROUP BY Owner.Id
            ]) {
                mapOwnerQuantityCases.put(
                    objCaseOwner.get('ownerId') + '',
                    Integer.valueOf(objCaseOwner.get('Quantity'))
                );
            }

            Integer intDiff = TimeZone.getTimeZone('America/New_York').getOffSet(System.now()) / 1000 / 3600;

            List<CaseHistory__c> lstCaseHistory = new List<CaseHistory__c>();
            for (Case objCase : caseMap.values()) {
                String strPrefixOldOwner = oldCaseMap.get(objCase.Id).OwnerId != null
                    ? String.valueOf(oldCaseMap.get(objCase.Id).OwnerId).substring(0, 3)
                    : null;
                String strPrefixNewOwner = String.valueOf(objCase.OwnerId).substring(0, 3);
                Boolean blnOldOwnerIsUser = strUserPrefix == strPrefixOldOwner;
                Boolean blnNewOwnerIsUser = strUserPrefix == strPrefixNewOwner;

                Long intDurationLastInteraction = 0;

                if (objCase.IsClosed == oldCaseMap.get(objCase.Id).IsClosed || objCase.IsClosed) {
                    Datetime dttLastInteraction = mapCasesWithHistory.get(objCase.Id).Case_history__r.isEmpty()
                        ? Datetime.valueOf(
                              objCase.CreatedDate.addHours(hoursToAddForDST)
                                  .format('yyyy-MM-dd HH:mm:ss', 'America/New_York')
                          )
                        : Datetime.valueOf(
                              mapCasesWithHistory.get(objCase.Id)
                                  .Case_history__r[0]
                                  .CreatedDate.addHours(hoursToAddForDST)
                                  .format('yyyy-MM-dd HH:mm:ss', 'America/New_York')
                          );

                    intDurationLastInteraction = Math.abs(
                        BusinessHours.diff(
                            businessHoursId,
                            Datetime.valueOf(
                                System.now()
                                    .addHours(hoursToAddForDST)
                                    .format('yyyy-MM-dd HH:mm:ss', 'America/New_York')
                            ),
                            dttLastInteraction
                        ) /
                        1000 /
                        60
                    );
                }

                lstCaseHistory.add(
                    new CaseHistory__c(
                        Case__c = objCase.Id,
                        Name = objCase.CaseNumber + ' ' + System.now().addHours(intDiff),
                        OldUserOwner__c = blnOldOwnerIsUser ? oldCaseMap.get(objCase.Id).OwnerId : null,
                        NewUserOwner__c = blnNewOwnerIsUser ? objCase.OwnerId : null,
                        OldOwnerRole__c = blnOldOwnerIsUser
                            ? mapOwnersUsers.get(oldCaseMap.get(objCase.Id).OwnerId).UserRole.Name
                            : null,
                        NewOwnerRole__c = blnNewOwnerIsUser ? mapOwnersUsers.get(objCase.OwnerId).UserRole.Name : null,
                        OldOwnerText__c = !blnOldOwnerIsUser && oldCaseMap.get(objCase.Id).OwnerId != null
                            ? mapQueue.get(oldCaseMap.get(objCase.Id).OwnerId).Name
                            : null,
                        NewOwnerText__c = !blnNewOwnerIsUser ? mapQueue.get(objCase.OwnerId).Name : null,
                        CloseDate__c = objCase.IsClosed != oldCaseMap.get(objCase.Id).IsClosed && objCase.IsClosed
                            ? System.now()
                            : null,
                        NumberOwnerOpenCases__c = mapOwnerQuantityCases.get(objCase.OwnerId),
                        DurationMinutes__c = intDurationLastInteraction
                    )
                );
            }

            DatabaseUtilities.upsertToDatabase(
                lstCaseHistory,
                'CaseHandler.createRecordHistory',
                'Create and update CaseHistory__c records realted to the Case'
            );
        }
    }

    /**
     * @description keep roll up on Job__c object updated
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void updateJobRollUp(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        //reset jobs that meets conditions and send them to recalculation
        Map<Id, Job__c> jobsToUpdate = new Map<Id, Job__c>();
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Case myCase : newCaseList) {
                Boolean cond1 = Trigger.isInsert && myCase.RecordTypeId == caseSourcingRecordTypeId;
                Boolean cond2 = myCase.Job__c != null && myCase.Status != 'Closed';

                if (cond1 && cond2) {
                    jobsToUpdate.put(myCase.Job__c, new Job__c(Id = myCase.Job__c, Open_Cases__c = 0));
                }

                cond1 = Trigger.isUpdate && myCase.RecordTypeId == caseSourcingRecordTypeId;
                cond2 =
                    cond1 &&
                    (myCase.Status != oldCaseMap.get(myCase.Id).Status &&
                    (myCase.Status == 'Closed' ||
                    oldCaseMap.get(myCase.Id).Status == 'Closed'));
                Boolean cond3 = cond1 && (myCase.Job__c != oldCaseMap.get(myCase.Id).Job__c);

                if (cond2 || cond3) {
                    jobsToUpdate.put(myCase.Job__c, new Job__c(Id = myCase.Job__c, Open_Cases__c = 0));
                    if (cond3) {
                        jobsToUpdate.put(
                            oldCaseMap.get(myCase.Id).Job__c,
                            new Job__c(Id = oldCaseMap.get(myCase.Id).Job__c, Open_Cases__c = 0)
                        );
                    }
                }
            }
        }

        if (Trigger.isDelete) {
            for (Case myCase : oldCaseMap.values()) {
                jobsToUpdate.put(myCase.Job__c, new Job__c(Id = myCase.Job__c, Open_Cases__c = 0));
            }
        }

        if (!jobsToUpdate.isEmpty()) {
            jobsToUpdate.remove(null);
            //recalculate jobs rollup field, getting and counting all related Cases
            for (AggregateResult aggRes : [
                SELECT Job__c, count(Id) OpenCases
                FROM Case
                WHERE RecordType.Name = 'Sourcing' AND Status != 'Closed' AND Job__c IN :jobsToUpdate.keySet()
                GROUP BY Job__c
            ]) {
                jobsToUpdate.get((Id) aggRes.get('Job__c')).Open_Cases__c = (Integer) aggRes.get('OpenCases');
            }

            DatabaseUtilities.upsertToDatabase(
                jobsToUpdate.values(),
                'CaseHandler.updateJobRollUp',
                'Keep Job__c in sync with the amount of Cases'
            );
        }
    }

    /**
     * @description Combined Validations to close Cases
     * Validate if the case is created by Email to case the status is chaged to Closed
     * Validate if the value of the SuppliedEmail field of the record is in the BlackList__mdt,
     * if it is, the case will be automatically closed and it will give the reason why the domain is BlackList
     * @param newCaseList - list of new cases
     */
    public static void closeCaseOnCreation(List<Case> newCaseList) {
        Map<String, String> mapFieldsValidation = new Map<String, String>{
            'Subject' => System.Label.SubjectEmail2Case,
            'Description' => System.Label.DescriptionEmail2Case
        };

        List<BlackList__mdt> lstBlackList = [SELECT MasterLabel FROM BlackList__mdt];
        Set<String> setBlackList = new Set<String>();
        for (BlackList__mdt objBlackList : lstBlackList) {
            setBlackList.add(objBlackList.MasterLabel);
        }

        for (Case objCase : newCaseList) {
            if (objCase.SuppliedEmail != null && setBlackList.contains(objCase.SuppliedEmail.split('@')[1])) {
                if (objCase.recordTypeId == AppConstants.caseGeneralSupportRTypeId) {
                    objCase.Status = 'Solved';
                } else {
                    objCase.Status = 'Closed';
                }
                objCase.Reason = 'Domain is BlackListed';
                objCase.IsClosedByAutoClose__c = true;
            }

            if (objCase.Origin != null && objCase.Origin.contains('Email:')) {
                Boolean blnMeetsAnyCondition = false;
                for (String strField : mapFieldsValidation.keySet()) {
                    String strValueField = objCase.get(strField) + '';
                    if (!blnMeetsAnyCondition && strValueField != 'null') {
                        List<String> lstOption = mapFieldsValidation.get(strField).split(';;');
                        for (String strOption : lstOption) {
                            if (!blnMeetsAnyCondition && String.valueOf(objCase.get(strField)).contains(strOption)) {
                                blnMeetsAnyCondition = true;
                                if (objCase.recordTypeId == AppConstants.caseGeneralSupportRTypeId) {
                                    objCase.Status = 'Solved';
                                } else {
                                    objCase.Status = 'Closed';
                                }
                                objCase.IsClosedByAutoClose__c = true;
                                break;
                            }
                        }
                    } else {
                        break;
                    }
                }
            }
        }
    }

    /**
     * @description check if strings contains any of the keys on the Set
     * @param baseStr - string that could contain our key
     * @param searchSet - set of key strings to search
     * @return retVal - true when any key is found
     */
    static boolean ContainsAnyStringSet(String baseStr, Set<String> searchSet) {
        Boolean retVal = false;

        for (String seartchStr : searchSet) {
            if (baseStr.containsIgnoreCase(seartchStr)) {
                retVal = true;
                break;
            }
        }

        return retVal;
    }

    /**
     * @description When a case changes owner and is assigned to a queue or someone in a queue
     *  it should change to the appropriate Case Record Type
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void setRecordTypeOnOwnerChange(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> casesWithNewOwner = new List<Case>();
        Set<Id> newOwners = new Set<Id>();
        //Only allow record type changes for cases that start as General Support Cases

        for (Case objCase : newCaseList) {
            if (
                //Owner is changed
                objCase.OwnerId != oldCaseMap.get(objCase.Id).OwnerId &&
                //Old record type is in the inclusion list
                objCase.RecordTypeId == AppConstants.caseGeneralSupportRTypeId
            ) {
                casesWithNewOwner.add(objCase);
                newOwners.add(objCase.OwnerId);
            }
        }

        if (!casesWithNewOwner.isEmpty()) {
            //Getting User Role Info
            Map<Id, User> ownerMap = new Map<Id, User>([SELECT Id, UserRole.Name FROM User WHERE Id IN :newOwners]);
            Map<Id, Id> userToRecordType = new Map<Id, Id>();
            Set<Id> usersToLookForQueuesSet = new Set<Id>();

            Boolean casesNeedNewRecordType = false;
            for (Id newOwnerId : ownerMap.keySet()) {
                if (ownerMap.get(newOwnerId) != null) {
                    Id newRecordTypeIdFromRole = AppConstants.ROLE_NAME_TO_CASE_RTYPE_MAP.get(newOwnerId) == null
                        ? caseGeneralSupportRTypeId
                        : AppConstants.ROLE_NAME_TO_CASE_RTYPE_MAP.get(newOwnerId);
                    if (
                        newRecordTypeIdFromRole != AppConstants.caseGeneralSupportRTypeId &&
                        !AppConstants.CASE_RECORD_TYPE_SWITCHING_EXCLUSIONS.contains(newRecordTypeIdFromRole)
                    ) {
                        userToRecordType.put(newOwnerId, newRecordTypeIdFromRole);
                        if (!casesNeedNewRecordType) {
                            casesNeedNewRecordType = true;
                        }
                    } else {
                        usersToLookForQueuesSet.add(newOwnerId);
                    }
                }
            }

            if (!usersToLookForQueuesSet.isEmpty()) {
                for (GroupMember u : [
                    SELECT Group.Name, UserOrGroupId
                    FROM GroupMember
                    WHERE UserOrGroupId IN :usersToLookForQueuesSet
                ]) {
                    Id newRecordTypeIdFromQueue = AppConstants.QUEUE_NAME_TO_CASE_RTYPE_MAP.get(u.Group.Name) == null
                        ? caseGeneralSupportRTypeId
                        : AppConstants.QUEUE_NAME_TO_CASE_RTYPE_MAP.get(u.Group.Name);
                    if (
                        newRecordTypeIdFromQueue != AppConstants.caseGeneralSupportRTypeId &&
                        !AppConstants.CASE_RECORD_TYPE_SWITCHING_EXCLUSIONS.contains(newRecordTypeIdFromQueue)
                    ) {
                        userToRecordType.put(u.UserOrGroupId, newRecordTypeIdFromQueue);
                        if (!casesNeedNewRecordType) {
                            casesNeedNewRecordType = true;
                        }
                    }
                }
            }

            if (casesNeedNewRecordType) {
                for (Case caseToUpdate : casesWithNewOwner) {
                    if (userToRecordType.containsKey(caseToUpdate.OwnerId)) {
                        caseToUpdate.RecordTypeId = userToRecordType.get(caseToUpdate.OwnerId);
                    }
                }
            }
        }
    }

    /**
     * @description Validates if there are CaseOpportunity records related to the cases and if they need to be updated
     * @param casesWithNewQuote - new CaseOpportunity records created based on case records
     */
    private static void syncCaseOpportunityRecords(Map<Id, CaseOpportunity__c> casesWithNewQuote) {
        Map<Id, List<CaseOpportunity__c>> caseJunctionsMap = new Map<Id, List<CaseOpportunity__c>>();
        Set<String> setCaseOpportunitiesKeys = new Set<String>();
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>();
        for (CaseOpportunity__c myCaseOpp : casesWithNewQuote.values()) {
            if (myCaseOpp.Opportunity__c != null) {
                oppsMap.put(myCaseOpp.Opportunity__c, null);
            }
        }

        if (!oppsMap.isEmpty()) {
            for (Opportunity opp : [
                SELECT Id, Last_Quote_Xometry_ERP_ID__c
                FROM Opportunity
                WHERE Id IN :oppsMap.keySet()
            ]) {
                oppsMap.put(opp.Id, opp);
            }
        }

        //looking for junction objects related to case and update his values
        for (CaseOpportunity__c caseOpp : [
            SELECT Id, Case__c, Opportunity__c, Xometry_ERP_ID__c, IsPrimaryOppOnCase__c
            FROM CaseOpportunity__c
            WHERE Case__c IN :casesWithNewQuote.keySet()
        ]) {
            Boolean updateJunction = false;
            setCaseOpportunitiesKeys.add(
                caseOpp.Case__c +
                '-' +
                caseOpp.Xometry_ERP_ID__c +
                '-' +
                caseOpp.Opportunity__c
            );
            if (!caseJunctionsMap.containsKey(caseOpp.Case__c)) {
                caseJunctionsMap.put(caseOpp.Case__c, new List<CaseOpportunity__c>());
            }

            // only fill the Opp if its already empty
            if (
                caseOpp.Opportunity__c == null &&
                casesWithNewQuote.get(caseOpp.Case__c).Opportunity__c != null &&
                (caseOpp.Xometry_ERP_ID__c == null ||
                (caseOpp.Xometry_ERP_ID__c == casesWithNewQuote.get(caseOpp.Case__c).Xometry_ERP_ID__c &&
                caseOpp.Xometry_ERP_ID__c ==
                oppsMap.get(casesWithNewQuote.get(caseOpp.Case__c).Opportunity__c).Last_Quote_Xometry_ERP_ID__c))
            ) {
                caseOpp.Opportunity__c = casesWithNewQuote.get(caseOpp.Case__c).Opportunity__c;
                updateJunction = true;
            }

            //if there is a matching CaseOpp.Opportunity__c and xometry Id is empty, use this junction instead of creating one
            if (
                caseOpp.Opportunity__c != null &&
                casesWithNewQuote.get(caseOpp.Case__c).Opportunity__c != null &&
                casesWithNewQuote.get(caseOpp.Case__c).Xometry_ERP_ID__c != null &&
                (caseOpp.Xometry_ERP_ID__c == null &&
                caseOpp.Opportunity__c == casesWithNewQuote.get(caseOpp.Case__c).Opportunity__c)
            ) {
                caseOpp.Xometry_ERP_ID__c = casesWithNewQuote.get(caseOpp.Case__c).Xometry_ERP_ID__c;
                updateJunction = true;
            }

            //set new Primary junctions, this will execute a reset on junction trigger
            if (casesWithNewQuote.get(caseOpp.Case__c).Opportunity__c != null) {
                Boolean isPrimary = casesWithNewQuote.get(caseOpp.Case__c).Opportunity__c == caseOpp.Opportunity__c;

                if (isPrimary && isPrimary != caseOpp.IsPrimaryOppOnCase__c) {
                    caseOpp.IsPrimaryOppOnCase__c = isPrimary;
                    updateJunction = true;
                }
            }

            if (updateJunction) {
                caseJunctionsMap.get(caseOpp.Case__c).add(caseOpp);
            }
        }

        for (Id caseId : casesWithNewQuote.keySet()) {
            CaseOpportunity__c caseOpp = casesWithNewQuote.get(caseId);

            //Solving Xometry Id from related objects
            if (caseOpp.Xometry_ERP_ID__c == null) {
                if (caseOpp.Opportunity__c != null && oppsMap.containsKey(caseOpp.Opportunity__c)) {
                    caseOpp.Xometry_ERP_ID__c = oppsMap.get(caseOpp.Opportunity__c).Last_Quote_Xometry_ERP_ID__c;
                }
            }

            if (caseOpp.Opportunity__c != null && caseOpp.Xometry_ERP_ID__c != null) {
                //avoid insert caseopp.XometryId with unmatched opp.XometryId
                if (
                    oppsMap.get(caseOpp.Opportunity__c).Last_Quote_Xometry_ERP_ID__c != null &&
                    caseOpp.Xometry_ERP_ID__c != oppsMap.get(caseOpp.Opportunity__c).Last_Quote_Xometry_ERP_ID__c
                ) {
                    continue;
                }

                //cleanup CaseOpp.XomId if Opp.XomId is null
                if (oppsMap.get(caseOpp.Opportunity__c).Last_Quote_Xometry_ERP_ID__c == null) {
                    caseOpp.Xometry_ERP_ID__c = null;
                }
            }

            //check that each case has a junction for update
            //if not create a new junction
            if (
                (!caseJunctionsMap.containsKey(caseId) || caseJunctionsMap.get(caseId).isEmpty()) &&
                !setCaseOpportunitiesKeys.contains(
                    caseId +
                    '-' +
                    caseOpp.Xometry_ERP_ID__c +
                    '-' +
                    caseOpp.Opportunity__c
                )
            ) {
                if (!caseJunctionsMap.containsKey(caseId)) {
                    caseJunctionsMap.put(caseId, new List<CaseOpportunity__c>());
                }

                caseJunctionsMap.get(caseId).add(caseOpp);
                setCaseOpportunitiesKeys.add(caseId + '-' + caseOpp.Xometry_ERP_ID__c + '-' + caseOpp.Opportunity__c);
            }
        }

        if (!caseJunctionsMap.isEmpty()) {
            //collect all junctions to save
            List<CaseOpportunity__c> junctionsToUpdate = new List<CaseOpportunity__c>();
            for (List<CaseOpportunity__c> caseOppList : caseJunctionsMap.values()) {
                junctionsToUpdate.addAll(caseOppList);
            }

            DatabaseUtilities.upsertToDatabase(
                junctionsToUpdate,
                'CaseHandler.syncCaseQuote',
                'Keep junction object in sync with Case field'
            );
        }
    }

    /**
     * @description Validates if there are CaseOrders records related to the cases and if they need to be updated
     * @param casesWithNewQuote - new CaseOrders records created based on case records
     */
    private static void syncCaseOrdersRecords(
        Map<Id, List<CaseOpsOrder__c>> casesWithNewOrder,
        Set<Id> setCaseFromDeleteOrder,
        Set<String> setCaseOrdersDelete
    ) {
        List<CaseOpsOrder__c> lstDeleteJunctionRecord = new List<CaseOpsOrder__c>();
        //looking for junction objects related to case and update his values
        if (!setCaseFromDeleteOrder.isEmpty()) {
            for (CaseOpsOrder__c caseOppOrder : [
                SELECT Id, Case__c, Ops_Order__c
                FROM CaseOpsOrder__c
                WHERE Case__c IN :setCaseFromDeleteOrder
            ]) {
                if (setCaseOrdersDelete.contains(caseOppOrder.Case__c + '-' + caseOppOrder.Ops_Order__c)) {
                    lstDeleteJunctionRecord.add(caseOppOrder);
                }
            }

            if (!lstDeleteJunctionRecord.isEmpty()) {
                DatabaseUtilities.deleteFromDatabase(
                    lstDeleteJunctionRecord,
                    'CaseHandler.syncCaseOrdersRecords',
                    'Delete junction object when the field of the case is null or The ParentOrder and GNOOrder is the same'
                );
            }
        }

        if (!casesWithNewOrder.isEmpty()) {
            //collect all junctions to save
            List<CaseOpsOrder__c> lstInsertJuntionRecord = new List<CaseOpsOrder__c>();
            for (List<CaseOpsOrder__c> caseOppList : casesWithNewOrder.values()) {
                lstInsertJuntionRecord.addAll(caseOppList);
            }

            Map<Id, String> orderIdsToCaseMap = new Map<Id, String>();
            Map<Id, CaseOpsOrder__c> orderToCaseOpsOrderMap = new Map<Id, CaseOpsOrder__c>();
            for (CaseOpsOrder__c coo : lstInsertJuntionRecord) {
                orderIdsToCaseMap.put(coo.Ops_Order__c, coo.Case__c);
                orderToCaseOpsOrderMap.put(coo.Ops_Order__c, coo);
            }
            for (CaseOpsOrder__c coo : [
                SELECT Id, Ops_Order__c, Case__c
                FROM CaseOpsOrder__c
                WHERE Ops_Order__c IN :orderIdsToCaseMap.keySet() AND Case__c IN :orderIdsToCaseMap.values()
            ]) {
                if (
                    orderIdsToCaseMap.containsKey(coo.Ops_Order__c) &&
                    orderIdsToCaseMap.get(coo.Ops_Order__c) == coo.Case__c
                ) {
                    orderToCaseOpsOrderMap.remove(coo.Ops_Order__c);
                }
            }

            DatabaseUtilities.upsertToDatabase(
                orderToCaseOpsOrderMap.values(),
                'CaseHandler.syncCaseQuote',
                'Keep junction object in sync with Case field'
            );
        }
    }

    /**
     * @description A case should never be owned by any of the system users
     * for CPC Call center closed cases should not be owned by a queue.
     * This method changes the case to a queue or cpc house user
     * @param newCaseList - list of new or updated cases
     */
    public static void noSystemOwner(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Set<String> systemUserIdSet = AppConstants.getSystemUsersIdSet();

        List<Case> checkNewOwnerCaseList = new List<Case>();

        for (Case c : newCaseList) {
            Boolean cond = (Trigger.isInsert || Trigger.isUpdate) && systemUserIdSet.contains(c.ownerId);
            cond = cond || (Trigger.isInsert && AppConstants.CASE_CLOSED_STATUSES.contains(c.Status));
            cond =
                cond ||
                (Trigger.isUpdate &&
                AppConstants.CASE_CLOSED_STATUSES.contains(c.Status) &&
                c.Status != oldCaseMap.get(c.Id).Status);
            cond = cond || (Trigger.isUpdate && c.OwnerId != oldCaseMap.get(c.Id).OwnerId);

            // CPC Call center requires closed cases to be owned by a user
            if (cond) {
                checkNewOwnerCaseList.add(c);
            }
        }

        if (!checkNewOwnerCaseList.isEmpty()) {
            Id cpcQueueID; //OmniChannelQueue
            Id cpcSystemOnlyID; //OmniChannel Queue with a routing configuration to nowhere and no members
            Id pseQueueID;

            for (Group g : [
                SELECT ID, DeveloperName
                FROM Group
                WHERE
                    DeveloperName IN ('CPC_Support', 'Pre_Sales_Engineering_Queue', 'CPC_System_Only')
                    AND Type = 'Queue'
            ]) {
                if (g.DeveloperName == 'CPC_Support') {
                    cpcQueueID = g.Id;
                }
                if (g.DeveloperName == 'Pre_Sales_Engineering_Queue') {
                    pseQueueID = g.Id;
                }
                if (g.DeveloperName == 'CPC_System_Only') {
                    cpcSystemOnlyID = g.Id;
                }
            }

            for (Case c : checkNewOwnerCaseList) {
                if (systemUserIdSet.contains(c.ownerId) && c.RecordTypeId == casePSERecordTypeId) {
                    c.ownerId = pseQueueID;
                }

                if (systemUserIdSet.contains(c.ownerId)) {
                    c.ownerId = cpcSystemOnlyID;
                }

                // CPC Call center requires closed cases to be owned by a user
                if (
                    AppConstants.CASE_CLOSED_STATUSES.contains(c.Status) &&
                    (c.OwnerId == cpcQueueID ||
                    c.OwnerId == cpcSystemOnlyID)
                ) {
                    c.OwnerId = AppConstants.CPC_HOUSE_USER;
                }
            }
        }
    }

    /**
     * @description When a case changes Outcome and is PSE Record Type
     *  it should change to the appropriate Case Record Type
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void createOutcomeRecordHistory(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> journalCases = new List<Case>();
        for (Case c : newCaseList) {
            if (c.RecordTypeId == casePSERecordTypeId) {
                boolean cond =
                    Trigger.isInsert &&
                    (c.PSEOutcome__c != null ||
                    c.OutcomeSalesUse__c != null ||
                    c.SalesOpsOutcome__c != null);
                cond =
                    cond ||
                    (Trigger.isUpdate &&
                    (oldCaseMap.get(c.Id).PSEOutcome__c != c.PSEOutcome__c ||
                    oldCaseMap.get(c.Id).OutcomeSalesUse__c != c.OutcomeSalesUse__c ||
                    oldCaseMap.get(c.Id).SalesOpsOutcome__c != c.SalesOpsOutcome__c));
                if (cond) {
                    journalCases.add(c);
                }
            }
        }

        if (!journalCases.isEmpty()) {
            List<CaseHistory__c> lstCaseHistory = new List<CaseHistory__c>();

            Integer intDiff = TimeZone.getTimeZone('America/New_York').getOffSet(System.now()) / 1000 / 3600;
            Datetime timeNow = System.now().addHours(intDiff);

            for (Case c : journalCases) {
                CaseHistory__c caseHistory = new CaseHistory__c();
                caseHistory.Name = c.CaseNumber + ' ' + timeNow;
                caseHistory.Case__c = c.Id;
                caseHistory.Opportunity__c = c.Opportunity__c;

                if (Trigger.isInsert) {
                    caseHistory.NewPSEOutcome__c = c.PSEOutcome__c;
                    caseHistory.NewOutcomeSalesUse__c = c.OutcomeSalesUse__c;
                    caseHistory.NewOutcomeSalesUse__c = c.SalesOpsOutcome__c;
                }

                if (Trigger.isUpdate && oldCaseMap.get(c.Id).PSEOutcome__c != c.PSEOutcome__c) {
                    caseHistory.NewPSEOutcome__c = c.PSEOutcome__c;
                    caseHistory.OldPSEOutcome__c = oldCaseMap.get(c.Id).PSEOutcome__c;
                }

                if (Trigger.isUpdate && oldCaseMap.get(c.Id).OutcomeSalesUse__c != c.OutcomeSalesUse__c) {
                    caseHistory.NewOutcomeSalesUse__c = c.OutcomeSalesUse__c;
                    caseHistory.OldOutcomeSalesUse__c = oldCaseMap.get(c.Id).OutcomeSalesUse__c;
                }

                if (Trigger.isUpdate && oldCaseMap.get(c.Id).SalesOpsOutcome__c != c.SalesOpsOutcome__c) {
                    caseHistory.NewSalesOpsOutcome__c = c.SalesOpsOutcome__c;
                    caseHistory.OldSalesOpsOutcome__c = oldCaseMap.get(c.Id).SalesOpsOutcome__c;
                }

                lstCaseHistory.add(caseHistory);
            }

            DatabaseUtilities.insertToDatabase(
                lstCaseHistory,
                'CaseHandler.outcomeJournalEntry',
                'Create and update CaseHistory__c records realted to the Case'
            );
        }
    }

    /**
     * @description Adding Case owner to Team Members, TeamRole depends on Owner Profile
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void createTeamMember(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Map<Id, Case> teamCases = new Map<Id, Case>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        for (Case c : newCaseList) {
            Boolean cond = c.RecordTypeId == casePSERecordTypeId;

            Boolean cond2 = Trigger.isInsert;
            cond2 |= Trigger.isUpdate && oldCaseMap.get(c.Id).OwnerId != c.OwnerId;

            if (cond && cond2) {
                teamCases.put(c.Id, c);
                userIds.add(c.OwnerId);
                if (c.CaseContactOwnerID__c != null) {
                    userIds.add(c.CaseContactOwnerID__c);
                }
            }

            Boolean cond3 = Trigger.isInsert && c.Opportunity__c != null;
            cond3 |=
                Trigger.isUpdate &&
                oldCaseMap.get(c.Id).Opportunity__c != c.Opportunity__c &&
                c.Opportunity__c != null;

            if (cond && cond3) {
                teamCases.put(c.Id, c);
                oppMap.put(c.Opportunity__c, null);
            }
        }

        if (!teamCases.isEmpty()) {
            List<CaseTeamMember> addTeamMembers = new List<CaseTeamMember>();
            Map<Id, User> usersMap = new Map<Id, User>();
            Map<Id, Set<Id>> membersMap = new Map<Id, Set<Id>>();

            Map<String, Id> rolesMap = new Map<String, Id>();
            for (CaseTeamRole tRole : [SELECT Id, Name FROM CaseTeamRole]) {
                rolesMap.put(tRole.Name, tRole.Id);
            }
            //Getting "special UserIds" for TSE
            Set<Id> specialUserIds = new Set<Id>();
            for (Admin_Ref_Variable__mdt adminRefVarValues : [
                SELECT Text_Ref_Var__c
                FROM Admin_Ref_Variable__mdt
                WHERE DeveloperName = 'createTSETeamMember'
            ]) {
                specialUserIds.addAll((List<Id>) adminRefVarValues.Text_Ref_Var__c.split(';'));
            }

            //mapping already members to avoid duplicates
            for (CaseTeamMember tMember : [
                SELECT MemberId, ParentId
                FROM CaseTeamMember
                WHERE ParentId IN :teamCases.keySet()
            ]) {
                if (!membersMap.containsKey(tMember.ParentId)) {
                    membersMap.put(tMember.ParentId, new Set<Id>());
                }
                membersMap.get(tMember.ParentId).add(tMember.MemberId);
            }

            if (!userIds.isEmpty()) {
                for (User u : [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id IN :userIds]) {
                    usersMap.put(u.Id, u);
                }
            }

            if (!oppMap.isEmpty()) {
                oppMap = new Map<Id, Opportunity>(
                    [
                        SELECT OwnerId
                        FROM Opportunity
                        WHERE
                            Id IN :oppMap.keySet()
                            AND OwnerId != :AppConstants.CPC_HOUSE_USER
                            AND OwnerId != :AppConstants.API_USER
                    ]
                );
            }

            for (Case c : teamCases.values()) {
                //On Case Creation, insert case team, memberid = case’s contact Owner
                if (Trigger.isInsert) {
                    Boolean cond =
                        usersMap.containsKey(c.CaseContactOwnerID__c) &&
                        !(membersMap.containsKey(c.Id) && membersMap.get(c.Id).contains(c.CaseContactOwnerID__c));
                    Boolean cond2 = cond && usersMap.get(c.CaseContactOwnerID__c).Profile.Name == 'Xometry Sales User';
                    Boolean cond3 =
                        cond && usersMap.get(c.CaseContactOwnerID__c).Profile.Name == 'Xometry Sales Leadership';
                    if (cond2 || cond3) {
                        CaseTeamMember newTeamMember = new CaseTeamMember();
                        newTeamMember.ParentId = c.Id;
                        newTeamMember.MemberId = c.CaseContactOwnerID__c;
                        newTeamMember.TeamRoleId = rolesMap.get('PSE2.0-Contact Owner');
                        addTeamMembers.add(newTeamMember);
                        if (!membersMap.containsKey(newTeamMember.ParentId)) {
                            membersMap.put(newTeamMember.ParentId, new Set<Id>());
                        }
                        membersMap.get(newTeamMember.ParentId).add(newTeamMember.MemberId);
                    }
                }

                //checking owner roles to add as team members
                if (
                    usersMap.containsKey(c.OwnerId) &&
                    !(membersMap.containsKey(c.Id) && membersMap.get(c.Id).contains(c.OwnerId))
                ) {
                    //When users with TSE Role become case owners
                    //add them to Case Team with the case team role PSE2.0-TSE
                    if (usersMap.get(c.OwnerId).UserRole.Name == 'TSE' || specialUserIds.contains(c.OwnerId)) {
                        CaseTeamMember newTeamMember = new CaseTeamMember();
                        newTeamMember.ParentId = c.Id;
                        newTeamMember.MemberId = c.OwnerId;
                        newTeamMember.TeamRoleId = rolesMap.get('PSE2.0-TSE');
                        addTeamMembers.add(newTeamMember);
                        if (!membersMap.containsKey(newTeamMember.ParentId)) {
                            membersMap.put(newTeamMember.ParentId, new Set<Id>());
                        }
                        membersMap.get(newTeamMember.ParentId).add(newTeamMember.MemberId);
                    }
                }

                //checking owner profiles to add as team members
                if (
                    usersMap.containsKey(c.OwnerId) &&
                    !(membersMap.containsKey(c.Id) && membersMap.get(c.Id).contains(c.OwnerId))
                ) {
                    //When a user with Xometry Pre-Sales Engineering profile becomes the case owner, PSE2.0 -PSE role give to that user
                    if (usersMap.get(c.OwnerId).Profile.Name == 'Xometry Pre-Sales Engineering') {
                        CaseTeamMember newTeamMember = new CaseTeamMember();
                        newTeamMember.ParentId = c.Id;
                        newTeamMember.MemberId = c.OwnerId;
                        newTeamMember.TeamRoleId = rolesMap.get('PSE2.0-PSE');
                        addTeamMembers.add(newTeamMember);
                        if (!membersMap.containsKey(newTeamMember.ParentId)) {
                            membersMap.put(newTeamMember.ParentId, new Set<Id>());
                        }
                        membersMap.get(newTeamMember.ParentId).add(newTeamMember.MemberId);
                    }

                    //When a user with Xometry Sales Ops profile becomes the case owner
                    //add the user to the case team with a role PSE2.0-Sales Ops
                    if (usersMap.get(c.OwnerId).Profile.Name == 'Xometry Sales Ops') {
                        CaseTeamMember newTeamMember = new CaseTeamMember();
                        newTeamMember.ParentId = c.Id;
                        newTeamMember.MemberId = c.OwnerId;
                        newTeamMember.TeamRoleId = rolesMap.get('PSE2.0-Sales Ops');
                        addTeamMembers.add(newTeamMember);
                        if (!membersMap.containsKey(newTeamMember.ParentId)) {
                            membersMap.put(newTeamMember.ParentId, new Set<Id>());
                        }
                        membersMap.get(newTeamMember.ParentId).add(newTeamMember.MemberId);
                    }
                }

                //If the case has associated with an Opp, Add the Opp Owner to the case team
                if (
                    c.Opportunity__c != null &&
                    oppMap.containsKey(c.Opportunity__c) &&
                    !(membersMap.containsKey(c.Id) &&
                    membersMap.get(c.Id).contains(oppMap.get(c.Opportunity__c).OwnerId))
                ) {
                    CaseTeamMember newTeamMember = new CaseTeamMember();
                    newTeamMember.ParentId = c.Id;
                    newTeamMember.MemberId = oppMap.get(c.Opportunity__c).OwnerId;
                    newTeamMember.TeamRoleId = rolesMap.get('PSE2.0-Opportunity Owner');
                    addTeamMembers.add(newTeamMember);

                    if (!membersMap.containsKey(newTeamMember.ParentId)) {
                        membersMap.put(newTeamMember.ParentId, new Set<Id>());
                    }
                    membersMap.get(newTeamMember.ParentId).add(newTeamMember.MemberId);
                }
            }

            DatabaseUtilities.insertToDatabase(
                addTeamMembers,
                'CaseHandler.createTeamMember',
                'Create CaseTeamMember records realted to the Case'
            );
        }
    }

    /**
     * @description Checks if a newly inserted case has an account and if updated cases
     * added an account. If the account is VIP sets the case priority to high
     * @param newCaseList Newly inserted or updated cases from trigger
     * @param oldCaseMap Old cases map from trigger
     */
    public static void checkAccountVIP(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        List<Case> casesToUpdate = new List<Case>();
        Set<Id> accountsToSearch = new Set<Id>();
        for (Case c : newCaseList) {
            if (Trigger.isInsert) {
                if (!String.isBlank(c.AccountId)) {
                    casesToUpdate.add(c);
                    accountsToSearch.add(c.AccountId);
                }
            }
            if (Trigger.isUpdate) {
                if (!String.isBlank(c.AccountId) && String.isBlank(oldCaseMap.get(c.Id).AccountId)) {
                    casesToUpdate.add(c);
                    accountsToSearch.add(c.AccountId);
                }
            }
        }

        if (!accountsToSearch.isEmpty()) {
            Map<ID, Account> returnedAccounts = new Map<Id, Account>(
                [SELECT Id, VIP__c FROM Account WHERE Id IN :accountsToSearch AND VIP__c = TRUE]
            );

            for (Case c : casesToUpdate) {
                if (!String.isBlank(c.AccountId) && returnedAccounts.containsKey(c.AccountId)) {
                    Account thisAccount = returnedAccounts.get(c.AccountId);
                    if (thisAccount.VIP__c == true) {
                        c.Priority = 'High';
                    }
                }
            }
        }
    }

    public static void assignOwnerByUser(List<Case> newCaseList) {
        List<Case> casesToAssign = new List<Case>();
        Set<String> emailSet = new Set<String>();
        for (Case c : newCaseList) {
            if (
                !String.isBlank(c.SuppliedEmail) &&
                c.SuppliedEmail.contains('@xometry.com') &&
                c.RecordTypeId == casePSERecordTypeId
            ) {
                System.debug('email is not blank, contains xom, and is pse');
                emailSet.add(c.SuppliedEmail);
                casesToAssign.add(c);
            }
        }
        if (!casesToAssign.isEmpty()) {
            Map<String, User> userEmailMap = new Map<String, User>();
            List<User> users = [
                SELECT Id, Profile.Name, Email, IsActive
                FROM User
                WHERE Email IN :emailSet AND Profile.Name = 'Xometry Sales User' AND IsActive = TRUE
            ];

            for (User u : users) {
                System.debug(u);
                userEmailMap.put(u.Email, u);
            }

            for (Case c : casesToAssign) {
                if (userEmailMap.containsKey(c.SuppliedEmail)) {
                    c.OwnerId = userEmailMap.get(c.SuppliedEmail).Id;
                }
            }
        }
    }

    /**
     * @description Associate existing Opps to new Cases with matching Shadow Job IDs
     * Supplies_Xometry_Job__c's field
     * @param newCases - List of newly created cases
     */
    public static void assignSuppliesOppToCase(List<Case> newCases) {
        Set<String> jobIDSet = new Set<String>();
        for (Case c : newCases) {
            if (
                (c.RecordTypeId == AppConstants.caseSellerMarketPlaceRTypeId ||
                c.RecordTypeId == AppConstants.caseFinServRTypeId) && c.Supplies_Xometry_Job__c != null
            ) {
                jobIDSet.add(c.Supplies_Xometry_Job__c);
            }
        }

        //Fetch existing opportunities
        if (!jobIDSet.isEmpty()) {
            Map<String, ID> jobIDToExistingOppMap = new Map<String, ID>();
            List<Opportunity> suppliesOppList = [
                SELECT Shadow_JobId__c, Id
                FROM Opportunity
                WHERE Shadow_JobId__c IN :jobIDSet AND RecordTypeID = :AppConstants.oppSellerMarketplaceRecordTypeId
            ];
            //  creating a map that contains opportunities's id
            if (!suppliesOppList.isEmpty()) {
                for (Opportunity opp : suppliesOppList) {
                    jobIDToExistingOppMap.put(opp.Shadow_JobId__c, opp.Id);
                }
                //assigning opportunities to the cases
                for (Case c : newCases) {
                    if (
                        (c.RecordTypeId == AppConstants.caseSellerMarketPlaceRTypeId ||
                        c.RecordTypeId == AppConstants.caseFinServRTypeId) &&
                        jobIDToExistingOppMap.containsKey(c.Supplies_Xometry_Job__c)
                    ) {
                        c.Opportunity__c = jobIDToExistingOppMap.get(c.Supplies_Xometry_Job__c);
                    }
                }
            }
        }
    }

    /**
     * @description Checks if a new or closed case is a collections case,
     * and closes out all other collections cases for that billing profile
     * @param newCaseList Newly inserted or updated cases from trigger
     * @param oldCaseMap Old cases map from trigger
     */
    public static void closeCollectionsCases(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Map<String, String> billingProfileIdToCaseDescriptionMap = new Map<String, String>();
        Set<String> billingProfilesWithZeroBalance = new Set<String>();
        Set<Id> casesNotToClose = new Set<Id>();

        for (Case c : newCaseList) {
            Boolean isCollectionCase =
                c.RecordTypeID == AppConstants.collectionsRTypeId && String.isNotBlank(c.Billing_Profile_ID__c);
            Boolean netNewCase = Trigger.isInsert && c.Total_Past_Due__c > 0;
            Boolean balanceIsZero =
                Trigger.isUpdate &&
                c.Total_Past_Due__c <= 0 &&
                c.IsClosed &&
                !oldCaseMap.get(c.Id).IsClosed;

            if (isCollectionCase && (netNewCase || balanceIsZero)) {
                billingProfileIdToCaseDescriptionMap.put(
                    c.Billing_Profile_ID__c,
                    balanceIsZero
                        ? '$0.00 Total Due balance - COLLECTIONS CASE CLOSED'
                        : 'OUTDATED INFORMATION - COLLECTIONS CASE CLOSED'
                );
                if (netNewCase) {
                    casesNotToClose.add(c.Id);
                }
                if (balanceIsZero) {
                    billingProfilesWithZeroBalance.add(c.Billing_Profile_ID__c);
                }
            }
        }

        if (!billingProfileIdToCaseDescriptionMap.isEmpty()) {
            List<Case> casesToUpdateList = new List<Case>();

            for (Case c : [
                SELECT ID, Status, Description, Total_Past_Due__c, Billing_Profile_ID__c
                FROM Case
                WHERE
                    RecordTypeID = :AppConstants.collectionsRTypeId
                    AND IsClosed = FALSE
                    AND Billing_Profile_ID__c IN :billingProfileIdToCaseDescriptionMap.keySet()
                    AND ID NOT IN :casesNotToClose
            ]) {
                Case updatedCase = new Case();
                updatedCase.Id = c.Id;
                updatedCase.Description = billingProfileIdToCaseDescriptionMap.get(c.Billing_Profile_ID__c);
                if (billingProfilesWithZeroBalance.contains(c.Billing_Profile_ID__c)) {
                    updatedCase.Total_Past_Due__c = 0;
                }
                if (c.Status != 'Response Received') {
                    updatedCase.Status = 'Solved';
                }
                casesToUpdateList.add(updatedCase);
            }

            if (casesToUpdateList.size() > 0) {
                DatabaseUtilities.saveToDatabase(
                    casesToUpdateList,
                    'CaseHandler.closeCollectionsCases',
                    'Updating duplicate collections cases'
                );
            }
        }
    }

    /**
     * @description Checks if there is an existing Collections or Sourcing case
     * before re-opening a closed case or creating a new one
     * @param newCaseList Updated cases from trigger
     * @param oldCaseMap Old cases map from trigger
     */
    public static void restrictDuplicateCases(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Map<Id, Case> updatedCollectionsCaseMap = new Map<Id, Case>();
        Set<String> newPartsToBeSourcedSet = new Set<String>();

        for (Case c : newCaseList) {
            Boolean isUpdatedCollectionsCase =
                Trigger.isUpdate &&
                c.RecordTypeID == AppConstants.collectionsRTypeId &&
                String.isNotBlank(c.Billing_Profile_ID__c) &&
                c.Status != oldCaseMap.get(c.Id).Status;

            Boolean isNewSourcingCase =
                Trigger.isInsert &&
                c.RecordTypeID == AppConstants.caseSourcingRTypeId &&
                String.isNotBlank(c.OrderedPartID__c);

            if (isUpdatedCollectionsCase) {
                updatedCollectionsCaseMap.put(c.Id, c);
            } else if (isNewSourcingCase) {
                newPartsToBeSourcedSet.add(c.OrderedPartID__c);
            }
        }

        //COLLECTIONS LOGIC
        if (!updatedCollectionsCaseMap.isEmpty()) {
            CaseUtility caseUtility = CaseUtility.getInstance();
            Set<Id> casesBeingReopenedSet = new Set<Id>();
            Map<String, Case> billingProfilesWithReopenedCasesMap = new Map<String, Case>();

            for (Case updatedCase : updatedCollectionsCaseMap.values()) {
                Boolean isClosed = caseUtility.isClosed(updatedCase.Status);
                Boolean wasClosed = caseUtility.isClosed(oldCaseMap.get(updatedCase.Id).Status);
                if (wasClosed && !isClosed) {
                    casesBeingReopenedSet.add(updatedCase.Id);
                    billingProfilesWithReopenedCasesMap.put(updatedCase.Billing_Profile_ID__c, updatedCase);
                }
            }

            if (!billingProfilesWithReopenedCasesMap.isEmpty()) {
                List<Case> reopenedIncorrectlyList = new List<Case>();

                for (Case c : [
                    SELECT ID, Billing_Profile_ID__c
                    FROM Case
                    WHERE
                        RecordTypeID = :AppConstants.collectionsRTypeId
                        AND IsClosed = FALSE
                        AND Billing_Profile_ID__c IN :billingProfilesWithReopenedCasesMap.keySet()
                        AND ID NOT IN :casesBeingReopenedSet
                ]) {
                    if (billingProfilesWithReopenedCasesMap.containsKey(c.Billing_Profile_ID__c)) {
                        reopenedIncorrectlyList.add(billingProfilesWithReopenedCasesMap.get(c.Billing_Profile_ID__c));
                    }
                }

                for (Case duplicatedCase : reopenedIncorrectlyList) {
                    duplicatedCase.addError('This Billing Account already has an open Collections Case.');
                }
            }
        }

        if (!newPartsToBeSourcedSet.isEmpty()) {
            deleteDuplicateCasesFuture(newPartsToBeSourcedSet);
        }
    }

    /**
     * @description delete duplicate cases
     * @param newPartsToBeSourcedSet - Set of Ordered Part IDs for newly created Sourcing Cases
     */
    @future
    public static void deleteDuplicateCasesFuture(Set<String> newPartsToBeSourcedSet) {
        Map<String, Map<DateTime, Case>> orderedPartIDToSourcingCaseMap = new Map<String, Map<Datetime, Case>>();

        for (Case c : [
            SELECT ID, OrderedPartID__c, CreatedDate
            FROM Case
            WHERE RecordTypeID = :AppConstants.caseSourcingRTypeId AND OrderedPartID__c IN :newPartsToBeSourcedSet
        ]) {
            String orderedPartID = c.OrderedPartID__c;
            if (!orderedPartIDToSourcingCaseMap.containsKey(orderedPartID)) {
                orderedPartIDToSourcingCaseMap.put(orderedPartID, new Map<Datetime, Case>());
            }
            orderedPartIDToSourcingCaseMap.get(orderedPartID).put(c.CreatedDate, c);
        }

        List<Case> casesToDelete = new List<Case>();

        for (String orderedPartID : orderedPartIDToSourcingCaseMap.keySet()) {
            if (orderedPartIDToSourcingCaseMap.get(orderedPartID).size() > 1) {
                List<DateTime> sortList = new List<DateTime>();
                sortList.addAll(orderedPartIDToSourcingCaseMap.get(orderedPartID).keySet());
                sortList.sort();
                DateTime minDateTime = sortList.get(0);
                orderedPartIDToSourcingCaseMap.get(orderedPartID).remove(minDateTime);
                casesToDelete.addAll(orderedPartIDToSourcingCaseMap.get(orderedPartID).values());
            }
        }

        if (!casesToDelete.isEmpty()) {
            DatabaseUtilities.deleteFromDatabase(
                casesToDelete,
                'CaseHandler.deleteDuplicateCases',
                'Deleting duplicate Cases'
            );
        }
    }

    /**
     * @description Listens for status updates and send changes to Parent Orders
     * @param caseList - list of cases being created/updated/deleted
     * @param oldCaseMap - map of old cases
     */
    public static void checkLargeOrderSummary(List<Case> caseList, Map<Id, Case> oldCaseMap) {
        Set<Id> orderIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();

        Set<Id> allowCaseRT = new Set<Id>{ caseManagementRTypeId, caseDFMRTypeId };

        if (!EventBusBypass.isByPassed(largeOrderHelper.caseByPass)) {
            //Checking Cases with new Status or updated Relations
            //and collecting Ids Orders and ParentOrders to reset
            for (Case oneCase : caseList) {
                Boolean cond = Trigger.isInsert || Trigger.isDelete;
                cond |= (Trigger.isUpdate &&
                !AppConstants.CASE_CLOSED_STATUSES.contains(oldCaseMap.get(oneCase.Id).Status) &&
                AppConstants.CASE_CLOSED_STATUSES.contains(oneCase.Status));
                cond |= (Trigger.isUpdate &&
                AppConstants.CASE_CLOSED_STATUSES.contains(oldCaseMap.get(oneCase.Id).Status) &&
                !AppConstants.CASE_CLOSED_STATUSES.contains(oneCase.Status));
                cond |= (Trigger.isUpdate && oldCaseMap.get(oneCase.Id).ParentOpsOrder__c != oneCase.ParentOpsOrder__c);
                cond |= (Trigger.isUpdate && oldCaseMap.get(oneCase.Id).GNOOrder__c != oneCase.GNOOrder__c);

                if (cond && allowCaseRT.contains(oneCase.RecordTypeId)) {
                    if (Trigger.isDelete) {
                        if (oldCaseMap.get(oneCase.Id).GNOOrder__c != null)
                            orderIds.add(oldCaseMap.get(oneCase.Id).GNOOrder__c);
                    }

                    if (oneCase.GNOOrder__c != null) {
                        //reset order
                        orderIds.add(oneCase.GNOOrder__c);
                    }

                    if (oneCase.ParentOpsOrder__c != null) {
                        //reset parent order
                        orderIds.add(oneCase.ParentOpsOrder__c);
                    }

                    if (
                        Trigger.isUpdate &&
                        oldCaseMap.get(oneCase.Id).ParentOpsOrder__c != null &&
                        oldCaseMap.get(oneCase.Id).ParentOpsOrder__c != oneCase.ParentOpsOrder__c
                    ) {
                        //reset old parent order too
                        orderIds.add(oldCaseMap.get(oneCase.Id).ParentOpsOrder__c);
                    }

                    if (
                        Trigger.isUpdate &&
                        oldCaseMap.get(oneCase.Id).GNOOrder__c != null &&
                        oldCaseMap.get(oneCase.Id).GNOOrder__c != oneCase.GNOOrder__c
                    ) {
                        //reset old order too
                        orderIds.add(oldCaseMap.get(oneCase.Id).GNOOrder__c);
                    }
                }
            }
            if (!orderIds.isEmpty()) {
                if (Trigger.isUpdate) {
                    largeOrderHelper.updateLargeOrderSummaryRT(orderIds);
                } else {
                    OpsOrderHandler.updateLargeOrderSummary(orderIds);
                }
            }
        }
    }
    /**
     * @description Restricts Record Type Switching for Cases with an excluded Type
     * @param newCaseList Updated cases from trigger
     * @param oldCaseMap Old cases map from trigger
     */
    public static void restrictRecordTypeSwitching(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        for (Case c : newCaseList) {
            if (
                AppConstants.CASE_TYPE_SWITCHING_EXCLUSIONS.contains(oldCaseMap.get(c.Id).Type) &&
                c.RecordTypeID != oldCaseMap.get(c.Id).RecordTypeID
            ) {
                c.RecordTypeID = oldCaseMap.get(c.Id).RecordTypeID;
            }
        }
    }

    /**
     * @description For NYOPCases will attempt to search for a PSE parent Case if none exists on the Case at trigger Insert
     * @param newCaseList list of Cases to be inserted
     */
    public static void nyopCaseLink(List<Case> newCaseList) {
        Set<String> quoteIDCheckSet = new Set<String>();
        List<Case> nyopCaseList = new List<Case>();

        for (Case c : newCaseList) {
            if (
                (c.RecordTypeID == Appconstants.nyopRTypeID) &&
                (String.isblank(c.ParentID)) &&
                !String.isblank(c.Shadow_Xometry_ERP_ID__C)
            ) {
                quoteIDCheckSet.add(c.Shadow_Xometry_ERP_ID__C);
                nyopCaseList.add(c);
            }
        }
        if (!quoteIDCheckSet.isEmpty()) {
            Map<String, Case> pseCasebyQuoteMap = getPSECasebyXomQuote(quoteIDCheckSet);
            if (!pseCasebyQuoteMap.isEmpty()) {
                nyopAddParentCase(nyopCaseList, pseCasebyQuoteMap);
            }
        }
    }

    /**
     * @description This method will update a list of NYOP cases with a matching PSE case as the Parent and take the parents opp as its own.
     * @param nyopCaseCheckList a List of NYOP Cases to add their parent cases to
     * @param xomQuoteIDCaseMap a Map containing XometryQuote Strings and PSE Cases
     */
    public static void nyopAddParentCase(List<Case> nyopCaseCheckList, Map<String, Case> xomQuoteIDCaseMap) {
        List<Case> casesToUpdateList = new List<Case>();
        for (Case nyopCase : nyopCaseCheckList) {
            if (xomQuoteIDCaseMap.containsKey(nyopCase.Shadow_Xometry_ERP_ID__C)) {
                Case PSECASE = xomQuoteIDCaseMap.get(nyopCase.Shadow_Xometry_ERP_ID__C);
                nyopCase.Opportunity__C = PSECASE.Opportunity__c;
                nyopCase.ParentID = PSECASE.ID;
            }
        }
    }

    /**
     * @description Returns all PSE Cases in the system with matching QuoteIDs
     * @param quoteIDCheckSet a set of Xometry Quote IDS
     */
    public static Map<String, Case> getPSECasebyXomQuote(Set<String> quoteIDCheckSet) {
        Map<String, Case> pseCasebyQuoteMap = new Map<String, Case>();
        //The firstPSE case  per Quote shall get the link aka oldest CreatedDate
        for (Case c : [
            SELECT ID, Shadow_Xometry_ERP_ID__C, Opportunity__c
            FROM Case
            WHERE RecordTypeID = :AppConstants.casePSERecordTypeId AND Shadow_Xometry_ERP_ID__C IN :quoteIDCheckSet
            ORDER BY CreatedDate
        ]) {
            if (!pseCasebyQuoteMap.containsKey(c.Shadow_Xometry_ERP_ID__C)) {
                pseCasebyQuoteMap.put(c.Shadow_Xometry_ERP_ID__C, c);
            }
        }
        return pseCasebyQuoteMap;
    }

    /**
     * @description this method takes new Credit Application Cases and links them to the most recently created Open Purchase Order Case
     * @param newCaseList -
     */
    public static void creditAppToPO(List<Case> newCaseList) {
        Set<ID> contactIDSet = new Set<ID>();
        Set<ID> accountIDSet = new Set<ID>();
        List<Case> caCaseList = new List<Case>();

        for (Case myCase : newCaseList) {
            if (myCase.Category__c == 'Credit Applications' && myCase.parentID == null) {
                caCaseList.add(myCase);
                if (!String.isblank(myCase.ContactID)) {
                    contactIDSet.add(myCase.ContactID);
                }
                if (!String.isblank(myCase.AccountID)) {
                    accountIDSet.add(myCase.AccountID);
                }
            }
        }

        //Atempt to find matching cases
        if (!caCaseList.isEmpty()) {
            Map<ID, Case> existingPOContactCases = new Map<ID, Case>();
            Map<ID, Case> existingPOAccountCases = new Map<ID, Case>();
            for (Case poCase : [
                SELECT ID, ContactID, AccountID, Createddate
                FROM Case
                WHERE
                    Category__c = 'PO'
                    AND isClosed = FALSE
                    AND (contactID IN :contactIDSet
                    OR accountID IN :accountIDSet)
            ]) {
                //Assign to the most recent matching created PO case
                if (poCase.ContactID != null) {
                    if (!existingPOContactCases.containsKey(poCase.ContactID)) {
                        existingPOContactCases.put(poCase.ContactID, poCase);
                    } else if (poCase.CreatedDate > existingPOContactCases.get(poCase.ContactID).CreatedDate) {
                        existingPOContactCases.put(poCase.ContactID, poCase);
                    }
                }
                if (poCase.AccountID != null) {
                    if (!existingPOAccountCases.containsKey(poCase.AccountID)) {
                        existingPOAccountCases.put(poCase.AccountID, poCase);
                    } else if (poCase.CreatedDate > existingPOAccountCases.get(poCase.AccountID).CreatedDate) {
                        existingPOAccountCases.put(poCase.AccountID, poCase);
                    }
                }
            }
            for (Case myCase : caCaseList) {
                if (existingPOContactCases.containsKey(myCase.ContactID)) {
                    myCase.parentID = existingPOContactCases.get(myCase.ContactID).ID;
                } else if (existingPOAccountCases.containsKey(myCase.AccountID)) {
                    myCase.parentID = existingPOAccountCases.get(myCase.AccountID).ID;
                }
            }
        }
    }

    /**
     * @description When a case is inserted or the case Job is updated, the Opp and the account are related
     * @param newCaseList - list of new cases
     * @param oldCaseMap - map of old cases
     */
    public static void populateOppAccount(List<Case> newCaseList, Map<Id, Case> oldCaseMap) {
        Map<Id, Job__c> mapJob = new Map<Id, Job__c>();
        List<Case> sourceCases = new List<Case>();
        Set<String> setOrderId = new Set<String>();
        Map<String,Ops_Order__c> mapOpsOrders = new Map<String,Ops_Order__c>();
        for (Case myCase : newCaseList) {
            if(
                (
                    oldCaseMap == null || 
                    oldCaseMap.get(myCase.Id).Job__c != myCase.Job__c ||
                    oldCaseMap.get(myCase.Id).OrderID__c != myCase.OrderID__c
                ) &&
                myCase.RecordTypeId == caseSourcingRecordTypeId
            )
            {
                if(myCase.Job__c != null)
                {
                    sourceCases.add(myCase);
                    mapJob.put(myCase.Job__c, null);
                }
                else if(myCase.OrderID__c != null)
                {
                    setOrderId.add(myCase.OrderID__c);
                    sourceCases.add(myCase);
                }
                else{
                    myCase.Opportunity__c  = null;
                    myCase.AccountId = null;
                    myCase.ContactId = null;
                }
            }
        }

        if(!setOrderId.isEmpty())
        {
            List<Ops_Order__c> lstOpsOrder =   [SELECT Id, Opportunity__c, Opportunity__r.AccountId, XometryOpsOrderID__c
                                                FROM Ops_Order__c 
                                                WHERE XometryOpsOrderID__c IN :setOrderId AND Opportunity__c != null];
            for(Ops_Order__c objOpsOrder : lstOpsOrder)
            {
                mapOpsOrders.put(objOpsOrder.XometryOpsOrderID__c, objOpsOrder);
            }
        }

        if(!mapJob.isEmpty() || !mapOpsOrders.isEmpty())
        {
            mapJob = new Map<Id, Job__c>((List<Job__c>) [SELECT id, OrderID__c, OrderID__r.Opportunity__c, OrderID__r.Opportunity__r.AccountId 
                                                        FROM Job__c 
                                                        WHERE Id IN: mapJob.keySet() AND OrderID__r.Opportunity__c != null]);
            for (Case myCase : sourceCases) {
                Job__c objJob = mapJob.get(myCase.Job__c);
                if(objJob != null)
                {
                    myCase.Opportunity__c  = objJob.OrderID__r.Opportunity__c;
                    myCase.AccountId = objJob.OrderID__r.Opportunity__r.AccountId;
                }
                else if(mapOpsOrders.containsKey(myCase.OrderID__c))
                {
                    Ops_Order__c objOpsOrder = mapOpsOrders.get(myCase.OrderID__c);
                    myCase.Opportunity__c  = objOpsOrder.Opportunity__c;
                    myCase.AccountId = objOpsOrder.Opportunity__r.AccountId;
                }
            }
        }
    }
}