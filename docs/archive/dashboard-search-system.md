# WealthWise Dashboard & Analytics System

## Dashboard Architecture

### 1. Widget-Based Modular Design
```swift
// Dashboard Widget Protocol
protocol DashboardWidget: Identifiable, Codable {
    var id: UUID { get }
    var title: String { get }
    var size: WidgetSize { get set }
    var position: WidgetPosition { get set }
    var isVisible: Bool { get set }
    var refreshInterval: TimeInterval { get }
    var requiresNetworkData: Bool { get }
    
    func createView() -> AnyView
    func updateData() async
    func exportData() -> WidgetData
}

enum WidgetSize: String, CaseIterable {
    case small = "1x1"      // 150x150pt
    case medium = "2x1"     // 320x150pt
    case large = "2x2"      // 320x320pt
    case extraLarge = "4x2" // 680x320pt
}

struct WidgetPosition: Codable {
    var row: Int
    var column: Int
    var span: (width: Int, height: Int)
}
```

### 2. Core Dashboard Widgets

#### Net Worth Widget
```swift
struct NetWorthWidget: DashboardWidget {
    let id = UUID()
    let title = "Net Worth"
    var size: WidgetSize = .large
    var position: WidgetPosition = WidgetPosition(row: 0, column: 0, span: (2, 2))
    var isVisible = true
    let refreshInterval: TimeInterval = 3600 // 1 hour
    let requiresNetworkData = true
    
    @StateObject private var dataManager = NetWorthDataManager()
    
    func createView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // Header with total net worth
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Net Worth")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("₹\(dataManager.totalNetWorth, specifier: "%.0f")")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(dataManager.monthlyChange >= 0 ? "+" : "")
                            + Text("₹\(dataManager.monthlyChange, specifier: "%.0f")")
                        Text("\(dataManager.monthlyChangePercent, specifier: "%.1f")%")
                    }
                    .font(.caption)
                    .foregroundColor(dataManager.monthlyChange >= 0 ? .green : .red)
                }
                
                // Net worth trend chart
                Chart(dataManager.netWorthHistory) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Net Worth", entry.value)
                    )
                    .foregroundStyle(.blue.gradient)
                    
                    // Mark Indian festivals on chart
                    if entry.isFestival {
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Net Worth", entry.value)
                        )
                        .foregroundStyle(.orange)
                        .symbol(.circle)
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: dataManager.chartYRange)
                
                // Asset breakdown
                HStack {
                    ForEach(dataManager.assetBreakdown, id: \.category) { asset in
                        VStack {
                            Circle()
                                .fill(asset.color)
                                .frame(width: 12, height: 12)
                            Text(asset.category)
                                .font(.caption2)
                            Text("₹\(asset.value, specifier: "%.0f")")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
        )
    }
    
    func updateData() async {
        await dataManager.refreshNetWorthData()
    }
    
    func exportData() -> WidgetData {
        WidgetData(
            type: "net_worth",
            data: [
                "total": dataManager.totalNetWorth,
                "monthly_change": dataManager.monthlyChange,
                "asset_breakdown": dataManager.assetBreakdown,
                "history": dataManager.netWorthHistory
            ]
        )
    }
}
```

#### Indian Market Tracker Widget
```swift
struct IndianMarketWidget: DashboardWidget {
    let id = UUID()
    let title = "Market Overview"
    var size: WidgetSize = .medium
    var position: WidgetPosition = WidgetPosition(row: 0, column: 2, span: (2, 1))
    var isVisible = true
    let refreshInterval: TimeInterval = 300 // 5 minutes during market hours
    let requiresNetworkData = true
    
    @StateObject private var marketData = IndianMarketDataManager()
    
    func createView() -> AnyView {
        AnyView(
            VStack(spacing: 8) {
                HStack {
                    Text("Indian Markets")
                        .font(.headline)
                    Spacer()
                    Text(marketData.lastUpdated, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2)) {
                    MarketIndexCard(
                        name: "NIFTY 50",
                        value: marketData.nifty50.value,
                        change: marketData.nifty50.change,
                        changePercent: marketData.nifty50.changePercent
                    )
                    
                    MarketIndexCard(
                        name: "SENSEX",
                        value: marketData.sensex.value,
                        change: marketData.sensex.change,
                        changePercent: marketData.sensex.changePercent
                    )
                    
                    MarketIndexCard(
                        name: "Gold (₹/10g)",
                        value: marketData.goldPrice.value,
                        change: marketData.goldPrice.change,
                        changePercent: marketData.goldPrice.changePercent
                    )
                    
                    MarketIndexCard(
                        name: "USD/INR",
                        value: marketData.usdInr.value,
                        change: marketData.usdInr.change,
                        changePercent: marketData.usdInr.changePercent
                    )
                }
                
                if marketData.isMarketOpen {
                    Text("Market Open")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.1))
                        .cornerRadius(4)
                } else {
                    Text("Market Closed")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
        )
    }
    
    func updateData() async {
        await marketData.refreshMarketData()
    }
    
    func exportData() -> WidgetData {
        WidgetData(
            type: "indian_markets",
            data: [
                "nifty50": marketData.nifty50,
                "sensex": marketData.sensex,
                "gold_price": marketData.goldPrice,
                "usd_inr": marketData.usdInr,
                "is_market_open": marketData.isMarketOpen
            ]
        )
    }
}
```

#### Budget Progress Widget
```swift
struct BudgetProgressWidget: DashboardWidget {
    let id = UUID()
    let title = "Monthly Budget"
    var size: WidgetSize = .medium
    var position: WidgetPosition = WidgetPosition(row: 1, column: 0, span: (2, 1))
    var isVisible = true
    let refreshInterval: TimeInterval = 1800 // 30 minutes
    let requiresNetworkData = false
    
    @StateObject private var budgetManager = BudgetManager()
    
    func createView() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Budget Progress")
                        .font(.headline)
                    Spacer()
                    Text(budgetManager.currentMonthName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ForEach(budgetManager.topCategories, id: \.category) { budget in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(budget.category)
                                .font(.subheadline)
                            Spacer()
                            Text("₹\(budget.spent)/₹\(budget.allocated)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: min(budget.progress, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: 
                                budget.progress > 1.0 ? .red : 
                                budget.progress > 0.8 ? .orange : .green
                            ))
                        
                        if budget.progress > 1.0 {
                            Text("Over budget by ₹\(budget.spent - budget.allocated)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                HStack {
                    Text("Total: ₹\(budgetManager.totalSpent)/₹\(budgetManager.totalBudget)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if budgetManager.totalProgress > 1.0 {
                        Text("Over by ₹\(budgetManager.totalSpent - budgetManager.totalBudget)")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("₹\(budgetManager.totalBudget - budgetManager.totalSpent) remaining")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
        )
    }
    
    func updateData() async {
        await budgetManager.refreshBudgetData()
    }
    
    func exportData() -> WidgetData {
        WidgetData(
            type: "budget_progress",
            data: [
                "total_budget": budgetManager.totalBudget,
                "total_spent": budgetManager.totalSpent,
                "categories": budgetManager.topCategories,
                "progress": budgetManager.totalProgress
            ]
        )
    }
}
```

### 3. Dashboard Manager
```swift
class DashboardManager: ObservableObject {
    @Published var widgets: [any DashboardWidget] = []
    @Published var isEditMode = false
    @Published var dashboardLayout: DashboardLayout = .default
    
    private let persistenceManager = DashboardPersistenceManager()
    private var refreshTimer: Timer?
    
    enum DashboardLayout: String, CaseIterable {
        case compact = "Compact"
        case default = "Default"
        case detailed = "Detailed"
        case custom = "Custom"
    }
    
    init() {
        loadSavedConfiguration()
        setupAutoRefresh()
    }
    
    func loadSavedConfiguration() {
        if let savedWidgets = persistenceManager.loadWidgetConfiguration() {
            self.widgets = savedWidgets
        } else {
            setupDefaultWidgets()
        }
    }
    
    func setupDefaultWidgets() {
        widgets = [
            NetWorthWidget(),
            IndianMarketWidget(),
            BudgetProgressWidget(),
            RecentTransactionsWidget(),
            InvestmentPerformanceWidget(),
            GoalsProgressWidget(),
            UpcomingBillsWidget(),
            ExpenseBreakdownWidget()
        ]
    }
    
    func addWidget(_ widget: any DashboardWidget) {
        widgets.append(widget)
        saveConfiguration()
    }
    
    func removeWidget(at index: Int) {
        widgets.remove(at: index)
        saveConfiguration()
    }
    
    func moveWidget(from source: IndexSet, to destination: Int) {
        widgets.move(fromOffsets: source, toOffset: destination)
        saveConfiguration()
    }
    
    func updateWidgetPosition(_ widget: any DashboardWidget, to position: WidgetPosition) {
        if let index = widgets.firstIndex(where: { $0.id == widget.id }) {
            widgets[index].position = position
            saveConfiguration()
        }
    }
    
    func refreshAllWidgets() async {
        await withTaskGroup(of: Void.self) { group in
            for widget in widgets where widget.isVisible {
                group.addTask {
                    await widget.updateData()
                }
            }
        }
    }
    
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshAllWidgets()
            }
        }
    }
    
    private func saveConfiguration() {
        persistenceManager.saveWidgetConfiguration(widgets)
    }
}
```

## Advanced Search System

### 1. Universal Search Architecture
```swift
// Multi-dimensional Search Engine
class UniversalSearchEngine: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchFilters: SearchFilters = SearchFilters()
    
    private let searchQueue = DispatchQueue(label: "search.engine", qos: .userInitiated)
    private let searchCache = LRUCache<String, [SearchResult]>(capacity: 100)
    private let indexManager = SearchIndexManager()
    
    struct SearchFilters {
        var dateRange: DateRange = .allTime
        var amountRange: ClosedRange<Decimal>?
        var categories: Set<TransactionCategory> = []
        var accounts: Set<Account> = []
        var searchType: SearchType = .all
        var sortBy: SortOption = .relevance
        var includeTags: Set<String> = []
        var excludeTags: Set<String> = []
    }
    
    enum SearchType: String, CaseIterable {
        case all = "All"
        case transactions = "Transactions"
        case assets = "Assets"
        case contacts = "Contacts"
        case goals = "Goals"
        case bills = "Bills"
    }
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case dateDescending = "Date (Newest)"
        case dateAscending = "Date (Oldest)"
        case amountDescending = "Amount (Highest)"
        case amountAscending = "Amount (Lowest)"
    }
    
    func search(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // Check cache first
        let cacheKey = createCacheKey(query, filters: searchFilters)
        if let cachedResults = searchCache[cacheKey] {
            searchResults = cachedResults
            return
        }
        
        isSearching = true
        
        Task {
            let results = await performSearch(query)
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
                self.searchCache[cacheKey] = results
            }
        }
    }
    
    private func performSearch(_ query: String) async -> [SearchResult] {
        return await withTaskGroup(of: [SearchResult].self) { group in
            // Natural language processing
            group.addTask {
                await self.naturalLanguageSearch(query)
            }
            
            // Exact text matching
            group.addTask {
                await self.exactTextSearch(query)
            }
            
            // Fuzzy matching
            group.addTask {
                await self.fuzzySearch(query)
            }
            
            // Semantic search
            group.addTask {
                await self.semanticSearch(query)
            }
            
            // Amount-based search
            group.addTask {
                await self.amountBasedSearch(query)
            }
            
            var allResults: [SearchResult] = []
            for await results in group {
                allResults.append(contentsOf: results)
            }
            
            return consolidateAndRankResults(allResults)
        }
    }
    
    private func naturalLanguageSearch(_ query: String) async -> [SearchResult] {
        let nlProcessor = NaturalLanguageProcessor()
        let searchIntent = nlProcessor.parseSearchIntent(query)
        
        switch searchIntent.type {
        case .amountQuery:
            return await searchByAmount(searchIntent.extractedAmount, operator: searchIntent.operator)
        case .merchantQuery:
            return await searchByMerchant(searchIntent.extractedMerchant)
        case .categoryQuery:
            return await searchByCategory(searchIntent.extractedCategory)
        case .dateQuery:
            return await searchByDate(searchIntent.extractedDateRange)
        case .complexQuery:
            return await complexSearch(searchIntent)
        default:
            return []
        }
    }
    
    private func exactTextSearch(_ query: String) async -> [SearchResult] {
        return await searchQueue.async {
            let transactions = DatabaseManager.shared.searchTransactions(query: query, exact: true)
            let assets = DatabaseManager.shared.searchAssets(query: query, exact: true)
            let contacts = DatabaseManager.shared.searchContacts(query: query, exact: true)
            
            var results: [SearchResult] = []
            
            results.append(contentsOf: transactions.map { SearchResult(item: $0, score: 1.0, type: .transaction) })
            results.append(contentsOf: assets.map { SearchResult(item: $0, score: 1.0, type: .asset) })
            results.append(contentsOf: contacts.map { SearchResult(item: $0, score: 1.0, type: .contact) })
            
            return results
        }
    }
    
    private func fuzzySearch(_ query: String) async -> [SearchResult] {
        return await searchQueue.async {
            let fuzzyMatcher = FuzzyStringMatcher()
            let allSearchableItems = self.indexManager.getAllSearchableItems()
            
            let matches = allSearchableItems.compactMap { item in
                let score = fuzzyMatcher.score(query, against: item.searchableText)
                return score > 0.5 ? SearchResult(item: item.data, score: score, type: item.type) : nil
            }
            
            return matches.sorted { $0.score > $1.score }
        }
    }
    
    private func semanticSearch(_ query: String) async -> [SearchResult] {
        // Use Core ML for semantic similarity search
        let semanticModel = SemanticSearchModel()
        let queryEmbedding = await semanticModel.embed(query)
        
        let similarItems = await indexManager.findSimilarItems(to: queryEmbedding, threshold: 0.7)
        
        return similarItems.map { item in
            SearchResult(item: item.data, score: item.similarity, type: item.type)
        }
    }
    
    private func consolidateAndRankResults(_ results: [SearchResult]) -> [SearchResult] {
        // Remove duplicates and boost scores based on multiple matches
        var consolidatedResults: [String: SearchResult] = [:]
        
        for result in results {
            let key = result.uniqueKey
            if let existing = consolidatedResults[key] {
                // Boost score for multiple matches
                consolidatedResults[key] = SearchResult(
                    item: existing.item,
                    score: min(existing.score + result.score * 0.3, 1.0),
                    type: existing.type
                )
            } else {
                consolidatedResults[key] = result
            }
        }
        
        // Apply filters and sort
        let filteredResults = consolidatedResults.values.filter { result in
            applyFilters(to: result)
        }
        
        return sortResults(Array(filteredResults))
    }
}
```

### 2. Smart Search Suggestions
```swift
// Intelligent Search Suggestions
class SearchSuggestionEngine: ObservableObject {
    @Published var suggestions: [SearchSuggestion] = []
    
    private let searchHistory = SearchHistoryManager()
    private let frequencyAnalyzer = SearchFrequencyAnalyzer()
    
    struct SearchSuggestion {
        let text: String
        let type: SuggestionType
        let icon: String
        let score: Double
        let isRecent: Bool
        let frequency: Int
    }
    
    enum SuggestionType {
        case recentSearch
        case popularMerchant
        case frequentCategory
        case amountPattern
        case dateRange
        case smartCompletion
    }
    
    func generateSuggestions(for query: String) {
        let currentSuggestions = combineSuggestions([
            recentSearchSuggestions(for: query),
            merchantSuggestions(for: query),
            categorySuggestions(for: query),
            amountSuggestions(for: query),
            dateSuggestions(for: query),
            smartCompletions(for: query)
        ])
        
        suggestions = currentSuggestions
            .sorted { $0.score > $1.score }
            .prefix(8)
            .map { $0 }
    }
    
    private func recentSearchSuggestions(for query: String) -> [SearchSuggestion] {
        return searchHistory.getRecentSearches()
            .filter { $0.lowercased().contains(query.lowercased()) }
            .prefix(3)
            .map { search in
                SearchSuggestion(
                    text: search,
                    type: .recentSearch,
                    icon: "clock",
                    score: 0.9,
                    isRecent: true,
                    frequency: searchHistory.getFrequency(for: search)
                )
            }
    }
    
    private func merchantSuggestions(for query: String) -> [SearchSuggestion] {
        let merchants = frequencyAnalyzer.getTopMerchants()
        return merchants
            .filter { merchant in
                merchant.name.lowercased().contains(query.lowercased()) ||
                merchant.aliases.contains { $0.lowercased().contains(query.lowercased()) }
            }
            .prefix(5)
            .map { merchant in
                SearchSuggestion(
                    text: merchant.name,
                    type: .popularMerchant,
                    icon: merchant.category.icon,
                    score: 0.8 * merchant.frequencyScore,
                    isRecent: merchant.lastUsed > Date().addingTimeInterval(-86400 * 7),
                    frequency: merchant.transactionCount
                )
            }
    }
    
    private func smartCompletions(for query: String) -> [SearchSuggestion] {
        let completions = generateSmartCompletions(query)
        return completions.map { completion in
            SearchSuggestion(
                text: completion.text,
                type: .smartCompletion,
                icon: completion.icon,
                score: completion.confidence,
                isRecent: false,
                frequency: 0
            )
        }
    }
    
    private func generateSmartCompletions(_ query: String) -> [SmartCompletion] {
        var completions: [SmartCompletion] = []
        
        // Pattern: "spent X at" -> suggest merchants
        if query.matches(pattern: "spent \\d+ at") {
            let merchants = frequencyAnalyzer.getTopMerchants().prefix(3)
            completions.append(contentsOf: merchants.map { merchant in
                SmartCompletion(
                    text: query + " " + merchant.name,
                    icon: "storefront",
                    confidence: 0.85
                )
            })
        }
        
        // Pattern: "transactions in" -> suggest categories or time periods
        if query.lowercased().hasPrefix("transactions in") {
            completions.append(contentsOf: [
                SmartCompletion(text: "transactions in January", icon: "calendar", confidence: 0.7),
                SmartCompletion(text: "transactions in Food & Dining", icon: "fork.knife", confidence: 0.7),
                SmartCompletion(text: "transactions in last month", icon: "clock", confidence: 0.8)
            ])
        }
        
        // Pattern: "more than" -> suggest amounts
        if query.lowercased().contains("more than") {
            let commonAmounts = [500, 1000, 2000, 5000, 10000]
            completions.append(contentsOf: commonAmounts.map { amount in
                SmartCompletion(
                    text: query + " ₹\(amount)",
                    icon: "indianrupeesign.circle",
                    confidence: 0.6
                )
            })
        }
        
        return completions
    }
}
```

### 3. Advanced Filtering System
```swift
// Advanced Search Filters
struct AdvancedSearchFilters: View {
    @Binding var filters: UniversalSearchEngine.SearchFilters
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Quick filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "Today", isSelected: filters.dateRange == .today) {
                        filters.dateRange = .today
                    }
                    FilterChip(title: "This Week", isSelected: filters.dateRange == .thisWeek) {
                        filters.dateRange = .thisWeek
                    }
                    FilterChip(title: "This Month", isSelected: filters.dateRange == .thisMonth) {
                        filters.dateRange = .thisMonth
                    }
                    FilterChip(title: "High Amount", isSelected: filters.amountRange != nil) {
                        filters.amountRange = 10000...Decimal.greatestFiniteMagnitude
                    }
                    FilterChip(title: "Expenses", isSelected: filters.searchType == .transactions) {
                        filters.searchType = .transactions
                    }
                }
                .padding(.horizontal)
            }
            
            if isExpanded {
                VStack(spacing: 16) {
                    // Date range picker
                    DateRangeSection(dateRange: $filters.dateRange)
                    
                    // Amount range picker
                    AmountRangeSection(amountRange: $filters.amountRange)
                    
                    // Category selection
                    CategorySelectionSection(selectedCategories: $filters.categories)
                    
                    // Account selection
                    AccountSelectionSection(selectedAccounts: $filters.accounts)
                    
                    // Tags
                    TagSelectionSection(
                        includeTags: $filters.includeTags,
                        excludeTags: $filters.excludeTags
                    )
                    
                    // Sort options
                    SortOptionsSection(sortBy: $filters.sortBy)
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale))
            }
            
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "More Filters")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
}

struct AmountRangeSection: View {
    @Binding var amountRange: ClosedRange<Decimal>?
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var useRange = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Amount Range")
                    .font(.headline)
                Spacer()
                Toggle("Enable", isOn: $useRange)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            if useRange {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Minimum")
                            .font(.caption)
                        TextField("₹0", text: $minAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Text("to")
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading) {
                        Text("Maximum")
                            .font(.caption)
                        TextField("No limit", text: $maxAmount)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Quick amount chips
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    AmountChip(title: "< ₹1,000", range: 0...1000)
                    AmountChip(title: "₹1K - ₹10K", range: 1000...10000)
                    AmountChip(title: "₹10K - ₹1L", range: 10000...100000)
                    AmountChip(title: "₹1L - ₹10L", range: 100000...1000000)
                    AmountChip(title: "> ₹10L", range: 1000000...Decimal.greatestFiniteMagnitude)
                    AmountChip(title: "Clear", range: nil)
                }
            }
        }
        .onChange(of: useRange) { enabled in
            if !enabled {
                amountRange = nil
                minAmount = ""
                maxAmount = ""
            }
        }
        .onChange(of: minAmount) { newValue in
            updateAmountRange()
        }
        .onChange(of: maxAmount) { newValue in
            updateAmountRange()
        }
    }
    
    private func updateAmountRange() {
        guard useRange else { return }
        
        let min = Decimal(string: minAmount) ?? 0
        let max = Decimal(string: maxAmount) ?? Decimal.greatestFiniteMagnitude
        
        amountRange = min...max
    }
    
    private func AmountChip(title: String, range: ClosedRange<Decimal>?) -> some View {
        Button(title) {
            if let range = range {
                amountRange = range
                minAmount = String(describing: range.lowerBound)
                maxAmount = range.upperBound == Decimal.greatestFiniteMagnitude ? "" : String(describing: range.upperBound)
                useRange = true
            } else {
                amountRange = nil
                useRange = false
            }
        }
        .buttonStyle(.bordered)
        .font(.caption)
    }
}
```

This comprehensive dashboard and search system provides:

1. **Modular Widget System** - Customizable, drag-and-drop widgets for different financial aspects
2. **Indian Market Integration** - Real-time BSE/NSE data, gold prices, currency rates
3. **Advanced Search Engine** - Natural language, fuzzy matching, semantic search with caching
4. **Smart Suggestions** - AI-powered search completions and historical patterns
5. **Performance Optimization** - Efficient caching, lazy loading, and background updates
6. **Cultural Context** - Indian financial instruments, market hours, festival tracking

The system is designed to handle large datasets efficiently while providing instant search results and maintaining smooth user experience across all supported platforms.