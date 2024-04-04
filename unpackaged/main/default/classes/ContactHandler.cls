public with sharing class ContactHandler {
    public static Set<String> genericEmailDomains = LeadHandler.getGenericDomains();
    //The original LeadSource at the start of Contact Creation is important for driving various decisions
    public static Set<String> originalCPCLeadSourceSet = new Set<String>();
    public static Set<String> contactsWithLeadsToConvertEmailSet = new Set<String>();

    public static void primaryEmailPop(List<Contact> inNewContactList) {
        for (Contact c : inNewContactList) {
            if (String.isBlank(c.Email)) {
                c.Email = c.Primary_Email__c;
            }
            else if (c.Email != c.Primary_Email__c) {
                c.Primary_Email__c = c.Email;
            }
        }
    }

    /**
     * @description Set all Contacts being created with the LeadSourcevalue of CPC to CPC house user
     * @param inNewContactList new contacts to be inserted
     */
    public static void cpcLeadSource(List<Contact> inNewContactList) {
        for (Contact con : inNewContactList) {
            if (con.LeadSource == 'CPC' ||
                    (con.OwnerId == AppConstants.CPC_HOUSE_USER && con.LeadSource == 'Registered User')) {
                con.OwnerId = AppConstants.CPC_HOUSE_USER;
                originalCPCLeadSourceSet.add(con.Primary_Email__c);
            }
        }
    }
    /**
     * @description adds the supplier lookup when a new user is created with a partner id
     * @param newContactList new contacts to be inserted
     */
    public static void newSupplierUser(List<Contact> newContactList) {
        Set<String> partnerIdSet = new Set<String>();

        for (Contact c : newContactList) {
            if (!String.isBlank(c.GNO_PartnerId__c)) {
                partnerIdSet.add(c.GNO_PartnerId__c);
            }
        }
        Map<String, Supplier__c> supplierMap = SupplierUtility.fetchSuppliers(partnerIdSet);

        for (Contact c : newContactList) {
            if (supplierMap.containsKey(c.GNO_PartnerId__c)) {
                Supplier__c s = supplierMap.get(c.GNO_PartnerId__c);
                c.AccountId = s.AccountID__c;
                c.Supplier__c = s.Id;
                c.OwnerId = AppConstants.GNO_HOUSE_USER;
            }
        }
    }

    /**
     * @description If the contact owner changes independently of downstream inserts downstream event
     * @param newContactList Updated contact List
     * @param oldContactMap Old contact map
     */
    public static void contactDownstream(List<Contact> newContactList, Map<Id, Contact> oldContactMap) {
        if (!EventBusBypass.isByPassed('contactDownstream')) {
            List<Downstream_Event__e> downstreamEvents = new List<Downstream_Event__e>();

            for (Contact a : newContactList) {
                Contact oldContact = oldContactMap.get(a.Id);
                if (oldContact.OwnerId != a.OwnerId) {
                    Downstream_Event__e e = new Downstream_Event__e();
                    e.SourceId__c = a.Id;
                    e.OldOwner__c = oldContact.OwnerId;
                    e.NewOwner__c = a.OwnerId;
                    e.Object__c = 'Contact';
                    downstreamEvents.add(e);
                }
            }
            EventBus.publish(downstreamEvents);
        }
    }
    /**
     * @description method to associate a contact to a new account
     * @param contactNeedingAccount contact which need new accounts
     * @return accounts to create
     */

    private static List<Account> contactToNewAccount(List<Contact> contactNeedingAccount) {
        List<Account> accountsToCreateList = new List<Account>();
        Map<String, Account> accountsToCreateMap = new Map<String, Account>();
        Set<String> newContactEmail = new Set<String>();
        Set<String> acctDomainMainSet = new Set<String>();
        Map<String, Account> existingAccountDomains = new Map<String, Account>();
        String custEmail;
        String emailDomain;
        for (Contact c : contactNeedingAccount) {
            if (!String.isBlank(c.Primary_Email__c)) {
                newContactEmail.add(c.Primary_Email__c);
                emailDomain = c.Primary_Email__c.substring(c.Primary_Email__c.indexOf('@') + 1);
                System.debug('Custom Domain: ' + emailDomain);
                if (genericEmailDomains.contains(emailDomain)) {
                    acctDomainMainSet.add(c.Primary_Email__c.toLowerCase());
                } else {
                    acctDomainMainSet.add(emailDomain.toLowerCase());
                }
            }
        }
        existingAccountDomains = accountEmailDomain(acctDomainMainSet);
        //Checking existing leads
        Map<String, Lead> existingLeadMap = QuoteERPHandler.fetchExistingLeadsMap(newContactEmail);

        for (Contact c : contactNeedingAccount) {
            if (c.AccountId == null && !String.isBlank(c.Primary_Email__c)) {
                Account a = new Account();
                a.Account_Owner_Type__c = 'BDR';
                a.RR_Flag__c = true;
                custEmail = c.Primary_Email__c;
                emailDomain = custEmail.substring(custEmail.indexOf('@') + 1);
                Boolean addToInsert = true;
                if (genericEmailDomains.contains(emailDomain)) {
                    a.Generic_Account__c = true;
                    c.Generic_Contact__c = true;
                    a.Name = c.Primary_Email__c;
                    //custEmail = c.Primary_Email__c;
                    a.Email_Domain__c = c.Primary_Email__c;
                    if (
                        existingAccountDomains.size() > 0 && existingAccountDomains.containsKey(custEmail.toLowerCase())
                    ) {
                        c.OwnerId = existingAccountDomains.get(custEmail.toLowerCase()).OwnerId;
                        c.AccountId = existingAccountDomains.get(custEmail.toLowerCase()).Id;
                        addToInsert = false;
                    } else {
                        if (!existingLeadMap.isEmpty()) {
                            if (
                                existingLeadMap.containsKey(c.Primary_Email__c) &&
                                existingLeadMap.get(c.Primary_Email__c).OwnerId != AppConstants.API_USER &&
                                existingLeadMap.get(c.Primary_Email__c).OwnerId != AppConstants.SALES_API_USER
                            ) {
                                c.OwnerId = existingLeadMap.get(c.Primary_Email__c).OwnerId;
                            }
                        }
                    }
                } else {
                    a.Generic_Account__c = false;
                    c.Generic_Contact__c = false;
                 //   custEmail = c.Primary_Email__c;
                    if (custEmail.indexOf('@') > 0) {
                        emailDomain = custEmail.substring(custEmail.indexOf('@') + 1);
                        a.Email_Domain__c = emailDomain.toLowerCase();
                        a.Name = emailDomain;
                        if (
                            existingAccountDomains.size() > 0 &&
                            existingAccountDomains.containsKey(emailDomain.toLowerCase())
                        ) {
                            c.OwnerId = existingAccountDomains.get(emailDomain.toLowerCase()).OwnerId;
                            c.AccountId = existingAccountDomains.get(emailDomain.toLowerCase()).Id;
                            addToInsert = false;
                        } else {
                            if (!existingLeadMap.isEmpty()) {
                                if (
                                    existingLeadMap.containsKey(emailDomain) &&
                                    existingLeadMap.get(emailDomain).OwnerId != AppConstants.API_USER &&
                                    existingLeadMap.get(emailDomain).OwnerId != AppConstants.SALES_API_USER
                                ) {
                                    c.OwnerId = existingLeadMap.get(emailDomain).OwnerId;
                                }
                            }
                        }
                    }
                }
                //Move CPC Leadsource Contacts back to the CPC House
                if (originalCPCLeadSourceSet.contains(c.Primary_Email__c)) {
                    c.OwnerId = AppConstants.CPC_HOUSE_USER;
                    a.OwnerId = AppConstants.CPC_HOUSE_USER;
                    a.RR_Flag__c = false;
                }
                if (addToInsert == true) {
                    accountsToCreateMap.put(a.Email_Domain__c, a);
                }
            }
        }
        accountsToCreateList.addAll(accountsToCreateMap.values());

        return accountsToCreateList;
    }
    /**
     * @description method to Process association of a contact to a new account and Round robin them when it's
     * required.
     * @param newContactList contact list to determine which need new accounts
     */

    public static void processContactToNewAccount(List<Contact> newContactList) {
        List<Contact> contactNeedingAccount = new List<Contact>();
        Set<Id> createdAccountNonGenericRRIDs = new Set<Id>();
        Set<Id> createdAccountGenericRRIDs = new Set<Id>();
        Set<Id> createdAccountIDSet = new Set<Id>();
        for (Contact c : newContactList) {
            if (String.isBlank(c.AccountId)) {
                contactNeedingAccount.add(c);
            }
        }
        List<Account> accountList = new List<Account>();
        if (!contactNeedingAccount.isEmpty()) {
            accountList = contactToNewAccount(contactNeedingAccount);
        }

        DatabaseUtilities.insertToDatabase(accountList, 'ContactHandler', 'Non Generic Account Inserts');
        String custEmail;
        String custDomain;
        for (Account a : accountList) {
            if (a.Id != null) {
                createdAccountIDSet.add(a.Id);
                if (a.RR_Flag__c) {
                    if (a.Generic_Account__c) {
                        createdAccountGenericRRIDs.add(a.Id);
                    } else {
                        createdAccountNonGenericRRIDs.add(a.Id);
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
            //Take the Success List and Get Account IDs, OwnerIDs and the Domain and Assign OwnerID to Contact
            //Map the Accounts to Domain
            Map<String, Account> allAccountsDomainMap = new Map<String, Account>();
            for (Account a : [
                SELECT Id, Name, Email_Domain__c, OwnerId
                FROM Account
                WHERE Id IN :createdAccountIDSet
                WITH SECURITY_ENFORCED
            ]) {
                allAccountsDomainMap.put(a.Email_Domain__c, a);
            }
            // Post Account Creation Add the Newly Created Accounts to the Contacts
            for (Contact c : contactNeedingAccount) {
                custEmail = c.Primary_Email__c;
                custDomain = custEmail.substring(custEmail.indexOf('@') + 1);
                if (genericEmailDomains.contains(custDomain)) {
                    if (allAccountsDomainMap.containsKey(c.Primary_Email__c)) {
                        c.OwnerId = allAccountsDomainMap.get(c.Primary_Email__c).OwnerId;
                        c.AccountId = allAccountsDomainMap.get(c.Primary_Email__c).Id;
                    }
                } else {
                    if (allAccountsDomainMap.containsKey(custDomain)) {
                        c.OwnerId = allAccountsDomainMap.get(custDomain).OwnerId;
                        c.AccountId = allAccountsDomainMap.get(custDomain).Id;
                    }
                }
            }
        }
    }
    /**
     * @description when Drift creates a Contact if there is a matching account ensure the Contact Owner matches the Account Owner
     */
    public static void driftContactAccountMatching(List<Contact> newContactList) {
        List<Contact> driftContacts = new List<Contact>();
        Set<Id> accountToFetchIDSet = new Set<Id>();
        for (Contact con : newContactList) {
            if (con.LeadSource == 'Drift' && String.isNotBlank(con.AccountId)) {
                driftContacts.add(con);
                accountToFetchIDSet.add(con.AccountId);
            }
        }
        if (!driftContacts.isEmpty()) {
            Map<Id, Account> existingAccountMap = new Map<Id, Account>(
                [SELECT Id, OwnerId FROM Account WHERE Id IN :accountToFetchIDSet]
            );
            for (Contact con : driftContacts) {
                if (existingAccountMap.containsKey(con.AccountId)) {
                    con.OwnerId = existingAccountMap.get(con.AccountId).OwnerId;
                }
            }
        }
    }
    /** @param acctDomainSet Email that search a existing account domain that match with contact email
     * accountEmailDomain retrieve information for existing account using the contact email domain.
     */

    private static Map<String, Account> accountEmailDomain(Set<String> acctDomainSet) {
        Map<String, Account> acctRetMap = new Map<String, Account>();
        for (Account a : [
            SELECT Id, Name, Email_Domain__c, OwnerId
            FROM Account
            WHERE Email_Domain__c = :acctDomainSet AND Generic_Account__c = FALSE
            WITH SECURITY_ENFORCED
        ]) {
            if (!String.isBlank(a.Email_Domain__c)) {
                String lCaseEmailDomain = a.Email_Domain__c.toLowerCase();
                acctRetMap.put(lCaseEmailDomain, a);
            }
        }
        return acctRetMap;
    }

    /**
     * @description take the lead source and generated by sales values from the preexisting lead
     * @param newContactList Email that search a existing Lead match with contact email
     */

    public static void checkLeadSource(List<Contact> newContactList) {
        Map<String, Contact> newContactPrimaryEmailMap = new Map<String, Contact>();
        for (Contact newContact : newContactList) {
            if (!String.isBlank(newContact.Primary_Email__c)) {
                newContactPrimaryEmailMap.put(newContact.Primary_Email__c, newContact);
            }
        }

        Map<String, Lead> existingLeadMap = QuoteERPHandler.fetchExistingLeadsMap(newContactPrimaryEmailMap.keySet());

        if (!existingLeadMap.isEmpty()) {
            for (String email : existingLeadMap.keySet()) {
                newContactPrimaryEmailMap.get(email).LeadSource = existingLeadMap.get(email).LeadSource;

                if (existingLeadMap.get(email).Generated_by_Sales__c == 'TRUE') {
                    newContactPrimaryEmailMap.get(email).Generated_by_Sales__c = existingLeadMap.get(email)
                        .Generated_by_Sales__c;
                }
                if (
                    existingLeadMap.get(email).LeadSource == 'Drift' ||
                    existingLeadMap.get(email).LeadSource == 'Intercom' ||
                    (originalCPCLeadSourceSet.contains(email))
                ) {
                    contactsWithLeadsToConvertEmailSet.add(email);
                }
            }
        }
    }

    /**
     * @description take any Contacts inserted with an email that matches a lead and Convert that lead
     * @param newContactList New Contacts that have been inserted
     */
    public static void checkForContactToConvert(List<Contact> newContactList) {
        List<Database.LeadConvert> dbLeadConvertList = new List<Database.LeadConvert>();
        if (!contactsWithLeadsToConvertEmailSet.isEmpty()) {
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
            Map<String, Contact> emailContactMap = new Map<String, Contact>();
            for (Contact con : newContactList) {
                emailContactMap.put(con.Email, con);
            }
            //Fetch Leads to be converted
            //Create the DB converter for Leads
            for (Lead l : [
                    SELECT Id, Primary_Email__c
                    FROM Lead
                    WHERE Primary_Email__c IN :contactsWithLeadsToConvertEmailSet AND IsConverted = FALSE
            ]) {
                if (emailContactMap.containsKey(l.Primary_Email__c)) {
                    Contact myContact = emailContactMap.get(l.Primary_Email__c);
                    Database.LeadConvert l_dbLeadConvert = new Database.LeadConvert();
                    l_dbLeadConvert.setConvertedStatus(convertStatus.MasterLabel);
                    l_dbLeadConvert.setLeadId(l.Id);
                    l_dbLeadConvert.setOwnerId(myContact.OwnerId);
                    l_dbLeadConvert.setAccountId(myContact.AccountId);
                    l_dbLeadConvert.setContactId(myContact.Id);
                    l_dbLeadConvert.setDoNotCreateOpportunity(true);
                    dbLeadConvertList.add(l_dbLeadConvert);
                }
            }
        }
        if (!dbLeadConvertList.isEmpty()) {
            DatabaseUtilities.leadConvert(
                dbLeadConvertList,
                'ContactHandler.checkForContactToConvert',
                'Contact Dev Convert'
            );
        }
    }

    /**
     * @description If a contact's primary email contains a generic domain,
     * mark the contact as generic
     * @param contacts contact List
    */
    public static void markIfGenericContact(List<Contact> contacts) {
        for(Contact c : contacts){
            if(String.isNotBlank(c.Primary_Email__c)){
                String emailDomain = c.Primary_Email__c.substring(c.Primary_Email__c.indexOf('@') + 1);
                if (genericEmailDomains.contains(emailDomain)) {
                    c.Generic_Contact__c = true;
                }
            }
        }
    }
}