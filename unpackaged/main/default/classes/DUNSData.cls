public with sharing class DUNSData {
    public string userDUNSNumber { get; set; }
    public string userParentDUNSNumber { get; set; }
    public string userUltimateDUNSNumber { get; set; }
    public string domain { get; set; }
    public string sourceId { get; set; }
    public string accountId { get; set; }
    public string ownerId { get; set; }
    public string matchedDuns { get; set; }
    public DUNSData() {
    }

    public DUNSData(
        String userDUNSNumber,
        String userParentDUNSNumber,
        String userUltimateDUNSNumber,
        String domain,
        String sourceId,
        String accountId,
        String ownerId,
        String matchedDUNS
    ) {
        this.userDUNSNumber = userDUNSNumber;
        this.userParentDUNSNumber = userParentDUNSNumber;
        this.userUltimateDUNSNumber = userUltimateDUNSNumber;
        this.domain = domain;
        this.sourceId = sourceId;
        this.accountId = accountId;
        this.ownerId = ownerId;
        this.matchedDuns = matchedDUNS;
    }
}