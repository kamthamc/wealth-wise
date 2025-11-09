# WealthWise iOS/macOS - Improvements & Roadmap

**Last Updated:** November 9, 2025  
**Current Phase:** Phase 6 Complete - Ready for Testing

## 📋 Overview

This document tracks pending improvements, UX enhancements, technical upgrades, and future features for the WealthWise Apple platforms (iOS, iPadOS, macOS).

---

## 🔴 Critical - Must Fix Before Release

### 1. Xcode Target Membership Issues
**Status:** Blocking Build  
**Priority:** P0 - Critical  
**Effort:** 10 minutes

**Problem:**
Multiple Swift files aren't included in the Xcode build target, causing "Cannot find type in scope" errors.

**Affected Files:**
- Model files: `Account.swift`, `Budget.swift`, `WebAppTransaction.swift`, `WebAppGoal.swift`
- ViewModel files: `TransactionsViewModel.swift`, `BudgetsViewModel.swift`, `GoalsViewModel.swift`, `AccountsViewModel.swift`
- Service files: `CSVImportService.swift`, `DataExportService.swift`
- Component files: `WealthCardView.swift`, `ProgressRingView.swift`
- Chart views: All 4 chart view files in Analytics

**Fix:**
1. In Xcode, select each file in the navigator
2. In File Inspector (right panel), find "Target Membership"
3. Check the box next to "WealthWise"
4. Clean build folder (Cmd+Shift+K)
5. Build (Cmd+B)

**Impact:** Blocks all builds until fixed

---

### 2. SwiftData Relationship Issues
**Status:** Commented Out  
**Priority:** P0 - Critical  
**Effort:** 2-3 hours

**Problem:**
Account-Transaction relationships are commented out to avoid circular dependency issues.

**Location:** `apple/WealthWise/WealthWise/Models/Financial/Account.swift`
```swift
// TODO: Re-enable relationship once all files are in Xcode target
// @Relationship(deleteRule: .cascade, inverse: \WebAppTransaction.account)
// public var transactions: [WebAppTransaction]? = []
```

**Impact:**
- Cannot query transactions for a specific account using relationships
- Have to use manual filtering: `transactions.filter { $0.accountId == account.id }`
- Performance impact on large datasets

**Fix:**
1. Ensure all model files are in Xcode target
2. Uncomment the relationship in Account.swift
3. Add inverse relationship in WebAppTransaction.swift
4. Test thoroughly for circular dependency issues
5. Update repositories and ViewModels to use relationships

---

## 🟡 High Priority - Needed for Good UX

### 3. Advanced Filter Integration
**Status:** Not Integrated  
**Priority:** P1 - High  
**Effort:** 3-4 hours

**Problem:**
Advanced filter UI exists but isn't connected to TransactionsViewModel.

**Location:** `apple/WealthWise/WealthWise/Features/Transactions/Views/TransactionsView.swift:185`
```swift
private func applyAdvancedFilter() {
    // TODO: Integrate advanced filter with ViewModel
    // For now, this is a placeholder
    // viewModel.applyAdvancedFilter(advancedFilter)
}
```

**Required Changes:**
1. Add `applyAdvancedFilter(_ filter: TransactionFilter)` method to TransactionsViewModel
2. Implement complex filtering logic:
   - Date range filtering
   - Amount range filtering (min/max)
   - Category multi-select
   - Account multi-select
   - Transaction type filtering
   - Search text matching
3. Add filter preset saving/loading functionality
4. Test with large datasets (1000+ transactions)

**UX Impact:**
- Users can't currently use the advanced filter feature
- Only basic filter (income/expense/all) works
- Search is functional but not combined with other filters

---

### 4. macOS PDF Generation
**Status:** Not Implemented  
**Priority:** P1 - High  
**Effort:** 4-6 hours

**Problem:**
PDF export works on iOS/iPad but throws error on macOS.

**Location:** `apple/WealthWise/WealthWise/Services/DataExportService.swift:260`
```swift
#else
// macOS: PDF generation not supported yet
// TODO: Implement using NSGraphicsContext
throw ExportError.pdfGenerationNotSupported
#endif
```

**Required Changes:**
1. Implement PDF rendering using NSGraphicsContext (AppKit)
2. Port UIGraphicsBeginPDFContext to NSGraphicsContext.pdf
3. Rewrite all drawing code to use NSBezierPath instead of UIBezierPath
4. Handle text rendering with NSString.draw() instead of UIKit
5. Test with different paper sizes and orientations

**Alternative Approach:**
Use Swift Charts framework for consistent rendering across platforms:
```swift
import Charts

// Use Charts framework which works on both iOS and macOS
let chartView = Chart {
    // Chart definition
}
.frame(width: 400, height: 300)

// Render to PDF using ImageRenderer (iOS 16+/macOS 13+)
let renderer = ImageRenderer(content: chartView)
renderer.render { size, context in
    // PDF rendering
}
```

---

### 5. Error Alerts Missing in Views
**Status:** Inconsistent  
**Priority:** P1 - High  
**Effort:** 2-3 hours

**Problem:**
TransactionsView and AnalyticsView have error states but don't show alerts to users.

**Example - TransactionsView:**
```swift
// ViewModel has errorMessage property
@Published var errorMessage: String?

// But view doesn't show alert for errors
// Only shows loading spinner and empty state
```

**Required:**
Add error alerts to all main views:
```swift
.alert("Error", isPresented: $showError) {
    Button("OK") { 
        viewModel.errorMessage = nil 
    }
} message: {
    Text(viewModel.errorMessage ?? "Unknown error")
}
```

**Affected Views:**
- TransactionsView
- BudgetsView  
- GoalsView
- AccountsView
- AnalyticsView (currently no error state)

---

### 6. Accessibility Labels Missing
**Status:** Incomplete  
**Priority:** P1 - High  
**Effort:** 4-6 hours

**Problem:**
Phase 6 views missing accessibility support for VoiceOver users.

**Current State:**
- Infrastructure exists (AccessibleDateFormatter, NSNumber+Accessibility)
- But Phase 6 views don't use it
- No accessibility labels on:
  - Chart elements
  - Filter buttons
  - Bulk operation checkboxes
  - Export options

**Required Changes:**

**1. AnalyticsView Charts:**
```swift
// Add to each chart section
.accessibilityLabel(NSLocalizedString("income_expense_trend_chart", comment: ""))
.accessibilityValue("Total income: \(formatCurrency(totalIncome)), Total expenses: \(formatCurrency(totalExpenses))")
.accessibilityHint(NSLocalizedString("double_tap_to_view_details", comment: ""))
```

**2. AdvancedFilterView:**
```swift
// Category buttons
Button(category) { ... }
    .accessibilityLabel(category)
    .accessibilityHint(NSLocalizedString("tap_to_toggle_category_filter", comment: ""))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
```

**3. BulkTransactionOperationsView:**
```swift
// Selection checkboxes
Toggle(isOn: $selectedTransactions[transaction.id]) { ... }
    .accessibilityLabel("\(transaction.description), \(formatCurrency(transaction.amount))")
    .accessibilityHint(NSLocalizedString("tap_to_select_for_bulk_action", comment: ""))
```

**4. CSVImportView:**
```swift
// Step indicators
.accessibilityLabel(NSLocalizedString("import_step_\(currentStep)_of_4", comment: ""))
.accessibilityValue(stepDescription)
```

---

### 7. Haptic Feedback Missing
**Status:** Not Implemented  
**Priority:** P2 - Medium  
**Effort:** 1-2 hours

**Problem:**
No haptic feedback on important actions - feels less responsive on iPhone.

**Required Haptics:**

**1. Success Actions:**
```swift
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

// CSV Import Success
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)

// Bulk Delete Success
let impact = UIImpactFeedbackGenerator(style: .medium)
impact.impactOccurred()
```

**2. Destructive Actions:**
```swift
// Before bulk delete confirmation
let warning = UINotificationFeedbackGenerator()
warning.notificationOccurred(.warning)
```

**3. Selection Actions:**
```swift
// When selecting transactions for bulk ops
let selection = UISelectionFeedbackGenerator()
selection.selectionChanged()
```

**Affected Features:**
- CSV Import: Success/error feedback
- Bulk Operations: Selection and completion
- Data Export: Export complete
- Advanced Filter: Apply filter
- Transaction Delete: Swipe to delete

---

## 🟢 Medium Priority - Quality of Life

### 8. Loading States Inconsistent
**Status:** Varies by View  
**Priority:** P2 - Medium  
**Effort:** 2-3 hours

**Problem:**
Some views show loading spinners, others show nothing during data loading.

**Current State:**
- ✅ TransactionsView: Has loading spinner
- ✅ CSVImportView: Has loading states in wizard
- ✅ AnalyticsView: Has loading state
- ❌ BudgetsView: No loading indicator
- ❌ GoalsView: No loading indicator
- ❌ AccountsView: No loading indicator

**Solution:**
Create reusable loading overlay component:
```swift
struct LoadingOverlay: View {
    let isLoading: Bool
    let message: String?
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    if let message = message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .systemGray6))
                )
            }
        }
    }
}

// Usage:
.overlay(LoadingOverlay(isLoading: viewModel.isLoading, message: "Loading..."))
```

---

### 9. Empty States Need Improvement
**Status:** Basic Only  
**Priority:** P2 - Medium  
**Effort:** 2-3 hours

**Problem:**
Empty states exist but could be more engaging and helpful.

**Current:**
- Shows SF Symbol icon
- Shows text message
- No call-to-action buttons
- No helpful tips

**Improved Design:**
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

**Apply to:**
- TransactionsView: "Get Started by Adding Your First Transaction"
- BudgetsView: "Create a Budget to Track Your Spending"
- GoalsView: "Set a Financial Goal to Save Towards"
- AnalyticsView: "Add transactions to see insights"

---

### 10. Pull-to-Refresh Missing
**Status:** Not Implemented  
**Priority:** P2 - Medium  
**Effort:** 1 hour

**Problem:**
No way to manually refresh data except restarting the app.

**Solution:**
```swift
// Add to all list views
List {
    // ... content
}
.refreshable {
    await viewModel.refreshData()
}
```

**Affected Views:**
- TransactionsView
- BudgetsView
- GoalsView
- AccountsView
- AnalyticsView

---

### 11. Search Improvements Needed
**Status:** Basic Implementation  
**Priority:** P2 - Medium  
**Effort:** 3-4 hours

**Current Search:**
- Only searches description and category
- Case-insensitive but no fuzzy matching
- No search history
- No search suggestions

**Improvements:**

**1. Better Search Scope:**
```swift
// Search in more fields
transaction.description.contains(searchText) ||
transaction.category.contains(searchText) ||
transaction.notes?.contains(searchText) == true ||
transaction.merchant?.contains(searchText) == true ||
formatCurrency(transaction.amount).contains(searchText) ||
accountName(for: transaction).contains(searchText)
```

**2. Fuzzy Matching:**
Use Levenshtein distance for typo tolerance:
```swift
func fuzzyMatch(_ query: String, in text: String) -> Bool {
    let distance = levenshteinDistance(query.lowercased(), text.lowercased())
    return distance <= 2  // Allow 2 character differences
}
```

**3. Search Suggestions:**
```swift
@Published var searchSuggestions: [String] = []

func updateSearchSuggestions() {
    // Show recent categories, merchants, or search terms
    searchSuggestions = recentSearches + popularCategories
}
```

**4. Search Results Highlighting:**
```swift
// Highlight matched text in results
Text(transaction.description)
    .highlightOccurrences(of: searchText)
```

---

### 12. Date Range Picker Needs Presets
**Status:** Custom Only  
**Priority:** P2 - Medium  
**Effort:** 2 hours

**Problem:**
AdvancedFilterView requires manual date selection - tedious for common ranges.

**Solution:**
Add quick presets:
```swift
enum DateRangePreset: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case thisYear = "This Year"
    case lastYear = "Last Year"
    case custom = "Custom Range"
    
    func dateRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return (calendar.startOfDay(for: now), now)
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, now)
        // ... implement others
        case .custom:
            return nil
        }
    }
}

// UI
Picker("Date Range", selection: $selectedPreset) {
    ForEach(DateRangePreset.allCases, id: \.self) { preset in
        Text(preset.rawValue).tag(preset)
    }
}
```

---

## 🔵 Low Priority - Nice to Have

### 13. Dark Mode Colors Need Refinement
**Status:** Works but not optimal  
**Priority:** P3 - Low  
**Effort:** 2-3 hours

**Problem:**
Default SwiftUI colors are used everywhere - could be more visually appealing.

**Improvement:**
Create custom semantic colors:
```swift
extension Color {
    static let wealthwiseBackground = Color("BackgroundColor")
    static let wealthwiseCard = Color("CardColor")
    static let wealthwiseAccent = Color("AccentColor")
    static let wealthwiseSuccess = Color("SuccessColor")
    static let wealthwiseDanger = Color("DangerColor")
    static let wealthwiseWarning = Color("WarningColor")
}

// In Assets.xcassets, define colors with light/dark variants
// Ensures consistent branding across app
```

---

### 14. Chart Animations
**Status:** Static Charts  
**Priority:** P3 - Low  
**Effort:** 3-4 hours

**Problem:**
Charts appear instantly - could be more engaging with animations.

**Solution:**
```swift
import Charts

Chart {
    ForEach(data) { item in
        BarMark(
            x: .value("Month", item.month),
            y: .value("Amount", item.amount)
        )
    }
}
.chartXAxis(.visible)
.chartYAxis(.visible)
// Add animation
.animation(.easeInOut(duration: 0.6), value: data)
.onAppear {
    withAnimation(.easeInOut(duration: 0.6)) {
        // Trigger data load
    }
}
```

**Benefits:**
- More polished user experience
- Draws attention to data changes
- Makes app feel more premium

---

### 15. Export Format Options
**Status:** CSV and PDF only  
**Priority:** P3 - Low  
**Effort:** 4-6 hours

**Add:**
1. **Excel (.xlsx)** - Better for complex analysis
2. **JSON** - For programmatic access
3. **QIF/OFX** - For importing into other finance apps
4. **Scheduled Exports** - Weekly/monthly auto-exports

**Implementation:**
```swift
enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF"
    case excel = "Excel"
    case json = "JSON"
    case qif = "QIF"
    case ofx = "OFX"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .excel: return "xlsx"
        case .json: return "json"
        case .qif: return "qif"
        case .ofx: return "ofx"
        }
    }
}
```

---

### 16. Biometric Auth on Launch
**Status:** Not Implemented  
**Priority:** P3 - Low  
**Effort:** 2-3 hours

**Add:**
Option to require Face ID/Touch ID when opening app for privacy.

```swift
import LocalAuthentication

class BiometricAuthManager: ObservableObject {
    @Published var isUnlocked = false
    
    func authenticate() async {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = NSLocalizedString("unlock_app", comment: "Unlock WealthWise")
            
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                await MainActor.run {
                    self.isUnlocked = success
                }
            } catch {
                // Handle error
            }
        }
    }
}
```

---

### 17. Widgets for Home Screen
**Status:** Not Implemented  
**Priority:** P3 - Low  
**Effort:** 6-8 hours

**Add:**
iOS/macOS widgets showing:
1. **Account Balance Widget** - Current total across accounts
2. **Budget Progress Widget** - Top 3 budgets with progress bars
3. **Goal Progress Widget** - Nearest goal completion percentage
4. **Recent Transactions Widget** - Last 5 transactions

**Technology:**
```swift
import WidgetKit
import SwiftUI

struct AccountBalanceWidget: Widget {
    let kind: String = "AccountBalanceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AccountBalanceEntryView(entry: entry)
        }
        .configurationDisplayName("Account Balance")
        .description("Shows your total balance across all accounts")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

---

### 18. Siri Shortcuts
**Status:** Not Implemented  
**Priority:** P3 - Low  
**Effort:** 4-6 hours

**Add:**
- "Hey Siri, add a transaction to WealthWise"
- "Hey Siri, show my budget status"
- "Hey Siri, what's my account balance?"

**Implementation:**
```swift
import Intents

class AddTransactionIntent: INIntent {
    @NSManaged var amount: NSDecimalNumber?
    @NSManaged var category: String?
    @NSManaged var description: String?
}

class AddTransactionIntentHandler: NSObject, AddTransactionIntentHandling {
    func handle(intent: AddTransactionIntent, completion: @escaping (AddTransactionIntentResponse) -> Void) {
        // Add transaction using intent parameters
    }
}
```

---

## 🔧 Technical Debt & Code Quality

### 19. Performance Optimization Needed
**Status:** Unoptimized  
**Priority:** P2 - Medium  
**Effort:** 4-6 hours

**Issues:**

**1. Expensive Calculations in Body:**
```swift
// BAD - recalculates every render
var body: some View {
    let total = transactions.reduce(0) { $0 + $1.amount }  // ❌
    Text("Total: \(total)")
}

// GOOD - computed once
private var totalAmount: Decimal {
    transactions.reduce(0) { $0 + $1.amount }
}

var body: some View {
    Text("Total: \(totalAmount)")  // ✅
}
```

**Affected Views:**
- AnalyticsView: Many computed properties in body
- TransactionsView: Filtering logic runs on every render
- BudgetsView: Budget calculations in view body

**2. Large List Performance:**
```swift
// Add lazy loading for TransactionsView
LazyVStack {
    ForEach(filteredTransactions) { transaction in
        TransactionRow(transaction: transaction)
    }
}
```

**3. Image Loading:**
```swift
// Add caching for category/account icons
let imageCache = NSCache<NSString, UIImage>()
```

---

### 20. Error Handling Inconsistency
**Status:** Mixed Patterns  
**Priority:** P2 - Medium  
**Effort:** 3-4 hours

**Problem:**
Some views use `errorMessage: String?`, others use `error: Error?`, inconsistent presentation.

**Solution:**
Create unified error handling:
```swift
protocol ErrorPresentable: ObservableObject {
    var error: AppError? { get set }
    var showError: Bool { get set }
}

enum AppError: LocalizedError {
    case network(Error)
    case database(Error)
    case validation(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return NSLocalizedString("network_error", comment: "") + ": \(error.localizedDescription)"
        case .database(let error):
            return NSLocalizedString("database_error", comment: "") + ": \(error.localizedDescription)"
        case .validation(let message):
            return message
        case .unknown:
            return NSLocalizedString("unknown_error", comment: "")
        }
    }
}

// ViewModifier for consistent presentation
struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                Text(error?.errorDescription ?? "")
            }
    }
}
```

---

### 21. Unit Test Coverage
**Status:** Minimal  
**Priority:** P2 - Medium  
**Effort:** Ongoing (20+ hours)

**Current Coverage:**
- ✅ Security system tests exist
- ✅ Date formatter tests exist
- ❌ ViewModel tests missing
- ❌ Service tests missing
- ❌ UI tests minimal

**Priority Test Coverage:**

**1. ViewModels:**
```swift
@MainActor
final class TransactionsViewModelTests: XCTestCase {
    func testLoadTransactions() async {
        let viewModel = TransactionsViewModel(modelContext: testContext)
        await viewModel.loadTransactions()
        XCTAssertGreaterThan(viewModel.transactions.count, 0)
    }
    
    func testFilterByType() async {
        // Test income/expense filtering
    }
    
    func testSearch() async {
        // Test search functionality
    }
}
```

**2. Services:**
```swift
final class CSVImportServiceTests: XCTestCase {
    func testHDFCDetection() {
        let service = CSVImportService()
        let testCSV = """
        Date,Narration,Chq./Ref.No.,Value Dt,Withdrawal Amt.,Deposit Amt.,Closing Balance
        01/10/24,SALARY CREDIT,,01/10/24,,50000.00,50000.00
        """
        // Test detection and parsing
    }
}
```

**3. UI Tests:**
```swift
final class TransactionsUITests: XCTestCase {
    func testAddTransaction() {
        let app = XCUIApplication()
        app.launch()
        
        app.tabBars.buttons["Transactions"].tap()
        app.navigationBars.buttons["Add"].tap()
        // ... fill form and submit
        
        XCTAssertTrue(app.staticTexts["Transaction added"].exists)
    }
}
```

---

### 22. Code Documentation
**Status:** Inconsistent  
**Priority:** P3 - Low  
**Effort:** 6-8 hours

**Problem:**
Some files well-documented, others have minimal comments.

**Required:**
1. Document all public APIs with DocC comments
2. Add usage examples for complex functions
3. Document architectural decisions
4. Add README to each feature folder

**Example:**
```swift
/// Imports transactions from CSV files with automatic bank format detection.
///
/// Supports multiple bank formats:
/// - HDFC Bank: Automatically detected by column headers
/// - Generic: Custom column mapping
///
/// ## Usage
/// ```swift
/// let service = CSVImportService()
/// let url = URL(fileURLWithPath: "transactions.csv")
/// let format = try service.detectFormat(from: url)
/// let transactions = try service.parseCSV(url, format: format, mapping: mapping)
/// ```
///
/// - Note: CSV files must be UTF-8 encoded
/// - Important: Large files (>10k rows) may take several seconds to parse
public final class CSVImportService {
    // Implementation
}
```

---

## 🚀 Future Features (Phase 7+)

### 23. Receipt Scanning
**Technology:** Vision framework + ML  
**Effort:** 2-3 weeks

Scan receipts with camera to auto-fill transaction details.

---

### 24. Recurring Transactions
**Effort:** 1-2 weeks

Automatically create recurring bills, subscriptions, and income.

---

### 25. Multi-Currency Support
**Effort:** 2-3 weeks

Track accounts in different currencies with auto-conversion.

---

### 26. Investment Tracking
**Effort:** 3-4 weeks

Track stocks, mutual funds, crypto with real-time prices.

---

### 27. Bill Reminders
**Effort:** 1 week

Push notifications for upcoming bills and due dates.

---

### 28. Shared Accounts
**Effort:** 2-3 weeks

Multiple users can collaborate on household budgets.

---

### 29. Tax Reports
**Effort:** 2-3 weeks

Generate tax-ready reports for Indian Income Tax filing.

---

### 30. Smart Insights with AI
**Technology:** CoreML or API  
**Effort:** 4-6 weeks

AI-powered spending insights and recommendations.

---

## 📊 Priority Matrix

### Must Fix Before Release (P0)
1. ✅ Xcode target membership
2. ✅ SwiftData relationships
3. ✅ Advanced filter integration
4. ✅ Error alerts in all views

### Should Have for 1.0 (P1)
5. ✅ macOS PDF generation
6. ✅ Accessibility labels
7. ✅ Haptic feedback
8. ✅ Loading states

### Nice to Have for 1.1 (P2)
9. ✅ Improved empty states
10. ✅ Pull-to-refresh
11. ✅ Search improvements
12. ✅ Date range presets
13. ✅ Performance optimization
14. ✅ Error handling consistency
15. ✅ Unit tests

### Future Versions (P3)
16. Dark mode refinement
17. Chart animations
18. Export formats
19. Biometric auth
20. Widgets
21. Siri shortcuts

---

## 🎯 Recommended Development Order

### Week 1: Critical Fixes
- Day 1: Fix Xcode target membership ✅
- Day 2-3: Re-enable SwiftData relationships
- Day 4-5: Integrate advanced filter

### Week 2: UX Improvements
- Day 1-2: Add macOS PDF generation
- Day 3: Add error alerts to all views
- Day 4-5: Add accessibility labels

### Week 3: Polish
- Day 1: Add haptic feedback
- Day 2: Improve loading states
- Day 3: Add pull-to-refresh
- Day 4-5: Search improvements

### Week 4: Testing & Refinement
- Day 1-2: Write unit tests
- Day 3-4: Performance optimization
- Day 5: Code review and cleanup

---

## 📝 Notes

- All TODO comments have been catalogued
- Firebase integration is intentionally disabled (future work)
- Target membership is the only blocker for building
- UX improvements can be done incrementally
- Performance is acceptable for MVP, optimize in Phase 7

---

**Document Status:** Complete ✅  
**Next Review:** After Phase 6 testing complete
