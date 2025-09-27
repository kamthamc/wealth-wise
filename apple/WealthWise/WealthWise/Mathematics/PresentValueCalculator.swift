//
//  PresentValueCalculator.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Copyright © 2025 WealthWise. All rights reserved.
//

import Foundation

/// Advanced present value calculator for sophisticated investment analysis and valuation.
/// Supports NPV calculations, bond valuation, and cash flow analysis for portfolio optimization.
@MainActor
public final class PresentValueCalculator {
    
    // MARK: - Calculation Results
    
    /// Result structure for present value calculations
    public struct PresentValueResult: Sendable {
        public let futureValue: Decimal
        public let discountRate: Decimal
        public let timeInYears: Decimal
        public let presentValue: Decimal
        public let discountFactor: Decimal
        
        /// Initialize present value result
        public init(futureValue: Decimal, discountRate: Decimal, timeInYears: Decimal, presentValue: Decimal, discountFactor: Decimal) {
            self.futureValue = futureValue
            self.discountRate = discountRate
            self.timeInYears = timeInYears
            self.presentValue = presentValue
            self.discountFactor = discountFactor
        }
    }
    
    /// Net Present Value calculation result
    public struct NPVResult: Sendable {
        public let cashFlows: [CashFlow]
        public let discountRate: Decimal
        public let netPresentValue: Decimal
        public let totalPresentValue: Decimal
        public let initialInvestment: Decimal
        public let isPositiveNPV: Bool
        
        /// Initialize NPV result
        public init(cashFlows: [CashFlow], discountRate: Decimal, netPresentValue: Decimal, totalPresentValue: Decimal, initialInvestment: Decimal, isPositiveNPV: Bool) {
            self.cashFlows = cashFlows
            self.discountRate = discountRate
            self.netPresentValue = netPresentValue
            self.totalPresentValue = totalPresentValue
            self.initialInvestment = initialInvestment
            self.isPositiveNPV = isPositiveNPV
        }
    }
    
    /// Cash flow structure for NPV calculations
    public struct CashFlow: Sendable {
        public let amount: Decimal
        public let timeInYears: Decimal
        public let presentValue: Decimal
        
        /// Initialize cash flow
        public init(amount: Decimal, timeInYears: Decimal, presentValue: Decimal) {
            self.amount = amount
            self.timeInYears = timeInYears
            self.presentValue = presentValue
        }
    }
    
    // MARK: - Core Calculations
    
    /// Calculate present value of a future cash flow
    /// - Parameters:
    ///   - futureValue: Future amount to be received
    ///   - discountRate: Annual discount rate (required rate of return)
    ///   - timeInYears: Time period until cash flow is received
    /// - Returns: Present value calculation result
    public static func calculatePresentValue(
        futureValue: Decimal,
        discountRate: Decimal,
        timeInYears: Decimal
    ) -> PresentValueResult {
        
        // PV = FV / (1 + r)^t
        let onePlusRate = 1 + discountRate
        let discountFactor = power(base: onePlusRate, exponent: timeInYears)
        let presentValue = futureValue / discountFactor
        
        return PresentValueResult(
            futureValue: futureValue,
            discountRate: discountRate,
            timeInYears: timeInYears,
            presentValue: presentValue,
            discountFactor: discountFactor
        )
    }
    
    /// Calculate Net Present Value (NPV) for a series of cash flows
    /// - Parameters:
    ///   - initialInvestment: Initial investment amount (negative cash flow)
    ///   - cashFlows: Array of future cash flows with their timing
    ///   - discountRate: Required rate of return
    /// - Returns: NPV calculation result
    public static func calculateNPV(
        initialInvestment: Decimal,
        cashFlows: [(amount: Decimal, timeInYears: Decimal)],
        discountRate: Decimal
    ) -> NPVResult {
        
        var totalPresentValue: Decimal = 0
        var processedCashFlows: [CashFlow] = []
        
        // Calculate present value of each cash flow
        for cashFlow in cashFlows {
            let pvResult = calculatePresentValue(
                futureValue: cashFlow.amount,
                discountRate: discountRate,
                timeInYears: cashFlow.timeInYears
            )
            
            let processedCashFlow = CashFlow(
                amount: cashFlow.amount,
                timeInYears: cashFlow.timeInYears,
                presentValue: pvResult.presentValue
            )
            
            processedCashFlows.append(processedCashFlow)
            totalPresentValue += pvResult.presentValue
        }
        
        let netPresentValue = totalPresentValue - initialInvestment
        let isPositiveNPV = netPresentValue > 0
        
        return NPVResult(
            cashFlows: processedCashFlows,
            discountRate: discountRate,
            netPresentValue: netPresentValue,
            totalPresentValue: totalPresentValue,
            initialInvestment: initialInvestment,
            isPositiveNPV: isPositiveNPV
        )
    }
    
    /// Calculate present value of an annuity (series of equal payments)
    /// - Parameters:
    ///   - paymentAmount: Amount of each payment
    ///   - discountRate: Annual discount rate
    ///   - numberOfPayments: Total number of payments
    /// - Returns: Present value of the annuity
    public static func calculateAnnuityPresentValue(
        paymentAmount: Decimal,
        discountRate: Decimal,
        numberOfPayments: Int
    ) -> Decimal {
        
        if discountRate == 0 {
            // No discount scenario
            return paymentAmount * Decimal(numberOfPayments)
        }
        
        // PV = PMT * [(1 - (1 + r)^-n) / r]
        let onePlusRate = 1 + discountRate
        let discountFactor = power(base: onePlusRate, exponent: Decimal(-numberOfPayments))
        let numerator = 1 - discountFactor
        let annuityFactor = numerator / discountRate
        
        return paymentAmount * annuityFactor
    }
    
    /// Calculate present value of a perpetuity (infinite series of payments)
    /// - Parameters:
    ///   - paymentAmount: Amount of each payment
    ///   - discountRate: Annual discount rate
    /// - Returns: Present value of the perpetuity
    public static func calculatePerpetuityPresentValue(
        paymentAmount: Decimal,
        discountRate: Decimal
    ) -> Decimal {
        
        guard discountRate > 0 else {
            return Decimal.greatestFiniteMagnitude // Infinite value
        }
        
        // PV = PMT / r
        return paymentAmount / discountRate
    }
    
    /// Calculate present value of a growing perpetuity
    /// - Parameters:
    ///   - initialPayment: First payment amount
    ///   - growthRate: Annual growth rate of payments
    ///   - discountRate: Annual discount rate
    /// - Returns: Present value of the growing perpetuity
    public static func calculateGrowingPerpetuityPresentValue(
        initialPayment: Decimal,
        growthRate: Decimal,
        discountRate: Decimal
    ) -> Decimal {
        
        guard discountRate > growthRate && discountRate > 0 else {
            return Decimal.greatestFiniteMagnitude // Invalid parameters
        }
        
        // PV = PMT / (r - g)
        let denominator = discountRate - growthRate
        return initialPayment / denominator
    }
    
    /// Calculate present value with continuous compounding
    /// - Parameters:
    ///   - futureValue: Future amount to be received
    ///   - continuousRate: Continuous discount rate
    ///   - timeInYears: Time period until cash flow is received
    /// - Returns: Present value with continuous discounting
    public static func calculateContinuousPresentValue(
        futureValue: Decimal,
        continuousRate: Decimal,
        timeInYears: Decimal
    ) -> Decimal {
        
        // PV = FV * e^(-rt)
        let exponent = -continuousRate * timeInYears
        let discountFactor = calculateExponential(exponent)
        
        return futureValue * discountFactor
    }
    
    // MARK: - Goal-Specific Calculations
    
    /// Calculate how much needs to be invested today to reach a goal
    /// - Parameters:
    ///   - goalAmount: Target amount to achieve
    ///   - timeToGoal: Time period until goal is needed
    ///   - expectedReturn: Expected annual return rate
    /// - Returns: Required initial investment amount
    public static func calculateRequiredInitialInvestment(
        goalAmount: Decimal,
        timeToGoal: Decimal,
        expectedReturn: Decimal
    ) -> Decimal {
        
        let pvResult = calculatePresentValue(
            futureValue: goalAmount,
            discountRate: expectedReturn,
            timeInYears: timeToGoal
        )
        
        return pvResult.presentValue
    }
    
    /// Calculate present value of goal contributions over time
    /// - Parameters:
    ///   - monthlyContribution: Regular monthly contribution amount
    ///   - annualReturn: Expected annual return rate
    ///   - timeInYears: Investment period in years
    /// - Returns: Present value of all contributions
    public static func calculateContributionsPresentValue(
        monthlyContribution: Decimal,
        annualReturn: Decimal,
        timeInYears: Decimal
    ) -> Decimal {
        
        let monthlyRate = annualReturn / 12
        let numberOfPayments = Int(12 * Double(truncating: timeInYears as NSNumber))
        
        return calculateAnnuityPresentValue(
            paymentAmount: monthlyContribution,
            discountRate: monthlyRate,
            numberOfPayments: numberOfPayments
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
    
    /// Calculate exponential function (e^x) for continuous discounting
    private static func calculateExponential(_ x: Decimal) -> Decimal {
        let xDouble = Double(truncating: x as NSNumber)
        let result = exp(xDouble)
        return Decimal(result)
    }
}

// MARK: - Investment Analysis Extensions

extension PresentValueCalculator {
    
    /// Investment analysis result
    public struct InvestmentAnalysisResult: Sendable {
        public let presentValue: Decimal
        public let futureValue: Decimal
        public let totalReturn: Decimal
        public let annualizedReturn: Decimal
        public let roi: Decimal // Return on Investment percentage
        
        /// Initialize investment analysis result
        public init(presentValue: Decimal, futureValue: Decimal, totalReturn: Decimal, annualizedReturn: Decimal, roi: Decimal) {
            self.presentValue = presentValue
            self.futureValue = futureValue
            self.totalReturn = totalReturn
            self.annualizedReturn = annualizedReturn
            self.roi = roi
        }
    }
    
    /// Analyze investment return from present value perspective
    /// - Parameters:
    ///   - initialInvestment: Initial investment amount
    ///   - expectedFutureValue: Expected value at end of investment period
    ///   - timeInYears: Investment period in years
    /// - Returns: Investment analysis result
    public static func analyzeInvestmentReturn(
        initialInvestment: Decimal,
        expectedFutureValue: Decimal,
        timeInYears: Decimal
    ) -> InvestmentAnalysisResult {
        
        let totalReturn = expectedFutureValue - initialInvestment
        let roi = (totalReturn / initialInvestment) * 100
        
        // Calculate annualized return: (FV/PV)^(1/t) - 1
        let returnRatio = expectedFutureValue / initialInvestment
        let annualizedReturn = power(base: returnRatio, exponent: 1 / timeInYears) - 1
        
        return InvestmentAnalysisResult(
            presentValue: initialInvestment,
            futureValue: expectedFutureValue,
            totalReturn: totalReturn,
            annualizedReturn: annualizedReturn,
            roi: roi
        )
    }
}