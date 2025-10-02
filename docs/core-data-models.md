# Core Data Entity Models Documentation

## Overview

This document describes the Core Data entity models defined in `WealthWiseDataModel.xcdatamodeld` for the WealthWise application. The data model provides comprehensive support for portfolio management with specialized entities for different asset types including commodities, real estate, bonds, chit funds, fixed deposits, and cash holdings.

## Entity Hierarchy

```
Portfolio (Root entity for organizing assets)
    ↓
Asset (Abstract base entity)
    ├── Commodity (Gold, Silver, Platinum, etc.)
    ├── RealEstate (Residential, Commercial properties)
    ├── Bond (Government, Corporate bonds)
    ├── ChitFund (Traditional Indian investment scheme)
    ├── FixedDeposit (Bank FDs and RDs)
    └── CashHolding (Savings, Current accounts, Cash)

Transaction (Records asset transactions)
```

## Entity Details

### 1. Portfolio Entity

**Purpose**: Organizes and groups assets into portfolios for better management and tracking.

**Attributes**:
- `id` (UUID): Unique identifier
- `name` (String): Portfolio name
- `portfolioDescription` (String, optional): Detailed description
- `currency` (String): Base currency for portfolio (default: "INR")
- `totalValue` (Decimal): Computed total value of all assets
- `isDefault` (Boolean): Whether this is the default portfolio
- `createdAt` (Date): Creation timestamp
- `updatedAt` (Date): Last update timestamp

**Relationships**:
- `assets` (one-to-many): Collection of assets in this portfolio
- `transactions` (one-to-many): Collection of transactions in this portfolio

**Example Usage**:
```swift
let portfolio = PortfolioEntity.create(
    in: context,
    name: "Investment Portfolio",
    currency: "INR",
    description: "My primary investment portfolio",
    isDefault: true
)
```

### 2. Asset Entity (Abstract)

**Purpose**: Base entity for all asset types, providing common attributes and behavior.

**Attributes**:
- `id` (UUID): Unique identifier
- `name` (String): Asset name
- `symbol` (String, optional): Trading symbol or identifier
- `assetType` (String): Type of asset (e.g., "commodity", "realEstate")
- `assetCategory` (String): Category classification
- `currentValue` (Decimal): Current market value
- `purchasePrice` (Decimal, optional): Original purchase price
- `purchaseDate` (Date, optional): Date of acquisition
- `quantity` (Decimal, optional): Quantity held
- `currency` (String): Currency of valuation (default: "INR")
- `isActive` (Boolean): Whether asset is actively held
- `encryptedAccountNumber` (Binary, optional): Encrypted account number
- `encryptedNotes` (Binary, optional): Encrypted user notes
- `createdAt` (Date): Creation timestamp
- `updatedAt` (Date): Last update timestamp

**Relationships**:
- `portfolio` (many-to-one): Parent portfolio
- `transactions` (one-to-many): Related transactions

**Computed Properties**:
- `unrealizedGainLoss`: Current value - Purchase price
- `unrealizedGainLossPercentage`: Gain/loss as percentage

### 3. Commodity Entity

**Purpose**: Represents physical commodities like gold, silver, and other precious metals.

**Inherits from**: Asset

**Additional Attributes**:
- `commodityType` (String): Type of commodity (gold, silver, platinum, etc.)
- `weight` (Decimal, optional): Physical weight
- `unit` (String): Unit of measurement (gram, kg, troy ounce)
- `purity` (String, optional): Purity specification (e.g., "24K", "999")
- `storageLocation` (String, optional): Where commodity is stored

**Example Usage**:
```swift
let gold = CommodityEntity.create(
    in: context,
    name: "Gold Bars",
    commodityType: .gold,
    quantity: 100,
    unit: "gram",
    currentValue: 500000,
    currency: "INR"
)
gold.purity = "24K"
gold.storageLocation = "Bank Locker"
```

**Supported Commodity Types**:
- Gold (physical, ETF)
- Silver
- Platinum
- Palladium
- Copper
- Oil
- Other commodities

### 4. RealEstate Entity

**Purpose**: Represents residential, commercial, and other real estate holdings.

**Inherits from**: Asset

**Additional Attributes**:
- `propertyType` (String): Type of property (residential, commercial, agricultural, industrial, plot)
- `address` (String, optional): Property address
- `city` (String, optional): City location
- `state` (String, optional): State/province
- `country` (String): Country (default: "India")
- `zipCode` (String, optional): Postal code
- `areaInSqFt` (Decimal, optional): Property area in square feet
- `registrationNumber` (String, optional): Property registration number
- `annualRentalIncome` (Decimal, optional): Annual rental income if applicable
- `isPrimaryResidence` (Boolean): Whether this is primary residence
- `mortgageAmount` (Decimal, optional): Outstanding mortgage amount

**Example Usage**:
```swift
let apartment = RealEstateEntity.create(
    in: context,
    name: "Apartment in Mumbai",
    propertyType: .residential,
    currentValue: 5000000,
    address: "123 Marine Drive",
    city: "Mumbai",
    state: "Maharashtra"
)
apartment.areaInSqFt = 1200 as NSDecimalNumber
apartment.annualRentalIncome = 360000 as NSDecimalNumber
apartment.isPrimaryResidence = true
```

**Computed Properties**:
- `rentalYield`: Annual rental income / Current value (%)
- `netEquity`: Current value - Mortgage amount

### 5. Bond Entity

**Purpose**: Represents government and corporate bonds, fixed income securities.

**Inherits from**: Asset

**Additional Attributes**:
- `bondType` (String): Type of bond (government, corporate, municipal, convertible, zeroCoupon)
- `issuer` (String, optional): Bond issuer name
- `isin` (String, optional): International Securities Identification Number
- `faceValue` (Decimal, optional): Par value of bond
- `couponRate` (Decimal, optional): Annual coupon rate (%)
- `maturityDate` (Date, optional): Bond maturity date
- `interestFrequency` (String, optional): Interest payment frequency
- `nextCouponDate` (Date, optional): Next coupon payment date
- `yieldToMaturity` (Decimal, optional): Yield to maturity (%)
- `rating` (String, optional): Credit rating (e.g., "AAA", "AA+")

**Example Usage**:
```swift
let govtBond = BondEntity.create(
    in: context,
    name: "Government Bond 2029",
    bondType: .government,
    issuer: "Government of India",
    faceValue: 100000,
    couponRate: 7.5,
    maturityDate: Date().addingTimeInterval(5 * 365 * 24 * 60 * 60),
    currentValue: 102000
)
govtBond.rating = "AAA"
govtBond.interestFrequency = "semiAnnual"
```

**Computed Properties**:
- `annualInterest`: Face value × Coupon rate / 100
- `currentYield`: Annual interest / Current value (%)
- `hasMatured`: Whether maturity date has passed

### 6. ChitFund Entity

**Purpose**: Represents chit funds, a traditional Indian savings and credit scheme.

**Inherits from**: Asset

**Additional Attributes**:
- `chitValue` (Decimal): Total chit fund value
- `monthlyContribution` (Decimal): Monthly contribution amount
- `totalMonths` (Int16): Total duration in months
- `totalMembers` (Int16): Number of members in the chit
- `currentMonth` (Int16): Current month number
- `startDate` (Date, optional): Chit start date
- `hasReceivedPrize` (Boolean): Whether prize has been received
- `prizeReceivedMonth` (Int16, optional): Month when prize was received
- `prizeReceivedDate` (Date, optional): Date when prize was received
- `forepersonName` (String, optional): Name of chit foreman
- `registrationNumber` (String, optional): Registration number

**Example Usage**:
```swift
let chitFund = ChitFundEntity.create(
    in: context,
    name: "Community Chit Fund",
    chitValue: 100000,
    monthlyContribution: 5000,
    totalMonths: 20,
    totalMembers: 20,
    startDate: Date()
)
chitFund.forepersonName = "John Doe"
chitFund.registrationNumber = "CHIT/2024/001"
```

**Computed Properties**:
- `totalPaid`: Monthly contribution × Current month
- `remainingMonths`: Total months - Current month
- `isComplete`: Whether chit fund has completed all months
- `expectedMaturityValue`: Total chit value

### 7. FixedDeposit Entity

**Purpose**: Represents fixed deposits, recurring deposits, and similar bank instruments.

**Inherits from**: Asset

**Additional Attributes**:
- `bankName` (String): Name of the bank
- `accountNumber` (String, optional): FD account number
- `depositType` (String): Type of deposit (fixedDeposit, recurringDeposit, taxSaverFD, seniorCitizenFD)
- `interestRate` (Decimal): Annual interest rate (%)
- `tenure` (Int16): Tenure in months
- `maturityDate` (Date): Date of maturity
- `maturityAmount` (Decimal, optional): Calculated maturity amount
- `interestFrequency` (String): Interest compounding frequency (monthly, quarterly, halfYearly, annual, maturity)
- `autoRenewal` (Boolean): Whether FD auto-renews on maturity
- `nomineeDetails` (String, optional): Nominee information

**Example Usage**:
```swift
let fixedDeposit = FixedDepositEntity.create(
    in: context,
    name: "HDFC Fixed Deposit",
    bankName: "HDFC Bank",
    depositType: .fixedDeposit,
    principalAmount: 100000,
    interestRate: 7.0,
    tenure: 12,
    maturityDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
    interestFrequency: .quarterly
)
fixedDeposit.accountNumber = "FD123456789"
fixedDeposit.autoRenewal = true
```

**Computed Properties**:
- `expectedReturn`: Maturity amount - Principal
- `hasMatured`: Whether maturity date has passed
- `daysUntilMaturity`: Days remaining until maturity

### 8. CashHolding Entity

**Purpose**: Represents bank accounts, cash in hand, and liquid cash equivalents.

**Inherits from**: Asset

**Additional Attributes**:
- `accountType` (String): Type of account (savings, current, salary, cashInHand, moneyMarket)
- `bankName` (String, optional): Bank name
- `accountNumber` (String, optional): Account number
- `branchName` (String, optional): Bank branch name
- `ifscCode` (String, optional): IFSC code (India)
- `minimumBalance` (Decimal, optional): Required minimum balance
- `interestRate` (Decimal, optional): Interest rate on balance
- `isLinkedUPI` (Boolean): Whether linked to UPI
- `lastUpdated` (Date, optional): Last balance update date

**Example Usage**:
```swift
let savingsAccount = CashHoldingEntity.create(
    in: context,
    name: "SBI Savings Account",
    accountType: .savings,
    currentBalance: 50000,
    bankName: "State Bank of India",
    accountNumber: "123456789012"
)
savingsAccount.ifscCode = "SBIN0001234"
savingsAccount.minimumBalance = 10000 as NSDecimalNumber
savingsAccount.isLinkedUPI = true
```

**Computed Properties**:
- `isBelowMinimum`: Whether balance is below minimum required
- `excessBalance`: Balance above minimum requirement

### 9. Transaction Entity

**Purpose**: Records all transactions related to assets and portfolios.

**Attributes**:
- `id` (UUID): Unique identifier
- `transactionType` (String): Type of transaction (buy, sell, deposit, withdrawal, dividend, interest, fee, transfer)
- `amount` (Decimal): Transaction amount
- `price` (Decimal, optional): Price per unit
- `quantity` (Decimal, optional): Quantity transacted
- `transactionDate` (Date): Date of transaction
- `encryptedReference` (Binary, optional): Encrypted reference number
- `encryptedNotes` (Binary, optional): Encrypted transaction notes
- `createdAt` (Date): Creation timestamp

**Relationships**:
- `asset` (many-to-one): Related asset
- `portfolio` (many-to-one): Related portfolio

**Example Usage**:
```swift
let transaction = TransactionEntity.create(
    in: context,
    type: .buy,
    amount: 50000,
    date: Date(),
    asset: goldAsset,
    portfolio: mainPortfolio
)
transaction.quantity = 10 as NSDecimalNumber
transaction.price = 5000 as NSDecimalNumber
```

## Relationships and Cascade Rules

### Portfolio → Assets (One-to-Many)
- **Deletion Rule**: Cascade
- When a portfolio is deleted, all its assets are also deleted

### Portfolio → Transactions (One-to-Many)
- **Deletion Rule**: Cascade
- When a portfolio is deleted, all its transactions are also deleted

### Asset → Transactions (One-to-Many)
- **Deletion Rule**: Cascade
- When an asset is deleted, all its transactions are also deleted

### Asset → Portfolio (Many-to-One)
- **Deletion Rule**: Nullify
- When an asset is deleted, the portfolio relationship is set to nil

## Data Encryption

Sensitive fields are stored as encrypted binary data:

- **Asset Entity**:
  - `encryptedAccountNumber`: Account numbers and identifiers
  - `encryptedNotes`: User notes and comments

- **Transaction Entity**:
  - `encryptedReference`: Transaction reference numbers
  - `encryptedNotes`: Transaction notes

Encryption is handled automatically using AES-256-GCM via the Core Data transformers.

## Usage Examples

### Creating a Complete Portfolio

```swift
// Create portfolio
let portfolio = PortfolioEntity.create(
    in: context,
    name: "My Investment Portfolio",
    currency: "INR",
    isDefault: true
)

// Add gold investment
let gold = CommodityEntity.create(
    in: context,
    name: "Gold Coins",
    commodityType: .gold,
    quantity: 50,
    unit: "gram",
    currentValue: 250000
)
gold.portfolio = portfolio

// Add property
let apartment = RealEstateEntity.create(
    in: context,
    name: "Mumbai Apartment",
    propertyType: .residential,
    currentValue: 5000000
)
apartment.portfolio = portfolio

// Add fixed deposit
let fd = FixedDepositEntity.create(
    in: context,
    name: "SBI FD",
    bankName: "State Bank of India",
    depositType: .fixedDeposit,
    principalAmount: 500000,
    interestRate: 7.0,
    tenure: 12,
    maturityDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
    interestFrequency: .quarterly
)
fd.portfolio = portfolio

// Save context
try context.save()

// Calculate total portfolio value
portfolio.updateTotalValue()
print("Total Portfolio Value: \(portfolio.totalValue)")
```

### Recording Transactions

```swift
// Buy gold transaction
let buyGold = TransactionEntity.create(
    in: context,
    type: .buy,
    amount: 250000,
    date: Date(),
    asset: gold,
    portfolio: portfolio
)
buyGold.quantity = 50 as NSDecimalNumber
buyGold.price = 5000 as NSDecimalNumber

// Receive FD interest
let fdInterest = TransactionEntity.create(
    in: context,
    type: .interest,
    amount: 8750,
    date: Date(),
    asset: fd,
    portfolio: portfolio
)

try context.save()
```

### Querying Assets

```swift
// Fetch all active assets in a portfolio
let fetchRequest: NSFetchRequest<AssetEntity> = AssetEntity.fetchRequest()
fetchRequest.predicate = NSPredicate(
    format: "portfolio == %@ AND isActive == YES",
    portfolio
)
let assets = try context.fetch(fetchRequest)

// Fetch all commodities
let commodityFetch: NSFetchRequest<CommodityEntity> = CommodityEntity.fetchRequest()
let commodities = try context.fetch(commodityFetch)

// Fetch maturing fixed deposits
let fdFetch: NSFetchRequest<FixedDepositEntity> = FixedDepositEntity.fetchRequest()
fdFetch.predicate = NSPredicate(
    format: "maturityDate >= %@ AND maturityDate <= %@",
    Date() as NSDate,
    Calendar.current.date(byAdding: .month, value: 1, to: Date())! as NSDate
)
let maturingFDs = try context.fetch(fdFetch)
```

## Migration and Versioning

The current model version is **WealthWiseDataModel.xcdatamodel**.

To create a new model version:
1. Editor → Add Model Version in Xcode
2. Make schema changes in the new version
3. Create a mapping model if needed
4. Update `.xccurrentversion` to point to new version

## Testing

Comprehensive unit tests are provided in `CoreDataEntitiesTests.swift`:

- Entity creation and validation
- Computed properties and calculations
- Relationship integrity
- Cascade deletion behavior
- Performance benchmarks

Run tests using:
```bash
xcodebuild test -project WealthWise.xcodeproj -scheme WealthWise -destination "platform=macOS"
```

## Best Practices

1. **Always use helper methods**: Use the provided `create()` methods for entity creation
2. **Save context regularly**: Save after significant changes to prevent data loss
3. **Use background contexts**: For heavy operations, use background contexts
4. **Validate data**: Validate input data before saving
5. **Handle errors**: Always handle Core Data errors appropriately
6. **Encrypt sensitive data**: Use encrypted fields for account numbers and notes
7. **Update timestamps**: Keep `updatedAt` current when modifying entities
8. **Calculate derived values**: Update portfolio totals after asset changes

## Performance Considerations

1. **Batch operations**: Use batch fetch/update for large datasets
2. **Predicates**: Use efficient predicates to filter fetches
3. **Fault management**: Be aware of faulting behavior
4. **Relationship traversal**: Minimize deep relationship traversals
5. **Index attributes**: Key attributes are indexed for faster queries

## Security

1. All sensitive fields are encrypted using AES-256-GCM
2. Encryption keys are managed via iOS Keychain
3. Core Data store uses file protection on iOS
4. No sensitive data stored in plain text
5. Backup encryption recommended for cloud backups

## Future Enhancements

Planned additions to the data model:
- User entity for multi-user support
- Category entity for custom asset categorization
- Valuation entity for price history tracking
- Alert entity for notifications
- Audit log for compliance tracking
- Document storage for receipts and statements
