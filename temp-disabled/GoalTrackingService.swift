//
//  GoalTrackingService.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import Foundation
import SwiftData
import Combine

/// Comprehensive goal tracking service that manages all aspects of financial goal monitoring,
/// progress analysis, and recommendation generation for wealth management.
@MainActor
public final class GoalTrackingService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently tracked goals
    @Published public private(set) var activeGoals: [Goal] = []
    
    /// Goal progress analyses
    @Published public private(set) var goalAnalyses: [UUID: GoalProgressCalculator.GoalProgressAnalysis] = [:]
    
    /// Service status
    @Published public private(set) var isLoading: Bool = false
    
    /// Last update timestamp
    @Published public private(set) var lastUpdated: Date?
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let calculationQueue = DispatchQueue(label: "goal-calculations", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    /// Service configuration
    public struct Configuration: Sendable {
        public let defaultExpectedReturn: Decimal
        public let defaultMarketVolatility: Decimal
        public let defaultInflationRate: Decimal
        public let updateInterval: TimeInterval
        public let enableAutomaticUpdates: Bool
        
        /// Initialize configuration with default values
        public init(
            defaultExpectedReturn: Decimal = 0.12, // 12% default return
            defaultMarketVolatility: Decimal = 0.15, // 15% volatility
            defaultInflationRate: Decimal = 0.03, // 3% inflation
            updateInterval: TimeInterval = 3600, // 1 hour
            enableAutomaticUpdates: Bool = true
        ) {
            self.defaultExpectedReturn = defaultExpectedReturn
            self.defaultMarketVolatility = defaultMarketVolatility
            self.defaultInflationRate = defaultInflationRate
            self.updateInterval = updateInterval
            self.enableAutomaticUpdates = enableAutomaticUpdates
        }
        
        /// Default configuration for Indian market
        public static let indianMarket = Configuration(
            defaultExpectedReturn: 0.12, // 12% for Indian equity markets
            defaultMarketVolatility: 0.18, // Higher volatility for emerging markets
            defaultInflationRate: 0.05, // 5% inflation for India
            updateInterval: 1800, // 30 minutes for active markets
            enableAutomaticUpdates: true
        )
        
        /// Conservative configuration for risk-averse users
        public static let conservative = Configuration(
            defaultExpectedReturn: 0.07, // 7% conservative return
            defaultMarketVolatility: 0.10, // Lower volatility
            defaultInflationRate: 0.03, // Standard inflation
            updateInterval: 7200, // 2 hours
            enableAutomaticUpdates: true
        )
    }
    
    private let configuration: Configuration
    
    // MARK: - Initialization
    
    /// Initialize goal tracking service
    /// - Parameters:
    ///   - modelContext: SwiftData model context for persistence
    ///   - configuration: Service configuration
    public init(modelContext: ModelContext, configuration: Configuration = .indianMarket) {
        self.modelContext = modelContext
        self.configuration = configuration
        
        setupAutomaticUpdates()
        loadActiveGoals()
    }
    
    // MARK: - Goal Management
    
    /// Add a new goal to tracking
    /// - Parameter goal: Goal to start tracking
    public func startTrackingGoal(_ goal: Goal) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Save goal to persistence
        modelContext.insert(goal)
        try modelContext.save()
        
        // Add to active goals
        activeGoals.append(goal)
        
        // Calculate initial progress
        await updateGoalProgress(for: goal)
        
        // Log goal creation
        print("Started tracking goal: \(goal.title) - Target: ₹\(goal.targetAmount) by \(goal.targetDate)")
    }
    
    /// Stop tracking a goal
    /// - Parameter goalId: ID of the goal to stop tracking
    public func stopTrackingGoal(goalId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Remove from active goals
        activeGoals.removeAll { $0.id == goalId }
        
        // Remove analysis
        goalAnalyses.removeValue(forKey: goalId)
        
        // Remove from persistence (optional - could mark as inactive instead)
        if let goal = try modelContext.fetch(FetchDescriptor<Goal>()).first(where: { $0.id == goalId }) {
            modelContext.delete(goal)
            try modelContext.save()
        }
        
        print("Stopped tracking goal: \(goalId)")
    }
    
    /// Update goal parameters
    /// - Parameters:
    ///   - goalId: ID of the goal to update
    ///   - updates: Closure that modifies the goal
    public func updateGoal(goalId: UUID, updates: @escaping (inout Goal) -> Void) async throws {
        guard let goalIndex = activeGoals.firstIndex(where: { $0.id == goalId }) else {
            throw GoalTrackingError.goalNotFound(goalId)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Apply updates
        var goal = activeGoals[goalIndex]
        updates(&goal)
        
        // Update in active goals
        activeGoals[goalIndex] = goal
        
        // Update persistence
        try modelContext.save()
        
        // Recalculate progress
        await updateGoalProgress(for: goal)
        
        print("Updated goal: \(goal.title)")
    }
    
    /// Add contribution to a goal
    /// - Parameters:
    ///   - goalId: ID of the goal
    ///   - amount: Contribution amount
    ///   - date: Contribution date (defaults to now)
    ///   - description: Optional contribution description
    public func addContribution(
        to goalId: UUID,
        amount: Decimal,
        date: Date = Date(),
        description: String? = nil
    ) async throws {
        
        guard let goalIndex = activeGoals.firstIndex(where: { $0.id == goalId }) else {
            throw GoalTrackingError.goalNotFound(goalId)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Create contribution
        let goal = activeGoals[goalIndex]
        let contribution = GoalContribution(
            id: UUID(),
            amount: amount,
            date: date,
            description: description ?? NSLocalizedString("contribution.default_description", comment: "Regular contribution"),
            currency: goal.targetCurrency
        )
        
        // Add to goal
        goal.contributions.append(contribution)
        
        // Update persistence
        try modelContext.save()
        
        // Recalculate progress
        await updateGoalProgress(for: goal)
        
        print("Added contribution of ₹\(amount) to goal: \(goal.title)")
    }
    
    // MARK: - Progress Tracking
    
    /// Update progress for all active goals
    public func updateAllGoalProgress() async {
        isLoading = true
        defer { 
            isLoading = false
            lastUpdated = Date()
        }
        
        // Update goals sequentially to avoid data races with @MainActor isolation
        for goal in activeGoals {
            await updateGoalProgress(for: goal)
        }
        
        print("Updated progress for \(activeGoals.count) goals")
    }
    
    /// Update progress for a specific goal
    /// - Parameter goal: Goal to update progress for
    public func updateGoalProgress(for goal: Goal) async {
        let currentAmount = calculateCurrentGoalAmount(for: goal)
        
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: goal,
            currentAmount: currentAmount,
            contributions: goal.contributions,
            expectedReturn: configuration.defaultExpectedReturn,
            marketVolatility: configuration.defaultMarketVolatility
        )
        
        goalAnalyses[goal.id] = analysis
        
        // Check for milestone achievements
        await checkMilestoneAchievements(for: goal, analysis: analysis)
        
        // Generate notifications if needed
        await generateProgressNotifications(for: goal, analysis: analysis)
    }
    
    /// Calculate current amount for a goal based on contributions and returns
    /// - Parameter goal: Goal to calculate amount for
    /// - Returns: Current accumulated amount
    private func calculateCurrentGoalAmount(for goal: Goal) -> Decimal {
        // In a real implementation, this would integrate with portfolio data
        // For now, we'll use the current amount from the goal itself
        return goal.currentAmount
    }
    
    // MARK: - Milestone Tracking
    
    /// Check for milestone achievements and trigger celebrations
    /// - Parameters:
    ///   - goal: Goal to check milestones for
    ///   - analysis: Current progress analysis
    private func checkMilestoneAchievements(for goal: Goal, analysis: GoalProgressCalculator.GoalProgressAnalysis) async {
        for milestoneProgress in analysis.milestoneStatus.milestones {
            if milestoneProgress.isAchieved && !milestoneProgress.milestone.isAchieved {
                // Milestone newly achieved
                await celebrateMilestoneAchievement(goal: goal, milestone: milestoneProgress.milestone)
            }
        }
    }
    
    /// Celebrate milestone achievement
    /// - Parameters:
    ///   - goal: Goal that achieved milestone
    ///   - milestone: Milestone that was achieved
    private func celebrateMilestoneAchievement(goal: Goal, milestone: GoalMilestone) async {
        // Mark milestone as achieved
        if let goalIndex = activeGoals.firstIndex(where: { $0.id == goal.id }),
           let milestoneIndex = activeGoals[goalIndex].milestones.firstIndex(where: { $0.id == milestone.id }) {
            activeGoals[goalIndex].milestones[milestoneIndex].isAchieved = true
        }
        
        // Generate celebration notification
        print("🎉 Milestone achieved! \(milestone.description ?? milestone.title) for goal: \(goal.title)")
        
        // In a real implementation, this would trigger UI celebrations, notifications, etc.
    }
    
    // MARK: - Contribution Optimization
    
    /// Calculate optimal contribution strategy for a goal
    /// - Parameter goalId: ID of the goal to optimize
    /// - Returns: Contribution optimization result
    public func calculateOptimalContributionStrategy(for goalId: UUID) async throws -> ContributionOptimizationResult {
        guard let goal = activeGoals.first(where: { $0.id == goalId }) else {
            throw GoalTrackingError.goalNotFound(goalId)
        }
        
        let currentAmount = calculateCurrentGoalAmount(for: goal)
        let timeRemaining = goal.targetDate.timeIntervalSince(Date()) / (365.25 * 24 * 60 * 60)
        
        // Calculate different contribution scenarios
        let scenarios = await calculateContributionScenarios(
            goal: goal,
            currentAmount: currentAmount,
            timeRemaining: Decimal(timeRemaining)
        )
        
        return ContributionOptimizationResult(
            goal: goal,
            currentAmount: currentAmount,
            timeRemaining: Decimal(timeRemaining),
            scenarios: scenarios,
            recommendedScenario: selectOptimalScenario(from: scenarios)
        )
    }
    
    /// Calculate different contribution scenarios
    private func calculateContributionScenarios(
        goal: Goal,
        currentAmount: Decimal,
        timeRemaining: Decimal
    ) async -> [ContributionScenario] {
        
        var scenarios: [ContributionScenario] = []
        
        // Minimum contribution scenario
        let minContribution = CompoundInterestCalculator.calculateRequiredContribution(
            goalAmount: goal.targetAmount,
            currentAmount: currentAmount,
            annualRate: configuration.defaultExpectedReturn,
            timeInYears: timeRemaining,
            compoundingFrequency: .monthly
        )
        
        scenarios.append(ContributionScenario(
            name: NSLocalizedString("scenario.minimum", comment: "Minimum contribution scenario"),
            monthlyContribution: minContribution,
            probabilityOfSuccess: 0.5,
            totalContributions: minContribution * 12 * timeRemaining,
            projectedFinalAmount: goal.targetAmount
        ))
        
        // Conservative scenario (20% buffer)
        let conservativeContribution = minContribution * 1.2
        let projectedConservative = FutureValueCalculator.calculateInvestmentProjection(
            initialInvestment: currentAmount,
            monthlyContribution: conservativeContribution,
            annualReturn: configuration.defaultExpectedReturn,
            timeInYears: timeRemaining
        )
        
        scenarios.append(ContributionScenario(
            name: NSLocalizedString("scenario.conservative", comment: "Conservative contribution scenario"),
            monthlyContribution: conservativeContribution,
            probabilityOfSuccess: 0.75,
            totalContributions: conservativeContribution * 12 * timeRemaining,
            projectedFinalAmount: projectedConservative.finalValue
        ))
        
        // Aggressive scenario (50% buffer)
        let aggressiveContribution = minContribution * 1.5
        let projectedAggressive = FutureValueCalculator.calculateInvestmentProjection(
            initialInvestment: currentAmount,
            monthlyContribution: aggressiveContribution,
            annualReturn: configuration.defaultExpectedReturn,
            timeInYears: timeRemaining
        )
        
        scenarios.append(ContributionScenario(
            name: NSLocalizedString("scenario.aggressive", comment: "Aggressive contribution scenario"),
            monthlyContribution: aggressiveContribution,
            probabilityOfSuccess: 0.90,
            totalContributions: aggressiveContribution * 12 * timeRemaining,
            projectedFinalAmount: projectedAggressive.finalValue
        ))
        
        return scenarios
    }
    
    /// Select optimal scenario based on user preferences
    private func selectOptimalScenario(from scenarios: [ContributionScenario]) -> ContributionScenario {
        // For now, select the conservative scenario as optimal
        // In a real implementation, this would consider user risk profile
        return scenarios.first { $0.name.contains("Conservative") } ?? scenarios.first!
    }
    
    // MARK: - Notifications
    
    /// Generate progress notifications for a goal
    /// - Parameters:
    ///   - goal: Goal to generate notifications for
    ///   - analysis: Current progress analysis
    private func generateProgressNotifications(for goal: Goal, analysis: GoalProgressCalculator.GoalProgressAnalysis) async {
        // Check for significant progress updates
        if analysis.currentProgress.progressPercentage >= 25 && analysis.currentProgress.progressPercentage < 26 {
            print("📊 25% progress achieved for goal: \(goal.title)")
        }
        
        if analysis.currentProgress.progressPercentage >= 50 && analysis.currentProgress.progressPercentage < 51 {
            print("📊 50% progress achieved for goal: \(goal.title)")
        }
        
        if analysis.currentProgress.progressPercentage >= 75 && analysis.currentProgress.progressPercentage < 76 {
            print("📊 75% progress achieved for goal: \(goal.title)")
        }
        
        // Check for risk warnings
        if analysis.riskAssessment.overallRiskLevel == .high || analysis.riskAssessment.overallRiskLevel == .critical {
            print("⚠️ High risk detected for goal: \(goal.title)")
        }
        
        // Check for deadline proximity
        if analysis.currentProgress.timeRemaining < 0.25 && analysis.currentProgress.progressPercentage < 80 {
            print("⏰ Goal deadline approaching with insufficient progress: \(goal.title)")
        }
    }
    
    // MARK: - Reporting
    
    /// Generate comprehensive goal report
    /// - Parameter goalId: ID of the goal to generate report for
    /// - Returns: Goal report
    public func generateGoalReport(for goalId: UUID) async throws -> GoalReport {
        guard let goal = activeGoals.first(where: { $0.id == goalId }),
              let analysis = goalAnalyses[goalId] else {
            throw GoalTrackingError.goalNotFound(goalId)
        }
        
        let optimizationResult = try await calculateOptimalContributionStrategy(for: goalId)
        
        return GoalReport(
            goal: goal,
            analysis: analysis,
            optimizationResult: optimizationResult,
            generatedDate: Date()
        )
    }
    
    /// Generate portfolio-wide goals summary
    /// - Returns: Goals summary report
    public func generateGoalsSummary() async -> GoalsSummaryReport {
        let totalGoals = activeGoals.count
        let achievedGoals = activeGoals.filter { goal in
            guard let analysis = goalAnalyses[goal.id] else { return false }
            return analysis.currentProgress.progressPercentage >= 100
        }.count
        
        let totalTargetAmount = activeGoals.reduce(0) { $0 + $1.targetAmount }
        let totalCurrentAmount = activeGoals.reduce(0) { sum, goal in
            sum + calculateCurrentGoalAmount(for: goal)
        }
        
        let overallProgress = totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) * 100 : 0
        
        return GoalsSummaryReport(
            totalGoals: totalGoals,
            achievedGoals: achievedGoals,
            totalTargetAmount: totalTargetAmount,
            totalCurrentAmount: totalCurrentAmount,
            overallProgressPercentage: overallProgress,
            generatedDate: Date()
        )
    }
    
    // MARK: - Private Setup
    
    /// Setup automatic updates if enabled
    private func setupAutomaticUpdates() {
        guard configuration.enableAutomaticUpdates else { return }
        
        Timer.publish(every: configuration.updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.updateAllGoalProgress()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Load active goals from persistence
    private func loadActiveGoals() {
        do {
            let fetchDescriptor = FetchDescriptor<Goal>()
            activeGoals = try modelContext.fetch(fetchDescriptor)
            
            // Calculate initial progress for loaded goals
            Task {
                await updateAllGoalProgress()
            }
        } catch {
            print("Failed to load active goals: \(error)")
        }
    }
}

// MARK: - Supporting Data Structures

/// Contribution optimization result
public struct ContributionOptimizationResult: Sendable {
    public let goal: Goal
    public let currentAmount: Decimal
    public let timeRemaining: Decimal
    public let scenarios: [ContributionScenario]
    public let recommendedScenario: ContributionScenario
    
    /// Initialize contribution optimization result
    public init(goal: Goal, currentAmount: Decimal, timeRemaining: Decimal, scenarios: [ContributionScenario], recommendedScenario: ContributionScenario) {
        self.goal = goal
        self.currentAmount = currentAmount
        self.timeRemaining = timeRemaining
        self.scenarios = scenarios
        self.recommendedScenario = recommendedScenario
    }
}

/// Contribution scenario
public struct ContributionScenario: Sendable {
    public let name: String
    public let monthlyContribution: Decimal
    public let probabilityOfSuccess: Decimal
    public let totalContributions: Decimal
    public let projectedFinalAmount: Decimal
    
    /// Initialize contribution scenario
    public init(name: String, monthlyContribution: Decimal, probabilityOfSuccess: Decimal, totalContributions: Decimal, projectedFinalAmount: Decimal) {
        self.name = name
        self.monthlyContribution = monthlyContribution
        self.probabilityOfSuccess = probabilityOfSuccess
        self.totalContributions = totalContributions
        self.projectedFinalAmount = projectedFinalAmount
    }
}

/// Goal report
public struct GoalReport: Sendable {
    public let goal: Goal
    public let analysis: GoalProgressCalculator.GoalProgressAnalysis
    public let optimizationResult: ContributionOptimizationResult
    public let generatedDate: Date
    
    /// Initialize goal report
    public init(goal: Goal, analysis: GoalProgressCalculator.GoalProgressAnalysis, optimizationResult: ContributionOptimizationResult, generatedDate: Date) {
        self.goal = goal
        self.analysis = analysis
        self.optimizationResult = optimizationResult
        self.generatedDate = generatedDate
    }
}

/// Goals summary report
public struct GoalsSummaryReport: Sendable {
    public let totalGoals: Int
    public let achievedGoals: Int
    public let totalTargetAmount: Decimal
    public let totalCurrentAmount: Decimal
    public let overallProgressPercentage: Decimal
    public let generatedDate: Date
    
    /// Initialize goals summary report
    public init(totalGoals: Int, achievedGoals: Int, totalTargetAmount: Decimal, totalCurrentAmount: Decimal, overallProgressPercentage: Decimal, generatedDate: Date) {
        self.totalGoals = totalGoals
        self.achievedGoals = achievedGoals
        self.totalTargetAmount = totalTargetAmount
        self.totalCurrentAmount = totalCurrentAmount
        self.overallProgressPercentage = overallProgressPercentage
        self.generatedDate = generatedDate
    }
}

/// Goal tracking errors
public enum GoalTrackingError: LocalizedError {
    case goalNotFound(UUID)
    case invalidGoalParameters(String)
    case calculationError(String)
    case persistenceError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .goalNotFound(let id):
            return NSLocalizedString("error.goal_not_found", comment: "Goal not found: \(id)")
        case .invalidGoalParameters(let message):
            return NSLocalizedString("error.invalid_parameters", comment: "Invalid parameters: \(message)")
        case .calculationError(let message):
            return NSLocalizedString("error.calculation_failed", comment: "Calculation failed: \(message)")
        case .persistenceError(let error):
            return NSLocalizedString("error.persistence_failed", comment: "Persistence failed: \(error.localizedDescription)")
        }
    }
}