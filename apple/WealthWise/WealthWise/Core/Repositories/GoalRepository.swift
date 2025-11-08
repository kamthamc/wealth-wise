//
//  GoalRepository.swift
//  WealthWise
//
//  Repository for managing financial goals with offline-first architecture
//

import Foundation
import SwiftData

/// Repository managing goal operations with offline-first pattern
/// Provides SwiftData local storage with Firebase Cloud Functions sync
@MainActor
final class GoalRepository: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var goals: [WebAppGoal] = []
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
    
    /// Fetch all goals from local storage
    func fetchLocal() {
        let descriptor = FetchDescriptor<WebAppGoal>(
            sortBy: [
                SortDescriptor(\.priority, order: .forward),
                SortDescriptor(\.targetDate, order: .forward)
            ]
        )
        
        do {
            goals = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching local goals: \(error)")
        }
    }
    
    /// Fetch active goals (not completed or cancelled)
    func fetchActiveGoals() {
        let predicate = #Predicate<WebAppGoal> { goal in
            goal.status == GoalStatus.active || goal.status == GoalStatus.paused
        }
        
        let descriptor = FetchDescriptor<WebAppGoal>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.priority, order: .forward),
                SortDescriptor(\.targetDate, order: .forward)
            ]
        )
        
        do {
            goals = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching active goals: \(error)")
        }
    }
    
    /// Fetch goals by type
    func fetchLocal(type: GoalType) {
        let predicate = #Predicate<WebAppGoal> { goal in
            goal.type == type
        }
        
        let descriptor = FetchDescriptor<WebAppGoal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.targetDate, order: .forward)]
        )
        
        do {
            goals = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching goals by type: \(error)")
        }
    }
    
    /// Fetch goals by priority
    func fetchLocal(priority: GoalPriority) {
        let predicate = #Predicate<WebAppGoal> { goal in
            goal.priority == priority
        }
        
        let descriptor = FetchDescriptor<WebAppGoal>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.targetDate, order: .forward)]
        )
        
        do {
            goals = try modelContext.fetch(descriptor)
        } catch {
            lastError = error
            print("Error fetching goals by priority: \(error)")
        }
    }
    
    // MARK: - Firebase Sync
    
    /// Sync goals from Firebase to local storage
    func sync() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let dtos = try await firebaseService.fetchGoals()
            
            // Convert DTOs to SwiftData models and save locally
            for dto in dtos {
                let goal = dto.toGoal()
                modelContext.insert(goal)
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
    
    /// Create new goal (saves locally and syncs to Firebase)
    func create(_ goal: WebAppGoal) async throws {
        // Save locally first (optimistic update)
        modelContext.insert(goal)
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync to Firebase
        Task {
            do {
                let dto = try await firebaseService.createOrUpdateGoal(
                    goalId: nil,
                    name: goal.name,
                    targetAmount: NSDecimalNumber(decimal: goal.targetAmount).doubleValue,
                    targetDate: goal.targetDate,
                    type: goal.type.rawValue,
                    priority: goal.priority.rawValue
                )
                
                // Update local goal with server data
                goal.lastSyncedAt = Date()
                try modelContext.save()
                
            } catch {
                lastError = error
                print("Error syncing goal to Firebase: \(error)")
            }
        }
    }
    
    /// Update existing goal
    func update(_ goal: WebAppGoal) async throws {
        goal.updatedAt = Date()
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync to Firebase using createOrUpdateGoal
        Task {
            do {
                _ = try await firebaseService.createOrUpdateGoal(
                    goalId: goal.id.uuidString,
                    name: goal.name,
                    targetAmount: NSDecimalNumber(decimal: goal.targetAmount).doubleValue,
                    targetDate: goal.targetDate,
                    type: goal.type.rawValue,
                    priority: goal.priority.rawValue
                )
                
                goal.lastSyncedAt = Date()
                try modelContext.save()
                
            } catch {
                lastError = error
                print("Error syncing goal update to Firebase: \(error)")
            }
        }
    }
    
    /// Delete goal
    func delete(_ goal: WebAppGoal) async throws {
        modelContext.delete(goal)
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync deletion to Firebase
        Task {
            do {
                try await firebaseService.deleteGoal(goal.id.uuidString)
            } catch {
                lastError = error
                print("Error deleting goal from Firebase: \(error)")
            }
        }
    }
    
    // MARK: - Contribution Management
    
    /// Add contribution to goal
    func addContribution(to goal: WebAppGoal, amount: Decimal, date: Date, note: String?) async throws {
        // Add contribution locally
        goal.addContribution(amount: amount, date: date, note: note)
        try modelContext.save()
        
        // Refresh local list
        fetchLocal()
        
        // Sync to Firebase
        Task {
            do {
                _ = try await firebaseService.addGoalContribution(
                    goalId: goal.id.uuidString,
                    amount: NSDecimalNumber(decimal: amount).doubleValue,
                    date: date,
                    note: note
                )
                
                goal.lastSyncedAt = Date()
                try modelContext.save()
                
            } catch {
                lastError = error
                print("Error syncing contribution to Firebase: \(error)")
            }
        }
    }
    
    // MARK: - Goal Status Management
    
    /// Mark goal as completed
    func complete(_ goal: WebAppGoal) async throws {
        goal.status = .completed
        goal.updatedAt = Date()
        try modelContext.save()
        
        // Sync to Firebase
        try await update(goal)
    }
    
    /// Pause goal
    func pause(_ goal: WebAppGoal) async throws {
        goal.status = .paused
        goal.updatedAt = Date()
        try modelContext.save()
        
        // Sync to Firebase
        try await update(goal)
    }
    
    /// Resume paused goal
    func resume(_ goal: WebAppGoal) async throws {
        goal.status = .active
        goal.updatedAt = Date()
        try modelContext.save()
        
        // Sync to Firebase
        try await update(goal)
    }
    
    /// Cancel goal
    func cancel(_ goal: WebAppGoal) async throws {
        goal.status = .cancelled
        goal.updatedAt = Date()
        try modelContext.save()
        
        // Sync to Firebase
        try await update(goal)
    }
    
    // MARK: - Goal Analysis
    
    /// Get goals by completion status
    func goalsByCompletion() -> (completed: [WebAppGoal], inProgress: [WebAppGoal], notStarted: [WebAppGoal]) {
        let completed = goals.filter { $0.status == .completed }
        let inProgress = goals.filter { $0.progressPercentage > 0 && $0.progressPercentage < 100 && $0.status == .active }
        let notStarted = goals.filter { $0.progressPercentage == 0 && $0.status == .active }
        
        return (completed, inProgress, notStarted)
    }
    
    /// Get overdue goals
    func overdueGoals() -> [WebAppGoal] {
        let now = Date()
        return goals.filter { $0.targetDate < now && $0.status == .active && $0.progressPercentage < 100 }
    }
    
    /// Get goals near deadline (within 30 days)
    func goalsNearDeadline(days: Int = 30) -> [WebAppGoal] {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: days, to: Date()) else {
            return []
        }
        
        let now = Date()
        return goals.filter { 
            $0.targetDate >= now && 
            $0.targetDate <= cutoffDate && 
            $0.status == .active &&
            $0.progressPercentage < 100
        }
    }
    
    /// Calculate total target amount
    func totalTargetAmount() -> Decimal {
        goals.reduce(Decimal.zero) { $0 + $1.targetAmount }
    }
    
    /// Calculate total saved amount
    func totalSavedAmount() -> Decimal {
        goals.reduce(Decimal.zero) { $0 + $1.currentAmount }
    }
    
    /// Get average progress percentage
    func averageProgress() -> Double {
        guard !goals.isEmpty else { return 0 }
        let total = goals.reduce(0.0) { $0 + $1.progressPercentage }
        return total / Double(goals.count)
    }
    
    /// Get high priority goals
    func highPriorityGoals() -> [WebAppGoal] {
        goals.filter { $0.priority == .high && $0.status == .active }
    }
    
    /// Calculate total monthly contribution needed
    func totalMonthlyContributionNeeded() -> Decimal {
        goals.filter { $0.status == .active }
            .reduce(Decimal.zero) { $0 + $1.suggestedMonthlyContribution }
    }
}
