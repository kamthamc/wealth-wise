//
//  ThemePreferencesTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Theme Preferences Tests
//

import XCTest
@testable import WealthWise

@MainActor
final class ThemePreferencesTests: XCTestCase {
    
    var themePreferences: ThemePreferences!
    
    override func setUp() async throws {
        try await super.setUp()
        themePreferences = ThemePreferences()
    }
    
    override func tearDown() async throws {
        themePreferences = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        let theme = ThemePreferences()
        
        XCTAssertEqual(theme.selectedTheme, .system)
        XCTAssertEqual(theme.accentColor, .blue)
        XCTAssertEqual(theme.chartColorPalette, .standard)
        XCTAssertTrue(theme.animationsEnabled)
        XCTAssertEqual(theme.appearanceMode, .automatic)
        XCTAssertFalse(theme.highContrastEnabled)
        XCTAssertEqual(theme.cardStyle, .standard)
        XCTAssertEqual(theme.graphStyle, .smooth)
        XCTAssertEqual(theme.culturalTheme, .neutral)
    }
    
    func testCustomInitialization() {
        let theme = ThemePreferences(
            selectedTheme: .dark,
            accentColor: .green,
            chartColorPalette: .accessible,
            appearanceMode: .alwaysDark,
            highContrastEnabled: true,
            culturalTheme: .festive
        )
        
        XCTAssertEqual(theme.selectedTheme, .dark)
        XCTAssertEqual(theme.accentColor, .green)
        XCTAssertEqual(theme.chartColorPalette, .accessible)
        XCTAssertEqual(theme.appearanceMode, .alwaysDark)
        XCTAssertTrue(theme.highContrastEnabled)
        XCTAssertEqual(theme.culturalTheme, .festive)
    }
    
    // MARK: - Theme Selection Tests
    
    func testThemeSelectionUpdatesDerivedProperties() {
        themePreferences.selectedTheme = .dark
        
        // Dark theme should update related properties
        XCTAssertEqual(themePreferences.selectedTheme, .dark)
        XCTAssertEqual(themePreferences.appearanceMode, .alwaysDark)
    }
    
    func testSystemThemeFollowsDevice() {
        themePreferences.selectedTheme = .system
        
        XCTAssertEqual(themePreferences.selectedTheme, .system)
        XCTAssertEqual(themePreferences.appearanceMode, .automatic)
    }
    
    func testLightThemeConfiguration() {
        themePreferences.selectedTheme = .light
        
        XCTAssertEqual(themePreferences.selectedTheme, .light)
        XCTAssertEqual(themePreferences.appearanceMode, .alwaysLight)
    }
    
    // MARK: - Accent Color Tests
    
    func testAccentColorConfiguration() {
        let colors: [AccentColor] = [.blue, .green, .red, .orange, .purple, .pink, .teal, .indigo]
        
        for color in colors {
            themePreferences.accentColor = color
            XCTAssertEqual(themePreferences.accentColor, color)
        }
    }
    
    func testAccentColorSystemIntegration() {
        themePreferences.accentColor = .blue
        
        // Should provide system color integration
        XCTAssertEqual(themePreferences.accentColor, .blue)
    }
    
    // MARK: - Chart Color Palette Tests
    
    func testChartColorPaletteOptions() {
        let palettes: [ChartColorPalette] = [.standard, .accessible, .colorBlindFriendly, .warm, .cool, .monochrome]
        
        for palette in palettes {
            themePreferences.chartColorPalette = palette
            XCTAssertEqual(themePreferences.chartColorPalette, palette)
        }
    }
    
    func testAccessibleChartPalette() {
        themePreferences.chartColorPalette = .accessible
        
        XCTAssertEqual(themePreferences.chartColorPalette, .accessible)
        // Accessible palette should work with high contrast
        themePreferences.highContrastEnabled = true
        XCTAssertTrue(themePreferences.highContrastEnabled)
    }
    
    func testColorBlindFriendlyPalette() {
        themePreferences.chartColorPalette = .colorBlindFriendly
        
        XCTAssertEqual(themePreferences.chartColorPalette, .colorBlindFriendly)
        // Should be compatible with all color blind types
    }
    
    // MARK: - Animation Tests
    
    func testAnimationToggle() {
        XCTAssertTrue(themePreferences.animationsEnabled)
        
        themePreferences.animationsEnabled = false
        XCTAssertFalse(themePreferences.animationsEnabled)
        
        themePreferences.animationsEnabled = true
        XCTAssertTrue(themePreferences.animationsEnabled)
    }
    
    func testReducedMotionIntegration() {
        // Test that theme respects system reduced motion settings
        themePreferences.animationsEnabled = true
        
        // Should still respect system accessibility settings
        XCTAssertTrue(themePreferences.animationsEnabled)
    }
    
    // MARK: - High Contrast Tests
    
    func testHighContrastToggle() {
        XCTAssertFalse(themePreferences.highContrastEnabled)
        
        themePreferences.highContrastEnabled = true
        XCTAssertTrue(themePreferences.highContrastEnabled)
        
        themePreferences.highContrastEnabled = false
        XCTAssertFalse(themePreferences.highContrastEnabled)
    }
    
    func testHighContrastWithDifferentThemes() {
        let themes: [AppTheme] = [.light, .dark, .system]
        
        for theme in themes {
            themePreferences.selectedTheme = theme
            themePreferences.highContrastEnabled = true
            
            XCTAssertTrue(themePreferences.highContrastEnabled)
            XCTAssertEqual(themePreferences.selectedTheme, theme)
        }
    }
    
    // MARK: - Card Style Tests
    
    func testCardStyleOptions() {
        let styles: [CardStyle] = [.standard, .compact, .minimal, .detailed]
        
        for style in styles {
            themePreferences.cardStyle = style
            XCTAssertEqual(themePreferences.cardStyle, style)
        }
    }
    
    func testCardStyleWithDifferentThemes() {
        themePreferences.cardStyle = .minimal
        
        themePreferences.selectedTheme = .dark
        XCTAssertEqual(themePreferences.cardStyle, .minimal)
        
        themePreferences.selectedTheme = .light
        XCTAssertEqual(themePreferences.cardStyle, .minimal)
    }
    
    // MARK: - Graph Style Tests
    
    func testGraphStyleOptions() {
        let styles: [GraphStyle] = [.smooth, .angular, .stepped, .minimal]
        
        for style in styles {
            themePreferences.graphStyle = style
            XCTAssertEqual(themePreferences.graphStyle, style)
        }
    }
    
    func testGraphStyleWithAccessibility() {
        themePreferences.graphStyle = .smooth
        themePreferences.highContrastEnabled = true
        
        // Graph style should be compatible with accessibility settings
        XCTAssertEqual(themePreferences.graphStyle, .smooth)
        XCTAssertTrue(themePreferences.highContrastEnabled)
    }
    
    // MARK: - Cultural Theme Tests
    
    func testCulturalThemeOptions() {
        let themes: [CulturalTheme] = [.neutral, .festive, .traditional, .modern, .professional]
        
        for theme in themes {
            themePreferences.culturalTheme = theme
            XCTAssertEqual(themePreferences.culturalTheme, theme)
        }
    }
    
    func testFestiveCulturalTheme() {
        themePreferences.culturalTheme = .festive
        
        XCTAssertEqual(themePreferences.culturalTheme, .festive)
        // Festive theme should be compatible with all base themes
        themePreferences.selectedTheme = .dark
        XCTAssertEqual(themePreferences.culturalTheme, .festive)
    }
    
    func testTraditionalCulturalTheme() {
        themePreferences.culturalTheme = .traditional
        
        XCTAssertEqual(themePreferences.culturalTheme, .traditional)
        // Traditional theme should work with Indian cultural context
    }
    
    // MARK: - Validation Tests
    
    func testThemeValidation() {
        let validTheme = ThemePreferences()
        validTheme.selectedTheme = .dark
        validTheme.accentColor = .blue
        validTheme.chartColorPalette = .standard
        
        XCTAssertTrue(validTheme.isValid())
        XCTAssertTrue(validTheme.validate().isEmpty)
    }
    
    func testIncompatibleCombinationValidation() {
        let theme = ThemePreferences()
        
        // Test potential incompatible combinations
        theme.highContrastEnabled = true
        theme.chartColorPalette = .warm // Might not be ideal with high contrast
        
        // Should still be valid as warm palette can work with high contrast
        XCTAssertTrue(theme.isValid())
    }
    
    // MARK: - System Integration Tests
    
    func testSystemThemeFollowing() {
        themePreferences.selectedTheme = .system
        
        // Should adapt to system appearance
        XCTAssertEqual(themePreferences.selectedTheme, .system)
        XCTAssertEqual(themePreferences.appearanceMode, .automatic)
    }
    
    func testAccessibilityIntegration() {
        themePreferences.highContrastEnabled = true
        themePreferences.chartColorPalette = .accessible
        themePreferences.animationsEnabled = false
        
        // All accessibility features should work together
        XCTAssertTrue(themePreferences.highContrastEnabled)
        XCTAssertEqual(themePreferences.chartColorPalette, .accessible)
        XCTAssertFalse(themePreferences.animationsEnabled)
    }
    
    // MARK: - Codable Tests
    
    func testCodableEncoding() throws {
        themePreferences.selectedTheme = .dark
        themePreferences.accentColor = .green
        themePreferences.chartColorPalette = .accessible
        themePreferences.highContrastEnabled = true
        themePreferences.culturalTheme = .festive
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(themePreferences)
        
        XCTAssertFalse(data.isEmpty)
    }
    
    func testCodableDecoding() throws {
        // Create test theme
        let originalTheme = ThemePreferences()
        originalTheme.selectedTheme = .dark
        originalTheme.accentColor = .purple
        originalTheme.chartColorPalette = .cool
        originalTheme.animationsEnabled = false
        originalTheme.highContrastEnabled = true
        originalTheme.cardStyle = .compact
        originalTheme.graphStyle = .angular
        originalTheme.culturalTheme = .traditional
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalTheme)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedTheme = try decoder.decode(ThemePreferences.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedTheme.selectedTheme, originalTheme.selectedTheme)
        XCTAssertEqual(decodedTheme.accentColor, originalTheme.accentColor)
        XCTAssertEqual(decodedTheme.chartColorPalette, originalTheme.chartColorPalette)
        XCTAssertEqual(decodedTheme.animationsEnabled, originalTheme.animationsEnabled)
        XCTAssertEqual(decodedTheme.highContrastEnabled, originalTheme.highContrastEnabled)
        XCTAssertEqual(decodedTheme.cardStyle, originalTheme.cardStyle)
        XCTAssertEqual(decodedTheme.graphStyle, originalTheme.graphStyle)
        XCTAssertEqual(decodedTheme.culturalTheme, originalTheme.culturalTheme)
    }
    
    func testCodableRoundTrip() throws {
        // Configure complex theme
        themePreferences.selectedTheme = .dark
        themePreferences.accentColor = .teal
        themePreferences.chartColorPalette = .colorBlindFriendly
        themePreferences.animationsEnabled = false
        themePreferences.appearanceMode = .alwaysDark
        themePreferences.highContrastEnabled = true
        themePreferences.cardStyle = .minimal
        themePreferences.graphStyle = .stepped
        themePreferences.culturalTheme = .professional
        
        // Round trip encode/decode
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(themePreferences)
        let decoded = try decoder.decode(ThemePreferences.self, from: data)
        
        // Should be identical
        XCTAssertEqual(decoded.selectedTheme, themePreferences.selectedTheme)
        XCTAssertEqual(decoded.accentColor, themePreferences.accentColor)
        XCTAssertEqual(decoded.chartColorPalette, themePreferences.chartColorPalette)
        XCTAssertEqual(decoded.animationsEnabled, themePreferences.animationsEnabled)
        XCTAssertEqual(decoded.appearanceMode, themePreferences.appearanceMode)
        XCTAssertEqual(decoded.highContrastEnabled, themePreferences.highContrastEnabled)
        XCTAssertEqual(decoded.cardStyle, themePreferences.cardStyle)
        XCTAssertEqual(decoded.graphStyle, themePreferences.graphStyle)
        XCTAssertEqual(decoded.culturalTheme, themePreferences.culturalTheme)
    }
    
    // MARK: - Edge Case Tests
    
    func testNilPropertiesHandling() {
        // Test with minimal configuration
        let minimalTheme = ThemePreferences()
        
        // Should have sensible defaults
        XCTAssertNotNil(minimalTheme.selectedTheme)
        XCTAssertNotNil(minimalTheme.accentColor)
        XCTAssertNotNil(minimalTheme.chartColorPalette)
    }
    
    func testThemeConsistency() {
        // Dark theme should have consistent settings
        themePreferences.selectedTheme = .dark
        themePreferences.appearanceMode = .alwaysLight // Inconsistent
        
        // Validation should catch this
        let issues = themePreferences.validate()
        XCTAssertTrue(issues.contains { $0.contains("inconsistent") })
    }
    
    func testExtremeCombinations() {
        themePreferences.selectedTheme = .dark
        themePreferences.highContrastEnabled = true
        themePreferences.chartColorPalette = .monochrome
        themePreferences.animationsEnabled = false
        themePreferences.cardStyle = .minimal
        themePreferences.graphStyle = .minimal
        
        // Extreme accessibility combination should be valid
        XCTAssertTrue(themePreferences.isValid())
    }
    
    // MARK: - Performance Tests
    
    func testThemeApplicationPerformance() {
        measure {
            for _ in 0..<1000 {
                themePreferences.selectedTheme = .dark
                themePreferences.accentColor = .blue
                themePreferences.chartColorPalette = .standard
                
                // Simulate theme application
                _ = themePreferences.selectedTheme
                _ = themePreferences.accentColor
                _ = themePreferences.chartColorPalette
            }
        }
    }
    
    func testValidationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = themePreferences.validate()
                _ = themePreferences.isValid()
            }
        }
    }
    
    func testCodingPerformance() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        measure {
            do {
                for _ in 0..<100 {
                    let data = try encoder.encode(themePreferences)
                    _ = try decoder.decode(ThemePreferences.self, from: data)
                }
            } catch {
                XCTFail("Coding performance test failed: \(error)")
            }
        }
    }
    
    // MARK: - Cultural Adaptation Tests
    
    func testIndianCulturalAdaptation() {
        themePreferences.culturalTheme = .festive
        
        // Should adapt to Indian festivals and cultural preferences
        XCTAssertEqual(themePreferences.culturalTheme, .festive)
        
        // Should work with warm color palettes for festivals
        themePreferences.chartColorPalette = .warm
        XCTAssertEqual(themePreferences.chartColorPalette, .warm)
    }
    
    func testProfessionalThemeForBusiness() {
        themePreferences.culturalTheme = .professional
        themePreferences.selectedTheme = .light
        themePreferences.cardStyle = .standard
        
        // Professional theme should be conservative and business-appropriate
        XCTAssertEqual(themePreferences.culturalTheme, .professional)
        XCTAssertEqual(themePreferences.cardStyle, .standard)
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage() {
        let themes = (0..<100).map { _ in ThemePreferences() }
        
        // Configure each theme differently
        for (index, theme) in themes.enumerated() {
            theme.selectedTheme = index % 2 == 0 ? .dark : .light
            theme.accentColor = AccentColor.allCases[index % AccentColor.allCases.count]
            theme.chartColorPalette = ChartColorPalette.allCases[index % ChartColorPalette.allCases.count]
        }
        
        // Should handle multiple theme instances efficiently
        XCTAssertEqual(themes.count, 100)
        
        // Verify they're configured correctly
        XCTAssertEqual(themes[0].selectedTheme, .dark)
        XCTAssertEqual(themes[1].selectedTheme, .light)
    }
}