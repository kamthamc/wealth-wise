import Foundation

/// Handles currency formatting for display
public class CurrencyFormatter {
    
    // MARK: - Singleton
    public static let shared = CurrencyFormatter()
    
    // MARK: - Private Properties
    private let numberFormatter = NumberFormatter()
    private var formatters: [String: NumberFormatter] = [:]
    
    // MARK: - Initialization
    private init() {
        setupDefaultFormatter()
    }
    
    // MARK: - Public Methods
    
    /// Format amount with currency symbol
    public func format(_ amount: Decimal, currency: SupportedCurrency, locale: Locale? = nil) -> String {
        let formatter = getFormatter(for: currency, locale: locale)
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
    }
    
    /// Format amount with currency symbol (Double version)
    public func format(_ amount: Double, currency: SupportedCurrency, locale: Locale? = nil) -> String {
        return format(Decimal(amount), currency: currency, locale: locale)
    }
    
    /// Format amount without currency symbol
    public func formatValue(_ amount: Decimal, currency: SupportedCurrency, locale: Locale? = nil) -> String {
        let formatter = getValueFormatter(for: currency, locale: locale)
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
    }
    
    /// Format amount without currency symbol (Double version)
    public func formatValue(_ amount: Double, currency: SupportedCurrency, locale: Locale? = nil) -> String {
        return formatValue(Decimal(amount), currency: currency, locale: locale)
    }
    
    /// Format amount with custom style
    public func format(_ amount: Decimal, 
                      currency: SupportedCurrency,
                      style: NumberFormatter.Style = .currency,
                      locale: Locale? = nil,
                      minimumFractionDigits: Int? = nil,
                      maximumFractionDigits: Int? = nil) -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.currencyCode = currency.rawValue
        formatter.locale = locale ?? currency.preferredLocale
        
        if let minDigits = minimumFractionDigits {
            formatter.minimumFractionDigits = minDigits
        }
        
        if let maxDigits = maximumFractionDigits {
            formatter.maximumFractionDigits = maxDigits
        }
        
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
    }
    
    /// Get currency symbol for display
    public func getCurrencySymbol(for currency: SupportedCurrency, locale: Locale? = nil) -> String {
        let formatter = getFormatter(for: currency, locale: locale)
        return formatter.currencySymbol ?? currency.symbol
    }
    
    /// Format amount for input (no currency symbol, appropriate decimal places)
    public func formatForInput(_ amount: Decimal, currency: SupportedCurrency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = currency.decimalPlaces
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
    }
    
    /// Parse string to decimal amount
    public func parseAmount(_ string: String, currency: SupportedCurrency, locale: Locale? = nil) -> Decimal? {
        let formatter = getFormatter(for: currency, locale: locale)
        
        // Try parsing with currency formatter first
        if let number = formatter.number(from: string) {
            return number.decimalValue
        }
        
        // Try parsing as plain number
        let plainFormatter = NumberFormatter()
        plainFormatter.numberStyle = .decimal
        plainFormatter.locale = locale ?? currency.preferredLocale
        
        if let number = plainFormatter.number(from: string) {
            return number.decimalValue
        }
        
        // Try parsing with different separators
        let cleanString = string
            .replacingOccurrences(of: currency.symbol, with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let number = plainFormatter.number(from: cleanString) {
            return number.decimalValue
        }
        
        return nil
    }
    
    /// Format exchange rate for display
    public func formatExchangeRate(_ rate: ExchangeRate) -> String {
        let rateString = format(rate.rate, currency: rate.toCurrency, minimumFractionDigits: 2, maximumFractionDigits: 6)
        return "1 \(rate.fromCurrency.rawValue) = \(rateString)"
    }
    
    /// Format percentage
    public func formatPercentage(_ value: Double, fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultFormatter() {
        numberFormatter.numberStyle = .currency
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
    }
    
    private func getFormatter(for currency: SupportedCurrency, locale: Locale? = nil) -> NumberFormatter {
        let targetLocale = locale ?? currency.preferredLocale
        let key = "\(currency.rawValue)_\(targetLocale.identifier)"
        
        if let existingFormatter = formatters[key] {
            return existingFormatter
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.locale = targetLocale
        formatter.maximumFractionDigits = currency.decimalPlaces
        formatter.minimumFractionDigits = min(2, currency.decimalPlaces)
        
        formatters[key] = formatter
        return formatter
    }
    
    private func getValueFormatter(for currency: SupportedCurrency, locale: Locale? = nil) -> NumberFormatter {
        let targetLocale = locale ?? currency.preferredLocale
        let key = "value_\(currency.rawValue)_\(targetLocale.identifier)"
        
        if let existingFormatter = formatters[key] {
            return existingFormatter
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = targetLocale
        formatter.maximumFractionDigits = currency.decimalPlaces
        formatter.minimumFractionDigits = min(2, currency.decimalPlaces)
        formatter.usesGroupingSeparator = true
        
        formatters[key] = formatter
        return formatter
    }
}

// MARK: - SupportedCurrency Extensions for Formatting
extension SupportedCurrency {
    /// Preferred locale for formatting this currency
    public var preferredLocale: Locale {
        switch self {
        case .INR:
            return Locale(identifier: "en_IN")
        case .USD:
            return Locale(identifier: "en_US")
        case .EUR:
            return Locale(identifier: "en_DE")
        case .GBP:
            return Locale(identifier: "en_GB")
        case .JPY:
            return Locale(identifier: "ja_JP")
        case .AUD:
            return Locale(identifier: "en_AU")
        case .CAD:
            return Locale(identifier: "en_CA")
        case .CHF:
            return Locale(identifier: "de_CH")
        case .CNY:
            return Locale(identifier: "zh_CN")
        case .SEK:
            return Locale(identifier: "sv_SE")
        case .NZD:
            return Locale(identifier: "en_NZ")
        case .SGD:
            return Locale(identifier: "en_SG")
        case .HKD:
            return Locale(identifier: "en_HK")
        case .NOK:
            return Locale(identifier: "no_NO")
        case .DKK:
            return Locale(identifier: "da_DK")
        case .PLN:
            return Locale(identifier: "pl_PL")
        case .CZK:
            return Locale(identifier: "cs_CZ")
        case .HUF:
            return Locale(identifier: "hu_HU")
        case .RUB:
            return Locale(identifier: "ru_RU")
        case .KRW:
            return Locale(identifier: "ko_KR")
          case .BRL:
            return Locale(identifier: "pt_BR")
          case .MXN:
            return Locale(identifier: "es_MX")
          case .MYR:
            return Locale(identifier: "ms_MY")
          case .ZAR:
            return Locale(identifier: "en_ZA")
        }
    }
    
    /// Number of decimal places typically used for this currency
    public var decimalPlaces: Int {
        switch self {
        case .JPY, .KRW:
            return 0
        case .INR, .USD, .EUR, .GBP, .AUD, .CAD, .CHF, .CNY, .SEK, .NZD, .SGD, .HKD, .NOK, .DKK, .PLN, .CZK, .RUB:
            return 2
          case .BRL, .MXN, .MYR, .ZAR:
            return 2
        case .HUF:
            return 0
        }
    }
    
    /// Minimum amount for this currency (smallest unit)
    public var minimumAmount: Decimal {
        let places = decimalPlaces
        return places == 0 ? 1 : Decimal(1) / Decimal(pow(10.0, Double(places)))
    }
}
