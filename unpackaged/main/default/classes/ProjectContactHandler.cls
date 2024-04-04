public with sharing class ProjectContactHandler {
    static final String UPDATE_PRIMARY_METHOD_NAME = 'ProjectContactHandler.updatePrimaryContact';
    static final String SAVE_CONTACT_JUNCTION_DEV_NOTE = 'Did not save new Contact Project Junction';
    static final String SAVE_PROJECT_UPDATE_DEV_NOTE = 'Did not save updated Primary Contact to Project';

    /**
     * @description updates the Primary Contact on Project on Update
     * @param inJunctionList List of newly updated project contact junctions
     */
    public static void updatePrimaryContact(List<Project_Contact__c> inJunctionList) {
        List<Id> updatedProjects = new List<Id>();
        List<Id> junctionUpdateIds = new List<Id>();
        Map<Id, Id> primaryProjectContactMap = new Map<Id, Id>();

        for (Project_Contact__c pc : inJunctionList) {
            if (pc.Primary__c == true) {
                updatedProjects.add(pc.Project__c);
                junctionUpdateIds.add(pc.Id);
                primaryProjectContactMap.put(pc.Project__c, pc.Contact__c);
            }
        }

        if (!updatedProjects.isEmpty()) {
            List<Project__c> saveProjectUpdate = new List<Project__c>();
            for (Project__c p : [SELECT Id, Primary_Contact__c FROM Project__c WHERE Id IN :updatedProjects]) {
                p.Primary_Contact__c = primaryProjectContactMap.get(p.Id);
                saveProjectUpdate.add(p);
            }

            DatabaseUtilities.upsertToDatabase(
                saveProjectUpdate,
                UPDATE_PRIMARY_METHOD_NAME,
                SAVE_PROJECT_UPDATE_DEV_NOTE
            );

            List<Project_Contact__c> updatedPrimary = new List<Project_Contact__c>();
            for (Project_Contact__c opc : [
                SELECT Id, Primary__c
                FROM Project_Contact__c
                WHERE Id NOT IN :junctionUpdateIds AND Project__C IN :updatedProjects AND Primary__c = TRUE
            ]) {
                opc.Primary__c = false;
                updatedPrimary.add(opc);
            }

            DatabaseUtilities.upsertToDatabase(
                updatedPrimary,
                UPDATE_PRIMARY_METHOD_NAME,
                SAVE_CONTACT_JUNCTION_DEV_NOTE
            );
        }
    }

    /**
     * @description updates the Primary Contact on Project on Insert
     * @param inJunctionList List of newly inserted project contact junctions
     */
    public static void insertNewPrimaryJunction(List<Project_Contact__c> inJunctionList) {
        List<Project_Contact__c> updatedPrimary = new List<Project_Contact__c>();
        Set<Id> newPrimaries = new Set<Id>();
        List<Id> alteredProjectIds = new List<Id>();
        Map<Id, Id> projectNewPrimaryContactMap = new Map<Id, Id>();

        for (Project_Contact__c pc : inJunctionList) {
            if (pc.Primary__c == true) {
                newPrimaries.add(pc.Id);
                alteredProjectIds.add(pc.Project__c);
                projectNewPrimaryContactMap.put(pc.Project__c, pc.Contact__c);
            }
        }

        if (!alteredProjectIds.isEmpty()) {
            List<Project__c> saveProjectUpdate = new List<Project__c>();
            for (Project__c p : [SELECT Id, Primary_Contact__c FROM Project__c WHERE Id IN :alteredProjectIds]) {
                if (p.Primary_Contact__c != projectNewPrimaryContactMap.get(p.Id)) {
                    p.Primary_Contact__c = projectNewPrimaryContactMap.get(p.Id);
                    saveProjectUpdate.add(p);
                }
            }

            DatabaseUtilities.saveToDatabase(
                saveProjectUpdate,
                UPDATE_PRIMARY_METHOD_NAME,
                SAVE_PROJECT_UPDATE_DEV_NOTE
            );

            for (Project_Contact__c opc : [
                SELECT Id, Primary__c
                FROM Project_Contact__c
                WHERE Id NOT IN :newPrimaries AND Project__C IN :alteredProjectIds AND Primary__c = TRUE
            ]) {
                opc.Primary__c = false;
                updatedPrimary.add(opc);
            }

            DatabaseUtilities.saveToDatabase(
                updatedPrimary,
                UPDATE_PRIMARY_METHOD_NAME,
                SAVE_CONTACT_JUNCTION_DEV_NOTE
            );
        }
    }

    /**
     * @description validate that a contact in a project is not in the same role more than once
     * @param inJunctionList List of newly inserted project contact junctions
     */
    public static void validateContactRole(List<Project_Contact__c> inJunctionList) {
        Set<Id> updatedProjectSet = new Set<Id>();

        for (Project_Contact__c pc : inJunctionList) {
            updatedProjectSet.add(pc.Project__c);
        }

        List<Project_Contact__c> existingPcJunctionsInUpdatedProjects = [
            SELECT Project__c, Contact__c, Contact_Role__c
            FROM Project_Contact__c
            WHERE Project__c IN :updatedProjectSet
        ];

        Map<Id, Project_Contact__c> existingPcJunctionMap = new Map<Id, Project_Contact__c>();
        for (Project_Contact__C pc : existingPcJunctionsInUpdatedProjects) {
            existingPcJunctionMap.put(pc.Contact__c, pc);
        }

        for (Project_Contact__c pc : inJunctionList) {
            if (
                existingPcJunctionMap.containsKey(pc.Contact__c) &&
                existingPcJunctionMap.get(pc.Contact__c).Project__c == pc.Project__c &&
                existingPcJunctionMap.get(pc.Contact__c).Contact_Role__c == pc.Contact_Role__c
            ) {
                pc.addError('Contact cannot have the same role twice in a Project');
            }
        }
    }
}