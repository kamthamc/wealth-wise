import Foundation

/// Extension to Decimal for convenient localized formatting
@available(iOS 18.6, macOS 15.6, *)
extension Decimal {
    
    // MARK: - Number Formatting
    
    /// Format as localized number string using Indian numbering system
    public func indianNumberString(abbreviated: Bool = false) -> String {
        let formatter = LocalizedNumberFormatter.indianFormatter(abbreviated: abbreviated)
        return formatter.string(from: self)
    }
    
    /// Format as localized number string using Western numbering system
    public func westernNumberString(abbreviated: Bool = false) -> String {
        let formatter = LocalizedNumberFormatter.americanFormatter(abbreviated: abbreviated)
        return formatter.string(from: self)
    }
    
    /// Format as localized number string for specific audience
    public func formattedString(for audience: PrimaryAudience, abbreviated: Bool = false) -> String {
        let formatter = LocalizedNumberFormatter.formatter(for: audience, abbreviated: abbreviated)
        return formatter.string(from: self)
    }
    
    /// Format as accessibility-friendly number string
    public func accessibleNumberString(for audience: PrimaryAudience = .american) -> String {
        let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
        return formatter.accessibleString(from: self)
    }
    
    // MARK: - Currency Formatting
    
    /// Format as Indian Rupee string
    public func indianRupeeString(abbreviated: Bool = false) -> String {
        let formatter = LocalizedCurrencyFormatter.indianRupeeFormatter(abbreviated: abbreviated)
        return formatter.string(from: self)
    }
    
    /// Format as US Dollar string
    public func usDollarString(abbreviated: Bool = false) -> String {
        let formatter = LocalizedCurrencyFormatter.usDollarFormatter(abbreviated: abbreviated)
        return formatter.string(from: self)
    }
    
    /// Format as British Pound string
    public func britishPoundString(abbreviated: Bool = false) -> String {
        let formatter = LocalizedCurrencyFormatter.britishPoundFormatter(abbreviated: abbreviated)
        return formatter.string(from: self)
    }
    
    /// Format as Euro string
    public func euroString(abbreviated: Bool = false) -> String {
        let formatter = LocalizedCurrencyFormatter.euroFormatter(abbreviated: abbreviated)
        return formatter.string(from: self)
    }
    
    /// Format as currency string for specific currency and audience
    public func currencyString(
        currency: SupportedCurrency,
        audience: PrimaryAudience,
        abbreviated: Bool = false
    ) -> String {
        let formatter = LocalizedCurrencyFormatter.formatter(
            for: currency,
            audience: audience,
            abbreviated: abbreviated
        )
        return formatter.string(from: self)
    }
    
    /// Format as accessibility-friendly currency string
    public func accessibleCurrencyString(
        currency: SupportedCurrency,
        audience: PrimaryAudience = .american
    ) -> String {
        let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
        return formatter.accessibleCurrencyString(from: self, currency: currency)
    }
    
    // MARK: - Specialized Formatting
    
    /// Format for financial reports (always uses full precision)
    public func financialReportString(
        currency: SupportedCurrency,
        audience: PrimaryAudience
    ) -> String {
        let config = NumberFormatterConfiguration(
            numberingSystem: CulturalNumberingSystem.forAudience(audience),
            audience: audience,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
            usesGroupingSeparator: true,
            useAbbreviation: false,
            abbreviationThreshold: Decimal.greatestFiniteMagnitude,
            localeIdentifier: audience.preferredLocale.identifier
        )
        
        let formatter = LocalizedCurrencyFormatter(currency: currency, configuration: config)
        return formatter.string(from: self)
    }
    
    /// Format for dashboard display (uses abbreviation for large amounts)
    public func dashboardString(
        currency: SupportedCurrency,
        audience: PrimaryAudience
    ) -> String {
        let threshold: Decimal = audience == .indian ? 100_000 : 1_000_000
        
        let config = NumberFormatterConfiguration(
            numberingSystem: CulturalNumberingSystem.forAudience(audience),
            audience: audience,
            minimumFractionDigits: 0,
            maximumFractionDigits: 1,
            usesGroupingSeparator: false,
            useAbbreviation: true,
            abbreviationThreshold: threshold,
            localeIdentifier: audience.preferredLocale.identifier
        )
        
        let formatter = LocalizedCurrencyFormatter(currency: currency, configuration: config)
        return formatter.string(from: self)
    }
    
    /// Format for export (CSV-friendly, no currency symbols, standard decimal separator)
    public func exportString() -> String {
        let config = NumberFormatterConfiguration(
            numberingSystem: .western,
            audience: .american,
            minimumFractionDigits: 2,
            maximumFractionDigits: 6,
            usesGroupingSeparator: false,
            useAbbreviation: false,
            abbreviationThreshold: Decimal.greatestFiniteMagnitude,
            localeIdentifier: "en_US"
        )
        
        let formatter = LocalizedNumberFormatter(configuration: config)
        return formatter.string(from: self)
    }
    
    // MARK: - Comparison Helpers
    
    /// Check if this amount is considered "large" for the given audience
    public func isLargeAmount(for audience: PrimaryAudience) -> Bool {
        let threshold: Decimal = audience == .indian ? 100_000 : 1_000_000
        return abs(self) >= threshold
    }
    
    /// Get appropriate formatting style based on amount size
    public func suggestedAbbreviation(for audience: PrimaryAudience) -> Bool {
        return isLargeAmount(for: audience)
    }
    
    // MARK: - Utility Methods
    
    /// Round to currency precision (typically 2 decimal places)
    public func roundedToCurrency(_ currency: SupportedCurrency) -> Decimal {
        let decimalPlaces = currency.decimalPlaces
        let multiplierDecimal = pow(Decimal(10), decimalPlaces)
        
        let scaled = self * multiplierDecimal
        let nsDecimal = NSDecimalNumber(decimal: scaled)
        let rounded = nsDecimal.rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .bankers,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        ))
        return rounded.decimalValue / multiplierDecimal
    }
    
    /// Format percentage with cultural preferences
    public func percentageString(for audience: PrimaryAudience, decimalPlaces: Int = 2) -> String {
        let config = NumberFormatterConfiguration.forAudience(audience, abbreviated: false)
        let formatter = LocalizedNumberFormatter(configuration: config)
        
        let percentage = self * 100
        let formattedNumber = formatter.string(from: percentage)
        let percentSymbol = NSLocalizedString("symbol.percent", value: "%", comment: "Percent symbol")
        
        return "\(formattedNumber)\(percentSymbol)"
    }
    
    /// Check if value is effectively zero (within currency precision)
    public func isEffectivelyZero(for currency: SupportedCurrency) -> Bool {
        let precision = pow(Decimal(10), -currency.decimalPlaces)
        return abs(self) < precision
    }
}

// MARK: - String to Decimal Parsing

extension Decimal {
    
    /// Parse localized number string
    public static func from(
        localizedString string: String,
        audience: PrimaryAudience
    ) -> Decimal? {
        let formatter = LocalizedNumberFormatter.formatter(for: audience, abbreviated: false)
        return formatter.decimal(from: string)
    }
    
    /// Parse localized currency string
    public static func from(
        currencyString string: String,
        currency: SupportedCurrency,
        audience: PrimaryAudience
    ) -> Decimal? {
        let formatter = LocalizedCurrencyFormatter.formatter(
            for: currency,
            audience: audience,
            abbreviated: false
        )
        return formatter.decimal(from: string)
    }
    
    /// Parse export format string (CSV-friendly)
    public static func fromExportString(_ string: String) -> Decimal? {
        return Decimal(string: string.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - Validation Helpers

extension Decimal {
    
    /// Validate that the decimal can be properly represented in the given currency
    public func isValidAmount(for currency: SupportedCurrency) -> Bool {
        // Check if the decimal places don't exceed currency precision
        let decimalPlaces = currency.decimalPlaces
        let multiplierDecimal = pow(Decimal(10), decimalPlaces)
        
        let scaled = self * multiplierDecimal
        let nsDecimal = NSDecimalNumber(decimal: scaled)
        let rounded = nsDecimal.rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .bankers,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        ))
        
        return scaled == rounded.decimalValue
    }
    
    /// Get validation error message if amount is invalid for currency
    public func validationError(for currency: SupportedCurrency) -> String? {
        if !isValidAmount(for: currency) {
            return NSLocalizedString(
                "validation.currency.precision",
                value: "Amount has too many decimal places for \(currency.displayName)",
                comment: "Currency precision validation error"
            )
        }
        
        if self < 0 && !currency.supportsNegativeAmounts {
            return NSLocalizedString(
                "validation.currency.negative",
                value: "\(currency.displayName) does not support negative amounts",
                comment: "Currency negative amount validation error"
            )
        }
        
        return nil
    }
}

// MARK: - SupportedCurrency Extension for Validation

extension SupportedCurrency {
    /// Whether the currency typically supports negative amounts
    var supportsNegativeAmounts: Bool {
        // Most currencies support negative amounts for accounting purposes
        // This could be configured per business logic requirements
        return true
    }
}