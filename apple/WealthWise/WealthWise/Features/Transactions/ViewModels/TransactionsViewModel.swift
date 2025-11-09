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
    
    /// Advanced filter (if set, overrides basic filter)
    @Published var advancedFilter: TransactionFilter?
    
    // MARK: - Filter Types
    
    enum TransactionFilter {
        case all, income, expense
    }
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Data Loading
    
    func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load from SwiftData
            let descriptor = FetchDescriptor<WebAppTransaction>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            transactions = try modelContext.fetch(descriptor)
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
        // Use advanced filter if set, otherwise use basic filter
        if let advancedFilter = advancedFilter {
            applyAdvancedFilter(advancedFilter)
        } else {
            applyBasicFilter()
        }
    }
    
    /// Apply advanced filter with all criteria
    func applyAdvancedFilter(_ filter: TransactionFilter) {
        var result = transactions
        
        // 1. Date Range Filter
        if let dateRange = filter.dateRange.dateRange {
            result = result.filter { transaction in
                transaction.date >= dateRange.start && transaction.date < dateRange.end
            }
        }
        
        // 2. Amount Range Filter
        if let amountRange = filter.amountRange {
            if let min = amountRange.minimum {
                result = result.filter { $0.amount >= min }
            }
            if let max = amountRange.maximum {
                result = result.filter { $0.amount <= max }
            }
        }
        
        // 3. Category Filter
        if !filter.categories.isEmpty {
            result = result.filter { filter.categories.contains($0.category) }
        }
        
        // 4. Account Filter
        if !filter.accountIds.isEmpty {
            result = result.filter { filter.accountIds.contains($0.accountId) }
        }
        
        // 5. Transaction Type Filter
        if !filter.transactionTypes.isEmpty {
            result = result.filter { filter.transactionTypes.contains($0.type) }
        }
        
        // 6. Search Text Filter
        if !filter.searchText.isEmpty {
            let searchLower = filter.searchText.lowercased()
            result = result.filter { transaction in
                transaction.transactionDescription.lowercased().contains(searchLower) ||
                transaction.category.lowercased().contains(searchLower) ||
                (transaction.notes?.lowercased().contains(searchLower) ?? false)
            }
        }
        
        // Sort by date (newest first)
        result.sort { $0.date > $1.date }
        
        filteredTransactions = result
    }
    
    /// Apply basic filter (income/expense/all)
    private func applyBasicFilter() {
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
                transaction.transactionDescription.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText) ||
                (transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort by date (newest first)
        result.sort { $0.date > $1.date }
        
        filteredTransactions = result
    }
    
    /// Set advanced filter and apply it
    func setAdvancedFilter(_ filter: TransactionFilter?) {
        self.advancedFilter = filter
        applyFilters()
    }
    
    /// Clear advanced filter and return to basic filtering
    func clearAdvancedFilter() {
        self.advancedFilter = nil
        applyFilters()
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
            modelContext.delete(transaction)
            try modelContext.save()
            await loadTransactions()
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
        // Fetch account from SwiftData
        let descriptor = FetchDescriptor<WebAppAccount>(
            predicate: #Predicate { $0.id == transaction.accountId }
        )
        guard let account = try? modelContext.fetch(descriptor).first else {
            return NSLocalizedString("unknown_account", comment: "Unknown Account")
        }
        return account.name
    }
}
