public with sharing class JobHandler {
    static final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();
    /**
     * @description creates a map of jobs with a set of related order id's
     * @param newJobsList List of jobs to be inserted
     */
    public static Map<String, Set<String>> getJobOrderMap(List<Job__c> newJobsList) {
        Map<String, Set<String>> orderSetByJobMap = new Map<String, Set<String>>();
        for (Job__c j : newJobsList) {
            Set<String> orderIdSet = new Set<String>();
            if (j.XometryOpsOrderID__c != null) {
                orderIdSet.add(j.XometryOpsOrderID__c);
            }
            if (!String.isEmpty(j.Order_IDs_String__c)) {
                orderIdSet.addAll(j.Order_IDs_String__c.split(';'));
            }

            if (!orderIdSet.isEmpty()) {
                orderSetByJobMap.put(j.XometryJobID__c, new Set<String>(orderIdSet));
            }
        }
        return orderSetByJobMap;
    }

    /**
     * @description creates a map of order IDs to OpsOrders for Large Orders
     * @param newJobsList List of jobs to be inserted
     */
    public static Set<String> getLargeOrderIdSet(List<Job__c> newJobsList) {
        Map<String, Set<String>> jobsToOrdersMap = getJobOrderMap(newJobsList);
        List<String> allOrdersIds = new List<String>();

        for (String jobID : jobsToOrdersMap.keySet()) {
            for (String orderID : jobsToOrdersMap.get(jobId)) {
                allOrdersIds.add(orderID);
            }
        }

        Set<String> largeOrderIdSet = new Set<String>();

        for (Ops_Order__c oo : [
            SELECT ID, XometryOpsOrderID__c
            FROM Ops_Order__c
            WHERE XometryOpsOrderID__c IN :allOrdersIds AND Is_Large_Order__c = TRUE
        ]) {
            largeOrderIdSet.add(oo.XometryOpsOrderID__c);
        }

        return largeOrderIdSet;
    }

    /**
     * @description associates jobs to ops order
     * @param newJobsList List of jobs to be inserted
     */
    public static void associateOpsOrder(List<Job__c> newJobsList) {
        Set<String> jobOrdersSet = new Set<String>();
        Map<String, Ops_Order__c> orderSetByOrderMap = new Map<String, Ops_Order__c>();
        Map<String, Set<String>> orderSetByJobMap = getJobOrderMap(newJobsList);
        for (Set<String> orderSet : orderSetByJobMap.values()) {
            jobOrdersSet.addAll(orderSet);
        }

        if (!jobOrdersSet.isEmpty()) {
            Map<String, Ops_Order__c> existingOpsOrdersMap = new Map<String, Ops_Order__c>();
            Set<Ops_Order__c> existingLargeOrdersSet = new Set<Ops_Order__c>();

            for (Ops_Order__c o : [
                SELECT
                    Id,
                    XometryOpsOrderID__c,
                    Stage__c,
                    Is_Large_Order__c,
                    Opportunity__r.Account.OPS_Top_Quality_Customer__c
                FROM Ops_Order__c
                WHERE XometryOpsOrderID__c IN :jobOrdersSet
            ]) {
                existingOpsOrdersMap.put(o.XometryOpsOrderID__c, o);
                if (o.Is_Large_Order__c) {
                    existingLargeOrdersSet.add(o);
                }
            }

            Map<String, Ops_Order__c> opsOrderMap2up = new Map<String, Ops_Order__c>();

            for (Job__c j : newJobsList) {
                Set<String> thisJobOrderIdSet = new Set<String>();
                if (orderSetByJobMap.containsKey(j.XometryJobID__c)) {
                    thisJobOrderIdSet = orderSetByJobMap.get(j.XometryJobID__c);
                }

                for (String orderId : thisJobOrderIdSet) {
                    Boolean thisOrderTopQualityCustomer = false;
                    if (existingOpsOrdersMap.containsKey(orderId)) {
                        opsOrderMap2up.put(orderId, existingOpsOrdersMap.get(orderId));
                        thisOrderTopQualityCustomer = existingOpsOrdersMap.get(orderId)
                            .Opportunity__r.Account.OPS_Top_Quality_Customer__c;
                        if (thisOrderTopQualityCustomer == true) {
                            j.Ops_TopQualityCustomer__c = true;
                        }
                    } else if (!opsOrderMap2up.containsKey(orderId)) {
                        Ops_Order__c newOpsOrder = new Ops_Order__c();
                        newOpsOrder.Name = orderId;
                        newOpsOrder.XometryOpsOrderID__c = orderId;
                        opsOrderMap2up.put(orderId, newOpsOrder);
                    }
                }
            }
            DatabaseUtilities.upsertToDatabase(
                opsOrderMap2up.values(),
                'JobHandler.associateOpsOrder',
                'Did not associate orders to job'
            );

            Map<String, Id> insertedOpsOrdersMap = new Map<String, Id>();
            //TODO: Make sure the Large Order is the "main" order on the job
            for (Ops_Order__c o : opsOrderMap2up.values()) {
                insertedOpsOrdersMap.put(o.XometryOpsOrderID__c, o.Id);
            }

            for (Job__c j : newJobsList) {
                Set<String> thisJobOrderIdSet = new Set<String>();
                if (orderSetByJobMap.containsKey(j.XometryJobID__c)) {
                    thisJobOrderIdSet = orderSetByJobMap.get(j.XometryJobID__c);
                }

                for (String orderId : thisJobOrderIdSet) {
                    j.OrderID__c = insertedOpsOrdersMap.get(j.XometryOpsOrderID__c);
                }
            }
        }
    }

    /**
     * @description associates job to a supplier
     * @param jobList list of jobs to be inserted or updated
     */

    public static void associateSupplier(List<Job__c> jobList) {
        Set<String> jobsHaveAcceptedPartner = new Set<String>();

        for (Job__c j : jobList) {
            if (j.AcceptedPartnerID__c != null) {
                jobsHaveAcceptedPartner.add(j.AcceptedPartnerID__c);
            }
        }

        if (!jobsHaveAcceptedPartner.isEmpty()) {
            Map<String, Supplier__c> existingSuppliersMap = new Map<String, Supplier__c>();

            for (Supplier__c s : [
                SELECT Id, PartnerID__c, SPOC_Supplier__c, SPOC_Owner__c
                FROM Supplier__c
                WHERE PartnerID__c IN :jobsHaveAcceptedPartner
            ]) {
                existingSuppliersMap.put(s.PartnerId__c, s);
            }

            for (Job__c j : jobList) {
                if (existingSuppliersMap.containsKey(j.AcceptedPartnerID__c)) {
                    j.Supplier__c = existingSuppliersMap.get(j.AcceptedPartnerID__c).Id;
                    if (existingSuppliersMap.get(j.AcceptedPartnerID__c).SPOC_Supplier__c) {
                        j.Accepted_by_SPOC_Supplier__c = true;
                        if (existingSuppliersMap.get(j.AcceptedPartnerID__c).SPOC_Owner__c != null) {
                            j.SPOC_Owner__c = existingSuppliersMap.get(j.AcceptedPartnerID__c).SPOC_Owner__c;
                        }
                    }
                }
            }
        }
    }
    /*
     * @description Creates Supplies Opportunity
     * @param  newJobList list of Jobs being created
     */
    public static void createSuppliesOpps(List<Job__c> newJobList, Map<ID, Job__C> oldJobMap) {
        Set<String> existingSupplierSet = new Set<String>();
        Set<String> xomJobIdSet = new Set<String>();
        for (Job__c job : newJobList) {
            xomJobIdSet.add(job.XometryJobID__c);
            existingSupplierSet.add(job.Supplier__c);
        }
        Map<Id, Supplier__C> existingSupplierMap = new Map<Id, Supplier__C>();
        List<routingAddress> supRoutingList = new List<routingAddress>();
        Map<ID, ID> supplierToRouteOwnerMap = new Map<ID, ID>();
        if (!existingSupplierSet.isEmpty()) {
            List<Supplier__C> existingSuppliers = [
                SELECT
                    Id,
                    AccountID__c,
                    ContactID__c,
                    P21_Account_Details__c,
                    P21_Account_Details__r.OwnerID,
                    Zipcode__c
                FROM Supplier__C
                WHERE ID IN :existingSupplierSet
            ];
            for (Supplier__C sup : existingSuppliers) {
                existingSupplierMap.put(sup.ID, sup);
                //Construct a Territory Router Check
                if (sup.P21_Account_Details__C == null && sup.Zipcode__c != null) {
                    routingAddress myRoutingAddress = new routingAddress(sup.Zipcode__c, null, null, null, sup.Id);
                    supRoutingList.add(myRoutingAddress);
                }
            }
            if (!supRoutingList.isEmpty()) {
                supRoutingList = routingHelper.suppliesTerritoryRouting(supRoutingList, 'Supplies');
                for (routingAddress rAddr : supRoutingList) {
                    if (rAddr.routedOwnerID != null) {
                        supplierToRouteOwnerMap.put(rAddr.sourceID, rAddr.routedOwnerID);
                    }
                }
            }
        }
        // TODO check if the update is changing the status to Accepted if not can skip this logic. Performance tuning.
        List<Opportunity> oppsToInsertList = new List<Opportunity>();
        List<Opportunity> oppsToUpsertList = new List<Opportunity>();
        List<Opportunity> existingOpportunityList = [
            SELECT Id, Shadow_JobId__c, JobId__C
            FROM Opportunity
            WHERE Shadow_JobId__c IN :xomJobIdSet AND RecordtypeID = :oppSuppliesRecordTypeID
        ];
        Map<String, Opportunity> existingJobOppMap = new Map<String, Opportunity>();
        for (Opportunity opp : existingOpportunityList) {
            existingJobOppMap.put(opp.Shadow_JobId__c, opp);
        }
        for (Job__c job : newJobList) {
            //Do not create Supplies Opps for anything not Domestic and accepted time before 12/05
            if (job.MadeInChina__c == false && job.AcceptedDateTime__c >= DateTime.newInstanceGMT(2021, 12, 5)) {
                // if there is no Supplies Opp for the Job then create it.
                if (!existingJobOppMap.containsKey(job.XometryJobID__c)) {
                    if (job.Stage__C == 'Accepted') {
                        Opportunity newOpp = new Opportunity();
                        newOpp.RecordTypeID = oppSuppliesRecordTypeID;
                        newOpp.Shadow_JobId__c = job.XometryJobID__c;
                        newOpp.JobId__C = job.Id;
                        newOpp.name = 'Job ' + job.XometryJobID__c + ' Accepted';
                        newOpp.CloseDate = Date.today() + 30;
                        newOpp.OwnerId = AppConstants.SUPPLIES_HOUSE_USER;
                        newOpp.Line_of_Business__c = 'Supplies';
                        newOpp.StageName = 'New';
                        if (existingSupplierMap.containsKey(job.Supplier__c)) {
                            //Mark the Job
                            Supplier__C existingSupplier = existingSupplierMap.get(job.Supplier__c);
                            newOpp.Primary_Contact__c = existingSupplier.ContactID__C;
                            newOpp.AccountID = existingSupplier.AccountID__C;
                            newOpp.P21_Account_Details__C = existingSupplier.P21_Account_Details__c;
                            // Check if the Supplier has a P21 Account and assign the Owner accordingly
                            if (existingSupplier.P21_Account_Details__r.OwnerID != null) {
                                newOpp.OwnerID = existingSupplier.P21_Account_Details__r.OwnerID;
                            } else if (supplierToRouteOwnerMap.containsKey(existingSupplier.Id)) {
                                //Check the suppliers Zipcode against the Rep router territories
                                newOpp.OwnerID = supplierToRouteOwnerMap.get(existingSupplier.Id);
                            } else {
                                newOpp.OwnerID = AppConstants.SUPPLIES_HOUSE_USER;
                            }
                            newOpp.Primary_Supplier__C = existingSupplier.Id;
                        }
                        oppsToInsertList.add(newOpp);
                    }
                }
                // if there is an existing Opp that does not have the Lookup Populated then add the ID
                if (existingJobOppMap.containsKey(job.XometryJobID__c)) {
                    Opportunity existingOpp = existingJobOppMap.get(job.XometryJobID__c);
                    if (existingOpp.JobId__C == null) {
                        existingOpp.JobId__C = job.Id;
                        existingOpp.Primary_Supplier__C = job.Supplier__c;
                        oppsToUpsertList.add(existingOpp);
                    }
                }
            }
        }

        if (!oppsToInsertList.isEmpty()) {
            routingHelper.routeSuppliesOpps(oppsToInsertList);
        }
        oppsToUpsertList.addAll(oppsToInsertList);
        DatabaseUtilities.upsertToDatabase(
            oppsToUpsertList,
            'JobHandler.createSuppliesOpps',
            'Creating new Supplies Opps from Jobs'
        );
    }

    /*
     * @description Creates/updates many to many Junction Object, Jobs with Ops Orders
     * @param  newJobList list of Jobs being inserted or updated
     */
    public static void upsertJobOrderJunction(List<Job__c> newJobList, Map<Id, Job__c> oldJobMap) {
        Map<String, Job__c> newJobMap = new Map<String, Job__c>();
        for (Job__c j : newJobList) {
            Boolean insertCond = Trigger.isInsert;
            Boolean updateCond =
                Trigger.isUpdate &&
                (j.XometryOpsOrderID__c != oldJobMap.get(j.Id).XometryOpsOrderID__c ||
                j.Order_IDs_String__c != oldJobMap.get(j.Id).Order_IDs_String__c);
            if (insertCond || updateCond) {
                newJobMap.put(j.XometryJobID__c, j);
            }
        }
        Map<String, Set<String>> orderSetByJobMap = getJobOrderMap(newJobMap.values());
        Set<String> allOrdersSet = new Set<String>();
        // Map uKey List[orderId, jobId]
        Map<String, List<String>> uKeyMap = new Map<String, List<String>>();

        for (String thisJob : orderSetByJobMap.keySet()) {
            for (String orderId : orderSetByJobMap.get(thisJob)) {
                String uKey = orderId + ' : ' + thisJob;
                uKeyMap.put(uKey, new List<String>{ orderId, thisJob });
                allOrdersSet.add(orderId);
            }
        }

        Map<String, Ops_Order__c> opsOrderMap = new Map<String, Ops_Order__c>();
        if (!allOrdersSet.isEmpty()) {
            for (Ops_Order__c opsOrd : [
                SELECT Id, XometryOpsOrderID__c
                FROM Ops_Order__c
                WHERE XometryOpsOrderID__c IN :allOrdersSet
            ]) {
                opsOrderMap.put(opsOrd.XometryOpsOrderID__c, opsOrd);
            }

            if (allOrdersSet.size() != opsOrderMap.size()) {
                List<Ops_Order__c> createOpsOrderList = new List<Ops_Order__c>();
                for (String orderString : allOrdersSet) {
                    if (!opsOrderMap.containsKey(orderString)) {
                        // create ops order shell
                        Ops_Order__c newOpsOrder = new Ops_Order__c(
                            Name = orderString,
                            XometryOpsOrderID__c = orderString
                        );
                        createOpsOrderList.add(newOpsOrder);
                    }
                }
                if (!createOpsOrderList.isEmpty()) {
                    DatabaseUtilities.insertToDatabase(
                        createOpsOrderList,
                        'JobHandler.JobOrderJunction',
                        'createOpsOrder job order junction'
                    );
                    for (Ops_Order__c newOpsOrder : createOpsOrderList) {
                        opsOrderMap.put(newOpsOrder.XometryOpsOrderID__c, newOpsOrder);
                    }
                }
            }
        }

        if (!uKeyMap.keySet().isEmpty()) {
            Map<String, Job_Order__c> existingJobOrdsJunction = new Map<String, Job_Order__c>();
            for (Job_Order__c jo : [
                SELECT Id, OrderAndJobId__c, XometryJobID__c, Job__c, XometryOpsOrderID__c, Ops_Order__c
                FROM Job_Order__c
                WHERE OrderAndJobId__c IN :uKeyMap.keySet()
            ]) {
                existingJobOrdsJunction.put(jo.OrderAndJobId__c, jo);
            }
            Map<String, Job_Order__c> jobOrderJunctionToUpsertMap = new Map<String, Job_Order__c>();
            for (String uKey : uKeyMap.keySet()) {
                String thisOrderId = uKeyMap.get(uKey)[0];
                String thisJobId = uKeyMap.get(uKey)[1];
                if (!existingJobOrdsJunction.containsKey(uKey)) {
                    Job_Order__c jobOrd = new Job_Order__c();
                    jobOrd.OrderAndJobId__c = uKey;
                    jobOrd.XometryJobID__c = thisJobId;
                    jobOrd.Job__c = newJobMap.get(thisJobId).Id;
                    if (opsOrderMap.containsKey(thisOrderId)) {
                        jobOrd.Ops_Order__c = opsOrderMap.get(thisOrderId).Id;
                    }
                    jobOrd.XometryOpsOrderID__c = thisOrderId;

                    jobOrderJunctionToUpsertMap.put(uKey, jobOrd);
                } else {
                    Boolean updateTracker = false;
                    Job_Order__c jobOrd = existingJobOrdsJunction.get(uKey);
                    if (String.isBlank(jobOrd.XometryJobID__c)) {
                        jobOrd.XometryJobID__c = thisJobId;
                        updateTracker = true;
                    }
                    if (String.isBlank(jobOrd.Job__c)) {
                        jobOrd.Job__c = newJobMap.get(thisJobId).Id;
                        updateTracker = true;
                    }

                    if (String.isBlank(jobOrd.XometryOpsOrderID__c)) {
                        jobOrd.XometryOpsOrderID__c = thisOrderId;
                        updateTracker = true;
                    }
                    if (String.isBlank(jobOrd.Ops_Order__c) && opsOrderMap.containsKey(thisOrderId)) {
                        jobOrd.Ops_Order__c = opsOrderMap.get(thisOrderId).Id;
                        updateTracker = true;
                    }

                    if (updateTracker == true) {
                        jobOrderJunctionToUpsertMap.put(uKey, jobOrd);
                    }
                }
            }
            DatabaseUtilities.upsertToDatabase(
                jobOrderJunctionToUpsertMap.values(),
                'JobHandler.upsertJobOrderJunction',
                'Updating junction object'
            );
        }
    }

    /**
     * @description Sets the Technical Review Status for jobs checking Tech_Review_Case_Creation_Flag__c formula field in large orders on creation
     * @param newJobList list of Jobs being created/updated/deleted
     * @param oldJobMap map of Jobs before the trigger
     */
    public static void setTechnicalReviewStatus(List<Job__c> newJobList, Map<ID, Job__c> oldJobMap) {
        Set<String> closeCaseTechXomJobIDSet = new Set<String>();
        Set<String> largeOrderIdSet = getLargeOrderIdSet(Trigger.new);

        for (Job__c newJob : newJobList) {
            Boolean cond1 = Trigger.isInsert;
            Boolean cond2 =
                Trigger.isUpdate &&
                (oldJobMap.get(newJob.ID).Stage__c != newJob.Stage__c) &&
                newJob.Technical_Review_Status__c == 'Pending Technical Review';
            boolean closeFlag = false;

            if (cond1 || cond2) {
                if (!String.isBlank(newjob.RiskFactor__c) && newjob.Tech_Review_Case_Creation_Flag__c) {
                    for (String orderId : newJob.Order_IDs_String__c.split(';')) {
                        if (largeOrderIdSet.contains(orderId)) {
                            newJob.Technical_Review_Status__c = 'Pending Technical Review';
                            closeFlag = JobHandler.largeOrderCloseStatusChangeCheck(newJob);

                            if (closeFlag == true) {
                                newJob.Technical_review_Status__c = 'No Technical Review Required';
                                newJob.DFM_Complete__c = true;

                                if (cond2) {
                                    closeCaseTechXomJobIDSet.add(newJob.XometryJobID__c);
                                }
                            }
                            break;
                        }
                    }
                }
            }
        }

        if (!closeCaseTechXomJobIDSet.isEmpty()) {
            List<Case> casesToUpdateList = new List<Case>();
            for (Case c : [
                SELECT ID, Job__c, ShadowXometryJobID__c, isClosed
                FROM Case
                WHERE
                    ShadowXometryJobID__c IN :closeCaseTechXomJobIDSet
                    AND RecordTypeId = :AppConstants.caseManagementRTypeId
                    AND Type = 'Technical Review'
                    AND isClosed = FALSE
            ]) {
                //If the job has had its stage changed the current case is Open
                c.Status = 'Closed';
                c.Technical_Review_Status__c = 'Large Order Review Complete';
                c.Resource_Category__c = 'Automation Canceled';
                c.Cancellation_Reason__c = 'Automation';
                casesToUpdateList.add(c);
            }
            DatabaseUtilities.saveToDatabase(
                casesToUpdateList,
                'Jobhandler.casesToInsertList',
                'Update Tech Review Cases for Stage Change'
            );
        }
    }

    /**
     * @description Sets the Technical Review Status for Jobs that are High Risk but no longer Open and not Accepted
     * @param newJobList list of Jobs being created/updated/deleted
     * @param largeOrderIdSet a Set of XometryOrderIds that are large Orders
     */
    public static boolean largeOrderCloseStatusChangeCheck(Job__c job) {
        if (AppConstants.jobClosedStringSet.contains(job.Stage__c)) {
            return true;
        } else {
            return false;
        }
    }

    //TODO: Create a set of large orders IDs to pass to multiple methods
    //TODO: Separate case creation to be called from main Job processing method

    /**
     * @description Creates technical review cases for jobs checking Tech_Review_Case_Creation_Flag__c formula field in large orders
     * @param newJobList list of Jobs being created/updated/deleted
     * @param oldJobMap map of old jobs
     */
    public static void createTechnicalReviewCase(List<Job__c> newJobList, Map<ID, Job__c> oldJobMap) {
        Map<String, List<Job__c>> orderIDToJobListMap = new Map<String, List<Job__c>>();
        Map<String, Job__c> jobIdToRecordMap = new Map<String, Job__c>();

        for (Job__c job : newJobList) {
            //checking Tech_Review_Case_Creation_Flag__c formula field
            Boolean cond1 = !String.isBlank(job.RiskFactor__c) && job.Tech_Review_Case_Creation_Flag__c;
            //Job is accepted on insert
            Boolean cond2 = Trigger.isInsert && job.AcceptedPartnerID__c != null;
            //Job was accepted on update
            Boolean cond3 = Trigger.isUpdate && job.AcceptedPartnerID__c != null;
            //Job was not previously accepted
            Boolean cond4 = Trigger.isUpdate && oldJobMap.get(job.ID).AcceptedPartnerID__c == null;
            //Job tech review status was updated from an Ops Order meeting Large Order criteria
            Boolean cond5 =
                Trigger.isUpdate &&
                job.Technical_Review_Status__c == 'Pending Technical Review' &&
                oldJobMap.get(job.ID).Technical_Review_Status__c == 'No Technical Review Required';

            if (cond1 && (cond2 || (cond3 && (cond4 || cond5)))) {
                jobIdToRecordMap.put(job.XometryJobID__c, job);
                if (job.Order_IDs_String__c != null) {
                    for (String orderID : job.Order_IDs_String__c.split(';')) {
                        if (!orderIDToJobListMap.containsKey(orderId)) {
                            orderIDToJobListMap.put(orderID, new List<Job__c>{ job });
                        } else {
                            if (!orderIDToJobListMap.get(orderID).contains(job)) {
                                orderIDToJobListMap.get(orderID).add(job);
                            }
                        }
                    }
                } else {
                    orderIDToJobListMap.put(job.XometryOpsOrderID__c, new List<Job__c>{ job });
                }
            }
        }

        if (!jobIdToRecordMap.isEmpty()) {
            // Make sure a case does not already exist
            for (Case techReviewCase : [
                SELECT Job__c, ShadowXometryJobID__c
                FROM Case
                WHERE
                    ShadowXometryJobID__c IN :jobIdToRecordMap.keySet()
                    AND RecordTypeId = :AppConstants.caseManagementRTypeId
                    AND Type = 'Technical Review'
            ]) {
                jobIdToRecordMap.remove(techReviewCase.ShadowXometryJobID__c);
            }
        }

        if (!jobIdToRecordMap.isEmpty()) {
            List<Job__c> jobsList = new List<Job__c>();
            for (String jobId : jobIdToRecordMap.keySet()) {
                jobsList.add(jobIdToRecordMap.get(jobId));
            }

            if (!jobsList.isEmpty()) {
                Map<String, BusinessHours> hoursMap = new Map<String, BusinessHours>();
                for (BusinessHours bHours : [SELECT Id, Name, MondayEndTime FROM BusinessHours]) {
                    hoursMap.put(bHours.Name, bHours);
                }

                Map<Job__c, Ops_Order__c> highRiskJobToLargeOrderIdMap = new Map<Job__c, Ops_Order__c>();
                for (Ops_Order__c opsOrder : [
                    SELECT Id, XometryOpsOrderID__c, ParentOpsOrder__c, POD__c
                    FROM Ops_Order__c
                    WHERE XometryOpsOrderID__c IN :orderIDToJobListMap.keySet() AND Is_Large_Order__c = TRUE
                ]) {
                    for (Job__c job : orderIDToJobListMap.get(opsOrder.XometryOpsOrderID__c)) {
                        highRiskJobToLargeOrderIdMap.put(job, opsOrder);
                    }
                }

                if (!highRiskJobToLargeOrderIdMap.isEmpty()) {
                    Map<String, Id> queueMap = new Map<String, Id>();

                    for (Group queueGroup : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue']) {
                        queueMap.put(queueGroup.DeveloperName, queueGroup.Id);
                    }

                    List<Case> casesToInsertList = new List<Case>();
                    for (Job__c highRiskJob : highRiskJobToLargeOrderIdMap.keySet()) {
                        Boolean closeCaseCheck = false;

                        Case techReviewCase = new Case();
                        techReviewCase.RecordTypeID = AppConstants.caseManagementRTypeId;
                        techReviewCase.OwnerId = highRiskJobToLargeOrderIdMap.get(highRiskJob).POD__c != null &&
                            queueMap.containsKey(highRiskJobToLargeOrderIdMap.get(highRiskJob).POD__c.replace(' ', '_'))
                            ? queueMap.get(highRiskJobToLargeOrderIdMap.get(highRiskJob).POD__c.replace(' ', '_'))
                            : queueMap.get('First_Impressions');
                        techReviewCase.Type = 'Technical Review';
                        techReviewCase.Status = 'New';
                        techReviewCase.Subject = highRiskJob.XometryJobID__c + ' Technical Review Case';
                        techReviewCase.Job__c = highRiskJob.Id;
                        techReviewCase.ShadowXometryJobID__c = highRiskJob.XometryJobID__c;
                        techReviewCase.JobRiskFactor__c = highRiskJob.RiskFactor__c;
                        techReviewCase.Supplier__c = highRiskJob.Supplier__c;
                        techReviewCase.ContactId = highRiskJob.Supplier__r.ContactID__c;
                        techReviewCase.SuppliedEmail = highRiskJob.Supplier__r.EmailAddress__c;
                        //Note: Leaving the possibility of a job having parts from multiple large orders
                        techReviewCase.GNOOrder__c = highRiskJobToLargeOrderIdMap.get(highRiskJob).Id;
                        techReviewCase.ParentOpsOrder__c = highRiskJobToLargeOrderIdMap.get(highRiskJob)
                            .ParentOpsOrder__c;
                        techReviewCase.BusinessHoursId = hoursMap.get('POD Business Hours - EST').Id;

                        closeCaseCheck = largeOrderCloseStatusChangeCheck(highRiskJob);
                        if (closeCaseCheck == true) {
                            techReviewCase.Status = 'Closed';
                            techReviewCase.Resource_Category__c = 'Automation Canceled';
                            techReviewCase.Technical_Review_Status__c = 'Large Order Review Complete';
                            techReviewCase.Cancellation_Reason__c = 'Automation';
                        }

                        casesToInsertList.add(techReviewCase);
                    }

                    DatabaseUtilities.insertToDatabase(
                        casesToInsertList,
                        'Jobhandler.casesToInsertList',
                        'Creating Tech Review for high risk jobs'
                    );
                }
            }
        }
    }

    /**
     * @description Creates junctions where necessary
     * @param newJobList new jobs from the ETL
     * @param oldJobMap old Map of jobs or null if insert
     */
    public static void associateJunctions(List<Job__c> newJobList, Map<Id, Job__c> oldJobMap) {
        Set<String> jopPKSet = new Set<String>();
        Map<String, Job__c> jobByOPKeyMap = new Map<String, Job__c>();
        Map<String, Job__c> jobMap = new Map<String, Job__c>();
        List<JobOrderedPart__c> jopToUpsert = new List<JobOrderedPart__c>();
        Map<String, JobOrderedPart__c> existingJOPMap = new Map<String, JobOrderedPart__c>();
        Map<String, Ordered_Part__c> existingOrderedParts = new Map<String, Ordered_Part__c>();
        Map<String, Ordered_Part__c> allOrderedParts = new Map<String, Ordered_Part__c>();
        List<Ordered_Part__c> orderedPartShell = new List<Ordered_Part__c>();

        for (Job__c thisJob : newJobList) {
            Job__c oldJob = new Job__c();

            Boolean cond1 = Trigger.isInsert && !String.isBlank(thisJob.ORDERED_PART_Ids_String__c);
            Boolean cond2 = false;
            if (Trigger.isUpdate) {
                oldJob = oldJobMap.get(thisJob.Id);
                cond2 = (!String.isBlank(thisJob.ORDERED_PART_Ids_String__c) &&
                thisJob.ORDERED_PART_Ids_String__c != oldJob.ORDERED_PART_Ids_String__c);
            }

            if (cond1 || cond2) {
                jobMap.put(thisJob.XometryJobID__c, thisJob);
                for (String op : thisJob.ORDERED_PART_Ids_String__c.split(';')) {
                    jopPKSet.add(thisJob.XometryJobID__c + ' : ' + op);
                    jobByOPKeyMap.put(op, thisJob);
                }
            }
        }

        if (!jopPKSet.isEmpty()) {
            for (Ordered_Part__c op : [
                SELECT Id, Unique_Ordered_Part_ID__c
                FROM Ordered_Part__c
                WHERE Unique_Ordered_Part_ID__c IN :jobByOPKeyMap.keySet()
            ]) {
                existingOrderedParts.put(op.Unique_Ordered_Part_ID__c, op);
                allOrderedParts.put(op.Unique_Ordered_Part_ID__c, op);
            }
            if (existingOrderedParts.size() != jobByOPKeyMap.size()) {
                for (String opId : jobByOPKeyMap.keySet()) {
                    if (!existingOrderedParts.containsKey(opId)) {
                        Ordered_Part__c newOP = new Ordered_Part__c(
                            Unique_Ordered_Part_ID__c = opId,
                            Ops_Order__c = jobByOPKeyMap.get(opId).OrderID__c,
                            Xometry_Order_ID__c = jobByOPKeyMap.get(opId).XometryOpsOrderID__c
                        );
                        orderedPartShell.add(newOP);
                    }
                }
            }
            if (!orderedPartShell.isEmpty()) {
                EventBusBypass.ByPass('orderedPartShell');
                DatabaseUtilities.insertToDatabase(
                    orderedPartShell,
                    'JobHandler.associateJunctions',
                    'Ordered Part Shell was not created'
                );
                for (Ordered_Part__c op : orderedPartShell) {
                    allOrderedParts.put(op.Unique_Ordered_Part_ID__c, op);
                }
            }
            // TODO: add all created parts to a list to check
            for (JobOrderedPart__c jop : [
                SELECT Id, JobOrderedPartKey__c, JobId__c, ERPJobId__c, OrderedPartId__c, ERPOrderedPartId__c
                FROM JobOrderedPart__c
                WHERE JobOrderedPartKey__c IN :jopPKSet
            ]) {
                existingJOPMap.put(jop.JobOrderedPartKey__c, jop);
            }
            for (String pKey : jopPKSet) {
                Boolean updateMarker = false;
                String separator = ' : ';
                String thisJob = pKey.substringBefore(separator);
                String thisOrderedPart = pKey.substringAfter(separator);
                if (existingJOPMap.containsKey(pKey)) {
                    JobOrderedPart__c thisJOP = existingJOPMap.get(pKey);
                    if (String.isBlank(thisJOP.OrderedPartId__c) && allOrderedParts.containsKey(thisOrderedPart)) {
                        thisJOP.OrderedPartId__c = allOrderedParts.get(thisOrderedPart).Id;
                        updateMarker = true;
                    }
                    if (String.isBlank(thisJOP.ERPOrderedPartId__c)) {
                        thisJOP.ERPOrderedPartId__c = thisOrderedPart;
                        updateMarker = true;
                    }
                    if (String.isBlank(thisJOP.JobId__c)) {
                        thisJOP.JobId__c = jobMap.get(thisJob).Id;
                        updateMarker = true;
                    }
                    if (String.isBlank(thisJOP.ERPJobId__c)) {
                        thisJOP.ERPJobId__c = thisJob;
                        updateMarker = true;
                    }
                    if (updateMarker) {
                        jopToUpsert.add(thisJOP);
                    }
                }
                if (!existingJOPMap.containsKey(pKey)) {
                    JobOrderedPart__c newJOP = new JobOrderedPart__c(
                        OrderedPartId__c = allOrderedParts.containsKey(thisOrderedPart)
                            ? allOrderedParts.get(thisOrderedPart).Id
                            : null,
                        ERPOrderedPartId__c = thisOrderedPart,
                        JobId__c = jobMap.get(thisJob).Id,
                        ERPJobId__c = thisJob,
                        JobOrderedPartKey__c = pKey,
                        Name = pKey
                    );
                    jopToUpsert.add(newJOP);
                }
            }
            DatabaseUtilities.upsertToDatabase(
                jopToUpsert,
                'JobHandler.associateJunctions',
                'JobOrderedPart junction did not update/create'
            );
        }
    }
    /**
     * @description determines whether to trigger a large Order Update
     * @param newJobList new jobs from the ETL
     * @param oldJobMap old Map of jobs or null if insert
     */
    public static void checkForLargeOrderSummary(List<Job__c> newJobList, Map<Id, Job__c> oldJobMap) {
        Set<Id> opsOrderIdSet = new Set<Id>();
        Set<Id> jobUpdateIdSet = new Set<Id>();
        System.debug('We are now in checkForLargeOrderSummary');
        if (!EventBusBypass.isByPassed(largeOrderHelper.jobByPass)) {
            System.debug('We won\'t get here - This is T\'s hypothesis');
            for (Job__c job : newJobList) {
                if (Trigger.isUpdate) {
                    Job__c oldJob = oldJobMap.get(job.Id);
                    if (job.Technical_Review_Status__c != oldJob.Technical_Review_Status__c) {
                        jobUpdateIdSet.add(job.Id);
                    }
                    if (job.Stage__c != oldJob.Stage__c) {
                        jobUpdateIdSet.add(job.Id);
                    }
                }
                if (Trigger.isInsert) {
                    jobUpdateIdSet.add(job.Id);
                    System.debug('Job has been inserted and added to update Set');
                }
            }

            List<Job_Order__c> jobOrderList = [
                SELECT Ops_Order__c, Ops_Order__r.Is_Large_Order__c
                FROM Job_Order__c
                WHERE Job__c IN :jobUpdateIdSet AND Ops_Order__r.Is_Large_Order__c = TRUE
            ];
            System.debug('Job Order List: ' + jobOrderList);
            for (Job_Order__c jobOrd : jobOrderList) {
                if (jobOrd.Ops_Order__r.Is_Large_Order__c == true) {
                    opsOrderIdSet.add(jobOrd.Ops_Order__c);
                }
                // }

                System.debug('opsOrderIdSet from Job Handler: ' + opsOrderIdSet);

                // List<JobOrderedPart__c> jobOrdPartUpdateList = [Select Id, OrderedPartId__r.Ops_Order__c from JobOrderedPart__c where Jobid__c in : ];
                // for (JobOrderedPart__c jobOrdPart : jobOrdPartUpdateList){
            }
            if (!opsOrderIdSet.isEmpty()) {
                OpsOrderHandler.updateLargeOrderSummary(opsOrderIdSet);
                System.debug('Order was sent to get large order summary update from Job Handler');
            }
        }
    }

    /**
     * @description Sets the Job_Overdue_Flag__c on insert/update of the DueDate__c
     * so that the Job_is_Past_Due__c is right before the batch runs
     * @param newJobsList List of jobs to be inserted
     */
    public static void setOverdueFlag(List<Job__c> newJobsList, Map<ID, Job__C> oldJobMap) {
        Date dToday = System.today();
        for (Job__c job : newJobsList) {
            Boolean cond = Trigger.isInsert;
            cond |= Trigger.isUpdate && job.DueDate__c != oldJobMap.get(job.Id).DueDate__c;
            if (cond && job.DueDate__c != null) {
                job.Job_OverDue_Flag__c = job.DueDate__c.daysBetween(dToday);
            }
        }
    }

    /**
     * @description create a Job Event and Order Event record when Asana criteria are met
     * @param newJobList List of Jobs that were just inserted or updated
     * @param oldJobMap Map of Jobs changed by the update
     */
    public static void jobEventConditionals(list<Job__c> newJobList, Map<Id, Job__c> oldJobMap) {
        Set<ID> jobRecordIDSet = new Set<ID>();
        Map<String, Map<ID, String>> jobToOpsOrdersMap = new Map<String, Map<ID, String>>();

        //The allows us to provice qualitative data to the users at a glance of the Event record
        //Instead of having to click through records to find the qualifying update
        Map<String, Map<String, String>> jobToAdditionalInformationMap = new Map<String, Map<String, String>>();

        Set<Id> opsOrderIdsWithNewJobEvents = new Set<Id>();

        Boolean anyAdditiveJobs = false;
        // Boolean anyLateBOs = false;
        // Boolean anyRejectedBOs = false;

        for (Job__c job : newJobList) {
            jobRecordIDSet.add(job.ID);
            jobToAdditionalInformationMap.put(job.XometryJobID__c, new Map<String, String>());
            if (!anyAdditiveJobs && job.processGroup_isAdditiveOnly__c) {
                anyAdditiveJobs = true;
            }
            // if (!anyLateBOs && job.Bad_Outcome_Late_Worst_Part__c != null) {
            //     anyLateBOs = true;
            // }
            // if (!anyRejectedBOs && job.Bad_Outcome_Rejected_Worst_Part__c != null) {
            //     anyRejectedBOs = true;
            // }
        }

        for (Job_Order__c jobOrd : [
            SELECT XometryJobID__c, Job__c, Ops_Order__c, XometryOpsOrderId__c
            FROM Job_Order__c
            WHERE Job__c IN :jobRecordIDSet
        ]) {
            if (!jobToOpsOrdersMap.containsKey(jobOrd.XometryJobID__c)) {
                jobToOpsOrdersMap.put(jobOrd.XometryJobID__c, new Map<ID, String>());
            }
            jobToOpsOrdersMap.get(jobOrd.XometryJobID__c).put(jobOrd.Ops_Order__c, jobOrd.XometryOpsOrderId__c);
        }

        String additiveMdtName = 'additiveJob_EventQualAmount';
        Decimal additiveThreshold = 0;

        if (anyAdditiveJobs) {
            additiveThreshold = [
                SELECT ID, DeveloperName, Currency_Ref_Value__c
                FROM Event_Threshold__mdt
                WHERE DeveloperName = :additiveMdtName
            ]
            .Currency_Ref_Value__c;
        }

        // String lateBOMdtName = 'job_BadOutcomeLateWorstPart';
        // Decimal lateBOThreshold = 0;

        // String rejectBOMdtName = 'job_BadOutcomeRejectedWorstPart';
        // Decimal rejectedBOThreshold = 0;

        // Set<String> eventThresholdMdtSet = new Set<String>{ additiveMdtName, lateBOMdtName, rejectBOMdtName };

        // if (anyLateBOs || anyRejectedBOs || anyAdditiveJobs) {
        //     for (Event_Threshold__mdt record : [
        //         SELECT ID, DeveloperName, Number_Ref_Value__c, Currency_Ref_Value__c
        //         FROM Event_Threshold__mdt
        //         WHERE DeveloperName IN :eventThresholdMdtSet
        //     ]) {
        //         if (record.DeveloperName == additiveMdtName) {
        //             additiveThreshold = record.Currency_Ref_Value__c;
        //         }
        //         if (record.DeveloperName == lateBOMdtName) {
        //             lateBOThreshold = record.Number_Ref_Value__c;
        //         }
        //         if (record.DeveloperName == rejectBOMdtName) {
        //             rejectedBOThreshold = record.Number_Ref_Value__c;
        //         }
        //     }
        // }

        //Xometry Job ID -> Process Group
        //Process Group -> Criteria Type that the job meets
        //Critiera Type -> Is this a criteria or just an event that we want to see in the event log?
        Map<String, Map<String, Map<String, Boolean>>> jobIDToCriteriaMap = new Map<String, Map<String, Map<String, Boolean>>>();

        for (Job__c job : newJobList) {
            String jobID = job.XometryJobID__c;
            String processGroup = '';
            String currentEventType = '';
            String additionalInfo = '';

            jobIDToCriteriaMap.put(jobID, new Map<String, Map<String, Boolean>>());

            Boolean spocSupplier = false;
            if (job.Accepted_by_SPOC_Supplier__c) {
                if (Trigger.isInsert || (Trigger.isUpdate && !oldJobMap.get(job.ID).Accepted_by_SPOC_Supplier__c)) {
                    spocSupplier = true;
                }
            }

            Boolean newECD = false;
            if (job.EstimatedCompletionDate__c != null) {
                if (
                    Trigger.isInsert ||
                    (Trigger.isUpdate && oldJobMap.get(job.ID).EstimatedCompletionDate__c == null ||
                    job.EstimatedCompletionDate__c != oldJobMap.get(job.ID).EstimatedCompletionDate__c)
                ) {
                    newECD = true;
                }
            }

            Boolean newECDReason = false;
            if (job.EstimatedCompletionDateReason__c != null) {
                if (
                    Trigger.isInsert ||
                    (Trigger.isUpdate && oldJobMap.get(job.ID).EstimatedCompletionDateReason__c == null ||
                    job.EstimatedCompletionDateReason__c != oldJobMap.get(job.ID).EstimatedCompletionDateReason__c)
                ) {
                    newECDReason = true;
                }
            }

            Boolean justCancelled = false;
            if (job.Stage__c == 'Cancelled') {
                if (
                    Trigger.isInsert ||
                    (Trigger.isUpdate && oldJobMap.get(job.ID).Stage__c == null ||
                    oldJobMap.get(job.ID).Stage__c != 'Cancelled')
                ) {
                    justCancelled = true;
                }
            }

            Boolean fullyShipped = false;
            if (job.Stage__c != null && AppConstants.JOB_COMPLETED_STATUSES.contains(job.Stage__c)) {
                if (
                    Trigger.isInsert ||
                    (Trigger.isUpdate &&
                    (oldJobMap.get(job.ID).Stage__c == null ||
                    !AppConstants.JOB_COMPLETED_STATUSES.contains(oldJobMap.get(job.ID).Stage__c)))
                ) {
                    fullyShipped = true;
                }
            }

            // Boolean lateBadOutcome = false;
            // if (job.Bad_Outcome_Late_Worst_Part__c != null && job.Bad_Outcome_Late_Worst_Part__c > lateBOThreshold) {
            //     if (
            //         Trigger.isInsert ||
            //         (Trigger.isUpdate &&
            //         (oldJobMap.get(job.ID).Bad_Outcome_Late_Worst_Part__c == null ||
            //         oldJobMap.get(job.ID).Bad_Outcome_Late_Worst_Part__c <= lateBOThreshold))
            //     ) {
            //         lateBadOutcome = true;
            //     }
            // }

            // Boolean rejectedBadOutcome = false;
            // if (
            //     job.Bad_Outcome_Rejected_Worst_Part__c != null &&
            //     job.Bad_Outcome_Rejected_Worst_Part__c > rejectedBOThreshold
            // ) {
            //     if (
            //         Trigger.isInsert ||
            //         (Trigger.isUpdate &&
            //         (oldJobMap.get(job.ID).Bad_Outcome_Rejected_Worst_Part__c == null ||
            //         oldJobMap.get(job.ID).Bad_Outcome_Rejected_Worst_Part__c <= rejectedBOThreshold))
            //     ) {
            //         rejectedBadOutcome = true;
            //     }
            // }

            if (
                spocSupplier ||
                newECD ||
                newECDReason ||
                justCancelled ||
                fullyShipped //lateBadOutcome || //rejectedBadOutcome
            ) {
                processGroup = 'All';
                jobIDToCriteriaMap.get(jobID).put(processGroup, new Map<String, Boolean>());

                if (spocSupplier) {
                    currentEventType = 'SPOC Supplier';
                    jobIDToCriteriaMap.get(jobID)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));
                    jobToAdditionalInformationMap.get(jobID)
                        .put(
                            currentEventType,
                            'Supplier: ' +
                            job.Supplier__r.SupplierCompanyName__c +
                            '\n' +
                            'SPOC Owner: ' +
                            job.Supplier__r.SPOC_Owner__r.Full_Name__c
                        );
                }

                if (newECD || newECDReason) {
                    currentEventType = 'Estimated Completion Date';
                    jobIDToCriteriaMap.get(jobID)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));

                    if (newECD && newECDReason) {
                        additionalInfo =
                            'New ECD: ' +
                            job.EstimatedCompletionDate__c +
                            '\n' +
                            'Supplier Update: ' +
                            job.EstimatedCompletionDateReason__c;
                    } else if (newECD) {
                        additionalInfo = 'New ECD: ' + job.EstimatedCompletionDate__c;
                    } else {
                        additionalInfo = 'Supplier Update: ' + job.EstimatedCompletionDateReason__c;
                    }
                    jobToAdditionalInformationMap.get(jobID).put(currentEventType, additionalInfo);
                }

                if (justCancelled) {
                    currentEventType = 'Job Cancelled';
                    jobIDToCriteriaMap.get(jobID)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));
                    additionalInfo = jobID + 'has been cancelled';
                    jobToAdditionalInformationMap.get(jobID).put(currentEventType, additionalInfo);
                }

                if (fullyShipped) {
                    currentEventType = 'Fully Shipped';
                    jobIDToCriteriaMap.get(jobID)
                        .get(processGroup)
                        .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));
                    additionalInfo = jobID + 'has been fully shipped';
                    jobToAdditionalInformationMap.get(jobID).put(currentEventType, additionalInfo);
                }

                // if (lateBadOutcome || rejectedBadOutcome) {
                //     currentEventType = 'Job Bad Outcome';
                //     jobIDToCriteriaMap.get(jobID)
                //         .get(processGroup)
                //         .put(currentEventType, OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType));

                //     if (lateBadOutcome && rejectedBadOutcome) {
                //         additionalInfo =
                //             'Job Late Bad Outcome Score: ' +
                //             job.Bad_Outcome_Late_Worst_Part__c +
                //             '\n' +
                //             'Job Rejected Bad Outcome Score:' +
                //             job.Bad_Outcome_Rejected_Worst_Part__c;
                //     } else if (lateBadOutcome) {
                //         additionalInfo = 'Job Late Bad Outcome Score: ' + job.Bad_Outcome_Late_Worst_Part__c;
                //     } else {
                //         additionalInfo = 'Job Rejected Bad Outcome Score:' + job.Bad_Outcome_Rejected_Worst_Part__c;
                //     }

                //     jobToAdditionalInformationMap.get(jobID).put(currentEventType, additionalInfo);
                // }
            }

            Boolean containsSubtractivePart = job.processGroup_isSubtractiveOnly__c || job.processGroup_isMixed__c;
            Boolean additiveOnly = job.processGroup_isAdditiveOnly__c;

            if (containsSubtractivePart) {
                processGroup = 'Subtractive Only or Mixed';
                jobIDToCriteriaMap.get(jobID).put(processGroup, new Map<String, Boolean>());

                Boolean topQualityAccount = false;
                if (job.Ops_TopQualityCustomer__c) {
                    if (Trigger.isInsert || (Trigger.isUpdate && !oldJobMap.get(job.ID).Ops_TopQualityCustomer__c)) {
                        topQualityAccount = true;
                        currentEventType = 'Top Quality Account';
                        jobIDToCriteriaMap.get(jobID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }
            }

            if (additiveOnly) {
                processGroup = 'Additive Only';
                jobIDToCriteriaMap.get(jobID).put(processGroup, new Map<String, Boolean>());

                Boolean lateAdditiveJob = false;
                if (job.Job_Overdue_Flag__c != null && job.Job_Overdue_Flag__c > 0) {
                    if (Trigger.isInsert || (Trigger.isUpdate && oldJobMap.get(job.ID).Job_Overdue_Flag__c <= 0)) {
                        lateAdditiveJob = true;
                        currentEventType = 'Additive Job Past Due';
                        jobIDToCriteriaMap.get(jobID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                    }
                }

                Boolean highValueAdditiveJob = false;
                if (job.AcceptedPrice__c != null && job.AcceptedPrice__c > additiveThreshold) {
                    if (
                        Trigger.isInsert ||
                        (Trigger.isUpdate &&
                        (oldJobMap.get(job.ID).AcceptedPrice__c == null ||
                        oldJobMap.get(job.ID).AcceptedPrice__c <= additiveThreshold))
                    ) {
                        highValueAdditiveJob = true;
                        currentEventType = '> Additive Job Value Threshold';
                        jobIDToCriteriaMap.get(jobID)
                            .get(processGroup)
                            .put(
                                currentEventType,
                                OpsEventsHelper.EVENT_TYPE_TO_CRITERIA_FLAG_MAP.get(currentEventType)
                            );
                        jobToAdditionalInformationMap.get(jobID)
                            .put(currentEventType, 'Job Accepted Value: $' + job.AcceptedPrice__c);
                    }
                }
            }
        }

        if (!jobIDToCriteriaMap.isEmpty()) {
            List<Job_Event__c> jobEventsList = new List<Job_Event__c>();
            List<Order_Event__c> orderEventsList = new List<Order_Event__c>();

            for (Job__c job : newJobList) {
                if (!jobIDToCriteriaMap.get(job.XometryJobID__c).isEmpty()) {
                    String jobID = job.XometryJobID__c;

                    for (String processGroup : jobIDToCriteriaMap.get(jobID).keySet()) {
                        if (!jobIDToCriteriaMap.get(jobID).get(processGroup).isEmpty()) {
                            for (String criteriaType : jobIDToCriteriaMap.get(jobID).get(processGroup).keySet()) {
                                Map<Job_Event__c, List<Order_Event__c>> eventsToInsertMap = createJobEvent(
                                    job.ID,
                                    jobID,
                                    jobToOpsOrdersMap.get(jobID),
                                    criteriaType,
                                    processGroup,
                                    jobIDToCriteriaMap.get(jobID).get(processGroup).get(criteriaType),
                                    jobToAdditionalInformationMap.get(jobID).get(criteriaType)
                                );
                                opsOrderIdsWithNewJobEvents.addAll(jobToOpsOrdersMap.get(jobID).keySet());

                                for (Job_Event__c jobEvent : eventsToInsertMap.keySet()) {
                                    jobEventsList.add(jobEvent);
                                    for (Order_Event__c orderEvent : eventsToInsertMap.get(jobEvent)) {
                                        orderEventsList.add(orderEvent);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if (!jobEventsList.isEmpty()) {
                DatabaseUtilities.insertToDatabase(
                    jobEventsList,
                    'JobHandler.jobEventConditionals',
                    'Job Events were not inserted'
                );
            }

            if (!orderEventsList.isEmpty()) {
                DatabaseUtilities.insertToDatabase(
                    orderEventsList,
                    'JobHandler.jobEventConditionals',
                    'Order Events triggered from Job Events were not inserted'
                );
                Set<String> opsOrderIds = new Set<String>();
                for (Order_Event__c oe : orderEventsList) {
                    opsOrderIds.add(oe.OrderId__c);
                }
                // get order ids related to job events that were inserted
                OpsEventsHelper.readyToEvaluate(opsOrderIds);
            }
        }
    }

    /**
     * @description createJobEvent
     * @param ID jobRecordID
     * @param String xomJobID
     * @param  Map<ID, String> opsOrderMap
     * @param  String eventType
     * @param  String processGroup
     * @param  Boolean criteria
     * @param  String additionalInformation
     */
    public static Map<Job_Event__c, List<Order_Event__c>> createJobEvent(
        ID jobRecordID,
        String xomJobID,
        Map<ID, String> opsOrderMap,
        String eventType,
        String processGroup,
        Boolean criteria,
        String additionalInformation
    ) {
        Map<Job_Event__c, List<Order_Event__c>> jobToOrderEventsReturnMap = new Map<Job_Event__c, List<Order_Event__c>>();
        Job_Event__c je = new Job_Event__c();
        je.Name = xomJobID + ' - ' + eventType;
        je.Job__c = jobRecordID;
        je.JobID__c = xomJobID;
        je.Type__c = eventType;
        je.Qualifying_Object__c = 'Job';
        je.Process_Group__c = processGroup;
        je.Criteria__c = criteria;
        je.AdditionalInformation__c = additionalInformation;

        jobToOrderEventsReturnMap.put(je, new List<Order_Event__c>());

        //Loop through all of the Ops Orders that have parts in the job
        //Create an Order Event on each Ops Order
        if (opsOrderMap != null) {
            for (ID ooID : opsOrderMap.keySet()) {
                jobToOrderEventsReturnMap.get(je)
                    .add(
                        createOrderEvent(
                            xomJobID,
                            ooID,
                            opsOrderMap.get(ooID),
                            eventType,
                            processGroup,
                            criteria,
                            additionalInformation
                        )
                    );
            }
        }

        return jobToOrderEventsReturnMap;
    }

    /**
     * @description createOrderEvents
     * @param  String xomJobID
     * @param  ID opsOrderRecordID
     * @param  String xomOrderID
     * @param  String eventType
     * @param  String processGroup
     * @param  Boolean criteria
     * @param  String additionalInformation
     */
    public static Order_Event__c createOrderEvent(
        String xomJobID,
        ID opsOrderRecordID,
        String xomOrderID,
        String eventType,
        String processGroup,
        Boolean criteria,
        String additionalInformation
    ) {
        Order_Event__c oe = new Order_Event__c();
        oe.Name = xomOrderID + ' - ' + xomJobID + ' - ' + eventType;
        oe.Ops_Order__c = opsOrderRecordID;
        oe.OrderID__c = xomOrderID;
        oe.Type__c = eventType;
        oe.Qualifying_Object__c = 'Job';
        oe.Process_Group__c = processGroup;
        oe.Criteria__c = criteria;
        oe.AdditionalInformation__c = additionalInformation;

        return oe;
    }

    /*
     * @description Checks to see if the job has any changed orders to see if it should be considered top quality
     * @param newJobsList List of jobs to be inserted
     * @param oldJobMap Map of old jobs
     */
    public static void stampTopQuality(List<Job__c> newJobsList, Map<ID, Job__C> oldJobMap) {
        Map<String, Set<String>> jobsToOrdersMap = getJobOrderMap(newJobsList);
        Set<String> ordersToCheck = new Set<String>();
        Map<String, Boolean> orderTopQualityMap = new Map<String, Boolean>();

        for (Job__c job : newJobsList) {
            Boolean topQuality = job.Ops_TopQualityCustomer__c;
            Boolean ordersUpdated =
                Trigger.isUpdate &&
                (job.Order_IDs_String__c != oldJobMap.get(job.Id).Order_IDs_String__c ||
                job.XometryOpsOrderID__c != oldJobMap.get(job.Id).XometryOpsOrderID__c);
            Boolean jobInsert = Trigger.isInsert;

            if (!topQuality && (ordersUpdated || jobInsert)) {
                ordersToCheck.addAll(jobsToOrdersMap.get(job.XometryJobID__c));
            }
        }
        if (!ordersToCheck.isEmpty()) {
            for (Ops_Order__c oo : [
                SELECT Id, XometryOpsOrderID__c, Opportunity__r.Account.OPS_Top_Quality_Customer__c
                FROM Ops_Order__c
                WHERE XometryOpsOrderID__c IN :ordersToCheck
            ]) {
                if (oo.Opportunity__r.Account.OPS_Top_Quality_Customer__c) {
                    orderTopQualityMap.put(
                        oo.XometryOpsOrderID__c,
                        oo.Opportunity__r.Account.OPS_Top_Quality_Customer__c
                    );
                }
            }
            for (Job__c job : newJobsList) {
                Set<String> thisJobOrderIdSet = new Set<String>();
                if (jobsToOrdersMap.containsKey(job.XometryJobID__c)) {
                    thisJobOrderIdSet = jobsToOrdersMap.get(job.XometryJobID__c);
                }

                for (String orderId : thisJobOrderIdSet) {
                    if (orderTopQualityMap.containsKey(orderId)) {
                        job.Ops_TopQualityCustomer__c = orderTopQualityMap.get(orderId);
                    }
                }
            }
        }
    }
    /**
     * @description updates Sourcing Cases that were accepted before the Job record was created
     * @param jobList list of jobs to be inserted
     */

    public static void updateSourcingCases(List<Job__c> jobList) {
        Map<String, ID> jobIDMap = new Map<String, ID>();

        for (Job__c job : jobList) {
            jobIDMap.put(job.XometryJobID__c, job.ID);
        }

        List<Case> casesToUpdate = new List<Case>();
        for (Case c : [
            SELECT ID, Job__c, AcceptedJobID__c
            FROM Case
            WHERE RecordTypeID = :AppConstants.caseSourcingRTypeId AND AcceptedJobID__c IN :jobIDMap.keySet()
        ]) {
            c.Job__c = jobIDMap.get(c.AcceptedJobID__c);
            casesToUpdate.add(c);
        }

        if (!casesToUpdate.isEmpty()) {
            DatabaseUtilities.saveToDatabase(
                casesToUpdate,
                'JobHandler.updateSourcingCases',
                'Updating sourcing cases with their Accepted Job ID'
            );
        }
    }
}