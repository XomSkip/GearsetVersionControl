public with sharing class EmailMessageHelper {
    /**
     * @description Helper class for EmailMessages
     * Reduces queries in AppConstants since all these of these are used to send an email, but nowhere else
     */
    public static final Boolean inSandbox = [
        SELECT IsSandbox
        FROM Organization
        WHERE Id = :UserInfo.getOrganizationId()
    ]
    .IsSandbox;

    public static final String supportRoutingAddress{
        get{
            if(supportRoutingAddress == null){
                if(inSandbox){
                    String emailDomainName = [SELECT EmailDomainName FROM EmailServicesAddress WHERE DeveloperName = 'support' LIMIT 1]?.EmailDomainName;
                    supportRoutingAddress = 'support@' + ( emailDomainName != null ? emailDomainName : 'testxometry.com' );
                }else{
                    supportRoutingAddress = 'support@xometry.com';
                }
            }


            return supportRoutingAddress;

        }
        set;
    }

    public static List<Messaging.SendEmailResult> sendEmail(List<Messaging.SingleEmailMessage> sendEmails, Boolean allOrNothing){
        
        List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();

        if(!EmailMessageHelper.InSandbox){

            results = Messaging.sendEmail(sendEmails, allOrNothing);

        }else{

            List<EmailMessage> testEmailMessageList = new List<EmailMessage>();
            for(Messaging.SingleEmailMessage mail:sendEmails){
                EmailMessage testEmailMessage = new EmailMessage();
                testEmailMessage.ParentId = mail.getWhatId();
                testEmailMessage.Subject = mail.getSubject();
                testEmailMessage.HtmlBody = mail.getHtmlBody();
                testEmailMessageList.add(testEmailMessage);
            }

            insert testEmailMessageList;

        }

        return results;

    }

    public static final EmailTemplate missingEUDEmailTemplate = [
        SELECT Id, Name, Subject, Body
        FROM EmailTemplate
        WHERE Name = 'Missing EUD Text Template'
    ];

    public static final ID supportOrgWideEmailID = [
        SELECT ID
        FROM OrgWideEmailAddress
        WHERE Address = 'support@xometry.com'
        LIMIT 1
    ][0]
    .Id;

    /**
     * @description logs a general exception to audit trail error
     * @param e general exception error
     */
    public static void handleEmailError(Exception e, String module, String dev_audit_notes) {
        Audit_Trail_Error__c auditError = new Audit_Trail_Error__c();
        auditError.Module__c = module;
        auditError.Dev_Audit_Notes__c = dev_audit_notes;
        auditError.errorMessage__c = e.getMessage().abbreviate(250);
        insert auditError;
    }
}