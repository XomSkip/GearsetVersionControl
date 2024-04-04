/**
 * @description handler for Opportunity insertions and updates
 */
public with sharing class OpportunityHandler {
    static final String ASSOCIATE_PROJECT_METHOD_NAME = 'OpportunityHandler.associateToProject';
    static final String ASSOCIATE_PROJECT_DEV_NOTE = 'Did not save new Project';
    static final String SAVE_ORDER_DEV_NOTE = 'Did not save new Order';
    static final String SAVE_CONTACT_JUNCTION_DEV_NOTE = 'Did not save new Contact Project Junction';
    static final String UPDATE_PROJECT_STATUS_METHOD_NAME = 'OpportunityHandler.updateProjectStatus';
    static final String UPDATE_PROJECT_STATUS_DEV_NOTE = 'Did not update Project status';
    static final String UPDATE_PROJECT_AMOUNT_METHOD_NAME = 'OpportunityHandler.updateProjectAmount';
    static final String UPDATE_PROJECT_AMOUNT_DEV_NOTE = 'Error updating Project Amount';
    public static Boolean isAmountUpdatedFromOpp = false;

    public static set<String> setIdCaseRecalculate;

    /**
     * @description populates the Commission Owner field for opportunities when the it is won, an order id has been
     *              populated, and the Commission Owner field is blank
     * @param inOpportunityList to be newly inserted Opportunties (before trigger)
     */
    public static void populateCommissionOwner(List<Opportunity> inOpportunityList) {
        for (Opportunity opp : inOpportunityList) {
            if (
                opp.StageName == 'Closed Won' &&
                !String.isblank(opp.Order_ERP_Xom_ID__c) &&
                String.isblank(opp.Commission_Owner_LKP__c)
            ) {
                opp.Commission_Owner_LKP__c = opp.OwnerID;
            }
        }
    }

    /**
     * @description populates the Current Stage Start Date field with today's date if it is null
     * @param inOpportunityList to be newly inserted Opportunties (before trigger)
     */
    public static void populateCurrentStageEntryDate(List<Opportunity> inOpportunityList) {
        Date todayDate = date.today();
        for (Opportunity opp : inOpportunityList) {
            if (opp.Current_Stage_Start_Date__c == null) {
                opp.Current_Stage_Start_Date__c = todayDate;
            }
        }
    }

    /**
     *
     * @description populates the Pending Payment Type on The Opportunity with a valid picklist option
     * @param paymentType a string that is matched against a map of valid values
     */

    public static string setPaymentType(String paymentType) {
        Map<String, String> paymentTransformationsMap = new Map<String, String>{
            'buy_now_pay_later' => 'BNPL',
            'no_payment' => 'BNPL',
            'credit_card' => 'Credit Card',
            'purchase_order' => 'Purchase Order'
        };
        String oppPaymentType = null;
        if (paymentTransformationsMap.containsKey(paymentType)) {
            System.debug('Payment map match');
            oppPaymentType = paymentTransformationsMap.get(paymentType);
        }
        return oppPaymentType;
    }

    /**
     * @description populates the Current Stage Start Date field with today's date if it is null
     * @param inOpportunityList newly updated Opportunties
     * @param inOldOpportunityMap old Opportunties which were updated
     */
    public static void populateCurrentStageEntryDate(
        List<Opportunity> inOpportunityList,
        Map<ID, Opportunity> inOldOpportunityMap
    ) {
        Date todayDate = date.today();
        for (Opportunity opp : inOpportunityList) {
            if (inOldOpportunityMap.containsKey(opp.ID)) {
                Opportunity oldOpp = inOldOpportunityMap.get(opp.ID);
                if (opp.StageName != 'Open' && opp.StageName != oldOpp.StageName) {
                    opp.Current_Stage_Start_Date__c = todayDate;
                }
            }
        }
    }

    /**
     * @description Before Updating an Opportunity check if the Opportunity has the Hold_Op_to_Prior_Owner__c set to true and use the OldMap Owner
     * @param inOpportunityList List of Opportunities to be Updated
     * @param inOldOpportunityMap The Old Opportunity Map before the Update was triggered.
     */
    public static void checkKeepOppOwner(
        List<Opportunity> inOpportunityList,
        Map<ID, Opportunity> inOldOpportunityMap
    ) {
        for (Opportunity Opp : inOpportunityList) {
            if (Opp.Hold_Op_to_Prior_Owner__c == true) {
                Opp.OwnerID = inOldOpportunityMap.get(Opp.ID).OwnerID;
            }
        }
    }

    /**
     * @description When updating the status of an Opp, check the stage to determine whether it should be primary or not
     * @param inOpportunityList List of Opportunities updated
     */
    public static void updatePrimaryInformation(List<Opportunity> inOpportunityList) {
        for (Opportunity opp : inOpportunityList) {
            if (opp.RecordTypeId != AppConstants.oppManufacturingServRTypeID) {
                continue;
            }
            if (opp.StageName == 'Closed Won') {
                opp.Primary__c = true;
            } else if (opp.StageName == 'Closed Lost') {
                opp.Primary__c = false;
            }
        }
    }

    /**
     * @description This method takes a Opportunity Ids and associates them to a Project/creates a Project as needed
     * This is intended to be run outside of a trigger execution
     * @param inOppIDSet Set of Opportunities to check for project creation
     *
     */
    public static void associateToProjectAdHoc(Set<ID> inOppIDSet) {
        String ASSOCIATE_TO_PROJECT_ADHOC_METHOD_NAME = 'OpportunityHandler.associateToProjectAdHoc';
        List<Opportunity> oppsNeedProjectList = [
            SELECT
                ID,
                Project__c,
                Primary_Contact__c,
                AccountId,
                RecordTypeId,
                Line_of_Business__c,
                OwnerId,
                Opportunity_Create_Date__c,
                Last_Quote_Xometry_Create_Time__c
            FROM Opportunity
            WHERE ID IN :inOppIDSet AND Project__c = NULL
        ];

        OpportunityHandler.associateToProject(oppsNeedProjectList);

        DatabaseUtilities.upsertToDatabase(
            oppsNeedProjectList,
            ASSOCIATE_TO_PROJECT_ADHOC_METHOD_NAME,
            'updating Opportunities with Projects'
        );
    }
    /**
     * @description Associate to/Create new Project Object
     * @param inOpportunityList List all new Opportunities in insert
     */
    public static void associateToProject(List<Opportunity> inOpportunityList) {
        Set<Id> primaryContactSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();

        for (Opportunity o : inOpportunityList) {
            if (o.Primary_Contact__c != null && o.RecordTypeId == AppConstants.oppManufacturingServRTypeID) {
                primaryContactSet.add(o.Primary_Contact__c);
                accountIdSet.add(o.AccountId);
            }
        }

        if (!primaryContactSet.isEmpty()) {
            Map<Id, Project__c> existingProjectMap = new Map<Id, Project__c>();
            for (Project__c p : [
                SELECT Primary_Contact__c, Project__c, CreatedDate, Line_of_Business__c
                FROM Project__c
                WHERE
                    Primary_Contact__c IN :primaryContactSet
                    AND Locked__c != TRUE
                    AND Stage__c NOT IN ('Closed Won', 'Closed Lost')
            ]) {
                if (existingProjectMap.containsKey(p.Primary_Contact__c)) {
                    if (existingProjectMap.get(p.Primary_Contact__c).CreatedDate < p.CreatedDate) {
                        existingProjectMap.put(p.Primary_Contact__c, p);
                    }
                } else {
                    existingProjectMap.put(p.Primary_Contact__c, p);
                }
            }

            List<Project__c> projectList = new List<Project__c>();
            List<Project__c> newProjectsList = new List<Project__c>();

            Set<Id> hasMktProjectSet = new Set<Id>();
            Set<Id> hasIQProjectSet = new Set<Id>();
            for (Opportunity opp : inOpportunityList) {
                // If no project(s), create new project
                // else if project(s) and all project(s) is closed, create new project
                // else if project(s) open > 1, then add to most recent open project
                if (
                    (!hasMktProjectSet.contains(opp.Primary_Contact__c) && opp.Line_of_Business__c == 'Marketplace') ||
                    (!hasIQProjectSet.contains(opp.Primary_Contact__c) && opp.Line_of_Business__c == 'Instant Quote')
                ) {
                    if (
                        existingProjectMap.containsKey(opp.Primary_Contact__c) &&
                        existingProjectMap.get(opp.Primary_Contact__c).Line_of_Business__c == opp.Line_of_Business__c
                    ) {
                        projectList.add(existingProjectMap.get(opp.Primary_Contact__c));
                        // We will likely want to update some field here in the future
                    } else {
                        Project__c newProject = new Project__c();
                        newProject.Primary_Contact__c = opp.Primary_Contact__c;
                        newProject.Stage__c = 'New';
                        newProject.AccountId__c = opp.AccountId;
                        newProject.Line_of_Business__c = opp.Line_of_Business__c;
                        newProject.OwnerId = opp.OwnerId;
                        newProject.Last_Opp_Created_Date__c = opp.Opportunity_Create_Date__c;
                        newProject.Last_Quote_Mod_Date__c = opp.Last_Quote_Xometry_Create_Time__c;
                        newProjectsList.add(newProject);
                    }
                }
                if (opp.Line_of_Business__c == 'Marketplace') {
                    hasMktProjectSet.add(opp.Primary_Contact__c);
                } else {
                    hasIQProjectSet.add(opp.Primary_Contact__c);
                }
            }

            if (!newProjectsList.isEmpty()) {
                Map<Id, String> contactIdToNameMap = new Map<Id, String>();
                Map<Id, String> accountIdToNameMap = new Map<Id, String>();
                for (Contact c : [SELECT Name FROM Contact WHERE Id IN :primaryContactSet]) {
                    contactIdToNameMap.put(c.Id, c.Name);
                }

                for (Account a : [SELECT Name FROM Account WHERE Id IN :accountIdSet]) {
                    accountIdToNameMap.put(a.Id, a.Name);
                }

                for (Project__c newProject : newProjectsList) {
                    String projectName =
                        accountIdToNameMap.get(newProject.AccountId__c) +
                        ' - ' +
                        contactIdToNameMap.get(newProject.Primary_Contact__c) +
                        ' - ' +
                        DateTime.now().format();

                    if (projectName.length() > 79) {
                        projectName = (contactIdToNameMap.get(newProject.Primary_Contact__c) +
                            ' - ' +
                            DateTime.now().format())
                            .left(79);
                    }
                    newProject.Project__c = projectName;
                    newProject.Name = projectName;
                    projectList.add(newProject);
                }
            }

            // Save new Projects and get project ID to place back onto Opp
            Database.UpsertResult[] srList = DatabaseUtilities.upsertToDatabase(
                projectList,
                ASSOCIATE_PROJECT_METHOD_NAME,
                ASSOCIATE_PROJECT_DEV_NOTE
            );

            Map<Id, Id> contactToMktProjectIdMap = new Map<Id, Id>();
            Map<Id, Id> contactToIQProjectIdMap = new Map<Id, Id>();

            for (Integer i = 0; i < projectList.size(); i++) {
                if (projectList[i].Line_of_Business__c == 'Marketplace') {
                    contactToMktProjectIdMap.put(projectList[i].Primary_Contact__c, srList[i].getId());
                } else {
                    contactToIQProjectIdMap.put(projectList[i].Primary_Contact__c, srList[i].getId());
                }
            }

            for (Opportunity opp : inOpportunityList) {
                if (
                    opp.Line_of_Business__c == 'Marketplace' &&
                    contactToMktProjectIdMap.containsKey(opp.Primary_Contact__c)
                ) {
                    opp.Project__c = contactToMktProjectIdMap.get(opp.Primary_Contact__c);
                } else if (
                    opp.Line_of_Business__c == 'Instant Quote' &&
                    contactToIQProjectIdMap.containsKey(opp.Primary_Contact__c)
                ) {
                    opp.Project__c = contactToIQProjectIdMap.get(opp.Primary_Contact__c);
                }
            }
        }
    }

    /**
     * @description Set CL Projects with an Opp that was switched from CL to CW to System Reopened
     * @param inOpportunityList List of Opportunities to be Updated
     * @param inOldOpportunityMap The Old Opportunity Map before the Update was triggered.
     */
    public static void updateProjectStatus(
        List<Opportunity> inOpportunityList,
        Map<ID, Opportunity> inOldOpportunityMap
    ) {
        Set<Id> projectsToReopenSet = new Set<Id>();
        for (Opportunity opp : inOpportunityList) {
            if (
                opp.RecordTypeId == AppConstants.oppManufacturingServRTypeID &&
                ((opp.StageName == 'Closed Won' && inOldOpportunityMap.get(opp.Id).StageName == 'Closed Lost') ||
                (opp.StageName == 'Closed Lost' &&
                inOldOpportunityMap.get(opp.Id).StageName == 'Closed Won'))
            ) {
                projectsToReopenSet.add(opp.Project__c);
            }
        }

        if (!projectsToReopenSet.isEmpty()) {
            List<Project__c> projectsToReopenList = [
                SELECT ID, Stage__c
                FROM Project__c
                WHERE Id IN :projectsToReopenSet AND (Stage__c = 'Closed Lost' OR Stage__c = 'Closed Won')
            ];

            List<Project__c> needToChangeProjectStatusList = new List<Project__c>();
            for (Project__c proj : projectsToReopenList) {
                Project__c p = new Project__c();
                p.Id = proj.Id;
                p.Stage__c = 'System Reopened';
                needToChangeProjectStatusList.add(p);
            }

            DatabaseUtilities.upsertToDatabase(
                needToChangeProjectStatusList,
                UPDATE_PROJECT_STATUS_METHOD_NAME,
                UPDATE_PROJECT_STATUS_DEV_NOTE
            );
        }
    }

    /**
     * @description Get all projects associated with primary Opps
     * @param inOpportunityList List of Opportunities that has been deleted
     */
    public static void deleteOppChangesProject(List<Opportunity> inOpportunityList) {
        Set<Id> recalculateProjectAmountSet = new Set<Id>();
        Set<Id> updateProjectDateSet = new Set<Id>();

        for (Opportunity o : inOpportunityList) {
            // Primary Status is true
            if (o.Primary__c && o.Project__c != null) {
                recalculateProjectAmountSet.add(o.Project__c);
            }
            updateProjectDateSet.add(o.Project__c);
        }

        if (!recalculateProjectAmountSet.isEmpty()) {
            updateProjectAmount(recalculateProjectAmountSet);
        }
        if (!updateProjectDateSet.isEmpty()) {
            projectDateUpdateFuture.updateProjectDates(updateProjectDateSet);
        }
    }

    /**
     * @description Reset the amount field on a project when opps are moved, amount is changed, or marked primary
     * @param inOpportunityList List of Opportunities to be Updated
     * @param inOldOpportunityMap The Old Opportunity Map before the Update was triggered.
     */
    public static void updatedOppChangesProject(
        List<Opportunity> inOpportunityList,
        Map<ID, Opportunity> inOldOpportunityMap
    ) {
        Set<Id> recalculateProjectAmountSet = new Set<Id>();
        Set<Id> updateProjectDateSet = new Set<Id>();

        for (Opportunity o : inOpportunityList) {
            if (o.RecordTypeId != AppConstants.oppManufacturingServRTypeID) {
                continue;
            }

            // Primary Status has changed
            if (
                o.Primary__c != inOldOpportunityMap.get(o.id).Primary__c &&
                (o.StageName != 'Closed Lost' || (o.StageName != inOldOpportunityMap.get(o.id).StageName))
            ) {
                recalculateProjectAmountSet.add(o.Project__c);
            }

            // Amount Field has changed
            if (o.Primary__c == true && o.Amount != inOldOpportunityMap.get(o.id).Amount) {
                recalculateProjectAmountSet.add(o.Project__c);
            }

            // add to set if project has changed
            if (o.Primary__c == true && o.Project__c != inOldOpportunityMap.get(o.id).Project__c) {
                recalculateProjectAmountSet.add(o.Project__c);
                recalculateProjectAmountSet.add(inOldOpportunityMap.get(o.id).Project__c);
            }

            // process for updating Last Quote Mod Time
            if (o.Project__c != inOldOpportunityMap.get(o.id).Project__c) {
                updateProjectDateSet.add(o.Project__c);
                updateProjectDateSet.add(inOldOpportunityMap.get(o.id).Project__c);
            }
        }

        recalculateProjectAmountSet.remove(null);
        if (!recalculateProjectAmountSet.isEmpty()) {
            updateProjectAmount(recalculateProjectAmountSet);
        }
        if (!updateProjectDateSet.isEmpty()) {
            projectDateUpdateFuture.updateProjectDates(updateProjectDateSet);
        }
    }

    /**
     * @description Reassign the Owner of associated cases if the previous owner was PSE Queue and if the manufacturing process changes
     * @param inOpportunityList List of Updated Opportunities
     * @param inOldOpportunityMap The Old Opportunity Map before the Update was triggered
     */
    public static void reassignCaseOwner(
        List<Opportunity> inOpportunityList,
        Map<ID, Opportunity> inOldOpportunityMap
    ) {
        Set<Id> validOppIdSet = new Set<Id>();

        for (Opportunity opp : inOpportunityList) {
            if (opp.Manufacturing_Process__c != inOldOpportunityMap.get(opp.Id).Manufacturing_Process__c) {
                validOppIdSet.add(opp.Id);
            }
        }

        if (!validOppIdSet.isEmpty()) {
            // if assignment rules are not set, then there is no point to rerouting the case
            List<AssignmentRule> AR = [
                SELECT id
                FROM AssignmentRule
                WHERE SobjectType = 'Case' AND Active = TRUE
                LIMIT 1
            ];
            if (!AR.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = AR[0].id;

                List<Case> associatedCases = new List<Case>();

                Group pseQueue = [
                    SELECT Id, Name
                    FROM Group
                    WHERE Type = 'Queue' AND Name = 'Pre-Sales Engineering Queue'
                    LIMIT 1
                ];

                for (Case c : [
                    SELECT Id, OwnerId, RecordType.Name, Opportunity__c
                    FROM Case
                    WHERE
                        OwnerId = :pseQueue.Id
                        AND RecordTypeID = :AppConstants.casePSERecordTypeId
                        AND Opportunity__c IN :validOppIdSet
                ]) {
                    c.setOptions(dmlOpts);
                    associatedCases.add(c);
                }

                DatabaseUtilities.saveToDatabase(
                    associatedCases,
                    'OpportunityHandler.reassignCaseOwner',
                    'Failed updating case owner'
                );
            }
        }
    }

    /**
     * @description Update attached Project for inserted primary opp
     * @param inOpportunityList List of Opportunities that has been inserted
     */
    public static void insertedOppChangesProject(List<Opportunity> inOpportunityList) {
        Set<Id> recalculateProjectAmountSet = new Set<Id>();
        Set<Id> updateProjectDateSet = new Set<Id>();

        for (Opportunity o : inOpportunityList) {
            // Primary Status is true
            if (o.Primary__c && o.Project__c != null) {
                recalculateProjectAmountSet.add(o.Project__c);
            }
            updateProjectDateSet.add(o.Project__c);
        }

        if (!recalculateProjectAmountSet.isEmpty()) {
            updateProjectAmount(recalculateProjectAmountSet);
        }
        if (!updateProjectDateSet.isEmpty()) {
            projectDateUpdateFuture.updateProjectDates(updateProjectDateSet);
        }
    }

    /**
     * @description Reset the amount field on a project when opps are moved or marked primary
     * @param recalculateProjectAmountSet set of project ids to be updated
     */
    public static void updateProjectAmount(Set<Id> recalculateProjectAmountSet) {
        if (!recalculateProjectAmountSet.isEmpty()) {
            List<Project__c> updatedProjects = new List<Project__c>();

            AggregateResult[] projectOppAggregate = [
                SELECT Project__c, SUM(Amount) amountSum
                FROM Opportunity
                WHERE Primary__c = TRUE AND Project__c IN :recalculateProjectAmountSet
                GROUP BY Project__c
            ];

            for (AggregateResult ar : projectOppAggregate) {
                Project__c p = new Project__c(Id = (Id) ar.get('Project__c'));
                p.Amount__c = (Decimal) ar.get('amountSum');
                updatedProjects.add(p);
                recalculateProjectAmountSet.remove((Id) ar.get('Project__c'));
            }

            // These are all remaining projects which have no Opps to aggregate
            for (Id i : recalculateProjectAmountSet) {
                Project__c p = new Project__c(Id = i);
                p.Amount__c = 0.00;
                updatedProjects.add(p);
            }

            if(!updatedProjects.isEmpty())
            {
                isAmountUpdatedFromOpp = true;
                DatabaseUtilities.upsertToDatabase(
                    updatedProjects,
                    UPDATE_PROJECT_AMOUNT_METHOD_NAME,
                    UPDATE_PROJECT_AMOUNT_DEV_NOTE
                );
            }
        }
    }

    /**
     * @description sets the Supplies Rep on a Contact who last owned an Opportunity.
     * @param newOppList List of Opportunities to be Inserted/Updated
     * @param oldOppMap The Old Opportunity Map before the Update was triggered.
     */
    public static void updateSuppliesContact(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        Set<String> validProfileNames = new Set<String>();
        validProfileNames.add('Xometry Seller Marketplace');

        List<Opportunity> suppliesOppList = new List<Opportunity>();
        for (Opportunity opp : newOppList) {
            if (opp.RecordtypeID == AppConstants.oppSellerMarketplaceRecordTypeId) {
                suppliesOppList.add(opp);
            }
        }
        if (!suppliesOppList.isEmpty()) {
            System.debug('We have Some Sup Opps to Check for Contact Logic size: ' + suppliesOppList.size());
            Set<ID> oppOwners = new Set<ID>();
            Set<ID> SupplierIDSet = new Set<ID>();
            Map<ID, Supplier__C> existingSupplierMap = new Map<ID, Supplier__C>();
            Map<ID, Supplier__C> supplierNeedsUpdateMap = new Map<ID, Supplier__C>();
            for (Opportunity opp : suppliesOppList) {
                oppOwners.add(opp.OwnerID);
                if (!string.isBlank(opp.Primary_Supplier__C)) {
                    SupplierIDSet.add(opp.Primary_Supplier__C);
                }
            }
            if (!SupplierIDSet.isEmpty()) {
                existingSupplierMap = SupplierUtility.fetchSuppliersbySFID(SupplierIDSet);
            }

            List<Contact> contactsToUpdateList = new List<Contact>();
            Map<Id, Contact> contactsToUpdateMap = new Map<Id, Contact>();
            List<User> oppUserList = [
                SELECT Id, profile.name, profileid
                FROM User
                WHERE Id IN :oppOwners AND isActive = TRUE
            ];
            Set<Id> validSupUsers = new Set<Id>();
            for (User usr : oppUserList) {
                if (validProfileNames.contains(usr.profile.name)) {
                    validSupUsers.add(usr.Id);
                }
            }
            DateTime currentTime = DateTime.now();
            if (!validSupUsers.isEmpty()) {
                if (Trigger.isInsert) {
                    System.debug('We are setting the Sup Contact Owner Tracker from Insert');
                    for (Opportunity opp : suppliesOppList) {
                        if (
                            validSupUsers.contains(opp.OwnerID) &&
                            opp.OwnerID != AppConstants.SUPPLIES_HOUSE_USER &&
                            !String.isBlank(opp.Primary_contact__c)
                        ) {
                            Contact con = new Contact();
                            con.Id = opp.Primary_Contact__c;
                            con.Supplies_Last_Opp_Owner__c = opp.OwnerID;
                            con.Supplies_Last_Owner_DateTime__c = currentTime;
                            contactsToUpdateMap.put(con.Id, con);
                            if (existingSupplierMap.containsKey(opp.Primary_Supplier__C)) {
                                Supplier__C sup = existingSupplierMap.get(opp.Primary_Supplier__C);
                                sup.Sup_Owner_Stamp__c = opp.OwnerID;
                                sup.Sup_Owner_RouteTime__c = currentTime;
                                supplierNeedsUpdateMap.put(sup.ID, sup);
                            }
                        }
                    }
                } else if (Trigger.isUpdate) {
                    System.debug('We are setting the Sup Contact Owner Tracker from Update');
                    for (Opportunity opp : suppliesOppList) {
                        if (
                            validSupUsers.contains(opp.OwnerID) &&
                            opp.OwnerID != AppConstants.SUPPLIES_HOUSE_USER &&
                            (opp.OwnerID != oldOppMap.get(opp.Id).OwnerID ||
                            String.isBlank(oldOppMap.get(opp.Id).Primary_contact__c)) &&
                            !String.isBlank(opp.Primary_contact__c)
                        ) {
                            Contact con = new Contact();
                            con.Id = opp.Primary_Contact__c;
                            con.Supplies_Last_Opp_Owner__c = opp.OwnerID;
                            con.Supplies_Last_Owner_DateTime__c = currentTime;
                            contactsToUpdateMap.put(con.Id, con);
                            if (existingSupplierMap.containsKey(opp.Primary_Supplier__C)) {
                                Supplier__C sup = existingSupplierMap.get(opp.Primary_Supplier__C);
                                sup.Sup_Owner_Stamp__c = opp.OwnerID;
                                sup.Sup_Owner_RouteTime__c = currentTime;
                                supplierNeedsUpdateMap.put(sup.ID, sup);
                            }
                        }
                    }
                }

                contactsToUpdateList.addAll(contactsToUpdateMap.values());
                DatabaseUtilities.saveToDatabase(
                    contactsToUpdateList,
                    'OpportunityHandler.updateSuppliesContact',
                    'Updating the Supplies Last Opp Owner'
                );
                DatabaseUtilities.saveToDatabase(
                    supplierNeedsUpdateMap.values(),
                    'OpportunityHandler.updateSuppliesContact',
                    'Update supplier Opp Owner Stamp'
                );
            }
        }
    }

    /*
     * @description When the opportunities' Amount or LineItemCount__c changes, the summary fields in the related Cases must be recalculated
     * @param inOpportunityList - list of new values of the Opportunities
     * @param inOldOpportunityMap - map of old values of the Opportunities
     */
    public static void keepTotalFieldsCaseUpdated(
        List<Opportunity> inOpportunityList,
        Map<ID, Opportunity> inOldOpportunityMap
    ) {
        Set<String> setOppChanged = new Set<String>();
        Map<Id, Case> mapCases = new Map<Id, Case>();
        Case objCase;
        if (!System.isBatch()) {
            for (Opportunity Opp : inOpportunityList) {
                if (opp.RecordTypeId != AppConstants.oppSellerMarketplaceRecordTypeId) {
                    if (
                        Opp.Amount != inOldOpportunityMap.get(Opp.Id).Amount ||
                        Opp.LineItemCount__c != inOldOpportunityMap.get(Opp.Id).LineItemCount__c ||
                        Opp.StageName != inOldOpportunityMap.get(Opp.Id).StageName ||
                        Opp.Total_Amt_Additive__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_Additive__c ||
                        Opp.Total_Amt_BinderJetting__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_BinderJetting__c ||
                        Opp.Total_Amt_Carbon__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_Carbon__c ||
                        Opp.Total_Amt_CNC__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_CNC__c ||
                        Opp.Total_Amt_CNC_Sheet__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_CNC_Sheet__c ||
                        Opp.Total_Amt_DieCasting__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_DieCasting__c ||
                        Opp.Total_Amt_DirectSourced__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_DirectSourced__c ||
                        Opp.Total_Amt_DMLS__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_DMLS__c ||
                        Opp.Total_Amt_Extrusion__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_Extrusion__c ||
                        Opp.Total_Amt_FDM__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_FDM__c ||
                        Opp.Total_Amt_HPMultJetFusion__c !=
                        inOldOpportunityMap.get(Opp.Id).Total_Amt_HPMultJetFusion__c ||
                        Opp.Total_Amt_InjectionMolding__c !=
                        inOldOpportunityMap.get(Opp.Id).Total_Amt_InjectionMolding__c ||
                        Opp.Total_Amt_InjectionMoldingTool__c !=
                        inOldOpportunityMap.get(Opp.Id).Total_Amt_InjectionMoldingTool__c ||
                        Opp.Total_Amt_Molding__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_Molding__c ||
                        Opp.Total_Amt_PolyJet3D__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_PolyJet3D__c ||
                        Opp.Total_Amt_SheetCutting__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_SheetCutting__c ||
                        Opp.Total_Amt_SheetMetal__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_SheetMetal__c ||
                        Opp.Total_Amt_SLA__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_SLA__c ||
                        Opp.Total_Amt_SLS__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_SLS__c ||
                        Opp.Total_Amt_Sourced__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_Sourced__c ||
                        Opp.Total_Amt_Stamping__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_Stamping__c ||
                        Opp.Total_Amt_UrethaneCasting__c != inOldOpportunityMap.get(Opp.Id).Total_Amt_UrethaneCasting__c
                    ) {
                        setOppChanged.add(Opp.Id);
                    }
                }
            }
            if (!setOppChanged.isEmpty()) {
                sumOppsValuesInCasesRecords(null, setOppChanged, null);
            }
        }
    }

    /*
     * @description When an opportunity is deleted, this method collects the id of the cases that are related to those opportunities
     *              through the records in the CaseOpportunity object, and stores them in the static variable setIdCaseRecalculate of the class
     * @param mapOldOpportunities - map of old values of the Opportunities
     */
    public static void getCasesRelatedIds(Map<Id, Opportunity> mapOldOpportunities) {
        List<CaseOpportunity__c> lstCaseOpp = [
            SELECT Case__c
            FROM CaseOpportunity__c
            WHERE Opportunity__c IN :mapOldOpportunities.KeySet() AND Case__c != NULL
        ];
        setIdCaseRecalculate = new Set<String>();
        for (CaseOpportunity__c objCaseOpp : lstCaseOpp) {
            setIdCaseRecalculate.add(objCaseOpp.Case__c);
        }
    }

    /*
     * @description When an opportunity is eliminated, the summary fields of the cases whose ids are stored in the static variable setIdCaseRecalculate of the class are recalculated
     */
    public static void keepTotalFieldsCaseDeletedOpps() {
        Map<Id, Case> mapCases = new Map<Id, Case>();
        Case objCase;
        if (!System.isBatch()) {
            if (!setIdCaseRecalculate.isEmpty()) {
                sumOppsValuesInCasesRecords(setIdCaseRecalculate, null, null);
            }
        }
    }

    /*
     * @description When an opportunity is eliminated, the summary fields of the cases whose ids are stored in the static variable setIdCaseRecalculate of the class are recalculated
     * @param setCasesId    - Ids of the cases that should recalculate the values of the opportunities
     * @param setOppsId     - Id of the opportunities that have been modified to recalculate the summary fields of the cases that have those related opportunities
     * @param setCaseOppsId - Id of the CaseOpportunity records that have been created or deleted to recalculate the summary fields in the related cases
     */
    @future
    public static void sumOppsValuesInCasesRecords(
        Set<String> setCasesId,
        Set<String> setOppsId,
        Set<Id> setCaseOppsId
    ) {
        if (
            (setCasesId == null || setCasesId.isEmpty()) &&
            (setOppsId == null || setOppsId.isEmpty()) &&
            (setCaseOppsId == null || setCaseOppsId.isEmpty())
        ) {
            throw new IllegalArgumentException();
        }

        if ((setCaseOppsId != null && !setCaseOppsId.isEmpty()) || (setOppsId != null && !setOppsId.isEmpty())) {
            List<CaseOpportunity__c> newCaseOppList = (setCaseOppsId != null && !setCaseOppsId.isEmpty())
                ? [SELECT Case__c, Opportunity__c FROM CaseOpportunity__c WHERE Id IN :setCaseOppsId ALL ROWS]
                : [SELECT Case__c, Opportunity__c FROM CaseOpportunity__c WHERE Opportunity__c IN :setOppsId];

            setCasesId = new Set<String>();

            for (CaseOpportunity__c caseOpp : newCaseOppList) {
                if (String.isNotBlank(caseOpp.Opportunity__c) && String.isNotBlank(caseOpp.Case__c)) {
                    setCasesId.add(caseOpp.Case__c);
                }
            }
        }

        List<CaseOpportunity__c> lstAllCaseOpp = [
            SELECT
                Id,
                Case__c,
                Case__r.PO_Amount__c,
                Case__r.Total_Quantity_Opps__c,
                Case__r.Total_Amount_Opps__c,
                Case__r.Total_LineItem_Opps__c,
                Case__r.TotalAmountClosedWonOpps__c,
                Case__r.TotalAmountClosedLostOpps__c,
                Opportunity__c,
                Opportunity__r.Amount,
                Opportunity__r.StageName,
                Opportunity__r.LineItemCount__c,
                Opportunity__r.Total_Amt_BinderJetting__c,
                Opportunity__r.Total_Amt_Carbon__c,
                Opportunity__r.Total_Amt_CNC__c,
                Opportunity__r.Total_Amt_DieCasting__c,
                Opportunity__r.Total_Amt_DirectSourced__c,
                Opportunity__r.Total_Amt_DMLS__c,
                Opportunity__r.Total_Amt_Extrusion__c,
                Opportunity__r.Total_Amt_FDM__c,
                Opportunity__r.Total_Amt_HPMultJetFusion__c,
                Opportunity__r.Total_Amt_InjectionMolding__c,
                Opportunity__r.Total_Amt_InjectionMoldingTool__c,
                Opportunity__r.Total_Amt_PolyJet3D__c,
                Opportunity__r.Total_Amt_SheetCutting__c,
                Opportunity__r.Total_Amt_SheetMetal__c,
                Opportunity__r.Total_Amt_SLA__c,
                Opportunity__r.Total_Amt_SLS__c,
                Opportunity__r.Total_Amt_Stamping__c,
                Opportunity__r.Total_Amt_UrethaneCasting__c
            FROM CaseOpportunity__c
            WHERE Case__c IN :setCasesId AND Opportunity__c != NULL
        ];

        Map<Id, Case> mapCases = new Map<Id, Case>();
        Case objCase;

        for (CaseOpportunity__c objCaseOpp : lstAllCaseOpp) {
            objCase = mapCases.get(objCaseOpp.Case__c);
            if (objCase == null) {
                objCase = new Case(
                    Id = objCaseOpp.Case__c,
                    Total_Amount_Opps__c = 0,
                    Total_Quantity_Opps__c = 0,
                    Total_LineItem_Opps__c = 0,
                    TotalAmountClosedWonOpps__c = 0,
                    TotalAmountClosedLostOpps__c = 0,
                    Total_Amt_BinderJetting_opps__c = 0,
                    Total_Amt_Carbon_opps__c = 0,
                    Total_Amt_CNC_opps__c = 0,
                    Total_Amt_DieCasting_opps__c = 0,
                    Total_Amt_DirectSourced_opps__c = 0,
                    Total_Amt_DMLS_opps__c = 0,
                    Total_Amt_Extrusion_opps__c = 0,
                    Total_Amt_FDM_opps__c = 0,
                    Total_Amt_HPMultJetFusion_opps__c = 0,
                    Total_Amt_InjectionMolding_opps__c = 0,
                    Total_Amt_InjectionMoldingTool_opps__c = 0,
                    Total_Amt_PolyJet3D_opps__c = 0,
                    Total_Amt_SheetCutting_opps__c = 0,
                    Total_Amt_SheetMetal_opps__c = 0,
                    Total_Amt_SLA_opps__c = 0,
                    Total_Amt_SLS_opps__c = 0,
                    Total_Amt_Stamping_opps__c = 0,
                    Total_Amt_UrethaneCasting_opps__c = 0,
                    PO_Amount__c = objCaseOpp.Case__r.PO_Amount__c
                );
                mapCases.put(objCaseOpp.Case__c, objCase);
            }

            objCase.Total_Quantity_Opps__c++;
            objCase.Total_Amount_Opps__c += objCaseOpp.Opportunity__r.Amount != null
                ? objCaseOpp.Opportunity__r.Amount
                : 0;
            objCase.Total_LineItem_Opps__c += objCaseOpp.Opportunity__r.LineItemCount__c != null
                ? objCaseOpp.Opportunity__r.LineItemCount__c
                : 0;
            objCase.TotalAmountClosedWonOpps__c += objCaseOpp.Opportunity__r.StageName == 'Closed Won' &&
                objCaseOpp.Opportunity__r.Amount != null
                ? objCaseOpp.Opportunity__r.Amount
                : 0;
            objCase.TotalAmountClosedLostOpps__c += objCaseOpp.Opportunity__r.StageName == 'Closed Lost' &&
                objCaseOpp.Opportunity__r.Amount != null
                ? objCaseOpp.Opportunity__r.Amount
                : 0;

            objCase.Total_Amt_BinderJetting_opps__c += objCaseOpp.Opportunity__r.Total_Amt_BinderJetting__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_BinderJetting__c
                : 0;
            objCase.Total_Amt_Carbon_opps__c += objCaseOpp.Opportunity__r.Total_Amt_Carbon__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_Carbon__c
                : 0;
            objCase.Total_Amt_CNC_opps__c += objCaseOpp.Opportunity__r.Total_Amt_CNC__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_CNC__c
                : 0;
            objCase.Total_Amt_DieCasting_opps__c += objCaseOpp.Opportunity__r.Total_Amt_DieCasting__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_DieCasting__c
                : 0;
            objCase.Total_Amt_DirectSourced_opps__c += objCaseOpp.Opportunity__r.Total_Amt_DirectSourced__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_DirectSourced__c
                : 0;
            objCase.Total_Amt_DMLS_opps__c += objCaseOpp.Opportunity__r.Total_Amt_DMLS__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_DMLS__c
                : 0;
            objCase.Total_Amt_Extrusion_opps__c += objCaseOpp.Opportunity__r.Total_Amt_Extrusion__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_Extrusion__c
                : 0;
            objCase.Total_Amt_FDM_opps__c += objCaseOpp.Opportunity__r.Total_Amt_FDM__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_FDM__c
                : 0;
            objCase.Total_Amt_HPMultJetFusion_opps__c += objCaseOpp.Opportunity__r.Total_Amt_HPMultJetFusion__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_HPMultJetFusion__c
                : 0;
            objCase.Total_Amt_InjectionMolding_opps__c += objCaseOpp.Opportunity__r.Total_Amt_InjectionMolding__c !=
                null
                ? objCaseOpp.Opportunity__r.Total_Amt_InjectionMolding__c
                : 0;
            objCase.Total_Amt_InjectionMoldingTool_opps__c += objCaseOpp.Opportunity__r.Total_Amt_InjectionMoldingTool__c !=
                null
                ? objCaseOpp.Opportunity__r.Total_Amt_InjectionMoldingTool__c
                : 0;
            objCase.Total_Amt_PolyJet3D_opps__c += objCaseOpp.Opportunity__r.Total_Amt_PolyJet3D__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_PolyJet3D__c
                : 0;
            objCase.Total_Amt_SheetCutting_opps__c += objCaseOpp.Opportunity__r.Total_Amt_SheetCutting__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_SheetCutting__c
                : 0;
            objCase.Total_Amt_SheetMetal_opps__c += objCaseOpp.Opportunity__r.Total_Amt_SheetMetal__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_SheetMetal__c
                : 0;
            objCase.Total_Amt_SLA_opps__c += objCaseOpp.Opportunity__r.Total_Amt_SLA__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_SLA__c
                : 0;
            objCase.Total_Amt_SLS_opps__c += objCaseOpp.Opportunity__r.Total_Amt_SLS__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_SLS__c
                : 0;
            objCase.Total_Amt_Stamping_opps__c += objCaseOpp.Opportunity__r.Total_Amt_Stamping__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_Stamping__c
                : 0;
            objCase.Total_Amt_UrethaneCasting_opps__c += objCaseOpp.Opportunity__r.Total_Amt_UrethaneCasting__c != null
                ? objCaseOpp.Opportunity__r.Total_Amt_UrethaneCasting__c
                : 0;
            objCase.PO_Amount__c = objCase.PO_Amount__c != null ? objCase.PO_Amount__c : 0;
        }

        if (!mapCases.isEmpty()) {
            DatabaseUtilities.upsertToDatabase(
                mapCases.values(),
                'OpportunityHandler.sumOppsValuesInCasesRecords',
                'Recalculate the Case fields with the values of the related opportunities'
            );
        }
    }

    /**
     * @description On OwnerId change, add new owner to Team Members and delete the old Owner from Team Members
     * @param newOppList - list of new Opps
     * @param oldOppMap - map of old Opps
     */
    public static void createTeamMember(Map<Id, Opportunity> newOppMap, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppSet = new Set<Id>();
        for (Opportunity opp : newOppMap.values()) {
            Boolean cond = Trigger.isUpdate && oldOppMap.get(opp.Id).OwnerId != opp.OwnerId;
            if (cond) {
                oppSet.add(opp.Id);
            }
        }

        if (!oppSet.isEmpty()) {
            Map<String, Id> rolesMap = new Map<String, Id>();
            for (CaseTeamRole tRole : [SELECT Id, Name FROM CaseTeamRole]) {
                rolesMap.put(tRole.Name, tRole.Id);
            }

            Map<Id, Case> caseMap = new Map<Id, Case>(
                [
                    SELECT Id, Opportunity__c
                    FROM Case
                    WHERE Opportunity__c IN :oppSet AND RecordtypeId = :AppConstants.casePSERecordTypeId
                ]
            );

            Map<Id, Set<Id>> membersMap = new Map<Id, Set<Id>>();
            List<CaseTeamMember> addTeamMembers = new List<CaseTeamMember>();
            List<CaseTeamMember> removeTeamMembers = new List<CaseTeamMember>();

            //mapping already members to avoid duplicates
            //removing old owners
            for (CaseTeamMember tMember : [
                SELECT MemberId, ParentId
                FROM CaseTeamMember
                WHERE ParentId IN :caseMap.keySet()
            ]) {
                if (!membersMap.containsKey(tMember.ParentId)) {
                    membersMap.put(tMember.ParentId, new Set<Id>());
                }
                membersMap.get(tMember.ParentId).add(tMember.MemberId);

                Id oppId = caseMap.get(tMember.ParentId).Opportunity__c;

                if (tMember.MemberId == oldOppMap.get(oppId).OwnerId) {
                    removeTeamMembers.add(tMember);
                }
            }

            for (Case c : caseMap.values()) {
                if (
                    !(membersMap.containsKey(c.Id) &&
                    membersMap.get(c.Id).contains(newOppMap.get(c.Opportunity__c).OwnerId))
                ) {
                    CaseTeamMember newTeamMember = new CaseTeamMember();
                    newTeamMember.ParentId = c.Id;
                    newTeamMember.MemberId = newOppMap.get(c.Opportunity__c).OwnerId;
                    newTeamMember.TeamRoleId = rolesMap.get('PSE2.0-Opportunity Owner');
                    addTeamMembers.add(newTeamMember);
                }
            }

            DatabaseUtilities.deleteFromDatabase(
                removeTeamMembers,
                'OpportunityHandler.createTeamMember',
                'Delete CaseTeamMember for old OwnerId'
            );

            DatabaseUtilities.insertToDatabase(
                addTeamMembers,
                'OpportunityHandler.createTeamMember',
                'Create CaseTeamMember for new OwnerId'
            );
        }
    }

    /*
     * @When an Opportunity is update check to see if the Shadow_JobId__c changed or needs a JobID lookup if it is blank
     * @param newOppList List of Opportunities to be Inserted/Updated
     * @param oldOppMap The Old Opportunity Map before the Update was triggered.
     */
    public static void linkOpptoJob(List<Opportunity> inOpportunityList, Map<Id, Opportunity> inOldOpportunityMap) {
        Map<String, List<Opportunity>> OppsNeedJobIDLookupMap = new Map<String, List<Opportunity>>();
        //More then one Opp can have a Job ID so you a List of Opps to Update
        for (Opportunity Opp : inOpportunityList) {
            boolean condition0 = Opp.recordTypeID == AppConstants.oppSellerMarketplaceRecordTypeId;
            boolean condition1 =
                Trigger.isInsert &&
                !String.isblank(Opp.Shadow_JobId__c) &&
                String.isblank(Opp.JobId__C);
            boolean condition2 =
                Trigger.isUpdate &&
                !String.isblank(Opp.Shadow_JobId__c) &&
                (String.isblank(Opp.JobId__C) ||
                (Opp.Shadow_JobId__c != inOldOpportunityMap.get(Opp.Id).Shadow_JobId__c));
            //Condition Theres was a Shadow_JobId__C and the ETL is removing it
            boolean condition3 =
                Trigger.isUpdate &&
                String.isblank(Opp.Shadow_JobId__C) &&
                !String.isblank(inOldOpportunityMap.get(Opp.Id).Shadow_JobId__c);
            if (condition0 && (condition1 || condition2)) {
                if (OppsNeedJobIDLookupMap.containsKey(Opp.Shadow_JobId__c)) {
                    List<Opportunity> oppNeedJobIDList = OppsNeedJobIDLookupMap.get(Opp.Shadow_JobId__c);
                    oppNeedJobIDList.add(Opp);
                    OppsNeedJobIDLookupMap.put(Opp.Shadow_JobId__c, oppNeedJobIDList);
                } else {
                    List<Opportunity> oppNeedJobIDList = new List<Opportunity>();
                    oppNeedJobIDList.add(Opp);
                    OppsNeedJobIDLookupMap.put(Opp.Shadow_JobId__c, oppNeedJobIDList);
                }
            }
            if (condition3) {
                Opp.JobId__C = null;
            }
        }
        if (OppsNeedJobIDLookupMap.size() > 0) {
            List<Job__c> existingJobList = [
                SELECT ID, XometryJobID__c
                FROM Job__C
                WHERE XometryJobID__c IN :OppsNeedJobIDLookupMap.keySet()
            ];
            for (Job__c job : existingJobList) {
                if (OppsNeedJobIDLookupMap.containsKey(job.XometryJobID__c)) {
                    List<Opportunity> oppsNeedJobList = OppsNeedJobIDLookupMap.get(job.XometryJobID__c);
                    for (Opportunity opp : oppsNeedJobList) {
                        opp.JobId__C = job.ID;
                    }
                }
            }
        }
    }
    /**
     * @description assing existing cases to the opportunities created that Supplies_Xometry_Job__c match with cases
     * Shadow_JobId__c's field
     * @param newOpportunities - list of opportunities that has been created
     */

    public static void assignOppToCase(List<Opportunity> newOpportunities) {
        Map<String, Opportunity> jobIdToOppMap = new Map<String, Opportunity>();

        //  creating a map that contains opportunities's id
        for (Opportunity o : newOpportunities) {
            if (o.RecordTypeId == AppConstants.oppSellerMarketplaceRecordTypeId && o.Shadow_JobId__c != null) {
                jobIdToOppMap.put(o.Shadow_JobId__c, o);
            }
        }
        //fetching existing cases
        if (!jobIdToOppMap.isEmpty()) {
            List<Case> suppliesCaseList = [
                SELECT Supplies_Xometry_Job__c, Id, Opportunity__c, Job__c
                FROM Case
                WHERE
                    Supplies_Xometry_Job__c != NULL
                    AND Supplies_Xometry_Job__c IN :jobIdToOppMap.keySet()
                    AND Opportunity__c = NULL
                    AND (RecordTypeId = :AppConstants.caseSellerMarketPlaceRTypeId
                    OR RecordTypeId = :AppConstants.caseFinServRTypeId)
            ];

            //assigning opportunities to the cases
            if (!suppliesCaseList.isEmpty()) {
                for (Case c : suppliesCaseList) {
                    if (jobIdToOppMap.containsKey(c.Supplies_Xometry_Job__c)) {
                        c.Opportunity__c = jobIdToOppMap.get(c.Supplies_Xometry_Job__c).Id;
                        c.Job__c = jobIdToOppMap.get(c.Supplies_Xometry_Job__c).JobId__c;
                    }
                }

                DatabaseUtilities.upsertToDatabase(
                    suppliesCaseList,
                    'OpportunityHandler.assignOppToCase',
                    'Update Case with Supplies Opp'
                );
            }
        }
    }

    /**
     * @description Adding new Opp to existing junction object CaseOpportunity
     * @param newOppList - list of new Opps
     * @param oldOppMap - Map of old Opps
     */
    public static void associateToCaseOpp(List<Opportunity> newOppList, Map<Id, Opportunity> oldOppMap) {
        Map<String, Opportunity> quoteOppMap = new Map<String, Opportunity>();
        Map<String, Opportunity> oldQuoteOppMap = new Map<String, Opportunity>();
        for (Opportunity opp : newOppList) {
            Boolean cond = Trigger.isInsert;

            if (
                Trigger.isUpdate &&
                opp.Last_Quote_Xometry_ERP_ID__c != oldOppMap.get(opp.Id).Last_Quote_Xometry_ERP_ID__c
            ) {
                cond = true;
                oldQuoteOppMap.put(oldOppMap.get(opp.Id).Last_Quote_Xometry_ERP_ID__c, opp);
            }

            if (cond) {
                quoteOppMap.put(opp.Last_Quote_Xometry_ERP_ID__c, opp);
            }
        }

        List<CaseOpportunity__c> caseOppToUpdate = new List<CaseOpportunity__c>();
        List<CaseOpportunity__c> caseOppToDelete = new List<CaseOpportunity__c>();
        for (CaseOpportunity__c caseOpp : [
            SELECT Xometry_ERP_ID__c, Opportunity__c
            FROM CaseOpportunity__c
            WHERE Xometry_ERP_ID__c IN :quoteOppMap.keySet() OR Xometry_ERP_ID__c IN :oldQuoteOppMap.keySet()
        ]) {
            //update holder junctions when is created/updated with matching Xometry Id
            if (quoteOppMap.containsKey(caseOpp.Xometry_ERP_ID__c) && caseOpp.Opportunity__c == null) {
                caseOpp.Opportunity__c = quoteOppMap.get(caseOpp.Xometry_ERP_ID__c).Id;
                caseOppToUpdate.add(caseOpp);
            }
            //unlink opp with old Xometry Id
            if (
                oldQuoteOppMap.containsKey(caseOpp.Xometry_ERP_ID__c) &&
                oldQuoteOppMap.get(caseOpp.Xometry_ERP_ID__c).Id == caseOpp.Opportunity__c
            ) {
                caseOpp.Opportunity__c = null;
                caseOppToUpdate.add(caseOpp);
            }
        }

        DatabaseUtilities.saveToDatabase(
            caseOppToUpdate,
            'OpportunityHandler.associateToCaseOpp',
            'Update CaseOpportunity with new Opp'
        );
    }

    /*
     * Stamp the First Quote Owner (first sales rep that owns the Opp) and
     * Account Owner On Create (Opp owner at the time of created, regardless of being a House Account)
     * @param newOppList List of Opportunities to be Inserted/Updated
     * @param oldOppMap The Old Opportunity Map before the Update was triggered
     */
    public static void stampOwnershipFields(
        List<Opportunity> inOpportunityList,
        Map<Id, Opportunity> inOldOpportunityMap
    ) {
        List<Opportunity> oppsNeedingInitialAccountOwner = new List<Opportunity>();
        List<Opportunity> oppsNeedingFirstSalesOwner = new List<Opportunity>();
        Set<ID> accountIDSet = new Set<ID>();
        Set<ID> ownerIDSet = new Set<ID>();

        for (Opportunity opp : inOpportunityList) {
            Boolean isMfgOpp = opp.RecordTypeID == AppConstants.oppManufacturingServRTypeID;
            Boolean quoteCreatedAfterLaunch = opp.Quote_Created_Date__c >= AppConstants.oppOwnerStampLaunchTime;
            Boolean orderCreatedOppBeforeQuote =
                Trigger.isInsert &&
                opp.Quote_Created_Date__c == null &&
                opp.Order_Date__C >= AppConstants.oppOwnerStampLaunchTime;

            if (isMfgOpp && (quoteCreatedAfterLaunch || orderCreatedOppBeforeQuote)) {
                Boolean needsInitialAccountOwner =
                    String.isNotBlank(opp.AccountID) && String.isBlank(opp.AccountOwnerOnCreation__c);
                if (needsInitialAccountOwner) {
                    oppsNeedingInitialAccountOwner.add(opp);
                    accountIDSet.add(opp.AccountID);
                }

                Boolean needsFirstSalesOwner =
                    opp.FirstSalesOwner__c == null &&
                    String.isNotBlank(opp.OwnerId) &&
                    !AppConstants.HOUSE_USERS_TO_EXCLUDE_FOR_SALES_OWNERSHIP.contains(opp.OwnerId);
                if (needsFirstSalesOwner) {
                    oppsNeedingFirstSalesOwner.add(opp);
                    ownerIDSet.add(opp.OwnerId);
                }
            }
        }

        Boolean oppsNeedAccountOwner = !oppsNeedingInitialAccountOwner.isEmpty();
        Boolean oppsNeedFirstSalesOwner = !oppsNeedingFirstSalesOwner.isEmpty();

        if (oppsNeedAccountOwner || oppsNeedFirstSalesOwner) {
            Map<Id, Id> accountIDToOwnerIDMap = new Map<Id, Id>();

            if (oppsNeedAccountOwner) {
                for (Account a : [SELECT ID, OwnerID FROM Account WHERE ID IN :accountIDSet]) {
                    accountIDToOwnerIDMap.put(a.ID, a.OwnerID);
                    ownerIDSet.add(a.OwnerId);
                }
            }
            Map<Id, User> ownerMap = new Map<Id, User>([SELECT Id, UserRole.Name FROM User WHERE Id IN :ownerIDSet]);

            if (oppsNeedAccountOwner) {
                for (Opportunity opp : oppsNeedingInitialAccountOwner) {
                    if (String.isNotBlank(accountIDToOwnerIDMap.get(opp.AccountID))) {
                        ID oppAccountOwnerID = accountIDToOwnerIDMap.get(opp.AccountID);
                        opp.AccountOwnerOnCreation__c = oppAccountOwnerID;
                        opp.AccountOwnerOnCreationRole__c = ownerMap.get(oppAccountOwnerID).UserRole.Name;
                    }
                }
            }

            if (oppsNeedFirstSalesOwner) {
                for (Opportunity opp : oppsNeedingFirstSalesOwner) {
                    ID oppOwnerID = opp.OwnerID;
                    opp.FirstSalesOwner__c = oppOwnerID;
                    opp.FirstSalesOwnerRole__c = ownerMap.get(oppOwnerID).UserRole.Name;
                }
            }
        }
    }
}