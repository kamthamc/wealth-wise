//
//  AccessibilityColorHelper.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Accessibility compliance and color contrast validation
//

import Foundation
import SwiftUI
import AppKit

/// Helper for accessibility color compliance and validation
public struct AccessibilityColorHelper: Sendable {
    
    // MARK: - WCAG Standards
    
    public static let wcagAAContrastRatio: Double = 4.5
    public static let wcagAAAContrastRatio: Double = 7.0
    
    // MARK: - Color Contrast Calculation
    
    /// Calculate contrast ratio between foreground and background colors
    public static func contrastRatio(foreground: Color, background: Color) -> Double {
        let fgLuminance = relativeLuminance(of: foreground)
        let bgLuminance = relativeLuminance(of: background)
        
        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Calculate relative luminance of a color according to WCAG guidelines
    public static func relativeLuminance(of color: Color) -> Double {
        // Convert SwiftUI Color to NSColor and extract sRGB components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1
        
        if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
            red = nsColor.redComponent
            green = nsColor.greenComponent
            blue = nsColor.blueComponent
            alpha = nsColor.alphaComponent
        }
        
        let r = linearRGBComponent(red)
        let g = linearRGBComponent(green)
        let b = linearRGBComponent(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Convert sRGB component to linear RGB
    private static func linearRGBComponent(_ component: CGFloat) -> Double {
        let value = Double(component)
        
        if value <= 0.03928 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }
    
    // MARK: - Accessibility Validation
    
    /// Check if color combination meets WCAG AA standards
    public static func meetsWCAGAA(foreground: Color, background: Color) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)
        return ratio >= wcagAAContrastRatio
    }
    
    /// Check if color combination meets WCAG AAA standards
    public static func meetsWCAGAAA(foreground: Color, background: Color) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)
        return ratio >= wcagAAAContrastRatio
    }
    
    /// Validate a complete color scheme
    public static func validateColorScheme(_ semanticColors: SemanticColors) -> AccessibilityReport {
        var issues: [AccessibilityIssue] = []
        var warnings: [AccessibilityWarning] = []
        
        // Check primary text on background
        if !meetsWCAGAA(foreground: semanticColors.primaryText, background: semanticColors.background) {
            issues.append(.insufficientContrast(
                foreground: "primaryText",
                background: "background",
                ratio: contrastRatio(foreground: semanticColors.primaryText, background: semanticColors.background)
            ))
        }
        
        // Check secondary text on background
        if !meetsWCAGAA(foreground: semanticColors.secondaryText, background: semanticColors.background) {
            warnings.append(.lowContrast(
                foreground: "secondaryText",
                background: "background",
                ratio: contrastRatio(foreground: semanticColors.secondaryText, background: semanticColors.background)
            ))
        }
        
        // Check interactive elements
        if !meetsWCAGAA(foreground: semanticColors.interactive, background: semanticColors.background) {
            issues.append(.insufficientContrast(
                foreground: "interactive",
                background: "background",
                ratio: contrastRatio(foreground: semanticColors.interactive, background: semanticColors.background)
            ))
        }
        
        // Check financial colors
        validateFinancialColors(semanticColors, issues: &issues, warnings: &warnings)
        
        return AccessibilityReport(
            meetsStandards: issues.isEmpty,
            issues: issues,
            warnings: warnings,
            overallScore: calculateAccessibilityScore(issues: issues, warnings: warnings)
        )
    }
    
    private static func validateFinancialColors(
        _ semanticColors: SemanticColors,
        issues: inout [AccessibilityIssue],
        warnings: inout [AccessibilityWarning]
    ) {
        let financialColors = [
            ("positive", semanticColors.positive),
            ("negative", semanticColors.negative),
            ("warning", semanticColors.warning)
        ]
        
        for (name, color) in financialColors {
            if !meetsWCAGAA(foreground: color, background: semanticColors.background) {
                issues.append(.insufficientContrast(
                    foreground: name,
                    background: "background",
                    ratio: contrastRatio(foreground: color, background: semanticColors.background)
                ))
            }
        }
    }
    
    private static func calculateAccessibilityScore(issues: [AccessibilityIssue], warnings: [AccessibilityWarning]) -> Double {
        let maxScore = 100.0
        let issueDeduction = 20.0
        let warningDeduction = 5.0
        
        let score = maxScore - (Double(issues.count) * issueDeduction) - (Double(warnings.count) * warningDeduction)
        return max(0.0, score)
    }
    
    // MARK: - Color Enhancement
    
    /// Enhance color for better accessibility
    public static func enhanceColorForAccessibility(
        _ color: Color,
        against background: Color,
        targetRatio: Double = wcagAAContrastRatio
    ) -> Color {
        let currentRatio = contrastRatio(foreground: color, background: background)
        
        if currentRatio >= targetRatio {
            return color // Already meets standards
        }
        
        // Try darkening/lightening the color to meet contrast requirements
        return adjustColorForContrast(color, background: background, targetRatio: targetRatio)
    }
    
    private static func adjustColorForContrast(
        _ color: Color,
        background: Color,
        targetRatio: Double
    ) -> Color {
        let bgLuminance = relativeLuminance(of: background)
        let fgLuminance = relativeLuminance(of: color)
        
        // Determine if we need to make the color lighter or darker
        let shouldLighten = bgLuminance > fgLuminance
        
        var adjustedColor = color
        var attempts = 0
        let maxAttempts = 20
        
        while attempts < maxAttempts {
            let currentRatio = contrastRatio(foreground: adjustedColor, background: background)
            
            if currentRatio >= targetRatio {
                break
            }
            
            adjustedColor = shouldLighten 
                ? lightenColor(adjustedColor, by: 0.1)
                : darkenColor(adjustedColor, by: 0.1)
            
            attempts += 1
        }
        
        return adjustedColor
    }
    
    private static func lightenColor(_ color: Color, by factor: Double) -> Color {
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let red = min(1.0, components[0] + CGFloat(factor))
        let green = min(1.0, components[1] + CGFloat(factor))
        let blue = min(1.0, components[2] + CGFloat(factor))
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
    
    private static func darkenColor(_ color: Color, by factor: Double) -> Color {
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let red = max(0.0, components[0] - CGFloat(factor))
        let green = max(0.0, components[1] - CGFloat(factor))
        let blue = max(0.0, components[2] - CGFloat(factor))
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
    
    // MARK: - System Integration
    
    /// Check if system has accessibility preferences enabled
    public static func systemAccessibilitySettings() -> SystemAccessibilitySettings {
        SystemAccessibilitySettings(
            highContrastEnabled: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast,
            reduceMotionEnabled: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
            reduceTransparencyEnabled: NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency,
            voiceOverEnabled: NSWorkspace.shared.isVoiceOverEnabled,
            switchControlEnabled: NSWorkspace.shared.isSwitchControlEnabled
        )
    }
}

// MARK: - Supporting Types

/// Accessibility validation report
public struct AccessibilityReport: Sendable {
    public let meetsStandards: Bool
    public let issues: [AccessibilityIssue]
    public let warnings: [AccessibilityWarning]
    public let overallScore: Double
    
    public var recommendationsText: String {
        var recommendations: [String] = []
        
        if !meetsStandards {
            recommendations.append(NSLocalizedString("accessibility.enable_high_contrast", 
                                                     comment: "Enable high contrast mode"))
        }
        
        if !issues.isEmpty {
            recommendations.append(NSLocalizedString("accessibility.fix_contrast_issues", 
                                                     comment: "Fix contrast issues"))
        }
        
        if !warnings.isEmpty {
            recommendations.append(NSLocalizedString("accessibility.consider_improvements", 
                                                     comment: "Consider accessibility improvements"))
        }
        
        return recommendations.joined(separator: "\n")
    }
}

/// Accessibility issues
public enum AccessibilityIssue: Sendable {
    case insufficientContrast(foreground: String, background: String, ratio: Double)
    case missingAltText(element: String)
    case improperFocusOrder(element: String)
    
    public var description: String {
        switch self {
        case .insufficientContrast(let fg, let bg, let ratio):
            return String(format: NSLocalizedString("accessibility.insufficient_contrast", 
                                                   comment: "Insufficient contrast ratio"), fg, bg, ratio)
        case .missingAltText(let element):
            return String(format: NSLocalizedString("accessibility.missing_alt_text", 
                                                   comment: "Missing alt text"), element)
        case .improperFocusOrder(let element):
            return String(format: NSLocalizedString("accessibility.improper_focus", 
                                                   comment: "Improper focus order"), element)
        }
    }
}

/// Accessibility warnings
public enum AccessibilityWarning: Sendable {
    case lowContrast(foreground: String, background: String, ratio: Double)
    case smallTouchTarget(element: String, size: CGSize)
    case rapidAnimation(element: String)
    
    public var description: String {
        switch self {
        case .lowContrast(let fg, let bg, let ratio):
            return String(format: NSLocalizedString("accessibility.low_contrast", 
                                                   comment: "Low contrast ratio"), fg, bg, ratio)
        case .smallTouchTarget(let element, let size):
            return String(format: NSLocalizedString("accessibility.small_touch_target", 
                                                   comment: "Small touch target"), element, size.width, size.height)
        case .rapidAnimation(let element):
            return String(format: NSLocalizedString("accessibility.rapid_animation", 
                                                   comment: "Rapid animation"), element)
        }
    }
}

/// System accessibility settings
public struct SystemAccessibilitySettings: Sendable {
    public let highContrastEnabled: Bool
    public let reduceMotionEnabled: Bool
    public let reduceTransparencyEnabled: Bool
    public let voiceOverEnabled: Bool
    public let switchControlEnabled: Bool
}

// MARK: - Color Extensions

public extension Color {
    /// Get accessibility-enhanced version of the color
    func accessibilityEnhanced(against background: Color) -> Color {
        AccessibilityColorHelper.enhanceColorForAccessibility(self, against: background)
    }
    
    /// Check if this color meets accessibility standards against a background
    func meetsAccessibilityStandards(against background: Color) -> Bool {
        AccessibilityColorHelper.meetsWCAGAA(foreground: self, background: background)
    }
    
    /// Get contrast ratio against a background color
    func contrastRatio(against background: Color) -> Double {
        AccessibilityColorHelper.contrastRatio(foreground: self, background: background)
    }
}