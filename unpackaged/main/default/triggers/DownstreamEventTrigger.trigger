trigger DownstreamEventTrigger on Downstream_Event__e(after insert) {
    DownstreamEventHelper.processEvents(Trigger.new);
}