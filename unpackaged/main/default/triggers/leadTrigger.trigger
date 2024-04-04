trigger leadTrigger on lead(before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            //Email Cleanup Logic
            if (ApexBypassUtility.shouldRun('Lead_primaryEmailPop')) {
                LeadHandler.primaryEmailPop(Trigger.new);
            }
            // Prep for Smart Domain. Lookup the domain and apply Owner routing
            if (ApexBypassUtility.shouldRun('Lead_smartDomainLKP')) {
                LeadHandler.smartDomainLKP(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_PartnerMatch')) {
                LeadHandler.partnerMatch(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_Quarantine')) {
                LeadHandler.quarantineCheck(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_SpecialLeadRules')) {
                LeadHandler.specialLeadRules(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_DomainMatching')) {
                boolean leadDomainMatchFlag = ApexBypassUtility.shouldRun('Lead_DomainMatching_Lead');
                LeadHandler.domainMatching(Trigger.new, leadDomainMatchFlag);
            }
            if (ApexBypassUtility.shouldRun('Lead_setClasification')) {
                LeadHandler.setClasification(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_setDNB_DUNS')) {
                LeadHandler.setDUNS(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_cleanDomain')) {
                LeadHandler.cleanDomain(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_fillCompanyRecommended')) {
                LeadHandler.fillCompanyRecommended(Trigger.new);
            }
        }
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Lead_primaryEmailPop')) {
                LeadHandler.primaryEmailPop(Trigger.new);
            }
            if (ApexBypassUtility.shouldRun('Lead_updateRecommendedAccount')) {
                LeadHandler.updateRecommendedAccount(Trigger.newMap, Trigger.oldmap);
            }
            if (ApexBypassUtility.shouldRun('Lead_cleanDomain')) {
                LeadHandler.cleanDomain(Trigger.new);
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            if (ApexBypassUtility.shouldRun('Lead_convertedLeadBucketing')) {
                LeadHandler.convertedLeadBucketing(Trigger.new, Trigger.oldmap);
            }
        }
    }
}