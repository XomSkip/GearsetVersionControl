/**
 * @author jelf-alter
 * @date 2020-4-2
 *
 * @description LTV Handler for the LTV (Lifetime Value) Trigger ensures loaded LTV is properly associated to
 * related Contacts with null LTV values
 */
public with sharing class LtvHandler {
    static final String ASSOCIATE_CONTACT_METHOD_NAME = 'LtvHelper.associateContact';
    static final String ASSOCIATE_CONTACT_DEV_NOTE = 'Contact Updates post LTV Load';
    static final String ASSOCIATE_ACCOUNT_METHOD_NAME = 'LtvHelper.associateAccount';
    static final String ASSOCIATE_ACCOUNT_DEV_NOTE = 'Account Updates post LTV Load';
    static final String ASSOCIATE_RECORD_TYPE_METHOD_NAME = 'LtvHelper.associateRecordType';
    static final String ASSOCIATE_RECORD_TYPE_DEV_NOTE = 'LTV assigned Record Type ID';

    static final ID accountRecordTypeId = Schema.SObjectType.LTV__c.getRecordTypeInfosByDeveloperName()
        .get('Account_LTV')
        .getRecordTypeID();
    static final ID contactRecordTypeId = Schema.SObjectType.LTV__c.getRecordTypeInfosByDeveloperName()
        .get('Contact_LTV')
        .getRecordTypeID();

    /**
     * @description Associates ltv objects to a contact object. Updates the contact object.
     * @param addedLtv List of LTV objects inserted into Salesforce
     */
    public static void associateContact(List<LTV__c> addedLtv) {
        List<Contact> contactUpdateList = getContactUpdateList(addedLtv);
        DatabaseUtilities.saveToDatabase(contactUpdateList, ASSOCIATE_CONTACT_METHOD_NAME, ASSOCIATE_CONTACT_DEV_NOTE);
    }

    /**
     * @description Updates RecordTypeId on LTV objects.
     * @param addedLtv List of LTV objects to be inserted into Salesforce
     */
    public static void associateRecordType(List<LTV__c> addedLtv) {
        for (LTV__c ltv : addedLtv) {
            if (String.isNotBlank(ltv.Account_Domain__c)) {
                ltv.RecordTypeId = accountRecordTypeId;
            } else {
                ltv.RecordTypeId = contactRecordTypeId;
            }
        }
    }

    /**
     * @description Retrieves all contacts with null LTV values and matching email to new LTV to be updated
     * by the newly added Ltv values.
     * @param addedLtv List of LTV objects inserted into Salesforce.
     * @return List of updated Contacts with newly associated LTV values
     */
    public static List<Contact> getContactUpdateList(List<LTV__c> addedLtv) {
        Set<String> newLtvSet = new Set<String>();

        for (LTV__c l : addedLtv) {
            if (l.RecordTypeId == contactRecordTypeId) {
                newLtvSet.add(l.Customer_Email__c);
            }
        }

        List<Contact> contactUpdateList = new List<Contact>();

        if (!newLtvSet.isEmpty()) {
            Map<String, LTV__c> ltvMap = new Map<String, LTV__c>();
            Set<Contact> contactsToUpdate = new Set<Contact>();

            for (LTV__c ltv : addedLtv) {
                ltvMap.put(ltv.Customer_Email__c, ltv);
            }

            for (Contact c : [
                SELECT Primary_Email__c, LTV__c
                FROM Contact
                WHERE email IN :newLtvSet AND LTV_LKP__c = NULL
            ]) {
                if (ltvMap.containsKey(c.Primary_Email__c)) {
                    LTV__c con_ltv = ltvMap.get(c.Primary_Email__c);
                    c.LTV_LKP__c = con_ltv.id;
                    contactsToUpdate.add(c);
                }
            }

            contactUpdateList.addAll(contactsToUpdate);
        }

        return contactUpdateList;
    }

    /**
     * @description Retrieves all accounts with null LTV values and matching domain to new LTV to be updated
     * by the newly added Ltv values.
     * @param addedLtv List of LTV objects inserted into Salesforce.
     */
    public static void associateAccount(List<LTV__c> addedLtv) {
        Map<String, LTV__c> ltvMap = new Map<String, LTV__c>();

        for (LTV__c l : addedLtv) {
            if (l.RecordTypeId == accountRecordTypeId) {
                ltvMap.put(l.Account_Domain__c, l);
            }
        }

        if (!ltvMap.isEmpty()) {
            List<Account> accountFetchList = [
                SELECT Email_Domain__c, LTV__c
                FROM Account
                WHERE Email_Domain__c IN :ltvMap.keySet() AND LTV_LKP__c = NULL
            ];

            Set<Account> accountsToUpdate = new Set<Account>();
            List<Account> accountUpdateList = new List<Account>();

            for (Account a : accountFetchList) {
                if (ltvMap.containsKey(a.Email_Domain__c)) {
                    LTV__c acc_ltv = ltvMap.get(a.Email_Domain__c);
                    a.LTV_LKP__c = acc_ltv.id;
                    accountsToUpdate.add(a);
                }
            }

            accountUpdateList.addAll(accountsToUpdate);
            DatabaseUtilities.saveToDatabase(
                accountUpdateList,
                ASSOCIATE_ACCOUNT_METHOD_NAME,
                ASSOCIATE_ACCOUNT_DEV_NOTE
            );
        }
    }
}