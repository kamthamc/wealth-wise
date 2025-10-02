//
//  ThemedText.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-28.
//  Theme System: Themed text component with semantic styling
//

import SwiftUI

/// Content type for ThemedText
public enum ThemedTextContent {
    case string(String)
    case localizedKey(LocalizedStringKey)
}

/// Themed text component that applies semantic colors and typography
public struct ThemedText: View {
    
    // MARK: - Properties
    
    @Environment(\.themeConfiguration) private var themeConfiguration
    
    private let content: ThemedTextContent
    private let level: TextLevel
    private let alignment: TextAlignment
    private let lineLimit: Int?
    
    // MARK: - Initialization
    
    public init(
        _ text: String,
        level: TextLevel = .primary,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) {
        self.content = .string(text)
        self.level = level
        self.alignment = alignment
        self.lineLimit = lineLimit
    }
    
    public init(
        _ localizedKey: LocalizedStringKey,
        level: TextLevel = .primary,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) {
        self.content = .localizedKey(localizedKey)
        self.level = level
        self.alignment = alignment
        self.lineLimit = lineLimit
    }
    
    // MARK: - Body
    
    public var body: some View {
        textView
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(alignment)
            .lineLimit(lineLimit)
            .animation(themeConfiguration.animationCurve, value: themeConfiguration.preferences.selectedTheme)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(accessibilityValue ?? "")
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var textView: some View {
        switch content {
        case .string(let text):
            Text(text)
        case .localizedKey(let key):
            Text(key)
        }
    }
    
    // MARK: - Computed Properties
    
    private var font: Font {
        let baseFont = level.font
        
        // Apply cultural typography adjustments if needed
        switch themeConfiguration.preferences.culturalTheme {
        case .none:
            return baseFont
        case .festival, .seasonal, .celebration:
            return baseFont.weight(.medium) // Slightly bolder for cultural themes
        }
    }
    
    private var color: Color {
        let baseColor = level.color(from: themeConfiguration.semanticColors)
        
        // Enhance contrast if needed
        if themeConfiguration.isHighContrastEnabled {
            return baseColor.accessibilityEnhanced(against: themeConfiguration.semanticColors.background)
        }
        
        return baseColor
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        let textString = switch content {
        case .string(let text): text
        case .localizedKey(let key): String(describing: key)
        }
        
        switch level {
        case .primary, .secondary, .tertiary, .accent:
            return textString
        case .positive:
            return String(format: NSLocalizedString("text.positive.accessibility", 
                                                   comment: "Positive value: %@"), textString)
        case .negative:
            return String(format: NSLocalizedString("text.negative.accessibility", 
                                                   comment: "Negative value: %@"), textString)
        case .warning:
            return String(format: NSLocalizedString("text.warning.accessibility", 
                                                   comment: "Warning: %@"), textString)
        }
    }
    
    private var accessibilityValue: String? {
        switch level {
        case .positive:
            return NSLocalizedString("text.positive.value", comment: "Positive")
        case .negative:
            return NSLocalizedString("text.negative.value", comment: "Negative")
        case .warning:
            return NSLocalizedString("text.warning.value", comment: "Warning")
        default:
            return nil
        }
    }
}

// MARK: - TextLevel Extensions

public extension TextLevel {
    /// Get font for text level
    var font: Font {
        switch self {
        case .primary:
            return .body
        case .secondary:
            return .callout
        case .tertiary:
            return .caption
        case .accent:
            return .body.weight(.medium)
        case .positive, .negative:
            return .body.weight(.semibold)
        case .warning:
            return .body.weight(.medium)
        }
    }
    
    /// Get color for text level from semantic colors
    func color(from semanticColors: SemanticColors) -> Color {
        switch self {
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
}

// MARK: - Convenience Extensions

public extension Text {
    /// Apply themed styling for string literals
    static func themed(
        _ text: String,
        level: TextLevel = .primary,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: level, alignment: alignment, lineLimit: lineLimit)
    }

    /// Apply themed styling for localized string keys
    static func themed(
        _ text: LocalizedStringKey,
        level: TextLevel = .primary,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: level, alignment: alignment, lineLimit: lineLimit)
    }

    /// Deprecated: Cannot extract text content from Text
    @available(*, deprecated, message: "Cannot extract text content from Text. Use Text.themed(_:level:alignment:lineLimit:) with a String or LocalizedStringKey instead.")
    func themed(
        level: TextLevel = .primary,
        alignment: TextAlignment = .leading
    ) -> ThemedText {
        // Unable to extract text content from Text
        ThemedText("", level: level, alignment: alignment)
    }
}

// MARK: - Convenience Initializers

public extension ThemedText {
    /// Create primary text
    static func primary(
        _ text: String,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: .primary, alignment: alignment, lineLimit: lineLimit)
    }
    
    /// Create secondary text
    static func secondary(
        _ text: String,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: .secondary, alignment: alignment, lineLimit: lineLimit)
    }
    
    /// Create tertiary text
    static func tertiary(
        _ text: String,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: .tertiary, alignment: alignment, lineLimit: lineLimit)
    }
    
    /// Create accent text
    static func accent(
        _ text: String,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: .accent, alignment: alignment, lineLimit: lineLimit)
    }
    
    /// Create positive financial text
    static func positive(
        _ text: String,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: .positive, alignment: alignment, lineLimit: lineLimit)
    }
    
    /// Create negative financial text
    static func negative(
        _ text: String,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: .negative, alignment: alignment, lineLimit: lineLimit)
    }
    
    /// Create warning text
    static func warning(
        _ text: String,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil
    ) -> ThemedText {
        ThemedText(text, level: .warning, alignment: alignment, lineLimit: lineLimit)
    }
}

// MARK: - Financial Text Helpers

public extension ThemedText {
    /// Create currency text with proper formatting
    static func currency(
        _ amount: Decimal,
        currency: String,
        isPositive: Bool? = nil,
        alignment: TextAlignment = .trailing
    ) -> ThemedText {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        
        let formattedText = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "¤0.00"
        
        let level: TextLevel
        if let isPositive = isPositive {
            level = isPositive ? .positive : .negative
        } else {
            level = amount >= 0 ? .positive : .negative
        }
        
        return ThemedText(formattedText, level: level, alignment: alignment)
    }
    
    /// Create percentage text
    static func percentage(
        _ value: Double,
        alignment: TextAlignment = .trailing
    ) -> ThemedText {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        
        let formattedText = formatter.string(from: NSNumber(value: value)) ?? "0.0%"
        let level: TextLevel = value >= 0 ? .positive : .negative
        
        return ThemedText(formattedText, level: level, alignment: alignment)
    }
}