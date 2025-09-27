//
//  CompoundInterestCalculator.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import Foundation

/// Advanced compound interest calculator for sophisticated financial projections.
/// Supports various compounding frequencies, continuous compounding, and annuity calculations.
@MainActor
public final class CompoundInterestCalculator {
    
    // MARK: - Compounding Frequency
    
    /// Represents different compounding frequencies for interest calculations
    public enum CompoundingFrequency: Int, CaseIterable, Sendable {
        case annually = 1
        case semiAnnually = 2
        case quarterly = 4
        case monthly = 12
        case weekly = 52
        case daily = 365
        case continuously = 0 // Special case for continuous compounding
        
        /// Localized description for the compounding frequency
        public var localizedDescription: String {
            switch self {
            case .annually:
                return NSLocalizedString("compounding.annually", comment: "Annual compounding frequency")
            case .semiAnnually:
                return NSLocalizedString("compounding.semi_annually", comment: "Semi-annual compounding frequency")
            case .quarterly:
                return NSLocalizedString("compounding.quarterly", comment: "Quarterly compounding frequency")
            case .monthly:
                return NSLocalizedString("compounding.monthly", comment: "Monthly compounding frequency")
            case .weekly:
                return NSLocalizedString("compounding.weekly", comment: "Weekly compounding frequency")
            case .daily:
                return NSLocalizedString("compounding.daily", comment: "Daily compounding frequency")
            case .continuously:
                return NSLocalizedString("compounding.continuously", comment: "Continuous compounding frequency")
            }
        }
    }
    
    // MARK: - Calculation Results
    
    /// Result structure for compound interest calculations
    public struct CompoundInterestResult: Sendable {
        public let principal: Decimal
        public let rate: Decimal
        public let time: Decimal
        public let frequency: CompoundingFrequency
        public let futureValue: Decimal
        public let totalInterest: Decimal
        public let effectiveAnnualRate: Decimal
        
        /// Initialize compound interest result
        public init(principal: Decimal, rate: Decimal, time: Decimal, frequency: CompoundingFrequency, futureValue: Decimal, totalInterest: Decimal, effectiveAnnualRate: Decimal) {
            self.principal = principal
            self.rate = rate
            self.time = time
            self.frequency = frequency
            self.futureValue = futureValue
            self.totalInterest = totalInterest
            self.effectiveAnnualRate = effectiveAnnualRate
        }
    }
    
    // MARK: - Core Calculations
    
    /// Calculate compound interest with specified parameters
    /// - Parameters:
    ///   - principal: Initial investment amount
    ///   - annualRate: Annual interest rate as decimal (e.g., 0.12 for 12%)
    ///   - timeInYears: Investment period in years
    ///   - compoundingFrequency: How often interest is compounded
    /// - Returns: Compound interest calculation result
    public static func calculateCompoundInterest(
        principal: Decimal,
        annualRate: Decimal,
        timeInYears: Decimal,
        compoundingFrequency: CompoundingFrequency = .annually
    ) -> CompoundInterestResult {
        
        let futureValue: Decimal
        let effectiveRate: Decimal
        
        if compoundingFrequency == .continuously {
            // Continuous compounding: A = P * e^(rt)
            let exponent = annualRate * timeInYears
            let eToThePower = calculateExponential(exponent)
            futureValue = principal * eToThePower
            effectiveRate = calculateExponential(annualRate) - 1
        } else {
            // Standard compounding: A = P(1 + r/n)^(nt)
            let n = Decimal(compoundingFrequency.rawValue)
            let ratePerPeriod = annualRate / n
            let numberOfPeriods = n * timeInYears
            
            let onePlusRate = 1 + ratePerPeriod
            let compoundFactor = power(base: onePlusRate, exponent: numberOfPeriods)
            futureValue = principal * compoundFactor
            
            // Effective annual rate: (1 + r/n)^n - 1
            let effectiveFactor = power(base: onePlusRate, exponent: n)
            effectiveRate = effectiveFactor - 1
        }
        
        let totalInterest = futureValue - principal
        
        return CompoundInterestResult(
            principal: principal,
            rate: annualRate,
            time: timeInYears,
            frequency: compoundingFrequency,
            futureValue: futureValue,
            totalInterest: totalInterest,
            effectiveAnnualRate: effectiveRate
        )
    }
    
    /// Calculate required monthly contribution to reach a goal
    /// - Parameters:
    ///   - goalAmount: Target amount to achieve
    ///   - currentAmount: Current savings amount
    ///   - annualRate: Expected annual return rate
    ///   - timeInYears: Time period to achieve goal
    ///   - compoundingFrequency: Compounding frequency
    /// - Returns: Required monthly contribution amount
    public static func calculateRequiredContribution(
        goalAmount: Decimal,
        currentAmount: Decimal,
        annualRate: Decimal,
        timeInYears: Decimal,
        compoundingFrequency: CompoundingFrequency = .monthly
    ) -> Decimal {
        
        // Future value of current amount
        let currentFutureValue = calculateCompoundInterest(
            principal: currentAmount,
            annualRate: annualRate,
            timeInYears: timeInYears,
            compoundingFrequency: compoundingFrequency
        ).futureValue
        
        // Remaining amount needed from contributions
        let remainingAmount = goalAmount - currentFutureValue
        
        if remainingAmount <= 0 {
            return 0 // Goal already achievable with current amount
        }
        
        // Calculate required payment using annuity formula
        let n = Decimal(compoundingFrequency.rawValue)
        let ratePerPeriod = annualRate / n
        let numberOfPeriods = n * timeInYears
        
        if ratePerPeriod == 0 {
            // No interest scenario
            return remainingAmount / numberOfPeriods
        }
        
        // PMT = FV * r / ((1 + r)^n - 1)
        let onePlusRate = 1 + ratePerPeriod
        let compoundFactor = power(base: onePlusRate, exponent: numberOfPeriods)
        let denominator = compoundFactor - 1
        
        let requiredPayment = remainingAmount * ratePerPeriod / denominator
        
        return requiredPayment
    }
    
    /// Calculate time required to reach a goal with regular contributions
    /// - Parameters:
    ///   - goalAmount: Target amount to achieve
    ///   - currentAmount: Current savings amount
    ///   - monthlyContribution: Regular monthly contribution
    ///   - annualRate: Expected annual return rate
    /// - Returns: Time in years to reach the goal
    public static func calculateTimeToGoal(
        goalAmount: Decimal,
        currentAmount: Decimal,
        monthlyContribution: Decimal,
        annualRate: Decimal
    ) -> Decimal {
        
        if goalAmount <= currentAmount {
            return 0 // Goal already achieved
        }
        
        let monthlyRate = annualRate / 12
        
        if monthlyRate == 0 {
            // No interest scenario
            return (goalAmount - currentAmount) / monthlyContribution / 12
        }
        
        // Using future value of annuity formula to solve for time
        // This requires iterative approximation
        return approximateTimeToGoal(
            goalAmount: goalAmount,
            currentAmount: currentAmount,
            monthlyContribution: monthlyContribution,
            monthlyRate: monthlyRate
        )
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
    
    /// Iteratively approximate time to reach goal
    private static func approximateTimeToGoal(
        goalAmount: Decimal,
        currentAmount: Decimal,
        monthlyContribution: Decimal,
        monthlyRate: Decimal
    ) -> Decimal {
        
        var timeInMonths: Decimal = 1
        var currentValue = currentAmount
        let maxIterations = 1200 // 100 years maximum
        
        for _ in 0..<maxIterations {
            // Apply interest to current value
            currentValue = currentValue * (1 + monthlyRate)
            // Add monthly contribution
            currentValue += monthlyContribution
            
            if currentValue >= goalAmount {
                break
            }
            
            timeInMonths += 1
        }
        
        return timeInMonths / 12 // Convert to years
    }
}

// MARK: - Localization Strings

extension CompoundInterestCalculator {
    
    /// Localized strings for financial mathematics
    public enum LocalizedStrings {
        public static let compoundingAnnually = NSLocalizedString("compounding.annually", comment: "Annual compounding frequency")
        public static let compoundingSemiAnnually = NSLocalizedString("compounding.semi_annually", comment: "Semi-annual compounding frequency")
        public static let compoundingQuarterly = NSLocalizedString("compounding.quarterly", comment: "Quarterly compounding frequency")
        public static let compoundingMonthly = NSLocalizedString("compounding.monthly", comment: "Monthly compounding frequency")
        public static let compoundingWeekly = NSLocalizedString("compounding.weekly", comment: "Weekly compounding frequency")
        public static let compoundingDaily = NSLocalizedString("compounding.daily", comment: "Daily compounding frequency")
        public static let compoundingContinuously = NSLocalizedString("compounding.continuously", comment: "Continuous compounding frequency")
    }
}