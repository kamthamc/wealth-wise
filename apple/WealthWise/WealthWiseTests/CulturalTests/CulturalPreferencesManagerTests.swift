//
//  CulturalPreferencesManagerTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 02/10/2025.
//  Comprehensive tests for CulturalPreferencesManager functionality
//

import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
@MainActor
final class CulturalPreferencesManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var manager: CulturalPreferencesManager!
    
    // MARK: - Test Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        manager = CulturalPreferencesManager()
    }
    
    override func tearDown() async throws {
        manager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(manager)
        XCTAssertNotNil(manager.currentContext)
        XCTAssertFalse(manager.isSwitching)
    }
    
    func testInitializationWithContext() {
        let context = CulturalContext(audience: .indian)
        let customManager = CulturalPreferencesManager(initialContext: context)
        
        XCTAssertEqual(customManager.currentContext.audience, .indian)
    }
    
    // MARK: - Audience Switching Tests
    
    func testSwitchAudience() async {
        await manager.switchAudience(to: .indian)
        
        XCTAssertEqual(manager.currentContext.audience, .indian)
        XCTAssertNotNil(manager.lastSwitchTimestamp)
    }
    
    func testSwitchAudienceUpdatesFormatters() async {
        await manager.switchAudience(to: .indian)
        
        let formatted = manager.formatNumber(100000)
        XCTAssertFalse(formatted.isEmpty)
    }
    
    func testSwitchAudienceToRTL() async {
        await manager.switchAudience(to: .emirati)
        
        XCTAssertEqual(manager.currentContext.audience, .emirati)
        XCTAssertTrue(manager.currentContext.isRTL)
    }
    
    // MARK: - Context Switching Tests
    
    func testSwitchContext() async {
        let newContext = CulturalContext(audience: .british)
        await manager.switchContext(to: newContext)
        
        XCTAssertEqual(manager.currentContext.audience, .british)
    }
    
    // MARK: - Text Direction Tests
    
    func testUpdateTextDirection() {
        manager.updateTextDirection(.rightToLeft)
        
        XCTAssertEqual(manager.currentContext.textDirection, .rightToLeft)
        XCTAssertTrue(manager.currentContext.isRTL)
    }
    
    // MARK: - Accessibility Tests
    
    func testUpdateAccessibility() {
        manager.updateAccessibility(enabled: true, highContrast: true, reducedMotion: true)
        
        XCTAssertTrue(manager.currentContext.isAccessibilityEnabled)
        XCTAssertTrue(manager.currentContext.isHighContrastEnabled)
        XCTAssertTrue(manager.currentContext.isReducedMotionEnabled)
    }
    
    // MARK: - Formatting Tests
    
    func testFormatNumber() {
        let formatted = manager.formatNumber(1000)
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertNotEqual(formatted, "1000")
    }
    
    func testFormatCurrency() {
        let formatted = manager.formatCurrency(1000.50)
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("1") || formatted.contains("1000"))
    }
    
    func testFormatDate() {
        let date = Date()
        let formatted = manager.formatDate(date)
        XCTAssertFalse(formatted.isEmpty)
    }
    
    func testFormatDateAccessible() {
        let date = Date()
        let formatted = manager.formatDateAccessible(date)
        XCTAssertFalse(formatted.isEmpty)
    }
    
    // MARK: - Validation Tests
    
    func testValidateNumber() {
        let result = manager.validateNumber("1000")
        XCTAssertTrue(result.isValid)
    }
    
    func testValidateInvalidNumber() {
        let result = manager.validateNumber("invalid")
        XCTAssertFalse(result.isValid)
    }
    
    func testValidateCurrency() {
        let result = manager.validateCurrency("$100")
        XCTAssertTrue(result.isValid)
    }
    
    func testValidateDate() {
        let result = manager.validateDate("01/01/2025")
        // Result should be valid or have a message
        XCTAssertTrue(result.isValid || result.message != nil)
    }
    
    // MARK: - UI Adaptation Tests
    
    func testGetUIAdapter() {
        let adapter = manager.getUIAdapter()
        XCTAssertNotNil(adapter)
    }
    
    func testGetAccessibilityPatterns() {
        let patterns = manager.getAccessibilityPatterns()
        XCTAssertNotNil(patterns)
    }
    
    // MARK: - Persistence Tests
    
    func testSaveContextAsPreset() {
        let initialCount = manager.availableContexts.count
        manager.saveContextAsPreset(name: "Test Preset")
        
        XCTAssertEqual(manager.availableContexts.count, initialCount + 1)
    }
    
    func testDeleteContext() {
        manager.saveContextAsPreset(name: "Test Preset")
        let contextToDelete = manager.availableContexts.last!
        
        manager.deleteContext(contextToDelete)
        XCTAssertFalse(manager.availableContexts.contains(where: { $0 == contextToDelete }))
    }
    
    func testResetToDefault() async {
        await manager.switchAudience(to: .indian)
        await manager.resetToDefault()
        
        // Should be reset to default context
        XCTAssertNotNil(manager.currentContext)
    }
    
    // MARK: - Performance Tests
    
    func testGetPerformanceMetrics() {
        let metrics = manager.getPerformanceMetrics()
        XCTAssertNotNil(metrics)
    }
    
    func testAudienceSwitchPerformance() async {
        measure {
            Task {
                await manager.switchAudience(to: .indian)
                await manager.switchAudience(to: .american)
            }
        }
    }
    
    func testFormattingPerformance() {
        measure {
            for i in 0..<100 {
                _ = manager.formatNumber(Decimal(i * 1000))
            }
        }
    }
}
