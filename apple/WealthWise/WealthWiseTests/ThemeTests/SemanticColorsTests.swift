//
//  SemanticColorsTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Tests for SemanticColors functionality
//

import XCTest
import SwiftUI
@testable import WealthWise

final class SemanticColorsTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var lightSemanticColors: SemanticColors!
    var darkSemanticColors: SemanticColors!
    var highContrastLightColors: SemanticColors!
    var highContrastDarkColors: SemanticColors!
    
    override func setUp() async throws {
        try await super.setUp()
        
        lightSemanticColors = SemanticColors(colorScheme: .light, accentColor: .blue, isHighContrast: false)
        darkSemanticColors = SemanticColors(colorScheme: .dark, accentColor: .blue, isHighContrast: false)
        highContrastLightColors = SemanticColors(colorScheme: .light, accentColor: .blue, isHighContrast: true)
        highContrastDarkColors = SemanticColors(colorScheme: .dark, accentColor: .blue, isHighContrast: true)
    }
    
    override func tearDown() async throws {
        lightSemanticColors = nil
        darkSemanticColors = nil
        highContrastLightColors = nil
        highContrastDarkColors = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() throws {
        XCTAssertEqual(lightSemanticColors.colorScheme, .light, "Light semantic colors should have light color scheme")
        XCTAssertEqual(darkSemanticColors.colorScheme, .dark, "Dark semantic colors should have dark color scheme")
        XCTAssertEqual(lightSemanticColors.accentColor, .blue, "Accent color should be preserved")
        XCTAssertFalse(lightSemanticColors.isHighContrast, "High contrast should be false by default")
        XCTAssertTrue(highContrastLightColors.isHighContrast, "High contrast should be true when specified")
    }
    
    // MARK: - Primary Colors Tests
    
    func testPrimaryColors() throws {
        // Test that primary colors are different between light and dark modes
        XCTAssertNotEqual(lightSemanticColors.primary, darkSemanticColors.primary, "Primary colors should differ between light and dark modes")
        
        // Test that high contrast colors are different from normal colors
        XCTAssertNotEqual(lightSemanticColors.primary, highContrastLightColors.primary, "High contrast primary should differ from normal")
        XCTAssertNotEqual(darkSemanticColors.primary, highContrastDarkColors.primary, "High contrast primary should differ from normal in dark mode")
    }
    
    func testSecondaryColors() throws {
        XCTAssertNotNil(lightSemanticColors.secondary, "Secondary color should be defined")
        XCTAssertNotNil(darkSemanticColors.secondary, "Secondary color should be defined for dark mode")
        
        // Test that secondary colors adapt to high contrast
        XCTAssertNotEqual(lightSemanticColors.secondary, highContrastLightColors.secondary, "High contrast secondary should differ")
        XCTAssertNotEqual(darkSemanticColors.secondary, highContrastDarkColors.secondary, "High contrast secondary should differ in dark mode")
    }
    
    // MARK: - Background Colors Tests
    
    func testBackgroundColors() throws {
        // Test background color hierarchy
        XCTAssertNotNil(lightSemanticColors.background, "Background color should be defined")
        XCTAssertNotNil(lightSemanticColors.secondaryBackground, "Secondary background should be defined")
        XCTAssertNotNil(lightSemanticColors.tertiaryBackground, "Tertiary background should be defined")
        
        // Test that backgrounds are different between light and dark
        XCTAssertNotEqual(lightSemanticColors.background, darkSemanticColors.background, "Backgrounds should differ between modes")
        
        // Test high contrast backgrounds
        XCTAssertNotEqual(lightSemanticColors.background, highContrastLightColors.background, "High contrast background should differ")
    }
    
    // MARK: - Text Colors Tests
    
    func testTextColors() throws {
        // Test text color hierarchy
        XCTAssertNotNil(lightSemanticColors.primaryText, "Primary text color should be defined")
        XCTAssertNotNil(lightSemanticColors.secondaryText, "Secondary text color should be defined")
        XCTAssertNotNil(lightSemanticColors.tertiaryText, "Tertiary text color should be defined")
        
        // Test that text colors adapt between light and dark modes
        XCTAssertNotEqual(lightSemanticColors.primaryText, darkSemanticColors.primaryText, "Text colors should differ between modes")
        
        // Test high contrast text colors provide better contrast
        XCTAssertNotEqual(lightSemanticColors.primaryText, highContrastLightColors.primaryText, "High contrast text should differ")
    }
    
    // MARK: - Financial Colors Tests
    
    func testFinancialColors() throws {
        // Test that financial colors are defined
        XCTAssertNotNil(lightSemanticColors.positive, "Positive color should be defined")
        XCTAssertNotNil(lightSemanticColors.negative, "Negative color should be defined")
        XCTAssertNotNil(lightSemanticColors.neutral, "Neutral color should be defined")
        XCTAssertNotNil(lightSemanticColors.warning, "Warning color should be defined")
        
        // Test that financial colors are distinct
        XCTAssertNotEqual(lightSemanticColors.positive, lightSemanticColors.negative, "Positive and negative colors should be different")
        XCTAssertNotEqual(lightSemanticColors.positive, lightSemanticColors.warning, "Positive and warning colors should be different")
        XCTAssertNotEqual(lightSemanticColors.negative, lightSemanticColors.warning, "Negative and warning colors should be different")
        
        // Test that financial colors adapt to dark mode
        XCTAssertNotEqual(lightSemanticColors.positive, darkSemanticColors.positive, "Positive colors should adapt to dark mode")
        XCTAssertNotEqual(lightSemanticColors.negative, darkSemanticColors.negative, "Negative colors should adapt to dark mode")
        
        // Test high contrast financial colors
        XCTAssertNotEqual(lightSemanticColors.positive, highContrastLightColors.positive, "High contrast positive should differ")
        XCTAssertNotEqual(lightSemanticColors.negative, highContrastLightColors.negative, "High contrast negative should differ")
    }
    
    // MARK: - UI Element Colors Tests
    
    func testUIElementColors() throws {
        // Test UI element colors are defined
        XCTAssertNotNil(lightSemanticColors.separator, "Separator color should be defined")
        XCTAssertNotNil(lightSemanticColors.cardStroke, "Card stroke color should be defined")
        XCTAssertNotNil(lightSemanticColors.interactive, "Interactive color should be defined")
        XCTAssertNotNil(lightSemanticColors.disabled, "Disabled color should be defined")
        
        // Test that UI colors adapt between modes
        XCTAssertNotEqual(lightSemanticColors.separator, darkSemanticColors.separator, "Separator colors should differ between modes")
        XCTAssertNotEqual(lightSemanticColors.cardStroke, darkSemanticColors.cardStroke, "Card stroke colors should differ between modes")
        
        // Test interactive color matches primary
        XCTAssertEqual(lightSemanticColors.interactive, lightSemanticColors.primary, "Interactive color should match primary")
    }
    
    // MARK: - Chart Colors Tests
    
    func testChartColors() throws {
        let chartColors = lightSemanticColors.chartColors
        
        XCTAssertFalse(chartColors.isEmpty, "Chart colors should not be empty")
        XCTAssertGreaterThanOrEqual(chartColors.count, 3, "Should have at least 3 chart colors")
        
        // Test that chart colors are distinct
        let uniqueColors = Set(chartColors.map { $0.description })
        XCTAssertEqual(uniqueColors.count, chartColors.count, "Chart colors should be unique")
        
        // Test chart colors adapt to dark mode
        let darkChartColors = darkSemanticColors.chartColors
        XCTAssertEqual(chartColors.count, darkChartColors.count, "Chart color count should be consistent across modes")
    }
    
    // MARK: - Accent Color Tests
    
    func testAccentColorVariations() throws {
        let blueColors = SemanticColors(colorScheme: .light, accentColor: .blue, isHighContrast: false)
        let greenColors = SemanticColors(colorScheme: .light, accentColor: .green, isHighContrast: false)
        let orangeColors = SemanticColors(colorScheme: .light, accentColor: .orange, isHighContrast: false)
        
        // Test that different accent colors produce different primary colors
        XCTAssertNotEqual(blueColors.primary, greenColors.primary, "Different accent colors should produce different primaries")
        XCTAssertNotEqual(blueColors.primary, orangeColors.primary, "Different accent colors should produce different primaries")
        XCTAssertNotEqual(greenColors.primary, orangeColors.primary, "Different accent colors should produce different primaries")
        
        // Test that interactive color follows accent color
        XCTAssertEqual(blueColors.interactive, blueColors.primary, "Interactive should match primary for blue")
        XCTAssertEqual(greenColors.interactive, greenColors.primary, "Interactive should match primary for green")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityCompliance() throws {
        // Test that high contrast mode claims to meet standards
        XCTAssertTrue(highContrastLightColors.meetsAccessibilityStandards(), "High contrast should meet accessibility standards")
        XCTAssertTrue(highContrastDarkColors.meetsAccessibilityStandards(), "High contrast dark should meet accessibility standards")
        
        // Normal mode may or may not meet standards, but should be testable
        let lightMeetsStandards = lightSemanticColors.meetsAccessibilityStandards()
        let darkMeetsStandards = darkSemanticColors.meetsAccessibilityStandards()
        
        // These should at least be boolean values (not crash)
        XCTAssertNotNil(lightMeetsStandards, "Light mode accessibility check should return a value")
        XCTAssertNotNil(darkMeetsStandards, "Dark mode accessibility check should return a value")
    }
    
    // MARK: - High Contrast Tests
    
    func testHighContrastDifferences() throws {
        // Test that high contrast actually produces different colors
        XCTAssertNotEqual(lightSemanticColors.primaryText, highContrastLightColors.primaryText, "High contrast primary text should differ")
        XCTAssertNotEqual(lightSemanticColors.background, highContrastLightColors.background, "High contrast background should differ")
        XCTAssertNotEqual(lightSemanticColors.positive, highContrastLightColors.positive, "High contrast positive should differ")
        XCTAssertNotEqual(lightSemanticColors.negative, highContrastLightColors.negative, "High contrast negative should differ")
        
        // Test dark mode high contrast
        XCTAssertNotEqual(darkSemanticColors.primaryText, highContrastDarkColors.primaryText, "High contrast dark primary text should differ")
        XCTAssertNotEqual(darkSemanticColors.background, highContrastDarkColors.background, "High contrast dark background should differ")
    }
    
    // MARK: - Performance Tests
    
    func testColorGenerationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                let colors = SemanticColors(colorScheme: .light, accentColor: .blue, isHighContrast: false)
                let _ = colors.primary
                let _ = colors.primaryText
                let _ = colors.background
                let _ = colors.positive
                let _ = colors.negative
            }
        }
    }
    
    func testChartColorsPerformance() throws {
        measure {
            for _ in 0..<100 {
                let _ = lightSemanticColors.chartColors
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEdgeCases() throws {
        // Test with all accent colors
        for accentColor in AccentColor.allCases {
            let colors = SemanticColors(colorScheme: .light, accentColor: accentColor, isHighContrast: false)
            
            XCTAssertNotNil(colors.primary, "Primary color should be defined for \(accentColor)")
            XCTAssertNotNil(colors.interactive, "Interactive color should be defined for \(accentColor)")
            XCTAssertEqual(colors.accentColor, accentColor, "Accent color should be preserved for \(accentColor)")
        }
        
        // Test with both color schemes
        for colorScheme in [ColorScheme.light, ColorScheme.dark] {
            let colors = SemanticColors(colorScheme: colorScheme, accentColor: .blue, isHighContrast: false)
            
            XCTAssertEqual(colors.colorScheme, colorScheme, "Color scheme should be preserved")
            XCTAssertNotNil(colors.background, "Background should be defined for \(colorScheme)")
            XCTAssertNotNil(colors.primaryText, "Primary text should be defined for \(colorScheme)")
        }
    }
}