# WealthWise Core Data Models

This directory contains the Core Data models and supporting files for the WealthWise application's persistence layer.

## Files

### WealthWiseDataModel.xcdatamodeld
The Core Data model file defining all entities, attributes, and relationships:
- **Portfolio**: Root entity for organizing assets
- **Asset** (Abstract): Base entity for all asset types
  - **Commodity**: Physical commodities (gold, silver, etc.)
  - **RealEstate**: Properties (residential, commercial, etc.)
  - **Bond**: Fixed income securities
  - **ChitFund**: Traditional Indian investment scheme
  - **FixedDeposit**: Bank deposits (FD, RD)
  - **CashHolding**: Cash and bank accounts
- **Transaction**: Records asset transactions

### CoreDataModels.swift
Swift extensions providing:
- Convenient factory methods for creating entities
- Computed properties for financial calculations
- Type-safe enumerations for asset types
- Helper methods for common operations
- Localized display names

### PersistentContainer.swift
Manages Core Data stack:
- Singleton pattern for easy access
- Configures persistent store with encryption
- Provides background context operations
- Handles change notifications
- Database statistics and utilities

### SimpleTransformers.swift
Custom value transformers for Core Data:
- Decimal number transformations
- Date transformations
- Encryption support

### DataModelMigrations.swift
Handles Core Data model migrations:
- Version tracking
- Migration policies
- Backward compatibility

## Quick Start

### Import and Setup
```swift
import CoreData
@testable import WealthWise

// Access the persistent container
let container = PersistentContainer.shared
let context = container.viewContext
```

### Create a Portfolio
```swift
let portfolio = PortfolioEntity.create(
    in: context,
    name: "My Portfolio",
    currency: "INR"
)
try context.save()
```

### Add Assets
```swift
// Add gold
let gold = CommodityEntity.create(
    in: context,
    name: "Gold Coins",
    commodityType: .gold,
    quantity: 50,
    unit: "gram",
    currentValue: 300000
)
gold.portfolio = portfolio

// Add property
let property = RealEstateEntity.create(
    in: context,
    name: "Apartment",
    propertyType: .residential,
    currentValue: 5000000
)
property.portfolio = portfolio

try context.save()
```

### Calculate Portfolio Value
```swift
portfolio.updateTotalValue()
print("Total: ₹\(portfolio.totalValue)")
```

## Entity Types

### Asset Categories
- **Commodity**: Physical gold, silver, platinum
- **RealEstate**: Residential, commercial properties
- **Bond**: Government, corporate bonds
- **ChitFund**: Community savings schemes
- **FixedDeposit**: Bank FDs, RDs
- **CashHolding**: Savings, current accounts, cash

### Transaction Types
- Buy, Sell
- Deposit, Withdrawal
- Dividend, Interest
- Fee, Transfer

## Key Features

### Encryption
Sensitive fields are automatically encrypted:
- Account numbers
- User notes
- Transaction references

### Relationships
- Portfolio → Assets (One-to-Many, Cascade)
- Portfolio → Transactions (One-to-Many, Cascade)
- Asset → Transactions (One-to-Many, Cascade)

### Computed Properties
- Unrealized gain/loss
- Rental yield
- Bond current yield
- FD maturity amount
- Excess balance

### Localization
All user-facing strings use `NSLocalizedString` for proper localization support.

## Documentation

For detailed documentation, see:
- `/docs/core-data-models.md` - Complete entity reference
- `/docs/core-data-usage-examples.md` - Code examples and patterns

## Testing

Run unit tests:
```bash
xcodebuild test -project WealthWise.xcodeproj \
    -scheme WealthWise \
    -destination "platform=macOS"
```

Test coverage includes:
- Entity creation and validation
- Computed properties
- Relationship integrity
- Cascade deletion
- Performance benchmarks

## Best Practices

1. **Always save after changes**: `try context.save()`
2. **Use factory methods**: `Entity.create(in:...)` for consistency
3. **Handle errors**: Wrap Core Data ops in do-catch
4. **Background operations**: Use `performBackgroundTask` for heavy work
5. **Update timestamps**: Keep `updatedAt` current
6. **Validate data**: Check inputs before saving
7. **Encrypt sensitive data**: Use encrypted fields

## Migration

The current model version is **WealthWiseDataModel**.

To create a new version:
1. Editor → Add Model Version in Xcode
2. Make schema changes
3. Create mapping model if needed
4. Update `.xccurrentversion`

## Performance

Optimizations:
- Batch operations for large datasets
- Indexed key attributes
- Efficient predicates
- Lazy loading
- Background contexts

## Security

- Field-level encryption using AES-256-GCM
- Keys stored in iOS Keychain
- File protection on persistent store
- Secure backup support

## Support

For issues or questions:
1. Check documentation in `/docs/`
2. Review test cases in `WealthWiseTests/`
3. Consult `CoreDataModels.swift` for API reference

## License

See project LICENSE file.
