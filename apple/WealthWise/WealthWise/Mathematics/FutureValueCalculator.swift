//
//  FutureValueCalculator.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import Foundation

/// Advanced future value calculator for investment projections and goal planning.
/// Supports various growth scenarios, inflation adjustments, and portfolio projections.
@MainActor
public final class FutureValueCalculator {
    
    // MARK: - Calculation Results
    
    /// Result structure for future value calculations
    public struct FutureValueResult: Sendable {
        public let presentValue: Decimal
        public let growthRate: Decimal
        public let timeInYears: Decimal
        public let futureValue: Decimal
        public let totalGrowth: Decimal
        public let totalReturnPercentage: Decimal
        
        /// Initialize future value result
        public init(presentValue: Decimal, growthRate: Decimal, timeInYears: Decimal, futureValue: Decimal, totalGrowth: Decimal, totalReturnPercentage: Decimal) {
            self.presentValue = presentValue
            self.growthRate = growthRate
            self.timeInYears = timeInYears
            self.futureValue = futureValue
            self.totalGrowth = totalGrowth
            self.totalReturnPercentage = totalReturnPercentage
        }
    }
    
    /// Future value of annuity result
    public struct FutureValueAnnuityResult: Sendable {
        public let paymentAmount: Decimal
        public let interestRate: Decimal
        public let numberOfPayments: Int
        public let futureValue: Decimal
        public let totalPayments: Decimal
        public let totalInterest: Decimal
        
        /// Initialize future value annuity result
        public init(paymentAmount: Decimal, interestRate: Decimal, numberOfPayments: Int, futureValue: Decimal, totalPayments: Decimal, totalInterest: Decimal) {
            self.paymentAmount = paymentAmount
            self.interestRate = interestRate
            self.numberOfPayments = numberOfPayments
            self.futureValue = futureValue
            self.totalPayments = totalPayments
            self.totalInterest = totalInterest
        }
    }
    
    /// Investment projection result
    public struct InvestmentProjectionResult: Sendable {
        public let initialInvestment: Decimal
        public let monthlyContribution: Decimal
        public let annualReturn: Decimal
        public let timeInYears: Decimal
        public let finalValue: Decimal
        public let totalContributions: Decimal
        public let totalReturns: Decimal
        public let inflationAdjustedValue: Decimal?
        
        /// Initialize investment projection result
        public init(initialInvestment: Decimal, monthlyContribution: Decimal, annualReturn: Decimal, timeInYears: Decimal, finalValue: Decimal, totalContributions: Decimal, totalReturns: Decimal, inflationAdjustedValue: Decimal? = nil) {
            self.initialInvestment = initialInvestment
            self.monthlyContribution = monthlyContribution
            self.annualReturn = annualReturn
            self.timeInYears = timeInYears
            self.finalValue = finalValue
            self.totalContributions = totalContributions
            self.totalReturns = totalReturns
            self.inflationAdjustedValue = inflationAdjustedValue
        }
    }
    
    // MARK: - Core Calculations
    
    /// Calculate future value of a present amount
    /// - Parameters:
    ///   - presentValue: Current investment amount
    ///   - annualGrowthRate: Expected annual growth rate
    ///   - timeInYears: Investment period in years
    /// - Returns: Future value calculation result
    public static func calculateFutureValue(
        presentValue: Decimal,
        annualGrowthRate: Decimal,
        timeInYears: Decimal
    ) -> FutureValueResult {
        
        // FV = PV * (1 + r)^t
        let onePlusRate = 1 + annualGrowthRate
        let growthFactor = power(base: onePlusRate, exponent: timeInYears)
        let futureValue = presentValue * growthFactor
        
        let totalGrowth = futureValue - presentValue
        let totalReturnPercentage = (totalGrowth / presentValue) * 100
        
        return FutureValueResult(
            presentValue: presentValue,
            growthRate: annualGrowthRate,
            timeInYears: timeInYears,
            futureValue: futureValue,
            totalGrowth: totalGrowth,
            totalReturnPercentage: totalReturnPercentage
        )
    }
    
    /// Calculate future value of an annuity (regular payments)
    /// - Parameters:
    ///   - paymentAmount: Amount of each payment
    ///   - interestRate: Interest rate per period
    ///   - numberOfPayments: Total number of payments
    /// - Returns: Future value of annuity result
    public static func calculateAnnuityFutureValue(
        paymentAmount: Decimal,
        interestRate: Decimal,
        numberOfPayments: Int
    ) -> FutureValueAnnuityResult {
        
        if interestRate == 0 {
            // No interest scenario
            let futureValue = paymentAmount * Decimal(numberOfPayments)
            let totalPayments = futureValue
            
            return FutureValueAnnuityResult(
                paymentAmount: paymentAmount,
                interestRate: interestRate,
                numberOfPayments: numberOfPayments,
                futureValue: futureValue,
                totalPayments: totalPayments,
                totalInterest: 0
            )
        }
        
        // FV = PMT * [((1 + r)^n - 1) / r]
        let onePlusRate = 1 + interestRate
        let compoundFactor = power(base: onePlusRate, exponent: Decimal(numberOfPayments))
        let numerator = compoundFactor - 1
        let annuityFactor = numerator / interestRate
        
        let futureValue = paymentAmount * annuityFactor
        let totalPayments = paymentAmount * Decimal(numberOfPayments)
        let totalInterest = futureValue - totalPayments
        
        return FutureValueAnnuityResult(
            paymentAmount: paymentAmount,
            interestRate: interestRate,
            numberOfPayments: numberOfPayments,
            futureValue: futureValue,
            totalPayments: totalPayments,
            totalInterest: totalInterest
        )
    }
    
    /// Calculate future value with continuous compounding
    /// - Parameters:
    ///   - presentValue: Current investment amount
    ///   - continuousRate: Continuous interest rate
    ///   - timeInYears: Investment period in years
    /// - Returns: Future value with continuous compounding
    public static func calculateContinuousFutureValue(
        presentValue: Decimal,
        continuousRate: Decimal,
        timeInYears: Decimal
    ) -> Decimal {
        
        // FV = PV * e^(rt)
        let exponent = continuousRate * timeInYears
        let growthFactor = calculateExponential(exponent)
        
        return presentValue * growthFactor
    }
    
    /// Calculate inflation-adjusted future value (real value)
    /// - Parameters:
    ///   - presentValue: Current investment amount
    ///   - nominalRate: Nominal interest rate
    ///   - inflationRate: Expected inflation rate
    ///   - timeInYears: Investment period in years
    /// - Returns: Inflation-adjusted future value
    public static func calculateInflationAdjustedFutureValue(
        presentValue: Decimal,
        nominalRate: Decimal,
        inflationRate: Decimal,
        timeInYears: Decimal
    ) -> Decimal {
        
        // Real rate = (1 + nominal) / (1 + inflation) - 1
        let realRate = ((1 + nominalRate) / (1 + inflationRate)) - 1
        
        let realFutureValue = calculateFutureValue(
            presentValue: presentValue,
            annualGrowthRate: realRate,
            timeInYears: timeInYears
        )
        
        return realFutureValue.futureValue
    }
    
    // MARK: - Investment Projections
    
    /// Calculate comprehensive investment projection with initial amount and regular contributions
    /// - Parameters:
    ///   - initialInvestment: Initial lump sum investment
    ///   - monthlyContribution: Regular monthly contribution
    ///   - annualReturn: Expected annual return rate
    ///   - timeInYears: Investment period in years
    ///   - inflationRate: Optional inflation rate for real value calculation
    /// - Returns: Investment projection result
    public static func calculateInvestmentProjection(
        initialInvestment: Decimal,
        monthlyContribution: Decimal,
        annualReturn: Decimal,
        timeInYears: Decimal,
        inflationRate: Decimal? = nil
    ) -> InvestmentProjectionResult {
        
        // Future value of initial investment
        let initialFutureValue = calculateFutureValue(
            presentValue: initialInvestment,
            annualGrowthRate: annualReturn,
            timeInYears: timeInYears
        ).futureValue
        
        // Future value of monthly contributions
        let monthlyRate = annualReturn / 12
        let numberOfMonths = Int(12 * Double(truncating: timeInYears as NSNumber))
        
        let contributionsFutureValue = calculateAnnuityFutureValue(
            paymentAmount: monthlyContribution,
            interestRate: monthlyRate,
            numberOfPayments: numberOfMonths
        )
        
        let finalValue = initialFutureValue + contributionsFutureValue.futureValue
        let totalContributions = initialInvestment + contributionsFutureValue.totalPayments
        let totalReturns = finalValue - totalContributions
        
        // Calculate inflation-adjusted value if inflation rate provided
        let inflationAdjustedValue: Decimal?
        if let inflationRate = inflationRate {
            inflationAdjustedValue = calculateInflationAdjustedFutureValue(
                presentValue: totalContributions,
                nominalRate: annualReturn,
                inflationRate: inflationRate,
                timeInYears: timeInYears
            )
        } else {
            inflationAdjustedValue = nil
        }
        
        return InvestmentProjectionResult(
            initialInvestment: initialInvestment,
            monthlyContribution: monthlyContribution,
            annualReturn: annualReturn,
            timeInYears: timeInYears,
            finalValue: finalValue,
            totalContributions: totalContributions,
            totalReturns: totalReturns,
            inflationAdjustedValue: inflationAdjustedValue
        )
    }
    
    /// Calculate goal achievement probability based on different return scenarios
    /// - Parameters:
    ///   - goalAmount: Target amount to achieve
    ///   - currentAmount: Current savings amount
    ///   - monthlyContribution: Regular monthly contribution
    ///   - timeInYears: Time period to achieve goal
    ///   - expectedReturn: Expected annual return rate
    ///   - returnVolatility: Standard deviation of returns
    /// - Returns: Array of scenario results with probabilities
    public static func calculateGoalAchievementScenarios(
        goalAmount: Decimal,
        currentAmount: Decimal,
        monthlyContribution: Decimal,
        timeInYears: Decimal,
        expectedReturn: Decimal,
        returnVolatility: Decimal
    ) -> [ScenarioResult] {
        
        var scenarios: [ScenarioResult] = []
        
        // Conservative scenario (expected return - 1 standard deviation)
        let conservativeReturn = expectedReturn - returnVolatility
        let conservativeProjection = calculateInvestmentProjection(
            initialInvestment: currentAmount,
            monthlyContribution: monthlyContribution,
            annualReturn: conservativeReturn,
            timeInYears: timeInYears
        )
        
        scenarios.append(ScenarioResult(
            name: NSLocalizedString("scenario.conservative", comment: "Conservative scenario"),
            returnRate: conservativeReturn,
            finalValue: conservativeProjection.finalValue,
            probability: 0.16, // ~16% probability (lower tail)
            achievesGoal: conservativeProjection.finalValue >= goalAmount
        ))
        
        // Expected scenario (expected return)
        let expectedProjection = calculateInvestmentProjection(
            initialInvestment: currentAmount,
            monthlyContribution: monthlyContribution,
            annualReturn: expectedReturn,
            timeInYears: timeInYears
        )
        
        scenarios.append(ScenarioResult(
            name: NSLocalizedString("scenario.expected", comment: "Expected scenario"),
            returnRate: expectedReturn,
            finalValue: expectedProjection.finalValue,
            probability: 0.68, // ~68% probability (within 1 std dev)
            achievesGoal: expectedProjection.finalValue >= goalAmount
        ))
        
        // Optimistic scenario (expected return + 1 standard deviation)
        let optimisticReturn = expectedReturn + returnVolatility
        let optimisticProjection = calculateInvestmentProjection(
            initialInvestment: currentAmount,
            monthlyContribution: monthlyContribution,
            annualReturn: optimisticReturn,
            timeInYears: timeInYears
        )
        
        scenarios.append(ScenarioResult(
            name: NSLocalizedString("scenario.optimistic", comment: "Optimistic scenario"),
            returnRate: optimisticReturn,
            finalValue: optimisticProjection.finalValue,
            probability: 0.16, // ~16% probability (upper tail)
            achievesGoal: optimisticProjection.finalValue >= goalAmount
        ))
        
        return scenarios
    }
    
    // MARK: - Scenario Result
    
    /// Scenario result for goal achievement analysis
    public struct ScenarioResult: Sendable {
        public let name: String
        public let returnRate: Decimal
        public let finalValue: Decimal
        public let probability: Decimal
        public let achievesGoal: Bool
        
        /// Initialize scenario result
        public init(name: String, returnRate: Decimal, finalValue: Decimal, probability: Decimal, achievesGoal: Bool) {
            self.name = name
            self.returnRate = returnRate
            self.finalValue = finalValue
            self.probability = probability
            self.achievesGoal = achievesGoal
        }
    }
    
    // MARK: - Utility Functions
    
    /// Calculate power function for Decimal values
    private static func power(base: Decimal, exponent: Decimal) -> Decimal {
        if exponent == 0 {
            return 1
        }
        
        if exponent == 1 {
            return base
        }
        
        // For financial calculations, we use approximation for non-integer exponents
        let baseDouble = Double(truncating: base as NSNumber)
        let exponentDouble = Double(truncating: exponent as NSNumber)
        
        let result = pow(baseDouble, exponentDouble)
        
        return Decimal(result)
    }
    
    /// Calculate exponential function (e^x) for continuous compounding
    private static func calculateExponential(_ x: Decimal) -> Decimal {
        let xDouble = Double(truncating: x as NSNumber)
        let result = exp(xDouble)
        return Decimal(result)
    }
}

// MARK: - Goal-Specific Extensions

extension FutureValueCalculator {
    
    /// Calculate how much an investment will be worth at different time horizons
    /// - Parameters:
    ///   - currentAmount: Current investment amount
    ///   - expectedReturn: Expected annual return rate
    ///   - timeHorizons: Array of time periods to calculate
    /// - Returns: Array of future values at different time points
    public static func calculateMultipleTimeHorizons(
        currentAmount: Decimal,
        expectedReturn: Decimal,
        timeHorizons: [Decimal]
    ) -> [(timeInYears: Decimal, futureValue: Decimal)] {
        
        return timeHorizons.map { timeInYears in
            let result = calculateFutureValue(
                presentValue: currentAmount,
                annualGrowthRate: expectedReturn,
                timeInYears: timeInYears
            )
            return (timeInYears: timeInYears, futureValue: result.futureValue)
        }
    }
    
    /// Calculate the impact of increasing contributions over time
    /// - Parameters:
    ///   - initialContribution: Starting monthly contribution
    ///   - contributionGrowthRate: Annual increase rate for contributions
    ///   - investmentReturn: Expected annual investment return
    ///   - timeInYears: Investment period in years
    /// - Returns: Future value with growing contributions
    public static func calculateGrowingContributionsFutureValue(
        initialContribution: Decimal,
        contributionGrowthRate: Decimal,
        investmentReturn: Decimal,
        timeInYears: Decimal
    ) -> Decimal {
        
        var totalFutureValue: Decimal = 0
        let monthlyReturn = investmentReturn / 12
        let monthlyGrowthRate = contributionGrowthRate / 12
        
        let numberOfMonths = Int(12 * Double(truncating: timeInYears as NSNumber))
        
        for month in 0..<numberOfMonths {
            // Calculate contribution amount for this month (growing over time)
            let monthsElapsed = Decimal(month)
            let contributionGrowthFactor = power(base: 1 + monthlyGrowthRate, exponent: monthsElapsed)
            let currentContribution = initialContribution * contributionGrowthFactor
            
            // Calculate how long this contribution will compound
            let monthsRemaining = Decimal(numberOfMonths - month)
            let compoundingFactor = power(base: 1 + monthlyReturn, exponent: monthsRemaining)
            
            // Add the future value of this contribution to the total
            totalFutureValue += currentContribution * compoundingFactor
        }
        
        return totalFutureValue
    }
}