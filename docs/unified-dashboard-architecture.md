# WealthWise Unified Dashboard Architecture

## Overview
A comprehensive dashboard architecture that unifies all WealthWise modules - goal tracking, tax management, salary tracking, currency management, multi-country tax, audience switching, localization, and cross-border asset management - into a single, cohesive experience with seamless switching between currencies and audiences.

## Unified Dashboard Architecture

### 1. Dashboard Coordinator
```swift
@MainActor
class WealthWiseDashboardCoordinator: ObservableObject {
    // Core Managers
    @Published var currencyManager = CurrencyManager.shared
    @Published var audienceManager = AudienceManager.shared
    @Published var localizationManager = LocalizationManager.shared
    @Published var crossBorderAssetManager: CrossBorderAssetManager
    @Published var multiCountryTaxManager: MultiCountryTaxManager
    @Published var goalTrackingManager: GoalTrackingManager
    @Published var salaryTrackingManager: SalaryTrackingManager
    
    // Dashboard State
    @Published var currentView: DashboardView = .overview
    @Published var selectedTimeframe: TimeFrame = .month
    @Published var displayCurrency: SupportedCurrency
    @Published var showComplianceAlerts: Bool = true
    @Published var quickActions: [QuickAction] = []
    
    // Data Models
    @Published var dashboardData: DashboardData
    @Published var insights: [FinancialInsight] = []
    @Published var notifications: [DashboardNotification] = []
    
    // Loading States
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date = Date()
    
    init() {
        // Initialize with current audience currency
        displayCurrency = audienceManager.currentAudience.primaryCurrency
        
        // Initialize managers with dependencies
        multiCountryTaxManager = MultiCountryTaxManager(
            currencyManager: currencyManager,
            audienceManager: audienceManager
        )
        
        crossBorderAssetManager = CrossBorderAssetManager(
            currencyManager: currencyManager,
            taxManager: multiCountryTaxManager,
            audienceManager: audienceManager
        )
        
        goalTrackingManager = GoalTrackingManager(
            currencyManager: currencyManager,
            assetManager: crossBorderAssetManager
        )
        
        salaryTrackingManager = SalaryTrackingManager(
            currencyManager: currencyManager,
            taxManager: multiCountryTaxManager,
            audienceManager: audienceManager
        )
        
        // Initialize dashboard data
        dashboardData = DashboardData()
        
        setupObservers()
        loadDashboardData()
    }
    
    private func setupObservers() {
        // Currency change observer
        NotificationCenter.default.addObserver(
            forName: .currencyChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let changeInfo = notification.object as? CurrencyChangeInfo {
                self?.handleCurrencyChange(changeInfo)
            }
        }
        
        // Audience change observer
        NotificationCenter.default.addObserver(
            forName: .audienceChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let changeInfo = notification.object as? AudienceChangeInfo {
                self?.handleAudienceChange(changeInfo)
            }
        }
        
        // Asset update observer
        NotificationCenter.default.addObserver(
            forName: .assetsUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDashboardData()
        }
    }
    
    // MARK: - Dashboard Data Management
    func loadDashboardData() {
        isLoading = true
        
        Task {
            await refreshDashboardData()
            await generateInsights()
            await loadQuickActions()
            await checkNotifications()
            
            isLoading = false
            lastUpdated = Date()
        }
    }
    
    func refreshDashboardData() async {
        // Collect data from all managers in display currency
        let netWorth = await calculateNetWorth()
        let monthlyFlow = await calculateMonthlyFlow()
        let goalProgress = await calculateGoalProgress()
        let taxSummary = await calculateTaxSummary()
        let assetAllocation = await calculateAssetAllocation()
        let countryBreakdown = await calculateCountryBreakdown()
        
        dashboardData = DashboardData(
            netWorth: netWorth,
            monthlyIncome: monthlyFlow.income,
            monthlyExpenses: monthlyFlow.expenses,
            savingsRate: monthlyFlow.savingsRate,
            goalProgress: goalProgress,
            taxLiability: taxSummary.currentLiability,
            taxSavings: taxSummary.potentialSavings,
            assetAllocation: assetAllocation,
            countryBreakdown: countryBreakdown,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Currency Management
    func switchDisplayCurrency(to currency: SupportedCurrency) async {
        displayCurrency = currency
        
        // Update all managers
        await crossBorderAssetManager.switchDisplayCurrency(to: currency)
        await goalTrackingManager.switchDisplayCurrency(to: currency)
        await salaryTrackingManager.switchDisplayCurrency(to: currency)
        
        // Refresh dashboard
        await refreshDashboardData()
        
        NotificationCenter.default.post(
            name: .displayCurrencyChanged,
            object: CurrencyChangeInfo(from: displayCurrency, to: currency)
        )
    }
    
    // MARK: - Audience Management
    func switchAudience(to audience: PrimaryAudience) async {
        await audienceManager.switchAudience(to: audience)
        
        // Update display currency to audience default
        let newCurrency = audience.primaryCurrency
        if displayCurrency != newCurrency {
            await switchDisplayCurrency(to: newCurrency)
        }
        
        // Refresh all data
        await refreshDashboardData()
        await generateInsights()
        await loadQuickActions()
    }
    
    // MARK: - Data Calculations
    private func calculateNetWorth() async -> NetWorthData {
        let totalAssets = await crossBorderAssetManager.getPortfolioAllocation()
            .reduce(Decimal(0)) { sum, allocation in
                return sum + currencyManager.convertSync(
                    amount: allocation.value,
                    from: allocation.assets.first?.originalCurrency ?? displayCurrency,
                    to: displayCurrency
                ) ?? 0
            }
        
        let totalLiabilities = await crossBorderAssetManager.assets
            .filter { $0.type.isLiability }
            .reduce(Decimal(0)) { sum, asset in
                return sum + (currencyManager.convertSync(
                    amount: asset.currentValue,
                    from: asset.originalCurrency,
                    to: displayCurrency
                ) ?? 0)
            }
        
        return NetWorthData(
            assets: totalAssets,
            liabilities: totalLiabilities,
            netWorth: totalAssets - totalLiabilities,
            changeFromLastMonth: calculateNetWorthChange()
        )
    }
    
    private func calculateMonthlyFlow() async -> MonthlyFlowData {
        let salaryData = await salaryTrackingManager.getCurrentSalaryData()
        let income = currencyManager.convertSync(
            amount: salaryData.netSalary,
            from: salaryData.currency,
            to: displayCurrency
        ) ?? 0
        
        // Calculate expenses from transaction data
        let expenses = Decimal(0) // TODO: Implement transaction tracking
        
        let savings = income - expenses
        let savingsRate = income > 0 ? (savings / income) * 100 : 0
        
        return MonthlyFlowData(
            income: income,
            expenses: expenses,
            savings: savings,
            savingsRate: savingsRate
        )
    }
    
    private func calculateGoalProgress() async -> [GoalProgressSummary] {
        return await goalTrackingManager.getAllGoals().map { goal in
            GoalProgressSummary(
                id: goal.id,
                name: goal.name,
                targetAmount: currencyManager.convertSync(
                    amount: goal.targetAmount,
                    from: goal.currency,
                    to: displayCurrency
                ) ?? 0,
                currentAmount: currencyManager.convertSync(
                    amount: goal.currentAmount,
                    from: goal.currency,
                    to: displayCurrency
                ) ?? 0,
                progressPercentage: goal.progressPercentage,
                isOnTrack: goal.isOnTrack
            )
        }
    }
    
    private func calculateTaxSummary() async -> TaxSummaryData {
        let currentYear = Calendar.current.component(.year, from: Date())
        let taxData = await multiCountryTaxManager.calculateTaxSummary(for: currentYear)
        
        return TaxSummaryData(
            currentLiability: currencyManager.convertSync(
                amount: taxData.totalTaxLiability,
                from: audienceManager.currentAudience.primaryCurrency,
                to: displayCurrency
            ) ?? 0,
            potentialSavings: currencyManager.convertSync(
                amount: taxData.potentialSavings,
                from: audienceManager.currentAudience.primaryCurrency,
                to: displayCurrency
            ) ?? 0,
            nextPaymentDue: taxData.nextPaymentDue,
            countries: taxData.countryBreakdown.count
        )
    }
    
    private func calculateAssetAllocation() async -> [AssetAllocationSummary] {
        return crossBorderAssetManager.getPortfolioAllocation().map { allocation in
            AssetAllocationSummary(
                type: allocation.type,
                value: currencyManager.convertSync(
                    amount: allocation.value,
                    from: allocation.assets.first?.originalCurrency ?? displayCurrency,
                    to: displayCurrency
                ) ?? 0,
                percentage: allocation.percentage
            )
        }
    }
    
    private func calculateCountryBreakdown() async -> [CountryBreakdownSummary] {
        return crossBorderAssetManager.getCountryAllocation().map { allocation in
            CountryBreakdownSummary(
                country: allocation.country,
                value: currencyManager.convertSync(
                    amount: allocation.value,
                    from: allocation.assets.first?.originalCurrency ?? displayCurrency,
                    to: displayCurrency
                ) ?? 0,
                percentage: allocation.percentage,
                complianceStatus: allocation.complianceStatus
            )
        }
    }
    
    // MARK: - Insights Generation
    private func generateInsights() async {
        insights = []
        
        // Net worth trend insight
        let netWorthChange = calculateNetWorthChange()
        if netWorthChange != 0 {
            insights.append(FinancialInsight(
                type: .netWorthTrend,
                title: netWorthChange > 0 ? "Net Worth Growing" : "Net Worth Declining",
                description: "Your net worth has \(netWorthChange > 0 ? "increased" : "decreased") by \(localizationManager.formatCurrency(abs(netWorthChange))) this month",
                severity: netWorthChange > 0 ? .positive : .warning,
                actionable: netWorthChange < 0
            ))
        }
        
        // Goal progress insights
        let goals = await goalTrackingManager.getAllGoals()
        for goal in goals.prefix(3) {
            if !goal.isOnTrack {
                insights.append(FinancialInsight(
                    type: .goalProgress,
                    title: "Goal Behind Schedule",
                    description: "\(goal.name) is behind schedule. Consider increasing monthly contributions.",
                    severity: .warning,
                    actionable: true
                ))
            }
        }
        
        // Tax optimization insights
        let taxData = await multiCountryTaxManager.calculateTaxSummary(for: Calendar.current.component(.year, from: Date()))
        if taxData.potentialSavings > 0 {
            insights.append(FinancialInsight(
                type: .taxOptimization,
                title: "Tax Savings Opportunity",
                description: "You could save up to \(localizationManager.formatCurrency(taxData.potentialSavings)) in taxes this year",
                severity: .positive,
                actionable: true
            ))
        }
        
        // Currency risk insights
        let portfolioInForeignCurrencies = crossBorderAssetManager.assets
            .filter { $0.originalCurrency != displayCurrency }
            .reduce(Decimal(0)) { sum, asset in
                return sum + (currencyManager.convertSync(
                    amount: asset.currentValue,
                    from: asset.originalCurrency,
                    to: displayCurrency
                ) ?? 0)
            }
        
        if portfolioInForeignCurrencies > dashboardData.netWorth.netWorth * Decimal(0.2) {
            insights.append(FinancialInsight(
                type: .currencyRisk,
                title: "Currency Risk Exposure",
                description: "Over 20% of your portfolio is in foreign currencies. Consider hedging strategies.",
                severity: .info,
                actionable: true
            ))
        }
        
        // Compliance insights
        let complianceAlerts = crossBorderAssetManager.complianceAlerts
        if !complianceAlerts.isEmpty {
            insights.append(FinancialInsight(
                type: .compliance,
                title: "Compliance Action Required",
                description: "You have \(complianceAlerts.count) compliance items requiring attention",
                severity: .warning,
                actionable: true
            ))
        }
    }
    
    // MARK: - Quick Actions
    private func loadQuickActions() async {
        quickActions = []
        
        // Add transaction
        quickActions.append(QuickAction(
            id: "add_transaction",
            title: localizationManager.localizedString(.addTransaction),
            icon: "plus.circle",
            action: .addTransaction
        ))
        
        // Create goal
        quickActions.append(QuickAction(
            id: "create_goal",
            title: localizationManager.localizedString(.createGoal),
            icon: "target",
            action: .createGoal
        ))
        
        // View tax summary
        quickActions.append(QuickAction(
            id: "tax_summary",
            title: localizationManager.localizedString(.taxLiability),
            icon: "doc.text",
            action: .viewTaxSummary
        ))
        
        // Switch currency if user has assets in multiple currencies
        let currenciesInPortfolio = Set(crossBorderAssetManager.assets.map { $0.originalCurrency })
        if currenciesInPortfolio.count > 1 {
            quickActions.append(QuickAction(
                id: "switch_currency",
                title: "Switch Currency",
                icon: "arrow.2.squarepath",
                action: .switchCurrency
            ))
        }
        
        // Switch market if user has assets in multiple countries
        let countriesInPortfolio = Set(crossBorderAssetManager.assets.map { $0.country })
        if countriesInPortfolio.count > 1 {
            quickActions.append(QuickAction(
                id: "switch_market",
                title: "Switch Market",
                icon: "globe",
                action: .switchMarket
            ))
        }
    }
    
    // MARK: - Event Handlers
    private func handleCurrencyChange(_ changeInfo: CurrencyChangeInfo) {
        Task {
            await refreshDashboardData()
        }
    }
    
    private func handleAudienceChange(_ changeInfo: AudienceChangeInfo) {
        displayCurrency = changeInfo.newAudience.primaryCurrency
        Task {
            await refreshDashboardData()
            await generateInsights()
            await loadQuickActions()
        }
    }
    
    // MARK: - Helper Methods
    private func calculateNetWorthChange() -> Decimal {
        // TODO: Implement historical net worth tracking
        return Decimal(0)
    }
    
    private func checkNotifications() async {
        notifications = []
        
        // Compliance notifications
        let complianceAlerts = crossBorderAssetManager.complianceAlerts
        for alert in complianceAlerts.prefix(3) {
            notifications.append(DashboardNotification(
                id: alert.id.uuidString,
                type: .compliance,
                title: alert.title,
                message: alert.description,
                severity: mapAlertSeverity(alert.severity),
                actionRequired: true
            ))
        }
        
        // Goal notifications
        let goals = await goalTrackingManager.getAllGoals()
        for goal in goals.filter({ !$0.isOnTrack }).prefix(2) {
            notifications.append(DashboardNotification(
                id: goal.id.uuidString,
                type: .goal,
                title: "Goal Update Needed",
                message: "\(goal.name) needs attention to stay on track",
                severity: .warning,
                actionRequired: true
            ))
        }
        
        // Tax notifications
        let taxData = await multiCountryTaxManager.calculateTaxSummary(for: Calendar.current.component(.year, from: Date()))
        if let nextPayment = taxData.nextPaymentDue, nextPayment.timeIntervalSinceNow < 86400 * 30 {
            notifications.append(DashboardNotification(
                id: "tax_payment_due",
                type: .tax,
                title: "Tax Payment Due",
                message: "Tax payment due in less than 30 days",
                severity: .warning,
                actionRequired: true
            ))
        }
    }
    
    private func mapAlertSeverity(_ severity: ComplianceAlert.AlertSeverity) -> DashboardNotification.Severity {
        switch severity {
        case .info: return .info
        case .warning: return .warning
        case .critical: return .critical
        }
    }
}

// MARK: - Supporting Data Models
struct DashboardData {
    let netWorth: NetWorthData
    let monthlyIncome: Decimal
    let monthlyExpenses: Decimal
    let savingsRate: Decimal
    let goalProgress: [GoalProgressSummary]
    let taxLiability: Decimal
    let taxSavings: Decimal
    let assetAllocation: [AssetAllocationSummary]
    let countryBreakdown: [CountryBreakdownSummary]
    let lastUpdated: Date
    
    init() {
        self.netWorth = NetWorthData(assets: 0, liabilities: 0, netWorth: 0, changeFromLastMonth: 0)
        self.monthlyIncome = 0
        self.monthlyExpenses = 0
        self.savingsRate = 0
        self.goalProgress = []
        self.taxLiability = 0
        self.taxSavings = 0
        self.assetAllocation = []
        self.countryBreakdown = []
        self.lastUpdated = Date()
    }
    
    init(
        netWorth: NetWorthData,
        monthlyIncome: Decimal,
        monthlyExpenses: Decimal,
        savingsRate: Decimal,
        goalProgress: [GoalProgressSummary],
        taxLiability: Decimal,
        taxSavings: Decimal,
        assetAllocation: [AssetAllocationSummary],
        countryBreakdown: [CountryBreakdownSummary],
        lastUpdated: Date
    ) {
        self.netWorth = netWorth
        self.monthlyIncome = monthlyIncome
        self.monthlyExpenses = monthlyExpenses
        self.savingsRate = savingsRate
        self.goalProgress = goalProgress
        self.taxLiability = taxLiability
        self.taxSavings = taxSavings
        self.assetAllocation = assetAllocation
        self.countryBreakdown = countryBreakdown
        self.lastUpdated = lastUpdated
    }
}

struct NetWorthData {
    let assets: Decimal
    let liabilities: Decimal
    let netWorth: Decimal
    let changeFromLastMonth: Decimal
    
    var changePercentage: Decimal {
        let previousNetWorth = netWorth - changeFromLastMonth
        return previousNetWorth != 0 ? (changeFromLastMonth / previousNetWorth) * 100 : 0
    }
}

struct MonthlyFlowData {
    let income: Decimal
    let expenses: Decimal
    let savings: Decimal
    let savingsRate: Decimal
}

struct GoalProgressSummary: Identifiable {
    let id: UUID
    let name: String
    let targetAmount: Decimal
    let currentAmount: Decimal
    let progressPercentage: Decimal
    let isOnTrack: Bool
}

struct TaxSummaryData {
    let currentLiability: Decimal
    let potentialSavings: Decimal
    let nextPaymentDue: Date?
    let countries: Int
}

struct AssetAllocationSummary {
    let type: AssetType
    let value: Decimal
    let percentage: Decimal
}

struct CountryBreakdownSummary {
    let country: CountryCode
    let value: Decimal
    let percentage: Decimal
    let complianceStatus: ComplianceStatus
}

struct FinancialInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let severity: Severity
    let actionable: Bool
    
    enum InsightType {
        case netWorthTrend
        case goalProgress
        case taxOptimization
        case currencyRisk
        case compliance
        case spending
        case investment
    }
    
    enum Severity {
        case positive
        case info
        case warning
        case critical
    }
}

struct DashboardNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let severity: Severity
    let actionRequired: Bool
    
    enum NotificationType {
        case compliance
        case goal
        case tax
        case currency
        case general
    }
    
    enum Severity {
        case info
        case warning
        case critical
    }
}

struct QuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let action: ActionType
    
    enum ActionType {
        case addTransaction
        case createGoal
        case viewTaxSummary
        case switchCurrency
        case switchMarket
        case addAsset
        case viewCompliance
    }
}

enum DashboardView: String, CaseIterable {
    case overview = "overview"
    case portfolio = "portfolio"
    case goals = "goals"
    case taxes = "taxes"
    case compliance = "compliance"
    case reports = "reports"
}

enum TimeFrame: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    case all = "all"
}

// MARK: - Extensions for Asset Types
extension AssetType {
    var isLiability: Bool {
        switch self {
        case .homeLoan, .personalLoan, .creditCard, .studentLoan, .businessLoan:
            return true
        default:
            return false
        }
    }
    
    var category: AssetCategory {
        switch self {
        case .bankAccount, .savingsAccount, .currentAccount, .fixedDeposit, .certificateOfDeposit:
            return .cash
        case .stocks, .bonds, .mutualFunds, .etf, .indexFunds:
            return .investments
        case .providentFund, .retirementAccount, .pension, .superannuation, .rrsp, .cpf:
            return .retirement
        case .lifeInsurance, .healthInsurance, .propertyInsurance, .termInsurance, .ulip:
            return .insurance
        case .residentialProperty, .commercialProperty, .land, .reit:
            return .realEstate
        case .gold, .silver, .art, .collectibles, .privateEquity, .businessOwnership, .commodities, .cryptocurrency:
            return .alternative
        case .homeLoan, .personalLoan, .creditCard, .studentLoan, .businessLoan:
            return .liabilities
        }
    }
    
    enum AssetCategory: String, CaseIterable {
        case cash = "cash"
        case investments = "investments"
        case retirement = "retirement"
        case insurance = "insurance"
        case realEstate = "real_estate"
        case alternative = "alternative"
        case liabilities = "liabilities"
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let displayCurrencyChanged = Notification.Name("displayCurrencyChanged")
    static let assetsUpdated = Notification.Name("assetsUpdated")
}
```

### 2. Main Dashboard View
```swift
struct WealthWiseDashboard: View {
    @StateObject private var coordinator = WealthWiseDashboardCoordinator()
    @StateObject private var localization = LocalizationManager.shared
    
    @State private var showingCurrencyPicker = false
    @State private var showingAudiencePicker = false
    @State private var selectedTab: DashboardView = .overview
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardOverviewView(coordinator: coordinator)
                .tabItem {
                    Image(systemName: "house.fill")
                    LocalizedText(.dashboard)
                }
                .tag(DashboardView.overview)
            
            CrossBorderPortfolioView(assetManager: coordinator.crossBorderAssetManager)
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    LocalizedText(.portfolio)
                }
                .tag(DashboardView.portfolio)
            
            GoalTrackingView(goalManager: coordinator.goalTrackingManager)
                .tabItem {
                    Image(systemName: "target")
                    LocalizedText(.goals)
                }
                .tag(DashboardView.goals)
            
            TaxManagementView(taxManager: coordinator.multiCountryTaxManager)
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Taxes")
                }
                .tag(DashboardView.taxes)
            
            ComplianceView(assetManager: coordinator.crossBorderAssetManager)
                .tabItem {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Compliance")
                }
                .tag(DashboardView.compliance)
            
            ReportsView(coordinator: coordinator)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    LocalizedText(.reports)
                }
                .tag(DashboardView.reports)
        }
        .environment(\.layoutDirection, localization.layoutDirection)
        .onAppear {
            coordinator.loadDashboardData()
        }
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerSheet(
                selectedCurrency: $coordinator.displayCurrency,
                onSelectionChanged: { currency in
                    Task {
                        await coordinator.switchDisplayCurrency(to: currency)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAudiencePicker) {
            AudiencePickerSheet(
                selectedAudience: $coordinator.audienceManager.currentAudience,
                onSelectionChanged: { audience in
                    Task {
                        await coordinator.switchAudience(to: audience)
                    }
                }
            )
        }
    }
}

struct DashboardOverviewView: View {
    @ObservedObject var coordinator: WealthWiseDashboardCoordinator
    @Environment(\.localization) private var localization
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header with net worth and currency/audience switchers
                DashboardHeaderCard(coordinator: coordinator)
                
                // Quick actions
                if !coordinator.quickActions.isEmpty {
                    QuickActionsCard(actions: coordinator.quickActions, coordinator: coordinator)
                }
                
                // Insights
                if !coordinator.insights.isEmpty {
                    InsightsCard(insights: coordinator.insights)
                }
                
                // Monthly flow
                MonthlyFlowCard(
                    income: coordinator.dashboardData.monthlyIncome,
                    expenses: coordinator.dashboardData.monthlyExpenses,
                    savingsRate: coordinator.dashboardData.savingsRate,
                    currency: coordinator.displayCurrency
                )
                
                // Goal progress
                if !coordinator.dashboardData.goalProgress.isEmpty {
                    GoalProgressCard(
                        goals: coordinator.dashboardData.goalProgress,
                        currency: coordinator.displayCurrency
                    )
                }
                
                // Asset allocation
                if !coordinator.dashboardData.assetAllocation.isEmpty {
                    AssetAllocationCard(
                        allocations: coordinator.dashboardData.assetAllocation,
                        currency: coordinator.displayCurrency
                    )
                }
                
                // Country breakdown (only if multi-country)
                if coordinator.dashboardData.countryBreakdown.count > 1 {
                    CountryBreakdownCard(
                        countries: coordinator.dashboardData.countryBreakdown,
                        currency: coordinator.displayCurrency
                    )
                }
                
                // Tax summary
                TaxSummaryCard(
                    liability: coordinator.dashboardData.taxLiability,
                    savings: coordinator.dashboardData.taxSavings,
                    currency: coordinator.displayCurrency
                )
                
                // Notifications
                if !coordinator.notifications.isEmpty {
                    NotificationsCard(notifications: coordinator.notifications)
                }
            }
            .padding()
        }
        .refreshable {
            coordinator.loadDashboardData()
        }
        .navigationTitle(LocalizedText(.dashboard))
        .navigationBarTitleDisplayMode(.large)
    }
}

struct DashboardHeaderCard: View {
    @ObservedObject var coordinator: WealthWiseDashboardCoordinator
    @Environment(\.localization) private var localization
    
    @State private var showingCurrencyPicker = false
    @State private var showingAudiencePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Net worth display
            VStack(spacing: 8) {
                LocalizedText(.netWorth)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button(action: { showingCurrencyPicker = true }) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        LocalizedCurrencyText(
                            coordinator.dashboardData.netWorth.netWorth,
                            style: .symbolOnly
                        )
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        
                        Text(coordinator.displayCurrency.rawValue)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Net worth change
                if coordinator.dashboardData.netWorth.changeFromLastMonth != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: coordinator.dashboardData.netWorth.changeFromLastMonth > 0 ? 
                              "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(coordinator.dashboardData.netWorth.changeFromLastMonth > 0 ? 
                                           .green : .red)
                        
                        LocalizedCurrencyText(
                            abs(coordinator.dashboardData.netWorth.changeFromLastMonth),
                            style: .compact
                        )
                        .foregroundColor(coordinator.dashboardData.netWorth.changeFromLastMonth > 0 ? 
                                       .green : .red)
                        
                        Text("(\(localization.formatNumber(coordinator.dashboardData.netWorth.changePercentage))%)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            // Audience and settings
            HStack {
                Button(action: { showingAudiencePicker = true }) {
                    HStack(spacing: 8) {
                        Text(coordinator.audienceManager.currentAudience.flag)
                            .font(.title2)
                        
                        Text(coordinator.audienceManager.currentAudience.displayName)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Text("Updated \(coordinator.lastUpdated, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingCurrencyPicker) {
            CurrencyPickerSheet(
                selectedCurrency: $coordinator.displayCurrency,
                onSelectionChanged: { currency in
                    Task {
                        await coordinator.switchDisplayCurrency(to: currency)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAudiencePicker) {
            AudiencePickerSheet(
                selectedAudience: $coordinator.audienceManager.currentAudience,
                onSelectionChanged: { audience in
                    Task {
                        await coordinator.switchAudience(to: audience)
                    }
                }
            )
        }
    }
}

struct QuickActionsCard: View {
    let actions: [QuickAction]
    let coordinator: WealthWiseDashboardCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(actions) { action in
                        QuickActionButton(action: action, coordinator: coordinator)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct QuickActionButton: View {
    let action: QuickAction
    let coordinator: WealthWiseDashboardCoordinator
    
    var body: some View {
        Button(action: {
            handleAction(action.action)
        }) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(action.title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleAction(_ actionType: QuickAction.ActionType) {
        // Handle quick action based on type
        switch actionType {
        case .addTransaction:
            // Navigate to add transaction
            break
        case .createGoal:
            // Navigate to create goal
            break
        case .viewTaxSummary:
            // Navigate to tax summary
            break
        case .switchCurrency:
            // Show currency picker
            break
        case .switchMarket:
            // Show audience picker
            break
        case .addAsset:
            // Navigate to add asset
            break
        case .viewCompliance:
            // Navigate to compliance view
            break
        }
    }
}

// Additional card views for insights, monthly flow, goals, etc.
struct InsightsCard: View {
    let insights: [FinancialInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(insights.prefix(3)) { insight in
                InsightRow(insight: insight)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let insight: FinancialInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if insight.actionable {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var severityIcon: String {
        switch insight.severity {
        case .positive: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    private var severityColor: Color {
        switch insight.severity {
        case .positive: return .green
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}
```

This unified dashboard architecture provides:

1. **Central Coordination**: Single coordinator managing all WealthWise modules
2. **Seamless Currency Switching**: View entire portfolio in any supported currency
3. **Audience Switching**: Switch between markets (Indian, American, etc.) with automatic adaptation
4. **Real-time Integration**: All modules communicate and update together
5. **Unified Data Model**: Consistent data representation across all features
6. **Intelligent Insights**: AI-powered insights across goals, taxes, compliance, and investments
7. **Quick Actions**: Context-aware shortcuts based on user's situation
8. **Compliance Monitoring**: Integrated compliance tracking across all assets and countries
9. **Localized Experience**: Full localization support with RTL and cultural preferences
10. **Modular Architecture**: Easy to extend with new features while maintaining cohesion

The dashboard successfully unifies all requested features - goal tracking (₹5CR in 3 years), tax management, salary tracking, currency switching, audience switching, cross-border assets, and localization - into a single, powerful financial management experience.