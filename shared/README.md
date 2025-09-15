# WealthWise - Shared Library

This package contains shared TypeScript models, services, and utilities used across all platforms of WealthWise - the smart personal finance management application that makes you smarter about money.

## Contents

### 📁 Models (`/models`)
- **Core Models**: Account, Transaction, Budget, Asset, Loan, and Investment data structures
- **Enums**: AccountType, TransactionType, TransactionCategory, and other enumerations
- **Interfaces**: Complete TypeScript interfaces for all financial data entities

### 🔧 Services (`/services`)
- **Service Interfaces**: Contract definitions for all business logic services
- **Repository Patterns**: Data access layer abstractions
- **Analytics Interfaces**: Reporting and analytics service contracts

### 🛠️ Utils (`/utils`)
- **DateUtils**: Indian financial year calculations, date formatting, quarter management
- **CurrencyUtils**: Multi-currency formatting, INR lakhs/crores notation, amount-to-words conversion
- **ValidationUtils**: Indian banking validations (IFSC, PAN, Aadhaar, bank accounts, UPI)
- **TextUtils**: Natural language processing, transaction categorization, text extraction
- **EncryptionUtils**: Data encryption and security utilities

## Usage

### Installation
```bash
npm install @wealthwise/shared
```

### Importing Models
```typescript
import { Account, Transaction, AccountType, TransactionCategory } from '@wealthwise/shared';

const account: Account = {
  id: 'account-1',
  name: 'HDFC Savings',
  accountType: AccountType.SAVINGS,
  institutionName: 'HDFC Bank',
  currentBalance: 50000,
  currency: 'INR',
  isActive: true,
  createdAt: new Date(),
  updatedAt: new Date()
};
```

### Using Utilities
```typescript
import { DateUtils, CurrencyUtils, ValidationUtils } from '@wealthwise/shared';

// Financial year calculations
const fyStart = DateUtils.getFinancialYearStart(new Date());
console.log('FY starts:', fyStart); // April 1st

// Indian currency formatting
const formatted = CurrencyUtils.formatIndianCurrency(100000);
console.log(formatted); // ₹1,00,000.00

// Banking validations
const isValidIFSC = ValidationUtils.validateIFSC('HDFC0000123');
console.log('Valid IFSC:', isValidIFSC); // true
```

### Service Contracts
```typescript
import { ITransactionService, IAccountService } from '@wealthwise/shared';

class TransactionService implements ITransactionService {
  async createTransaction(transaction: Transaction): Promise<string> {
    // Implementation
  }
  // ... other methods
}
```

## Development

### Building
```bash
npm run build
```

### Testing
```bash
npm test                # Run all tests
npm run test:coverage   # Run with coverage
npm run test:watch      # Watch mode
```

### Linting
```bash
npm run lint           # Check for issues
npm run lint:fix       # Auto-fix issues
npm run format         # Format code
```

## Platform Integration

This shared library is designed to be consumed by:

- **iOS App** (`../ios`): Swift/SwiftUI with Core Data
- **Android App** (`../android`): Kotlin with Room Database  
- **Windows App** (`../windows`): .NET Core with Entity Framework

Each platform implements the service interfaces and uses the shared models as reference for their native data structures.

## Features

### Indian Banking Support
- Financial year calculations (April-March)
- Indian number formatting (lakhs, crores)
- Banking validations (IFSC, PAN, Aadhaar)
- UPI ID validation
- Indian mobile number validation

### Multi-Currency Support
- Currency formatting for 50+ currencies
- Exchange rate calculations
- Localized number formatting

### Smart Categorization (On-Device AI)
- Automatic transaction categorization (when device supports AI)
- Natural language processing for banking SMS (optional enhancement)
- Amount extraction from text
- Merchant recognition (available on compatible devices)

### Security
- Data encryption utilities
- Secure key generation
- Validation helpers
- Input sanitization

## Contributing

1. All changes must maintain backward compatibility
2. Add tests for new functionality
3. Update documentation for API changes
4. Follow TypeScript strict mode requirements
5. Ensure all validations support Indian banking standards

## License

Proprietary - WealthWise Inc.