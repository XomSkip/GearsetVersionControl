public with sharing class routingAddress {
    public string routingZipCode { get; set; }
    public string routingCity { get; set; }
    public string routingaltZipCode { get; set; }
    public string routingaltCity { get; set; }
    //ID to be used on return maps
    public String sourceID { get; set; }
    public ID routedOwnerID { get; set; }
    public routingAddress() {
    }
    public routingAddress(
        string routingZipCode,
        string routingCity,
        string routingaltZipCode,
        string routingaltCity,
        String sourceID
    ) {
        this.routingZipCode = routingZipCode;
        this.routingCity = routingCity;
        this.routingaltZipCode = routingaltZipCode;
        this.routingaltCity = routingaltCity;
        this.sourceID = sourceID;
    }
}