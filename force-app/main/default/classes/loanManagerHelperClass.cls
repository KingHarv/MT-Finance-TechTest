public class loanManagerHelperClass {
    
    Public List<Loan__c> triggeringLoans = new List<Loan__c>();
    Public List<Loan__c> loansWithExistingReleaseCharge = new List<Loan__c>();
    Public List<Loan__c> loansWithoutExistingReleaseCharge = new List<Loan__c>();
    
    Public List<Loan_Charge__c> relatedLoanCharges = new List<Loan_Charge__c>();
    Public List<Loan_Charge__c> releaseLoanChargesToCreate = new List<Loan_Charge__c>();
    
    /*
* Method Purpose: 
*	Intercept and store all individual Loans into their own List for later processesing in assessLoans() & insertLoanCharges() Method  
*
* Parameters:
*	List Loan__c: Trigger.new Value(s) parsed via loanManager.apxt
*
* Return: 
*	N/A
*/    
    public void interceptLoans(List<Loan__c> loans){  
        For (Loan__c iteratingLoans : Loans){
            triggeringLoans.add(iteratingLoans);
        }
    }
    
    /*
* Method Purpose: 
*	Determine/Assess if a Release Charge must be created alongside the Loan which is being created
*
* Parameters:
*	List Loan__c: triggeringLoans parsed via loanManager.apxt
*
* Return: 
*	N/A
*/    
    public void assessLoans(List<Loan__c> triggeringLoansFound){
        
        if(triggeringLoansFound == null || triggeringLoansFound.isempty()){
            System.debug('assessLoans Method has exited early as there were no Loans Found when the Method was invoked. Please ensure a Record or List of Records is passed into the Method call.');
            return;
        }
        
        List<Loan_Charge__c> relatedLoanCharges = [SELECT Id, Charge_Type__c, Loan__c, Amount__c FROM Loan_Charge__c where Loan__c IN: triggeringLoansFound AND Charge_Type__c = 'Release Charge'];
        Set<ID> loanIdsWithReleaseLoanCharge = new Set<ID>();
        
        for(Loan_charge__c lc : relatedLoanCharges){
            loanIdsWithReleaseLoanCharge.add(lc.Loan__c);
        }
        
        for (Loan__c l1: triggeringLoansFound){
            if(loanIdsWithReleaseLoanCharge.contains(l1.id)){
                loansWithExistingReleaseCharge.add(l1);
                System.debug('Loan already has a Release Charge Loan Charge Record associated. Another will NOT be created.'); 
            } else {
                loansWithoutExistingReleaseCharge.add(l1);
                System.debug('Loan does not have a Release Charge Loan Charge Record associated. One will be created later in the execution.'); 
            }
        }
    }
    
    
    /*
* Method Purpose: 
*	Intake and process Release Charges to be created per associated Loan 
*	This is a result of the processing AND assessment carried out in interceptLoans() & assessLoans()
*
* Parameters:
*	List Loan__c: loansWithoutExistingReleaseCharge parsed via loanManager.apxt
*
* Return: 
*	N/A
*/     
    public void prepareLoanCharges(List<Loan__c> noExistingReleaseChargeLoans){
        
        system.debug('noExistingReleaseChargeLoans: ' + noExistingReleaseChargeLoans);
        
        for (Loan__c l : noExistingReleaseChargeLoans){
            Loan_Charge__c releaseChargeLC = new Loan_Charge__c();
            releaseChargeLC.Name = l.Name + ' Release Charge';
            releaseChargeLC.Amount__c = 500;
            releaseChargeLC.Charge_Type__c = 'Release Charge';
            releaseChargeLC.Date__c = l.Date_Loan_Issued__c.addMonths((Integer) Math.floor(l.Term__c));
            releaseChargeLC.Loan__c = l.id;
            releaseLoanChargesToCreate.add(releaseChargeLC);
        }
    }
    
    /*
* Method Purpose: 
*	Attempt to Insert all necessary Release Charges per Loan 
*
* Parameters:
*	List Loan__c: releaseLoanChargesToCreate parsed via loanManager.apxt
*
* Return: 
*	N/A
*/   
    public void insertLoanCharges(List<Loan_Charge__c> toInsert){
        try{
            insert toInsert;
            relatedLoanCharges = [SELECT Id, Charge_Type__c, Loan__c, Amount__c,Date__c FROM Loan_Charge__c where Loan__c IN: triggeringLoans]; 
            system.debug('The following Loan Charges have been Inserted: ' + relatedLoanCharges + '\nThese Insertions should be of "Release Charge" Type.');
        } catch (exception e){
            system.debug('An Exception has been found. Please review the following Exception Message: ' + e);
        }      
    }
    
}