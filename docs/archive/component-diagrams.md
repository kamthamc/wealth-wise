# WealthWise Component Diagrams

## High-Level System Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[SwiftUI Views]
        B[ViewModels]
        C[Navigation Manager]
    end
    
    subgraph "Business Layer" 
        D[Portfolio Manager]
        E[Asset Manager]
        F[Transaction Manager]
        G[Reporting Engine]
        H[Calculation Service]
    end
    
    subgraph "Service Layer"
        I[Data Service]
        J[Security Service]
        K[Market Data Service]
        L[Import/Export Service]
        M[Notification Service]
    end
    
    subgraph "Data Layer"
        N[SwiftData Store]
        O[Keychain Services]
        P[File System]
        Q[CloudKit Sync]
    end
    
    A --> B
    B --> D
    B --> E
    B --> F
    B --> G
    
    D --> I
    E --> I
    F --> I
    G --> H
    
    I --> N
    J --> O
    K --> P
    L --> P
    M --> Q
    
    style A fill:#e3f2fd
    style D fill:#fff3e0
    style I fill:#e8f5e8
    style N fill:#fce4ec
```

## UI Component Architecture

```mermaid
graph TD
    subgraph "App Shell"
        A[WealthWiseMacApp]
        B[WindowGroup]
        C[MenuBarExtra]
    end
    
    subgraph "Main Interface"
        D[MacContentView]
        E[NavigationSplitView]
        F[SidebarView]
        G[ContentView]
        H[DetailView]
    end
    
    subgraph "Feature Views"
        I[DashboardView]
        J[PortfolioView] 
        K[AssetsView]
        L[ReportsView]
        M[SettingsView]
    end
    
    subgraph "Shared Components"
        N[AssetCard]
        O[TransactionList]
        P[PerformanceChart]
        Q[SearchBar]
        R[FilterPanel]
    end
    
    A --> B
    A --> C
    B --> D
    D --> E
    E --> F
    E --> G
    E --> H
    
    G --> I
    G --> J
    G --> K
    G --> L
    G --> M
    
    I --> N
    J --> O
    K --> P
    L --> Q
    M --> R
    
    style A fill:#4caf50
    style D fill:#2196f3
    style I fill:#ff9800
    style N fill:#9c27b0
```

## Data Flow Components

```mermaid
sequenceDiagram
    participant V as SwiftUI View
    participant VM as ViewModel
    participant AM as Asset Manager
    participant DS as Data Service
    participant SD as SwiftData
    participant SS as Security Service
    participant KS as Keychain
    
    V->>VM: User Action (Add Asset)
    VM->>AM: createAsset(assetData)
    AM->>DS: save(asset)
    DS->>SS: encryptSensitiveFields(asset)
    SS->>KS: getEncryptionKey()
    KS-->>SS: encryptionKey
    SS-->>DS: encryptedAsset
    DS->>SD: insert(encryptedAsset)
    SD-->>DS: success
    DS-->>AM: assetId
    AM-->>VM: success
    VM-->>V: updateUI
```

## Security Components

```mermaid
graph TB
    subgraph "Authentication Layer"
        A[LocalAuthentication]
        B[BiometricAuth]
        C[MasterPassword]
        D[AuthManager]
    end
    
    subgraph "Encryption Layer"
        E[CryptoKit]
        F[EncryptionService]
        G[KeyManager]
        H[FieldEncryption]
    end
    
    subgraph "Key Management"
        I[Keychain Services]
        J[Key Derivation]
        K[Key Rotation]
        L[Secure Enclave]
    end
    
    subgraph "Data Protection"
        M[Data Classification]
        N[Access Control]
        O[Audit Logging]
        P[Secure Deletion]
    end
    
    D --> A
    A --> B
    A --> C
    
    F --> E
    F --> G
    F --> H
    
    G --> I
    G --> J
    G --> K
    I --> L
    
    H --> M
    N --> O
    O --> P
    
    style A fill:#f44336
    style E fill:#ff5722
    style I fill:#795548
    style M fill:#607d8b
```

## Business Logic Components

```mermaid
graph TB
    subgraph "Portfolio Management"
        A[PortfolioManager]
        B[HoldingCalculator]
        C[AllocationAnalyzer]
        D[RebalancingEngine]
    end
    
    subgraph "Asset Management"
        E[AssetManager]
        F[ValuationService]
        G[PriceHistory]
        H[AssetClassifier]
    end
    
    subgraph "Transaction Processing"
        I[TransactionManager]
        J[TradeExecutor]
        K[CorporateActions]
        L[DividendTracker]
    end
    
    subgraph "Analytics & Reporting"
        M[ReportingEngine]
        N[PerformanceCalculator]
        O[TaxCalculator]
        P[InsightsGenerator]
    end
    
    A --> B
    A --> C
    A --> D
    
    E --> F
    E --> G
    E --> H
    
    I --> J
    I --> K
    I --> L
    
    M --> N
    M --> O
    M --> P
    
    B --> F
    C --> G
    N --> H
    O --> L
    
    style A fill:#4caf50
    style E fill:#2196f3
    style I fill:#ff9800
    style M fill:#9c27b0
```

## Service Layer Architecture

```mermaid
graph TB
    subgraph "Core Services"
        A[DataService]
        B[SecurityService] 
        C[ConfigurationService]
        D[LoggingService]
    end
    
    subgraph "Domain Services"
        E[MarketDataService]
        F[CalculationService]
        G[NotificationService]
        H[BackupService]
    end
    
    subgraph "Integration Services"
        I[ImportService]
        J[ExportService]
        K[SyncService]
        L[ValidationService]
    end
    
    subgraph "External Adapters"
        M[BankAPIAdapter]
        N[MarketDataAdapter]
        O[CloudStorageAdapter]
        P[NotificationAdapter]
    end
    
    A --> B
    A --> C
    A --> D
    
    E --> F
    E --> G
    E --> H
    
    I --> J
    I --> K
    I --> L
    
    E --> N
    F --> M
    H --> O
    G --> P
    
    style A fill:#4caf50
    style E fill:#ff9800
    style I fill:#2196f3
    style M fill:#9c27b0
```

## Data Layer Components

```mermaid
graph TB
    subgraph "SwiftData Layer"
        A[ModelContainer]
        B[ModelContext]
        C[Query Engine]
        D[Migration Manager]
    end
    
    subgraph "Data Models"
        E[Asset Model]
        F[Portfolio Model]
        G[Transaction Model]
        H[User Model]
    end
    
    subgraph "Storage Layer"
        I[SQLite Database]
        J[File Storage]
        K[Keychain Storage]
        L[CloudKit Container]
    end
    
    subgraph "Data Operations"
        M[CRUD Operations]
        N[Batch Processing]
        O[Query Optimization]
        P[Cache Management]
    end
    
    B --> A
    C --> A
    D --> A
    
    E --> F
    F --> G
    G --> H
    
    A --> I
    J --> K
    K --> L
    
    M --> N
    N --> O
    O --> P
    
    B --> E
    C --> M
    
    style A fill:#4caf50
    style E fill:#2196f3
    style I fill:#ff9800
    style M fill:#9c27b0
```

## Dependency Injection Architecture

```mermaid
graph TB
    subgraph "DI Container"
        A[ServiceContainer]
        B[ServiceRegistry]
        C[DependencyResolver]
        D[LifecycleManager]
    end
    
    subgraph "Service Protocols"
        E[IDataService]
        F[ISecurityService]
        G[IMarketDataService]
        H[ICalculationService]
    end
    
    subgraph "Implementations"
        I[SwiftDataService]
        J[KeychainSecurityService]
        K[YahooMarketDataService]
        L[PortfolioCalculationService]
    end
    
    subgraph "Consumers"
        M[ViewModels]
        N[Managers]
        O[Services]
        P[Components]
    end
    
    A --> B
    B --> C
    C --> D
    
    E --> F
    F --> G
    G --> H
    
    I --> E
    J --> F
    K --> G
    L --> H
    
    C --> M
    C --> N
    C --> O
    C --> P
    
    style A fill:#4caf50
    style E fill:#2196f3
    style I fill:#ff9800
    style M fill:#9c27b0
```

## Testing Architecture

```mermaid
graph TB
    subgraph "Test Types"
        A[Unit Tests]
        B[Integration Tests]
        C[UI Tests]
        D[Performance Tests]
    end
    
    subgraph "Test Infrastructure"
        E[XCTest Framework]
        F[Mock Services]
        G[Test Data Factory]
        H[Test Utilities]
    end
    
    subgraph "Test Targets"
        I[Business Logic]
        J[Data Layer]
        K[Security Components]
        L[UI Components]
    end
    
    subgraph "Test Tools"
        M[Xcode Test Navigator]
        N[Test Coverage]
        O[Performance Metrics]
        P[CI/CD Pipeline]
    end
    
    A --> E
    B --> F
    C --> G
    D --> H
    
    E --> I
    F --> J
    G --> K
    H --> L
    
    I --> M
    J --> N
    K --> O
    L --> P
    
    style A fill:#4caf50
    style E fill:#2196f3
    style I fill:#ff9800
    style M fill:#9c27b0
```

## Performance & Monitoring

```mermaid
graph TB
    subgraph "Performance Monitoring"
        A[Metrics Collection]
        B[Performance Profiler]
        C[Memory Monitor]
        D[Network Monitor]
    end
    
    subgraph "Error Handling"
        E[Error Manager]
        F[Crash Reporter]
        G[Logging System]
        H[Alert System]
    end
    
    subgraph "Analytics"
        I[Usage Analytics]
        J[Performance Analytics]
        K[Error Analytics]
        L[User Behavior]
    end
    
    subgraph "Optimization"
        M[Cache Strategy]
        N[Lazy Loading]
        O[Background Processing]
        P[Resource Management]
    end
    
    A --> B
    B --> C
    C --> D
    
    E --> F
    F --> G
    G --> H
    
    I --> J
    J --> K
    K --> L
    
    M --> N
    N --> O
    O --> P
    
    B --> I
    F --> K
    
    style A fill:#4caf50
    style E fill:#f44336
    style I fill:#ff9800
    style M fill:#2196f3
```

## Deployment Components

```mermaid
graph TB
    subgraph "Build Process"
        A[Source Code]
        B[Swift Compiler]
        C[Asset Compilation]
        D[Code Signing]
    end
    
    subgraph "Distribution"
        E[App Store Connect]
        F[TestFlight]
        G[Direct Distribution]
        H[Enterprise Distribution]
    end
    
    subgraph "Configuration"
        I[Build Configurations]
        J[Environment Variables]
        K[Feature Flags]
        L[Localization]
    end
    
    subgraph "Quality Assurance"
        M[Automated Testing]
        N[Manual Testing]
        O[Performance Testing]
        P[Security Audit]
    end
    
    A --> B
    B --> C
    C --> D
    
    D --> E
    E --> F
    F --> G
    G --> H
    
    I --> J
    J --> K
    K --> L
    
    M --> N
    N --> O
    O --> P
    
    C --> I
    D --> M
    
    style A fill:#4caf50
    style E fill:#2196f3
    style I fill:#ff9800
    style M fill:#9c27b0
```

## Notes

### Component Responsibilities

#### Presentation Layer
- **SwiftUI Views**: User interface rendering and interaction
- **ViewModels**: State management and business logic coordination  
- **Navigation**: App flow and deep linking management

#### Business Layer
- **Managers**: Core business logic and workflow orchestration
- **Services**: Specific domain functionality and calculations
- **Engines**: Complex processing and analysis algorithms

#### Data Layer
- **SwiftData**: Local database management and querying
- **Services**: Data access abstraction and caching
- **Security**: Encryption, authentication, and key management

### Communication Patterns
- **Protocols**: Define service interfaces and contracts
- **Dependency Injection**: Loose coupling and testability
- **Combine**: Reactive programming for data flow
- **Async/Await**: Asynchronous operation management

### Error Handling Strategy
- **Result Types**: Explicit error handling in service layer
- **Error Propagation**: Structured error bubbling to UI
- **Logging**: Comprehensive error tracking and analysis
- **Recovery**: Graceful degradation and retry mechanisms