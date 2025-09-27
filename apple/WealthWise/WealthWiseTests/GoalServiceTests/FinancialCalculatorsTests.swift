//
//  FinancialCalculatorsTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import XCTest
@testable import WealthWise

/// Comprehensive test suite for financial mathematics calculators
@MainActor
final class FinancialCalculatorsTests: XCTestCase {
    
    // MARK: - CompoundInterestCalculator Tests
    
    func testCompoundInterestBasicCalculation() {
        // Given
        let principal: Decimal = 100000 // ₹1L
        let annualRate: Decimal = 0.12 // 12%
        let years: Decimal = 5
        let frequency: CompoundInterestCalculator.CompoundingFrequency = .annually
        
        // When
        let result = CompoundInterestCalculator.calculateCompoundInterest(
            principal: principal,
            annualRate: annualRate,
            years: years,
            compoundingFrequency: frequency
        )
        
        // Then
        // Expected: 100000 * (1.12)^5 = 176,234.17
        XCTAssertEqual(result.finalAmount, 176234.17, accuracy: 0.01)
        XCTAssertEqual(result.totalInterest, 76234.17, accuracy: 0.01)
        XCTAssertEqual(result.effectiveAnnualRate, 0.12, accuracy: 0.001)
    }
    
    func testCompoundInterestMonthlyCompounding() {
        // Given
        let principal: Decimal = 500000 // ₹5L
        let annualRate: Decimal = 0.10 // 10%
        let years: Decimal = 3
        let frequency: CompoundInterestCalculator.CompoundingFrequency = .monthly
        
        // When
        let result = CompoundInterestCalculator.calculateCompoundInterest(
            principal: principal,
            annualRate: annualRate,
            years: years,
            compoundingFrequency: frequency
        )
        
        // Then  
        // Monthly compounding should yield higher returns than annual
        // Expected: ~₹6,74,000
        XCTAssertGreaterThan(result.finalAmount, 670000)
        XCTAssertLessThan(result.finalAmount, 680000)
        XCTAssertGreaterThan(result.effectiveAnnualRate, 0.10) // Should be > 10% due to compounding
    }
    
    func testRequiredContributionCalculation() {
        // Given - "5cr in 3 years" scenario
        let targetAmount: Decimal = 5000000 // ₹5cr
        let annualRate: Decimal = 0.12 // 12%
        let years: Decimal = 3
        let currentAmount: Decimal = 0
        
        // When
        let requiredContribution = CompoundInterestCalculator.calculateRequiredContribution(
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            annualRate: annualRate,
            years: years,
            compoundingFrequency: .monthly
        )
        
        // Then
        XCTAssertNotNil(requiredContribution)
        // Should require approximately ₹1.18L per month
        XCTAssertGreaterThan(requiredContribution!, 115000)
        XCTAssertLessThan(requiredContribution!, 125000)
    }
    
    func testTimeToGoalCalculation() {
        // Given
        let targetAmount: Decimal = 1000000 // ₹10L
        let monthlyContribution: Decimal = 10000 // ₹10k per month
        let annualRate: Decimal = 0.12 // 12%
        let currentAmount: Decimal = 100000 // ₹1L starting
        
        // When
        let timeToGoal = CompoundInterestCalculator.calculateTimeToGoal(
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            monthlyContribution: monthlyContribution,
            annualRate: annualRate
        )
        
        // Then
        XCTAssertNotNil(timeToGoal)
        // Should take approximately 6-8 years
        XCTAssertGreaterThan(timeToGoal!, 5)
        XCTAssertLessThan(timeToGoal!, 10)
    }
    
    // MARK: - PresentValueCalculator Tests
    
    func testNetPresentValueCalculation() {
        // Given
        let initialInvestment: Decimal = -1000000 // ₹10L initial investment
        let cashFlows: [Decimal] = [200000, 300000, 400000, 500000] // Annual returns
        let discountRate: Decimal = 0.10 // 10% discount rate
        
        // When
        let result = PresentValueCalculator.calculateNetPresentValue(
            initialInvestment: initialInvestment,
            cashFlows: cashFlows,
            discountRate: discountRate
        )
        
        // Then
        XCTAssertGreaterThan(result.npv, 0) // Should be profitable
        XCTAssertGreaterThan(result.profitabilityIndex, 1.0) // Should be > 1 for good investment
        XCTAssertLessThan(result.paybackPeriod, 4.0) // Should payback within 4 years
    }
    
    func testPresentValueOfAnnuity() {
        // Given
        let annualPayment: Decimal = 100000 // ₹1L per year
        let discountRate: Decimal = 0.08 // 8%
        let periods: Int = 10
        
        // When
        let result = PresentValueCalculator.calculateAnnuityPresentValue(
            payment: annualPayment,
            rate: discountRate,
            periods: periods,
            annuityType: .ordinary
        )
        
        // Then
        // Expected: ~₹6.71L for ordinary annuity
        XCTAssertGreaterThan(result.presentValue, 650000)
        XCTAssertLessThan(result.presentValue, 680000)
        XCTAssertEqual(result.totalPayments, 1000000) // 10 * 1L
    }
    
    func testPresentValueOfAnnuityDue() {
        // Given
        let annualPayment: Decimal = 100000 // ₹1L per year
        let discountRate: Decimal = 0.08 // 8%
        let periods: Int = 10
        
        // When
        let ordinaryResult = PresentValueCalculator.calculateAnnuityPresentValue(
            payment: annualPayment,
            rate: discountRate,
            periods: periods,
            annuityType: .ordinary
        )
        
        let dueResult = PresentValueCalculator.calculateAnnuityPresentValue(
            payment: annualPayment,
            rate: discountRate,
            periods: periods,
            annuityType: .due
        )
        
        // Then
        // Annuity due should have higher present value than ordinary annuity
        XCTAssertGreaterThan(dueResult.presentValue, ordinaryResult.presentValue)
        
        // Due should be ~8% higher (equal to the discount rate)
        let expectedRatio = 1 + discountRate
        let actualRatio = dueResult.presentValue / ordinaryResult.presentValue
        XCTAssertEqual(Double(actualRatio), Double(expectedRatio), accuracy: 0.01)
    }
    
    func testGoalSpecificPresentValue() {
        // Given - Goal requiring ₹5cr in 3 years
        let futureValue: Decimal = 5000000 // ₹5cr
        let discountRate: Decimal = 0.12 // 12%
        let years: Decimal = 3
        
        // When
        let result = PresentValueCalculator.calculateGoalPresentValue(
            futureValue: futureValue,
            discountRate: discountRate,
            years: years
        )
        
        // Then
        // Expected: 5000000 / (1.12)^3 = ₹35.6L
        XCTAssertGreaterThan(result.presentValue, 3500000)
        XCTAssertLessThan(result.presentValue, 3600000)
        XCTAssertEqual(result.discountFactor, pow(1 + discountRate, -years), accuracy: 0.001)
    }
    
    // MARK: - FutureValueCalculator Tests
    
    func testSingleInvestmentFutureValue() {
        // Given
        let presentValue: Decimal = 100000 // ₹1L
        let rate: Decimal = 0.15 // 15%
        let periods: Decimal = 5
        
        // When
        let result = FutureValueCalculator.calculateFutureValue(
            presentValue: presentValue,
            rate: rate,
            periods: periods
        )
        
        // Then
        // Expected: 100000 * (1.15)^5 = ₹2,01,136
        XCTAssertEqual(result.futureValue, 201136, accuracy: 1)
        XCTAssertEqual(result.totalGrowth, 101136, accuracy: 1)
        XCTAssertEqual(result.annualizedReturn, rate, accuracy: 0.001)
    }
    
    func testFutureValueOfAnnuity() {
        // Given
        let monthlyPayment: Decimal = 10000 // ₹10k per month
        let annualRate: Decimal = 0.12 // 12%
        let years: Int = 10
        
        // When
        let result = FutureValueCalculator.calculateAnnuityFutureValue(
            payment: monthlyPayment,
            rate: annualRate / 12, // Monthly rate
            periods: years * 12 // Monthly periods
        )
        
        // Then
        // Should accumulate to significant amount with compound growth
        XCTAssertGreaterThan(result.futureValue, 2000000) // Should be > ₹20L
        XCTAssertEqual(result.totalContributions, Decimal(years * 12) * monthlyPayment)
        XCTAssertGreaterThan(result.totalInterest, 0)
    }
    
    func testInvestmentProjection() {
        // Given
        let initialAmount: Decimal = 500000 // ₹5L
        let monthlyContribution: Decimal = 25000 // ₹25k per month
        let annualReturn: Decimal = 0.12 // 12%
        let years: Int = 5
        let inflationRate: Decimal = 0.06 // 6%
        
        // When
        let result = FutureValueCalculator.calculateInvestmentProjection(
            initialAmount: initialAmount,
            monthlyContribution: monthlyContribution,
            annualReturn: annualReturn,
            years: years,
            inflationRate: inflationRate
        )
        
        // Then
        XCTAssertGreaterThan(result.nominalValue, initialAmount)
        XCTAssertLessThan(result.realValue, result.nominalValue) // Inflation-adjusted should be less
        XCTAssertGreaterThan(result.totalContributions, Decimal(years * 12) * monthlyContribution)
        XCTAssertGreaterThan(result.investmentGains, 0)
    }
    
    func testGrowingContributionProjection() {
        // Given
        let initialContribution: Decimal = 20000 // ₹20k first month
        let contributionGrowthRate: Decimal = 0.10 // 10% annual growth
        let investmentReturn: Decimal = 0.12 // 12% annual return
        let years: Int = 3
        
        // When
        let result = FutureValueCalculator.calculateGrowingContributionProjection(
            initialContribution: initialContribution,
            contributionGrowthRate: contributionGrowthRate,
            investmentReturn: investmentReturn,
            years: years
        )
        
        // Then
        XCTAssertGreaterThan(result.finalValue, initialContribution * Decimal(years * 12))
        XCTAssertGreaterThan(result.totalContributions, initialContribution * Decimal(years * 12))
        XCTAssertGreaterThan(result.growthBenefit, 0) // Growing contributions should provide benefit
    }
    
    func testGoalAchievementProbability() {
        // Given
        let currentAmount: Decimal = 1000000 // ₹10L
        let monthlyContribution: Decimal = 50000 // ₹50k per month
        let targetAmount: Decimal = 5000000 // ₹50L target
        let timeHorizon: Int = 5 // 5 years
        let expectedReturn: Decimal = 0.12 // 12%
        let volatility: Decimal = 0.20 // 20% volatility
        
        // When
        let scenarios = FutureValueCalculator.calculateScenarioAnalysis(
            currentAmount: currentAmount,
            monthlyContribution: monthlyContribution,
            targetAmount: targetAmount,
            timeHorizon: timeHorizon,
            expectedReturn: expectedReturn,
            volatility: volatility
        )
        
        // Then
        XCTAssertEqual(scenarios.count, 5) // Should have optimistic, likely, expected, conservative, pessimistic
        
        // Verify scenario ordering
        XCTAssertGreaterThan(scenarios[0].projectedValue, scenarios[1].projectedValue) // Optimistic > Likely
        XCTAssertGreaterThan(scenarios[1].projectedValue, scenarios[2].projectedValue) // Likely > Expected
        XCTAssertGreaterThan(scenarios[2].projectedValue, scenarios[3].projectedValue) // Expected > Conservative
        XCTAssertGreaterThan(scenarios[3].projectedValue, scenarios[4].projectedValue) // Conservative > Pessimistic
        
        // Check probability ranges
        for scenario in scenarios {
            XCTAssertGreaterThanOrEqual(scenario.probabilityOfSuccess, 0)
            XCTAssertLessThanOrEqual(scenario.probabilityOfSuccess, 1)
        }
    }
    
    // MARK: - Integration Tests
    
    func testFinancialCalculatorsIntegration() {
        // Given - "5cr in 3 years" goal scenario
        let targetAmount: Decimal = 5000000 // ₹5cr
        let currentAmount: Decimal = 500000 // ₹5L current
        let timeHorizon: Decimal = 3 // 3 years
        let expectedReturn: Decimal = 0.12 // 12%
        
        // Step 1: Calculate required monthly contribution using compound interest
        let requiredMonthlyContribution = CompoundInterestCalculator.calculateRequiredContribution(
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            annualRate: expectedReturn,
            years: timeHorizon,
            compoundingFrequency: .monthly
        )
        
        XCTAssertNotNil(requiredMonthlyContribution)
        let monthlyContribution = requiredMonthlyContribution!
        
        // Step 2: Verify with future value calculation
        let futureValueResult = FutureValueCalculator.calculateInvestmentProjection(
            initialAmount: currentAmount,
            monthlyContribution: monthlyContribution,
            annualReturn: expectedReturn,
            years: Int(timeHorizon),
            inflationRate: 0.06
        )
        
        // Should achieve target (within reasonable tolerance)
        XCTAssertEqual(futureValueResult.nominalValue, targetAmount, accuracy: 10000)
        
        // Step 3: Calculate present value of the goal
        let presentValueResult = PresentValueCalculator.calculateGoalPresentValue(
            futureValue: targetAmount,
            discountRate: expectedReturn,
            years: timeHorizon
        )
        
        // Present value should be less than target
        XCTAssertLessThan(presentValueResult.presentValue, targetAmount)
        
        // Step 4: Verify total investment vs returns
        let totalInvestment = currentAmount + (monthlyContribution * 36) // 3 years * 12 months
        XCTAssertLessThan(totalInvestment, targetAmount) // Should require less than target due to returns
    }
    
    // MARK: - Performance Tests
    
    func testCalculatorPerformance() {
        measure {
            // Test performance of complex calculations
            for _ in 0..<100 {
                let _ = CompoundInterestCalculator.calculateCompoundInterest(
                    principal: 100000,
                    annualRate: 0.12,
                    years: 10,
                    compoundingFrequency: .monthly
                )
                
                let _ = PresentValueCalculator.calculateNetPresentValue(
                    initialInvestment: -500000,
                    cashFlows: [100000, 150000, 200000, 250000, 300000],
                    discountRate: 0.10
                )
                
                let _ = FutureValueCalculator.calculateInvestmentProjection(
                    initialAmount: 100000,
                    monthlyContribution: 10000,
                    annualReturn: 0.12,
                    years: 5,
                    inflationRate: 0.06
                )
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testZeroInputHandling() {
        // Test zero principal
        let zeroResult = CompoundInterestCalculator.calculateCompoundInterest(
            principal: 0,
            annualRate: 0.12,
            years: 5,
            compoundingFrequency: .annually
        )
        XCTAssertEqual(zeroResult.finalAmount, 0)
        XCTAssertEqual(zeroResult.totalInterest, 0)
        
        // Test zero rate
        let zeroRateResult = CompoundInterestCalculator.calculateCompoundInterest(
            principal: 100000,
            annualRate: 0,
            years: 5,
            compoundingFrequency: .annually
        )
        XCTAssertEqual(zeroRateResult.finalAmount, 100000)
        XCTAssertEqual(zeroRateResult.totalInterest, 0)
        
        // Test zero years
        let zeroYearsResult = CompoundInterestCalculator.calculateCompoundInterest(
            principal: 100000,
            annualRate: 0.12,
            years: 0,
            compoundingFrequency: .annually
        )
        XCTAssertEqual(zeroYearsResult.finalAmount, 100000)
        XCTAssertEqual(zeroYearsResult.totalInterest, 0)
    }
    
    func testHighVolatilityScenarios() {
        // Test extreme volatility scenario
        let scenarios = FutureValueCalculator.calculateScenarioAnalysis(
            currentAmount: 1000000,
            monthlyContribution: 50000,
            targetAmount: 10000000,
            timeHorizon: 10,
            expectedReturn: 0.15,
            volatility: 0.50 // 50% volatility
        )
        
        // Should still return valid scenarios
        XCTAssertEqual(scenarios.count, 5)
        
        // Wide spread between optimistic and pessimistic
        let optimistic = scenarios[0].projectedValue
        let pessimistic = scenarios[4].projectedValue
        XCTAssertGreaterThan(optimistic / pessimistic, 2) // At least 2x difference
    }
}