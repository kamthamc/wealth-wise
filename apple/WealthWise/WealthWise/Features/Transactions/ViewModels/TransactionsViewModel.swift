//
//  TransactionsViewModel.swift
//  WealthWise
//
//  Transactions view model with filtering and search
//

import SwiftUI
import SwiftData

@MainActor
final class TransactionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var transactions: [WebAppTransaction] = []
    @Published var filteredTransactions: [WebAppTransaction] = []
    @Published var selectedFilter: TransactionFilter = .all
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Filter Types
    
    enum TransactionFilter {
        case all, income, expense
    }
    
    // MARK: - Repositories
    
    private let transactionRepository: TransactionRepository
    private let accountRepository: AccountRepository
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.transactionRepository = TransactionRepository(modelContext: modelContext)
        self.accountRepository = AccountRepository(modelContext: modelContext)
    }
    
    // MARK: - Data Loading
    
    func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load from local storage
            transactionRepository.fetchLocal()
            transactions = transactionRepository.transactions
            applyFilters()
            
            // Sync with Firebase
            try await transactionRepository.sync()
            transactions = transactionRepository.transactions
            applyFilters()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadTransactions()
    }
    
    // MARK: - Filtering
    
    func applyFilters() {
        var result = transactions
        
        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .income:
            result = result.filter { $0.type == .credit }
        case .expense:
            result = result.filter { $0.type == .debit }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.description.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText) ||
                (transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort by date (newest first)
        result.sort { $0.date > $1.date }
        
        filteredTransactions = result
    }
    
    func setFilter(_ filter: TransactionFilter) {
        selectedFilter = filter
        applyFilters()
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        applyFilters()
    }
    
    // MARK: - Transaction Operations
    
    func deleteTransaction(_ transaction: WebAppTransaction) async {
        do {
            try await transactionRepository.delete(transaction)
            transactions = transactionRepository.transactions
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Computed Properties
    
    var hasTransactions: Bool {
        !transactions.isEmpty
    }
    
    var totalIncome: Decimal {
        transactions
            .filter { $0.type == .credit }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    var totalExpense: Decimal {
        transactions
            .filter { $0.type == .debit }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    // MARK: - Grouping
    
    func transactionsByDate() -> [(Date, [WebAppTransaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        return grouped.sorted { $0.key > $1.key }
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
    
    func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return NSLocalizedString("today", comment: "Today")
        } else if calendar.isDateInYesterday(date) {
            return NSLocalizedString("yesterday", comment: "Yesterday")
        } else {
            return formatDate(date)
        }
    }
    
    // MARK: - Account Info
    
    func accountName(for transaction: WebAppTransaction) -> String {
        accountRepository.accounts.first { $0.id == transaction.accountId }?.name ?? "Unknown"
    }
}
