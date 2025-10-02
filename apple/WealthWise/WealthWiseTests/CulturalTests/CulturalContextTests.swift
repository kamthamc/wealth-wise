//
//  CulturalContextTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 02/10/2025.
//  Comprehensive tests for CulturalContext functionality
//

import XCTest
@testable import WealthWise

final class CulturalContextTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var context: CulturalContext!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        context = CulturalContext()
    }
    
    override func tearDown() {
        context = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        XCTAssertNotNil(context)
        XCTAssertNotNil(context.audience)
        XCTAssertNotNil(context.localizationConfig)
        XCTAssertNotNil(context.textDirection)
    }
    
    func testAudienceSpecificInitialization() {
        let indianContext = CulturalContext(audience: .indian)
        XCTAssertEqual(indianContext.audience, .indian)
        XCTAssertEqual(indianContext.localizationConfig.numberSystem, .indian)
        XCTAssertFalse(indianContext.isRTL)
        
        let emaratiContext = CulturalContext(audience: .emirati)
        XCTAssertEqual(emaratiContext.audience, .emirati)
        XCTAssertTrue(emaratiContext.isRTL)
    }
    
    // MARK: - Property Tests
    
    func testCurrentLocale() {
        let locale = context.currentLocale
        XCTAssertNotNil(locale)
    }
    
    func testCurrentCalendar() {
        let calendar = context.currentCalendar
        XCTAssertNotNil(calendar)
    }
    
    func testNumberSystem() {
        context.updateAudience(.indian)
        XCTAssertEqual(context.numberSystem, .indian)
        
        context.updateAudience(.american)
        XCTAssertEqual(context.numberSystem, .western)
    }
    
    func testPrimaryCurrencyCode() {
        context.updateAudience(.indian)
        XCTAssertEqual(context.primaryCurrencyCode, "INR")
        
        context.updateAudience(.american)
        XCTAssertEqual(context.primaryCurrencyCode, "USD")
        
        context.updateAudience(.british)
        XCTAssertEqual(context.primaryCurrencyCode, "GBP")
    }
    
    // MARK: - Audience Update Tests
    
    func testUpdateAudience() {
        context.updateAudience(.indian)
        XCTAssertEqual(context.audience, .indian)
        XCTAssertEqual(context.localizationConfig.numberSystem, .indian)
    }
    
    func testUpdateAudienceWithRTL() {
        context.updateAudience(.emirati)
        XCTAssertEqual(context.audience, .emirati)
        XCTAssertTrue(context.isRTL)
        XCTAssertEqual(context.textDirection, .rightToLeft)
    }
    
    // MARK: - Text Direction Tests
    
    func testUpdateTextDirection() {
        context.updateTextDirection(.rightToLeft)
        XCTAssertEqual(context.textDirection, .rightToLeft)
        XCTAssertTrue(context.isRTL)
        XCTAssertTrue(context.localizationConfig.isRTLEnabled)
    }
    
    func testLayoutDirection() {
        context.updateTextDirection(.leftToRight)
        XCTAssertEqual(context.layoutDirection, .leftToRight)
        
        context.updateTextDirection(.rightToLeft)
        XCTAssertEqual(context.layoutDirection, .rightToLeft)
    }
    
    // MARK: - Accessibility Tests
    
    func testUpdateAccessibility() {
        context.updateAccessibility(enabled: true, highContrast: true, reducedMotion: true)
        
        XCTAssertTrue(context.isAccessibilityEnabled)
        XCTAssertTrue(context.isHighContrastEnabled)
        XCTAssertTrue(context.isReducedMotionEnabled)
    }
    
    func testAccessibilityDefaults() {
        XCTAssertFalse(context.isAccessibilityEnabled)
        XCTAssertFalse(context.isHighContrastEnabled)
        XCTAssertFalse(context.isReducedMotionEnabled)
    }
    
    // MARK: - Validation Tests
    
    func testValidation() {
        let issues = context.validate()
        XCTAssertTrue(issues.isEmpty, "Default context should be valid")
    }
    
    func testValidationWithInconsistentRTL() {
        context.updateAudience(.american)
        context.updateTextDirection(.rightToLeft)
        
        let issues = context.validate()
        XCTAssertFalse(issues.isEmpty, "Should detect RTL inconsistency")
    }
    
    func testValidationWithInconsistentLanguage() {
        context.updateAudience(.indian)
        context.localizationConfig.appLanguage = .french
        
        let issues = context.validate()
        XCTAssertFalse(issues.isEmpty, "Should detect language inconsistency")
    }
    
    // MARK: - Copy Tests
    
    func testCopy() {
        context.updateAudience(.indian)
        context.updateAccessibility(enabled: true)
        
        let copy = context.copy()
        XCTAssertEqual(copy.audience, context.audience)
        XCTAssertEqual(copy.isAccessibilityEnabled, context.isAccessibilityEnabled)
    }
    
    // MARK: - Codable Tests
    
    func testEncodeDecode() throws {
        context.updateAudience(.indian)
        context.updateTextDirection(.leftToRight)
        context.updateAccessibility(enabled: true)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        
        let decoder = JSONDecoder()
        let decodedContext = try decoder.decode(CulturalContext.self, from: data)
        
        XCTAssertEqual(decodedContext.audience, context.audience)
        XCTAssertEqual(decodedContext.textDirection, context.textDirection)
        XCTAssertEqual(decodedContext.isAccessibilityEnabled, context.isAccessibilityEnabled)
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable() {
        let context1 = CulturalContext(audience: .indian)
        let context2 = CulturalContext(audience: .indian)
        let context3 = CulturalContext(audience: .american)
        
        XCTAssertEqual(context1, context2)
        XCTAssertNotEqual(context1, context3)
    }
    
    // MARK: - Hashable Tests
    
    func testHashable() {
        let context1 = CulturalContext(audience: .indian)
        let context2 = CulturalContext(audience: .indian)
        
        let set: Set<CulturalContext> = [context1, context2]
        XCTAssertEqual(set.count, 1, "Equal contexts should hash to same value")
    }
    
    // MARK: - Performance Tests
    
    func testContextCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = CulturalContext()
            }
        }
    }
    
    func testAudienceUpdatePerformance() {
        measure {
            for audience in PrimaryAudience.allCases {
                context.updateAudience(audience)
            }
        }
    }
}
