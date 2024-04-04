@isTest
public class slack_tst_Supplier {
	@isTest 
	static void testTrigger() {
		Supplier__c obj0 = new Supplier__c(
			PartnerID__c = 's'
		);
		insert obj0;
	}
}