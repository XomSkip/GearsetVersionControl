global class CreateFolderResponse {
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public String consumerFolderITAR { get; set; }
    @AuraEnabled
    public String consumerFolderNonITAR { get; set; }
    @AuraEnabled
    public String caseFolder { get; set; }

    public CreateFolderResponse(String status, String caseFolder, String consumerFolderITAR, String consumerFolderNonITAR) {
        this.status = status;
        this.consumerFolderITAR = consumerFolderITAR;
        this.consumerFolderNonITAR = consumerFolderNonITAR;
        this.caseFolder = caseFolder;
    }
}