# Alternative Investments Module

## Overview

The Alternative Investments Module provides comprehensive tracking and management for non-traditional investment assets including real estate properties, physical commodities (gold, silver, etc.), bonds, and traditional Indian chit funds.

**Issue**: #5 - Alternative Investments Module  
**Status**: ✅ Complete  
**Version**: 1.0  
**Date**: 2025-10-02

## Features

### 1. Real Estate Property Management

Track residential and commercial properties with comprehensive details:

- **Property Types**: Apartment, Villa, Plot/Land, Commercial Office, Shop, Warehouse, Agricultural, Industrial
- **Financial Tracking**: Purchase price, current value, capital appreciation
- **Rental Income**: Monthly rent, tenant details, lease management
- **Loan Management**: Loan amount, outstanding balance, EMI tracking
- **Maintenance History**: Repairs, renovations, and ongoing costs
- **Valuation History**: Track property value changes over time
- **Document Storage**: Encrypted storage for sale deeds, tax receipts, insurance

#### Usage Example

```swift
import WealthWise

// Create a property address
let address = PropertyAddress(
    street: "123 MG Road",
    city: "Bangalore",
    state: "Karnataka",
    country: "India",
    postalCode: "560001"
)

// Create a real estate property
let property = RealEstateProperty(
    name: "Bangalore Apartment",
    propertyDescription: "2BHK in prime location",
    propertyType: .apartment,
    address: address,
    totalArea: 1200,
    areaUnit: .squareFeet,
    purchaseDate: Date(),
    purchasePrice: 6000000,
    currentValue: 7000000,
    currency: "INR"
)

// Add rental information
property.updateRentalInfo(
    isRented: true,
    monthlyRent: 45000,
    tenantName: "John Doe",
    leaseStartDate: Date(),
    leaseEndDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
)

// Record rental income
property.recordRentalIncome(amount: 45000, description: "June 2024 rent")

// Update valuation
property.updateValuation(newValue: 7200000, notes: "Market appreciation")

// Attach documents
property.attachDocument(
    fileName: "sale_deed.pdf",
    fileType: .saleAgreement,
    filePath: "/secure/documents/sale_deed.pdf",
    encryptionKey: "encrypted_key_abc123",
    fileSize: 1024000
)
```

### 2. Commodity Investments

Track physical precious metals and other commodities:

- **Commodity Types**: Gold, Silver, Platinum, Palladium, Diamond
- **Forms**: Jewelry, Coins, Bars, Bullion, Ornaments
- **Weight Tracking**: Grams, Kilograms, Ounces, Pounds
- **Market Price Updates**: Track current market value
- **Storage Management**: Home locker, Bank locker, Vault storage
- **Insurance**: Track insurance coverage and provider
- **Purity Tracking**: Record hallmark and purity details

#### Usage Example

```swift
// Create a gold investment
let goldJewelry = Commodity(
    name: "Gold Necklace Set",
    commodityDescription: "22K gold jewelry with hallmark",
    commodityType: .gold,
    weight: 50,
    weightUnit: .grams,
    purity: 91.6,
    form: .jewelry,
    purchaseDate: Date(),
    purchasePrice: 250000,
    pricePerUnit: 5000,
    currentValue: 280000,
    currency: "INR",
    storageLocation: .bankLocker
)

// Update with current market price
goldJewelry.updateValuation(
    marketPricePerUnit: 5600,
    notes: "Gold price increased due to market conditions"
)

// Add insurance
goldJewelry.updateInsurance(
    isInsured: true,
    insuranceValue: 300000,
    insuranceProvider: "ICICI Lombard"
)

// Computed properties
print("Current value per unit: \(goldJewelry.currentValuePerUnit)")
print("Price appreciation: \(goldJewelry.priceAppreciationPerUnit)")
print("Capital appreciation: \(goldJewelry.capitalAppreciation)")
```

### 3. Bond Investments

Track government, corporate, and municipal bonds:

- **Bond Types**: Government, Corporate, Municipal, Treasury, Savings, Zero Coupon, Convertible
- **Interest Tracking**: Coupon rate, payment frequency, accrued interest
- **Maturity Management**: Track maturity dates and yields
- **Credit Rating**: Store rating information and risk level
- **Income History**: Record all interest payments
- **Yield Calculations**: Current yield, yield to maturity

#### Usage Example

```swift
// Create a government bond
let bond = Bond(
    name: "Government of India Bond 2030",
    bondDescription: "7.5% GOI Bond",
    bondType: .governmentBond,
    issuer: "Government of India",
    isin: "IN0020130016",
    faceValue: 1000,
    quantity: 100,
    purchaseDate: Date(),
    purchasePrice: 100000,
    currentValue: 102000,
    currency: "INR",
    couponRate: 7.5,
    interestPaymentFrequency: .halfYearly,
    maturityDate: Calendar.current.date(byAdding: .year, value: 5, to: Date())!,
    riskLevel: .low
)

// Record interest payment
bond.recordInterestPayment(
    amount: 3750,
    description: "Half-yearly interest payment"
)

// Update valuation
bond.updateValuation(newValue: 103000, notes: "Market value increased")

// Computed properties
print("Annual interest: \(bond.annualInterestIncome)")
print("Years to maturity: \(bond.yearsToMaturity)")
print("Current yield: \(bond.calculatedCurrentYield)%")
print("Total interest received: \(bond.totalInterestReceived)")
```

### 4. Chit Fund Investments

Track traditional Indian chit fund schemes:

- **Chit Details**: Organizer, members, total value, duration
- **Contribution Tracking**: Monthly contributions, payment history
- **Auction Management**: Record auction details and winners
- **Payout Tracking**: Record received payouts and discounts
- **Status Monitoring**: Active, completed status tracking
- **Return Calculation**: Net benefit and ROI percentage

#### Usage Example

```swift
// Create a chit fund
let chitFund = ChitFund(
    name: "Shriram Monthly Chit",
    chitDescription: "Monthly contribution scheme",
    organizer: "Shriram Chits",
    totalMembers: 40,
    chitValue: 400000,
    monthlyContribution: 10000,
    duration: 40,
    startDate: Date(),
    currency: "INR"
)

// Record monthly contributions
for month in 1...5 {
    chitFund.recordContribution(
        amount: 10000,
        month: month,
        notes: "Month \(month) contribution"
    )
}

// Record auction details
chitFund.recordAuction(
    month: 5,
    winnerName: "Priya Singh",
    bidAmount: 370000,
    discount: 30000,
    date: Date()
)

// Record payout if won
chitFund.recordPayout(
    amount: 370000,
    month: 10,
    discount: 30000,
    notes: "Won auction in month 10"
)

// Computed properties
print("Total contributed: \(chitFund.totalContributed)")
print("Months remaining: \(chitFund.monthsRemaining)")
print("Net benefit: \(chitFund.netBenefit)")
print("Return percentage: \(chitFund.returnPercentage)%")
```

## Service Layer

The `AlternativeInvestmentService` provides centralized management of all alternative investments:

### Service Features

- **CRUD Operations**: Create, read, update, delete for all investment types
- **Advanced Filtering**: Filter by type, status, rental status, maturity dates
- **Portfolio Analytics**: Calculate totals, aggregations, and summaries
- **Error Handling**: Comprehensive error handling with localized messages

### Usage Example

```swift
// Initialize service with SwiftData ModelContext
let service = AlternativeInvestmentService(modelContext: modelContext)

// Real Estate Operations
try service.createRealEstateProperty(property)
let properties = try service.fetchRealEstateProperties()
let rentedProperties = try service.fetchRentedProperties()
let totalValue = try service.calculateTotalRealEstateValue()
let totalRentalIncome = try service.calculateTotalRentalIncome()

// Commodity Operations
try service.createCommodity(commodity)
let goldCommodities = try service.fetchCommodities(ofType: .gold)
try service.updateCommodityPrice(commodityId: id, marketPricePerUnit: 5600)
let totalGoldGrams = try service.calculateTotalGoldHoldings()

// Bond Operations
try service.createBond(bond)
let maturingSoon = try service.fetchBondsMaturingSoon()
try service.recordBondInterest(bondId: id, amount: 3750)
let annualInterest = try service.calculateAnnualBondInterest()

// Chit Fund Operations
try service.createChitFund(chitFund)
let activeChits = try service.fetchActiveChitFunds()
try service.recordChitContribution(chitFundId: id, amount: 10000, month: 1)
try service.recordChitPayout(chitFundId: id, amount: 280000, month: 10, discount: 20000)

// Portfolio Analytics
let summary = try service.getAlternativeInvestmentsSummary()
print("Total value: \(summary.totalValue)")
print("Annual income: \(summary.annualIncome)")
print("Real estate count: \(summary.realEstateCount)")
print("Bond count: \(summary.bondCount)")
```

## Data Models

### Supporting Types

#### ValuationRecord
Tracks historical valuations with change calculations:
```swift
public struct ValuationRecord {
    let date: Date
    let value: Decimal
    let previousValue: Decimal
    let changeAmount: Decimal
    let changePercentage: Double
    let valuationType: ValuationType
    let notes: String?
}
```

#### IncomeRecord
Records income from investments:
```swift
public struct IncomeRecord {
    let date: Date
    let amount: Decimal
    let incomeType: IncomeType // rent, interest, dividend, chitPayout
    let description: String?
    let currency: String
}
```

#### SecureDocument
Encrypted document storage:
```swift
public struct SecureDocument {
    let fileName: String
    let fileType: DocumentType
    let filePath: String
    let encryptionKey: String
    let fileSize: Int
    let uploadDate: Date
}
```

## Localization

All user-facing strings are fully localized in:
- **English (en)** - Primary language
- **Hindi (hi)** - Indian market
- **Tamil (ta)** - South Indian market

### Localization Keys

Property types, commodity types, bond types, income types, maintenance categories, document types, risk levels, and all error messages are fully localized.

Example usage:
```swift
let propertyType = PropertyType.apartment
print(propertyType.displayName) // Uses NSLocalizedString internally

let incomeType = IncomeType.rent
print(incomeType.displayName) // Automatically localized
```

## Security

### Document Encryption

All documents are stored with encryption keys:
```swift
property.attachDocument(
    fileName: "title_deed.pdf",
    fileType: .titleDeed,
    filePath: "/secure/documents/title_deed.pdf",
    encryptionKey: "aes256_encrypted_key_here",
    fileSize: 2048000
)
```

### Data Privacy

- All financial data uses `Decimal` for precision
- Sensitive information encrypted at rest
- Secure storage for document encryption keys
- Biometric authentication support for accessing investments

## Testing

### Test Coverage

- **Model Tests**: 30+ tests covering all data models
- **Service Tests**: 20+ tests covering service operations
- **Edge Cases**: Zero values, completed status, calculations
- **Performance Tests**: Bulk operations and calculations

### Running Tests

```bash
# Build the project
xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise -destination "generic/platform=macOS" build

# Run tests
xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise -destination "generic/platform=macOS" test
```

## Integration with Existing Systems

### AssetType Integration

The alternative investments integrate with the existing `AssetType` enum:
- `.realEstateResidential`, `.realEstateCommercial`, `.realEstateInternational`
- `.goldPhysical`, `.silverPhysical`, `.otherPreciousMetals`
- `.governmentBonds`, `.corporateBonds`, `.municipalBonds`
- `.chitFunds`, `.traditionalInvestments`

### Transaction Linking

Alternative investments can be linked to `Transaction` records:
```swift
// Create a transaction for property purchase
let transaction = Transaction(
    amount: 6000000,
    transactionDescription: "Property purchase",
    transactionType: .investment,
    category: .real_estate
)

// Link to property
transaction.assetId = property.id.uuidString
```

### Goal Tracking

Link investments to financial goals:
```swift
let goal = Goal(
    title: "Build Real Estate Portfolio",
    targetAmount: 50000000,
    targetDate: futureDate
)

// Track progress with property values
goal.updateProgress(currentAmount: totalPropertyValue)
```

## Best Practices

### 1. Regular Valuation Updates

Update valuations periodically to maintain accurate portfolio values:
```swift
// Update property valuations annually
property.updateValuation(
    newValue: currentMarketValue,
    notes: "Annual valuation update"
)
```

### 2. Income Tracking

Record all income promptly for accurate returns calculation:
```swift
// Record rental income as received
property.recordRentalIncome(amount: 45000, date: Date())

// Record bond interest payments
bond.recordInterestPayment(amount: 3750, date: Date())
```

### 3. Document Management

Attach important documents with proper encryption:
```swift
// Attach sale deed, insurance, tax receipts
property.attachDocument(
    fileName: "sale_deed.pdf",
    fileType: .saleAgreement,
    filePath: secureFilePath,
    encryptionKey: generatedEncryptionKey,
    fileSize: fileSize
)
```

### 4. Portfolio Review

Use the service layer for portfolio analytics:
```swift
let summary = try service.getAlternativeInvestmentsSummary()

// Review total values and income
print("Total alternative investments: ₹\(summary.totalValue)")
print("Annual income: ₹\(summary.annualIncome)")
print("Real estate properties: \(summary.realEstateCount)")
```

## Future Enhancements

Planned features for future releases:

1. **Market Data Integration**: Automatic gold/silver price updates from market APIs
2. **Property Market Trends**: Integration with real estate market data
3. **Tax Calculations**: Automated capital gains and rental income tax calculations
4. **Loan Amortization**: Detailed EMI schedules and principal/interest breakup
5. **Depreciation Tracking**: Asset depreciation calculations for tax purposes
6. **Insurance Renewal Alerts**: Notifications for insurance policy renewals
7. **Chit Fund Auction Predictions**: ML-based prediction of auction outcomes
8. **Portfolio Rebalancing**: Recommendations for optimal alternative investment allocation

## Support

For issues, questions, or contributions related to the Alternative Investments Module:

- **GitHub Issues**: https://github.com/kamthamc/wealth-wise/issues
- **Documentation**: Check `/docs` directory for additional information
- **Code Examples**: See test files for comprehensive usage examples

## License

This module is part of the WealthWise application. All rights reserved.

---

*Alternative Investments Module v1.0 - Built with Swift 6, SwiftUI, and SwiftData*
