//
//  ThemeConfiguration.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Configuration container for theme-aware components
//

import Foundation
import SwiftUI

/// Complete theme configuration for UI components
public struct ThemeConfiguration: Sendable {
    
    // MARK: - Properties
    
    /// Theme preferences
    public let preferences: ThemePreferences
    
    /// Effective color scheme
    public let effectiveColorScheme: ColorScheme
    
    /// Semantic colors
    public let semanticColors: SemanticColors
    
    /// Whether animations are enabled
    public var animationsEnabled: Bool {
        preferences.animationsEnabled && !preferences.reduceMotion
    }
    
    /// Whether high contrast is enabled
    public var isHighContrastEnabled: Bool {
        preferences.highContrastEnabled
    }
    
    /// Card style configuration
    public var cardStyle: CardStyle {
        preferences.cardStyle
    }
    
    /// Graph style configuration
    public var graphStyle: GraphStyle {
        preferences.graphStyle
    }
    
    /// Chart color palette
    public var chartColorPalette: ChartColorPalette {
        preferences.chartColorPalette
    }
    
    // MARK: - Initialization
    
    public init(
        preferences: ThemePreferences,
        effectiveColorScheme: ColorScheme,
        semanticColors: SemanticColors
    ) {
        self.preferences = preferences
        self.effectiveColorScheme = effectiveColorScheme
        self.semanticColors = semanticColors
    }
    
    // MARK: - Styling Helpers
    
    /// Get animation duration based on preferences
    public var animationDuration: Double {
        animationsEnabled ? 0.3 : 0.0
    }
    
    /// Get animation curve based on preferences
    public var animationCurve: Animation {
        animationsEnabled ? .easeInOut(duration: animationDuration) : .linear(duration: 0)
    }
    
    /// Get corner radius for cards based on style
    public var cardCornerRadius: CGFloat {
        switch cardStyle {
        case .minimal:
            return 4.0
        case .standard:
            return 8.0
        case .detailed:
            return 12.0
        }
    }
    
    /// Get padding for cards based on style
    public var cardPadding: EdgeInsets {
        switch cardStyle {
        case .minimal:
            return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .standard:
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        case .detailed:
            return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        }
    }
    
    /// Get shadow configuration for cards
    public var cardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        let baseColor = semanticColors.cardStroke.opacity(0.1)
        switch cardStyle {
        case .minimal:
            return (baseColor, 1.0, 0, 1)
        case .standard:
            return (baseColor, 2.0, 0, 2)
        case .detailed:
            return (baseColor, 4.0, 0, 3)
        }
    }
    
    /// Get button styling configuration
    public func buttonConfiguration(for style: ButtonStyleType) -> ButtonConfiguration {
        ButtonConfiguration(
            backgroundColor: semanticColors.primary,
            foregroundColor: semanticColors.background,
            cornerRadius: cardCornerRadius * 0.75,
            padding: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16),
            animation: animationCurve
        )
    }
    
    /// Get text styling configuration
    public func textConfiguration(for level: TextLevel) -> TextConfiguration {
        TextConfiguration(
            color: textColor(for: level),
            font: font(for: level),
            animation: animationCurve
        )
    }
    
    // MARK: - Private Helpers
    
    private func textColor(for level: TextLevel) -> Color {
        switch level {
        case .primary:
            return semanticColors.primaryText
        case .secondary:
            return semanticColors.secondaryText
        case .tertiary:
            return semanticColors.tertiaryText
        case .accent:
            return semanticColors.primary
        case .positive:
            return semanticColors.positive
        case .negative:
            return semanticColors.negative
        case .warning:
            return semanticColors.warning
        }
    }
    
    private func font(for level: TextLevel) -> Font {
        switch level {
        case .primary:
            return .body
        case .secondary:
            return .callout
        case .tertiary:
            return .caption
        case .accent:
            return .body.weight(.medium)
        case .positive, .negative, .warning:
            return .body.weight(.semibold)
        }
    }
}

// MARK: - Supporting Types

/// Button style types
public enum ButtonStyleType: String, CaseIterable, Sendable {
    case primary
    case secondary
    case tertiary
    case destructive
    case success
}

/// Text hierarchy levels
public enum TextLevel: String, CaseIterable, Sendable {
    case primary
    case secondary
    case tertiary
    case accent
    case positive
    case negative
    case warning
}

/// Button configuration
public struct ButtonConfiguration: Sendable {
    public let backgroundColor: Color
    public let foregroundColor: Color
    public let cornerRadius: CGFloat
    public let padding: EdgeInsets
    public let animation: Animation
}

/// Text configuration
public struct TextConfiguration: Sendable {
    public let color: Color
    public let font: Font
    public let animation: Animation
}

// MARK: - Environment Key

public struct ThemeConfigurationKey: EnvironmentKey {
    public static let defaultValue: ThemeConfiguration = ThemeConfiguration(
        preferences: ThemePreferences(),
        effectiveColorScheme: .light,
        semanticColors: SemanticColors(colorScheme: .light, accentColor: .blue)
    )
}

public extension EnvironmentValues {
    var themeConfiguration: ThemeConfiguration {
        get { self[ThemeConfigurationKey.self] }
        set { self[ThemeConfigurationKey.self] = newValue }
    }
}

// MARK: - View Modifier

public struct ThemeConfigurationModifier: ViewModifier {
    let configuration: ThemeConfiguration
    
    public func body(content: Content) -> some View {
        content
            .environment(\.themeConfiguration, configuration)
    }
}

public extension View {
    /// Apply theme configuration to the view hierarchy
    func themeConfiguration(_ configuration: ThemeConfiguration) -> some View {
        self.modifier(ThemeConfigurationModifier(configuration: configuration))
    }
}