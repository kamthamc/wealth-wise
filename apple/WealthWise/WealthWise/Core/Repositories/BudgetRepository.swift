//
//  BudgetRepository.swift
//  WealthWise
//
//  Repository for managing budgets with offline-first architecture
//

import Foundation
import SwiftData

/// Repository managing budget operations with offline-first pattern
/// Provides SwiftData local storage with Firebase Cloud Functions sync
@MainActor
final class BudgetRepository: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var budgets: [Budget] = []
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
    
    /// Fetch all budgets from local storage
    func fetchLocal() {
        let descriptor = FetchDescriptor<Budget>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            budgets = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching local budgets: \(error)")
        }
    }
    
    /// Fetch active budgets (current date within budget period)
    func fetchActiveBudgets() {
        let now = Date()
        let predicate = #Predicate<Budget> { budget in
            budget.startDate <= now && budget.endDate >= now
        }
        
        let descriptor = FetchDescriptor<Budget>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            budgets = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching active budgets: \(error)")
        }
    }
    
    /// Fetch budgets by period
    func fetchLocal(period: BudgetPeriod) {
        let predicate = #Predicate<Budget> { budget in
            budget.period == period
        }
        
        let descriptor = FetchDescriptor<Budget>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            budgets = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching budgets by period: \(error)")
        }
    }
    
    // MARK: - Firebase Sync
    
    /// Sync budgets from Firebase to local storage
    func sync() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dtos = try await firebaseService.fetchBudgets()
            
            // Convert DTOs to SwiftData models and save locally
            for dto in dtos {
                let budget = dto.toBudget()
                modelContext.insert(budget)
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
    
    /// Create new budget (saves locally and syncs to Firebase)
    func create(_ budget: Budget) async throws {
        // Save locally first (optimistic update)
        modelContext.insert(budget)
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync to Firebase
        Task {
            do {
                let dto = try await firebaseService.createOrUpdateBudget(
                    budgetId: nil,
                    name: budget.name,
                    amount: NSDecimalNumber(decimal: budget.amount).doubleValue,
                    period: budget.period.rawValue,
                    categories: budget.categories,
                    startDate: budget.startDate
                )
                
                // Update local budget with server data
                budget.lastSyncedAt = Date()
                try modelContext.save()
                
            } catch {
                lastError = error
                print("Error syncing budget to Firebase: \(error)")
            }
        }
    }
    
    /// Update existing budget
    func update(_ budget: Budget) async throws {
        budget.updatedAt = Date()
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync to Firebase using createOrUpdateBudget
        Task {
            do {
                _ = try await firebaseService.createOrUpdateBudget(
                    budgetId: budget.id.uuidString,
                    name: budget.name,
                    amount: NSDecimalNumber(decimal: budget.amount).doubleValue,
                    period: budget.period.rawValue,
                    categories: budget.categories,
                    startDate: budget.startDate
                )
                
                budget.lastSyncedAt = Date()
                try modelContext.save()
                
            } catch {
                lastError = error
                print("Error syncing budget update to Firebase: \(error)")
            }
        }
    }
    
    /// Delete budget
    func delete(_ budget: Budget) async throws {
        modelContext.delete(budget)
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync deletion to Firebase
        Task {
            do {
                try await firebaseService.deleteBudget(budget.id.uuidString)
            } catch {
                lastError = error
                print("Error deleting budget from Firebase: \(error)")
            }
        }
    }
    
    // MARK: - Budget Analysis
    
    /// Calculate spending for budget
    func calculateSpending(for budget: Budget, transactions: [WebAppTransaction]) {
        budget.calculateSpent(from: transactions)
        try? modelContext.save()
    }
    
    /// Generate budget report from Firebase
    func generateReport(for budget: Budget) async throws -> BudgetReportDTO {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let report = try await firebaseService.generateBudgetReport(budgetId: budget.id.uuidString)
            return report
        } catch {
            lastError = error
            throw error
        }
    }
    
    /// Get budgets exceeding limit
    func overBudgetBudgets() -> [Budget] {
        budgets.filter { $0.progressPercentage > 100 }
    }
    
    /// Get budgets near limit (>80%)
    func nearLimitBudgets() -> [Budget] {
        budgets.filter { $0.progressPercentage > 80 && $0.progressPercentage <= 100 }
    }
    
    /// Get total budgeted amount
    func totalBudgetedAmount() -> Decimal {
        budgets.reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Get total spent across all budgets
    func totalSpent() -> Decimal {
        budgets.reduce(Decimal.zero) { $0 + $1.currentSpent }
    }
    
    /// Check if category has active budget
    func hasBudget(forCategory category: String) -> Bool {
        fetchActiveBudgets()
        return budgets.contains { $0.categories.contains(category) }
    }
    
    /// Get budget for category
    func budget(forCategory category: String) -> Budget? {
        fetchActiveBudgets()
        return budgets.first { $0.categories.contains(category) }
    }
}
