//
//  BankAccountTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - BankAccount Model Tests
//

import XCTest
@testable import WealthWise

/// Comprehensive tests for BankAccount model
@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class BankAccountTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    
    func testBankAccountInitialization() {
        // Given
        let accountName = "Primary Savings"
        let accountNumber = "12345678901"
        let bankName = "HDFC Bank"
        let balance: Decimal = 50000
        
        // When
        let account = BankAccount(
            accountName: accountName,
            accountNumber: accountNumber,
            accountType: .savings,
            bankName: bankName,
            currentBalance: balance,
            accountHolderName: "Test User"
        )
        
        // Then
        XCTAssertEqual(account.accountName, accountName)
        XCTAssertEqual(account.accountNumber, accountNumber)
        XCTAssertEqual(account.bankName, bankName)
        XCTAssertEqual(account.currentBalance, balance)
        XCTAssertEqual(account.availableBalance, balance)
        XCTAssertEqual(account.accountType, .savings)
        XCTAssertTrue(account.isActive)
        XCTAssertFalse(account.isPrimary)
        XCTAssertEqual(account.currency, "INR")
        XCTAssertEqual(account.totalInterestEarned, 0)
    }
    
    func testSavingsAccountDefaults() {
        // Given / When
        let account = BankAccount(
            accountName: "Savings Account",
            accountNumber: "ACC123",
            accountType: .savings,
            bankName: "SBI",
            accountHolderName: "Test User"
        )
        
        // Then
        XCTAssertEqual(account.accountType.defaultMinimumBalance, 1000)
        XCTAssertEqual(account.accountType.defaultInterestRate, 3.5)
        XCTAssertEqual(account.interestCalculationType, .compound)
        XCTAssertTrue(account.isTaxable)
    }
    
    func testCurrentAccountDefaults() {
        // Given / When
        let account = BankAccount(
            accountName: "Business Current",
            accountNumber: "CUR456",
            accountType: .current,
            bankName: "ICICI",
            currentBalance: 100000,
            minimumBalance: 5000,
            accountHolderName: "Business Owner"
        )
        
        // Then
        XCTAssertEqual(account.accountType.defaultMinimumBalance, 5000)
        XCTAssertEqual(account.accountType.defaultInterestRate, 0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testDisplayBalance() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 100000,
            accountHolderName: "Test User"
        )
        
        // When
        let displayBalance = account.displayBalance
        
        // Then
        XCTAssertFalse(displayBalance.isEmpty)
        XCTAssertTrue(displayBalance.contains("100") || displayBalance.contains("₹"))
    }
    
    func testIsBelowMinimumBalance() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 500,
            minimumBalance: 1000,
            accountHolderName: "Test User"
        )
        
        // Then
        XCTAssertTrue(account.isBelowMinimumBalance)
        
        // When - Update balance above minimum
        account.updateBalance(newBalance: 2000)
        
        // Then
        XCTAssertFalse(account.isBelowMinimumBalance)
    }
    
    func testTotalAvailableBalance() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .current,
            bankName: "Test Bank",
            currentBalance: 10000,
            accountHolderName: "Test User"
        )
        account.overdraftLimit = 5000
        
        // When
        let totalAvailable = account.totalAvailableBalance
        
        // Then
        XCTAssertEqual(totalAvailable, 15000)
    }
    
    func testDaysActive() {
        // Given
        let calendar = Calendar.current
        let openingDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            accountHolderName: "Test User",
            openingDate: openingDate
        )
        
        // When
        let daysActive = account.daysActive
        
        // Then
        XCTAssertEqual(daysActive, 30)
    }
    
    // MARK: - Interest Calculation Tests
    
    func testCalculateSimpleInterest() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 100000,
            interestRate: 4.0,
            interestCalculationType: .simple,
            accountHolderName: "Test User"
        )
        
        // When
        let interest = account.calculateInterestEarned(days: 365)
        
        // Then
        // Simple interest: 100000 * 0.04 * 1 = 4000
        XCTAssertEqual(interest, 4000, accuracy: 0.01)
    }
    
    func testCalculateCompoundInterest() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 100000,
            interestRate: 4.0,
            interestCalculationType: .compound,
            accountHolderName: "Test User"
        )
        
        // When
        let interest = account.calculateInterestEarned(days: 365)
        
        // Then
        // Compound interest should be slightly more than simple
        XCTAssertGreaterThan(interest, 4000)
        XCTAssertLessThan(interest, 4500)
    }
    
    func testCalculateInterestForPartialPeriod() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 100000,
            interestRate: 4.0,
            interestCalculationType: .simple,
            accountHolderName: "Test User"
        )
        
        // When - 90 days (quarter)
        let interest = account.calculateInterestEarned(days: 90)
        
        // Then
        // Should be approximately 1000 (quarter of annual interest)
        XCTAssertEqual(interest, 986.3, accuracy: 50)
    }
    
    // MARK: - Balance Update Tests
    
    func testUpdateBalance() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 10000,
            accountHolderName: "Test User"
        )
        
        let initialUpdateTime = account.updatedAt
        
        // When
        Thread.sleep(forTimeInterval: 0.01)
        account.updateBalance(newBalance: 15000)
        
        // Then
        XCTAssertEqual(account.currentBalance, 15000)
        XCTAssertEqual(account.availableBalance, 15000)
        XCTAssertNotNil(account.lastTransactionDate)
        XCTAssertGreaterThan(account.updatedAt, initialUpdateTime)
    }
    
    func testCreditInterest() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 100000,
            accountHolderName: "Test User"
        )
        
        // When
        let interestAmount: Decimal = 1000
        account.creditInterest(amount: interestAmount)
        
        // Then
        XCTAssertEqual(account.currentBalance, 101000)
        XCTAssertEqual(account.availableBalance, 101000)
        XCTAssertEqual(account.totalInterestEarned, 1000)
        XCTAssertNotNil(account.lastInterestCreditDate)
    }
    
    // MARK: - Joint Account Tests
    
    func testJointAccountSetup() {
        // Given
        let account = BankAccount(
            accountName: "Joint Savings",
            accountNumber: "JNT123",
            accountType: .savings,
            bankName: "HDFC",
            accountHolderName: "Primary Holder",
            accountHolderType: .joint
        )
        
        // When
        account.isJointAccount = true
        account.jointHolderNames = ["Secondary Holder 1", "Secondary Holder 2"]
        
        // Then
        XCTAssertTrue(account.isJointAccount)
        XCTAssertEqual(account.accountHolderType, .joint)
        XCTAssertEqual(account.jointHolderNames.count, 2)
    }
    
    // MARK: - Multi-Currency Tests
    
    func testMultiCurrencyAccount() {
        // Given
        let account = BankAccount(
            accountName: "NRI Account",
            accountNumber: "NRI123",
            accountType: .nri,
            bankName: "SBI",
            currentBalance: 10000,
            currency: "USD",
            accountHolderName: "NRI Customer"
        )
        
        // When
        account.isMultiCurrency = true
        account.supportedCurrencies = ["USD", "EUR", "GBP"]
        
        // Then
        XCTAssertTrue(account.isMultiCurrency)
        XCTAssertEqual(account.currency, "USD")
        XCTAssertEqual(account.supportedCurrencies.count, 3)
    }
    
    // MARK: - Performance Tests
    
    func testAccountCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = BankAccount(
                    accountName: "Performance Test",
                    accountNumber: "PERF\(UUID().uuidString)",
                    accountType: .savings,
                    bankName: "Test Bank",
                    currentBalance: 100000,
                    accountHolderName: "Test User"
                )
            }
        }
    }
    
    func testInterestCalculationPerformance() {
        // Given
        let account = BankAccount(
            accountName: "Test Account",
            accountNumber: "123",
            accountType: .savings,
            bankName: "Test Bank",
            currentBalance: 100000,
            interestRate: 4.0,
            accountHolderName: "Test User"
        )
        
        // When / Then
        measure {
            for _ in 0..<1000 {
                _ = account.calculateInterestEarned(days: 365)
            }
        }
    }
}
