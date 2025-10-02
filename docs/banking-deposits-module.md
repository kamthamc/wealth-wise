# Banking & Deposits Module

## Overview

The Banking & Deposits Module provides comprehensive management of banking accounts, fixed deposits, and cash holdings with sophisticated interest calculation engines. This module supports multi-currency operations, maturity tracking, and Indian banking compliance requirements.

## Features

### 1. Bank Account Management
- **Account Types**: Savings, Current, Salary, NRI, Foreign accounts
- **Balance Tracking**: Real-time balance with overdraft support
- **Interest Calculation**: Both simple and compound interest
- **Multi-Currency**: Support for multiple currencies per account
- **Joint Accounts**: Multiple account holder tracking
- **Tax Compliance**: PAN, TDS, Form 15G/15H support

### 2. Fixed Deposit Tracking
- **CRUD Operations**: Create, read, update, delete FDs
- **Maturity Tracking**: Automatic maturity date calculation
- **Maturity Alerts**: 30-day advance alerts (configurable)
- **Interest Calculation**: Multiple compounding frequencies
- **Premature Withdrawal**: Calculate penalties and effective returns
- **Auto-Renewal**: Configurable renewal instructions
- **Multiple Types**: Regular, Tax-Saving, Senior Citizen, NRI, Cumulative, Non-Cumulative

### 3. Cash Holdings
- **Multi-Currency**: Track cash in multiple currencies
- **Physical Cash**: Denomination-level tracking
- **Location Management**: Wallet, Safe, Locker, Office, etc.
- **Exchange Rates**: Real-time currency conversion
- **Purpose Classification**: Emergency, Travel, Business, etc.
- **Security Tracking**: Insurance and security measures

### 4. Interest Calculation Engine
- **Simple Interest**: Traditional simple interest calculations
- **Compound Interest**: Various compounding frequencies
- **FD Maturity**: Accurate maturity amount calculations
- **RD Maturity**: Recurring deposit calculations
- **Savings Interest**: Quarterly interest for savings accounts
- **TDS Calculation**: Automatic tax deduction calculation
- **Comparison**: Compare multiple deposit options

## Usage Examples

### Creating a Bank Account

```swift
import WealthWise

// Create a savings account
let savingsAccount = BankAccount(
    accountName: "HDFC Savings Account",
    accountNumber: "12345678901",
    accountType: .savings,
    bankName: "HDFC Bank",
    branchName: "Koramangala Branch",
    ifscCode: "HDFC0001234",
    currentBalance: 50000,
    currency: "INR",
    minimumBalance: 1000,
    interestRate: 3.5,
    interestCalculationType: .compound,
    accountHolderName: "John Doe",
    taxResidencyCountry: "IND"
)

// Update balance
savingsAccount.updateBalance(newBalance: 55000)

// Calculate interest earned
let interestEarned = savingsAccount.calculateInterestEarned(days: 90)
print("Interest for quarter: \(interestEarned)")

// Credit interest
savingsAccount.creditInterest(amount: interestEarned)
```

### Creating a Fixed Deposit

```swift
// Create a 1-year fixed deposit
let fixedDeposit = FixedDeposit(
    depositName: "SBI 1 Year FD",
    certificateNumber: "FD123456",
    bankName: "State Bank of India",
    branchName: "Main Branch",
    principalAmount: 100000,
    currency: "INR",
    interestRate: 6.5,
    compoundingFrequency: .quarterly,
    tenureInMonths: 12,
    depositType: .regular,
    autoRenew: false,
    interestPayoutMode: .onMaturity
)

// Check maturity details
print("Maturity Amount: \(fixedDeposit.displayMaturityAmount)")
print("Interest Earned: \(fixedDeposit.interestEarned)")
print("Days to Maturity: \(fixedDeposit.daysToMaturity)")
print("Progress: \(fixedDeposit.progressPercentage)%")

// Check if alert should be shown
if fixedDeposit.shouldShowMaturityAlert {
    print("⚠️ FD maturing soon!")
}

// Calculate premature withdrawal
let withdrawalResult = fixedDeposit.calculatePrematureWithdrawal()
print("Premature withdrawal amount: \(withdrawalResult.displayWithdrawalAmount)")
print("Penalty: \(withdrawalResult.penaltyAmount)")

// Mark as matured when time comes
fixedDeposit.markAsMatured()

// Renew the deposit
fixedDeposit.renew(newInterestRate: 7.0)
```

### Creating Cash Holdings

```swift
// Create daily wallet cash
let walletCash = CashHolding(
    name: "Daily Wallet",
    holdingType: .wallet,
    amount: 5000,
    currency: "INR",
    location: .wallet,
    purpose: .general
)

// Add denomination details
walletCash.addDenomination(value: 500, count: 6)  // 6 × ₹500
walletCash.addDenomination(value: 200, count: 5)  // 5 × ₹200
walletCash.addDenomination(value: 100, count: 10) // 10 × ₹100

// Verify consistency
if walletCash.isDenominationConsistent {
    print("✓ Cash denomination matches total")
}

// Create foreign currency holding
let usdCash = CashHolding(
    name: "US Dollars",
    holdingType: .foreign,
    amount: 500,
    currency: "USD",
    baseCurrency: "INR",
    purpose: .travel
)

// Update with exchange rate
usdCash.updateAmount(500, exchangeRate: 83.5)
print("INR equivalent: \(usdCash.displayBaseCurrencyAmount)")

// Create emergency fund
let emergencyFund = CashHolding(
    name: "Emergency Fund",
    holdingType: .emergency,
    amount: 50000,
    location: .safe,
    purpose: .emergency
)
emergencyFund.isEmergencyFund = true
emergencyFund.targetEmergencyAmount = 100000
emergencyFund.isSecured = true
```

### Using Interest Calculator Service

```swift
let calculator = InterestCalculatorService.shared

// Calculate simple interest
let simpleResult = calculator.calculateSimpleInterest(
    principal: 100000,
    annualRate: 0.06,
    timeInYears: 2
)
print("Simple Interest: \(simpleResult.displayInterest)")

// Calculate compound interest
let compoundResult = calculator.calculateCompoundInterest(
    principal: 100000,
    annualRate: 0.065,
    timeInYears: 1,
    compoundingFrequency: .quarterly
)
print("Maturity Amount: \(compoundResult.futureValue)")

// Calculate FD maturity
let fdResult = calculator.calculateFixedDepositMaturity(
    principal: 100000,
    annualRate: 6.5,
    tenureMonths: 12,
    compoundingFrequency: .quarterly,
    isInterestPaidOut: false
)
print("FD Maturity: \(fdResult.displayMaturityAmount)")

// Calculate recurring deposit
let rdResult = calculator.calculateRecurringDepositMaturity(
    monthlyInstallment: 5000,
    annualRate: 6.0,
    tenureMonths: 12
)
print("RD Maturity: \(rdResult.displayMaturityAmount)")
print("Total Principal: \(rdResult.totalPrincipal)")
print("Interest Earned: \(rdResult.interestEarned)")

// Calculate savings account interest
let savingsInterest = calculator.calculateSavingsAccountInterest(
    averageBalance: 50000,
    annualRate: 3.5,
    days: 90
)
print("Quarterly Interest: \(savingsInterest)")

// Calculate TDS
let tds = calculator.calculateTDS(
    interestAmount: 50000,
    tdsRate: 10,
    form15Submitted: false
)
print("TDS Deducted: \(tds)")

// Compare deposit options
let options = [
    DepositOption(
        bankName: "HDFC Bank",
        depositType: "Regular FD",
        interestRate: 6.5,
        tenureMonths: 12,
        compoundingFrequency: .quarterly
    ),
    DepositOption(
        bankName: "SBI",
        depositType: "Regular FD",
        interestRate: 6.8,
        tenureMonths: 12,
        compoundingFrequency: .quarterly
    ),
    DepositOption(
        bankName: "ICICI Bank",
        depositType: "Regular FD",
        interestRate: 6.3,
        tenureMonths: 12,
        compoundingFrequency: .monthly
    )
]

let comparison = calculator.compareDepositOptions(amount: 100000, options: options)
for result in comparison {
    print("\(result.bankName): \(result.result.displayMaturityAmount) (ROI: \(result.returnOnInvestment)%)")
}
```

### Tax Compliance

```swift
// Bank account with tax details
let account = BankAccount(
    accountName: "Savings Account",
    accountNumber: "123456",
    accountType: .savings,
    bankName: "HDFC Bank",
    currentBalance: 100000,
    accountHolderName: "Tax Payer"
)
account.panNumber = "ABCDE1234F"
account.isTaxable = true
account.tdsApplicable = false

// Fixed deposit with TDS
let taxSavingFD = FixedDeposit(
    depositName: "Tax Saving FD",
    bankName: "SBI",
    principalAmount: 150000,
    interestRate: 6.5,
    tenureInMonths: 60, // 5 years lock-in
    depositType: .tax_saving
)
taxSavingFD.panNumber = "ABCDE1234F"
taxSavingFD.tdsApplicable = true
taxSavingFD.tdsRate = 10
taxSavingFD.form15GSubmitted = false

// Calculate TDS
if taxSavingFD.tdsApplicable {
    let interest = taxSavingFD.interestEarned
    let tds = calculator.calculateTDS(
        interestAmount: interest,
        tdsRate: taxSavingFD.tdsRate,
        form15Submitted: taxSavingFD.form15GSubmitted
    )
    taxSavingFD.tdsDeducted = tds
}
```

## Integration with Existing Systems

### With AssetType Enum

```swift
// Fixed deposits and savings accounts are already defined in AssetType
let fdAsset = CrossBorderAsset.createDomesticAsset(
    name: "SBI Fixed Deposit",
    assetType: .fixedDeposits,
    countryCode: "IND",
    currentValue: fixedDeposit.maturityAmount,
    currencyCode: "INR"
)

let savingsAsset = CrossBorderAsset.createDomesticAsset(
    name: "HDFC Savings",
    assetType: .savingsAccount,
    countryCode: "IND",
    currentValue: savingsAccount.currentBalance,
    currencyCode: "INR"
)
```

### With Transaction System

```swift
// Link transactions to bank accounts
let transaction = Transaction(
    amount: 5000,
    currency: "INR",
    transactionDescription: "Interest Credit",
    date: Date(),
    transactionType: .income,
    category: .interest_income,
    accountType: .bank
)
transaction.accountId = savingsAccount.id.uuidString

// Link to bank account
savingsAccount.transactions?.append(transaction)
```

### With Goal Tracking

```swift
// Link FD to goal
let goal = Goal(
    title: "Emergency Fund Goal",
    targetAmount: 500000,
    targetCurrency: "INR",
    targetDate: Calendar.current.date(byAdding: .year, value: 2, to: Date())!
)

// FD contributes to goal
let fdContribution = fixedDeposit.maturityAmount
// Link in goal tracking system
```

## Data Models

### BankAccount Properties
- `accountName`: Account display name
- `accountNumber`: Bank account number
- `accountType`: Savings, Current, Salary, etc.
- `bankName`: Name of the bank
- `branchName`: Branch location
- `ifscCode`: Indian Financial System Code
- `currentBalance`: Current balance
- `availableBalance`: Available balance (considering holds)
- `currency`: Account currency
- `minimumBalance`: Required minimum balance
- `overdraftLimit`: Overdraft facility (optional)
- `interestRate`: Annual interest rate
- `interestCalculationType`: Simple or Compound
- `totalInterestEarned`: Total interest credited

### FixedDeposit Properties
- `depositName`: FD display name
- `certificateNumber`: FD certificate number
- `bankName`: Name of the bank
- `principalAmount`: Initial deposit amount
- `interestRate`: Annual interest rate
- `compoundingFrequency`: Monthly, Quarterly, Half-yearly, Annual
- `depositDate`: Date of deposit
- `maturityDate`: Calculated maturity date
- `tenureInMonths`: Tenure in months
- `maturityAmount`: Calculated maturity amount
- `interestEarned`: Total interest earned
- `autoRenew`: Auto-renewal preference
- `depositType`: Regular, Tax-Saving, Senior Citizen, etc.

### CashHolding Properties
- `name`: Cash holding name
- `holdingType`: Physical, Wallet, Safe, Locker, etc.
- `amount`: Amount in original currency
- `currency`: Currency code
- `location`: Physical location
- `baseCurrency`: Base currency for conversion
- `baseCurrencyAmount`: Amount in base currency
- `exchangeRate`: Current exchange rate
- `denominations`: Array of denomination details
- `purpose`: General, Emergency, Travel, Business, etc.

## Compliance & Security

### Indian Banking Requirements
- **PAN Number**: Required for all accounts and FDs above threshold
- **TDS**: Automatic TDS calculation for interest > ₹40,000
- **Form 15G/15H**: Support for TDS exemption forms
- **IFSC Code**: Bank branch identification
- **Tax Residency**: Country-specific tax compliance

### Security Features
- **Encryption**: All sensitive data encrypted at rest
- **Biometric Auth**: Required for high-value transactions
- **Location Tracking**: Physical cash security levels
- **Insurance**: Optional insurance coverage tracking
- **Audit Trail**: All changes tracked with timestamps

## Performance Considerations

- **Calculation Caching**: Interest calculations cached where appropriate
- **Lazy Loading**: Large datasets loaded on demand
- **Background Processing**: Heavy calculations offloaded to background
- **Optimized Queries**: Database queries optimized for performance

## Best Practices

1. **Always validate balances**: Ensure balance updates maintain consistency
2. **Set maturity alerts**: Configure advance alerts for FD maturity
3. **Track denominations**: For physical cash, maintain denomination details
4. **Regular verification**: Periodically verify cash holdings
5. **Tax compliance**: Keep PAN and TDS information up to date
6. **Currency updates**: Update exchange rates regularly for foreign currency
7. **Security measures**: Document security arrangements for high-value holdings
8. **Backup information**: Maintain copies of certificates and statements

## Testing

The module includes 105 comprehensive tests covering:
- Model initialization and defaults
- Interest calculations (simple & compound)
- Maturity tracking and alerts
- Premature withdrawal calculations
- Multi-currency support
- Denomination tracking
- Tax compliance
- Edge cases and performance

Run tests with:
```bash
xcodebuild -project WealthWise.xcodeproj -scheme WealthWise test
```

## Future Enhancements

- [ ] Bank statement import/parsing
- [ ] Automatic balance sync with bank APIs
- [ ] Interest rate trend analysis
- [ ] FD ladder strategy recommendations
- [ ] Cash flow forecasting
- [ ] Automatic tax report generation
- [ ] Integration with accounting software
- [ ] Recurring deposit tracking
- [ ] Sweep-in/sweep-out facility support

## Support

For issues, feature requests, or questions:
- GitHub Issues: [wealth-wise/issues](https://github.com/kamthamc/wealth-wise/issues)
- Documentation: [WealthWise Docs](../README.md)
