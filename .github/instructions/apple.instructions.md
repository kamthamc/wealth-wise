---
applyTo: "**/*.swift"
---
# Apple Development Instructions (iOS/macOS)

## Project Structure (Static Reference - Avoid Repeated Lookups)

### Main Xcode Project
- **Location**: `apple/WealthWise/WealthWise.xcodeproj`
- **Scheme**: `WealthWise` (universal iOS/macOS)
- **Test Targets**: `WealthWiseTests`, `WealthWiseUITests`
- **Bundle ID**: `com.wealthwise.app`
- **Deployment**: iOS 18.6+, macOS 15.6+

### Key Directories
```
apple/WealthWise/WealthWise/
├── Models/
│   ├── Asset/                 # CrossBorderAsset, AssetType, TaxResidencyStatus
│   ├── Country/              # Country data models
│   ├── Currency/             # Currency and exchange models
│   ├── Preferences/          # User preference models
│   └── Security/             # Security and authentication models
├── Services/                 # Business logic services
│   ├── Security/             # Security services
│   └── CurrencyService.swift # Currency conversion
├── CoreData/                 # Persistence layer
│   ├── PersistentContainer.swift
│   ├── DataModelMigrations.swift
│   └── AssetTransformers.swift
├── Resources/                # Localization files
│   ├── en.lproj/            # English strings
│   ├── hi.lproj/            # Hindi strings  
│   └── ta.lproj/            # Tamil strings
└── Assets.xcassets/         # Images and colors
```

### MANDATORY Localization Requirements (All Code)
**Every user-facing string MUST be localized - NO exceptions:**

#### 1. String Localization Pattern
```swift
// ✅ CORRECT - Always use NSLocalizedString
Text(NSLocalizedString("transaction_amount", comment: "Transaction amount label"))
Button(NSLocalizedString("save_button", comment: "Save button title")) { }

// ❌ WRONG - Never hardcode strings
Text("Transaction Amount")
Button("Save") { }
```

#### 2. Localizable.strings Structure
```swift
/* Financial Terms */
"transaction_amount" = "Transaction Amount";
"account_balance" = "Account Balance";
"currency_conversion" = "Currency Conversion";

/* Navigation */
"back_button" = "Back";
"next_button" = "Next";
"done_button" = "Done";

/* Errors */
"network_error" = "Network connection failed";
"invalid_input" = "Please enter valid information";
```

#### 3. Number & Currency Formatting
```swift
// Always use locale-aware formatting
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.locale = Locale.current
let formattedAmount = formatter.string(from: NSNumber(value: amount))

// Date formatting
let dateFormatter = DateFormatter()
dateFormatter.dateStyle = .medium
dateFormatter.locale = Locale.current
```

#### 4. RTL Language Support
```swift
// Use leading/trailing instead of left/right
VStack(alignment: .leading) {
    HStack {
        Text("Amount")
        Spacer()
        Text(formattedAmount)
    }
}
```

#### 5. Localization Validation
- Test with RTL languages (Arabic, Hebrew)  
- Verify number formatting in different locales
- Check text truncation in longer languages
- Validate cultural appropriateness

## Overview
Platform-specific instructions for iOS and macOS development within the WealthWise project using Swift 6, SwiftUI, and modern Apple frameworks.

## Development Principles

### Swift 6 & Modern Patterns
- Use strict concurrency checking with actor isolation
- Implement typed throws for better error handling
- Apply async/await patterns consistently
- Use modern SwiftUI features (iOS 18.6+/macOS 15.6+)
- Leverage @Observable for state management
- **CRITICAL**: Avoid default values in @Observable Codable properties - initialize in init()

### MANDATORY Build Validation Workflow
**ALL code changes MUST be validated before commit/PR/issue closure:**

1. **Clean Build**: Always clean build before testing
   ```
   xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise clean
   ```

2. **Full Build Validation**: Test both iOS and macOS targets
   ```
   # macOS build
   xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise -destination "generic/platform=macOS" build
   
   # iOS build  
   xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise -destination "generic/platform=iOS Simulator" build
   ```

3. **Test Execution**: Run unit and UI tests
   ```
   xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise -destination "generic/platform=macOS" test
   ```

4. **Code Quality**: SwiftLint and formatting validation
   ```
   swiftlint --path apple/
   swift-format --recursive apple/ --in-place
   ```

**NEVER commit, create PR, or close issue without successful build validation**

### CRITICAL Swift Concurrency Patterns (Efficiency Reference)
**Common issues and solutions to avoid repeated debugging:**

#### 1. @Observable + Codable Conflicts
```swift
// ❌ WRONG - Default values break Codable synthesis
@Observable
final class Settings: Codable {
    var enabled: Bool = true  // Compilation error
}

// ✅ CORRECT - Initialize in init()
@Observable  
final class Settings: Codable {
    var enabled: Bool
    
    init() {
        enabled = true
    }
}
```

#### 2. Core Data Transformers with Actor Isolation
```swift
// ✅ CORRECT - Use nonisolated and @unchecked Sendable
@objc(DecimalTransformer)
final class DecimalTransformer: NSSecureUnarchiveFromDataTransformer, @unchecked Sendable {
    override class var allowedTopLevelClasses: [AnyClass] {
        return [NSDecimalNumber.self]
    }
    
    nonisolated override func transformedValue(_ value: Any?) -> Any? {
        guard let decimal = value as? Decimal else { return nil }
        return NSDecimalNumber(decimal: decimal)
    }
    
    nonisolated override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let number = value as? NSDecimalNumber else { return nil }
        return number.decimalValue
    }
}
```

#### 3. Generic Type Inference Issues  
```swift
// ❌ Compilation error - generic parameter inference fails
func validateEntity<T>(_ entity: T) -> ValidationResult

// ✅ CORRECT - Add constraint for proper inference
func validateEntity<T: NSManagedObject>(_ entity: T) -> ValidationResult
```

#### 4. Unused Variable Warnings
```swift
// ❌ Unused immutable value warning
let backupURL = getBackupURL()

// ✅ Use underscore for intentionally unused values
let _ = getBackupURL()
```

#### 5. Actor Isolation in Persistence
```swift
// ✅ CORRECT - Singleton with proper isolation
final class PersistentContainer: @unchecked Sendable {
    static let shared = PersistentContainer()
    
    @MainActor
    private(set) lazy var persistentContainer: NSPersistentContainer = {
        // Container setup
    }()
    
    nonisolated func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
}
```

### Localization Requirements (All Strings Must Be Localized)

#### String Localization Pattern
```swift
// ALWAYS use NSLocalizedString for user-facing text
Text(NSLocalizedString("Total Balance", comment: "Main balance display"))

// Use localization keys consistently
private enum LocalizationKeys {
    static let totalBalance = "total_balance"
    static let accountSummary = "account_summary"
}

// Complex formatting with localization
String(format: NSLocalizedString("account_balance_format", comment: "Account balance with currency"), 
       accountName, formattedAmount)
```

#### Currency and Number Localization
```swift
// Use NumberFormatter for financial values
let currencyFormatter = NumberFormatter()
currencyFormatter.numberStyle = .currency
currencyFormatter.locale = Locale.current
currencyFormatter.currencyCode = account.currency

// Cultural number formatting
let percentFormatter = NumberFormatter()
percentFormatter.numberStyle = .percent
percentFormatter.locale = Locale.current
percentFormatter.minimumFractionDigits = 2
```

#### Supported Locales
- **Primary**: English (en) - Base localization
- **Secondary**: Hindi (hi) - Indian market
- **Tertiary**: Tamil (ta) - South Indian market
- **File Structure**: `Resources/{locale}.lproj/Localizable.strings`

### @Observable Codable Models - Critical Pattern
```swift
// WRONG - Default values break Codable with @Observable
@Observable
final class Settings: Codable {
    var enabled: Bool = true  // ❌ Causes compilation error
}

// CORRECT - Initialize in init()
@Observable  
final class Settings: Codable {
    var enabled: Bool  // ✅ No default value
    
    init() {
        enabled = true  // ✅ Set in initializer
    }
}
```

### Security First (Apple Platforms)
- All financial data encrypted with AES-256-GCM using CryptoKit
- Use Keychain Services for credential storage
- Implement biometric authentication with LocalAuthentication
- Apply secure coding practices and input validation
- Never store sensitive data in plain text

### Platform-Native Design
- Follow iOS Human Interface Guidelines and macOS Design Guidelines
- Use platform-specific UI patterns and navigation
- Implement proper accessibility features with VoiceOver
- Support cultural localization for target markets

## Architecture Guidelines

### Core Data Models (Swift/SwiftData)
```swift
// Financial data models with proper SwiftData integration
@Model
final class CrossBorderAsset: Sendable {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbol: String
    var assetType: AssetType
    var primaryCountry: String
    var primaryCurrency: String
    var currentValue: Decimal
    
    init(name: String, symbol: String, assetType: AssetType, 
         primaryCountry: String, primaryCurrency: String, currentValue: Decimal) {
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.assetType = assetType
        self.primaryCountry = primaryCountry
        self.primaryCurrency = primaryCurrency
        self.currentValue = currentValue
    }
}
```

### Service Layer (Actor-based)
```swift
// Protocol-oriented services with actor isolation
@globalActor
final actor FinancialServiceActor {
    static let shared = FinancialServiceActor()
}

@FinancialServiceActor
protocol TransactionService: Sendable {
    func createTransaction(_ transaction: Transaction) async throws
    func fetchTransactions(for account: Account) async throws -> [Transaction]
}
```

### UI Components (SwiftUI)
```swift
// Modern SwiftUI with platform-specific features
@available(iOS 18.6, macOS 15.6, *)
struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    
    var body: some View {
        List(transactions) { transaction in
            TransactionRow(transaction: transaction)
        }
        .listStyle(.insetGrouped)
        #if os(iOS)
        .refreshable {
            await refreshTransactions()
        }
        #endif
    }
}

// Glass effects for latest OS versions only
@available(iOS 26.0, macOS 26.0, *)
extension View {
    func glassEffect() -> some View {
        self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .backgroundStyle(.glass)
    }
}
```

## Testing Framework (Static Reference - Avoid Project Lookups)

### Test Structure
```
WealthWiseTests/
├── TaxResidencyStatusTests.swift      # Tax compliance model tests
├── PerformanceMetricsTests.swift      # Performance tracking tests  
├── CurrencyRiskTests.swift            # Currency risk model tests
├── AssetDataModelsIntegrationTests.swift  # Cross-model integration
├── AssetDataModelsSystemTests.swift   # System-wide integration
└── CountryGeographySystemTests.swift  # Geography system tests
```

### Test Execution Commands (Static Reference)
```bash
# Build project
xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise -destination "generic/platform=macOS" build

# Run tests
xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise -destination "generic/platform=macOS" test

# Clean build
xcodebuild -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise clean
```

### VS Code Tasks (Available via run_task)
- `shell: Build - WealthWise (macOS)` - Build for macOS
- `shell: Build - WealthWise (iOS Simulator)` - Build for iOS
- `shell: Test - WealthWise (macOS)` - Run test suite
- `shell: Clean - WealthWise` - Clean build artifacts
- `shell: SwiftLint - Fix Issues` - Auto-fix linting issues
- `shell: Swift Format - All Files` - Format Swift code

### Test Pattern Requirements
```swift
// Unit test class structure
final class ModelNameTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    func testModelInitialization() { }
    
    // MARK: - Computed Properties Tests  
    func testComputedProperties() { }
    
    // MARK: - Business Logic Tests
    func testBusinessLogicMethods() { }
    
    // MARK: - Codable Tests
    func testModelCodable() throws { }
    
    // MARK: - Hashable/Equatable Tests
    func testHashableEquatable() { }
    
    // MARK: - Performance Tests
    func testModelPerformance() {
        measure { /* test code */ }
    }
}
```

## MCP Tools for Apple Development

### GitHub Integration
- `mcp_github_list_issues` - List open issues for project planning
- `mcp_github_get_issue` - Get detailed issue information
- `mcp_github_create_issue` - Create new issues from feature requests
- `mcp_github_update_issue` - Update issue status and progress
- `mcp_github_add_issue_comment` - Add progress comments
- `mcp_github_list_commits` - Review recent changes
- `activate_github_pull_request_management` - Manage PRs

### Code Analysis
- `semantic_search` - Find related Swift code patterns
- `grep_search` - Search for specific Swift/SwiftUI patterns
- `list_code_usages` - Understand Swift protocol/class dependencies
- `get_errors` - Check Swift compilation errors

## VSCode Tasks for Apple Development

Use these tasks from `.vscode/tasks.json`:

### Build Tasks
- **`swift-build-ios`** - Build iOS target
- **`swift-build-macos`** - Build macOS target
- **`swift-clean`** - Clean build artifacts

### Testing Tasks
- **`swift-test`** - Run unit tests
- **`swift-test-coverage`** - Run tests with coverage
- **`swift-ui-test`** - Run UI automation tests

### Code Quality
- **`swift-lint`** - Run SwiftLint analysis
- **`swift-format`** - Auto-format Swift code
- **`security-scan`** - Run security analysis

### Development Workflow
- **`xcode-open`** - Open project in Xcode
- **`git-prepare-commit`** - Stage and prepare commit
- **`build-and-test`** - Full build and test cycle

## Apple-Specific Implementation Guidelines

### iOS-Specific Features
- Use UIKit integration where SwiftUI lacks features
- Implement proper background task handling
- Support universal links and app shortcuts
- Use iOS-specific authentication methods

### macOS-Specific Features
- Implement proper menu bar integration
- Support keyboard shortcuts and menu items
- Use macOS-specific window management
- Implement proper document-based architecture if needed

### Security Implementation (Apple)
```swift
// AES-256-GCM encryption for sensitive data
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

### Performance Guidelines (Apple)
- Use weak references to prevent retain cycles
- Implement proper image caching for transaction receipts
- Use lazy initialization for expensive resources
- Monitor memory usage with Instruments

### Testing Requirements (Apple)
```swift
@available(iOS 18.6, macOS 15.6, *)
final class TransactionServiceTests: XCTestCase {
    var service: TransactionService!
    var mockContext: ModelContext!
    
    override func setUp() async throws {
        mockContext = ModelContext(ModelContainer.preview)
        service = TransactionServiceImplementation(context: mockContext)
    }
    
    func testCreateTransaction_ValidData_Success() async throws {
        // Test implementation
    }
}
```

## Code Generation Preferences (Swift)

### Naming Conventions
- Use descriptive names following Swift conventions (camelCase)
- Protocol names should describe capability (e.g., `TransactionProcessing`)
- Use meaningful abbreviations sparingly

### Error Handling (Swift 6)
```swift
// Use typed throws for better error handling
enum TransactionError: Error, LocalizedError {
    case invalidAmount
    case insufficientFunds
    case networkFailure
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "The transaction amount is invalid"
        case .insufficientFunds:
            return "Insufficient funds for this transaction"
        case .networkFailure:
            return "Network connection failed"
        }
    }
}

func processTransaction(_ transaction: Transaction) async throws(TransactionError) {
    // Implementation with specific error types
}
```

### Documentation Standards
- Add documentation comments for public APIs
- Explain complex business logic
- Include code examples for non-trivial functions
- Document security considerations

This instruction set ensures consistent, secure, and high-quality Apple platform development while leveraging modern Swift 6 features and MCP GitHub integration tools.