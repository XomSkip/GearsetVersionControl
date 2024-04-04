global class LeadConvertToContactBatchJob implements Database.Batchable<sObject> {
    String batchQuery = ' SELECT Id, Primary_Email__c, Email_Domain__c, CreatedDate, Generated_by_Sales__c, LeadSource FROM Lead WHERE IsConverted = FALSE';
    LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];

    public LeadConvertToContactBatchJob(String whereClause) {
        if (!String.isEmpty(whereClause)) {
            batchQuery += ' AND ( ' + whereClause + ') ';
        }
        batchQuery += ' ORDER BY CreatedDate ASC';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(batchQuery);
    }

    global void execute(Database.BatchableContext BC, list<Lead> leadList) {
        Map<Id, List<Database.LeadConvert>> leadsToConvertMap = new Map<Id, List<Database.LeadConvert>>();
        Map<String, List<Lead>> emailLeadsMap = new Map<String, List<Lead>>();
        Map<String, Id> checkAccountDomains = new Map<String, Id>();
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();

        //Getting all Lead emails to compare against Contacts
        for (Lead l : leadList) {
            if (!String.isBlank(l.Primary_Email__c)) {
                if (!emailLeadsMap.containsKey(l.Primary_Email__c)) {
                    emailLeadsMap.put(l.Primary_Email__c, new List<Lead>());
                }
                emailLeadsMap.get(l.Primary_Email__c).add(l);

                if (!String.isBlank(l.Email_Domain__c)) {
                    checkAccountDomains.put(l.Email_Domain__c, null);
                }
            }
        }

        //Mapping Accounts by unique Domain to avoid error assigning same value to another Account with null Domain
        if (!checkAccountDomains.isEmpty()) {
            for (Account acc : [
                SELECT Id, Email_Domain__c
                FROM Account
                WHERE Email_Domain__c = :checkAccountDomains.keySet()
            ]) {
                checkAccountDomains.put(acc.Email_Domain__c, acc.Id);
            }
        }

        Map<Id, Contact> contactsToUpdateMap = new Map<Id, Contact>();
        List<Lead> lstUpdate = new List<Lead>();

        //Quering contacts and sending matching leads to convert
        for (Contact c : [
            SELECT Account.Email_Domain__c, Email, CreatedDate, Generated_by_Sales__c, OwnerId, Owner.isActive
            FROM Contact
            WHERE Email IN :emailLeadsMap.keySet()
        ]) {
            for (Lead l : emailLeadsMap.get(c.Email)) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.Id);
                lc.setAccountId(c.AccountId);
                lc.setContactId(c.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                lc.setDoNotCreateOpportunity(true);

                if(c.Owner.isActive)
                {
                    lc.setOwnerID(c.OwnerId);
                }
                else
                {
                    l.ownerId = c.OwnerId;
                    lstUpdate.add(l);
                    lc.setOwnerID(AppConstants.SALES_API_USER);
                }

                if (
                    c.Account.Email_Domain__c != null ||
                    !checkAccountDomains.containsKey(l.Email_Domain__c) ||
                    checkAccountDomains.get(l.Email_Domain__c) == c.AccountId
                ) {
                    leadsToConvert.add(lc);
                }

                if (!contactsToUpdateMap.containsKey(c.Id) && c.CreatedDate > l.CreatedDate) {
                    c.LeadSource = l.LeadSource;

                    if (c.Generated_by_Sales__c == 'FALSE' && l.Generated_by_Sales__c == 'TRUE') {
                        c.Generated_by_Sales__c = l.Generated_by_Sales__c;
                        contactsToUpdateMap.put(c.Id, c);
                    }
                }
            }
        }

        DatabaseUtilities.leadConvert(
            leadsToConvert,
            'LeadConvertToContactBatchJob',
            'Convert Lead to Matching Contact'
        );

        DatabaseUtilities.saveToDatabase(
            contactsToUpdateMap.values(),
            'LeadConvertToContactBatchJob',
            'Update Contact with older Lead info'
        );

        DatabaseUtilities.saveToDatabase(
            lstUpdate,
            'LeadConvertToContactBatchJob',
            'Update inactive owner Lead'
        );
    }

    global void finish(Database.BatchableContext BC) {
    }
}