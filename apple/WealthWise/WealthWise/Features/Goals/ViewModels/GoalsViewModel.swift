//
//  GoalsViewModel.swift
//  WealthWise
//
//  Goals view model with progress tracking
//

import SwiftUI
import SwiftData

@MainActor
final class GoalsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var goals: [WebAppGoal] = []
    @Published var activeGoals: [WebAppGoal] = []
    @Published var completedGoals: [WebAppGoal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Repositories
    
    private let goalRepository: GoalRepository
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.goalRepository = GoalRepository(modelContext: modelContext)
    }
    
    // MARK: - Data Loading
    
    func loadGoals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load from local storage
            goalRepository.fetchLocal()
            updateGoalLists()
            
            // Sync with Firebase
            try await goalRepository.sync()
            updateGoalLists()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadGoals()
    }
    
    private func updateGoalLists() {
        goals = goalRepository.goals
        activeGoals = goalRepository.fetchActiveGoals()
        completedGoals = goals.filter { $0.status == .completed }
    }
    
    // MARK: - Goal Operations
    
    func deleteGoal(_ goal: WebAppGoal) async {
        do {
            try await goalRepository.delete(goal)
            updateGoalLists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func completeGoal(_ goal: WebAppGoal) async {
        do {
            try await goalRepository.complete(goal)
            updateGoalLists()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Computed Properties
    
    var hasGoals: Bool {
        !goals.isEmpty
    }
    
    var hasActiveGoals: Bool {
        !activeGoals.isEmpty
    }
    
    var hasCompletedGoals: Bool {
        !completedGoals.isEmpty
    }
    
    var totalTargetAmount: Decimal {
        goalRepository.totalTargetAmount()
    }
    
    var totalSavedAmount: Decimal {
        goalRepository.totalSavedAmount()
    }
    
    // MARK: - Goal Analysis
    
    func progressPercentage(for goal: WebAppGoal) -> Double {
        guard goal.targetAmount > 0 else { return 0 }
        return Double(truncating: (goal.currentAmount / goal.targetAmount) as NSDecimalNumber)
    }
    
    func remainingAmount(for goal: WebAppGoal) -> Decimal {
        max(goal.targetAmount - goal.currentAmount, 0)
    }
    
    func daysRemaining(for goal: WebAppGoal) -> Int? {
        let calendar = Calendar.current
        let now = Date()
        guard let days = calendar.dateComponents([.day], from: now, to: goal.targetDate).day else {
            return nil
        }
        return max(days, 0)
    }
    
    func isOverdue(_ goal: WebAppGoal) -> Bool {
        goal.targetDate < Date() && goal.status != .completed
    }
    
    func goalStatusColor(_ goal: WebAppGoal) -> Color {
        switch goal.status {
        case .notStarted:
            return .gray
        case .inProgress:
            if isOverdue(goal) {
                return .red
            } else if let days = daysRemaining(for: goal), days < 30 {
                return .orange
            } else {
                return .blue
            }
        case .paused:
            return .orange
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
    
    func goalPriorityColor(_ priority: GoalPriority) -> Color {
        switch priority {
        case .low:
            return .gray
        case .medium:
            return .blue
        case .high:
            return .orange
        case .critical:
            return .red
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
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    func goalTypeText(_ type: GoalType) -> String {
        switch type {
        case .savings:
            return NSLocalizedString("savings", comment: "Savings")
        case .investment:
            return NSLocalizedString("investment", comment: "Investment")
        case .debtPayment:
            return NSLocalizedString("debt_payment", comment: "Debt Payment")
        case .purchase:
            return NSLocalizedString("purchase", comment: "Purchase")
        case .education:
            return NSLocalizedString("education", comment: "Education")
        case .retirement:
            return NSLocalizedString("retirement", comment: "Retirement")
        case .emergency:
            return NSLocalizedString("emergency", comment: "Emergency Fund")
        case .other:
            return NSLocalizedString("other", comment: "Other")
        }
    }
}
