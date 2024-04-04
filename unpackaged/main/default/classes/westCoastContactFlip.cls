/**
 * Async Queueable class to flip a given Account's Contacts to the West Coast BDR
 */
public class westCoastContactFlip implements Queueable {
    static final String WEST_COAST_CONTACT_FLIP_METHOD_NOTE = 'westCoastContactFlip.execute';
    static final String WEST_COAST_CONTACT_FLIP_CONTACT_DEV_NOTE = 'West Coast Contact Flip has failed';
    static final String WEST_COAST_CONTACT_FLIP_OPP_DEV_NOTE = 'West Coast Opportunity Flip has failed';

    ID WestCoastOwnerID;
    Set<ID> contactIDSet = new Set<ID>();

    /**
     * @description enqueued job for changing all BDR owned contacts for a given Account
     * @param reassignedAccountIDSet list of IDs for Accounts which are now owned by the West Coast BDR
     */
    public westCoastContactFlip(Set<ID> reassignedAccountIDSet, ID westCoastBDR) {
        // select all BDR owned contacts for a given account
        List<Contact> BDRContacts = [
            SELECT ID
            FROM Contact
            WHERE AccountId IN :reassignedAccountIDSet AND Owner.UserRole.Name = :AppConstants.BDR_NAME
        ];

        // put West Coast ID and Contact ID in map
        for (Contact c : BDRContacts) {
            WestCoastOwnerID = westCoastBDR;
            contactIDSet.add(c.ID);
        }
    }

    public void execute(QueueableContext context) {
        List<Contact> updatedContactList = [SELECT ID, OwnerID FROM Contact WHERE ID IN :contactIDSet];

        for (Contact c : updatedContactList) {
            c.OwnerID = WestCoastOwnerID;
        }

        List<Opportunity> opportunityList = [
            SELECT ID, OwnerId
            FROM Opportunity
            WHERE
                StageName NOT IN ('Closed Won', 'Closed Lost')
                AND PRIMARY_CONTACT__C IN :contactIDSet
                AND Owner.UserRole.Name = :AppConstants.BDR_NAME
        ];

        for (Opportunity opp : opportunityList) {
            opp.OwnerId = WestCoastOwnerID;
        }

        List<Project__c> projectList = [
            SELECT ID, OwnerId, Primary_Contact__c
            FROM Project__c
            WHERE
                Stage__c NOT IN ('Closed Won', 'Closed Lost')
                AND Primary_Contact__c IN :contactIDSet
                AND Owner.UserRole.Name = :AppConstants.BDR_NAME
        ];

        for (Project__c p : projectList) {
            p.OwnerId = WestCoastOwnerID;
        }

        DatabaseUtilities.saveToDatabase(
            updatedContactList,
            WEST_COAST_CONTACT_FLIP_METHOD_NOTE,
            WEST_COAST_CONTACT_FLIP_CONTACT_DEV_NOTE
        );
        DatabaseUtilities.saveToDatabase(
            opportunityList,
            WEST_COAST_CONTACT_FLIP_METHOD_NOTE,
            WEST_COAST_CONTACT_FLIP_OPP_DEV_NOTE
        );
        DatabaseUtilities.saveToDatabase(
            projectList,
            WEST_COAST_CONTACT_FLIP_METHOD_NOTE,
            WEST_COAST_CONTACT_FLIP_CONTACT_DEV_NOTE
        );
    }
}