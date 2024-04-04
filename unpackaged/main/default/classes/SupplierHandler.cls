public with sharing class SupplierHandler {
    static final ID ACCOUNTCUSTOMERRECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Customer')
        .getRecordTypeID();

    static final ID CASESUPPLIERONBOARDRECORDTYPEID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get('Supplier_Onboarding')
        .getRecordTypeID();

    static final String METHOD_NAME = 'SupplierHandler.processSuppliers';
    static final String CREATE_ACCOUNTS_DEV_NOTE = 'Account Creation post Supplier Load';
    static final String CREATE_CONTACTS_DEV_NOTE = 'Contact Creation post Supplier Load';
    static final String UPDATE_ACCOUNTS_DEV_NOTE = 'Update Supplier Account Fields ';
    static final String UPDATE_CONTACTS_DEV_NOTE = 'Update Supplier Contact Fields';
    public static Set<String> genericEmailDomains = LeadHandler.getGenericDomains();
    /**
     * @description method that does the core of processing creating/updating all objects associated with Suppliers
     * @param newSupplierList list of newly inserted Suppliers
     */
    public static void processSuppliers(List<Supplier__C> newSuppliersList) {
        Set<String> newSupplierIDSet = new Set<String>();
        // Lookup Existing Contacts
        Set<String> newSupplierPrimaryEmailSet = new Set<String>();
        Set<String> newSupplierAccountDomainSet = new Set<String>();
        Set<String> newSupplierAccountNameSet = new Set<String>();
        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        Map<String, Account> existingAccountMap = new Map<String, Account>();

        for (Supplier__c s : newSuppliersList) {
            newSupplierIDSet.add(s.PartnerID__c);
            newSupplierPrimaryEmailSet.add(s.EmailAddress__c);

            //No blank domains so check for generics and determine if the email needs a generic flag
            if (string.isBlank(s.AccountDomain__c) && !string.isblank(s.EmailAddress__c)) {
                String custDomain = s.EmailAddress__c.substring(s.EmailAddress__c.indexOf('@') + 1);
                if (genericEmailDomains.contains(custDomain)) {
                    s.AccountDomain__c = s.EmailAddress__c.toLowerCase();
                    s.IsGeneric__c = true;
                } else {
                    s.AccountDomain__c = custDomain.toLowerCase();
                    s.IsGeneric__c = false;
                }
            }
            if (!String.isBlank(s.AccountDomain__c)) {
                newSupplierAccountDomainSet.add(s.AccountDomain__c.toLowerCase());
            }
            if (!String.isBlank(s.SupplierCompanyName__c)) {
                newSupplierAccountNameSet.add(s.SupplierCompanyName__c);
            }
        }

        existingContactMap = fetchSupplierContacts(newSupplierPrimaryEmailSet);
        existingAccountMap = fetchSupplierAccounts(newSupplierAccountDomainSet);

        List<Supplier__c> contactsToCreateSuppliersList = new List<Supplier__c>();
        List<Supplier__c> accountsToCreateSuppliersList = new List<Supplier__c>();
        Set<Contact> contactsToCreateSet = new Set<Contact>();
        // Check if Contact exists or Account Exists
        for (Supplier__c s : newSuppliersList) {
            s.OwnerID = AppConstants.GNO_HOUSE_USER;
            if (existingContactMap.containsKey(s.EmailAddress__c)) {
                s.ContactID__C = existingContactMap.get(s.EmailAddress__c).ID;
                s.AccountID__C = existingContactMap.get(s.EmailAddress__c).AccountID;
            } else if (existingAccountMap.containsKey(s.AccountDomain__c)) {
                // Check if Account exists to Create Contact List
                s.AccountID__C = existingAccountMap.get(s.AccountDomain__c).ID;
                contactsToCreateSet.add(createContact(s));
                contactsToCreateSuppliersList.add(s);
            } else {
                // Account and Contact does not exist
                accountsToCreateSuppliersList.add(s);
            }
        }

        Map<String, Account> allAccountsDomainMap = createNewAccounts(
            accountsToCreateSuppliersList,
            newSupplierAccountNameSet
        );

        // Post Account Creation Add the Newly Created Account to the Supplier and the newAccountNewContactSet

        for (Supplier__c s : accountsToCreateSuppliersList) {
            if (allAccountsDomainMap.containsKey(s.AccountDomain__c)) {
                //OWNER ID
                s.OwnerID = AppConstants.GNO_HOUSE_USER;
                s.AccountID__C = allAccountsDomainMap.get(s.AccountDomain__c).ID;

                //Create a new Contact for each newly created Account
                contactsToCreateSet.add(createContact(s));
                contactsToCreateSuppliersList.add(s);
            }
        }
        //Create Contacts

        Map<String, Contact> insertedContactMap = createNewContacts(contactsToCreateSet);

        for (Supplier__c s : contactsToCreateSuppliersList) {
            if (insertedContactMap.containsKey(s.EmailAddress__c)) {
                s.ContactID__C = insertedContactMap.get(s.EmailAddress__c).ID;
            }
        }

        updateSupplierFlagExistingAccounts(newSupplierAccountDomainSet, newSuppliersList);
        updateContacts(newSupplierPrimaryEmailSet, newSuppliersList);
    }

    /**
     * @description method to associate a supplier to a new account
     * @param suppliersNeedingAccounts list of suppliers which need new accounts
     * @param accountNameSet set of all existing account names
     */
    public static Map<String, Account> createNewAccounts(
        List<Supplier__c> suppliersNeedingAccounts,
        Set<String> accountNameSet
    ) {
        List<Account> accountsToCreateList = new List<Account>();
        Set<String> accountEmailsOrDomains = new Set<String>();
        Map<String, Account> accountsToCreateMap = new Map<String, Account>();

        for (Supplier__c s : suppliersNeedingAccounts) {
            if (
                (s.IsGeneric__c == true && !accountEmailsOrDomains.contains(s.EmailAddress__c)) ||
                (s.IsGeneric__c == false && !accountEmailsOrDomains.contains(s.AccountDomain__c))
            ) {
                Account a = new Account();
                a.OwnerId = AppConstants.GNO_HOUSE_USER;
                a.RecordtypeID = ACCOUNTCUSTOMERRECORDTYPEID;
                a.Account_Owner_Type__c = 'Ops';
                a.generic_account__c = s.IsGeneric__c;
                a.Email_Domain__c = s.AccountDomain__c;
                a.ERP_Billing_Address__c = s.Address__c;
                a.ERP_Billing_City__c = s.City__c;
                a.ERP_Billing_Country__c = s.Country__c;
                // state is commented out because data in ERP is abbreviated
                a.ERP_Billing_State_or_Province__c = s.State__c;
                a.ERP_Billing_Zip_Code__c = s.ZipCode__c;
                a.ERP_Shipping_Address__c = s.Address__c;
                a.ERP_Shipping_City__c = s.City__c;
                a.ERP_Shipping_Country__c = s.Country__c;
                // state is commented out because data in ERP is abbreviated
                a.ERP_Shipping_State_or_Province__c = s.State__c;
                a.ERP_Shipping_Zip_Code__c = s.ZipCode__c;
                a.IsSupplier__c = true;
                a.GNO_PartnerId__c = s.PartnerID__c;

                if (
                    !string.isBlank(s.SupplierCompanyName__c) &&
                    !accountNameSet.contains(s.SupplierCompanyName__C.toUpperCase())
                ) {
                    a.name = s.SupplierCompanyName__C;
                } else {
                    a.name = s.AccountDomain__c;
                }
                accountsToCreateMap.put(a.Email_Domain__c, a);
            }
        }

        accountsToCreateList.addAll(accountsToCreateMap.values());
        //Insert the Accounts
        if (accountsToCreateList.size() > 0) {
            // Create Accounts that don't exist in the system
            DatabaseUtilities.insertToDatabase(accountsToCreateList, METHOD_NAME, CREATE_ACCOUNTS_DEV_NOTE);
        }

        Map<String, Account> allAccountsDomainMap = new Map<String, Account>();
        for (Account a : accountsToCreateList) {
            if (a.ID != null) {
                allAccountsDomainMap.put(a.Email_Domain__C, a);
            }
        }

        return allAccountsDomainMap;
    }

    /**
     * @description creates a contact
     * @param s Supplier__c object for creating a new contact
     * @return c newly created Contact object
     */
    public static Contact createContact(Supplier__c s) {
        Contact c = new Contact();
        c.OwnerId = AppConstants.GNO_HOUSE_USER;
        if (!String.isBlank(s.LastName__c)) {
            c.LastName = s.LastName__c;
        } else {
            c.LastName = s.EmailAddress__c;
        }
        if (!String.isBlank(s.Phone__c)) {
            c.Phone = s.Phone__c;
            c.ERP_Contact_Phone__C = s.Phone__c;
        }
        c.FirstName = s.FirstName__c;
        c.Xometry_ERP_Contact_ID__C = s.ERPContact__c;
        c.Email = s.EmailAddress__c;
        c.Primary_Email__C = s.EmailAddress__c;
        c.OwnerID = AppConstants.GNO_HOUSE_USER;
        c.AccountID = s.AccountID__C;
        c.ERP_Shipping_Address__c = s.Address__c;
        c.ERP_Shipping_City__c = s.City__c;
        c.ERP_Shipping_Country__c = s.Country__c;
        // state is commented out because data in ERP is abbreviated
        c.ERP_Shipping_State_or_Province__c = s.State__c;
        c.ERP_Shipping_Zip_Code__c = s.ZipCode__c;
        c.IsSupplier__c = true;
        c.Partner__c = true;
        c.GNO_PartnerID__c = s.PartnerID__c;
        c.LeadSource = 'Partner';
        return c;
    }

    /**
     * @description fetches all contacts in the system that match incoming supplier emails
     * @param newSupplierPrimaryEmailSet set of to be inserted supplier emails
     * @return map of supplier contacts in the organization with email as key
     */
    public static Map<String, Contact> fetchSupplierContacts(Set<String> newSupplierPrimaryEmailSet) {
        List<Contact> existingContactList = [
            SELECT ID, AccountID, OwnerID, Phone, Primary_Email__C
            FROM Contact
            WHERE Primary_Email__C IN :newSupplierPrimaryEmailSet
        ];
        Map<String, Contact> existingContactMap = new Map<String, Contact>();
        for (Contact c : existingContactList) {
            existingContactMap.put(c.Primary_Email__C, c);
        }

        return existingContactMap;
    }
    /**
     * @description fetches all accounts in the system that match incoming supplier domains
     * @param newSupplierAccountDomainSet set of to be inserted supplier domains
     * @return map of supplier accounts in the organization with email as key
     */
    public static Map<String, Account> fetchSupplierAccounts(Set<String> newSupplierAccountDomainSet) {
        Map<String, Account> existingAccountMap = new Map<String, Account>();

        if (!newSupplierAccountDomainSet.isEmpty()) {
            for (Account a : [
                SELECT ID, Email_Domain__c, OwnerID
                FROM Account
                WHERE Email_Domain__c IN :newSupplierAccountDomainSet
            ]) {
                existingAccountMap.put(a.Email_Domain__c, a);
            }
        }

        return existingAccountMap;
    }

    /**
     * @description updates existing accounts that are not a supplier and flags it as a supplier
     * @param newSupplierAccountDomainSet set of to be inserted supplier domains
     * @param newSuppliersList list of suppliers to insert
     */
    public static void updateSupplierFlagExistingAccounts(
        Set<String> newSupplierAccountDomainSet,
        List<Supplier__c> newSuppliersList
    ) {
        if (!newSupplierAccountDomainSet.isEmpty()) {
            //Check for Existing Accounts and checks off that they are a partner
            Map<String, Account> updateAccountMatchMap = new Map<String, Account>();
            for (Account a : [
                SELECT ID, Email_Domain__c, IsSupplier__c, GNO_PartnerId__c
                FROM Account
                WHERE Email_Domain__c IN :newSupplierAccountDomainSet AND GNO_PartnerId__c = NULL
            ]) {
                updateAccountMatchMap.put(a.Email_Domain__C, a);
            }

            Map<String, Account> updateAccountMatchUpdateMap = new Map<String, Account>();
            for (Supplier__c s : newSuppliersList) {
                if (updateAccountMatchMap.containsKey(s.AccountDomain__c)) {
                    Account a = updateAccountMatchMap.get(s.AccountDomain__c);
                    a.IsSupplier__c = true;
                    a.GNO_PartnerID__c = s.PartnerID__c;
                    updateAccountMatchUpdateMap.put(a.Email_Domain__c, a);
                }
            }
            List<Account> updateAccountMatchUpdateList = new List<Account>(updateAccountMatchUpdateMap.values());
            //Update some Accounts
            // Create Contacts that don't exist in the system
            if (updateAccountMatchUpdateList.size() > 0) {
                DatabaseUtilities.saveToDatabase(updateAccountMatchUpdateList, METHOD_NAME, UPDATE_ACCOUNTS_DEV_NOTE);
            }
        }
    }

    /**
     * @description updates existing contacts and flags it as a supplier
     * @param newSupplierPrimaryEmailSet set of to be inserted supplier Emails
     * @param newSuppliersList list of suppliers to insert
     */

    public static void updateContacts(Set<String> newSupplierPrimaryEmailSet, List<Supplier__c> newSuppliersList) {
        //Check for Existing Contacts that are not marked as partner

        Map<String, Contact> updateContactMatchMap = new Map<String, Contact>();
        for (Contact c : [
            SELECT ID, Primary_Email__C, IsSupplier__c, GNO_PartnerID__c, ERP_Contact_Phone__C
            FROM Contact
            WHERE Primary_Email__C IN :newSupplierPrimaryEmailSet
        ]) {
            updateContactMatchMap.put(c.Primary_Email__C, c);
        }

        List<Contact> updateContactMatchUpdateList = new List<Contact>();
        Map<String, Contact> updateContactMatchMapUpdateMap = new Map<String, Contact>();
        for (Supplier__c s : newSuppliersList) {
            if (updateContactMatchMap.containsKey(s.EmailAddress__c)) {
                Contact c = updateContactMatchMap.get(s.EmailAddress__c);
                Boolean updated = false;
                if (c.IsSupplier__c == false) {
                    c.IsSupplier__c = true;
                    c.GNO_PartnerID__c = s.PartnerID__c;
                    updated = true;
                }
                if (String.isBlank(c.GNO_PartnerID__c)) {
                    c.GNO_PartnerID__c = s.PartnerID__C;
                    updated = true;
                }
                //always update phone field
                if (!String.isBlank(s.Phone__c)) {
                    if (String.isBlank(c.ERP_Contact_Phone__C) || (!c.ERP_Contact_Phone__C.equals(s.Phone__C))) {
                        c.ERP_Contact_Phone__C = s.Phone__C;
                        updated = true;
                    }
                }

                //always update address fields if the address and either state or zipcode are not null and either address or city are not null
                if (
                    (!String.isBlank(s.Address__c) || !String.isBlank(s.City__c)) &&
                    (!String.isBlank(s.State__c) || !String.isBlank(s.ZipCode__c))
                ) {
                    c.ERP_Shipping_Address__C = s.Address__c;
                    c.ERP_Shipping_City__c = s.City__c;
                    c.ERP_Shipping_Country__c = s.Country__c;
                    // state is commented out because data in ERP is abbreviated
                    c.ERP_Shipping_State_or_Province__c = s.State__c;
                    c.ERP_Shipping_Zip_Code__c = s.ZipCode__c;
                    updated = true;
                }
                if (updated) {
                    //No duplicates with Map
                    updateContactMatchMapUpdateMap.put(c.Primary_Email__C, c);
                }
            }
        }

        //Update some Contacts
        updateContactMatchUpdateList.addAll(updateContactMatchMapUpdateMap.values());
        if (updateContactMatchUpdateList.size() > 0) {
            DatabaseUtilities.saveToDatabase(updateContactMatchUpdateList, METHOD_NAME, UPDATE_CONTACTS_DEV_NOTE);
        }
    }

    /**
     * @description inserts contacts to database
     * @param contactsToCreateSet Set of contacts not in the system
     * @return Map of contacts inserted
     */

    public static Map<String, Contact> createNewContacts(Set<Contact> contactsToCreateSet) {
        Set<String> primaryEmailCreateSet = new Set<String>();
        Set<Contact> allContactToCreateSet = new Set<Contact>();

        for (Contact c : contactsToCreateSet) {
            if (!primaryEmailCreateSet.contains(c.Primary_Email__C)) {
                primaryEmailCreateSet.add(c.Primary_Email__C);
                allContactToCreateSet.add(c);
            }
        }

        List<Contact> contactsToCreateList = new List<Contact>();
        Map<String, Contact> insertedContactMap = new Map<String, Contact>();
        contactsToCreateList.addAll(allContactToCreateSet);
        // Create Contacts that don't exist in the system
        if (contactsToCreateList.size() > 0) {
            DatabaseUtilities.insertToDatabase(contactsToCreateList, METHOD_NAME, CREATE_CONTACTS_DEV_NOTE);
        }

        for (Contact c : contactsToCreateList) {
            if (c.Id != null) {
                insertedContactMap.put(c.Primary_Email__C, c);
            }
        }

        return insertedContactMap;
    }

    /**
     * @description On Supplier update last job read date updates when job offers increase from old value
     * @param newSuppliersList new suppliers List coming in via the update Trigger's Trigger.new
     * @param oldSuppliersMap old suppliers Map that exist via the update Trigger's Trigger.oldMap
     */

    public static void updateActivityStatus(List<Supplier__c> newSuppliersList, Map<Id, Supplier__c> oldSuppliersMap) {
        for (Supplier__c s : newSuppliersList) {
            if (s.JobOffersRead__c > oldSuppliersMap.get(s.Id).JobOffersRead__c) {
                s.LastReadJobDate__c = Date.today();
            }
        }
    }

    /**
     * @description Creates Case and Update Supplier OnboardingParentCase__c
     * @param newSupplierList List of new suppliers Inserted
     */

    public static void onboardingParentCaseCreation(List<Supplier__C> newSupplierList) {
        Date lastUpdateSince = Date.newInstance(2021, 5, 1);

        Set<Id> registeredSupliers = new Set<Id>();
        for (Supplier__c s : newSupplierList) {
            Boolean cond1 = s.SupplierStatus__c == 'registered';
            Boolean cond2 = s.DateApproved__c == null;
            Boolean cond3 = s.SupplierStatusLastUpdated__c > lastUpdateSince;

            if (cond1 && cond2 && cond3) {
                registeredSupliers.add(s.Id);
            }
        }

        if (!registeredSupliers.isEmpty()) {
            //Supplier Onboarding Parent Case Creation
            List<Case> newCases = new List<Case>();
            for (Id supplierId : registeredSupliers) {
                Case newCase = new Case();
                newCase.Origin = 'Internal';
                newCase.RecordtypeID = CASESUPPLIERONBOARDRECORDTYPEID;
                newCase.Status = 'New';
                newCase.Subject = 'Supplier Onboarding Parent Case';
                newCase.Supplier__c = supplierId;
                newCases.add(newCase);
            }

            DatabaseUtilities.upsertToDatabase(
                newCases,
                'SupplierHandler.onboardingParentCaseCreation',
                'Supplier Onboarding Parent Case Creation'
            );

            //Update Supplier With Parent Case Id

            List<Supplier__c> existingSuppliers = new List<Supplier__c>();
            for (Case createdCase : newCases) {
                Supplier__c supplier = new Supplier__c(Id = createdCase.Supplier__c);
                supplier.OnboardingParentCase__c = createdCase.Id;
                existingSuppliers.add(supplier);
            }

            DatabaseUtilities.upsertToDatabase(
                existingSuppliers,
                'SupplierHandler.onboardingParentCaseCreation',
                'Update Supplier With Parent Case Id'
            );
        }
    }

    /**
     * @description updates Contact with Supplier Id
     * @param newSupplierList List of new suppliers Inserted
     */

    public static void updateContactWithSupplierId(List<Supplier__C> newSupplierList) {
        Map<Id, Contact> existingContactsMap = new Map<Id, Contact>();
        for (Supplier__c s : newSupplierList) {
            if (s.ContactId__c != null) {
                Contact existingContact = new Contact(Id = s.ContactId__c, Supplier__c = s.Id, Partner__c = true);
                existingContactsMap.put(s.ContactId__c, existingContact);
            }
        }
        DatabaseUtilities.saveToDatabase(
            existingContactsMap.values(),
            'SupplierHandler.updateContactWithSupplierId',
            'supplier updates supplier id on Contact'
        );
    }

    /**
     * @description updates Contact and Account according to Supplier changes
     * @param newSupplierList List of new suppliers updates
     * @param oldSuppliersMap Map of old suppliers values
     */
    public static void updateObjectsFromSupplierChanges(
        List<Supplier__C> newSupplierList,
        Map<Id, Supplier__c> oldSuppliersMap
    ) {
        Map<String, String[]> fieldsFromSupplierToContactMap = new Map<String, String[]>{
            'LastName__c' => new List<String>{ 'LastName' },
            'FirstName__c' => new List<String>{ 'FirstName' },
            'EmailAddress__c' => new List<String>{ 'Email', 'Primary_Email__C' },
            'Phone__c' => new List<String>{ 'Phone', 'ERP_Contact_Phone__C' },
            'Address__c' => new List<String>{ 'ERP_Shipping_Address__c' },
            'City__c' => new List<String>{ 'ERP_Shipping_City__c' },
            'Country__c' => new List<String>{ 'ERP_Shipping_Country__c' },
            'ZipCode__c' => new List<String>{ 'ERP_Shipping_Zip_Code__c' },
            'State__c' => new List<String>{ 'ERP_Shipping_State_or_Province__c' }
        };

        Map<String, String[]> fieldsFromSupplierToAccountMap = new Map<String, String[]>{
            'AccountDomain__c' => new List<String>{ 'Name', 'Email_Domain__c' },
            'SupplierCompanyName__C' => new List<String>{ 'Name' },
            'IsGeneric__c' => new List<String>{ 'generic_account__c' },
            'Address__c' => new List<String>{ 'ERP_Billing_Address__c', 'ERP_Shipping_Address__c' },
            'City__c' => new List<String>{ 'ERP_Billing_City__c', 'ERP_Shipping_City__c' },
            'Country__c' => new List<String>{ 'ERP_Billing_Country__c', 'ERP_Shipping_Country__c' },
            'ZipCode__c' => new List<String>{ 'ERP_Billing_Zip_Code__c', 'ERP_Shipping_Zip_Code__c' },
            'State__c' => new List<String>{ 'ERP_Shipping_State_or_Province__c' }
        };

        Map<Id, Account> existingAccountsMap = new Map<Id, Account>();
        Map<Id, Contact> existingContactsMap = new Map<Id, Contact>();

        for (Supplier__c s : newSupplierList) {
            if (s.ContactId__c != null) {
                //Get fields with different values and send changes to Contacts
                for (String supplierFieldName : fieldsFromSupplierToContactMap.keySet()) {
                    if (
                        s.get(supplierFieldName) != null &&
                        s.get(supplierFieldName) != oldSuppliersMap.get(s.Id).get(supplierFieldName)
                    ) {
                        for (String contactFieldName : fieldsFromSupplierToContactMap.get(supplierFieldName)) {
                            if (!existingContactsMap.containsKey(s.ContactId__c)) {
                                existingContactsMap.put(s.ContactId__c, new Contact(Id = s.ContactId__c));
                            }
                            existingContactsMap.get(s.ContactId__c).put(contactFieldName, s.get(supplierFieldName));
                        }
                    }
                }
            }

            if (s.AccountId__c != null) {
                //Get fields with different values and send changes to Account
                for (String supplierFieldName : fieldsFromSupplierToAccountMap.keySet()) {
                    if (
                        s.get(supplierFieldName) != null &&
                        s.get(supplierFieldName) != oldSuppliersMap.get(s.Id).get(supplierFieldName)
                    ) {
                        for (String accountFieldName : fieldsFromSupplierToAccountMap.get(supplierFieldName)) {
                            Boolean validToUpdateField = true;

                            //validations before update
                            if (
                                accountFieldName == 'Name' &&
                                (supplierFieldName != 'SupplierCompanyName__C' &&
                                !String.isBlank(s.SupplierCompanyName__C))
                            ) {
                                validToUpdateField = false;
                            }

                            if (validToUpdateField) {
                                if (!existingAccountsMap.containsKey(s.AccountId__c)) {
                                    existingAccountsMap.put(s.AccountId__c, new Account(Id = s.AccountId__c));
                                }
                                existingAccountsMap.get(s.AccountId__c).put(accountFieldName, s.get(supplierFieldName));
                            }
                        }
                    }
                }
            }
        }

        if (!existingAccountsMap.isEmpty()) {
            Account[] acc2update = new List<Account>{};
            for (Account acc : [
                SELECT Id
                FROM Account
                WHERE Id = :existingAccountsMap.keySet() AND OwnerId = :AppConstants.GNO_HOUSE_USER
            ]) {
                acc2update.add(existingAccountsMap.get(acc.Id));
            }

            DatabaseUtilities.saveToDatabase(
                acc2update,
                'SupplierHandler.updateObjectsFromSupplierChanges',
                'supplier updates fields on Account'
            );
        }

        if (!existingContactsMap.isEmpty()) {
            Contact[] con2update = new List<Contact>{};
            for (Contact con : [
                SELECT Id
                FROM Contact
                WHERE Id = :existingContactsMap.keySet() AND OwnerId = :AppConstants.GNO_HOUSE_USER
            ]) {
                con2update.add(existingContactsMap.get(con.Id));
            }

            DatabaseUtilities.saveToDatabase(
                con2update,
                'SupplierHandler.updateObjectsFromSupplierChanges',
                'supplier updates fields on Contact'
            );
        }
    }

    /**
     * @description updates Jobs with their current SPOC Owner
     * @param newSupplierList List of new suppliers updates
     * @param oldSuppliersMap Map of old suppliers values
     */
    public static void keepSPOCInSync(List<Supplier__C> newSupplierList, Map<Id, Supplier__c> oldSuppliersMap) {
        Map<ID, Set<String>> suppliersWithUpdatedSPOCInfoMap = new Map<ID, Set<String>>();
        Map<ID, ID> supplierToSPOCOwnerMap = new Map<ID, ID>();

        String newSPOCSupplierString = 'New SPOC Supplier';
        String spocOwnerChangeString = 'New SPOC Owner';

        for (Supplier__c s : newSupplierList) {
            Boolean newSPOCSupplier = s.SPOC_Supplier__c && !oldSuppliersMap.get(s.Id).SPOC_Supplier__c;
            Boolean spocOwnerChange =
                s.SPOC_Owner__c != null && (s.SPOC_Owner__c != oldSuppliersMap.get(s.Id).SPOC_Owner__c);

            if (newSPOCSupplier || spocOwnerChange) {
                suppliersWithUpdatedSPOCInfoMap.put(s.ID, new Set<String>());
                if (newSPOCSupplier) {
                    suppliersWithUpdatedSPOCInfoMap.get(s.ID).add(newSPOCSupplierString);
                }
                if (spocOwnerChange) {
                    suppliersWithUpdatedSPOCInfoMap.get(s.ID).add(spocOwnerChangeString);
                    supplierToSPOCOwnerMap.put(s.ID, s.SPOC_Owner__c);
                }
            }
        }

        if (!suppliersWithUpdatedSPOCInfoMap.isEmpty()) {
            List<Job__c> jobsToUpdateList = new List<Job__c>();
            for (Job__c job : [
                SELECT ID, Supplier__c, Accepted_by_SPOC_Supplier__c, SPOC_Owner__c
                FROM Job__c
                WHERE
                    Stage__c NOT IN :AppConstants.JOB_COMPLETED_STATUSES
                    AND Supplier__c IN :suppliersWithUpdatedSPOCInfoMap.keySet()
            ]) {
                ID supplierID = job.Supplier__c;
                if (suppliersWithUpdatedSPOCInfoMap.get(supplierID).contains(newSPOCSupplierString)) {
                    job.Accepted_by_SPOC_Supplier__c = true;
                }
                if (suppliersWithUpdatedSPOCInfoMap.get(supplierID).contains(spocOwnerChangeString)) {
                    job.SPOC_Owner__c = supplierToSPOCOwnerMap.get(supplierID);
                }
                jobsToUpdateList.add(job);
            }

            DatabaseUtilities.saveToDatabase(
                jobsToUpdateList,
                'SupplierHandler.keepSPOCInSync',
                'Downstream objects did not get SPOC Updates'
            );
        }
    }
}