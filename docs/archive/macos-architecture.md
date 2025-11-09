# macOS WealthWise Architecture

## Overview

WealthWise macOS is a native SwiftUI application designed for comprehensive personal finance management with local-first, privacy-focused architecture. The application provides secure asset tracking, portfolio management, and financial insights### Technology Stack

### Core Technologies
- **UI Framework**: SwiftUI with AppKit integration
- **Visual Effects**: Glass effects for macOS 15+ and iOS 18+ (enhanced for 26+)
- **Data Persistence**: SwiftData with CloudKit sync (optional)
- **Authentication**: LocalAuthentication framework
- **Encryption**: CryptoKit for AES-256 encryption
- **Networking**: URLSession for market data (optional)
- **Testing**: XCTest with SwiftUI testing utilitiesintaining complete data ownership through local encrypted storage.

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
- **Application-Level Encryption**: Sensitive fields encrypted before SwiftData storage
- **Key Management**: Master key derived from authentication, stored in Keychain
- **Key Rotation**: Periodic key rotation with backward compatibility
- **Backup Encryption**: iCloud backups encrypted with separate key

### 3. Data Classification
- **Public**: Asset types, currencies, non-sensitive metadata
- **Confidential**: Asset values, portfolio performance, calculated metrics  
- **Secret**: Account numbers, personal notes, transaction references

## Entity-Relationship Diagram

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Portfolio │────▶│   Holding   │◀────│    Asset    │
│             │     │             │     │             │
│ - id        │     │ - id        │     │ - id        │
│ - name      │     │ - quantity  │     │ - name      │
│ - created   │     │ - avgCost   │     │ - type      │
└─────────────┘     │ - currentVal│     │ - value     │
        │           └─────────────┘     │ - purchase  │
        │                  │            └─────────────┘
        ▼                  ▼                    │
┌─────────────┐     ┌─────────────┐           │
│ Transaction │     │   Valuation │           │
│             │     │             │           │
│ - id        │     │ - id        │           │
│ - date      │     │ - date      │           │
│ - type      │     │ - price     │           │
│ - amount    │     │ - source    │           │
│ - reference │     └─────────────┘           │
└─────────────┘                               │
        ▲                                     │
        └─────────────────────────────────────┘
```

## Component Interaction Diagram

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   SwiftUI   │───▶│ ViewModel   │───▶│   Manager   │
│    View     │    │             │    │  (Business) │
└─────────────┘    └─────────────┘    └─────────────┘
        │                 │                    │
        ▼                 ▼                    ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Navigation  │    │   Combine   │    │   Service   │
│  Manager    │    │ Publishers  │    │   Layer     │
└─────────────┘    └─────────────┘    └─────────────┘
                           │                    │
                           ▼                    ▼
                   ┌─────────────┐    ┌─────────────┐
                   │   State     │    │  SwiftData  │
                   │ Management  │    │   Store     │
                   └─────────────┘    └─────────────┘
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

## Conclusion

The macOS WealthWise architecture provides a solid foundation for secure, performant personal finance management while maintaining simplicity and user privacy. The modular design enables incremental development and future enhancements while ensuring data security and user experience remain paramount.