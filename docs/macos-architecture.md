# macOS WealthWise Architecture

## Overview

WealthWise macOS is a native SwiftUI application designed for comprehensive personal finance management with local-first, privacy-focused architecture. The application provides secure asset tracking, portfolio management, and financial insights while maintaining complete data ownership through local encrypted storage.

### Technology Stack

#### Core Technologies
- **UI Framework**: SwiftUI with AppKit integration
- **Visual Effects**: Glass effects for macOS 15+ and iOS 18+ (enhanced for 26+)
- **Data Persistence**: SwiftData with CloudKit sync (optional)
- **Authentication**: LocalAuthentication framework
- **Encryption**: CryptoKit for AES-256 encryption
- **Networking**: URLSession for market data (optional)
- **Testing**: XCTest with SwiftUI testing utilities

## Architecture Principles

### 1. Local-First Design
- All financial data stored locally with AES-256 encryption
- No external backend services or cloud dependencies
- Complete functionality without internet connectivity
- Optional iCloud backup for data portability

### 2. Security-First Approach
- Biometric authentication (Touch ID/Face ID) with master password fallback
- AES-256 encryption for all sensitive data at rest
- Secure key management via Keychain Services
- Data isolation and secure memory handling

### 3. SwiftUI Native Experience
- Platform-native UI following macOS design guidelines
- Multi-window support with proper state management
- Dark mode and accessibility compliance
- Menu bar integration and keyboard shortcuts
- Glass effect utilization for macOS 26+ and iOS 26+ with graceful fallbacks

### 4. Modular Architecture
- Clear separation of concerns with protocol-based interfaces
- Dependency injection for testability and maintainability
- Reactive programming with Combine framework
- Service-oriented architecture for business logic

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      WealthWise macOS                       │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI Views)                         │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐  │
│  │ Dashboard   │ Portfolio   │ Assets      │ Reports     │  │
│  │ View        │ View        │ View        │ View        │  │
│  └─────────────┴─────────────┴─────────────┴─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Business Logic Layer                                       │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐  │
│  │ Portfolio   │ Asset       │ Reporting   │ Import/     │  │
│  │ Manager     │ Manager     │ Engine      │ Export      │  │
│  └─────────────┴─────────────┴─────────────┴─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                              │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐  │
│  │ Data        │ Security    │ Market      │ Calculation │  │
│  │ Service     │ Service     │ Data        │ Service     │  │
│  └─────────────┴─────────────┴─────────────┴─────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                 │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐  │
│  │ SwiftData   │ Keychain    │ File        │ iCloud      │  │
│  │ Store       │ Services    │ System      │ Backup      │  │
│  └─────────────┴─────────────┴─────────────┴─────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Presentation Layer

#### 1. View Hierarchy
```swift
WealthWiseMacApp
├── WindowGroup
│   ├── MacContentView (NavigationSplitView)
│   │   ├── SidebarView
│   │   ├── ContentView
│   │   └── DetailView
│   ├── DashboardView
│   ├── PortfolioView
│   ├── AssetsView
│   └── ReportsView
└── MenuBarExtra (optional)
```

#### 2. Navigation Management
- `NavigationManager`: Centralized navigation state
- Deep linking support for menu commands
- Multi-window coordination
- State restoration

#### 3. View Models
- Protocol-based ViewModels using `ObservableObject`
- Reactive data binding with `@Published` properties
- Error handling and loading states
- Input validation and formatting

### Business Logic Layer

#### 1. Asset Management
```swift
protocol AssetManagerProtocol {
    func addAsset(_ asset: Asset) async throws
    func updateAsset(_ asset: Asset) async throws
    func deleteAsset(id: UUID) async throws
    func calculateNetWorth() async -> Decimal
    func getAssetsByType(_ type: AssetType) async -> [Asset]
}
```

#### 2. Portfolio Management
```swift
protocol PortfolioManagerProtocol {
    func createPortfolio(_ portfolio: Portfolio) async throws
    func addHolding(_ holding: Holding, to portfolioId: UUID) async throws
    func calculatePortfolioValue(_ portfolioId: UUID) async -> PortfolioValue
    func getPerformanceMetrics(_ portfolioId: UUID) async -> PerformanceMetrics
}
```

#### 3. Calculation Engine
- Real-time net worth calculation
- P&L calculations (realized/unrealized)
- Tax implications and reporting
- Performance metrics and ratios
- Currency conversion support

### Service Layer

#### 1. Data Service
```swift
protocol DataServiceProtocol {
    func save<T: PersistentModel>(_ model: T) async throws
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) async throws -> [T]
    func delete<T: PersistentModel>(_ model: T) async throws
    func executeQuery<T>(_ query: Query<T>) async throws -> [T]
}
```

#### 2. Security Service
```swift
protocol SecurityServiceProtocol {
    func authenticateUser() async throws -> Bool
    func encryptData(_ data: Data) throws -> Data
    func decryptData(_ encryptedData: Data) throws -> Data
    func storeSecurely(_ data: Data, key: String) throws
    func retrieveSecurely(key: String) throws -> Data?
}
```

#### 3. Market Data Service
```swift
protocol MarketDataServiceProtocol {
    func getCurrentPrice(symbol: String) async -> Price?
    func getHistoricalPrices(symbol: String, range: DateRange) async -> [Price]
    func searchSymbol(_ query: String) async -> [SecurityInfo]
}
```

### Data Layer

#### 1. SwiftData Models
```swift
@Model
class Asset {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: AssetType
    var currentValue: Decimal
    var purchaseDate: Date
    var purchasePrice: Decimal?
    @Relationship var transactions: [Transaction]
    
    // Encrypted fields using custom property wrappers
    @Encrypted var accountNumber: String?
    @Encrypted var notes: String?
}

@Model  
class Portfolio {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String?
    var createdDate: Date
    @Relationship var holdings: [Holding]
    @Relationship var transactions: [Transaction]
}

@Model
class Transaction {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: TransactionType
    var amount: Decimal
    var price: Decimal?
    var quantity: Decimal?
    @Relationship var asset: Asset
    @Relationship var portfolio: Portfolio?
    
    @Encrypted var reference: String?
    @Encrypted var notes: String?
}
```

#### 2. Encryption Layer
```swift
@propertyWrapper
struct Encrypted<T: Codable> {
    private let key: String
    private let securityService: SecurityServiceProtocol
    
    var wrappedValue: T? {
        get { /* Decrypt and decode */ }
        set { /* Encode and encrypt */ }
    }
}
```

## Security Architecture

### 1. Authentication Flow
```
App Launch
    ↓
Biometric Check Available?
    ├─ Yes → Touch ID/Face ID
    │        ├─ Success → Unlock App
    │        └─ Failure → Master Password
    └─ No → Master Password
             ├─ Success → Unlock App  
             └─ Failure → Exit/Retry
```

### 2. Encryption Strategy

#### AES-256-GCM Encryption with CryptoKit
```
┌────────────────────────────────────────────────────────┐
│          Encryption Service Architecture               │
├────────────────────────────────────────────────────────┤
│                                                         │
│  Master Key Generation:                                │
│    ┌──────────────┐                                    │
│    │ User Auth    │ → Derive Key → ┌──────────────┐   │
│    │ (Biometric/  │                │ SymmetricKey │   │
│    │  Password)   │                │  (256-bit)   │   │
│    └──────────────┘                └──────────────┘   │
│                                           ↓            │
│                                    Store in Keychain   │
│                                    (kSecAttrAccessible │
│                                     WhenUnlockedThis   │
│                                     DeviceOnly)        │
│                                                         │
│  Field-Level Encryption:                               │
│    Plain Text → AES.GCM.seal() → Encrypted Data       │
│                      ↓                                  │
│              Combined format:                           │
│              [nonce + ciphertext + tag]                │
│                                                         │
│  Encrypted Fields:                                     │
│    • Transaction.encryptedReference                    │
│    • Transaction.encryptedNotes                        │
│    • CrossBorderAsset.accountNumber (if implemented)   │
│    • CrossBorderAsset.notes (if implemented)           │
│                                                         │
└────────────────────────────────────────────────────────┘
```

#### Encryption Implementation Pattern
```swift
// Encryption Service (CryptoKit-based)
actor EncryptionService {
    private let key: SymmetricKey
    
    func encrypt(_ data: Data) async throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ encryptedData: Data) async throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

// Property Wrapper for Transparent Encryption
@propertyWrapper
struct Encrypted<T: Codable> {
    private var encryptedValue: Data?
    
    var wrappedValue: T? {
        get { /* Decrypt and decode */ }
        set { /* Encode and encrypt */ }
    }
}
```

### 3. Data Classification

#### Security Levels
```
┌─────────────────────────────────────────────────────────┐
│ Security Level │ Data Type              │ Protection    │
├────────────────┼────────────────────────┼───────────────┤
│ PUBLIC         │ • Asset types          │ None          │
│                │ • Currency codes       │               │
│                │ • Category names       │               │
│                │ • Enum values          │               │
├────────────────┼────────────────────────┼───────────────┤
│ CONFIDENTIAL   │ • Asset values         │ App-level     │
│                │ • Transaction amounts  │ access control│
│                │ • Portfolio totals     │               │
│                │ • Performance metrics  │               │
├────────────────┼────────────────────────┼───────────────┤
│ SECRET         │ • Account numbers      │ AES-256-GCM   │
│                │ • Transaction refs     │ + Keychain    │
│                │ • Personal notes       │               │
│                │ • Tax documents        │               │
└────────────────┴────────────────────────┴───────────────┘
```

### 4. Key Management Flow
```
┌─────────────────────────────────────────────────────────┐
│              Key Lifecycle Management                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Key Generation (First Launch):                      │
│     User Auth → Generate 256-bit key → Store in Keychain│
│                                                          │
│  2. Key Retrieval (App Launch):                         │
│     User Auth → Load from Keychain → Unlock App        │
│                                                          │
│  3. Key Rotation (Annual or on-demand):                 │
│     Generate new key → Re-encrypt data → Replace old key│
│                                                          │
│  4. Key Backup (Optional iCloud):                       │
│     Encrypt key with user password → Upload to iCloud   │
│     (Separate from encrypted data backup)               │
│                                                          │
│  5. Key Recovery:                                       │
│     User password → Decrypt backup key → Restore        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Entity-Relationship Diagram

### Core Data Models (Actual Implementation)

```
┌──────────────────────┐     ┌──────────────────────┐
│  CrossBorderAsset    │     │     Transaction      │
│  (Struct/Codable)    │     │  (@Model/SwiftData)  │
├──────────────────────┤     ├──────────────────────┤
│ - id: UUID           │     │ - id: UUID           │
│ - name: String       │     │ - amount: Decimal    │
│ - assetType: Enum    │     │ - currency: String   │
│ - domicileCountry    │     │ - transactionType    │
│ - ownerCountry       │     │ - category: Enum     │
│ - currentValue       │     │ - date: Date         │
│ - nativeCurrency     │     │ - accountType: Enum  │
│ - quantity           │     │ - status: Enum       │
│ - pricePerUnit       │     │ - isTaxable: Bool    │
│ - isActive: Bool     │     │ - taxCategory        │
│ - performanceHistory │     │ - linkedGoal         │
│ - taxJurisdictions   │     │ - attachments[]      │
└──────────────────────┘     └──────────────────────┘
         │                            │
         │                            │
         ▼                            ▼
┌──────────────────────┐     ┌──────────────────────┐
│ PerformanceSnapshot  │     │        Goal          │
│     (Embedded)       │     │  (@Model/SwiftData)  │
├──────────────────────┤     ├──────────────────────┤
│ - date: Date         │     │ - id: UUID           │
│ - value: Decimal     │     │ - title: String      │
│ - currency: String   │     │ - targetAmount       │
│ - source: String     │     │ - currentAmount      │
└──────────────────────┘     │ - targetDate: Date   │
                             │ - goalType: Enum     │
                             │ - priority: Enum     │
┌──────────────────────┐     │ - milestones[]       │
│   IncomePayment      │     │ - contributions[]    │
│     (Embedded)       │     │ - progressHistory[]  │
├──────────────────────┤     │ - linkedTransactions │
│ - amount: Decimal    │     └──────────────────────┘
│ - currency: String   │              │
│ - paymentDate        │              │
│ - type: Enum         │              ▼
└──────────────────────┘     ┌──────────────────────┐
                             │   GoalMilestone      │
                             │     (Embedded)       │
                             ├──────────────────────┤
                             │ - id: UUID           │
                             │ - percentage: Double │
                             │ - targetAmount       │
                             │ - targetDate: Date   │
                             │ - isAchieved: Bool   │
                             └──────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                    Supporting Models                      │
├──────────────────────────────────────────────────────────┤
│ • AssetType: Enum (equity, fixedIncome, alternative)     │
│ • AssetCategory: Enum (derived from AssetType)           │
│ • ComplianceRequirement: Enum (tax, reporting)           │
│ • TransactionCategory: Enum (50+ categories)             │
│ • AccountType: Enum (bank, credit_card, investment)      │
│ • TaxCategory: Enum (STCG, LTCG, dividend, interest)     │
│ • GoalType: Enum (investment, retirement, education)     │
│ • RiskTolerance: Enum (conservative to aggressive)       │
└──────────────────────────────────────────────────────────┘
```

### Cross-Border Asset System

```
┌─────────────────────────────────────────────────────────┐
│              CrossBorderAsset Properties                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Geographic & Regulatory:                               │
│    • domicileCountryCode (where asset is registered)    │
│    • ownerCountryCode (investor's country)              │
│    • taxJurisdictions (Set<String>)                     │
│    • complianceRequirements (Set<ComplianceRequirement>)│
│                                                          │
│  Financial Information:                                 │
│    • currentValue (Decimal)                             │
│    • nativeCurrencyCode (asset's currency)              │
│    • originalInvestment (Decimal?)                      │
│    • quantity (Decimal?)                                │
│    • pricePerUnit (Decimal?)                            │
│                                                          │
│  Risk & Analytics:                                      │
│    • riskRating (RiskRating?)                           │
│    • liquidityRating (LiquidityRating)                  │
│    • esgScore (ESGScore?)                               │
│    • correlationData ([String: Decimal])                │
│                                                          │
│  Computed Properties:                                   │
│    • isCrossBorder (Bool)                               │
│    • unrealizedGainLoss (Decimal?)                      │
│    • unrealizedGainLossPercentage (Double?)             │
│    • currentYield (Double?)                             │
│    • qualifiesForLongTermCapitalGains (Bool)            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Service Layer Architecture

### Core Services Implementation

```
┌─────────────────────────────────────────────────────────┐
│                  Service Layer Design                    │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │         CurrencyService (Implemented)           │   │
│  ├─────────────────────────────────────────────────┤   │
│  │ • Currency conversion & exchange rates          │   │
│  │ • Multi-currency support                        │   │
│  │ • Real-time rate updates                        │   │
│  │ • Offline rate caching                          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │         SecurityService (Planned)               │   │
│  ├─────────────────────────────────────────────────┤   │
│  │ • Biometric authentication                      │   │
│  │ • AES-256-GCM encryption                        │   │
│  │ • Keychain key management                       │   │
│  │ • Secure data deletion                          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │         DataService (SwiftData-based)           │   │
│  ├─────────────────────────────────────────────────┤   │
│  │ • CRUD operations for @Model entities           │   │
│  │ • Query and filtering                           │   │
│  │ • Batch operations                              │   │
│  │ • CloudKit sync (optional)                      │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │         AssetManager (Implemented)              │   │
│  ├─────────────────────────────────────────────────┤   │
│  │ • CrossBorderAsset management                   │   │
│  │ • Performance tracking                          │   │
│  │ • Multi-currency valuation                      │   │
│  │ • Tax compliance monitoring                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
┌──────────────────────────────────────────────────────────┐
│         Transaction Creation Flow (Example)              │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  1. User Input (SwiftUI View)                           │
│     ↓                                                     │
│  2. ViewModel Validation                                │
│     • Amount validation                                  │
│     • Currency validation                                │
│     • Category selection                                 │
│     ↓                                                     │
│  3. Business Logic (Manager)                            │
│     • Apply business rules                               │
│     • Calculate tax implications                         │
│     • Determine transaction type                         │
│     ↓                                                     │
│  4. Service Layer Processing                            │
│     • Currency conversion (if cross-border)              │
│     • Encryption of sensitive fields                     │
│     • Prepare for persistence                            │
│     ↓                                                     │
│  5. Data Persistence (SwiftData)                        │
│     • Create Transaction @Model                          │
│     • Save to ModelContext                               │
│     • Trigger CloudKit sync (if enabled)                 │
│     ↓                                                     │
│  6. UI Update                                           │
│     • Reactive update via @Query                         │
│     • Animation and feedback                             │
│     • Update related views                               │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### Goal Progress Update Flow

```
┌──────────────────────────────────────────────────────────┐
│            Goal Progress Update Flow                      │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  @MainActor Goal.updateProgress(currentAmount:)         │
│     ↓                                                     │
│  1. Update current amount                                │
│  2. Calculate progress percentage                        │
│  3. Create progress snapshot                             │
│     • Date                                               │
│     • Current amount                                     │
│     • Progress percentage                                │
│     • Time elapsed percentage                            │
│     • Projected completion date                          │
│     ↓                                                     │
│  4. Check milestone achievements                         │
│     • Iterate through milestones                         │
│     • Mark achieved milestones                           │
│     • Record achievement date                            │
│     ↓                                                     │
│  5. Check for goal completion                           │
│     • If currentAmount >= targetAmount                   │
│     • Mark goal as completed                             │
│     • Set completion date                                │
│     • Mark all milestones achieved                       │
│     ↓                                                     │
│  6. Update timestamp                                     │
│     • Set updatedAt = Date()                             │
│     • Set lastCalculatedAt = Date()                      │
│     ↓                                                     │
│  7. SwiftData auto-save                                 │
│     • @Model change tracking                             │
│     • Persist to database                                │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Component Interaction Diagram

### High-Level Component Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   SwiftUI   │───▶│ ViewModel   │───▶│   Manager   │
│    View     │    │ (@Observable│    │  (Business) │
│             │◀───│  Protocol)  │◀───│   Logic)    │
└─────────────┘    └─────────────┘    └─────────────┘
        │                 │                    │
        │                 │                    ▼
        │                 │           ┌─────────────┐
        │                 │           │   Service   │
        │                 │           │   Layer     │
        │                 │           └─────────────┘
        │                 │                    │
        ▼                 ▼                    ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Navigation  │    │   Combine   │    │  SwiftData  │
│  Manager    │    │ Publishers  │    │   Store     │
│             │    │   @Query    │    │ @ModelContext│
└─────────────┘    └─────────────┘    └─────────────┘
```

### Detailed Transaction Processing Flow

```
User Action (Add Transaction)
        ↓
┌────────────────────────────────────┐
│  TransactionView (SwiftUI)         │
│  • Form fields                     │
│  • Amount input                    │
│  • Category picker                 │
│  • Date picker                     │
└────────────────────────────────────┘
        ↓ Binding
┌────────────────────────────────────┐
│  TransactionViewModel              │
│  • @Published properties           │
│  • Validation logic                │
│  • Format helpers                  │
└────────────────────────────────────┘
        ↓ Submit Action
┌────────────────────────────────────┐
│  TransactionManager                │
│  • Business rules                  │
│  • Tax calculations                │
│  • Currency conversion             │
└────────────────────────────────────┘
        ↓
┌────────────────────────────────────┐
│  Services (Parallel)               │
│  ├─ CurrencyService                │
│  │   └─ Convert if cross-border    │
│  ├─ SecurityService                │
│  │   └─ Encrypt sensitive fields   │
│  └─ DataService                    │
│      └─ Prepare persistence        │
└────────────────────────────────────┘
        ↓
┌────────────────────────────────────┐
│  SwiftData ModelContext            │
│  • insert(transaction)             │
│  • try context.save()              │
│  • CloudKit sync (if enabled)      │
└────────────────────────────────────┘
        ↓
┌────────────────────────────────────┐
│  Reactive UI Update                │
│  • @Query automatically updates    │
│  • List view refreshes             │
│  • Animation plays                 │
│  • Success feedback                │
└────────────────────────────────────┘
```

## Technology Stack

### Core Technologies
- **UI Framework**: SwiftUI with AppKit integration
- **Data Persistence**: SwiftData with CloudKit sync (optional)
- **Authentication**: LocalAuthentication framework
- **Encryption**: CryptoKit for AES-256 encryption
- **Networking**: URLSession for market data (optional)
- **Testing**: XCTest with SwiftUI testing utilities

### Development Tools
- **IDE**: Xcode 15.0+
- **Language**: Swift 5.9+
- **Minimum Target**: macOS 15.0, iOS 18.0
- **Package Manager**: Swift Package Manager
- **CI/CD**: GitHub Actions

### Third-Party Dependencies
- **Charts**: Swift Charts for financial visualizations
- **CSV**: SwiftCSV for import/export functionality
- **Keychain**: KeychainAccess for secure storage
- **Logging**: OSLog for system integration

## Performance Considerations

### 1. Memory Management
- Lazy loading for large datasets
- Efficient Core Data fetching with batch sizes
- Image and chart caching strategies
- Proper object lifecycle management

### 2. Data Operations
- Background processing for calculations
- Incremental updates for real-time data
- Efficient queries with proper indexing
- Batch operations for bulk imports

### 3. UI Responsiveness
- Async/await for non-blocking operations
- Progressive loading for complex views
- Optimized list rendering with lazy stacks
- Debounced search and filtering

## Deployment Architecture

### 1. Build Configuration
```
Debug
├── Local data only
├── Mock market data
└── Development logging

Release  
├── Encrypted local storage
├── Optional market data
└── Minimal logging
```

### 2. Distribution
- Mac App Store distribution
- Notarization for direct distribution
- Automatic updates via App Store
- Privacy-compliant analytics (optional)

### 3. Data Migration
- SwiftData automatic lightweight migration
- Custom migration for complex schema changes
- Backup and rollback procedures
- Version compatibility matrix

## Testing Strategy

### 1. Unit Testing
- Business logic managers with mocked dependencies
- Calculation engine accuracy tests
- Encryption/decryption validation
- Data model validation and constraints

### 2. Integration Testing
- SwiftData operations and migrations
- Security service integration
- Import/export workflows
- Multi-window state management

### 3. UI Testing
- Critical user flows (add asset, view portfolio)
- Navigation and menu interactions
- Accessibility compliance
- Performance benchmarking

## Glass Effect Implementation

### Version Detection Strategy
```swift
// Automatic detection of glass effect capabilities
PlatformInfo.Features.advancedGlassEffects  // macOS 26+ / iOS 26+
PlatformInfo.Features.basicGlassEffects     // macOS 15+ / iOS 18+

// Usage in components
.cardGlassEffect()           // Dashboard cards
.sidebarGlassEffect()        // Navigation sidebar  
.modalGlassEffect()          // Modal dialogs
```

### Glass Effect Components
1. **GlassCard**: Context-aware cards with multiple styles
2. **GlassToolbar**: Floating toolbar with glass background
3. **GlassModalView**: Enhanced modal presentation
4. **GlassBackground**: Large area background effects

### Supported OS Versions
- **Minimum**: macOS 15.0, iOS 18.0 (basic glass effects with .ultraThinMaterial)
- **Enhanced**: macOS 26.0+, iOS 26.0+ (advanced glass effects with gradients and shadows)
- **Unsupported**: Older OS versions are not supported by WealthWise

## Future Considerations

### 1. Extensibility
- Plugin architecture for new asset types
- Custom report generation
- API integration framework
- Third-party service connectors
- Enhanced glass effects for future OS versions

### 2. Platform Expansion
- iOS companion app with shared data models and consistent glass UI
- Apple Watch complications and notifications
- Shortcuts and Siri integration
- Focus modes and productivity features
- Cross-platform glass effect synchronization

### 3. Advanced Features
- Machine learning for categorization
- Natural language transaction entry
- Advanced portfolio analytics with glass effect visualizations
- Tax optimization recommendations
- Adaptive glass effects based on content and user preferences

## SwiftData Implementation Patterns

### @Model Entity Design

```swift
// Current Implementation Examples

// 1. Transaction (@Model with SwiftData)
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Transaction {
    @Attribute(.unique) public var id: UUID
    public var amount: Decimal
    public var currency: String
    public var transactionDescription: String
    
    // Relationships
    @Relationship(deleteRule: .nullify) public var linkedGoal: Goal?
    @Relationship(deleteRule: .cascade) public var attachments: [TransactionAttachment]?
    
    // Computed properties for business logic
    public var displayAmount: String { /* formatted */ }
    public var isCrossBorder: Bool { /* check currencies */ }
    public var taxEfficiencyScore: Double { /* calculate */ }
}

// 2. Goal (@Model with comprehensive tracking)
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Goal {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var targetAmount: Decimal
    
    // Embedded collections (Codable structs)
    public var milestones: [GoalMilestone]
    public var contributions: [GoalContribution]
    public var progressHistory: [ProgressSnapshot]
    
    // Relationships
    @Relationship(deleteRule: .cascade) public var linkedTransactions: [Transaction]?
}

// 3. CrossBorderAsset (Struct/Codable - not SwiftData)
public struct CrossBorderAsset: Codable, Hashable, Identifiable {
    public let id: UUID
    public var name: String
    public var assetType: AssetType
    public var currentValue: Decimal
    
    // Embedded collections
    public var performanceHistory: [PerformanceSnapshot]
    public var taxJurisdictions: Set<String>
    public var complianceRequirements: Set<ComplianceRequirement>
}
```

### Actor Isolation and Concurrency

```swift
// Service-level actors for thread-safe operations
@globalActor
final actor FinancialServiceActor {
    static let shared = FinancialServiceActor()
}

@FinancialServiceActor
protocol TransactionService: Sendable {
    func createTransaction(_ transaction: Transaction) async throws
    func fetchTransactions(for account: Account) async throws -> [Transaction]
}

// MainActor for UI-bound operations
@MainActor
extension Goal {
    public func updateProgress(currentAmount: Decimal, source: ProgressUpdateSource = .manual) {
        self.currentAmount = currentAmount
        self.updatedAt = Date()
        checkMilestoneAchievements()
    }
}
```

### Data Persistence Strategy

```
┌─────────────────────────────────────────────────────────┐
│          Current Persistence Implementation              │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  SwiftData @Model Entities (Persistent):                │
│    ✅ Transaction (with relationships)                   │
│    ✅ Goal (with embedded collections)                   │
│    ✅ TransactionAttachment (embedded struct)            │
│    ⏳ User (planned)                                     │
│    ⏳ Portfolio (planned - when needed)                  │
│                                                          │
│  Codable Structs (Non-persistent):                      │
│    ✅ CrossBorderAsset (in-memory or JSON)              │
│    ✅ PerformanceSnapshot (embedded in assets)           │
│    ✅ GoalMilestone (embedded in goals)                  │
│    ✅ ExchangeRate (cached temporarily)                  │
│    ✅ TaxResidencyStatus (configuration)                 │
│                                                          │
│  Data Flow:                                             │
│    User Input → @Model Entity → SwiftData Context →     │
│    SQLite → CloudKit (optional)                         │
│                                                          │
│  Query Pattern:                                         │
│    @Query(sort: \Transaction.date, order: .reverse)     │
│    var transactions: [Transaction]                      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Implementation Roadmap

### Phase 1: Foundation (Current State)
- ✅ Core data models (Transaction, Goal, CrossBorderAsset)
- ✅ SwiftData integration for transactions and goals
- ✅ Multi-currency support infrastructure
- ✅ Tax calculation framework
- ✅ Localization framework (en, hi, ta)
- ⏳ Encryption service (design complete)
- ⏳ Security framework (authentication planned)

### Phase 2: Data Services (In Progress)
- ⏳ Complete SwiftData persistence layer
- ⏳ Implement encryption service with CryptoKit
- ⏳ Add CloudKit sync capability
- ⏳ Transaction import/export services
- ⏳ Market data integration
- ⏳ Currency conversion service enhancements

### Phase 3: Business Logic (Planned)
- ⏳ Asset management service
- ⏳ Portfolio calculation engine
- ⏳ Tax calculation service
- ⏳ Reporting engine
- ⏳ Goal tracking automation
- ⏳ Performance analytics

### Phase 4: UI & Experience (Planned)
- ⏳ Dashboard views
- ⏳ Transaction management UI
- ⏳ Goal tracking interface
- ⏳ Asset portfolio views
- ⏳ Reports and analytics
- ⏳ Settings and preferences

## Architecture Documentation Status

### Completed
- ✅ Entity-relationship diagrams (ASCII and Mermaid)
- ✅ Component architecture overview
- ✅ Security architecture design
- ✅ Service layer architecture
- ✅ Data flow diagrams
- ✅ SwiftData implementation patterns
- ✅ Actor isolation patterns
- ✅ Encryption strategy

### Available Diagram Files
- ✅ `docs/macos-architecture.md` - Complete architecture document
- ✅ `docs/entity-diagrams.md` - Detailed ER diagrams with Mermaid
- ✅ `docs/component-diagrams.md` - Component interaction diagrams
- ✅ `docs/encryption-analysis.md` - Encryption strategy analysis
- ✅ `docs/security-framework.md` - Security implementation details

## Conclusion

The macOS WealthWise architecture provides a solid foundation for secure, performant personal finance management while maintaining simplicity and user privacy. The modular design enables incremental development and future enhancements while ensuring data security and user experience remain paramount.

### Key Architectural Strengths
1. **Local-First Design**: Complete data ownership with optional cloud backup
2. **Security-First Approach**: AES-256-GCM encryption with Keychain integration
3. **Modern Swift Stack**: SwiftUI + SwiftData + CryptoKit + Actor isolation
4. **Cross-Border Support**: Multi-currency, multi-jurisdiction asset management
5. **Comprehensive Tax Support**: STCG, LTCG, TDS tracking for Indian tax system
6. **Goal-Oriented**: Sophisticated goal tracking with milestone management
7. **Type-Safe**: Leverages Swift's type system for compile-time safety
8. **Testable**: Protocol-oriented design with dependency injection
9. **Localized**: Multi-language support (English, Hindi, Tamil)
10. **Privacy-Focused**: No external tracking, minimal data collection

### Architecture Compliance
- ✅ Follows Apple's Human Interface Guidelines
- ✅ Uses platform-native frameworks (SwiftUI, SwiftData, CryptoKit)
- ✅ Implements proper actor isolation for Swift 6 concurrency
- ✅ Supports iOS 18.6+ and macOS 15.6+ with enhanced features for 26.0+
- ✅ Glass effect integration with version detection
- ✅ Accessibility support through VoiceOver and dynamic type