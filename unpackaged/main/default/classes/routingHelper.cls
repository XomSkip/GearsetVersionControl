public with sharing class routingHelper {
    /**
     * @description assigns an OwnerID based on a determined ZipCode Map or Custom Territory Rule
     * @param routingAddressList a list of Addresses to determine the OwnerID of based on Territory Routing
     * @param businessEntity a Field that maps to the global Picklist Line of Business
     */
    public static List<routingAddress> suppliesTerritoryRouting(
        List<routingAddress> routingAddressList,
        String businessEntity
    ) {
        Set<String> searchZIPs = new Set<String>();

        //Once we are in PROD refactor to use the Constants value in Prod
        //ID BusinessEntityHouse = [Select ID from where ]
        // Check if we have a matched based on the businessEntity and criteria
        // if no match return the default Business Entity House Account
        // Designed to search by ZipCode
        for (routingAddress rA : routingAddressList) {
            if (!string.isBlank(rA.routingZipCode)) {
                searchZIPS.add(rA.routingZipCode);
            }
        }
        //Get all Active Users based on Search Criteria
        System.debug('Starting the Router Method');
        List<Rep_Router__c> matchRoutes = [
            SELECT User__c, ZipCode__c
            FROM Rep_Router__c
            WHERE
                ZipCode__c IN :searchZIPS
                AND Business_Entity__C = :businessEntity
                AND User__c != null
                AND User__r.isActive = true
        ];
        System.debug('We have some matchingRoutes: ' + matchRoutes.size());
        Map<String, Rep_Router__c> repRoutesMaps = new Map<String, Rep_Router__c>();
        if (matchRoutes.size() > 0) {
            for (Rep_Router__c repR : matchRoutes) {
                repRoutesMaps.put(repR.ZipCode__c, repR);
            }
        }

        for (routingAddress rA : routingAddressList) {
            if (repRoutesMaps.containsKey(rA.routingZipCode)) {
                rA.routedOwnerID = repRoutesMaps.get(rA.routingZipCode).User__c;
            } else {
                rA.routedOwnerID = AppConstants.SUPPLIES_HOUSE_USER;
            }
        }
        System.debug('Ending the Router');
        return routingAddressList;
    }
    /* @description assigns an OwnerID or assigns the Opp to House Account based on some additional rules. Occurs after territory routing
     * @param inOpportunityList a list of Opportunities to identify
     */
    public static List<Opportunity> checkLastActiveSupplyRep(List<Opportunity> inOpportunityList) {

        Set<ID> primaryContactCheckSet = new Set<ID>();

        for (Opportunity opp : inOpportunityList) {
            //ToDo Logic Here
            primaryContactCheckSet.add(opp.Primary_Contact__c);
        }

        if (!primaryContactCheckSet.isEmpty()) {

            Map<Id, Contact> primaryConMap = new Map<Id, Contact>();
            for (Contact con : [
                SELECT Id, OwnerID, Supplies_Last_Opp_Owner__c, Supplies_Last_Owner_DateTime__c
                FROM Contact
                WHERE Id IN :primaryContactCheckSet AND Supplies_Last_Opp_Owner__c != null
            ]) {
                primaryConMap.put(con.ID, con);
            }

            for (Opportunity opp : inOpportunityList) {

                if (primaryConMap.containsKey(opp.Primary_Contact__c)) {
                    Contact con = primaryConMap.get(opp.Primary_Contact__c);
                    if (con.Supplies_Last_Owner_DateTime__c != null) {
                        opp.OwnerID = con.Supplies_Last_Opp_Owner__c;
                    }
                }

            }
        }

        return inOpportunityList;
    }

    /* @description assigns an OwnerID or assigns the Opp to House Account based on some additional rules. Occurs after territory routing
     * @param inOpportunityList a list of Opportunities to identify Owners for
     */
    public static List<Opportunity> routeSuppliesOpps(List<Opportunity> inOpportunityList) {
        List<Opportunity> suppliesOppsNeedRR = new List<Opportunity>();
        List<Opportunity> suppliesOppsNeedContactCheck = new List<Opportunity>();
        for (Opportunity opp : inOpportunityList) {
            System.debug('Lets look at the Opps Owner');
            System.debug(opp.OwnerID);
            if (
                opp.OwnerId == AppConstants.SUPPLIES_HOUSE_USER ||
                opp.OwnerId == AppConstants.API_USER ||
                opp.OwnerID == null
            ) {
                suppliesOppsNeedContactCheck.add(opp);
            }
        }
        if (!suppliesOppsNeedContactCheck.isEmpty()) {
            checkLastActiveSupplyRep(suppliesOppsNeedContactCheck);
            //Any Opps that still don't have an owner now go through the round robin.
            for (Opportunity opp : suppliesOppsNeedContactCheck) {
                if (
                    opp.OwnerId == AppConstants.SUPPLIES_HOUSE_USER ||
                    opp.OwnerId == AppConstants.API_USER ||
                    opp.OwnerID == null
                ) {
                    suppliesOppsNeedRR.add(opp);
                }
            }
            if (!suppliesOppsNeedRR.isEmpty()) {
                roundRobinDist.oppRoundRobinSuppliesHouse(suppliesOppsNeedRR);
            }
        }
        return inOpportunityList;
    }
}