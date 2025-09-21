import Foundation

/// Comprehensive enumeration of supported currencies with localization and formatting support
public enum SupportedCurrency: String, CaseIterable, Codable, Identifiable {
    // Major Global Currencies
    case usd = "USD"  // US Dollar
    case eur = "EUR"  // Euro
    case gbp = "GBP"  // British Pound
    case jpy = "JPY"  // Japanese Yen
    case chf = "CHF"  // Swiss Franc
    
    // Asia-Pacific Currencies
    case inr = "INR"  // Indian Rupee
    case cny = "CNY"  // Chinese Yuan
    case hkd = "HKD"  // Hong Kong Dollar
    case sgd = "SGD"  // Singapore Dollar
    case aud = "AUD"  // Australian Dollar
    case nzd = "NZD"  // New Zealand Dollar
    case krw = "KRW"  // South Korean Won
    case thb = "THB"  // Thai Baht
    case myr = "MYR"  // Malaysian Ringgit
    case php = "PHP"  // Philippine Peso
    
    // Other Major Currencies
    case cad = "CAD"  // Canadian Dollar
    case brl = "BRL"  // Brazilian Real
    case rub = "RUB"  // Russian Ruble
    case zar = "ZAR"  // South African Rand
    case aed = "AED"  // UAE Dirham
    case sar = "SAR"  // Saudi Riyal
    
    public var id: String { rawValue }
    
    /// Currency symbol for display
    public var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .chf: return "Fr"
        case .inr: return "₹"
        case .cny: return "¥"
        case .hkd: return "HK$"
        case .sgd: return "S$"
        case .aud: return "A$"
        case .nzd: return "NZ$"
        case .krw: return "₩"
        case .thb: return "฿"
        case .myr: return "RM"
        case .php: return "₱"
        case .cad: return "C$"
        case .brl: return "R$"
        case .rub: return "₽"
        case .zar: return "R"
        case .aed: return "د.إ"
        case .sar: return "ر.س"
        }
    }
    
    /// Number of decimal places for this currency
    public var decimalPlaces: Int {
        switch self {
        case .jpy, .krw: return 0  // Currencies without fractional units
        default: return 2
        }
    }
    
    /// Localized display name
    public var displayName: String {
        switch self {
        case .usd: return NSLocalizedString("currency.usd", value: "US Dollar", comment: "US Dollar currency name")
        case .eur: return NSLocalizedString("currency.eur", value: "Euro", comment: "Euro currency name")
        case .gbp: return NSLocalizedString("currency.gbp", value: "British Pound", comment: "British Pound currency name")
        case .jpy: return NSLocalizedString("currency.jpy", value: "Japanese Yen", comment: "Japanese Yen currency name")
        case .chf: return NSLocalizedString("currency.chf", value: "Swiss Franc", comment: "Swiss Franc currency name")
        case .inr: return NSLocalizedString("currency.inr", value: "Indian Rupee", comment: "Indian Rupee currency name")
        case .cny: return NSLocalizedString("currency.cny", value: "Chinese Yuan", comment: "Chinese Yuan currency name")
        case .hkd: return NSLocalizedString("currency.hkd", value: "Hong Kong Dollar", comment: "Hong Kong Dollar currency name")
        case .sgd: return NSLocalizedString("currency.sgd", value: "Singapore Dollar", comment: "Singapore Dollar currency name")
        case .aud: return NSLocalizedString("currency.aud", value: "Australian Dollar", comment: "Australian Dollar currency name")
        case .nzd: return NSLocalizedString("currency.nzd", value: "New Zealand Dollar", comment: "New Zealand Dollar currency name")
        case .krw: return NSLocalizedString("currency.krw", value: "South Korean Won", comment: "South Korean Won currency name")
        case .thb: return NSLocalizedString("currency.thb", value: "Thai Baht", comment: "Thai Baht currency name")
        case .myr: return NSLocalizedString("currency.myr", value: "Malaysian Ringgit", comment: "Malaysian Ringgit currency name")
        case .php: return NSLocalizedString("currency.php", value: "Philippine Peso", comment: "Philippine Peso currency name")
        case .cad: return NSLocalizedString("currency.cad", value: "Canadian Dollar", comment: "Canadian Dollar currency name")
        case .brl: return NSLocalizedString("currency.brl", value: "Brazilian Real", comment: "Brazilian Real currency name")
        case .rub: return NSLocalizedString("currency.rub", value: "Russian Ruble", comment: "Russian Ruble currency name")
        case .zar: return NSLocalizedString("currency.zar", value: "South African Rand", comment: "South African Rand currency name")
        case .aed: return NSLocalizedString("currency.aed", value: "UAE Dirham", comment: "UAE Dirham currency name")
        case .sar: return NSLocalizedString("currency.sar", value: "Saudi Riyal", comment: "Saudi Riyal currency name")
        }
    }
    
    /// Flag emoji for the primary country using this currency
    public var flagEmoji: String {
        switch self {
        case .usd: return "🇺🇸"
        case .eur: return "🇪🇺"
        case .gbp: return "🇬🇧"
        case .jpy: return "🇯🇵"
        case .chf: return "🇨🇭"
        case .inr: return "🇮🇳"
        case .cny: return "🇨🇳"
        case .hkd: return "🇭🇰"
        case .sgd: return "🇸🇬"
        case .aud: return "🇦🇺"
        case .nzd: return "🇳🇿"
        case .krw: return "🇰🇷"
        case .thb: return "🇹🇭"
        case .myr: return "🇲🇾"
        case .php: return "🇵🇭"
        case .cad: return "🇨🇦"
        case .brl: return "🇧🇷"
        case .rub: return "🇷🇺"
        case .zar: return "🇿🇦"
        case .aed: return "🇦🇪"
        case .sar: return "🇸🇦"
        }
    }
    
    /// Primary region where this currency is used
    public var primaryRegion: String {
        switch self {
        case .usd: return "US"
        case .eur: return "EU"
        case .gbp: return "GB"
        case .jpy: return "JP"
        case .chf: return "CH"
        case .inr: return "IN"
        case .cny: return "CN"
        case .hkd: return "HK"
        case .sgd: return "SG"
        case .aud: return "AU"
        case .nzd: return "NZ"
        case .krw: return "KR"
        case .thb: return "TH"
        case .myr: return "MY"
        case .php: return "PH"
        case .cad: return "CA"
        case .brl: return "BR"
        case .rub: return "RU"
        case .zar: return "ZA"
        case .aed: return "AE"
        case .sar: return "SA"
        }
    }
    
    /// Whether this currency typically uses a comma as decimal separator
    public var usesCommaAsDecimalSeparator: Bool {
        switch self {
        case .eur, .brl: return true
        default: return false
        }
    }
    
    /// Whether this currency uses Indian numbering system (lakh/crore)
    public var usesIndianNumberingSystem: Bool {
        return self == .inr
    }
    
    /// Locale for this currency
    public var locale: Locale {
        return Locale(identifier: "\(Locale.current.language.languageCode?.identifier ?? "en")_\(primaryRegion)")
    }
}

// MARK: - Accessibility Support
extension SupportedCurrency {
    /// Accessibility label for VoiceOver
    public var accessibilityLabel: String {
        return "\(displayName) (\(symbol))"
    }
    
    /// Accessibility hint for currency selection
    public var accessibilityHint: String {
        return NSLocalizedString("currency.accessibility.hint", 
                                value: "Select \(displayName) as currency", 
                                comment: "Accessibility hint for currency selection")
    }
}

// MARK: - Sorting and Grouping
extension SupportedCurrency {
    /// Returns currencies sorted by popularity/usage
    public static var sortedByPopularity: [SupportedCurrency] {
        return [
            .usd, .eur, .gbp, .inr, .cny, .jpy, .cad, .aud, .chf, .sgd,
            .hkd, .nzd, .krw, .myr, .thb, .php, .brl, .rub, .zar, .aed, .sar
        ]
    }
    
    /// Returns currencies grouped by region
    public static var groupedByRegion: [String: [SupportedCurrency]] {
        return [
            "North America": [.usd, .cad],
            "Europe": [.eur, .gbp, .chf, .rub],
            "Asia": [.inr, .cny, .jpy, .hkd, .sgd, .krw, .thb, .myr, .php],
            "Oceania": [.aud, .nzd],
            "South America": [.brl],
            "Africa": [.zar],
            "Middle East": [.aed, .sar]
        ]
    }
    
    /// Returns major world currencies
    public static var majorCurrencies: [SupportedCurrency] {
        return [.usd, .eur, .gbp, .jpy, .inr, .cny, .cad, .aud, .chf]
    }
}

// MARK: - Currency Pair Support
public struct CurrencyPair: Hashable, Codable {
    public let from: SupportedCurrency
    public let to: SupportedCurrency
    
    public init(from: SupportedCurrency, to: SupportedCurrency) {
        self.from = from
        self.to = to
    }
    
    /// Reversed currency pair
    public var reversed: CurrencyPair {
        return CurrencyPair(from: to, to: from)
    }
    
    /// String representation for API calls
    public var pairString: String {
        return "\(from.rawValue)\(to.rawValue)"
    }
    
    /// Display string for UI
    public var displayString: String {
        return "\(from.rawValue) → \(to.rawValue)"
    }
}

// MARK: - Historical Context
extension SupportedCurrency {
    /// Whether this is a cryptocurrency (for future crypto support)
    public var isCryptocurrency: Bool {
        return false // Will be extended when crypto support is added
    }
    
    /// Whether this currency is considered stable
    public var isStableCurrency: Bool {
        switch self {
        case .usd, .eur, .gbp, .chf, .jpy, .cad, .aud, .sgd:
            return true
        default:
            return false
        }
    }
    
    /// Typical volatility level
    public enum VolatilityLevel {
        case low, medium, high
    }
    
    public var volatilityLevel: VolatilityLevel {
        switch self {
        case .usd, .eur, .gbp, .chf, .jpy:
            return .low
        case .cad, .aud, .sgd, .inr, .cny:
            return .medium
        default:
            return .high
        }
    }
}