/*
 * @description: this handler contains business logic for Quote_ERP__C trigger
 */
public with sharing class QuoteERPHandler {
    static final String UPDATE_OPP_DEV_NOTE = 'Opportunity Updates post Quote Load';
    static final String UPDATE_OPP_METHOD_NAME = 'QuoteERPHandler.updateOpp';
    static final String DEFAULT_LINE_OF_BUSINESS = 'Instant Quote';
    static final String INSTANT_QUOTE_LINE_OF_BUSINESS = 'Instant Quote';
    static final String MARKETPLACE_LINE_OF_BUSINESS = 'Marketplace';
    static final String WEST_COAST_METHOD_NAME = 'QuoteERPHandler.reassignedWestCoast';

    static final ID accountCustomerRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer')
        .getRecordTypeID();
    static final ID oppManuSRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID oppDefaultRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID quoteManuSRecordTypeID = Schema.SObjectType.Quote_ERP__C.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID quoteDefaultRecordTypeID = Schema.SObjectType.Quote_ERP__C.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID pseCasetRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('PSE_Case')
        .getRecordTypeID();
    static final ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final ID dfmCaseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('DFM_Case')
        .getRecordTypeID();
    static final ID caseMgmtCaseRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('CaseMgmt')
        .getRecordTypeID();

    public static List<Case> nyopCasesToUpdate = new List<Case>();

    /**
     * @description reassigns associated quote information
     * @param newQuoteERPList a list of new quotes to be inserted
     */
    public static void reassignWestCoast(List<Quote_ERP__C> newQuoteERPList) {
        Set<ID> associatedAccountSet = new Set<ID>();
        Set<ID> associatedContactsSet = new Set<ID>();
        Set<ID> associatedOppSet = new Set<ID>();

        Set<ID> reassignedAccountIDSet = new Set<ID>();

        Set<Account> reassignedAccountUpdateSet = new Set<Account>();
        List<Account> reassignedAccountUpdateList = new List<Account>();

        Set<Contact> reassignedContactsUpdateSet = new Set<Contact>();
        List<Contact> reassignedContactsUpdateList = new List<Contact>();

        Set<Opportunity> reassignedOppsUpdateSet = new Set<Opportunity>();
        List<Opportunity> reassignedOppsUpdateList = new List<Opportunity>();

        Set<Id> quoteAccountIds = new Set<Id>();

        for (Quote_ERP__c q : newQuoteERPList) {
            quoteAccountIds.add(q.AccountId__c);
        }

        Map<ID, Account> accountMap = new Map<ID, Account>(
            [
                SELECT ID, BillingState, BillingCountry, Parent.BillingState, Parent.BillingCountry
                FROM Account
                WHERE Id IN :quoteAccountIds
            ]
        );

        // get the billing address for all quotes (skip if nonexistant)
        for (Quote_ERP__c q : newQuoteERPList) {
            // filter down to west coast (CA, OR, WA, NV, AK, HI)
            if (
                coalesceCountry(accountMap.get(q.AccountId__c), q.ERP_Billing_Country__c) == 'United States' &&
                AppConstants.WEST_COAST_STATES.contains(
                    coalesceState(accountMap.get(q.AccountId__c), q.ERP_Billing_State_or_Province__c)
                ) &&
                q.IS_Generic__c == false
            ) {
                // reassign all quotes to west coast
                // TODO: Round Robin logic for BDRs
                associatedAccountSet.add(q.AccountID__c);
                associatedContactsSet.add(q.ContactID__c);
                associatedOppSet.add(q.OpportunityID__C);
            }
        }

        if (!associatedOppSet.isEmpty() || !associatedContactsSet.isEmpty() || !associatedAccountSet.isEmpty()) {
            ID westCoastBDR;

            // First West Coast BDRs from the public group
            westCoastBDR = [
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE GroupID = :AppConstants.WEST_COAST_BDR_GROUP
                LIMIT 1
            ]
            .UserOrGroupId;

            if (!associatedAccountSet.isEmpty()) {
                // reassign account if owned by bdr
                List<Account> reassignedAccounts = [
                    SELECT ID, OwnerID, Owner.UserRole.Name
                    FROM Account
                    WHERE Id IN :associatedAccountSet
                ];
                if (!reassignedAccounts.isEmpty()) {
                    for (Account a : reassignedAccounts) {
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
            }

            if (!associatedContactsSet.isEmpty()) {
                // reassign contact if owned by bdr
                List<Contact> reassignedContacts = [
                    SELECT ID, OwnerID, Owner.UserRole.Name
                    FROM Contact
                    WHERE Id IN :associatedContactsSet
                ];

                if (!reassignedContacts.isEmpty()) {
                    for (Contact c : reassignedContacts) {
                        if (c.Owner.UserRole.Name == AppConstants.BDR_NAME) {
                            c.OwnerID = westCoastBDR;
                            reassignedContactsUpdateSet.add(c);
                        } else {
                            associatedContactsSet.remove(c.ID);
                        }
                    }

                    reassignedContactsUpdateList.addAll(reassignedContactsUpdateSet);

                    DatabaseUtilities.saveToDatabase(
                        reassignedContactsUpdateList,
                        WEST_COAST_METHOD_NAME,
                        AppConstants.WEST_COAST_CONTACT_DEV_NOTE
                    );
                }
            }

            if (!associatedOppSet.isEmpty()) {
                // reassign contact if owned by bdr
                List<Opportunity> reassignedOpps = [
                    SELECT ID, OwnerID, StageName
                    FROM Opportunity
                    WHERE
                        Id IN :associatedOppSet
                        AND StageName NOT IN ('Closed Won', 'Closed Lost')
                        AND Owner.UserRole.Name = :AppConstants.BDR_NAME
                ];

                if (!reassignedOpps.isEmpty()) {
                    for (Opportunity opp : reassignedOpps) {
                        opp.OwnerID = westCoastBDR;
                        reassignedOppsUpdateSet.add(opp);
                    }

                    reassignedOppsUpdateList.addAll(reassignedOppsUpdateSet);

                    DatabaseUtilities.saveToDatabase(
                        reassignedOppsUpdateList,
                        WEST_COAST_METHOD_NAME,
                        AppConstants.WEST_COAST_CONTACT_DEV_NOTE
                    );
                }
            }

            for (Quote_ERP__c q : newQuoteERPList) {
                if (associatedAccountSet.contains(q.AccountID__c) && associatedContactsSet.contains(q.ContactID__c)) {
                    q.OwnerID = westCoastBDR;
                }
            }
        }
        // todo: async job to reassign all other contacts owned by the account to the account owner
    }

    //THIS IS ONLY USED IN TEST METHOD

    /**
     * @description returns the maximum amount required to create an Opportunity
     */
    public static double getOppMaxCreationAmount() {
        Admin_Ref_Variable__mdt adminRefVarValues = [
            SELECT DeveloperName, Number_Ref_Value__C
            FROM admin_ref_variable__mdt
            WHERE DeveloperName = 'Opportunity_Max_Creation_Amount'
        ][0];
        Double oppMaxAmountCreationVar = adminRefVarValues.Number_Ref_Value__C;
        if (oppMaxAmountCreationVar == null) {
            //If the custom metadata is missing we will use the original default value of 10,000,000
            oppMaxAmountCreationVar = 10000000;
        }
        return oppMaxAmountCreationVar;
    }

    /**
     * @description populate the Record Type on Quotes based on the Line of Business Value
     * Assigns the default record type if the recordtype is blank and the Line of Business (LOB) is blank
     * @param newQuotesERPList a list of quotes to be inserted
     */
    public static void LOBToRecordTypes(List<Quote_ERP__C> newQuoteERPList) {
        //Line of Business to determine record types a Default Record Type is assigned in the variables
        //This is an integration object so record types are controlled by the Logic Here.

        for (Quote_ERP__c q : newQuoteERPList) {
            if (
                q.Line_of_Business__c == MARKETPLACE_LINE_OF_BUSINESS ||
                q.Line_of_Business__c == INSTANT_QUOTE_LINE_OF_BUSINESS
            ) {
                q.RecordtypeID = quoteManuSRecordTypeID;
            } else if (String.isblank(q.Line_of_Business__c)) {
                //Use the default variables.
                q.Line_of_Business__c = DEFAULT_LINE_OF_BUSINESS;
                q.RecordtypeID = quoteDefaultRecordTypeID;
            } else {
                q.RecordtypeID = quoteDefaultRecordTypeID;
            }
        }
    }
    /**
     * @description populates Account and/or Contacts with Quotes information.
     * Also updates Leads with First and Last Quote Dates
     * @param newQuotesERPList a list of quotes to be updated
     */
    public static void QuoteDateofFirstQuotePop(List<Quote_ERP__c> newQuotesERPList) {
        Set<ID> accountIDSet = new Set<ID>();
        Set<ID> leadIDSet = new Set<ID>();
        Map<ID, Quote_ERP__c> accountIDFirstQuoteMap = new Map<ID, Quote_ERP__c>();
        Map<ID, Quote_ERP__c> accountIDLastQuoteMap = new Map<ID, Quote_ERP__c>();
        Map<ID, List<Quote_ERP__c>> contactIDQuoteListMap = new Map<ID, List<Quote_ERP__c>>();
        Map<ID, Quote_ERP__c> leadIDFirstQuoteMap = new Map<ID, Quote_ERP__c>();
        Map<ID, Quote_ERP__c> leadIDLastQuoteMap = new Map<ID, Quote_ERP__c>();

        for (Quote_ERP__c q : newQuotesERPList) {

            if (!String.isblank(q.AccountID__c)) {
                accountIDSet.add(q.AccountID__c);
                if (!accountIDFirstQuoteMap.containsKey(q.AccountID__c)) {
                    accountIDFirstQuoteMap.put(q.AccountID__c, q);
                } else {
                    if (
                        q.Quote_ERP_Created_Date__c <
                        accountIDFirstQuoteMap.get(q.AccountID__c).Quote_ERP_Created_Date__c
                    ) {
                        accountIDFirstQuoteMap.put(q.AccountID__c, q);
                    }
                }
                if (!accountIDLastQuoteMap.containsKey(q.AccountID__c)) {
                    accountIDLastQuoteMap.put(q.AccountID__c, q);
                } else {
                    if (
                        q.Quote_ERP_Created_Date__c >
                        accountIDLastQuoteMap.get(q.AccountID__c).Quote_ERP_Created_Date__c
                    ) {
                        accountIDLastQuoteMap.put(q.AccountID__c, q);
                    }
                }
            }

            if (!String.isBlank(q.ContactID__c)) {

                if( !contactIDQuoteListMap.containsKey(q.ContactID__C) ){
                    contactIDQuoteListMap.put(q.ContactID__C, new List<Quote_ERP__C>());
                }
                contactIDQuoteListMap.get(q.ContactID__C).add(q);

            }

            //Only do Leads when just leads
            if (!String.isBlank(q.LeadID__c) && String.isBlank(q.ContactID__c) && String.isBlank(q.AccountID__c)) {
                leadIDSet.add(q.LeadID__c);
                if (!leadIDFirstQuoteMap.containsKey(q.LeadID__C)) {
                    leadIDFirstQuoteMap.put(q.LeadID__C, q);
                } else {
                    if (q.Quote_ERP_Created_Date__c < leadIDFirstQuoteMap.get(q.LeadID__C).Quote_ERP_Created_Date__c) {
                        leadIDFirstQuoteMap.put(q.LeadID__C, q);
                    }
                }
                if (!leadIDLastQuoteMap.containsKey(q.LeadID__C)) {
                    leadIDLastQuoteMap.put(q.LeadID__C, q);
                } else {
                    if (q.Quote_ERP_Created_Date__c > leadIDLastQuoteMap.get(q.LeadID__C).Quote_ERP_Created_Date__c) {
                        leadIDLastQuoteMap.put(q.LeadID__C, q);
                    }
                }
            }
        }

        if (!contactIDQuoteListMap.isEmpty()) {

            List<Contact> listContactUpdateList = new List<Contact>();

            //Get Contacts to Compare
            for (Contact c : [
                SELECT ID, First_Quote_Date__c, Date_of_Last_Quote__c,
                Has_Used_Punchout__c, First_Quote_Punchout__c
                FROM Contact
                WHERE ID IN :contactIDQuoteListMap.keySet()
            ]) {

                Boolean cond = false;

                for( Quote_ERP__C q : contactIDQuoteListMap.get(c.Id) ){

                    if( c.Has_Used_Punchout__c != true && q.Quote_Source__c == AppConstants.QSRC_Punchout ){
                       
                        c.Has_Used_Punchout__c = true;
                        cond = true;

                    }

                    if (
                        (c.First_Quote_Date__c > q.Quote_ERP_Created_Date__c) ||
                        c.First_Quote_Date__c == null
                    ) {

                        c.First_Quote_Date__c = q.Quote_ERP_Created_Date__c;
                        
                        if( c.First_Quote_Punchout__c != true && q.Quote_Source__c == AppConstants.QSRC_Punchout ){
                            c.First_Quote_Punchout__c = true;
                        }

                        if( c.First_Quote_Punchout__c == true && q.Quote_Source__c != AppConstants.QSRC_Punchout ){
                            c.First_Quote_Punchout__c = false;
                        }

                        cond = true;
                    }

                    if (
                        (c.Date_of_Last_Quote__c < q.Quote_ERP_Created_Date__c) ||
                        c.Date_of_Last_Quote__c == null
                    ) {

                        c.Date_of_Last_Quote__c = q.Quote_ERP_Created_Date__c;
                        cond = true;

                    }

                }

                if(cond){
                    listContactUpdateList.add(c);
                }

            }

            DatabaseUtilities.saveToDatabase(
                listContactUpdateList,
                'QuoteERPHandler.QuoteDateofFirstQuotePop',
                'Contact Updates post Quote'
            );
        }

        if (!accountIDSet.isEmpty()) {
            //Get Accounts to Compare
            List<Account> accountFetchList = [
                SELECT ID, Date_of_First_Quote__c, Date_of_Last_Quote__C
                FROM Account
                WHERE ID IN :accountIDSet
            ];

            Set<account> accountUpdateSet = new Set<account>();
            for (account a : accountFetchList) {
                if (accountIDFirstQuoteMap.containsKey(a.ID)) {
                    if (
                        (a.Date_of_First_Quote__c > accountIDFirstQuoteMap.get(a.ID).Quote_ERP_Created_Date__c) ||
                        a.Date_of_First_Quote__c == null
                    ) {
                        a.Date_of_First_Quote__c = accountIDFirstQuoteMap.get(a.ID).Quote_ERP_Created_Date__c;
                    }
                }
                if (accountIDFirstQuoteMap.containsKey(a.ID)) {
                    if (
                        (a.Date_of_Last_Quote__c < accountIDFirstQuoteMap.get(a.ID).Quote_ERP_Created_Date__c) ||
                        a.Date_of_Last_Quote__c == null
                    ) {
                        a.Date_of_Last_Quote__c = accountIDFirstQuoteMap.get(a.ID).Quote_ERP_Created_Date__c;
                    }
                }
                accountUpdateSet.add(a);
            }

            List<account> listAccountUpdateList = new List<Account>();
            listAccountUpdateList.addAll(accountUpdateSet);

            DatabaseUtilities.saveToDatabase(
                listAccountUpdateList,
                'QuoteERPHandler.QuoteDateofFirstQuotePop',
                'Account Updates post Quote'
            );
        }

        if (!leadIDSet.isEmpty()) {
            List<Lead> leadFetchList = [
                SELECT ID, First_Quote_Date__c, Date_of_Last_Quote__c
                FROM Lead
                WHERE ID IN :leadIDSet AND isConverted = FALSE
            ];

            //Leads
            Set<lead> leadUpdateSet = new Set<lead>();
            for (lead l : leadFetchList) {
                if (leadIDFirstQuoteMap.containsKey(l.ID)) {
                    if (
                        (l.First_Quote_Date__c > leadIDFirstQuoteMap.get(l.ID).Quote_ERP_Created_Date__c) ||
                        l.First_Quote_Date__c == null
                    ) {
                        l.First_Quote_Date__c = leadIDFirstQuoteMap.get(l.ID).Quote_ERP_Created_Date__c;
                    }
                }
                if (leadIDLastQuoteMap.containsKey(l.ID)) {
                    if (
                        (l.Date_of_Last_Quote__c < leadIDLastQuoteMap.get(l.ID).Quote_ERP_Created_Date__c) ||
                        l.Date_of_Last_Quote__c == null
                    ) {
                        l.Date_of_Last_Quote__c = leadIDLastQuoteMap.get(l.ID).Quote_ERP_Created_Date__c;
                    }
                }
                leadUpdateSet.add(l);
            }

            List<Lead> listLeadUpdateList = new List<Lead>();
            listLeadUpdateList.addAll(leadUpdateSet);

            DatabaseUtilities.saveToDatabase(
                listLeadUpdateList,
                'QuoteERPHandler.QuoteDateofFirstQuotePop',
                'Lead Updates post Quote'
            );
        }
    }

    /**
     * @description update the contact fields based in the last QuoteERP
     * Also updates Leads with First and Last Quote Dates
     * @param newQuoteMap a map of quotes with new values
     * @param oldQuoteMap a map of quotes with old values
     */
    public static void updateContactLastQuote(Map<ID, Quote_ERP__C> newQuoteMap, Map<ID, Quote_ERP__C> oldQuoteMap) {
        Map<String, Quote_ERP__C> quoteXomERPId = new Map<String, Quote_ERP__C>();
        Map<String, Quote_ERP__C> mapEmail = new Map<String, Quote_ERP__C>();
        List<Quote_ERP__C> quoteWithDFMList = new List<Quote_ERP__C>();

        for (Quote_ERP__C q : newQuoteMap.values()) {
            Quote_ERP__C qOldRecord = oldQuoteMap.get(q.Id);

            if (
                (String.isblank(qOldRecord.DFM_Description__C) ||
                qOldRecord.DFM_Description__c != q.DFM_Description__c) &&
                !String.isBlank(q.DFM_Description__c) &&
                !String.isBlank(q.Quote_Email__c)
            ) {
                quoteXomERPId.put(q.Xometry_ERP_ID__c, q);
                mapEmail.put(q.Quote_Email__c, q);
                quoteWithDFMList.add(q);
            }
        }

        if (!quoteXomERPId.isEmpty()) {
            Map<String, Contact> contactsExistMap = new Map<String, Contact>();
            //Get Contacts to Compare
            for (Contact c : [
                SELECT ID, DFM_Quote__c, Date_of_Last_DFM_Quote__c, DFM_Description__c, Primary_Email__C
                FROM Contact
                WHERE Primary_Email__C IN :mapEmail.keySet()
            ]) {
                contactsExistMap.put(c.Primary_Email__C, c);
            }

            Set<contact> contactUpdateSet = new Set<contact>();
            for (quote_erp__c q : quoteWithDFMList) {
                if (contactsExistMap.containsKey(q.Quote_Email__C)) {
                    Contact contLastValues = contactsExistMap.get(q.Quote_Email__C);
                    if (
                        (!String.isblank(q.DFM_Description__c)) &&
                        (contLastValues.Date_of_Last_DFM_Quote__c == null ||
                        q.Quote_ERP_Created_Time__c >= contLastValues.Date_of_Last_DFM_Quote__c)
                    ) {
                        contLastValues.DFM_Description__c = q.DFM_Description__c;
                        contLastValues.DFM_Quote__c = q.Xometry_ERP_ID__c;
                        contLastValues.Date_of_Last_DFM_Quote__c = q.Quote_ERP_Created_Time__c;
                        contactsExistMap.put(contLastValues.Primary_Email__C, contLastValues);
                    }
                }
            }

            DatabaseUtilities.saveToDatabase(
                contactsExistMap.values(),
                'QuoteERPHandler.updateContactLastQuote',
                'Updates last Quote fields in the contact'
            );
        }
    }

    /**
     * @description Creates Opportunities for Quotes that had their amounts updated based on creation criteria
     * @param newQuoteERPList a list of quotes to be updated
     * @param oldQuoteMap the map for how the quotes looked before update
     * @param newQuoteMap the map for how the quotes will look in the update
     *
     */
    public static void processCheckforPricePostQuoteCreation(
        List<Quote_ERP__C> newQuoteERPList,
        Map<ID, Quote_ERP__C> oldQuoteMap,
        Map<ID, Quote_ERP__C> newQuoteMap
    ) {
        List<Quote_ERP__C> quotesNeedOpps = new List<Quote_ERP__C>();
        List<Opportunity> oppsToCreate = new List<Opportunity>();

        for (Quote_ERP__C q : newQuoteERPList) {
            if (oldQuoteMap.containsKey(q.ID)) {
                Quote_ERP__C compareOldQuote = oldQuoteMap.get(q.ID);
                // Check if Old does not have lead and does not have opportunity
                if (
                    String.isBlank(compareOldQuote.LeadID__C) &&
                    String.isBlank(compareOldQuote.OpportunityID__C) &&
                    //Contact and Account Should Exist
                    !String.isBlank(q.AccountID__C) &&
                    !String.isBlank(q.ContactID__C) &&
                    String.isBlank(q.OpportunityID__C) &&
                    q.Order_Time_Flag__c == false
                ) {
                    quotesNeedOpps.add(q);
                }
            }
        }

        if (!quotesNeedOpps.isEmpty()) {
            // Method to Create Quotes
            oppsToCreate = QuoteToNewOpp(quotesNeedOpps);

            //Insert the opportunities
            DatabaseUtilities.insertToDatabase(
                oppsToCreate,
                'QuoteERPHandler.PricePostQuoteCreation',
                'Opportunity Inserts'
            );

            Map<String, Opportunity> oppNewMap = new Map<String, Opportunity>();
            for (Opportunity opp : oppsToCreate) {
                oppNewMap.put(opp.Quote_ERP_XOM_CREATE_ID__c, opp);
            }

            //Update the Opportunity Contact Role
            List<OpportunityContactRole> oppConRolInsList = OpportunityContactRoleNew(oppsToCreate);

            //Insert the opportunities

            DatabaseUtilities.insertToDatabase(
                oppConRolInsList,
                'QuoteERPHandler.PricePostQuoteCreation',
                'pportunityContact Role Inserts'
            );

            //Update the Opportunity on the Quote
            for (Quote_ERP__C q : quotesNeedOpps) {
                if (oppNewMap.containsKey(q.Xometry_ERP_ID__C)) {
                    q.OpportunityID__C = oppNewMap.get(q.Xometry_ERP_ID__C).ID;
                }
            }
        }
    }

    /**
     * @description helper method for Opportunity Contact Roles
     * @param oppsNeedingConRole list of Opportunities without associated OpportunityContactRoles
     * @return List of OpportunityContactRoles for each Opportunity passed
     */
    public static List<OpportunityContactRole> OpportunityContactRoleNew(List<Opportunity> oppsNeedingConRole) {
        List<OpportunityContactRole> oppConRoleListRet = new List<OpportunityContactRole>();
        for (Opportunity opp : oppsNeedingConRole) {
            OpportunityContactRole newOppCRole = new OpportunityContactRole();
            newOppCRole.ContactID = opp.Primary_Contact__c;
            newOppCRole.IsPrimary = true;
            newOppCRole.OpportunityID = opp.ID;
            newOppCRole.Role = 'Decision Maker';
            oppConRoleListRet.add(newOppCRole);
        }
        return oppConRoleListRet;
    }

    /**
     * @description helper method for creating Opportunities from Quotes
     * @param inQuoteList list of Quotes eligible to generate new Opportunties
     * @return List of newly created Opportunities
     */
    public static List<Opportunity> QuoteToNewOpp(List<Quote_ERP__C> inQuoteList) {
        Set<ID> contactOwnerIDSet = new Set<ID>();
        for (Quote_ERP__C q : inQuoteList) {
            contactOwnerIDSet.add(q.ContactID__C);
        }

        Map<ID, Contact> contactOwnerMap = new Map<ID, Contact>(
            [SELECT ID, OwnerId FROM Contact WHERE ID IN :contactOwnerIDSet]
        );

        List<Opportunity> newOppList = new List<Opportunity>();
        for (Quote_ERP__C q : inQuoteList) {
            Opportunity Opp = new Opportunity();
            Opp.Line_of_Business__c = q.Line_of_Business__c;
            if (
                q.Line_of_Business__c == INSTANT_QUOTE_LINE_OF_BUSINESS ||
                q.Line_of_Business__c == MARKETPLACE_LINE_OF_BUSINESS
            ) {
                Opp.RecordtypeID = oppManuSRecordTypeID;
            } else {
                //default recordType logic
                Opp.RecordtypeID = oppDefaultRecordTypeID;
            }
            Opp.ERP_Status__c = q.ERP_Status__c;
            Opp.AccountID = q.AccountID__C;
            Opp.StageName = 'Open';
            Opp.Name = q.Xometry_ERP_ID__C;
            Opp.Amount = q.Quote_Price__C;
            Opp.order_Discount__c = q.Quote_Discount__c;
            Opp.order_Redeemed_Points_Value__c = q.Quote_Redeemed_Points_Value__c;
            Opp.SubTotal__c = q.Quote_Sub_Total__c;
            Opp.order_Shipping__c = q.Quote_Shipping__c;
            Opp.Quote_Created_Date__c = q.Quote_ERP_Created_Date__c;
            Date quoteCreatedDate = q.Quote_ERP_Created_Date__c;
            Opp.CloseDate = quoteCreatedDate + 30;
            if (contactOwnerMap.containsKey(q.ContactID__C)) {
                Opp.OwnerID = contactOwnerMap.get(q.ContactID__C).OwnerId;
            } else {
                Opp.OwnerID = q.OwnerID;
            }

            Opp.Quote_ERP_XOM_CREATE_ID__c = q.Xometry_ERP_ID__c;
            Opp.Last_Quote_Xometry_ERP_ID__c = q.Xometry_ERP_ID__C;
            Opp.Original_Quoter_Email__C = q.Quote_Email__C;
            Opp.Primary_Contact__c = q.ContactID__C;
            Opp.Last_Quote_Xometry_Create_Time__c = q.Quote_ERP_Last_Updated_Time__c;
            Opp.most_recent_quote_Carbon__c = q.process_isCarbon__c;
            Opp.most_recent_quote_CNC_Machining__c = q.process_isCNC_Machining__c;
            Opp.most_recent_quote_Die_Casting__c = q.process_isDie_Casting__c;
            Opp.most_recent_quote_Direct_Sourced__c = q.process_isDirect_Sourced__c;
            Opp.most_recent_quote_DMLS__c = q.process_isDMLS__c;
            Opp.most_recent_quote_Extrusion__c = q.process_isExtrusion__c;
            Opp.most_recent_quote_FDM__c = q.process_isFDM__c;
            Opp.most_recent_quote_HPMultiJetFusion__c = q.process_isHPMultJetFusion__c;
            Opp.most_recent_quote_Injection_Molding__c = q.process_isInjection_Molding__c;
            Opp.Most_Recent_Quote_Injection_Molding_Tool__c = q.process_isInjectionMoldingTool__c;
            Opp.most_recent_quote_PolyJet_3D__c = q.process_isPolyJet_3D__c;
            Opp.most_recent_quote_PlasticExtrusion__c = q.process_isPlasticExtrusion__c;
            Opp.most_recent_quote_Sheet_metal__c = q.process_isSheet_metal__c;
            Opp.most_recent_quote_SLA__c = q.process_isSLA__c;
            Opp.most_recent_quote_SLS__c = q.process_isSLS__c;
            Opp.most_recent_quote_Stamping__c = q.process_isStamping__c;
            Opp.most_recent_quote_Urethane_Casting__c = q.process_isUrethane_Casting__c;
            Opp.most_recent_quote_BinderJetting__c = q.process_isBinderJetting__c;
            Opp.most_recent_quote_SheetCutting__c = q.process_isSheetCutting__c;
            Opp.most_recent_quote_TubeBending__c = q.process_isTubeBending__c;
            Opp.most_recent_quote_TubeCutting__c = q.process_isTubeCutting__c;
            Opp.most_recent_quote_Other__c = q.process_isOther__c;
            Opp.most_recent_quote_Other_NotIncluded__c = q.process_isOther_NotIncluded__c;
            Opp.most_recent_quote_LSPc__c = q.process_isLSPc__c;
            Opp.most_recent_quote_Assembly__c = q.process_isAssembly__c;
            Opp.Total_Amt_Carbon__c = q.Quoted_Total_Amt_Carbon__c;
            Opp.Total_Amt_CNC__c = q.Quoted_Total_Amt_CNC__c;
            Opp.Total_Amt_DieCasting__c = q.Quoted_Total_Amt_DieCasting__c;
            Opp.Total_Amt_DirectSourced__c = q.Quoted_Total_Amt_DirectSourced__c;
            Opp.Total_Amt_DMLS__c = q.Quoted_Total_Amt_DMLS__c;
            Opp.Total_Amt_Extrusion__c = q.Quoted_Total_Amt_Extrusion__c;
            Opp.Total_Amt_FDM__c = q.Quoted_Total_Amt_FDM__c;
            Opp.Total_Amt_HPMultJetFusion__c = q.Quoted_Total_Amt_HPMultJetFusion__c;
            Opp.Total_Amt_InjectionMolding__c = q.Quoted_Total_Amt_InjectionMolding__c;
            Opp.Total_Amt_InjectionMoldingTool__c = q.Quoted_Total_Amt_InjectionMoldingTool__c;
            Opp.Total_Amt_PolyJet3D__c = q.Quoted_Total_Amt_PolyJet3D__c;
            Opp.Total_Amt_PlasticExtrusion__c = q.Quoted_Total_Amt_PlasticExtrusion__c;
            Opp.Total_Amt_SheetMetal__c = q.Quoted_Total_Amt_SheetMetal__c;
            Opp.Total_Amt_SLA__c = q.Quoted_Total_Amt_SLA__c;
            Opp.Total_Amt_SLS__c = q.Quoted_Total_Amt_SLS__c;
            Opp.Total_Amt_Stamping__c = q.Quoted_Total_Amt_Stamping__c;
            Opp.Total_Amt_UrethaneCasting__c = q.Quoted_Total_Amt_UrethaneCasting__c;
            opp.Total_Amt_BinderJetting__c = q.Quoted_Total_Amt_BinderJetting__c;
            opp.Total_Amt_SheetCutting__c = q.Quoted_Total_Amt_SheetCutting__c;
            Opp.Total_Amt_Tube_Bending__c = q.Quoted_Total_Amt_Tube_Bending__c;
            Opp.Total_Amt_Tube_Cutting__c = q.Quoted_Total_Amt_Tube_Cutting__c;
            Opp.Total_Amt_Other__c = q.Quoted_Total_Amt_Other__c;
            Opp.Total_Amt_Other_NotIncluded__c = q.Quoted_Total_Amt_Other_NotIncluded__c;
            Opp.Total_Amt_LSPc__c = q.Quoted_Total_Amt_LSPc__c;
            Opp.Total_Amt_Assembly__c = q.Quoted_Total_Amt_Assembly__c;
            Opp.Total_Qty_Carbon__c = q.Quoted_Total_Qty_Carbon__c;
            Opp.Total_Qty_CNC__c = q.Quoted_Total_Qty_CNC__c;
            Opp.Total_Qty_DieCasting__c = q.Quoted_Total_Qty_DieCasting__c;
            Opp.Total_Qty_DirectSourced__c = q.Quoted_Total_Qty_DirectSourced__c;
            Opp.Total_Qty_DMLS__c = q.Quoted_Total_Qty_DMLS__c;
            Opp.Total_Qty_Extrusion__c = q.Quoted_Total_Qty_Extrusion__c;
            Opp.Total_Qty_FDM__c = q.Quoted_Total_Qty_FDM__c;
            Opp.Total_Qty_HPMultJetFusion__c = q.Quoted_Total_Qty_HPMultJetFusion__c;
            Opp.Total_Qty_InjectionMolding__c = q.Quoted_Total_Qty_InjectionMolding__c;
            Opp.Total_Qty_InjectionMoldingTool__c = q.Quoted_Total_Qty_InjectionMoldingTool__c;
            Opp.Total_Qty_PolyJet3D__c = q.Quoted_Total_Qty_PolyJet3D__c;
            Opp.Total_Qty_PlasticExtrusion__c = q.Quoted_Total_Qty_PlasticExtrusion__c;
            Opp.Total_Qty_SheetMetal__c = q.Quoted_Total_Qty_SheetMetal__c;
            Opp.Total_Qty_SLA__c = q.Quoted_Total_Qty_SLA__c;
            Opp.Total_Qty_SLS__c = q.Quoted_Total_Qty_SLS__c;
            Opp.Total_Qty_Stamping__c = q.Quoted_Total_Qty_Stamping__c;
            Opp.Total_Qty_UrethaneCasting__c = q.Quoted_Total_Qty_UrethaneCasting__c;
            Opp.Total_Qty_BinderJetting__c = q.Quoted_Total_Qty_BinderJetting__c;
            Opp.Total_Qty_SheetCutting__c = q.Quoted_Total_Qty_SheetCutting__c;
            opp.Total_Qty_Tube_Bending__c = q.Quoted_Total_Qty_Tube_Bending__c;
            opp.Total_Qty_Tube_Cutting__c = q.Quoted_Total_Qty_Tube_Cutting__c;
            opp.Total_Qty_Other__c = q.Quoted_Total_Qty_Other__c;
            opp.Total_Qty_Other_NotIncluded__c = q.Quoted_Total_Qty_Other_NotIncluded__c;
            opp.Total_Qty_LSPc__c = q.Quoted_Total_Qty_LSPc__c;
            opp.Total_Qty_Assembly__c = q.Quoted_Total_Qty_Assembly__c;
            Opp.Quote_Type__c = q.Quote_Type__c;
            Opp.OriginatedInFusion360__c = q.OriginatedInFusion360__c;
            Opp.FirstQuoterEmail__c = q.FirstQuoterEmail__c;
            Opp.ManualQuoterEmail__c = q.ManualQuoterEmail__c;
            Opp.FirstQuoterUser__c = q.FirstQuoterUser__c;
            Opp.ManualQuoterUser__c = q.ManualQuoterUser__c;
            Opp.ManualQuoteTime__c = q.ManualQuoteTime__c;
            Opp.ConversionProbability__c = q.ConversionProbability__c;
            Opp.ITAR__c = q.ITAR__c;
            Opp.Hardware_Cert__c = q.Hardware_Cert__c;
            Opp.Conformance_Cert__c = q.Conformance_Cert__c;
            Opp.Material_Traceability_Cert__c = q.Material_Traceability_Cert__c;
            Opp.Material_Cert__c = q.Material_Cert__c;
            Opp.LineItemCount__c = q.LineItemCount__c;
            Opp.DFM_Description__c = q.DFM_Description__c;
            Opp.Manual_Quote_Prioritization_Score__c = q.Manual_Quote_Prioritization_Score__c;
            Opp.Win_Rate_Expected_Value__c = q.Win_Rate_Expected_Value__c;
            Opp.Quote_Win_Rate__c = q.Quote_Win_Rate__c;
            Opp.QuickTurn__c = q.QuickTurn__c;
            Opp.getSite_Deleted__c = q.getSite_Deleted__c;
            Opp.Allow_EU_Quoting__c = q.Allow_EU_Quoting__c;
            Opp.Quote_Source__c = q.Quote_Source__c;

            newOppList.add(Opp);
        }
        return newOppList;
    }

    /**
     * @description creates cases for quote's with Requested_Manual_Quote_Flag__c set to true
     * @param newQuoteERPList - updated quotes
     * @param oldQuoteERPMap - quotes before updates
     */
    public static void createCases(List<Quote_ERP__c> newQuoteERPList, Map<Id, Quote_ERP__c> oldQuoteERPMap) {
        Set<Id> pseCasePossibleRecordTypeList = new Set<Id>{
            pseCasetRecordTypeID,
            dfmCaseRecordTypeID,
            caseMgmtCaseRecordTypeID
        };

        Map<String, Quote_ERP__c> quoteXomIdMap = new Map<String, Quote_ERP__c>();

        Map<String, Quote_ERP__c> checkQuotes = new Map<String, Quote_ERP__c>();
        for (Quote_ERP__c thisQuoteERP : newQuoteERPList) {
            quoteXomIdMap.put(thisQuoteERP.Xometry_ERP_ID__C, thisQuoteERP);

            Boolean cond = thisQuoteERP.Requested_Manual_Quote_Flag__c == true;
            cond &= thisQuoteERP.Requested_Manual_Quote_Time__C >= AppConstants.pseLaunchTime;

            Boolean cond2 = Trigger.isInsert;
            cond2 |=
                Trigger.isUpdate &&
                thisQuoteERP.Requested_Manual_Quote_Flag__c !=
                oldQuoteERPMap.get(thisQuoteERP.Id).Requested_Manual_Quote_Flag__c;
            cond2 |=
                Trigger.isUpdate &&
                thisQuoteERP.DFM_Description__c != oldQuoteERPMap.get(thisQuoteERP.Id).DFM_Description__c;
            cond2 |=
                Trigger.isUpdate &&
                thisQuoteERP.LineItemCount__c != oldQuoteERPMap.get(thisQuoteERP.Id).LineItemCount__c;
            cond2 |= Trigger.isUpdate && thisQuoteERP.QuickTurn__c != oldQuoteERPMap.get(thisQuoteERP.Id).QuickTurn__c;
            cond2 |=
                Trigger.isUpdate &&
                thisQuoteERP.Allow_EU_Quoting__c != oldQuoteERPMap.get(thisQuoteERP.Id).Allow_EU_Quoting__c;
            if (cond && cond2) {
                checkQuotes.put(thisQuoteERP.Xometry_ERP_ID__C, thisQuoteERP);
            }
        }

        List<Case> casesToUpsertList = new List<Case>();
        Set<STRING> existingCaseQuoteSET = new Set<STRING>();

        for (case thisCase : [
            SELECT
                ID,
                Shadow_Xometry_ERP_ID__c,
                AccountId,
                Project__c,
                ContactId,
                Opportunity__c,
                Origin,
                Subject,
                Comments,
                Quote_Linked_by_Integration__c,
                DFM_Description__c,
                LineItemCount__c,
                Reorder__c,
                Requote__c,
                PSE_Quote_Link__c,
                QuickTurn__c,
                Allow_EU_Quoting__c
            FROM CASE
            WHERE Shadow_Xometry_ERP_ID__c IN :quoteXomIdMap.keySet() AND RecordTypeId IN :pseCasePossibleRecordTypeList
        ]) {
            /*  Make a PSE CASE if it does not exist PSE Cases for quotes are separate from the other cases
                For right now we will use custom field PSE_Quote_Link__c in the future we will change this
                if PSE also starts marking their Cases or with improved origin tracking
            */
            if (thisCase.PSE_Quote_Link__c == true) {
                existingCaseQuoteSET.add(thisCase.Shadow_Xometry_ERP_ID__c);
            }

            Quote_ERP__C myQuote = quoteXomIdMap.get(thisCase.Shadow_Xometry_ERP_ID__c);

            if (thisCase.Quote_Linked_by_Integration__c == false) {
                // Update data on existing cases and do not make a new Case if the quote already exists
                if (String.isBlank(thisCase.AccountId) && !String.isBlank(myQuote.AccountID__C)) {
                    thisCase.AccountId = myQuote.AccountID__C;
                }
                if (String.isBlank(thisCase.ContactId) && !String.isBlank(myQuote.ContactID__c)) {
                    thisCase.ContactId = myQuote.ContactID__c;
                }
                if (String.isBlank(thisCase.Opportunity__c)) {
                    if (!String.isBlank(myQuote.OpportunityID__C)) {
                        thisCase.Opportunity__c = myQuote.OpportunityID__C;
                    }
                    if (!String.isBlank(myQuote.Project__c)) {
                        thisCase.Project__c = myQuote.Project__c;
                    }
                }
                if (String.isBlank(thisCase.Origin)) {
                    thisCase.Origin = 'ERP Quote';
                }
                if (String.isBlank(thisCase.Subject)) {
                    thisCase.Subject = 'RFQ submitted: ' + myQuote.Xometry_ERP_ID__C;
                }
                if (String.isBlank(thisCase.DFM_Description__c)) {
                    thisCase.DFM_Description__c = myQuote.DFM_Description__c;
                }
                if (thisCase.LineItemCount__c == null) {
                    thisCase.LineItemCount__c = myQuote.LineItemCount__c;
                }
                if (thisCase.Reorder__c == false) {
                    thisCase.Reorder__c = myQuote.Reorder__c;
                }
                if (thisCase.Requote__c == false) {
                    thisCase.Requote__c = myQuote.Requote__c;
                }
                if (thisCase.QuickTurn__c == false) {
                    thisCase.QuickTurn__c = myQuote.QuickTurn__c;
                }
                if (String.isBlank(thisCase.Comments)) {
                    thisCase.Comments = 'RFQ submitted on get site. Case updated through quote automation flow.';
                } else {
                    thisCase.Comments += '\nRFQ submitted on get site. Case updated through quote automation flow.';
                }
                thisCase.Quote_Linked_by_Integration__c = true;
                thisCase.Allow_EU_Quoting__c = myQuote.Allow_EU_Quoting__c;
                casesToUpsertList.add(thisCase);
            } else {
                //For Cases that have an update to DFM description or quick turn but already had a Quote Linked
                if (Trigger.isUpdate) {
                    Boolean dfmDescriptionUpdate =
                        myQuote.DFM_Description__c != oldQuoteERPMap.get(myQuote.Id).DFM_Description__c;
                    Boolean quickTurnUpdate = myQuote.QuickTurn__c && !oldQuoteERPMap.get(myQuote.Id).QuickTurn__c;
                    Boolean allowEUQuotingChange =
                        myQuote.Allow_EU_Quoting__c != oldQuoteERPMap.get(myQuote.Id).Allow_EU_Quoting__c;
                    if (dfmDescriptionUpdate || quickTurnUpdate || allowEUQuotingChange) {
                        if (dfmDescriptionUpdate) {
                            thisCase.DFM_Description__c = myQuote.DFM_Description__c;
                        }
                        if (quickTurnUpdate) {
                            thisCase.QuickTurn__c = myQuote.QuickTurn__c;
                        }
                        if (allowEUQuotingChange) {
                            thisCase.Allow_EU_Quoting__c = myQuote.Allow_EU_Quoting__c;
                        }
                        casesToUpsertList.add(thisCase);
                    }
                }
            }
        }

        if (!checkQuotes.isEmpty()) {
            /*
            if a junction exists update with the Opportunity ID, 
            also check if junction case is PSE, if so then skip over the case creation steps
            otherwise if junction doesn't exist or junction case is not PSE allow case creation 
            */
            Map<String, CaseOpportunity__c> existingJunctionsMap = new Map<String, CaseOpportunity__c>();
            for (CaseOpportunity__c caseOpp : [
                SELECT Xometry_ERP_ID__c, Case__r.PSE_Quote_Link__c, Opportunity__c
                FROM CaseOpportunity__c
                WHERE Xometry_ERP_ID__c IN :checkQuotes.keySet()
            ]) {
                existingJunctionsMap.put(caseOpp.Xometry_ERP_ID__c, caseOpp);
            }

            Boolean assignmentRulePresent = false;
            Group pseQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Pre-Sales Engineering Queue'];

            List<AssignmentRule> AR = [
                SELECT id
                FROM AssignmentRule
                WHERE SobjectType = 'Case' AND Active = TRUE
                LIMIT 1
            ];

            //Creating the DMLOptions for "Assign using active assignment rules" checkbox
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            if (AR.size() > 0) {
                dmlOpts.assignmentRuleHeader.assignmentRuleId = AR[0].id;
                assignmentRulePresent = true;
            }

            for (Quote_ERP__c thisQuoteERP : checkQuotes.values()) {
                if (
                    !existingCaseQuoteSET.contains(thisQuoteERP.Xometry_ERP_ID__C) &&
                    (!existingJunctionsMap.containsKey(thisQuoteERP.Xometry_ERP_ID__C) ||
                    existingJunctionsMap.get(thisQuoteERP.Xometry_ERP_ID__C).Case__c == null ||
                    existingJunctionsMap.get(thisQuoteERP.Xometry_ERP_ID__C).Case__r.PSE_Quote_Link__c == false)
                ) {
                    Case newCase = createCase(thisQuoteERP, dmlOpts, pseQueue, assignmentRulePresent);
                    casesToUpsertList.add(newCase);
                }
            }
        }

        DatabaseUtilities.upsertToDatabase(casesToUpsertList, 'QuoteERPHandler.createCases', 'Cases from QuoteERP');
        if (!casesToUpsertList.isEmpty()) {
            Set<String> xomQuoteIDSet = new Set<String>();
            for (Case c : casesToUpsertList) {
                if (!String.isblank(c.Shadow_Xometry_ERP_ID__C)) {
                    xomQuoteIDSet.add(c.Shadow_Xometry_ERP_ID__C);
                }
            }

            //Update NYOP cases with their PSE parent Case

            List<Case> NYOPCaseList = [
                SELECT ID, Shadow_Xometry_ERP_ID__C, ParentID, Opportunity__c
                FROM Case
                WHERE recordTypeID = :AppConstants.nyopRTypeID AND Shadow_Xometry_ERP_ID__C IN :xomQuoteIDSet
            ];
            if (!NYOPCaseList.isEmpty()) {
                for (Case nyopCase : NYOPCaseList) {
                    if (String.isblank(nyopCase.ParentID)) {
                        nyopCasesToUpdate.add(nyopCase);
                    }
                }
            }
        }
    }

    /**
     * @description case creation utility
     * @param quoteERP - quote ERP to create case from
     * @param pseQueue - pse queue
     */
    private static Case createCase(
        Quote_ERP__c quoteERP,
        Database.DMLOptions dmlOpts,
        Group pseQueue,
        Boolean assignmentRulePresent
    ) {
        Case newCase = new Case(
            AccountId = quoteERP.AccountID__c,
            ContactId = quoteERP.ContactID__c,
            Project__c = quoteERP.Project__c,
            Opportunity__c = quoteERP.OpportunityID__c,
            Shadow_Xometry_ERP_ID__c = quoteERP.Xometry_ERP_ID__C,
            Origin = 'ERP Quote',
            Subject = 'RFQ submitted: ' + quoteERP.Xometry_ERP_ID__C,
            Comments = 'RFQ submitted on get site. Case created through quote automation flow.',
            Quote_Linked_by_Integration__c = true,
            DFM_Description__c = quoteERP.DFM_Description__c,
            LineItemCount__c = quoteERP.LineItemCount__c,
            Reorder__c = quoteERP.Reorder__c,
            Requote__c = quoteERP.Requote__c,
            PSE_Quote_Link__c = true,
            SuppliedEmail = quoteERP.Quote_Email__c,
            RecordtypeID = pseCasetRecordTypeID,
            QuickTurn__c = quoteERP.QuickTurn__c,
            Allow_EU_Quoting__c = quoteERP.Allow_EU_Quoting__c
        );

        if (assignmentRulePresent) {
            newCase.setOptions(dmlOpts);
        } else {
            newCase.OwnerId = pseQueue.Id;
        }

        return newCase;
    }

    /**
     * @description method to queue async job to update contact with manufacturing processes
     * @param newQuoteERPList list of newly inserted or updated Quotes
     */
    public static void processQuoteContactManuProc(List<Quote_ERP__C> newQuoteERPList) {
        Map<ID, List<Quote_ERP__C>> contactQuoteMap = new Map<ID, List<Quote_ERP__C>>();

        for (Quote_ERP__C q : newQuoteERPList) {
            if (!string.isblank(q.ContactID__C)) {
                if (!contactQuoteMap.containsKey(q.ContactID__C)) {
                    contactQuoteMap.put(q.ContactID__C, new List<Quote_ERP__C>());
                }
                contactQuoteMap.get(q.ContactID__C).add(q);
            }
        }

        if (!contactQuoteMap.isEmpty()) {
            for (Contact contactWithDiff : checkQuoteContactDifferences(contactQuoteMap)) {
                for (Quote_ERP__C quoteToUpdateFlag : contactQuoteMap.get(contactWithDiff.Id)) {
                    quoteToUpdateFlag.Process_Update__c = true;
                }
            }
        }
    }

    /**
     * @description Query Contacts related to Quotes and check differences on Quoted fields
     * @param contactQuoteMap Map Quotes to Contacts
     */
    public static List<Contact> checkQuoteContactDifferences(Map<ID, List<Quote_ERP__C>> contactQuoteMap) {
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        // Contact Updates
        for (Contact cont : [
            SELECT
                has_quoted_Carbon__c,
                has_quoted_CNC_Machining__c,
                has_quoted_Die_Casting__c,
                has_quoted_Direct_Sourced__c,
                has_quoted_DMLS__c,
                has_quoted_Extrusion__c,
                has_quoted_FDM__c,
                has_quoted_HPMultiJetFusion__c,
                has_quoted_Injection_Molding__c,
                has_quoted_PolyJet_3D__c,
                has_quoted_Sheet_metal__c,
                has_quoted_SLA__c,
                has_quoted_SLS__c,
                has_quoted_Stamping__c,
                has_quoted_Urethane_Casting__c,
                has_quoted_BinderJetting__c,
                has_quoted_SheetCutting__c,
                has_quoted_Tube_Bending__c,
                has_quoted_Tube_Cutting__c,
                has_quoted_Other__c,
                has_quoted_PlasticExtrusion__c,
                has_quoted_Other_NotIncluded__c,
                has_quoted_LSPc__c,
                has_quoted_Assembly__c
            FROM Contact
            WHERE ID IN :contactQuoteMap.keyset()
        ]) {
            for (Quote_ERP__C quote : contactQuoteMap.get(cont.Id)) {
                Boolean needUpdate = false;
                Contact c = contactMap.containsKey(cont.Id) ? contactMap.get(cont.Id) : cont;

                if (c.has_quoted_Carbon__c == false && quote.process_isCarbon__c == true) {
                    c.has_quoted_Carbon__c = quote.process_isCarbon__c;
                    needUpdate = true;
                }
                if (c.has_quoted_CNC_Machining__c == false && quote.process_isCNC_Machining__c == true) {
                    c.has_quoted_CNC_Machining__c = quote.process_isCNC_Machining__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Die_Casting__c == false && quote.process_isDie_Casting__c == true) {
                    c.has_quoted_Die_Casting__c = quote.process_isDie_Casting__c;
                    needUpdate = true;
                }
                if (c.has_quoted_DMLS__c == false && quote.process_isDMLS__c == true) {
                    c.has_quoted_DMLS__c = quote.process_isDMLS__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Direct_Sourced__c == false && quote.process_isDirect_Sourced__c == true) {
                    c.has_quoted_Direct_Sourced__c = quote.process_isDirect_Sourced__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Extrusion__c == false && quote.process_isExtrusion__c == true) {
                    c.has_quoted_Extrusion__c = quote.process_isExtrusion__c;
                    needUpdate = true;
                }
                if (c.has_quoted_FDM__c == false && quote.process_isFDM__c == true) {
                    c.has_quoted_FDM__c = quote.process_isFDM__c;
                    needUpdate = true;
                }
                if (c.has_quoted_HPMultiJetFusion__c == false && quote.process_isHPMultJetFusion__c == true) {
                    c.has_quoted_HPMultiJetFusion__c = quote.process_isHPMultJetFusion__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Injection_Molding__c == false && quote.process_isInjection_Molding__c == true) {
                    c.has_quoted_Injection_Molding__c = quote.process_isInjection_Molding__c;
                    needUpdate = true;
                }
                if (c.has_quoted_PolyJet_3D__c == false && quote.process_isPolyJet_3D__c == true) {
                    c.has_quoted_PolyJet_3D__c = quote.process_isPolyJet_3D__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Sheet_metal__c == false && quote.process_isSheet_metal__c == true) {
                    c.has_quoted_Sheet_metal__c = quote.process_isSheet_metal__c;
                    needUpdate = true;
                }
                if (c.has_quoted_SLA__c == false && quote.process_isSLA__c == true) {
                    c.has_quoted_SLA__c = quote.process_isSLA__c;
                    needUpdate = true;
                }
                if (c.has_quoted_SLS__c == false && quote.process_isSLS__c == true) {
                    c.has_quoted_SLS__c = quote.process_isSLS__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Stamping__c == false && quote.process_isStamping__c == true) {
                    c.has_quoted_Stamping__c = quote.process_isStamping__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Urethane_Casting__c == false && quote.process_isUrethane_Casting__c == true) {
                    c.has_quoted_Urethane_Casting__c = quote.process_isUrethane_Casting__c;
                    needUpdate = true;
                }
                if (c.has_quoted_BinderJetting__c == false && quote.process_isBinderJetting__c == true) {
                    c.has_quoted_BinderJetting__c = quote.process_isBinderJetting__c;
                    needUpdate = true;
                }
                if (c.has_quoted_SheetCutting__c == false && quote.process_isSheetCutting__c == true) {
                    c.has_quoted_SheetCutting__c = quote.process_isSheetCutting__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Tube_Bending__c == false && quote.process_isTubeBending__c == true) {
                    c.has_quoted_Tube_Bending__c = quote.process_isTubeBending__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Tube_Cutting__c == false && quote.process_isTubeCutting__c == true) {
                    c.has_quoted_Tube_Cutting__c = quote.process_isTubeCutting__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Other__c == false && quote.process_isOther__c == true) {
                    c.has_quoted_Other__c = quote.process_isOther__c;
                    needUpdate = true;
                }
                if (c.has_quoted_PlasticExtrusion__c == false && quote.process_isPlasticExtrusion__c == true) {
                    c.has_quoted_PlasticExtrusion__c = quote.process_isPlasticExtrusion__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Other_NotIncluded__c == false && quote.process_isOther_NotIncluded__c == true) {
                    c.has_quoted_Other_NotIncluded__c = quote.process_isOther_NotIncluded__c;
                    needUpdate = true;
                }
                if (c.has_quoted_LSPc__c == false && quote.process_isLSPc__c == true) {
                    c.has_quoted_LSPc__c = quote.process_isLSPc__c;
                    needUpdate = true;
                }
                if (c.has_quoted_Assembly__c == false && quote.process_isAssembly__c == true) {
                    c.has_quoted_Assembly__c = quote.process_isAssembly__c;
                    needUpdate = true;
                }
                if (needUpdate) {
                    contactMap.put(c.id, c);
                }
            }
        }

        return contactMap.values();
    }

    /**
     * @description method to associate a quote to a new account
     * @param quotesNeedingAccounts list of quotes which need new accounts
     * @param accountNameSet set of all existing account names
     * @param existingLeadMap  set of all existing leads
     */
    public static List<Account> QuoteToNewAccount(
        List<Quote_ERP__c> quotesNeedingAccounts,
        Set<String> accountNameSet,
        Map<String, Lead> existingLeadMap
    ) {
        List<Account> accountsToCreateList = new List<Account>();
        Map<String, Account> accountsToCreateMap = new Map<String, Account>();
        Set<String> accountEmailsOrDomains = new Set<String>();

        for (Quote_ERP__C q : quotesNeedingAccounts) {
            if (
                ((q.is_generic__c == true && !accountEmailsOrDomains.contains(q.Quote_Email__C)) ||
                (q.is_generic__c == false && !accountEmailsOrDomains.contains(q.account_domain__c))) &&
                !accountsToCreateMap.containsKey(q.Account_Domain__c)
            ) {
                Account a = new Account();
                a.RecordtypeID = accountCustomerRecordTypeID;
                a.Account_Owner_Type__c = 'BDR';
                a.generic_account__c = q.is_generic__c;
                a.Email_Domain__c = q.Account_Domain__c;
                a.ERP_Billing_Address__c = q.ERP_Billing_Address__c;
                a.ERP_Billing_City__c = q.ERP_Billing_City__c;
                a.ERP_Billing_Country__c = q.ERP_Billing_Country__c;
                a.ERP_Billing_State_or_Province__c = q.ERP_Billing_State_or_Province__c;
                a.ERP_Billing_Zip_Code__c = q.ERP_Billing_Zip_Code__c;
                a.ERP_Shipping_Address__c = q.ERP_Shipping_Address__c;
                a.ERP_Shipping_City__c = q.ERP_Shipping_City__c;
                a.ERP_Shipping_Country__c = q.ERP_Shipping_Country__c;
                a.ERP_Shipping_State_or_Province__c = q.ERP_Shipping_State_or_Province__c;
                a.ERP_Shipping_Zip_Code__c = q.ERP_Shipping_Zip_Code__c;

                if (
                    !string.isBlank(q.ERP_User_Company_Name__C) &&
                    !accountNameSet.contains(q.ERP_User_Company_Name__C.toUpperCase())
                ) {
                    a.name = q.ERP_User_Company_Name__C;
                } else {
                    if (q.is_generic__c) {
                        a.name = q.Quote_Email__C;
                    } else {
                        a.name = q.Account_Domain__c;
                    }
                }

                //IDEA-499 Check that the leadsource is not Drift and Lead is not owned by API ADMIN  0056A000002S1sMQAS to keep Lead Owner
                if (
                    existingLeadmap.containsKey(q.Quote_Email__C) &&
                    existingLeadMap.get(q.Quote_Email__C).leadsource != 'Drift' &&
                    existingLeadMap.get(q.Quote_Email__C).OwnerID != AppConstants.API_USER
                ) {
                    a.OwnerID = existingLeadMap.get(q.Quote_Email__c).OwnerID;
                    a.RR_FLAG__C = false;
                } else {
                    a.RR_FLAG__C = true;
                }
                accountsToCreateMap.put(a.Email_Domain__c, a);
            }
        }
        accountsToCreateList.addAll(accountsToCreateMap.values());

        return accountsToCreateList;
    }

    /**
     * @description creates a contact for a given quote
     * @param q quote_erp__c object for creating a new contact
     * @return c newly created Contact object
     */
    public static Contact createContact(Quote_ERP__C q) {
        Contact c = new Contact();
        if (!String.isblank(q.ERP_Contact_Last_Name__C)) {
            c.LastName = q.ERP_Contact_Last_Name__C;
        } else {
            c.LastName = q.Quote_Email__C;
        }
        if (!String.isblank(q.ERP_Contact_Phone__c)) {
            c.Phone = q.ERP_Contact_Phone__c;
            c.ERP_Contact_Phone__C = q.ERP_Contact_Phone__C;
        }
        c.FirstName = q.ERP_Contact_First_Name__C;
        c.Xometry_ERP_Contact_ID__C = q.ERP_Contact__C;
        c.Email = q.Quote_Email__C;
        c.Primary_Email__C = q.Quote_Email__C;
        c.OwnerID = q.OwnerID;
        c.AccountID = q.AccountID__C;
        c.ERP_Shipping_Address__c = q.ERP_Shipping_Address__c;
        c.ERP_Shipping_City__c = q.ERP_Shipping_City__c;
        c.ERP_Shipping_Country__c = q.ERP_Shipping_Country__c;
        c.ERP_Shipping_State_or_Province__c = q.ERP_Shipping_State_or_Province__c;
        c.ERP_Shipping_Zip_Code__c = q.ERP_Shipping_Zip_Code__c;
        if (!String.isBlank(q.MKP_PartnerId__c)) {
            c.GNO_PartnerId__c = q.MKP_PartnerId__c;
        }
        c.LeadSource = 'Quoter';
        return c;
    }

    /**
     * @description updates or inserts a new Opportunity associated with the Quote
     * @param oppQuoteLogicStartList list of quotes for initial processing
     * @param newQuotesERPList list of all quotes passed via the trigger
     */
    public static List<Audit_Trail_Error__c> upsertOpportunities(
        List<Quote_ERP__C> oppQuoteLogicStartList,
        List<Quote_ERP__C> newQuotesERPList
    ) {
        Set<ID> quoteAccountIDSet = new Set<ID>();
        Set<ID> quoteContactIDSet = new Set<ID>();
        Set<String> quoteIdSet = new Set<String>();
        Set<String> quoteEmailSet = new Set<String>();
        Set<String> quoteOppXomQuoteSet = new Set<String>();
        Set<String> quoteLeadXomQuoteSet = new Set<String>();
        List<Audit_Trail_Error__c> myAuditErrorList = new List<Audit_Trail_Error__c>();
        List<Quote_ERP__c> oppsToCreate = new List<Quote_ERP__C>();

        List<Quote_ERP__C> checkQuotes = new List<Quote_ERP__C>();

        for (Quote_ERP__c q : oppQuoteLogicStartList) {
            quoteAccountIDSet.add(q.AccountID__C);
            quoteContactIDSet.add(q.ContactID__C);
            quoteEmailSet.add(q.Quote_Email__C);
            quoteIdSet.add(q.Xometry_ERP_ID__C);

            // Check that the quote is not an order to prevent duplicates. Comes into play for delays.
            // Also check to see if the date is newer than the release of POP. This stops reloads from creating
            // out of date Opps
            if (
                q.Order_Time_Flag__c == false &&
                q.ERP_Status__c != 'Ordered' &&
                q.Quote_ERP_Created_Date__c > Date.newInstance(2021, 2, 1)
            ) {
                checkQuotes.add(q);
            }
        }

        Map<ID, Contact> allContactsMap = new Map<ID, Contact>();
        if (!checkQuotes.isEmpty()) {
            Map<ID, Account> allAccountsMap = new Map<ID, Account>(
                [
                    SELECT ID, Name, Account_Owner_Type__c, OwnerID, Email_Domain__c
                    FROM Account
                    WHERE ID IN :quoteAccountIDSet
                ]
            );

            allContactsMap = new Map<ID, Contact>(
                [
                    SELECT ID, LastName, Primary_Email__C, OwnerId, Suppress_Opps_and_Leads_Flag__c, Has_Ordered__c
                    FROM Contact
                    WHERE ID IN :quoteContactIDSet
                ]
            );

            for (Quote_ERP__C q : checkQuotes) {
                //Original Quote
                if (allAccountsMap.containsKey(q.AccountID__C)) {
                    if (
                        (allContactsMap.containsKey(q.ContactID__C) &&
                        allContactsMap.get(q.ContactID__C).Suppress_OPPS_AND_LEADS_FLAG__C == false) ||
                        q.Requested_Manual_Quote_Flag__c
                    ) {
                        oppsToCreate.add(q);
                    }
                }
            }

            if (!oppsToCreate.isEmpty()) {

                Map<ID, Opportunity> allOppswithNoQuotesMap = new Map<ID, Opportunity>();
                for (Opportunity o : [
                    SELECT Name, ID, Primary_Contact__c, AccountId, Quote_ERP_XOM_CREATE_ID__c
                    FROM Opportunity
                    WHERE
                        Closed_By_System_Order__c = FALSE
                        AND StageName NOT IN ('Closed Lost', 'Closed Won')
                        AND AccountID IN :quoteAccountIDSet
                        AND Primary_Contact__c IN :quoteContactIDSet
                        AND RecordTypeId = :oppManufacturingServRTypeID
                    ORDER BY Createddate DESC
                ]) {
                    if (
                        !allOppswithNoQuotesMap.containsKey(o.Primary_Contact__c) &&
                        o.Quote_ERP_XOM_CREATE_ID__c == null
                    ) {
                        allOppswithNoQuotesMap.put(o.Primary_Contact__c, o);
                    }
                }

                Map<String, Opportunity> allOppsWithExistingQuoteMap = new Map<String, Opportunity>();
                for (Opportunity o : [
                    SELECT Name, ID, Quote_ERP_XOM_CREATE_ID__c
                    FROM Opportunity
                    WHERE Quote_ERP_XOM_CREATE_ID__c IN :quoteIdSet AND RecordTypeId = :oppManufacturingServRTypeID
                    ORDER BY Createddate DESC
                ]) {
                    if (!allOppsWithExistingQuoteMap.containsKey(o.Quote_ERP_XOM_CREATE_ID__c)) {
                        allOppsWithExistingQuoteMap.put(o.Quote_ERP_XOM_CREATE_ID__c, o);
                    }
                }

                List<Quote_ERP__C> quoteOppHasNoQuoteList = new List<Quote_ERP__C>();
                List<Quote_ERP__C> quoteOppHasExistedList = new List<Quote_ERP__c>();
                List<Quote_ERP__C> quoteOppList = new List<Quote_ERP__C>();
                Set<ID> quoteOppHasNoQuoteContSet = new Set<ID>();

                // If a quote's contact/account has an opp and no quote, then associate the quote
                // Also, if an opp exists for the quote, but it is getting reinserted, be sure to assoiciate it back
                for (Quote_ERP__C q : oppsToCreate) {
                    if (allOppsWithExistingQuoteMap.containsKey(q.Xometry_ERP_Id__c)) {
                        quoteOppHasExistedList.add(q);
                    } else if (
                        !String.isblank(q.ContactID__c) &&
                        allOppswithNoQuotesMap.containsKey(q.ContactID__C) &&
                        !quoteOppHasNoQuoteContSet.contains(q.ContactID__C)
                    ) {
                        quoteOppHasNoQuoteList.add(q);
                        quoteOppHasNoQuoteContSet.add(q.ContactID__C);
                    } else {
                        quoteOppList.add(q);
                    }
                }

                //quoteOppHasNoQuoteList
                Set<Opportunity> OppHasNoQuoteSet = new Set<Opportunity>();
                Map<ID, Opportunity> OppHasNoQuoteMap = new Map<ID, Opportunity>();
                List<Opportunity> oppHasNoQuoteList = new List<Opportunity>();
                for (Quote_ERP__C q : quoteOppHasNoQuoteList) {
                    Opportunity Opp = allOppswithNoQuotesMap.get(q.ContactID__c);
                    q.OpportunityID__C = Opp.ID;
                    if (q.Quote_Price__C == null && q.Line_of_Business__c != MARKETPLACE_LINE_OF_BUSINESS) {
                        Opp.Amount = .01;
                    } else {
                        Opp.Amount = q.Quote_Price__c;
                    }
                    Opp.order_Discount__c = q.Quote_Discount__c;
                    Opp.order_Redeemed_Points_Value__c = q.Quote_Redeemed_Points_Value__c;
                    Opp.SubTotal__c = q.Quote_Sub_Total__c;
                    Opp.order_Shipping__c = q.Quote_Shipping__c;
                    Date quoteCreatedDate = q.Quote_ERP_Created_Time__c.date();
                    Opp.CloseDate = quoteCreatedDate + 30;
                    Opp.Quote_ERP_XOM_CREATE_ID__c = q.Xometry_ERP_ID__C;
                    Opp.Last_Quote_Xometry_ERP_ID__c = q.Xometry_ERP_ID__C;
                    Opp.Original_Quoter_Email__C = q.Quote_Email__C;
                    Opp.name = q.Xometry_ERP_ID__C;
                    Opp.Last_Quote_Xometry_Create_Time__c = q.Quote_ERP_Last_Updated_Time__c;
                    if (!String.isBlank(q.ContactID__C)) {
                        Opp.Primary_Contact__c = q.ContactID__C;
                    }
                    Opp.ERP_Status__c = q.ERP_Status__c;
                    //Use Contact Owner for Owner Assignment
                    if (allContactsMap.containsKey(q.ContactID__C)) {
                        Opp.OwnerId = allContactsMap.get(q.ContactID__C).OwnerId;
                    }
                    Opp.most_recent_quote_Carbon__c = q.process_isCarbon__c;
                    Opp.most_recent_quote_CNC_Machining__c = q.process_isCNC_Machining__c;
                    Opp.most_recent_quote_Die_Casting__c = q.process_isDie_Casting__c;
                    Opp.most_recent_quote_Direct_Sourced__c = q.process_isDirect_Sourced__c;
                    Opp.most_recent_quote_DMLS__c = q.process_isDMLS__c;
                    Opp.most_recent_quote_Extrusion__c = q.process_isExtrusion__c;
                    Opp.most_recent_quote_FDM__c = q.process_isFDM__c;
                    Opp.most_recent_quote_HPMultiJetFusion__c = q.process_isHPMultJetFusion__c;
                    Opp.most_recent_quote_Injection_Molding__c = q.process_isInjection_Molding__c;
                    Opp.Most_Recent_Quote_Injection_Molding_Tool__c = q.process_isInjectionMoldingTool__c;
                    Opp.most_recent_quote_PolyJet_3D__c = q.process_isPolyJet_3D__c;
                    Opp.most_recent_quote_PlasticExtrusion__c = q.process_isPlasticExtrusion__c;
                    Opp.most_recent_quote_Sheet_metal__c = q.process_isSheet_metal__c;
                    Opp.most_recent_quote_SLA__c = q.process_isSLA__c;
                    Opp.most_recent_quote_SLS__c = q.process_isSLS__c;
                    Opp.most_recent_quote_Stamping__c = q.process_isStamping__c;
                    Opp.most_recent_quote_Urethane_Casting__c = q.process_isUrethane_Casting__c;
                    Opp.most_recent_quote_BinderJetting__c = q.process_isBinderJetting__c;
                    Opp.most_recent_quote_SheetCutting__c = q.process_isSheetCutting__c;
                    Opp.most_recent_quote_TubeBending__c = q.process_isTubeBending__c;
                    Opp.most_recent_quote_TubeCutting__c = q.process_isTubeCutting__c;
                    Opp.most_recent_quote_Other__c = q.process_isOther__c;
                    Opp.most_recent_quote_Other_NotIncluded__c = q.process_isOther_NotIncluded__c;
                    Opp.most_recent_quote_LSPc__c = q.process_isLSPc__c;
                    Opp.most_recent_quote_Assembly__c = q.process_isAssembly__c;
                    Opp.Total_Amt_Carbon__c = q.Quoted_Total_Amt_Carbon__c;
                    Opp.Total_Amt_CNC__c = q.Quoted_Total_Amt_CNC__c;
                    Opp.Total_Amt_DieCasting__c = q.Quoted_Total_Amt_DieCasting__c;
                    Opp.Total_Amt_DirectSourced__c = q.Quoted_Total_Amt_DirectSourced__c;
                    Opp.Total_Amt_DMLS__c = q.Quoted_Total_Amt_DMLS__c;
                    Opp.Total_Amt_Extrusion__c = q.Quoted_Total_Amt_Extrusion__c;
                    Opp.Total_Amt_FDM__c = q.Quoted_Total_Amt_FDM__c;
                    Opp.Total_Amt_HPMultJetFusion__c = q.Quoted_Total_Amt_HPMultJetFusion__c;
                    Opp.Total_Amt_InjectionMolding__c = q.Quoted_Total_Amt_InjectionMolding__c;
                    Opp.Total_Amt_InjectionMoldingTool__c = q.Quoted_Total_Amt_InjectionMoldingTool__c;
                    Opp.Total_Amt_PolyJet3D__c = q.Quoted_Total_Amt_PolyJet3D__c;
                    Opp.Total_Amt_PlasticExtrusion__c = q.Quoted_Total_Amt_PlasticExtrusion__c;
                    Opp.Total_Amt_SheetMetal__c = q.Quoted_Total_Amt_SheetMetal__c;
                    Opp.Total_Amt_SLA__c = q.Quoted_Total_Amt_SLA__c;
                    Opp.Total_Amt_SLS__c = q.Quoted_Total_Amt_SLS__c;
                    Opp.Total_Amt_Stamping__c = q.Quoted_Total_Amt_Stamping__c;
                    Opp.Total_Amt_UrethaneCasting__c = q.Quoted_Total_Amt_UrethaneCasting__c;
                    Opp.Total_Amt_BinderJetting__c = q.Quoted_Total_Amt_BinderJetting__c;
                    Opp.Total_Amt_SheetCutting__c = q.Quoted_Total_Amt_SheetCutting__c;
                    Opp.Total_Amt_Tube_Bending__c = q.Quoted_Total_Amt_Tube_Bending__c;
                    Opp.Total_Amt_Tube_Cutting__c = q.Quoted_Total_Amt_Tube_Cutting__c;
                    Opp.Total_Amt_Other__c = q.Quoted_Total_Amt_Other__c;
                    Opp.Total_Amt_Other_NotIncluded__c = q.Quoted_Total_Amt_Other_NotIncluded__c;
                    Opp.Total_Amt_LSPc__c = q.Quoted_Total_Amt_LSPc__c;
                    Opp.Total_Amt_Assembly__c = q.Quoted_Total_Amt_Assembly__c;
                    Opp.Total_Qty_Carbon__c = q.Quoted_Total_Qty_Carbon__c;
                    Opp.Total_Qty_CNC__c = q.Quoted_Total_Qty_CNC__c;
                    Opp.Total_Qty_DieCasting__c = q.Quoted_Total_Qty_DieCasting__c;
                    Opp.Total_Qty_DirectSourced__c = q.Quoted_Total_Qty_DirectSourced__c;
                    Opp.Total_Qty_DMLS__c = q.Quoted_Total_Qty_DMLS__c;
                    Opp.Total_Qty_Extrusion__c = q.Quoted_Total_Qty_Extrusion__c;
                    Opp.Total_Qty_FDM__c = q.Quoted_Total_Qty_FDM__c;
                    Opp.Total_Qty_HPMultJetFusion__c = q.Quoted_Total_Qty_HPMultJetFusion__c;
                    Opp.Total_Qty_InjectionMolding__c = q.Quoted_Total_Qty_InjectionMolding__c;
                    Opp.Total_Qty_InjectionMoldingTool__c = q.Quoted_Total_Qty_InjectionMoldingTool__c;
                    Opp.Total_Qty_PolyJet3D__c = q.Quoted_Total_Qty_PolyJet3D__c;
                    Opp.Total_Qty_PlasticExtrusion__c = q.Quoted_Total_Qty_PlasticExtrusion__c;
                    Opp.Total_Qty_SheetMetal__c = q.Quoted_Total_Qty_SheetMetal__c;
                    Opp.Total_Qty_SLA__c = q.Quoted_Total_Qty_SLA__c;
                    Opp.Total_Qty_SLS__c = q.Quoted_Total_Qty_SLS__c;
                    Opp.Total_Qty_Stamping__c = q.Quoted_Total_Qty_Stamping__c;
                    Opp.Total_Qty_UrethaneCasting__c = q.Quoted_Total_Qty_UrethaneCasting__c;
                    opp.Total_Qty_BinderJetting__c = q.Quoted_Total_Qty_BinderJetting__c;
                    opp.Total_Qty_SheetCutting__c = q.Quoted_Total_Qty_SheetCutting__c;
                    opp.Total_Qty_Tube_Bending__c = q.Quoted_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Tube_Cutting__c = q.Quoted_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Other__c = q.Quoted_Total_Qty_Other__c;
                    opp.Total_Qty_Other_NotIncluded__c = q.Quoted_Total_Qty_Other_NotIncluded__c;
                    opp.Total_Qty_LSPc__c = q.Quoted_Total_Qty_LSPc__c;
                    opp.Total_Qty_Assembly__c = q.Quoted_Total_Qty_Assembly__c;
                    Opp.FDMSize__c = q.FDMSize__c;
                    Opp.FirstQuoterEmail__c = q.FirstQuoterEmail__c;
                    Opp.ManualQuoterEmail__c = q.ManualQuoterEmail__c;
                    Opp.FirstQuoterUser__c = q.FirstQuoterUser__c;
                    Opp.ManualQuoterUser__c = q.ManualQuoterUser__c;
                    Opp.ManualQuoteTime__c = q.ManualQuoteTime__c;
                    Opp.ConversionProbability__c = q.ConversionProbability__c;
                    Opp.ITAR__c = q.ITAR__c;
                    Opp.Hardware_Cert__c = q.Hardware_Cert__c;
                    Opp.Conformance_Cert__c = q.Conformance_Cert__c;
                    Opp.Material_Traceability_Cert__c = q.Material_Traceability_Cert__c;
                    Opp.Material_Cert__c = q.Material_Cert__c;
                    Opp.LineItemCount__c = q.LineItemCount__c;
                    Opp.DFM_Description__c = q.DFM_Description__c;
                    Opp.Line_of_business__c = q.Line_of_business__c;
                    Opp.Manual_Quote_Prioritization_Score__c = q.Manual_Quote_Prioritization_Score__c;
                    Opp.Win_Rate_Expected_Value__c = q.Win_Rate_Expected_Value__c;
                    Opp.Quote_Win_Rate__c = q.Quote_Win_Rate__c;
                    Opp.QuickTurn__c = q.QuickTurn__c;
                    Opp.getSite_Deleted__c = q.getSite_Deleted__c;
                    Opp.Allow_EU_Quoting__c = q.Allow_EU_Quoting__c;
                    Opp.Quote_Source__c = q.Quote_Source__c;

                    //Use the most recent quote
                    if (!OppHasNoQuoteMap.containsKey(Opp.ID)) {
                        OppHasNoQuoteMap.put(Opp.ID, Opp);
                    } else {
                        //Check if quote is already being added
                        if (
                            Opp.Last_Quote_Xometry_Create_Time__c >
                            OppHasNoQuoteMap.get(Opp.ID).Last_Quote_Xometry_Create_Time__c
                        ) {
                            OppHasNoQuoteMap.put(Opp.ID, Opp);
                        }
                    }
                }
                //for use with the junction object
                oppHasNoQuoteList = OppHasNoQuoteMap.values();

                //Update the opportunities
                DatabaseUtilities.saveToDatabase(
                    oppHasNoQuoteList,
                    'QuoteERPHandler',
                    'Opportunity Updates with No Quotes'
                );

                for (Quote_ERP__C q : quoteOppHasExistedList) {
                    Opportunity Opp = allOppsWithExistingQuoteMap.get(q.Xometry_ERP_Id__c);
                    q.OpportunityID__C = Opp.ID;
                }

                List<Opportunity> oppsInsertList = new List<Opportunity>();
                Set<Opportunity> oppsInsertSet = new Set<Opportunity>();

                for (Quote_ERP__C q : quoteOppList) {
                    Opportunity Opp = new Opportunity();
                    Opp.AccountID = q.AccountID__C;
                    Opp.Line_of_Business__c = q.Line_of_Business__c;
                    if (
                        q.Line_of_Business__c == INSTANT_QUOTE_LINE_OF_BUSINESS ||
                        q.Line_of_Business__c == MARKETPLACE_LINE_OF_BUSINESS
                    ) {
                        Opp.RecordtypeID = oppManuSRecordTypeID;
                    } else {
                        //default recordType logic
                        Opp.RecordtypeID = oppDefaultRecordTypeID;
                    }
                    Opp.ERP_Status__c = q.ERP_Status__c;
                    // Round Robin Logic on Opps assigned on Account level
                    Opp.StageName = 'Open';
                    Opp.Name = q.Xometry_ERP_ID__C;
                    if (q.Quote_Price__C == null && q.Line_of_Business__c != MARKETPLACE_LINE_OF_BUSINESS) {
                        Opp.Amount = .01;
                    } else {
                        Opp.Amount = q.Quote_Price__c;
                    }
                    Opp.order_Discount__c = q.Quote_Discount__c;
                    Opp.order_Redeemed_Points_Value__c = q.Quote_Redeemed_Points_Value__c;
                    Opp.SubTotal__c = q.Quote_Sub_Total__c;
                    Opp.order_Shipping__c = q.Quote_Shipping__c;
                    Opp.Quote_Created_Date__c = q.Quote_ERP_Created_Date__c;
                    Date quoteCreatedDate = q.Quote_ERP_Created_Date__c;
                    Opp.CloseDate = quoteCreatedDate + 30;
                    Opp.OwnerID = allContactsMap.get(q.ContactID__C).OwnerID;
                    Opp.Quote_ERP_XOM_CREATE_ID__c = q.Xometry_ERP_ID__c;
                    Opp.Last_Quote_Xometry_ERP_ID__c = q.Xometry_ERP_ID__C;
                    Opp.Original_Quoter_Email__C = q.Quote_Email__C;
                    Opp.Primary_Contact__c = q.ContactID__C;
                    Opp.Last_Quote_Xometry_Create_Time__c = q.Quote_ERP_Last_Updated_Time__c;
                    Opp.most_recent_quote_Carbon__c = q.process_isCarbon__c;
                    Opp.most_recent_quote_CNC_Machining__c = q.process_isCNC_Machining__c;
                    Opp.most_recent_quote_Die_Casting__c = q.process_isDie_Casting__c;
                    Opp.most_recent_quote_Direct_Sourced__c = q.process_isDirect_Sourced__c;
                    Opp.most_recent_quote_DMLS__c = q.process_isDMLS__c;
                    Opp.most_recent_quote_Extrusion__c = q.process_isExtrusion__c;
                    Opp.most_recent_quote_FDM__c = q.process_isFDM__c;
                    Opp.most_recent_quote_HPMultiJetFusion__c = q.process_isHPMultJetFusion__c;
                    Opp.most_recent_quote_Injection_Molding__c = q.process_isInjection_Molding__c;
                    Opp.Most_Recent_Quote_Injection_Molding_Tool__c = q.process_isInjectionMoldingTool__c;
                    Opp.most_recent_quote_PolyJet_3D__c = q.process_isPolyJet_3D__c;
                    Opp.most_recent_quote_PlasticExtrusion__c = q.process_isPlasticExtrusion__c;
                    Opp.most_recent_quote_Sheet_metal__c = q.process_isSheet_metal__c;
                    Opp.most_recent_quote_SLA__c = q.process_isSLA__c;
                    Opp.most_recent_quote_SLS__c = q.process_isSLS__c;
                    Opp.most_recent_quote_Stamping__c = q.process_isStamping__c;
                    Opp.most_recent_quote_Urethane_Casting__c = q.process_isUrethane_Casting__c;
                    Opp.most_recent_quote_BinderJetting__c = q.process_isBinderJetting__c;
                    Opp.most_recent_quote_SheetCutting__c = q.process_isSheetCutting__c;
                    // When the Part is blank then it gets the New Opportunity to not get mixed up
                    Opp.most_recent_quote_TubeBending__c = q.process_isTubeBending__c;
                    Opp.most_recent_quote_TubeCutting__c = q.process_isTubeCutting__c;
                    Opp.most_recent_quote_Other__c = q.process_isOther__c;
                    Opp.most_recent_quote_Other_NotIncluded__c = q.process_isOther_NotIncluded__c;
                    Opp.most_recent_quote_LSPc__c = q.process_isLSPc__c;
                    Opp.most_recent_quote_Assembly__c = q.process_isAssembly__c;
                    Opp.Total_Amt_Carbon__c = q.Quoted_Total_Amt_Carbon__c;
                    Opp.Total_Amt_CNC__c = q.Quoted_Total_Amt_CNC__c;
                    Opp.Total_Amt_DieCasting__c = q.Quoted_Total_Amt_DieCasting__c;
                    Opp.Total_Amt_DirectSourced__c = q.Quoted_Total_Amt_DirectSourced__c;
                    Opp.Total_Amt_DMLS__c = q.Quoted_Total_Amt_DMLS__c;
                    Opp.Total_Amt_Extrusion__c = q.Quoted_Total_Amt_Extrusion__c;
                    Opp.Total_Amt_FDM__c = q.Quoted_Total_Amt_FDM__c;
                    Opp.Total_Amt_HPMultJetFusion__c = q.Quoted_Total_Amt_HPMultJetFusion__c;
                    Opp.Total_Amt_InjectionMolding__c = q.Quoted_Total_Amt_InjectionMolding__c;
                    Opp.Total_Amt_InjectionMoldingTool__c = q.Quoted_Total_Amt_InjectionMoldingTool__c;
                    Opp.Total_Amt_PolyJet3D__c = q.Quoted_Total_Amt_PolyJet3D__c;
                    Opp.Total_Amt_PlasticExtrusion__c = q.Quoted_Total_Amt_PlasticExtrusion__c;
                    Opp.Total_Amt_SheetMetal__c = q.Quoted_Total_Amt_SheetMetal__c;
                    Opp.Total_Amt_SLA__c = q.Quoted_Total_Amt_SLA__c;
                    Opp.Total_Amt_SLS__c = q.Quoted_Total_Amt_SLS__c;
                    Opp.Total_Amt_Stamping__c = q.Quoted_Total_Amt_Stamping__c;
                    Opp.Total_Amt_UrethaneCasting__c = q.Quoted_Total_Amt_UrethaneCasting__c;
                    Opp.Total_Amt_BinderJetting__c = q.Quoted_Total_Amt_BinderJetting__c;
                    Opp.Total_Amt_SheetCutting__c = q.Quoted_Total_Amt_SheetCutting__c;
                    Opp.Total_Amt_Tube_Bending__c = q.Quoted_Total_Amt_Tube_Bending__c;
                    Opp.Total_Amt_Tube_Cutting__c = q.Quoted_Total_Amt_Tube_Cutting__c;
                    Opp.Total_Amt_Other__c = q.Quoted_Total_Amt_Other__c;
                    Opp.Total_Amt_Other_NotIncluded__c = q.Quoted_Total_Amt_Other_NotIncluded__c;
                    Opp.Total_Amt_LSPc__c = q.Quoted_Total_Amt_LSPc__c;
                    Opp.Total_Amt_Assembly__c = q.Quoted_Total_Amt_Assembly__c;
                    Opp.Total_Qty_Carbon__c = q.Quoted_Total_Qty_Carbon__c;
                    Opp.Total_Qty_CNC__c = q.Quoted_Total_Qty_CNC__c;
                    Opp.Total_Qty_DieCasting__c = q.Quoted_Total_Qty_DieCasting__c;
                    Opp.Total_Qty_DirectSourced__c = q.Quoted_Total_Qty_DirectSourced__c;
                    Opp.Total_Qty_DMLS__c = q.Quoted_Total_Qty_DMLS__c;
                    Opp.Total_Qty_Extrusion__c = q.Quoted_Total_Qty_Extrusion__c;
                    Opp.Total_Qty_FDM__c = q.Quoted_Total_Qty_FDM__c;
                    Opp.Total_Qty_HPMultJetFusion__c = q.Quoted_Total_Qty_HPMultJetFusion__c;
                    Opp.Total_Qty_InjectionMolding__c = q.Quoted_Total_Qty_InjectionMolding__c;
                    Opp.Total_Qty_InjectionMoldingTool__c = q.Quoted_Total_Qty_InjectionMoldingTool__c;
                    Opp.Total_Qty_PolyJet3D__c = q.Quoted_Total_Qty_PolyJet3D__c;
                    Opp.Total_Qty_PlasticExtrusion__c = q.Quoted_Total_Qty_PlasticExtrusion__c;
                    Opp.Total_Qty_SheetMetal__c = q.Quoted_Total_Qty_SheetMetal__c;
                    Opp.Total_Qty_SLA__c = q.Quoted_Total_Qty_SLA__c;
                    Opp.Total_Qty_SLS__c = q.Quoted_Total_Qty_SLS__c;
                    Opp.Total_Qty_Stamping__c = q.Quoted_Total_Qty_Stamping__c;
                    Opp.Total_Qty_UrethaneCasting__c = q.Quoted_Total_Qty_UrethaneCasting__c;
                    opp.Total_Qty_BinderJetting__c = q.Quoted_Total_Qty_BinderJetting__c;
                    opp.Total_Qty_SheetCutting__c = q.Quoted_Total_Qty_SheetCutting__c;
                    opp.Total_Qty_Tube_Bending__c = q.Quoted_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Tube_Cutting__c = q.Quoted_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Other__c = q.Quoted_Total_Qty_Other__c;
                    opp.Total_Qty_Other_NotIncluded__c = q.Quoted_Total_Qty_Other_NotIncluded__c;
                    opp.Total_Qty_LSPc__c = q.Quoted_Total_Qty_LSPc__c;
                    opp.Total_Qty_Assembly__c = q.Quoted_Total_Qty_Assembly__c;
                    Opp.FDMSize__c = q.FDMSize__c;
                    Opp.Quote_Type__c = q.Quote_Type__c;
                    Opp.OriginatedInFusion360__c = q.OriginatedInFusion360__c;
                    Opp.FirstQuoterEmail__c = q.FirstQuoterEmail__c;
                    Opp.ManualQuoterEmail__c = q.ManualQuoterEmail__c;
                    Opp.FirstQuoterUser__c = q.FirstQuoterUser__c;
                    Opp.ManualQuoterUser__c = q.ManualQuoterUser__c;
                    Opp.ManualQuoteTime__c = q.ManualQuoteTime__c;
                    Opp.ConversionProbability__c = q.ConversionProbability__c;
                    Opp.ITAR__c = q.ITAR__c;
                    Opp.Hardware_Cert__c = q.Hardware_Cert__c;
                    Opp.Conformance_Cert__c = q.Conformance_Cert__c;
                    Opp.Material_Traceability_Cert__c = q.Material_Traceability_Cert__c;
                    Opp.Material_Cert__c = q.Material_Cert__c;
                    Opp.LineItemCount__c = q.LineItemCount__c;
                    Opp.DFM_Description__c = q.DFM_Description__c;
                    Opp.Manual_Quote_Prioritization_Score__c = q.Manual_Quote_Prioritization_Score__c;
                    Opp.Win_Rate_Expected_Value__c = q.Win_Rate_Expected_Value__c;
                    Opp.Quote_Win_Rate__c = q.Quote_Win_Rate__c;
                    Opp.QuickTurn__c = q.QuickTurn__c;
                    Opp.getSite_Deleted__c = q.getSite_Deleted__c;
                    Opp.Allow_EU_Quoting__c = q.Allow_EU_Quoting__c;
                    Opp.Quote_Source__c = q.Quote_Source__c;

                    oppsInsertSet.add(Opp);
                }

                oppsInsertList.addAll(oppsInsertSet);

                //Insert the opportunities

                DatabaseUtilities.insertToDatabase(oppsInsertList, 'QuoteERPHandler', 'Opportunity Inserts');

                // Assign OpportunityIDs to Quotes
                List<OpportunityContactRole> newOppContactRoleList = new List<OpportunityContactRole>();
                Set<OpportunityContactRole> newOppContactRoleSet = new Set<OpportunityContactRole>();

                if (!oppsInsertList.isEmpty()) {
                    Map<String, Opportunity> newOppsCreatedMap = new Map<String, Opportunity>();
                    for (Opportunity opp : oppsInsertList) {
                        newOppsCreatedMap.put(opp.Quote_ERP_XOM_CREATE_ID__c, opp);
                    }
                    for (Quote_ERP__C q : quoteOppList) {
                        if (newOppsCreatedMap.containsKey(q.Xometry_ERP_ID__C)) {
                            ID lOPPID = newOppsCreatedMap.get(q.Xometry_ERP_ID__C).ID;
                            q.OpportunityID__C = lOPPID;
                            //Update the Junction Object Create the Decision Maker as the role and set primary
                            if (!String.isBlank(q.ContactID__C)) {
                                OpportunityContactRole newOppCRole = new OpportunityContactRole();
                                newOppCRole.ContactID = q.ContactID__C;
                                newOppCRole.IsPrimary = true;
                                newOppCRole.OpportunityID = lOPPID;
                                newOppCRole.Role = 'Decision Maker';
                                newOppContactRoleSet.add(newOppCRole);
                            }
                        }
                    }
                }

                if (!oppHasNoQuoteList.isEmpty()) {
                    Map<String, Opportunity> oppHasNoQuotePostMap = new Map<String, Opportunity>();
                    for (Opportunity opp : oppHasNoQuoteList) {
                        oppHasNoQuotePostMap.put(opp.Quote_ERP_XOM_CREATE_ID__c, opp);
                    }
                    for (Quote_ERP__C q : quoteOppHasNoQuoteList) {
                        //Update the Junction Object Create the Decision Maker as the role and set primary
                        ID lOPPID = oppHasNoQuotePostMap.get(q.Xometry_ERP_ID__C).ID;
                        if (!String.isBlank(q.ContactID__C)) {
                            OpportunityContactRole newOppCRole = new OpportunityContactRole();
                            newOppCRole.ContactID = q.ContactID__C;
                            newOppCRole.IsPrimary = true;
                            newOppCRole.OpportunityID = lOPPID;
                            newOppCRole.Role = 'Decision Maker';
                            newOppContactRoleSet.add(newOppCRole);
                        }
                    }
                }

                //take the list see which quote now have Opps make a part to Opp map to Update quotes with matching parts without an Opp
                Map<String, ID> partToOppPostInsertMap = new Map<String, ID>();
                for (Quote_ERP__C q : quoteOppList) {
                    if (!String.isblank(q.OpportunityID__C)) {
                        partToOppPostInsertMap.put(q.ERP_PartPK__C, q.OpportunityID__C);
                    }
                }
                for (Quote_ERP__C q : quoteOppList) {
                    if (String.isblank(q.OpportunityID__C)) {
                        //check the map
                        if (partToOppPostInsertMap.containsKey(q.ERP_PartPK__C)) {
                            q.OpportunityID__C = partToOppPostInsertMap.get(q.ERP_PartPK__C);
                        }
                    }
                }

                //Insert the junction object
                newOppContactRoleList.addAll(newOppContactRoleSet);
                //Insert the opportunities
                DatabaseUtilities.insertToDatabase(
                    newOppContactRoleList,
                    'QuoteERPHandler',
                    'OpportunityContact Role Inserts'
                );
            }
        }

        //Lead Convertsion Time
        //Potential Quote for Conversion
        List<Quote_ERP__C> potentialQuoteLeadConversionList = new List<Quote_ERP__C>();
        Map<String, Quote_ERP__C> potentialQuoteLeadConversionMap = new Map<String, Quote_ERP__C>();
        Map<Id, User> mapUser = new Map<Id, User>();
        Set<String> leadEmailCheckSet = new Set<String>();
        for (Quote_ERP__C q : newQuotesERPList) {
            if (q.ContactID__C != null) {
                potentialQuoteLeadConversionList.add(q);
                leadEmailCheckSet.add(q.Quote_Email__C);
                potentialQuoteLeadConversionMap.put(q.Quote_Email__C, q);
                mapUser.put(q.OwnerId, null);
            }
        }

        mapUser = new Map<Id, User>([SELECT IsActive FROM User WHERE Id IN: mapUser.KeySet() AND IsActive = false]);
        Map<Id, Id> mapOwner = new Map<Id, Id>();

        if (!leadEmailCheckSet.isEmpty()) {
            List<Database.LeadConvert> leadQuoteConvertList = new List<Database.LeadConvert>();
            Set<Database.LeadConvert> leadQuoteConvertSet = new Set<Database.LeadConvert>();

            Set<ID> leadToConvertIDSET = new Set<ID>();

            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
            Set<ID> leadIdConvertSET = new Set<ID>();

            //Fetch Leads to be converted
            //Create the DB converter for Leads
            for (Lead l : [
                SELECT ID, Primary_Email__C
                FROM Lead
                WHERE Primary_Email__C IN :leadEmailCheckSet AND isConverted = FALSE
            ]) {
                if (potentialQuoteLeadConversionMap.containsKey(l.Primary_Email__C)) {
                    Quote_ERP__C q = potentialQuoteLeadConversionMap.get(l.Primary_Email__C);

                    //database Converter
                    //Convert the Lead to Opportunity Account
                    Database.LeadConvert l_dbLeadConvert = new Database.LeadConvert();
                    l_dbLeadConvert.setConvertedStatus(convertStatus.MasterLabel);
                    l_dbLeadConvert.setLeadID(l.ID);
                    l_dbLeadConvert.setOwnerID(q.OwnerID);
                    l_dbLeadConvert.setAccountID(q.AccountID__C);
                    l_dbLeadConvert.setContactID(q.ContactID__C);

                    if(mapUser.containsKey(q.OwnerID))
                    {
                        mapOwner.put(l.Id, q.OwnerId);
                        l_dbLeadConvert.setOwnerID(AppConstants.SALES_API_USER);
                    }

                    //IF the quote converting the Lead is already ordered then there will be no Opp yet so instead
                    //have the lead convert with no Opp created
                    if (q.Order_Time_Flag__c == true && String.isblank(q.OpportunityID__C)) {
                        l_dbLeadConvert.setDoNotCreateOpportunity(true);
                    } else {
                        l_dbLeadConvert.setOpportunityId(q.OpportunityID__C);
                    }

                    if (!leadIDConvertSET.contains(l.ID)) {
                        //One Converter Class Per Lead
                        leadQuoteConvertSet.add(l_dbLeadConvert);
                        leadIdConvertSET.add(q.LeadID__C);
                    }
                }
            }

            leadQuoteConvertList.addAll(leadQuoteConvertSet);
            //Convert the Leads
            Set<ID> lcrIDSuccessSet = new Set<ID>();
            if (leadQuoteConvertList.size() > 0) {
                List<Database.LeadConvertResult> srLeadConvertResult = Database.convertLead(
                    leadQuoteConvertList,
                    false
                );
                for (Database.LeadConvertResult lcr : srLeadConvertResult) {
                    if (lcr.isSuccess()) {
                        lcrIDSuccessSet.add(lcr.getLeadID());
                    } else {
                        //Log errors
                        for (Database.Error err : lcr.getErrors()) {
                            Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
                            myAuditError.Module__c = 'QuoteERPHandler';
                            myAuditError.Dev_Audit_Notes__c = 'Lead Quote Convert Conversion';
                            myAuditError.StatusCode__c = err.getStatusCode().name();
                            myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
                            myAuditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
                            myAuditErrorList.add(myAuditError);
                        }
                    }
                }
            }

            if(!mapOwner.isEmpty())
            {
                List<Lead> lstLeadUpd = new List<Lead>();
                for(Id idLead : mapOwner.KeySet())
                {
                    lstLeadUpd.add(new Lead(id = idLead, OwnerId = mapOwner.get(idLead)));
                }

                Database.SaveResult[] srLeadUpdateResult = Database.update(lstLeadUpd, false);
                for (Database.SaveResult sr : srLeadUpdateResult) {
                    if (sr.isSuccess()) {
                        // lcrIDSuccessSet.add(sr.getLeadID());
                    } else {
                        //Log errors
                        for (Database.Error err : sr.getErrors()) {
                            Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
                            myAuditError.Module__c = 'QuoteERPHandler';
                            myAuditError.Dev_Audit_Notes__c = 'Update inactive owner Lead';
                            myAuditError.StatusCode__c = err.getStatusCode().name();
                            myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
                            myAuditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
                            myAuditErrorList.add(myAuditError);
                        }
                    }
                }
            }
        }
        return myAuditErrorList;
    }

    /**
     * @description creates a map of existing orders from the quote ERP list
     * @param newQuotesERPList list of all quotes passed via the trigger
     * @param newQuoteXometryERPIDSet set of new quote ids from ERP List
     * @return existingOrderMap map of orders with Quote Id as key
     */
    public static Map<String, Order_ERP__C> fetchExistingOrdersMap(
        List<Quote_ERP__C> newQuotesERPList,
        Set<String> newQuoteXometryERPIDSet
    ) {
        Map<String, Order_ERP__C> existingOrderMap = new Map<String, Order_ERP__C>();
        for (Order_ERP__C o : [
            SELECT ID, Xometry_Quote_ID__c, Xometry_ERP_ID__C, AccountID__C, OwnerID, OpportunityID__C, ContactID__C
            FROM Order_ERP__C
            WHERE Xometry_Quote_ID__c IN :newQuoteXometryERPIDSet
        ]) {
            existingOrderMap.put(o.Xometry_Quote_ID__c, o);
        }
        return existingOrderMap;
    }

    /**
     * @description creates a map of existing accounts from the quote ERP list and updates addresses
     * @param newQuotesERPList list of all quotes passed via the trigger
     * @param newQuoteAccountDomainSet new quote account domain set from ERP List
     * @return existingAccountMap map of orders with account domain as key
     */
    public static Map<String, Account> fetchAndProcessExistingAccountsMap(
        List<Quote_ERP__C> newQuotesERPList,
        Set<String> newQuoteAccountDomainSet
    ) {
        // Get all Existing Accounts with Domain
        Map<String, Account> existingAccountMap = new Map<String, Account>();
        for (Account a : [
            SELECT ID, Email_Domain__c, OwnerID
            FROM Account
            WHERE Email_Domain__c IN :newQuoteAccountDomainSet
        ]) {
            existingAccountMap.put(a.Email_Domain__c, a);
        }

        //Check for Existing Accounts and populate their ERP SHIPPING ADDRESSES and ERP BILLING ADDRESSES
        //Orders are more reliable then Quotes for this data so only update Accounts where the Billing or Shipping Address combo is blank on the Account
        Map<String, Account> updateAccountMatchMap = new Map<String, Account>();
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
                OwnerId
            FROM Account
            WHERE Email_Domain__c IN :newQuoteAccountDomainSet
        ]) {
            updateAccountMatchMap.put(a.Email_Domain__C, a);
        }

        List<Account> updateAccountMatchUpdateList = new List<Account>();
        Map<String, Account> updateAccountMatchMapUpdateMap = new Map<String, Account>();
        for (Quote_ERP__C q : newQuotesERPList) {
            if (updateAccountMatchMap.containsKey(q.Account_Domain__c)) {
                Account a = updateAccountMatchMap.get(q.Account_Domain__c);
                Integer UpdateMarker = 0;
                //Check for Blank Billing Addresses
                if (
                    (String.isblank(a.ERP_Billing_Address__c) || String.isblank(a.ERP_Billing_City__c)) &&
                    (String.isblank(a.ERP_Billing_State_or_Province__c) || (String.isblank(a.ERP_Billing_Zip_Code__c)))
                ) {
                    if (
                        (!String.isblank(q.ERP_Billing_Address__c) || !String.isblank(q.ERP_Billing_City__c)) &&
                        (!String.isblank(q.ERP_Billing_State_or_Province__c) ||
                        !String.isblank(q.ERP_Billing_Zip_Code__c))
                    ) {
                        a.ERP_Billing_Address__c = q.ERP_Billing_Address__c;
                        a.ERP_Billing_City__c = q.ERP_Billing_City__c;
                        a.ERP_Billing_Country__c = q.ERP_Billing_Country__c;
                        a.ERP_Billing_State_or_Province__c = q.ERP_Billing_State_or_Province__c;
                        a.ERP_Billing_Zip_Code__c = q.ERP_Billing_Zip_Code__c;
                        UpdateMarker = 1;
                    }
                }
                //Check for Blank Shipping Addresses
                if (
                    (String.isblank(a.ERP_Shipping_Address__C) || String.isblank(a.ERP_Shipping_City__c)) &&
                    (String.isblank(a.ERP_Shipping_State_or_Province__c) ||
                    (String.isblank(a.ERP_Shipping_Zip_Code__c)))
                ) {
                    if (
                        (!String.isblank(q.ERP_Shipping_Address__C) || !String.isblank(q.ERP_Shipping_City__c)) &&
                        (!String.isblank(q.ERP_Shipping_State_or_Province__c) ||
                        !String.isblank(q.ERP_Shipping_Zip_Code__c))
                    ) {
                        a.ERP_Shipping_Address__C = q.ERP_Shipping_Address__C;
                        a.ERP_Shipping_City__c = q.ERP_Shipping_City__c;
                        a.ERP_Shipping_Country__c = q.ERP_Shipping_Country__c;
                        a.ERP_Shipping_State_or_Province__c = q.ERP_Shipping_State_or_Province__c;
                        a.ERP_Shipping_Zip_Code__c = q.ERP_Shipping_Zip_Code__c;
                        UpdateMarker = 1;
                    }
                }
                // Check if Account Owner is GNO House User and update to Sales House User
                if (a.OwnerId == AppConstants.GNO_HOUSE_USER) {
                    a.OwnerId = AppConstants.SALES_HOUSE_USER;
                    UpdateMarker = 1;
                }
                if (UpdateMarker == 1) {
                    //No duplicates with Map
                    updateAccountMatchMapUpdateMap.put(a.Email_Domain__C, a);
                }
            }
        }

        //Update some Accounts
        updateAccountMatchUpdateList.addAll(updateAccountMatchMapUpdateMap.values());
        // Create Contacts that don't exist in the system
        DatabaseUtilities.saveToDatabase(
            updateAccountMatchUpdateList,
            'QuoteERPHandler',
            'Update Account Update Fields'
        );

        return existingAccountMap;
    }

    /**
     * @description creates a map of existing contacts from the quote ERP list and updates addresses
     * @param newQuotesERPList list of all quotes passed via the trigger
     * @param newQuotePrimaryEmailSet set of primary emails from ERP List
     * @return existingContactMap map of orders with primary email as key
     */
    public static Map<String, Contact> fetchAndProcessExistingContactsMap(
        List<Quote_ERP__C> newQuotesERPList,
        Set<String> newQuotePrimaryEmailSet,
        Set<String> newQuotePartnerIdSet,
        Map<String, DUNSData> mappedDunsAccounts
    ) {
        // Get all Existing Contacts
        //Check for Existing Contacts that do not have ERP_CONTACT_IDS and Address Fields
        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        Map<String, Contact> updateContactMatchMap = new Map<String, Contact>();
        Set<String> XometryERPIdQuoteSet = new Set<String>();
        for (Contact c : [
            SELECT
                ID,
                ERP_Contact_Phone__C,
                Xometry_ERP_Contact_ID__C,
                Primary_Email__C,
                ERP_Shipping_Address__c,
                ERP_Shipping_City__c,
                ERP_Shipping_Country__c,
                ERP_Shipping_State_or_Province__c,
                ERP_Shipping_Zip_Code__c,
                OwnerId,
                AccountId,
                GNO_PartnerId__c,
                DNBConnect__D_B_Connect_Contact_Profile__c,
                LastName,
                Phone,
                DFM_Quote__c,
                Date_of_Last_DFM_Quote__c,
                DFM_Description__c
            FROM Contact
            WHERE Primary_Email__C IN :newQuotePrimaryEmailSet
        ]) {
            existingContactMap.put(c.Primary_Email__C, c);
            updateContactMatchMap.put(c.Primary_Email__C, c);

            if (String.isNotBlank(c.DFM_Quote__c)) {
                XometryERPIdQuoteSet.add(c.DFM_Quote__c);
            }
        }

        Map<String, Supplier__c> supplierMap = new Map<String, Supplier__c>();
        if (!newQuotePartnerIdSet.isEmpty()) {
            for (Supplier__c s : [
                SELECT ID, AccountId__c, PartnerId__c
                FROM Supplier__c
                WHERE PartnerId__c IN :newQuotePartnerIdSet
            ]) {
                supplierMap.put(s.PartnerId__c, s);
            }
        }

        List<Contact> updateContactMatchUpdateList = new List<Contact>();
        Map<String, Contact> updateContactMatchMapUpdateMap = new Map<String, Contact>();
        for (Quote_ERP__C q : newQuotesERPList) {
            if (updateContactMatchMap.containsKey(q.Quote_Email__C)) {
                Contact c = updateContactMatchMap.get(q.Quote_Email__C);
                Integer UpdateMarker = 0;
                if (String.isBlank(c.Xometry_ERP_Contact_ID__C)) {
                    c.Xometry_ERP_Contact_ID__C = q.ERP_Contact__C;
                    UpdateMarker = 1;
                }
                //always update phone field
                if (!String.isblank(q.ERP_Contact_Phone__c)) {
                    if (
                        String.isblank(c.ERP_Contact_Phone__C) ||
                        (!c.ERP_Contact_Phone__C.equals(q.ERP_Contact_Phone__C))
                    ) {
                        c.ERP_Contact_Phone__C = q.ERP_Contact_Phone__C;
                        UpdateMarker = 1;
                    }
                }
                //always update address fields if the address and either state or zipcode are not null and either address or city are not null
                if (
                    (!String.isblank(q.ERP_Shipping_Address__C) || !String.isblank(q.ERP_Shipping_City__c)) &&
                    (!String.isblank(q.ERP_Shipping_State_or_Province__c) ||
                    !String.isblank(q.ERP_Shipping_Zip_Code__c))
                ) {
                    c.ERP_Shipping_Address__C = q.ERP_Shipping_Address__C;
                    c.ERP_Shipping_City__c = q.ERP_Shipping_City__c;
                    c.ERP_Shipping_Country__c = q.ERP_Shipping_Country__c;
                    c.ERP_Shipping_State_or_Province__c = q.ERP_Shipping_State_or_Province__c;
                    c.ERP_Shipping_Zip_Code__c = q.ERP_Shipping_Zip_Code__c;
                    UpdateMarker = 1;
                }
                if (
                    c.DNBConnect__D_B_Connect_Contact_Profile__c == null && mappedDunsAccounts.containsKey(q.Xometry_ERP_ID__c)
                ) {
                    c.AccountId = mappedDunsAccounts.get(q.Xometry_ERP_ID__c).accountId;
                    existingContactMap.get(c.Primary_Email__c).AccountId = c.AccountId;
                    UpdateMarker = 1;
                }
                if (!String.isBlank(q.MKP_PartnerId__c)) {
                    c.GNO_PartnerId__c = q.MKP_PartnerId__c;
                    if (!supplierMap.isEmpty()) {
                        c.AccountId = supplierMap.get(q.MKP_PartnerID__c).AccountId__c;
                        existingContactMap.get(c.Primary_Email__c).GNO_PartnerId__c = c.GNO_PartnerId__c;
                    }
                    UpdateMarker = 1;
                }
                if (c.LastName.contains('@') && c.LastName == q.Quote_Email__c && q.ERP_Contact_Last_Name__c != null) {
                    c.LastName = q.ERP_Contact_Last_Name__c;
                    UpdateMarker = 1;
                }

                Contact contLastValues = new Contact();
                if (updateContactMatchMapUpdateMap.containsKey(c.Primary_Email__C)) {
                    contLastValues = updateContactMatchMapUpdateMap.get(c.Primary_Email__c);
                } else {
                    contLastValues = c;
                }
                //Mini DRY method for later
                if (
                    (!String.isblank(q.DFM_Description__c)) &&
                    (contLastValues.Date_of_Last_DFM_Quote__c == null ||
                    q.Quote_ERP_Created_Time__c >= contLastValues.Date_of_Last_DFM_Quote__c)
                ) {
                    c.DFM_Description__c = q.DFM_Description__c;
                    c.DFM_Quote__c = q.Xometry_ERP_ID__c;
                    c.Date_of_Last_DFM_Quote__c = q.Quote_ERP_Created_Time__c;
                    UpdateMarker = 1;
                }

                if (UpdateMarker == 1) {
                    //No duplicates with Map
                    updateContactMatchMapUpdateMap.put(c.Primary_Email__C, c);
                }
            }
        }

        //Update some Contacts
        updateContactMatchUpdateList.addAll(updateContactMatchMapUpdateMap.values());
        // Create Contacts that don't exist in the system
        DatabaseUtilities.saveToDatabase(
            updateContactMatchUpdateList,
            'QuoteERPHandler',
            'Update Contact Update Fields'
        );
        return existingContactMap;
    }

    /**
     * @description creates a map of existing leads from the quote ERP list and updates addresses
     * @param newQuotePrimaryEmailSet set of primary emails from ERP List
     * @return existingLeadMap map of orders with primary email as key
     */
    public static Map<String, Lead> fetchExistingLeadsMap(Set<String> newQuotePrimaryEmailSet) {
        // Get all Existing Leads with Domain
        Map<String, Lead> existingLeadMap = new Map<String, Lead>();
        for (Lead l : [
            SELECT
                ID,
                Lead_Creation_Email__C,
                Primary_Email__C,
                Phone,
                OwnerID,
                LeadSource,
                Email_Domain__c,
                Generated_by_Sales__c
            FROM Lead
            WHERE
                (Lead_Creation_Email__C IN :newQuotePrimaryEmailSet
                OR Primary_Email__C IN :newQuotePrimaryEmailSet)
                AND isConverted = FALSE
            ORDER BY Createddate DESC
        ]) {
            if (
                !String.isBlank(l.Lead_Creation_Email__C) && newQuotePrimaryEmailSet.contains(l.Lead_Creation_Email__C)
            ) {
                if (!existingLeadmap.containsKey(l.Lead_Creation_Email__C)) {
                    existingLeadMap.put(l.Lead_Creation_Email__C, l);
                }
            } else if (!existingLeadmap.containsKey(l.Primary_Email__C)) {
                existingLeadMap.put(l.Primary_Email__C, l);
            }
        }
        return existingLeadMap;
    }

    /**
     * @description method that does the core of processing creating/updating all objects associated with Quotes
     * @param newQuoteERPList list of newly inserted Quotes
     */
    public static void processERPQuotes2(List<Quote_ERP__C> newQuotesERPList) {
        // Referencing
        Set<String> newQuoteXometryERPIDSet = new Set<String>();
        // Lookup Existing Contacts
        Set<String> newQuotePrimaryEmailSet = new Set<String>();
        Set<String> newQuoteAccountDomainSet = new Set<String>();
        Set<String> newQuoteAccountNameSet = new Set<String>();
        Set<String> newQuotePartnerIdSet = new Set<String>();
        List<DUNSData> newQuoteDunsData = new List<DUNSData>();

        for (Quote_ERP__C q : newQuotesERPList) {
            newQuoteXometryERPIDSet.add(q.Xometry_ERP_ID__C);
            newQuotePrimaryEmailSet.add(q.Quote_Email__C);
            newQuoteAccountDomainSet.add(q.Account_Domain__c);
            if (!string.isBlank(q.ERP_User_Company_Name__C)) {
                newQuoteAccountNameSet.add(q.ERP_User_Company_Name__C);
            }
            if (!String.isBlank(q.MKP_PartnerID__c)) {
                newQuotePartnerIdSet.add(q.MKP_PartnerID__c);
            }
            if (
                !String.isBlank(q.UserDUNSNumber__c) ||
                !String.isBlank(q.UserParentDUNSNumber__c) ||
                !String.isBlank(q.UserUltimateDUNSNumber__c)
            ) {
                DUNSData duns = new DUNSData();
                duns.userDUNSNumber = q.UserDUNSNumber__c;
                duns.userParentDUNSNumber = q.UserParentDUNSNumber__c;
                duns.userUltimateDUNSNumber = q.UserUltimateDUNSNumber__c;
                duns.domain = q.Account_Domain__c;
                duns.sourceId = q.Xometry_ERP_ID__c;
                duns.accountId = null;
                duns.ownerId = null;
                newQuoteDunsData.add(duns);
            }
        }

        Map<String, Order_ERP__C> existingOrderMap = fetchExistingOrdersMap(newQuotesERPList, newQuoteXometryERPIDSet);
        Map<String, Account> existingAccountMap = fetchAndProcessExistingAccountsMap(
            newQuotesERPList,
            newQuoteAccountDomainSet
        );
        Map<String, DUNSData> mappedDunsAccounts = new Map<String, DUNSData>();
        if (!newQuoteDunsData.isEmpty()) {
            mappedDunsAccounts = AccountDunsHelper.DunsAccountRouting(newQuoteDunsData);
        }

        Map<String, Contact> existingContactMap = fetchAndProcessExistingContactsMap(
            newQuotesERPList,
            newQuotePrimaryEmailSet,
            newQuotePartnerIdSet,
            mappedDunsAccounts
        );

        Map<String, Supplier__c> existingSupplierMap = SupplierUtility.fetchSuppliers(newQuotePartnerIdSet);

        List<Quote_ERP__C> oppQuoteLogicStartList = new List<Quote_ERP__C>();
        List<Quote_ERP__C> contactsToCreateQuotesList = new List<Quote_ERP__C>();
        List<Quote_ERP__C> accountsToCreateQuotesList = new List<Quote_ERP__C>();
        Set<Contact> contactsToCreateSet = new Set<Contact>();
        // Check if Contact exists or Account Exists
        for (Quote_ERP__C q : newQuotesERPList) {
            if (existingOrderMap.containsKey(q.Xometry_ERP_ID__C)) {
                // Check if Order already exists for Quote
                q.ContactID__C = existingOrderMap.get(q.Xometry_ERP_ID__C).ContactID__C;
                q.AccountID__C = existingOrderMap.get(q.Xometry_ERP_ID__C).AccountID__C;
                q.OrderERPSFID__C = existingOrderMap.get(q.Xometry_ERP_ID__C).ID;
                q.OwnerID = existingOrderMap.get(q.Xometry_ERP_ID__C).OwnerID;
                q.OpportunityID__C = existingOrderMap.get(q.Xometry_ERP_ID__C).OpportunityID__C;
            } else if (existingSupplierMap.containsKey(q.MKP_PartnerId__c)) {
                // Check if Account with Partner ID exists drop to Domain/Email checking
                q.AccountID__c = existingSupplierMap.get(q.MKP_PartnerId__c).AccountId__c;
                q.OwnerId = existingSupplierMap.get(q.MKP_PartnerId__c).AccountId__r.OwnerId;
                if (existingContactMap.containsKey(q.Quote_Email__C)) {
                    q.ContactID__C = existingContactMap.get(q.Quote_Email__C).ID;
                    oppQuoteLogicStartList.add(q);
                } else {
                    contactsToCreateSet.add(createContact(q));
                    contactsToCreateQuotesList.add(q);
                }
            } else if (mappedDunsAccounts.containsKey(q.Xometry_ERP_ID__c)) {
                q.AccountId__c = mappedDunsAccounts.get(q.Xometry_ERP_ID__c).accountId;
                q.OwnerId = mappedDunsAccounts.get(q.Xometry_ERP_ID__c).ownerId;
                if (existingContactMap.containsKey(q.Quote_Email__C)) {
                    System.debug('contact exists');
                    q.ContactID__C = existingContactMap.get(q.Quote_Email__C).ID;
                    oppQuoteLogicStartList.add(q);
                } else {
                    System.debug('Contact does not exist');
                    contactsToCreateSet.add(createContact(q));
                    contactsToCreateQuotesList.add(q);
                }
            } else if (existingContactMap.containsKey(q.Quote_Email__C)) {
                // Check if Contact exists drop to Create Opp List
                existingContactMap.get(q.Quote_Email__C);
                q.ContactID__C = existingContactMap.get(q.Quote_Email__C).ID;
                q.AccountID__C = existingContactMap.get(q.Quote_Email__C).AccountID;
                q.OwnerID = existingContactMap.get(q.Quote_Email__C).OwnerID;
                oppQuoteLogicStartList.add(q);
            } else if (existingAccountMap.containsKey(q.Account_Domain__c)) {
                // Check if Account exists and is not generic drop to Create Contact List and Create Opp List
                q.AccountID__C = existingAccountMap.get(q.Account_Domain__c).ID;
                q.OwnerID = existingAccountMap.get(q.Account_Domain__c).OwnerID;
                contactsToCreateSet.add(createContact(q));
                contactsToCreateQuotesList.add(q);
            } else {
                // Check if the domain is non generic and we have already checked for account/contact doesn't exist
                accountsToCreateQuotesList.add(q);
                // Create Accounts then after Account Creation then new Contact Creation
            }

            if (q.OwnerID == AppConstants.API_USER) {
                q.OwnerID = AppConstants.SALES_API_USER;
            }
        }

        //Create Accounts
        if (!accountsToCreateQuotesList.isEmpty()) {
            Map<String, Lead> existingLeadMap = fetchExistingLeadsMap(newQuotePrimaryEmailSet);

            List<Account> accountsToCreateList = QuoteToNewAccount(
                accountsToCreateQuotesList,
                newQuoteAccountNameSet,
                existingLeadMap
            );

            //Insert the Accounts
            DatabaseUtilities.insertToDatabase(accountsToCreateList, 'QuoteERPHandler', 'Non Generic Account Inserts');

            //Only RR successes
            if (!accountsToCreateList.isEmpty()) {
                Set<ID> createdAccountNonGenericRRIDs = new Set<ID>();
                Set<ID> createdAccountGenericRRIDs = new Set<ID>();
                Set<ID> createdAccountIDSet = new Set<ID>();

                for (Account a : accountsToCreateList) {
                    if (a.ID != null) {
                        createdAccountIDSet.add(a.ID);
                        if (a.RR_FLAG__C && ApexBypassUtility.shouldRun('QuoteERPHandler_account_round_robin')) {
                            if (a.generic_account__c) {
                                createdAccountGenericRRIDs.add(a.ID);
                            } else {
                                createdAccountNonGenericRRIDs.add(a.ID);
                            }
                        }
                    }
                }

                //Round Robin the Account
                if (createdAccountNonGenericRRIDs.size() > 0) {
                    roundRobinDist.account_round_robin_NonGeneric_BDR(createdAccountNonGenericRRIDs);
                }

                //Round Robin the Account
                if (createdAccountGenericRRIDs.size() > 0) {
                    roundRobinDist.account_round_robin_Generic_BDR(createdAccountGenericRRIDs);
                }

                if (!createdAccountIDSet.isEmpty()) {
                    //Take the Success List and Get Account IDs, OwnerIDs and the Domain. Create a domain map
                    //Map the Accounts to Domain
                    Map<String, Account> allAccountsDomainMap = new Map<String, Account>();
                    for (Account a : [
                        SELECT ID, Name, Email_Domain__c, OwnerID
                        FROM Account
                        WHERE ID IN :createdAccountIDSet
                    ]) {
                        allAccountsDomainMap.put(a.Email_Domain__C, a);
                    }

                    // Post Account Creation Add the Newly Created Account to the Quote and the newAccountNewContactSet
                    for (Quote_ERP__C q : accountsToCreateQuotesList) {
                        if (allAccountsDomainMap.containsKey(q.Account_Domain__c)) {
                            q.OwnerID = allAccountsDomainMap.get(q.Account_Domain__c).OwnerID;
                            q.AccountID__C = allAccountsDomainMap.get(q.Account_Domain__c).ID;

                            //Create a new Contact for each newly created Account
                            contactsToCreateSet.add(createContact(q));
                            contactsToCreateQuotesList.add(q);
                        }
                    }
                }
            }
        }

        // Post Account Creation Add the Newly Created Account to the Quote and the newAccountNewContactSet
        List<Audit_Trail_Error__c> myAuditErrorList = new List<Audit_Trail_Error__c>();

        //Create Contacts
        if (!contactsToCreateSet.isEmpty()) {
            //Loop through both Contact Sets and create new set based on emails
            Set<String> primaryEmailCreateSet = new Set<String>();
            Map<String, Contact> contactsToCreateMap = new Map<String, Contact>();

            for (Contact c : contactsToCreateSet) {
                //Remove duplicate contacts rapid quotes from same new email
                if (!primaryEmailCreateSet.contains(c.Primary_Email__C)) {
                    if (existingSupplierMap.containsKey(c.GNO_PartnerId__c)) {
                        c.AccountId = existingSupplierMap.get(c.GNO_PartnerId__c).AccountId__c;
                    }
                    primaryEmailCreateSet.add(c.Primary_Email__C);
                    contactsToCreateMap.put(c.Primary_Email__C, c);
                }
            }

            // Create Contacts that don't exist in the system
            Database.SaveResult[] srList = Database.insert(contactsToCreateMap.values(), false);

            //Check Results of Insert -- Create error object to write errors to
            Set<Id> createdContactIDs = new Set<Id>();
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    //Operation was successful
                    createdContactIDs.add(sr.getId());
                } else {
                    //Log errors
                    for (Database.Error err : sr.getErrors()) {
                        Audit_Trail_Error__c myAuditError = new Audit_Trail_Error__c();
                        myAuditError.Module__c = 'QuoteERPHandler';
                        myAuditError.Dev_Audit_Notes__c = 'Non Generic Contact Inserts';
                        myAuditError.StatusCode__c = err.getStatusCode().name();
                        myAuditError.errorMessage__c = err.getMessage().abbreviate(250);
                        myAuditError.errorFields__c = String.join(err.getFields(), ' ').abbreviate(250);
                        myAuditErrorList.add(myAuditError);
                    }
                }
            }

            for (Quote_ERP__C q : contactsToCreateQuotesList) {
                if (
                    contactsToCreateMap.containsKey(q.Quote_Email__C) &&
                    contactsToCreateMap.get(q.Quote_Email__C).Id != null
                ) {
                    q.ContactID__C = contactsToCreateMap.get(q.Quote_Email__C).Id;
                }
                oppQuoteLogicStartList.add(q);
            }
        }

        //Start of the Opp Section
        myAuditErrorList.addAll(upsertOpportunities(oppQuoteLogicStartList, newQuotesERPList));

        //If the AuditList is not empty then insert the audit list
        if (!myAuditErrorList.isEmpty()) {
            insert myAuditErrorList;
        }
    }

    /**
     * @description Retrieves all Opportunities associated with an Quote with updated price field
     * @param updatedQuotes List of Quote objects updated in Salesforce
     * @param oldQuoteMap map of quotes that have been changed
     */
    public static void updateOpp(List<Quote_ERP__C> updatedQuotes, Map<ID, Quote_ERP__C> oldQuoteMap) {
        // Set of Quote to look up all associated Opportunities, Map of Quotes to matching
        Set<String> newQuoteSet = new Set<String>();
        Map<String, Quote_ERP__C> quoteMap = new Map<String, Quote_ERP__C>();

        for (Quote_ERP__C quote : updatedQuotes) {
            Quote_ERP__C oldQuote = oldQuoteMap.get(quote.ID);
            if (
                //For ETL delays where the Order Time flag from the Order is not on the quote but the quote's status is updated.
                (quote.Order_Time_Flag__c == false && quote.ERP_Status__c != 'Ordered') &&
                (// if any amount, erp status, manufacturing, or quote type values are changed, then add it to the change list
                oldQuote.Quote_Price__c != quote.Quote_Price__c ||
                oldQuote.ERP_Status__c != quote.ERP_Status__c ||
                oldQuote.process_isCarbon__c != quote.process_isCarbon__c ||
                oldQuote.process_isCNC_Machining__c != quote.process_isCNC_Machining__c ||
                oldQuote.process_isDie_Casting__c != quote.process_isDie_Casting__c ||
                oldQuote.process_isDirect_Sourced__c != quote.process_isDirect_Sourced__c ||
                oldQuote.process_isDMLS__c != quote.process_isDMLS__c ||
                oldQuote.process_isExtrusion__c != quote.process_isExtrusion__c ||
                oldQuote.process_isFDM__c != quote.process_isFDM__c ||
                oldQuote.process_isHPMultJetFusion__c != quote.process_isHPMultJetFusion__c ||
                oldQuote.process_isInjection_Molding__c != quote.process_isInjection_Molding__c ||
                oldQuote.process_isInjectionMoldingTool__c != quote.process_isInjectionMoldingTool__c ||
                oldQuote.process_isPolyJet_3D__c != quote.process_isPolyJet_3D__c ||
                oldQuote.process_isPlasticExtrusion__c != quote.process_isPlasticExtrusion__c ||
                oldQuote.process_isSheet_metal__c != quote.process_isSheet_metal__c ||
                oldQuote.process_isSLA__c != quote.process_isSLA__c ||
                oldQuote.process_isSLS__c != quote.process_isSLS__c ||
                oldQuote.process_isStamping__c != quote.process_isStamping__c ||
                oldQuote.process_isUrethane_Casting__c != quote.process_isUrethane_Casting__c ||
                oldQuote.process_isBinderJetting__c != quote.process_isBinderJetting__c ||
                oldQuote.process_isSheetCutting__c != quote.process_isSheetCutting__c ||
                oldQuote.process_isTubeBending__c != quote.process_isTubeBending__c ||
                oldQuote.process_isTubeCutting__c != quote.process_isTubeCutting__c ||
                oldQuote.process_isOther__c != quote.process_isOther__c ||
                oldQuote.process_isOther_NotIncluded__c != quote.process_isOther_NotIncluded__c ||
                oldQuote.process_isLSPc__c != quote.process_isLSPc__c ||
                oldQuote.process_isAssembly__c != quote.process_isAssembly__c ||
                oldQuote.Quoted_Total_Qty_Carbon__c != quote.Quoted_Total_Qty_Carbon__c ||
                oldQuote.Quoted_Total_Qty_CNC__c != quote.Quoted_Total_Qty_CNC__c ||
                oldQuote.Quoted_Total_Qty_DieCasting__c != quote.Quoted_Total_Qty_DieCasting__c ||
                oldQuote.Quoted_Total_Qty_DirectSourced__c != quote.Quoted_Total_Qty_DirectSourced__c ||
                oldQuote.Quoted_Total_Qty_DMLS__c != quote.Quoted_Total_Qty_DMLS__c ||
                oldQuote.Quoted_Total_Qty_Extrusion__c != quote.Quoted_Total_Qty_Extrusion__c ||
                oldQuote.Quoted_Total_Qty_FDM__c != quote.Quoted_Total_Qty_FDM__c ||
                oldQuote.Quoted_Total_Qty_HPMultJetFusion__c != quote.Quoted_Total_Qty_HPMultJetFusion__c ||
                oldQuote.Quoted_Total_Qty_InjectionMolding__c != quote.Quoted_Total_Qty_InjectionMolding__c ||
                oldQuote.Quoted_Total_Qty_InjectionMoldingTool__c != quote.Quoted_Total_Qty_InjectionMoldingTool__c ||
                oldQuote.Quoted_Total_Qty_PolyJet3D__c != quote.Quoted_Total_Qty_PolyJet3D__c ||
                oldQuote.Quoted_Total_Qty_PlasticExtrusion__c != quote.Quoted_Total_Qty_PlasticExtrusion__c ||
                oldQuote.Quoted_Total_Qty_SheetMetal__c != quote.Quoted_Total_Qty_SheetMetal__c ||
                oldQuote.Quoted_Total_Qty_SLA__c != quote.Quoted_Total_Qty_SLA__c ||
                oldQuote.Quoted_Total_Qty_SLS__c != quote.Quoted_Total_Qty_SLS__c ||
                oldQuote.Quoted_Total_Qty_Stamping__c != quote.Quoted_Total_Qty_Stamping__c ||
                oldQuote.Quoted_Total_Qty_UrethaneCasting__c != quote.Quoted_Total_Qty_UrethaneCasting__c ||
                oldQuote.Quoted_Total_Qty_BinderJetting__c != quote.Quoted_Total_Qty_BinderJetting__c ||
                oldQuote.Quoted_Total_Qty_SheetCutting__c != quote.Quoted_Total_Qty_SheetCutting__c ||
                oldQuote.Quoted_Total_Qty_Tube_Cutting__c != quote.Quoted_Total_Qty_Tube_Cutting__c ||
                oldQuote.Quoted_Total_Qty_Tube_Cutting__c != quote.Quoted_Total_Qty_Tube_Cutting__c ||
                oldQuote.Quoted_Total_Qty_Other__c != quote.Quoted_Total_Qty_Other__c ||
                oldQuote.Quoted_Total_Qty_Other_NotIncluded__c != quote.Quoted_Total_Qty_Other_NotIncluded__c ||
                oldQuote.Quoted_Total_Qty_LSPc__c != quote.Quoted_Total_Qty_LSPc__c ||
                oldQuote.Quoted_Total_Qty_Assembly__c != quote.Quoted_Total_Qty_Assembly__c ||
                oldQuote.FDMSize__c != quote.FDMSize__c ||
                oldQuote.Quote_Type__c != quote.Quote_Type__c ||
                oldQuote.FirstQuoterEmail__c != quote.FirstQuoterEmail__c ||
                oldQuote.ManualQuoterEmail__c != quote.ManualQuoterEmail__c ||
                oldQuote.FirstQuoterUser__c != quote.FirstQuoterUser__c ||
                oldQuote.ManualQuoterUser__c != quote.ManualQuoterUser__c ||
                oldQuote.ManualQuoteTime__c != quote.ManualQuoteTime__c ||
                oldQuote.ConversionProbability__c != quote.ConversionProbability__c ||
                oldQuote.ITAR__c != quote.ITAR__c ||
                oldQuote.Hardware_Cert__c != quote.Hardware_Cert__c ||
                oldQuote.Conformance_Cert__c != quote.Conformance_Cert__c ||
                oldQuote.Material_Traceability_Cert__c != quote.Material_Traceability_Cert__c ||
                oldQuote.Material_Cert__c != quote.Material_Cert__c ||
                oldQuote.LineItemCount__c != quote.LineItemCount__c ||
                oldQuote.Quote_Discount__c != quote.Quote_Discount__c ||
                oldQuote.Quote_Redeemed_Points_Value__c != quote.Quote_Redeemed_Points_Value__c ||
                oldQuote.Quote_Sub_Total__c != quote.Quote_Sub_Total__c ||
                oldQuote.Quote_Shipping__c != quote.Quote_Shipping__c) ||
                oldQuote.DFM_Description__c != quote.DFM_Description__c ||
                oldQuote.Manual_Quote_Prioritization_Score__c != quote.Manual_Quote_Prioritization_Score__c ||
                oldQuote.Win_Rate_Expected_Value__c != quote.Win_Rate_Expected_Value__c ||
                oldQuote.Quote_Win_Rate__c != quote.Quote_Win_Rate__c ||
                oldQuote.QuickTurn__c != quote.QuickTurn__c ||
                oldQuote.getSite_Deleted__c != quote.getSite_Deleted__c ||
                oldQuote.Allow_EU_Quoting__c != quote.Allow_EU_Quoting__c ||
                oldQuote.Quote_Source__c != quote.Quote_Source__c
            ) {
                newQuoteSet.add(quote.Xometry_ERP_ID__C);
                quoteMap.put(quote.Xometry_ERP_ID__C, quote);
            }
        }

        if (!newQuoteSet.isEmpty()) {
            Set<Opportunity> updatedOppSet = new Set<Opportunity>();
            List<Opportunity> oppsUpdateList = new List<Opportunity>();

            for (
                Opportunity opp : [
                    SELECT
                        ID,
                        Last_Quote_Xometry_ERP_ID__c,
                        Amount,
                        ERP_Status__c,
                        most_recent_quote_Carbon__c,
                        most_recent_quote_CNC_Machining__c,
                        most_recent_quote_Die_Casting__c,
                        most_recent_quote_Direct_Sourced__c,
                        most_recent_quote_DMLS__c,
                        most_recent_quote_Extrusion__c,
                        most_recent_quote_FDM__c,
                        most_recent_quote_HPMultiJetFusion__c,
                        most_recent_quote_Injection_Molding__c,
                        most_recent_quote_PolyJet_3D__c,
                        most_recent_quote_Sheet_metal__c,
                        most_recent_quote_SLA__c,
                        most_recent_quote_SLS__c,
                        most_recent_quote_Stamping__c,
                        most_recent_quote_Urethane_Casting__c,
                        FDMSize__c
                    FROM Opportunity
                    WHERE Last_Quote_Xometry_ERP_ID__c IN :newQuoteSet AND StageName != 'Closed Won'
                    //If the Opp is closed won then we want the Order to handle all Update operations at this time for safety
                ]
            ) {
                if (quoteMap.containsKey(opp.Last_Quote_Xometry_ERP_ID__c)) {
                    Quote_ERP__c quote = quoteMap.get(opp.Last_Quote_Xometry_ERP_ID__c);
                    opp.Amount = quote.Quote_Price__c;
                    opp.ERP_Status__c = quote.ERP_Status__c;
                    opp.most_recent_quote_Carbon__c = quote.process_isCarbon__c;
                    opp.most_recent_quote_CNC_Machining__c = quote.process_isCNC_Machining__c;
                    opp.most_recent_quote_Die_Casting__c = quote.process_isDie_Casting__c;
                    opp.most_recent_quote_Direct_Sourced__c = quote.process_isDirect_Sourced__c;
                    opp.most_recent_quote_DMLS__c = quote.process_isDMLS__c;
                    opp.most_recent_quote_Extrusion__c = quote.process_isExtrusion__c;
                    opp.most_recent_quote_FDM__c = quote.process_isFDM__c;
                    opp.most_recent_quote_HPMultiJetFusion__c = quote.process_isHPMultJetFusion__c;
                    opp.most_recent_quote_Injection_Molding__c = quote.process_isInjection_Molding__c;
                    Opp.Most_Recent_Quote_Injection_Molding_Tool__c = quote.process_isInjectionMoldingTool__c;
                    opp.most_recent_quote_PolyJet_3D__c = quote.process_isPolyJet_3D__c;
                    opp.most_recent_quote_PlasticExtrusion__c = quote.process_isPlasticExtrusion__c;
                    opp.most_recent_quote_Sheet_metal__c = quote.process_isSheet_metal__c;
                    opp.most_recent_quote_SLA__c = quote.process_isSLA__c;
                    opp.most_recent_quote_SLS__c = quote.process_isSLS__c;
                    opp.most_recent_quote_Stamping__c = quote.process_isStamping__c;
                    opp.most_recent_quote_Urethane_Casting__c = quote.process_isUrethane_Casting__c;
                    opp.most_recent_quote_BinderJetting__c = quote.process_isBinderJetting__c;
                    opp.most_recent_quote_SheetCutting__c = quote.process_isSheetCutting__c;
                    opp.most_recent_quote_TubeBending__c = quote.process_isTubeBending__c;
                    opp.most_recent_quote_TubeCutting__c = quote.process_isTubeCutting__c;
                    opp.most_recent_quote_Other__c = quote.process_isOther__c;
                    opp.most_recent_quote_Other_NotIncluded__c = quote.process_isOther_NotIncluded__c;
                    opp.most_recent_quote_LSPc__c = quote.process_isLSPc__c;
                    opp.most_recent_quote_Assembly__c = quote.process_isAssembly__c;
                    opp.Total_Amt_Carbon__c = quote.Quoted_Total_Amt_Carbon__c;
                    opp.Total_Amt_CNC__c = quote.Quoted_Total_Amt_CNC__c;
                    opp.Total_Amt_DieCasting__c = quote.Quoted_Total_Amt_DieCasting__c;
                    opp.Total_Amt_DirectSourced__c = quote.Quoted_Total_Amt_DirectSourced__c;
                    opp.Total_Amt_DMLS__c = quote.Quoted_Total_Amt_DMLS__c;
                    opp.Total_Amt_Extrusion__c = quote.Quoted_Total_Amt_Extrusion__c;
                    opp.Total_Amt_FDM__c = quote.Quoted_Total_Amt_FDM__c;
                    opp.Total_Amt_HPMultJetFusion__c = quote.Quoted_Total_Amt_HPMultJetFusion__c;
                    opp.Total_Amt_InjectionMolding__c = quote.Quoted_Total_Amt_InjectionMolding__c;
                    opp.Total_Amt_InjectionMoldingTool__c = quote.Quoted_Total_Amt_InjectionMoldingTool__c;
                    opp.Total_Amt_PolyJet3D__c = quote.Quoted_Total_Amt_PolyJet3D__c;
                    opp.Total_Amt_PlasticExtrusion__c = quote.Quoted_Total_Amt_PlasticExtrusion__c;
                    opp.Total_Amt_SheetMetal__c = quote.Quoted_Total_Amt_SheetMetal__c;
                    opp.Total_Amt_SLA__c = quote.Quoted_Total_Amt_SLA__c;
                    opp.Total_Amt_SLS__c = quote.Quoted_Total_Amt_SLS__c;
                    opp.Total_Amt_Stamping__c = quote.Quoted_Total_Amt_Stamping__c;
                    opp.Total_Amt_UrethaneCasting__c = quote.Quoted_Total_Amt_UrethaneCasting__c;
                    opp.Total_Amt_BinderJetting__c = quote.Quoted_Total_Amt_BinderJetting__c;
                    opp.Total_Amt_SheetCutting__c = quote.Quoted_Total_Amt_SheetCutting__c;
                    opp.Total_Amt_Tube_Bending__c = quote.Quoted_Total_Amt_Tube_Bending__c;
                    opp.Total_Amt_Tube_Cutting__c = quote.Quoted_Total_Amt_Tube_Cutting__c;
                    opp.Total_Amt_Other__c = quote.Quoted_Total_Amt_Other__c;
                    opp.Total_Amt_Other_NotIncluded__c = quote.Quoted_Total_Amt_Other_NotIncluded__c;
                    opp.Total_Amt_LSPc__c = quote.Quoted_Total_Amt_LSPc__c;
                    opp.Total_Amt_Assembly__c = quote.Quoted_Total_Amt_Assembly__c;
                    opp.Total_Qty_Carbon__c = quote.Quoted_Total_Qty_Carbon__c;
                    opp.Total_Qty_CNC__c = quote.Quoted_Total_Qty_CNC__c;
                    opp.Total_Qty_DieCasting__c = quote.Quoted_Total_Qty_DieCasting__c;
                    opp.Total_Qty_DirectSourced__c = quote.Quoted_Total_Qty_DirectSourced__c;
                    opp.Total_Qty_DMLS__c = quote.Quoted_Total_Qty_DMLS__c;
                    opp.Total_Qty_Extrusion__c = quote.Quoted_Total_Qty_Extrusion__c;
                    opp.Total_Qty_FDM__c = quote.Quoted_Total_Qty_FDM__c;
                    opp.Total_Qty_HPMultJetFusion__c = quote.Quoted_Total_Qty_HPMultJetFusion__c;
                    opp.Total_Qty_InjectionMolding__c = quote.Quoted_Total_Qty_InjectionMolding__c;
                    opp.Total_Qty_InjectionMoldingTool__c = quote.Quoted_Total_Qty_InjectionMoldingTool__c;
                    opp.Total_Qty_PolyJet3D__c = quote.Quoted_Total_Qty_PolyJet3D__c;
                    opp.Total_Qty_PlasticExtrusion__c = quote.Quoted_Total_Qty_PlasticExtrusion__c;
                    opp.Total_Qty_SheetMetal__c = quote.Quoted_Total_Qty_SheetMetal__c;
                    opp.Total_Qty_SLA__c = quote.Quoted_Total_Qty_SLA__c;
                    opp.Total_Qty_SLS__c = quote.Quoted_Total_Qty_SLS__c;
                    opp.Total_Qty_Stamping__c = quote.Quoted_Total_Qty_Stamping__c;
                    opp.Total_Qty_UrethaneCasting__c = quote.Quoted_Total_Qty_UrethaneCasting__c;
                    opp.Total_Qty_BinderJetting__c = quote.Quoted_Total_Qty_BinderJetting__c;
                    opp.Total_Qty_SheetCutting__c = quote.Quoted_Total_Qty_SheetCutting__c;
                    opp.Total_Qty_Tube_Bending__c = quote.Quoted_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Tube_Cutting__c = quote.Quoted_Total_Qty_Tube_Cutting__c;
                    opp.Total_Qty_Other__c = quote.Quoted_Total_Qty_Other__c;
                    opp.Total_Qty_Other_NotIncluded__c = quote.Quoted_Total_Qty_Other_NotIncluded__c;
                    opp.Total_Qty_LSPc__c = quote.Quoted_Total_Qty_LSPc__c;
                    opp.Total_Qty_Assembly__c = quote.Quoted_Total_Qty_Assembly__c;
                    opp.FDMSize__c = quote.FDMSize__c;
                    opp.Quote_Type__c = quote.Quote_Type__c;
                    opp.FirstQuoterEmail__c = quote.FirstQuoterEmail__c;
                    opp.ManualQuoterEmail__c = quote.ManualQuoterEmail__c;
                    opp.FirstQuoterUser__c = quote.FirstQuoterUser__c;
                    opp.ManualQuoterUser__c = quote.ManualQuoterUser__c;
                    opp.ManualQuoteTime__c = quote.ManualQuoteTime__c;
                    opp.ConversionProbability__c = quote.ConversionProbability__c;
                    Opp.ITAR__c = quote.ITAR__c;
                    Opp.Hardware_Cert__c = quote.Hardware_Cert__c;
                    Opp.Conformance_Cert__c = quote.Conformance_Cert__c;
                    Opp.Material_Traceability_Cert__c = quote.Material_Traceability_Cert__c;
                    Opp.Material_Cert__c = quote.Material_Cert__c;
                    Opp.LineItemCount__c = quote.LineItemCount__c;
                    Opp.order_Discount__c = quote.Quote_Discount__c;
                    Opp.order_Redeemed_Points_Value__c = quote.Quote_Redeemed_Points_Value__c;
                    Opp.SubTotal__c = quote.Quote_Sub_Total__c;
                    Opp.order_Shipping__c = quote.Quote_Shipping__c;
                    Opp.DFM_Description__c = quote.DFM_Description__c;
                    Opp.Win_Rate_Expected_Value__c = quote.Win_Rate_Expected_Value__c;
                    Opp.Quote_Win_Rate__c = quote.Quote_Win_Rate__c;
                    Opp.QuickTurn__c = quote.QuickTurn__c;
                    Opp.Manual_Quote_Prioritization_Score__c = quote.Manual_Quote_Prioritization_Score__c;
                    Opp.getSite_Deleted__c = quote.getSite_Deleted__c;
                    Opp.Allow_EU_Quoting__c = quote.Allow_EU_Quoting__c;
                    Opp.Quote_Source__c = quote.Quote_Source__c;

                    updatedOppSet.add(opp);
                }
            }

            oppsUpdateList.addAll(updatedOppSet);

            DatabaseUtilities.saveToDatabase(oppsUpdateList, UPDATE_OPP_METHOD_NAME, UPDATE_OPP_DEV_NOTE);
        }
    }

    /**
     * @description helper function to coalesce String values
     * @param accountObject Account value to be returned if not null with highest priority
     * @param quoteCountry String value to be returned if not null with lowest priority
     */
    public static String coalesceCountry(Account accountObject, String quoteCountry) {
        if (accountObject != null && accountObject.parent != null && accountObject.parent.BillingCountry != null) {
            return accountObject.parent.BillingCountry;
        } else if (accountObject != null && accountObject.BillingCountry != null) {
            return accountObject.BillingCountry;
        } else if (quoteCountry != null) {
            return quoteCountry;
        } else {
            return '';
        }
    }

    /**
     * @description helper function to coalesce String values
     * @param accountObject Account value to be returned if not null with highest priority
     * @param quoteState String value to be returned if not null with lowest priority
     */
    public static String coalesceState(Account accountObject, String quoteState) {
        if (accountObject != null && accountObject.parent != null && accountObject.parent.BillingState != null) {
            return accountObject.parent.BillingState;
        } else if (accountObject != null && accountObject.BillingState != null) {
            return accountObject.BillingState;
        } else if (quoteState != null) {
            return quoteState;
        } else {
            return '';
        }
    }

    /**
     * @description updates the User lookup field for Manual Quoter User and First Quoter User
     * @param quoteList Quote from trigger
     */
    public static void updateQuoterUser(List<Quote_ERP__C> quoteList) {
        Set<String> userEmailSet = new Set<String>();
        Map<String, User> userEmailMap = new Map<String, User>();

        for (Quote_ERP__c q : quoteList) {
            if (q.ManualQuoterEmail__c != null) {
                userEmailSet.add(q.ManualQuoterEmail__c);
            }
            if (q.FirstQuoterEmail__c != null && q.FirstQuoterEmail__c.contains('@xometry.com')) {
                userEmailSet.add(q.FirstQuoterEmail__c);
            }
        }

        for (User u : [SELECT Id, Email, IsActive FROM User WHERE Email IN :userEmailSet AND IsActive = TRUE]) {
            userEmailMap.put(u.Email, u);
        }

        if (userEmailMap.size() > 0) {
            for (Quote_ERP__c q : quoteList) {
                if (userEmailMap.containsKey(q.ManualQuoterEmail__c)) {
                    q.ManualQuoterUser__c = userEmailMap.get(q.ManualQuoterEmail__c).Id;
                }
                if (userEmailMap.containsKey(q.FirstQuoterEmail__c) && q.FirstQuoterEmail__c.contains('@xometry.com')) {
                    q.FirstQuoterUser__c = userEmailMap.get(q.FirstQuoterEmail__c).Id;
                }
            }
        }
    }

    /**
     * @description queue up NYOP cases that need to be updated
     * @param quoteList Quote from trigger
     */
    public static void updateNYOPCases(List<Quote_ERP__C> newQuoteList) {
        //Que up some Case Updates for NYOP
        if (!nyopCasesToUpdate.isEmpty()) {
            updateNYOPCaseQue updater = new updateNYOPCaseQue(nyopCasesToUpdate);
            System.enqueueJob(updater);
            nyopCasesToUpdate.clear();
        }
    }
}