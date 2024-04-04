/* **************************************************************************
 * Copyright © 2015-2021, Neilon Technologies LLP.
 * All rights reserved
 *
 * Controller Class: S3LinkUtils
 * Created by Anil Meghnathi: 24/04/2021
 *
 * - This is S3-Link customization utils class.
 * - Modifications:
 * - Anil Meghnathi, 24/04/2021 – Initial Development
 ************************************************************************** */
public class S3LinkUtils {
    /**
     * @description Pass the object api name and method will return whether trigger for that object is active or deactivate as per the custom settings.
     * @param objectAPIName - string objectAPIName
     */
    public static Boolean isTriggerDeactivate(String objectAPIName) {
        Map<String, NEILON__Trigger_Deactivation_Configuration__c> triggerActivationConfigurationMap = NEILON__Trigger_Deactivation_Configuration__c.getAll();
        if (triggerActivationConfigurationMap != null && triggerActivationConfigurationMap.get(objectAPIName) != null) {
            return triggerActivationConfigurationMap.get(objectAPIName).NEILON__Disabled__c;
        }
        return false;
    }
}