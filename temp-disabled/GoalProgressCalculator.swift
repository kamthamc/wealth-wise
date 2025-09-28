//
//  GoalProgressCalculator.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import Foundation

/// Sophisticated goal progress calculator for comprehensive goal tracking and analysis.
/// Provides detailed progress metrics, milestone tracking, and achievement projections.
@MainActor
public final class GoalProgressCalculator {
    
    // MARK: - Progress Analysis Results
    
    /// Comprehensive goal progress analysis result
    public struct GoalProgressAnalysis: Sendable {
        public let goal: Goal
        public let currentProgress: ProgressMetrics
        public let projectedProgress: ProjectionMetrics
        public let milestoneStatus: MilestoneStatus
        public let recommendations: [ProgressRecommendation]
        public let riskAssessment: RiskAssessment
        
        /// Initialize goal progress analysis
        public init(goal: Goal, currentProgress: ProgressMetrics, projectedProgress: ProjectionMetrics, milestoneStatus: MilestoneStatus, recommendations: [ProgressRecommendation], riskAssessment: RiskAssessment) {
            self.goal = goal
            self.currentProgress = currentProgress
            self.projectedProgress = projectedProgress
            self.milestoneStatus = milestoneStatus
            self.recommendations = recommendations
            self.riskAssessment = riskAssessment
        }
    }
    
    /// Current progress metrics
    public struct ProgressMetrics: Sendable {
        public let currentAmount: Decimal
        public let targetAmount: Decimal
        public let progressPercentage: Decimal
        public let totalContributions: Decimal
        public let totalReturns: Decimal
        public let timeElapsed: Decimal
        public let timeRemaining: Decimal
        public let currentRunRate: Decimal // Amount per year based on recent contributions
        
        /// Initialize progress metrics
        public init(currentAmount: Decimal, targetAmount: Decimal, progressPercentage: Decimal, totalContributions: Decimal, totalReturns: Decimal, timeElapsed: Decimal, timeRemaining: Decimal, currentRunRate: Decimal) {
            self.currentAmount = currentAmount
            self.targetAmount = targetAmount
            self.progressPercentage = progressPercentage
            self.totalContributions = totalContributions
            self.totalReturns = totalReturns
            self.timeElapsed = timeElapsed
            self.timeRemaining = timeRemaining
            self.currentRunRate = currentRunRate
        }
    }
    
    /// Projected progress metrics
    public struct ProjectionMetrics: Sendable {
        public let projectedFinalAmount: Decimal
        public let projectedShortfall: Decimal
        public let probabilityOfSuccess: Decimal
        public let requiredRunRate: Decimal
        public let recommendedAdjustment: Decimal
        public let projectedCompletionDate: Date?
        
        /// Initialize projection metrics
        public init(projectedFinalAmount: Decimal, projectedShortfall: Decimal, probabilityOfSuccess: Decimal, requiredRunRate: Decimal, recommendedAdjustment: Decimal, projectedCompletionDate: Date?) {
            self.projectedFinalAmount = projectedFinalAmount
            self.projectedShortfall = projectedShortfall
            self.probabilityOfSuccess = probabilityOfSuccess
            self.requiredRunRate = requiredRunRate
            self.recommendedAdjustment = recommendedAdjustment
            self.projectedCompletionDate = projectedCompletionDate
        }
    }
    
    /// Milestone tracking status
    public struct MilestoneStatus: Sendable {
        public let milestones: [MilestoneProgress]
        public let nextMilestone: MilestoneProgress?
        public let milestonesAchieved: Int
        public let totalMilestones: Int
        public let milestoneCompletionRate: Decimal
        
        /// Initialize milestone status
        public init(milestones: [MilestoneProgress], nextMilestone: MilestoneProgress?, milestonesAchieved: Int, totalMilestones: Int, milestoneCompletionRate: Decimal) {
            self.milestones = milestones
            self.nextMilestone = nextMilestone
            self.milestonesAchieved = milestonesAchieved
            self.totalMilestones = totalMilestones
            self.milestoneCompletionRate = milestoneCompletionRate
        }
    }
    
    /// Individual milestone progress
    public struct MilestoneProgress: Sendable {
        public let milestone: GoalMilestone
        public let isAchieved: Bool
        public let progressTowardsMilestone: Decimal
        public let projectedAchievementDate: Date?
        public let daysUntilTarget: Int?
        
        /// Initialize milestone progress
        public init(milestone: GoalMilestone, isAchieved: Bool, progressTowardsMilestone: Decimal, projectedAchievementDate: Date?, daysUntilTarget: Int?) {
            self.milestone = milestone
            self.isAchieved = isAchieved
            self.progressTowardsMilestone = progressTowardsMilestone
            self.projectedAchievementDate = projectedAchievementDate
            self.daysUntilTarget = daysUntilTarget
        }
    }
    
    /// Progress recommendation types
    public enum ProgressRecommendation: Sendable {
        case increaseContributions(amount: Decimal, reason: String)
        case adjustTimeline(newDeadline: Date, reason: String)
        case optimizeReturns(targetRate: Decimal, reason: String)
        case celebrateMilestone(milestone: GoalMilestone, message: String)
        case riskWarning(risk: String, mitigation: String)
        case onTrack(message: String)
        
        /// Localized description for the recommendation
        public var localizedDescription: String {
            switch self {
            case .increaseContributions(let amount, let reason):
                return String(format: NSLocalizedString("recommendation.increase_contributions", comment: "Increase contributions recommendation"), Double(truncating: amount as NSDecimalNumber), reason)
            case .adjustTimeline(let newDeadline, let reason):
                return String(format: NSLocalizedString("recommendation.adjust_timeline", comment: "Adjust timeline recommendation"), DateFormatter.localizedString(from: newDeadline, dateStyle: .medium, timeStyle: .none), reason)
            case .optimizeReturns(let targetRate, let reason):
                return String(format: NSLocalizedString("recommendation.optimize_returns", comment: "Optimize returns recommendation"), Double(truncating: targetRate as NSDecimalNumber), reason)
            case .celebrateMilestone(let milestone, let message):
                return String(format: NSLocalizedString("recommendation.celebrate_milestone", comment: "Celebrate milestone"), milestone.description ?? milestone.title, message)
            case .riskWarning(let risk, let mitigation):
                return String(format: NSLocalizedString("recommendation.risk_warning", comment: "Risk warning"), risk, mitigation)
            case .onTrack(let message):
                return String(format: NSLocalizedString("recommendation.on_track", comment: "On track message"), message)
            }
        }
    }
    
    /// Risk assessment for goal achievement
    public struct RiskAssessment: Sendable {
        public let overallRiskLevel: RiskLevel
        public let timeRisk: Decimal // Risk of not meeting deadline
        public let amountRisk: Decimal // Risk of not reaching target amount
        public let marketRisk: Decimal // Risk from market volatility
        public let inflationRisk: Decimal // Risk from inflation impact
        public let mitigationStrategies: [String]
        
        /// Initialize risk assessment
        public init(overallRiskLevel: RiskLevel, timeRisk: Decimal, amountRisk: Decimal, marketRisk: Decimal, inflationRisk: Decimal, mitigationStrategies: [String]) {
            self.overallRiskLevel = overallRiskLevel
            self.timeRisk = timeRisk
            self.amountRisk = amountRisk
            self.marketRisk = marketRisk
            self.inflationRisk = inflationRisk
            self.mitigationStrategies = mitigationStrategies
        }
    }
    
    /// Risk level enumeration
    public enum RiskLevel: String, CaseIterable, Sendable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        case critical = "critical"
        
        /// Localized description for risk level
        public var localizedDescription: String {
            switch self {
            case .low:
                return NSLocalizedString("risk.level.low", comment: "Low risk level")
            case .moderate:
                return NSLocalizedString("risk.level.moderate", comment: "Moderate risk level")
            case .high:
                return NSLocalizedString("risk.level.high", comment: "High risk level")
            case .critical:
                return NSLocalizedString("risk.level.critical", comment: "Critical risk level")
            }
        }
    }
    
    // MARK: - Core Progress Calculations
    
    /// Calculate comprehensive goal progress analysis
    /// - Parameters:
    ///   - goal: The goal to analyze
    ///   - currentAmount: Current accumulated amount
    ///   - contributions: Array of contributions made toward the goal
    ///   - expectedReturn: Expected annual return rate
    ///   - marketVolatility: Expected market volatility (standard deviation)
    /// - Returns: Comprehensive goal progress analysis
    public static func calculateGoalProgress(
        goal: Goal,
        currentAmount: Decimal,
        contributions: [GoalContribution],
        expectedReturn: Decimal = 0.12, // Default 12% expected return
        marketVolatility: Decimal = 0.15 // Default 15% volatility
    ) -> GoalProgressAnalysis {
        
        // Calculate current progress metrics
        let currentProgress = calculateCurrentProgressMetrics(
            goal: goal,
            currentAmount: currentAmount,
            contributions: contributions
        )
        
        // Calculate projected progress
        let projectedProgress = calculateProjectedProgressMetrics(
            goal: goal,
            currentAmount: currentAmount,
            currentProgress: currentProgress,
            expectedReturn: expectedReturn,
            marketVolatility: marketVolatility
        )
        
        // Analyze milestone status
        let milestoneStatus = analyzeMilestoneStatus(
            goal: goal,
            currentAmount: currentAmount,
            projectedProgress: projectedProgress
        )
        
        // Generate recommendations
        let recommendations = generateProgressRecommendations(
            goal: goal,
            currentProgress: currentProgress,
            projectedProgress: projectedProgress,
            milestoneStatus: milestoneStatus
        )
        
        // Assess risks
        let riskAssessment = assessGoalRisks(
            goal: goal,
            currentProgress: currentProgress,
            projectedProgress: projectedProgress,
            marketVolatility: marketVolatility
        )
        
        return GoalProgressAnalysis(
            goal: goal,
            currentProgress: currentProgress,
            projectedProgress: projectedProgress,
            milestoneStatus: milestoneStatus,
            recommendations: recommendations,
            riskAssessment: riskAssessment
        )
    }
    
    // MARK: - Current Progress Analysis
    
    /// Calculate current progress metrics
    private static func calculateCurrentProgressMetrics(
        goal: Goal,
        currentAmount: Decimal,
        contributions: [GoalContribution]
    ) -> ProgressMetrics {
        
        let progressPercentage = (currentAmount / goal.targetAmount) * 100
        
        // Calculate total contributions and returns
        let totalContributions = contributions.reduce(0) { $0 + $1.amount }
        let totalReturns = currentAmount - totalContributions
        
        // Calculate time metrics
        let timeElapsed = Date().timeIntervalSince(goal.startDate) / (365.25 * 24 * 60 * 60) // Years
        let timeRemaining = max(0, goal.targetDate.timeIntervalSince(Date()) / (365.25 * 24 * 60 * 60))
        
        // Calculate current run rate (annualized contribution rate)
        let currentRunRate = calculateCurrentRunRate(contributions: contributions)
        
        return ProgressMetrics(
            currentAmount: currentAmount,
            targetAmount: goal.targetAmount,
            progressPercentage: progressPercentage,
            totalContributions: totalContributions,
            totalReturns: totalReturns,
            timeElapsed: Decimal(timeElapsed),
            timeRemaining: Decimal(timeRemaining),
            currentRunRate: currentRunRate
        )
    }
    
    /// Calculate current contribution run rate
    private static func calculateCurrentRunRate(contributions: [GoalContribution]) -> Decimal {
        guard !contributions.isEmpty else { return 0 }
        
        // Get contributions from the last 12 months
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let recentContributions = contributions.filter { $0.date >= oneYearAgo }
        
        if recentContributions.isEmpty {
            return 0
        }
        
        let totalRecentContributions = recentContributions.reduce(0) { $0 + $1.amount }
        let timeSpan = Date().timeIntervalSince(recentContributions.first?.date ?? Date()) / (365.25 * 24 * 60 * 60)
        
        if timeSpan > 0 {
            return totalRecentContributions / Decimal(timeSpan)
        } else {
            return totalRecentContributions
        }
    }
    
    // MARK: - Projected Progress Analysis
    
    /// Calculate projected progress metrics
    private static func calculateProjectedProgressMetrics(
        goal: Goal,
        currentAmount: Decimal,
        currentProgress: ProgressMetrics,
        expectedReturn: Decimal,
        marketVolatility: Decimal
    ) -> ProjectionMetrics {
        
        // Project final amount based on current run rate
        let projectedFinalAmount = FutureValueCalculator.calculateInvestmentProjection(
            initialInvestment: currentAmount,
            monthlyContribution: currentProgress.currentRunRate / 12,
            annualReturn: expectedReturn,
            timeInYears: currentProgress.timeRemaining
        ).finalValue
        
        let projectedShortfall = max(0, goal.targetAmount - projectedFinalAmount)
        
        // Calculate probability of success using scenarios
        let scenarios = FutureValueCalculator.calculateGoalAchievementScenarios(
            goalAmount: goal.targetAmount,
            currentAmount: currentAmount,
            monthlyContribution: currentProgress.currentRunRate / 12,
            timeInYears: currentProgress.timeRemaining,
            expectedReturn: expectedReturn,
            returnVolatility: marketVolatility
        )
        
        let probabilityOfSuccess = calculateSuccessProbability(from: scenarios)
        
        // Calculate required run rate to meet goal
        let requiredRunRate = CompoundInterestCalculator.calculateRequiredContribution(
            goalAmount: goal.targetAmount,
            currentAmount: currentAmount,
            annualRate: expectedReturn,
            timeInYears: currentProgress.timeRemaining,
            compoundingFrequency: .monthly
        ) * 12 // Convert to annual
        
        let recommendedAdjustment = requiredRunRate - currentProgress.currentRunRate
        
        // Calculate projected completion date
        let projectedCompletionDate = calculateProjectedCompletionDate(
            goal: goal,
            currentAmount: currentAmount,
            currentRunRate: currentProgress.currentRunRate,
            expectedReturn: expectedReturn
        )
        
        return ProjectionMetrics(
            projectedFinalAmount: projectedFinalAmount,
            projectedShortfall: projectedShortfall,
            probabilityOfSuccess: probabilityOfSuccess,
            requiredRunRate: requiredRunRate,
            recommendedAdjustment: recommendedAdjustment,
            projectedCompletionDate: projectedCompletionDate
        )
    }
    
    /// Calculate success probability from scenarios
    private static func calculateSuccessProbability(from scenarios: [FutureValueCalculator.ScenarioResult]) -> Decimal {
        let successfulScenarios = scenarios.filter { $0.achievesGoal }
        let totalProbability = successfulScenarios.reduce(0) { $0 + $1.probability }
        return totalProbability
    }
    
    /// Calculate projected completion date
    private static func calculateProjectedCompletionDate(
        goal: Goal,
        currentAmount: Decimal,
        currentRunRate: Decimal,
        expectedReturn: Decimal
    ) -> Date? {
        
        guard currentRunRate > 0 else { return nil }
        
        let timeToGoal = CompoundInterestCalculator.calculateTimeToGoal(
            goalAmount: goal.targetAmount,
            currentAmount: currentAmount,
            monthlyContribution: currentRunRate / 12,
            annualRate: expectedReturn
        )
        
        let yearsToGoal = Double(truncating: timeToGoal as NSNumber)
        return Calendar.current.date(byAdding: .day, value: Int(yearsToGoal * 365.25), to: Date())
    }
    
    // MARK: - Milestone Analysis
    
    /// Analyze milestone status
    private static func analyzeMilestoneStatus(
        goal: Goal,
        currentAmount: Decimal,
        projectedProgress: ProjectionMetrics
    ) -> MilestoneStatus {
        
        let sortedMilestones = goal.milestones.sorted { $0.targetDate < $1.targetDate }
        var milestoneProgresses: [MilestoneProgress] = []
        var milestonesAchieved = 0
        var nextMilestone: MilestoneProgress?
        
        for milestone in sortedMilestones {
            let isAchieved = currentAmount >= milestone.targetAmount
            let progressTowardsMilestone = min(100, (currentAmount / milestone.targetAmount) * 100)
            
            if isAchieved {
                milestonesAchieved += 1
            } else if nextMilestone == nil {
                // This is the next milestone to achieve
                nextMilestone = MilestoneProgress(
                    milestone: milestone,
                    isAchieved: false,
                    progressTowardsMilestone: progressTowardsMilestone,
                    projectedAchievementDate: projectedProgress.projectedCompletionDate,
                    daysUntilTarget: Calendar.current.dateComponents([.day], from: Date(), to: milestone.targetDate).day
                )
            }
            
            let milestoneProgress = MilestoneProgress(
                milestone: milestone,
                isAchieved: isAchieved,
                progressTowardsMilestone: progressTowardsMilestone,
                projectedAchievementDate: projectedProgress.projectedCompletionDate,
                daysUntilTarget: Calendar.current.dateComponents([.day], from: Date(), to: milestone.targetDate).day
            )
            
            milestoneProgresses.append(milestoneProgress)
        }
        
        let milestoneCompletionRate = sortedMilestones.isEmpty ? 0 : Decimal(milestonesAchieved) / Decimal(sortedMilestones.count) * 100
        
        return MilestoneStatus(
            milestones: milestoneProgresses,
            nextMilestone: nextMilestone,
            milestonesAchieved: milestonesAchieved,
            totalMilestones: sortedMilestones.count,
            milestoneCompletionRate: milestoneCompletionRate
        )
    }
    
    // MARK: - Recommendations Generation
    
    /// Generate progress recommendations
    private static func generateProgressRecommendations(
        goal: Goal,
        currentProgress: ProgressMetrics,
        projectedProgress: ProjectionMetrics,
        milestoneStatus: MilestoneStatus
    ) -> [ProgressRecommendation] {
        
        var recommendations: [ProgressRecommendation] = []
        
        // Check if on track
        if projectedProgress.probabilityOfSuccess >= 0.8 {
            recommendations.append(.onTrack(message: NSLocalizedString("progress.on_track", comment: "Goal is on track")))
        }
        
        // Check for shortfall
        if projectedProgress.projectedShortfall > 0 {
            let increaseAmount = projectedProgress.recommendedAdjustment
            if increaseAmount > 0 {
                recommendations.append(.increaseContributions(
                    amount: increaseAmount,
                    reason: NSLocalizedString("progress.increase_reason", comment: "To meet goal target")
                ))
            }
        }
        
        // Check for timeline adjustment needs
        if projectedProgress.probabilityOfSuccess < 0.5 && currentProgress.timeRemaining < 1 {
            if let newDeadline = Calendar.current.date(byAdding: .year, value: 1, to: goal.targetDate) {
                recommendations.append(.adjustTimeline(
                    newDeadline: newDeadline,
                    reason: NSLocalizedString("progress.timeline_reason", comment: "To improve success probability")
                ))
            }
        }
        
        // Check for milestone celebrations
        if let nextMilestone = milestoneStatus.nextMilestone,
           nextMilestone.progressTowardsMilestone >= 95 {
            recommendations.append(.celebrateMilestone(
                milestone: nextMilestone.milestone,
                message: NSLocalizedString("progress.milestone_close", comment: "Milestone is almost achieved")
            ))
        }
        
        // Return optimization recommendation
        if projectedProgress.probabilityOfSuccess < 0.7 {
            recommendations.append(.optimizeReturns(
                targetRate: 0.15, // Suggest higher return target
                reason: NSLocalizedString("progress.optimize_reason", comment: "To improve goal achievement probability")
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Risk Assessment
    
    /// Assess goal achievement risks
    private static func assessGoalRisks(
        goal: Goal,
        currentProgress: ProgressMetrics,
        projectedProgress: ProjectionMetrics,
        marketVolatility: Decimal
    ) -> RiskAssessment {
        
        // Calculate individual risk components
        let timeRisk = calculateTimeRisk(currentProgress: currentProgress)
        let amountRisk = calculateAmountRisk(projectedProgress: projectedProgress)
        let marketRisk = marketVolatility
        let inflationRisk = calculateInflationRisk(goal: goal, currentProgress: currentProgress)
        
        // Determine overall risk level
        let overallRisk = (timeRisk + amountRisk + marketRisk + inflationRisk) / 4
        let overallRiskLevel: RiskLevel
        
        switch overallRisk {
        case 0..<0.25:
            overallRiskLevel = .low
        case 0.25..<0.5:
            overallRiskLevel = .moderate
        case 0.5..<0.75:
            overallRiskLevel = .high
        default:
            overallRiskLevel = .critical
        }
        
        // Generate mitigation strategies
        let mitigationStrategies = generateMitigationStrategies(
            timeRisk: timeRisk,
            amountRisk: amountRisk,
            marketRisk: marketRisk,
            inflationRisk: inflationRisk
        )
        
        return RiskAssessment(
            overallRiskLevel: overallRiskLevel,
            timeRisk: timeRisk,
            amountRisk: amountRisk,
            marketRisk: marketRisk,
            inflationRisk: inflationRisk,
            mitigationStrategies: mitigationStrategies
        )
    }
    
    /// Calculate time-based risk
    private static func calculateTimeRisk(currentProgress: ProgressMetrics) -> Decimal {
        if currentProgress.timeRemaining <= 0 {
            return 1.0 // Maximum risk if time has passed
        }
        
        // Risk increases as time remaining decreases relative to progress needed
        let progressRatio = currentProgress.progressPercentage / 100
        let timeRatio = 1 - (currentProgress.timeRemaining / (currentProgress.timeElapsed + currentProgress.timeRemaining))
        
        return max(0, timeRatio - progressRatio)
    }
    
    /// Calculate amount-based risk
    private static func calculateAmountRisk(projectedProgress: ProjectionMetrics) -> Decimal {
        let shortfallRatio = projectedProgress.projectedShortfall / projectedProgress.projectedFinalAmount
        return min(1.0, shortfallRatio)
    }
    
    /// Calculate inflation risk
    private static func calculateInflationRisk(goal: Goal, currentProgress: ProgressMetrics) -> Decimal {
        // Assume 3% inflation rate for risk calculation
        let _: Decimal = 0.03 // assumedInflationRate
        let inflationImpact = pow(1.03, Double(truncating: currentProgress.timeRemaining as NSNumber)) - 1
        return min(1.0, Decimal(inflationImpact))
    }
    
    /// Generate risk mitigation strategies
    private static func generateMitigationStrategies(
        timeRisk: Decimal,
        amountRisk: Decimal,
        marketRisk: Decimal,
        inflationRisk: Decimal
    ) -> [String] {
        
        var strategies: [String] = []
        
        if timeRisk > 0.5 {
            strategies.append(NSLocalizedString("mitigation.time_risk", comment: "Consider extending timeline or increasing contributions"))
        }
        
        if amountRisk > 0.5 {
            strategies.append(NSLocalizedString("mitigation.amount_risk", comment: "Increase monthly contributions or initial investment"))
        }
        
        if marketRisk > 0.2 {
            strategies.append(NSLocalizedString("mitigation.market_risk", comment: "Diversify investments to reduce volatility"))
        }
        
        if inflationRisk > 0.3 {
            strategies.append(NSLocalizedString("mitigation.inflation_risk", comment: "Consider inflation-protected investments"))
        }
        
        return strategies
    }
}