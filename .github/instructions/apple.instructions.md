---
applyTo: "**/*.swift"
---
# Apple Development Instructions (iOS/macOS)

## Overview
Platform-specific instructions for iOS and macOS development within the WealthWise project using Swift 6, SwiftUI, and modern Apple frameworks.

## Development Principles

### Swift 6 & Modern Patterns
- Use strict concurrency checking with actor isolation
- Implement typed throws for better error handling
- Apply async/await patterns consistently
- Use modern SwiftUI features (iOS 18.6+/macOS 15.6+)
- Leverage @Observable for state management

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
// Financial data models with encryption
@Model
final class Transaction: Sendable {
    @Attribute(.unique) var id: UUID
    @Attribute(.encrypt) var amount: Decimal
    @Attribute(.encrypt) var description: String
    var category: TransactionCategory
    var account: Account
    var date: Date
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