/**
 * @description Lead Handler adds modification to manually and automatically generated leads
 */
public with sharing class LeadHandler {
    /**
     * @description sets the primary email field on newly inserted Leads
     * @param inNewLeadList List of Lead objects inserted into Salesforce
     */
    public static void primaryEmailPop(List<Lead> inNewLeadList) {
        // Primary_Email__C is the hidden field that is used to enforce uniqueness on Email
        for (Lead l : inNewLeadList) {
            if (String.isblank(l.Email)) {
                l.Email = l.Primary_Email__C;
            } else if (l.Primary_Email__C != l.Email) {
                l.Primary_Email__C = l.Email;
            }
        }
    }

    /**
     * @description After update, fetch all leads that just got converted
     * @param inNewLeadList list of newly inserted leads
     * @param inOldLeadMap map of old leads which were changed
     */
    public static void convertedLeadBucketing(List<Lead> inNewLeadList, Map<ID, Lead> inOldLeadMap) {
        System.debug('Bucketing if after update the lead was just converted');
        List<Lead> leadsToConvertQuotesList = new List<Lead>();

        for (Lead l : inNewLeadList) {
            System.debug('The old Map shows ' + l.id + ' : ' + inOldLeadMap.get(l.id).isConverted);
            System.debug('The new in shows ' + l.id + ' : ' + l.isConverted);
            if (inOldLeadMap.containsKey(l.id)) {
                if (l.isConverted == true && inOldLeadMap.get(l.id).isConverted == false) {
                    leadsToConvertQuotesList.add(l);
                    //For Converted Leads set the Primary Contact on the Opportunity if Not Already Set.
                }
            }
        }
        if (!leadsToConvertQuotesList.isEmpty()) {
            leadConverterCustom.LeadConvertUpdateQuote(leadsToConvertQuotesList);
        }
    }

    /**
     * @description returns a list of quarentined domains
     */
    public static Set<String> getQuarentinedDomains() {
        List<Lead> QuarantinedLeadList = new List<Lead>();
        Set<String> quarantinedDomainSet = new Set<String>();

        List<Email_Domain__mdt> quarantineEmailDomainList = [
            SELECT Email_Domains__C
            FROM Email_Domain__mdt
            WHERE Quarantined_Domains__c = TRUE
        ];

        for (Email_Domain__mdt emdt : quarantineEmailDomainList) {
            quarantinedDomainSet.add(emdt.Email_Domains__C);
        }
        return quarantinedDomainSet;
    }

    /**
     * @description returns a list of generic domains
     */
    public static Set<String> getGenericDomains() {
        Set<String> genericDomainSet = new Set<String>();
        //Generics are stored as custom Metadata Customer Metadata/ Custom Settings
        List<Email_Domain__mdt> genericEmailDomainList = [
            SELECT Email_Domains__C
            FROM Email_Domain__mdt
            WHERE Generic_FLAG__C = TRUE
        ];

        for (Email_Domain__mdt em : genericEmailDomainList) {
            genericDomainSet.add(em.Email_Domains__C);
        }
        return genericDomainSet;
    }

    /**
     * @description Associate lead with Partners and assign account recommendation accordingly
     * @param incomingLeads new Lead being inserted
     */
    public static void partnerMatch(List<Lead> incomingLeads) {
        List<Lead> partnerLeadList = new List<Lead>();
        Set<String> partnerIDSet = new Set<String>();
        for (Lead l : incomingLeads) {
            if (!String.isBlank(l.Partner_ID__c)) {
                partnerLeadList.add(l);
                partnerIDSet.add(l.Partner_ID__c);
            }
        }
        if (!partnerLeadList.isEmpty()) {
            Map<String, Account> acctsWithPartnerId = new Map<String, Account>();
            for (Account a : [
                SELECT ID, GNO_PartnerID__c, Name, Email_Domain__C, OwnerId, Generic_Account__c
                FROM Account
                WHERE GNO_PartnerID__c IN :partnerIDSet
            ]) {
                if (!String.isBlank(a.GNO_PartnerID__c)) {
                    acctsWithPartnerId.put(a.GNO_PartnerID__c, a);
                }
            }
            for (Lead l : partnerLeadList) {
                Account a = acctsWithPartnerId.get(l.Partner_ID__c);
                l.AccountMatchMethod__c = 'Partner ID';
                l.Recommended_Account_LKP__c = a.Id;
                l.Recommended_Account__c = a.name;
                l.RR_Flag__C = false;
                l.Email_Domain__C = a.Email_Domain__C;
                l.OwnerId = a.OwnerId;
                l.Generic_FLAG__C = a.Generic_Account__c;
            }
        }
    }

    /**
     * @description Checks if the leads Domain matches a Quarantine Domian and sets the lead match to Qurantine
     * @param incomingLeads new Lead being inserted
     */

    public static void quarantineCheck(List<Lead> incomingLeads) {
        List<Lead> quarantineLeadList = new List<Lead>();
        Set<String> quarantinedDomainSet = getQuarentinedDomains();
        for (Lead l : incomingLeads) {
            //nCheck if the domain is on the quarentined set
            if (quarantinedDomainSet.contains(l.Email_Domain__C.toLowerCase())) {
                quarantineLeadList.add(l);
            }
        }
        if (!quarantineLeadList.isEmpty()) {
            Group QuarantinedQueue = [
                SELECT ID, Name
                FROM Group
                WHERE type = 'Queue' AND name = 'Quarantined Email Domains'
            ];
            ID QuarantinedQueueID = QuarantinedQueue.ID;
            for (Lead l : quarantineLeadList) {
                l.OwnerID = QuarantinedQueueID;
                l.RR_Flag__C = false;
                l.Domain_Match_Flag__C = true;
                l.Automation_Routing__c = AppConstants.LEAD_QUARANTINE;
            }
        }
    }

    /**
     * @description Apply special routing rules based on LeadSource
     * Note this method sets the Generic Flag on Leads!
     * @param incomingLeads all leads just added via insert
     */

    public static void specialLeadRules(List<Lead> incomingLeads) {
        //2. Drift Check For Leadsource Drift Do some generic checks
        Set<String> genericDomainSet = getGenericDomains();

        // Check for leasdsource that Need Generic Checks
        Set<String> genericLeadSourceCheckSet = new Set<String>();
        genericLeadSourceCheckSet.add('CAS Referral');
        genericLeadSourceCheckSet.add('Chat');
        genericLeadSourceCheckSet.add('Cold Prospect');
        genericLeadSourceCheckSet.add('Design Guide Download');
        genericLeadSourceCheckSet.add('Drift');
        genericLeadSourceCheckSet.add('Google AdWords');
        genericLeadSourceCheckSet.add('Lead Gen');
        genericLeadSourceCheckSet.add('Other');
        genericLeadSourceCheckSet.add('Purchased List');
        genericLeadSourceCheckSet.add('Newsletter');
        genericLeadSourceCheckSet.add('Quoter');
        genericLeadSourceCheckSet.add('Trade Show');
        genericLeadSourceCheckSet.add('Webinar');
        genericLeadSourceCheckSet.add('Zendesk Support');
        genericLeadSourceCheckSet.add('Zoominfo');
        genericLeadSourceCheckSet.add('F360');
        genericLeadSourceCheckSet.add('Sales Generated');
        genericLeadSourceCheckSet.add('Registered User');
        genericLeadSourceCheckSet.add('Organic search');
        genericLeadSourceCheckSet.add('Paid search');
        genericLeadSourceCheckSet.add('Organic Social');
        genericLeadSourceCheckSet.add('Referrals');
        genericLeadSourceCheckSet.add('Other campaigns');
        genericLeadSourceCheckSet.add('Direct traffic');
        genericLeadSourceCheckSet.add('Offline sources');
        genericLeadSourceCheckSet.add('Paid Social');
        genericLeadSourceCheckSet.add('Thomas');
        genericLeadSourceCheckSet.add('Outreach');
        genericLeadSourceCheckSet.add('Data Migration');
        genericLeadSourceCheckSet.add('CPC');

        List<Lead> nonQuarantineLeadList = new List<Lead>();
        for (Lead l : incomingLeads) {
            if (l.Automation_Routing__c != AppConstants.LEAD_QUARANTINE) {
                nonQuarantineLeadList.add(l);
            }
        }
        for (Lead l : nonQuarantineLeadList) {
            if (String.isBlank(l.leadsource) || genericLeadSourceCheckSet.contains(l.leadsource)) {
                //Round Robin if the user is API ADMIN otherwise let the user submitting the field dictate round robin.
                if (l.OwnerID == AppConstants.API_USER) {
                    l.RR_Flag__C = true;
                }
                //For Drift Leads trust the Owner provided by Drift and Do not roundrobin.
                //Still perform generic and domain checks
                // If the owner is API ADMIN then still round robin testing change for IDEA-499
                if (
                    (l.leadsource == 'Drift' || l.LeadSource == 'Outreach' || l.LeadSource == 'Zoominfo') &&
                    l.OwnerID != AppConstants.API_USER
                ) {
                    l.RR_Flag__C = false;
                }
                if (genericDomainSet.contains(l.Email_Domain__C)) {
                    l.Generic_FLAG__C = true;
                    l.Email_Domain__C = l.email;
                }
            }
        }
    }

    /**
     * @description Apply special routing rules based on LeadSource
     * Note this method sets the Generic Flag on Leads!
     * @param incomingLeads all leads just added via insert
     * @param leadDomainMatchFlag allows the matching logic of Leads based on other Leads to be turned off independent of the upstream account check
     */

    public static void domainMatching(List<Lead> incomingLeads, Boolean leadDomainMatchFlag) {
        Set<String> acctDomainSet = new Set<String>();
        //3 and 4 Check Domain against existing Domains for Accounts and Leads
        List<Lead> leadNonGenericNonQuoterList = new List<Lead>();
        for (Lead l : incomingLeads) {
            //Check for leadsource Don't Apply for Leadsource Quoter and Only Non Generics
            //l.LeadSource !='Quoter'
            if (
                l.Automation_Routing__c != AppConstants.LEAD_QUARANTINE &&
                l.Generic_FLAG__c == false &&
                String.isBlank(l.AccountMatchMethod__c)
            ) {
                leadNonGenericNonQuoterList.add(l);
            }
        }
        for (Lead l : leadNonGenericNonQuoterList) {
            if (l.Email_Domain__C != null) {
                //Check if Domain is not null if it is not null extract out Domain
                acctDomainSet.add(l.Email_Domain__C);
            }
        }
        if (!acctDomainSet.isEmpty()) {
            // Get Accounts with Domains and Owner Set If found then
            Map<String, Account> acctRetMap = new Map<String, Account>();

            // Grab all accounts matching domains of newly entered leads
            for (Account a : [
                SELECT ID, Name, Email_Domain__C, OwnerID
                FROM Account
                WHERE Email_Domain__C IN :acctDomainSet AND Generic_Account__C = FALSE
            ]) {
                if (!String.isBlank(a.Email_Domain__C)) {
                    String lCaseEmailDomain = a.Email_Domain__C.toLowerCase();
                    acctRetMap.put(lCaseEmailDomain, a);
                }
            }

            Map<String, Lead> lNoAcctDomainMatchMap = new Map<String, Lead>();
            for (Lead l : leadNonGenericNonQuoterList) {
                if (acctRetMap.containsKey(l.Email_Domain__C)) {
                    System.debug('Domain Matched!');
                    Account a = acctRetMap.get(l.Email_Domain__C);
                    l.Recommended_Account__c = a.Name;
                    //Lookup to Account

                    l.Email_Domain__C = a.Email_Domain__C;
                    l.Domain_Match_Flag__C = true;
                    l.Recommended_Account_LKP__C = a.ID;
                } else {
                    //No Match create a new domain set for Leads
                    lNoAcctDomainMatchMap.put(l.Email_Domain__C, l);
                }
            }

            if (!lNoAcctDomainMatchMap.isEmpty() && leadDomainMatchFlag) {
                //Check Existing Leads for Domain Match. If true then Create
                //Can have more than one Email_Domain Match so use first return for each
                //Check for a Match with the Lead Domains

                Map<String, Lead> leadRetMap = new Map<String, Lead>();
                for (Lead l : [
                    SELECT ID, OwnerID, Email_Domain__C
                    FROM Lead
                    WHERE
                        Email_Domain__C IN :lNoAcctDomainMatchMap.keySet()
                        AND isConverted = FALSE
                        AND Email_Domain__C != NULL
                    ORDER BY CreatedDate DESC
                ]) {
                    lNoAcctDomainMatchMap.get(l.Email_Domain__C).OwnerID = l.OwnerID;
                    lNoAcctDomainMatchMap.get(l.Email_Domain__C).RR_Flag__C = false;
                    lNoAcctDomainMatchMap.get(l.Email_Domain__C).Domain_Match_Flag__C = true;
                }
            }
        }
    }

    /**
     * @description Associates a lead to a quarentine set or searches domain to see if generic
     * @param incomingLeads all leads just added via insert
     */
    public static void smartDomainLKP(List<Lead> incomingLeads) {

        Map<Id,List<Lead>> userOwnerLeadsMap = new Map<Id,List<Lead>>();

        for (Lead l : incomingLeads) {

            if (l.LeadSource == 'Outreach' || l.LeadSource == 'Zoominfo') {

                l.RR_Flag__C = false;
                l.Ultimate_Created_By__c = l.OwnerId;

            } else {

                l.Ultimate_Created_By__c = UserInfo.getUserId();

            }

            //Check if Domain is not null -- if it is extract out Domain
            if (String.isBlank(l.Email_Domain__C)) {
                String custEmail = l.Email;
                if ( !String.isBlank(custEmail) && custEmail.indexOf('@') > 0 ) {
                    String custDomain = custEmail.substring(custEmail.indexOf('@') + 1);
                    l.Email_Domain__C = custDomain.toLowerCase();
                }
            } else {
                l.Email_Domain__C = l.Email_Domain__C.toLowerCase();
            }

            //Mapping owners and LeadIds
            if( !userOwnerLeadsMap.containsKey(l.OwnerId) ){
                userOwnerLeadsMap.put( l.OwnerId, new List<Lead>() );
            }
            userOwnerLeadsMap.get(l.OwnerId).add(l);

        }

        //Getting user info from mapped Owners and assign User Role to Leads
        if( !userOwnerLeadsMap.isEmpty() ){

            for(User userOwner : [SELECT Id, UserRole.Name FROM User WHERE Id IN : userOwnerLeadsMap.keySet()]){

                for( Lead l : userOwnerLeadsMap.get( userOwner.Id ) ){
                    l.Ultimate_Created_By_Role__c = userOwner.UserRole.Name;
                }

            }

        }

    }
    /**
     * @description centering Account classification to one picklist,
     * this trigger runs before insert and set the initial value.
     *
     * @param newLeadList - List with triggered accounts new values
     */

    public static void setClasification(List<Lead> newLeadList) {
        for (Lead l : newLeadList) {
            if (l.Generic_FLAG__c) {
                l.Account_Classification__c = 'Generic';
            }
            if (l.Generic_BDR_RR_FLAG__c) {
                l.Account_Classification__c = 'BDR';
            }
        }
    }

    /**
     * @description Sets the DNB DUNS number if populated from Hubspot
     * @param newLeadList - New leads
     */
    public static void setDUNS(List<Lead> newLeadList) {
        for (Lead l : newLeadList) {
            if (!String.isBlank(l.HubspotDUNSNumber__c)) {
                l.DnB_Connect_DUNS__c = l.HubspotDUNSNumber__c;
                if (l.Generic_FLAG__c) {
                    l.Email_Domain__c = l.Email;
                }
                l.Generic_FLAG__c = false;
            }
        }
    }

    /**
     * @description Do not let ‘xometry.com’ be the domain on any Lead.
     *
     * @param newLeadList - List with triggered Leads new values
     */
    public static void cleanDomain(List<Lead> newLeadList) {
        for (Lead l : newLeadList) {
            if (l.Email_Domain__C == 'xometry.com') {
                l.Email_Domain__C = null;
            }
        }
    }

    /**
     * @description When the Recommended_Account is updated, the fields related to the Account in the Lead are updated too
     *
     * @param inNewLeadMap map of newly inserted leads
     * @param inOldLeadMap map of old leads which were changed
     */
    public static void updateRecommendedAccount(Map<ID, Lead> inNewLeadMap, Map<ID, Lead> inOldLeadMap) {
        Map<ID, String> mapChangeRecommendedAccount = new Map<ID, String>();
        Map<ID, String> mapChangeRecommendedAccountLKP = new Map<ID, String>();
        Map<ID, Account> mapAccountsID = new Map<ID, Account>();
        Map<String, Account> mapAccountsName = new Map<String, Account>();
        for (Lead newLead : inNewLeadMap.values()) {
            Lead oldLead = inOldLeadMap.get(newLead.Id);
            if (
                newLead.Recommended_Account__c != oldLead.Recommended_Account__c &&
                newLead.Recommended_Account__c != null &&
                newLead.Recommended_Account_LKP__c == null
            ) {
                mapChangeRecommendedAccount.put(newLead.Id, newLead.Recommended_Account__c);
            } else if (
                newLead.Recommended_Account_LKP__c != oldLead.Recommended_Account_LKP__c &&
                newLead.Recommended_Account_LKP__c != null
            ) {
                mapChangeRecommendedAccountLKP.put(newLead.Id, newLead.Recommended_Account_LKP__c);
            }
        }

        for (Account a : [
            SELECT ID, GNO_PartnerID__c, Name, Email_Domain__C, OwnerId, Generic_Account__c
            FROM Account
            WHERE Id IN :mapChangeRecommendedAccountLKP.values() OR Name IN :mapChangeRecommendedAccount.values()
        ]) {
            mapAccountsID.put(a.Id, a);
            mapAccountsName.put(a.Name, a);
        }

        for (Id idleadChangeRecommendedAccount : mapChangeRecommendedAccount.keySet()) {
            Lead newLead = inNewLeadMap.get(idleadChangeRecommendedAccount);
            Account objAccount = mapAccountsName.get(mapChangeRecommendedAccount.get(idleadChangeRecommendedAccount));
            if (objAccount != null) {
                newLead.Recommended_Account__c = objAccount.name;
                newLead.Recommended_Account_LKP__c = objAccount.Id;
                newLead.Email_Domain__C = objAccount.Email_Domain__C;
                newLead.Generic_FLAG__C = objAccount.Generic_Account__c;
                newLead.OwnerId = objAccount.OwnerId;
            }
        }

        for (Id idleadChangeRecommendedAccountLKP : mapChangeRecommendedAccountLKP.keySet()) {
            Lead newLead = inNewLeadMap.get(idleadChangeRecommendedAccountLKP);
            Account objAccount = mapAccountsID.get(
                mapChangeRecommendedAccountLKP.get(idleadChangeRecommendedAccountLKP)
            );
            if (objAccount != null) {
                newLead.Recommended_Account__c = objAccount.name;
                newLead.Recommended_Account_LKP__c = objAccount.Id;
                newLead.Email_Domain__C = objAccount.Email_Domain__C;
                newLead.Generic_FLAG__C = objAccount.Generic_Account__c;
                newLead.OwnerId = objAccount.OwnerId;
            }
        }
    }

    /**
     * @description resolving value When the Company field is blank or would be [not Provided]
     * @param newLeadList new Leads to be inserted
     */
    public static void fillCompanyRecommended(List<Lead> inNewLeadList) {
        for (Lead c : inNewLeadList) {
            if (
                String.isBlank(c.Company) ||
                c.Company.containsIgnoreCase('not provided') ||
                c.Company.containsIgnoreCase('Sent from Intercom')
            ) {
                if (!String.isBlank(c.Marketing_Recommended_Company__c)) {
                    c.Company = c.Marketing_Recommended_Company__c;
                } else {
                    c.Company = c.Email_Domain__c;
                }
            }
        }
    }
}