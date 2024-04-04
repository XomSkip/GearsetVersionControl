@RestResource(UrlMapping='/UserInfo/v1/*')
global with sharing class XomEndpoint_UserInfo {

    private static final String NULL_PAYLOAD = 'bnVsbA==';

    public class XomEndpoint_UserResourceException extends Exception { }

    public class UserInformation {
        public String xometryUserId { get; set; }
        public String email { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
    }

    public class Error {
        public Datetime timeStamp { get; set; }
        public String description { get; set; }
    }

    /**
     * @description Used to create/update customer information
     */
    @HttpPatch
    global static void writeCustomerRegistration(){
        try{
            RestRequest inboundRequest = RestContext.request;
            if(missingCustomerData(inboundRequest)){
                error('No data was found with this request.');
            }
            UserInformation customerData = getCustomerData(inboundRequest);
            validate(customerData);
            writeCustomerRecord(customerData);
            respondWithSuccess(customerData.xometryUserId);
        }
        catch(Exception err){
            respondWithError(err);
        }
    }

    private static void error(String msg) {
        throw new XomEndpoint_UserResourceException(msg);
    }

    private static UserInformation getCustomerData(RestRequest restRequest) {
        return (UserInformation)
                JSON.deserialize(restRequest.requestBody.toString(),UserInformation.class);
    }

    private static void respondWithSuccess(String xometryId) {
        RestContext.response.statusCode = 200;
        RestContext.response.responseBody = Blob.valueOf(xometryId);
    }

    private static Boolean missingCustomerData(RestRequest request) {
        return (EncodingUtil.base64Encode(request.requestBody) == NULL_PAYLOAD);
    }

    private static void respondWithError(Exception e) {
        RestContext.response.statusCode = 400;
        RestContext.response.responseBody = generateErrorMessage(e);
    }

    private static Blob generateErrorMessage(Exception e) {
        Error err = new Error();
        err.timeStamp = Datetime.now();
        err.description = e.getMessage();
        return Blob.valueOf(JSON.serializePretty(err));
    }

    private static void validate(XomEndpoint_UserInfo.UserInformation erpInfo){
        if(!requiredDataIsPresent(erpInfo)){
            throw new XomEndpoint_UserResourceException(
                    'The following required fields are missing: ' + getMissingData(erpInfo));
        }
    }

    private static void writeCustomerRecord(XomEndpoint_UserInfo.UserInformation erpInfo){
        Contact customer = getCustomerByEmail(erpInfo.email);
        if(customer==null){
            createCustomer(erpInfo);
        }
        else {
            updateCustomer(erpInfo,customer);
        }
    }

    private static void updateCustomer(XomEndpoint_UserInfo.UserInformation erpInfo, Contact customer) {
        customer.FirstName = String.isNotBlank(erpInfo.firstName) ? erpInfo.firstName : customer.FirstName;
        customer.LastName = String.isNotBlank(erpInfo.lastName) ? erpInfo.lastName : customer.LastName;
        if(String.isBlank(customer.Xometry_ERP_Contact_ID__c) &&
           String.isNotBlank(erpInfo.xometryUserId)){
            customer.Xometry_ERP_Contact_ID__c = erpInfo.xometryUserId;
        }
        try {
            updateInDB(customer);
        } catch (Exception e) {
            throw new XomEndpoint_UserResourceException('Can\'t update customer record with email: ' + erpInfo.email, e);
        }
    }

    private static void createCustomer(XomEndpoint_UserInfo.UserInformation erpInfo) {
        try {
            Contact customer = new Contact();
            if(!String.isBlank(erpInfo.firstName)){
                customer.FirstName = erpInfo.firstName;
            }
            if(!String.isBlank(erpInfo.lastName)){
                customer.LastName = erpInfo.lastName;
            }
            if(!String.isBlank(erpInfo.email)){
                customer.Primary_Email__c = erpInfo.email;
            }
            if(!String.isBlank(erpInfo.xometryUserId)){
                customer.OwnerId = AppConstants.CPC_HOUSE_USER;
                customer.Xometry_ERP_Contact_ID__c = erpInfo.xometryUserId;
                customer.LeadSource = 'Registered User';
            }
            createInDB(customer);
        }
        catch (Exception e){
            throw new XomEndpoint_UserResourceException('Can\'t create record for customer with email: ' + erpInfo.email, e);
        }
    }

    private static void createInDB(Contact customer) {
        List<Audit_Trail_Error__c> errors =
                DatabaseUtilities.insertToDatabase2(
                        new List<Contact>{  customer },
                        'XomEndpoint_UserInfo.createCustomer',
                        'Customer creation was not successful');
        if (!errors?.isEmpty()) {
            throw new XomEndpoint_UserResourceException('Customer record creation was not successful');
        }
    }

    private static void updateInDB(Contact customer) {
        List<Audit_Trail_Error__c> errors =
                DatabaseUtilities.updateToDatabase(
                        new List<Contact>{  customer },
                        'XomEndpoint_UserInfo.updateCustomer',
                        'Customer update was not successful');
        if (!errors?.isEmpty()) {
            throw new XomEndpoint_UserResourceException('Customer record creation was not successful');
        }
    }

    private static Contact getCustomerByEmail(String email) {
        Contact result;
        List<Contact> customers = [
                SELECT Id, FirstName, LastName, Primary_Email__c, Xometry_ERP_Contact_ID__c, LeadSource
                FROM Contact
                WHERE Primary_Email__c = :email
                WITH USER_MODE
        ];
        if(!customers.isEmpty()){
            result = customers[0];
        }
        return result;
    }

    private static Boolean requiredDataIsPresent(XomEndpoint_UserInfo.UserInformation erpInfo){
        return String.isNotBlank(erpInfo.xometryUserId) && String.isNotBlank(erpInfo.email);
    }

    private static String getMissingData(XomEndpoint_UserInfo.UserInformation erpInfo){
        String missingData = '';
        if(String.isBlank(erpInfo.xometryUserId)){
            missingData += 'xometryUserId';
        }
        if(missingData.length()>0){
            missingData+=', ';
        }
        if(String.isBlank(erpInfo.email)){
            missingData += 'email';
        }
        return missingData;
    }

}