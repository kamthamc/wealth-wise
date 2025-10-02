# WealthWise Architecture Documentation

## Overview

This directory contains comprehensive architecture documentation for WealthWise, a cross-platform personal finance management application with a focus on security, privacy, and cross-border asset management.

## Quick Links

### Core Architecture Documents
- **[macOS Architecture](./macos-architecture.md)** - Complete macOS/iOS architecture overview
- **[Entity Diagrams](./entity-diagrams.md)** - Entity-relationship diagrams with Mermaid
- **[Component Diagrams](./component-diagrams.md)** - Component interaction and system architecture
- **[Technical Architecture](./technical-architecture.md)** - High-level technical overview

### Specialized Documentation
- **[Security Framework](./security-framework.md)** - Security implementation details
- **[Encryption Analysis](./encryption-analysis.md)** - Encryption strategy and analysis
- **[Cross-Border Asset Management](./cross-border-asset-management.md)** - International asset tracking
- **[Multi-Country Tax Module](./multi-country-tax-module.md)** - Tax calculation and reporting

### Implementation Guides
- **[Cross-Platform Localization](./cross-platform-localization-architecture.md)** - Localization infrastructure
- **[Goals, Tax & Salary Tracking](./goals-tax-salary-tracking.md)** - Financial goal management
- **[Development Setup](./development-setup.md)** - Getting started with development

## Architecture Highlights

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    WealthWise Platform                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Apple      │  │   Android    │  │   Windows    │     │
│  │  (Swift/     │  │  (Kotlin/    │  │   (.NET/     │     │
│  │   SwiftUI)   │  │   Compose)   │  │    WPF)      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                 │                  │              │
│         └─────────────────┴──────────────────┘              │
│                           │                                  │
│                           ▼                                  │
│              ┌─────────────────────────┐                    │
│              │   Shared Business Logic │                    │
│              │  (Platform-Specific)    │                    │
│              └─────────────────────────┘                    │
│                           │                                  │
│              ┌────────────┴────────────┐                    │
│              ▼                         ▼                     │
│    ┌──────────────────┐    ┌──────────────────┐           │
│    │  Local Encrypted │    │  Optional Cloud  │           │
│    │     Storage      │    │      Backup      │           │
│    └──────────────────┘    └──────────────────┘           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

#### 1. Security-First Design
- **AES-256-GCM Encryption** - All sensitive data encrypted at rest
- **Biometric Authentication** - Touch ID/Face ID/Windows Hello
- **Keychain Integration** - Secure key storage using platform APIs
- **Zero-Knowledge Architecture** - Complete data ownership

#### 2. Cross-Border Asset Management
- **Multi-Currency Support** - 150+ currencies with real-time conversion
- **International Asset Tracking** - Stocks, bonds, real estate across countries
- **Tax Compliance** - Multi-jurisdiction tax tracking (US FATCA, OECD CRS, India LRS)
- **Regulatory Compliance** - KYC, source of funds, audit trails

#### 3. Modern Technology Stack
- **Apple**: Swift 6, SwiftUI, SwiftData, CryptoKit, Combine
- **Android**: Kotlin, Jetpack Compose, Room, Kotlin Coroutines
- **Windows**: C# .NET, WPF/WinUI 3, Entity Framework, DPAPI
- **Cross-Platform**: Protocol-oriented design, dependency injection

#### 4. Local-First Architecture
- **Offline-First** - Complete functionality without internet
- **Optional Sync** - CloudKit/Firebase/OneDrive integration
- **Privacy-Focused** - No external tracking or analytics
- **Data Portability** - Export to standard formats (CSV, JSON, PDF)

## Core Data Models

### Implemented Entities

#### 1. Transaction (@Model - SwiftData)
Comprehensive financial transaction tracking with tax implications.

**Key Properties:**
- Amount, currency, multi-currency support
- 50+ transaction categories
- Tax category tracking (STCG, LTCG, TDS)
- Recurring transaction patterns
- Cross-border transaction support
- Attachment support (receipts, invoices)

**Relationships:**
- `linkedGoal` - Optional goal association
- `attachments` - Transaction attachments

#### 2. Goal (@Model - SwiftData)
Sophisticated financial goal tracking with milestone management.

**Key Properties:**
- Target amount and timeline
- Progress tracking with snapshots
- Milestone achievements
- Contribution history
- Risk tolerance and expected returns
- Projected completion dates

**Relationships:**
- `linkedTransactions` - Associated transactions
- Embedded: `milestones`, `contributions`, `progressHistory`

#### 3. CrossBorderAsset (Struct - Codable)
International asset tracking with regulatory compliance.

**Key Properties:**
- Domicile and owner country codes
- Multi-currency valuation
- Tax jurisdiction tracking
- Compliance requirements
- Performance history
- ESG scores and risk ratings

**Supporting Structures:**
- `PerformanceSnapshot` - Historical performance
- `IncomePayment` - Dividend/interest tracking
- `TaxResidencyStatus` - Tax jurisdiction status

## Architecture Patterns

### SwiftData Implementation

```swift
// Transaction entity with relationships
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Transaction {
    @Attribute(.unique) public var id: UUID
    public var amount: Decimal
    public var currency: String
    
    // Relationships
    @Relationship(deleteRule: .nullify) 
    public var linkedGoal: Goal?
    
    @Relationship(deleteRule: .cascade) 
    public var attachments: [TransactionAttachment]?
}
```

### Actor Isolation for Swift 6

```swift
// Service-level actors for thread-safe operations
@globalActor
final actor FinancialServiceActor {
    static let shared = FinancialServiceActor()
}

@FinancialServiceActor
protocol TransactionService: Sendable {
    func createTransaction(_ transaction: Transaction) async throws
}
```

### Encryption Pattern

```swift
// CryptoKit-based encryption
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
```

## Data Flow Architecture

### Transaction Creation Flow

```
User Input (SwiftUI View)
    ↓
ViewModel Validation
    ↓
Business Logic (Manager)
    ↓
Service Layer
    ├─ Currency Conversion
    ├─ Encryption
    └─ Tax Calculation
    ↓
SwiftData Persistence
    ↓
UI Update (@Query)
```

### Goal Progress Update

```
Goal.updateProgress(amount)
    ↓
Calculate Progress %
    ↓
Create Progress Snapshot
    ↓
Check Milestones
    ↓
Check Completion
    ↓
SwiftData Auto-Save
    ↓
UI Refresh
```

## Security Architecture

### Authentication Flow

```
App Launch
    ↓
Biometric Available?
    ├─ Yes → Touch ID/Face ID
    │        ├─ Success → Unlock
    │        └─ Failure → Password
    └─ No → Master Password
             ├─ Success → Unlock
             └─ Failure → Retry
```

### Encryption Strategy

1. **Master Key Generation** - Derived from user authentication
2. **Key Storage** - Keychain with device-only access
3. **Field-Level Encryption** - AES-256-GCM for sensitive data
4. **Key Rotation** - Annual rotation with backward compatibility

### Data Classification

| Level | Data Type | Protection |
|-------|-----------|------------|
| **PUBLIC** | Asset types, currencies, categories | None |
| **CONFIDENTIAL** | Asset values, transaction amounts | App-level access control |
| **SECRET** | Account numbers, tax IDs, notes | AES-256-GCM + Keychain |

## Component Architecture

### Presentation Layer
- SwiftUI views with platform-native UI
- ViewModels with @Observable protocol
- Navigation management
- State restoration

### Business Logic Layer
- Asset managers
- Transaction processors
- Portfolio calculators
- Tax calculation engines

### Service Layer
- Data service (SwiftData CRUD)
- Security service (encryption, authentication)
- Currency service (conversion, rates)
- Market data service (price feeds)

### Data Layer
- SwiftData @Model entities
- Keychain Services
- File system (attachments, exports)
- CloudKit sync (optional)

## Implementation Status

### Phase 1: Foundation ✅
- ✅ Core data models (Transaction, Goal, CrossBorderAsset)
- ✅ SwiftData integration
- ✅ Multi-currency infrastructure
- ✅ Tax calculation framework
- ✅ Localization (English, Hindi, Tamil)

### Phase 2: Services (In Progress)
- ⏳ Encryption service implementation
- ⏳ Authentication flow
- ⏳ CloudKit sync
- ⏳ Import/export services
- ⏳ Market data integration

### Phase 3: Business Logic (Planned)
- ⏳ Asset management service
- ⏳ Portfolio calculation engine
- ⏳ Complete tax calculation
- ⏳ Reporting engine
- ⏳ Goal automation

### Phase 4: UI & Polish (Planned)
- ⏳ Complete dashboard
- ⏳ Transaction management
- ⏳ Goal tracking UI
- ⏳ Portfolio views
- ⏳ Reports and analytics

## Technology Compliance

### Platform Requirements
- **iOS**: 18.6+ (enhanced features in 26.0+)
- **macOS**: 15.6+ (enhanced features in 26.0+)
- **Android**: API 29+ (Android 10+)
- **Windows**: Windows 10 1809+ (.NET 8.0)

### Frameworks
- **Swift**: 5.9+ (Swift 6 concurrency)
- **Kotlin**: 1.9+
- **C#**: 12.0 (.NET 8.0)

### Design Guidelines
- ✅ Apple Human Interface Guidelines
- ✅ Material Design 3
- ✅ Windows Fluent Design System

## Testing Strategy

### Unit Testing
- Business logic with mocked dependencies
- Calculation engine accuracy
- Encryption/decryption validation
- Data model constraints

### Integration Testing
- SwiftData operations
- Security service integration
- Multi-currency conversion
- Import/export workflows

### UI Testing
- Critical user flows
- Navigation testing
- Accessibility compliance
- Performance benchmarks

## Documentation Standards

### Code Documentation
- Swift: DocC comments for public APIs
- Kotlin: KDoc comments
- C#: XML documentation comments

### Architecture Documentation
- Updated with each major feature
- Diagrams maintained in sync with code
- Examples include real implementation

## Related Resources

### External Documentation
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CryptoKit Documentation](https://developer.apple.com/documentation/cryptokit)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

### Internal Links
- [Project Breakdown](./project-breakdown-tree.md)
- [Feature Specification](./feature-specification.md)
- [Development Setup](./development-setup.md)

## Contributing

When updating architecture documentation:

1. **Keep diagrams in sync** - Update both ASCII and Mermaid versions
2. **Match implementation** - Verify diagrams reflect actual code
3. **Add examples** - Include code snippets from real implementation
4. **Update status** - Keep implementation status current
5. **Test diagrams** - Ensure Mermaid syntax is valid

## Questions?

For architecture questions or clarifications:
- Review detailed documentation in linked files
- Check Swift model implementations in `apple/WealthWise/WealthWise/Models/`
- See test files for usage examples
- Open a GitHub issue for architectural discussions

---

**Last Updated**: 2024-10-02  
**Status**: Complete - All acceptance criteria met  
**Issue**: #3 - Architecture document & entity diagrams
