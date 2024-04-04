public with sharing class SuppliesOrderHandler {
    static final ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer')
        .getRecordTypeID();
    static final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();

    /* @description
            1.This method creates the P21 Account Details
            Will attempt to see if we have a matching P21 Account (this is not the default Account table in Salesforce!) if not identifies P21 Accounts to be created.
            2.Attempt to see if we have an existing Account and if not then makes an account. This default account is owned by Managed Services unless the existing Lead says otherwise.
            Map the P21 Account to an existing Account either by Partner ID or by domain with Generic Logic
            Create a new Account if it does not alreay exist. Origin is Supplies            
            /DnB maybe be able to tell us more about the P21 Customer based on the Address entered into the main Account if it is created. Will need a seperate async job to improve this. 
            3.Route the P21 Account based on Address Information and create P21 Accounts if needed.          
            4.Create the Contact if it does not exists. Identify the origin as Supplies. Link Contacts to P21 Account
            5.Create the Opportunity if it does not exists. There may already be an existing Opportunity for the Order Entry reference Quote.
            6.Create the Opportunity Contact Junction.
            7.Convert any Leads as needed
            @params newSuppliesOrderList a List of Supplies Orders being Inserted 
            */
    public static void processSuppliesOrders(List<Supplies_Order__C> newSuppliesOrderList) {
        List<Audit_Trail_Error__c> myAuditErrorList = new List<Audit_Trail_Error__c>();
        Set<String> quoteDomainSet = new Set<String>();
        Set<String> quoteEmailSet = new Set<String>();
        Set<String> quotePartnerIDSet = new Set<String>();
        //ID Mapping to the P21 Account Object in Salesforce.
        Set<String> p21CustomerIDSet = new Set<String>();
        Set<String> p21QuoteERPIDSet = new Set<String>();
        Set<String> p21OrderOEIDSet = new Set<String>();
        Set<String> p21XomJobIDSet = new Set<String>();

        for (Supplies_Order__C sOrder : newSuppliesOrderList) {
            if (!string.isBlank(sOrder.Account_Domain__c)) {
                quoteDomainSet.add(sOrder.Account_Domain__c);
            }
            if (!string.isBlank(sOrder.Order_Email__C)) {
                quoteEmailSet.add(sOrder.Order_Email__C);
            }
            if (!string.isBlank(sOrder.PartnerID__C)) {
                quotePartnerIDSet.add(sOrder.PartnerID__C);
            }
            if (!string.isBlank(sOrder.P21_Order_OE_ERP_ID__c)) {
                p21OrderOEIDSet.add(sOrder.P21_Order_OE_ERP_ID__c); //This is the PK for the Supplies Order Table
            }
            if (!string.isBlank(sOrder.P21_Quote_OE_ERP_ID__C)) {
                p21QuoteERPIDSet.add(sOrder.P21_Quote_OE_ERP_ID__C); // This is a PK reference for the Supplies Quote Table
            }
            if (!string.isBlank(sOrder.P21_CustomerID__C)) {
                p21CustomerIDSet.add(sOrder.P21_CustomerID__C);
            }
            if (!string.isBlank(sOrder.XometryJobID__c)) {
                p21XomJobIDSet.add(sOrder.XometryJobID__c);
            }
        }

        //Use the Same Managed Service Quote ERP Logic for Leads
        Map<String, Lead> existingLeadMap = new Map<String, Lead>();
        existingLeadMap = QuoteERPHandler.fetchExistingLeadsMap(quoteEmailSet);

        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        Map<String, Contact> contactsNeedUpdateMap = new Map<String, Contact>();
        if (!quoteEmailSet.isEmpty()) {
            for (Contact c : [
                SELECT
                    ID,
                    Primary_Email__C,
                    P21_Account_Details__c,
                    P21_Account_Details__r.P21_CustomerID__c,
                    P21_ContactID__c
                FROM Contact
                WHERE Primary_Email__C IN :quoteEmailSet
            ]) {
                existingContactMap.put(c.Primary_Email__C, c);
                //if an Existing Contact does not have a P21_Account_Details__c then update the Contact.
                if (String.isblank(c.P21_Account_Details__c)) {
                    contactsNeedUpdateMap.put(c.Primary_Email__C, c);
                }
            }
        }

        Map<String, Account> existingAccountDomainMap = new Map<String, Account>();
        Map<String, Supplier__C> existingAccountPartnerIDMap = new Map<String, Supplier__C>();
        Map<String, Supplier__c> supplierNeedsP21AcctMap = new Map<String, Supplier__c>();
        List<Supplier__c> suppliersNeedP21Acct = new List<Supplier__c>();
        if (!quotePartnerIDSet.isEmpty()) {
            existingAccountPartnerIDMap = SupplierUtility.fetchSuppliers(quotePartnerIDSet);
            for (Supplier__C sup : existingAccountPartnerIDMap.values()) {
                if (sup.P21_Account_Details__c == null) {
                    supplierNeedsP21AcctMap.put(sup.PartnerID__c, sup);
                }
            }
        }
        //ToDO switch to using the Supplier to get the Partners Account
        if (!quoteDomainSet.isEmpty()) {
            List<Account> existingAccountList = [
                SELECT ID, Email_Domain__C, GNO_PartnerId__c, OwnerId, Generic_Account__C, Physical_Zip_Code__c
                FROM Account
                WHERE Email_Domain__c IN :quoteDomainSet
            ];
            if (existingAccountList.size() > 0) {
                for (Account a : existingAccountList) {
                    if (!String.isblank(a.Email_Domain__C)) {
                        existingAccountDomainMap.put(a.Email_Domain__c, a);
                    }
                }
            }
        }

        Map<String, P21_Account_Details__c> existingP21CustomerMap = new Map<String, P21_Account_Details__c>();
        if (!p21CustomerIDSet.isEmpty()) {
            List<P21_Account_Details__c> existingP21AccountList = [
                SELECT ID, OwnerID, AccountID__C, AccountID__R.OwnerID, P21_CustomerID__C, Primary_Zip_Code__c
                FROM P21_Account_Details__c
                WHERE P21_CustomerID__C IN :p21CustomerIDSet
            ];

            if (existingP21AccountList.size() > 0) {
                for (P21_Account_Details__c p21A : existingP21AccountList) {
                    existingP21CustomerMap.put(p21A.P21_CustomerID__C, p21A);
                }
            }
        }

        List<Supplies_Order__C> sOrderNeedsSFAccount = new List<Supplies_Order__C>();
        List<Supplies_Order__C> sOrderNeedsP21Account = new List<Supplies_Order__C>();
        List<Supplies_Order__C> sOrderUpdateP21AccountOwner = new List<Supplies_Order__C>();
        Set<P21_Account_Details__C> p21AccountToCreate = new Set<P21_Account_Details__C>();
        Map<String, P21_Account_Details__C> p21AccountsToCreateMap = new Map<String, P21_Account_Details__C>();
        Map<String, P21_Account_Details__C> p21AccountsToUpdateMap = new Map<String, P21_Account_Details__C>();
        //Create P21 Account if it does not exists
        for (Supplies_Order__C sOrder : newSuppliesOrderList) {
            //Xometry Customer ID of 15077 will be a manually created P21 Account and Salesforce Account for Go Live
            if (existingP21CustomerMap.containsKey(sOrder.P21_CustomerID__C)) {
                P21_Account_Details__C existingP21Customer = existingP21CustomerMap.get(sOrder.P21_CustomerID__C);
                if (
                    (existingP21Customer.Primary_Zip_Code__c != sOrder.P21_Physical_Zip_Code__c &&
                    existingP21Customer.OwnerID == AppConstants.SUPPLIES_HOUSE_USER) ||
                    String.isBlank(existingP21Customer.Primary_Zip_Code__c)
                ) {
                    sOrderUpdateP21AccountOwner.add(sOrder);
                    p21AccountsToUpdateMap.put(existingP21Customer.P21_CustomerID__C, existingP21Customer);
                }
                sOrder.OwnerID = existingP21Customer.OwnerID;
                sOrder.AccountID__C = existingP21Customer.AccountID__C;
                sOrder.P21_Account_DetailsID__C = existingP21Customer.ID;
                //Handle scenario for existing
            } else {
                P21_Account_Details__C newP21Account = new P21_Account_Details__C();
                newP21Account.P21_CustomerID__C = sOrder.P21_CustomerID__C;
                newP21Account.name = sOrder.P21_CustomerID__C;
                newP21Account.Primary_Zip_Code__c = sOrder.P21_Physical_Zip_Code__c;
                //Check if we can identify the SF Account based on the Contacts email domain or PartnerID
                //Check if we can identify the SF Account for P21 Account Details if not then make the SF Account
                if (existingAccountPartnerIDMap.containsKey(sOrder.PartnerID__c)) {
                    newP21Account.AccountID__C = existingAccountPartnerIDMap.get(sOrder.PartnerID__C).AccountId__c;
                    sOrder.AccountID__C = existingAccountPartnerIDMap.get(sOrder.PartnerID__C).AccountId__c;
                    if (string.isBlank(sOrder.P21_Physical_Zip_Code__c)) {
                        newP21Account.Primary_Zip_Code__c = existingAccountPartnerIDMap.get(sOrder.PartnerID__C)
                            .AccountId__r.Physical_Zip_Code__c;
                    }
                } else if (existingAccountDomainMap.containsKey(sOrder.Account_Domain__c)) {
                    newP21Account.AccountID__C = existingAccountDomainMap.get(sOrder.Account_Domain__c).ID;
                    sOrder.AccountID__C = existingAccountDomainMap.get(sOrder.Account_Domain__c).ID;
                    if (string.isBlank(sOrder.P21_Physical_Zip_Code__c)) {
                        newP21Account.Primary_Zip_Code__c = existingAccountDomainMap.get(sOrder.Account_Domain__c)
                            .Physical_Zip_Code__c;
                    }
                } else {
                    sOrderNeedsSFAccount.add(sOrder);
                }
                sOrderNeedsP21Account.add(sOrder);
                p21AccountsToCreateMap.put(sOrder.P21_CustomerID__C, newP21Account);
            }
        }
        Map<String, Account> p21CustIDNewSFAccountMap = new Map<String, Account>();
        Map<String, Account> emailDomainAccountMap = new Map<String, Account>();
        List<Account> sfAccountCreateList = new List<Account>();
        //Do not use the PartnerID all Partners should be made GNO Process
        for (Supplies_Order__C sOrder : sOrderNeedsSFAccount) {
            //The Main Account will be put under the Managed Services House Account for the time being.
            // Can clean this up later
            Account a = emailDomainAccountMap.get(sOrder.Account_Domain__c);
            if (a == null) {
                a = new Account();
                a.RecordtypeID = accountCustomerRecordTypeID;
                a.LOB_Creation__c = 'Supplies';
                a.LD_USE_DnB_Connect__c = true;
                a.Account_Owner_Type__c = 'Ops';
                a.Email_Domain__C = sOrder.Account_Domain__c;
                a.Generic_Account__c = sOrder.is_generic__c;
                //The Owner of a High Level Account is always Managed Services or GNO never the Supplies Rep
                a.OwnerID = AppConstants.GNO_HOUSE_USER;
                if (sOrder.is_generic__c) {
                    a.name = sOrder.Order_Email__C;
                } else {
                    a.name = sOrder.Account_Domain__c;
                }
                //Discuss with team about Origin Field

                //IDEA-499 Check that the leadsource is not Drift and Lead is not owned by API ADMIN  0056A000002S1sMQAS to keep Lead Owner
                if (
                    existingLeadmap.containsKey(sOrder.Order_Email__C) &&
                    existingLeadMap.get(sOrder.Order_Email__C).leadsource != 'Drift' &&
                    existingLeadMap.get(sOrder.Order_Email__C).OwnerID != AppConstants.API_USER
                ) {
                    a.OwnerID = existingLeadMap.get(sOrder.Order_Email__c).OwnerID;
                }

                emailDomainAccountMap.put(a.Email_Domain__C, a);
                p21CustIDNewSFAccountMap.put(sOrder.P21_CustomerID__C, a);
            }
        }
        sfAccountCreateList.addAll(p21CustIDNewSFAccountMap.values());
        //Create the new SF Accounts
        DatabaseUtilities.insertToDatabase(
            sfAccountCreateList,
            'SuppliesOrderHandler.processSuppliesOrders',
            'Creating new Accounts'
        );

        Set<ID> createdAccountIDSet = new Set<ID>();
        //Map the Accounts to Domain
        Map<String, Account> allAccountsDomainMap = new Map<String, Account>();
        for (Account a : sfAccountCreateList) {
            if (a.ID != null) {
                createdAccountIDSet.add(a.ID);
                //Update the SFQuote with the Account Owner
                allAccountsDomainMap.put(a.Email_Domain__C, a);
            }
        }

        for (Supplies_Order__C sOrder : sOrderNeedsSFAccount) {
            if (allAccountsDomainMap.containsKey(sOrder.Account_Domain__c)) {
                sOrder.AccountID__C = allAccountsDomainMap.get(sOrder.Account_Domain__c).Id;
                if (p21AccountsToCreateMap.containsKey(sOrder.P21_CustomerID__C)) {
                    p21AccountsToCreateMap.get(sOrder.P21_CustomerID__C).AccountID__C = sOrder.AccountID__C;
                }
            }
        }

        //Get the Owner based on Routing

        List<routingAddress> p21AccountsToRoute = new List<routingAddress>();
        List<P21_Account_Details__C> p21AccountNeedRouteList = new List<P21_Account_Details__C>();
        p21AccountNeedRouteList.addAll(p21AccountsToUpdateMap.values());
        p21AccountNeedRouteList.addAll(p21AccountsToCreateMap.values());
        for (P21_Account_Details__C p21Acct : p21AccountsToCreateMap.values()) {
            routingAddress myRoutingAddress = new routingAddress(
                p21Acct.Primary_Zip_Code__c,
                null,
                null,
                null,
                p21Acct.P21_CustomerID__C
            );
            p21AccountsToRoute.add(myRoutingAddress);
        }

        System.debug('Starting the Router Call');
        p21AccountsToRoute = routingHelper.suppliesTerritoryRouting(p21AccountsToRoute, 'Supplies');
        System.debug('Finished the Router call');
        for (routingAddress rAddr : p21AccountsToRoute) {
            if (p21AccountsToCreateMap.containsKey(rAddr.sourceID)) {
                p21AccountsToCreateMap.get(rAddr.sourceID).OwnerID = rAddr.routedOwnerID;
            }
            if (p21AccountsToUpdateMap.containsKey(rAddr.sourceID)) {
                p21AccountsToUpdateMap.get(rAddr.sourceID).OwnerID = rAddr.routedOwnerID;
            }
        }
        // All account should exist at this time. Add the Account to the P21 Account Details that need the new Account
        List<P21_Account_Details__C> p21AccountsToCreateList = p21AccountsToCreateMap.values();

        DatabaseUtilities.insertToDatabase(
            p21AccountsToCreateList,
            'SuppliesOrderHandler.processSuppliesOrders',
            'Creating new P21 Accounts'
        );
        Set<ID> createdP21AccountDetailsIDSet = new Set<ID>();
        Map<String, P21_Account_Details__C> newP21AccountCustIDMap = new Map<String, P21_Account_Details__C>();
        for (P21_Account_Details__C p21Acct : p21AccountsToCreateList) {
            if (p21Acct.ID != null) {
                //Get the new ID on the quote
                newP21AccountCustIDMap.put(p21Acct.P21_CustomerID__c, p21Acct);
                createdP21AccountDetailsIDSet.add(p21Acct.ID);
            }
        }

        //Testing Check
        //System.debug('Created ' + createdP21AccountDetailsIDSet.size() + ' new P21Accounts');

        for (Supplies_Order__C sOrder : sOrderNeedsP21Account) {
            if (newP21AccountCustIDMap.containsKey(sOrder.P21_CustomerID__C)) {
                sOrder.P21_Account_DetailsID__C = newP21AccountCustIDMap.get(sOrder.P21_CustomerID__C).ID;
                sOrder.OwnerID = newP21AccountCustIDMap.get(sOrder.P21_CustomerID__C).OwnerID;
            }
        }

        if (!p21AccountsToUpdateMap.values().isEmpty()) {
            DatabaseUtilities.saveToDatabase(
                p21AccountsToUpdateMap.values(),
                'SuppliesOrderHandler.processSuppliesOrders',
                'Updating P21 Account Owners'
            );
        }

        for (Supplies_Order__C sOrder : sOrderUpdateP21AccountOwner) {
            if (p21AccountsToUpdateMap.containsKey(sOrder.P21_CustomerID__c)) {
                sOrder.OwnerID = p21AccountsToUpdateMap.get(sOrder.P21_CustomerID__c).OwnerID;
            }
        }

        List<Supplies_Order__C> sOrdersNeedContactsList = new List<Supplies_Order__C>();
        //Create the Contact if it does not exists and ensure that the Contact is linked to the right P21 Account.
        for (Supplies_Order__C sOrder : newSuppliesOrderList) {
            if (existingContactMap.containsKey(sOrder.Order_Email__C)) {
                sOrder.ContactID__C = existingContactMap.get(sOrder.Order_Email__C).ID;
                //Update Contacts that need to be linked to the P21 Account Details
                if (contactsNeedUpdateMap.containsKey(sOrder.Order_Email__C)) {
                    contactsNeedUpdateMap.get(sOrder.Order_Email__C)
                        .P21_Account_Details__C = sOrder.P21_Account_DetailsID__C;
                }
            } else {
                sOrdersNeedContactsList.add(sOrder);
            }
        }

        System.debug('Size of contacts that need to be created : ' + sOrdersNeedContactsList.size());
        Map<String, Contact> newContactMap = new Map<String, Contact>();

        if (!sOrdersNeedContactsList.isEmpty()) {
            for (Supplies_Order__C sOrder : sOrdersNeedContactsList) {
                if (!newContactMap.containsKey(sOrder.Order_Email__C)) {
                    Contact c = new Contact();
                    c.LD_USE_DnB_Connect_Contact__c = true;
                    if (!String.isblank(sOrder.P21_Contact_Last_Name__C)) {
                        c.LastName = sOrder.P21_Contact_Last_Name__C;
                    } else {
                        c.LastName = sOrder.Order_Email__C;
                    }
                    if (!String.isblank(sOrder.P21_Contact_Phone__c)) {
                        c.Phone = sOrder.P21_Contact_Phone__c;
                    }
                    c.FirstName = sOrder.P21_Contact_First_Name__C;
                    c.P21_ContactID__c = sOrder.P21_ContactID__c;
                    c.Email = sOrder.Order_Email__C;
                    c.Primary_Email__C = sOrder.Order_Email__C;
                    c.OwnerID = sOrder.OwnerId;
                    c.AccountID = sOrder.AccountID__C;
                    c.P21_Account_Details__c = sOrder.P21_Account_DetailsID__c;
                    //ERP fields shall be overrided with source system
                    c.ERP_Shipping_Address__c = sOrder.P21_Physical_Address__c;
                    c.ERP_Shipping_City__c = sOrder.P21_Physical_City__c;
                    c.ERP_Shipping_Country__c = sOrder.P21_Physical_Country__c;
                    c.ERP_Shipping_State_or_Province__c = sOrder.P21_Physical_State__c;
                    c.ERP_Shipping_Zip_Code__c = sOrder.P21_Physical_Zip_Code__c;
                    c.GNO_PartnerId__c = sOrder.PartnerID__C;
                    newContactMap.put(c.Primary_Email__C, c);
                }
            }
        }
        List<Contact> newContactList = new List<Contact>();
        if (!newContactMap.isEmpty()) {
            newContactList.addAll(newContactMap.values());
        }

        DatabaseUtilities.insertToDatabase(
            newContactList,
            'SuppliesOrderHandler.processSuppliesOrders',
            'Creating new Contacts'
        );

        //System.debug('Finished: Number of new Contacts created: ' + newContactList.size());

        if (!contactsNeedUpdateMap.isEmpty()) {
            DatabaseUtilities.saveToDatabase(
                contactsNeedUpdateMap.values(),
                'SuppliesOrderHandler.processSuppliesOrders',
                'Updating Contact with P21 Account Details'
            );
        }

        //Update Suppliers that need to be linked to Their P21 Account
        if (supplierNeedsP21AcctMap.size() > 0) {
            for (Supplies_Order__C sOrder : newSuppliesOrderList) {
                if (supplierNeedsP21AcctMap.containsKey(sOrder.PartnerID__C)) {
                    Supplier__c sup = supplierNeedsP21AcctMap.get(sOrder.PartnerID__C);
                    if (string.isBlank(sup.P21_Account_Details__c)) {
                        sup.P21_Account_Details__c = sOrder.P21_Account_DetailsID__C;
                    }
                }
            }

            DatabaseUtilities.saveToDatabase(
                supplierNeedsP21AcctMap.values(),
                'SuppliesQuoteHandler.processSuppliesQuotes',
                'Linking Suppliers to P21 Accounts'
            );
        }

        //Add the ContactsID into
        Map<String, Contact> allContactExistMap = new Map<String, Contact>();
        List<Contact> quoteAllContactList = [
            SELECT
                ID,
                OwnerId,
                Suppress_OPPS_AND_LEADS_FLAG__C,
                Primary_Email__C,
                P21_Account_Details__C,
                P21_Account_Details__r.P21_CustomerID__c,
                P21_Account_Details__R.OwnerId
            FROM Contact
            WHERE Primary_Email__C IN :quoteEmailSet
        ];

        if (quoteAllContactList.size() > 0) {
            for (Contact c : quoteAllContactList) {
                allContactExistMap.put(c.Primary_Email__C, c);
            }
        }

        for (Supplies_Order__C sOrder : newSuppliesOrderList) {
            if (allContactExistMap.containsKey(sOrder.Order_Email__C)) {
                sOrder.ContactID__C = allContactExistMap.get(sOrder.Order_Email__C).ID;
            }
        }

        for (Database.LeadConvertResult lcr : HandlerUtil.leadConverter(newSuppliesOrderList)) {
            if (!lcr.isSuccess()) {
                //Log errors
                for (Database.Error err : lcr.getErrors()) {
                    Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
                    myAuditError.Module__c = 'SuppliesOrderHandler';
                    myAuditError.Dev_Audit_Notes__c = 'Lead Convert Conversion';
                    myAuditError.StatusCode__c = err.getStatusCode().name();
                    myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
                    myAuditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
                    myAuditErrorList.add(myAuditError);
                }
            }
        }

        //Supplies Order Opportunity Section
        /*
    Allow no duplicate Opportunities based on the P21 Order OE ID
    If there is an Open Supplies Opp that is a placeholder by a rep based on a Job ID then match with the reference or deduct from Job ID.
    Supplies Routing is not the same as Managed Services. The P21 Zipcode may determine the Commission Owner which can be different then the Opp owner.
*/

        //Opp creation Logic and Linking
        //existing Opportunities based on a quote that should have their Opportunity become closed Won or closed Lost if the Order is Canceled.
        // An existing Opportunity exists for the Order Entry based on the Quote
        // An Open Opportunity exist for Supplies with a Job ID that has its P21 Quote Slot Open
        // ToDo Aaron Zamora LogicNo existing Quote exists check if there is a Supplies Opportunity created for a Job that matched on the Secondary Field
        // This is to reward proactivity for Reps who have decided to identify Managed Service Jobs that should become Opportunities

        //Map Check if any cases exists with a Quote ID if so then use that case information for opp
        Map<String, Case> existingP21QuoteCaseMap = new Map<String, Case>();
        Set<ID> caseHasOppIDSet = new Set<ID>();
        Set<Id> existingcaseOppIDSet = new Set<ID>();
        Set<Id> ownerIDSet = new Set<ID>();
        if (!p21QuoteERPIDSet.isEmpty()) {
            for (Case c : [
                SELECT
                    ID,
                    OwnerId,
                    Owner.Type,
                    AccountId,
                    Opportunity__c,
                    Opportunity__r.RecordtypeID,
                    ContactID,
                    Contact.Supplies_Last_Opp_Owner__c,
                    Shadow_P21_Quote_Id__c,
                    Job__c,
                    Job__r.Supplier__c,
                    Job__r.Supplier__r.Sup_Owner_Stamp__c
                FROM Case
                WHERE Shadow_P21_Quote_Id__c IN :p21QuoteERPIDSet
            ]) {
                existingP21QuoteCaseMap.put(c.Shadow_P21_Quote_Id__c, c);
                if (c.Opportunity__c != null && c.Opportunity__r.RecordTypeId == oppSuppliesRecordTypeID) {
                    caseHasOppIDSet.add(c.Opportunity__c);
                }
                if (c.Owner.Type == 'User') {
                    ownerIDSet.add(c.OwnerId);
                }
            }
        }
        Set<ID> suppliesSalesRepIDSet = new Set<ID>();
        if (!ownerIDSet.isEmpty()) {
            for (User u : [SELECT Id FROM User WHERE ID IN :ownerIDSet AND Supplies_Sales_Rep__c = TRUE]) {
                suppliesSalesRepIDSet.add(u.ID);
            }
        }

        Map<String, Opportunity> existingOppswithSQuoteMap = new Map<String, Opportunity>();
        Map<ID, Opportunity> existingOppMap = new Map<ID, Opportunity>();
        if (!p21QuoteERPIDSet.isEmpty()) {
            List<Opportunity> existingOppswithSQuotesList = [
                SELECT
                    Id,
                    Name,
                    OwnerId,
                    Order_ERP_Xom_ID__c,
                    Last_Quote_Xometry_ERP_ID__c,
                    Quote_ERP_XOM_CREATE_ID__c,
                    StageName,
                    Shadow_JobId__c,
                    JobId__c
                FROM Opportunity
                WHERE Last_Quote_Xometry_ERP_ID__c IN :p21QuoteERPIDSet OR ID IN :caseHasOppIDSet
            ];
            for (Opportunity opp : existingOppswithSQuotesList) {
                if (!string.isblank(opp.Last_Quote_Xometry_ERP_ID__c)) {
                    existingOppswithSQuoteMap.put(opp.Last_Quote_Xometry_ERP_ID__c, opp);
                }
                existingOppMap.put(opp.Id, opp);
            }
        }

        Map<String, Opportunity> existingOppswithSOrderMap = new Map<String, Opportunity>();

        //This allows  a reload of a Supplies Order without creating a duplicate Opp
        if (!p21OrderOEIDSet.isEmpty()) {
            List<Opportunity> existingOppswithSOrderList = [
                SELECT
                    Id,
                    Name,
                    OwnerId,
                    Order_ERP_Xom_ID__c,
                    Last_Quote_Xometry_ERP_ID__c,
                    Quote_ERP_XOM_CREATE_ID__c,
                    StageName,
                    Shadow_JobId__c,
                    JobId__c
                FROM Opportunity
                WHERE Order_ERP_Xom_ID__c IN :p21OrderOEIDSet
            ];
            for (Opportunity opp : existingOppswithSOrderList) {
                existingOppswithSOrderMap.put(opp.Order_ERP_Xom_ID__c, opp);
            }
        }

        Map<String, Opportunity> existingOppswithJobMap = new Map<String, Opportunity>();
        Map<String, ID> existingJobtoJobIDMap = new Map<String, ID>();
        //Only want to grab Job Opps that do not have a SQUOTE or SORDER attached.
        //Filter performance avoid using null in SOQL and instead move to map check
        if (!p21XomJobIDSet.isEmpty()) {
            List<Opportunity> existingOppsWithJobAvList = [
                SELECT
                    Id,
                    Name,
                    OwnerId,
                    Order_ERP_Xom_ID__c,
                    Last_Quote_Xometry_ERP_ID__c,
                    Quote_ERP_XOM_CREATE_ID__c,
                    StageName,
                    Shadow_JobId__c,
                    JobId__c
                FROM Opportunity
                WHERE Shadow_JobId__c IN :p21XomJobIDSet
            ];
            for (Opportunity opp : existingOppsWithJobAvList) {
                if (opp.Order_ERP_Xom_ID__c == null && opp.Last_Quote_Xometry_ERP_ID__c == null) {
                    existingOppswithJobMap.put(opp.Shadow_JobId__c, opp);
                    existingJobtoJobIDMap.put(opp.Shadow_JobId__c, opp.JobId__C);
                }
            }
        }

        List<Supplies_Order__C> sOrdersNeedOpps = new List<Supplies_Order__C>();
        Map<String, Opportunity> sOrderUpdateExistingOppsMap = new Map<String, Opportunity>();
        Set<String> p21QuoteOppExistsAndMarked = new Set<String>();
        Set<Id> p21OppCaseOppExistsAndMarked = new Set<Id>();
        Set<String> p21JobQuoteOppExistsAndMarked = new Set<String>();
        Set<String> existingOpponCaseSet = new Set<String>();
        List<Supplies_Order__C> sOrderToUpdateOpps = new List<Supplies_Order__C>();

        //The same Opp is in two different sets so have them share the Opp marking.

        for (Supplies_Order__C sOrder : newSuppliesOrderList) {
            system.debug('Starting the assigning pass');
            if (existingOppswithSOrderMap.containsKey(sOrder.P21_Order_OE_ERP_ID__C)) {
                sOrder.OpportunityID__C = existingOppswithSOrderMap.get(sOrder.P21_Order_OE_ERP_ID__C).ID;
            } else if (existingOppswithSQuoteMap.containsKey(sOrder.P21_Quote_OE_ERP_ID__C)) {
                //System.debug('Here is the quote id of this order :' + sOrder.P21_Quote_OE_ERP_ID__C);
                //System.debug('Here is the order id of this order :' + sOrder.P21_Order_OE_ERP_ID__C);
                //Data Integrity scenario if a Quote is split into two or more Orders the existing Opp gets one of the Orders and any additional Orders create new Opps
                Opportunity existingOpp = existingOppswithSQuoteMap.get(sOrder.P21_Quote_OE_ERP_ID__C);
                if (
                    !p21QuoteOppExistsAndMarked.contains(sOrder.P21_Quote_OE_ERP_ID__C) &&
                    !p21OppCaseOppExistsAndMarked.contains(existingOpp.ID) &&
                    existingOpp.StageName != 'Closed Won' &&
                    String.isblank(existingOpp.Order_ERP_Xom_ID__c)
                ) {
                    sOrder.OpportunityID__C = existingOpp.ID;
                    p21QuoteOppExistsAndMarked.add(sOrder.P21_Quote_OE_ERP_ID__C);
                    p21OppCaseOppExistsAndMarked.add(existingOpp.ID);
                    sOrderUpdateExistingOppsMap.put(sOrder.P21_Order_OE_ERP_ID__C, existingOpp);
                    sOrderToUpdateOpps.add(sOrder);
                } else {
                    sOrdersNeedOpps.add(sOrder);
                }
            } else if (existingP21QuoteCaseMap.containsKey(sOrder.P21_Quote_OE_ERP_ID__C)) {
                //Use the P21 Quote if it exists to find an existing Opp attached to a Case based on the Quote on the Order
                // This is for race condition if the P21 manual Quote is created and before the ETL makes its way to Salesforce it also
                // an Order Created.
                Case existingCase = existingP21QuoteCaseMap.get(sOrder.P21_Quote_OE_ERP_ID__C);
                //The Case does not have an Opp but the Order has a Job. Job Opp for the Order and link it to the case
                if (
                    !String.isBlank(sOrder.XometryJobID__c) &&
                    existingOppswithJobMap.containsKey(sOrder.XometryJobID__c) &&
                    !p21JobQuoteOppExistsAndMarked.contains(sOrder.XometryJobID__c) &&
                    existingOppswithJobMap.get(sOrder.XometryJobID__c).StageName != 'Closed Won'
                ) {
                    Opportunity existingOpp = existingOppswithJobMap.get(sOrder.XometryJobID__c);
                    sOrder.OpportunityID__C = existingOpp.ID;
                    p21JobQuoteOppExistsAndMarked.add(sOrder.XometryJobID__c);
                    p21OppCaseOppExistsAndMarked.add(existingOPP.ID);
                    sOrderToUpdateOpps.add(sOrder);
                    sOrderUpdateExistingOppsMap.put(sOrder.P21_Order_OE_ERP_ID__C, existingOpp);
                } else if (
                    existingCase.Opportunity__c != null &&
                    existingOppMap.containsKey(existingCase.Opportunity__c) &&
                    existingOppMap.get(existingCase.Opportunity__c).StageName != 'Closed Won' &&
                    !p21OppCaseOppExistsAndMarked.contains(existingOppMap.get(existingCase.Opportunity__c).ID)
                ) {
                    //The Case Has an Opp so do not create a new Opp
                    Opportunity existingOpp = existingOppMap.get(existingCase.Opportunity__c);
                    // If the Opp has a Quote then the Orders Quote must match the Opp quote in order to qualify
                    if (
                        String.isBlank(existingOpp.Last_Quote_Xometry_ERP_ID__c) ||
                        (existingOpp.Last_Quote_Xometry_ERP_ID__c == sOrder.P21_Quote_OE_ERP_ID__C)
                    ) {
                        sOrderToUpdateOpps.add(sOrder);
                        existingOpponCaseSet.add(sOrder.P21_Quote_OE_ERP_ID__C);
                        sOrderUpdateExistingOppsMap.put(sOrder.P21_Order_OE_ERP_ID__C, existingOpp);
                        p21OppCaseOppExistsAndMarked.add(existingOPP.ID);
                    } else {
                        sOrdersNeedOpps.add(sOrder);
                    }
                } else {
                    sOrdersNeedOpps.add(sOrder);
                }
            } else if (
                !String.isBlank(sOrder.XometryJobID__c) && existingOppswithJobMap.containsKey(sOrder.XometryJobID__c)
            ) {
                Opportunity existingOpp = existingOppswithJobMap.get(sOrder.XometryJobID__c);
                //Existing Job Opp gets one quote attached to it otherwise make a new Opp.
                if (
                    !p21JobQuoteOppExistsAndMarked.contains(sOrder.XometryJobID__c) &&
                    existingOpp.StageName != 'Closed Won'
                ) {
                    sOrder.OpportunityID__C = existingOpp.ID;
                    p21JobQuoteOppExistsAndMarked.add(sOrder.XometryJobID__c);
                    sOrderUpdateExistingOppsMap.put(sOrder.P21_Order_OE_ERP_ID__C, existingOpp);
                    sOrderToUpdateOpps.add(sOrder);
                } else {
                    sOrdersNeedOpps.add(sOrder);
                }
            } else {
                sOrdersNeedOpps.add(sOrder);
            }
        }
        List<Supplies_Order__C> supQuoteCaseLink = new List<Supplies_Order__C>();
        List<Opportunity> suppliesOppsCheckRoutingList = new List<Opportunity>();
        List<Opportunity> oppsToUpsertList = new List<Opportunity>();
        System.debug('Number of Opps needing updates is : ' + sOrderUpdateExistingOppsMap.values().size());
        for (Supplies_Order__C sOrder : sOrderToUpdateOpps) {
            if (sOrderUpdateExistingOppsMap.containsKey(sOrder.P21_Order_OE_ERP_ID__C)) {
                Opportunity oppToUpdate = sOrderUpdateExistingOppsMap.get(sOrder.P21_Order_OE_ERP_ID__C);
                oppToUpdate.Quote_ERP_XOM_CREATE_ID__c = String.isblank(sOrder.P21_Quote_OE_ERP_ID__C)
                    ? sOrder.P21_Order_OE_ERP_ID__C
                    : sOrder.P21_Quote_OE_ERP_ID__C;
                oppToUpdate.Primary_Contact__c = sOrder.ContactID__C;
                oppToUpdate.Quote_Type__c = 'Manually-Quoted';
                oppToUpdate.AccountID = sOrder.AccountID__C;
                oppToUpdate.P21_Account_Details__C = sOrder.P21_Account_DetailsID__C;
                oppToUpdate.Line_of_Business__c = 'Supplies';
                oppToUpdate.RecordtypeID = oppSuppliesRecordTypeID;
                oppToUpdate.StageName = 'Closed Won';
                oppToUpdate.CloseDate = sOrder.Order_Date__c;
                oppToUpdate.Amount = sOrder.Order_Total__c;
                oppToUpdate.Last_Quote_Xometry_ERP_ID__c = sOrder.P21_Order_OE_ERP_ID__C;
                oppToUpdate.Order_ERP_Xom_ID__c = sOrder.P21_Order_OE_ERP_ID__C;
                if (existingAccountPartnerIDMap.containsKey(sOrder.PartnerID__C)) {
                    oppToUpdate.Primary_Supplier__C = existingAccountPartnerIDMap.get(sOrder.PartnerID__C).Id;
                }
                //ToDo talk to Chris about the specific owner if an Opp was owned by House and at time of owner we get the Zipcode.
                if (
                    oppToUpdate.OwnerId == AppConstants.SUPPLIES_HOUSE_USER &&
                    (allContactExistMap.containsKey(sOrder.Order_Email__C))
                ) {
                    oppToUpdate.OwnerID = allContactExistMap.get(sOrder.Order_Email__C).P21_Account_Details__R.OwnerId;
                }
                oppToUpdate.Shadow_JobId__c = sOrder.XometryJobID__c;
                if (existingJobtoJobIDMap.containsKey(sOrder.XometryJobID__c)) {
                    oppToUpdate.JobId__C = existingJobtoJobIDMap.get(sOrder.XometryJobID__c);
                }
                if (sOrder.eCommerce_Flag__c == true) {
                    oppToUpdate.Sup_Source_Category__c = 'eCommerce';
                } else if (sOrder.SFP_FLAG__C == true) {
                    oppToUpdate.Sup_Source_Category__c = 'SFP';
                    if (oppToUpdate.name.substring(0, 3).toUpperCase() != 'SFP') {
                        oppToUpdate.name = 'SFP ' + oppToUpdate.name;
                    }
                } else {
                    oppToUpdate.Sup_Source_Category__c = '';
                }
                if (existingP21QuoteCaseMap.containsKey(sOrder.P21_Quote_OE_ERP_ID__C)) {
                    Case existingCase = existingP21QuoteCaseMap.get(sOrder.P21_Quote_OE_ERP_ID__C);
                    //Use case information to determine the owner when its a supply sales rep who owns the case
                    if (suppliesSalesRepIDSet.contains(existingCase.OwnerId)) {
                        oppToUpdate.OwnerId = existingCase.OwnerId;
                    }
                    supQuoteCaseLink.add(sOrder);
                }
                oppsToUpsertList.add(oppToUpdate);
            }
        }
        //Opps to Create
        for (Supplies_Order__C sOrder : sOrdersNeedOpps) {
            Opportunity opp = new Opportunity();
            opp.Quote_ERP_XOM_CREATE_ID__c = String.isblank(sOrder.P21_Quote_OE_ERP_ID__C)
                ? sOrder.P21_Order_OE_ERP_ID__C
                : sOrder.P21_Quote_OE_ERP_ID__C;
            opp.Primary_Contact__c = sOrder.ContactID__C;
            Opp.Quote_Type__c = 'Manually-Quoted';
            Opp.AccountID = sOrder.AccountID__C;
            Opp.P21_Account_Details__C = sOrder.P21_Account_DetailsID__C;
            Opp.Line_of_Business__c = 'Supplies';
            Opp.RecordtypeID = oppSuppliesRecordTypeID;
            Opp.ERP_Status__c = 'New';
            // Round Robin Logic on Opps assigned on Account level
            Opp.StageName = 'Closed Won';
            // todo Get a BetterName
            Opp.Name = sOrder.P21_Order_OE_ERP_ID__C;
            Opp.Amount = sOrder.Order_Total__c;
            Date quoteCreatedDate = sOrder.Order_Date__c;
            Opp.CreatedDate = quoteCreatedDate;
            Opp.CloseDate = sOrder.Order_Date__c;
            if (allContactExistMap.containsKey(sOrder.Order_Email__C)) {
                Opp.OwnerID = allContactExistMap.get(sOrder.Order_Email__C).P21_Account_Details__R.OwnerId;
            }
            if (String.isblank(Opp.OwnerID)) {
                Opp.OwnerID = AppConstants.SUPPLIES_HOUSE_USER;
            }
            Opp.Last_Quote_Xometry_ERP_ID__c = sOrder.P21_Order_OE_ERP_ID__C;
            Opp.Order_ERP_Xom_ID__c = sOrder.P21_Order_OE_ERP_ID__C;
            Opp.Original_Quoter_Email__C = sOrder.Order_Email__C;
            Opp.Last_Quote_Xometry_Create_Time__c = sOrder.Order_P21_Last_Updated_Time__c;
            if (existingAccountPartnerIDMap.containsKey(sOrder.PartnerID__C)) {
                Opp.Primary_Supplier__C = existingAccountPartnerIDMap.get(sOrder.PartnerID__C).Id;
            }
            Opp.Shadow_JobId__c = sOrder.XometryJobID__c;
            if (existingJobtoJobIDMap.containsKey(sOrder.XometryJobID__c)) {
                Opp.JobId__C = existingJobtoJobIDMap.get(sOrder.XometryJobID__c);
            }
            if (sOrder.eCommerce_Flag__c == true) {
                opp.Sup_Source_Category__c = 'eCommerce';
            } else if (sOrder.SFP_FLAG__C == true) {
                opp.Sup_Source_Category__c = 'SFP';
                if (opp.name.substring(0, 3).toUpperCase() != 'SFP') {
                    opp.name = 'SFP ' + opp.name;
                }
            } else {
                opp.Sup_Source_Category__c = '';
            }
            if (existingP21QuoteCaseMap.containsKey(sOrder.P21_Quote_OE_ERP_ID__C)) {
                Case existingCase = existingP21QuoteCaseMap.get(sOrder.P21_Quote_OE_ERP_ID__C);
                //Use case information to determine the owner when its a supply sales rep who owns the case
                if (suppliesSalesRepIDSet.contains(existingCase.OwnerId)) {
                    opp.OwnerId = existingCase.OwnerId;
                }
                supQuoteCaseLink.add(sOrder);
            }
            oppsToUpsertList.add(opp);
        }

        //Supplies Opp Routing - Determine the Owner of the Opportunity
        // Check if the Contact has a P21 Owner that is not House (P21 Zip Routing) Done above
        //Rest of Routing Logic is handled in routing method
        if (!oppsToUpsertList.isEmpty()) {
            routingHelper.routeSuppliesOpps(oppsToUpsertList);
        }

        //Upsert the List of Opps
        DatabaseUtilities.upsertToDatabase(
            oppsToUpsertList,
            'SuppliesOrderHandler.processSuppliesOrders',
            'Upserting Opportunities'
        );
        //Opportunity Contact Records
        List<OpportunityContactRole> newOppContactRoleList = new List<OpportunityContactRole>();
        Set<OpportunityContactRole> newOppContactRoleSet = new Set<OpportunityContactRole>();
        Map<String, Opportunity> newOppsCreatedMap = new Map<String, Opportunity>();
        if (!oppsToUpsertList.isEmpty()) {
            for (Opportunity opp : oppsToUpsertList) {
                newOppsCreatedMap.put(opp.Order_ERP_Xom_ID__c, opp);
            }
        }
        for (Supplies_Order__C sOrder : newSuppliesOrderList) {
            if (newOppsCreatedMap.containsKey(sOrder.P21_Order_OE_ERP_ID__C)) {
                ID lOPPID = newOppsCreatedMap.get(sOrder.P21_Order_OE_ERP_ID__C).ID;
                sOrder.OpportunityID__C = lOPPID;
                //Update the Junction Object Create the Decision Maker as the role and set primary
                if (!String.isBlank(sOrder.ContactID__C)) {
                    OpportunityContactRole newOppCRole = new OpportunityContactRole();
                    newOppCRole.ContactID = sOrder.ContactID__C;
                    newOppCRole.IsPrimary = true;
                    newOppCRole.OpportunityID = lOPPID;
                    newOppCRole.Role = 'Decision Maker';
                    newOppContactRoleSet.add(newOppCRole);
                }
            }
        }

        //Insert the junction object
        newOppContactRoleList.addAll(newOppContactRoleSet);
        System.debug('The opportunitiescontact roles to be inserted are ' + newOppContactRoleList);
        DatabaseUtilities.insertToDatabase(
            newOppContactRoleList,
            'SuppliesOrderHandler',
            'OpportunityContact Role Inserts'
        );

        // Update the Case for any Opportunities that were created.
        Map<ID, Case> casesToUpdateMap = new Map<ID, Case>();
        for (Supplies_Order__C sOrder : supQuoteCaseLink) {
            if (existingP21QuoteCaseMap.containsKey(sOrder.P21_Quote_OE_ERP_ID__C)) {
                Case linkCase = existingP21QuoteCaseMap.get(sOrder.P21_Quote_OE_ERP_ID__C);
                linkCase.Opportunity__c = sOrder.OpportunityID__C;
                casesToUpdateMap.put(linkCase.ID, linkCase);
            }
        }

        DatabaseUtilities.saveToDatabase(
            casesToUpdateMap.values(),
            'SuppliesOrderHandler.processSuppliesOrders',
            'Updating existing Cases'
        );

        //Todo call the Lead Convert Method by passing Accountid, ContactId, Oppid Lead Convert Method in another ticket
        // System.debug('At the end of our method with CPU time at: ' + Limits.getCpuTime());
        // System.debug('At the end of our method with Queries at : ' + Limits.getQueries());
    }

    /**
     * @description Retrieves all Opportunities associated with an Order with updated price or status
     * @param updatedOrders List of Order objects updated in Salesforce
     * @param oldOrderMap map of orders changed by the update
     */
    public static void updateOpps(List<Supplies_Order__c> updatedOrders, Map<ID, Supplies_Order__c> oldOrderMap) {
        Set<String> updatedOrderSet = new Set<String>();
        Map<String, Supplies_Order__c> orderMap = new Map<String, Supplies_Order__c>();
        Set<Opportunity> updatedOppSet = new Set<Opportunity>();
        List<Opportunity> oppsUpdateList = new List<Opportunity>();
        Set<String> cancelledOrderSet = new Set<String>();

        for (Supplies_Order__c supOrd : updatedOrders) {
            Supplies_Order__c oldSupOrd = oldOrderMap.get(supOrd.ID);
            if (
                oldSupOrd.Order_Total__C != supOrd.Order_Total__c ||
                oldSupOrd.P21_OE_Status__c != supOrd.P21_OE_Status__c ||
                oldSupOrd.eCommerce_Flag__c != supOrd.eCommerce_Flag__c ||
                oldSupOrd.SFP_FLAG__C != supOrd.SFP_FLAG__C ||
                oldSupOrd.XometryJobID__c != supOrd.XometryJobID__c
            ) {
                updatedOrderSet.add(supOrd.P21_Order_OE_ERP_ID__c);
                orderMap.put(supOrd.P21_Order_OE_ERP_ID__c, supOrd);
                if (oldSupOrd.P21_OE_Status__c != supOrd.P21_OE_Status__c) {
                    cancelledOrderSet.add(supOrd.P21_Order_OE_ERP_ID__c);
                }
            }
        }

        if (!updatedOrderSet.isEmpty()) {
            for (Opportunity opp : [
                SELECT ID, Quote_ERP_XOM_CREATE_ID__c, Order_ERP_Xom_ID__c, Amount, StageName, Name
                FROM Opportunity
                WHERE Order_ERP_Xom_ID__c IN :updatedOrderSet
            ]) {
                if (orderMap.containsKey(opp.Order_ERP_Xom_ID__c)) {
                    Supplies_Order__c so = orderMap.get(opp.Order_ERP_Xom_ID__c);
                    opp.Amount = so.Order_Total__c;
                    opp.Shadow_JobId__c = so.XometryJobID__c;
                    if (so.eCommerce_Flag__c == true) {
                        opp.Sup_Source_Category__c = 'eCommerce';
                    } else if (so.SFP_FLAG__C == true) {
                        opp.Sup_Source_Category__c = 'SFP';
                        if (opp.name.substring(0, 3).toUpperCase() != 'SFP') {
                            opp.name = 'SFP ' + opp.name;
                        }
                    } else {
                        opp.Sup_Source_Category__c = '';
                    }
                    if (cancelledOrderSet.contains(opp.Order_ERP_Xom_ID__c)) {
                        if (opp.StageName == 'Closed Lost' && so.P21_OE_Status__c == 'Active') {
                            opp.StageName = 'Closed Won';
                            opp.Loss_Reason__c = null;
                            opp.Sub_Loss_Reason__c = null;
                            opp.CloseDate = so.Order_Date__c;
                        } else if (opp.StageName != 'Closed Lost' && so.P21_OE_Status__c == 'Canceled') {
                            opp.StageName = 'Closed Lost';
                            opp.Loss_Reason__c = 'Order Cancelled';
                        }
                    }

                    updatedOppSet.add(opp);
                }
            }
            oppsUpdateList.addAll(updatedOppSet);
            DatabaseUtilities.saveToDatabase(
                oppsUpdateList,
                'SuppliesOrderHandler.updateOpps',
                'Opportunity Updates post Order Load'
            );
        }
    }
}