# WealthWise Entity-Relationship Diagrams

## Overview

This document provides comprehensive entity-relationship diagrams for WealthWise, detailing the data models and their relationships. The diagrams reflect the actual implementation in the codebase, including SwiftData @Model entities and Codable structures.

### Documentation Contents
1. **Core Entity Model** - Primary entities with Mermaid ER diagram
2. **Asset Type Hierarchy** - Comprehensive asset classification
3. **Transaction Types & States** - Transaction lifecycle and categories
4. **Security & Encryption Model** - Encryption and key management
5. **Data Flow Architecture** - System data flow patterns
6. **Portfolio Performance** - Performance metrics and calculations
7. **Reporting & Analytics** - Report generation models
8. **Import/Export** - Data import and export structures
9. **System Integration** - External service integration points

### Implementation Status

#### SwiftData @Model Entities (Persistent)
- ✅ **Transaction** - Full implementation with relationships
- ✅ **Goal** - Complete with milestones and contributions
- ⏳ **User** - Planned for authentication system
- ⏳ **Portfolio** - Planned when multi-portfolio support added

#### Codable Structures (Non-Persistent)
- ✅ **CrossBorderAsset** - Comprehensive international asset tracking
- ✅ **PerformanceSnapshot** - Historical performance tracking
- ✅ **ExchangeRate** - Currency conversion rates
- ✅ **TaxResidencyStatus** - Tax jurisdiction tracking
- ✅ **GoalMilestone** - Embedded in Goal entity
- ✅ **TransactionAttachment** - Embedded in Transaction

### Entity Relationship Summary

```
┌────────────────────────────────────────────────────────┐
│              WealthWise Data Model Overview            │
├────────────────────────────────────────────────────────┤
│                                                         │
│  User (Planned)                                        │
│    │                                                    │
│    ├──▶ CrossBorderAsset (Codable)                    │
│    │      └──▶ PerformanceSnapshot[]                   │
│    │      └──▶ IncomePayment[]                         │
│    │      └──▶ TaxResidencyStatus                      │
│    │                                                    │
│    ├──▶ Transaction (@Model)                           │
│    │      ├──▶ TransactionAttachment[]                 │
│    │      └──▶ Goal (@Model)                           │
│    │                                                    │
│    └──▶ Goal (@Model)                                  │
│           ├──▶ GoalMilestone[]                         │
│           ├──▶ GoalContribution[]                      │
│           ├──▶ ProgressSnapshot[]                      │
│           └──▶ Transaction[] (linked)                  │
│                                                         │
│  Relationships:                                        │
│    • User → CrossBorderAsset (1:N)                    │
│    • User → Transaction (1:N)                          │
│    • User → Goal (1:N)                                 │
│    • Transaction ↔ Goal (M:N via linkedGoal)          │
│    • Goal → Transaction (1:N via linkedTransactions)  │
│    • Transaction → Attachments (1:N cascade)          │
│                                                         │
└────────────────────────────────────────────────────────┘
```

## Core Entity Model

```mermaid
erDiagram
    User {
        uuid id PK
        string firstName
        string lastName  
        string email
        datetime createdAt
        datetime lastLogin
        boolean biometricEnabled
        string encryptedMasterKey
    }
    
    CrossBorderAsset {
        uuid id PK
        string name
        enum assetType
        enum category
        string domicileCountryCode
        string ownerCountryCode
        decimal currentValue
        string nativeCurrencyCode
        decimal originalInvestment
        datetime acquisitionDate
        decimal quantity
        decimal pricePerUnit
        string institutionIdentifier
        string securityIdentifier
        datetime createdAt
        datetime updatedAt
        boolean isActive
        boolean isIncludedInPortfolio
    }
    
    Transaction {
        uuid id PK
        decimal amount
        string currency
        string transactionDescription
        string notes
        datetime date
        datetime valueDate
        enum transactionType
        enum category
        string subcategory
        string accountId
        enum accountType
        decimal originalAmount
        string originalCurrency
        decimal exchangeRate
        decimal baseCurrencyAmount
        enum status
        boolean isRecurring
        datetime createdAt
        datetime updatedAt
        boolean isTaxable
        enum taxCategory
        decimal taxAmount
        decimal tdsAmount
    }
    
    Goal {
        uuid id PK
        string title
        string goalDescription
        decimal targetAmount
        string targetCurrency
        datetime startDate
        datetime targetDate
        decimal currentAmount
        decimal contributedAmount
        decimal projectedAmount
        enum goalType
        enum priority
        boolean isActive
        boolean isCompleted
        datetime completedAt
        enum riskTolerance
        decimal expectedAnnualReturn
        boolean inflationAdjusted
        datetime createdAt
        datetime updatedAt
    }
    
    PerformanceSnapshot {
        datetime date
        decimal value
        string currency
        string source
    }
    
    IncomePayment {
        decimal amount
        string currency
        datetime paymentDate
        enum type
    }
    
    GoalMilestone {
        uuid id PK
        double percentage
        string title
        string description
        decimal targetAmount
        datetime targetDate
        boolean isAchieved
        datetime achievedAt
    }
    
    GoalContribution {
        uuid id PK
        decimal amount
        datetime date
        string description
        string currency
    }
    
    TransactionAttachment {
        uuid id PK
        string fileName
        enum fileType
        string filePath
        datetime uploadDate
        int fileSize
    }
    
    ExchangeRate {
        string fromCurrency PK
        string toCurrency PK
        decimal rate
        datetime lastUpdated
        string source
    }
    
    TaxResidencyStatus {
        uuid id PK
        string countryCode
        enum residencyType
        datetime effectiveFrom
        datetime effectiveTo
        boolean isPrimary
    }

    User ||--o{ CrossBorderAsset : "owns"
    User ||--o{ Transaction : "creates"
    User ||--o{ Goal : "sets"
    CrossBorderAsset ||--o{ PerformanceSnapshot : "has_history"
    CrossBorderAsset ||--o{ IncomePayment : "receives"
    Transaction ||--o{ TransactionAttachment : "has"
    Transaction }o--o| Goal : "linked_to"
    Goal ||--o{ GoalMilestone : "tracks"
    Goal ||--o{ GoalContribution : "receives"
    Goal ||--o{ Transaction : "contains"
    CrossBorderAsset }o--|| TaxResidencyStatus : "subject_to"
```

## Asset Type Hierarchy

```
Asset Types:
├── Financial Securities
│   ├── Stocks
│   │   ├── Equity Shares
│   │   ├── Preference Shares
│   │   └── ADRs/GDRs
│   ├── Mutual Funds
│   │   ├── Equity Funds
│   │   ├── Debt Funds
│   │   ├── Hybrid Funds
│   │   └── ELSS Funds
│   ├── ETFs
│   │   ├── Index ETFs
│   │   ├── Gold ETFs
│   │   └── International ETFs
│   └── Bonds
│       ├── Government Bonds
│       ├── Corporate Bonds
│       └── Municipal Bonds
├── Bank Products
│   ├── Fixed Deposits
│   ├── Recurring Deposits
│   ├── Savings Accounts
│   └── Current Accounts
├── Alternative Investments
│   ├── Real Estate
│   │   ├── Residential Property
│   │   ├── Commercial Property
│   │   └── REITs
│   ├── Commodities
│   │   ├── Gold (Physical)
│   │   ├── Silver
│   │   └── Other Precious Metals
│   ├── Traditional Investments
│   │   ├── Chit Funds
│   │   ├── Post Office Schemes
│   │   └── Insurance (ULIP/Endowment)
│   └── Cryptocurrency
│       ├── Bitcoin
│       ├── Ethereum
│       └── Other Altcoins
└── Cash & Equivalents
    ├── Cash in Hand
    ├── Bank Balances
    └── Money Market Funds
```

## Transaction Types & States

```mermaid
stateDiagram-v2
    [*] --> Pending
    
    Pending --> Processing : Validate
    Processing --> Completed : Success
    Processing --> Failed : Error
    Processing --> Cancelled : User_Cancel
    
    Failed --> Pending : Retry
    Cancelled --> [*]
    Completed --> [*]
    
    note right of Completed
        Transaction Types:
        - BUY: Purchase asset
        - SELL: Dispose asset  
        - DIVIDEND: Dividend received
        - INTEREST: Interest earned
        - BONUS: Bonus shares
        - SPLIT: Stock split
        - MERGER: Corporate action
        - TRANSFER: Portfolio transfer
    end note
```

## Security & Encryption Model

```mermaid
erDiagram
    EncryptionKey {
        uuid id PK
        string keyIdentifier
        string encryptedKey
        string keyDerivationSalt
        enum keyType
        datetime createdAt
        datetime rotatedAt
        boolean isActive
    }
    
    EncryptedField {
        uuid id PK
        uuid entityId
        string fieldName
        string encryptedValue
        uuid encryptionKeyId FK
        string initializationVector
        datetime encryptedAt
    }
    
    BiometricAuth {
        uuid id PK
        uuid userId FK
        enum authType
        string encryptedBiometricData
        datetime lastUsed
        boolean isEnabled
        int failureCount
    }
    
    SecurityAudit {
        uuid id PK
        uuid userId FK
        enum eventType
        string description
        datetime timestamp
        string riskLevel
        boolean resolved
    }

    EncryptionKey ||--o{ EncryptedField : "encrypts"
    User ||--o{ BiometricAuth : "has"
    User ||--o{ SecurityAudit : "triggers"
```

## Data Flow Architecture

```mermaid
flowchart TD
    A[SwiftUI View] --> B[ViewModel]
    B --> C[Business Manager]
    C --> D[Service Layer]
    D --> E[Data Service]
    E --> F[SwiftData Store]
    
    C --> G[Security Service]
    G --> H[Keychain]
    
    C --> I[Market Data Service]
    I --> J[External API]
    
    D --> K[Calculation Service]
    K --> L[Cache Layer]
    
    F --> M[Encrypted Storage]
    H --> N[Secure Enclave]
    
    style A fill:#e1f5fe
    style F fill:#fff3e0
    style G fill:#ffebee
    style M fill:#f3e5f5
```

## Portfolio Performance Calculations

```mermaid
erDiagram
    PerformanceMetrics {
        uuid id PK
        uuid portfolioId FK
        decimal totalReturn
        decimal annualizedReturn
        decimal sharpeRatio
        decimal beta
        decimal alpha
        decimal volatility
        decimal maxDrawdown
        datetime calculatedAt
        string timeframe
    }
    
    Benchmark {
        uuid id PK
        string name
        string symbol
        string description
        boolean isDefault
    }
    
    PortfolioBenchmark {
        uuid portfolioId FK
        uuid benchmarkId FK
        decimal weight
        datetime assignedAt
    }
    
    AssetAllocation {
        uuid id PK
        uuid portfolioId FK
        string category
        decimal currentWeight
        decimal targetWeight
        decimal deviation
        datetime calculatedAt
    }

    Portfolio ||--o{ PerformanceMetrics : "has"
    Portfolio ||--o{ PortfolioBenchmark : "benchmarked_against"
    Benchmark ||--o{ PortfolioBenchmark : "benchmarks"
    Portfolio ||--o{ AssetAllocation : "allocated_as"
```

## Reporting & Analytics Model

```mermaid
erDiagram
    Report {
        uuid id PK
        uuid userId FK
        string name
        enum type
        string parameters
        datetime generatedAt
        datetime periodStart
        datetime periodEnd
        string format
        string encryptedPath
    }
    
    ReportTemplate {
        uuid id PK
        string name
        enum category
        string template
        boolean isDefault
        datetime createdAt
    }
    
    TaxCalculation {
        uuid id PK
        uuid userId FK
        string financialYear
        decimal shortTermGains
        decimal longTermGains
        decimal totalDividend
        decimal totalInterest
        decimal taxableIncome
        decimal taxOwed
        datetime calculatedAt
    }
    
    Insight {
        uuid id PK
        uuid userId FK
        enum category
        string title
        string description
        string actionable
        enum priority
        datetime generatedAt
        boolean isDismissed
    }

    User ||--o{ Report : "generates"
    Report }o--|| ReportTemplate : "uses"
    User ||--o{ TaxCalculation : "calculates"
    User ||--o{ Insight : "receives"
```

## Import/Export Data Model

```mermaid
erDiagram
    ImportJob {
        uuid id PK
        uuid userId FK
        string filename
        enum sourceType
        enum status
        int totalRecords
        int successfulRecords
        int failedRecords
        datetime startedAt
        datetime completedAt
        string errorLog
    }
    
    ImportMapping {
        uuid id PK
        uuid importJobId FK
        string sourceField
        string targetField
        enum dataType
        string transformation
        boolean isRequired
    }
    
    ExportJob {
        uuid id PK
        uuid userId FK
        enum exportType
        string parameters
        enum status
        string outputPath
        datetime requestedAt
        datetime completedAt
    }
    
    DataValidation {
        uuid id PK
        uuid importJobId FK
        int recordNumber
        string fieldName
        string errorMessage
        enum severity
        datetime detectedAt
    }

    User ||--o{ ImportJob : "initiates"
    ImportJob ||--o{ ImportMapping : "uses"
    ImportJob ||--o{ DataValidation : "validates"
    User ||--o{ ExportJob : "requests"
```

## System Integration Points

```mermaid
graph TB
    subgraph "WealthWise Core"
        A[SwiftData Store]
        B[Business Logic]
        C[Security Layer]
    end
    
    subgraph "Apple Ecosystem"
        D[CloudKit Sync]
        E[Keychain Services]
        F[LocalAuthentication]
        G[WidgetKit]
    end
    
    subgraph "External Services"
        H[Market Data APIs]
        I[Bank APIs]
        J[Tax Services]
    end
    
    subgraph "File System"
        K[iCloud Drive]
        L[Local Backups]
        M[Import Files]
    end
    
    B --> A
    C --> E
    C --> F
    B --> H
    B --> I
    A --> D
    B --> K
    B --> L
    A --> G
    
    style A fill:#4caf50
    style C fill:#f44336
    style H fill:#ff9800
```

## Notes

### Entity Constraints
1. **User**: Single user per application instance (local-first design)
2. **CrossBorderAsset**: Can be domestic or international, tracks multi-currency assets
3. **Transaction**: SwiftData @Model with comprehensive financial tracking
4. **Goal**: Supports milestone tracking and contribution suggestions
5. **PerformanceSnapshot**: Historical data, maximum 100 snapshots per asset

### Encryption Strategy
- **Field-Level**: Sensitive data encrypted before storage
- **Key Management**: Master key derived from biometric/password
- **Key Rotation**: Periodic rotation with migration support
- **Backup Security**: Separate encryption for export files

### Performance Considerations
- **Indexing**: Primary keys, foreign keys, date fields
- **Caching**: Calculated values cached with invalidation
- **Batch Operations**: Bulk imports/exports optimized
- **Lazy Loading**: Large datasets loaded on demand

### Data Integrity
- **Referential Integrity**: Foreign key constraints
- **Validation Rules**: Data type and range validation  
- **Audit Trail**: All changes logged for compliance
- **Backup Verification**: Checksums for data integrity