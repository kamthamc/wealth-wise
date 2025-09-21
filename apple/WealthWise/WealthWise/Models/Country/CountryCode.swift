import Foundation

// Import the Currency models to resolve SupportedCurrency reference

/// ISO 3166-1 alpha-3 country codes with flag emojis and display names
/// Supporting countries relevant to WealthWise users with cross-border assets
public enum CountryCode: String, CaseIterable, Codable, Hashable {
    // Primary Markets
    case IND = "IND"  // India
    case USA = "USA"  // United States
    case GBR = "GBR"  // United Kingdom
    case CAN = "CAN"  // Canada
    case AUS = "AUS"  // Australia
    case SGP = "SGP"  // Singapore
    
    // European Union & Europe
    case DEU = "DEU"  // Germany
    case FRA = "FRA"  // France
    case NLD = "NLD"  // Netherlands
    case CHE = "CHE"  // Switzerland
    case IRL = "IRL"  // Ireland
    case LUX = "LUX"  // Luxembourg
    
    // Asia-Pacific
    case JPN = "JPN"  // Japan
    case HKG = "HKG"  // Hong Kong
    case NZL = "NZL"  // New Zealand
    case MYS = "MYS"  // Malaysia
    case THA = "THA"  // Thailand
    case PHL = "PHL"  // Philippines
    
    // Middle East
    case ARE = "ARE"  // United Arab Emirates
    case QAT = "QAT"  // Qatar
    case SAU = "SAU"  // Saudi Arabia
    
    // Americas
    case BRA = "BRA"  // Brazil
    case MEX = "MEX"  // Mexico
    
    /// Display name for the country in English
    public var displayName: String {
        switch self {
        case .IND: return "India"
        case .USA: return "United States"
        case .GBR: return "United Kingdom"
        case .CAN: return "Canada"
        case .AUS: return "Australia"
        case .SGP: return "Singapore"
        case .DEU: return "Germany"
        case .FRA: return "France"
        case .NLD: return "Netherlands"
        case .CHE: return "Switzerland"
        case .IRL: return "Ireland"
        case .LUX: return "Luxembourg"
        case .JPN: return "Japan"
        case .HKG: return "Hong Kong"
        case .NZL: return "New Zealand"
        case .MYS: return "Malaysia"
        case .THA: return "Thailand"
        case .PHL: return "Philippines"
        case .ARE: return "United Arab Emirates"
        case .QAT: return "Qatar"
        case .SAU: return "Saudi Arabia"
        case .BRA: return "Brazil"
        case .MEX: return "Mexico"
        }
    }
    
    /// Flag emoji for the country
    public var flagEmoji: String {
        switch self {
        case .IND: return "🇮🇳"
        case .USA: return "🇺🇸"
        case .GBR: return "🇬🇧"
        case .CAN: return "🇨🇦"
        case .AUS: return "🇦🇺"
        case .SGP: return "🇸🇬"
        case .DEU: return "🇩🇪"
        case .FRA: return "🇫🇷"
        case .NLD: return "🇳🇱"
        case .CHE: return "🇨🇭"
        case .IRL: return "🇮🇪"
        case .LUX: return "🇱🇺"
        case .JPN: return "🇯🇵"
        case .HKG: return "🇭🇰"
        case .NZL: return "🇳🇿"
        case .MYS: return "🇲🇾"
        case .THA: return "🇹🇭"
        case .PHL: return "🇵🇭"
        case .ARE: return "🇦🇪"
        case .QAT: return "🇶🇦"
        case .SAU: return "🇸🇦"
        case .BRA: return "🇧🇷"
        case .MEX: return "🇲🇽"
        }
    }
    
    /// ISO 3166-1 alpha-2 country code
    public var alpha2Code: String {
        switch self {
        case .IND: return "IN"
        case .USA: return "US"
        case .GBR: return "GB"
        case .CAN: return "CA"
        case .AUS: return "AU"
        case .SGP: return "SG"
        case .DEU: return "DE"
        case .FRA: return "FR"
        case .NLD: return "NL"
        case .CHE: return "CH"
        case .IRL: return "IE"
        case .LUX: return "LU"
        case .JPN: return "JP"
        case .HKG: return "HK"
        case .NZL: return "NZ"
        case .MYS: return "MY"
        case .THA: return "TH"
        case .PHL: return "PH"
        case .ARE: return "AE"
        case .QAT: return "QA"
        case .SAU: return "SA"
        case .BRA: return "BR"
        case .MEX: return "MX"
        }
    }
    
    /// Primary currency code used in this country
    public var primaryCurrencyCode: String {
        switch self {
        case .IND: return "INR"
        case .USA: return "USD"
        case .GBR: return "GBP"
        case .CAN: return "CAD"
        case .AUS: return "AUD"
        case .SGP: return "SGD"
        case .DEU, .FRA, .NLD, .IRL, .LUX: return "EUR"
        case .CHE: return "CHF"
        case .JPN: return "JPY"
        case .HKG: return "HKD"
        case .NZL: return "NZD"
        case .MYS: return "MYR"
        case .THA: return "THB"
        case .PHL: return "PHP"
        case .ARE, .QAT, .SAU: return "USD"  // Often USD pegged
        case .BRA: return "BRL"
        case .MEX: return "MXN"
        }
    }
    
    /// Time zone identifier for the country's main financial center
    public var primaryTimeZone: String {
        switch self {
        case .IND: return "Asia/Kolkata"
        case .USA: return "America/New_York"  // EST/EDT for financial markets
        case .GBR: return "Europe/London"
        case .CAN: return "America/Toronto"
        case .AUS: return "Australia/Sydney"
        case .SGP: return "Asia/Singapore"
        case .DEU: return "Europe/Berlin"
        case .FRA: return "Europe/Paris"
        case .NLD: return "Europe/Amsterdam"
        case .CHE: return "Europe/Zurich"
        case .IRL: return "Europe/Dublin"
        case .LUX: return "Europe/Luxembourg"
        case .JPN: return "Asia/Tokyo"
        case .HKG: return "Asia/Hong_Kong"
        case .NZL: return "Pacific/Auckland"
        case .MYS: return "Asia/Kuala_Lumpur"
        case .THA: return "Asia/Bangkok"
        case .PHL: return "Asia/Manila"
        case .ARE: return "Asia/Dubai"
        case .QAT: return "Asia/Qatar"
        case .SAU: return "Asia/Riyadh"
        case .BRA: return "America/Sao_Paulo"
        case .MEX: return "America/Mexico_City"
        }
    }
    
    /// Financial year start month (1 = January, 4 = April, etc.)
    public var financialYearStartMonth: Int {
        switch self {
        case .IND: return 4  // April 1st
        case .AUS, .NZL: return 7  // July 1st
        case .JPN: return 4  // April 1st
        case .THA: return 10  // October 1st
        default: return 1  // January 1st (most countries)
        }
    }
    
    /// Whether the country uses right-to-left text direction
    public var isRTL: Bool {
        switch self {
        case .ARE, .QAT, .SAU: return true
        default: return false
        }
    }
    
    /// Major languages spoken in this country (ISO 639-1 codes)
    public var primaryLanguages: [String] {
        switch self {
        case .IND: return ["hi", "en", "ta", "te", "bn", "gu", "kn", "ml", "mr"]
        case .USA: return ["en", "es"]
        case .GBR: return ["en"]
        case .CAN: return ["en", "fr"]
        case .AUS, .NZL: return ["en"]
        case .SGP: return ["en", "zh", "ms", "ta"]
        case .DEU: return ["de"]
        case .FRA: return ["fr"]
        case .NLD: return ["nl"]
        case .CHE: return ["de", "fr", "it", "rm"]
        case .IRL: return ["en", "ga"]
        case .LUX: return ["lb", "fr", "de"]
        case .JPN: return ["ja"]
        case .HKG: return ["zh", "en"]
        case .MYS: return ["ms", "en", "zh", "ta"]
        case .THA: return ["th", "en"]
        case .PHL: return ["en", "tl"]
        case .ARE, .QAT, .SAU: return ["ar", "en"]
        case .BRA: return ["pt"]
        case .MEX: return ["es"]
        }
    }
    
    /// Countries with significant expat populations from India
    public static var popularExpatDestinations: [CountryCode] {
        return [.USA, .GBR, .CAN, .AUS, .SGP, .ARE, .DEU, .NLD]
    }
    
    /// Countries in the European Union (for regulatory purposes)
    public static var europeanUnion: [CountryCode] {
        return [.DEU, .FRA, .NLD, .IRL, .LUX]
    }
    
    /// Initialize from ISO alpha-2 code
    public init?(alpha2: String) {
        let alpha2Upper = alpha2.uppercased()
        for country in CountryCode.allCases {
            if country.alpha2Code == alpha2Upper {
                self = country
                return
            }
        }
        return nil
    }
    
    /// Initialize from current device locale
    public static var current: CountryCode {
        guard let regionCode = Locale.current.region?.identifier,
              let country = CountryCode(alpha2: regionCode) else {
            return .USA  // Default fallback
        }
        return country
    }
}

// MARK: - Comparable
extension CountryCode: Comparable {
    public static func < (lhs: CountryCode, rhs: CountryCode) -> Bool {
        lhs.displayName < rhs.displayName
    }
}

// MARK: - CustomStringConvertible
extension CountryCode: CustomStringConvertible {
    public var description: String {
        "\(flagEmoji) \(displayName)"
    }
}