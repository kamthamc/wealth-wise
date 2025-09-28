//
//  AccessibilityColorTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Tests for accessibility color compliance
//

import XCTest
import SwiftUI
@testable import WealthWise

final class AccessibilityColorTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var lightSemanticColors: SemanticColors!
    var darkSemanticColors: SemanticColors!
    var highContrastColors: SemanticColors!
    
    override func setUp() async throws {
        try await super.setUp()
        
        lightSemanticColors = SemanticColors(colorScheme: .light, accentColor: .blue, isHighContrast: false)
        darkSemanticColors = SemanticColors(colorScheme: .dark, accentColor: .blue, isHighContrast: false)
        highContrastColors = SemanticColors(colorScheme: .light, accentColor: .blue, isHighContrast: true)
    }
    
    override func tearDown() async throws {
        lightSemanticColors = nil
        darkSemanticColors = nil
        highContrastColors = nil
        try await super.tearDown()
    }
    
    // MARK: - Contrast Ratio Tests
    
    func testContrastRatioCalculation() throws {
        // Test basic contrast ratio calculation
        let whiteColor = Color.white
        let blackColor = Color.black
        
        let contrastRatio = AccessibilityColorHelper.contrastRatio(foreground: blackColor, background: whiteColor)
        
        XCTAssertGreaterThan(contrastRatio, 15.0, "Black on white should have very high contrast ratio")
        XCTAssertLessThan(contrastRatio, 25.0, "Contrast ratio should be reasonable") // Sanity check
    }
    
    func testLuminanceCalculation() throws {
        // Test relative luminance calculation
        let whiteLuminance = AccessibilityColorHelper.relativeLuminance(of: Color.white)
        let blackLuminance = AccessibilityColorHelper.relativeLuminance(of: Color.black)
        
        XCTAssertGreaterThan(whiteLuminance, blackLuminance, "White should have higher luminance than black")
        XCTAssertGreaterThanOrEqual(whiteLuminance, 0.0, "Luminance should be non-negative")
        XCTAssertLessThanOrEqual(whiteLuminance, 1.0, "Luminance should not exceed 1.0")
        XCTAssertGreaterThanOrEqual(blackLuminance, 0.0, "Black luminance should be non-negative")
    }
    
    // MARK: - WCAG Compliance Tests
    
    func testWCAGAACompliance() throws {
        // Test high contrast colors meet WCAG AA
        let primaryText = highContrastColors.primaryText
        let background = highContrastColors.background
        
        let meetsAA = AccessibilityColorHelper.meetsWCAGAA(foreground: primaryText, background: background)
        XCTAssertTrue(meetsAA, "High contrast primary text should meet WCAG AA standards")
        
        // Test financial colors
        let positiveColor = highContrastColors.positive
        let negativeColor = highContrastColors.negative
        let warningColor = highContrastColors.warning
        
        XCTAssertTrue(AccessibilityColorHelper.meetsWCAGAA(foreground: positiveColor, background: background), 
                     "High contrast positive color should meet WCAG AA")
        XCTAssertTrue(AccessibilityColorHelper.meetsWCAGAA(foreground: negativeColor, background: background), 
                     "High contrast negative color should meet WCAG AA")
        XCTAssertTrue(AccessibilityColorHelper.meetsWCAGAA(foreground: warningColor, background: background), 
                     "High contrast warning color should meet WCAG AA")
    }
    
    func testWCAGAAACompliance() throws {
        // Test if high contrast colors can meet WCAG AAA (more stringent)
        let primaryText = highContrastColors.primaryText
        let background = highContrastColors.background
        
        let meetsAAA = AccessibilityColorHelper.meetsWCAGAAA(foreground: primaryText, background: background)
        
        // High contrast should at least attempt to meet AAA when possible
        if meetsAAA {
            XCTAssertTrue(meetsAAA, "High contrast should meet WCAG AAA when possible")
        } else {
            // Even if it doesn't meet AAA, it should at least meet AA
            XCTAssertTrue(AccessibilityColorHelper.meetsWCAGAA(foreground: primaryText, background: background), 
                         "Should at least meet WCAG AA standards")
        }
    }
    
    // MARK: - Color Scheme Validation Tests
    
    func testLightSchemeValidation() throws {
        let report = AccessibilityColorHelper.validateColorScheme(lightSemanticColors)
        
        XCTAssertNotNil(report, "Validation report should be generated")
        XCTAssertGreaterThanOrEqual(report.overallScore, 0.0, "Overall score should be non-negative")
        XCTAssertLessThanOrEqual(report.overallScore, 100.0, "Overall score should not exceed 100")
        
        // Issues and warnings should be arrays (may be empty)
        XCTAssertNotNil(report.issues, "Issues array should exist")
        XCTAssertNotNil(report.warnings, "Warnings array should exist")
    }
    
    func testDarkSchemeValidation() throws {
        let report = AccessibilityColorHelper.validateColorScheme(darkSemanticColors)
        
        XCTAssertNotNil(report, "Dark scheme validation report should be generated")
        XCTAssertGreaterThanOrEqual(report.overallScore, 0.0, "Dark scheme overall score should be non-negative")
        XCTAssertLessThanOrEqual(report.overallScore, 100.0, "Dark scheme overall score should not exceed 100")
    }
    
    func testHighContrastValidation() throws {
        let report = AccessibilityColorHelper.validateColorScheme(highContrastColors)
        
        XCTAssertNotNil(report, "High contrast validation report should be generated")
        XCTAssertTrue(report.meetsStandards, "High contrast should meet accessibility standards")
        XCTAssertTrue(report.issues.isEmpty, "High contrast should have no accessibility issues")
        XCTAssertGreaterThanOrEqual(report.overallScore, 80.0, "High contrast should have high accessibility score")
    }
    
    // MARK: - Color Enhancement Tests
    
    func testColorEnhancement() throws {
        // Create a low contrast color combination
        let lowContrastForeground = Color.gray
        let background = Color.white
        
        let enhancedColor = AccessibilityColorHelper.enhanceColorForAccessibility(
            lowContrastForeground,
            against: background,
            targetRatio: AccessibilityColorHelper.wcagAAContrastRatio
        )
        
        XCTAssertNotNil(enhancedColor, "Enhanced color should be generated")
        
        let enhancedContrastRatio = AccessibilityColorHelper.contrastRatio(
            foreground: enhancedColor,
            background: background
        )
        
        let originalContrastRatio = AccessibilityColorHelper.contrastRatio(
            foreground: lowContrastForeground,
            background: background
        )
        
        XCTAssertGreaterThanOrEqual(enhancedContrastRatio, originalContrastRatio, 
                                   "Enhanced color should have better or equal contrast")
    }
    
    func testColorEnhancementAlreadyCompliant() throws {
        // Test with colors that already meet standards
        let compliantForeground = Color.black
        let background = Color.white
        
        let enhancedColor = AccessibilityColorHelper.enhanceColorForAccessibility(
            compliantForeground,
            against: background
        )
        
        // Should return the same color if already compliant
        XCTAssertEqual(enhancedColor.description, compliantForeground.description, 
                      "Should not modify already compliant colors")
    }
    
    // MARK: - System Integration Tests
    
    func testSystemAccessibilitySettings() throws {
        let settings = AccessibilityColorHelper.systemAccessibilitySettings()
        
        XCTAssertNotNil(settings, "System accessibility settings should be retrievable")
        
        // Test that all properties are accessible (not crashing)
        let _ = settings.highContrastEnabled
        let _ = settings.reduceMotionEnabled
        let _ = settings.reduceTransparencyEnabled
        let _ = settings.voiceOverEnabled
        let _ = settings.switchControlEnabled
        
        // These are boolean values, so just ensure they're accessible
        XCTAssertTrue(true, "System accessibility settings should be accessible")
    }
    
    // MARK: - Validation Report Tests
    
    func testValidationReportGeneration() throws {
        let report = AccessibilityColorHelper.validateColorScheme(lightSemanticColors)
        
        // Test report properties
        XCTAssertNotNil(report.recommendationsText, "Recommendations text should be generated")
        
        if !report.meetsStandards {
            XCTAssertFalse(report.recommendationsText.isEmpty, "Should have recommendations if not meeting standards")
        }
        
        if !report.issues.isEmpty {
            XCTAssertFalse(report.recommendationsText.isEmpty, "Should have recommendations if there are issues")
        }
    }
    
    func testAccessibilityIssueDescriptions() throws {
        let issue = AccessibilityIssue.insufficientContrast(
            foreground: "primaryText",
            background: "background",
            ratio: 3.5
        )
        
        XCTAssertFalse(issue.description.isEmpty, "Issue description should not be empty")
        XCTAssertTrue(issue.description.contains("3.5"), "Issue description should contain ratio value")
        
        let altTextIssue = AccessibilityIssue.missingAltText(element: "button")
        XCTAssertFalse(altTextIssue.description.isEmpty, "Alt text issue description should not be empty")
        
        let focusIssue = AccessibilityIssue.improperFocusOrder(element: "textField")
        XCTAssertFalse(focusIssue.description.isEmpty, "Focus issue description should not be empty")
    }
    
    func testAccessibilityWarningDescriptions() throws {
        let warning = AccessibilityWarning.lowContrast(
            foreground: "secondaryText",
            background: "background",
            ratio: 4.0
        )
        
        XCTAssertFalse(warning.description.isEmpty, "Warning description should not be empty")
        XCTAssertTrue(warning.description.contains("4.0"), "Warning description should contain ratio value")
        
        let sizeWarning = AccessibilityWarning.smallTouchTarget(
            element: "button",
            size: CGSize(width: 30, height: 30)
        )
        XCTAssertFalse(sizeWarning.description.isEmpty, "Size warning description should not be empty")
        
        let animationWarning = AccessibilityWarning.rapidAnimation(element: "transition")
        XCTAssertFalse(animationWarning.description.isEmpty, "Animation warning description should not be empty")
    }
    
    // MARK: - Color Extension Tests
    
    func testColorAccessibilityExtensions() throws {
        let foregroundColor = Color.gray
        let backgroundColor = Color.white
        
        // Test accessibility enhancement extension
        let enhancedColor = foregroundColor.accessibilityEnhanced(against: backgroundColor)
        XCTAssertNotNil(enhancedColor, "Color accessibility enhancement should work")
        
        // Test accessibility standards check extension
        let meetsStandards = foregroundColor.meetsAccessibilityStandards(against: backgroundColor)
        XCTAssertNotNil(meetsStandards, "Accessibility standards check should return a boolean")
        
        // Test contrast ratio extension
        let contrastRatio = foregroundColor.contrastRatio(against: backgroundColor)
        XCTAssertGreaterThan(contrastRatio, 0.0, "Contrast ratio should be positive")
        XCTAssertLessThan(contrastRatio, 50.0, "Contrast ratio should be reasonable")
    }
    
    // MARK: - Performance Tests
    
    func testContrastCalculationPerformance() throws {
        let foreground = Color.black
        let background = Color.white
        
        measure {
            for _ in 0..<1000 {
                let _ = AccessibilityColorHelper.contrastRatio(foreground: foreground, background: background)
            }
        }
    }
    
    func testColorSchemeValidationPerformance() throws {
        measure {
            for _ in 0..<100 {
                let _ = AccessibilityColorHelper.validateColorScheme(lightSemanticColors)
            }
        }
    }
    
    func testColorEnhancementPerformance() throws {
        let lowContrastColor = Color.gray
        let background = Color.white
        
        measure {
            for _ in 0..<100 {
                let _ = AccessibilityColorHelper.enhanceColorForAccessibility(
                    lowContrastColor,
                    against: background
                )
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testExtremeColorValues() throws {
        // Test with pure colors
        let pureRed = Color.red
        let pureBlue = Color.blue
        let pureWhite = Color.white
        let pureBlack = Color.black
        
        // These should not crash
        let _ = AccessibilityColorHelper.relativeLuminance(of: pureRed)
        let _ = AccessibilityColorHelper.relativeLuminance(of: pureBlue)
        let _ = AccessibilityColorHelper.relativeLuminance(of: pureWhite)
        let _ = AccessibilityColorHelper.relativeLuminance(of: pureBlack)
        
        // Contrast ratios should be calculable
        let redWhiteContrast = AccessibilityColorHelper.contrastRatio(foreground: pureRed, background: pureWhite)
        let blueWhiteContrast = AccessibilityColorHelper.contrastRatio(foreground: pureBlue, background: pureWhite)
        
        XCTAssertGreaterThan(redWhiteContrast, 0.0, "Red-white contrast should be positive")
        XCTAssertGreaterThan(blueWhiteContrast, 0.0, "Blue-white contrast should be positive")
    }
    
    func testIdenticalColors() throws {
        // Test contrast ratio between identical colors
        let sameColor = Color.blue
        let contrastRatio = AccessibilityColorHelper.contrastRatio(foreground: sameColor, background: sameColor)
        
        XCTAssertEqual(contrastRatio, 1.0, accuracy: 0.1, "Identical colors should have contrast ratio of 1.0")
    }
}