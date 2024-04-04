trigger SuppliesQuoteTrigger on Supplies_Quote__C(before insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SuppliesQuoteHandler.processSuppliesQuotes(Trigger.new);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            SuppliesQuoteHandler.updateOpps(Trigger.new, Trigger.oldMap);
        }
    }
}