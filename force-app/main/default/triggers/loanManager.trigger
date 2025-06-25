trigger loanManager on Loan__c (after insert) {

    if (trigger.isinsert && trigger.isafter){
        loanManagerHelperClass helper = new loanManagerHelperClass();
        helper.interceptLoans(trigger.new);
        helper.assessLoans(helper.triggeringLoans);
        helper.prepareLoanCharges(helper.loansWithoutExistingReleaseCharge);
        helper.insertLoanCharges(helper.releaseLoanChargesToCreate);
    }
}