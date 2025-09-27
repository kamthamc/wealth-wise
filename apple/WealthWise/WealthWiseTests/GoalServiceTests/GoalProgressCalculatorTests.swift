//
//  GoalProgressCalculatorTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import XCTest
@testable import WealthWise

/// Test suite for GoalProgressCalculator mathematical accuracy and business logic
@MainActor
final class GoalProgressCalculatorTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var testGoal: Goal!
    private var testContributions: [Goal.Contribution]!
    
    // MARK: - Test Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test goal - "5cr in 3 years"
        testGoal = Goal.createFiveCroreGoal()
        
        // Create test contributions - ₹1L per month for 18 months
        testContributions = createTestContributions(monthlyAmount: 100000, months: 18)
    }
    
    override func tearDown() async throws {
        testGoal = nil
        testContributions = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Create test contributions with specified parameters
    private func createTestContributions(monthlyAmount: Decimal, months: Int) -> [Goal.Contribution] {
        var contributions: [Goal.Contribution] = []
        let startDate = testGoal.startDate
        
        for month in 0..<months {
            let contributionDate = Calendar.current.date(byAdding: .month, value: month, to: startDate)!
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
    
    // MARK: - Core Progress Calculation Tests
    
    func testCalculateGoalProgressWithZeroContributions() {
        // Given
        let currentAmount: Decimal = 0
        let emptyContributions: [Goal.Contribution] = []
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: testGoal,
            currentAmount: currentAmount,
            contributions: emptyContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        XCTAssertEqual(analysis.currentProgress.currentAmount, 0)
        XCTAssertEqual(analysis.currentProgress.progressPercentage, 0)
        XCTAssertEqual(analysis.currentProgress.totalContributions, 0)
        XCTAssertEqual(analysis.currentProgress.totalReturns, 0)
        XCTAssertEqual(analysis.currentProgress.currentRunRate, 0)
        
        // Verify projected metrics
        XCTAssertEqual(analysis.projectedProgress.projectedFinalAmount, 0)
        XCTAssertEqual(analysis.projectedProgress.projectedShortfall, testGoal.targetAmount)
        XCTAssertLessThan(analysis.projectedProgress.probabilityOfSuccess, 0.1)
    }
    
    func testCalculateGoalProgressWithRegularContributions() {
        // Given
        let currentAmount: Decimal = 2000000 // ₹20L accumulated
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: testGoal,
            currentAmount: currentAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        XCTAssertEqual(analysis.currentProgress.currentAmount, currentAmount)
        XCTAssertEqual(analysis.currentProgress.progressPercentage, 40) // 40% of 5cr
        XCTAssertEqual(analysis.currentProgress.totalContributions, 1800000) // 18 * 1L
        XCTAssertEqual(analysis.currentProgress.totalReturns, 200000) // 20L - 18L
        XCTAssertGreaterThan(analysis.currentProgress.currentRunRate, 0)
        
        // Verify projected metrics are reasonable
        XCTAssertGreaterThan(analysis.projectedProgress.projectedFinalAmount, currentAmount)
        XCTAssertGreaterThan(analysis.projectedProgress.probabilityOfSuccess, 0)
        XCTAssertLessThanOrEqual(analysis.projectedProgress.probabilityOfSuccess, 1)
    }
    
    func testProgressCalculationAccuracy() {
        // Given
        let testCases: [(currentAmount: Decimal, expectedProgress: Decimal)] = [
            (0, 0),
            (1250000, 25), // 25% of 5cr
            (2500000, 50), // 50% of 5cr
            (3750000, 75), // 75% of 5cr
            (5000000, 100), // 100% of 5cr
            (6000000, 120) // 120% of 5cr
        ]
        
        for testCase in testCases {
            // When
            let analysis = GoalProgressCalculator.calculateGoalProgress(
                goal: testGoal,
                currentAmount: testCase.currentAmount,
                contributions: testContributions,
                expectedReturn: 0.12,
                marketVolatility: 0.15
            )
            
            // Then
            XCTAssertEqual(
                analysis.currentProgress.progressPercentage,
                testCase.expectedProgress,
                accuracy: 0.01,
                "Progress percentage should match expected value for amount ₹\(testCase.currentAmount)"
            )
        }
    }
    
    // MARK: - Milestone Analysis Tests
    
    func testMilestoneStatusCalculation() {
        // Given
        let currentAmount: Decimal = 1500000 // ₹15L
        
        // Add milestones to test goal
        let milestone1 = Goal.Milestone(
            id: UUID(),
            description: "25% Milestone",
            targetAmount: 1250000,
            targetDate: Calendar.current.date(byAdding: .year, value: 1, to: testGoal.startDate)!,
            isAchieved: false
        )
        
        let milestone2 = Goal.Milestone(
            id: UUID(),
            description: "50% Milestone",
            targetAmount: 2500000,
            targetDate: Calendar.current.date(byAdding: .year, value: 2, to: testGoal.startDate)!,
            isAchieved: false
        )
        
        testGoal.milestones = [milestone1, milestone2]
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: testGoal,
            currentAmount: currentAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        let milestoneStatus = analysis.milestoneStatus
        XCTAssertEqual(milestoneStatus.totalMilestones, 2)
        XCTAssertEqual(milestoneStatus.milestonesAchieved, 1) // Should have achieved 25% milestone
        XCTAssertEqual(milestoneStatus.milestoneCompletionRate, 50) // 1 out of 2 achieved
        XCTAssertNotNil(milestoneStatus.nextMilestone)
        XCTAssertEqual(milestoneStatus.nextMilestone?.milestone.targetAmount, 2500000)
    }
    
    func testMilestoneProgressCalculation() {
        // Given
        let currentAmount: Decimal = 3000000 // ₹30L
        
        let milestone = Goal.Milestone(
            id: UUID(),
            description: "50% Milestone",
            targetAmount: 2500000,
            targetDate: Calendar.current.date(byAdding: .year, value: 2, to: testGoal.startDate)!,
            isAchieved: false
        )
        
        testGoal.milestones = [milestone]
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: testGoal,
            currentAmount: currentAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        let milestoneProgress = analysis.milestoneStatus.milestones.first!
        XCTAssertTrue(milestoneProgress.isAchieved)
        XCTAssertEqual(milestoneProgress.progressTowardsMilestone, 100) // Exceeded the milestone
    }
    
    // MARK: - Risk Assessment Tests
    
    func testRiskAssessmentLevels() {
        // Test different risk scenarios
        let riskTestCases: [(currentAmount: Decimal, timeRemaining: TimeInterval, expectedRiskLevel: GoalProgressCalculator.RiskAssessment.RiskLevel)] = [
            (4500000, 365 * 24 * 60 * 60, .low), // Close to goal with time remaining
            (2500000, 365 * 24 * 60 * 60, .moderate), // Halfway with 1 year remaining
            (1000000, 180 * 24 * 60 * 60, .high), // Low progress with 6 months remaining
            (500000, 30 * 24 * 60 * 60, .critical) // Very low progress with 1 month remaining
        ]
        
        for testCase in riskTestCases {
            // Given
            let adjustedGoal = testGoal!
            adjustedGoal.deadline = Date().addingTimeInterval(testCase.timeRemaining)
            
            // When
            let analysis = GoalProgressCalculator.calculateGoalProgress(
                goal: adjustedGoal,
                currentAmount: testCase.currentAmount,
                contributions: testContributions,
                expectedReturn: 0.12,
                marketVolatility: 0.15
            )
            
            // Then
            XCTAssertEqual(
                analysis.riskAssessment.overallRiskLevel,
                testCase.expectedRiskLevel,
                "Risk level should match expected for amount ₹\(testCase.currentAmount) with \(testCase.timeRemaining) seconds remaining"
            )
        }
    }
    
    func testRiskMitigationStrategies() {
        // Given - High risk scenario
        let currentAmount: Decimal = 1000000 // ₹10L
        let shortTermGoal = testGoal!
        shortTermGoal.deadline = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: shortTermGoal,
            currentAmount: currentAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.20 // High volatility
        )
        
        // Then
        let mitigationStrategies = analysis.riskAssessment.mitigationStrategies
        XCTAssertGreaterThan(mitigationStrategies.count, 0)
        
        // Should contain relevant mitigation strategies
        let strategiesText = mitigationStrategies.joined(separator: " ")
        XCTAssertTrue(strategiesText.contains("contribution") || strategiesText.contains("timeline") || strategiesText.contains("diversify"))
    }
    
    // MARK: - Recommendation Generation Tests
    
    func testOnTrackRecommendation() {
        // Given - Goal that's on track
        let currentAmount: Decimal = 4800000 // ₹48L (very close to 5cr goal)
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: testGoal,
            currentAmount: currentAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        let recommendations = analysis.recommendations
        let hasOnTrackRecommendation = recommendations.contains { recommendation in
            if case .onTrack = recommendation {
                return true
            }
            return false
        }
        XCTAssertTrue(hasOnTrackRecommendation, "Should have on-track recommendation for goal close to completion")
    }
    
    func testIncreaseContributionRecommendation() {
        // Given - Goal that needs more contributions
        let currentAmount: Decimal = 500000 // ₹5L (far from 5cr goal)
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: testGoal,
            currentAmount: currentAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        let recommendations = analysis.recommendations
        let hasIncreaseContributionRecommendation = recommendations.contains { recommendation in
            if case .increaseContributions = recommendation {
                return true
            }
            return false
        }
        XCTAssertTrue(hasIncreaseContributionRecommendation, "Should recommend increasing contributions for underperforming goal")
    }
    
    func testTimelineAdjustmentRecommendation() {
        // Given - Goal with very low success probability and short timeline
        let currentAmount: Decimal = 1000000 // ₹10L
        let shortTermGoal = testGoal!
        shortTermGoal.deadline = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: shortTermGoal,
            currentAmount: currentAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        let recommendations = analysis.recommendations
        let hasTimelineAdjustmentRecommendation = recommendations.contains { recommendation in
            if case .adjustTimeline = recommendation {
                return true
            }
            return false
        }
        XCTAssertTrue(hasTimelineAdjustmentRecommendation || analysis.projectedProgress.probabilityOfSuccess < 0.5, 
                     "Should recommend timeline adjustment for unrealistic short-term goals")
    }
    
    // MARK: - Performance Tests
    
    func testProgressCalculationPerformance() {
        // Given - Large number of contributions
        let largeContributions = createTestContributions(monthlyAmount: 50000, months: 120) // 10 years
        
        // When & Then
        measure {
            let _ = GoalProgressCalculator.calculateGoalProgress(
                goal: testGoal,
                currentAmount: 6000000,
                contributions: largeContributions,
                expectedReturn: 0.12,
                marketVolatility: 0.15
            )
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroTargetGoal() {
        // Given
        let zeroGoal = testGoal!
        zeroGoal.targetAmount = 0
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: zeroGoal,
            currentAmount: 1000000,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then - Should not crash and handle gracefully
        XCTAssertNotNil(analysis)
        // Progress percentage might be infinity or handled specially
    }
    
    func testNegativeCurrentAmount() {
        // Given
        let negativeAmount: Decimal = -100000
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: testGoal,
            currentAmount: negativeAmount,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then - Should handle negative amounts gracefully
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.currentProgress.currentAmount, negativeAmount)
        XCTAssertLessThan(analysis.currentProgress.progressPercentage, 0)
    }
    
    func testFutureDeadlineGoal() {
        // Given
        let futureGoal = testGoal!
        futureGoal.deadline = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        
        // When
        let analysis = GoalProgressCalculator.calculateGoalProgress(
            goal: futureGoal,
            currentAmount: 1000000,
            contributions: testContributions,
            expectedReturn: 0.12,
            marketVolatility: 0.15
        )
        
        // Then
        XCTAssertGreaterThan(analysis.currentProgress.timeRemaining, 9) // Should have ~10 years remaining
        XCTAssertEqual(analysis.riskAssessment.overallRiskLevel, .low) // Long timeline should be low risk
    }
    
    // MARK: - Mathematical Accuracy Tests
    
    func testProgressPercentageAccuracy() {
        // Test various current amounts for precise percentage calculation
        let testCases: [(current: Decimal, target: Decimal, expected: Decimal)] = [
            (0, 5000000, 0.0),
            (1250000, 5000000, 25.0),
            (2500000, 5000000, 50.0),
            (3750000, 5000000, 75.0),
            (5000000, 5000000, 100.0),
            (7500000, 5000000, 150.0),
            (333333, 1000000, 33.3333)
        ]
        
        for testCase in testCases {
            // Given
            let customGoal = testGoal!
            customGoal.targetAmount = testCase.target
            
            // When
            let analysis = GoalProgressCalculator.calculateGoalProgress(
                goal: customGoal,
                currentAmount: testCase.current,
                contributions: [],
                expectedReturn: 0.12,
                marketVolatility: 0.15
            )
            
            // Then
            XCTAssertEqual(
                analysis.currentProgress.progressPercentage,
                testCase.expected,
                accuracy: 0.01,
                "Progress percentage should be accurate for current: \(testCase.current), target: \(testCase.target)"
            )
        }
    }
}