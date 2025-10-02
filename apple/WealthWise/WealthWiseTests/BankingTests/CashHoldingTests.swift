//
//  CashHoldingTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - CashHolding Model Tests
//

import XCTest
@testable import WealthWise

/// Comprehensive tests for CashHolding model
@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class CashHoldingTests: XCTestCase {
    
    // MARK: - Basic Model Tests
    
    func testCashHoldingInitialization() {
        // Given
        let name = "Daily Wallet"
        let amount: Decimal = 5000
        let holdingType: CashHoldingType = .wallet
        
        // When
        let cash = CashHolding(
            name: name,
            holdingType: holdingType,
            amount: amount,
            currency: "INR"
        )
        
        // Then
        XCTAssertEqual(cash.name, name)
        XCTAssertEqual(cash.amount, amount)
        XCTAssertEqual(cash.currency, "INR")
        XCTAssertEqual(cash.holdingType, holdingType)
        XCTAssertEqual(cash.baseCurrency, "INR")
        XCTAssertEqual(cash.baseCurrencyAmount, amount)
        XCTAssertTrue(cash.isAccessible)
        XCTAssertFalse(cash.isEmergencyFund)
    }
    
    func testEmergencyFundSetup() {
        // Given / When
        let cash = CashHolding(
            name: "Emergency Fund",
            holdingType: .emergency,
            amount: 50000,
            purpose: .emergency
        )
        cash.isEmergencyFund = true
        cash.targetEmergencyAmount = 100000
        
        // Then
        XCTAssertEqual(cash.holdingType, .emergency)
        XCTAssertEqual(cash.purpose, .emergency)
        XCTAssertTrue(cash.isEmergencyFund)
        XCTAssertEqual(cash.targetEmergencyAmount, 100000)
    }
    
    func testPhysicalCashInSafe() {
        // Given / When
        let cash = CashHolding(
            name: "Home Safe",
            holdingType: .safe,
            amount: 100000,
            location: .safe
        )
        cash.isSecured = true
        cash.securityMeasure = "Fireproof safe with biometric lock"
        
        // Then
        XCTAssertEqual(cash.location, .safe)
        XCTAssertEqual(cash.location.securityLevel, 4)
        XCTAssertTrue(cash.isSecured)
        XCTAssertNotNil(cash.securityMeasure)
    }
    
    // MARK: - Multi-Currency Tests
    
    func testForeignCurrencyHolding() {
        // Given
        let amount: Decimal = 1000
        let currency = "USD"
        let baseCurrency = "INR"
        
        // When
        let cash = CashHolding(
            name: "US Dollars",
            holdingType: .foreign,
            amount: amount,
            currency: currency,
            baseCurrency: baseCurrency
        )
        
        // Then
        XCTAssertEqual(cash.currency, "USD")
        XCTAssertEqual(cash.baseCurrency, "INR")
        XCTAssertTrue(cash.isForeignCurrency)
    }
    
    func testCurrencyConversion() {
        // Given
        let cash = CashHolding(
            name: "Foreign Cash",
            holdingType: .foreign,
            amount: 1000,
            currency: "USD",
            baseCurrency: "INR"
        )
        
        let exchangeRate: Decimal = 83.5 // 1 USD = 83.5 INR
        
        // When
        cash.updateAmount(1000, exchangeRate: exchangeRate)
        
        // Then
        XCTAssertEqual(cash.amount, 1000)
        XCTAssertEqual(cash.baseCurrencyAmount, 83500)
        XCTAssertEqual(cash.exchangeRate, exchangeRate)
        XCTAssertNotNil(cash.lastExchangeRateUpdate)
    }
    
    func testConvertToCurrency() {
        // Given
        let cash = CashHolding(
            name: "Test Cash",
            holdingType: .wallet,
            amount: 1000,
            currency: "USD",
            baseCurrency: "INR"
        )
        cash.baseCurrencyAmount = 83500 // Already converted
        
        // When
        let convertedAmount = cash.convertToCurrency("EUR", rate: 0.9) // INR to EUR rate
        
        // Then
        XCTAssertGreaterThan(convertedAmount, 0)
    }
    
    // MARK: - Denomination Tests
    
    func testAddDenomination() {
        // Given
        let cash = CashHolding(
            name: "Physical Cash",
            holdingType: .physical,
            amount: 0
        )
        
        // When
        cash.addDenomination(value: 500, count: 10)  // 10 notes of ₹500
        cash.addDenomination(value: 200, count: 5)   // 5 notes of ₹200
        cash.addDenomination(value: 100, count: 20)  // 20 notes of ₹100
        
        // Then
        XCTAssertEqual(cash.denominations.count, 3)
        XCTAssertTrue(cash.hasDenominationDetails)
        XCTAssertEqual(cash.denominationTotal, 8000) // 5000 + 1000 + 2000
    }
    
    func testDenominationConsistency() {
        // Given
        let cash = CashHolding(
            name: "Physical Cash",
            holdingType: .physical,
            amount: 8000
        )
        
        // When
        cash.addDenomination(value: 500, count: 10)
        cash.addDenomination(value: 200, count: 5)
        cash.addDenomination(value: 100, count: 20)
        
        // Then
        XCTAssertTrue(cash.isDenominationConsistent)
    }
    
    func testDenominationInconsistency() {
        // Given
        let cash = CashHolding(
            name: "Physical Cash",
            holdingType: .physical,
            amount: 10000
        )
        
        // When
        cash.addDenomination(value: 500, count: 10) // Total: 5000
        
        // Then - Amount doesn't match denominations
        XCTAssertFalse(cash.isDenominationConsistent)
    }
    
    func testAddingDuplicateDenomination() {
        // Given
        let cash = CashHolding(
            name: "Physical Cash",
            holdingType: .physical,
            amount: 0
        )
        
        // When - Add same denomination twice
        cash.addDenomination(value: 500, count: 5)
        cash.addDenomination(value: 500, count: 3)
        
        // Then - Should combine counts
        XCTAssertEqual(cash.denominations.count, 1)
        let denomination = cash.denominations.first { $0.value == 500 }
        XCTAssertEqual(denomination?.count, 8)
    }
    
    // MARK: - Display Properties Tests
    
    func testDisplayAmount() {
        // Given
        let cash = CashHolding(
            name: "Test Cash",
            holdingType: .wallet,
            amount: 5000
        )
        
        // When
        let display = cash.displayAmount
        
        // Then
        XCTAssertFalse(display.isEmpty)
        XCTAssertTrue(display.contains("5") || display.contains("₹"))
    }
    
    func testDisplayBaseCurrencyAmount() {
        // Given
        let cash = CashHolding(
            name: "Foreign Cash",
            holdingType: .foreign,
            amount: 100,
            currency: "USD",
            baseCurrency: "INR"
        )
        cash.baseCurrencyAmount = 8350
        
        // When
        let display = cash.displayBaseCurrencyAmount
        
        // Then
        XCTAssertFalse(display.isEmpty)
        XCTAssertTrue(display.contains("8") || display.contains("₹"))
    }
    
    // MARK: - Update Tests
    
    func testUpdateAmount() {
        // Given
        let cash = CashHolding(
            name: "Test Cash",
            holdingType: .wallet,
            amount: 5000
        )
        
        let initialUpdateTime = cash.lastUpdated
        
        // When
        Thread.sleep(forTimeInterval: 0.01)
        cash.updateAmount(7500)
        
        // Then
        XCTAssertEqual(cash.amount, 7500)
        XCTAssertGreaterThan(cash.lastUpdated, initialUpdateTime)
    }
    
    func testUpdateAmountWithExchangeRate() {
        // Given
        let cash = CashHolding(
            name: "Foreign Cash",
            holdingType: .foreign,
            amount: 100,
            currency: "USD",
            baseCurrency: "INR"
        )
        
        // When
        cash.updateAmount(150, exchangeRate: 83.5)
        
        // Then
        XCTAssertEqual(cash.amount, 150)
        XCTAssertEqual(cash.baseCurrencyAmount, 12525) // 150 * 83.5
        XCTAssertNotNil(cash.lastExchangeRateUpdate)
    }
    
    func testVerifyHolding() {
        // Given
        let cash = CashHolding(
            name: "Test Cash",
            holdingType: .safe,
            amount: 50000
        )
        
        // When
        cash.verifyHolding()
        
        // Then
        XCTAssertNotNil(cash.lastVerified)
    }
    
    // MARK: - Location and Security Tests
    
    func testLocationSecurityLevels() {
        // Given / When / Then
        XCTAssertEqual(CashLocation.locker.securityLevel, 5) // Highest
        XCTAssertEqual(CashLocation.safe.securityLevel, 4)
        XCTAssertEqual(CashLocation.home.securityLevel, 3)
        XCTAssertEqual(CashLocation.wallet.securityLevel, 2)
        XCTAssertEqual(CashLocation.vehicle.securityLevel, 1) // Lowest
    }
    
    func testSecuredCashWithInsurance() {
        // Given
        let cash = CashHolding(
            name: "Bank Locker",
            holdingType: .locker,
            amount: 500000,
            location: .locker
        )
        
        // When
        cash.isSecured = true
        cash.insuranceCovered = true
        cash.insuranceAmount = 500000
        
        // Then
        XCTAssertTrue(cash.isSecured)
        XCTAssertTrue(cash.insuranceCovered)
        XCTAssertEqual(cash.insuranceAmount, 500000)
    }
    
    // MARK: - Purpose Classification Tests
    
    func testTravelExpenseCash() {
        // Given / When
        let cash = CashHolding(
            name: "Travel Money",
            holdingType: .physical,
            amount: 20000,
            location: .wallet,
            purpose: .travel
        )
        
        // Then
        XCTAssertEqual(cash.purpose, .travel)
        XCTAssertEqual(cash.location, .wallet)
    }
    
    func testBusinessCash() {
        // Given / When
        let cash = CashHolding(
            name: "Petty Cash",
            holdingType: .petty,
            amount: 10000,
            location: .office,
            purpose: .business
        )
        
        // Then
        XCTAssertEqual(cash.purpose, .business)
        XCTAssertEqual(cash.holdingType, .petty)
        XCTAssertEqual(cash.location, .office)
    }
    
    // MARK: - Tags and Notes Tests
    
    func testTagsAndNotes() {
        // Given
        let cash = CashHolding(
            name: "Test Cash",
            holdingType: .wallet,
            amount: 5000
        )
        
        // When
        cash.tags = ["urgent", "backup", "emergency"]
        cash.notes = "Keep for emergency medical expenses"
        
        // Then
        XCTAssertEqual(cash.tags.count, 3)
        XCTAssertNotNil(cash.notes)
        XCTAssertTrue(cash.tags.contains("emergency"))
    }
    
    // MARK: - Enum Display Names Tests
    
    func testCashHoldingTypeDisplayNames() {
        // Given / When / Then
        XCTAssertFalse(CashHoldingType.physical.displayName.isEmpty)
        XCTAssertFalse(CashHoldingType.wallet.displayName.isEmpty)
        XCTAssertFalse(CashHoldingType.emergency.displayName.isEmpty)
        XCTAssertFalse(CashHoldingType.foreign.displayName.isEmpty)
    }
    
    func testCashLocationDisplayNames() {
        // Given / When / Then
        XCTAssertFalse(CashLocation.wallet.displayName.isEmpty)
        XCTAssertFalse(CashLocation.safe.displayName.isEmpty)
        XCTAssertFalse(CashLocation.locker.displayName.isEmpty)
    }
    
    func testCashPurposeDisplayNames() {
        // Given / When / Then
        XCTAssertFalse(CashPurpose.general.displayName.isEmpty)
        XCTAssertFalse(CashPurpose.emergency.displayName.isEmpty)
        XCTAssertFalse(CashPurpose.travel.displayName.isEmpty)
        XCTAssertFalse(CashPurpose.business.displayName.isEmpty)
    }
    
    // MARK: - Denomination Struct Tests
    
    func testCashDenominationCalculations() {
        // Given
        let denomination = CashDenomination(value: 500, count: 10, currency: "INR")
        
        // When
        let total = denomination.total
        let display = denomination.displayTotal
        
        // Then
        XCTAssertEqual(total, 5000)
        XCTAssertFalse(display.isEmpty)
    }
    
    func testMultipleDenominationTypes() {
        // Given
        let cash = CashHolding(
            name: "Mixed Denominations",
            holdingType: .physical,
            amount: 0
        )
        
        // When - Add various Indian denominations
        cash.addDenomination(value: 2000, count: 5)  // ₹10,000
        cash.addDenomination(value: 500, count: 10)  // ₹5,000
        cash.addDenomination(value: 200, count: 20)  // ₹4,000
        cash.addDenomination(value: 100, count: 30)  // ₹3,000
        cash.addDenomination(value: 50, count: 40)   // ₹2,000
        cash.addDenomination(value: 20, count: 50)   // ₹1,000
        cash.addDenomination(value: 10, count: 100)  // ₹1,000
        
        // Then
        XCTAssertEqual(cash.denominations.count, 7)
        XCTAssertEqual(cash.denominationTotal, 26000)
        XCTAssertTrue(cash.hasDenominationDetails)
    }
    
    // MARK: - Performance Tests
    
    func testCashHoldingCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = CashHolding(
                    name: "Performance Test",
                    holdingType: .wallet,
                    amount: 5000
                )
            }
        }
    }
    
    func testDenominationAdditionPerformance() {
        // Given
        let cash = CashHolding(
            name: "Test Cash",
            holdingType: .physical,
            amount: 0
        )
        
        // When / Then
        measure {
            for i in 0..<100 {
                cash.addDenomination(value: Decimal(i * 10), count: 5)
            }
        }
    }
}
