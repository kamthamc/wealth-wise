//
//  UserSettingsTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Unit Tests
//

import XCTest
@testable import WealthWise

@MainActor
final class UserSettingsTests: XCTestCase {
    
    var userSettings: UserSettings!
    
    override func setUp() {
        super.setUp()
        userSettings = UserSettings()
    }
    
    override func tearDown() {
        userSettings = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        XCTAssertEqual(userSettings.primaryCurrency, .INR)
        XCTAssertEqual(userSettings.primaryAudience, .indian)
        XCTAssertEqual(userSettings.settingsVersion, 1)
        XCTAssertTrue(userSettings.hapticFeedbackEnabled)
        XCTAssertTrue(userSettings.biometricAuthEnabled)
        XCTAssertEqual(userSettings.autoLockTimeout, 15 * 60)
    }
    
    func testAudienceSpecificInitialization() {
        let americanSettings = UserSettings(forAudience: .american)
        XCTAssertEqual(americanSettings.primaryAudience, .american)
        XCTAssertEqual(americanSettings.primaryCurrency, .USD)
        
        let britishSettings = UserSettings(forAudience: .british)
        XCTAssertEqual(britishSettings.primaryAudience, .british)
        XCTAssertEqual(britishSettings.primaryCurrency, .GBP)
        
        let singaporeanSettings = UserSettings(forAudience: .singaporean)
        XCTAssertEqual(singaporeanSettings.primaryAudience, .singaporean)
        XCTAssertEqual(singaporeanSettings.primaryCurrency, .SGD)
    }
    
    // MARK: - Currency Validation Tests
    
    func testCurrencyValidationForAudience() {
        // Test valid currencies for Indian audience
        XCTAssertTrue(SupportedCurrency.INR.isValidForAudience(.indian))
        XCTAssertTrue(SupportedCurrency.USD.isValidForAudience(.indian))
        XCTAssertTrue(SupportedCurrency.GBP.isValidForAudience(.indian))
        
        // Test valid currencies for American audience
        XCTAssertTrue(SupportedCurrency.USD.isValidForAudience(.american))
        XCTAssertTrue(SupportedCurrency.CAD.isValidForAudience(.american))
        
        // Test edge cases
        XCTAssertTrue(SupportedCurrency.JPY.isValidForAudience(.german)) // Should allow flexibility
    }
    
    // MARK: - Settings Validation Tests
    
    func testValidSettings() {
        let issues = userSettings.validateSettings()
        XCTAssertTrue(issues.isEmpty, "Default settings should be valid")
    }
    
    func testInvalidAutoLockTimeout() {
        userSettings.autoLockTimeout = 30 // Too short
        var issues = userSettings.validateSettings()
        XCTAssertTrue(issues.contains { $0.contains("Auto-lock timeout") })
        
        userSettings.autoLockTimeout = 4000 // Too long
        issues = userSettings.validateSettings()
        XCTAssertTrue(issues.contains { $0.contains("Auto-lock timeout") })
    }
    
    func testCurrencyAudienceMismatch() {
        userSettings.primaryAudience = .american
        userSettings.primaryCurrency = .INR // Indian Rupee for American audience
        
        let issues = userSettings.validateSettings()
        XCTAssertTrue(issues.contains { $0.contains("currency may not be optimal") })
    }
    
    // MARK: - Settings Update Tests
    
    func testSettingsUpdate() {
        let originalModified = userSettings.lastModified
        
        // Wait a small amount to ensure different timestamp
        let expectation = XCTestExpectation(description: "Wait for timestamp difference")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        userSettings.updateSettings(\.primaryCurrency, value: .USD)
        
        XCTAssertEqual(userSettings.primaryCurrency, .USD)
        XCTAssertGreaterThan(userSettings.lastModified, originalModified)
    }
    
    func testResetToDefaults() {
        // Modify settings
        userSettings.primaryCurrency = .USD
        userSettings.hapticFeedbackEnabled = false
        userSettings.autoLockTimeout = 1800
        
        // Reset to defaults
        userSettings.resetToDefaults()
        
        // Verify reset
        XCTAssertEqual(userSettings.primaryCurrency, .INR) // Back to default for Indian audience
        XCTAssertTrue(userSettings.hapticFeedbackEnabled)
        XCTAssertEqual(userSettings.autoLockTimeout, 15 * 60)
    }
    
    // MARK: - Migration Tests
    
    func testMigrationRequired() {
        userSettings.settingsVersion = 0
        XCTAssertTrue(userSettings.requiresMigration)
        
        userSettings.settingsVersion = UserSettings.currentSettingsVersion
        XCTAssertFalse(userSettings.requiresMigration)
    }
    
    // MARK: - Codable Tests
    
    func testCodableRoundTrip() throws {
        // Modify settings to non-default values
        userSettings.primaryCurrency = .USD
        userSettings.primaryAudience = .american
        userSettings.hapticFeedbackEnabled = false
        userSettings.autoLockTimeout = 1800
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(userSettings)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedSettings = try decoder.decode(UserSettings.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedSettings.primaryCurrency, userSettings.primaryCurrency)
        XCTAssertEqual(decodedSettings.primaryAudience, userSettings.primaryAudience)
        XCTAssertEqual(decodedSettings.hapticFeedbackEnabled, userSettings.hapticFeedbackEnabled)
        XCTAssertEqual(decodedSettings.autoLockTimeout, userSettings.autoLockTimeout)
        XCTAssertEqual(decodedSettings.settingsVersion, userSettings.settingsVersion)
    }
    
    func testCodableWithDates() throws {
        let testDate = Date()
        userSettings.lastSyncTimestamp = testDate
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(userSettings)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedSettings = try decoder.decode(UserSettings.self, from: data)
        
        // Compare dates with small tolerance for precision differences
        XCTAssertEqual(decodedSettings.lastSyncTimestamp?.timeIntervalSince1970,
                       testDate.timeIntervalSince1970,
                       accuracy: 1.0)
    }
    
    // MARK: - Sub-Settings Integration Tests
    
    func testSubSettingsIntegration() {
        // Test that sub-settings are properly initialized
        XCTAssertNotNil(userSettings.localization)
        XCTAssertNotNil(userSettings.accessibility)
        XCTAssertNotNil(userSettings.theme)
        XCTAssertNotNil(userSettings.privacy)
        
        // Test that sub-settings validation is included
        userSettings.localization.region = "invalid" // Invalid region format
        let issues = userSettings.validateSettings()
        XCTAssertTrue(issues.contains { $0.contains("Invalid region format") })
    }
    
    // MARK: - Performance Tests
    
    func testSettingsValidationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = userSettings.validateSettings()
            }
        }
    }
    
    func testCodingPerformance() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        measure {
            do {
                for _ in 0..<100 {
                    let data = try encoder.encode(userSettings)
                    _ = try decoder.decode(UserSettings.self, from: data)
                }
            } catch {
                XCTFail("Encoding/Decoding should not fail: \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testExtremeDateValues() throws {
        // Test with very old date
        userSettings.lastModified = Date(timeIntervalSince1970: 0)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(userSettings)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedSettings = try decoder.decode(UserSettings.self, from: data)
        
        XCTAssertEqual(decodedSettings.lastModified.timeIntervalSince1970, 0, accuracy: 1.0)
    }
    
    func testMaximumSettingsValues() {
        userSettings.autoLockTimeout = 3600 // Maximum allowed
        let issues = userSettings.validateSettings()
        XCTAssertFalse(issues.contains { $0.contains("Auto-lock timeout") })
    }
    
    func testMinimumSettingsValues() {
        userSettings.autoLockTimeout = 60 // Minimum allowed
        let issues = userSettings.validateSettings()
        XCTAssertFalse(issues.contains { $0.contains("Auto-lock timeout") })
    }
}