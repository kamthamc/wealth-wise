import Foundation

/// Rounding mode for number formatting (Codable version)
public enum FormatterRoundingMode: String, CaseIterable, Codable, Hashable {
    case ceiling = "ceiling"
    case floor = "floor"
    case down = "down"
    case up = "up"
    case halfEven = "halfEven"
    case halfDown = "halfDown"
    case halfUp = "halfUp"
    
    /// Convert to NumberFormatter.RoundingMode
    var numberFormatterRoundingMode: NumberFormatter.RoundingMode {
        switch self {
        case .ceiling: return .ceiling
        case .floor: return .floor
        case .down: return .down
        case .up: return .up
        case .halfEven: return .halfEven
        case .halfDown: return .halfDown
        case .halfUp: return .halfUp
        }
    }
    
    /// Create from NumberFormatter.RoundingMode
    init(from roundingMode: NumberFormatter.RoundingMode) {
        switch roundingMode {
        case .ceiling: self = .ceiling
        case .floor: self = .floor
        case .down: self = .down
        case .up: self = .up
        case .halfEven: self = .halfEven
        case .halfDown: self = .halfDown
        case .halfUp: self = .halfUp
        @unknown default: self = .halfUp
        }
    }
}

/// Configuration for localized number formatting
/// Provides centralized control over number format settings
public struct NumberFormatterConfiguration: Codable, Hashable {
    
    // MARK: - Properties
    
    /// Cultural numbering system to use
    public let numberingSystem: CulturalNumberingSystem
    
    /// Primary audience for cultural adaptation
    public let audience: PrimaryAudience
    
    /// Minimum number of fraction digits
    public let minimumFractionDigits: Int
    
    /// Maximum number of fraction digits
    public let maximumFractionDigits: Int
    
    /// Whether to use grouping separators (e.g., commas)
    public let usesGroupingSeparator: Bool
    
    /// Whether to use abbreviated format for large numbers
    public let useAbbreviation: Bool
    
    /// Abbreviation threshold (numbers above this will be abbreviated)
    public let abbreviationThreshold: Decimal
    
    /// Locale identifier for number formatting
    public let localeIdentifier: String
    
    /// Whether to use accessibility-friendly formatting
    public let useAccessibilityFormatting: Bool
    
    /// Rounding mode for number formatting
    public let roundingMode: FormatterRoundingMode
    
    // MARK: - Initialization
    
    public init(
        numberingSystem: CulturalNumberingSystem = .western,
        audience: PrimaryAudience = .american,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 2,
        usesGroupingSeparator: Bool = true,
        useAbbreviation: Bool = false,
        abbreviationThreshold: Decimal = 1000,
        localeIdentifier: String? = nil,
        useAccessibilityFormatting: Bool = false,
        roundingMode: FormatterRoundingMode = .halfUp
    ) {
        self.numberingSystem = numberingSystem
        self.audience = audience
        self.minimumFractionDigits = minimumFractionDigits
        self.maximumFractionDigits = maximumFractionDigits
        self.usesGroupingSeparator = usesGroupingSeparator
        self.useAbbreviation = useAbbreviation
        self.abbreviationThreshold = abbreviationThreshold
        self.localeIdentifier = localeIdentifier ?? audience.preferredLocale.identifier
        self.useAccessibilityFormatting = useAccessibilityFormatting
        self.roundingMode = roundingMode
    }
    
    // MARK: - Predefined Configurations
    
    /// Standard configuration for Indian audience
    public static let indian = NumberFormatterConfiguration(
        numberingSystem: .indian,
        audience: .indian,
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
        usesGroupingSeparator: true,
        useAbbreviation: false,
        abbreviationThreshold: 100_000, // 1 lakh
        localeIdentifier: "en_IN"
    )
    
    /// Abbreviated configuration for Indian audience  
    public static let indianAbbreviated = NumberFormatterConfiguration(
        numberingSystem: .indian,
        audience: .indian,
        minimumFractionDigits: 0,
        maximumFractionDigits: 1,
        usesGroupingSeparator: false,
        useAbbreviation: true,
        abbreviationThreshold: 100_000, // 1 lakh
        localeIdentifier: "en_IN"
    )
    
    /// Standard configuration for American audience
    public static let american = NumberFormatterConfiguration(
        numberingSystem: .western,
        audience: .american,
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
        usesGroupingSeparator: true,
        useAbbreviation: false,
        abbreviationThreshold: 1_000_000, // 1 million
        localeIdentifier: "en_US"
    )
    
    /// Abbreviated configuration for American audience
    public static let americanAbbreviated = NumberFormatterConfiguration(
        numberingSystem: .western,
        audience: .american,
        minimumFractionDigits: 0,
        maximumFractionDigits: 1,
        usesGroupingSeparator: false,
        useAbbreviation: true,
        abbreviationThreshold: 1_000_000, // 1 million
        localeIdentifier: "en_US"
    )
    
    /// Standard configuration for British audience
    public static let british = NumberFormatterConfiguration(
        numberingSystem: .british,
        audience: .british,
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
        usesGroupingSeparator: true,
        useAbbreviation: false,
        abbreviationThreshold: 1_000_000, // 1 million
        localeIdentifier: "en_GB"
    )
    
    /// European configuration
    public static let european = NumberFormatterConfiguration(
        numberingSystem: .european,
        audience: .german,
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
        usesGroupingSeparator: true,
        useAbbreviation: false,
        abbreviationThreshold: 1_000_000, // 1 million
        localeIdentifier: "de_DE"
    )
    
    /// Accessibility-optimized configuration
    public static let accessibility = NumberFormatterConfiguration(
        numberingSystem: .western,
        audience: .american,
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
        usesGroupingSeparator: true,
        useAbbreviation: false,
        abbreviationThreshold: Decimal.greatestFiniteMagnitude,
        localeIdentifier: "en_US",
        useAccessibilityFormatting: true
    )
    
    // MARK: - Factory Methods
    
    /// Create configuration for specific audience
    public static func forAudience(_ audience: PrimaryAudience, abbreviated: Bool = false) -> NumberFormatterConfiguration {
        let numberingSystem = CulturalNumberingSystem.forAudience(audience)
        
        return NumberFormatterConfiguration(
            numberingSystem: numberingSystem,
            audience: audience,
            minimumFractionDigits: 0,
            maximumFractionDigits: abbreviated ? 1 : 2,
            usesGroupingSeparator: !abbreviated,
            useAbbreviation: abbreviated,
            abbreviationThreshold: numberingSystem == .indian ? 100_000 : 1_000_000,
            localeIdentifier: audience.preferredLocale.identifier
        )
    }
    
    /// Create accessibility configuration for specific audience
    public static func accessibilityConfiguration(for audience: PrimaryAudience) -> NumberFormatterConfiguration {
        return NumberFormatterConfiguration (
            numberingSystem: CulturalNumberingSystem.forAudience(audience),
            audience: audience,
            minimumFractionDigits: 0,
            maximumFractionDigits: 2,
            usesGroupingSeparator: true,
            useAbbreviation: false,
            abbreviationThreshold: Decimal.greatestFiniteMagnitude,
            localeIdentifier: audience.preferredLocale.identifier,
            useAccessibilityFormatting: true
        )
    }
}

// MARK: - PrimaryAudience Extension

extension PrimaryAudience {
    /// Get preferred locale for the audience
    var preferredLocale: Locale {
        switch self {
        case .indian:
            return Locale(identifier: "en_IN")
        case .american:
            return Locale(identifier: "en_US")
        case .british:
            return Locale(identifier: "en_GB")
        case .canadian:
            return Locale(identifier: "en_CA")
        case .australian:
            return Locale(identifier: "en_AU")
        case .singaporean:
            return Locale(identifier: "en_SG")
        case .german:
            return Locale(identifier: "de_DE")
        case .french:
            return Locale(identifier: "fr_FR")
        case .dutch:
            return Locale(identifier: "nl_NL")
        case .swiss:
            return Locale(identifier: "de_CH")
        case .irish:
            return Locale(identifier: "en_IE")
        case .luxembourgish:
            return Locale(identifier: "lb_LU")
        case .japanese:
            return Locale(identifier: "ja_JP")
        case .hongKongese:
            return Locale(identifier: "zh_HK")
        case .newZealander:
            return Locale(identifier: "en_NZ")
        case .malaysian:
            return Locale(identifier: "ms_MY")
        case .thai:
            return Locale(identifier: "th_TH")
        case .filipino:
            return Locale(identifier: "en_PH")
        case .emirati:
            return Locale(identifier: "ar_AE")
        case .qatari:
            return Locale(identifier: "ar_QA")
        case .saudi:
            return Locale(identifier: "ar_SA")
        case .brazilian:
            return Locale(identifier: "pt_BR")
        case .mexican:
            return Locale(identifier: "es_MX")
        }
    }
}