public class postOrderAggUpdates implements Queueable {
    private Set<ID> accountIDSet;
    private Set<ID> contactIDSet;
    private Date currentDate;
    private Integer currentMonth;
    private Integer currentYear;
    private Integer previousYear;
    private Integer rollingMonth;
    private Integer rollingYear;
    private Date rollingDate;

    static ID oppManufacturingServRTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Manufacturing_Services')
        .getRecordTypeID();

    public postOrderAggUpdates(Set<ID> inaccountIDs) {
        this.accountIDSet = inaccountIDs;
        this.currentDate = Date.today();
        this.currentMonth = this.currentDate.month();
        this.currentYear = this.currentDate.year();
        this.previousYear = this.currentYear - 1;
        if (this.currentMonth == 12) {
            this.rollingMonth = 1;
            this.rollingYear = this.currentYear;
        } else {
            this.rollingMonth = this.currentMonth + 1;
            this.rollingYear = this.previousYear;
        }
        this.rollingDate = Date.newInstance(this.rollingYear, this.rollingMonth, 1);
    }

    public void execute(QueueableContext context) {
        System.debug('Firing Off the PostOrderAggUpdates execute method!');
        Map<ID, Account> accountsToUpdateMap = new Map<ID, Account>();
        for (ID acctID : accountIDSet) {
            Account a = new Account(ID = acctID);
            accountsToUpdateMap.put(a.ID, a);
        }
        List<Account> accountsToUpdateList = new List<Account>();
        //Calculate YTD information
        AggregateResult[] myAggResYTD = [
            SELECT AccountID, Sum(Amount) Total
            FROM Opportunity
            WHERE
                Stagename = 'Closed Won'
                AND AccountID IN :accountIDSet
                AND CALENDAR_YEAR(closeDate) = :currentYear
                AND RecordTypeId = :oppManufacturingServRTypeID
            GROUP BY AccountID
        ];
        if (!myAggResYTD.isEmpty()) {
            for (AggregateResult aggRes : myAggResYTD) {
                ID lID = ID.valueOf(String.valueOf(aggRes.get('AccountID')));
                Decimal lTotal = Decimal.valueOf(String.valueOf(aggRes.get('Total')));
                if (accountsToUpdateMap.containsKey(lID)) {
                    Account a = accountsToUpdateMap.get(lID);
                    a.YTDSpend__c = lTotal;
                    accountsToUpdateMap.put(a.ID, a);
                }
            }
        }
        //Calculate Rolling12
        AggregateResult[] myAggResRolling = [
            SELECT AccountID, Sum(Amount) RollingTotal
            FROM Opportunity
            WHERE
                Stagename = 'Closed Won'
                AND AccountID IN :accountIDSet
                AND closeDate >= :rollingDate
                AND RecordTypeId = :oppManufacturingServRTypeID
            GROUP BY AccountID
        ];
        if (!myAggResRolling.isEmpty()) {
            for (AggregateResult aggRes : myAggResRolling) {
                ID lID = ID.valueOf(String.valueOf(aggRes.get('AccountID')));
                Decimal lRollTotal = Decimal.valueOf(String.valueOf(aggRes.get('RollingTotal')));
                if (accountsToUpdateMap.containsKey(lID)) {
                    Account a = accountsToUpdateMap.get(lID);
                    a.Rolling_12_Spend__c = lRollTotal;
                    accountsToUpdateMap.put(a.ID, a);
                }
            }
        }

        AggregateResult[] myAggResLifeTimeOrd = [
            SELECT AccountID, Sum(Amount) LifetimeSpend, Count_Distinct(Order_ERP_Xom_ID__c) NumOrders
            FROM Opportunity
            WHERE
                Stagename = 'Closed Won'
                AND AccountID IN :accountIDSet
                AND RecordTypeId = :oppManufacturingServRTypeID
            GROUP BY AccountID
        ];
        if (!myAggResLifeTimeOrd.isEmpty()) {
            for (AggregateResult aggRes : myAggResLifeTimeOrd) {
                ID lID = ID.valueOf(String.valueOf(aggRes.get('AccountID')));
                Decimal lLifetimeSpend = Decimal.valueOf(String.valueOf(aggRes.get('LifetimeSpend')));
                Integer lNumberOrders = Integer.valueOf(String.valueOf(aggRes.get('NumOrders')));
                if (accountsToUpdateMap.containsKey(lID)) {
                    Account a = accountsToUpdateMap.get(lID);
                    a.Lifetime_Spend__c = lLifetimeSpend;
                    a.Number_Orders__c = lNumberOrders;
                    accountsToUpdateMap.put(a.ID, a);
                }
            }
        }

        System.debug('About to start the Account Order Updates');
        accountsToUpdateList = accountsToUpdateMap.values();
        DatabaseUtilities.saveToDatabase(
            accountsToUpdateList,
            'postOrderAggUpdates.execute',
            'Account Updates in Execution Queue'
        );
    }
}