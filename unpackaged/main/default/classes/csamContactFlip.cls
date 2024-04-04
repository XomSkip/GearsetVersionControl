global class csamContactFlip implements Database.Batchable<sObject> {
    //CSAM stands for Enterprise Account Manager
    global Integer recordsProcessed = 0;
    static final ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();
    static final String AUDIT_DEV_NOTE = 'Contact Owner Updates for CSAM';
    static final String AUDIT_DEV_NAME = 'csamContactFlip.execute';
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //This query is designed to update Contacts both when a CSAM no longer is on an account team or when they have been added
        return Database.getQueryLocator(
            'Select ID, AccountID, Name, OwnerID, Account.OwnerID, Account.ParentID from Contact where Account.account_owner_type__c = \'AM\'  and Customer_Type__c= \'RETENTION\' and Retention_Exemption__c = false order by AccountID'
        );
    }
    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        integer updateTracker = 0;
        Set<ID> contactIDSet = new Set<ID>();
        Set<ID> accountIDSet = new Set<ID>();
        Set<ID> parentAccountIDSet = new Set<ID>();
        Set<ID> accountAndParentAcctIDSet = new Set<ID>();
        Map<ID, ID> contactToAccountIDMap = new Map<ID, ID>();
        for (Contact c : scope) {
            contactIDSet.add(c.ID);
            accountIDSet.add(c.AccountID);
            if (c.Account.ParentID != null) {
                parentAccountIDSet.add(c.Account.ParentID);
                accountAndParentAcctIDSet.add(c.Account.ParentID);
                contactToAccountIDMap.put(c.ID, c.Account.ParentID);
            } else {
                contactToAccountIDMap.put(c.ID, c.AccountID);
                accountAndParentAcctIDSet.add(c.AccountID);
            }
        }

        Map<ID, Account_Team__C> accountTeamCSAMMap = accountTeamHandler.createAccountTeamCSAMMap(
            accountAndParentAcctIDSet
        );

        List<Contact> updateContactList = new List<Contact>();
        //For the Contact check if the CSAMmember exists and there is a matching owner
        //If no CSAM exists then make sure the contact matches the account owner
        for (Contact c : scope) {
            contact contactToUpdate = new Contact();
            contactToUpdate.ID = c.ID;
            //When an Account has a parent always use the parent AccountID so use the Map from above
            if (contactToAccountIDMap.containsKey(c.ID)) {
                ID lAccountID = contactToAccountIDMap.get(c.ID);

                if (accountTeamCSAMMap.containsKey(lAccountID)) {
                    Account_Team__C atm = accountTeamCSAMMap.get(lAccountID);
                    if (c.OwnerID != atm.Team_Member__c) {
                        contactToUpdate.OwnerID = atm.Team_Member__c;
                        updateContactList.add(contactToUpdate);
                    }
                } else if (c.OwnerID != c.Account.OwnerID) {
                    contactToUpdate.OwnerID = c.Account.OwnerID;
                    updateContactList.add(contactToUpdate);
                }
            }
        }

        if (!updateContactList.isEmpty()) {
            recordsProcessed += updateContactList.size();
            updateTracker += DatabaseUtilities.saveToDatabaseTracking(
                updateContactList,
                AUDIT_DEV_NAME,
                AUDIT_DEV_NOTE
            );
        }

        //Update the Opportunity Owner to be the contacts Owner
        //Get All Opportunities that are Open and Update accordingly
        List<Opportunity> opportunityFetchList = [
            SELECT ID, OWNERID, PRIMARY_CONTACT__C, PRIMARY_CONTACT__R.OWNERID
            FROM Opportunity
            WHERE
                StageName NOT IN ('Closed Won', 'Closed Lost')
                AND PRIMARY_CONTACT__C IN :contactIDSet
                AND RecordTypeId = :oppManufacturingServRTypeID
        ];
        List<Opportunity> opportunityToUpdateList = new List<Opportunity>();
        for (Opportunity opp : opportunityFetchList) {
            if (opp.OWNERID != opp.PRIMARY_CONTACT__R.OWNERID) {
                Opportunity updateOpp = new Opportunity();
                updateOpp.ID = opp.ID;
                updateOpp.OWNERID = opp.PRIMARY_CONTACT__R.OWNERID;
                opportunityToUpdateList.add(updateOpp);
            }
        }

        if (opportunityToUpdateList.size() > 0) {
            recordsProcessed += opportunityToUpdateList.size();
            updateTracker += DatabaseUtilities.saveToDatabaseTracking(
                opportunityToUpdateList,
                AUDIT_DEV_NAME,
                AUDIT_DEV_NOTE
            );
        }

        //Update the Project Owner to be the contacts Owner
        //Get Projects and Update Accordingly
        List<Project__c> projectList = new List<Project__c>(
            [
                SELECT Id, OwnerId, Primary_Contact__c, Primary_Contact__r.OwnerId
                FROM Project__c
                WHERE
                    Primary_Contact__c IN :contactIDSet
                    AND Stage__c NOT IN ('Closed Won', 'Closed Lost')
                    AND Hold_Project_to_Prior_Owner__c = FALSE
            ]
        );
        List<Project__c> projectsToUpdateList = new List<Project__c>();
        for (Project__c thisProject : projectList) {
            if (thisProject.OwnerId != thisProject.Primary_Contact__r.OwnerId) {
                //Project__c updateOpp = new Project__c();
                //updateOpp.Id = opp.Id;
                thisProject.OwnerId = thisProject.Primary_Contact__r.OwnerId;
                projectsToUpdateList.add(thisProject);
            }
        }
        if (projectsToUpdateList.size() > 0) {
            recordsProcessed += projectsToUpdateList.size();
            updateTracker += DatabaseUtilities.saveToDatabaseTracking(
                projectsToUpdateList,
                AUDIT_DEV_NAME,
                AUDIT_DEV_NOTE
            );
        }

        System.debug('Current Records Processed' + recordsProcessed);
        System.debug('The update tracker records for this batch are ' + updatetracker);
    }

    global void finish(Database.BatchableContext bc) {
        //execute any post-processing operations
        //this is uesful for testing with Database.Stateful turning off for production to improve performance
        //System.debug(recordsProcessed + ' records processed. Shazam!');
        System.debug('Finished CSAM processing Shazam!');
    }
}