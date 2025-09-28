//
//  TransactionService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Transaction Management System: Core business logic service
//

import Foundation
import SwiftData
import Combine
import OSLog

/// Service for managing financial transactions with CRUD operations, validation, and analytics
@available(iOS 18.6, macOS 15.6, *)
@Observable
public final class TransactionService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let logger = Logger(subsystem: "com.wealthwise.app", category: "TransactionService")
    
    /// Published properties for reactive UI updates
    public private(set) var transactions: [Transaction] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: TransactionError?
    
    // Analytics properties
    public private(set) var totalBalance: Decimal = 0
    public private(set) var monthlyIncome: Decimal = 0
    public private(set) var monthlyExpenses: Decimal = 0
    public private(set) var transactionCount: Int = 0
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadTransactions()
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new transaction
    @MainActor
    public func createTransaction(_ transaction: Transaction) async throws {
        logger.info("Creating new transaction: \(transaction.transactionDescription)")
        
        do {
            // Validate transaction
            try validateTransaction(transaction)
            
            // Set creation timestamp
            transaction.createdAt = Date()
            transaction.updatedAt = Date()
            
            // Insert into context
            modelContext.insert(transaction)
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadTransactions()
            await updateAnalytics()
            
            logger.info("Transaction created successfully with ID: \(transaction.id)")
            
        } catch {
            logger.error("Failed to create transaction: \(error.localizedDescription)")
            self.error = TransactionError.creationFailed(error)
            throw error
        }
    }
    
    /// Update existing transaction
    @MainActor
    public func updateTransaction(_ transaction: Transaction) async throws {
        logger.info("Updating transaction: \(transaction.id)")
        
        do {
            // Validate transaction
            try validateTransaction(transaction)
            
            // Update modification timestamp
            transaction.updatedAt = Date()
            
            // Save changes
            try modelContext.save()
            
            // Update local state
            await loadTransactions()
            await updateAnalytics()
            
            logger.info("Transaction updated successfully")
            
        } catch {
            logger.error("Failed to update transaction: \(error.localizedDescription)")
            self.error = TransactionError.updateFailed(error)
            throw error
        }
    }
    
    /// Delete transaction
    @MainActor
    public func deleteTransaction(_ transaction: Transaction) async throws {
        logger.info("Deleting transaction: \(transaction.id)")
        
        do {
            modelContext.delete(transaction)
            try modelContext.save()
            
            // Update local state
            await loadTransactions()
            await updateAnalytics()
            
            logger.info("Transaction deleted successfully")
            
        } catch {
            logger.error("Failed to delete transaction: \(error.localizedDescription)")
            self.error = TransactionError.deletionFailed(error)
            throw error
        }
    }
    
    /// Delete multiple transactions
    @MainActor
    public func deleteTransactions(_ transactions: [Transaction]) async throws {
        logger.info("Deleting \(transactions.count) transactions")
        
        do {
            for transaction in transactions {
                modelContext.delete(transaction)
            }
            
            try modelContext.save()
            
            // Update local state
            await loadTransactions()
            await updateAnalytics()
            
            logger.info("Bulk deletion completed successfully")
            
        } catch {
            logger.error("Failed to delete transactions: \(error.localizedDescription)")
            self.error = TransactionError.bulkDeletionFailed(error)
            throw error
        }
    }
    
    // MARK: - Query Operations
    
    /// Load all transactions
    @MainActor
    public func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<Transaction>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            transactions = try modelContext.fetch(descriptor)
            transactionCount = transactions.count
            
          logger.info("Loaded \(self.transactions.count) transactions")
            
        } catch {
            logger.error("Failed to load transactions: \(error.localizedDescription)")
            self.error = TransactionError.loadingFailed(error)
        }
    }
    
    /// Search transactions by text
    @MainActor
    public func searchTransactions(query: String) async -> [Transaction] {
        guard !query.isEmpty else { return transactions }
        
        let lowercaseQuery = query.lowercased()
        
        return transactions.filter { transaction in
            transaction.transactionDescription.lowercased().contains(lowercaseQuery) ||
            transaction.notes?.lowercased().contains(lowercaseQuery) == true ||
            transaction.merchantName?.lowercased().contains(lowercaseQuery) == true ||
            transaction.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    /// Filter transactions by criteria
    @MainActor
    public func filterTransactions(
        type: TransactionType? = nil,
        category: TransactionCategory? = nil,
        dateRange: DateInterval? = nil,
        amountRange: ClosedRange<Decimal>? = nil,
        currency: String? = nil
    ) async -> [Transaction] {
        
        return transactions.filter { transaction in
            // Type filter
            if let type = type, transaction.transactionType != type {
                return false
            }
            
            // Category filter
            if let category = category, transaction.category != category {
                return false
            }
            
            // Date range filter
            if let dateRange = dateRange, !dateRange.contains(transaction.date) {
                return false
            }
            
            // Amount range filter
            if let amountRange = amountRange, !amountRange.contains(abs(transaction.amount)) {
                return false
            }
            
            // Currency filter
            if let currency = currency, transaction.currency != currency {
                return false
            }
            
            return true
        }
    }
    
    /// Get transactions for specific month
    @MainActor
    public func getTransactionsForMonth(_ date: Date) async -> [Transaction] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date
        
        return transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= endOfMonth
        }
    }
    
    /// Get recent transactions
    @MainActor
    public func getRecentTransactions(limit: Int = 10) async -> [Transaction] {
        return Array(transactions.prefix(limit))
    }
    
    // MARK: - Analytics
    
    /// Update analytics data
    @MainActor
    private func updateAnalytics() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let currentMonthTransactions = transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= endOfMonth
        }
        
        // Calculate monthly income and expenses
        monthlyIncome = currentMonthTransactions
            .filter { $0.isIncome }
            .reduce(0) { $0 + $1.baseCurrencyAmount }
        
        monthlyExpenses = currentMonthTransactions
            .filter { $0.isExpense }
            .reduce(0) { $0 + abs($1.baseCurrencyAmount) }
        
        // Calculate total balance (simplified - would typically query accounts)
        totalBalance = transactions.reduce(0) { total, transaction in
            switch transaction.transactionType {
            case .income:
                return total + transaction.baseCurrencyAmount
            case .expense:
                return total - abs(transaction.baseCurrencyAmount)
            case .transfer, .investment:
                return total // Transfers don't affect net worth, investments tracked separately
            case .refund, .dividend, .interest, .capital_gain:
                return total + transaction.baseCurrencyAmount // Positive income types
            case .capital_loss:
                return total - abs(transaction.baseCurrencyAmount) // Negative impact
            }
        }
        
      logger
        .info(
          "Analytics updated - Balance: \(self.totalBalance), Income: \(self.monthlyIncome), Expenses: \(self.monthlyExpenses)"
        )
    }
    
    /// Get spending by category for current month
    @MainActor
    public func getSpendingByCategory() async -> [CategorySpending] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        let currentMonthExpenses = transactions.filter { transaction in
            transaction.isExpense &&
            transaction.date >= startOfMonth &&
            transaction.date <= endOfMonth
        }
        
        let groupedByCategory = Dictionary(grouping: currentMonthExpenses) { $0.category }
        
        return groupedByCategory.map { category, transactions in
            let total = transactions.reduce(0) { $0 + abs($1.baseCurrencyAmount) }
            return CategorySpending(
                category: category,
                amount: total,
                transactionCount: transactions.count,
                percentage: monthlyExpenses > 0 ? Double(truncating: NSDecimalNumber(decimal: total / monthlyExpenses)) * 100 : 0
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Validation
    
    /// Validate transaction data
    private func validateTransaction(_ transaction: Transaction) throws {
        // Amount validation
        if transaction.amount == 0 {
            throw TransactionError.invalidAmount("Amount cannot be zero")
        }
        
        // Description validation
        if transaction.transactionDescription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            throw TransactionError.invalidDescription("Description cannot be empty")
        }
        
        // Date validation
        if transaction.date > Date().addingTimeInterval(86400) { // 1 day in future
            throw TransactionError.invalidDate("Transaction date cannot be more than 1 day in the future")
        }
        
        // Currency validation
        if transaction.currency.count != 3 {
            throw TransactionError.invalidCurrency("Currency code must be 3 characters")
        }
        
        logger.debug("Transaction validation passed")
    }
    
    // MARK: - Bulk Operations
    
    /// Update category for multiple transactions
    @MainActor
    public func updateCategoryForTransactions(
        _ transactions: [Transaction],
        category: TransactionCategory
    ) async throws {
        logger.info("Updating category for \(transactions.count) transactions")
        
        do {
            for transaction in transactions {
                transaction.category = category
                transaction.updatedAt = Date()
            }
            
            try modelContext.save()
            
            await loadTransactions()
            await updateAnalytics()
            
            logger.info("Bulk category update completed successfully")
            
        } catch {
            logger.error("Failed to update categories: \(error.localizedDescription)")
            self.error = TransactionError.bulkUpdateFailed(error)
            throw error
        }
    }
    
    /// Add tags to multiple transactions
    @MainActor
    public func addTagsToTransactions(
        _ transactions: [Transaction],
        tags: [String]
    ) async throws {
        logger.info("Adding tags to \(transactions.count) transactions")
        
        do {
            for transaction in transactions {
                let newTags = Set(transaction.tags + tags)
                transaction.tags = Array(newTags)
                transaction.updatedAt = Date()
            }
            
            try modelContext.save()
            
            await loadTransactions()
            
            logger.info("Bulk tag addition completed successfully")
            
        } catch {
            logger.error("Failed to add tags: \(error.localizedDescription)")
            self.error = TransactionError.bulkUpdateFailed(error)
            throw error
        }
    }
}

// MARK: - Supporting Models

/// Category spending analytics
public struct CategorySpending {
    public let category: TransactionCategory
    public let amount: Decimal
    public let transactionCount: Int
    public let percentage: Double
}

/// Transaction service errors
public enum TransactionError: LocalizedError, Sendable {
    case creationFailed(Error)
    case updateFailed(Error)
    case deletionFailed(Error)
    case bulkDeletionFailed(Error)
    case bulkUpdateFailed(Error)
    case loadingFailed(Error)
    case invalidAmount(String)
    case invalidDescription(String)
    case invalidDate(String)
    case invalidCurrency(String)
    case validationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .creationFailed(let error):
            return "Failed to create transaction: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update transaction: \(error.localizedDescription)"
        case .deletionFailed(let error):
            return "Failed to delete transaction: \(error.localizedDescription)"
        case .bulkDeletionFailed(let error):
            return "Failed to delete transactions: \(error.localizedDescription)"
        case .bulkUpdateFailed(let error):
            return "Failed to update transactions: \(error.localizedDescription)"
        case .loadingFailed(let error):
            return "Failed to load transactions: \(error.localizedDescription)"
        case .invalidAmount(let message),
             .invalidDescription(let message),
             .invalidDate(let message),
             .invalidCurrency(let message),
             .validationFailed(let message):
            return message
        }
    }
}
