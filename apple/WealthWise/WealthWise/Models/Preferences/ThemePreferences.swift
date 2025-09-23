//
//  ThemePreferences.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Theme Configuration
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Theme preferences for dark/light mode, custom themes, and visual appearance
/// Supports comprehensive theming with accessibility compliance
@MainActor
@Observable
public final class ThemePreferences: Codable {
    
    // MARK: - Theme Settings
    
    /// Color scheme preference
    public var colorScheme: ColorSchemePreference = .system
    
    /// Selected theme
    public var selectedTheme: AppTheme = .default
    
    /// Custom theme identifier (if using custom theme)
    public var customThemeId: String?
    
    /// Accent color preference
    public var accentColor: AccentColorOption = .system
    
    /// Custom accent color RGB values (if using custom accent)
    public var customAccentColorRGB: [Double]?
    
    /// Computed property to get Color from RGB values
    public var customAccentColor: Color? {
        get {
            guard let rgb = customAccentColorRGB, rgb.count >= 3 else { return nil }
            return Color(red: rgb[0], green: rgb[1], blue: rgb[2])
        }
        set {
            if let color = newValue {
                #if canImport(UIKit)
                let uiColor = UIColor(color)
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                customAccentColorRGB = [Double(red), Double(green), Double(blue)]
                #else
                let nsColor = NSColor(color)
                customAccentColorRGB = [Double(nsColor.redComponent), Double(nsColor.greenComponent), Double(nsColor.blueComponent)]
                #endif
            } else {
                customAccentColorRGB = nil
            }
        }
    }
    
    // MARK: - Visual Effects
    
    /// Enable visual effects (blur, shadows, etc.)
    public var visualEffectsEnabled: Bool = true
    
    /// Animation speed multiplier
    public var animationSpeed: AnimationSpeed = .normal
    
    /// Reduce motion effects (different from accessibility setting)
    public var reduceMotionEffects: Bool = false
    
    /// Enable particles and decorative animations
    public var decorativeAnimationsEnabled: Bool = true
    
    /// Transparency level (0.0 to 1.0)
    public var transparencyLevel: Double = 1.0
    
    // MARK: - Interface Customization
    
    /// Corner radius style
    public var cornerRadiusStyle: CornerRadiusStyle = .standard
    
    /// Button style preference
    public var buttonStyle: ButtonStylePreference = .filled
    
    /// Card style preference
    public var cardStyle: CardStylePreference = .elevated
    
    /// Navigation style
    public var navigationStyle: NavigationStylePreference = .standard
    
    /// Show gradient backgrounds
    public var useGradientBackgrounds: Bool = true
    
    /// Icon style preference
    public var iconStyle: IconStyle = .outlined
    
    // MARK: - Chart and Data Visualization
    
    /// Chart color palette
    public var chartColorPalette: ChartColorPalette = .vibrant
    
    /// Use pattern fills for accessibility
    public var usePatternFills: Bool = false
    
    /// Chart animation enabled
    public var chartAnimationsEnabled: Bool = true
    
    /// Data point emphasis
    public var emphasizeDataPoints: Bool = false
    
    // MARK: - Cultural Adaptations
    
    /// Currency symbol style
    public var currencySymbolStyle: CurrencySymbolStyle = .standard
    
    /// Number display style
    public var numberDisplayStyle: NumberDisplayStyle = .standard
    
    /// Use cultural color meanings
    public var useCulturalColors: Bool = true
    
    // MARK: - Accessibility Integration
    
    /// Force high contrast when accessibility needs it
    public var autoHighContrast: Bool = true
    
    /// Minimum contrast ratio for text
    public var minimumContrastRatio: Double = 4.5
    
    /// Focus indicator style
    public var focusIndicatorStyle: FocusIndicatorStyle = .outline
    
    /// Large touch targets
    public var useLargeTouchTargets: Bool = false
    
    // MARK: - Initialization
    
    public init() {
        configureDefaults()
    }
    
    public init(forAudience audience: PrimaryAudience) {
        configureDefaults()
        configureForAudience(audience)
    }
    
    // MARK: - Configuration
    
    private func configureDefaults() {
        // Set system-appropriate defaults
        colorScheme = .system
        selectedTheme = .default
        accentColor = .system
#if canImport(UIKit)
        visualEffectsEnabled = !UIAccessibility.isReduceMotionEnabled
        reduceMotionEffects = UIAccessibility.isReduceMotionEnabled
#else
        visualEffectsEnabled = true
        reduceMotionEffects = false
#endif
    }
    
    public func configureForAudience(_ audience: PrimaryAudience) {
        switch audience {
        case .indian:
            // Indian cultural preferences
            useCulturalColors = true
            chartColorPalette = .warm
            currencySymbolStyle = .prominent
            
        case .american:
            // American preferences
            chartColorPalette = .vibrant
            buttonStyle = .filled
            
        case .british:
            // British preferences
            chartColorPalette = .classic
            cornerRadiusStyle = .minimal
            
        case .canadian:
            // Canadian preferences
            chartColorPalette = .nature
            
        case .australian:
            // Australian preferences
            chartColorPalette = .vibrant
            useGradientBackgrounds = true
            
        case .singaporean:
            // Singaporean preferences
            chartColorPalette = .professional
            cardStyle = .minimal
            
        default:
            // Default international settings
            break
        }
    }
    
    // MARK: - Dynamic Properties
    
    /// Current effective color scheme
    public var effectiveColorScheme: ColorScheme? {
        switch colorScheme {
        case .system:
            return nil // Let system decide
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// Whether high contrast should be applied
    public var shouldUseHighContrast: Bool {
#if canImport(UIKit)
        return autoHighContrast && UIAccessibility.isDarkerSystemColorsEnabled
#else
        return autoHighContrast
#endif
    }
    
    /// Effective animation speed based on accessibility
    public var effectiveAnimationSpeed: Double {
#if canImport(UIKit)
        let reduceMotion = UIAccessibility.isReduceMotionEnabled || reduceMotionEffects
#else
        let reduceMotion = reduceMotionEffects
#endif
        if reduceMotion {
            return 0.1 // Very fast/minimal animation
        }
        return animationSpeed.multiplier
    }
    
    // MARK: - Theme Application
    
    /// Apply theme to environment
    public func applyToEnvironment() -> some View {
        EmptyView()
            .preferredColorScheme(effectiveColorScheme)
            .accentColor(effectiveAccentColor)
    }
    
    /// Get effective accent color
    public var effectiveAccentColor: Color {
        switch accentColor {
        case .system:
            return .accentColor
        case .blue:
            return .blue
        case .green:
            return .green
        case .orange:
            return .orange
        case .red:
            return .red
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .yellow:
            return .yellow
        case .custom:
            return customAccentColor ?? .accentColor
        }
    }
    
    // MARK: - Validation
    
    public func validate() -> [String] {
        var issues: [String] = []
        
        // Validate transparency level
        if transparencyLevel < 0.0 || transparencyLevel > 1.0 {
            issues.append("Transparency level must be between 0.0 and 1.0")
        }
        
        // Validate contrast ratio
        if minimumContrastRatio < 1.0 || minimumContrastRatio > 21.0 {
            issues.append("Minimum contrast ratio must be between 1.0 and 21.0")
        }
        
        // Validate custom theme
        if selectedTheme == .custom && customThemeId == nil {
            issues.append("Custom theme selected but no theme ID provided")
        }
        
        // Validate custom accent color
        if accentColor == .custom && customAccentColor == nil {
            issues.append("Custom accent color selected but no color provided")
        }
        
        return issues
    }
    


}

// MARK: - Supporting Types

/// Color scheme preferences
public enum ColorSchemePreference: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// Available app themes
public enum AppTheme: String, CaseIterable, Codable {
    case `default` = "default"
    case minimal = "minimal"
    case vibrant = "vibrant"
    case professional = "professional"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .default: return "Default"
        case .minimal: return "Minimal"
        case .vibrant: return "Vibrant"
        case .professional: return "Professional"
        case .custom: return "Custom"
        }
    }
}

/// Accent color options
public enum AccentColorOption: String, CaseIterable, Codable {
    case system = "system"
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case pink = "pink"
    case yellow = "yellow"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .system: return "System"
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .red: return "Red"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .yellow: return "Yellow"
        case .custom: return "Custom"
        }
    }
}

/// Animation speed options
public enum AnimationSpeed: String, CaseIterable, Codable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    
    public var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        }
    }
    
    public var multiplier: Double {
        switch self {
        case .slow: return 1.5
        case .normal: return 1.0
        case .fast: return 0.7
        }
    }
}

/// Corner radius style options
public enum CornerRadiusStyle: String, CaseIterable, Codable {
    case minimal = "minimal"    // 2-4pt
    case standard = "standard"  // 8-12pt
    case rounded = "rounded"    // 16-20pt
    
    public var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .standard: return "Standard"
        case .rounded: return "Rounded"
        }
    }
    
    public var radius: CGFloat {
        switch self {
        case .minimal: return 4
        case .standard: return 12
        case .rounded: return 20
        }
    }
}

/// Button style preferences
public enum ButtonStylePreference: String, CaseIterable, Codable {
    case filled = "filled"
    case outlined = "outlined"
    case text = "text"
    
    public var displayName: String {
        switch self {
        case .filled: return "Filled"
        case .outlined: return "Outlined"
        case .text: return "Text"
        }
    }
}

/// Card style preferences
public enum CardStylePreference: String, CaseIterable, Codable {
    case elevated = "elevated"
    case outlined = "outlined"
    case minimal = "minimal"
    
    public var displayName: String {
        switch self {
        case .elevated: return "Elevated"
        case .outlined: return "Outlined"
        case .minimal: return "Minimal"
        }
    }
}

/// Navigation style preferences
public enum NavigationStylePreference: String, CaseIterable, Codable {
    case standard = "standard"
    case large = "large"
    case inline = "inline"
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .large: return "Large"
        case .inline: return "Inline"
        }
    }
}

/// Icon style preferences
public enum IconStyle: String, CaseIterable, Codable {
    case outlined = "outlined"
    case filled = "filled"
    case rounded = "rounded"
    case sharp = "sharp"
    
    public var displayName: String {
        switch self {
        case .outlined: return "Outlined"
        case .filled: return "Filled"
        case .rounded: return "Rounded"
        case .sharp: return "Sharp"
        }
    }
}

/// Chart color palette options
public enum ChartColorPalette: String, CaseIterable, Codable {
    case vibrant = "vibrant"
    case professional = "professional"
    case warm = "warm"
    case cool = "cool"
    case nature = "nature"
    case classic = "classic"
    case monochrome = "monochrome"
    
    public var displayName: String {
        switch self {
        case .vibrant: return "Vibrant"
        case .professional: return "Professional"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .nature: return "Nature"
        case .classic: return "Classic"
        case .monochrome: return "Monochrome"
        }
    }
}

/// Currency symbol display styles
public enum CurrencySymbolStyle: String, CaseIterable, Codable {
    case standard = "standard"      // $1,000
    case prominent = "prominent"    // $ 1,000
    case suffix = "suffix"          // 1,000 USD
    case full = "full"             // 1,000 US Dollars
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard ($1,000)"
        case .prominent: return "Prominent ($ 1,000)"
        case .suffix: return "Suffix (1,000 USD)"
        case .full: return "Full Name (1,000 US Dollars)"
        }
    }
}

/// Number display style preferences
public enum NumberDisplayStyle: String, CaseIterable, Codable {
    case standard = "standard"      // 1,000,000
    case abbreviated = "abbreviated" // 1M
    case scientific = "scientific"  // 1e6
    case words = "words"           // One Million
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard (1,000,000)"
        case .abbreviated: return "Abbreviated (1M)"
        case .scientific: return "Scientific (1e6)"
        case .words: return "Words (One Million)"
        }
    }
}

/// Focus indicator style options
public enum FocusIndicatorStyle: String, CaseIterable, Codable {
    case outline = "outline"
    case glow = "glow"
    case underline = "underline"
    case highlight = "highlight"
    
    public var displayName: String {
        switch self {
        case .outline: return "Outline"
        case .glow: return "Glow"
        case .underline: return "Underline"
        case .highlight: return "Highlight"
        }
    }
}

// MARK: - Color Extensions

extension Color {
    /// Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}