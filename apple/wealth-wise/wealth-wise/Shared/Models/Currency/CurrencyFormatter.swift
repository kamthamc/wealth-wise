import Foundation

/// Comprehensive currency formatter with cultural adaptations and accessibility support
public class CurrencyFormatter {
    private let locale: Locale
    private let numberFormatter: NumberFormatter
    private let compactFormatter: NumberFormatter
    
    public init(locale: Locale = Locale.current) {
        self.locale = locale
        self.numberFormatter = NumberFormatter()
        self.compactFormatter = NumberFormatter()
        
        setupFormatters()
    }
    
    private func setupFormatters() {
        // Standard formatter
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = locale
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 0
        
        // Compact formatter for large numbers
        compactFormatter.numberStyle = .decimal
        compactFormatter.locale = locale
        compactFormatter.maximumFractionDigits = 1
        compactFormatter.minimumFractionDigits = 0
    }
    
    /// Formats a currency amount with full precision
    public func formatCurrency(
        _ amount: Decimal,
        currency: SupportedCurrency,
        style: CurrencyFormatterStyle = .standard
    ) -> String {
        switch style {
        case .standard:
            return formatStandard(amount, currency: currency)
        case .compact:
            return formatCompact(amount, currency: currency)
        case .symbolOnly:
            return formatSymbolOnly(amount, currency: currency)
        case .codeOnly:
            return formatCodeOnly(amount, currency: currency)
        case .accessible:
            return formatAccessible(amount, currency: currency)
        }
    }
    
    /// Formats amount in Indian numbering system (lakh/crore)
    public func formatIndianCurrency(_ amount: Decimal) -> String {
        let absoluteAmount = abs(amount)
        let isNegative = amount < 0
        let prefix = isNegative ? "-" : ""
        
        let symbol = SupportedCurrency.inr.symbol
        
        if absoluteAmount >= 10_000_000 { // 1 Crore
            let crores = absoluteAmount / 10_000_000
            let formatted = formatDecimal(crores, maxFractionDigits: 2)
            return "\(prefix)\(symbol)\(formatted) Cr"
        } else if absoluteAmount >= 100_000 { // 1 Lakh
            let lakhs = absoluteAmount / 100_000
            let formatted = formatDecimal(lakhs, maxFractionDigits: 2)
            return "\(prefix)\(symbol)\(formatted) L"
        } else if absoluteAmount >= 1_000 { // 1 Thousand
            let thousands = absoluteAmount / 1_000
            let formatted = formatDecimal(thousands, maxFractionDigits: 1)
            return "\(prefix)\(symbol)\(formatted)K"
        } else {
            let formatted = formatDecimal(absoluteAmount, maxFractionDigits: 0)
            return "\(prefix)\(symbol)\(formatted)"
        }
    }
    
    /// Formats amount in Western numbering system (million/billion)
    public func formatWesternCurrency(_ amount: Decimal, currency: SupportedCurrency) -> String {
        let absoluteAmount = abs(amount)
        let isNegative = amount < 0
        let prefix = isNegative ? "-" : ""
        
        let symbol = currency.symbol
        
        if absoluteAmount >= 1_000_000_000 { // 1 Billion
            let billions = absoluteAmount / 1_000_000_000
            let formatted = formatDecimal(billions, maxFractionDigits: 2)
            return "\(prefix)\(symbol)\(formatted)B"
        } else if absoluteAmount >= 1_000_000 { // 1 Million
            let millions = absoluteAmount / 1_000_000
            let formatted = formatDecimal(millions, maxFractionDigits: 2)
            return "\(prefix)\(symbol)\(formatted)M"
        } else if absoluteAmount >= 1_000 { // 1 Thousand
            let thousands = absoluteAmount / 1_000
            let formatted = formatDecimal(thousands, maxFractionDigits: 1)
            return "\(prefix)\(symbol)\(formatted)K"
        } else {
            let formatted = formatDecimal(absoluteAmount, maxFractionDigits: currency.decimalPlaces)
            return "\(prefix)\(symbol)\(formatted)"
        }
    }
    
    // MARK: - Private Formatting Methods
    
    private func formatStandard(_ amount: Decimal, currency: SupportedCurrency) -> String {
        numberFormatter.currencyCode = currency.rawValue
        numberFormatter.currencySymbol = currency.symbol
        numberFormatter.maximumFractionDigits = currency.decimalPlaces
        
        // Handle Indian numbering system
        if currency.usesIndianNumberingSystem {
            return formatIndianStandard(amount, currency: currency)
        }
        
        return numberFormatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)0"
    }
    
    private func formatCompact(_ amount: Decimal, currency: SupportedCurrency) -> String {
        if currency.usesIndianNumberingSystem {
            return formatIndianCurrency(amount)
        } else {
            return formatWesternCurrency(amount, currency: currency)
        }
    }
    
    private func formatSymbolOnly(_ amount: Decimal, currency: SupportedCurrency) -> String {
        let formatted = formatDecimal(amount, maxFractionDigits: currency.decimalPlaces)
        return "\(currency.symbol)\(formatted)"
    }
    
    private func formatCodeOnly(_ amount: Decimal, currency: SupportedCurrency) -> String {
        let formatted = formatDecimal(amount, maxFractionDigits: currency.decimalPlaces)
        return "\(formatted) \(currency.rawValue)"
    }
    
    private func formatAccessible(_ amount: Decimal, currency: SupportedCurrency) -> String {
        let standardFormat = formatStandard(amount, currency: currency)
        let spokenAmount = formatDecimalForSpeech(amount)
        
        return "\(standardFormat), \(spokenAmount) \(currency.displayName)"
    }
    
    private func formatIndianStandard(_ amount: Decimal, currency: SupportedCurrency) -> String {
        let absoluteAmount = abs(amount)
        let isNegative = amount < 0
        let prefix = isNegative ? "-" : ""
        let symbol = currency.symbol
        
        // Use Indian grouping (XX,XX,XXX)
        compactFormatter.groupingSize = 3
        compactFormatter.secondaryGroupingSize = 2
        compactFormatter.usesGroupingSeparator = true
        
        let formatted = compactFormatter.string(from: absoluteAmount as NSDecimalNumber) ?? "0"
        return "\(prefix)\(symbol)\(formatted)"
    }
    
    private func formatDecimal(_ amount: Decimal, maxFractionDigits: Int) -> String {
        compactFormatter.maximumFractionDigits = maxFractionDigits
        return compactFormatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
    
    private func formatDecimalForSpeech(_ amount: Decimal) -> String {
        let absoluteAmount = abs(amount)
        
        if absoluteAmount >= 1_000_000_000 {
            let billions = absoluteAmount / 1_000_000_000
            let rounded = round(billions * 10) / 10
            return "\(rounded) billion"
        } else if absoluteAmount >= 1_000_000 {
            let millions = absoluteAmount / 1_000_000
            let rounded = round(millions * 10) / 10
            return "\(rounded) million"
        } else if absoluteAmount >= 1_000 {
            let thousands = absoluteAmount / 1_000
            let rounded = round(thousands * 10) / 10
            return "\(rounded) thousand"
        } else {
            return "\(absoluteAmount)"
        }
    }
}

// MARK: - Currency Formatter Style
public enum CurrencyFormatterStyle {
    case standard    // $1,234.56
    case compact     // $1.2K
    case symbolOnly  // $1,234.56 (no currency code)
    case codeOnly    // 1,234.56 USD (no symbol)
    case accessible  // $1,234.56, one thousand two hundred thirty four dollars and fifty six cents
}

// MARK: - Localized Currency Formatter
public class LocalizedCurrencyFormatter {
    private var formatters: [String: CurrencyFormatter] = [:]
    
    public static let shared = LocalizedCurrencyFormatter()
    
    private init() {}
    
    public func formatter(for locale: Locale) -> CurrencyFormatter {
        let localeIdentifier = locale.identifier
        
        if let cachedFormatter = formatters[localeIdentifier] {
            return cachedFormatter
        }
        
        let formatter = CurrencyFormatter(locale: locale)
        formatters[localeIdentifier] = formatter
        return formatter
    }
    
    public func formatCurrency(
        _ amount: Decimal,
        currency: SupportedCurrency,
        locale: Locale = Locale.current,
        style: CurrencyFormatterStyle = .standard
    ) -> String {
        let formatter = self.formatter(for: locale)
        return formatter.formatCurrency(amount, currency: currency, style: style)
    }
    
    public func clearCache() {
        formatters.removeAll()
    }
}

// MARK: - Extensions
extension Decimal {
    /// Formats this decimal as currency
    public func formatted(
        as currency: SupportedCurrency,
        style: CurrencyFormatterStyle = .standard,
        locale: Locale = Locale.current
    ) -> String {
        return LocalizedCurrencyFormatter.shared.formatCurrency(
            self,
            currency: currency,
            locale: locale,
            style: style
        )
    }
    
    /// Formats this decimal with Indian numbering system
    public func formattedAsIndianCurrency() -> String {
        let formatter = CurrencyFormatter(locale: Locale(identifier: "en_IN"))
        return formatter.formatIndianCurrency(self)
    }
}

// MARK: - SwiftUI Integration
// SwiftUI integration will be added when UI layer is implemented