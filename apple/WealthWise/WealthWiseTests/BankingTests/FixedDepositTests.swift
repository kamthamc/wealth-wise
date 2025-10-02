//
//  FixedDepositTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - FixedDeposit Model Tests
//

import XCTest
@testable import WealthWise

/// Comprehensive tests for FixedDeposit model
@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class FixedDepositTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    
    func testFixedDepositInitialization() {
        // Given
        let depositName = "HDFC 1 Year FD"
        let bankName = "HDFC Bank"
        let principal: Decimal = 100000
        let interestRate: Decimal = 6.5
        let tenure = 12
        
        // When
        let fd = FixedDeposit(
            depositName: depositName,
            bankName: bankName,
            principalAmount: principal,
            interestRate: interestRate,
            tenureInMonths: tenure
        )
        
        // Then
        XCTAssertEqual(fd.depositName, depositName)
        XCTAssertEqual(fd.bankName, bankName)
        XCTAssertEqual(fd.principalAmount, principal)
        XCTAssertEqual(fd.interestRate, interestRate)
        XCTAssertEqual(fd.tenureInMonths, tenure)
        XCTAssertFalse(fd.isMatured)
        XCTAssertEqual(fd.status, .active)
        XCTAssertEqual(fd.currency, "INR")
        XCTAssertGreaterThan(fd.maturityAmount, principal)
    }
    
    func testMaturityDateCalculation() {
        // Given
        let depositDate = Date()
        let tenure = 12
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            depositDate: depositDate,
            tenureInMonths: tenure
        )
        
        // Then
        let calendar = Calendar.current
        let expectedMaturity = calendar.date(byAdding: .month, value: tenure, to: depositDate)!
        let components = calendar.dateComponents([.day], from: fd.maturityDate, to: expectedMaturity)
        XCTAssertLessThanOrEqual(abs(components.day ?? 0), 1) // Allow 1 day difference
    }
    
    func testMaturityAmountCalculation() {
        // Given - 100000 @ 6.5% for 12 months with quarterly compounding
        let principal: Decimal = 100000
        let rate: Decimal = 6.5
        let tenure = 12
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: principal,
            interestRate: rate,
            compoundingFrequency: .quarterly,
            tenureInMonths: tenure
        )
        
        // Then - Expected: ~106,699
        XCTAssertGreaterThan(fd.maturityAmount, 106500)
        XCTAssertLessThan(fd.maturityAmount, 107000)
        XCTAssertGreaterThan(fd.interestEarned, 6500)
        XCTAssertLessThan(fd.interestEarned, 7000)
    }
    
    // MARK: - Maturity Tracking Tests
    
    func testDaysToMaturity() {
        // Given
        let calendar = Calendar.current
        let depositDate = calendar.date(byAdding: .month, value: -6, to: Date())!
        let tenure = 12
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            depositDate: depositDate,
            tenureInMonths: tenure
        )
        
        // Then - Should be approximately 180 days remaining
        XCTAssertGreaterThan(fd.daysToMaturity, 170)
        XCTAssertLessThan(fd.daysToMaturity, 190)
    }
    
    func testShouldShowMaturityAlert() {
        // Given - FD maturing in 20 days
        let calendar = Calendar.current
        let depositDate = calendar.date(byAdding: .day, value: -345, to: Date())!
        let tenure = 12
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            depositDate: depositDate,
            tenureInMonths: tenure
        )
        
        // Then - Should show alert (within 30 days)
        XCTAssertTrue(fd.shouldShowMaturityAlert)
        XCTAssertLessThanOrEqual(fd.daysToMaturity, 30)
    }
    
    func testProgressPercentage() {
        // Given - FD halfway through tenure
        let calendar = Calendar.current
        let depositDate = calendar.date(byAdding: .month, value: -6, to: Date())!
        let tenure = 12
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            depositDate: depositDate,
            tenureInMonths: tenure
        )
        
        // Then - Should be approximately 50%
        XCTAssertGreaterThan(fd.progressPercentage, 45)
        XCTAssertLessThan(fd.progressPercentage, 55)
    }
    
    func testCurrentValue() {
        // Given - FD halfway through tenure
        let calendar = Calendar.current
        let depositDate = calendar.date(byAdding: .month, value: -6, to: Date())!
        let principal: Decimal = 100000
        let tenure = 12
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: principal,
            interestRate: 6.5,
            depositDate: depositDate,
            tenureInMonths: tenure
        )
        
        // Then - Current value should be between principal and maturity amount
        XCTAssertGreaterThan(fd.currentValue, principal)
        XCTAssertLessThan(fd.currentValue, fd.maturityAmount)
    }
    
    // MARK: - Premature Withdrawal Tests
    
    func testPrematureWithdrawal() {
        // Given - FD with 1% penalty
        let principal: Decimal = 100000
        let rate: Decimal = 6.5
        let penalty: Decimal = 1.0
        
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: principal,
            interestRate: rate,
            tenureInMonths: 12
        )
        fd.penaltyOnPrematureWithdrawal = penalty
        
        // When - Withdraw after 6 months
        let calendar = Calendar.current
        let withdrawalDate = calendar.date(byAdding: .month, value: 6, to: fd.depositDate)!
        let result = fd.calculatePrematureWithdrawal(on: withdrawalDate)
        
        // Then - Should get less than full maturity
        XCTAssertLessThan(result.withdrawalAmount, fd.maturityAmount)
        XCTAssertGreaterThan(result.withdrawalAmount, principal)
        XCTAssertEqual(result.effectiveRate, rate - penalty)
        XCTAssertGreaterThan(result.penaltyAmount, 0)
    }
    
    func testPrematureWithdrawalImmediately() {
        // Given
        let principal: Decimal = 100000
        
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: principal,
            interestRate: 6.5,
            tenureInMonths: 12
        )
        
        // When - Withdraw immediately
        let result = fd.calculatePrematureWithdrawal(on: fd.depositDate)
        
        // Then - Should get approximately principal amount
        XCTAssertEqual(result.withdrawalAmount, principal, accuracy: 100)
        XCTAssertLessThanOrEqual(result.interestEarned, 100)
    }
    
    // MARK: - Maturity and Renewal Tests
    
    func testMarkAsMatured() {
        // Given
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12
        )
        
        // When
        fd.markAsMatured()
        
        // Then
        XCTAssertTrue(fd.isMatured)
        XCTAssertEqual(fd.status, .matured)
        XCTAssertNotNil(fd.actualMaturityDate)
    }
    
    func testRenewal() {
        // Given
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12
        )
        fd.markAsMatured()
        
        let oldMaturityAmount = fd.maturityAmount
        let newRate: Decimal = 7.0
        
        // When
        fd.renew(newInterestRate: newRate)
        
        // Then
        XCTAssertFalse(fd.isMatured)
        XCTAssertEqual(fd.status, .active)
        XCTAssertEqual(fd.principalAmount, oldMaturityAmount) // Renewed with maturity amount
        XCTAssertEqual(fd.interestRate, newRate)
        XCTAssertFalse(fd.alertSent)
    }
    
    func testRenewalWithCustomAmount() {
        // Given
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12
        )
        
        let newPrincipal: Decimal = 150000
        
        // When
        fd.renew(newPrincipal: newPrincipal)
        
        // Then
        XCTAssertEqual(fd.principalAmount, newPrincipal)
        XCTAssertFalse(fd.isMatured)
        XCTAssertEqual(fd.status, .active)
    }
    
    // MARK: - Different Deposit Types Tests
    
    func testTaxSavingFD() {
        // Given / When
        let fd = FixedDeposit(
            depositName: "Tax Saver FD",
            bankName: "SBI",
            principalAmount: 150000,
            interestRate: 6.5,
            tenureInMonths: 60, // 5 years minimum
            depositType: .tax_saving
        )
        
        // Then
        XCTAssertEqual(fd.depositType, .tax_saving)
        XCTAssertGreaterThanOrEqual(fd.tenureInMonths, 60) // Tax saving FDs have 5-year lock-in
    }
    
    func testSeniorCitizenFD() {
        // Given / When - Senior citizens typically get 0.5% extra
        let fd = FixedDeposit(
            depositName: "Senior Citizen FD",
            bankName: "HDFC",
            principalAmount: 200000,
            interestRate: 7.0, // Higher rate for senior citizens
            tenureInMonths: 12,
            depositType: .senior_citizen
        )
        
        // Then
        XCTAssertEqual(fd.depositType, .senior_citizen)
        XCTAssertGreaterThan(fd.interestRate, 6.5) // Higher than regular FD
    }
    
    func testCumulativeFD() {
        // Given / When
        let fd = FixedDeposit(
            depositName: "Cumulative FD",
            bankName: "ICICI",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12,
            depositType: .cumulative,
            interestPayoutMode: .onMaturity
        )
        
        // Then
        XCTAssertEqual(fd.depositType, .cumulative)
        XCTAssertEqual(fd.interestPayoutMode, .onMaturity)
        XCTAssertGreaterThan(fd.maturityAmount, fd.principalAmount)
    }
    
    func testNonCumulativeFD() {
        // Given / When
        let fd = FixedDeposit(
            depositName: "Non-Cumulative FD",
            bankName: "ICICI",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12,
            depositType: .nonCumulative,
            interestPayoutMode: .monthly
        )
        
        // Then
        XCTAssertEqual(fd.depositType, .nonCumulative)
        XCTAssertEqual(fd.interestPayoutMode, .monthly)
    }
    
    // MARK: - Display Properties Tests
    
    func testDisplayPrincipal() {
        // Given
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12
        )
        
        // When
        let display = fd.displayPrincipal
        
        // Then
        XCTAssertFalse(display.isEmpty)
        XCTAssertTrue(display.contains("100") || display.contains("₹"))
    }
    
    func testDisplayMaturityAmount() {
        // Given
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12
        )
        
        // When
        let display = fd.displayMaturityAmount
        
        // Then
        XCTAssertFalse(display.isEmpty)
        XCTAssertTrue(display.contains("106") || display.contains("107"))
    }
    
    // MARK: - Compounding Frequency Tests
    
    func testMonthlyCompounding() {
        // Given
        let principal: Decimal = 100000
        let rate: Decimal = 6.5
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: principal,
            interestRate: rate,
            compoundingFrequency: .monthly,
            tenureInMonths: 12
        )
        
        // Then - Monthly compounding should yield higher returns
        XCTAssertGreaterThan(fd.maturityAmount, 106700)
    }
    
    func testQuarterlyCompounding() {
        // Given
        let principal: Decimal = 100000
        let rate: Decimal = 6.5
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: principal,
            interestRate: rate,
            compoundingFrequency: .quarterly,
            tenureInMonths: 12
        )
        
        // Then
        XCTAssertGreaterThan(fd.maturityAmount, 106500)
        XCTAssertLessThan(fd.maturityAmount, 107000)
    }
    
    func testAnnualCompounding() {
        // Given
        let principal: Decimal = 100000
        let rate: Decimal = 6.5
        
        // When
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: principal,
            interestRate: rate,
            compoundingFrequency: .annually,
            tenureInMonths: 12
        )
        
        // Then - Annual compounding should yield lowest returns
        XCTAssertEqual(fd.maturityAmount, 106500, accuracy: 10)
    }
    
    // MARK: - Performance Tests
    
    func testFixedDepositCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = FixedDeposit(
                    depositName: "Performance Test FD",
                    bankName: "Test Bank",
                    principalAmount: 100000,
                    interestRate: 6.5,
                    tenureInMonths: 12
                )
            }
        }
    }
    
    func testPrematureWithdrawalCalculationPerformance() {
        // Given
        let fd = FixedDeposit(
            depositName: "Test FD",
            bankName: "Test Bank",
            principalAmount: 100000,
            interestRate: 6.5,
            tenureInMonths: 12
        )
        
        // When / Then
        measure {
            for _ in 0..<1000 {
                _ = fd.calculatePrematureWithdrawal()
            }
        }
    }
}
