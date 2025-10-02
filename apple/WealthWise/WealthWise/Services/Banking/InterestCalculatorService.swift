//
//  InterestCalculatorService.swift
//  WealthWise
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - Interest Calculation Service
//

import Foundation

/// Comprehensive interest calculation service for banking products
/// Provides both simple and compound interest calculations with various frequencies
@MainActor
public final class InterestCalculatorService {
    
    // MARK: - Singleton
    
    public static let shared = InterestCalculatorService()
    
    private init() {}
    
    // MARK: - Simple Interest Calculations
    
    /// Calculate simple interest
    /// Formula: I = P * R * T
    /// - Parameters:
    ///   - principal: Principal amount
    ///   - annualRate: Annual interest rate as decimal (e.g., 0.065 for 6.5%)
    ///   - timeInYears: Time period in years
    /// - Returns: Simple interest result
    public func calculateSimpleInterest(
        principal: Decimal,
        annualRate: Decimal,
        timeInYears: Decimal
    ) -> SimpleInterestResult {
        let interest = principal * annualRate * timeInYears
        let totalAmount = principal + interest
        
        return SimpleInterestResult(
            principal: principal,
            rate: annualRate,
            time: timeInYears,
            interest: interest,
            totalAmount: totalAmount
        )
    }
    
    /// Calculate simple interest for a specific number of days
    /// - Parameters:
    ///   - principal: Principal amount
    ///   - annualRate: Annual interest rate as decimal
    ///   - days: Number of days
    /// - Returns: Simple interest result
    public func calculateSimpleInterest(
        principal: Decimal,
        annualRate: Decimal,
        days: Int
    ) -> SimpleInterestResult {
        let timeInYears = Decimal(days) / 365
        return calculateSimpleInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: timeInYears
        )
    }
    
    // MARK: - Compound Interest Calculations
    
    /// Calculate compound interest using existing CompoundInterestCalculator
    /// - Parameters:
    ///   - principal: Principal amount
    ///   - annualRate: Annual interest rate as decimal
    ///   - timeInYears: Time period in years
    ///   - compoundingFrequency: Frequency of compounding
    /// - Returns: Compound interest result
    public func calculateCompoundInterest(
        principal: Decimal,
        annualRate: Decimal,
        timeInYears: Decimal,
        compoundingFrequency: CompoundInterestCalculator.CompoundingFrequency = .quarterly
    ) -> CompoundInterestCalculator.CompoundInterestResult {
        return CompoundInterestCalculator.calculateCompoundInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: timeInYears,
            compoundingFrequency: compoundingFrequency
        )
    }
    
    // MARK: - Fixed Deposit Calculations
    
    /// Calculate fixed deposit maturity amount
    /// - Parameters:
    ///   - principal: Deposit amount
    ///   - annualRate: Interest rate as percentage (e.g., 6.5)
    ///   - tenureMonths: Tenure in months
    ///   - compoundingFrequency: Compounding frequency
    ///   - isInterestPaidOut: Whether interest is paid out periodically
    /// - Returns: Fixed deposit calculation result
    public func calculateFixedDepositMaturity(
        principal: Decimal,
        annualRate: Decimal,
        tenureMonths: Int,
        compoundingFrequency: CompoundInterestCalculator.CompoundingFrequency = .quarterly,
        isInterestPaidOut: Bool = false
    ) -> FixedDepositResult {
        let rateDecimal = annualRate / 100
        let timeInYears = Decimal(tenureMonths) / 12
        
        if isInterestPaidOut {
            // For non-cumulative FDs, calculate simple interest
            let result = calculateSimpleInterest(
                principal: principal,
                annualRate: rateDecimal,
                timeInYears: timeInYears
            )
            return FixedDepositResult(
                principal: principal,
                rate: annualRate,
                tenureMonths: tenureMonths,
                maturityAmount: result.totalAmount,
                interestEarned: result.interest,
                effectiveRate: annualRate,
                isCumulative: false
            )
        } else {
            // For cumulative FDs, use compound interest
            let result = calculateCompoundInterest(
                principal: principal,
                annualRate: rateDecimal,
                timeInYears: timeInYears,
                compoundingFrequency: compoundingFrequency
            )
            return FixedDepositResult(
                principal: principal,
                rate: annualRate,
                tenureMonths: tenureMonths,
                maturityAmount: result.futureValue,
                interestEarned: result.totalInterest,
                effectiveRate: result.effectiveAnnualRate * 100,
                isCumulative: true
            )
        }
    }
    
    /// Calculate recurring deposit maturity
    /// Formula: M = P × n × (n+1) / 2 × r / 12
    /// - Parameters:
    ///   - monthlyInstallment: Monthly deposit amount
    ///   - annualRate: Interest rate as percentage
    ///   - tenureMonths: Tenure in months
    /// - Returns: Recurring deposit result
    public func calculateRecurringDepositMaturity(
        monthlyInstallment: Decimal,
        annualRate: Decimal,
        tenureMonths: Int
    ) -> RecurringDepositResult {
        let rateDecimal = annualRate / 100
        let monthlyRate = rateDecimal / 12
        let n = Decimal(tenureMonths)
        
        // Total principal invested
        let totalPrincipal = monthlyInstallment * n
        
        // RD interest calculation
        let interest = monthlyInstallment * n * (n + 1) / 2 * monthlyRate
        let maturityAmount = totalPrincipal + interest
        
        return RecurringDepositResult(
            monthlyInstallment: monthlyInstallment,
            rate: annualRate,
            tenureMonths: tenureMonths,
            totalPrincipal: totalPrincipal,
            interestEarned: interest,
            maturityAmount: maturityAmount
        )
    }
    
    // MARK: - Savings Account Calculations
    
    /// Calculate savings account interest (quarterly compounding typical)
    /// - Parameters:
    ///   - dailyBalances: Array of daily balances
    ///   - annualRate: Interest rate as percentage
    ///   - quarter: Which quarter (1-4)
    /// - Returns: Quarterly interest amount
    public func calculateSavingsAccountInterest(
        dailyBalances: [Decimal],
        annualRate: Decimal,
        quarter: Int
    ) -> Decimal {
        guard !dailyBalances.isEmpty else { return 0 }
        
        // Calculate average daily balance
        let totalBalance = dailyBalances.reduce(0, +)
        let averageBalance = totalBalance / Decimal(dailyBalances.count)
        
        // Quarterly interest rate
        let quarterlyRate = (annualRate / 100) / 4
        
        return averageBalance * quarterlyRate
    }
    
    /// Calculate savings account interest for simplified average balance
    /// - Parameters:
    ///   - averageBalance: Average balance for the period
    ///   - annualRate: Interest rate as percentage
    ///   - days: Number of days
    /// - Returns: Interest amount
    public func calculateSavingsAccountInterest(
        averageBalance: Decimal,
        annualRate: Decimal,
        days: Int
    ) -> Decimal {
        let rateDecimal = annualRate / 100
        let dailyRate = rateDecimal / 365
        return averageBalance * dailyRate * Decimal(days)
    }
    
    // MARK: - Tax Calculations
    
    /// Calculate TDS (Tax Deducted at Source) on interest
    /// - Parameters:
    ///   - interestAmount: Interest earned
    ///   - tdsRate: TDS rate as percentage (typically 10%)
    ///   - form15Submitted: Whether Form 15G/15H submitted
    /// - Returns: TDS amount
    public func calculateTDS(
        interestAmount: Decimal,
        tdsRate: Decimal = 10,
        form15Submitted: Bool = false
    ) -> Decimal {
        guard !form15Submitted else { return 0 }
        
        // TDS applicable if interest exceeds ₹40,000 (₹50,000 for senior citizens)
        let tdsThreshold: Decimal = 40000
        
        guard interestAmount > tdsThreshold else { return 0 }
        
        return interestAmount * (tdsRate / 100)
    }
    
    // MARK: - Comparison and Planning
    
    /// Compare different deposit options
    /// - Parameters:
    ///   - amount: Investment amount
    ///   - options: Array of deposit options to compare
    /// - Returns: Sorted array of comparison results
    public func compareDepositOptions(
        amount: Decimal,
        options: [DepositOption]
    ) -> [DepositComparisonResult] {
        var results: [DepositComparisonResult] = []
        
        for option in options {
            let result = calculateFixedDepositMaturity(
                principal: amount,
                annualRate: option.interestRate,
                tenureMonths: option.tenureMonths,
                compoundingFrequency: option.compoundingFrequency,
                isInterestPaidOut: option.isInterestPaidOut
            )
            
            results.append(DepositComparisonResult(
                bankName: option.bankName,
                depositType: option.depositType,
                result: result,
                features: option.features
            ))
        }
        
        // Sort by maturity amount (highest first)
        return results.sorted { $0.result.maturityAmount > $1.result.maturityAmount }
    }
}

// MARK: - Result Types

/// Simple interest calculation result
public struct SimpleInterestResult {
    public let principal: Decimal
    public let rate: Decimal
    public let time: Decimal
    public let interest: Decimal
    public let totalAmount: Decimal
    
    public var displayInterest: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: interest as NSDecimalNumber) ?? "\(interest)"
    }
    
    public var displayTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: totalAmount as NSDecimalNumber) ?? "\(totalAmount)"
    }
}

/// Fixed deposit calculation result
public struct FixedDepositResult {
    public let principal: Decimal
    public let rate: Decimal
    public let tenureMonths: Int
    public let maturityAmount: Decimal
    public let interestEarned: Decimal
    public let effectiveRate: Decimal
    public let isCumulative: Bool
    
    public var tenureInYears: Decimal {
        return Decimal(tenureMonths) / 12
    }
    
    public var displayMaturityAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: maturityAmount as NSDecimalNumber) ?? "\(maturityAmount)"
    }
}

/// Recurring deposit calculation result
public struct RecurringDepositResult {
    public let monthlyInstallment: Decimal
    public let rate: Decimal
    public let tenureMonths: Int
    public let totalPrincipal: Decimal
    public let interestEarned: Decimal
    public let maturityAmount: Decimal
    
    public var displayMaturityAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        return formatter.string(from: maturityAmount as NSDecimalNumber) ?? "\(maturityAmount)"
    }
}

/// Deposit option for comparison
public struct DepositOption {
    public let bankName: String
    public let depositType: String
    public let interestRate: Decimal
    public let tenureMonths: Int
    public let compoundingFrequency: CompoundInterestCalculator.CompoundingFrequency
    public let isInterestPaidOut: Bool
    public let features: [String]
    
    public init(
        bankName: String,
        depositType: String,
        interestRate: Decimal,
        tenureMonths: Int,
        compoundingFrequency: CompoundInterestCalculator.CompoundingFrequency = .quarterly,
        isInterestPaidOut: Bool = false,
        features: [String] = []
    ) {
        self.bankName = bankName
        self.depositType = depositType
        self.interestRate = interestRate
        self.tenureMonths = tenureMonths
        self.compoundingFrequency = compoundingFrequency
        self.isInterestPaidOut = isInterestPaidOut
        self.features = features
    }
}

/// Deposit comparison result
public struct DepositComparisonResult {
    public let bankName: String
    public let depositType: String
    public let result: FixedDepositResult
    public let features: [String]
    
    public var returnOnInvestment: Decimal {
        return (result.interestEarned / result.principal) * 100
    }
}
