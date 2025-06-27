public class loanChargeManagerHelperClass {
    
    Public List<Loan_Charge__c> interestChargeLoanCharges = new List<Loan_Charge__c>();
    Public List<Loan_Charge__c> legalFeeLoanCharges = new List<Loan_Charge__c>();
    Public List<Loan_Charge__c> adminFeeLoanCharges = new List<Loan_Charge__c>();
    Public List<Loan_Charge__c> existingChargesToAmend = new List<Loan_Charge__c>();
    
    /*
* Method Purpose: 
*	Intercept and store all individual LoanCharges into their own respective Lists for later processesing in manageLoanCharges() & updateLoanCharges() Method 
* 
* Parameters:
*	List Loan_Charge__c: Trigger.new Value(s) parsed via loanChargeManager.apxt
* 
* Return: 
* 	N/A
*/
    public void interceptLoanCharges(List<Loan_Charge__c> loanCharges){
        if(loanCharges == null || loanCharges.isEmpty()){
            System.debug('interceptLoanCharges Method has exited early as there were no Loans Found when the Method was invoked. Please ensure a Record or List of Records is passed into the Method call.');
            return;
        } else {
            For (Loan_Charge__c iteratingLoanCharge : loanCharges){
                if(iteratingLoanCharge.Charge_Type__c == 'Release Charge'){
                    // query existing LC to see if a RC exists for the same L. throw error if does. If the Release Charge triggering this is the one being created, do not throw error.
                    List<Loan_Charge__c> identifiedReleaseCharges = [SELECT id, Charge_type__c, loan__c FROM Loan_charge__c where loan__c =: iteratingLoanCharge.Loan__c AND Id != :iteratingLoanCharge.Id AND Charge_Type__c = 'Release Charge'];
                    if (identifiedReleaseCharges.size() > 0){
                        System.debug('A Release Charge Loan Charge has been detected for this Loan. Another will not be created.');
                        iteratingLoanCharge.Loan__c.adderror('A Release Charge Loan Charge has been detected for this Loan. You cannot create another for the same Loan.');
                    } else {
                        System.debug('A retroactive addition of a Release Charge is going to be added. This has been allowed as there has not been a detected Release Charge on the Loan: ' + iteratingLoanCharge.Loan__c);
                    }
                }  if (iteratingLoanCharge.Charge_Type__c == 'Interest Charge'){
                    // add LC to IC list
                    interestChargeLoanCharges.add(iteratingLoanCharge);
                    System.debug('A Interest Charge Loan Charge has been added to a List and is being prepared to be created. Interest Charge Loan: ' + iteratingLoanCharge);
                } else if (iteratingLoanCharge.Charge_Type__c == 'Legal Fee'){
                    // add LC to LF list
                    legalFeeLoanCharges.add(iteratingLoanCharge);
                    System.debug('A Legal Fee Loan Charge has been added to a List and is being prepared to be created. Legal Fee Loan: ' + iteratingLoanCharge);
                } else if (iteratingLoanCharge.Charge_Type__c == 'Admin Fee'){
                    // add LC to AF list
                    adminFeeLoanCharges.add(iteratingLoanCharge);
                    System.debug('A Admin Fee Loan Charge has been added to a List and is being prepared to be created. Admin Fee Loan: ' + iteratingLoanCharge);
                } else {
                    system.debug('no applicable lc found... ');
                }
            }   
        }
    }
    
    /*
* Method Purpose: 
* 	Retrieve and compile all individual Loan Charges found from interceptLoanCharges() Method,
* 	Detect and associate the Loan corresponding to each Charge,
* 	Relate that Loan & the most recent Charge Date for each child Loan Charge in the furthestDatePerLoan Map
* 	Compare the most recent Charge Date for each child Loan Charge against the corresponding Release Charge relating & determine whether it needs it's Charge Date to be amended by +1
*
* Parameters:
* 	N/A
*
* Return: 
* 	N/A
*/ 
    public void manageLoanCharges(){
        
        Map<Id, Date> furthestDatePerLoan = new Map<Id, Date>(); // LoanId -> Latest non-'release charge' date
        List<Loan_Charge__c> allNonReleaseLoanCharges = new List<Loan_Charge__c>();
        
        // Collect all non-release charges
        allNonReleaseLoanCharges.addAll(interestChargeLoanCharges);
        allNonReleaseLoanCharges.addAll(legalFeeLoanCharges);
        allNonReleaseLoanCharges.addAll(adminFeeLoanCharges);
        
        // Find the latest non-release charge date per loan
        for (Loan_Charge__c charge : allNonReleaseLoanCharges) {
            if (charge.Loan__c != null && charge.Date__c != null) {
                if (!furthestDatePerLoan.containsKey(charge.Loan__c) || charge.Date__c > furthestDatePerLoan.get(charge.Loan__c)) {
                    furthestDatePerLoan.put(charge.Loan__c, charge.Date__c);
                }
            }
        }
        
        System.debug('Furthest dates found across Loan Charges relating to x Loan: ' + furthestDatePerLoan);
        
        // Get all Release Charges for those loans
        List<Loan_Charge__c> existingReleaseCharges = [SELECT Id, Loan__c, Date__c FROM Loan_Charge__c WHERE Charge_Type__c = 'Release Charge' AND Loan__c IN :furthestDatePerLoan.keySet()];
        
        for (Loan_Charge__c releaseCharge : existingReleaseCharges) {
            Date latestDate = furthestDatePerLoan.get(releaseCharge.Loan__c);
            Date expectedDate = latestDate.addMonths(1);
            
            if (releaseCharge.Date__c == null || releaseCharge.Date__c < expectedDate) {
                releaseCharge.Date__c = expectedDate;
                existingChargesToAmend.add(releaseCharge);
            }
        }
    }
    
    /*
* Method Purpose: 
*	Attempt to update the required Release Charge Loan Charges (+1 to Charge Date) 
*
* Parameters:
*	List Loan_Charge__c: existingChargesToAmend parsed via loanChargeManager.apxt (Loan Charges to Update) 
*
* Return: 
*	N/A
*/ 
    public void updateLoanCharges(List<Loan_Charge__c> toUpdate){
        try{
            system.debug('Loan Charges before Records held in the list are Updated: ' + toUpdate);
            update toUpdate;
            existingChargesToAmend = [SELECT Id, Charge_Type__c, Loan__c, Amount__c FROM Loan_Charge__c where id IN: toUpdate]; 
            system.debug('The following Loan Charges have been Updated: ' + existingChargesToAmend + '\nThese Updates should be relating to the Charge Date');
        } catch (exception e){
            system.debug('An Exception has been found. Please review the following Exception Message: ' + e);
        }
    }
    
    
}