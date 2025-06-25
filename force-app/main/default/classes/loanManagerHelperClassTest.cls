@istest
public class loanManagerHelperClassTest {
    
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
    
    
    public static Loan_Charge__c createLegalFeeLoanCharge(Account Acc, Loan__c Loan){
        Loan_Charge__c LegalFeeLC = new Loan_Charge__c();
        LegalFeeLC.Date__c = system.today();
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
        List<Loan_Charge__c> releaseChargeLC = [SELECT ID, Charge_Type__c,Loan__c,date__c from Loan_Charge__c where loan__c =: l.id AND charge_type__c = 'Release Charge'];
        System.debug('Loan Found! Loan: ' + l);
        System.debug('Release Charge Loan Charge Found! Loan Charge: ' + releaseChargeLC);
        System.Assert(
            releaseChargeLC[0].Loan__c == l.id && 
            releaseChargeLC[0].Charge_Type__c == 'Release Charge' &&
            releaseChargeLC[0].id != null,
            'Error - An ID was not found, meaning the Loan Charge created (or not created) was not of Release Charge value');
        
        Test.stopTest();
    }
    
    @istest
    public static void updateLoanTerm(){
        account a = createDefaultAccount();
        insert a;
        loan__c l = createDefaultLoan(a);
        insert l;
        l.Term__c = 55;
        Test.startTest();
        List<Loan_Charge__c> allLoanCharges = [SELECT ID, Charge_Type__c,Loan__c,date__c from Loan_Charge__c where loan__c =: l.id];
        
        System.debug('All Loan Charges Created at beginning of Test '+ allLoanCharges);	
        List<Loan_Charge__c> releaseChargeLC = [SELECT ID, Charge_Type__c,Loan__c,date__c from Loan_Charge__c where loan__c =: l.id AND charge_type__c = 'Release Charge'];
        System.debug('Release Charge Date BEFORE Term amendment: ' + releaseChargeLC[0].date__c);
        
        update l;
        Loan__c updatedLoan = [SELECT Id, Term__c, Date_Loan_Issued__c FROM Loan__c WHERE Id = :l.Id];
        Date ExpectedDate = updatedLoan.Date_Loan_Issued__c.addmonths(75);
        
        releaseChargeLC = [SELECT ID, Charge_Type__c,Loan__c,date__c from Loan_Charge__c where loan__c =: l.id AND charge_type__c = 'Release Charge'];
        System.debug('Release Charge Date AFTER Term amendment: ' + releaseChargeLC[0].date__c);
        System.debug('Loan Found! Loan: ' + l);
        System.debug('Loan Charge Found! Loan Charge: ' + releaseChargeLC);
        allLoanCharges = [SELECT ID, Charge_Type__c,Loan__c,date__c from Loan_Charge__c where loan__c =: l.id];
        System.debug('All Loan Charges Created at end of Test '+ allLoanCharges);
        
        System.Assert(
            releaseChargeLC[0].Loan__c == l.id && 
            releaseChargeLC[0].id != null &&
            releaseChargeLC[0].date__c == ExpectedDate &&
            allLoanCharges.size() == 2, // 1 Release Charge via Loan Insertion & 1 Admin Fee via Term Amendment
            'Error - An ID was not found, or the date on the Release Charge was not as expected after the Term update.');
        
        Test.stopTest();
    }
    
    @istest
    public static void createLoanChargesToTestTotalChargesOnLoan(){
        account a = createDefaultAccount();
        insert a;
        loan__c l = createDefaultLoan(a); 
        Decimal expectedtotal = 0; 
        
        Test.startTest();
        insert l;
        Loan_Charge__c ic = createInterestChargeLoanCharge(a,l);
        Loan_Charge__c lf = createLegalFeeLoanCharge(a,l);
        insert ic;
        insert lf;
        
        List<Loan__c> Loan = [SELECT ID, Total_Charges_on_the_Loan__c,Gross_Loan_Amount__c,Balance_of_the_Loan__c from Loan__c where id =: l.id];
        System.debug('Loan Found! Loan: ' + Loan);
        System.debug('Finding all Loan Charges Relating to Loan in order to affirm that Loan Amount Fields are correct.');
        List<Loan_Charge__c> LoanCharges = [SELECT id, amount__c, Loan__c from Loan_Charge__c where Loan__c =: l.id];
        
        for(Loan_Charge__c lc : LoanCharges){
            expectedtotal = expectedtotal + lc.amount__c; 
        }
        
        expectedtotal = expectedtotal + l.Gross_Loan_Amount__c;
        
        system.debug('ExpectedTotal: '+ expectedtotal);
        system.debug('ActualTotal: '+ l.Balance_of_the_Loan__c); // value doesnt display in debug log but System.Assert Method verifies that the Roll-Up Works as expected.
        
        System.Assert(
            Loan[0].id != null &&
            expectedtotal == Loan[0].Balance_of_the_Loan__c,
            'Error - An ID was not found, or the calculation for the Total Balance Of the Loan was incorrect.');
        
        Test.stopTest();
    }
    
}