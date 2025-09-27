//
//  GoalTrackingServiceTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import XCTest
import SwiftData
@testable import WealthWise

/// Comprehensive test suite for Goal Tracking Service functionality
@MainActor
final class GoalTrackingServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var modelContext: ModelContext!
    private var goalTrackingService: GoalTrackingService!
    private var testGoal: Goal!
    
    // MARK: - Test Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model context for testing
        let schema = Schema([Goal.self, Transaction.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // Initialize service with test configuration
        let testConfiguration = GoalTrackingService.Configuration(
            defaultExpectedReturn: 0.12,
            defaultMarketVolatility: 0.15,
            defaultInflationRate: 0.03,
            updateInterval: 3600,
            enableAutomaticUpdates: false // Disable for testing
        )
        
        goalTrackingService = GoalTrackingService(
            modelContext: modelContext,
            configuration: testConfiguration
        )
        
        // Create test goal
        testGoal = createTestGoal()
    }
    
    override func tearDown() async throws {
        goalTrackingService = nil
        modelContext = nil
        testGoal = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Create a test goal for "5cr in 3 years" scenario
    private func createTestGoal() -> Goal {
        let startDate = Date()
        let deadline = Calendar.current.date(byAdding: .year, value: 3, to: startDate)!
        
        let goal = Goal.createFiveCroreGoal()
        goal.startDate = startDate
        goal.deadline = deadline
        
        return goal
    }
    
    /// Create test contributions
    private func createTestContributions(goal: Goal, monthlyAmount: Decimal, months: Int) -> [Goal.Contribution] {
        var contributions: [Goal.Contribution] = []
        
        for month in 0..<months {
            let contributionDate = Calendar.current.date(byAdding: .month, value: month, to: goal.startDate)!
            let contribution = Goal.Contribution(
                id: UUID(),
                amount: monthlyAmount,
                date: contributionDate,
                description: "Test contribution \(month + 1)"
            )
            contributions.append(contribution)
        }
        
        return contributions
    }
    
    // MARK: - Goal Management Tests
    
    func testStartTrackingGoal() async throws {
        // Given
        XCTAssertEqual(goalTrackingService.activeGoals.count, 0)
        
        // When
        try await goalTrackingService.startTrackingGoal(testGoal)
        
        // Then
        XCTAssertEqual(goalTrackingService.activeGoals.count, 1)
        XCTAssertEqual(goalTrackingService.activeGoals.first?.id, testGoal.id)
        XCTAssertEqual(goalTrackingService.activeGoals.first?.title, testGoal.title)
        XCTAssertEqual(goalTrackingService.activeGoals.first?.targetAmount, testGoal.targetAmount)
        
        // Verify goal analysis was created
        XCTAssertNotNil(goalTrackingService.goalAnalyses[testGoal.id])
    }
    
    func testStopTrackingGoal() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        XCTAssertEqual(goalTrackingService.activeGoals.count, 1)
        
        // When
        try await goalTrackingService.stopTrackingGoal(goalId: testGoal.id)
        
        // Then
        XCTAssertEqual(goalTrackingService.activeGoals.count, 0)
        XCTAssertNil(goalTrackingService.goalAnalyses[testGoal.id])
    }
    
    func testUpdateGoal() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        let originalTitle = testGoal.title
        let newTitle = "Updated Goal Title"
        
        // When
        try await goalTrackingService.updateGoal(goalId: testGoal.id) { goal in
            goal.title = newTitle
        }
        
        // Then
        XCTAssertNotEqual(goalTrackingService.activeGoals.first?.title, originalTitle)
        XCTAssertEqual(goalTrackingService.activeGoals.first?.title, newTitle)
    }
    
    func testAddContribution() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        let contributionAmount: Decimal = 50000
        let initialContributionsCount = testGoal.contributions.count
        
        // When
        try await goalTrackingService.addContribution(
            to: testGoal.id,
            amount: contributionAmount,
            description: "Test contribution"
        )
        
        // Then
        let updatedGoal = goalTrackingService.activeGoals.first { $0.id == testGoal.id }
        XCTAssertNotNil(updatedGoal)
        XCTAssertEqual(updatedGoal?.contributions.count, initialContributionsCount + 1)
        
        let lastContribution = updatedGoal?.contributions.last
        XCTAssertEqual(lastContribution?.amount, contributionAmount)
        XCTAssertEqual(lastContribution?.description, "Test contribution")
    }
    
    // MARK: - Progress Tracking Tests
    
    func testCalculateGoalProgressWithNoContributions() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        
        // When
        await goalTrackingService.updateGoalProgress(for: testGoal)
        
        // Then
        let analysis = goalTrackingService.goalAnalyses[testGoal.id]
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis?.currentProgress.currentAmount, 0)
        XCTAssertEqual(analysis?.currentProgress.progressPercentage, 0)
        XCTAssertEqual(analysis?.currentProgress.totalContributions, 0)
    }
    
    func testCalculateGoalProgressWithContributions() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        
        // Add some contributions
        let monthlyContribution: Decimal = 100000 // ₹1L per month
        for i in 0..<12 { // 12 months of contributions
            try await goalTrackingService.addContribution(
                to: testGoal.id,
                amount: monthlyContribution,
                date: Calendar.current.date(byAdding: .month, value: i, to: testGoal.startDate)!
            )
        }
        
        // When
        await goalTrackingService.updateGoalProgress(for: testGoal)
        
        // Then
        let analysis = goalTrackingService.goalAnalyses[testGoal.id]
        XCTAssertNotNil(analysis)
        XCTAssertGreaterThan(analysis!.currentProgress.currentAmount, 0)
        XCTAssertGreaterThan(analysis!.currentProgress.progressPercentage, 0)
        XCTAssertEqual(analysis!.currentProgress.totalContributions, monthlyContribution * 12)
    }
    
    func testUpdateAllGoalProgress() async throws {
        // Given
        let goal1 = createTestGoal()
        let goal2 = createTestGoal()
        goal2.title = "Second Test Goal"
        
        try await goalTrackingService.startTrackingGoal(goal1)
        try await goalTrackingService.startTrackingGoal(goal2)
        
        // When
        await goalTrackingService.updateAllGoalProgress()
        
        // Then
        XCTAssertNotNil(goalTrackingService.goalAnalyses[goal1.id])
        XCTAssertNotNil(goalTrackingService.goalAnalyses[goal2.id])
        XCTAssertNotNil(goalTrackingService.lastUpdated)
    }
    
    // MARK: - Contribution Optimization Tests
    
    func testCalculateOptimalContributionStrategy() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        
        // Add some initial contributions
        try await goalTrackingService.addContribution(to: testGoal.id, amount: 500000) // ₹5L initial
        
        // When
        let optimizationResult = try await goalTrackingService.calculateOptimalContributionStrategy(for: testGoal.id)
        
        // Then
        XCTAssertEqual(optimizationResult.goal.id, testGoal.id)
        XCTAssertGreaterThan(optimizationResult.scenarios.count, 0)
        XCTAssertNotNil(optimizationResult.recommendedScenario)
        
        // Validate scenarios
        for scenario in optimizationResult.scenarios {
            XCTAssertGreaterThan(scenario.monthlyContribution, 0)
            XCTAssertGreaterThanOrEqual(scenario.probabilityOfSuccess, 0)
            XCTAssertLessThanOrEqual(scenario.probabilityOfSuccess, 1)
        }
    }
    
    func testContributionScenarioProgression() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        
        // When
        let optimizationResult = try await goalTrackingService.calculateOptimalContributionStrategy(for: testGoal.id)
        
        // Then
        let scenarios = optimizationResult.scenarios.sorted { $0.monthlyContribution < $1.monthlyContribution }
        
        // Verify that higher contributions lead to higher success probability
        for i in 1..<scenarios.count {
            XCTAssertGreaterThanOrEqual(
                scenarios[i].probabilityOfSuccess,
                scenarios[i-1].probabilityOfSuccess,
                "Higher contributions should lead to higher success probability"
            )
        }
    }
    
    // MARK: - Milestone Tracking Tests
    
    func testMilestoneProgressTracking() async throws {
        // Given
        // Create a goal with milestones
        let goalWithMilestones = createTestGoal()
        let milestoneDate1 = Calendar.current.date(byAdding: .year, value: 1, to: goalWithMilestones.startDate)!
        let milestoneDate2 = Calendar.current.date(byAdding: .year, value: 2, to: goalWithMilestones.startDate)!
        
        let milestone1 = Goal.Milestone(
            id: UUID(),
            description: "25% Progress",
            targetAmount: goalWithMilestones.targetAmount * 0.25,
            targetDate: milestoneDate1,
            isAchieved: false
        )
        
        let milestone2 = Goal.Milestone(
            id: UUID(),
            description: "50% Progress",
            targetAmount: goalWithMilestones.targetAmount * 0.5,
            targetDate: milestoneDate2,
            isAchieved: false
        )
        
        goalWithMilestones.milestones = [milestone1, milestone2]
        
        try await goalTrackingService.startTrackingGoal(goalWithMilestones)
        
        // When
        await goalTrackingService.updateGoalProgress(for: goalWithMilestones)
        
        // Then
        let analysis = goalTrackingService.goalAnalyses[goalWithMilestones.id]
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis!.milestoneStatus.totalMilestones, 2)
        XCTAssertEqual(analysis!.milestoneStatus.milestonesAchieved, 0) // No contributions yet
        XCTAssertNotNil(analysis!.milestoneStatus.nextMilestone)
    }
    
    // MARK: - Reporting Tests
    
    func testGenerateGoalReport() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        try await goalTrackingService.addContribution(to: testGoal.id, amount: 1000000) // ₹10L
        
        // When
        let report = try await goalTrackingService.generateGoalReport(for: testGoal.id)
        
        // Then
        XCTAssertEqual(report.goal.id, testGoal.id)
        XCTAssertNotNil(report.analysis)
        XCTAssertNotNil(report.optimizationResult)
        XCTAssertLessThanOrEqual(report.generatedDate.timeIntervalSinceNow, 1) // Generated recently
        
        // Validate analysis completeness
        let analysis = report.analysis
        XCTAssertGreaterThan(analysis.currentProgress.currentAmount, 0)
        XCTAssertGreaterThan(analysis.projectedProgress.projectedFinalAmount, 0)
        XCTAssertNotNil(analysis.riskAssessment)
        XCTAssertGreaterThan(analysis.recommendations.count, 0)
    }
    
    func testGenerateGoalsSummary() async throws {
        // Given
        let goal1 = createTestGoal()
        let goal2 = createTestGoal()
        goal2.title = "Second Goal"
        goal2.targetAmount = 2000000 // ₹20L
        
        try await goalTrackingService.startTrackingGoal(goal1)
        try await goalTrackingService.startTrackingGoal(goal2)
        
        // Add contributions to both goals
        try await goalTrackingService.addContribution(to: goal1.id, amount: 500000)
        try await goalTrackingService.addContribution(to: goal2.id, amount: 200000)
        
        // When
        let summary = await goalTrackingService.generateGoalsSummary()
        
        // Then
        XCTAssertEqual(summary.totalGoals, 2)
        XCTAssertEqual(summary.achievedGoals, 0) // Neither goal achieved yet
        XCTAssertEqual(summary.totalTargetAmount, goal1.targetAmount + goal2.targetAmount)
        XCTAssertGreaterThan(summary.totalCurrentAmount, 0)
        XCTAssertGreaterThan(summary.overallProgressPercentage, 0)
        XCTAssertLessThanOrEqual(summary.generatedDate.timeIntervalSinceNow, 1)
    }
    
    // MARK: - Error Handling Tests
    
    func testGoalNotFoundError() async throws {
        // Given
        let nonExistentGoalId = UUID()
        
        // When & Then
        do {
            try await goalTrackingService.stopTrackingGoal(goalId: nonExistentGoalId)
            XCTFail("Expected error to be thrown")
        } catch GoalTrackingError.goalNotFound(let id) {
            XCTAssertEqual(id, nonExistentGoalId)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testAddContributionToNonExistentGoal() async throws {
        // Given
        let nonExistentGoalId = UUID()
        
        // When & Then
        do {
            try await goalTrackingService.addContribution(to: nonExistentGoalId, amount: 1000)
            XCTFail("Expected error to be thrown")
        } catch GoalTrackingError.goalNotFound(let id) {
            XCTAssertEqual(id, nonExistentGoalId)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testGoalProgressCalculationPerformance() async throws {
        // Given
        try await goalTrackingService.startTrackingGoal(testGoal)
        
        // Add many contributions to simulate real usage
        for i in 0..<100 {
            try await goalTrackingService.addContribution(
                to: testGoal.id,
                amount: Decimal(10000 + i * 100),
                date: Calendar.current.date(byAdding: .day, value: i, to: testGoal.startDate)!
            )
        }
        
        // When & Then
        measure {
            Task {
                await goalTrackingService.updateGoalProgress(for: testGoal)
            }
        }
    }
    
    func testMultipleGoalsProgressUpdatePerformance() async throws {
        // Given
        var goals: [Goal] = []
        for i in 0..<10 {
            let goal = createTestGoal()
            goal.title = "Performance Test Goal \(i)"
            goals.append(goal)
            try await goalTrackingService.startTrackingGoal(goal)
        }
        
        // When & Then
        measure {
            Task {
                await goalTrackingService.updateAllGoalProgress()
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testCompleteGoalLifecycle() async throws {
        // Given - Create and start tracking goal
        try await goalTrackingService.startTrackingGoal(testGoal)
        
        // When - Add regular contributions over time
        let monthlyContribution: Decimal = 120000 // ₹1.2L per month
        for month in 0..<36 { // 3 years of contributions
            try await goalTrackingService.addContribution(
                to: testGoal.id,
                amount: monthlyContribution,
                date: Calendar.current.date(byAdding: .month, value: month, to: testGoal.startDate)!
            )
        }
        
        // Update progress
        await goalTrackingService.updateGoalProgress(for: testGoal)
        
        // Then - Verify goal completion
        let analysis = goalTrackingService.goalAnalyses[testGoal.id]
        XCTAssertNotNil(analysis)
        
        let currentProgress = analysis!.currentProgress
        XCTAssertGreaterThan(currentProgress.currentAmount, 0)
        XCTAssertGreaterThan(currentProgress.progressPercentage, 0)
        XCTAssertEqual(currentProgress.totalContributions, monthlyContribution * 36)
        
        // Verify optimization recommendations
        let optimization = try await goalTrackingService.calculateOptimalContributionStrategy(for: testGoal.id)
        XCTAssertGreaterThan(optimization.scenarios.count, 0)
        
        // Generate final report
        let report = try await goalTrackingService.generateGoalReport(for: testGoal.id)
        XCTAssertNotNil(report)
        XCTAssertEqual(report.goal.id, testGoal.id)
    }
    
    // MARK: - Edge Cases Tests
    
    func testGoalWithPastDeadline() async throws {
        // Given - Create goal with past deadline
        let pastGoal = createTestGoal()
        pastGoal.deadline = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        
        try await goalTrackingService.startTrackingGoal(pastGoal)
        
        // When
        await goalTrackingService.updateGoalProgress(for: pastGoal)
        
        // Then
        let analysis = goalTrackingService.goalAnalyses[pastGoal.id]
        XCTAssertNotNil(analysis)
        XCTAssertLessThanOrEqual(analysis!.currentProgress.timeRemaining, 0)
        XCTAssertEqual(analysis!.riskAssessment.overallRiskLevel, .critical)
    }
    
    func testGoalWithZeroTarget() async throws {
        // Given - Create goal with zero target
        let zeroGoal = createTestGoal()
        zeroGoal.targetAmount = 0
        
        // When & Then - Should not crash
        try await goalTrackingService.startTrackingGoal(zeroGoal)
        await goalTrackingService.updateGoalProgress(for: zeroGoal)
        
        let analysis = goalTrackingService.goalAnalyses[zeroGoal.id]
        XCTAssertNotNil(analysis)
    }
}