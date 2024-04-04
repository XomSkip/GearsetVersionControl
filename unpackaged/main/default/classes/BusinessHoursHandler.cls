public class BusinessHoursHandler{    
    @InvocableMethod(label='calculate hours awaiting customer' description='calculates the hours since the case was changed to Awaiting Customer, based on POD Business Hours - EST')
    public static List<Long> calculateHoursAwaitingCustomer(List<Datetime> dtTimeSetToAwaitingCustomer){
        List<Long> lstReturn = new List<Long>();
        BusinessHours PODBusinessHoursRecord = [SELECT Id FROM BusinessHours WHERE Name = 'POD Business Hours - EST' LIMIT 1];
        for(Datetime dtAux : dtTimeSetToAwaitingCustomer)
        {            
            Long result = BusinessHours.diff(PODBusinessHoursRecord.Id, dtAux, Datetime.Now()) / 3600000;
            lstReturn.add(result);
        }     
        return lstReturn;
    }
}