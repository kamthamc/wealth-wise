//
//  BudgetsViewModel.swift
//  WealthWise
//
//  Budgets view model with spending analysis
//

import SwiftUI
import SwiftData

@MainActor
final class BudgetsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var budgets: [Budget] = []
    @Published var totalBudgeted: Decimal = 0
    @Published var totalSpent: Decimal = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Repositories
    
    private let budgetRepository: BudgetRepository
    private let transactionRepository: TransactionRepository
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.budgetRepository = BudgetRepository(modelContext: modelContext)
        self.transactionRepository = TransactionRepository(modelContext: modelContext)
    }
    
    // MARK: - Data Loading
    
    func loadBudgets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load from local storage
            budgetRepository.fetchLocal()
            updateBudgetData()
            
            // Sync with Firebase
            try await budgetRepository.sync()
            updateBudgetData()
            
            // Update spending for each budget
            await updateAllBudgetSpending()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadBudgets()
    }
    
    private func updateBudgetData() {
        budgets = budgetRepository.budgets
        totalBudgeted = budgetRepository.totalBudgetedAmount()
        totalSpent = budgetRepository.totalSpent()
    }
    
    private func updateAllBudgetSpending() async {
        for budget in budgets {
            let transactions = transactionRepository.fetchLocal(
                from: budget.startDate,
                to: budget.endDate
            ).filter { budget.categories.contains($0.category) }
            
            _ = budgetRepository.calculateSpending(for: budget, transactions: transactions)
        }
        updateBudgetData()
    }
    
    // MARK: - Budget Operations
    
    func deleteBudget(_ budget: Budget) async {
        do {
            try await budgetRepository.delete(budget)
            updateBudgetData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Computed Properties
    
    var hasBudgets: Bool {
        !budgets.isEmpty
    }
    
    var totalSpentPercentage: Double {
        guard totalBudgeted > 0 else { return 0 }
        return Double(truncating: (totalSpent / totalBudgeted) as NSDecimalNumber)
    }
    
    var overBudgetCount: Int {
        budgetRepository.overBudgetBudgets().count
    }
    
    var nearLimitCount: Int {
        budgetRepository.nearLimitBudgets().count
    }
    
    // MARK: - Budget Analysis
    
    func spentPercentage(for budget: Budget) -> Double {
        guard budget.amount > 0 else { return 0 }
        return Double(truncating: (budget.currentSpent / budget.amount) as NSDecimalNumber)
    }
    
    func remainingAmount(for budget: Budget) -> Decimal {
        max(budget.amount - budget.currentSpent, 0)
    }
    
    func isOverBudget(_ budget: Budget) -> Bool {
        budget.currentSpent > budget.amount
    }
    
    func isNearLimit(_ budget: Budget) -> Bool {
        let percentage = spentPercentage(for: budget)
        return percentage >= 0.8 && percentage < 1.0
    }
    
    func budgetStatus(_ budget: Budget) -> BudgetStatus {
        if isOverBudget(budget) {
            return .overBudget
        } else if isNearLimit(budget) {
            return .nearLimit
        } else {
            return .onTrack
        }
    }
    
    enum BudgetStatus {
        case onTrack, nearLimit, overBudget
        
        var color: Color {
            switch self {
            case .onTrack: return .green
            case .nearLimit: return .orange
            case .overBudget: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .onTrack: return "checkmark.circle.fill"
            case .nearLimit: return "exclamationmark.triangle.fill"
            case .overBudget: return "xmark.circle.fill"
            }
        }
    }
    
    // MARK: - Formatting
    
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: amount as NSDecimalNumber) ?? "₹0.00"
    }
    
    func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    func budgetPeriodText(_ period: BudgetPeriod) -> String {
        switch period {
        case .monthly:
            return NSLocalizedString("monthly", comment: "Monthly")
        case .quarterly:
            return NSLocalizedString("quarterly", comment: "Quarterly")
        case .yearly:
            return NSLocalizedString("yearly", comment: "Yearly")
        }
    }
}
