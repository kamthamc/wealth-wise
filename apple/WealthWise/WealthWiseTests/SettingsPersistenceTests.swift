//
//  SettingsPersistenceTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Settings Persistence Tests
//

import XCTest
@testable import WealthWise

@MainActor
final class SettingsPersistenceTests: XCTestCase {
    
    var settingsPersistence: SettingsPersistence!
    var testUserDefaults: UserDefaults!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test UserDefaults
        testUserDefaults = UserDefaults(suiteName: "test.wealthwise.settings")!
        testUserDefaults.removePersistentDomain(forName: "test.wealthwise.settings")
        
        // Create test persistence with test UserDefaults
        settingsPersistence = SettingsPersistence(
            userDefaults: testUserDefaults,
            keychainService: "test.wealthwise.settings"
        )
    }
    
    override func tearDown() async throws {
        // Clean up test data
        try? settingsPersistence.deleteAllSettings()
        testUserDefaults.removePersistentDomain(forName: "test.wealthwise.settings")
        
        settingsPersistence = nil
        testUserDefaults = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Basic Persistence Tests
    
    func testSaveAndLoadUserSettings() async throws {
        // Create test settings
        let originalSettings = UserSettings()
        originalSettings.primaryCurrency = .USD
        originalSettings.primaryAudience = .american
        originalSettings.hapticFeedbackEnabled = false
        originalSettings.autoLockTimeout = 1800
        
        // Save settings
        try await settingsPersistence.saveUserSettings(originalSettings)
        
        // Load settings
        let loadedSettings = try await settingsPersistence.loadUserSettings()
        
        // Verify
        XCTAssertEqual(loadedSettings.primaryCurrency, originalSettings.primaryCurrency)
        XCTAssertEqual(loadedSettings.primaryAudience, originalSettings.primaryAudience)
        XCTAssertEqual(loadedSettings.hapticFeedbackEnabled, originalSettings.hapticFeedbackEnabled)
        XCTAssertEqual(loadedSettings.autoLockTimeout, originalSettings.autoLockTimeout)
    }
    
    func testLoadNonExistentSettings() async throws {
        // Should return default settings when none exist
        let settings = try await settingsPersistence.loadUserSettings()
        
        XCTAssertEqual(settings.primaryCurrency, .INR) // Default for Indian audience
        XCTAssertEqual(settings.primaryAudience, .indian)
        XCTAssertTrue(settings.hapticFeedbackEnabled)
    }
    
    // MARK: - Component Storage Tests
    
    func testComponentStorage() throws {
        let localizationConfig = LocalizationConfig()
        localizationConfig.appLanguage = .hindi
        localizationConfig.numberSystem = .indian
        
        // Save component
        try settingsPersistence.saveComponent(localizationConfig, key: "test_localization", secure: false)
        
        // Load component
        let loadedConfig = try settingsPersistence.loadComponent(LocalizationConfig.self, key: "test_localization", secure: false)
        
        XCTAssertNotNil(loadedConfig)
        XCTAssertEqual(loadedConfig?.appLanguage, .hindi)
        XCTAssertEqual(loadedConfig?.numberSystem, .indian)
    }
    
    func testSecureComponentStorage() throws {
        let privacySettings = PrivacySettings()
        privacySettings.analyticsEnabled = true
        privacySettings.crashReportingEnabled = false
        
        // Save securely
        try settingsPersistence.saveComponent(privacySettings, key: "test_privacy", secure: true)
        
        // Load securely
        let loadedSettings = try settingsPersistence.loadComponent(PrivacySettings.self, key: "test_privacy", secure: true)
        
        XCTAssertNotNil(loadedSettings)
        XCTAssertEqual(loadedSettings?.analyticsEnabled, true)
        XCTAssertEqual(loadedSettings?.crashReportingEnabled, false)
    }
    
    // MARK: - Export/Import Tests
    
    func testExportImportSettings() async throws {
        // Create and save test settings
        let originalSettings = UserSettings()
        originalSettings.primaryCurrency = .EUR
        originalSettings.primaryAudience = .german
        originalSettings.theme.selectedTheme = .minimal
        
        try await settingsPersistence.saveUserSettings(originalSettings)
        
        // Export settings
        let exportedData = try await settingsPersistence.exportSettings()
        XCTAssertFalse(exportedData.isEmpty)
        
        // Clear settings
        try settingsPersistence.deleteAllSettings()
        
        // Import settings
        try await settingsPersistence.importSettings(from: exportedData)
        
        // Verify imported settings
        let importedSettings = try await settingsPersistence.loadUserSettings()
        XCTAssertEqual(importedSettings.primaryCurrency, .EUR)
        XCTAssertEqual(importedSettings.primaryAudience, .german)
        XCTAssertEqual(importedSettings.theme.selectedTheme, .minimal)
    }
    
    // MARK: - Validation Tests
    
    func testSettingsValidation() {
        let settings = UserSettings()
        settings.autoLockTimeout = 30 // Invalid (too short)
        
        let issues = settingsPersistence.validateSettings(settings)
        XCTAssertTrue(issues.contains { $0.contains("Auto-lock timeout") })
    }
    
    func testBiometricConsentValidation() {
        let settings = UserSettings()
        settings.biometricAuthEnabled = true
        settings.privacy.biometricDataUsageConsent = false
        
        let issues = settingsPersistence.validateSettings(settings)
        XCTAssertTrue(issues.contains { $0.contains("Biometric auth enabled without consent") })
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidJSONHandling() throws {
        // Store invalid JSON data
        let invalidData = "invalid json".data(using: .utf8)!
        testUserDefaults.set(invalidData, forKey: "user_settings")
        
        // Should handle gracefully and return default settings
        let expectation = XCTestExpectation(description: "Load settings with invalid data")
        
        Task {
            do {
                let settings = try await settingsPersistence.loadUserSettings()
                // Should get default settings since invalid data should be handled
                XCTAssertEqual(settings.primaryCurrency, .INR)
                expectation.fulfill()
            } catch {
                // Error is expected for invalid JSON
                XCTAssertTrue(error is SettingsPersistenceError)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Utility Tests
    
    func testStorageSize() {
        let settings = UserSettings()
        
        // Save some data
        let expectation = XCTestExpectation(description: "Save settings")
        Task {
            try await settingsPersistence.saveUserSettings(settings)
            
            let size = settingsPersistence.getStorageSize()
            XCTAssertGreaterThan(size, 0)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSettingsExist() {
        XCTAssertFalse(settingsPersistence.settingsExist())
        
        let expectation = XCTestExpectation(description: "Save and check settings")
        Task {
            let settings = UserSettings()
            try await settingsPersistence.saveUserSettings(settings)
            
            XCTAssertTrue(settingsPersistence.settingsExist())
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLastModificationDate() {
        XCTAssertNil(settingsPersistence.getLastModificationDate())
        
        let expectation = XCTestExpectation(description: "Save and check modification date")
        Task {
            let settings = UserSettings()
            let beforeSave = Date()
            try await settingsPersistence.saveUserSettings(settings)
            
            let modDate = settingsPersistence.getLastModificationDate()
            XCTAssertNotNil(modDate)
            XCTAssertGreaterThanOrEqual(modDate!, beforeSave)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentAccess() async throws {
        let settings1 = UserSettings()
        settings1.primaryCurrency = .USD
        
        let settings2 = UserSettings()
        settings2.primaryCurrency = .EUR
        
        // Perform concurrent save operations
        async let save1 = settingsPersistence.saveUserSettings(settings1)
        async let save2 = settingsPersistence.saveUserSettings(settings2)
        
        try await save1
        try await save2
        
        // Load final settings
        let finalSettings = try await settingsPersistence.loadUserSettings()
        
        // Should have one of the currencies (last one wins)
        XCTAssertTrue([SupportedCurrency.USD, .EUR].contains(finalSettings.primaryCurrency))
    }
    
    // MARK: - Migration Tests
    
    func testMigrationTrigger() async throws {
        let settings = UserSettings()
        settings.settingsVersion = 0 // Old version
        
        // Save with old version
        try await settingsPersistence.saveUserSettings(settings)
        
        // Load should trigger migration
        let loadedSettings = try await settingsPersistence.loadUserSettings()
        
        XCTAssertEqual(loadedSettings.settingsVersion, UserSettings.currentSettingsVersion)
    }
    
    // MARK: - Performance Tests
    
    func testSavePerformance() {
        let settings = UserSettings()
        settings.primaryCurrency = .USD
        
        measure {
            let expectation = XCTestExpectation(description: "Save settings performance")
            
            Task {
                do {
                    try await settingsPersistence.saveUserSettings(settings)
                    expectation.fulfill()
                } catch {
                    XCTFail("Save should not fail: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testLoadPerformance() {
        // First save some settings
        let saveExpectation = XCTestExpectation(description: "Save initial settings")
        Task {
            let settings = UserSettings()
            try await settingsPersistence.saveUserSettings(settings)
            saveExpectation.fulfill()
        }
        wait(for: [saveExpectation], timeout: 5.0)
        
        // Measure load performance
        measure {
            let expectation = XCTestExpectation(description: "Load settings performance")
            
            Task {
                do {
                    _ = try await settingsPersistence.loadUserSettings()
                    expectation.fulfill()
                } catch {
                    XCTFail("Load should not fail: \(error)")
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityAfterMultipleSaves() async throws {
        let originalSettings = UserSettings()
        originalSettings.primaryCurrency = .USD
        originalSettings.autoLockTimeout = 1800
        
        // Save multiple times
        for _ in 0..<5 {
            try await settingsPersistence.saveUserSettings(originalSettings)
        }
        
        // Load and verify data integrity
        let loadedSettings = try await settingsPersistence.loadUserSettings()
        
        XCTAssertEqual(loadedSettings.primaryCurrency, originalSettings.primaryCurrency)
        XCTAssertEqual(loadedSettings.autoLockTimeout, originalSettings.autoLockTimeout)
    }
    
    func testComplexObjectHandling() async throws {
        let settings = UserSettings()
        
        // Configure complex nested objects
        settings.localization.appLanguage = .hindi
        settings.localization.numberSystem = .indian
        settings.theme.selectedTheme = .vibrant
        settings.theme.chartColorPalette = .warm
        settings.accessibility.voiceOverEnabled = true
        settings.accessibility.textSizeMultiplier = 1.5
        settings.privacy.analyticsEnabled = false
        settings.privacy.gdprRegion = true
        
        // Save and load
        try await settingsPersistence.saveUserSettings(settings)
        let loadedSettings = try await settingsPersistence.loadUserSettings()
        
        // Verify complex nested objects
        XCTAssertEqual(loadedSettings.localization.appLanguage, .hindi)
        XCTAssertEqual(loadedSettings.localization.numberSystem, .indian)
        XCTAssertEqual(loadedSettings.theme.selectedTheme, .vibrant)
        XCTAssertEqual(loadedSettings.theme.chartColorPalette, .warm)
        XCTAssertEqual(loadedSettings.accessibility.voiceOverEnabled, true)
        XCTAssertEqual(loadedSettings.accessibility.textSizeMultiplier, 1.5)
        XCTAssertEqual(loadedSettings.privacy.analyticsEnabled, false)
        XCTAssertEqual(loadedSettings.privacy.gdprRegion, true)
    }
}