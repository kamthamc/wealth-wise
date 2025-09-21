# WealthWise Entity-Relationship Diagrams

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
    
    Portfolio {
        uuid id PK
        uuid userId FK
        string name
        string description
        datetime createdAt
        datetime updatedAt
        decimal totalValue
        string currency
        boolean isDefault
    }
    
    Asset {
        uuid id PK
        uuid portfolioId FK
        string name
        string symbol
        enum type
        string category
        decimal currentValue
        decimal purchasePrice
        datetime purchaseDate
        string currency
        decimal quantity
        string encryptedAccountNumber
        string encryptedNotes
        datetime createdAt
        datetime updatedAt
    }
    
    Transaction {
        uuid id PK
        uuid assetId FK
        uuid portfolioId FK
        enum type
        decimal amount
        decimal price
        decimal quantity
        datetime date
        string description
        string encryptedReference
        string encryptedNotes
        datetime createdAt
    }
    
    Valuation {
        uuid id PK
        uuid assetId FK
        decimal price
        decimal marketValue
        datetime date
        string source
        datetime createdAt
    }
    
    Category {
        uuid id PK
        string name
        string description
        string color
        string icon
        uuid parentId FK
        boolean isDefault
    }
    
    MarketData {
        uuid id PK
        string symbol
        string exchange
        decimal price
        decimal previousClose
        decimal change
        decimal changePercent
        datetime lastUpdated
        string currency
    }
    
    Alert {
        uuid id PK
        uuid userId FK
        uuid assetId FK
        enum type
        string title
        string message
        decimal triggerValue
        boolean isActive
        datetime createdAt
        datetime triggeredAt
    }
    
    Backup {
        uuid id PK
        uuid userId FK
        string filename
        string encryptedPath
        datetime createdAt
        long fileSize
        string checksum
    }
    
    AuditLog {
        uuid id PK
        uuid userId FK
        string action
        string entityType
        uuid entityId
        string oldValues
        string newValues
        datetime timestamp
        string ipAddress
        string userAgent
    }

    User ||--o{ Portfolio : "owns"
    Portfolio ||--o{ Asset : "contains"
    Asset ||--o{ Transaction : "has"
    Asset ||--o{ Valuation : "valued_by"
    Asset }o--|| Category : "categorized_as"
    User ||--o{ Alert : "receives"
    Alert }o--|| Asset : "monitors"
    User ||--o{ Backup : "creates"
    User ||--o{ AuditLog : "generates"
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
1. **User**: Single user per application instance
2. **Portfolio**: User can have multiple portfolios, one default
3. **Asset**: Must belong to exactly one portfolio
4. **Transaction**: Must reference valid asset and portfolio
5. **Valuation**: Historical price data, multiple per asset

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