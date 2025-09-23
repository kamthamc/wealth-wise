import Foundation

/// Supported currencies in the WealthWise application
/// Prioritizes Indian Rupee and major international currencies
public enum SupportedCurrency: String, CaseIterable, Codable {
    case INR = "INR"  // Indian Rupee (Primary)
    case USD = "USD"  // US Dollar
    case EUR = "EUR"  // Euro
    case GBP = "GBP"  // British Pound Sterling
    case JPY = "JPY"  // Japanese Yen
    case CAD = "CAD"  // Canadian Dollar
    case AUD = "AUD"  // Australian Dollar
    case CHF = "CHF"  // Swiss Franc
    case CNY = "CNY"  // Chinese Yuan
    case SGD = "SGD"  // Singapore Dollar
    case HKD = "HKD"  // Hong Kong Dollar
    case NZD = "NZD"  // New Zealand Dollar
    case SEK = "SEK"  // Swedish Krona
    case NOK = "NOK"  // Norwegian Krone
    case DKK = "DKK"  // Danish Krone
    case PLN = "PLN"  // Polish Zloty
    case CZK = "CZK"  // Czech Koruna
    case HUF = "HUF"  // Hungarian Forint
    case RUB = "RUB"  // Russian Ruble
    case BRL = "BRL"  // Brazilian Real
    case KRW = "KRW"  // South Korean Won
    case MXN = "MXN"  // Mexican Peso
    case MYR = "MYR"  // Malaysian Ringgit
    case ZAR = "ZAR"  // South African Rand
    
    /// Default currency (Indian Rupee for Indian market focus)
    public static let `default`: SupportedCurrency = .INR
    
    /// Currency display name
    public var displayName: String {
        switch self {
        case .INR: return "Indian Rupee"
        case .USD: return "US Dollar"
        case .EUR: return "Euro"
        case .GBP: return "British Pound Sterling"
        case .JPY: return "Japanese Yen"
        case .CAD: return "Canadian Dollar"
        case .AUD: return "Australian Dollar"
        case .CHF: return "Swiss Franc"
        case .CNY: return "Chinese Yuan"
        case .SGD: return "Singapore Dollar"
        case .HKD: return "Hong Kong Dollar"
        case .NZD: return "New Zealand Dollar"
        case .SEK: return "Swedish Krona"
        case .NOK: return "Norwegian Krone"
        case .DKK: return "Danish Krone"
        case .PLN: return "Polish Zloty"
        case .CZK: return "Czech Koruna"
        case .HUF: return "Hungarian Forint"
        case .RUB: return "Russian Ruble"
        case .BRL: return "Brazilian Real"
        case .KRW: return "South Korean Won"
        case .MXN: return "Mexican Peso"
        case .MYR: return "Malaysian Ringgit"
        case .ZAR: return "South African Rand"
        }
    }
    
    /// Currency symbol
    public var symbol: String {
        switch self {
        case .INR: return "₹"
        case .USD: return "$"
        case .EUR: return "€"
        case .GBP: return "£"
        case .JPY: return "¥"
        case .CAD: return "C$"
        case .AUD: return "A$"
        case .CHF: return "CHF"
        case .CNY: return "¥"
        case .SGD: return "S$"
        case .HKD: return "HK$"
        case .NZD: return "NZ$"
        case .SEK: return "kr"
        case .NOK: return "kr"
        case .DKK: return "kr"
        case .PLN: return "zł"
        case .CZK: return "Kč"
        case .HUF: return "Ft"
        case .RUB: return "₽"
        case .BRL: return "R$"
        case .KRW: return "₩"
        case .MXN: return "$"
        case .MYR: return "RM"
        case .ZAR: return "R"
        }
    }
    
    
    /// Major currencies for priority display
    public static var majorCurrencies: [SupportedCurrency] {
        return [.INR, .USD, .EUR, .GBP, .JPY, .CAD, .AUD, .CHF]
    }
    
    /// Check if currency supports fractional units
    public var supportsFractionalUnits: Bool {
        return decimalPlaces > 0
    }
    
    /// Locale identifier for formatting
    public var localeIdentifier: String {
        switch self {
        case .INR: return "en_IN"
        case .USD: return "en_US"
        case .EUR: return "en_EU"
        case .GBP: return "en_GB"
        case .JPY: return "ja_JP"
        case .CAD: return "en_CA"
        case .AUD: return "en_AU"
        case .CHF: return "de_CH"
        case .CNY: return "zh_CN"
        case .SGD: return "en_SG"
        case .HKD: return "zh_HK"
        case .NZD: return "en_NZ"
        case .SEK: return "sv_SE"
        case .NOK: return "nb_NO"
        case .DKK: return "da_DK"
        case .PLN: return "pl_PL"
        case .CZK: return "cs_CZ"
        case .HUF: return "hu_HU"
        case .RUB: return "ru_RU"
        case .BRL: return "pt_BR"
        case .KRW: return "ko_KR"
        case .MXN: return "es_MX"
        case .MYR: return "ms_MY"
        case .ZAR: return "en_ZA"
        }
    }
}
