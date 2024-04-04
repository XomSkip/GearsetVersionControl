public with sharing class EventBusBypass {
    public static Map<String, Boolean> triggerNameBypassed = new Map<String, Boolean>();

    /**
     * @description Called to skip the execution of specific methods during
     * the downstream event bus
     * @param triggerName the trigger of the event bus method you do not want to call
     */
    public static void ByPass(String triggerName) {
        triggerNameBypassed.put(triggerName, true);
    }

    /**
     * @description Resumes execution of the method during the downstream event bus
     * @param triggerName the trigger of the event bus method you want to execute
     */
    public static void UndoByPass(String triggerName) {
        triggerNameBypassed.put(triggerName, false);
    }

    /**
     * @description Used to call in the object trigger event bus method to check
     * if the object should be loaded into execution
     * @param triggerName the event bus trigger method that is being checked
     */
    public static Boolean isByPassed(String triggerName) {
        return triggerNameBypassed.containsKey(triggerName) && triggerNameBypassed.get(triggerName);
    }
}