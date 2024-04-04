public with sharing class SuppliesQuoteHandler {
    static final ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer')
        .getRecordTypeID();
    static final ID oppSuppliesRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Supplies')
        .getRecordTypeID();

    /*     public static void updateSuppliesOpps(List<Supplies_Quote__C> newSuppliesQuoteList) {
        //Identify what field can change and what needs to be updated
        
    } */

    public static void processSuppliesQuotes(List<Supplies_Quote__C> newSuppliesQuoteList) {
        /*
            1.This method creates the P21 Account Details
            Will attempt to see if we have a matching P21 Account (this is not the default Account table in Salesforce!) if not identifies P21 Accounts to be created.
            2.Attempt to see if we have an existing Account and if not then makes an account. This default account is owned by Managed Services unless the existing Lead says otherwise.
            Map the P21 Account to an existing Account either by Partner ID or by domain with Generic Logic
            Create a new Account if it does not alreay exist. Origin is Supplies            

            /DnB maybe be able to tell us more about the P21 Customer based on the Address entered into the main Account if it is created. Will need a seperate async job to improve this. 
            3.Route the P21 Account based on Address Information and create P21 Accounts if needed.          
            4.Create the Contact if it does not exists. Identify the origin as Supplies. Link Contacts to P21 Account
            5.Create the Opportunity if it does not exists.
            6.Create the Opportunity Contact Junction
            7.Convert any Leads as needed
            */
        List<Audit_Trail_Error__c> myAuditErrorList = new List<Audit_Trail_Error__c>();
        Set<String> quoteDomainSet = new Set<String>();
        Set<String> quoteEmailSet = new Set<String>();
        Set<String> quotePartnerIDSet = new Set<String>();
        //ID Mapping to the P21 Account Object in Salesforce.
        Set<String> p21CustomerIDSet = new Set<String>();
        Set<String> p21QuoteERPIDSet = new Set<String>();
        Set<String> p21OrderOEIDSet = new Set<String>();
        Set<String> p21XomJobIDSet = new Set<String>();

        for (Supplies_Quote__C sQuote : newSuppliesQuoteList) {
            if (!string.isBlank(sQuote.Account_Domain__c)) {
                quoteDomainSet.add(sQuote.Account_Domain__c);
            }
            if (!string.isBlank(sQuote.quote_Email__C)) {
                quoteEmailSet.add(sQuote.quote_Email__C);
            }
            if (!string.isBlank(sQuote.PartnerID__C)) {
                quotePartnerIDSet.add(sQuote.PartnerID__C);
            }
            if (!string.isBlank(sQuote.P21_ERP_ID__C)) {
                p21QuoteERPIDSet.add(sQuote.P21_ERP_ID__C);
            }
            if (!string.isBlank(sQuote.P21_Order_OE_ERP_ID__C)) {
                p21OrderOEIDSet.add(sQuote.P21_Order_OE_ERP_ID__C);
            }
            if (!string.isBlank(sQuote.P21_CustomerID__C)) {
                p21CustomerIDSet.add(sQuote.P21_CustomerID__C);
            }
            if (!string.isBlank(sQuote.XometryJobID__c)) {
                p21XomJobIDSet.add(sQuote.XometryJobID__c);
            }
        }

        //Use the Same Managed Service Quote ERP Logic for Leads
        Map<String, Lead> existingLeadMap = new Map<String, Lead>();
        existingLeadMap = QuoteERPHandler.fetchExistingLeadsMap(quoteEmailSet);

        Map<String, Contact> existingContactMap = new Map<String, Contact>();
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
        //Use a Supplier before using the domain
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
                SELECT ID, OwnerID, AccountID__C, AccountID__R.OwnerID, P21_CustomerID__C
                FROM P21_Account_Details__c
                WHERE P21_CustomerID__C IN :p21CustomerIDSet
            ];

            if (existingP21AccountList.size() > 0) {
                for (P21_Account_Details__c p21A : existingP21AccountList) {
                    existingP21CustomerMap.put(p21A.P21_CustomerID__C, p21A);
                }
            }
        }

        List<Supplies_Quote__C> sQuoteNeedsSFAccount = new List<Supplies_Quote__C>();
        List<Supplies_Quote__C> sQuoteNeedsP21Account = new List<Supplies_Quote__C>();
        Set<P21_Account_Details__C> p21AccountToCreate = new Set<P21_Account_Details__C>();
        Map<String, P21_Account_Details__C> p21AccountsToCreateMap = new Map<String, P21_Account_Details__C>();
        //Create P21 Account if it does not exists
        for (Supplies_Quote__C sQuote : newSuppliesQuoteList) {
            //Xometry Customer ID of 15077 will be a manually created P21 Account and Salesforce Account for Go Live
            if (existingP21CustomerMap.containsKey(sQuote.P21_CustomerID__C)) {
                P21_Account_Details__C existingP21Customer = existingP21CustomerMap.get(sQuote.P21_CustomerID__C);
                sQuote.OwnerID = existingP21Customer.OwnerID;
                sQuote.AccountID__C = existingP21Customer.AccountID__C;
                sQuote.P21_Account_DetailsID__C = existingP21Customer.ID;
                //Handle scenario for existing
            } else {
                P21_Account_Details__C newP21Account = new P21_Account_Details__C();
                newP21Account.P21_CustomerID__C = sQuote.P21_CustomerID__C;
                newP21Account.name = sQuote.P21_CustomerID__C;
                newP21Account.Primary_Zip_Code__c = sQuote.P21_Physical_Zip_Code__c;
                //Check if we can identify the SF Account based on the Contacts email domain or PartnerID
                //Check if we can identify the SF Account for P21 Account Details if not then make the SF Account
                if (existingAccountPartnerIDMap.containsKey(sQuote.PartnerID__c)) {
                    newP21Account.AccountID__C = existingAccountPartnerIDMap.get(sQuote.PartnerID__C).AccountId__c;
                    sQuote.AccountID__C = existingAccountPartnerIDMap.get(sQuote.PartnerID__C).AccountId__c;
                    if (!string.isBlank(existingAccountPartnerIDMap.get(sQuote.PartnerID__C).Sup_Owner_Stamp__c)) {
                        sQuote.OwnerId = existingAccountPartnerIDMap.get(sQuote.PartnerID__C).Sup_Owner_Stamp__c;
                    } else {
                        sQuote.OwnerId = AppConstants.SUPPLIES_HOUSE_USER;
                    }
                    if (string.isBlank(sQuote.P21_Physical_Zip_Code__c)) {
                        newP21Account.Primary_Zip_Code__c = existingAccountPartnerIDMap.get(sQuote.PartnerID__C)
                            .AccountId__r.Physical_Zip_Code__c;
                    }
                } else if (existingAccountDomainMap.containsKey(sQuote.Account_Domain__c)) {
                    newP21Account.AccountID__C = existingAccountDomainMap.get(sQuote.Account_Domain__c).ID;
                    sQuote.AccountID__C = existingAccountDomainMap.get(sQuote.Account_Domain__c).ID;
                    sQuote.OwnerId = existingAccountDomainMap.get(sQuote.Account_Domain__c).OwnerId;
                    if (string.isBlank(sQuote.P21_Physical_Zip_Code__c)) {
                        newP21Account.Primary_Zip_Code__c = existingAccountDomainMap.get(sQuote.Account_Domain__c)
                            .Physical_Zip_Code__c;
                    }
                } else {
                    sQuoteNeedsSFAccount.add(sQuote);
                }
                sQuoteNeedsP21Account.add(sQuote);
                p21AccountsToCreateMap.put(sQuote.P21_CustomerID__C, newP21Account);
            }
        }
        Map<String, Account> p21CustIDNewSFAccountMap = new Map<String, Account>();
        Map<String, Account> emailDomainAccountMap = new Map<String, Account>();
        List<Account> sfAccountCreateList = new List<Account>();
        //Do not use the PartnerID all Partners should be made GNO Process
        for (Supplies_Quote__C sQuote : sQuoteNeedsSFAccount) {
            //The Main Account will be put under the Managed Services House Account for the time being.
            // Can clean this up later
            Account a = emailDomainAccountMap.get(sQuote.Account_Domain__c);
            if (a == null) {
                a = new Account();
                a.RecordtypeID = accountCustomerRecordTypeID;
                a.LOB_Creation__c = 'Supplies';
                a.LD_USE_DnB_Connect__c  = true;
                a.Account_Owner_Type__c = 'Ops';
                a.Email_Domain__C = sQuote.Account_Domain__c;
                a.Generic_Account__c = sQuote.is_generic__c;
                //The Owner of a High Level Account is always Managed Services or GNO never the Supplies Rep
                a.OwnerID = AppConstants.GNO_HOUSE_USER;
                if (sQuote.is_generic__c) {
                    a.name = sQuote.Quote_Email__C;
                } else {
                    a.name = sQuote.Account_Domain__c;
                }
                //Discuss with team about Origin Field

                //IDEA-499 Check that the leadsource is not Drift and Lead is not owned by API ADMIN  0056A000002S1sMQAS to keep Lead Owner
                if (
                    existingLeadmap.containsKey(sQuote.Quote_Email__C) &&
                    existingLeadMap.get(sQuote.Quote_Email__C).leadsource != 'Drift' &&
                    existingLeadMap.get(sQuote.Quote_Email__C).OwnerID != AppConstants.API_USER
                ) {
                    a.OwnerID = existingLeadMap.get(sQuote.Quote_Email__c).OwnerID;
                }

                emailDomainAccountMap.put(a.Email_Domain__C, a);
                p21CustIDNewSFAccountMap.put(sQuote.P21_CustomerID__C, a);
            }
        }
        sfAccountCreateList.addAll(p21CustIDNewSFAccountMap.values());
        //Create the new SF Accounts
        DatabaseUtilities.insertToDatabase(
            sfAccountCreateList,
            'SuppliesQuoteHandler.processSuppliesQuotes',
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

        for (Supplies_Quote__C sQuote : sQuoteNeedsSFAccount) {
            if (allAccountsDomainMap.containsKey(sQuote.Account_Domain__c)) {
                sQuote.AccountID__C = allAccountsDomainMap.get(sQuote.Account_Domain__c).Id;
                if (p21AccountsToCreateMap.containsKey(sQuote.P21_CustomerID__C)) {
                    p21AccountsToCreateMap.get(sQuote.P21_CustomerID__C).AccountID__C = sQuote.AccountID__C;
                }
            }
        }

        //Get the Owner based on Routing
        List<routingAddress> p21AccountsToRoute = new List<routingAddress>();
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
        }
        // All account should exist at this time. Add the Account to the P21 Account Details that need the new Account
        List<P21_Account_Details__C> p21AccountsToCreateList = p21AccountsToCreateMap.values();

        DatabaseUtilities.insertToDatabase(
            p21AccountsToCreateList,
            'SuppliesQuoteHandler.processSuppliesQuotes',
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

        for (Supplies_Quote__C sQuote : sQuoteNeedsP21Account) {
            if (newP21AccountCustIDMap.containsKey(sQuote.P21_CustomerID__C)) {
                sQuote.P21_Account_DetailsID__C = newP21AccountCustIDMap.get(sQuote.P21_CustomerID__C).ID;
                sQuote.OwnerId = newP21AccountCustIDMap.get(sQuote.P21_CustomerID__C).OwnerId;
                sQuote.AccountId__c = newP21AccountCustIDMap.get(sQuote.P21_CustomerID__C).AccountId__c;
            }
        }

        List<Supplies_Quote__C> sQuotesNeedContactsList = new List<Supplies_Quote__C>();
        Map<ID, Contact> contactNeedP21AcctDetailsMap = new Map<ID, Contact>();
        //Create the Contact if it does not exists and ensure that the Contact is linked to the right P21 Account.
        for (Supplies_Quote__C sQuote : newSuppliesQuoteList) {
            if (existingContactMap.containsKey(sQuote.Quote_Email__C)) {
                Contact con = existingContactMap.get(sQuote.Quote_Email__C);
                sQuote.ContactID__C = con.ID;
                if (con.P21_Account_Details__c == null) {
                    con.P21_Account_Details__c = sQuote.P21_Account_DetailsID__C;
                    contactNeedP21AcctDetailsMap.put(con.ID, con);
                }
            } else {
                sQuotesNeedContactsList.add(sQuote);
            }
        }

        Map<String, Contact> newContactMap = new Map<String, Contact>();

        if (!sQuotesNeedContactsList.isEmpty()) {
            for (Supplies_Quote__C sQuote : sQuotesNeedContactsList) {
                if (!newContactMap.containsKey(sQuote.Quote_Email__C)) {
                    Contact c = new Contact();
                    c.LD_USE_DnB_Contact__c = true;
                    if (!String.isblank(sQuote.P21_Contact_Last_Name__C)) {
                        c.LastName = sQuote.P21_Contact_Last_Name__C;
                    } else {
                        c.LastName = sQuote.Quote_Email__C;
                    }
                    if (!String.isblank(sQuote.P21_Contact_Phone__c)) {
                        c.Phone = sQuote.P21_Contact_Phone__c;
                    }
                    c.FirstName = sQuote.P21_Contact_First_Name__C;
                    c.P21_ContactID__c = sQuote.P21_ContactID__c;
                    c.Email = sQuote.Quote_Email__C;
                    c.Primary_Email__C = sQuote.Quote_Email__C;
                    //Use the Account Owner
                    c.OwnerID = sQuote.OwnerId;
                    c.AccountID = sQuote.AccountID__C;
                    c.P21_Account_Details__c = sQuote.P21_Account_DetailsID__c;
                    //ERP fields shall be overrided with source system
                    c.ERP_Shipping_Address__c = sQuote.P21_Physical_Address__c;
                    c.ERP_Shipping_City__c = sQuote.P21_Physical_City__c;
                    c.ERP_Shipping_Country__c = sQuote.P21_Physical_Country__c;
                    c.ERP_Shipping_State_or_Province__c = sQuote.P21_Physical_State__c;
                    c.ERP_Shipping_Zip_Code__c = sQuote.P21_Physical_Zip_Code__c;
                    c.GNO_PartnerId__c = sQuote.PartnerID__C;
                    c.LeadSource = 'Supplies Quoter';
                    newContactMap.put(c.Primary_Email__C, c);
                }
            }
        }
        List<Contact> newContactList = new List<Contact>();
        if (!newContactMap.isEmpty()) {
            newContactList.addAll(newContactMap.values());
        }

        System.debug('Started: Number of new Contacts created: ' + newContactList.size());
        DatabaseUtilities.insertToDatabase(
            newContactList,
            'SuppliesQuoteHandler.processSuppliesQuotes',
            'Creating new Contacts'
        );

        // Update Contacts that need to be linked to Their P21 Account
        DatabaseUtilities.saveToDatabase(
            contactNeedP21AcctDetailsMap.values(),
            'SuppliesQuoteHandler.processSuppliesQuotes',
            'Updating contacts with P21 Accounts'
        );

        //Update Suppliers that need to be linked to Their P21 Account
        if (supplierNeedsP21AcctMap.size() > 0) {
            for (Supplies_Quote__C sQuote : newSuppliesQuoteList) {
                if (supplierNeedsP21AcctMap.containsKey(sQuote.PartnerID__C)) {
                    Supplier__c sup = supplierNeedsP21AcctMap.get(sQuote.PartnerID__C);
                    if (string.isBlank(sup.P21_Account_Details__c)) {
                        sup.P21_Account_Details__c = sQuote.P21_Account_DetailsID__C;
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

        for (Supplies_Quote__C sQuote : newSuppliesQuoteList) {
            if (allContactExistMap.containsKey(sQuote.Quote_Email__C)) {
                sQuote.ContactID__C = allContactExistMap.get(sQuote.Quote_Email__C).ID;
            }
        }
        //Create the Opportunities
        //Confirm that an Opportunity does not already exist and do not create an Opp if the Order Entry already has an Opp.

        // System.debug('At the start of Opps section with CPU time at: ' + Limits.getCpuTime());
        // System.debug('At the start of Opp section with Queries at : ' + Limits.getQueries());

        //Map Check if any cases exists with a Quote ID if so then use that case information for opp
        Map<String, Case> existingP21QuoteCaseMap = new Map<String, Case>();
        Set<ID> caseHasOppIDSet = new Set<ID>();
        Set<Id> existingcaseOppIDSet = new Set<ID>();
        Set<Id> ownerIDSet = new Set<ID>();
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

        Set<ID> suppliesSalesRepIDSet = new Set<ID>();
        if (!ownerIDSet.isEmpty()) {
            for (User u : [SELECT Id FROM User WHERE ID IN :ownerIDSet AND Supplies_Sales_Rep__c = TRUE]) {
                suppliesSalesRepIDSet.add(u.ID);
            }
        }

        Map<String, Opportunity> existingOppP21QuoteMap = new Map<String, Opportunity>();
        Map<String, Opportunity> existingOppP21OrderMap = new Map<String, Opportunity>();
        Map<ID, Opportunity> existingOppMap = new Map<ID, Opportunity>();

        Map<String, Opportunity> existingOppswithJobMap = new Map<String, Opportunity>();
        Map<String, ID> existingJobtoJobIDMap = new Map<String, ID>();

        //List<Opportunity> existingOpportunityList = [
        for (Opportunity existingOpp : [
            SELECT
                ID,
                StageName,
                Primary_Contact__c,
                OwnerID,
                Shadow_JobId__c,
                JobId__c,
                Quote_ERP_XOM_CREATE_ID__c,
                Last_Quote_Xometry_ERP_ID__c,
                Order_ERP_Xom_ID__c,
                Name
            FROM Opportunity
            WHERE
                Quote_ERP_XOM_CREATE_ID__C IN :p21QuoteERPIDSet
                OR Order_ERP_Xom_ID__c IN :p21OrderOEIDSet
                OR ID IN :caseHasOppIDSet
                OR Shadow_JobId__c IN :p21XomJobIDSet
        ]) {
            if (
                p21QuoteERPIDSet.contains(existingOpp.Quote_ERP_XOM_CREATE_ID__C) ||
                p21OrderOEIDSet.contains(existingOpp.Order_ERP_Xom_ID__c) ||
                caseHasOppIDSet.contains(existingOpp.ID)
            ) {
                if (!string.isBlank(existingOpp.Quote_ERP_XOM_CREATE_ID__C)) {
                    existingOppP21QuoteMap.put(existingOpp.Quote_ERP_XOM_CREATE_ID__C, existingOpp);
                }
                if (!string.isBlank(existingOpp.Order_ERP_Xom_ID__c)) {
                    existingOppP21OrderMap.put(existingOpp.Order_ERP_Xom_ID__c, existingOpp);
                }
                existingOppMap.put(existingOpp.ID, existingOpp);
            }
            if (p21XomJobIDSet.contains(existingOpp.Shadow_JobId__c)) {
                //Only want to grab Job Opps that do not have a SQUOTE or SORDER attached.
                if (existingOpp.Order_ERP_Xom_ID__c == null && existingOpp.Last_Quote_Xometry_ERP_ID__c == null) {
                    existingOppswithJobMap.put(existingOpp.Shadow_JobId__c, existingOpp);
                    existingJobtoJobIDMap.put(existingOpp.Shadow_JobId__c, existingOpp.JobId__C);
                }
            }
        }

        List<Supplies_Quote__C> oppSQuoteStartList = new List<Supplies_Quote__C>();
        Set<String> p21JobQuoteOppExistsAndMarked = new Set<String>();
        List<Supplies_Quote__C> sQuoteToUpdateOpps = new List<Supplies_Quote__C>();
        Map<String, Opportunity> sQuoteUpdateExistingOppsMap = new Map<String, Opportunity>();
        Map<String, Case> caseNeedsOpp = new Map<String, Case>();
        Set<String> existingOpponCaseSet = new Set<String>();
        //Last_Quote_Xometry_ERP_ID__c needs to be finalized on how to use this.
        // Will become pseudo polymorphic  as this starts as a Supplies OE Quote ID and then becomes OE Order ID
        for (Supplies_Quote__C sQuote : newSuppliesQuoteList) {
            if (sQuote.OpportunityID__C == null) {
                if (existingOppP21OrderMap.containsKey(sQuote.P21_Order_OE_ERP_ID__C)) {
                    sQuote.OpportunityID__C = existingOppP21OrderMap.get(sQuote.P21_Order_OE_ERP_ID__C).ID;
                }
                if (existingOppP21QuoteMap.containsKey(sQuote.P21_ERP_ID__C)) {
                    sQuote.OpportunityID__C = existingOppP21QuoteMap.get(sQuote.P21_ERP_ID__C).ID;
                } else if (sQuote.P21_Order_Erp_Flag__c == false) {
                    //if it has been marked as Order but we haven't processed the order wait for the Order to make the Opp
                    //Case Check
                    if (existingP21QuoteCaseMap.containsKey(sQuote.P21_ERP_ID__C)) {
                        Case existingCase = existingP21QuoteCaseMap.get(sQuote.P21_ERP_ID__C);
                        //The Case Exists but does not have an Opp. The quote has a Job and a Supplies Job Opp exists
                        if (
                            !String.isBlank(sQuote.XometryJobID__c) &&
                            existingOppswithJobMap.containsKey(sQuote.XometryJobID__c) &&
                            !p21JobQuoteOppExistsAndMarked.contains(sQuote.XometryJobID__c) &&
                            existingOppswithJobMap.get(sQuote.XometryJobID__c).StageName != 'Closed Won'
                        ) {
                            Opportunity existingOpp = existingOppswithJobMap.get(sQuote.XometryJobID__c);
                            sQuote.OpportunityID__C = existingOpp.ID;
                            p21JobQuoteOppExistsAndMarked.add(sQuote.XometryJobID__c);
                            sQuoteUpdateExistingOppsMap.put(sQuote.P21_ERP_ID__C, existingOpp);
                            existingOpponCaseSet.add(sQuote.P21_ERP_ID__C);
                            sQuoteToUpdateOpps.add(sQuote);
                        } else if (
                            existingCase.Opportunity__c != null &&
                            existingOppMap.containsKey(existingCase.Opportunity__c)
                        ) {
                            //The Case Has an Opp so do not create a new Opp
                            Opportunity existingOpp = existingOppMap.get(existingCase.Opportunity__c);
                            sQuoteToUpdateOpps.add(sQuote);
                            existingOpponCaseSet.add(sQuote.P21_ERP_ID__C);
                            sQuoteUpdateExistingOppsMap.put(sQuote.P21_ERP_ID__C, existingOpp);
                        } else {
                            oppSQuoteStartList.add(sQuote);
                        }
                    } else if (
                        !String.isBlank(sQuote.XometryJobID__c) &&
                        existingOppswithJobMap.containsKey(sQuote.XometryJobID__c)
                    ) {
                        //Job check
                        Opportunity existingOpp = existingOppswithJobMap.get(sQuote.XometryJobID__c);
                        //Existing Job Opp gets one quote attached to it otherwise make a new Opp.
                        if (
                            !p21JobQuoteOppExistsAndMarked.contains(sQuote.XometryJobID__c) &&
                            existingOpp.StageName != 'Closed Won'
                        ) {
                            sQuote.OpportunityID__C = existingOpp.ID;
                            p21JobQuoteOppExistsAndMarked.add(sQuote.XometryJobID__c);
                            sQuoteUpdateExistingOppsMap.put(sQuote.P21_ERP_ID__C, existingOpp);
                            sQuoteToUpdateOpps.add(sQuote);
                        } else if (
                            allContactExistMap.containsKey(sQuote.quote_Email__C) &&
                            allContactExistMap.get(sQuote.quote_Email__C).Suppress_OPPS_AND_LEADS_FLAG__C == false
                        ) {
                            oppSQuoteStartList.add(sQuote);
                            // Add a Shadow Job ID and the actual Job ID.
                        }
                    } else if (
                        allContactExistMap.containsKey(sQuote.quote_Email__C) &&
                        allContactExistMap.get(sQuote.quote_Email__C).Suppress_OPPS_AND_LEADS_FLAG__C == false
                    ) {
                        //todo add safety date for when to not make any Opps
                        oppSQuoteStartList.add(sQuote);
                    }
                }
            }
        }
        List<Supplies_Quote__C> supQuoteCaseLink = new List<Supplies_Quote__C>();
        Map<String, Opportunity> createOppsMap = new Map<String, Opportunity>();
        for (Supplies_Quote__C sQuote : oppSQuoteStartList) {
            if (!createOppsMap.containsKey(sQuote.P21_ERP_ID__C)) {
                Opportunity opp = new Opportunity();
                opp.Quote_ERP_XOM_CREATE_ID__c = sQuote.P21_ERP_ID__C;
                opp.Primary_Contact__c = sQuote.ContactID__C;
                Opp.Quote_Type__c = 'Manually-Quoted';
                Opp.AccountID = SQuote.AccountID__C;
                Opp.P21_Account_Details__C = sQuote.P21_Account_DetailsID__C;
                Opp.Line_of_Business__c = 'Supplies';
                Opp.RecordtypeID = oppSuppliesRecordTypeID;
                Opp.ERP_Status__c = 'New';
                // Round Robin Logic on Opps assigned on Account level
                Opp.StageName = 'New';
                // todo Get a BetterName
                Opp.Name = sQuote.P21_ERP_ID__C;
                Opp.Amount = sQuote.Quote_Price__c;
                Date quoteCreatedDate = sQuote.Quote_P21_Created_Date__c;
                Opp.CreatedDate = quoteCreatedDate;
                Opp.CloseDate = sQuote.Quote_P21_Created_Date__c + 30;
                Opp.OwnerID = allContactExistMap.get(sQuote.Quote_Email__C).P21_Account_Details__R.OwnerId;
                if (String.isblank(Opp.OwnerID)) {
                    Opp.OwnerID = AppConstants.SUPPLIES_HOUSE_USER;
                }
                Opp.Last_Quote_Xometry_ERP_ID__c = sQuote.P21_ERP_ID__C;
                Opp.Original_Quoter_Email__C = sQuote.Quote_Email__C;
                Opp.Last_Quote_Xometry_Create_Time__c = sQuote.Quote_P21_Last_Updated_Time__C;
                if (existingJobtoJobIDMap.containsKey(sQuote.XometryJobID__c)) {
                    Opp.JobId__C = existingJobtoJobIDMap.get(sQuote.XometryJobID__c);
                    Opp.Shadow_JobId__c = sQuote.XometryJobID__c;
                }
                if (existingAccountPartnerIDMap.containsKey(sQuote.PartnerID__C)) {
                    Opp.Primary_Supplier__C = existingAccountPartnerIDMap.get(sQuote.PartnerID__C).Id;
                }
                if (sQuote.SFP_FLAG__C == true) {
                    Opp.Sup_Source_Category__c = 'SFP';
                    Opp.name = 'SFP ' + opp.name;
                } else {
                    Opp.Sup_Source_Category__c = '';
                }
                if (existingP21QuoteCaseMap.containsKey(sQuote.P21_ERP_ID__C)) {
                    Case existingCase = existingP21QuoteCaseMap.get(sQuote.P21_ERP_ID__C);
                    //Use case information to determine the owner when its a supply sales rep who owns the case
                    if (suppliesSalesRepIDSet.contains(existingCase.OwnerId)) {
                        opp.OwnerId = existingCase.OwnerId;
                    }
                    supQuoteCaseLink.add(sQuote);
                }
                createOppsMap.put(sQuote.P21_ERP_ID__C, opp);
            }
        }

        List<Opportunity> oppsInsertList = new List<Opportunity>();
        if (!createOppsMap.isEmpty()) {
            oppsInsertList = createOppsMap.values();
        }
        List<Opportunity> oppsToUpsertList = new List<Opportunity>();
        Map<ID, Opportunity> oppsToUpsertMap = new Map<ID, Opportunity>();
        //Imperfect Map Solution - Some
        for (Supplies_Quote__C sQuote : sQuoteToUpdateOpps) {
            if (sQuoteUpdateExistingOppsMap.containsKey(sQuote.P21_ERP_ID__C)) {
                boolean exstingCaseMarker = false;
                Opportunity oppToUpdate = sQuoteUpdateExistingOppsMap.get(sQuote.P21_ERP_ID__C);

                Contact existingContact = allContactExistMap.get(sQuote.Quote_Email__C);
                if (existingP21QuoteCaseMap.containsKey(sQuote.P21_ERP_ID__C)) {
                    Case existingCase = existingP21QuoteCaseMap.get(sQuote.P21_ERP_ID__C);
                    exstingCaseMarker = true;
                }
                if (String.isBlank(oppToUpdate.Quote_ERP_XOM_CREATE_ID__c)) {
                    oppToUpdate.Quote_ERP_XOM_CREATE_ID__c = sQuote.P21_ERP_ID__C;
                }
                oppToUpdate.AccountID = sQuote.AccountID__C;
                oppToUpdate.Primary_Contact__c = sQuote.ContactID__C;
                if (existingAccountPartnerIDMap.containsKey(sQuote.PartnerID__C)) {
                    oppToUpdate.Primary_Supplier__C = existingAccountPartnerIDMap.get(sQuote.PartnerID__C).Id;
                }
                //ToDo talk to Chris about the specific owner if an Opp was owned by House and at time of owner we get the Zipcode.
                if (oppToUpdate.OwnerId == AppConstants.SUPPLIES_HOUSE_USER) {
                    oppToUpdate.OwnerID = allContactExistMap.get(sQuote.Quote_Email__C).P21_Account_Details__R.OwnerId;
                }
                oppToUpdate.Quote_Type__c = 'Manually-Quoted';
                oppToUpdate.P21_Account_Details__C = sQuote.P21_Account_DetailsID__C;
                oppToUpdate.Line_of_Business__c = 'Supplies';
                oppToUpdate.RecordtypeID = oppSuppliesRecordTypeID;
                if (oppToUpdate.StageName == 'Open') {
                    oppToUpdate.StageName = 'Initial Engagement';
                }
                oppToUpdate.Amount = sQuote.Quote_Price__c;
                if (!string.isBlank(sQuote.P21_Order_OE_ERP_ID__C)) {
                    oppToUpdate.Last_Quote_Xometry_ERP_ID__c = sQuote.P21_Order_OE_ERP_ID__C;
                } else {
                    oppToUpdate.Last_Quote_Xometry_ERP_ID__c = sQuote.P21_ERP_ID__C;
                }

                oppToUpdate.Order_ERP_Xom_ID__c = sQuote.P21_Order_OE_ERP_ID__C;

                if (sQuote.SFP_FLAG__C == true) {
                    oppToUpdate.Sup_Source_Category__c = 'SFP';
                    if (oppToUpdate.name.substring(0, 3).toUpperCase() != 'SFP') {
                        oppToUpdate.name = 'SFP ' + oppToUpdate.name;
                    }
                } else {
                    oppToUpdate.Sup_Source_Category__c = '';
                }
                if (existingP21QuoteCaseMap.containsKey(sQuote.P21_ERP_ID__C)) {
                    Case existingCase = existingP21QuoteCaseMap.get(sQuote.P21_ERP_ID__C);
                    exstingCaseMarker = true;
                    if (suppliesSalesRepIDSet.contains(existingCase.OwnerId)) {
                        oppToUpdate.OwnerId = existingCase.OwnerId;
                    }
                    supQuoteCaseLink.add(sQuote);
                }
                oppsToUpsertMap.put(oppToUpdate.ID, oppToUpdate);
            }
        }
        if (!oppsToUpsertMap.isEmpty()) {
            oppsToUpsertList.addAll(oppsToUpsertMap.values());
        }

        System.debug('The size of the oppsInsertList is : ' + oppsInsertList.size());

        List<Opportunity> oppsToRouteList = new List<Opportunity>();
        oppsToRouteList.addAll(oppsInsertList);
        oppsToRouteList.addAll(oppsToUpsertList);
        if (!oppsToRouteList.isEmpty()) {
            routingHelper.routeSuppliesOpps(oppsInsertList);
        }

        DatabaseUtilities.insertToDatabase(
            oppsInsertList,
            'SuppliesQuoteHandler.processSuppliesQuotes',
            'Creating new Opportunities'
        );
        DatabaseUtilities.saveToDatabase(
            oppsToUpsertList,
            'SuppliesQuoteHandler.processSuppliesQuotes',
            'Updating existing Opportunities'
        );
        // Assign OpportunityIDs to Quotes
        List<OpportunityContactRole> newOppContactRoleList = new List<OpportunityContactRole>();
        Set<OpportunityContactRole> newOppContactRoleSet = new Set<OpportunityContactRole>();
        Map<String, Opportunity> newOppsCreatedMap = new Map<String, Opportunity>();
        Map<String, Opportunity> oppsUpdateMap = new Map<String, Opportunity>();

        if (!oppsInsertList.isEmpty()) {
            for (Opportunity opp : oppsInsertList) {
                newOppsCreatedMap.put(opp.Quote_ERP_XOM_CREATE_ID__c, opp);
            }
        }

        if (!oppsToUpsertList.isEmpty()) {
            for (Opportunity opp : oppsToUpsertList) {
                oppsUpdateMap.put(opp.Quote_ERP_XOM_CREATE_ID__c, opp);
            }
        }

        System.debug('Here is the size of the oppsUpdateMap: ' + oppsUpdateMap.size());
        for (Supplies_Quote__C sQuote : sQuoteToUpdateOpps) {
            if (string.isBlank(sQuote.OpportunityID__C)) {
                if (oppsUpdateMap.containsKey(sQuote.P21_ERP_ID__C)) {
                    sQuote.OpportunityID__C = oppsUpdateMap.get(sQuote.P21_ERP_ID__C).ID;
                }
            }
        }

        for (Supplies_Quote__C sQuote : oppSQuoteStartList) {
            if (newOppsCreatedMap.containsKey(sQuote.P21_ERP_ID__C)) {
                ID lOPPID = newOppsCreatedMap.get(sQuote.P21_ERP_ID__C).ID;
                sQuote.OpportunityID__C = lOPPID;
                //Update the Junction Object Create the Decision Maker as the role and set primary
                if (!String.isBlank(sQuote.ContactID__C)) {
                    OpportunityContactRole newOppCRole = new OpportunityContactRole();
                    newOppCRole.ContactID = sQuote.ContactID__C;
                    newOppCRole.IsPrimary = true;
                    newOppCRole.OpportunityID = lOPPID;
                    newOppCRole.Role = 'Decision Maker';
                    newOppContactRoleSet.add(newOppCRole);
                }
            }
        }
        //Insert the junction object
        newOppContactRoleList.addAll(newOppContactRoleSet);
        //Insert the opportunities
        DatabaseUtilities.insertToDatabase(
            newOppContactRoleList,
            'SuppliesQuoteHandler',
            'OpportunityContact Role Inserts'
        );

        // Update the Case for any Opportunities that were created.
        List<Case> casesToUpdateList = new List<Case>();
        for (Supplies_Quote__C sQuote : supQuoteCaseLink) {
            if (existingP21QuoteCaseMap.containsKey(sQuote.P21_ERP_ID__C)) {
                Case linkCase = existingP21QuoteCaseMap.get(sQuote.P21_ERP_ID__C);
                linkCase.Opportunity__c = sQuote.OpportunityID__C;
                casesToUpdateList.add(linkCase);
            }
        }

        DatabaseUtilities.saveToDatabase(
            casesToUpdateList,
            'SuppliesQuoteHandler.processSuppliesQuotes',
            'Updating existing Cases'
        );

        // Lead Conversion Check
        for (Database.LeadConvertResult lcr : HandlerUtil.leadConverter(newSuppliesQuoteList)) {
            if (!lcr.isSuccess()) {
                //Log errors
                for (Database.Error err : lcr.getErrors()) {
                    Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
                    myAuditError.Module__c = 'SuppliesQuoteHandler';
                    myAuditError.Dev_Audit_Notes__c = 'Lead Convert Conversion';
                    myAuditError.StatusCode__c = err.getStatusCode().name();
                    myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
                    myAuditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
                    myAuditErrorList.add(myAuditError);
                }
            }
        }

        //Todo call the Lead Convert Method by passing Accountid, ContactId, Oppid Lead Convert Method in another ticket
        // System.debug('At the end of our method with CPU time at: ' + Limits.getCpuTime());
        // System.debug('At the end of our method with Queries at : ' + Limits.getQueries());
    }

    /**
     * @description Retrieves all Opportunities associated with an Order with updated price or status
     * @param updatedOrders List of Order objects updated in Salesforce
     * @param oldQuoteMap map of orders changed by the update
     */
    public static void updateOpps(List<Supplies_Quote__c> updatedQuotes, Map<ID, Supplies_Quote__c> oldQuoteMap) {
        Set<String> updatedQuoteSet = new Set<String>();
        Map<String, Supplies_Quote__c> quoteMap = new Map<String, Supplies_Quote__c>();
        Set<Opportunity> updatedOppSet = new Set<Opportunity>();
        List<Opportunity> oppsUpdateList = new List<Opportunity>();
        Set<String> cancelledQuoteSet = new Set<String>();

        for (Supplies_Quote__c supQuote : updatedQuotes) {
            Supplies_Quote__c oldSupQuote = oldQuoteMap.get(supQuote.ID);
            if (
                (oldSupQuote.Quote_Price__c != supQuote.Quote_Price__c ||
                oldSupQuote.P21_OE_Status__c != supQuote.P21_OE_Status__c ||
                oldSupQuote.SFP_FLAG__C != supQuote.SFP_FLAG__C ||
                oldSupQuote.XometryJobID__c != supQuote.XometryJobID__c) && supQuote.P21_Order_Erp_Flag__c == false
            ) {
                updatedQuoteSet.add(supQuote.P21_ERP_ID__C);
                quoteMap.put(supQuote.P21_ERP_ID__C, supQuote);
                if (oldSupQuote.P21_OE_Status__c != supQuote.P21_OE_Status__c) {
                    cancelledQuoteSet.add(supQuote.P21_ERP_ID__C);
                }
            }
        }

        if (!updatedQuoteSet.isEmpty()) {
            for (Opportunity opp : [
                SELECT ID, Quote_ERP_XOM_CREATE_ID__c, Amount, StageName, CloseDate, name
                FROM Opportunity
                WHERE Last_Quote_Xometry_ERP_ID__c IN :updatedQuoteSet
            ]) {
                if (quoteMap.containsKey(opp.Quote_ERP_XOM_CREATE_ID__c)) {
                    Supplies_Quote__c sq = quoteMap.get(opp.Quote_ERP_XOM_CREATE_ID__c);
                    opp.Amount = sq.Quote_Price__c;
                    opp.Shadow_JobId__c = sq.XometryJobID__c;
                    if (sq.SFP_FLAG__C == true) {
                        opp.Sup_Source_Category__c = 'SFP';
                        if (opp.name.substring(0, 2).toUpperCase() != 'SFP') {
                            opp.name = 'SFP ' + opp.name;
                        }
                    } else {
                        opp.Sup_Source_Category__c = '';
                    }
                    if (cancelledQuoteSet.contains(opp.Quote_ERP_XOM_CREATE_ID__c)) {
                        if (opp.StageName == 'Closed Lost' && sq.P21_OE_Status__c == 'Active') {
                            opp.StageName = 'System Reopened';
                            opp.System_Reopened_Flag__c = true;
                            opp.Loss_Reason__c = null;
                            opp.Sub_Loss_Reason__c = null;
                            opp.CloseDate = opp.CloseDate == null ? opp.CloseDate = date.today() + 30 : opp.CloseDate;
                        } else if (opp.Stagename != 'Closed Lost' && sq.P21_OE_Status__c == 'Canceled') {
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
                'SuppliesQuoteHandler.updateOpps',
                'Opportunity Updates post Quote Load'
            );
        }
    }
}