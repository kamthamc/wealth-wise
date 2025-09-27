import Foundation
import AVFoundation

/// Accessibility-friendly number formatter for VoiceOver and screen readers
/// Provides clear, pronounceable number representations
@available(iOS 18.6, macOS 15.6, *)
public final class AccessibleNumberFormatter {
    
    // MARK: - Properties
    
    /// Current formatting configuration
    public var configuration: NumberFormatterConfiguration
    
    /// Localized number formatter for base formatting
    private let baseFormatter: LocalizedNumberFormatter
    
    /// Speech synthesizer for pronunciation testing (optional)
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - Initialization
    
    public init(configuration: NumberFormatterConfiguration) {
        self.configuration = configuration
        self.baseFormatter = LocalizedNumberFormatter(configuration: configuration)
    }
    
    // MARK: - Public Methods
    
    /// Format number with accessibility-friendly pronunciation
    public func accessibleString(from value: Decimal) -> String {
        let absValue = abs(value)
        let isNegative = value < 0
        
        // Handle special cases
        if value == 0 {
            return localizedZero()
        }
        
        let accessibleString: String
        
        if configuration.numberingSystem == .indian {
            accessibleString = indianAccessibleString(from: absValue)
        } else {
            accessibleString = westernAccessibleString(from: absValue)
        }
        
        return isNegative ? "\(localizedNegative()) \(accessibleString)" : accessibleString
    }
    
    /// Format currency with accessibility-friendly pronunciation
    public func accessibleCurrencyString(from value: Decimal, currency: SupportedCurrency) -> String {
        let numberPart = accessibleString(from: value)
        let currencyName = accessibleCurrencyName(for: currency)
        
        // Format: "25 dollars and 50 cents" or "1 lakh rupees"
        if currency.supportsFractionalUnits && configuration.maximumFractionDigits > 0 {
            return formatWithFractionalUnits(numberPart: numberPart, currency: currency, value: value)
        } else {
            return "\(numberPart) \(currencyName)"
        }
    }
    
    /// Get phonetic representation for speech synthesis
    public func phoneticString(from value: Decimal) -> String {
        let accessibleString = accessibleString(from: value)
        
        // Add phonetic markers for better pronunciation
        return addPhoneticMarkers(to: accessibleString)
    }
    
    /// Test pronunciation using speech synthesizer (for development/testing)
    public func testPronunciation(of value: Decimal, completion: @escaping (Bool) -> Void) {
        let accessibleString = accessibleString(from: value)
        let utterance = AVSpeechUtterance(string: accessibleString)
        utterance.voice = AVSpeechSynthesisVoice(language: configuration.localeIdentifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        speechSynthesizer.speak(utterance)
        completion(true)
    }
    
    // MARK: - Private Methods - Indian Numbering
    
    /// Format number using Indian numbering system (lakh/crore)
    private func indianAccessibleString(from value: Decimal) -> String {
        let absValue = abs(value)
        
        if absValue >= 10_000_000 { // 1 crore
            let crores = absValue / 10_000_000
            let croresPart = (absValue / 10_000_000)
            let croresRounded = NSDecimalNumber(decimal: croresPart).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).decimalValue
            let remainder = absValue - (croresRounded * 10_000_000)
            
            if remainder == 0 {
                return formatIndianUnit(crores, unit: localizedCrore(), isPlural: crores != 1)
            } else {
                let croresPart = formatIndianUnit(crores, unit: localizedCrore(), isPlural: crores != 1)
                let remainderPart = indianAccessibleString(from: remainder)
                return "\(croresPart) \(remainderPart)"
            }
        } else if absValue >= 100_000 { // 1 lakh
            let lakhs = absValue / 100_000
            let lakhsPart = (absValue / 100_000)
            let lakhsRounded = NSDecimalNumber(decimal: lakhsPart).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).decimalValue
            let remainder = absValue - (lakhsRounded * 100_000)
            
            if remainder == 0 {
                return formatIndianUnit(lakhs, unit: localizedLakh(), isPlural: lakhs != 1)
            } else {
                let lakhsPart = formatIndianUnit(lakhs, unit: localizedLakh(), isPlural: lakhs != 1)
                let remainderPart = indianAccessibleString(from: remainder)
                return "\(lakhsPart) \(remainderPart)"
            }
        } else if absValue >= 1000 { // 1 thousand
            let thousands = absValue / 1000
            let thousandsPart = (absValue / 1000)
            let thousandsRounded = NSDecimalNumber(decimal: thousandsPart).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).decimalValue
            let remainder = absValue - (thousandsRounded * 1000)
            
            if remainder == 0 {
                return formatIndianUnit(thousands, unit: localizedThousand(), isPlural: thousands != 1)
            } else {
                let thousandsPart = formatIndianUnit(thousands, unit: localizedThousand(), isPlural: thousands != 1)
                let remainderPart = indianAccessibleString(from: remainder)
                return "\(thousandsPart) \(remainderPart)"
            }
        } else {
            return formatBasicNumber(value)
        }
    }
    
    /// Format Indian unit with proper pluralization
    private func formatIndianUnit(_ value: Decimal, unit: String, isPlural: Bool) -> String {
        let numberPart = formatBasicNumber(value)
        return "\(numberPart) \(unit)"
    }
    
    // MARK: - Private Methods - Western Numbering
    
    /// Format number using Western numbering system (million/billion)
    private func westernAccessibleString(from value: Decimal) -> String {
        let absValue = abs(value)
        
        if absValue >= 1_000_000_000 { // 1 billion
            let billions = absValue / 1_000_000_000
            let billionsPart = (absValue / 1_000_000_000)
            let billionsRounded = NSDecimalNumber(decimal: billionsPart).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).decimalValue
            let remainder = absValue - (billionsRounded * 1_000_000_000)
            
            if remainder == 0 {
                return formatWesternUnit(billions, unit: localizedBillion(), isPlural: billions != 1)
            } else {
                let billionsPart = formatWesternUnit(billions, unit: localizedBillion(), isPlural: billions != 1)
                let remainderPart = westernAccessibleString(from: remainder)
                return "\(billionsPart) \(remainderPart)"
            }
        } else if absValue >= 1_000_000 { // 1 million
            let millions = absValue / 1_000_000
            let millionsPart = (absValue / 1_000_000)
            let millionsRounded = NSDecimalNumber(decimal: millionsPart).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).decimalValue
            let remainder = absValue - (millionsRounded * 1_000_000)
            
            if remainder == 0 {
                return formatWesternUnit(millions, unit: localizedMillion(), isPlural: millions != 1)
            } else {
                let millionsPart = formatWesternUnit(millions, unit: localizedMillion(), isPlural: millions != 1)
                let remainderPart = westernAccessibleString(from: remainder)
                return "\(millionsPart) \(remainderPart)"
            }
        } else if absValue >= 1000 { // 1 thousand
            let thousands = absValue / 1000
            let thousandsPart = (absValue / 1000)
            let thousandsRounded = NSDecimalNumber(decimal: thousandsPart).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)).decimalValue
            let remainder = absValue - (thousandsRounded * 1000)
            
            if remainder == 0 {
                return formatWesternUnit(thousands, unit: localizedThousand(), isPlural: thousands != 1)
            } else {
                let thousandsPart = formatWesternUnit(thousands, unit: localizedThousand(), isPlural: thousands != 1)
                let remainderPart = westernAccessibleString(from: remainder)
                return "\(thousandsPart) \(remainderPart)"
            }
        } else {
            return formatBasicNumber(value)
        }
    }
    
    /// Format Western unit with proper pluralization
    private func formatWesternUnit(_ value: Decimal, unit: String, isPlural: Bool) -> String {
        let numberPart = formatBasicNumber(value)
        return "\(numberPart) \(unit)"
    }
    
    // MARK: - Private Methods - Basic Formatting
    
    /// Format basic number without units
    private func formatBasicNumber(_ value: Decimal) -> String {
        // For accessibility, always speak out the full number without abbreviations
        let tempConfig = NumberFormatterConfiguration(
            numberingSystem: configuration.numberingSystem,
            audience: configuration.audience,
            minimumFractionDigits: configuration.minimumFractionDigits,
            maximumFractionDigits: configuration.maximumFractionDigits,
            usesGroupingSeparator: false, // No separators for accessibility
            useAbbreviation: false, // Never abbreviate for accessibility
            abbreviationThreshold: Decimal.greatestFiniteMagnitude,
            localeIdentifier: configuration.localeIdentifier,
            useAccessibilityFormatting: true
        )
        
        let formatter = LocalizedNumberFormatter(configuration: tempConfig)
        return formatter.string(from: value)
    }
    
    /// Format currency with fractional units
    private func formatWithFractionalUnits(numberPart: String, currency: SupportedCurrency, value: Decimal) -> String {
        let nsDecimal = NSDecimalNumber(decimal: value)
        let integerPart = nsDecimal.rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .down,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )).decimalValue
        let fractionalPart = (value - integerPart) * Decimal(currency.decimalPlaces == 2 ? 100 : 1000)
        
        let mainCurrencyName = accessibleCurrencyName(for: currency)
        let fractionalCurrencyName = accessibleFractionalCurrencyName(for: currency)
        
        if fractionalPart > 0 {
            let integerPartString = accessibleString(from: integerPart)
            let fractionalPartString = accessibleString(from: fractionalPart)
            return "\(integerPartString) \(mainCurrencyName) \(localizedAnd()) \(fractionalPartString) \(fractionalCurrencyName)"
        } else {
            return "\(numberPart) \(mainCurrencyName)"
        }
    }
    
    /// Add phonetic markers for better speech synthesis
    private func addPhoneticMarkers(to string: String) -> String {
        var phoneticString = string
        
        // Add pauses for better pronunciation
        phoneticString = phoneticString.replacingOccurrences(of: " ", with: " <break time=\"0.2s\"/> ")
        
        // Mark numbers for proper pronunciation
        phoneticString = phoneticString.replacingOccurrences(of: "0", with: "<phoneme ph=\"oʊ\">0</phoneme>")
        
        return phoneticString
    }
    
    // MARK: - Localized Strings
    
    private func localizedZero() -> String {
        return NSLocalizedString("number.zero", value: "zero", comment: "Accessibility: Zero")
    }
    
    private func localizedNegative() -> String {
        return NSLocalizedString("number.negative", value: "negative", comment: "Accessibility: Negative number prefix")
    }
    
    private func localizedAnd() -> String {
        return NSLocalizedString("number.and", value: "and", comment: "Accessibility: 'and' connector")
    }
    
    private func localizedThousand() -> String {
        return NSLocalizedString("number.thousand", value: "thousand", comment: "Accessibility: Thousand")
    }
    
    private func localizedLakh() -> String {
        return NSLocalizedString("number.lakh", value: "lakh", comment: "Accessibility: Indian lakh")
    }
    
    private func localizedCrore() -> String {
        return NSLocalizedString("number.crore", value: "crore", comment: "Accessibility: Indian crore")
    }
    
    private func localizedMillion() -> String {
        return NSLocalizedString("number.million", value: "million", comment: "Accessibility: Million")
    }
    
    private func localizedBillion() -> String {
        return NSLocalizedString("number.billion", value: "billion", comment: "Accessibility: Billion")
    }
    
    /// Get accessible currency name
    private func accessibleCurrencyName(for currency: SupportedCurrency) -> String {
        switch currency {
        case .INR:
            return NSLocalizedString("currency.inr.name", value: "rupees", comment: "Accessibility: Indian Rupees")
        case .USD:
            return NSLocalizedString("currency.usd.name", value: "dollars", comment: "Accessibility: US Dollars")
        case .EUR:
            return NSLocalizedString("currency.eur.name", value: "euros", comment: "Accessibility: Euros")
        case .GBP:
            return NSLocalizedString("currency.gbp.name", value: "pounds", comment: "Accessibility: British Pounds")
        case .JPY:
            return NSLocalizedString("currency.jpy.name", value: "yen", comment: "Accessibility: Japanese Yen")
        default:
            return currency.displayName.lowercased()
        }
    }
    
    /// Get accessible fractional currency name
    private func accessibleFractionalCurrencyName(for currency: SupportedCurrency) -> String {
        switch currency {
        case .INR:
            return NSLocalizedString("currency.inr.fractional", value: "paise", comment: "Accessibility: Indian Paise")
        case .USD:
            return NSLocalizedString("currency.usd.fractional", value: "cents", comment: "Accessibility: US Cents")
        case .EUR:
            return NSLocalizedString("currency.eur.fractional", value: "cents", comment: "Accessibility: Euro Cents")
        case .GBP:
            return NSLocalizedString("currency.gbp.fractional", value: "pence", comment: "Accessibility: British Pence")
        case .JPY:
            return "" // Yen doesn't have fractional units in common usage
        default:
            return NSLocalizedString("currency.fractional.generic", value: "cents", comment: "Accessibility: Generic fractional currency")
        }
    }
}

// MARK: - Convenience Factory Methods

@available(iOS 18.6, macOS 15.6, *)
extension AccessibleNumberFormatter {
    
    /// Create accessibility formatter for Indian audience
    public static func indianAccessibilityFormatter() -> AccessibleNumberFormatter {
        let config = NumberFormatterConfiguration.accessibilityConfiguration(for: .indian)
        return AccessibleNumberFormatter(configuration: config)
    }
    
    /// Create accessibility formatter for American audience
    public static func americanAccessibilityFormatter() -> AccessibleNumberFormatter {
        let config = NumberFormatterConfiguration.accessibilityConfiguration(for: .american)
        return AccessibleNumberFormatter(configuration: config)
    }
    
    /// Create accessibility formatter for specific audience
    public static func accessibilityFormatter(for audience: PrimaryAudience) -> AccessibleNumberFormatter {
        let config = NumberFormatterConfiguration.accessibilityConfiguration(for: audience)
        return AccessibleNumberFormatter(configuration: config)
    }
}

