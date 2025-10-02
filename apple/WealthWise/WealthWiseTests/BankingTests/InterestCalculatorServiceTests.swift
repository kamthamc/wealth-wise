//
//  InterestCalculatorServiceTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - InterestCalculatorService Tests
//

import XCTest
@testable import WealthWise

/// Comprehensive tests for InterestCalculatorService
@MainActor
final class InterestCalculatorServiceTests: XCTestCase {
    
    var calculator: InterestCalculatorService!
    
    override func setUp() {
        super.setUp()
        calculator = InterestCalculatorService.shared
    }
    
    // MARK: - Simple Interest Tests
    
    func testSimpleInterestBasicCalculation() {
        // Given
        let principal: Decimal = 100000
        let annualRate: Decimal = 0.06 // 6%
        let years: Decimal = 2
        
        // When
        let result = calculator.calculateSimpleInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: years
        )
        
        // Then
        // I = 100000 * 0.06 * 2 = 12000
        XCTAssertEqual(result.principal, principal)
        XCTAssertEqual(result.rate, annualRate)
        XCTAssertEqual(result.time, years)
        XCTAssertEqual(result.interest, 12000)
        XCTAssertEqual(result.totalAmount, 112000)
    }
    
    func testSimpleInterestWithDays() {
        // Given
        let principal: Decimal = 50000
        let annualRate: Decimal = 0.05 // 5%
        let days = 90 // Quarter
        
        // When
        let result = calculator.calculateSimpleInterest(
            principal: principal,
            annualRate: annualRate,
            days: days
        )
        
        // Then
        // I = 50000 * 0.05 * (90/365) = 616.44 approximately
        XCTAssertEqual(result.interest, 616.44, accuracy: 10)
        XCTAssertEqual(result.totalAmount, 50616.44, accuracy: 10)
    }
    
    func testSimpleInterestZeroRate() {
        // Given
        let principal: Decimal = 100000
        let annualRate: Decimal = 0
        let years: Decimal = 5
        
        // When
        let result = calculator.calculateSimpleInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: years
        )
        
        // Then
        XCTAssertEqual(result.interest, 0)
        XCTAssertEqual(result.totalAmount, principal)
    }
    
    // MARK: - Compound Interest Tests
    
    func testCompoundInterestAnnually() {
        // Given
        let principal: Decimal = 100000
        let annualRate: Decimal = 0.10 // 10%
        let years: Decimal = 3
        
        // When
        let result = calculator.calculateCompoundInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: years,
            compoundingFrequency: .annually
        )
        
        // Then
        // A = 100000 * (1.10)^3 = 133,100
        XCTAssertEqual(result.futureValue, 133100, accuracy: 10)
        XCTAssertEqual(result.totalInterest, 33100, accuracy: 10)
    }
    
    func testCompoundInterestQuarterly() {
        // Given
        let principal: Decimal = 100000
        let annualRate: Decimal = 0.08 // 8%
        let years: Decimal = 2
        
        // When
        let result = calculator.calculateCompoundInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: years,
            compoundingFrequency: .quarterly
        )
        
        // Then - Quarterly compounding yields more than annual
        XCTAssertGreaterThan(result.futureValue, 117000)
        XCTAssertLessThan(result.futureValue, 118000)
    }
    
    func testCompoundInterestMonthly() {
        // Given
        let principal: Decimal = 50000
        let annualRate: Decimal = 0.06 // 6%
        let years: Decimal = 1
        
        // When
        let result = calculator.calculateCompoundInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: years,
            compoundingFrequency: .monthly
        )
        
        // Then - Monthly compounding yields highest returns
        XCTAssertGreaterThan(result.futureValue, 53000)
        XCTAssertLessThan(result.futureValue, 53100)
    }
    
    // MARK: - Fixed Deposit Tests
    
    func testFixedDepositMaturityCumulative() {
        // Given
        let principal: Decimal = 100000
        let annualRate: Decimal = 6.5
        let tenureMonths = 12
        
        // When
        let result = calculator.calculateFixedDepositMaturity(
            principal: principal,
            annualRate: annualRate,
            tenureMonths: tenureMonths,
            compoundingFrequency: .quarterly,
            isInterestPaidOut: false
        )
        
        // Then
        XCTAssertEqual(result.principal, principal)
        XCTAssertEqual(result.rate, annualRate)
        XCTAssertTrue(result.isCumulative)
        XCTAssertGreaterThan(result.maturityAmount, 106500)
        XCTAssertLessThan(result.maturityAmount, 107000)
    }
    
    func testFixedDepositMaturityNonCumulative() {
        // Given
        let principal: Decimal = 100000
        let annualRate: Decimal = 6.5
        let tenureMonths = 12
        
        // When
        let result = calculator.calculateFixedDepositMaturity(
            principal: principal,
            annualRate: annualRate,
            tenureMonths: tenureMonths,
            isInterestPaidOut: true
        )
        
        // Then - Non-cumulative uses simple interest
        XCTAssertFalse(result.isCumulative)
        XCTAssertEqual(result.maturityAmount, 106500, accuracy: 10)
        XCTAssertEqual(result.interestEarned, 6500, accuracy: 10)
    }
    
    func testFixedDepositShortTerm() {
        // Given - 6 month FD
        let principal: Decimal = 200000
        let annualRate: Decimal = 5.5
        let tenureMonths = 6
        
        // When
        let result = calculator.calculateFixedDepositMaturity(
            principal: principal,
            annualRate: annualRate,
            tenureMonths: tenureMonths
        )
        
        // Then
        XCTAssertEqual(result.tenureInYears, 0.5)
        XCTAssertGreaterThan(result.maturityAmount, 205000)
        XCTAssertLessThan(result.maturityAmount, 206000)
    }
    
    func testFixedDepositLongTerm() {
        // Given - 5 year FD
        let principal: Decimal = 150000
        let annualRate: Decimal = 7.0
        let tenureMonths = 60
        
        // When
        let result = calculator.calculateFixedDepositMaturity(
            principal: principal,
            annualRate: annualRate,
            tenureMonths: tenureMonths
        )
        
        // Then
        XCTAssertEqual(result.tenureInYears, 5)
        XCTAssertGreaterThan(result.maturityAmount, 210000)
        XCTAssertGreaterThan(result.interestEarned, 60000)
    }
    
    // MARK: - Recurring Deposit Tests
    
    func testRecurringDepositMaturity() {
        // Given
        let monthlyInstallment: Decimal = 5000
        let annualRate: Decimal = 6.0
        let tenureMonths = 12
        
        // When
        let result = calculator.calculateRecurringDepositMaturity(
            monthlyInstallment: monthlyInstallment,
            annualRate: annualRate,
            tenureMonths: tenureMonths
        )
        
        // Then
        XCTAssertEqual(result.monthlyInstallment, monthlyInstallment)
        XCTAssertEqual(result.totalPrincipal, 60000) // 5000 * 12
        XCTAssertGreaterThan(result.interestEarned, 1900)
        XCTAssertLessThan(result.interestEarned, 2000)
        XCTAssertGreaterThan(result.maturityAmount, 61900)
    }
    
    func testRecurringDepositLongTerm() {
        // Given - 5 year RD
        let monthlyInstallment: Decimal = 10000
        let annualRate: Decimal = 6.5
        let tenureMonths = 60
        
        // When
        let result = calculator.calculateRecurringDepositMaturity(
            monthlyInstallment: monthlyInstallment,
            annualRate: annualRate,
            tenureMonths: tenureMonths
        )
        
        // Then
        XCTAssertEqual(result.totalPrincipal, 600000) // 10000 * 60
        XCTAssertGreaterThan(result.interestEarned, 100000)
        XCTAssertGreaterThan(result.maturityAmount, 700000)
    }
    
    func testRecurringDepositShortTerm() {
        // Given - 6 month RD
        let monthlyInstallment: Decimal = 2000
        let annualRate: Decimal = 5.5
        let tenureMonths = 6
        
        // When
        let result = calculator.calculateRecurringDepositMaturity(
            monthlyInstallment: monthlyInstallment,
            annualRate: annualRate,
            tenureMonths: tenureMonths
        )
        
        // Then
        XCTAssertEqual(result.totalPrincipal, 12000)
        XCTAssertGreaterThan(result.interestEarned, 190)
        XCTAssertLessThan(result.interestEarned, 200)
    }
    
    // MARK: - Savings Account Interest Tests
    
    func testSavingsAccountInterestQuarterly() {
        // Given
        let dailyBalances: [Decimal] = Array(repeating: 50000, count: 90)
        let annualRate: Decimal = 4.0
        let quarter = 1
        
        // When
        let interest = calculator.calculateSavingsAccountInterest(
            dailyBalances: dailyBalances,
            annualRate: annualRate,
            quarter: quarter
        )
        
        // Then
        // Quarterly interest = 50000 * 0.04 / 4 = 500
        XCTAssertEqual(interest, 500, accuracy: 1)
    }
    
    func testSavingsAccountInterestAverageBalance() {
        // Given
        let averageBalance: Decimal = 100000
        let annualRate: Decimal = 3.5
        let days = 90
        
        // When
        let interest = calculator.calculateSavingsAccountInterest(
            averageBalance: averageBalance,
            annualRate: annualRate,
            days: days
        )
        
        // Then
        // Daily rate = 3.5/365 = 0.00958904
        // Interest = 100000 * 0.00958904 * 90 = 863.01
        XCTAssertEqual(interest, 863.01, accuracy: 10)
    }
    
    func testSavingsAccountInterestEmptyBalances() {
        // Given
        let dailyBalances: [Decimal] = []
        let annualRate: Decimal = 4.0
        
        // When
        let interest = calculator.calculateSavingsAccountInterest(
            dailyBalances: dailyBalances,
            annualRate: annualRate,
            quarter: 1
        )
        
        // Then
        XCTAssertEqual(interest, 0)
    }
    
    // MARK: - TDS Calculation Tests
    
    func testTDSCalculationAboveThreshold() {
        // Given
        let interestAmount: Decimal = 50000
        let tdsRate: Decimal = 10
        
        // When
        let tds = calculator.calculateTDS(
            interestAmount: interestAmount,
            tdsRate: tdsRate,
            form15Submitted: false
        )
        
        // Then
        // TDS = 50000 * 0.10 = 5000
        XCTAssertEqual(tds, 5000)
    }
    
    func testTDSCalculationBelowThreshold() {
        // Given
        let interestAmount: Decimal = 30000
        let tdsRate: Decimal = 10
        
        // When
        let tds = calculator.calculateTDS(
            interestAmount: interestAmount,
            tdsRate: tdsRate,
            form15Submitted: false
        )
        
        // Then - No TDS below 40000
        XCTAssertEqual(tds, 0)
    }
    
    func testTDSCalculationWithForm15() {
        // Given
        let interestAmount: Decimal = 50000
        let tdsRate: Decimal = 10
        
        // When
        let tds = calculator.calculateTDS(
            interestAmount: interestAmount,
            tdsRate: tdsRate,
            form15Submitted: true
        )
        
        // Then - No TDS if Form 15G/H submitted
        XCTAssertEqual(tds, 0)
    }
    
    func testTDSCalculationAtThreshold() {
        // Given
        let interestAmount: Decimal = 40000
        let tdsRate: Decimal = 10
        
        // When
        let tds = calculator.calculateTDS(
            interestAmount: interestAmount,
            tdsRate: tdsRate,
            form15Submitted: false
        )
        
        // Then - No TDS at exactly 40000
        XCTAssertEqual(tds, 0)
    }
    
    // MARK: - Deposit Comparison Tests
    
    func testCompareDepositOptions() {
        // Given
        let amount: Decimal = 100000
        let options = [
            DepositOption(
                bankName: "HDFC Bank",
                depositType: "Regular FD",
                interestRate: 6.5,
                tenureMonths: 12,
                compoundingFrequency: .quarterly
            ),
            DepositOption(
                bankName: "SBI",
                depositType: "Regular FD",
                interestRate: 6.8,
                tenureMonths: 12,
                compoundingFrequency: .quarterly
            ),
            DepositOption(
                bankName: "ICICI Bank",
                depositType: "Regular FD",
                interestRate: 6.3,
                tenureMonths: 12,
                compoundingFrequency: .monthly
            )
        ]
        
        // When
        let results = calculator.compareDepositOptions(amount: amount, options: options)
        
        // Then
        XCTAssertEqual(results.count, 3)
        // SBI should be first (highest rate)
        XCTAssertEqual(results[0].bankName, "SBI")
        XCTAssertGreaterThan(results[0].result.maturityAmount, results[1].result.maturityAmount)
    }
    
    func testCompareDepositOptionsROI() {
        // Given
        let amount: Decimal = 100000
        let options = [
            DepositOption(
                bankName: "Bank A",
                depositType: "FD",
                interestRate: 7.0,
                tenureMonths: 12
            )
        ]
        
        // When
        let results = calculator.compareDepositOptions(amount: amount, options: options)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertGreaterThan(results[0].returnOnInvestment, 7.0)
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroPrincipal() {
        // Given
        let principal: Decimal = 0
        let annualRate: Decimal = 0.06
        let years: Decimal = 1
        
        // When
        let result = calculator.calculateSimpleInterest(
            principal: principal,
            annualRate: annualRate,
            timeInYears: years
        )
        
        // Then
        XCTAssertEqual(result.interest, 0)
        XCTAssertEqual(result.totalAmount, 0)
    }
    
    func testVeryLongTenure() {
        // Given - 30 year FD
        let principal: Decimal = 100000
        let annualRate: Decimal = 7.0
        let tenureMonths = 360
        
        // When
        let result = calculator.calculateFixedDepositMaturity(
            principal: principal,
            annualRate: annualRate,
            tenureMonths: tenureMonths
        )
        
        // Then - Should handle long tenures
        XCTAssertEqual(result.tenureInYears, 30)
        XCTAssertGreaterThan(result.maturityAmount, 700000)
    }
    
    // MARK: - Performance Tests
    
    func testSimpleInterestPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = calculator.calculateSimpleInterest(
                    principal: 100000,
                    annualRate: 0.06,
                    timeInYears: 2
                )
            }
        }
    }
    
    func testCompoundInterestPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = calculator.calculateCompoundInterest(
                    principal: 100000,
                    annualRate: 0.06,
                    timeInYears: 2,
                    compoundingFrequency: .quarterly
                )
            }
        }
    }
    
    func testFixedDepositCalculationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = calculator.calculateFixedDepositMaturity(
                    principal: 100000,
                    annualRate: 6.5,
                    tenureMonths: 12
                )
            }
        }
    }
}
