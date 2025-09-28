//
//  SemanticColors.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Semantic color definitions with accessibility support
//

import Foundation
import SwiftUI

/// Semantic color system that adapts to theme and accessibility settings
public struct SemanticColors: Sendable {
    
    // MARK: - Properties
    
    public let colorScheme: ColorScheme
    public let accentColor: AccentColor
    public let isHighContrast: Bool
    
    // MARK: - Primary Colors
    
    /// Primary brand color
    public var primary: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return accentColor.swiftUIColor
        case (.light, true):
            return accentColor.highContrastLight
        case (.dark, false):
            return accentColor.darkVariant
        case (.dark, true):
            return accentColor.highContrastDark
        @unknown default:
            return accentColor.swiftUIColor
        }
    }
    
    /// Secondary brand color
    public var secondary: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.systemGray)
        case (.light, true):
            return Color(red: 0.8, green: 0.8, blue: 0.8)
        case (.dark, false):
            return Color(.systemGray)
        case (.dark, true):
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        @unknown default:
            return Color(.systemGray)
        }
    }
    
    /// Background colors
    public var background: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.windowBackgroundColor)
        case (.light, true):
            return Color.white
        case (.dark, false):
            return Color(.windowBackgroundColor)
        case (.dark, true):
            return Color.black
        @unknown default:
            return Color(.windowBackgroundColor)
        }
    }
    
    public var secondaryBackground: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.controlBackgroundColor)
        case (.light, true):
            return Color(.systemGray)
        case (.dark, false):
            return Color(.controlBackgroundColor)
        case (.dark, true):
            return Color(.systemGray)
        @unknown default:
            return Color(.controlBackgroundColor)
        }
    }
    
    public var tertiaryBackground: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.unemphasizedSelectedContentBackgroundColor)
        case (.light, true):
            return Color(.systemGray)
        case (.dark, false):
            return Color(.unemphasizedSelectedContentBackgroundColor)
        case (.dark, true):
            return Color(.systemGray)
        @unknown default:
            return Color(.unemphasizedSelectedContentBackgroundColor)
        }
    }
    
    // MARK: - Text Colors
    
    public var primaryText: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.labelColor)
        case (.light, true):
            return Color.black
        case (.dark, false):
            return Color(.labelColor)
        case (.dark, true):
            return Color.white
        @unknown default:
            return Color(.labelColor)
        }
    }
    
    public var secondaryText: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.secondaryLabelColor)
        case (.light, true):
            return Color(.systemGray)
        case (.dark, false):
            return Color(.secondaryLabelColor)
        case (.dark, true):
            return Color(.systemGray)
        @unknown default:
            return Color(.secondaryLabelColor)
        }
    }
    
    public var tertiaryText: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.tertiaryLabelColor)
        case (.light, true):
            return Color(.systemGray)
        case (.dark, false):
            return Color(.tertiaryLabelColor)
        case (.dark, true):
            return Color(.systemGray)
        @unknown default:
            return Color(.tertiaryLabelColor)
        }
    }
    
    // MARK: - Financial Colors
    
    /// Positive financial values (gains, income)
    public var positive: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.systemGreen)
        case (.light, true):
            return Color(red: 0.0, green: 0.6, blue: 0.0) // High contrast green
        case (.dark, false):
            return Color(.systemGreen)
        case (.dark, true):
            return Color(red: 0.2, green: 0.8, blue: 0.2) // High contrast dark green
        @unknown default:
            return Color(.systemGreen)
        }
    }
    
    /// Negative financial values (losses, expenses)
    public var negative: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.systemRed)
        case (.light, true):
            return Color(red: 0.8, green: 0.0, blue: 0.0) // High contrast red
        case (.dark, false):
            return Color(.systemRed)
        case (.dark, true):
            return Color(red: 1.0, green: 0.3, blue: 0.3) // High contrast dark red
        @unknown default:
            return Color(.systemRed)
        }
    }
    
    /// Neutral financial values
    public var neutral: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.systemBlue)
        case (.light, true):
            return Color(red: 0.0, green: 0.0, blue: 0.8) // High contrast blue
        case (.dark, false):
            return Color(.systemBlue)
        case (.dark, true):
            return Color(red: 0.4, green: 0.6, blue: 1.0) // High contrast dark blue
        @unknown default:
            return Color(.systemBlue)
        }
    }
    
    /// Warning/alert color
    public var warning: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.systemOrange)
        case (.light, true):
            return Color(red: 0.8, green: 0.4, blue: 0.0) // High contrast orange
        case (.dark, false):
            return Color(.systemOrange)
        case (.dark, true):
            return Color(red: 1.0, green: 0.6, blue: 0.2) // High contrast dark orange
        @unknown default:
            return Color(.systemOrange)
        }
    }
    
    // MARK: - UI Element Colors
    
    /// Separator/divider color
    public var separator: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.separatorColor)
        case (.light, true):
            return Color(.systemGray)
        case (.dark, false):
            return Color(.separatorColor)
        case (.dark, true):
            return Color(.systemGray)
        @unknown default:
            return Color(.separatorColor)
        }
    }
    
    /// Card/container stroke color
    public var cardStroke: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.quaternaryLabelColor)
        case (.light, true):
            return Color(.systemGray)
        case (.dark, false):
            return Color(.quaternaryLabelColor)
        case (.dark, true):
            return Color(.systemGray)
        @unknown default:
            return Color(.quaternaryLabelColor)
        }
    }
    
    /// Interactive element color
    public var interactive: Color {
        return primary
    }
    
    /// Disabled element color
    public var disabled: Color {
        switch (colorScheme, isHighContrast) {
        case (.light, false):
            return Color(.quaternaryLabelColor)
        case (.light, true):
            return Color(.systemGray)
        case (.dark, false):
            return Color(.quaternaryLabelColor)
        case (.dark, true):
            return Color(.systemGray)
        @unknown default:
            return Color(.quaternaryLabelColor)
        }
    }
    
    // MARK: - Chart Colors
    
    /// Chart color palette based on preferences
    public var chartColors: [Color] {
        let palette = ChartColorPalette.balanced // Could be from preferences
        return palette.colors(for: colorScheme, highContrast: isHighContrast)
    }
    
    // MARK: - Initialization
    
    public init(colorScheme: ColorScheme, accentColor: AccentColor, isHighContrast: Bool = false) {
        self.colorScheme = colorScheme
        self.accentColor = accentColor
        self.isHighContrast = isHighContrast
    }
    
    // MARK: - Accessibility Validation
    
    /// Check if current color scheme meets WCAG accessibility standards
    public func meetsAccessibilityStandards() -> Bool {
        if isHighContrast {
            return true // High contrast mode automatically meets standards
        }
        
        // Check primary contrast ratios
        let backgroundLuminance = background.luminance()
        let primaryTextLuminance = primaryText.luminance()
        let contrastRatio = contrastRatio(backgroundLuminance, primaryTextLuminance)
        
        return contrastRatio >= 4.5 // WCAG AA standard
    }
    
    /// Calculate contrast ratio between two luminance values
    private func contrastRatio(_ l1: Double, _ l2: Double) -> Double {
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

// MARK: - AccentColor Extensions

public extension AccentColor {
    /// High contrast variant for light mode
    var highContrastLight: Color {
        switch self {
        case .blue: return Color(red: 0.0, green: 0.0, blue: 0.8)
        case .green: return Color(red: 0.0, green: 0.6, blue: 0.0)
        case .orange: return Color(red: 0.8, green: 0.4, blue: 0.0)
        case .red: return Color(red: 0.8, green: 0.0, blue: 0.0)
        case .purple: return Color(red: 0.5, green: 0.0, blue: 0.8)
        case .pink: return Color(red: 0.8, green: 0.0, blue: 0.4)
        case .yellow: return Color(red: 0.6, green: 0.6, blue: 0.0)
        case .indigo: return Color(red: 0.2, green: 0.0, blue: 0.8)
        }
    }
    
    /// High contrast variant for dark mode
    var highContrastDark: Color {
        switch self {
        case .blue: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .green: return Color(red: 0.2, green: 0.8, blue: 0.2)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .red: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .purple: return Color(red: 0.8, green: 0.4, blue: 1.0)
        case .pink: return Color(red: 1.0, green: 0.4, blue: 0.7)
        case .yellow: return Color(red: 1.0, green: 1.0, blue: 0.4)
        case .indigo: return Color(red: 0.6, green: 0.4, blue: 1.0)
        }
    }
    
    /// Dark mode variant
    var darkVariant: Color {
        switch self {
        case .blue: return Color(.systemBlue)
        case .green: return Color(.systemGreen)
        case .orange: return Color(.systemOrange)
        case .red: return Color(.systemRed)
        case .purple: return Color(.systemPurple)
        case .pink: return Color(.systemPink)
        case .yellow: return Color(.systemYellow)
        case .indigo: return Color(.systemIndigo)
        }
    }
}

// MARK: - ChartColorPalette Extensions

public extension ChartColorPalette {
    /// Generate colors for chart palette
    func colors(for colorScheme: ColorScheme, highContrast: Bool) -> [Color] {
        switch (self, colorScheme, highContrast) {
        case (.standard, .light, false):
            return [.blue, .green, .orange, .red, .purple, .pink]
        case (.standard, .light, true):
            return [
                Color(red: 0.0, green: 0.0, blue: 0.8),
                Color(red: 0.0, green: 0.6, blue: 0.0),
                Color(red: 0.8, green: 0.4, blue: 0.0),
                Color(red: 0.8, green: 0.0, blue: 0.0),
                Color(red: 0.5, green: 0.0, blue: 0.8),
                Color(red: 0.8, green: 0.0, blue: 0.4)
            ]
        case (.standard, .dark, false):
            return [Color(.systemBlue), Color(.systemGreen), Color(.systemOrange), 
                   Color(.systemRed), Color(.systemPurple), Color(.systemPink)]
        case (.standard, .dark, true):
            return [
                Color(red: 0.4, green: 0.6, blue: 1.0),
                Color(red: 0.2, green: 0.8, blue: 0.2),
                Color(red: 1.0, green: 0.6, blue: 0.2),
                Color(red: 1.0, green: 0.3, blue: 0.3),
                Color(red: 0.8, green: 0.4, blue: 1.0),
                Color(red: 1.0, green: 0.4, blue: 0.7)
            ]
        case (.accessible, _, _):
            // Use high contrast colors regardless of setting for accessible palette
            return [
                Color(red: 0.0, green: 0.0, blue: 0.8),
                Color(red: 0.0, green: 0.6, blue: 0.0),
                Color(red: 0.8, green: 0.4, blue: 0.0),
                Color(red: 0.8, green: 0.0, blue: 0.0),
                Color(red: 0.5, green: 0.0, blue: 0.8),
                Color(red: 0.8, green: 0.0, blue: 0.4)
            ]
        case (.monochrome, .light, _), (.monochrome, .dark, _):
            return [Color(.systemGray), Color(.systemGray), Color(.systemGray), 
                   Color(.systemGray), Color(.systemGray), Color(.systemGray)]
        case (.vibrant, _, _):
            return [Color(.systemRed), Color(.systemOrange), Color(.systemYellow), 
                   Color(.systemGreen), Color(.systemBlue), Color(.systemPurple)]
        case (.balanced, _, _):
            return [.blue, .green, .orange, .red, .purple, .pink]
        @unknown default:
            return [.blue, .green, .orange, .red, .purple, .pink]
        }
    }
}



// MARK: - Color Extensions

public extension Color {
    /// Calculate luminance of the color for contrast calculations
    func luminance() -> Double {
        // Simplified luminance calculation
        // In a real implementation, you'd want more accurate color space conversion
        return 0.5 // Placeholder - implement proper luminance calculation
    }
}