public with sharing class OrderERPHandler {
    static final String ACCOUNT_CANCELED_DEV_NOTE = 'Accounts not being updated on Order cancellation';
    static final String CANCELED_ORDER_DATE_CHANGE = 'OrderERPHandler.cancelDateOfFirstOrder';
    static final String CONTACT_CANCELED_DEV_NOTE = 'Contacts not being updated on Order cancellation';

    static final String UPDATE_OPP_DEV_NOTE = 'Opportunity Updates post Order Load';
    static final String UPDATE_OPP_METHOD_NAME = 'OrderERPHandler.updateOpp';
    static final String DEFAULT_LINE_OF_BUSINESS = 'Instant Quote';
    static final String INSTANT_QUOTE_LINE_OF_BUSINESS = 'Instant Quote';
    static final String MARKETPLACE_LINE_OF_BUSINESS = 'Marketplace';

    static final String WEST_COAST_METHOD_NAME = 'OrderERPHandler.reassignedWestCoast';

    static final ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer')
        .getRecordTypeID();
    static final ID ordManuSRecordTypeID = Schema.SObjectType.Order_ERP__C.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID ordDefaultRecordTypeID = Schema.SObjectType.Order_ERP__C.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID oppManuSRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID oppDefaultRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID caseGeneralSupportRTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('GeneralSupportCase')
        .getRecordTypeId();

    public static Map<ID, String> eudCaseNeedEmailMap = new Map<ID, String>();
    public static List<Case> eudCaseNeedEmailCaseList = new List<Case>();
    public static List<Quote_ERP__C> existingQuoteList = new List<Quote_ERP__c>();

    /**
     * @description populate the Record Type on Quotes based on the Line of Business Value
     * Assigns the default record type if the recordtype is blank and the Line of Business (LOB) is blank
     * @param inOrderList list of all orders to be inserted
     */
    public static void LOBToRecordTypes(List<Order_ERP__C> inOrderList) {
        for (Order_ERP__C o : inOrderList) {
            if (
                o.Line_of_Business__c == MARKETPLACE_LINE_OF_BUSINESS ||
                o.Line_of_Business__c == INSTANT_QUOTE_LINE_OF_BUSINESS
            ) {
                o.RecordtypeID = ordManuSRecordTypeID;
            } else if (String.isblank(o.Line_of_Business__c)) {
                //Use the default variables.
                o.Line_of_Business__c = DEFAULT_LINE_OF_BUSINESS;
                o.RecordtypeID = ordDefaultRecordTypeID;
            } else {
                o.RecordtypeID = ordDefaultRecordTypeID;
            }
        }
    }
    /**
     * @description calls functions to update associated objects when an order is canceled
     * @param inOrderList list of all orders which have been updated
     * @param inOrderOldMap map of how orders where before the update
     */
    public static void orderCanceledChange(List<Order_ERP__C> inOrderList, Map<ID, Order_ERP__C> inOrderOldMap) {
        closeOpps(inOrderList, inOrderOldMap);
        cancelDateOfOrder(inOrderList);
    }

    /**
     * @description reassigns associated order information
     * @param newOrderERPList a list of new quotes to be inserted
     */
    public static void reassignWestCoast(List<Order_ERP__C> newOrderERPList) {
        Set<ID> associatedAccountSet = new Set<ID>();
        Set<ID> associatedContactsSet = new Set<ID>();
        Set<ID> associatedOppSet = new Set<ID>();

        Set<Id> orderAccountIds = new Set<Id>();

        for (Order_ERP__c o : newOrderERPList) {
            orderAccountIds.add(o.AccountId__c);
        }

        Map<ID, Account> accountMap = new Map<ID, Account>(
            [
                SELECT ID, BillingState, BillingCountry, ParentId, Parent.BillingState, Parent.BillingCountry
                FROM Account
                WHERE Id IN :orderAccountIds
            ]
        );

        // get the billing address for all ouotes (skip if nonexistant)
        for (Order_ERP__c o : newOrderERPList) {
            // filter down to west coast (CA, OR, WA, NV, AK, HI)
            if (
                coalesceCountry(accountMap.get(o.AccountId__c), o.ERP_Billing_Country__c) == 'United States' &&
                AppConstants.WEST_COAST_STATES.contains(
                    coalesceState(accountMap.get(o.AccountId__c), o.ERP_Billing_State_or_Province__c)
                ) &&
                o.IS_Generic__c == false
            ) {
                // reassign all order to west coast
                // TODO: Round Robin logic for BDRs
                associatedAccountSet.add(o.AccountID__c);
                associatedContactsSet.add(o.ContactID__c);
                associatedOppSet.add(o.OpportunityID__C);
            }
        }

        if (!associatedOppSet.isEmpty() || !associatedContactsSet.isEmpty() || !associatedAccountSet.isEmpty()) {
            // First West Coast BDRs from the public group
            ID westCoastBDR = [
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE GroupID = :AppConstants.WEST_COAST_BDR_GROUP
                LIMIT 1
            ]
            .UserOrGroupId;

            if (!associatedAccountSet.isEmpty()) {
                // reassign account if owned by bdr
                Set<Account> reassignedAccountUpdateSet = new Set<Account>();
                List<Account> reassignedAccountUpdateList = new List<Account>();
                Set<ID> reassignedAccountIDSet = new Set<ID>();

                for (Account a : [
                    SELECT ID, OwnerID, Owner.UserRole.Name
                    FROM Account
                    WHERE Id IN :associatedAccountSet
                ]) {
                    if (a.Owner.UserRole.Name == AppConstants.BDR_NAME) {
                        a.OwnerID = westCoastBDR;
                        reassignedAccountUpdateSet.add(a);
                        reassignedAccountIDSet.add(a.ID);
                    } else {
                        associatedAccountSet.remove(a.ID);
                    }
                }

                reassignedAccountUpdateList.addAll(reassignedAccountUpdateSet);

                if (!reassignedAccountUpdateList.isEmpty()) {
                    DatabaseUtilities.saveToDatabase(
                        reassignedAccountUpdateList,
                        WEST_COAST_METHOD_NAME,
                        AppConstants.WEST_COAST_ACCOUNT_DEV_NOTE
                    );

                    // Enqueued job to swap all contacts that belong to this account to the same owner
                    Id jobId = System.enqueueJob(new westCoastContactFlip(reassignedAccountIDSet, westCoastBDR));
                }
            }

            if (!associatedContactsSet.isEmpty()) {
                // reassign contact if owned by bdr
                Set<Contact> reassignedContactsUpdateSet = new Set<Contact>();
                List<Contact> reassignedContactsUpdateList = new List<Contact>();

                for (Contact c : [
                    SELECT ID, OwnerID, Owner.UserRole.Name
                    FROM Contact
                    WHERE Id IN :associatedContactsSet
                ]) {
                    if (c.Owner.UserRole.Name == AppConstants.BDR_NAME) {
                        c.OwnerID = westCoastBDR;
                        reassignedContactsUpdateSet.add(c);
                    } else {
                        associatedContactsSet.remove(c.ID);
                    }
                }

                reassignedContactsUpdateList.addAll(reassignedContactsUpdateSet);

                if (!reassignedContactsUpdateList.isEmpty()) {
                    DatabaseUtilities.saveToDatabase(
                        reassignedContactsUpdateList,
                        WEST_COAST_METHOD_NAME,
                        AppConstants.WEST_COAST_CONTACT_DEV_NOTE
                    );
                }
            }

            if (!associatedOppSet.isEmpty()) {
                // reassign contact if owned by bdr

                Set<Opportunity> reassignedOppsUpdateSet = new Set<Opportunity>();
                List<Opportunity> reassignedOppsUpdateList = new List<Opportunity>();

                for (Opportunity opp : [
                    SELECT ID, OwnerID, StageName, Owner.UserRole.Name
                    FROM Opportunity
                    WHERE
                        Id IN :associatedOppSet
                        AND StageName NOT IN ('Closed Lost')
                        AND Owner.UserRole.Name = :AppConstants.BDR_NAME
                ]) {
                    opp.OwnerID = westCoastBDR;
                    if (opp.StageName == 'Closed Won') {
                        opp.Commission_Owner_LKP__c = westCoastBDR;
                    }
                    reassignedOppsUpdateSet.add(opp);
                }

                reassignedOppsUpdateList.addAll(reassignedOppsUpdateSet);

                if (!reassignedOppsUpdateList.isEmpty()) {
                    DatabaseUtilities.saveToDatabase(
                        reassignedOppsUpdateList,
                        WEST_COAST_METHOD_NAME,
                        AppConstants.WEST_COAST_CONTACT_DEV_NOTE
                    );
                }
            }

            for (Order_ERP__c o : newOrderERPList) {
                if (associatedAccountSet.contains(o.AccountID__c) && associatedContactsSet.contains(o.ContactID__c)) {
                    o.OwnerID = westCoastBDR;
                }
            }
        }
    }

    /**
     * @description closes opportunities associated with a contact
     * @param inOrderList list of all orders which have been updated
     * @param inOrderOldMap map of how orders where before the update
     */
    public static void closeOpps(List<Order_ERP__C> inOrderList, Map<ID, Order_ERP__C> inOrderOldMap) {
        // Check if an Order was not canceled and now is canceled
        Set<ID> createCancellationSet = new Set<ID>();
        List<Order_ERP__C> inOrderCancellationList = new List<Order_ERP__C>();
        Map<Id, Opportunity> oppCanceledMap = new Map<Id, Opportunity>();
        Set<ID> createReOpenSet = new Set<ID>();
        for (Order_ERP__C o : inOrderList) {
            boolean newCanceled = o.Order_Canceled_Flag__c;
            boolean oldCanceled = inOrderOldMap.get(o.ID).Order_Canceled_Flag__c;
            if (newCanceled == true && oldCanceled == false) {
                Opportunity opp = new Opportunity();
                opp.id = o.OpportunityID__C;
                opp.Stagename = 'Closed Lost';
                opp.Loss_Reason__c = 'Order Cancelled';
                oppCanceledMap.put(opp.Id, opp);
            }
            if (newCanceled == false && oldCanceled == true) {
                Opportunity opp = new Opportunity();
                opp.id = o.OpportunityID__C;
                opp.Stagename = 'Closed Won';
                opp.Name = o.Xometry_Quote_ID__c == o.Xometry_ERP_ID__C
                    ? o.Xometry_ERP_ID__C
                    : o.Xometry_Quote_ID__c + ' | ' + o.Xometry_ERP_ID__C;
                opp.Loss_Reason__c = '';
                opp.CloseDate = o.Order_ERP_CreatedDate__C;
                opp.Order_DateTime__c = o.Order_ERP_Time__c;
                oppCanceledMap.put(opp.Id, opp);
            }
        }

        if (!oppCanceledMap.isEmpty()) {
            // Audit
            System.debug('About to start the Opportunity Updates for Order Cancellations');
            System.debug('The Opportunities to be updated are ' + oppCanceledMap);
            DatabaseUtilities.saveToDatabase(
                oppCanceledMap.values(),
                'OrderERPHandler.orderCanceledFlagUpdates',
                'Opportunity Updates for Cancellations'
            );

            // Opps stage has been switched, now make sure the project stage is correct

            // Get list of canceled Opps in CW Projects
            List<Opportunity> canceledOppsinCwProjectsList = [
                SELECT Id, Project__c, StageName
                FROM Opportunity
                WHERE
                    Id IN :oppCanceledMap.keySet()
                    AND Project__r.Stage__c = 'Closed Won'
                    AND StageName = 'Closed Lost'
            ];

            // Create a set of CW Project Ids for Opps that were just Canceled
            Set<Id> cwProjectsWithCanceledOppSet = new Set<Id>();
            for (Opportunity o : canceledOppsinCwProjectsList) {
                cwProjectsWithCanceledOppSet.add(o.Project__c);
            }

            //Get a set of all project Ids for projects that still have a CW opp
            Set<Id> projectWithCwOppSet = new Set<Id>();
            for (Opportunity opp : [
                SELECT Id, Project__c
                FROM Opportunity
                WHERE
                    Project__c IN :cwProjectsWithCanceledOppSet
                    AND Id NOT IN :oppCanceledMap.keySet()
                    AND StageName = 'Closed Won'
            ]) {
                projectWithCwOppSet.add(opp.Project__c);
            }

            //If a project still has a CW Opp, the stage can remain CW. Otherwise, Project stage needs to change
            List<Project__c> needToChangeProjectStatusList = new List<Project__c>();
            Date todayDate = date.today();

            for (Opportunity opp : canceledOppsinCwProjectsList) {
                if (!projectWithCwOppSet.contains(opp.Project__c)) {
                    Project__c p = new Project__c();
                    p.Id = opp.Project__c;
                    p.Stage__c = 'Closed Lost';
                    p.Close_Date__c = todayDate;
                    needToChangeProjectStatusList.add(p);
                }
            }

            System.debug('About to start the Project Updates for Order Cancelations');
            System.debug('The Projects to be updated are ' + needToChangeProjectStatusList);
            DatabaseUtilities.saveToDatabase(
                needToChangeProjectStatusList,
                'OrderERPHandler.orderCanceledFlagUpdates',
                'Project Updates for Order Cancelations'
            );
        }
    }

    /**
     * @description function to update Accounts and Contacts with their first and last order date when an order is canceled
     * @param modifiedOrders all updated orders from the trigger
     */
    public static void cancelDateOfOrder(List<Order_ERP__C> modifiedOrders) {
        Set<ID> accountIDs = new Set<ID>();
        Set<ID> contactIDs = new Set<ID>();
        for (Order_Erp__c o : modifiedOrders) {
            if (o.Order_Canceled_Flag__c) {
                accountIDs.add(o.AccountID__C);
                contactIDs.add(o.ContactID__C);
            }
        }

        if (!accountIDs.isEmpty()) {
            // Get accounts for orders which have been canceled
            List<Account> accountsWithCancelation = [
                SELECT ID, Date_of_First_Order__c, Date_of_Last_Order__c
                FROM Account
                WHERE ID IN :accountIDs
            ];

            // Get contacts for orders which have been canceled
            List<Contact> contactsWithCancelation = [
                SELECT ID, contact_s_Date_of_First_Order__c, Date_of_Last_Order__c
                FROM Contact
                WHERE ID IN :contactIDs
            ];

            // Get all other non-canceled order information for fetched accounts
            Map<Id, AggregateResult> nonCanceledAccountOrders = new Map<id, AggregateResult>(
                [
                    SELECT
                        AccountID__c Id,
                        Min(Order_ERP_CreatedDate__c) First_Order_Date,
                        Max(Order_ERP_CreatedDate__c) Last_Order_Date
                    FROM Order_Erp__c
                    WHERE
                        AccountID__c IN :accountIDs
                        AND Order_Canceled_Flag__c = FALSE
                        AND AccountID__c != NULL
                        AND Order_ERP_CreatedDate__c != NULL
                    GROUP BY AccountID__c
                ]
            );

            // Get all other non-canceled order information for fetched contacts
            Map<Id, AggregateResult> nonCanceledContactOrders = new Map<id, AggregateResult>(
                [
                    SELECT
                        ContactID__c Id,
                        Min(Order_ERP_CreatedDate__c) First_Order_Date,
                        Max(Order_ERP_CreatedDate__c) Last_Order_Date
                    FROM Order_Erp__c
                    WHERE
                        ContactID__c IN :contactIDs
                        AND Order_Canceled_Flag__c = FALSE
                        AND ContactID__c != NULL
                        AND Order_ERP_CreatedDate__c != NULL
                    GROUP BY ContactID__c
                ]
            );

            // set first and last order dates to null and update them with non-canceled order information
            Set<Account> accountUpdateSet = new Set<Account>();
            for (Account a : accountsWithCancelation) {
                a.Date_of_First_Order__c = null;
                a.Date_of_Last_Order__c = null;
                if (nonCanceledAccountOrders.containsKey(a.ID)) {
                    a.Date_of_First_Order__c = (Date) nonCanceledAccountOrders.get(a.ID).get('First_Order_Date');
                    a.Date_of_Last_Order__c = (Date) nonCanceledAccountOrders.get(a.ID).get('Last_Order_Date');
                }
                accountUpdateSet.add(a);
            }
            List<Account> accountUpdateList = new List<Account>();
            accountUpdateList.addAll(accountUpdateSet);
            DatabaseUtilities.saveToDatabase(accountUpdateList, CANCELED_ORDER_DATE_CHANGE, ACCOUNT_CANCELED_DEV_NOTE);

            Set<Contact> contactUpdateSet = new Set<Contact>();
            for (Contact c : contactsWithCancelation) {
                c.contact_s_Date_of_First_Order__c = null;
                c.Date_of_Last_Order__c = null;
                if (nonCanceledContactOrders.containsKey(c.ID)) {
                    c.contact_s_Date_of_First_Order__c = (Date) nonCanceledContactOrders.get(c.ID)
                        .get('First_Order_Date');
                    c.Date_of_Last_Order__c = (Date) nonCanceledContactOrders.get(c.ID).get('Last_Order_Date');
                }
                contactUpdateSet.add(c);
            }
            list<Contact> contactUpdateList = new List<Contact>();
            contactUpdateList.addAll(contactUpdateSet);
            DatabaseUtilities.saveToDatabase(contactUpdateList, CANCELED_ORDER_DATE_CHANGE, CONTACT_CANCELED_DEV_NOTE);
        }
    }

    /**
     * @description function to update Opportunities associated with an updated Order
     * @param updatedOrders list of orders which have been updated
     * @param oldOrderMap map of orders changed by the update
     */
    public static void updateOpp(List<Order_ERP__C> updatedOrders, Map<ID, Order_ERP__C> oldOrderMap) {
        List<Opportunity> updatedOpps = getOppList(updatedOrders, oldOrderMap);
        DatabaseUtilities.saveToDatabase(updatedOpps, UPDATE_OPP_METHOD_NAME, UPDATE_OPP_DEV_NOTE);
    }

    /**
     * @description Retrieves all Opportunities associated with an Order with updated price field
     * @param updatedOrders List of Order objects updated in Salesforce
     * @param oldOrderMap map of orders changed by the update
     * @return List of updated Opportunities with updated Amount (Price)
     */
    public static List<Opportunity> getOppList(List<Order_ERP__C> updatedOrders, Map<ID, Order_ERP__C> oldOrderMap) {
        // Set of Orders to look up all associated Opportunities, Map of Orders to matching
        Set<String> newOrderSet = new Set<String>();
        Map<String, Order_ERP__C> orderMap = new Map<String, Order_ERP__C>();

        Set<Opportunity> updatedOppSet = new Set<Opportunity>();
        List<Opportunity> oppsUpdateList = new List<Opportunity>();

        for (Order_ERP__C order : updatedOrders) {
            Order_ERP__c oldOrder = oldOrderMap.get(order.ID);
            if (
                // if any amount, status,  or manufacturing values are changed, then add it to the change list

                oldOrder.Order_Total__c != order.Order_Total__c ||
                oldOrder.ERP_Status__c != order.ERP_Status__C ||
                oldOrder.process_isCarbon__c != order.process_isCarbon__c ||
                oldOrder.process_isCNC_Machining__c != order.process_isCNC_Machining__c ||
                oldOrder.process_isDie_Casting__c != order.process_isDie_Casting__c ||
                oldOrder.process_isDirect_Sourced__c != order.process_isDirect_Sourced__c ||
                oldOrder.process_isDMLS__c != order.process_isDMLS__c ||
                oldOrder.process_isExtrusion__c != order.process_isExtrusion__c ||
                oldOrder.process_isFDM__c != order.process_isFDM__c ||
                oldOrder.process_isHPMultJetFusion__c != order.process_isHPMultJetFusion__c ||
                oldOrder.process_isInjection_Molding__c != order.process_isInjection_Molding__c ||
                oldOrder.process_isInjectionMoldingTool__c != order.process_isInjectionMoldingTool__c ||
                oldOrder.process_isPolyJet_3D__c != order.process_isPolyJet_3D__c ||
                oldOrder.process_isPlasticExtrusion__c != order.process_isPlasticExtrusion__c ||
                oldOrder.process_isSheet_metal__c != order.process_isSheet_metal__c ||
                oldOrder.process_isSLA__c != order.process_isSLA__c ||
                oldOrder.process_isSLS__c != order.process_isSLS__c ||
                oldOrder.process_isStamping__c != order.process_isStamping__c ||
                oldOrder.process_isUrethane_Casting__c != order.process_isUrethane_Casting__c ||
                oldOrder.process_isBinderJetting__c != order.process_isBinderJetting__c ||
                oldOrder.process_isSheetCutting__c != order.process_isSheetCutting__c ||
                oldOrder.process_isTubeBending__c != order.process_isTubeBending__c ||
                oldOrder.process_isTubeCutting__c != order.process_isTubeCutting__c ||
                oldOrder.process_isOther__c != order.process_isOther__c ||
                oldOrder.process_isOther_NotIncluded__c != order.process_isOther_NotIncluded__c ||
                oldOrder.process_isLSPc__c != order.process_isLSPc__c ||
                oldOrder.process_isAssembly__c != order.process_isAssembly__c ||
                oldOrder.Quote_Type__c != order.Quote_Type__c ||
                oldOrder.ITAR__c != order.ITAR__c ||
                oldOrder.Hardware_Cert__c != order.Hardware_Cert__c ||
                oldOrder.Conformance_Cert__c != order.Conformance_Cert__c ||
                oldOrder.Material_Traceability_Cert__c != order.Material_Traceability_Cert__c ||
                oldOrder.Material_Cert__c != order.Material_Cert__c ||
                oldOrder.LineItemCount__c != order.LineItemCount__c ||
                oldOrder.Payment_Type__c != order.Payment_Type__c ||
                oldOrder.Manual_Quote_Prioritization_Score__c != order.Manual_Quote_Prioritization_Score__c
            ) {
                newOrderSet.add(order.Xometry_ERP_ID__C);
                orderMap.put(order.Xometry_ERP_ID__C, order);
            }
        }

        if (!newOrderset.isEmpty()) {
            List<Opportunity> oppFetchList = [
                SELECT ID, Order_ERP_Xom_ID__c, Amount
                FROM Opportunity
                WHERE Order_ERP_Xom_ID__c IN :newOrderset
            ];

            for (Opportunity opp : oppFetchList) {
                if (orderMap.containsKey(opp.Order_ERP_Xom_ID__c)) {
                    Order_ERP__c o = orderMap.get(opp.Order_ERP_Xom_ID__c);
                    opp.Amount = o.Order_Total__c;
                    opp.ERP_Status__c = o.ERP_Status__c;
                    opp.has_ordered_Carbon__c = o.process_isCarbon__c;
                    opp.has_ordered_CNC_Machining__c = o.process_isCNC_Machining__c;
                    opp.has_ordered_Die_Casting__c = o.process_isDie_Casting__c;
                    opp.has_ordered_Direct_Sourced__c = o.process_isDirect_Sourced__c;
                    opp.has_ordered_DMLS__c = o.process_isDMLS__c;
                    opp.has_ordered_Extrusion__c = o.process_isExtrusion__c;
                    opp.has_ordered_FDM__c = o.process_isFDM__c;
                    opp.has_ordered_HPMultiJetFusion__c = o.process_isHPMultJetFusion__c;
                    opp.has_ordered_Injection_Molding__c = o.process_isInjection_Molding__c;
                    opp.has_ordered_Injection_Molding_Tool__c = o.process_isInjectionMoldingTool__c;
                    opp.has_ordered_PolyJet_3D__c = o.process_isPolyJet_3D__c;
                    opp.has_ordered_PlasticExtrusion__c = o.process_isPlasticExtrusion__c;
                    opp.has_ordered_Sheet_metal__c = o.process_isSheet_metal__c;
                    opp.has_ordered_SLA__c = o.process_isSLA__c;
                    opp.has_ordered_SLS__c = o.process_isSLS__c;
                    opp.has_ordered_Stamping__c = o.process_isStamping__c;
                    opp.has_ordered_Urethane_Casting__c = o.process_isUrethane_Casting__c;
                    opp.has_ordered_BinderJetting__c = o.process_isBinderJetting__c;
                    opp.has_ordered_SheetCutting__c = o.process_isSheetCutting__c;
                    opp.has_ordered_TubeBending__c = o.process_isTubeBending__c;
                    opp.has_ordered_TubeCutting__c = o.process_isTubeCutting__c;
                    opp.has_ordered_Other__c = o.process_isOther__c;
                    opp.has_ordered_Other_NotIncluded__c = o.process_isOther_NotIncluded__c;
                    opp.has_ordered_LSPc__c = o.process_isLSPc__c;
                    opp.has_ordered_Assembly__c = o.process_isAssembly__c;
                    opp.most_recent_quote_Carbon__c = o.process_isCarbon__c;
                    opp.most_recent_quote_CNC_Machining__c = o.process_isCNC_Machining__c;
                    opp.most_recent_quote_Die_Casting__c = o.process_isDie_Casting__c;
                    opp.most_recent_quote_Direct_Sourced__c = o.process_isDirect_Sourced__c;
                    opp.most_recent_quote_DMLS__c = o.process_isDMLS__c;
                    opp.most_recent_quote_Extrusion__c = o.process_isExtrusion__c;
                    opp.most_recent_quote_FDM__c = o.process_isFDM__c;
                    opp.most_recent_quote_HPMultiJetFusion__c = o.process_isHPMultJetFusion__c;
                    opp.most_recent_quote_Injection_Molding__c = o.process_isInjection_Molding__c;
                    opp.Most_Recent_Quote_Injection_Molding_Tool__c = o.process_isInjectionMoldingTool__c;
                    opp.Most_Recent_Quote_PolyJet_3D__c = o.process_isPolyJet_3D__c;
                    opp.Most_Recent_Quote_PlasticExtrusion__c = o.process_isPlasticExtrusion__c;
                    opp.most_recent_quote_Sheet_metal__c = o.process_isSheet_metal__c;
                    opp.Most_Recent_Quote_SLA__c = o.process_isSLA__c;
                    opp.most_recent_quote_SLS__c = o.process_isSLS__c;
                    opp.most_recent_quote_Stamping__c = o.process_isStamping__c;
                    opp.most_recent_quote_Urethane_Casting__c = o.process_isUrethane_Casting__c;
                    opp.most_recent_quote_BinderJetting__c = o.process_isBinderJetting__c;
                    opp.most_recent_quote_SheetCutting__c = o.process_isSheetCutting__c;
                    opp.most_recent_quote_TubeBending__c = o.process_isTubeBending__c;
                    opp.most_recent_quote_TubeCutting__c = o.process_isTubeCutting__c;
                    opp.most_recent_quote_Other__c = o.process_isOther__c;
                    opp.most_recent_quote_Other_NotIncluded__c = o.process_isOther_NotIncluded__c;
                    opp.most_recent_quote_LSPc__c = o.process_isLSPc__c;
                    opp.most_recent_quote_Assembly__c = o.process_isAssembly__c;
                    opp.Total_Amt_Carbon__c = o.Ordered_Total_Amt_Carbon__c;
                    opp.Total_Amt_CNC__c = o.Ordered_Total_Amt_CNC__c;
                    opp.Total_Amt_DieCasting__c = o.Ordered_Total_Amt_DieCasting__c;
                    opp.Total_Amt_DirectSourced__c = o.Ordered_Total_Amt_DirectSourced__c;
                    opp.Total_Amt_DMLS__c = o.Ordered_Total_Amt_DMLS__c;
                    opp.Total_Amt_Extrusion__c = o.Ordered_Total_Amt_Extrusion__c;
                    opp.Total_Amt_FDM__c = o.Ordered_Total_Amt_FDM__c;
                    opp.Total_Amt_HPMultJetFusion__c = o.Ordered_Total_Amt_HPMulJetFusion__c;
                    opp.Total_Amt_InjectionMolding__c = o.Ordered_Total_Amt_InjectionMolding__c;
                    opp.Total_Amt_InjectionMoldingTool__c = o.Ordered_Total_Amt_InjectionMoldingTool__c;
                    opp.Total_Amt_PolyJet3D__c = o.Ordered_Total_Amt_PolyJet3D__c;
                    opp.Total_Amt_PlasticExtrusion__c = o.Ordered_Total_Amt_PlasticExtrusion__c;
                    opp.Total_Amt_SheetMetal__c = o.Ordered_Total_Amt_SheetMetal__c;
                    opp.Total_Amt_SLA__c = o.Ordered_Total_Amt_SLA__c;
                    opp.Total_Amt_SLS__c = o.Ordered_Total_Amt_SLS__c;
                    opp.Total_Amt_Stamping__c = o.Ordered_Total_Amt_Stamping__c;
                    opp.Total_Amt_UrethaneCasting__c = o.Ordered_Total_Amt_UrethaneCasting__c;
                    opp.Total_Amt_BinderJetting__c = o.Ordered_Total_Amt_BinderJetting__c;
                    opp.Total_Amt_SheetCutting__c = o.Ordered_Total_Amt_SheetCutting__c;
                    opp.Total_Amt_Tube_Bending__c = o.Ordered_Total_Amt_Tube_Bending__c;
                    opp.Total_Amt_Tube_Cutting__c = o.Ordered_Total_Amt_Tube_Cutting__c;
                    opp.Total_Amt_Other__c = o.Ordered_Total_Amt_Other__c;
                    opp.Total_Amt_Other_NotIncluded__c = o.Ordered_Total_Amt_Other_NotIncluded__c;
                    opp.Total_Amt_LSPc__c = o.Ordered_Total_Amt_LSPc__c;
                    opp.Total_Amt_Assembly__c = o.Ordered_Total_Amt_Assembly__c;
                    opp.Total_Qty_Carbon__c = o.Ordered_Total_Qty_Carbon__c;
                    opp.Total_Qty_CNC__c = o.Ordered_Total_Qty_CNC__c;
                    opp.Total_Qty_DieCasting__c = o.Ordered_Total_Qty_DieCasting__c;
                    opp.Total_Qty_DirectSourced__c = o.Ordered_Total_Qty_DirectSourced__c;
                    opp.Total_Qty_DMLS__c = o.Ordered_Total_Qty_DMLS__c;
                    opp.Total_Qty_Extrusion__c = o.Ordered_Total_Qty_Extrusion__c;
                    opp.Total_Qty_FDM__c = o.Ordered_Total_Qty_FDM__c;
                    opp.Total_Qty_HPMultJetFusion__c = o.Ordered_Total_Qty_HPMultJetFusion__c;
                    opp.Total_Qty_InjectionMolding__c = o.Ordered_Total_Qty_InjectionMolding__c;
                    opp.Total_Qty_InjectionMoldingTool__c = o.Ordered_Total_Qty_InjectionMoldingTool__c;
                    opp.Total_Qty_PolyJet3D__c = o.Ordered_Total_Qty_PolyJet3D__c;
                    opp.Total_Qty_PlasticExtrusion__c = o.Ordered_Total_Qty_PlasticExtrusion__c;
                    opp.Total_Qty_SheetMetal__c = o.Ordered_Total_Qty_SheetMetal__c;
                    opp.Total_Qty_SLA__c = o.Ordered_Total_Qty_SLA__c;
                    opp.Total_Qty_SLS__c = o.Ordered_Total_Qty_SLS__c;
                    opp.Total_Qty_Stamping__c = o.Ordered_Total_Qty_Stamping__c;
                    opp.Total_Qty_UrethaneCasting__c = o.Ordered_Total_Qty_UrethaneCasting__c;
                    opp.Total_Qty_BinderJetting__c = o.Ordered_Total_Qty_BinderJetting__c;
                    opp.Total_Qty_SheetCutting__c = o.Ordered_Total_Qty_SheetCutting__c;
                    opp.Total_Qty_Tube_Bending__c = o.Ordered_Total_Qty_Tube_Bending__c;
                    opp.Total_Qty_Tube_Cutting__c = o.Ordered_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Other__c = o.Ordered_Total_Qty_Other__c;
                    opp.Total_Qty_Other_NotIncluded__c = o.Ordered_Total_Qty_Other_NotIncluded__c;
                    opp.Total_Qty_LSPc__c = o.Ordered_Total_Qty_LSPc__c;
                    opp.Total_Qty_Assembly__c = o.Ordered_Total_Qty_Assembly__c;
                    opp.Quote_Type__c = o.Quote_Type__c;
                    opp.ITAR__c = o.ITAR__c;
                    opp.Hardware_Cert__c = o.Hardware_Cert__c;
                    opp.Conformance_Cert__c = o.Conformance_Cert__c;
                    opp.Material_Traceability_Cert__c = o.Material_Traceability_Cert__c;
                    opp.Material_Cert__c = o.Material_Cert__c;
                    opp.LineItemCount__c = o.LineItemCount__c;
                    opp.Manual_Quote_Prioritization_Score__c = o.Manual_Quote_Prioritization_Score__c;
                    Opp.Pending_Payment_Type__c = OpportunityHandler.setPaymentType(o.Payment_Type__c);
                    updatedOppSet.add(opp);
                }
            }

            oppsUpdateList.addAll(updatedOppSet);
        }

        return oppsUpdateList;
    }

    /**
     * @description Populates the date of first order
     * @param inOrdersProcessed List of Order objects inserted
     * @param accountList List of Accounts objects to be updated
     * @param contactList List of Contacts objects to be updated
     */

    public static Set<Id> OrderDateofFirstOrderPop(
        List<Order_ERP__C> inOrdersProcessed,
        List<Account> accountList,
        List<Contact> contactList
    ) {
        // The purpose of this method is to update Accounts and Contacts with their first order date

        Map<Id, Order_ERP__C> accountIDFirstOrderMap = new Map<Id, Order_ERP__C>();
        Map<Id, Order_ERP__C> contactIDFirstOrderMap = new Map<Id, Order_ERP__C>();
        Map<Id, Order_ERP__C> accountIDLastOrderMap = new Map<Id, Order_ERP__C>();
        Map<Id, Order_ERP__C> contactIDLastOrderMap = new Map<Id, Order_ERP__C>();

        Set<Id> retMarkedIdSet = new Set<Id>();

        // Create seperate Map
        for (Order_ERP__C o : inOrdersProcessed) {
            if (!accountIDFirstOrderMap.containsKey(o.accountID__C)) {
                accountIDFirstOrderMap.put(o.AccountID__C, o);
            } else {
                if (o.Order_ERP_CreatedDate__C < accountIDFirstOrderMap.get(o.accountID__C).Order_ERP_CreatedDate__C) {
                    accountIDFirstOrderMap.put(o.AccountID__C, o);
                }
            }
            if (!contactIDFirstOrderMap.containsKey(o.contactID__C)) {
                contactIDFirstOrderMap.put(o.contactID__C, o);
            } else {
                if (o.Order_ERP_CreatedDate__C < contactIDFirstOrderMap.get(o.contactID__C).Order_ERP_CreatedDate__C) {
                    contactIDFirstOrderMap.put(o.contactID__C, o);
                }
            }
            if (!accountIDLastOrderMap.containsKey(o.AccountID__C)) {
                accountIDLastOrderMap.put(o.AccountID__C, o);
            } else {
                if (o.Order_ERP_CreatedDate__C > accountIDLastOrderMap.get(o.AccountID__C).Order_ERP_CreatedDate__C) {
                    accountIDLastOrderMap.put(o.AccountID__C, o);
                }
            }
            if (!contactIDLastOrderMap.containsKey(o.ContactID__C)) {
                contactIDLastOrderMap.put(o.ContactID__C, o);
            } else {
                if (o.Order_ERP_CreatedDate__C > contactIDLastOrderMap.get(o.ContactID__C).Order_ERP_CreatedDate__C) {
                    contactIDLastOrderMap.put(o.ContactID__C, o);
                }
            }
        }

        for (account a : accountList) {
            if (accountIDFirstOrderMap.containsKey(a.id)) {
                if (
                    (a.Date_of_First_Order__c > accountIDFirstOrderMap.get(a.id).Order_ERP_CreatedDate__c) ||
                    a.Date_of_First_Order__c == null
                ) {
                    a.Date_of_First_Order__c = accountIDFirstOrderMap.get(a.id).Order_ERP_CreatedDate__c;
                    retMarkedIdSet.add(a.Id);
                }
            }
            if (accountIDLastOrderMap.containsKey(a.id)) {
                if (
                    (a.Date_of_Last_Order__c < accountIDLastOrderMap.get(a.id).Order_ERP_CreatedDate__c) ||
                    a.Date_of_Last_Order__c == null
                ) {
                    a.Date_of_Last_Order__c = accountIDLastOrderMap.get(a.id).Order_ERP_CreatedDate__c;
                    retMarkedIdSet.add(a.Id);
                }
            }
        }

        // Contact Updates
        for (contact c : contactList) {
            // Date of First Order Check
            if (contactIDFirstOrderMap.containsKey(c.id)) {
                if (
                    (c.contact_s_Date_of_First_Order__c > contactIDFirstOrderMap.get(c.id).Order_ERP_CreatedDate__c) ||
                    c.contact_s_Date_of_First_Order__c == null
                ) {
                    c.contact_s_Date_of_First_Order__c = contactIDFirstOrderMap.get(c.id).Order_ERP_CreatedDate__c;
                    retMarkedIdSet.add(c.Id);
                }
                // Date of Last Order Check
                if (contactIDLastOrderMap.containsKey(c.id)) {
                    if (
                        (c.Date_of_Last_Order__c < contactIDLastOrderMap.get(c.id).Order_ERP_CreatedDate__C) ||
                        c.Date_of_Last_Order__c == null
                    ) {
                        c.Date_of_Last_Order__c = contactIDLastOrderMap.get(c.id).Order_ERP_CreatedDate__C;
                        retMarkedIdSet.add(c.Id);
                    }
                }
                c.Has_Ordered__c = true;
            }
        }

        return retMarkedIdSet;
    }

    /**
     * @description Populates the date of first order
     * @param inOrdersProcessed List of Order objects inserted
     */
    public static void OrderToQuoteCleanUp(List<Order_ERP__C> inOrdersProcessed) {
        // The purpose of this method is to update Quotes that have orders placed and grab the orders opportunity/account/contact to close the loop.
        Set<String> quoteXomIDSet = new Set<String>();
        Map<String, Order_ERP__C> quoteIDToOrdersMap = new Map<String, Order_ERP__C>();
        for (Order_ERP__C o : inOrdersProcessed) {
            quoteXomIDSet.add(o.Xometry_Quote_ID__c);
            quoteIDToOrdersMap.put(o.Xometry_Quote_ID__c, o);
        }

        List<Quote_ERP__C> existingQuotesFetched = new List<Quote_ERP__C>();
        for (Quote_ERP__C q : existingQuoteList) {
            if (quoteIDToOrdersMap.containsKey(q.Xometry_ERP_ID__C)) {
                q.OrderERPSFID__C = quoteIDToOrdersMap.get(q.Xometry_ERP_ID__C).Id;
                q.OpportunityID__C = quoteIDToOrdersMap.get(q.Xometry_ERP_ID__C).OpportunityID__C;
                q.OwnerID = quoteIDToOrdersMap.get(q.Xometry_ERP_ID__C).OwnerID;
                existingQuotesFetched.add(q);
            }
        }

        DatabaseUtilities.saveToDatabase(
            existingQuotesFetched,
            'OrderERPHandler.OrderToQuoteCleanUp',
            'Quote Updates post Orders'
        );
    }

    /**
     * @description bulk of processing for ERP Orders
     * @param newOrdersERPList List of Order objects to be inserted (before trigger)
     */
    public static void processERPOrders2(list<Order_ERP__C> newOrdersERPList) {
        // For Orders assign initial Quote information to the order before further logic
        // If the Quote exists assign quote's owner to Order

        // Initial Set for Order Information
        // for existing Quotes
        Set<String> orderXomERPIDSet = new Set<String>();
        Set<String> quoteXomERPIDSet = new Set<String>();
        Map<String, String> quoteIDToOrderIDMap = new Map<String, String>();
        // for existing Accounts
        set<string> orderXomAccountDomain = new Set<string>();
        // for existing contacts
        set<string> orderXomeEmailSET = new Set<string>();

        set<string> orderXomCompanyNameSET = new Set<string>();
        Set<String> orderXomPartnerIdSet = new Set<String>();

        MAP<String, Quote_ERP__C> existingQuoteMap = new Map<String, Quote_ERP__C>();
        List<DUNSData> newQuoteDunsData = new List<DUNSData>();

        // for existing Opportunities
        for (Order_ERP__C o : newOrdersERPList) {
            orderXomERPIDSET.add(o.Xometry_ERP_ID__c);
            quoteXomERPIDSet.add(o.Xometry_Quote_ID__c);
            quoteIDToOrderIDMap.put(o.Xometry_Quote_ID__c, o.Xometry_ERP_ID__c);

            if (o.Account_Domain__C != null) {
                orderXomAccountDomain.add(o.Account_Domain__C);
            }
            if (o.Order_Email__C != null) {
                orderXomeEmailSET.add(o.Order_Email__C);
            }
            if (!String.isBlank(o.ERP_Company_Name__c)) {
                orderXomCompanyNameSET.add(o.ERP_Company_Name__c);
            }
            if (!String.isBlank(o.MKP_PartnerId__c)) {
                orderXomPartnerIdSet.add(o.MKP_PartnerId__c);
            }
            if (
                !String.isBlank(o.UserDUNSNumber__c) ||
                !String.isBlank(o.UserParentDUNSNumber__c) ||
                !String.isBlank(o.UserUltimateDUNSNumber__c)
            ) {
                DUNSData duns = new DUNSData();
                duns.userDUNSNumber = o.UserDUNSNumber__c;
                duns.userParentDUNSNumber = o.UserParentDUNSNumber__c;
                duns.userUltimateDUNSNumber = o.UserUltimateDUNSNumber__c;
                duns.domain = o.Account_Domain__c;
                duns.sourceId = o.Xometry_ERP_ID__c;
                duns.accountId = null;
                duns.ownerId = null;
                newQuoteDunsData.add(duns);
            }

            if (o.OwnerID == AppConstants.API_USER) {
                o.OwnerID = AppConstants.SALES_API_USER;
            }
        }

        syncIDsOnRelatedObjects(quoteIDToOrderIDMap);

        // Create Quotes for Orders where Orders do not exist. When an Order happens in timespan before a quote

        existingQuoteList = [SELECT
                Xometry_ERP_ID__C,
                Xometry_Order_ID__c,
                AccountID__C,
                AccountID__R.Account_Owner_Type__c,
                ContactID__C,
                ContactID__R.OwnerID,
                OwnerID,
                OpportunityID__C,
                OpportunityID__R.StageName,
                OpportunityID__R.Closed_By_System_Order__c,
                LeadID__C,
                LeadID__R.IsConverted,
                LeadID__R.OwnerID
            FROM Quote_ERP__C
            WHERE Xometry_ERP_ID__C IN :quoteXomERPIDSet];
        
        for ( Quote_ERP__C q : existingQuoteList ){
            existingQuoteMap.put(q.Xometry_ERP_ID__C, q);
        }
        // For Orders assign initial Quote information to the order before further logic
        // If the Quote exists assign quote's owner to Order
        for (Order_ERP__C o : newOrdersERPList) {
            if (existingQuoteMap.containskey(o.Xometry_Quote_ID__c)) {
                Quote_ERP__C q = existingQuoteMap.get(o.Xometry_Quote_ID__c);
                o.AccountID__C = q.AccountID__C;
                //Use the Contacts Owner for Owner Assignment
                if (!String.isblank(q.ContactID__R.OwnerID)) {
                    o.OwnerID = q.ContactID__R.OwnerID;
                } else if (String.isblank(q.LeadID__R.OwnerID)) {
                    o.OwnerID = q.OwnerID;
                } else {
                    o.OwnerID = q.LeadID__R.OwnerID;
                }
                o.ContactID__C = q.ContactID__C;
                if (
                    q.OpportunityID__R.StageName != 'Closed Won' &&
                    q.OpportunityID__R.Closed_By_System_Order__c == false
                ) {
                    o.OpportunityID__C = q.OpportunityID__C;
                }
                o.LeadID__C = q.LeadID__C;
            }
        }

        Map<String, Supplier__c> supplierMap = SupplierUtility.fetchSuppliers(orderXomPartnerIdSet);

        // Check if Account exists with the account domain or if Contact Exist
        Map<String, Account> existingAccountWithDomainMap = new Map<String, Account>();

        // Check if Account Name Exists already for future if company Name Exists  then will use domain email
        Set<String> accountNameSet = new Set<String>();

        if (!orderXomAccountDomain.isEmpty() || !orderXomCompanyNameSET.isEmpty()) {
            // Check if Account exists with the account domain or if Contact Exist
            for (Account a : [
                SELECT Id, Name, Account_Owner_Type__c, OwnerID, Email_Domain__c
                FROM Account
                WHERE Email_Domain__c IN :orderXomAccountDomain OR Name IN :orderXomCompanyNameSET
                ORDER BY Name
            ]) {
                if (orderXomAccountDomain.contains(a.Email_Domain__c)) {
                    existingAccountWithDomainMap.put(a.Email_Domain__c, a);
                }

                if (orderXomCompanyNameSET.contains(a.Name)) {
                    accountNameSet.add(a.Name.toUpperCase());
                }
            }
        }

        Map<String, Contact> existingcontactMap = new Map<String, Contact>();
        if (!orderXomeEmailSET.isEmpty()) {
            // Check if Contacts exists with the primary contact
            for (Contact c : [
                SELECT ID, AccountID, OwnerID, Primary_Email__C, GNO_PartnerID__c
                FROM Contact
                WHERE Primary_Email__C IN :orderXomeEmailSET
            ]) {
                existingcontactMap.put(c.Primary_Email__C, c);
            }
        }

        Map<String, DUNSData> mappedDunsAccounts = new Map<String, DUNSData>();
        if (!newQuoteDunsData.isEmpty()) {
            mappedDunsAccounts = AccountDunsHelper.DunsAccountRouting(newQuoteDunsData);
        }

        Set<Account> createNewAccountSet = new Set<Account>();
        Set<String> BDRGenericRRSETDomain = new Set<String>();
        Set<String> BDRNoGenericRRSETDomain = new Set<String>();
        List<Account> createNewAccountsList = new List<Account>();
        List<Contact> createNewContactsList = new List<Contact>();

        List<Order_ERP__C> ordersNeedNewAccountList = new List<Order_ERP__C>();
        // Check if the domain exists as an account or the contact exists if not make an account
        for (Order_ERP__C o : newOrdersERPList) {
            if (
                supplierMap.containsKey(o.MKP_PartnerId__c) &&
                !String.isBlank(supplierMap.get(o.MKP_PartnerID__c).AccountID__c)
            ) {
                o.AccountID__c = supplierMap.get(o.MKP_PartnerId__c).AccountId__c;
                o.OwnerId = supplierMap.get(o.MKP_PartnerId__c).AccountId__r.OwnerId;
            } else if (
                !existingcontactMap.containskey(o.Order_Email__C) &&
                !existingAccountWithDomainMap.containskey(o.Account_Domain__c) &&
                !mappedDunsAccounts.containsKey(o.Xometry_ERP_ID__c)
            ) {
                ordersNeedNewAccountList.add(o);
                Account newAccount = new Account();
                // Address Fields
                newAccount.ERP_Billing_Address__c = o.ERP_Billing_Address__c;
                newAccount.ERP_Billing_City__c = o.ERP_Billing_City__c;
                newAccount.ERP_Billing_Country__c = o.ERP_Billing_Country__c;
                newAccount.ERP_Billing_State_or_Province__c = o.ERP_Billing_State_or_Province__c;
                newAccount.ERP_Billing_Zip_Code__c = o.ERP_Billing_Zip_Code__c;
                newAccount.ERP_Shipping_Address__c = o.ERP_Shipping_Address__c;
                newAccount.ERP_Shipping_City__c = o.ERP_Shipping_City__c;
                newAccount.ERP_Shipping_Country__c = o.ERP_Shipping_Country__c;
                newAccount.ERP_Shipping_State_or_Province__c = o.ERP_Shipping_State_or_Province__c;
                newAccount.ERP_Shipping_Zip_Code__c = o.ERP_Shipping_Zip_Code__c;
                newAccount.RecordtypeID = accountCustomerRecordTypeID;
                // Generic Account
                if (o.Is_Generic__C == true) {
                    if (String.isBlank(o.ERP_Company_Name__c)) {
                        newAccount.name = o.Order_Email__C;
                    } else {
                        // Check if name is in existence if it is use domain
                        if (!accountNameSet.contains(o.ERP_Company_Name__c.toUpperCase())) {
                            newAccount.name = o.ERP_Company_Name__c;
                        } else {
                            newAccount.name = o.Order_Email__C;
                        }
                    }
                    newAccount.Email_Domain__c = o.Account_Domain__c;
                    if (!existingQuoteMap.containskey(o.Xometry_Quote_ID__c)) {
                        // Needs Generic RR
                        BDRGenericRRSETDomain.add(o.Account_Domain__C);
                        newAccount.Account_Owner_Type__c = AppConstants.BDR_NAME;
                    } else {
                        newAccount.OwnerID = o.OwnerID;
                        // Check if new Account belongs to AM or RR
                        if (existingQuoteMap.containskey(o.Xometry_Quote_ID__c)) {
                            if (
                                !String.isblank(
                                    existingQuoteMap.get(o.Xometry_Quote_ID__c).AccountID__R.Account_Owner_Type__c
                                )
                            ) {
                                newAccount.Account_Owner_Type__c = existingQuoteMap.get(o.Xometry_Quote_ID__c)
                                    .AccountID__R.Account_Owner_Type__c;
                            } else {
                                newAccount.Account_Owner_Type__c = AppConstants.BDR_NAME;
                            }
                        } else {
                            newAccount.Account_Owner_Type__c = AppConstants.BDR_NAME;
                        }
                    }
                    newAccount.generic_account__c = true;
                    createNewAccountSet.add(newAccount);
                } else {
                    if (String.isBlank(o.ERP_Company_Name__c)) {
                        newAccount.name = o.Account_Domain__C;
                    } else {
                        // Check if name is in existence if it is use domain
                        if (!accountNameSet.contains(o.ERP_Company_Name__c.toUpperCase())) {
                            newAccount.name = o.ERP_Company_Name__c;
                        } else {
                            newAccount.name = o.Account_Domain__C;
                        }
                    }
                    newAccount.Email_Domain__c = o.Account_Domain__C;
                    if (!existingQuoteMap.containskey(o.Xometry_Quote_ID__c)) {
                        // Needs NonGeneric RR
                        BDRNoGenericRRSETDomain.add(o.Account_Domain__C);
                    } else {
                        newAccount.OwnerID = o.OwnerID;
                        // Check if new Account belongs to AM or RR
                        if (existingQuoteMap.containskey(o.Xometry_Quote_ID__c)) {
                            if (
                                !String.isblank(
                                    existingQuoteMap.get(o.Xometry_Quote_ID__c).AccountID__R.Account_Owner_Type__c
                                )
                            ) {
                                newAccount.Account_Owner_Type__c = existingQuoteMap.get(o.Xometry_Quote_ID__c)
                                    .AccountID__R.Account_Owner_Type__c;
                            } else {
                                newAccount.Account_Owner_Type__c = AppConstants.BDR_NAME;
                            }
                        } else {
                            newAccount.Account_Owner_Type__c = AppConstants.BDR_NAME;
                        }
                    }
                    createNewAccountSet.add(newAccount);
                }
            } else {
                if (mappedDunsAccounts.containsKey(o.Xometry_ERP_ID__c)) {
                    o.AccountID__c = mappedDunsAccounts.get(o.Xometry_ERP_ID__c).accountId;
                    o.OwnerID = mappedDunsAccounts.get(o.Xometry_ERP_ID__c).ownerId;
                } else if (existingAccountWithDomainMap.containskey(o.Account_Domain__c)) {
                    o.AccountID__C = existingAccountWithDomainMap.get(o.Account_Domain__C).ID;
                    o.OwnerID = existingAccountWithDomainMap.get(o.Account_Domain__C).OwnerID;
                }
            }
        }

        // Do Not Allow a duplicate set of account domains
        // loop through the set and limit based on map of domains then extract out the values.
        Map<String, Account> newAccountDomainMap = new Map<String, Account>();
        for (Account a : createNewAccountSet) {
            if (!newAccountDomainMap.containsKey(a.Email_Domain__C)) {
                newAccountDomainMap.put(a.Email_Domain__C, a);
            }
            // Don't create duplicate account based on email domain
        }

        createNewAccountsList.addAll(newAccountDomainMap.values());
        List<Account> createdAccountsList = new List<Account>();
        SET<ID> createdAccountIDs = new Set<ID>();

        // Create Account

        DatabaseUtilities.insertToDatabase(createNewAccountsList, 'OrderERPHandler', 'New Account Inserts');

        // Create a Map of domain to the CreatedList where ID is populated

        Map<String, Account> createNewAccountsDomainMap = new Map<String, Account>();
        // Only RR successes
        if (!createNewAccountsList.isEmpty()) {
            for (Account a : createNewAccountsList) {
                if (a.ID != null) {
                    createNewAccountsDomainMap.put(a.Email_Domain__C, a);
                }
            }
        }

        if (ApexBypassUtility.shouldRun('OrderERPHandler_account_round_robin')) {
            Set<ID> createdAccountNonGenericRRIDs = new Set<ID>();
            Set<ID> createdAccountGenericRRIDs = new Set<ID>();

            for (String s : BDRNoGenericRRSETDomain) {
                if (createNewAccountsDomainMap.containskey(s)) {
                    createdAccountNonGenericRRIDs.add(createNewAccountsDomainMap.get(s).ID);
                }
            }

            if (createdAccountNonGenericRRIDs.size() > 0) {
                roundRobinDist.account_round_robin_NonGeneric_BDR(createdAccountNonGenericRRIDs);
            }

            for (String s : BDRGenericRRSETDomain) {
                if (createNewAccountsDomainMap.containskey(s)) {
                    createdAccountGenericRRIDs.add(createNewAccountsDomainMap.get(s).ID);
                }
            }

            if (createdAccountGenericRRIDs.size() > 0) {
                roundRobinDist.account_round_robin_Generic_BDR(createdAccountGenericRRIDs);
            }
        }

        // All Accounts are Created. Run Query to get full information now.

        Set<ID> accountIdSet = new Set<ID>();
        for (Order_ERP__C o : newOrdersERPList) {
            if (o.AccountID__c != null) {
                accountIdSet.add(o.AccountID__c);
            }
        }

        Map<String, Account> allAccountDomainMap = new Map<String, Account>();

        Map<Id, Account> updateAllAccountMap = new Map<Id, Account>();

        if (!orderXomAccountDomain.isEmpty() || !accountIdSet.isEmpty()) {
            for (Account a : [
                SELECT
                    ID,
                    Email_Domain__c,
                    ERP_Billing_Address__c,
                    ERP_Billing_City__c,
                    ERP_Billing_Country__c,
                    ERP_Billing_State_or_Province__c,
                    ERP_Billing_Zip_Code__c,
                    ERP_Shipping_Address__c,
                    ERP_Shipping_City__c,
                    ERP_Shipping_Country__c,
                    ERP_Shipping_State_or_Province__c,
                    ERP_Shipping_Zip_Code__c,
                    OwnerId,
                    Date_of_First_Order__c,
                    Date_of_Last_Order__c
                FROM Account
                WHERE Email_Domain__c IN :orderXomAccountDomain OR Id IN :accountIdSet
            ]) {
                if (orderXomAccountDomain.contains(a.Email_Domain__c)) {
                    allAccountDomainMap.put(a.Email_Domain__c, a);
                }

                updateAllAccountMap.put(a.Id, a);
            }

            // Get the full Account Map and assign Owner/AccountID
            if (!ordersNeedNewAccountList.isEmpty()) {
                for (Order_Erp__C o : ordersNeedNewAccountList) {
                    if (allAccountDomainMap.containskey(o.Account_Domain__C)) {
                        o.OwnerID = allAccountDomainMap.get(o.Account_Domain__C).OwnerID;
                        o.AccountID__C = allAccountDomainMap.get(o.Account_Domain__C).ID;
                    }
                }
            }
        }

        // Contact Time
        // Create Contacts if they do not exist
        Set<Contact> createNewContactSet = new Set<Contact>();
        List<Order_ERP__C> ordersNeedingContacts = new List<Order_ERP__C>();

        // Do Not Allow a duplicate set of contact emails
        // loop through the set and limit based on map of domains then extract out the values.
        Map<String, Contact> newContactEmailMap = new Map<String, Contact>();

        for (Order_ERP__C o : newOrdersERPList) {
            if (!existingcontactMap.containskey(o.Order_Email__C)) {
                ordersNeedingContacts.add(o);
                // Create new Contact
                Contact c = new Contact();
                c.AccountID = o.AccountID__C;
                c.OwnerID = o.OwnerID;
                // Assign the Contact as generic
                if (o.Is_Generic__C == true) {
                    c.Generic_Contact__c = true;
                }
                if (!String.isBlank(o.ERP_Contact_Phone__C)) {
                    c.Phone = o.ERP_Contact_Phone__C;
                    c.ERP_Contact_Phone__C = o.ERP_Contact_Phone__C;
                }
                if (!String.isBlank(o.ERP_Contact_Last_Name__C)) {
                    c.LastName = o.ERP_Contact_Last_Name__C;
                } else {
                    c.LastName = o.Order_Email__C;
                }
                c.FirstName = o.ERP_Contact_First_Name__C;
                c.Primary_Email__C = o.Order_Email__C;
                c.Xometry_ERP_Contact_ID__c = o.ERP_Contact__C;
                c.ERP_Shipping_Address__c = o.ERP_Shipping_Address__c;
                c.ERP_Shipping_City__c = o.ERP_Shipping_City__c;
                c.ERP_Shipping_Country__c = o.ERP_Shipping_Country__c;
                c.ERP_Shipping_State_or_Province__c = o.ERP_Shipping_State_or_Province__c;
                c.ERP_Shipping_Zip_Code__c = o.ERP_Shipping_Zip_Code__c;
                if (!String.isBlank(o.MKP_PartnerID__c)) {
                    c.GNO_PartnerID__c = o.MKP_PartnerID__c;
                    if (supplierMap.containsKey(o.MKP_PartnerID__c)) {
                        c.AccountId = supplierMap.get(o.MKP_PartnerID__c).AccountId__c;
                    }
                }
                c.LeadSource = 'Quoter';

                if (!newContactEmailMap.containsKey(c.Primary_Email__C)) {
                    // Don't create duplicate account based on email domain
                    newContactEmailMap.put(c.Primary_Email__C, c);
                }
            } else {
                // ContactMap contains the Email used for the Order assign the Order based on the Contact's owner.account
                Contact c = existingcontactMap.get(o.Order_Email__C);

                o.ContactID__C = c.ID;
                o.AccountID__C = c.AccountID;
                o.OwnerID = c.OwnerID;
                if (mappedDunsAccounts.containsKey(o.Xometry_ERP_ID__c)) {
                    o.AccountID__c = mappedDunsAccounts.get(o.Xometry_ERP_ID__c).accountId;
                }
                if (!String.isBlank(o.MKP_PartnerID__c)) {
                    if (supplierMap.containsKey(o.MKP_PartnerID__c)) {
                        o.AccountId__c = supplierMap.get(o.MKP_PartnerID__c).AccountId__c;
                    }
                }
            }
        }

        DatabaseUtilities.insertToDatabase(newContactEmailMap.values(), 'OrderERPHandler', 'New Contact Inserts');

        // Update Accounts Billing and Shipping Information
        Set<String> updateAccountMatchMapUpdateSet = new Set<String>();

        if (!orderXomAccountDomain.isEmpty()) {
            // Check for Existing Accounts and populate their ERP SHIPPING ADDRESSES and ERP BILLING ADDRESSES
            // Orders are more reliable then Quotes for this data so always update Accounts where the Billing or Shipping Address combo is not blank on the order

            for (Order_ERP__C o : newOrdersERPList) {
                if (allAccountDomainMap.containsKey(o.Account_Domain__c)) {
                    Account a = allAccountDomainMap.get(o.Account_Domain__c);
                    Integer UpdateMarker = 0;
                    // Check for Blank Billing Addresses
                    if (
                        (!String.isblank(o.ERP_Billing_Address__c) || !String.isblank(o.ERP_Billing_City__c)) &&
                        (!String.isblank(o.ERP_Billing_State_or_Province__c) ||
                        !String.isblank(o.ERP_Billing_Zip_Code__c))
                    ) {
                        a.ERP_Billing_Address__c = o.ERP_Billing_Address__c;
                        a.ERP_Billing_City__c = o.ERP_Billing_City__c;
                        a.ERP_Billing_Country__c = o.ERP_Billing_Country__c;
                        a.ERP_Billing_State_or_Province__c = o.ERP_Billing_State_or_Province__c;
                        a.ERP_Billing_Zip_Code__c = o.ERP_Billing_Zip_Code__c;
                        UpdateMarker = 1;
                    }
                    // Check for Blank Shipping Addresses
                    if (
                        (!String.isblank(o.ERP_Shipping_Address__C) || !String.isblank(o.ERP_Shipping_City__c)) &&
                        (!String.isblank(o.ERP_Shipping_State_or_Province__c) ||
                        !String.isblank(o.ERP_Shipping_Zip_Code__c))
                    ) {
                        a.ERP_Shipping_Address__C = o.ERP_Shipping_Address__C;
                        a.ERP_Shipping_City__c = o.ERP_Shipping_City__c;
                        a.ERP_Shipping_Country__c = o.ERP_Shipping_Country__c;
                        a.ERP_Shipping_State_or_Province__c = o.ERP_Shipping_State_or_Province__c;
                        a.ERP_Shipping_Zip_Code__c = o.ERP_Shipping_Zip_Code__c;
                        UpdateMarker = 1;
                    }
                    // Check if Account Owner is GNO House User and update to Sales House User
                    if (a.OwnerId == AppConstants.GNO_HOUSE_USER) {
                        a.OwnerId = AppConstants.SALES_HOUSE_USER;
                        UpdateMarker = 1;
                    }
                    if (UpdateMarker == 1) {
                        // No duplicates with Map
                        updateAccountMatchMapUpdateSet.add(a.Email_Domain__C);
                    }
                }
            }
        }

        Set<ID> contactIdSet = new Set<ID>();
        for (Order_ERP__C o : newOrdersERPList) {
            if (
                o.ContactID__c == null &&
                newContactEmailMap.containsKey(o.Order_Email__C) &&
                newContactEmailMap.get(o.Order_Email__C).Id != null
            ) {
                o.ContactID__c = newContactEmailMap.get(o.Order_Email__C).Id;
            }
            contactIdSet.add(o.ContactID__c);
        }

        Map<Id, Contact> updateAllContactMap = new Map<Id, Contact>();
        Set<String> updateContactMatchMapUpdateSet = new Set<String>();

        if (!orderXomeEmailSET.isEmpty() || !contactIdSet.isEmpty()) {
            // Get all Contacts
            // Check for Contacts missing value
            Map<String, Contact> contactUpdateMap = new Map<String, Contact>();
            for (Contact c : [
                SELECT
                    ID,
                    Primary_Email__C,
                    ERP_Contact_Phone__C,
                    Xometry_ERP_Contact_ID__c,
                    ERP_Shipping_Address__c,
                    ERP_Shipping_City__c,
                    ERP_Shipping_Country__c,
                    ERP_Shipping_State_or_Province__c,
                    ERP_Shipping_Zip_Code__c,
                    OwnerId,
                    GNO_PartnerId__c,
                    AccountId,
                    DNBConnect__D_B_Connect_Contact_Profile__c,
                    LastName,
                    contact_s_Date_of_First_Order__c,
                    Date_of_Last_Order__c,
                    Has_Ordered__c,
                    First_Quote_Date__c
                FROM Contact
                WHERE Primary_Email__C IN :orderXomeEmailSET OR Id IN :contactIdSet
            ]) {
                if (orderXomeEmailSET.contains(c.Primary_Email__C)) {
                    // Map for future values
                    contactUpdateMap.put(c.Primary_Email__C, c);
                }

                updateAllContactMap.put(c.Id, c);
            }

            for (Order_ERP__C o : newOrdersERPList) {
                if (contactUpdateMap.containsKey(o.Order_Email__C)) {
                    Contact myContact = contactUpdateMap.get(o.Order_Email__C);
                    Integer UpdateMarker = 0;
                    if (String.isBlank(myContact.Xometry_ERP_Contact_ID__c)) {
                        myContact.Xometry_ERP_Contact_ID__c = o.ERP_Contact__C;
                        UpdateMarker = 1;
                    }
                    if (!String.isblank(o.ERP_Contact_Phone__c)) {
                        if (
                            String.isblank(myContact.ERP_Contact_Phone__C) ||
                            (!myContact.ERP_Contact_Phone__C.equals(o.ERP_Contact_Phone__C))
                        ) {
                            myContact.ERP_Contact_Phone__C = o.ERP_Contact_Phone__C;
                            UpdateMarker = 1;
                        }
                    }
                    if (
                        (!String.isblank(o.ERP_Shipping_Address__C) || !String.isblank(o.ERP_Shipping_City__c)) &&
                        (!String.isblank(o.ERP_Shipping_State_or_Province__c) ||
                        !String.isblank(o.ERP_Shipping_Zip_Code__c))
                    ) {
                        myContact.ERP_Shipping_Address__C = o.ERP_Shipping_Address__C;
                        myContact.ERP_Shipping_City__c = o.ERP_Shipping_City__c;
                        myContact.ERP_Shipping_Country__c = o.ERP_Shipping_Country__c;
                        myContact.ERP_Shipping_State_or_Province__c = o.ERP_Shipping_State_or_Province__c;
                        myContact.ERP_Shipping_Zip_Code__c = o.ERP_Shipping_Zip_Code__c;
                        UpdateMarker = 1;
                    }
                    if (String.isBlank(myContact.GNO_PartnerId__c) && !String.isBlank(o.MKP_PartnerId__c)) {
                        myContact.GNO_PartnerId__c = o.MKP_PartnerId__c;
                        UpdateMarker = 1;
                    }
                    if (
                        myContact.DNBConnect__D_B_Connect_Contact_Profile__c == null &&
                        mappedDunsAccounts.containsKey(o.Xometry_ERP_ID__c)
                    ) {
                        myContact.AccountId = mappedDunsAccounts.get(o.Xometry_ERP_ID__c).accountId;
                        UpdateMarker = 1;
                    }
                    if (
                        myContact.LastName.contains('@') &&
                        myContact.LastName == o.Order_Email__C &&
                        o.ERP_Contact_Last_Name__c != null
                    ) {
                        myContact.LastName = o.ERP_Contact_Last_Name__C;
                        UpdateMarker = 1;
                    }
                    //Safety check the First Quote Date on brand new contacts for Traction if the order beats the quote
                    if (myContact.First_Quote_Date__c == null && o.Order_ERP_CreatedDate__c != null) {
                        myContact.First_Quote_Date__c = o.Order_ERP_CreatedDate__c;
                    }
                    if (UpdateMarker == 1) {
                        // No duplicates with map
                        updateContactMatchMapUpdateSet.add(myContact.Primary_Email__C);
                    }
                }
            }
        }

        Set<Id> markedIdSet = OrderDateofFirstOrderPop(
            newOrdersERPList,
            updateAllAccountMap.values(),
            updateAllContactMap.values()
        );

        List<Account> updateAccountList = new List<Account>();
        for (Account acc2up : updateAllAccountMap.values()) {
            if (updateAccountMatchMapUpdateSet.contains(acc2up.Email_Domain__C) || markedIdSet.contains(acc2up.Id)) {
                updateAccountList.add(acc2up);
            }
        }

        DatabaseUtilities.saveToDatabase(updateAccountList, 'OrderERPHandler', 'Update Account Update Fields');

        List<Contact> updateContactList = new List<Contact>();
        for (Contact con2up : updateAllContactMap.values()) {
            if (updateContactMatchMapUpdateSet.contains(con2up.Primary_Email__C) || markedIdSet.contains(con2up.Id)) {
                updateContactList.add(con2up);
            }
        }

        DatabaseUtilities.saveToDatabase(updateContactList, 'OrderERPHandler', 'Contact Data Updates');

        if (!ordersNeedingContacts.isEmpty()) {
            //
            List<Contact> allContactList = [
                SELECT ID, OwnerID, Primary_Email__C, AccountID
                FROM Contact
                WHERE Primary_Email__C IN :orderXomeEmailSET
            ];

            Map<String, Contact> allContactMap = new Map<String, Contact>();
            if (!allContactList.isEmpty()) {
                for (Contact c : allContactList) {
                    allContactMap.put(c.Primary_Email__C, c);
                }
            }
            for (Order_ERP__C o : ordersneedingContacts) {
                if (allContactMap.containskey(o.Order_Email__C)) {
                    o.ContactID__C = allContactMap.get(o.Order_Email__C).ID;
                    o.AccountID__C = allContactMap.get(o.Order_Email__C).AccountID;
                }
            }
        }

        // Apply Business Logic
        Set<Opportunity> createNewOppSet = new Set<Opportunity>();
        List<Opportunity> createNewOppList = new List<Opportunity>();
        List<Order_ERP__C> ordersNeedingOpp = new List<Order_ERP__C>();

        // order map above OrderMap
        // check to see if opp has
        Map<String, Id> orderIdToOppIdMap = new Map<String, Id>();

        if (!quoteXomERPIDSet.isEmpty()) {
            // Quotes to Opportunity are One to One
            // Orders need to be One to One so where an Opp contains more then one order shorten out the others
            Set<ID> opportunityCheckIDSet = new Set<ID>();
            for (Order_ERP__C o : newOrdersERPList) {
                if (!String.isblank(o.OpportunityID__C)) {
                    if (!opportunityCheckIDSet.contains(o.OpportunityID__C)) {
                        // add the ID to the Set
                        opportunityCheckIDSet.add(o.OpportunityID__C);
                    } else {
                        // Blankout the Opportunity for duplicates
                        o.OpportunityID__C = null;
                    }
                }
            }

            for (Opportunity opp : [
                SELECT Id, Order_ERP_Xom_ID__c
                FROM Opportunity
                WHERE Order_ERP_Xom_ID__c IN :orderXomERPIDSET
            ]) {
                orderIdToOppIdMap.put(opp.Order_ERP_Xom_ID__c, opp.Id);
            }
        }

        for (Order_ERP__C o : newOrdersERPList) {
            if (orderIdToOppIdMap.containsKey(o.Xometry_ERP_ID__c)) {
                o.OpportunityID__c = orderIdToOppIdMap.get(o.Xometry_ERP_ID__c);
            }

            if (o.OpportunityID__C == null) {
                Opportunity opp = new Opportunity();
                ordersNeedingOpp.add(o);
                opp.Line_of_Business__c = o.Line_of_Business__c;
                if (
                    o.Line_of_Business__c == INSTANT_QUOTE_LINE_OF_BUSINESS ||
                    o.Line_of_Business__c == MARKETPLACE_LINE_OF_BUSINESS
                ) {
                    opp.RecordtypeID = oppManuSRecordTypeID;
                } else {
                    //default recordType logic
                    opp.RecordtypeID = oppDefaultRecordTypeID;
                }
                opp.AccountID = o.AccountID__C;
                opp.Stagename = 'Open';
                opp.CloseDate = o.Order_ERP_CreatedDate__C;
                opp.Order_Date__C = o.Order_ERP_CreatedDate__C;
                opp.Order_DateTime__C = o.Order_ERP_Time__c;
                opp.Primary_Contact__c = o.ContactID__C;
                opp.OwnerID = o.OwnerID;
                opp.Amount = o.Order_Total__C;
                opp.Name = o.Xometry_Quote_ID__c == o.Xometry_ERP_ID__C
                    ? o.Xometry_ERP_ID__C
                    : o.Xometry_Quote_ID__c + ' | ' + o.Xometry_ERP_ID__C;
                opp.Order_ERP_Xom_ID__c = o.Xometry_ERP_ID__C;
                opp.Quote_ERP_XOM_CREATE_ID__c = o.Xometry_Quote_ID__c;
                opp.Last_Quote_Xometry_ERP_ID__C = o.Xometry_Quote_ID__c;
                opp.Original_Quoter_Email__c = o.Order_Email__C;
                opp.Quote_Type__c = o.Quote_Type__c;
                opp.OriginatedInFusion360__c = o.OriginatedInFusion360__c;
                opp.Quote_Created_Date__c = o.Quote_Created_Date__c;
                createNewOppSet.add(opp);
            }
        }

        createNewOppList.addAll(createNewOppSet);

        DatabaseUtilities.insertToDatabase(createNewOppList, 'OrderERPHandler', 'New Opp Inserts');

        // Map the Opps
        Map<String, Opportunity> oppsCreatedMap = new Map<String, Opportunity>();
        if (!createNewOppList.isEmpty()) {
            for (Opportunity opp : createNewOppList) {
                oppsCreatedMap.put(opp.Quote_ERP_XOM_CREATE_ID__c, opp);
            }
        }

        // Assign Opps to Orders
        if (!ordersNeedingOpp.isEmpty()) {
            for (Order_ERP__C o : ordersNeedingOpp) {
                if (oppsCreatedMap.containskey(o.Xometry_Quote_ID__c)) {
                    o.OpportunityID__C = oppsCreatedMap.get(o.Xometry_Quote_ID__c).ID;
                }
            }
        }

        // all Opps and Contact Set
        // Get all the Opp and Contact
        Set<ID> allOppIdSet = new Set<ID>();
        for (Order_ERP__C o : newOrdersERPList) {
            if (o.OpportunityID__C != null) {
                allOppIdSet.add(o.OpportunityID__C);
            }
        }

        if (!allOppIdSet.isEmpty()) {
            // OpportunityContact Role
            // List<OpportunityContactRole> existingOppContactRoleList = [Select ID, OpportunityID, ContactID, Role, IsPrimary from OpportunityContactRole
            // where OpportunityID in :allOppIdSet and ContactID in :allContactIDSet order by OpportunityID, IsPrimary, ContactID];
            // Experiment optcontactrole
            List<OpportunityContactRole> existingOppContactRoleList = [
                SELECT ID, OpportunityID, ContactID, Role, IsPrimary
                FROM OpportunityContactRole
                WHERE OpportunityID IN :allOppIdSet
                ORDER BY OpportunityID, IsPrimary, ContactID
            ];

            Map<ID, Set<ID>> oppContactRoleExistMap = new Map<ID, Set<ID>>();
            if (!existingOppContactRoleList.isEmpty()) {
                for (OpportunityContactRole oppCon : existingOppContactRoleList) {
                    if (oppContactRoleExistMap.containskey(oppCon.OpportunityID)) {
                        // Add to the Set
                        Set<ID> lset = oppContactRoleExistMap.get(oppCon.OpportunityID);
                        lset.add(oppCon.ContactID);
                        oppContactRoleExistMap.put(oppCon.OpportunityID, lset);
                    } else {
                        // Create Set and add Opp to Map
                        Set<ID> oppContactRoleConSet = new Set<ID>();
                        oppContactRoleConSet.add(oppCon.ContactID);
                        oppContactRoleExistMap.put(oppCon.OpportunityID, oppContactRoleConSet);
                    }
                }
            }

            Set<OpportunityContactRole> newOppContRoleSet = new Set<OpportunityContactRole>();
            // Create OppContactrole for purchaser Mark Primary where no Contact Exists
            for (Order_ERP__C o : newOrdersERPList) {
                if (oppContactRoleExistMap.containsKey(o.OpportunityID__C)) {
                    Set<ID> lcontactSet = oppContactRoleExistMap.get(o.OpportunityID__C);
                    if (!lcontactSet.contains(o.ContactID__C)) {
                        // Create an Opportunity Contact Record
                        OpportunityContactRole oppConRole = new OpportunityContactRole();
                        oppConRole.Role = 'Purchaser';
                        oppConRole.IsPrimary = false;
                        oppConRole.OpportunityID = o.OpportunityID__C;
                        oppConRole.ContactID = o.ContactID__C;
                        newOppContRoleSet.add(oppConRole);
                    }
                    // Post MVP Folloup to Seperate New Contact as Primary or not and Could also overwrite existing Contact with Purchaser
                } else {
                    // No Opp Contact Record
                    OpportunityContactRole oppConRole = new OpportunityContactRole();
                    oppConRole.Role = 'Purchaser';
                    oppConRole.IsPrimary = true;
                    oppConRole.OpportunityID = o.OpportunityID__C;
                    oppConRole.ContactID = o.ContactID__C;
                    newOppContRoleSet.add(oppConRole);
                }
            }

            List<OpportunityContactRole> newOppContRoleList = new List<OpportunityContactRole>();
            newOppContRoleList.addAll(newOppContRoleSet);

            DatabaseUtilities.insertToDatabase(newOppContRoleList, 'OrderERPHandler', 'New Opp Contact Role Inserts');
        }

        //DB Lead Conversion Revert to not use Utility

        List<Database.LeadConvert> leadOrderConvertList = new List<Database.LeadConvert>();
        Set<Database.LeadConvert> leadOrderConvertSet = new Set<Database.LeadConvert>();

        List<Order_ERP__C> myOrderERPList = new List<Order_ERP__C>();
        for (Order_ERP__C o : newOrdersERPList) {
            if (existingQuoteMap.containsKey(o.Xometry_Quote_ID__c)) {
                if (o.LeadID__C != null && existingQuoteMap.get(o.Xometry_Quote_ID__c).LeadID__R.IsConverted == false) {
                    myOrderERPList.add(o);
                }
            }
        }

        List<Audit_Trail_Error__c> myAuditErrorList = new List<Audit_Trail_Error__c>();
        Set<ID> leadToConvertIDSET = new Set<ID>();
        Set<ID> leadIdConvertSET = new Set<ID>();
        if (!myOrderERPList.isEmpty()) {
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
            for (Order_ERP__C o : myOrderERPList) {
                // Convert the Lead to Opportunity Account
                Database.LeadConvert l_dbLeadConvert = new Database.LeadConvert();
                l_dbLeadConvert.setConvertedStatus(convertStatus.MasterLabel);
                l_dbLeadConvert.setLeadID(o.LeadID__C);
                l_dbLeadConvert.setOwnerID(o.OwnerID);
                l_dbLeadConvert.setAccountID(o.AccountID__C);
                l_dbLeadConvert.setContactID(o.ContactID__C);
                l_dbLeadConvert.setOpportunityID(o.OpportunityID__C);
                if (!leadIDConvertSET.contains(o.LeadID__C)) {
                    // One Converter Class Per Lead
                    leadOrderConvertSet.add(l_dbLeadConvert);
                    leadIdConvertSET.add(o.LeadID__C);
                }
            }

            leadOrderConvertList.addAll(leadOrderConvertSet);
            // Convert the Leads
            Set<ID> lcrIDSuccessSet = new Set<ID>();
            List<Database.LeadConvertResult> srLeadConvertResult = Database.convertLead(leadOrderConvertList, false);
            for (Database.LeadConvertResult lcr : srLeadConvertResult) {
                if (lcr.isSuccess()) {
                    lcrIDSuccessSet.add(lcr.getLeadID());
                } else {
                    // Log errors
                    for (Database.Error err : lcr.getErrors()) {
                        Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
                        myAuditError.Module__c = 'OrderERPHandler';
                        myAuditError.Dev_Audit_Notes__c = 'Lead Convert Conversion';
                        myAuditError.StatusCode__c = err.getStatusCode().name();
                        myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
                        myAuditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
                        myAuditErrorList.add(myAuditError);
                    }
                }
            }
        }

        // Update all Opps
        // Before we get the Update the Opportunity there is a chance the Contact Owner has changed due to a flip or
        // Process Builder/Flow change/Batch Job from contact updates above so fetch the Owner from the contacts. Update the Order
        // Owner then use that owner in the Opp Update Below.

        Set<Opportunity> allOppstoUpdateSet = new Set<Opportunity>();
        Map<ID, Opportunity> allOppstoUpdateMap = new Map<ID, Opportunity>();
        List<Opportunity> allOppstoUpdateList = new List<Opportunity>();

        for (Order_ERP__C o : newOrdersERPList) {
            if (allOppstoUpdateMap.containsKey(o.OpportunityID__C)) {
                Opportunity opp = allOppstoUpdateMap.get(o.OpportunityID__C);
                // if Opportunity previous Stagename was lost and new is not lost update it
                if (o.Order_Canceled_Flag__c == false) {
                    opp.Name = o.Xometry_Quote_ID__c == o.Xometry_ERP_ID__C
                        ? o.Xometry_ERP_ID__C
                        : o.Xometry_Quote_ID__c + ' | ' + o.Xometry_ERP_ID__C;
                    opp.Stagename = 'Closed Won';
                    opp.Loss_Reason__c = '';
                    opp.Order_ERP_Xom_ID__c = o.Xometry_ERP_ID__C;
                    opp.ERP_Status__c = o.ERP_Status__c;
                    opp.Line_of_Business__c = o.Line_of_Business__c;
                    opp.Amount = opp.Amount + o.Order_Total__C;
                    if (opp.has_ordered_Carbon__c == false) {
                        opp.has_ordered_Carbon__c = o.process_isCarbon__c;
                    }
                    if (opp.has_ordered_CNC_Machining__c == false) {
                        opp.has_ordered_CNC_Machining__c = o.process_isCNC_Machining__c;
                    }
                    if (opp.has_ordered_Die_Casting__c == false) {
                        opp.has_ordered_Die_Casting__c = o.process_isDie_Casting__c;
                    }
                    if (opp.has_ordered_Direct_Sourced__c == false) {
                        opp.has_ordered_Direct_Sourced__c = o.process_isDirect_Sourced__c;
                    }
                    if (opp.has_ordered_DMLS__c == false) {
                        opp.has_ordered_DMLS__c = o.process_isDMLS__c;
                    }
                    if (opp.has_ordered_Extrusion__c == false) {
                        opp.has_ordered_Extrusion__c = o.process_isExtrusion__c;
                    }
                    if (opp.has_ordered_FDM__c == false) {
                        opp.has_ordered_FDM__c = o.process_isFDM__c;
                    }
                    if (opp.has_ordered_HPMultiJetFusion__c == false) {
                        opp.has_ordered_HPMultiJetFusion__c = o.process_isHPMultJetFusion__c;
                    }
                    if (opp.has_ordered_Injection_Molding__c == false) {
                        opp.has_ordered_Injection_Molding__c = o.process_isInjection_Molding__c;
                    }
                    if (opp.has_ordered_Injection_Molding_Tool__c == false) {
                        opp.has_ordered_Injection_Molding_Tool__c = o.process_isInjectionMoldingTool__c;
                    }
                    if (opp.has_ordered_PolyJet_3D__c == false) {
                        opp.has_ordered_PolyJet_3D__c = o.process_isPolyJet_3D__c;
                    }
                    if (opp.has_ordered_PlasticExtrusion__c == false) {
                        opp.has_ordered_PlasticExtrusion__c = o.process_isPlasticExtrusion__c;
                    }
                    if (opp.has_ordered_Sheet_metal__c == false) {
                        opp.has_ordered_Sheet_metal__c = o.process_isSheet_metal__c;
                    }
                    if (opp.has_ordered_SLA__c == false) {
                        opp.has_ordered_SLA__c = o.process_isSLA__c;
                    }
                    if (opp.has_ordered_SLS__c == false) {
                        opp.has_ordered_SLS__c = o.process_isSLS__c;
                    }
                    if (opp.has_ordered_Stamping__c == false) {
                        opp.has_ordered_Stamping__c = o.process_isStamping__c;
                    }
                    if (opp.has_ordered_Urethane_Casting__c == false) {
                        opp.has_ordered_Urethane_Casting__c = o.process_isUrethane_Casting__c;
                    }
                    if (opp.has_ordered_BinderJetting__c == false) {
                        opp.has_ordered_BinderJetting__c = o.process_isBinderJetting__c;
                    }
                    if (opp.has_ordered_SheetCutting__c == false) {
                        opp.has_ordered_SheetCutting__c = o.process_isSheetCutting__c;
                    }
                    if (opp.has_ordered_TubeBending__c == false) {
                        opp.has_ordered_TubeBending__c = o.process_isTubeBending__c;
                    }
                    if (opp.has_ordered_TubeCutting__c == false) {
                        opp.has_ordered_TubeCutting__c = o.process_isTubeCutting__c;
                    }
                    if (opp.has_ordered_Other__c == false) {
                        opp.has_ordered_Other__c = o.process_IsOther__c;
                    }
                    if (opp.has_ordered_Other_NotIncluded__c == false) {
                        opp.has_ordered_Other_NotIncluded__c = o.process_IsOther_NotIncluded__c;
                    }
                    if (opp.has_ordered_LSPc__c == false) {
                        opp.has_ordered_LSPc__c = o.process_IsLSPc__c;
                    }
                    if (opp.has_ordered_Assembly__c == false) {
                        opp.has_ordered_Assembly__c = o.process_IsAssembly__c;
                    }
                    opp.most_recent_quote_Carbon__c = o.process_isCarbon__c;
                    opp.most_recent_quote_CNC_Machining__c = o.process_isCNC_Machining__c;
                    opp.most_recent_quote_Die_Casting__c = o.process_isDie_Casting__c;
                    opp.most_recent_quote_Direct_Sourced__c = o.process_isDirect_Sourced__c;
                    opp.most_recent_quote_DMLS__c = o.process_isDMLS__c;
                    opp.most_recent_quote_Extrusion__c = o.process_isExtrusion__c;
                    opp.most_recent_quote_FDM__c = o.process_isFDM__c;
                    opp.most_recent_quote_HPMultiJetFusion__c = o.process_isHPMultJetFusion__c;
                    opp.most_recent_quote_Injection_Molding__c = o.process_isInjection_Molding__c;
                    opp.Most_Recent_Quote_Injection_Molding_Tool__c = o.process_isInjectionMoldingTool__c;
                    opp.Most_Recent_Quote_PolyJet_3D__c = o.process_isPolyJet_3D__c;
                    opp.Most_Recent_Quote_PlasticExtrusion__c = o.process_isPlasticExtrusion__c;
                    opp.most_recent_quote_Sheet_metal__c = o.process_isSheet_metal__c;
                    opp.Most_Recent_Quote_SLA__c = o.process_isSLA__c;
                    opp.most_recent_quote_SLS__c = o.process_isSLS__c;
                    opp.most_recent_quote_Stamping__c = o.process_isStamping__c;
                    opp.most_recent_quote_Urethane_Casting__c = o.process_isUrethane_Casting__c;
                    opp.most_recent_quote_BinderJetting__c = o.process_isBinderJetting__c;
                    opp.most_recent_quote_SheetCutting__c = o.process_isSheetCutting__c;
                    opp.most_recent_quote_TubeBending__c = o.process_isTubeBending__c;
                    opp.most_recent_quote_TubeCutting__c = o.process_isTubeCutting__c;
                    opp.most_recent_quote_Other__c = o.process_isOther__c;
                    opp.most_recent_quote_Other_NotIncluded__c = o.process_isOther_NotIncluded__c;
                    opp.most_recent_quote_LSPc__c = o.process_isLSPc__c;
                    opp.most_recent_quote_Assembly__c = o.process_isAssembly__c;
                    opp.Total_Amt_Carbon__c = o.Ordered_Total_Amt_Carbon__c;
                    opp.Total_Amt_CNC__c = o.Ordered_Total_Amt_CNC__c;
                    opp.Total_Amt_DieCasting__c = o.Ordered_Total_Amt_DieCasting__c;
                    opp.Total_Amt_DirectSourced__c = o.Ordered_Total_Amt_DirectSourced__c;
                    opp.Total_Amt_DMLS__c = o.Ordered_Total_Amt_DMLS__c;
                    opp.Total_Amt_Extrusion__c = o.Ordered_Total_Amt_Extrusion__c;
                    opp.Total_Amt_FDM__c = o.Ordered_Total_Amt_FDM__c;
                    opp.Total_Amt_HPMultJetFusion__c = o.Ordered_Total_Amt_HPMulJetFusion__c;
                    opp.Total_Amt_InjectionMolding__c = o.Ordered_Total_Amt_InjectionMolding__c;
                    opp.Total_Amt_InjectionMoldingTool__c = o.Ordered_Total_Amt_InjectionMoldingTool__c;
                    opp.Total_Amt_PolyJet3D__c = o.Ordered_Total_Amt_PolyJet3D__c;
                    opp.Total_Amt_PlasticExtrusion__c = o.Ordered_Total_Amt_PlasticExtrusion__c;
                    opp.Total_Amt_SheetMetal__c = o.Ordered_Total_Amt_SheetMetal__c;
                    opp.Total_Amt_SLA__c = o.Ordered_Total_Amt_SLA__c;
                    opp.Total_Amt_SLS__c = o.Ordered_Total_Amt_SLS__c;
                    opp.Total_Amt_Stamping__c = o.Ordered_Total_Amt_Stamping__c;
                    opp.Total_Amt_UrethaneCasting__c = o.Ordered_Total_Amt_UrethaneCasting__c;
                    opp.Total_Amt_BinderJetting__c = o.Ordered_Total_Amt_BinderJetting__c;
                    opp.Total_Amt_SheetCutting__c = o.Ordered_Total_Amt_SheetCutting__c;
                    opp.Total_Amt_Tube_Bending__c = o.Ordered_Total_Amt_Tube_Bending__c;
                    opp.Total_Amt_Tube_Cutting__c = o.Ordered_Total_Amt_Tube_Cutting__c;
                    opp.Total_Amt_Other__c = o.Ordered_Total_Amt_Other__c;
                    opp.Total_Amt_Other_NotIncluded__c = o.Ordered_Total_Amt_Other_NotIncluded__c;
                    opp.Total_Amt_LSPc__c = o.Ordered_Total_Amt_LSPc__c;
                    opp.Total_Amt_Assembly__c = o.Ordered_Total_Amt_Assembly__c;
                    opp.Total_Qty_Carbon__c = o.Ordered_Total_Qty_Carbon__c;
                    opp.Total_Qty_CNC__c = o.Ordered_Total_Qty_CNC__c;
                    opp.Total_Qty_DieCasting__c = o.Ordered_Total_Qty_DieCasting__c;
                    opp.Total_Qty_DirectSourced__c = o.Ordered_Total_Qty_DirectSourced__c;
                    opp.Total_Qty_DMLS__c = o.Ordered_Total_Qty_DMLS__c;
                    opp.Total_Qty_Extrusion__c = o.Ordered_Total_Qty_Extrusion__c;
                    opp.Total_Qty_FDM__c = o.Ordered_Total_Qty_FDM__c;
                    opp.Total_Qty_HPMultJetFusion__c = o.Ordered_Total_Qty_HPMultJetFusion__c;
                    opp.Total_Qty_InjectionMolding__c = o.Ordered_Total_Qty_InjectionMolding__c;
                    opp.Total_Qty_InjectionMoldingTool__c = o.Ordered_Total_Qty_InjectionMoldingTool__c;
                    opp.Total_Qty_PolyJet3D__c = o.Ordered_Total_Qty_PolyJet3D__c;
                    opp.Total_Qty_PlasticExtrusion__c = o.Ordered_Total_Qty_PlasticExtrusion__c;
                    opp.Total_Qty_SheetMetal__c = o.Ordered_Total_Qty_SheetMetal__c;
                    opp.Total_Qty_SLA__c = o.Ordered_Total_Qty_SLA__c;
                    opp.Total_Qty_SLS__c = o.Ordered_Total_Qty_SLS__c;
                    opp.Total_Qty_Stamping__c = o.Ordered_Total_Qty_Stamping__c;
                    opp.Total_Qty_UrethaneCasting__c = o.Ordered_Total_Qty_UrethaneCasting__c;
                    opp.Total_Qty_BinderJetting__c = o.Ordered_Total_Qty_BinderJetting__c;
                    opp.Total_Qty_SheetCutting__c = o.Ordered_Total_Qty_SheetCutting__c;
                    opp.Total_Qty_Tube_Bending__c = o.Ordered_Total_Qty_Tube_Bending__c;
                    opp.Total_Qty_Tube_Cutting__c = o.Ordered_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Other__c = o.Ordered_Total_Qty_Other__c;
                    opp.Total_Qty_Other_NotIncluded__c = o.Ordered_Total_Qty_Other_NotIncluded__c;
                    opp.Total_Qty_LSPc__c = o.Ordered_Total_Qty_LSPc__c;
                    opp.Total_Qty_Assembly__c = o.Ordered_Total_Qty_Assembly__c;
                    opp.order_Certifications__c = o.certifications__c;
                    opp.order_Discount__c = o.discount__c;
                    opp.order_Points_Earned__c = o.points_Earned__c;
                    opp.order_Redeemed_Points__c = o.redeemed_Points__c;
                    opp.order_Redeemed_Points_Value__c = o.redeemed_Points_Value__c;
                    opp.order_Shipping__c = o.shipping__c;
                    opp.order_Shipping_Discount__c = o.shipping_discount__c;
                    opp.order_Tax__c = o.tax__c;
                    opp.Quote_Type__c = o.Quote_Type__c;
                    opp.OriginatedInFusion360__c = o.OriginatedInFusion360__c;
                    Opp.ITAR__c = o.ITAR__c;
                    Opp.Hardware_Cert__c = o.Hardware_Cert__c;
                    Opp.Conformance_Cert__c = o.Conformance_Cert__c;
                    Opp.Material_Traceability_Cert__c = o.Material_Traceability_Cert__c;
                    Opp.Material_Cert__c = o.Material_Cert__c;
                    Opp.LineItemCount__c = o.LineItemCount__c;
                    Opp.Pending_Payment_Type__c = OpportunityHandler.setPaymentType(o.Payment_Type__c);
                    opp.Manual_Quote_Prioritization_Score__c = o.Manual_Quote_Prioritization_Score__c;
                    allOppstoUpdateMap.put(opp.id, opp);
                }
            } else {
                Opportunity opp = new Opportunity();
                opp.Id = o.OpportunityID__C;
                if (o.Order_Canceled_Flag__c == true) {
                    opp.Stagename = 'Closed Lost';
                    opp.Loss_Reason__c = 'Order Cancelled';
                } else {
                    opp.Stagename = 'Closed Won';
                }
                opp.Name = o.Xometry_Quote_ID__c == o.Xometry_ERP_ID__C
                    ? o.Xometry_ERP_ID__C
                    : o.Xometry_Quote_ID__c + ' | ' + o.Xometry_ERP_ID__C;
                opp.AccountID = o.AccountID__C;
                opp.ERP_Status__c = o.ERP_Status__c;
                opp.Line_of_Business__c = o.Line_of_Business__c;
                opp.Closed_By_System_Order__c = true;
                opp.Amount = o.Order_Total__C;
                opp.Order_ERP_Xom_ID__c = o.Xometry_ERP_ID__C;
                opp.Closed_By_System_Order__c = true;
                opp.Order_Date__C = o.Order_ERP_CreatedDate__C;
                opp.Order_DateTime__C = o.Order_ERP_Time__c;
                opp.CloseDate = o.Order_ERP_CreatedDate__C;
                opp.has_ordered_Carbon__c = o.process_isCarbon__c;
                opp.has_ordered_CNC_Machining__c = o.process_isCNC_Machining__c;
                opp.has_ordered_Die_Casting__c = o.process_isDie_Casting__c;
                opp.has_ordered_Direct_Sourced__c = o.process_isDirect_Sourced__c;
                opp.has_ordered_DMLS__c = o.process_isDMLS__c;
                opp.has_ordered_Extrusion__c = o.process_isExtrusion__c;
                opp.has_ordered_FDM__c = o.process_isFDM__c;
                opp.has_ordered_HPMultiJetFusion__c = o.process_isHPMultJetFusion__c;
                opp.has_ordered_Injection_Molding__c = o.process_isInjection_Molding__c;
                opp.has_ordered_Injection_Molding_Tool__c = o.process_isInjectionMoldingTool__c;
                opp.has_ordered_PolyJet_3D__c = o.process_isPolyJet_3D__c;
                opp.has_ordered_PlasticExtrusion__c = o.process_isPlasticExtrusion__c;
                opp.has_ordered_Sheet_metal__c = o.process_isSheet_metal__c;
                opp.has_ordered_SLA__c = o.process_isSLA__c;
                opp.has_ordered_SLS__c = o.process_isSLS__c;
                opp.has_ordered_Stamping__c = o.process_isStamping__c;
                opp.has_ordered_Urethane_Casting__c = o.process_isUrethane_Casting__c;
                opp.has_ordered_BinderJetting__c = o.process_isBinderJetting__c;
                opp.has_ordered_SheetCutting__c = o.process_isSheetCutting__c;
                opp.has_ordered_TubeBending__c = o.process_isTubeBending__c;
                opp.has_ordered_TubeCutting__c = o.process_isTubeCutting__c;
                opp.has_ordered_Other__c = o.process_IsOther__c;
                opp.has_ordered_Other_NotIncluded__c = o.process_IsOther_NotIncluded__c;
                opp.has_ordered_LSPc__c = o.process_IsLSPc__c;
                opp.has_ordered_Assembly__c = o.process_IsAssembly__c;
                opp.most_recent_quote_Carbon__c = o.process_isCarbon__c;
                opp.most_recent_quote_CNC_Machining__c = o.process_isCNC_Machining__c;
                opp.most_recent_quote_Die_Casting__c = o.process_isDie_Casting__c;
                opp.most_recent_quote_Direct_Sourced__c = o.process_isDirect_Sourced__c;
                opp.most_recent_quote_DMLS__c = o.process_isDMLS__c;
                opp.most_recent_quote_Extrusion__c = o.process_isExtrusion__c;
                opp.most_recent_quote_FDM__c = o.process_isFDM__c;
                opp.most_recent_quote_HPMultiJetFusion__c = o.process_isHPMultJetFusion__c;
                opp.most_recent_quote_Injection_Molding__c = o.process_isInjection_Molding__c;
                opp.Most_Recent_Quote_Injection_Molding_Tool__c = o.process_isInjectionMoldingTool__c;
                opp.Most_Recent_Quote_PolyJet_3D__c = o.process_isPolyJet_3D__c;
                opp.Most_Recent_Quote_PlasticExtrusion__c = o.process_isPlasticExtrusion__c;
                opp.most_recent_quote_Sheet_metal__c = o.process_isSheet_metal__c;
                opp.Most_Recent_Quote_SLA__c = o.process_isSLA__c;
                opp.most_recent_quote_SLS__c = o.process_isSLS__c;
                opp.most_recent_quote_Stamping__c = o.process_isStamping__c;
                opp.most_recent_quote_Urethane_Casting__c = o.process_isUrethane_Casting__c;
                opp.most_recent_quote_BinderJetting__c = o.process_isBinderJetting__c;
                opp.most_recent_quote_SheetCutting__c = o.process_isSheetCutting__c;
                opp.most_recent_quote_TubeBending__c = o.process_isTubeBending__c;
                opp.most_recent_quote_TubeCutting__c = o.process_isTubeCutting__c;
                opp.most_recent_quote_Other__c = o.process_isOther__c;
                opp.most_recent_quote_Other_NotIncluded__c = o.process_isOther_NotIncluded__c;
                opp.most_recent_quote_LSPc__c = o.process_isLSPc__c;
                opp.most_recent_quote_Assembly__c = o.process_isAssembly__c;
                opp.Total_Amt_Carbon__c = o.Ordered_Total_Amt_Carbon__c;
                opp.Total_Amt_CNC__c = o.Ordered_Total_Amt_CNC__c;
                opp.Total_Amt_DieCasting__c = o.Ordered_Total_Amt_DieCasting__c;
                opp.Total_Amt_DirectSourced__c = o.Ordered_Total_Amt_DirectSourced__c;
                opp.Total_Amt_DMLS__c = o.Ordered_Total_Amt_DMLS__c;
                opp.Total_Amt_Extrusion__c = o.Ordered_Total_Amt_Extrusion__c;
                opp.Total_Amt_FDM__c = o.Ordered_Total_Amt_FDM__c;
                opp.Total_Amt_HPMultJetFusion__c = o.Ordered_Total_Amt_HPMulJetFusion__c;
                opp.Total_Amt_InjectionMolding__c = o.Ordered_Total_Amt_InjectionMolding__c;
                opp.Total_Amt_InjectionMoldingTool__c = o.Ordered_Total_Amt_InjectionMoldingTool__c;
                opp.Total_Amt_PolyJet3D__c = o.Ordered_Total_Amt_PolyJet3D__c;
                opp.Total_Amt_PlasticExtrusion__c = o.Ordered_Total_Amt_PlasticExtrusion__c;
                opp.Total_Amt_SheetMetal__c = o.Ordered_Total_Amt_SheetMetal__c;
                opp.Total_Amt_SLA__c = o.Ordered_Total_Amt_SLA__c;
                opp.Total_Amt_SLS__c = o.Ordered_Total_Amt_SLS__c;
                opp.Total_Amt_Stamping__c = o.Ordered_Total_Amt_Stamping__c;
                opp.Total_Amt_UrethaneCasting__c = o.Ordered_Total_Amt_UrethaneCasting__c;
                opp.Total_Amt_BinderJetting__c = o.Ordered_Total_Amt_BinderJetting__c;
                opp.Total_Amt_SheetCutting__c = o.Ordered_Total_Amt_SheetCutting__c;
                opp.Total_Amt_Tube_Bending__c = o.Ordered_Total_Amt_Tube_Bending__c;
                opp.Total_Amt_Tube_Cutting__c = o.Ordered_Total_Amt_Tube_Cutting__c;
                opp.Total_Amt_Other__c = o.Ordered_Total_Amt_Other__c;
                opp.Total_Amt_Other_NotIncluded__c = o.Ordered_Total_Amt_Other_NotIncluded__c;
                opp.Total_Amt_LSPc__c = o.Ordered_Total_Amt_LSPc__c;
                opp.Total_Amt_Assembly__c = o.Ordered_Total_Amt_Assembly__c;
                opp.Total_Qty_Carbon__c = o.Ordered_Total_Qty_Carbon__c;
                opp.Total_Qty_CNC__c = o.Ordered_Total_Qty_CNC__c;
                opp.Total_Qty_DieCasting__c = o.Ordered_Total_Qty_DieCasting__c;
                opp.Total_Qty_DirectSourced__c = o.Ordered_Total_Qty_DirectSourced__c;
                opp.Total_Qty_DMLS__c = o.Ordered_Total_Qty_DMLS__c;
                opp.Total_Qty_Extrusion__c = o.Ordered_Total_Qty_Extrusion__c;
                opp.Total_Qty_FDM__c = o.Ordered_Total_Qty_FDM__c;
                opp.Total_Qty_HPMultJetFusion__c = o.Ordered_Total_Qty_HPMultJetFusion__c;
                opp.Total_Qty_InjectionMolding__c = o.Ordered_Total_Qty_InjectionMolding__c;
                opp.Total_Qty_InjectionMoldingTool__c = o.Ordered_Total_Qty_InjectionMoldingTool__c;
                opp.Total_Qty_PolyJet3D__c = o.Ordered_Total_Qty_PolyJet3D__c;
                opp.Total_Qty_PlasticExtrusion__c = o.Ordered_Total_Qty_PlasticExtrusion__c;
                opp.Total_Qty_SheetMetal__c = o.Ordered_Total_Qty_SheetMetal__c;
                opp.Total_Qty_SLA__c = o.Ordered_Total_Qty_SLA__c;
                opp.Total_Qty_SLS__c = o.Ordered_Total_Qty_SLS__c;
                opp.Total_Qty_Stamping__c = o.Ordered_Total_Qty_Stamping__c;
                opp.Total_Qty_UrethaneCasting__c = o.Ordered_Total_Qty_UrethaneCasting__c;
                opp.Total_Qty_BinderJetting__c = o.Ordered_Total_Qty_BinderJetting__c;
                opp.Total_Qty_SheetCutting__c = o.Ordered_Total_Qty_SheetCutting__c;
                opp.Total_Qty_Tube_Bending__c = o.Ordered_Total_Qty_Tube_Bending__c;
                opp.Total_Qty_Tube_Cutting__c = o.Ordered_Total_Qty_Tube_Cutting__c;
                opp.Total_Qty_Other__c = o.Ordered_Total_Qty_Other__c;
                opp.Total_Qty_Other_NotIncluded__c = o.Ordered_Total_Qty_Other_NotIncluded__c;
                opp.Total_Qty_LSPc__c = o.Ordered_Total_Qty_LSPc__c;
                opp.Total_Qty_Assembly__c = o.Ordered_Total_Qty_Assembly__c;
                opp.order_Certifications__c = o.certifications__c;
                opp.order_Discount__c = o.discount__c;
                opp.order_Points_Earned__c = o.points_Earned__c;
                opp.order_Redeemed_Points__c = o.redeemed_Points__c;
                opp.order_Redeemed_Points_Value__c = o.redeemed_Points_Value__c;
                opp.order_Shipping__c = o.shipping__c;
                opp.order_Shipping_Discount__c = o.shipping_discount__c;
                opp.order_Tax__c = o.tax__c;
                opp.Total__c = o.Order_Total__C;
                opp.SubTotal__c = o.Order_Subtotal__c;
                opp.Quote_Type__c = o.Quote_Type__c;
                opp.OriginatedInFusion360__c = o.OriginatedInFusion360__c;
                opp.LineItemCount__c = o.LineItemCount__c;
                // Update the Quote ID as well as Order ID for data consistency purposes.
                opp.Last_Quote_Xometry_ERP_ID__C = o.Xometry_Quote_ID__c;
                opp.Quote_ERP_XOM_CREATE_ID__c = o.Xometry_Quote_ID__c;
                // Certificates
                Opp.ITAR__c = o.ITAR__c;
                Opp.Hardware_Cert__c = o.Hardware_Cert__c;
                Opp.Conformance_Cert__c = o.Conformance_Cert__c;
                Opp.Material_Traceability_Cert__c = o.Material_Traceability_Cert__c;
                Opp.Material_Cert__c = o.Material_Cert__c;
                Opp.Pending_Payment_Type__c = OpportunityHandler.setPaymentType(o.Payment_Type__c);
                opp.Manual_Quote_Prioritization_Score__c = o.Manual_Quote_Prioritization_Score__c;
                allOppstoUpdateMap.put(opp.id, opp);
            }
        }
        setOwnerOpp(allOppstoUpdateMap);

        allOppstoUpdateList.addAll(allOppstoUpdateMap.values());

        DatabaseUtilities.saveToDatabase(allOppstoUpdateList, 'OrderERPHandler', 'Opportunity Updates');
    }

    /**
     * @description Receives the opportunities to update, and validates if the owner is inactive or frozen to mark the record, 
     * then Traction will know to pick it up and route it correctly
     * @param allOppstoUpdateMap Map with the opportunities to update
     */
    public static void setOwnerOpp(Map<ID, Opportunity> allOppstoUpdateMap)
    {
        Set<Id> setUserInActive = new Set<Id>();
        Set<Id> setUserActive = new Set<Id>();
        Map<Id, List<Id>> mapUserOpps = new Map<Id, List<Id>>();//map to get the Opps that the User is owner

        List<Opportunity> lstOpp = [SELECT OwnerId, Owner.IsActive, Stagename FROM Opportunity WHERE Id IN: allOppstoUpdateMap.keySet()];

        //Populated the maps and separate the users actives and inactives
        for(Opportunity opp : lstOpp)
        {
            if(
                allOppstoUpdateMap.get(opp.Id).Stagename != opp.Stagename &&
                allOppstoUpdateMap.get(opp.Id).Stagename == 'Closed Won'
            )
            {
                List<Id> lstOppsId = mapUserOpps.get(opp.OwnerId);
                if(lstOppsId == null)
                {
                    lstOppsId = new List<Id>();
                    mapUserOpps.put(opp.OwnerId, lstOppsId);
                }
                lstOppsId.add(opp.Id);
                
                if(opp.Owner.IsActive)
                {
                    setUserActive.add(opp.OwnerId);
                }
                else
                {
                    setUserInActive.add(opp.OwnerId);
                }
            }
        }

        //Search if the users active are frozen
        if(!setUserActive.isEmpty())
        {
            List<UserLogin> lstUserLogin = [SELECT UserId FROM UserLogin WHERE IsFrozen = True AND UserId IN: setUserActive];
            for(UserLogin objUserLogin : lstUserLogin)
            {
                setUserInActive.add(objUserLogin.UserId);
            }
        }

        //Iterate the inactive users to mark the opps
        for(Id userId : setUserInActive)
        {   
            List<Id> lstOppsUser = mapUserOpps.get(userId);
            for(Id idOpp : lstOppsUser)
            {
                allOppstoUpdateMap.get(idOpp).Owner_Update_Needed__c = true;
            }
        }
    }

    /**
     * @description helper function to coalesce String values
     * @param accountObject Account value to be returned if not null with highest priority
     * @param orderCountry String value to be returned if not null with lowest priority
     */
    public static String coalesceCountry(Account accountObject, String orderCountry) {
        if (accountObject != null && accountObject.ParentId != null && accountObject.parent.BillingCountry != null) {
            return accountObject.parent.BillingCountry;
        } else if (accountObject != null && accountObject.BillingCountry != null) {
            return accountObject.BillingCountry;
        } else if (orderCountry != null) {
            return orderCountry;
        } else {
            return '';
        }
    }

    /**
     * @description helper function to coalesce String values
     * @param accountObject Account value to be returned if not null with highest priority
     * @param orderState String value to be returned if not null with lowest priority
     */
    public static String coalesceState(Account accountObject, String orderState) {
        if (accountObject != null && accountObject.parent != null && accountObject.parent.BillingState != null) {
            return accountObject.parent.BillingState;
        } else if (accountObject != null && accountObject.BillingState != null) {
            return accountObject.BillingState;
        } else if (orderState != null) {
            return orderState;
        } else {
            return '';
        }
    }

    /**
     * @description creates an OpsOrder object any time a new order comes in
     * if one already exisits, then update instead
     * @param newOrdersERPList List of Order objects to be inserted (before insert) or updated (before update)
     */

    public static void upsertOpsOrder(list<Order_ERP__C> newOrdersERPList) {
        Set<String> orderIdSet = new Set<String>();
        Set<String> caseManagerSet = new Set<String>();
        Set<String> parentOpsOrderIdSet = new Set<String>();

        for (Order_ERP__C o : newOrdersERPList) {
            if (o.Xometry_ERP_ID__c != null) {
                orderIdSet.add(o.Xometry_ERP_ID__c);
                caseManagerSet.add(o.CaseManager__c);
                if (o.ParentOpsOrderID__c != null) {
                    parentOpsOrderIdSet.add(o.ParentOpsOrderID__c);
                }
            }
        }

        if (!orderIdSet.isEmpty()) {
            Map<String, Ops_Order__c> existingOpsOrdersMap = new Map<String, Ops_Order__c>();
            for (Ops_Order__c o : [
                SELECT Id, XometryOpsOrderID__c, Stage__c
                FROM Ops_Order__c
                WHERE XometryOpsOrderID__c IN :orderIdSet
            ]) {
                existingOpsOrdersMap.put(o.XometryOpsOrderID__c, o);
            }

            Map<String, Ops_Order__c> opsOrderMap = new Map<String, Ops_Order__c>();
            Map<String, ID> caseManagerMap = getCaseManagers(caseManagerSet);
            Map<String, ID> parentOpsOrderMap = getParentOpsOrder(parentOpsOrderIdSet);
            List<Order_ERP__C> childrenSameBatchAsParentList = new List<Order_ERP__C>();
            Set<String> parentOrdersinSameBatch = new Set<String>();
            for (Order_ERP__C o : newOrdersERPList) {
                if (existingOpsOrdersMap.containsKey(o.Xometry_ERP_ID__c)) {
                    if (existingOpsOrdersMap.get(o.Xometry_ERP_ID__c).Stage__c == 'Complete') {
                        existingOpsOrdersMap.get(o.Xometry_ERP_ID__c).Stage__c = 'Reopened by Updated Order';
                    }
                    Ops_Order__c oo = existingOpsOrdersMap.get(o.Xometry_ERP_ID__C);
                    oo.LineItemCount__c = o.LineItemCount__c;
                    oo.POD__c = o.POD__c;
                    oo.CaseManager__c = caseManagerMap.get(o.CaseManager__c);
                    oo.CustomerNotes__c = o.CustomerNotes__c;
                    oo.DFMDescription__c = o.DFMDescription__c;
                    oo.DFMRecommendation__c = o.DFMRecommendation__c;
                    oo.OrderDueDate__c = o.OrderDueDate__c;
                    oo.ERPStatus__c = o.ERP_Status__c;
                    oo.LineItemCount__c = o.LineItemCount__c;
                    oo.MadeInChina__c = o.MadeInChina__c;
                    oo.QuoteType__c = o.Quote_Type__c;
                    oo.ManufacturingProcess__c = o.Manufacturing_Process__c;
                    oo.OrderTotal__C = o.Order_Total__c;
                    oo.OriginalDeliveryDate__c = o.OriginalDeliveryDate__c;
                    oo.OriginalDueDate__c = o.OriginalDueDate__c;
                    oo.Order_Date__C = o.Order_ERP_CreatedDate__C;
                    oo.Order_DateTime__c = o.Order_ERP_Time__c;
                    if (parentOpsOrderMap.containsKey(o.ParentOpsOrderID__c)) {
                        oo.ParentOpsOrder__c = parentOpsOrderMap.get(o.ParentOpsOrderID__c);
                    } else {
                        parentOrdersinSameBatch.add(o.ParentOpsOrderID__c);
                        childrenSameBatchAsParentList.add(o);
                    }
                    oo.PONumber__c = o.PONumber__c;
                    oo.PricingTier__c = o.PricingTier__c;
                    oo.ShippingService__c = o.ShippingService__c;
                    oo.ShippingMethod__c = o.ShippingMethod__c;
                    oo.RoboOutsource__c = o.RoboOutsource__c;
                    oo.AdditionalRequirements__c = o.AdditionalRequirements__c;
                    oo.ISSTAINLESSSTEEL_MAT__c = o.ISSTAINLESSSTEEL_MAT__c;
                    oo.ISALUM_MAT__c = o.ISALUM_MAT__c;
                    oo.EUD_MissingEndUseData__c = o.EUD_MissingEndUseData__c;
                    oo.AllOrdersTotal__c = o.AllOrdersTotal__c;
                    oo.Account_Domain__c = o.Account_Domain__c;
                    oo.AcceptedJobValue__c = o.AcceptedJobValue__c;
                    oo.AcceptedPartValue__c = o.AcceptedPartValue__c;
                    oo.AsanaERPFlag__c = o.AsanaERPFlag__c;
                    oo.processGroup_isAdditiveOnly__c = o.processGroup_isAdditiveOnly__c;
                    oo.processGroup_isSubtractiveOnly__c = o.processGroup_isSubtractiveOnly__c;
                    oo.processGroup_isMixed__c = o.processGroup_isMixed__c;
                    oo.ContainsCustomFinish__c = o.ContainsCustomFinish__c;
                    oo.Bad_Outcomes_Highest_Probability__c = o.Bad_Outcomes_Highest_Probability__c;
                    oo.Bad_Outcomes_Manage_Result__c = o.Bad_Outcomes_Manage_Result__c;
                    oo.Bad_Outcomes_Type__c = o.Bad_Outcomes_Type__c;
                    oo.Bad_Outcomes_Daily_Tier__c = o.Bad_Outcomes_Daily_Tier__c;
                    opsOrderMap.put(o.Xometry_ERP_ID__c, oo);
                } else {
                    Ops_Order__c newOpsOrder = new Ops_Order__c();
                    newOpsOrder.Name = o.Xometry_ERP_ID__c;
                    newOpsOrder.XometryOpsOrderID__c = o.Xometry_ERP_ID__c;
                    newOpsOrder.Xometry_Quote_ID__c = o.Xometry_Quote_ID__c;
                    newOpsOrder.POD__c = o.POD__c;
                    newOpsOrder.CaseManager__c = caseManagerMap.get(o.CaseManager__c);
                    newOpsOrder.CustomerNotes__c = o.CustomerNotes__c;
                    newOpsOrder.DFMDescription__c = o.DFMDescription__c;
                    newOpsOrder.DFMRecommendation__c = o.DFMRecommendation__c;
                    newOpsOrder.OrderDueDate__c = o.OrderDueDate__c;
                    newOpsOrder.ERPStatus__c = o.ERP_Status__c;
                    newOpsOrder.LineItemCount__c = o.LineItemCount__c;
                    newOpsOrder.MadeInChina__c = o.MadeInChina__c;
                    newOpsOrder.QuoteType__c = o.Quote_Type__c;
                    newOpsOrder.ManufacturingProcess__c = o.Manufacturing_Process__c;
                    newOpsOrder.OrderTotal__C = o.Order_Total__c;
                    newOpsOrder.OriginalDeliveryDate__c = o.OriginalDeliveryDate__c;
                    newOpsOrder.OriginalDueDate__c = o.OriginalDueDate__c;
                    newOpsOrder.Order_Date__C = o.Order_ERP_CreatedDate__C;
                    newOpsOrder.Order_DateTime__c = o.Order_ERP_Time__c;
                    if (parentOpsOrderMap.containsKey(o.ParentOpsOrderID__c)) {
                        newOpsOrder.ParentOpsOrder__c = parentOpsOrderMap.get(o.ParentOpsOrderID__c);
                    } else {
                        parentOrdersinSameBatch.add(o.ParentOpsOrderID__c);
                        childrenSameBatchAsParentList.add(o);
                    }
                    newOpsOrder.PONumber__c = o.PONumber__c;
                    newOpsOrder.PricingTier__c = o.PricingTier__c;
                    newOpsOrder.ShippingService__c = o.ShippingService__c;
                    newOpsOrder.ShippingMethod__c = o.ShippingMethod__c;
                    newOpsOrder.RoboOutsource__c = o.RoboOutsource__c;
                    newOpsOrder.PricingTier__c = o.PricingTier__c;
                    newOpsOrder.Opportunity__c = o.OpportunityID__c;
                    newOpsOrder.AdditionalRequirements__c = o.AdditionalRequirements__c;
                    newOpsOrder.ISSTAINLESSSTEEL_MAT__c = o.ISSTAINLESSSTEEL_MAT__c;
                    newOpsOrder.ISALUM_MAT__c = o.ISALUM_MAT__c;
                    newOpsOrder.EUD_MissingEndUseData__c = o.EUD_MissingEndUseData__c;
                    newOpsOrder.AllOrdersTotal__c = o.AllOrdersTotal__c;
                    newOpsOrder.Account_Domain__c = o.Account_Domain__c;
                    newOpsOrder.AcceptedJobValue__c = o.AcceptedJobValue__c;
                    newOpsOrder.AcceptedPartValue__c = o.AcceptedPartValue__c;
                    newOpsOrder.AsanaERPFlag__c = o.AsanaERPFlag__c;
                    newOpsOrder.processGroup_isAdditiveOnly__c = o.processGroup_isAdditiveOnly__c;
                    newOpsOrder.processGroup_isSubtractiveOnly__c = o.processGroup_isSubtractiveOnly__c;
                    newOpsOrder.processGroup_isMixed__c = o.processGroup_isMixed__c;
                    newOpsOrder.ContainsCustomFinish__c = o.ContainsCustomFinish__c;
                    newOpsOrder.Bad_Outcomes_Highest_Probability__c = o.Bad_Outcomes_Highest_Probability__c;
                    newOpsOrder.Bad_Outcomes_Manage_Result__c = o.Bad_Outcomes_Manage_Result__c;
                    newOpsOrder.Bad_Outcomes_Type__c = o.Bad_Outcomes_Type__c;
                    newOpsOrder.Bad_Outcomes_Daily_Tier__c = o.Bad_Outcomes_Daily_Tier__c;
                    opsOrderMap.put(o.Xometry_ERP_ID__c, newOpsOrder);
                }
            }

            DatabaseUtilities.upsertToDatabase(
                opsOrderMap.values(),
                'OrderERPHandler.upsertOpsOrder',
                'Did not associate to managed services order'
            );

            for (Order_ERP__C o : newOrdersERPList) {
                o.Ops_Order__c = opsOrderMap.get(o.Xometry_ERP_ID__c).Id;
            }

            //If the children are in the same batch as the parents then update the OpsOrder accordingly
            if (!childrenSameBatchAsParentList.isEmpty()) {
                Map<ID, Ops_Order__C> opsOrderChildrenUpdateMap = new Map<ID, Ops_Order__C>();
                Map<String, ID> parentOpsOrderMapPostInsert = getParentOpsOrder(parentOpsOrderIdSet);
                for (Order_ERP__C o : childrenSameBatchAsParentList) {
                    Ops_Order__c updateOpsOrder = new Ops_Order__c();
                    updateOpsOrder.ID = o.Ops_Order__c;
                    updateOpsOrder.ParentOpsOrder__c = parentOpsOrderMapPostInsert.get(o.ParentOpsOrderID__c);
                    opsOrderChildrenUpdateMap.put(updateOpsOrder.ID, updateOpsOrder);
                }

                DatabaseUtilities.upsertToDatabase(
                    opsOrderChildrenUpdateMap.values(),
                    'OrderERPHandler.upsertOpsOrder',
                    'Did not link children to parent Ops Orders'
                );
            }
        }
    }

    /**
     * @description Retrieves all Ops Orders associated with an Order with updated field
     * @param updatedOrders List of Order objects updated in Salesforce
     * @param oldOrderMap map of orders changed by the update
     * @return List of updated Opportunities with updated Amount (Price)
     */
    public static void updateOpsOrder(List<Order_ERP__C> updatedOrders, Map<ID, Order_ERP__C> oldOrderMap) {
        // Set of Orders to look up all associated Ops Orders, Map of Orders to matching
        Set<String> newOrderSet = new Set<String>();
        Map<String, Order_ERP__C> orderMap = new Map<String, Order_ERP__C>();
        Set<String> caseManagerSet = new Set<String>();
        Set<String> parentOpsOrderIdSet = new Set<String>();

        Set<Ops_Order__c> updatedOpsOrderSet = new Set<Ops_Order__c>();
        List<Ops_Order__c> opsOrdersUpdateList = new List<Ops_Order__c>();
        Map<String, Ops_Order__c> opsOrderMap = new Map<String, Ops_Order__c>();

        for (Order_ERP__C order : updatedOrders) {
            Order_ERP__c oldOrder = oldOrderMap.get(order.ID);
            if (
                oldOrder.Ops_Order__c == null ||
                oldOrder.Order_Total__c != order.Order_Total__c ||
                oldOrder.POD__c != order.POD__c ||
                oldOrder.CaseManager__c != order.CaseManager__c ||
                oldOrder.CustomerNotes__c != order.CustomerNotes__c ||
                oldOrder.DFMDescription__c != order.DFMDescription__c ||
                oldOrder.DFMRecommendation__c != order.DFMRecommendation__c ||
                oldOrder.OrderDueDate__c != order.OrderDueDate__c ||
                oldOrder.ERP_Status__c != order.ERP_Status__c ||
                oldOrder.LineItemCount__c != order.LineItemCount__c ||
                oldOrder.MadeInChina__c != order.MadeInChina__c ||
                oldOrder.Quote_Type__c != order.Quote_Type__c ||
                oldOrder.Manufacturing_Process__c != order.Manufacturing_Process__c ||
                oldOrder.process_isCarbon__c != order.process_isCarbon__c ||
                oldOrder.process_isCNC_Machining__c != order.process_isCNC_Machining__c ||
                oldOrder.process_isDie_Casting__c != order.process_isDie_Casting__c ||
                oldOrder.process_isDirect_Sourced__c != order.process_isDirect_Sourced__c ||
                oldOrder.process_isDMLS__c != order.process_isDMLS__c ||
                oldOrder.process_isExtrusion__c != order.process_isExtrusion__c ||
                oldOrder.process_isFDM__c != order.process_isFDM__c ||
                oldOrder.process_isHPMultJetFusion__c != order.process_isHPMultJetFusion__c ||
                oldOrder.process_isInjection_Molding__c != order.process_isInjection_Molding__c ||
                oldOrder.process_isInjectionMoldingTool__c != order.process_isInjectionMoldingTool__c ||
                oldOrder.process_isPolyJet_3D__c != order.process_isPolyJet_3D__c ||
                oldOrder.process_isPlasticExtrusion__c != order.process_isPlasticExtrusion__c ||
                oldOrder.process_isSheet_metal__c != order.process_isSheet_metal__c ||
                oldOrder.process_isSLA__c != order.process_isSLA__c ||
                oldOrder.process_isSLS__c != order.process_isSLS__c ||
                oldOrder.process_isStamping__c != order.process_isStamping__c ||
                oldOrder.process_isUrethane_Casting__c != order.process_isUrethane_Casting__c ||
                oldOrder.process_isBinderJetting__c != order.process_isBinderJetting__c ||
                oldOrder.process_isSheetCutting__c != order.process_isSheetCutting__c ||
                oldOrder.process_isTubeBending__c != order.process_isTubeBending__c ||
                oldOrder.process_isTubeCutting__c != order.process_isTubeCutting__c ||
                oldOrder.process_isOther__c != order.process_isOther__c ||
                oldOrder.process_isOther_NotIncluded__c != order.process_isOther_NotIncluded__c ||
                oldOrder.process_isLSPc__c != order.process_isLSPc__c ||
                oldOrder.process_isAssembly__c != order.process_isAssembly__c ||
                oldOrder.OriginalDeliveryDate__c != order.OriginalDeliveryDate__c ||
                oldOrder.OriginalDueDate__c != order.OriginalDueDate__c ||
                oldOrder.ParentOpsOrderID__c != order.ParentOpsOrderID__c ||
                oldOrder.PONumber__c != order.PONumber__c ||
                oldOrder.PricingTier__c != order.PricingTier__c ||
                oldOrder.ShippingService__c != order.ShippingService__c ||
                oldOrder.ShippingMethod__c != order.ShippingMethod__c ||
                oldOrder.RoboOutsource__c != order.RoboOutsource__c ||
                oldOrder.AdditionalRequirements__c != order.AdditionalRequirements__c ||
                oldOrder.ISSTAINLESSSTEEL_MAT__c != order.ISSTAINLESSSTEEL_MAT__c ||
                oldOrder.ISALUM_MAT__c != order.ISALUM_MAT__c ||
                oldOrder.EUD_MissingEndUseData__c != order.EUD_MissingEndUseData__c ||
                oldOrder.AllOrdersTotal__c != order.AllOrdersTotal__c ||
                oldOrder.AcceptedJobValue__c != order.AcceptedJobValue__c ||
                oldOrder.AcceptedPartValue__c != order.AcceptedPartValue__c ||
                oldOrder.AsanaERPFlag__c != order.AsanaERPFlag__c ||
                oldOrder.processGroup_isAdditiveOnly__c != order.processGroup_isAdditiveOnly__c ||
                oldOrder.processGroup_isSubtractiveOnly__c != order.processGroup_isSubtractiveOnly__c ||
                oldOrder.processGroup_isMixed__c != order.processGroup_isMixed__c ||
                oldOrder.ContainsCustomFinish__c != order.ContainsCustomFinish__c ||
                oldOrder.Bad_Outcomes_Highest_Probability__c != order.Bad_Outcomes_Highest_Probability__c ||
                oldOrder.Bad_Outcomes_Manage_Result__c != order.Bad_Outcomes_Manage_Result__c ||
                oldOrder.Bad_Outcomes_Type__c != order.Bad_Outcomes_Type__c ||
                oldOrder.Bad_Outcomes_Daily_Tier__c != order.Bad_Outcomes_Daily_Tier__c
            ) {
                newOrderSet.add(order.Xometry_ERP_ID__C);
                orderMap.put(order.Xometry_ERP_ID__C, order);
                caseManagerSet.add(order.CaseManager__c);
                if (order.ParentOpsOrderID__c != null) {
                    parentOpsOrderIdSet.add(order.ParentOpsOrderID__c);
                }
            }
        }

        if (!newOrderset.isEmpty()) {
            Map<String, ID> caseManagerMap = getCaseManagers(caseManagerSet);
            Map<String, ID> parentOpsOrderMap = getParentOpsOrder(parentOpsOrderIdSet);

            List<Ops_Order__c> opsOrderFetchList = [
                SELECT ID, XometryOpsOrderID__c
                FROM Ops_Order__c
                WHERE XometryOpsOrderID__c IN :newOrderset AND XometryOpsOrderID__c != NULL
            ];

            for (Ops_Order__c oo : opsOrderFetchList) {
                if (orderMap.containsKey(oo.XometryOpsOrderID__c)) {
                    Order_ERP__c o = orderMap.get(oo.XometryOpsOrderID__c);
                    oo.POD__c = o.POD__c;
                    oo.CaseManager__c = caseManagerMap.get(o.CaseManager__c);
                    oo.CustomerNotes__c = o.CustomerNotes__c;
                    oo.DFMDescription__c = o.DFMDescription__c;
                    oo.DFMRecommendation__c = o.DFMRecommendation__c;
                    oo.OrderDueDate__c = o.OrderDueDate__c;
                    oo.ERPStatus__c = o.ERP_Status__c;
                    oo.LineItemCount__c = o.LineItemCount__c;
                    oo.MadeInChina__c = o.MadeInChina__c;
                    oo.QuoteType__c = o.Quote_Type__c;
                    oo.ManufacturingProcess__c = o.Manufacturing_Process__c;
                    oo.OrderTotal__C = o.Order_Total__c;
                    oo.OriginalDeliveryDate__c = o.OriginalDeliveryDate__c;
                    oo.OriginalDueDate__c = o.OriginalDueDate__c;
                    oo.ParentOpsOrder__c = parentOpsOrderMap.get(o.ParentOpsOrderID__c);
                    oo.PONumber__c = o.PONumber__c;
                    oo.PricingTier__c = o.PricingTier__c;
                    oo.ShippingService__c = o.ShippingService__c;
                    oo.ShippingMethod__c = o.ShippingMethod__c;
                    oo.RoboOutsource__c = o.RoboOutsource__c;
                    oo.PricingTier__c = o.PricingTier__c;
                    oo.AdditionalRequirements__c = o.AdditionalRequirements__c;
                    oo.ISSTAINLESSSTEEL_MAT__c = o.ISSTAINLESSSTEEL_MAT__c;
                    oo.ISALUM_MAT__c = o.ISALUM_MAT__c;
                    oo.EUD_MissingEndUseData__c = o.EUD_MissingEndUseData__c;
                    oo.AllOrdersTotal__c = o.AllOrdersTotal__c;
                    oo.Account_Domain__c = o.Account_Domain__c;
                    oo.AcceptedJobValue__c = o.AcceptedJobValue__c;
                    oo.AcceptedPartValue__c = o.AcceptedPartValue__c;
                    oo.AsanaERPFlag__c = o.AsanaERPFlag__c;
                    oo.processGroup_isAdditiveOnly__c = o.processGroup_isAdditiveOnly__c;
                    oo.processGroup_isSubtractiveOnly__c = o.processGroup_isSubtractiveOnly__c;
                    oo.processGroup_isMixed__c = o.processGroup_isMixed__c;
                    oo.ContainsCustomFinish__c = o.ContainsCustomFinish__c;
                    oo.Bad_Outcomes_Highest_Probability__c = o.Bad_Outcomes_Highest_Probability__c;
                    oo.Bad_Outcomes_Manage_Result__c = o.Bad_Outcomes_Manage_Result__c;
                    oo.Bad_Outcomes_Type__c = o.Bad_Outcomes_Type__c;
                    oo.Bad_Outcomes_Daily_Tier__c = o.Bad_Outcomes_Daily_Tier__c;
                    updatedOpsOrderSet.add(oo);
                    if (o.Ops_Order__c == null) {
                        o.Ops_Order__c = oo.Id;
                    }
                }
            }

            if (opsOrderFetchList.size() != newOrderSet.size()) {
                for (Order_ERP__c o : orderMap.values()) {
                    if (o.Ops_Order__c == null) {
                        Ops_Order__c newOpsOrder = new Ops_Order__c();
                        newOpsOrder.Name = o.Xometry_ERP_ID__c;
                        newOpsOrder.XometryOpsOrderID__c = o.Xometry_ERP_ID__c;
                        newOpsOrder.Xometry_Quote_ID__c = o.Xometry_Quote_ID__c;
                        newOpsOrder.POD__c = o.POD__c;
                        newOpsOrder.CaseManager__c = caseManagerMap.get(o.CaseManager__c);
                        newOpsOrder.CustomerNotes__c = o.CustomerNotes__c;
                        newOpsOrder.DFMDescription__c = o.DFMDescription__c;
                        newOpsOrder.DFMRecommendation__c = o.DFMRecommendation__c;
                        newOpsOrder.OrderDueDate__c = o.OrderDueDate__c;
                        newOpsOrder.ERPStatus__c = o.ERP_Status__c;
                        newOpsOrder.LineItemCount__c = o.LineItemCount__c;
                        newOpsOrder.MadeInChina__c = o.MadeInChina__c;
                        newOpsOrder.QuoteType__c = o.Quote_Type__c;
                        newOpsOrder.ManufacturingProcess__c = o.Manufacturing_Process__c;
                        newOpsOrder.OrderTotal__C = o.Order_Total__c;
                        newOpsOrder.OriginalDeliveryDate__c = o.OriginalDeliveryDate__c;
                        newOpsOrder.OriginalDueDate__c = o.OriginalDueDate__c;
                        newOpsOrder.ParentOpsOrder__c = parentOpsOrderMap.get(o.ParentOpsOrderID__c);
                        newOpsOrder.PONumber__c = o.PONumber__c;
                        newOpsOrder.PricingTier__c = o.PricingTier__c;
                        newOpsOrder.ShippingService__c = o.ShippingService__c;
                        newOpsOrder.ShippingMethod__c = o.ShippingMethod__c;
                        newOpsOrder.RoboOutsource__c = o.RoboOutsource__c;
                        newOpsOrder.PricingTier__c = o.PricingTier__c;
                        newOpsOrder.AdditionalRequirements__c = o.AdditionalRequirements__c;
                        newOpsOrder.ISSTAINLESSSTEEL_MAT__c = o.ISSTAINLESSSTEEL_MAT__c;
                        newOpsOrder.ISALUM_MAT__c = o.ISALUM_MAT__c;
                        newOpsOrder.EUD_MissingEndUseData__c = o.EUD_MissingEndUseData__c;
                        newOpsOrder.AllOrdersTotal__c = o.AllOrdersTotal__c;
                        newOpsOrder.Account_Domain__c = o.Account_Domain__c;
                        newOpsOrder.AcceptedJobValue__c = o.AcceptedJobValue__c;
                        newOpsOrder.AcceptedPartValue__c = o.AcceptedPartValue__c;
                        newOpsOrder.AsanaERPFlag__c = o.AsanaERPFlag__c;
                        newOpsOrder.processGroup_isAdditiveOnly__c = o.processGroup_isAdditiveOnly__c;
                        newOpsOrder.processGroup_isSubtractiveOnly__c = o.processGroup_isSubtractiveOnly__c;
                        newOpsOrder.processGroup_isMixed__c = o.processGroup_isMixed__c;
                        newOpsOrder.ContainsCustomFinish__c = o.ContainsCustomFinish__c;
                        newOpsOrder.Bad_Outcomes_Highest_Probability__c = o.Bad_Outcomes_Highest_Probability__c;
                        newOpsOrder.Bad_Outcomes_Manage_Result__c = o.Bad_Outcomes_Manage_Result__c;
                        newOpsOrder.Bad_Outcomes_Type__c = o.Bad_Outcomes_Type__c;
                        newOpsOrder.Bad_Outcomes_Daily_Tier__c = o.Bad_Outcomes_Daily_Tier__c;
                        updatedOpsOrderSet.add(newOpsOrder);
                        opsOrderMap.put(o.Xometry_ERP_ID__c, newOpsOrder);
                    }
                }
            }

            opsOrdersUpdateList.addAll(updatedOpsOrderSet);
        }

        DatabaseUtilities.upsertToDatabase(
            opsOrdersUpdateList,
            'OrderERPHandler.updateOpsOrder',
            'Did not update Ops Order from Order ERP'
        );

        for (Order_ERP__C o : updatedOrders) {
            if (opsOrderMap.get(o.Xometry_ERP_ID__c) != null) {
                o.Ops_Order__c = opsOrderMap.get(o.Xometry_ERP_ID__c).Id;
            }
        }
    }

    /**
     * Gets Case Manager IDs
     * @param caseManagerSet
     *
     */
    public static Map<String, ID> getCaseManagers(Set<String> caseManagerNameSet) {
        Map<String, ID> caseManagersMap = new Map<String, ID>();

        if (!caseManagerNameSet.isEmpty()) {
            for (User u : [SELECT Name, Id FROM User WHERE Name IN :caseManagerNameSet AND IsActive = TRUE]) {
                caseManagersMap.put(u.name, u.Id);
            }
        }

        return caseManagersMap;
    }

    /**
     * Gets Parents Ops Order IDs
     * @param ParentOpsOrderIDSet
     * @return Map of Ops Order Xometry Order ID to Parent Ops Order Object Id
     */
    public static Map<String, ID> getParentOpsOrder(Set<String> parentOpsOrderIdSet) {
        Map<String, ID> parentOpsOrderMap = new Map<String, ID>();
        if (!parentOpsOrderIdSet.isEmpty()) {
            for (Ops_Order__C oo : [
                SELECT XometryOpsOrderID__c, Id
                FROM Ops_Order__c
                WHERE XometryOpsOrderID__c IN :parentOpsOrderIdSet AND XometryOpsOrderID__c != NULL
            ]) {
                parentOpsOrderMap.put(oo.XometryOpsOrderID__c, oo.Id);
            }
        }
        return parentOpsOrderMap;
    }

    /**
     * @description Creates EUD Cases for Orders Missing End Use Data
     * @param newOrdersList new ERP ORders
     */
    public static void checkForMissingEUD(List<Order_ERP__C> newOrdersList) {
        Set<String> orderIdSet = new Set<String>();
        dateTime eudLaunchTime = datetime.newInstanceGMT(2022, 4, 14, 0, 0, 0);

        for (Order_ERP__c o : newOrdersList) {
            if (o.EUD_MissingEndUseData__c && o.Order_ERP_Time__c > eudLaunchTime) {
                orderIdSet.add(o.Xometry_ERP_ID__c);
            }
        }

        if (!orderIdSet.isEmpty()) {
            Set<String> ordersWithEUDCaseSet = new Set<String>();
            for (Case eudCase : [
                SELECT ID, ShadowXometryOrderID__c
                FROM Case
                WHERE Category__c = 'End-use definition' AND ShadowXometryOrderID__c IN :orderIdSet
            ]) {
                orderIdSet.remove(eudCase.ShadowXometryOrderID__c);
            }

            List<Order_ERP__c> missingEUDOrdersList = new List<Order_ERP__c>();
            if (!orderIdSet.isEmpty()) {
                for (Order_ERP__c missingEUDCaseOrder : newOrdersList) {
                    if (orderIdSet.contains(missingEUDCaseOrder.Xometry_ERP_ID__c)) {
                        missingEUDOrdersList.add(missingEUDCaseOrder);
                    }
                }
                createEUDCase(missingEUDOrdersList);

                for (Order_ERP__c updatedOrd : missingEUDOrdersList) {
                    updatedOrd.EUD_HasCase__c = true;
                }
            }
        }
    }

    /**
     * @description Retrieves all EUD Cases associated with an Order with updated EUD field
     * @param updatedOrders List of Order objects updated in Salesforce
     * @param oldOrderMap map of orders changed by the update
     */
    public static void updateEUDCase(List<Order_ERP__C> updatedOrders, Map<ID, Order_ERP__C> oldOrderMap) {
        Set<String> orderIdSet = new Set<String>();
        Set<String> newEUDOrderIdSet = new Set<String>();
        List<Order_ERP__c> ordersNeedingEUDCaseList = new List<Order_ERP__C>();
        List<Order_ERP__c> updatedEUDOrderList = new List<Order_ERP__c>();
        // LaunchTime for EudData in Salesforce
        dateTime eudLaunchTime = datetime.newInstanceGMT(2022, 4, 14, 0, 0, 0);
        for (Order_ERP__C order : updatedOrders) {
            orderIdSet.add(order.Xometry_ERP_ID__c);
            if (order.EUD_MissingEndUseData__c) {
                newEUDOrderIdSet.add(order.Xometry_ERP_ID__c);
            }
        }

        Map<String, Case> existingEUDCaseMap = new Map<String, Case>();
        for (Case existingCase : [
            SELECT Id, ShadowXometryOrderID__c, EUD_MissingEndUseData__c
            FROM Case
            WHERE Category__c = 'End-use definition' AND ShadowXometryOrderID__c IN :orderIdSet
        ]) {
            existingEUDCaseMap.put(existingCase.ShadowXometryOrderID__c, existingCase);
            newEUDOrderIdSet.remove(existingCase.ShadowXometryOrderID__c);
        }

        for (Order_ERP__C order : updatedOrders) {
            Order_ERP__c oldOrder = oldOrderMap.get(order.ID);
            // If the order was not previously missing EUD but now is, and there isn't already an existing EUD Case for the order
            //Create a new EUD Case
            // Adding a Safety Check for Order Time so older Orders that have been completed do no create EUDcases.
            if (
                order.EUD_MissingEndUseData__c &&
                !oldOrder.EUD_MissingEndUseData__c &&
                newEUDOrderIdSet.contains(order.Xometry_ERP_ID__c) &&
                order.Order_ERP_Time__c > eudLaunchTime
            ) {
                ordersNeedingEUDCaseList.add(order);
            }
            if (existingEUDCaseMap.containsKey(order.Xometry_ERP_ID__c)) {
                // If the all EUD data has been completed OR any of the EUD components have been updated
                if (
                    (!order.EUD_MissingEndUseData__c &&
                    existingEUDCaseMap.get(order.Xometry_ERP_ID__c).EUD_MissingEndUseData__c) ||
                    (order.EUD_MissingEndUseData__c &&
                    (oldOrder.EUD_HTSCode__c != order.EUD_HTSCode__c ||
                    oldOrder.EUD_ImportReason__c != order.EUD_ImportReason__c ||
                    oldOrder.EUD_Industry__c != order.EUD_Industry__c ||
                    oldOrder.EUD_PartDescription__c != order.EUD_PartDescription__c ||
                    oldOrder.EUD_LineItemBreakdown__c != order.EUD_LineItemBreakdown__c ||
                    oldOrder.EUD_OriginCountry__c != order.EUD_OriginCountry__c))
                ) {
                    updatedEUDOrderList.add(order);
                }
            }
        }

        if (!ordersNeedingEUDCaseList.isEmpty()) {
            createEUDCase(ordersNeedingEUDCaseList);
            for (Order_ERP__c updatedOrd : ordersNeedingEUDCaseList) {
                updatedOrd.EUD_HasCase__c = true;
            }
        }

        if (!updatedEUDOrderList.isEmpty()) {
            Set<Case> updatedCaseSet = new Set<Case>();
            Set<ID> updatedCaseIDSet = new Set<ID>();
            List<Case> caseUpdateList = new List<Case>();
            Map<String, List<String>> orderIDToLineItemsListMap = new Map<String, List<String>>();
            List<Case> existingEudCaseList = new List<Case>();
            for (Order_ERP__c ord : updatedEUDOrderList) {
                Case eudCase = existingEUDCaseMap.get(ord.Xometry_ERP_ID__C);
                eudCase.EUD_MissingEndUseData__c = ord.EUD_MissingEndUseData__c;
                eudCase.EUD_HTSCode__c = ord.EUD_HTSCode__c;
                eudCase.EUD_ImportReason__c = ord.EUD_ImportReason__c;
                eudCase.EUD_Industry__c = ord.EUD_Industry__c;
                eudCase.EUD_PartDescription__c = ord.EUD_PartDescription__c;
                eudCase.EUD_LineItemBreakdown__c = ord.EUD_LineItemBreakdown__c;
                eudCase.EUD_OriginCountry__c = ord.EUD_OriginCountry__c;
                updatedCaseSet.add(eudCase);
                updatedCaseIDSet.add(eudCase.Id);

                List<String> lineItemStrings = new List<String>();
                if (!String.isBlank(ord.EUD_LineItemBreakdown__c)) {
                    for (String lineItem : ord.EUD_LineItemBreakdown__c.split(';')) {
                        String formattedLineItem = lineItem.trim();
                        lineItemStrings.add(formattedLineItem);
                    }
                } else {
                    lineItemStrings.add('');
                }

                orderIDToLineItemsListMap.put(ord.Xometry_ERP_ID__c, lineItemStrings);
            }
            caseUpdateList.addAll(updatedCaseSet);

            DatabaseUtilities.upsertToDatabase(
                caseUpdateList,
                'OrderERPHandler.updateEUDCase',
                'Did not update EUD case from updated Order ERP'
            );
            Map<String, String> lineItemTitleToBodyMap = new Map<String, String>();
            Map<String, Id> orderIdToEUDCaseMap = new Map<String, Id>();
            for (Case c : caseUpdateList) {
                orderIdToEUDCaseMap.put(c.ShadowXometryOrderID__c, c.ID);
            }

            upsertPartInfo(orderIdToEUDCaseMap, orderIDToLineItemsListMap);
        }
    }

    /**
     * Creates Cases for Orders Missing End Use Data
     * @param OrdersNeedingEUDCaseList
     */
    public static void createEUDcase(List<Order_ERP__c> OrdersNeedingEUDCaseList) {
        Set<Case> eudCaseSet = new Set<Case>();
        List<Case> eudCaseList = new List<Case>();
        List<Group> eudGroup = [SELECT ID FROM Group WHERE DeveloperName = 'EUD_Queue'];
        Id eudQueueID = eudGroup[0].ID;
        Map<String, List<String>> orderIDToLineItemListMap = new Map<String, List<String>>();
        for (Order_ERP__c o : OrdersNeedingEUDCaseList) {
            Case eudCase = new Case();
            eudCase.RecordTypeId = caseGeneralSupportRTypeId;
            eudCase.OwnerId = eudQueueID;
            eudCase.AccountId = o.AccountID__c;
            eudCase.ContactId = o.ContactID__c;
            eudCase.Subject = o.Xometry_ERP_ID__c + ' Missing End Use Data';
            eudCase.GNOOrder__c = o.Ops_Order__c;
            eudCase.OrderID__c = o.Xometry_ERP_ID__c;
            eudCase.ShadowXometryOrderID__c = o.Xometry_ERP_ID__c;
            eudCase.Shadow_Xometry_ERP_ID__c = o.Xometry_Quote_ID__c;
            eudCase.Opportunity__c = o.OpportunityID__c;
            eudCase.SuppliedEmail = o.Order_Email__c;
            eudCase.SuppliedPhone = o.ERP_Contact_Phone__c;
            eudCase.Origin = 'Internal';
            eudCase.Category__c = 'End-use definition';
            eudCase.EUD_MissingEndUseData__c = o.EUD_MissingEndUseData__c;
            eudCase.EUD_HTSCode__c = o.EUD_HTSCode__c;
            eudCase.EUD_ImportReason__c = o.EUD_ImportReason__c;
            eudCase.EUD_Industry__c = o.EUD_Industry__c;
            eudCase.EUD_PartDescription__c = o.EUD_PartDescription__c;
            eudCase.EUD_LineItemBreakdown__c = o.EUD_LineItemBreakdown__c;
            eudCase.EUD_OriginCountry__c = O.EUD_OriginCountry__c;
            eudCaseSet.add(eudCase);

            //To bring in multiple parts for an order, we have a string of part IDs, along with their missing EUD attributes through a LISTAGG
            //The parts are separated by a comma, so we split the string by the comma and map the part to the order
            List<String> lineItemStrings = new List<String>();
            if (!String.isBlank(o.EUD_LineItemBreakdown__c)) {
                for (String lineItem : o.EUD_LineItemBreakdown__c.split(';')) {
                    String formattedLineItem = lineItem.trim();
                    lineItemStrings.add(formattedLineItem);
                }
            } else {
                lineItemStrings.add('');
            }

            orderIDToLineItemListMap.put(o.Xometry_ERP_ID__c, lineItemStrings);
        }

        eudCaseList.addAll(eudCaseSet);

        DatabaseUtilities.insertToDatabase(
            eudCaseList,
            'OrderERPHandler.createEUDCase',
            'Did not create EUD case from Order ERP with missing end use data'
        );

        Map<String, Id> orderIdToEUDCaseMap = new Map<String, Id>();
        Set<Id> eudCasepreSortIDs = new Set<Id>();
        for (Case c : eudCaseList) {
            orderIdToEUDCaseMap.put(c.ShadowXometryOrderID__c, c.ID);
            eudCasepreSortIDs.add(c.ID);
        }

        Set<Id> sortedCaseIDSet = new Set<Id>();
        List<Case> sortedCaseList = new List<Case>();
        for (Case c : [
            SELECT ID, Subject, ShadowXometryOrderID__c, Account.EUD_EmailOptOut__c, Contact.EUD_EmailOptOut__c
            FROM CASE
            WHERE ID IN :eudCasepreSortIDs
            ORDER BY AccountID, ContactID
        ]) {
            //Check to make sure the Contact or Account has not opted-out from automated EUD emails
            if (!c.Account.EUD_EmailOptOut__c && !c.Contact.EUD_EmailOptOut__c) {
                sortedCaseList.add(c);
                eudCaseNeedEmailCaseList.add(c);
                eudCaseNeedEmailMap.put(c.ID, c.ShadowXometryOrderID__c);
            }
        }
        upsertPartInfo(orderIdToEUDCaseMap, orderIDToLineItemListMap);
    }

    /**
     * Upsert parts with new/updated Missing EUD
     * @param orderIDToCaseMap Map of Order IDs to EUD Case IDs
     * @param orderIDToUpdatedLineItemListMap Map or Order IDs to a List of all Line Items
     */
    public static void upsertPartInfo(
        Map<String, ID> orderIDToCaseMap,
        Map<String, List<String>> orderIDToUpdatedLineItemListMap
    ) {
        //If the line item is no longer missing any EUD, we want to update the part to show this
        Map<String, Part_Information__c> partIDToPartInfoObjectMap = new Map<String, Part_Information__c>();
        for (Part_Information__c lineItem : [
            SELECT ID, PartID__c
            FROM Part_Information__c
            WHERE OrderID__c IN :orderIDToCaseMap.keySet()
        ]) {
            partIDToPartInfoObjectMap.put(lineItem.PartID__c, lineItem);
        }

        Set<Part_Information__c> upsertPartSet = new Set<Part_Information__c>();
        List<Part_Information__c> upsertPartList = new List<Part_Information__c>();

        for (String orderID : orderIDToUpdatedLineItemListMap.keySet()) {
            Set<String> partIDSet = new Set<String>();
            Map<String, String> partIDToEUDComponentsMap = new Map<String, String>();
            Integer i = 0;
            if (!orderIDToUpdatedLineItemListMap.get(orderID).isEmpty()) {
                for (String part : orderIDToUpdatedLineItemListMap.get(orderID)) {
                    if (!String.isBlank(orderIDToUpdatedLineItemListMap.get(orderID)[i])) {
                        String partID = part.trim().left(7);
                        partIdSet.add(partID);
                        partIDToEUDComponentsMap.put(
                            partID,
                            orderIDToUpdatedLineItemListMap.get(orderID)[i].substring(8)
                        );
                        i++;
                    }
                }
                for (String partID : partIdSet) {
                    if (partIDToPartInfoObjectMap.containsKey(partID)) {
                        Part_Information__c updatedPart = partIDToPartInfoObjectMap.get(partID);
                        if (!partIDToEUDComponentsMap.get(partID).contains('Import Reason')) {
                            updatedPart.hasImportReason__c = true;
                        }
                        if (!partIDToEUDComponentsMap.get(partID).contains('Part Description')) {
                            updatedPart.hasPartDescription__c = true;
                        }
                        if (!partIDToEUDComponentsMap.get(partID).contains('Industry')) {
                            updatedPart.hasIndustry__c = true;
                        }
                        if (!partIDToEUDComponentsMap.get(partID).contains('HTS Code')) {
                            updatedPart.hasHTSCode__c = true;
                        }
                        partIDToPartInfoObjectMap.remove(partID);
                        upsertPartSet.add(updatedPart);
                    } else {
                        Part_Information__c newPart = new Part_Information__c();
                        newPart.PartID__c = partID;
                        newPart.Name = partID;
                        newPart.Case__c = orderIDToCaseMap.get(orderID);
                        newPart.OrderID__c = orderID;
                        //The value of the string is a "list" (listagg) of the missing EUD components
                        //If the value is not in the "list", then the EUD exists
                        if (!partIDToEUDComponentsMap.get(partID).contains('Import Reason')) {
                            newPart.hasImportReason__c = true;
                        }
                        if (!partIDToEUDComponentsMap.get(partID).contains('Part Description')) {
                            newPart.hasPartDescription__c = true;
                        }
                        if (!partIDToEUDComponentsMap.get(partID).contains('Industry')) {
                            newPart.hasIndustry__c = true;
                        }
                        if (!partIDToEUDComponentsMap.get(partID).contains('HTS Code')) {
                            newPart.hasHTSCode__c = true;
                        }
                        upsertPartSet.add(newPart);
                    }
                }
            }
        }

        //Just in case a part ID is removed from the Line Item Breakdown string
        //"Complete" parts that are not missing and end use data
        if (!partIDToPartInfoObjectMap.isEmpty()) {
            for (String partID : partIDToPartInfoObjectMap.keySet()) {
                Part_Information__c completePart = partIDToPartInfoObjectMap.get(partID);
                completePart.hasImportReason__c = true;
                completePart.hasIndustry__c = true;
                completePart.hasHTSCode__c = true;
                completePart.hasPartDescription__c = true;
                upsertPartSet.add(completePart);
            }
        }

        upsertPartList.addAll(upsertPartSet);

        DatabaseUtilities.upsertToDatabase(
            upsertPartList,
            'OrderERPHandler.upsertPartInfo',
            'Part object was not upserted with EUD'
        );
    }

    /**
     * @description Keeps Case & Junction objects in sync with quote and order IDs
     * @param newOrders List of newly inserted Orders
     */
    public static void syncIDsOnRelatedObjects(Map<String, String> quoteIDToOrderIDMap) {
        List<Case> updatedCaseList = new List<Case>();
        List<CaseOpportunity__c> updatedCaseOppList = new List<CaseOpportunity__c>();

        //Cases
        for (Case c : [
            SELECT Id, Shadow_Xometry_ERP_ID__c, ShadowXometryOrderID__c
            FROM Case
            WHERE Shadow_Xometry_ERP_ID__c IN :quoteIDToOrderIDMap.keySet()
        ]) {
            c.ShadowXometryOrderID__c = quoteIDToOrderIDMap.get(c.Shadow_Xometry_ERP_ID__c);
            updatedCaseList.add(c);
        }

        DatabaseUtilities.upsertToDatabase(
            updatedCaseList,
            'OrderERPHandler.syncIDsOnRelatedObjects',
            'Did not update cases with Shadow Order IDs'
        );

        //CaseOpps
        for (CaseOpportunity__c caseOpp : [
            SELECT Id, Xometry_ERP_ID__c, Xometry_Order_ID__c
            FROM CaseOpportunity__c
            WHERE Xometry_ERP_ID__c IN :quoteIDToOrderIDMap.keySet()
        ]) {
            caseOpp.Xometry_Order_ID__c = quoteIDToOrderIDMap.get(caseOpp.Xometry_ERP_ID__c);
            updatedCaseOppList.add(caseOpp);
        }

        DatabaseUtilities.upsertToDatabase(
            updatedCaseOppList,
            'OrderERPHandler.syncIDsOnRelatedObjects',
            'Did not update caseOpps with Shadow Order IDs'
        );
    }

    /**
     * @description process Cases and send EUD emails
     * @param eudCaseIDs Cases Ids that will be processed
     * @return retryEudCaseIDs Cases Ids that will be processed
     */
    public static List<Id> sendEUDEmail(Set<Id> eudCaseIDs) {
        if (eudCaseIDs.size() > 100) {
            //throw new OtherException('This method caps its set sizes at 100');
            System.debug('This should not occur');
        }

        System.debug('Starting future email message class');
        Set<String> orderIDsInitialEmailAlreadySent = new Set<String>();
        List<Id> retryEudCaseIDs = new List<Id>();

        List<Messaging.SingleEmailMessage> sendEmails = new List<Messaging.SingleEmailMessage>();
        List<Case> eudCaseList = new List<Case>(
            [
                SELECT
                    Id,
                    SuppliedEmail,
                    ContactId,
                    ShadowXometryOrderID__c,
                    EUD_EmailTemplateHelper__c,
                    EUD_MissingEndUseData__c
                FROM Case
                WHERE Id IN :eudCaseIDs AND EUD_Work_Stage__C = 'No Reach Out Yet' AND EUD_MissingEndUseData__c = TRUE
            ]
        );
        System.debug('We have some Cases to send emails with! the size is ' + eudCaseList.size());
        Integer eudCaseListSize = eudCaseList.size();
        Integer eudEmailSentCount = 0;
        for (Case c : eudCaseList) {
            // Sending emails to contacts about case EUD missing fields.
            if (!String.isBlank(c.SuppliedEmail)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new List<String>{ c.SuppliedEmail };

                String plainTextBody = EmailMessageHelper.missingEUDEmailTemplate.Body;
                plainTextBody = plainTextBody.replace('{!Case.ShadowXometryOrderID__c}', c.ShadowXometryOrderID__c);
                plainTextBody = plainTextBody.replace(
                    '{!Case.EUD_EmailTemplateHelper__c}',
                    c.EUD_EmailTemplateHelper__c
                );
                plainTextBody = plainTextBody.replaceAll('<br>', '\n');

                String eudSubject = EmailMessageHelper.missingEUDEmailTemplate.Subject;
                eudSubject = eudSubject.replace('{!Case.ShadowXometryOrderID__c}', c.ShadowXometryOrderID__c);

                mail.setTemplateId(EmailMessageHelper.missingEUDEmailTemplate.Id);
                mail.setSubject(eudSubject);
                mail.setPlainTextBody(plainTextBody);
                mail.setToAddresses(toAddresses);
                mail.setBccSender(false);
                mail.setSaveAsActivity(true);
                mail.setUseSignature(false);
                mail.setWhatId(c.Id);
                mail.setTargetObjectId(c.ContactId);
                try {
                    mail.setReplyTo(EmailMessageHelper.supportRoutingAddress);
                    mail.setOrgWideEmailAddressId(EmailMessageHelper.supportOrgWideEmailID);
                    sendEmails.add(mail);
                } catch (Exception e) {
                    EmailMessageHelper.handleEmailError(
                        e,
                        'OrderERPHandler.sendEUDEmail',
                        'EUD Email was not sent for Order ' + c.ShadowXometryOrderID__c
                    );
                }
            }

            if(Test.isRunningTest()){
                retryEudCaseIDs.add(c.Id);
            }
        }

        if (sendEmails.size() > 0) {
            List<Audit_Trail_Error__c> auditErrorList = new List<Audit_Trail_Error__c>();

            List<Messaging.SendEmailResult> results = EmailMessageHelper.sendEmail(sendEmails, false);
            for ( Integer i = 0; i<results.size(); i++ ) {
                Messaging.SendEmailResult eR = results.get(i);
                System.debug(eR);
                if (er.IsSuccess() == false) {
                    retryEudCaseIDs.add(sendEmails.get(i).getWhatId());
                    List<Messaging.sendEmailError> emailErrorMessageList = er.getErrors();
                    for (Messaging.sendEmailError emailErrorMessage : emailErrorMessageList) {
                        System.debug(emailErrorMessage.getStatusCode() + ' : ' + emailErrorMessage.getMessage());
                        System.debug('ERROR_FIELDS: ' + emailErrorMessage.getFields());
                        Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
                        auditError.Module__c = 'OrderERPHandler.sendEUDEmails';
                        auditError.SourceId__c = emailErrorMessage.getTargetObjectId();
                        auditError.Dev_Audit_Notes__c = 'EUD Email failed to send';
                        auditError.StatusCode__c = emailErrorMessage.getStatusCode().name();
                        auditError.errorMessage__c = emailErrorMessage.getMessage().abbreviate(250);
                        auditError.errorFields__c = String.join(emailErrorMessage.getFields(), ' ').abbreviate(250);
                        auditErrorList.add(auditError);
                    }
                }
            }

            if (!auditErrorList.isEmpty()) {
                insert auditErrorList;
            }
        }

        return retryEudCaseIDs;

    }

    /*
    @param queContext used to represent the the current operation 
    */
    public static void setupQueueJobs(List<Order_ERP__C> inOrdersList, string queContext) {
        orderQLauncherHelper.queLauncherFirer(inOrdersList, queContext, eudCaseNeedEmailMap, eudCaseNeedEmailCaseList);
        eudCaseNeedEmailMap.clear();
        eudCaseNeedEmailCaseList.clear();
    }
}