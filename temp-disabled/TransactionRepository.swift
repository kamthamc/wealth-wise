//
//  TransactionRepository.swift
//  WealthWise
//
//  Repository for managing transactions with offline-first architecture
//

import Foundation
import SwiftData

/// Repository managing transaction operations with offline-first pattern
/// Provides SwiftData local storage with Firebase Cloud Functions sync
@MainActor
final class TransactionRepository: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var transactions: [WebAppTransaction] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let firebaseService: FirebaseService
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, firebaseService: FirebaseService = .shared) {
        self.modelContext = modelContext
        self.firebaseService = firebaseService
    }
    
    // MARK: - Local Operations
    
    /// Fetch all transactions from local storage
    func fetchLocal() {
        let descriptor = FetchDescriptor<WebAppTransaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching local transactions: \(error)")
        }
    }
    
    /// Fetch transactions for specific account
    func fetchLocal(accountId: UUID) {
        let predicate = #Predicate<WebAppTransaction> { transaction in
            transaction.accountId == accountId
        }
        
        let descriptor = FetchDescriptor<WebAppTransaction>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching local transactions for account: \(error)")
        }
    }
    
    /// Fetch transactions by category
    func fetchLocal(category: String) {
        let predicate = #Predicate<WebAppTransaction> { transaction in
            transaction.category == category
        }
        
        let descriptor = FetchDescriptor<WebAppTransaction>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching local transactions by category: \(error)")
        }
    }
    
    /// Fetch transactions in date range
    func fetchLocal(from startDate: Date, to endDate: Date) {
        let predicate = #Predicate<WebAppTransaction> { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
        
        let descriptor = FetchDescriptor<WebAppTransaction>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching local transactions by date range: \(error)")
        }
    }
    
    // MARK: - Firebase Sync
    
    /// Sync transactions from Firebase to local storage
    func sync(accountId: String? = nil, startDate: Date? = nil, endDate: Date? = nil, category: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dtos = try await firebaseService.fetchTransactions(
                accountId: accountId,
                startDate: startDate,
                endDate: endDate,
                category: category
            )
            
            // Convert DTOs to SwiftData models and save locally
            for dto in dtos {
                let transaction = dto.toTransaction()
                modelContext.insert(transaction)
            }
            
            try modelContext.save()
            
            // Refresh local data
            fetchLocal()
            
        } catch {
            lastError = error
            throw error
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Create new transaction (saves locally and syncs to Firebase)
    func create(_ transaction: WebAppTransaction) async throws {
        // Save locally first (optimistic update)
        modelContext.insert(transaction)
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync to Firebase in background
        Task {
            do {
                let dto = try await firebaseService.createTransaction(
                    accountId: transaction.accountId.uuidString,
                    date: transaction.date,
                    amount: NSDecimalNumber(decimal: transaction.amount).doubleValue,
                    type: transaction.type.rawValue,
                    category: transaction.category,
                    description: transaction.description,
                    notes: transaction.notes
                )
                
                // Update local transaction with server data
                transaction.lastSyncedAt = Date()
                try modelContext.save()
                
            } catch {
                lastError = error
                print("Error syncing transaction to Firebase: \(error)")
            }
        }
    }
    
    /// Update existing transaction
    func update(_ transaction: WebAppTransaction) async throws {
        transaction.updatedAt = Date()
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync to Firebase
        Task {
            do {
                let updates: [String: Any] = [
                    "date": ISO8601DateFormatter().string(from: transaction.date),
                    "amount": NSDecimalNumber(decimal: transaction.amount).doubleValue,
                    "type": transaction.type.rawValue,
                    "category": transaction.category,
                    "description": transaction.description,
                    "notes": transaction.notes as Any
                ]
                
                _ = try await firebaseService.updateTransaction(
                    transactionId: transaction.id.uuidString,
                    updates: updates
                )
                
                transaction.lastSyncedAt = Date()
                try modelContext.save()
                
            } catch {
                lastError = error
                print("Error syncing transaction update to Firebase: \(error)")
            }
        }
    }
    
    /// Delete transaction
    func delete(_ transaction: WebAppTransaction) async throws {
        modelContext.delete(transaction)
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync deletion to Firebase
        Task {
            do {
                try await firebaseService.deleteTransaction(transaction.id.uuidString)
            } catch {
                lastError = error
                print("Error deleting transaction from Firebase: \(error)")
            }
        }
    }
    
    /// Bulk delete transactions
    func bulkDelete(_ transactions: [WebAppTransaction]) async throws {
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync bulk deletion to Firebase
        Task {
            do {
                let ids = transactions.map { $0.id.uuidString }
                try await firebaseService.bulkDeleteTransactions(ids)
            } catch {
                lastError = error
                print("Error bulk deleting transactions from Firebase: \(error)")
            }
        }
    }
    
    // MARK: - Statistics
    
    /// Calculate total for transactions
    func calculateTotal(for transactions: [WebAppTransaction]) -> Decimal {
        transactions.reduce(Decimal.zero) { $0 + $1.signedAmount }
    }
    
    /// Calculate total by category
    func calculateTotalByCategory() -> [String: Decimal] {
        var totals: [String: Decimal] = [:]
        
        for transaction in transactions {
            let current = totals[transaction.category] ?? Decimal.zero
            totals[transaction.category] = current + transaction.signedAmount
        }
        
        return totals
    }
    
    /// Get transactions grouped by month
    func transactionsByMonth() -> [Date: [WebAppTransaction]] {
        let calendar = Calendar.current
        var grouped: [Date: [WebAppTransaction]] = [:]
        
        for transaction in transactions {
            let components = calendar.dateComponents([.year, .month], from: transaction.date)
            guard let monthStart = calendar.date(from: components) else { continue }
            
            var monthTransactions = grouped[monthStart] ?? []
            monthTransactions.append(transaction)
            grouped[monthStart] = monthTransactions
        }
        
        return grouped
    }
    
    /// Get recent transactions (last 30 days)
    func recentTransactions(days: Int = 30) -> [WebAppTransaction] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        
        return transactions.filter { $0.date >= startDate }
    }
}
