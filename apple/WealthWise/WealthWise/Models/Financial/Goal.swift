//
//  Goal.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-27.
//  Financial Models Foundation - Goal Tracking System
//

import Foundation
import SwiftData

/// Comprehensive goal tracking model supporting financial objectives like "5cr in 3 years"
/// Provides sophisticated progress monitoring, contribution suggestions, and timeline management
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Goal {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var goalDescription: String?
    public var targetAmount: Decimal
    public var targetCurrency: String
    
    // MARK: - Timeline Properties
    
    public var startDate: Date
    public var targetDate: Date
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Progress Properties
    
    public var currentAmount: Decimal
    public var contributedAmount: Decimal // Total manually contributed
    public var projectedAmount: Decimal // Projected based on current investments
    public var lastCalculatedAt: Date?
    
    // MARK: - Goal Configuration
    
    public var goalType: GoalType
    public var priority: GoalPriority
    public var isActive: Bool
    public var isCompleted: Bool
    public var completedAt: Date?
    
    // MARK: - Investment Strategy
    
    public var riskTolerance: RiskTolerance
    public var expectedAnnualReturn: Decimal // Expected return percentage
    public var inflationAdjusted: Bool
    public var autoInvestmentEnabled: Bool
    
    // MARK: - Progress Tracking
    
    public var milestones: [GoalMilestone]
    public var contributions: [GoalContribution]
    public var progressHistory: [ProgressSnapshot]
    
    // MARK: - Relationships
    
    // TODO: CrossBorderAsset relationship will be activated when Issue #20 (Asset Data Models) is fully integrated
    // @Relationship(deleteRule: .cascade) public var linkedAssets: [CrossBorderAsset]?
    
    // NOTE: Temporarily commented to break circular dependency with Transaction
    // Will be restored via extension after successful compilation
    // @Relationship(deleteRule: .cascade) public var linkedTransactions: [Transaction]?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        title: String,
        goalDescription: String? = nil,
        targetAmount: Decimal,
        targetCurrency: String = "INR",
        startDate: Date = Date(),
        targetDate: Date,
        goalType: GoalType = .investment,
        priority: GoalPriority = .high,
        riskTolerance: RiskTolerance = .moderate,
        expectedAnnualReturn: Decimal = 12.0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.goalDescription = goalDescription
        self.targetAmount = targetAmount
        self.targetCurrency = targetCurrency
        self.startDate = startDate
        self.targetDate = targetDate
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize progress
        self.currentAmount = 0
        self.contributedAmount = 0
        self.projectedAmount = 0
        
        // Initialize configuration
        self.goalType = goalType
        self.priority = priority
        self.isActive = true
        self.isCompleted = false
        
        // Initialize investment strategy
        self.riskTolerance = riskTolerance
        self.expectedAnnualReturn = expectedAnnualReturn
        self.inflationAdjusted = true
        self.autoInvestmentEnabled = false
        
        // Initialize tracking arrays
        self.milestones = []
        self.contributions = []
        self.progressHistory = []
        
        // Create initial progress snapshot will be done later to avoid actor isolation issues
    }
    
    // MARK: - Computed Properties
    
    /// Progress percentage (0-100)
    public var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return Double(truncating: (currentAmount / targetAmount * 100) as NSDecimalNumber)
    }
    
    /// Time elapsed percentage (0-100)
    public var timeElapsedPercentage: Double {
        let totalDuration = targetDate.timeIntervalSince(startDate)
        let elapsedDuration = Date().timeIntervalSince(startDate)
        guard totalDuration > 0 else { return 0 }
        return min(100, max(0, (elapsedDuration / totalDuration) * 100))
    }
    
    /// Remaining amount to reach goal
    public var remainingAmount: Decimal {
        return max(0, targetAmount - currentAmount)
    }
    
    /// Days remaining to target date
    public var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: targetDate).day ?? 0
    }
    
    /// Years remaining to target date
    public var yearsRemaining: Double {
        return Double(daysRemaining) / 365.25
    }
    
    /// Whether goal is on track based on time vs progress
    public var isOnTrack: Bool {
        let targetProgress = timeElapsedPercentage
        let actualProgress = progressPercentage
        return actualProgress >= (targetProgress * 0.9) // 90% tolerance
    }
    
    /// Required monthly contribution to meet goal
    public var requiredMonthlyContribution: Decimal {
        guard yearsRemaining > 0 else { return remainingAmount }
        
        let monthsRemaining = yearsRemaining * 12
        let monthlyReturn = expectedAnnualReturn / 100 / 12
        
        if monthlyReturn > 0 {
            // Future value of annuity calculation using NSDecimalNumber for precision
            let remainingDecimal = NSDecimalNumber(decimal: remainingAmount)
            let returnDecimal = NSDecimalNumber(decimal: monthlyReturn)
            let _ = NSDecimalNumber(value: monthsRemaining)
            let onePlusReturn = returnDecimal.adding(NSDecimalNumber(value: 1))
            
            // Use power approximation for NSDecimalNumber since raising(toPower:) has limitations
            let powerResult = pow(onePlusReturn.doubleValue, monthsRemaining)
            let denominator = NSDecimalNumber(value: powerResult).subtracting(NSDecimalNumber(value: 1))
            let numerator = remainingDecimal.multiplying(by: returnDecimal)
            
            guard denominator.doubleValue != 0 else { return Decimal.zero }
            return numerator.dividing(by: denominator).decimalValue
        } else {
            // Simple division if no expected return
            return remainingAmount / Decimal(monthsRemaining)
        }
    }
    
    /// Projected completion date based on current progress
    public var projectedCompletionDate: Date {
        guard progressPercentage > 0 && progressPercentage < 100 else { return targetDate }
        
        let progressRate = progressPercentage / timeElapsedPercentage
        if progressRate > 0 {
            let totalTimeRequired = 100 / progressRate * timeElapsedPercentage
            let totalDays = (targetDate.timeIntervalSince(startDate) / 86400) * (totalTimeRequired / 100)
            return startDate.addingTimeInterval(totalDays * 86400)
        }
        
        return targetDate
    }
    
    /// Achievement probability based on current trajectory
    public var achievementProbability: Double {
        let timeRatio = timeElapsedPercentage / 100
        let progressRatio = progressPercentage / 100
        
        if timeRatio <= 0 { return 0.9 } // High probability at start
        if progressRatio >= 1 { return 1.0 } // Already achieved
        
        let ratioScore = progressRatio / timeRatio
        
        // Probability calculation based on trajectory
        if ratioScore >= 1.1 { return 0.95 } // Ahead of schedule
        if ratioScore >= 1.0 { return 0.85 } // On track
        if ratioScore >= 0.8 { return 0.70 } // Slightly behind
        if ratioScore >= 0.6 { return 0.50 } // Behind schedule
        if ratioScore >= 0.4 { return 0.30 } // Significantly behind
        return 0.15 // Far behind
    }
    
    // MARK: - Business Logic Methods
    
    /// Update current amount and recalculate progress
    @MainActor
    public func updateProgress(currentAmount: Decimal, source: ProgressUpdateSource = .manual) {
        self.currentAmount = currentAmount
        self.updatedAt = Date()
        self.lastCalculatedAt = Date()
        
        // Add progress snapshot
        let snapshot = ProgressSnapshot(
            date: Date(),
            currentAmount: currentAmount,
            progressPercentage: progressPercentage,
            timeElapsedPercentage: timeElapsedPercentage,
            projectedCompletion: projectedCompletionDate,
            source: source
        )
        progressHistory.append(snapshot)
        
        // Check for milestone achievements
        checkMilestoneAchievements()
        
        // Check for goal completion
        if currentAmount >= targetAmount && !isCompleted {
            markAsCompleted()
        }
    }
    
    /// Add a contribution to the goal
    @MainActor
    public func addContribution(amount: Decimal, date: Date = Date(), description: String? = nil) {
        let contribution = GoalContribution(
            id: UUID(),
            amount: amount,
            date: date,
            description: description ?? NSLocalizedString("default_contribution_description", comment: "Investment contribution")
        )
        contributions.append(contribution)
        contributedAmount += amount
        
        // Update current amount
        updateProgress(currentAmount: currentAmount + amount, source: .contribution)
    }
    
    /// Add a milestone to track
    @MainActor
    public func addMilestone(percentage: Double, title: String, description: String? = nil) {
        let milestoneTargetAmount = targetAmount * Decimal(percentage / 100)
        let milestoneTargetDate = calculateMilestoneDate(percentage: Decimal(percentage))
        let milestone = GoalMilestone(
            percentage: percentage,
            title: title,
            description: description,
            targetAmount: milestoneTargetAmount,
            targetDate: milestoneTargetDate
        )
        milestones.append(milestone)
        milestones.sort { $0.percentage < $1.percentage }
    }
    
    /// Check and update milestone achievements
    @MainActor
    private func checkMilestoneAchievements() {
        for index in milestones.indices where !milestones[index].isAchieved {
            if progressPercentage >= milestones[index].percentage {
                milestones[index].markAsAchieved()
            }
        }
    }
    
    /// Mark goal as completed
    @MainActor
    public func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
        
        // Mark all milestones as achieved
        for index in milestones.indices {
            if !milestones[index].isAchieved {
                milestones[index].markAsAchieved()
            }
        }
    }
    
    /// Update expected annual return
    @MainActor
    public func updateExpectedReturn(_ annualReturn: Decimal) {
        expectedAnnualReturn = annualReturn
        updatedAt = Date()
        
        // Recalculate projections
        updateProgress(currentAmount: currentAmount, source: .recalculation)
    }
    
    /// Extend target date
    @MainActor
    public func extendTargetDate(to newDate: Date) {
        guard newDate > targetDate else { return }
        targetDate = newDate
        updatedAt = Date()
        
        // Recalculate progress
        updateProgress(currentAmount: currentAmount, source: .recalculation)
    }
    
    /// Get contribution suggestions based on current progress
    @MainActor
    public func getContributionSuggestions() -> [ContributionSuggestion] {
        var suggestions: [ContributionSuggestion] = []
        
        // Monthly contribution to stay on track
        let monthlyRequired = requiredMonthlyContribution
        suggestions.append(
            ContributionSuggestion(
                type: .monthly,
                amount: monthlyRequired,
                frequency: .monthly,
                description: NSLocalizedString("contribution_to_stay_on_track", comment: "Monthly contribution to stay on track with goal"),
                impact: .onTrack
            )
        )
        
        // Accelerated contribution to finish early
        if yearsRemaining > 1 {
            let acceleratedMonthly = monthlyRequired * 1.2
            suggestions.append(
                ContributionSuggestion(
                    type: .accelerated,
                    amount: acceleratedMonthly,
                    frequency: .monthly,
                    description: NSLocalizedString("contribution_to_finish_early", comment: "Accelerated contribution to finish goal early"),
                    impact: .accelerated
                )
            )
        }
        
        // One-time lump sum suggestion
        if remainingAmount > 0 {
            let lumpSum = remainingAmount * 0.3 // 30% of remaining
            suggestions.append(
                ContributionSuggestion(
                    type: .lumpSum,
                    amount: lumpSum,
                    frequency: .oneTime,
                    description: NSLocalizedString("lump_sum_boost", comment: "One-time lump sum to boost progress"),
                    impact: .boost
                )
            )
        }
        
        return suggestions
    }
}

// MARK: - Supporting Types

/// Goal type classification
public enum GoalType: String, CaseIterable, Codable, Sendable {
    case investment = "investment"
    case savings = "savings"
    case retirement = "retirement"
    case education = "education"
    case property = "property"
    case vacation = "vacation"
    case emergency = "emergency"
    case business = "business"
    case tax_saving = "tax_saving"
    case debt_payoff = "debt_payoff"
    
    public var displayName: String {
        switch self {
        case .investment:
            return NSLocalizedString("goal_type_investment", comment: "Investment goal type")
        case .savings:
            return NSLocalizedString("goal_type_savings", comment: "Savings goal type")
        case .retirement:
            return NSLocalizedString("goal_type_retirement", comment: "Retirement goal type")
        case .education:
            return NSLocalizedString("goal_type_education", comment: "Education goal type")
        case .property:
            return NSLocalizedString("goal_type_property", comment: "Property goal type")
        case .vacation:
            return NSLocalizedString("goal_type_vacation", comment: "Vacation goal type")
        case .emergency:
            return NSLocalizedString("goal_type_emergency", comment: "Emergency fund goal type")
        case .business:
            return NSLocalizedString("goal_type_business", comment: "Business goal type")
        case .tax_saving:
            return NSLocalizedString("goal_type_tax_saving", comment: "Tax saving goal type")
        case .debt_payoff:
            return NSLocalizedString("goal_type_debt_payoff", comment: "Debt payoff goal type")
        }
    }
}

/// Goal priority levels
public enum GoalPriority: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low:
            return NSLocalizedString("priority_low", comment: "Low priority")
        case .medium:
            return NSLocalizedString("priority_medium", comment: "Medium priority")
        case .high:
            return NSLocalizedString("priority_high", comment: "High priority")
        case .critical:
            return NSLocalizedString("priority_critical", comment: "Critical priority")
        }
    }
    
    public var weight: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

/// Risk tolerance levels
public enum RiskTolerance: String, CaseIterable, Codable, Sendable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"
    case very_aggressive = "very_aggressive"
    
    public var displayName: String {
        switch self {
        case .conservative:
            return NSLocalizedString("risk_conservative", comment: "Conservative risk tolerance")
        case .moderate:
            return NSLocalizedString("risk_moderate", comment: "Moderate risk tolerance")
        case .aggressive:
            return NSLocalizedString("risk_aggressive", comment: "Aggressive risk tolerance")
        case .very_aggressive:
            return NSLocalizedString("risk_very_aggressive", comment: "Very aggressive risk tolerance")
        }
    }
    
    public var expectedReturn: Decimal {
        switch self {
        case .conservative: return 6.0
        case .moderate: return 10.0
        case .aggressive: return 14.0
        case .very_aggressive: return 18.0
        }
    }
}

/// Progress update source
public enum ProgressUpdateSource: String, Codable, Sendable {
    case manual = "manual"
    case automatic = "automatic"
    case contribution = "contribution"
    case investment_growth = "investment_growth"
    case recalculation = "recalculation"
}

/// Goal milestone for tracking progress
public struct GoalMilestone: Codable, Sendable, Identifiable {
    public let id: UUID
    public let percentage: Double
    public let title: String
    public let description: String?
    public let targetAmount: Decimal
    public let targetDate: Date
    public var isAchieved: Bool
    public var achievedAt: Date?
    
    public init(
        id: UUID = UUID(),
        percentage: Double,
        title: String,
        description: String? = nil,
        targetAmount: Decimal,
        targetDate: Date
    ) {
        self.id = id
        self.percentage = percentage
        self.title = title
        self.description = description
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.isAchieved = false
        self.achievedAt = nil
    }
    
    public mutating func markAsAchieved() {
        isAchieved = true
        achievedAt = Date()
    }
}

/// Goal contribution record
public struct GoalContribution: Codable, Sendable, Identifiable {
    public let id: UUID
    public let amount: Decimal
    public let date: Date
    public let description: String?
    public let currency: String
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = Date(),
        description: String? = nil,
        currency: String = "INR"
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.description = description
        self.currency = currency
    }
}

/// Progress snapshot for historical tracking
public struct ProgressSnapshot: Codable, Sendable, Identifiable {
    public let id: UUID
    public let date: Date
    public let currentAmount: Decimal
    public let progressPercentage: Double
    public let timeElapsedPercentage: Double
    public let projectedCompletion: Date
    public let source: ProgressUpdateSource
    
    public init(
        id: UUID = UUID(),
        date: Date,
        currentAmount: Decimal,
        progressPercentage: Double,
        timeElapsedPercentage: Double,
        projectedCompletion: Date,
        source: ProgressUpdateSource = .manual
    ) {
        self.id = id
        self.date = date
        self.currentAmount = currentAmount
        self.progressPercentage = progressPercentage
        self.timeElapsedPercentage = timeElapsedPercentage
        self.projectedCompletion = projectedCompletion
        self.source = source
    }
}

/// Contribution suggestion
public struct ContributionSuggestion: Codable, Sendable, Identifiable {
    public let id: UUID
    public let type: ContributionType
    public let amount: Decimal
    public let frequency: ContributionFrequency
    public let description: String
    public let impact: ContributionImpact
    
    public init(
        id: UUID = UUID(),
        type: ContributionType,
        amount: Decimal,
        frequency: ContributionFrequency,
        description: String,
        impact: ContributionImpact
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.frequency = frequency
        self.description = description
        self.impact = impact
    }
}

/// Contribution type
public enum ContributionType: String, CaseIterable, Codable, Sendable {
    case monthly = "monthly"
    case accelerated = "accelerated"
    case lumpSum = "lump_sum"
    case catchUp = "catch_up"
}

/// Contribution frequency
public enum ContributionFrequency: String, CaseIterable, Codable, Sendable {
    case oneTime = "one_time"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case annually = "annually"
}

/// Contribution impact
public enum ContributionImpact: String, CaseIterable, Codable, Sendable {
    case onTrack = "on_track"
    case accelerated = "accelerated"
    case boost = "boost"
    case catchUp = "catch_up"
}

// MARK: - Extensions
// SwiftData @Model provides Hashable and Equatable conformance automatically

// MARK: - Factory Methods

extension Goal {
    
    /// Create a "5 crore in 3 years" investment goal
    @MainActor
    public static func createFiveCroreGoal() -> Goal {
        let goal = Goal(
            title: NSLocalizedString("five_crore_goal_title", comment: "5 Crore Investment Goal"),
            goalDescription: NSLocalizedString("five_crore_goal_description", comment: "Achieve 5 crore investment target in 3 years"),
            targetAmount: 50000000, // 5 crores
            targetCurrency: "INR",
            targetDate: Calendar.current.date(byAdding: .year, value: 3, to: Date()) ?? Date(),
            goalType: .investment,
            priority: .critical,
            riskTolerance: .aggressive,
            expectedAnnualReturn: 15.0
        )
        
        // Add milestones
        let milestone25 = GoalMilestone(percentage: 25.0, title: "25% milestone", description: "1.25 crores", targetAmount: 12500000, targetDate: Calendar.current.date(byAdding: .month, value: 9, to: Date()) ?? Date())
        let milestone50 = GoalMilestone(percentage: 50.0, title: "50% milestone", description: "2.5 crores", targetAmount: 25000000, targetDate: Calendar.current.date(byAdding: .month, value: 18, to: Date()) ?? Date())
        let milestone75 = GoalMilestone(percentage: 75.0, title: "75% milestone", description: "3.75 crores", targetAmount: 37500000, targetDate: Calendar.current.date(byAdding: .month, value: 27, to: Date()) ?? Date())
        goal.milestones = [milestone25, milestone50, milestone75]
        
        return goal
    }
    
    /// Add a milestone to the goal
    @MainActor
    public func addMilestone(percentage: Decimal, title: String, description: String? = nil) {
        let targetAmount = (self.targetAmount * percentage) / 100
        let milestoneTargetDate = calculateMilestoneDate(percentage: percentage)
        let milestone = GoalMilestone(
            percentage: Double(truncating: NSDecimalNumber(decimal: percentage)),
            title: title,
            description: description,
            targetAmount: targetAmount,
            targetDate: milestoneTargetDate
        )
        
        milestones.append(milestone)
    }
    
    /// Add a contribution to the goal
    @MainActor
    public func addContribution(amount: Decimal, description: String? = nil, date: Date = Date()) {
        let contribution = GoalContribution(
            amount: amount,
            date: date,
            description: description
        )
        
        contributions.append(contribution)
    }
    
    /// Calculate milestone date based on percentage
    private func calculateMilestoneDate(percentage: Decimal) -> Date {
        let timeInterval = targetDate.timeIntervalSince(startDate)
        let milestoneInterval = timeInterval * Double(truncating: NSDecimalNumber(decimal: percentage / 100))
        return startDate.addingTimeInterval(milestoneInterval)
    }
}