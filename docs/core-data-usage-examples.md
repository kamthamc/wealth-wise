# Core Data Usage Examples

## Quick Start Guide

This guide provides practical examples for using the Core Data entity models in WealthWise.

## Setup

### Accessing the Persistent Container

```swift
import CoreData
import WealthWise

// Access the shared persistent container
let container = PersistentContainer.shared
let context = container.viewContext
```

## Basic Portfolio Management

### Creating a Portfolio

```swift
// Create a new portfolio
let portfolio = PortfolioEntity.create(
    in: context,
    name: "Retirement Portfolio",
    currency: "INR",
    description: "Long-term retirement savings",
    isDefault: true
)

// Save the context
try context.save()
```

### Calculating Portfolio Value

```swift
// Update and retrieve portfolio total value
portfolio.updateTotalValue()
let totalValue = portfolio.totalValue as Decimal

print("Portfolio Value: ₹\(totalValue)")
```

## Asset Management Examples

### 1. Adding Physical Gold

```swift
// Create a gold commodity asset
let gold = CommodityEntity.create(
    in: context,
    name: "24K Gold Coins",
    commodityType: .gold,
    quantity: 50,
    unit: "gram",
    currentValue: 300000,
    currency: "INR"
)

// Add optional details
gold.purity = "24K"
gold.storageLocation = "Bank Locker - SBI Main Branch"
gold.purchasePrice = 280000 as NSDecimalNumber
gold.purchaseDate = Date()

// Link to portfolio
gold.portfolio = portfolio

// Record the purchase transaction
let buyGold = TransactionEntity.create(
    in: context,
    type: .buy,
    amount: 280000,
    date: Date(),
    asset: gold,
    portfolio: portfolio
)
buyGold.quantity = 50 as NSDecimalNumber
buyGold.price = 5600 as NSDecimalNumber

try context.save()

// Check gain/loss
if let gainLoss = gold.unrealizedGainLoss {
    print("Gain/Loss: ₹\(gainLoss)")
}

// Calculate value per gram
if let valuePerGram = gold.valuePerUnit {
    print("Current value per gram: ₹\(valuePerGram)")
}
```

### 2. Adding Real Estate Property

```swift
// Create a residential property
let apartment = RealEstateEntity.create(
    in: context,
    name: "Apartment - Koramangala",
    propertyType: .residential,
    currentValue: 8500000,
    address: "123, 5th Block, Koramangala",
    city: "Bangalore",
    state: "Karnataka"
)

// Add property details
apartment.areaInSqFt = 1400 as NSDecimalNumber
apartment.registrationNumber = "REG/BLR/2020/123456"
apartment.purchasePrice = 7000000 as NSDecimalNumber
apartment.purchaseDate = Calendar.current.date(byAdding: .year, value: -3, to: Date())
apartment.isPrimaryResidence = true

// Add mortgage details if applicable
apartment.mortgageAmount = 2000000 as NSDecimalNumber

// Link to portfolio
apartment.portfolio = portfolio

try context.save()

// Calculate net equity
if let equity = apartment.netEquity {
    print("Net Equity: ₹\(equity)")
}

// If it's a rental property, add rental income
apartment.annualRentalIncome = 480000 as NSDecimalNumber

// Calculate rental yield
if let yield = apartment.rentalYield {
    print("Rental Yield: \(yield)%")
}
```

### 3. Adding Government Bonds

```swift
// Create a government bond
let maturityDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!

let bond = BondEntity.create(
    in: context,
    name: "Government of India Bond 2029",
    bondType: .government,
    issuer: "Government of India",
    faceValue: 100000,
    couponRate: 7.5,
    maturityDate: maturityDate,
    currentValue: 102500
)

// Add bond details
bond.isin = "INE0000001234"
bond.rating = "AAA"
bond.interestFrequency = "semiAnnual"
bond.nextCouponDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())

// Link to portfolio
bond.portfolio = portfolio

// Record purchase
let buyBond = TransactionEntity.create(
    in: context,
    type: .buy,
    amount: 102500,
    date: Date(),
    asset: bond,
    portfolio: portfolio
)

try context.save()

// Calculate annual interest income
if let annualInterest = bond.annualInterest {
    print("Annual Interest: ₹\(annualInterest)")
}

// Check current yield
if let currentYield = bond.currentYield {
    print("Current Yield: \(currentYield)%")
}

// Check if matured
if bond.hasMatured {
    print("Bond has matured")
}
```

### 4. Adding a Chit Fund

```swift
// Create a chit fund investment
let chitStartDate = Date()

let chit = ChitFundEntity.create(
    in: context,
    name: "Community Chit Fund - 2024",
    chitValue: 100000,
    monthlyContribution: 5000,
    totalMonths: 20,
    totalMembers: 20,
    startDate: chitStartDate
)

// Add additional details
chit.forepersonName = "Rajesh Kumar"
chit.registrationNumber = "CHIT/BLR/2024/001"

// Link to portfolio
chit.portfolio = portfolio

try context.save()

// Track progress
chit.currentMonth = 5

// Calculate total paid so far
let totalPaid = chit.totalPaid
print("Total Paid: ₹\(totalPaid)")

// Check remaining months
print("Remaining Months: \(chit.remainingMonths)")

// Mark when prize is received
if chit.hasReceivedPrize {
    print("Prize received in month: \(chit.prizeReceivedMonth)")
} else {
    print("Prize not yet received")
}
```

### 5. Adding Fixed Deposits

```swift
// Create a fixed deposit
let fdMaturityDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

let fixedDeposit = FixedDepositEntity.create(
    in: context,
    name: "HDFC Bank FD",
    bankName: "HDFC Bank",
    depositType: .fixedDeposit,
    principalAmount: 500000,
    interestRate: 7.2,
    tenure: 12,
    maturityDate: fdMaturityDate,
    interestFrequency: .quarterly
)

// Add account details
fixedDeposit.accountNumber = "FD123456789"
fixedDeposit.nomineeDetails = "Spouse - Priya Kumar"
fixedDeposit.autoRenewal = true

// Link to portfolio
fixedDeposit.portfolio = portfolio

try context.save()

// Check maturity amount
if let maturity = fixedDeposit.maturityAmount as Decimal? {
    print("Maturity Amount: ₹\(maturity)")
}

// Check expected return
if let expectedReturn = fixedDeposit.expectedReturn {
    print("Expected Return: ₹\(expectedReturn)")
}

// Check days until maturity
let daysRemaining = fixedDeposit.daysUntilMaturity
print("Days until maturity: \(daysRemaining)")

// Create a recurring deposit
let rdMaturityDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

let recurringDeposit = FixedDepositEntity.create(
    in: context,
    name: "SBI Recurring Deposit",
    bankName: "State Bank of India",
    depositType: .recurringDeposit,
    principalAmount: 5000,
    interestRate: 6.8,
    tenure: 24,
    maturityDate: rdMaturityDate,
    interestFrequency: .quarterly
)

recurringDeposit.portfolio = portfolio
try context.save()
```

### 6. Adding Cash Holdings

```swift
// Create a savings account
let savingsAccount = CashHoldingEntity.create(
    in: context,
    name: "SBI Savings Account",
    accountType: .savings,
    currentBalance: 75000,
    bankName: "State Bank of India",
    accountNumber: "1234567890"
)

// Add account details
savingsAccount.branchName = "Koramangala Branch"
savingsAccount.ifscCode = "SBIN0001234"
savingsAccount.minimumBalance = 10000 as NSDecimalNumber
savingsAccount.interestRate = 3.5 as NSDecimalNumber
savingsAccount.isLinkedUPI = true

// Link to portfolio
savingsAccount.portfolio = portfolio

try context.save()

// Check if below minimum
if savingsAccount.isBelowMinimum {
    print("Warning: Balance below minimum")
} else {
    if let excess = savingsAccount.excessBalance {
        print("Excess balance: ₹\(excess)")
    }
}

// Create a current account
let currentAccount = CashHoldingEntity.create(
    in: context,
    name: "Business Current Account",
    accountType: .current,
    currentBalance: 250000,
    bankName: "ICICI Bank",
    accountNumber: "9876543210"
)

currentAccount.portfolio = portfolio
try context.save()

// Create cash in hand entry
let cashInHand = CashHoldingEntity.create(
    in: context,
    name: "Cash in Hand",
    accountType: .cashInHand,
    currentBalance: 5000
)

cashInHand.portfolio = portfolio
try context.save()
```

## Transaction Management

### Recording Transactions

```swift
// Dividend received
let dividend = TransactionEntity.create(
    in: context,
    type: .dividend,
    amount: 5000,
    date: Date(),
    asset: stockAsset,
    portfolio: portfolio
)

// Interest payment
let interest = TransactionEntity.create(
    in: context,
    type: .interest,
    amount: 8750,
    date: Date(),
    asset: fixedDeposit,
    portfolio: portfolio
)

// Sale transaction
let sale = TransactionEntity.create(
    in: context,
    type: .sell,
    amount: 120000,
    date: Date(),
    asset: gold,
    portfolio: portfolio
)
sale.quantity = 20 as NSDecimalNumber
sale.price = 6000 as NSDecimalNumber

try context.save()
```

## Querying and Fetching

### Fetch All Assets in a Portfolio

```swift
let fetchRequest: NSFetchRequest<AssetEntity> = AssetEntity.fetchRequest()
fetchRequest.predicate = NSPredicate(
    format: "portfolio == %@ AND isActive == YES",
    portfolio
)
fetchRequest.sortDescriptors = [
    NSSortDescriptor(key: "currentValue", ascending: false)
]

let assets = try context.fetch(fetchRequest)

for asset in assets {
    print("\(asset.name ?? "Unknown"): ₹\(asset.currentValue ?? 0)")
}
```

### Fetch All Commodities

```swift
let commodityFetch: NSFetchRequest<CommodityEntity> = CommodityEntity.fetchRequest()
commodityFetch.sortDescriptors = [
    NSSortDescriptor(key: "currentValue", ascending: false)
]

let commodities = try context.fetch(commodityFetch)

for commodity in commodities {
    print("\(commodity.name ?? "Unknown") - \(commodity.commodityType ?? "Unknown")")
    if let valuePerUnit = commodity.valuePerUnit {
        print("  Value per \(commodity.unit ?? "unit"): ₹\(valuePerUnit)")
    }
}
```

### Fetch Maturing Fixed Deposits

```swift
let today = Date()
let oneMonthLater = Calendar.current.date(byAdding: .month, value: 1, to: today)!

let fdFetch: NSFetchRequest<FixedDepositEntity> = FixedDepositEntity.fetchRequest()
fdFetch.predicate = NSPredicate(
    format: "maturityDate >= %@ AND maturityDate <= %@",
    today as NSDate,
    oneMonthLater as NSDate
)
fdFetch.sortDescriptors = [
    NSSortDescriptor(key: "maturityDate", ascending: true)
]

let maturingFDs = try context.fetch(fdFetch)

print("Fixed Deposits maturing in the next month:")
for fd in maturingFDs {
    print("  \(fd.name ?? "Unknown") - Maturity: \(fd.maturityDate)")
    print("  Maturity Amount: ₹\(fd.maturityAmount ?? 0)")
}
```

### Fetch Properties by Type

```swift
let propertyFetch: NSFetchRequest<RealEstateEntity> = RealEstateEntity.fetchRequest()
propertyFetch.predicate = NSPredicate(
    format: "propertyType == %@",
    "residential"
)

let residentialProperties = try context.fetch(propertyFetch)

for property in residentialProperties {
    print("\(property.name ?? "Unknown")")
    print("  Location: \(property.city ?? "Unknown"), \(property.state ?? "Unknown")")
    print("  Value: ₹\(property.currentValue ?? 0)")
    
    if let yield = property.rentalYield {
        print("  Rental Yield: \(yield)%")
    }
}
```

### Fetch Recent Transactions

```swift
let transactionFetch: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
transactionFetch.predicate = NSPredicate(
    format: "portfolio == %@ AND transactionDate >= %@",
    portfolio,
    Calendar.current.date(byAdding: .month, value: -1, to: Date())! as NSDate
)
transactionFetch.sortDescriptors = [
    NSSortDescriptor(key: "transactionDate", ascending: false)
]

let recentTransactions = try context.fetch(transactionFetch)

print("Recent Transactions:")
for transaction in recentTransactions {
    let type = TransactionEntity.TransactionType(rawValue: transaction.transactionType ?? "")
    print("  \(transaction.transactionDate) - \(type?.displayName ?? "Unknown"): ₹\(transaction.amount ?? 0)")
    if let assetName = transaction.asset?.name {
        print("    Asset: \(assetName)")
    }
}
```

## Updating Asset Values

### Update Single Asset

```swift
// Update gold price
gold.currentValue = 320000 as NSDecimalNumber
gold.updatedAt = Date()

try context.save()

// Check new gain/loss
if let gainLoss = gold.unrealizedGainLoss,
   let percentage = gold.unrealizedGainLossPercentage {
    print("Gain/Loss: ₹\(gainLoss) (\(percentage)%)")
}
```

### Batch Update Portfolio Values

```swift
// Fetch all assets in portfolio
let fetchRequest: NSFetchRequest<AssetEntity> = AssetEntity.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "portfolio == %@", portfolio)

let assets = try context.fetch(fetchRequest)

// Update each asset
for asset in assets {
    // Update from market data source
    // asset.currentValue = fetchMarketPrice(for: asset)
    asset.updatedAt = Date()
}

try context.save()

// Update portfolio total
portfolio.updateTotalValue()
try context.save()

print("Portfolio updated. Total Value: ₹\(portfolio.totalValue)")
```

## Deleting Assets

### Delete Single Asset

```swift
// Delete an asset (will cascade delete transactions)
context.delete(gold)

try context.save()
```

### Delete Portfolio

```swift
// Delete portfolio (will cascade delete all assets and transactions)
context.delete(portfolio)

try context.save()
```

## Background Operations

### Performing Operations in Background

```swift
// Use background context for heavy operations
let container = PersistentContainer.shared

Task {
    try await container.performBackgroundTask { backgroundContext in
        // Create assets in background
        for i in 0..<100 {
            let gold = CommodityEntity.create(
                in: backgroundContext,
                name: "Gold Lot \(i)",
                commodityType: .gold,
                quantity: Decimal(10),
                unit: "gram",
                currentValue: Decimal(50000)
            )
            // Process...
        }
        
        // Context is automatically saved
    }
}
```

## Error Handling

### Safe Save with Error Handling

```swift
func saveContext() {
    let context = PersistentContainer.shared.viewContext
    
    guard context.hasChanges else {
        print("No changes to save")
        return
    }
    
    do {
        try context.save()
        print("Context saved successfully")
    } catch let error as NSError {
        print("Failed to save context: \(error)")
        print("Error info: \(error.userInfo)")
        
        // Handle specific errors
        if error.domain == NSCocoaErrorDomain {
            switch error.code {
            case NSValidationMultipleErrorsError:
                print("Multiple validation errors")
            case NSValidationMissingMandatoryPropertyError:
                print("Missing mandatory property")
            default:
                print("Other Core Data error")
            }
        }
    }
}
```

## SwiftUI Integration

### Using in SwiftUI Views

```swift
import SwiftUI
import CoreData

struct PortfolioView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PortfolioEntity.name, ascending: true)],
        animation: .default
    )
    private var portfolios: FetchedResults<PortfolioEntity>
    
    var body: some View {
        List {
            ForEach(portfolios) { portfolio in
                VStack(alignment: .leading) {
                    Text(portfolio.name ?? "Unknown")
                        .font(.headline)
                    Text("Value: ₹\(portfolio.totalValue ?? 0)")
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("Portfolios")
    }
}
```

## Best Practices

1. **Always save after modifications**: Don't forget to call `try context.save()` after changes
2. **Use background contexts for heavy operations**: Keep UI responsive
3. **Handle errors appropriately**: Wrap Core Data operations in do-catch blocks
4. **Update timestamps**: Keep `updatedAt` current when modifying entities
5. **Use computed properties**: Leverage provided computed properties for calculations
6. **Validate before saving**: Ensure data integrity before persisting
7. **Use predicates efficiently**: Filter data at database level, not in memory
8. **Keep contexts separate**: Don't mix view and background contexts
9. **Test thoroughly**: Verify relationships and cascade behaviors
10. **Encrypt sensitive data**: Use encrypted fields for account numbers and notes

## Performance Tips

1. **Batch operations**: Use batch fetch/update for large datasets
2. **Lazy loading**: Configure fetch requests to load data as needed
3. **Index frequently queried attributes**: Key attributes are already indexed
4. **Use predicates wisely**: Efficient predicates improve query performance
5. **Avoid retain cycles**: Be careful with relationship traversals
6. **Profile with Instruments**: Use Core Data instruments for optimization
