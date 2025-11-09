//
//  DashboardViewModel.swift
//  WealthWise
//
//  Dashboard view model with repository integration
//

import SwiftUI
import SwiftData

@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var totalBalance: Decimal = 0
    @Published var monthlyIncome: Decimal = 0
    @Published var monthlyExpenses: Decimal = 0
    @Published var recentTransactions: [WebAppTransaction] = []
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Repositories
    
    private let accountRepository: AccountRepository
    private let transactionRepository: TransactionRepository
    private let budgetRepository: BudgetRepository
    private let goalRepository: GoalRepository
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.accountRepository = AccountRepository(modelContext: modelContext)
        self.transactionRepository = TransactionRepository(modelContext: modelContext)
        self.budgetRepository = BudgetRepository(modelContext: modelContext)
        self.goalRepository = GoalRepository(modelContext: modelContext)
    }
    
    // MARK: - Data Loading
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load accounts and calculate total balance
            accountRepository.fetchLocal()
            accounts = accountRepository.accounts
            totalBalance = accountRepository.calculateTotalBalance()
            
            // Sync accounts from Firebase
            try await accountRepository.sync()
            accounts = accountRepository.accounts
            totalBalance = accountRepository.calculateTotalBalance()
            
            // Load recent transactions
            transactionRepository.fetchLocal()
            recentTransactions = transactionRepository.recentTransactions(days: 7)
            
            // Sync transactions from Firebase
            try await transactionRepository.sync()
            recentTransactions = transactionRepository.recentTransactions(days: 7)
            
            // Calculate monthly income and expenses
            calculateMonthlyTotals()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
    
    // MARK: - Calculations
    
    private func calculateMonthlyTotals() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get first day of current month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return
        }
        
        // Get first day of next month
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return
        }
        
        // Get this month's transactions
        let monthTransactions = transactionRepository.fetchLocal(from: startOfMonth, to: endOfMonth)
        
        // Calculate income (credit transactions)
        monthlyIncome = monthTransactions
            .filter { $0.type == .credit }
            .reduce(Decimal.zero) { $0 + $1.amount }
        
        // Calculate expenses (debit transactions)
        monthlyExpenses = monthTransactions
            .filter { $0.type == .debit }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    // MARK: - Computed Properties
    
    var accountCount: Int {
        accounts.filter { !$0.isArchived }.count
    }
    
    var netIncome: Decimal {
        monthlyIncome - monthlyExpenses
    }
    
    var hasData: Bool {
        !accounts.isEmpty || !recentTransactions.isEmpty
    }
    
    // MARK: - Formatting
    
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: amount as NSDecimalNumber) ?? "₹0.00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    // MARK: - Quick Actions
    
    func canAddTransaction() -> Bool {
        !accounts.isEmpty
    }
}
