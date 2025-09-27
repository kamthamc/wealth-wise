import Foundation

/// Extension to NSNumber for accessibility and localized formatting
@available(iOS 18.6, macOS 15.6, *)
extension NSNumber {
    
    // MARK: - Accessibility Formatting
    
    /// Get accessibility-friendly description for VoiceOver
    public func accessibilityDescription(
        for audience: PrimaryAudience = .american,
        as currency: SupportedCurrency? = nil
    ) -> String {
        let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
        
        if let currency = currency {
            return formatter.accessibleCurrencyString(from: self.decimalValue, currency: currency)
        } else {
            return formatter.accessibleString(from: self.decimalValue)
        }
    }
    
    /// Get phonetic representation for speech synthesis
    public func phoneticDescription(for audience: PrimaryAudience = .american) -> String {
        let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
        return formatter.phoneticString(from: self.decimalValue)
    }
    
    /// Test pronunciation using speech synthesizer
    public func testPronunciation(
        for audience: PrimaryAudience = .american,
        completion: @escaping (Bool) -> Void
    ) {
        let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
        formatter.testPronunciation(of: self.decimalValue, completion: completion)
    }
    
    // MARK: - Localized Formatting
    
    /// Format as localized number string for specific audience
    public func formattedString(for audience: PrimaryAudience, abbreviated: Bool = false) -> String {
        return self.decimalValue.formattedString(for: audience, abbreviated: abbreviated)
    }
    
    /// Format as currency string for specific currency and audience
    public func currencyString(
        currency: SupportedCurrency,
        audience: PrimaryAudience,
        abbreviated: Bool = false
    ) -> String {
        return self.decimalValue.currencyString(
            currency: currency,
            audience: audience,
            abbreviated: abbreviated
        )
    }
    
    // MARK: - Accessibility Attributes for UI
    
    /// Get accessibility label for UI elements displaying this number
    public func accessibilityLabel(
        context: AccessibilityContext = .general,
        audience: PrimaryAudience = .american
    ) -> String {
        switch context {
        case .general:
            return accessibilityDescription(for: audience)
        case .currency(let currency):
            return accessibilityDescription(for: audience, as: currency)
        case .percentage:
            return percentageAccessibilityDescription(for: audience)
        case .count:
            return countAccessibilityDescription(for: audience)
        case .ordinal:
            return ordinalAccessibilityDescription(for: audience)
        }
    }
    
    /// Get accessibility hint for UI elements displaying this number
    public func accessibilityHint(context: AccessibilityContext = .general) -> String? {
        switch context {
        case .currency(let currency):
            return NSLocalizedString(
                "accessibility.hint.currency",
                value: "Double tap to edit \(currency.displayName) amount",
                comment: "Accessibility hint for currency input"
            )
        case .percentage:
            return NSLocalizedString(
                "accessibility.hint.percentage",
                value: "Double tap to edit percentage value",
                comment: "Accessibility hint for percentage input"
            )
        case .count:
            return NSLocalizedString(
                "accessibility.hint.count",
                value: "Double tap to edit count",
                comment: "Accessibility hint for count input"
            )
        default:
            return nil
        }
    }
    
    /// Get accessibility traits for UI elements displaying this number
    public func accessibilityRole(context: AccessibilityContext = .general) -> NSAccessibility.Role {
        switch context {
        case .currency, .percentage, .count:
            return .textField // If editable
        case .ordinal:
            return .staticText
        case .general:
            return .staticText
        }
    }
    
    // MARK: - Specialized Accessibility Descriptions
    
    /// Get percentage accessibility description
    private func percentageAccessibilityDescription(for audience: PrimaryAudience) -> String {
        let percentage = self.doubleValue * 100
        let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
        let numberPart = formatter.accessibleString(from: Decimal(percentage))
        
        let percentWord = NSLocalizedString(
            "accessibility.percent",
            value: "percent",
            comment: "Accessibility: Percent word"
        )
        
        return "\(numberPart) \(percentWord)"
    }
    
    /// Get count accessibility description
    private func countAccessibilityDescription(for audience: PrimaryAudience) -> String {
        let count = self.intValue
        
        if count == 0 {
            return NSLocalizedString(
                "accessibility.count.zero",
                value: "no items",
                comment: "Accessibility: Zero count"
            )
        } else if count == 1 {
            return NSLocalizedString(
                "accessibility.count.one",
                value: "1 item",
                comment: "Accessibility: Single item count"
            )
        } else {
            let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
            let numberPart = formatter.accessibleString(from: Decimal(count))
            return NSLocalizedString(
                "accessibility.count.multiple",
                value: "\(numberPart) items",
                comment: "Accessibility: Multiple items count"
            )
        }
    }
    
    /// Get ordinal accessibility description (1st, 2nd, 3rd, etc.)
    private func ordinalAccessibilityDescription(for audience: PrimaryAudience) -> String {
        let ordinal = self.intValue
        
        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        ordinalFormatter.locale = audience.preferredLocale
        
        if let ordinalString = ordinalFormatter.string(from: self) {
            return ordinalString
        } else {
            // Fallback to basic ordinal description
            return getBasicOrdinalDescription(ordinal, for: audience)
        }
    }
    
    /// Get basic ordinal description as fallback
    private func getBasicOrdinalDescription(_ number: Int, for audience: PrimaryAudience) -> String {
        let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
        let numberPart = formatter.accessibleString(from: Decimal(number))
        
        // Simple English ordinal suffix logic (can be extended for other languages)
        let suffix: String
        if audience.preferredLocale.language.languageCode?.identifier == "en" {
            let lastDigit = number % 10
            let lastTwoDigits = number % 100
            
            if lastTwoDigits >= 11 && lastTwoDigits <= 13 {
                suffix = "th"
            } else {
                switch lastDigit {
                case 1: suffix = "st"
                case 2: suffix = "nd"
                case 3: suffix = "rd"
                default: suffix = "th"
                }
            }
        } else {
            suffix = "" // For non-English, rely on system formatter
        }
        
        return "\(numberPart)\(suffix)"
    }
    
    // MARK: - RTL Support
    
    /// Get formatted string with RTL layout consideration
    public func rtlAwareString(
        currency: SupportedCurrency,
        audience: PrimaryAudience
    ) -> String {
        let culturalPrefs = CulturalPreferences.forAudience(audience)
        let formatter = LocalizedCurrencyFormatter.formatter(
            for: currency,
            audience: audience,
            abbreviated: false
        )
        
        let formattedString = formatter.string(from: self.decimalValue)
        
        // For RTL languages, we might need to adjust the string direction
        if culturalPrefs.textDirection == "rtl" {
            return "\u{202E}\(formattedString)\u{202C}" // Right-to-left embedding
        } else {
            return formattedString
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Check if NSNumber represents a valid financial amount
    public func isValidFinancialAmount(for currency: SupportedCurrency) -> Bool {
        return self.decimalValue.isValidAmount(for: currency)
    }
    
    /// Get validation error message
    public func validationError(for currency: SupportedCurrency) -> String? {
        return self.decimalValue.validationError(for: currency)
    }
}

// MARK: - Accessibility Context Enum

/// Context for accessibility formatting
public enum AccessibilityContext {
    case general
    case currency(SupportedCurrency)
    case percentage
    case count
    case ordinal
}

// MARK: - UI Integration Helpers

@available(iOS 18.6, macOS 15.6, *)
extension NSNumber {
    
    #if canImport(AppKit)
    /// Configure accessibility for an NSTextField displaying this number
    public func configureAccessibility(
        for textField: NSTextField,
        context: AccessibilityContext,
        audience: PrimaryAudience = .american
    ) {
        textField.setAccessibilityLabel(self.accessibilityLabel(context: context, audience: audience))
        textField.setAccessibilityHelp(self.accessibilityHint(context: context))
        textField.setAccessibilityRole(self.accessibilityRole(context: context))
        
        // Enable accessibility
        textField.setAccessibilityElement(true)
        
        // Set accessibility identifier for UI testing
        switch context {
        case .currency(let currency):
            textField.setAccessibilityIdentifier("currency_\(currency.rawValue)_\(self.stringValue)")
        case .percentage:
            textField.setAccessibilityIdentifier("percentage_\(self.stringValue)")
        case .count:
            textField.setAccessibilityIdentifier("count_\(self.stringValue)")
        case .ordinal:
            textField.setAccessibilityIdentifier("ordinal_\(self.stringValue)")
        case .general:
            textField.setAccessibilityIdentifier("number_\(self.stringValue)")
        }
    }
    #endif
}

#if canImport(AppKit)
import AppKit
#endif