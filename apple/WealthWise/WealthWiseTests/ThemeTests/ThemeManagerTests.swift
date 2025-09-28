//
//  ThemeManagerTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Tests for ThemeManager functionality
//

import XCTest
import SwiftUI
@testable import WealthWise

final class ThemeManagerTests: XCTestCase {
    
    var themeManager: ThemeManager!
    
    override func setUp() async throws {
        try await super.setUp()
        // Create a new instance for testing to avoid singleton interference
        themeManager = ThemeManager()
    }
    
    override func tearDown() async throws {
        themeManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() throws {
        XCTAssertNotNil(themeManager.themePreferences, "Theme preferences should be initialized")
        XCTAssertEqual(themeManager.systemColorScheme, .light, "Default system color scheme should be light") 
    }
    
    func testDefaultThemePreferences() throws {
        let preferences = themeManager.themePreferences
        
        XCTAssertEqual(preferences.selectedTheme, .system, "Default theme should be system")
        XCTAssertEqual(preferences.accentColor, .blue, "Default accent color should be blue")
        XCTAssertTrue(preferences.animationsEnabled, "Animations should be enabled by default")
        XCTAssertFalse(preferences.highContrastEnabled, "High contrast should be disabled by default")
        XCTAssertFalse(preferences.reduceMotion, "Reduce motion should be disabled by default")
    }
    
    // MARK: - Theme Switching Tests
    
    func testThemeTypeUpdate() throws {
        // Test switching to dark theme
        themeManager.updateThemeType(.dark)
        
        XCTAssertEqual(themeManager.themePreferences.selectedTheme, .dark, "Theme should be updated to dark")
        XCTAssertEqual(themeManager.effectiveColorScheme, .dark, "Effective color scheme should be dark")
        
        // Test switching to light theme
        themeManager.updateThemeType(.light)
        
        XCTAssertEqual(themeManager.themePreferences.selectedTheme, .light, "Theme should be updated to light")
        XCTAssertEqual(themeManager.effectiveColorScheme, .light, "Effective color scheme should be light")
        
        // Test switching to system theme
        themeManager.updateThemeType(.system)
        
        XCTAssertEqual(themeManager.themePreferences.selectedTheme, .system, "Theme should be updated to system")
        XCTAssertEqual(themeManager.effectiveColorScheme, themeManager.systemColorScheme, "Effective color scheme should match system")
    }
    
    func testAccentColorUpdate() throws {
        themeManager.updateAccentColor(.green)
        
        XCTAssertEqual(themeManager.themePreferences.accentColor, .green, "Accent color should be updated to green")
        XCTAssertEqual(themeManager.semanticColors.accentColor, .green, "Semantic colors should reflect new accent color")
    }
    
    func testHighContrastToggle() throws {
        let initialState = themeManager.themePreferences.highContrastEnabled
        
        themeManager.toggleHighContrast()
        
        XCTAssertEqual(themeManager.themePreferences.highContrastEnabled, !initialState, "High contrast should be toggled")
        XCTAssertEqual(themeManager.isHighContrastEnabled, !initialState, "High contrast state should be reflected")
    }
    
    // MARK: - System Color Scheme Tests
    
    func testSystemColorSchemeUpdate() throws {
        themeManager.updateSystemColorScheme(.dark)
        
        XCTAssertEqual(themeManager.systemColorScheme, .dark, "System color scheme should be updated")
        
        // When theme is set to system, effective color scheme should match
        themeManager.updateThemeType(.system)
        XCTAssertEqual(themeManager.effectiveColorScheme, .dark, "Effective color scheme should match system when theme is system")
        
        // When theme is set to light, effective color scheme should remain light
        themeManager.updateThemeType(.light)
        XCTAssertEqual(themeManager.effectiveColorScheme, .light, "Effective color scheme should remain light when theme is explicitly set")
    }
    
    // MARK: - Semantic Colors Tests
    
    func testSemanticColorsGeneration() throws {
        let semanticColors = themeManager.semanticColors
        
        XCTAssertNotNil(semanticColors, "Semantic colors should be generated")
        XCTAssertEqual(semanticColors.colorScheme, themeManager.effectiveColorScheme, "Semantic colors should match effective color scheme")
        XCTAssertEqual(semanticColors.accentColor, themeManager.themePreferences.accentColor, "Semantic colors should match accent color preference")
    }
    
    func testSemanticColorsHighContrast() throws {
        themeManager.toggleHighContrast()
        let semanticColors = themeManager.semanticColors
        
        XCTAssertTrue(semanticColors.isHighContrast, "Semantic colors should reflect high contrast setting")
    }
    
    // MARK: - Theme Configuration Tests
    
    func testThemeConfiguration() throws {
        let configuration = themeManager.themeConfiguration
        
        XCTAssertNotNil(configuration, "Theme configuration should be generated")
        XCTAssertEqual(configuration.effectiveColorScheme, themeManager.effectiveColorScheme, "Configuration should match effective color scheme")
        XCTAssertEqual(configuration.preferences.selectedTheme, themeManager.themePreferences.selectedTheme, "Configuration should match theme preferences")
    }
    
    // MARK: - Audience Configuration Tests
    
    func testAudienceConfiguration() throws {
        themeManager.configureForAudience(.indian)
        
        XCTAssertEqual(themeManager.themePreferences.selectedTheme, .light, "Indian audience should default to light theme")
        XCTAssertEqual(themeManager.themePreferences.accentColor, .orange, "Indian audience should use orange accent color")
        
        themeManager.configureForAudience(.american)
        
        XCTAssertEqual(themeManager.themePreferences.selectedTheme, .system, "American audience should use system theme")
        XCTAssertEqual(themeManager.themePreferences.accentColor, .blue, "American audience should use blue accent color")
    }
    
    // MARK: - Cultural Event Tests
    
    func testCulturalEventUpdate() throws {
        themeManager.updateForCulturalEvent(.diwali)
        
        XCTAssertEqual(themeManager.themePreferences.accentColor, .orange, "Diwali event should use orange accent color")
        XCTAssertEqual(themeManager.themePreferences.culturalTheme, .festival, "Diwali should set festival cultural theme")
        
        themeManager.updateForCulturalEvent(.christmas)
        
        XCTAssertEqual(themeManager.themePreferences.accentColor, .green, "Christmas event should use green accent color")
        XCTAssertEqual(themeManager.themePreferences.culturalTheme, .seasonal, "Christmas should set seasonal cultural theme")
    }
    
    // MARK: - Reset Tests
    
    func testResetToDefault() throws {
        // Make some changes
        themeManager.updateThemeType(.dark)
        themeManager.updateAccentColor(.red)
        themeManager.toggleHighContrast()
        
        // Reset to default
        themeManager.resetToDefault()
        
        XCTAssertEqual(themeManager.themePreferences.selectedTheme, .system, "Theme should be reset to system")
        XCTAssertEqual(themeManager.themePreferences.accentColor, .blue, "Accent color should be reset to blue")
        XCTAssertFalse(themeManager.themePreferences.highContrastEnabled, "High contrast should be reset to false")
        XCTAssertTrue(themeManager.themePreferences.animationsEnabled, "Animations should be reset to true")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityValidation() throws {
        let issues = themeManager.validateAccessibility()
        
        // Default theme should not have accessibility issues
        XCTAssertTrue(issues.isEmpty, "Default theme should not have accessibility issues")
        
        // Enable high contrast and test again
        themeManager.toggleHighContrast()
        let highContrastIssues = themeManager.validateAccessibility()
        
        XCTAssertTrue(highContrastIssues.isEmpty, "High contrast theme should not have accessibility issues")
    }
    
    func testAccessibilityEnhancement() throws {
        // Simulate system accessibility settings
        themeManager.themePreferences.reduceMotion = false
        themeManager.themePreferences.animationsEnabled = true
        
        themeManager.enhanceAccessibility()
        
        // Should respect high contrast if semantic colors don't meet standards
        // This test would need to be expanded based on actual color validation
        XCTAssertNotNil(themeManager.themePreferences, "Preferences should be maintained after accessibility enhancement")
    }
    
    // MARK: - Persistence Tests
    
    func testPreferencesPersistence() throws {
        // Make changes
        themeManager.updateThemeType(.dark)
        themeManager.updateAccentColor(.green)
        
        // Verify last modified is updated
        let lastModified = themeManager.themePreferences.lastModified
        XCTAssertNotNil(lastModified, "Last modified should be set")
        
        // The actual persistence testing would require more complex setup
        // to test UserDefaults integration
    }
    
    // MARK: - Performance Tests
    
    func testThemeConfigurationPerformance() throws {
        measure {
            // Test performance of theme configuration generation
            for _ in 0..<1000 {
                let _ = themeManager.themeConfiguration
            }
        }
    }
    
    func testSemanticColorsPerformance() throws {
        measure {
            // Test performance of semantic colors generation
            for _ in 0..<1000 {
                let _ = themeManager.semanticColors
            }
        }
    }
}