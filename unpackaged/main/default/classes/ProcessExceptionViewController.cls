public class ProcessExceptionViewController{

    /**
     * @description method to fetch all open ProcessException related to the OpsOrder or Job record
     * @param recordId id of the OpsOrder or Job record
     * @return List of the ProcessException related
     */
    @AuraEnabled
    public static List<ProcessException> getAllProcessExceptions(Id recordId){
        if(recordId != null){
            String strObjectId = findObjectNameFromRecordIdPrefix(recordId);
            List<ProcessException> processExceptionsList = new List<ProcessException>();

            String strQuery = 'SELECT Id, '
                                +'(SELECT Id, ProcessExceptionNumber, AttachedToId, Status, Message, Priority, Category, Severity, CreatedDate, Owner.Name, Case.CaseNumber, Icon_indicator_type__c '
                                +'FROM ProcessExceptions '
                                +'WHERE Status != \'Resolved\' Order By Id DESC) ';

            if(strObjectId == 'Ops_Order__c')
            {
                List<Order_Event__c> lstOrdersEvents = Database.Query(strQuery+'FROM Order_Event__c WHERE Ops_Order__c = \''+recordId+'\'');
                List<Job_Event__c> lstJobsEvents = Database.Query(strQuery+'FROM Job_Event__c  WHERE Job__r.OrderID__c = \''+recordId+'\'');
                
                for(Order_Event__c obj : lstOrdersEvents)
                {
                    processExceptionsList.addAll(obj.ProcessExceptions);
                }

                for(Job_Event__c obj : lstJobsEvents)
                {
                    processExceptionsList.addAll(obj.ProcessExceptions);
                }
            }
            else if(strObjectId == 'Job__c')
            {
                List<Job_Event__c> lstJobsEvents = Database.Query(strQuery+'FROM Job_Event__c  WHERE Job__c = \''+recordId+'\'');
                
                for(Job_Event__c obj : lstJobsEvents)
                {
                    processExceptionsList.addAll(obj.ProcessExceptions);
                }
            }

            System.debug('processExceptionsList '+processExceptionsList);

            if(processExceptionsList != null && processExceptionsList.size() > 0){
                return processExceptionsList;
            }
        }

        return null;
    }

    /**
     * @description method to get the info of the OpsOrder
     * @param recordId id of the OpsOrder or Job record
     * @return OpsOrder record
     */
    @AuraEnabled
    public static Ops_Order__c getOpsOrderInfo(Id recordId){
        Ops_Order__c objOrder;
        if(recordId != null){
            String strObjectId = findObjectNameFromRecordIdPrefix(recordId);
            String strQuery = 'SELECT POD__c, LargeOrderStatus__c, Is_Large_Order__c FROM Ops_Order__c';
            if(strObjectId == 'Ops_Order__c')
            {
                objOrder = Database.query(strQuery+' WHERE Id = \''+recordId+'\'');
            }
            else if(strObjectId == 'Job__c')
            {
                objOrder = Database.query(strQuery+' WHERE Id IN (SELECT OrderID__c FROM Job__c WHERE Id = \''+recordId+'\')');
            }
        }

        return objOrder;
    }
    
    /**
     * @description get the Sobject type of the some Id
     * @param recordIdOrPrefix id of the record
     * @return the Sobject type of the some Id
     */
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 

            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }
}