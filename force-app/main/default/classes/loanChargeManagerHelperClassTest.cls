@IsTest
public class loanChargeManagerHelperClassTest {
    
    public static account createDefaultAccount(){
        Account defaultAccount = new Account();
        defaultAccount.name = 'Test Account Name';
        
        return defaultAccount;
    }
    
    public static Loan__c createDefaultLoan(Account acc){ //, List<Loan_Charge__c> LC){
        Loan__c defaultLoan = new Loan__c();
        defaultLoan.name = 'Test Loan Name';
        defaultLoan.account__c = acc.Id;
        defaultLoan.Address__c = 'Test Loan Security Address';
        defaultLoan.Gross_Loan_Amount__c = 65000;
        defaultLoan.Date_Loan_Issued__c = system.today();
        defaultLoan.Term__c = 20;
        // defaultLoan.Total_Charges_on_Loan__c = .Id;
        
        return defaultLoan;
    }
    
    public static Loan_Charge__c createReleaseChargeLoanCharge(Account Acc, Loan__c Loan){
        Loan_Charge__c ReleaseChargeLC = new Loan_Charge__c();
        ReleaseChargeLC.Date__c = system.today();
        ReleaseChargeLC.Charge_Type__c = 'Release Charge';
        ReleaseChargeLC.Amount__c = 500;
        ReleaseChargeLC.Loan__c = Loan.id;
        
        return ReleaseChargeLC;
    }
    
    public static Loan_Charge__c createInterestChargeLoanCharge(Account Acc, Loan__c Loan){
        Loan_Charge__c InterestChargeLC = new Loan_Charge__c();
        InterestChargeLC.Date__c = system.today();
        InterestChargeLC.Charge_Type__c = 'Interest charge';
        InterestChargeLC.Amount__c = 750;
        InterestChargeLC.Loan__c = Loan.id;
        
        return InterestChargeLC;
    }
    
    public static Loan_Charge__c createInterestChargeCompetingWithReleaseLoanChargeDate(Account Acc, Loan__c Loan, Loan_charge__c ReleaseLoanCharge){
        Loan_Charge__c InterestChargeLC = new Loan_Charge__c();
        InterestChargeLC.Date__c = ReleaseLoanCharge.Date__c;
        InterestChargeLC.Charge_Type__c = 'Interest charge';
        InterestChargeLC.Amount__c = 750;
        InterestChargeLC.Loan__c = Loan.id;
        
        return InterestChargeLC;
    }
    
    public static Loan_Charge__c createLegalFeeLoanCharge(Account Acc, Loan__c Loan, Loan_charge__c ReleaseLoanCharge){
        Loan_Charge__c LegalFeeLC = new Loan_Charge__c();
        LegalFeeLC.Date__c = ReleaseLoanCharge.Date__c.Addmonths(2);
        LegalFeeLC.Charge_Type__c = 'Legal Fee';
        LegalFeeLC.Amount__c = 1000;
        LegalFeeLC.Loan__c = Loan.id;
        
        return LegalFeeLC;
    }
    
    public static Loan_Charge__c createAdminFeeLoanCharge(Account Acc, Loan__c Loan){
        Loan_Charge__c AdminFeeLC = new Loan_Charge__c();
        AdminFeeLC.Date__c = system.today();
        AdminFeeLC.Charge_Type__c = 'Admin Fee';
        AdminFeeLC.Amount__c = 250;
        AdminFeeLC.Loan__c = Loan.id;
        
        return AdminFeeLC;
    }
    
    @istest
    public static void createLoanWithoutExplicitLoanCharge(){
        account a = createDefaultAccount();
        insert a;
        loan__c l = createDefaultLoan(a);
        
        Test.startTest();
        insert l;
        List<Loan_Charge__c> releaseChargeLC = [SELECT ID, Charge_Type__c,Loan__c from Loan_Charge__c where loan__c =: l.id];
        System.debug('Loan Found! Loan: ' + l);
        System.debug('Loan Charge Found! Loan Charge: ' + releaseChargeLC);
        System.Assert(
            releaseChargeLC[0].Loan__c == l.id && 
            releaseChargeLC[0].Charge_Type__c == 'Release Charge' &&
            releaseChargeLC[0].id != null,
            'Error - An ID was not found, the expected Loan was not related, the Total Charges On Loan was incorrect, or the Charge Type was not of Release Charge value'
        );
        Test.stopTest();
    }
    
    @istest
    public static void createLoanAndInterestLoanCharge(){
        account a = createDefaultAccount();
        insert a;
        loan__c l = createDefaultLoan(a);
        
        Test.startTest();
        insert l;
        Loan_charge__c lc = createInterestChargeLoanCharge(a,l);
        insert lc;
        List<Loan_Charge__c> releaseChargeLC = [SELECT ID, Charge_Type__c,Loan__c,amount__c, Loan__r.Total_Charges_on_the_loan__c,date__c  from Loan_Charge__c where loan__c =: l.id AND Charge_Type__c = 'Release Charge'];
        List<Loan_Charge__c> interestChargeLC = [SELECT ID, Charge_Type__c,Loan__c, amount__c, date__c from Loan_Charge__c where loan__c =: l.id AND Charge_Type__c = 'Interest Charge'];
        
        System.debug('Loan Found! Loan: ' + l);
        System.debug('Release Loan Charge Found! Loan Charge: ' + releaseChargeLC);
        System.debug('Interest Loan Charge Found! Loan Charge: ' + interestChargeLC);
        System.debug('Loan Total Amount: '+ l.Total_Charges_on_the_loan__c);
        
        System.Assert(
            releaseChargeLC[0].Loan__c == l.id && 
            interestChargeLC[0].Loan__c == l.id, 
            'Error - An ID was not found, or the Loan Charge was not of Release/Interest Charge value'
        );
        Test.stopTest();
    }
    
    @istest
    public static void createDuplicateReleaseCharge(){
        account a = createDefaultAccount();
        insert a;
        loan__c l = createDefaultLoan(a);
        
        Test.startTest();
        insert l;
        
        List<Loan_Charge__c> releaseChargeLC = [SELECT ID, Charge_Type__c,Loan__c,amount__c, Loan__r.Total_Charges_on_the_loan__c,date__c  from Loan_Charge__c where loan__c =: l.id AND Charge_Type__c = 'Release Charge'];
        
        System.debug('Loan Found! Loan: ' + l);
        System.debug('Release Loan Charge Found! Loan Charge: ' + releaseChargeLC);
        Loan_charge__c rc = createReleaseChargeLoanCharge(a,l);
        
        try{
            insert rc;
        } catch (exception e) {
            System.debug('Caught expected error: ' + e);
            System.assert(
                e.getMessage().contains('A Release Charge Loan Charge has been detected for this Loan.'),
                'Expected error message not found. Here is the actual: ' + e);
        }        
        Test.stopTest();
    }
    
}