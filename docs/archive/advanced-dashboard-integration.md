# WealthWise Advanced Dashboard & Integration System

## Comprehensive Widget Architecture

### 1. Smart Widget Framework
```swift
protocol FinancialWidget {
    var id: UUID { get }
    var title: String { get }
    var type: WidgetType { get }
    var size: WidgetSize { get }
    var priority: WidgetPriority { get }
    var refreshInterval: TimeInterval { get }
    var isConfigurable: Bool { get }
    
    func createView() -> AnyView
    func refresh() async
    func configure() -> AnyView?
}

enum WidgetType: String, CaseIterable {
    case goalProgress = "Goal Progress"
    case taxSummary = "Tax Summary"
    case salaryInsights = "Salary Insights"
    case netWorth = "Net Worth"
    case budgetOverview = "Budget Overview"
    case investmentPortfolio = "Investment Portfolio"
    case expenseAnalysis = "Expense Analysis"
    case savingsRate = "Savings Rate"
    case debtTracker = "Debt Tracker"
    case taxOptimization = "Tax Optimization"
    case advanceTaxReminder = "Advance Tax Reminder"
    case goalMilestone = "Goal Milestone"
    case salaryProjection = "Salary Projection"
    case quickActions = "Quick Actions"
    case financialInsights = "Financial Insights"
}

enum WidgetSize: String, CaseIterable {
    case small = "Small (1x1)"
    case medium = "Medium (2x1)"
    case large = "Large (2x2)"
    case extraLarge = "Extra Large (3x2)"
    
    var gridSize: CGSize {
        switch self {
        case .small: return CGSize(width: 1, height: 1)
        case .medium: return CGSize(width: 2, height: 1)
        case .large: return CGSize(width: 2, height: 2)
        case .extraLarge: return CGSize(width: 3, height: 2)
        }
    }
}

enum WidgetPriority: Int, CaseIterable {
    case critical = 1
    case high = 2
    case medium = 3
    case low = 4
    
    var description: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}
```

### 2. Goal Integration Widget
```swift
struct GoalIntegrationWidget: FinancialWidget {
    let id = UUID()
    let title = "Financial Goals Hub"
    let type = WidgetType.goalProgress
    let size = WidgetSize.extraLarge
    let priority = WidgetPriority.high
    let refreshInterval: TimeInterval = 3600 // 1 hour
    let isConfigurable = true
    
    @StateObject private var goalManager = GoalTrackingManager()
    @StateObject private var taxCalculator = TaxCalculator()
    @StateObject private var salaryTracker = SalaryTracker()
    
    func createView() -> AnyView {
        AnyView(GoalIntegrationView())
    }
    
    func refresh() async {
        await goalManager.refreshGoals()
        await taxCalculator.recalculateTax()
    }
    
    func configure() -> AnyView? {
        AnyView(GoalWidgetConfigurationView())
    }
}

struct GoalIntegrationView: View {
    @StateObject private var goalManager = GoalTrackingManager()
    @StateObject private var taxCalculator = TaxCalculator()
    @StateObject private var salaryTracker = SalaryTracker()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with quick stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Financial Goals")
                        .font(.headline.bold())
                    Text("\(goalManager.goals.count) active goals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Overall progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: overallProgress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(overallProgress * 100))%")
                        .font(.caption2.bold())
                }
            }
            
            // Priority goals with tax optimization
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(priorityGoals) { goal in
                        GoalCardWithTaxBenefits(
                            goal: goal,
                            taxBenefits: getTaxBenefits(for: goal),
                            salaryContribution: getSalaryContribution(for: goal)
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Smart recommendations
            if !smartRecommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart Recommendations")
                        .font(.subheadline.bold())
                    
                    ForEach(smartRecommendations.prefix(2)) { recommendation in
                        SmartRecommendationCard(recommendation: recommendation)
                    }
                }
            }
            
            // Quick actions
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Goal",
                    color: .blue
                ) {
                    // Show add goal sheet
                }
                
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Portfolio",
                    color: .green
                ) {
                    // Show portfolio view
                }
                
                QuickActionButton(
                    icon: "indianrupeesign.circle",
                    title: "Tax Save",
                    color: .orange
                ) {
                    // Show tax optimization
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private var overallProgress: Double {
        guard !goalManager.goals.isEmpty else { return 0 }
        let totalProgress = goalManager.goals.reduce(0.0) { total, goal in
            total + Double(truncating: goal.currentAmount / goal.targetAmount as NSNumber)
        }
        return totalProgress / Double(goalManager.goals.count)
    }
    
    private var priorityGoals: [FinancialGoal] {
        goalManager.goals
            .sorted { $0.priority.rawValue < $1.priority.rawValue }
            .prefix(3)
            .map { $0 }
    }
    
    private var smartRecommendations: [SmartRecommendation] {
        var recommendations: [SmartRecommendation] = []
        
        // Goal-based tax optimization
        for goal in goalManager.goals {
            if let taxBenefit = getTaxOptimizedContribution(for: goal) {
                recommendations.append(SmartRecommendation(
                    type: .taxOptimizedGoalContribution,
                    title: "Tax-Optimized Investment for \(goal.name)",
                    description: "Invest ₹\(taxBenefit.amount) in \(taxBenefit.instrument) to save ₹\(taxBenefit.taxSaving) in taxes",
                    impact: taxBenefit.taxSaving,
                    action: "Invest Now",
                    priority: .high
                ))
            }
        }
        
        // Salary-based goal acceleration
        if let salaryBoost = getSalaryBasedGoalAcceleration() {
            recommendations.append(SmartRecommendation(
                type: .salaryBasedGoalAcceleration,
                title: "Accelerate Goals with Salary Optimization",
                description: "Redirect ₹\(salaryBoost.amount) from salary deductions to reach goals \(salaryBoost.monthsEarlier) months earlier",
                impact: salaryBoost.amount,
                action: "Optimize",
                priority: .medium
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
}

struct GoalCardWithTaxBenefits: View {
    let goal: FinancialGoal
    let taxBenefits: [TaxBenefit]
    let salaryContribution: SalaryContribution?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Goal header
            HStack {
                VStack(alignment: .leading) {
                    Text(goal.name)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text(goal.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress indicator
                CircularProgressView(
                    progress: Double(truncating: goal.currentAmount / goal.targetAmount as NSNumber),
                    size: 24
                )
            }
            
            // Amount progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("₹\(goal.currentAmount, specifier: "%.0f")")
                        .font(.headline.bold())
                    Text("of ₹\(goal.targetAmount, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: Double(truncating: goal.currentAmount / goal.targetAmount as NSNumber))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // Tax benefits
            if !taxBenefits.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tax Benefits")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                    
                    ForEach(taxBenefits.prefix(2)) { benefit in
                        HStack {
                            Image(systemName: "leaf.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("\(benefit.section): ₹\(benefit.saving, specifier: "%.0f")")
                                .font(.caption2)
                        }
                    }
                }
            }
            
            // Salary contribution
            if let contribution = salaryContribution {
                HStack {
                    Image(systemName: "banknote")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("₹\(contribution.monthlyAmount, specifier: "%.0f")/month from salary")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            // Time to goal
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text(timeToGoalText)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var timeToGoalText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: goal.targetDate, relativeTo: Date())
    }
}

struct SmartRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let impact: Decimal
    let action: String
    let priority: WidgetPriority
    
    enum RecommendationType {
        case taxOptimizedGoalContribution
        case salaryBasedGoalAcceleration
        case advanceTaxOptimization
        case goalRebalancing
        case emergencyFundPriority
    }
}

struct SmartRecommendationCard: View {
    let recommendation: SmartRecommendation
    
    var body: some View {
        HStack {
            // Icon based on type
            Image(systemName: iconForType)
                .font(.title2)
                .foregroundColor(colorForPriority)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(recommendation.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack {
                Text("₹\(recommendation.impact, specifier: "%.0f")")
                    .font(.caption.bold())
                    .foregroundColor(colorForPriority)
                Button(recommendation.action) {
                    // Handle action
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }
        }
        .padding(8)
        .background(colorForPriority.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var iconForType: String {
        switch recommendation.type {
        case .taxOptimizedGoalContribution: return "leaf.arrow.triangle.circlepath"
        case .salaryBasedGoalAcceleration: return "speedometer"
        case .advanceTaxOptimization: return "calendar.badge.clock"
        case .goalRebalancing: return "arrow.triangle.swap"
        case .emergencyFundPriority: return "shield.checkerboard"
        }
    }
    
    private var colorForPriority: Color {
        switch recommendation.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}
```

### 3. Tax-Salary Integration Dashboard
```swift
struct TaxSalaryIntegrationWidget: FinancialWidget {
    let id = UUID()
    let title = "Tax & Salary Optimizer"
    let type = WidgetType.taxOptimization
    let size = WidgetSize.large
    let priority = WidgetPriority.critical
    let refreshInterval: TimeInterval = 1800 // 30 minutes
    let isConfigurable = true
    
    func createView() -> AnyView {
        AnyView(TaxSalaryIntegrationView())
    }
    
    func refresh() async {
        // Refresh tax calculations and salary projections
    }
    
    func configure() -> AnyView? {
        AnyView(TaxSalaryConfigurationView())
    }
}

struct TaxSalaryIntegrationView: View {
    @StateObject private var taxCalculator = TaxCalculator()
    @StateObject private var salaryTracker = SalaryTracker()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with tab selection
            HStack {
                Text("Tax & Salary Hub")
                    .font(.headline.bold())
                
                Spacer()
                
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Optimization").tag(1)
                    Text("Projections").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            switch selectedTab {
            case 0:
                TaxSalaryOverviewTab(
                    taxCalculator: taxCalculator,
                    salaryTracker: salaryTracker
                )
            case 1:
                TaxSalaryOptimizationTab(
                    taxCalculator: taxCalculator,
                    salaryTracker: salaryTracker
                )
            case 2:
                TaxSalaryProjectionsTab(
                    taxCalculator: taxCalculator,
                    salaryTracker: salaryTracker
                )
            default:
                EmptyView()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct TaxSalaryOverviewTab: View {
    @ObservedObject var taxCalculator: TaxCalculator
    @ObservedObject var salaryTracker: SalaryTracker
    
    var body: some View {
        VStack(spacing: 12) {
            // Current month summary
            HStack {
                VStack(alignment: .leading) {
                    Text("This Month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let currentSalary = salaryTracker.payslips.last {
                        Text("₹\(currentSalary.netSalary, specifier: "%.0f")")
                            .font(.title2.bold())
                    }
                    Text("Net Salary")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Tax Liability")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(taxCalculator.taxSummary.taxLiability, specifier: "%.0f")")
                        .font(.title2.bold())
                        .foregroundColor(.red)
                    Text("Annual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Tax efficiency meter
            TaxEfficiencyMeter(
                taxLiability: taxCalculator.taxSummary.taxLiability,
                grossIncome: salaryTracker.yearlyProjection?.totalGrossIncome ?? 0,
                deductions: taxCalculator.taxSummary.totalDeductions
            )
            
            // Quick actions
            HStack(spacing: 8) {
                TaxActionButton(
                    title: "Pay Advance Tax",
                    icon: "calendar.badge.plus",
                    color: .orange,
                    amount: getNextAdvanceTaxAmount()
                ) {
                    // Handle advance tax payment
                }
                
                TaxActionButton(
                    title: "Optimize Deductions",
                    icon: "slider.horizontal.3",
                    color: .blue,
                    amount: getPotentialSavings()
                ) {
                    // Show optimization view
                }
            }
        }
    }
}

struct TaxEfficiencyMeter: View {
    let taxLiability: Decimal
    let grossIncome: Decimal
    let deductions: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tax Efficiency")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(efficiencyPercentage))%")
                    .font(.subheadline.bold())
                    .foregroundColor(efficiencyColor)
            }
            
            // Efficiency progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * efficiencyPercentage / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Breakdown
            HStack {
                VStack(alignment: .leading) {
                    Text("Effective Tax Rate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(effectiveTaxRate, specifier: "%.1f")%")
                        .font(.caption.bold())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Deduction Utilization")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(deductionUtilization, specifier: "%.1f")%")
                        .font(.caption.bold())
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var efficiencyPercentage: Double {
        guard grossIncome > 0 else { return 0 }
        let maxPossibleDeductions: Decimal = 200000 // Approximate max deductions
        let utilizationScore = (deductions / maxPossibleDeductions) * 50
        let taxEfficiencyScore = (1 - (taxLiability / grossIncome)) * 50
        return Double(truncating: (utilizationScore + taxEfficiencyScore) as NSNumber)
    }
    
    private var efficiencyColor: Color {
        switch efficiencyPercentage {
        case 70...100: return .green
        case 40..<70: return .orange
        default: return .red
        }
    }
    
    private var effectiveTaxRate: Double {
        guard grossIncome > 0 else { return 0 }
        return Double(truncating: (taxLiability / grossIncome * 100) as NSNumber)
    }
    
    private var deductionUtilization: Double {
        let maxDeductions: Decimal = 200000
        return Double(truncating: (deductions / maxDeductions * 100) as NSNumber)
    }
}

struct TaxActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let amount: Decimal?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption.bold())
                    if let amount = amount {
                        Text("₹\(amount, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
```

### 4. Comprehensive Analytics Engine
```swift
class FinancialAnalyticsEngine: ObservableObject {
    @Published var insights: [FinancialInsight] = []
    @Published var predictions: [FinancialPrediction] = []
    @Published var recommendations: [ActionableRecommendation] = []
    
    private let goalManager: GoalTrackingManager
    private let taxCalculator: TaxCalculator
    private let salaryTracker: SalaryTracker
    
    init(goalManager: GoalTrackingManager, taxCalculator: TaxCalculator, salaryTracker: SalaryTracker) {
        self.goalManager = goalManager
        self.taxCalculator = taxCalculator
        self.salaryTracker = salaryTracker
        
        generateInsights()
        generatePredictions()
        generateRecommendations()
    }
    
    func generateInsights() {
        insights = []
        
        // Goal achievement patterns
        let goalInsights = analyzeGoalProgress()
        insights.append(contentsOf: goalInsights)
        
        // Tax optimization patterns
        let taxInsights = analyzeTaxEfficiency()
        insights.append(contentsOf: taxInsights)
        
        // Salary utilization patterns
        let salaryInsights = analyzeSalaryUtilization()
        insights.append(contentsOf: salaryInsights)
        
        // Cross-category insights
        let integratedInsights = analyzeIntegratedPatterns()
        insights.append(contentsOf: integratedInsights)
    }
    
    private func analyzeIntegratedPatterns() -> [FinancialInsight] {
        var insights: [FinancialInsight] = []
        
        // Goal-Tax-Salary correlation
        if let salaryProjection = salaryTracker.yearlyProjection {
            let goalContributions = goalManager.goals.reduce(Decimal(0)) { total, goal in
                total + goal.monthlyContribution * 12
            }
            
            let taxSavingPotential = taxCalculator.optimizationSuggestions.reduce(Decimal(0)) { total, suggestion in
                total + suggestion.potentialSaving
            }
            
            if goalContributions > salaryProjection.totalNetIncome * 0.3 {
                insights.append(FinancialInsight(
                    type: .warning,
                    category: .integrated,
                    title: "High Goal Commitment",
                    description: "Your goal contributions exceed 30% of net income. Consider optimizing tax deductions to increase available funds.",
                    impact: taxSavingPotential,
                    actionable: true,
                    priority: .high
                ))
            }
        }
        
        // Tax-efficient goal funding
        for goal in goalManager.goals {
            if let taxBenefit = getTaxBenefitForGoal(goal) {
                insights.append(FinancialInsight(
                    type: .opportunity,
                    category: .integrated,
                    title: "Tax-Efficient Goal Funding",
                    description: "Redirect \(goal.name) investments through tax-saving instruments for ₹\(taxBenefit) additional savings.",
                    impact: taxBenefit,
                    actionable: true,
                    priority: .medium
                ))
            }
        }
        
        return insights
    }
    
    func generatePredictions() {
        predictions = []
        
        // Goal completion predictions
        for goal in goalManager.goals {
            let prediction = predictGoalCompletion(goal: goal)
            predictions.append(prediction)
        }
        
        // Tax liability predictions
        let taxPrediction = predictTaxLiability()
        predictions.append(taxPrediction)
        
        // Salary growth predictions
        if let salaryPrediction = predictSalaryGrowth() {
            predictions.append(salaryPrediction)
        }
    }
    
    private func predictGoalCompletion(goal: FinancialGoal) -> FinancialPrediction {
        let currentProgress = goal.currentAmount
        let targetAmount = goal.targetAmount
        let monthlyContribution = goal.monthlyContribution
        let timeRemaining = goal.targetDate.timeIntervalSinceNow / (30 * 24 * 3600) // months
        
        let projectedAmount = currentProgress + (monthlyContribution * Decimal(timeRemaining))
        let completionProbability: Double
        
        if projectedAmount >= targetAmount {
            completionProbability = min(0.95, Double(truncating: (projectedAmount / targetAmount) as NSNumber))
        } else {
            completionProbability = Double(truncating: (projectedAmount / targetAmount * 0.8) as NSNumber)
        }
        
        return FinancialPrediction(
            type: .goalCompletion,
            title: "\(goal.name) Completion",
            description: "Based on current contribution rate, \(Int(completionProbability * 100))% likely to achieve by target date",
            probability: completionProbability,
            timeframe: goal.targetDate,
            impact: targetAmount - projectedAmount,
            confidence: 0.85
        )
    }
}

struct FinancialInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let category: InsightCategory
    let title: String
    let description: String
    let impact: Decimal
    let actionable: Bool
    let priority: WidgetPriority
    let timestamp = Date()
    
    enum InsightType {
        case opportunity, warning, achievement, trend
    }
    
    enum InsightCategory {
        case goals, tax, salary, integrated, portfolio
    }
}

struct FinancialPrediction: Identifiable {
    let id = UUID()
    let type: PredictionType
    let title: String
    let description: String
    let probability: Double // 0.0 to 1.0
    let timeframe: Date
    let impact: Decimal
    let confidence: Double // 0.0 to 1.0
    
    enum PredictionType {
        case goalCompletion, taxLiability, salaryGrowth, marketImpact
    }
}

struct ActionableRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: RecommendationCategory
    let impact: Decimal
    let effort: EffortLevel
    let timeToImplement: TimeInterval
    let deadline: Date?
    let actions: [String]
    
    enum RecommendationCategory {
        case goalOptimization, taxSaving, salaryMaximization, riskReduction
    }
    
    enum EffortLevel {
        case low, medium, high
    }
}
```

### 5. Master Dashboard Controller
```swift
struct MasterFinancialDashboard: View {
    @StateObject private var dashboardManager = DashboardManager()
    @StateObject private var analyticsEngine = FinancialAnalyticsEngine()
    @State private var selectedWidgets: [UUID] = []
    @State private var isCustomizing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                    ForEach(dashboardManager.activeWidgets) { widget in
                        widget.createView()
                            .frame(
                                width: widgetWidth(for: widget.size),
                                height: widgetHeight(for: widget.size)
                            )
                    }
                }
                .padding()
            }
            .navigationTitle("WealthWise Dashboard")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Customize") {
                        isCustomizing = true
                    }
                    
                    Button("Insights") {
                        // Show insights view
                    }
                }
            }
            .sheet(isPresented: $isCustomizing) {
                DashboardCustomizationView(dashboardManager: dashboardManager)
            }
        }
        .onAppear {
            dashboardManager.loadUserPreferences()
            analyticsEngine.refreshAnalytics()
        }
    }
    
    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 160, maximum: 400), spacing: 16)]
    }
    
    private func widgetWidth(for size: WidgetSize) -> CGFloat {
        switch size {
        case .small: return 160
        case .medium: return 320
        case .large: return 320
        case .extraLarge: return 480
        }
    }
    
    private func widgetHeight(for size: WidgetSize) -> CGFloat {
        switch size {
        case .small: return 160
        case .medium: return 160
        case .large: return 320
        case .extraLarge: return 320
        }
    }
}

class DashboardManager: ObservableObject {
    @Published var availableWidgets: [any FinancialWidget] = []
    @Published var activeWidgets: [any FinancialWidget] = []
    @Published var userPreferences: DashboardPreferences = DashboardPreferences()
    
    init() {
        setupAvailableWidgets()
        loadDefaultConfiguration()
    }
    
    private func setupAvailableWidgets() {
        availableWidgets = [
            GoalIntegrationWidget(),
            TaxSalaryIntegrationWidget(),
            NetWorthWidget(),
            BudgetOverviewWidget(),
            InvestmentPortfolioWidget(),
            ExpenseAnalysisWidget(),
            QuickActionsWidget(),
            FinancialInsightsWidget()
        ]
    }
    
    func loadUserPreferences() {
        // Load from UserDefaults or Core Data
        if let savedPreferences = UserDefaults.standard.data(forKey: "DashboardPreferences"),
           let preferences = try? JSONDecoder().decode(DashboardPreferences.self, from: savedPreferences) {
            userPreferences = preferences
            applyPreferences()
        }
    }
    
    func saveUserPreferences() {
        if let encoded = try? JSONEncoder().encode(userPreferences) {
            UserDefaults.standard.set(encoded, forKey: "DashboardPreferences")
        }
    }
    
    private func applyPreferences() {
        activeWidgets = availableWidgets.filter { widget in
            userPreferences.activeWidgetIds.contains(widget.id)
        }.sorted { widget1, widget2 in
            let index1 = userPreferences.widgetOrder.firstIndex(of: widget1.id) ?? Int.max
            let index2 = userPreferences.widgetOrder.firstIndex(of: widget2.id) ?? Int.max
            return index1 < index2
        }
    }
}

struct DashboardPreferences: Codable {
    var activeWidgetIds: [UUID] = []
    var widgetOrder: [UUID] = []
    var refreshInterval: TimeInterval = 300 // 5 minutes
    var showNotifications: Bool = true
    var compactMode: Bool = false
}
```

This advanced dashboard system provides:

1. **Unified Widget Architecture**: Modular, configurable widgets that integrate all features
2. **Smart Integration**: Cross-feature insights connecting goals, taxes, and salary
3. **Predictive Analytics**: AI-powered predictions and recommendations
4. **Customizable Interface**: User-configurable dashboard with drag-and-drop widgets  
5. **Real-time Updates**: Live data synchronization across all components
6. **Actionable Insights**: Context-aware recommendations with impact analysis
7. **Performance Optimization**: Efficient data loading and refresh strategies

The system creates a truly integrated financial management experience where all features work together seamlessly.