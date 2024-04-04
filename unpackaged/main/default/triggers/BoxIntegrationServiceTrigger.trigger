trigger BoxIntegrationServiceTrigger on Box_Integration_Service__e (after insert) {
    BoxIntegrationServiceHelper.processEvents(Trigger.new);
}