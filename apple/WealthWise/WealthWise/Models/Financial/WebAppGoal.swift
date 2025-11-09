//
//  WebAppGoal.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-08.
//  Goal tracking matching Firebase webapp schema
//

import Foundation
import SwiftData

/// Simplified goal model matching the Firebase webapp implementation
/// Tracks financial goals with contribution history
@available(iOS 18, macOS 15, *)
@Model
public final class WebAppGoal {
    
    // MARK: - Primary Properties
    
    /// Unique identifier matching Firestore document ID
    @Attribute(.unique) public var id: UUID
    
    /// User ID from Firebase Authentication
    public var userId: String
    
    /// Goal name
    public var name: String
    
    /// Target amount to achieve
    public var targetAmount: Decimal
    
    /// Current accumulated amount
    public var currentAmount: Decimal
    
    /// Target completion date
    public var targetDate: Date
    
    /// Goal type
    public var type: GoalType
    
    /// Goal priority
    public var priority: GoalPriority
    
    /// Goal status
    public var status: GoalStatus
    
    /// Contribution history
    public var contributions: [Contribution]
    
    /// Creation timestamp
    public var createdAt: Date
    
    /// Last update timestamp
    public var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Remaining amount to target
    public var remainingAmount: Decimal {
        max(targetAmount - currentAmount, 0)
    }
    
    /// Progress percentage (0-100)
    public var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        let progress = Double(truncating: currentAmount as NSNumber) / Double(truncating: targetAmount as NSNumber)
        return min(progress * 100, 100)
    }
    
    /// Whether goal is completed
    public var isCompleted: Bool {
        currentAmount >= targetAmount
    }
    
    /// Days until target date
    public var daysUntilTarget: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day ?? 0
    }
    
    /// Suggested monthly contribution
    public var suggestedMonthlyContribution: Decimal {
        guard daysUntilTarget > 0 else { return 0 }
        let monthsRemaining = Decimal(daysUntilTarget) / 30
        guard monthsRemaining > 0 else { return remainingAmount }
        return remainingAmount / monthsRemaining
    }
    
    /// Goal type display name
    public var typeDisplayName: String {
        switch type {
        case .savings:
            return NSLocalizedString("goal_type_savings", comment: "Savings")
        case .investment:
            return NSLocalizedString("goal_type_investment", comment: "Investment")
        case .debtPayment:
            return NSLocalizedString("goal_type_debt", comment: "Debt Payment")
        case .emergency:
            return NSLocalizedString("goal_type_emergency", comment: "Emergency Fund")
        case .custom:
            return NSLocalizedString("goal_type_custom", comment: "Custom Goal")
        }
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        targetDate: Date,
        type: GoalType = .savings,
        priority: GoalPriority = .medium,
        status: GoalStatus = .inProgress,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.type = type
        self.priority = priority
        self.status = status
        self.contributions = []
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    // MARK: - Methods
    
    /// Add a contribution to the goal
    public func addContribution(amount: Decimal, date: Date, note: String? = nil) {
        let contribution = Contribution(
            id: UUID(),
            amount: amount,
            date: date,
            note: note
        )
        contributions.append(contribution)
        currentAmount += amount
        updatedAt = Date()
        
        // Update status if goal is completed
        if isCompleted && status != .completed {
            status = .completed
        }
    }
    
    /// Remove a contribution
    public func removeContribution(_ contribution: Contribution) {
        contributions.removeAll { $0.id == contribution.id }
        currentAmount -= contribution.amount
        updatedAt = Date()
    }
    
    /// Convert to Firestore dictionary
    public func toFirestore() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "targetAmount": NSDecimalNumber(decimal: targetAmount).doubleValue,
            "currentAmount": NSDecimalNumber(decimal: currentAmount).doubleValue,
            "targetDate": targetDate,
            "type": type.rawValue,
            "priority": priority.rawValue,
            "status": status.rawValue,
            "contributions": contributions.map { $0.toDictionary() },
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

// MARK: - Goal Type

extension WebAppGoal {
    public enum GoalType: String, Codable, CaseIterable {
        case savings = "savings"
        case investment = "investment"
        case debtPayment = "debtPayment"
        case emergency = "emergency"
        case custom = "custom"
    }
    
    public enum GoalPriority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
    
    public enum GoalStatus: String, Codable, CaseIterable {
        case inProgress = "inProgress"
        case completed = "completed"
        case paused = "paused"
    }
}

// MARK: - Contribution Model

extension WebAppGoal {
    public struct Contribution: Codable, Identifiable, Hashable {
        public let id: UUID
        public let amount: Decimal
        public let date: Date
        public let note: String?
        
        public init(id: UUID = UUID(), amount: Decimal, date: Date, note: String? = nil) {
            self.id = id
            self.amount = amount
            self.date = date
            self.note = note
        }
        
        func toDictionary() -> [String: Any] {
            return [
                "id": id.uuidString,
                "amount": NSDecimalNumber(decimal: amount).doubleValue,
                "date": date,
                "note": note as Any
            ]
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension WebAppGoal {
    static var sampleSavings: WebAppGoal {
        let goal = WebAppGoal(
            userId: "sample_user",
            name: "Emergency Fund",
            targetAmount: 500000,
            currentAmount: 150000,
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
            type: .emergency,
            priority: .high
        )
        goal.addContribution(amount: 50000, date: Date().addingTimeInterval(-30*24*60*60), note: "Initial deposit")
        goal.addContribution(amount: 50000, date: Date().addingTimeInterval(-15*24*60*60), note: "Monthly savings")
        goal.addContribution(amount: 50000, date: Date(), note: "Bonus contribution")
        return goal
    }
    
    static var sampleInvestment: WebAppGoal {
        WebAppGoal(
            userId: "sample_user",
            name: "Retirement Fund - 5 Crore",
            targetAmount: 50000000,
            currentAmount: 2500000,
            targetDate: Calendar.current.date(byAdding: .year, value: 20, to: Date())!,
            type: .investment,
            priority: .high
        )
    }
    
    static var samples: [WebAppGoal] {
        [sampleSavings, sampleInvestment]
    }
}
#endif
