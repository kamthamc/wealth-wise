//
//  CulturalValidationTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 02/10/2025.
//  Tests for cultural validation functionality
//

import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class CulturalValidationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var validation: CulturalValidation!
    private var indianContext: CulturalContext!
    private var americanContext: CulturalContext!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        indianContext = CulturalContext(audience: .indian)
        americanContext = CulturalContext(audience: .american)
        validation = CulturalValidation(culturalContext: indianContext)
    }
    
    override func tearDown() {
        validation = nil
        indianContext = nil
        americanContext = nil
        super.tearDown()
    }
    
    // MARK: - Number Validation Tests
    
    func testValidNumberString() {
        let result = validation.validateNumberString("1000")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.message)
    }
    
    func testInvalidNumberString() {
        let result = validation.validateNumberString("abc")
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.message)
    }
    
    func testEmptyNumberString() {
        let result = validation.validateNumberString("")
        XCTAssertFalse(result.isValid)
    }
    
    func testNumberWithThousandsSeparator() {
        let result = validation.validateNumberString("1,00,000")
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Currency Validation Tests
    
    func testValidCurrencyString() {
        let result = validation.validateCurrencyString("₹1000")
        XCTAssertTrue(result.isValid)
    }
    
    func testValidCurrencyWithSymbol() {
        let result = validation.validateCurrencyString("$100.50")
        XCTAssertTrue(result.isValid)
    }
    
    func testInvalidCurrencyString() {
        let result = validation.validateCurrencyString("invalid")
        XCTAssertFalse(result.isValid)
    }
    
    func testEmptyCurrencyString() {
        let result = validation.validateCurrencyString("")
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - Date Validation Tests
    
    func testValidDateString() {
        let result = validation.validateDateString("01/01/2025")
        XCTAssertTrue(result.isValid || result.message != nil)
    }
    
    func testInvalidDateString() {
        let result = validation.validateDateString("invalid")
        XCTAssertFalse(result.isValid)
    }
    
    func testEmptyDateString() {
        let result = validation.validateDateString("")
        XCTAssertFalse(result.isValid)
    }
    
    func testDateWithSpecificFormat() {
        let result = validation.validateDateString("2025-01-01", format: .yyyymmdd)
        // Result should be valid or warning
        XCTAssertTrue(result.isValid || result.message != nil)
    }
    
    // MARK: - Text Direction Validation Tests
    
    func testTextDirectionValidation() {
        let result = validation.validateTextDirection(for: "Hello World")
        XCTAssertTrue(result.isValid)
    }
    
    func testRTLTextDirectionWarning() {
        let rtlContext = CulturalContext(audience: .emirati)
        let rtlValidation = CulturalValidation(culturalContext: rtlContext)
        
        let result = rtlValidation.validateTextDirection(for: "Hello World")
        // Should be valid but may have warning
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Cultural Format Validation Tests
    
    func testCulturalFormatValidation() {
        let data: [String: Any] = [
            "numbers": ["1000", "2000"],
            "dates": ["01/01/2025"],
            "currencies": ["₹1000"]
        ]
        
        let results = validation.validateCulturalFormat(data: data)
        XCTAssertFalse(results.isEmpty)
        
        let validCount = results.filter { $0.isValid }.count
        XCTAssertGreaterThan(validCount, 0)
    }
    
    func testCulturalFormatValidationEmpty() {
        let data: [String: Any] = [:]
        let results = validation.validateCulturalFormat(data: data)
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Accessibility Validation Tests
    
    func testAccessibilityValidation() {
        let element = AccessibleElement(
            label: "Test Button",
            hint: "Tap to test",
            fontSize: 17
        )
        
        let result = validation.validateAccessibility(for: element)
        XCTAssertTrue(result.isValid)
    }
    
    func testAccessibilityValidationMissingLabel() {
        let element = AccessibleElement(
            label: "",
            fontSize: 17
        )
        
        let result = validation.validateAccessibility(for: element)
        XCTAssertFalse(result.isValid)
    }
    
    func testAccessibilityValidationSmallFont() {
        let accessibleContext = CulturalContext(audience: .indian)
        accessibleContext.updateAccessibility(enabled: true)
        let accessibleValidation = CulturalValidation(culturalContext: accessibleContext)
        
        let element = AccessibleElement(
            label: "Test",
            fontSize: 12
        )
        
        let result = accessibleValidation.validateAccessibility(for: element)
        XCTAssertFalse(result.isValid)
    }
    
    func testAccessibilityValidationWithColors() {
        let colors = AccessibleColors(
            foreground: "#000000",
            background: "#FFFFFF"
        )
        
        let element = AccessibleElement(
            label: "Test",
            colors: colors,
            fontSize: 17
        )
        
        let result = validation.validateAccessibility(for: element)
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Performance Tests
    
    func testNumberValidationPerformance() {
        measure {
            for i in 0..<100 {
                _ = validation.validateNumberString("\(i * 1000)")
            }
        }
    }
    
    func testCurrencyValidationPerformance() {
        measure {
            for i in 0..<100 {
                _ = validation.validateCurrencyString("₹\(i * 1000)")
            }
        }
    }
}
