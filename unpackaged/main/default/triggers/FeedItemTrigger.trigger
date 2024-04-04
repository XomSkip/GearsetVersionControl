trigger FeedItemTrigger on FeedItem (after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (ApexBypassUtility.shouldRun('FeedItemTrigger_InternalNotes')) {
                FeedItemHandler.InternalNotes(Trigger.new);
            }
        }
    }
}