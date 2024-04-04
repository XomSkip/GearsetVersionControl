public class ApexBypassUtility {
    
    private static Map<String, Boolean> apexBypassMap{
        get {
            if (apexBypassMap == null) {
                apexBypassMap = getApexBypassMap();
            }

            return apexBypassMap;
        }
        set;
    }

    public ApexBypassUtility() {

    }

    /**
     * @description Check if the name of the custom metadata passed in as an input is within the map, and if so
     * check if the Bypass checkbox is set to true on the custom metadata record, and if so
     * then return false, which will cause the associated method to not execute, otherwise return true so the method executes
     * @param apexToBypassName A string containing the developer name of relative Apex Bypass record
     * @return Returns Boolean, true if the Bypass field is true on Apex Bypass Record, False otherwise
     */
    public Boolean apexShouldRun(String apexToBypassName) {

        return ShouldRun( apexToBypassName );

    }

    /**
     * @description Check if the name of the custom metadata passed in as an input is within the map, and if so
     * check if the Bypass checkbox is set to true on the custom metadata record, and if so
     * then return false, which will cause the associated method to not execute, otherwise return true so the method executes
     * @param apexToBypassName A string containing the developer name of relative Apex Bypass record
     * @return Returns Boolean, true if the Bypass field is true on Apex Bypass Record, False otherwise
     */
    public static Boolean shouldRun(String apexToBypassName) {
        if (
            apexBypassMap.size() > 0 &&
            apexBypassMap.containsKey(apexToBypassName) &&
            apexBypassMap.get(apexToBypassName) == true
        ) {
            return false;
        }
        return true;
    }

    /**
     * @description Query all Apex Bypass custom metadata records and add to Map defined above
     * @return Returns Map of all Apex Bypass custom metadata records, key is developer name, value is Bypass__c Boolean value
     */
    private static Map<String, Boolean> getApexBypassMap() {
        Map<String, Boolean> returnValue = new Map<String, Boolean>();
        for (Apex_Bypass__mdt thisBypass : [SELECT DeveloperName, Bypass__c FROM Apex_Bypass__mdt]) {
            returnValue.put(thisBypass.DeveloperName, thisBypass.Bypass__c);
        }
        return returnValue;
    }
}