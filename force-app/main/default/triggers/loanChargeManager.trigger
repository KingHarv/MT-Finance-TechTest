trigger loanChargeManager on Loan_Charge__c (after insert){ 
    
    if (trigger.isinsert && trigger.isafter){
        loanChargeManagerHelperClass helper = new loanChargeManagerHelperClass();
        helper.interceptLoanCharges(trigger.new);
        helper.manageLoanCharges();
        helper.updateLoanCharges(helper.existingChargesToAmend);
    }
}