//
//  AccountsViewModel.swift
//  WealthWise
//
//  Accounts view model with repository integration
//

import SwiftUI
import SwiftData

@MainActor
final class AccountsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var accounts: [Account] = []
    @Published var totalBalance: Decimal = 0
    @Published var activeAccountCount: Int = 0
    @Published var monthlyAverage: Decimal = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Repositories
    
    private let accountRepository: AccountRepository
    private let transactionRepository: TransactionRepository
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.accountRepository = AccountRepository(modelContext: modelContext)
        self.transactionRepository = TransactionRepository(modelContext: modelContext)
    }
    
    // MARK: - Data Loading
    
    func loadAccounts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load accounts from local storage
            accountRepository.fetchLocal()
            updateAccountData()
            
            // Sync with Firebase
            try await accountRepository.sync()
            updateAccountData()
            
            // Calculate monthly average
            await calculateMonthlyAverage()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadAccounts()
    }
    
    private func updateAccountData() {
        accounts = accountRepository.accounts.filter { !$0.isArchived }
        totalBalance = accountRepository.calculateTotalBalance()
        activeAccountCount = accounts.count
    }
    
    // MARK: - Calculations
    
    private func calculateMonthlyAverage() async {
        guard !accounts.isEmpty else {
            monthlyAverage = 0
            return
        }
        
        // Get last 6 months of transactions
        let calendar = Calendar.current
        let now = Date()
        guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) else {
            return
        }
        
        // Fetch transactions
        let recentTransactions = transactionRepository.fetchLocal(from: sixMonthsAgo, to: now)
        
        // Calculate average balance change per month
        let totalCredits = recentTransactions
            .filter { $0.type == .credit }
            .reduce(Decimal.zero) { $0 + $1.amount }
        
        let totalDebits = recentTransactions
            .filter { $0.type == .debit }
            .reduce(Decimal.zero) { $0 + $1.amount }
        
        let netChange = totalCredits - totalDebits
        monthlyAverage = netChange / 6
    }
    
    // MARK: - Account Operations
    
    func deleteAccount(_ account: Account) async {
        do {
            try await accountRepository.delete(account)
            updateAccountData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func archiveAccount(_ account: Account) async {
        do {
            try await accountRepository.archive(account)
            updateAccountData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Computed Properties
    
    var hasAccounts: Bool {
        !accounts.isEmpty
    }
    
    func accountsByType(_ type: AccountType) -> [Account] {
        accounts.filter { $0.type == type }
    }
    
    func accountBalance(_ account: Account) -> String {
        formatCurrency(account.currentBalance)
    }
    
    // MARK: - Formatting
    
    func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: amount as NSDecimalNumber) ?? "₹0.00"
    }
    
    func accountTypeIcon(_ type: AccountType) -> String {
        switch type {
        case .bank:
            return "building.columns.fill"
        case .creditCard:
            return "creditcard.fill"
        case .upi:
            return "indianrupeesign.circle.fill"
        case .brokerage:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    func accountTypeColor(_ type: AccountType) -> Color {
        switch type {
        case .bank:
            return .blue
        case .creditCard:
            return .purple
        case .upi:
            return .orange
        case .brokerage:
            return .green
        }
    }
}
