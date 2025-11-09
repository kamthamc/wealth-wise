//
//  AnalyticsView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Comprehensive analytics dashboard with charts and insights
//

import SwiftUI
import SwiftData

@available(iOS 18, macOS 15, *)
struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @StateObject private var transactionsViewModel: TransactionsViewModel
    @StateObject private var budgetsViewModel: BudgetsViewModel
    @StateObject private var goalsViewModel: GoalsViewModel
    
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var isLoading = true
    
    // Computed property for adaptive layout
    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    private var gridColumns: [GridItem] {
        if isCompactLayout {
            // iPhone/compact: 1 column
            return [GridItem(.flexible())]
        } else {
            // iPad/Mac: 2 columns
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }
    
    enum TimePeriod: String, CaseIterable {
        case thisMonth = "This Month"
        case last3Months = "3 Months"
        case last6Months = "6 Months"
        case thisYear = "This Year"
        
        var months: Int {
            switch self {
            case .thisMonth: return 1
            case .last3Months: return 3
            case .last6Months: return 6
            case .thisYear: return 12
            }
        }
    }
    
    init() {
        let context = ModelContext(ModelContainer.shared)
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModel(modelContext: context))
        _budgetsViewModel = StateObject(wrappedValue: BudgetsViewModel(modelContext: context))
        _goalsViewModel = StateObject(wrappedValue: GoalsViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period selector
                    periodSelector
                    
                    // Financial health card
                    financialHealthCard
                    
                    // Charts in adaptive grid
                    LazyVGrid(columns: gridColumns, spacing: 20) {
                        // Income vs Expense trend
                        WealthCardView.prominent {
                            IncomeExpenseTrendChartView(
                                data: incomeExpenseTrendData,
                                selectedPeriod: selectedPeriod.months
                            )
                        }
                        
                        // Category breakdown
                        WealthCardView.prominent {
                            ExpenseCategoryChartView(
                                data: categoryExpenseData,
                                totalExpense: totalExpenses
                            )
                        }
                        
                        // Category comparison
                        WealthCardView.prominent {
                            CategoryComparisonChartView(
                                data: categoryComparisonData,
                                comparisonType: .thisVsLastMonth
                            )
                        }
                        
                        // Monthly comparison
                        WealthCardView.prominent {
                            MonthlyComparisonChartView(
                                data: monthlyComparisonData
                            )
                        }
                    }                    // Budget adherence
                    budgetAdherenceSection
                    
                    // Goal progress
                    goalProgressSection
                    
                    // Spending patterns
                    spendingPatternsSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .alert(
                NSLocalizedString("error", comment: "Error"),
                isPresented: Binding(
                    get: { transactionsViewModel.errorMessage != nil || budgetsViewModel.errorMessage != nil || goalsViewModel.errorMessage != nil },
                    set: { if !$0 { 
                        transactionsViewModel.errorMessage = nil
                        budgetsViewModel.errorMessage = nil
                        goalsViewModel.errorMessage = nil
                    } }
                )
            ) {
                Button(NSLocalizedString("ok", comment: "OK")) {
                    transactionsViewModel.errorMessage = nil
                    budgetsViewModel.errorMessage = nil
                    goalsViewModel.errorMessage = nil
                }
            } message: {
                Text(
                    transactionsViewModel.errorMessage 
                    ?? budgetsViewModel.errorMessage 
                    ?? goalsViewModel.errorMessage 
                    ?? NSLocalizedString("unknown_error", comment: "An unknown error occurred")
                )
            }
        }
    }
    
    // MARK: - Period Selector
    
    @ViewBuilder
    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadData()
            }
        }
    }
    
    // MARK: - Financial Health Card
    
    @ViewBuilder
    private var financialHealthCard: some View {
        WealthCardView.prominent {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Financial Health Score")
                            .font(.headline)
                        Text("Based on savings rate, budget adherence, and goal progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                
                HStack(spacing: 40) {
                    // Score ring
                    ProgressRingView(
                        progress: financialHealthScore / 100,
                        color: scoreColor,
                        lineWidth: 16,
                        size: 140
                    )
                    
                    // Score breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        scoreItem(
                            title: "Savings Rate",
                            value: savingsRate,
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )
                        
                        scoreItem(
                            title: "Budget Adherence",
                            value: budgetAdherence,
                            icon: "chart.pie.fill",
                            color: .blue
                        )
                        
                        scoreItem(
                            title: "Goal Progress",
                            value: goalProgress,
                            icon: "target",
                            color: .orange
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func scoreItem(title: String, value: Double, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            ProgressView(value: value / 100)
                .tint(color)
                .frame(width: 80)
            Text("\(Int(value))%")
                .font(.caption.bold())
                .foregroundStyle(color)
                .frame(width: 35, alignment: .trailing)
        }
    }
    
    // MARK: - Budget Adherence
    
    @ViewBuilder
    private var budgetAdherenceSection: some View {
        WealthCardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Budget Adherence")
                    .font(.headline)
                
                if budgetsViewModel.budgets.isEmpty {
                    Text("No active budgets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(budgetsViewModel.budgets.prefix(5)) { budget in
                        budgetRow(budget)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func budgetRow(_ budget: Budget) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(budget.progressPercentage))%")
                    .font(.caption.bold())
                    .foregroundStyle(budget.isOverBudget ? .red : .blue)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(budget.isOverBudget ? Color.red : Color.blue)
                        .frame(
                            width: geometry.size.width * CGFloat(min(budget.progressPercentage / 100, 1.0)),
                            height: 6
                        )
                        .clipShape(Capsule())
                }
            }
            .frame(height: 6)
            
            HStack {
                Text(formatCurrency(budget.currentSpent))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("of")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCurrency(budget.amount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if budget.isOverBudget {
                    Text("Over by \(formatCurrency(abs(budget.remaining)))")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Goal Progress
    
    @ViewBuilder
    private var goalProgressSection: some View {
        WealthCardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Goal Progress")
                    .font(.headline)
                
                if goalsViewModel.activeGoals.isEmpty {
                    Text("No active goals")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(goalsViewModel.activeGoals.prefix(5)) { goal in
                        goalRow(goal)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func goalRow(_ goal: WebAppGoal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(goal.progressPercentage))%")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(
                            width: geometry.size.width * CGFloat(min(goal.progressPercentage / 100, 1.0)),
                            height: 6
                        )
                        .clipShape(Capsule())
                }
            }
            .frame(height: 6)
            
            HStack {
                Text(formatCurrency(goal.currentAmount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("of")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatCurrency(goal.targetAmount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Due \(goal.targetDate, style: .date)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Spending Patterns
    
    @ViewBuilder
    private var spendingPatternsSection: some View {
        WealthCardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Spending Patterns")
                    .font(.headline)
                
                PatternRow(
                    icon: "calendar",
                    title: "Most Active Day",
                    value: mostActiveDay,
                    color: .purple
                )
                
                PatternRow(
                    icon: "tag.fill",
                    title: "Top Category",
                    value: topCategory,
                    color: .red
                )
                
                PatternRow(
                    icon: "arrow.up.arrow.down",
                    title: "Avg. Transaction",
                    value: formatCurrency(averageTransaction),
                    color: .blue
                )
                
                PatternRow(
                    icon: "number",
                    title: "Total Transactions",
                    value: "\(totalTransactions)",
                    color: .green
                )
            }
        }
    }
    
    @ViewBuilder
    private func PatternRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .frame(width: 140, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        isLoading = true
        
        await transactionsViewModel.loadTransactions()
        await budgetsViewModel.loadBudgets()
        await goalsViewModel.loadGoals()
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    private var trendDateRange: IncomeExpenseTrendChartView.DateRange {
        switch selectedPeriod {
        case .thisMonth, .last3Months: return .threeMonths
        case .last6Months: return .sixMonths
        case .thisYear: return .oneYear
        }
    }
    
    private var monthlyTrendData: [IncomeExpenseTrendChartView.MonthlyData] {
        let calendar = Calendar.current
        var data: [IncomeExpenseTrendChartView.MonthlyData] = []
        
        for monthOffset in (0..<selectedPeriod.months).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) else { continue }
            
            let income = calculateIncome(for: monthStart)
            let expense = calculateExpense(for: monthStart)
            
            data.append(IncomeExpenseTrendChartView.MonthlyData(
                month: monthStart,
                income: income,
                expense: expense
            ))
        }
        
        return data
    }
    
    private var categoryExpenseData: [ExpenseCategoryChartView.CategoryExpense] {
        let expenses = transactionsViewModel.transactions.filter { $0.type == .debit }
        var categoryTotals: [String: Decimal] = [:]
        
        for transaction in expenses {
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }
        
        let colors: [Color] = [.red, .orange, .purple, .blue, .green, .pink, .indigo, .mint]
        
        return categoryTotals.map { category, amount in
            ExpenseCategoryChartView.CategoryExpense(
                category: category,
                amount: amount,
                color: colors[abs(category.hashValue) % colors.count]
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private var categoryComparisonData: [CategoryComparisonChartView.CategoryData] {
        // Simplified for preview - would calculate current vs previous month
        []
    }
    
    private var monthlyComparisonData: [MonthlyComparisonChartView.MonthData] {
        let calendar = Calendar.current
        var data: [MonthlyComparisonChartView.MonthData] = []
        
        for monthOffset in (0..<6).reversed() {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: Date()) else { continue }
            
            let income = calculateIncome(for: monthStart)
            let expense = calculateExpense(for: monthStart)
            
            data.append(MonthlyComparisonChartView.MonthData(
                month: monthStart,
                income: income,
                expense: expense,
                savings: income - expense
            ))
        }
        
        return data
    }
    
    private var financialHealthScore: Double {
        (savingsRate + budgetAdherence + goalProgress) / 3
    }
    
    private var scoreColor: Color {
        switch financialHealthScore {
        case 0..<40: return .red
        case 40..<60: return .orange
        case 60..<80: return .blue
        default: return .green
        }
    }
    
    private var savingsRate: Double {
        let income = totalIncome
        guard income > 0 else { return 0 }
        return Double(truncating: ((income - totalExpenses) / income * 100) as NSNumber)
    }
    
    private var budgetAdherence: Double {
        let budgets = budgetsViewModel.budgets
        guard !budgets.isEmpty else { return 100 }
        
        let totalAdherence = budgets.reduce(0.0) { total, budget in
            total + (budget.isOverBudget ? 0 : min(100, budget.progressPercentage))
        }
        
        return totalAdherence / Double(budgets.count)
    }
    
    private var goalProgress: Double {
        let goals = goalsViewModel.activeGoals
        guard !goals.isEmpty else { return 0 }
        
        let totalProgress = goals.reduce(0.0) { $0 + $1.progressPercentage }
        return totalProgress / Double(goals.count)
    }
    
    private var totalIncome: Decimal {
        transactionsViewModel.transactions
            .filter { $0.type == .credit }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    private var totalExpenses: Decimal {
        transactionsViewModel.transactions
            .filter { $0.type == .debit }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    private var mostActiveDay: String {
        "Monday" // Simplified - would calculate from actual data
    }
    
    private var topCategory: String {
        categoryExpenseData.first?.category ?? "N/A"
    }
    
    private var averageTransaction: Decimal {
        let count = transactionsViewModel.transactions.count
        guard count > 0 else { return 0 }
        let total = transactionsViewModel.transactions.reduce(Decimal(0)) { $0 + $1.amount }
        return total / Decimal(count)
    }
    
    private var totalTransactions: Int {
        transactionsViewModel.transactions.count
    }
    
    // MARK: - Helper Methods
    
    private func calculateIncome(for month: Date) -> Decimal {
        let calendar = Calendar.current
        let monthRange = calendar.date(byAdding: .month, value: 1, to: month)!
        
        return transactionsViewModel.transactions
            .filter { $0.type == .credit && $0.date >= month && $0.date < monthRange }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    private func calculateExpense(for month: Date) -> Decimal {
        let calendar = Calendar.current
        let monthRange = calendar.date(byAdding: .month, value: 1, to: month)!
        
        return transactionsViewModel.transactions
            .filter { $0.type == .debit && $0.date >= month && $0.date < monthRange }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "₹0"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Analytics") {
    AnalyticsView()
}
#endif
