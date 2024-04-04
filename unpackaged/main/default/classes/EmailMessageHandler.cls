public without sharing class EmailMessageHandler {
    static final ID caseGeneralSupportRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('GeneralSupportCase')
        .getRecordTypeID();
    static final ID caseManagementRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('CaseMgmt')
        .getRecordTypeID();
    static final ID caseDFMRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeID();

    static Map<String, Schema.RecordTypeInfo> recordTypeInfosByDeveloperName;
    public static Map<String, Schema.RecordTypeInfo> GetRecordTypeInfosByDeveloperName {
        get {
            if (recordTypeInfosByDeveloperName == null) {
                recordTypeInfosByDeveloperName = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
            }
            return recordTypeInfosByDeveloperName;
        }
    }

    /**
     * @description Associate Case with Job, Ops Order, and Supplier
     * Route Partner Portal Emails to Case Manager, POD or Queue
     *
     * @param newEmailMessageMap - Map with new values on triggered emails
     */
    public static void associateObjectsToEmailCases(Map<Id, EmailMessage> newEmailMessageMap) {
        Boolean allIncoming = false;
        for (EmailMessage newEmailMessage : newEmailMessageMap.values()) {
            if (newEmailMessage.Incoming) {
                allIncoming = true;
            }
        }
        if (allIncoming) {
            Map<Id, EmailMessage> newEmailMessageWorkingMap = new Map<Id, EmailMessage>();
            newEmailMessageWorkingMap.putAll(newEmailMessageMap);

            Map<Id, Id> casesToAssociate = new Map<Id, Id>();
            Set<String> fromEmailSet = new Set<String>();
            Set<String> emailDomainSet = new Set<String>();
            Map<ID, String> emailMessagetoDomainMap = new Map<ID, String>();

            Set<String> genericDomainSet = LeadHandler.getGenericDomains();
            //get the domain
            for (EmailMessage newEmailMessage : newEmailMessageWorkingMap.values()) {
                if (newEmailMessage.ParentId != null && newEmailMessage.Incoming == true) {
                    casesToAssociate.put(newEmailMessage.ParentId, newEmailMessage.Id);
                    if (
                        !String.isBlank(newEmailMessage.FromAddress) &&
                        !newEmailMessage.FromAddress.contains('xometry.com')
                    ) {
                        fromEmailSet.add(newEmailMessage.FromAddress);
                        if (newEmailMessage.FromAddress.indexOf('@') > 0) {
                            String custDomain = newEmailMessage.FromAddress.substring(
                                newEmailMessage.FromAddress.indexOf('@') + 1
                            );
                            if (genericDomainSet.contains(custDomain)) {
                                //Domain is generic so use the full email
                                custDomain = newEmailMessage.FromAddress;
                            }
                            emailDomainSet.add(custDomain);
                            emailMessagetoDomainMap.put(newEmailMessage.ID, custDomain);
                        }
                    }
                }
            }

            if (!casesToAssociate.isEmpty()) {
                for (Case c : [SELECT ID, ObjectsAssociated__c FROM Case WHERE ID IN :casesToAssociate.keySet()]) {
                    if (c.ObjectsAssociated__c == true) {
                        newEmailMessageWorkingMap.remove(c.Id);
                    }
                }

                Map<Id, Id> routeCases = new Map<Id, Id>();
                Map<Id, String> portalCaseMap = new Map<Id, String>();
                Set<Id> dfmCaseSet = new Set<Id>();
                Set<Id> rejectedPartCaseSet = new Set<Id>();

                for (EmailMessage newEmailMessage : newEmailMessageWorkingMap.values()) {
                    routeCases.put(newEmailMessage.ParentId, newEmailMessage.Id);
                    //For testing purposes:  if (newEmailMessage.ToAddress == 'partner-question@k52qomqv4gbyxnvojefuyz309agdqc24p6evvclojnai3q2tl.8c-4exeuai.cs216.case.sandbox.salesforce.com') {
                    if (newEmailMessage.FromAddress == 'partner-question@xometry.com') {
                        portalCaseMap.put(newEmailMessage.ParentId, newEmailMessage.CcAddress);
                        if (newEmailMessage.Subject.toLowerCase().contains('dfm')) {
                            dfmCaseSet.add(newEmailMessage.ParentId);
                        }
                    }
                }

                if (!routeCases.isEmpty()) {
                    Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
                    Map<Id, String> shadowJobIdCaseMap = new Map<Id, String>();
                    Map<Id, String> shadowOrderIdCaseMap = new Map<Id, String>();
                    Map<Id, String> shadowQuoteIdCaseMap = new Map<Id, String>();
                    Set<Id> shadowIdCaseSet = new Set<Id>();

                    Map<String, Id> jobCaseMap = new Map<String, Id>();
                    Map<String, Id> orderCaseMap = new Map<String, Id>();
                    Map<String, Id> quoteCaseMap = new Map<String, Id>();

                    Pattern jobFinder = Pattern.compile('(J0\\w\\w\\w\\w\\w\\w)');
                    Pattern orderFinder = Pattern.compile('(?:[^\\w]|^)(\\w\\w\\w\\w\\w-\\w\\w\\w\\w\\w)');
                    Pattern quoteFinder = Pattern.compile('(?:[^\\w]|^)(Q\\d\\d-\\d\\d\\d\\d-\\d\\d\\d\\d)');

                    for (Id caseId : routeCases.keySet()) {
                        Id emailId = routeCases.get(caseId);
                        EmailMessage newEmailMessage = newEmailMessageWorkingMap.get(emailId);
                        String bodyText;
                        String matchText = '';

                        if (!String.isEmpty(newEmailMessage.HtmlBody)) {
                            bodyText = newEmailMessage.HtmlBody.stripHtmlTags();
                        } else {
                            bodyText = newEmailMessage.TextBody;
                        }

                        if (bodyText != null && bodyText.contains('#partrejected')) {
                            rejectedPartCaseSet.add(newEmailMessage.ParentId);
                        }

                        if (newEmailMessage.Subject != null || bodytext != null) {
                            if (newEmailMessage.Subject != null && bodytext != null) {
                                matchtext = newEmailMessage.Subject + ' ' + bodyText;
                            } else if (newEmailMessage.Subject != null) {
                                matchtext = newEmailMessage.Subject;
                            } else {
                                matchtext = bodyText;
                            }

                            Matcher jobMatcher = jobFinder.matcher(matchText);
                            Matcher orderMatcher = orderFinder.matcher(matchText);
                            Matcher quoteMatcher = quoteFinder.matcher(matchText);

                            Boolean jobIdFound = jobMatcher.find();
                            Boolean orderIdFound = orderMatcher.find();
                            Boolean quoteIdFound = quoteMatcher.find();
                            String Xometry_JobId = '';
                            String Xometry_OrderId = '';
                            String Xometry_QuoteId = '';

                            if (jobIdFound || orderIdFound || quoteIdFound) {
                                casesToUpdateMap.put(caseId, new Case(Id = caseId));

                                if (jobIdFound) {
                                    Xometry_JobId = jobMatcher.group();
                                    jobCaseMap.put(Xometry_JobId, caseId);
                                    shadowIdCaseSet.add(caseId);
                                    shadowJobIdCaseMap.put(caseId, Xometry_JobId);
                                }
                                if (orderIdFound) {
                                    Xometry_OrderId = orderMatcher.group(1);
                                    if (!jobIdFound) {
                                        orderCaseMap.put(Xometry_OrderId, caseId);
                                        //Add the Order ID to the quoteCaseMap to pick up and pre-fission quotes
                                        //If there is not an Order ERP record with the Order ID, assume it is a quote
                                        //When looping through the orderCaseMap, remove the Order ID from the quoteCaseMap
                                        quoteCaseMap.put(Xometry_OrderId, caseId);
                                        shadowIdCaseSet.add(caseId);
                                    }
                                    shadowOrderIdCaseMap.put(caseId, Xometry_OrderId);
                                }
                                if (quoteIdFound) {
                                    Xometry_QuoteId = quoteMatcher.group(1);
                                    if (!jobIdFound && !orderIdFound) {
                                        quoteCaseMap.put(Xometry_QuoteId, caseId);
                                        shadowIdCaseSet.add(caseId);
                                    }
                                    ShadowQuoteIdCaseMap.put(caseId, Xometry_QuoteId);
                                }
                            }
                        }
                    }

                    if (!shadowIdCaseSet.isEmpty()) {
                        Map<String, Id> queueMap = new Map<String, Id>();
                        for (Group queueGroup : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']) {
                            queueMap.put(queueGroup.DeveloperName, queueGroup.Id);
                        }

                        Map<String, Id> supplierContactMap = new Map<String, Id>();
                        for (Contact supplierContact : [
                            SELECT Id, Primary_Email__c
                            FROM Contact
                            WHERE Primary_Email__c IN :portalCaseMap.values()
                        ]) {
                            supplierContactMap.put(supplierContact.Primary_Email__c, supplierContact.Id);
                        }

                        if (!jobCaseMap.isEmpty()) {
                            for (Job__c job : [
                                SELECT
                                    Id,
                                    Supplier__c,
                                    XometryJobID__c,
                                    MadeInChina__c,
                                    XometryOpsOrderID__c,
                                    OrderID__c,
                                    OrderID__r.CaseManager__c,
                                    OrderID__r.POD__c,
                                    OrderID__r.Xometry_Quote_ID__c,
                                    Supplier__r.AccountID__c,
                                    Supplier__r.ContactID__c
                                FROM Job__c
                                WHERE XometryJobID__c IN :jobCaseMap.keySet()
                            ]) {
                                Id caseId = jobCaseMap.get(job.XometryJobID__c);
                                shadowIdCaseSet.remove(caseId);
                                if (casesToUpdateMap.containsKey(caseID)) {
                                    casesToUpdateMap.get(caseId).ObjectsAssociated__c = true;
                                    casesToUpdateMap.get(caseId).Job__c = job.Id;
                                    casesToUpdateMap.get(caseId).Supplier__c = job.Supplier__c;
                                    casesToUpdateMap.get(caseId).GNOOrder__c = job.OrderID__c;
                                    casesToUpdateMap.get(caseId).ShadowXometryJobID__c = job.XometryJobID__c;
                                    casesToUpdateMap.get(caseId).ShadowXometryOrderID__c = job.XometryOpsOrderID__c;
                                    casesToUpdateMap.get(caseId)
                                        .Shadow_Xometry_ERP_ID__c = job.OrderID__r.Xometry_Quote_ID__c;
                                    if (portalCaseMap.containsKey(caseId) || rejectedPartCaseSet.contains(caseId)) {
                                        casesToUpdateMap.get(caseId).RecordTypeId = caseManagementRTypeId;
                                        casesToUpdateMap.get(caseId).Status = 'New';

                                        if (portalCaseMap.containsKey(caseId)) {
                                            casesToUpdateMap.get(caseId).Origin = 'Partner Portal';
                                            casesToUpdateMap.get(caseId).SuppliedEmail = portalCaseMap.get(caseId);
                                            casesToUpdateMap.get(caseId).ContactId = supplierContactMap.get(
                                                portalCaseMap.get(caseId)
                                            );
                                            casesToUpdateMap.get(caseId).AccountId = job.Supplier__r.AccountID__c;
                                        }
                                        //Ownership Logic
                                        if (dfmCaseSet.contains(caseId)) {
                                            if (
                                                job.OrderID__r.POD__c != null &&
                                                queueMap.containsKey(job.OrderID__r.POD__c.replace(' ', '_'))
                                            ) {
                                                casesToUpdateMap.get(caseId).OwnerId = queueMap.get(
                                                    job.OrderID__r.POD__c.replace(' ', '_')
                                                );
                                            } else {
                                                casesToUpdateMap.get(caseId).OwnerId = queueMap.get(
                                                    'First_Impressions'
                                                );
                                            }
                                        } else if (job.MadeInChina__c == true) {
                                            casesToUpdateMap.get(caseId).OwnerId = queueMap.get('First_Impressions');
                                        } else if (job.OrderID__r.CaseManager__c != null) {
                                            casesToUpdateMap.get(caseId).OwnerId = job.OrderID__r.CaseManager__c;
                                        } else if (
                                            job.OrderID__r.POD__c != null &&
                                            queueMap.containsKey(job.OrderID__r.POD__c.replace(' ', '_'))
                                        ) {
                                            casesToUpdateMap.get(caseId).OwnerId = queueMap.get(
                                                job.OrderID__r.POD__c.replace(' ', '_')
                                            );
                                        } else {
                                            casesToUpdateMap.get(caseId).OwnerId = queueMap.get('First_Impressions');
                                        }
                                    }
                                }
                            }
                        }

                        if (!orderCaseMap.isEmpty()) {
                            for (Ops_Order__c opsOrder : [
                                SELECT XometryOpsOrderID__c, CaseManager__c, POD__c, MadeInChina__c, Xometry_Quote_ID__c
                                FROM Ops_Order__c
                                WHERE XometryOpsOrderID__c IN :orderCaseMap.keySet()
                            ]) {
                                Id caseId = orderCaseMap.get(opsOrder.XometryOpsOrderID__c);
                                shadowIdCaseSet.remove(caseId);
                                if (quoteCaseMap.containsKey(opsOrder.XometryOpsOrderID__c)) {
                                    quoteCaseMap.remove(opsOrder.XometryOpsOrderID__c);
                                }
                                if (orderCaseMap.containsKey(opsOrder.Xometry_Quote_ID__c)) {
                                    orderCaseMap.remove(opsOrder.Xometry_Quote_ID__c);
                                }
                                if (casesToUpdateMap.containsKey(caseId)) {
                                    casesToUpdateMap.get(caseId).ObjectsAssociated__c = true;
                                    casesToUpdateMap.get(caseId).GNOOrder__c = opsOrder.Id;
                                    casesToUpdateMap.get(caseId)
                                        .ShadowXometryOrderID__c = opsOrder.XometryOpsOrderID__c;
                                    casesToUpdateMap.get(caseId)
                                        .Shadow_Xometry_ERP_ID__c = opsOrder.Xometry_Quote_ID__c;
                                    if (portalCaseMap.containsKey(caseId) || rejectedPartCaseSet.contains(caseId)) {
                                        casesToUpdateMap.get(caseId).RecordTypeId = caseManagementRTypeId;
                                        casesToUpdateMap.get(caseId).Status = 'New';

                                        if (portalCaseMap.containsKey(caseId)) {
                                            casesToUpdateMap.get(caseId).Origin = 'Partner Portal';
                                            casesToUpdateMap.get(caseId).SuppliedEmail = portalCaseMap.get(caseId);
                                            casesToUpdateMap.get(caseId).ContactId = supplierContactMap.get(
                                                portalCaseMap.get(caseId)
                                            );
                                        }

                                        if (dfmCaseSet.contains(caseId)) {
                                            if (
                                                opsOrder.POD__c != null &&
                                                queueMap.containsKey(opsOrder.POD__c.replace(' ', '_'))
                                            ) {
                                                casesToUpdateMap.get(caseId).OwnerId = queueMap.get(
                                                    opsOrder.POD__c.replace(' ', '_')
                                                );
                                            } else {
                                                casesToUpdateMap.get(caseId).OwnerId = queueMap.get(
                                                    'First_Impressions'
                                                );
                                            }
                                        } else if (opsOrder.MadeInChina__c == true) {
                                            casesToUpdateMap.get(caseId).OwnerId = queueMap.get('First_Impressions');
                                        } else if (opsOrder.CaseManager__c != null) {
                                            casesToUpdateMap.get(caseId).OwnerId = opsOrder.CaseManager__c;
                                        } else if (
                                            opsOrder.POD__c != null &&
                                            queueMap.containsKey(opsOrder.POD__c.replace(' ', '_'))
                                        ) {
                                            casesToUpdateMap.get(caseId).OwnerId = queueMap.get(
                                                opsOrder.POD__c.replace(' ', '_')
                                            );
                                        } else {
                                            casesToUpdateMap.get(caseId).OwnerId = queueMap.get('First_Impressions');
                                        }
                                    }
                                }
                            }
                        }

                        if (!quoteCaseMap.isEmpty()) {
                            for (Quote_ERP__c quote : [
                                SELECT Xometry_ERP_ID__c, Xometry_Order_ID__c
                                FROM Quote_ERP__c
                                WHERE Xometry_ERP_ID__c IN :quoteCaseMap.keySet()
                            ]) {
                                Id caseId = quoteCaseMap.get(quote.Xometry_ERP_ID__c);
                                shadowIdCaseSet.remove(caseId);
                                if (casesToUpdateMap.containsKey(caseId)) {
                                    casesToUpdateMap.get(caseId).ObjectsAssociated__c = true;
                                    casesToUpdateMap.get(caseId).Shadow_Xometry_ERP_ID__c = quote.Xometry_ERP_ID__c;
                                    casesToUpdateMap.get(caseId).ShadowXometryOrderID__c = quote.Xometry_Order_ID__c;
                                }
                            }
                        }

                        if (!shadowIdCaseSet.isEmpty()) {
                            for (Id caseId : shadowIdCaseSet) {
                                if (casesToUpdateMap.containsKey(caseId)) {
                                    casesToUpdateMap.get(caseId).ObjectsAssociated__c = true;
                                    if (jobCaseMap.containsKey(shadowJobIdCaseMap.get(caseId))) {
                                        casesToUpdateMap.get(caseId).ShadowXometryJobID__c = shadowJobIdCaseMap.get(
                                            caseId
                                        );
                                    }
                                    // Temporary gap: Pre-Fission quotes will get added as a shadow Order ID instead of Quote
                                    if (orderCaseMap.containsKey(shadowOrderIdCaseMap.get(caseId))) {
                                        casesToUpdateMap.get(caseId).ShadowXometryOrderID__c = shadowOrderIdCaseMap.get(
                                            caseId
                                        );
                                    }
                                    if (quoteCaseMap.containsKey(shadowQuoteIdCaseMap.get(caseId))) {
                                        casesToUpdateMap.get(caseId)
                                            .Shadow_Xometry_ERP_ID__c = shadowQuoteIdCaseMap.get(caseId);
                                    }
                                }

                                if (portalCaseMap.containsKey(caseId) || rejectedPartCaseSet.contains(caseId)) {
                                    casesToUpdateMap.get(caseId).RecordTypeId = caseManagementRTypeId;
                                    casesToUpdateMap.get(caseId).Status = 'New';
                                    if (portalCaseMap.containsKey(caseId)) {
                                        casesToUpdateMap.get(caseId).SuppliedEmail = portalCaseMap.get(caseId);
                                        casesToUpdateMap.get(caseId).ContactId = supplierContactMap.get(
                                            portalCaseMap.get(caseId)
                                        );
                                        casesToUpdateMap.get(caseId).Origin = 'Partner Portal';
                                    }
                                    if (dfmCaseSet.contains(caseId)) {
                                        casesToUpdateMap.get(caseId).OwnerId = queueMap.get('First_Impressions');
                                    }
                                }
                            }
                        }
                    }

                    //Fetch the email and or domain of a supplier and update the supplier flag
                    Map<String, ID> supplierFromEmailMap = new Map<String, ID>();
                    Map<String, ID> supplierFromEmailDomainMap = new Map<String, ID>();

                    for (Supplier__c sup : [
                        SELECT Id, EmailAddress__c, AccountDomain__c
                        FROM Supplier__c
                        WHERE
                            (EmailAddress__c IN :fromEmailSet
                            AND SupplierStatus__c = 'approved')
                            OR AccountDomain__c IN :emailDomainSet
                    ]) {
                        if (fromEmailSet.contains(sup.EmailAddress__c)) {
                            supplierFromEmailMap.put(sup.EmailAddress__C, sup.ID);
                        }

                        if (emailDomainSet.contains(sup.AccountDomain__c)) {
                            supplierFromEmailDomainMap.put(sup.AccountDomain__c, sup.ID);
                        }
                    }
                    //TODO use the internal generic list to see if the domain is generic or not
                    for (EmailMessage newEmailMessage : newEmailMessageWorkingMap.values()) {
                        ID supID = null;
                        Boolean hasMatch = false;

                        //Email is more accurate so match first
                        if (supplierFromEmailMap.containsKey(newEmailMessage.FromAddress)) {
                            supID = supplierFromEmailMap.get(newEmailMessage.FromAddress);
                            hasMatch = true;
                        }
                        if (
                            hasMatch == false &&
                            supplierFromEmailDomainMap.containsKey(emailMessagetoDomainMap.get(newEmailMessage.ID))
                        ) {
                            supID = supplierFromEmailDomainMap.get(emailMessagetoDomainMap.get(newEmailMessage.ID));
                            hasMatch = true;
                        }
                        if (hasMatch == true) {
                            Case caseToUpdate = new Case();
                            if (casesToUpdateMap.containsKey(newEmailMessage.ParentId)) {
                                caseToUpdate = casesToUpdateMap.get(newEmailMessage.ParentId);
                            }
                            caseToUpdate.Id = newEmailMessage.ParentId;
                            caseToUpdate.Supplier__C = supID;
                            caseToUpdate.IsPartnerSupplier__c = true;
                            caseToUpdate.ObjectsAssociated__c = true;
                            casesToUpdateMap.put(caseToUpdate.Id, caseToUpdate);
                        }
                    }
                    DatabaseUtilities.saveToDatabase(
                        casesToUpdateMap.values(),
                        'EmailMessageHandler.associateObjectsToEmailCases',
                        'EmailMessage associating Objects to Case'
                    );
                }
            }
        }
    }

    /**
     * @description centering EmailMessage classification to one picklist,
     * this trigger runs before insert and set the initial value.
     *
     * @param newEmailMessageList - List with triggered accounts new values
     */
    public static void updateCases(List<EmailMessage> newEmailMessageList) {
        Map<Id, EmailMessage> caseIdsEmailUpdateSLAEnd = new Map<Id, EmailMessage>();
        Map<Id, EmailMessage> caseIDsCheckforEUDUpdates = new Map<Id, EmailMessage>();
        Set<Id> caseIdsResetSLAEnd = new Set<Id>();
        for (EmailMessage newEmailMessage : newEmailMessageList) {
            Boolean cond1 = newEmailMessage.ParentId != null;
            if (cond1 && newEmailMessage.Incoming == true) {
                caseIdsEmailUpdateSLAEnd.put(newEmailMessage.ParentId, newEmailMessage);
            }
            if (cond1 && newEmailMessage.Incoming == false) {
                caseIdsResetSLAEnd.add(newEmailMessage.ParentId);
                caseIDsCheckforEUDUpdates.put(newEmailMessage.ParentID, newEmailMessage);
            }
        }

        if (
            !caseIdsResetSLAEnd.isEmpty() ||
            !caseIdsEmailUpdateSLAEnd.isEmpty() ||
            !caseIDsCheckforEUDUpdates.isEmpty()
        ) {
            Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
            //geting cases data for both process
            Map<Id, Case> casesMap = new Map<Id, Case>(
                [
                    SELECT
                        Id,
                        Status,
                        Origin,
                        Priority,
                        Email_Pending_SLA__c,
                        Next_SLA_End__c,
                        RecordTypeId,
                        IsPartnerSupplier__c,
                        Category__c,
                        EUD_Work_Stage__c,
                        ShadowXometryOrderID__c,
                        EUD_Email_Count__c
                    FROM Case
                    WHERE
                        (Id IN :caseIdsEmailUpdateSLAEnd.keySet()
                        OR Id IN :caseIdsResetSLAEnd)
                        AND (RecordTypeId = :caseManagementRTypeId
                        OR RecordTypeId = :caseDFMRTypeId
                        OR RecordTypeId = :caseGeneralSupportRTypeId)
                ]
            );

            //checking outbound emails
            if (!caseIdsResetSLAEnd.isEmpty()) {
                //Reseting SLA fields
                for (Case oneCase : casesMap.values()) {
                    if (caseIdsResetSLAEnd.contains(oneCase.Id)) {
                        oneCase.Email_Pending_SLA__c = null;
                        oneCase.Next_SLA_End__c = null;
                        casesToUpdateMap.put(oneCase.Id, oneCase);
                    }
                }
            }

            // For outbound EUD emails update the Case
            if (!caseIDsCheckforEUDUpdates.isEmpty()) {
                for (Case oneCase : casesMap.values()) {
                    if (
                        (oneCase.Category__c == 'End-use definition') &&
                        (oneCase.EUD_WORK_STAGE__C == 'No Reach Out Yet') &&
                        (oneCase.ShadowXometryOrderID__c != null)
                    ) {
                        Case caseToUpdate = new Case();
                        caseToUpdate.ID = oneCase.ID;
                        if (casesToUpdateMap.containsKey(oneCase.ID)) {
                            caseToUpdate = casesToUpdateMap.get(oneCase.ID);
                        }
                        caseToUpdate.EUD_Work_Stage__c = '1st Attempt Sent';
                        caseToUpdate.EUD_Email_Count__c = casesToUpdateMap.get(oneCase.ID).EUD_Email_Count__c + 1;
                        casesToUpdateMap.put(oneCase.Id, oneCase);
                    }
                }
            }
            //checking inbound emails
            if (!caseIdsEmailUpdateSLAEnd.isEmpty()) {
                Map<String, BusinessHours> hoursMap = new Map<String, BusinessHours>();
                for (BusinessHours bHours : [SELECT Id, Name, MondayEndTime FROM BusinessHours]) {
                    hoursMap.put(bHours.Name, bHours);
                }

                for (Case oneCase : casesMap.values()) {
                    //setting pending email for SLA
                    //calculate new date for breached flag
                    Boolean cond1 = caseIdsEmailUpdateSLAEnd.containsKey(oneCase.Id) && oneCase.Next_SLA_End__c == null;
                    //SLA updates on Closed Cases, should be set to the time the Email Response is received.
                    Boolean cond2 =
                        caseIdsEmailUpdateSLAEnd.containsKey(oneCase.Id) &&
                        (oneCase.Status == 'Closed' ||
                        oneCase.Status == 'Solved');
                    if (cond1 || cond2) {
                        //SLA 1: Response to inbound PARTNER related cases within 3 business hrs
                        Integer businessHours = 3;

                        if (!oneCase.IsPartnerSupplier__c) {
                            if (oneCase.Priority == 'Urgent' || oneCase.Priority == 'High') {
                                //SLA 2: Response to inbound CUSTOMER related cases with a priority of High/Urgent within 2 business hrs
                                businessHours = 2;
                            } else {
                                //SLA 3: Response to inbound CUSTOMER related cases with a priority not High/Urgent within 6 business hours.
                                businessHours = 6;
                            }
                        }

                        Id businessHoursId = hoursMap.get('Sourcing Team Business Hours').Id;
                        if (oneCase.RecordTypeId == caseGeneralSupportRTypeId) {
                            businessHoursId = hoursMap.get('CPC Business Hours').Id;
                        }

                        oneCase.Next_SLA_End__c = System.BusinessHours.add(
                            businessHoursId,
                            System.now(),
                            businessHours * 60 * 60 * 1000
                        );

                        oneCase.Email_Pending_SLA__c = caseIdsEmailUpdateSLAEnd.get(oneCase.Id).Id;
                        casesToUpdateMap.put(oneCase.Id, oneCase);
                    }
                }
            }

            DatabaseUtilities.saveToDatabase(
                casesToUpdateMap.values(),
                'EmailMessageHandler.updateCases',
                'EmailMessage updateCases'
            );
        }
    }

    private static Map<Id, EmailMessage> determineEmailsForAutoReply(List<EmailMessage> emailsToCheck) {
        Map<Id, EmailMessage> result = new Map<Id, EmailMessage>();
        for (EmailMessage newEmailMessage : emailsToCheck) {
            if (
                newEmailMessage.ParentId != null &&
                newEmailMessage.Incoming == true &&
                !String.isBlank(newEmailMessage.Subject)
            ) {
                result.put(newEmailMessage.ParentId, newEmailMessage);
            }
        }
        return result;
    }

    private class AutoCloseRules {
        public Map<String, List<Email_Autoreply_Rule__mdt>> Rules;
        public Set<String> RelevantFields;
    }

    private static AutoCloseRules fetchAutoCloseRules() {
        Map<String, List<Email_Autoreply_Rule__mdt>> rulesMap = new Map<String, List<Email_Autoreply_Rule__mdt>>();
        Set<String> queryFieldSet = new Set<String>{ 'Id' };

        for (Email_Autoreply_Rule__mdt rule : [
            SELECT Filter__c, Keywords__c, Addresses__c, Action__c, Field__c, DeveloperName, Priority__c
            FROM Email_Autoreply_Rule__mdt
            ORDER BY Priority__c DESC NULLS LAST, Id ASC
        ]) {
            if (!Test.isRunningTest() && rule.DeveloperName.containsIgnoreCase('test')) {
                continue;
            }

            if (String.isBlank(rule.Filter__c)) {
                if (!rulesMap.containsKey(rule.Filter__c)) {
                    rulesMap.put(rule.Filter__c, new List<Email_Autoreply_Rule__mdt>());
                }
                rulesMap.get(rule.Filter__c).add(rule);
                continue;
            }

            //split between multiple "OR" filters
            for (String filter : rule.Filter__c.split('\\|')) {
                if (!rulesMap.containsKey(filter)) {
                    rulesMap.put(filter, new List<Email_Autoreply_Rule__mdt>());
                }
                rulesMap.get(filter).add(rule);

                for (String filterPart : filter.split('&')) {
                    String fieldName = filterPart.split('=')[0];

                    if (fieldName.containsIgnoreCase('recordtype')) {
                        fieldName = 'RecordTypeId';
                    }

                    queryFieldSet.add(fieldName);
                }
            }
        }

        AutoCloseRules autoCloseRules = new AutoCloseRules();
        autoCloseRules.Rules = rulesMap;
        autoCloseRules.RelevantFields = queryFieldSet;
        return autoCloseRules;
    }

    /**
     * @description looking for special words on incoming emails and update records automatically
     *
     * @param newEmailMessageList - List with triggered accounts new values
     */
    public static void detectAutoReply(List<EmailMessage> newEmailMessageList) {
        //only process emails of interest
        Map<String, Schema.SObjectField> caseSchemaMap = Schema.SObjectType.Case.fields.getMap();

        Map<Id, EmailMessage> emailsToAnalyze = determineEmailsForAutoReply(newEmailMessageList);

        if (emailsToAnalyze.isEmpty()) {
            return;
        }

        AutoCloseRules autoCloseRules = fetchAutoCloseRules();

        Set<Id> caseIds = emailsToAnalyze.keySet();

        Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
        for (
            Case oneCase : Database.query(
                'SELECT ' +
                    String.join(new List<String>(autoCloseRules.RelevantFields), ', ') +
                    ' FROM Case WHERE Id IN :caseIds '
            )
        ) {
            //comparing each rule filter with Case data
            List<Email_Autoreply_Rule__mdt> filteredRules = new List<Email_Autoreply_Rule__mdt>();
            for (String filter : autoCloseRules.Rules.keyset()) {
                Boolean matchingFilter = true; //String.isEmpty(filter);

                if (!String.isEmpty(filter)) {
                    //split 'AND' filter rules, if more than one is defined all should be true.
                    for (String filterPart : filter.split('&')) {
                        String fieldName = filterPart.split('=')[0];
                        String compareValue = filterPart.split('=')[1];

                        //solving RecordTypeId
                        if (fieldName.containsIgnoreCase('recordtype')) {
                            fieldName = 'RecordTypeId';
                            compareValue = GetRecordTypeInfosByDeveloperName.get(compareValue).getRecordTypeID();
                        }

                        if (oneCase.get(fieldName) != compareValue) {
                            matchingFilter = false;
                            break;
                        }
                    }
                }

                if (matchingFilter) {
                    filteredRules.addAll(autoCloseRules.Rules.get(filter));
                }
            }

            if (filteredRules.isEmpty()) {
                continue;
            }

            Email_Autoreply_Rule__mdt applyRule = validateAutoreplyRules(
                emailsToAnalyze.get(oneCase.Id),
                filteredRules
            ); //keywordList.isEmpty() && checkKeywords;

            //matching rule! do action
            if (applyRule == null) {
                continue;
            }

            for (String action : applyRule.Action__c.split(';')) {
                List<String> actionDetails = action.split('\\|-\\|');
                if (actionDetails[0].containsIgnoreCase('update')) {
                    if (!casesToUpdateMap.containsKey(oneCase.Id)) {
                        casesToUpdateMap.put(oneCase.Id, oneCase);
                    }

                    String fieldName = actionDetails[1].split('=')[0];
                    String newValue = actionDetails[1].split('=')[1];

                    Schema.DisplayType fieldType = caseSchemaMap.get(fieldName).getDescribe().getType();

                    if (fieldType == schema.DisplayType.STRING || fieldType == schema.DisplayType.PICKLIST) {
                        casesToUpdateMap.get(oneCase.Id).put(fieldName, newValue);
                        if (fieldName == 'Status' && (newValue == 'Solved' || newValue == 'Closed')) {
                            casesToUpdateMap.get(oneCase.Id).put('IsClosedByAutoClose__c', true);
                        }
                    }
                    if (fieldType == schema.DisplayType.BOOLEAN) {
                        casesToUpdateMap.get(oneCase.Id).put(fieldName, newValue.containsIgnoreCase('true'));
                    }
                    if (fieldType == schema.DisplayType.INTEGER) {
                        casesToUpdateMap.get(oneCase.Id).put(fieldName, Integer.valueOf(newValue));
                    }
                    if (fieldType == schema.DisplayType.DOUBLE) {
                        casesToUpdateMap.get(oneCase.Id).put(fieldName, Double.valueOf(newValue));
                    }
                }
            }
        }

        DatabaseUtilities.saveToDatabase(
            casesToUpdateMap.values(),
            'EmailMessageHandler.detectAutoReply',
            'Close Case on Autoreply'
        );
    }

    /**
     * @description check a list of metadata rules against Case data and return one rule to apply
     *
     * @param case - Case data to compare
     * @param rules - List with filtered rules
     */
    public static Email_Autoreply_Rule__mdt validateAutoreplyRules(
        EmailMessage oneEmailCase,
        List<Email_Autoreply_Rule__mdt> rules
    ) {
        String emailBody = '';
        if (String.isNotBlank(oneEmailCase.HtmlBody)) {
            emailBody = oneEmailCase.HtmlBody.stripHtmlTags();
        } else {
            emailBody = oneEmailCase.TextBody;
        }

        Email_Autoreply_Rule__mdt applyRule = null;
        for (Email_Autoreply_Rule__mdt rule : rules) {
            if (applyRule != null && String.isBlank(rule.Addresses__c) && !rule.Field__c.contains('sender')) {
                continue;
            }

            String emailText = '';

            if (String.isNotBlank(emailBody) && rule.Field__c.contains('body')) {
                emailText = emailBody;
                //looking for keywords on body
                Integer stripLength = rule.Field__c.contains('body(')
                    ? Integer.valueOf(rule.Field__c.substringBetween('body(', ')'))
                    : 0;
                if (stripLength > 0 && emailBody.length() > stripLength) {
                    emailText = emailBody.substring(0, stripLength);
                }
            }

            if (String.isNotBlank(oneEmailCase.Subject) && rule.Field__c.contains('subject')) {
                //looking for keywords on subject
                emailText += ' ' + oneEmailCase.Subject;
            }

            //preprocess rule mapping emails:
            Set<String> emailSet = new Set<String>();
            if (String.isNotBlank(rule.Addresses__c)) {
                for (String keyword : rule.Addresses__c.split(';')) {
                    emailSet.add(keyword);
                }
            }

            List<String> keywordList = new List<String>();
            if (String.isNotBlank(rule.Keywords__c)) {
                for (String keyword : rule.Keywords__c.split(';')) {
                    keywordList.add(keyword);
                }
            }

            Boolean checkKeywords = !rule.Field__c.contains('sender');

            //when sender option is present, matching from address is mandatory
            if (String.isNotBlank(oneEmailCase.FromAddress) && rule.Field__c.contains('sender')) {
                for (String address : emailSet) {
                    Boolean matchingAddress = false;
                    if (address.contains('@')) {
                        matchingAddress = oneEmailCase.FromAddress == address;
                    } else {
                        matchingAddress = oneEmailCase.FromAddress.containsIgnoreCase(address);
                    }

                    if (matchingAddress) {
                        checkKeywords = true;
                        break;
                    }
                }
            }

            Boolean doAction = keywordList.isEmpty() && checkKeywords;

            if (checkKeywords) {
                //testing rule:
                for (String keyword : keywordList) {
                    if (String.isNotBlank(emailText) && emailText.containsIgnoreCase(keyword)) {
                        doAction = true;
                    }
                }
            }

            if (doAction) {
                applyRule = rule;
                //rules with address are priority
                if (rule.Field__c.contains('sender')) {
                    break;
                }
            }
        }

        return applyRule;
    }
}