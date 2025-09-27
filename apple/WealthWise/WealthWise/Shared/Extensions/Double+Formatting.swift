import Foundation

/// Extension to Double for convenient localized formatting
@available(iOS 18.6, macOS 15.6, *)
extension Double {
    
    // MARK: - Number Formatting
    
    /// Format as localized number string using Indian numbering system
    public func indianNumberString(abbreviated: Bool = false) -> String {
        return Decimal(self).indianNumberString(abbreviated: abbreviated)
    }
    
    /// Format as localized number string using Western numbering system
    public func westernNumberString(abbreviated: Bool = false) -> String {
        return Decimal(self).westernNumberString(abbreviated: abbreviated)
    }
    
    /// Format as localized number string for specific audience
    public func formattedString(for audience: PrimaryAudience, abbreviated: Bool = false) -> String {
        return Decimal(self).formattedString(for: audience, abbreviated: abbreviated)
    }
    
    /// Format as accessibility-friendly number string
    public func accessibleNumberString(for audience: PrimaryAudience = .american) -> String {
        return Decimal(self).accessibleNumberString(for: audience)
    }
    
    // MARK: - Currency Formatting
    
    /// Format as Indian Rupee string
    public func indianRupeeString(abbreviated: Bool = false) -> String {
        return Decimal(self).indianRupeeString(abbreviated: abbreviated)
    }
    
    /// Format as US Dollar string
    public func usDollarString(abbreviated: Bool = false) -> String {
        return Decimal(self).usDollarString(abbreviated: abbreviated)
    }
    
    /// Format as British Pound string
    public func britishPoundString(abbreviated: Bool = false) -> String {
        return Decimal(self).britishPoundString(abbreviated: abbreviated)
    }
    
    /// Format as Euro string
    public func euroString(abbreviated: Bool = false) -> String {
        return Decimal(self).euroString(abbreviated: abbreviated)
    }
    
    /// Format as currency string for specific currency and audience
    public func currencyString(
        currency: SupportedCurrency,
        audience: PrimaryAudience,
        abbreviated: Bool = false
    ) -> String {
        return Decimal(self).currencyString(
            currency: currency,
            audience: audience,
            abbreviated: abbreviated
        )
    }
    
    /// Format as accessibility-friendly currency string
    public func accessibleCurrencyString(
        currency: SupportedCurrency,
        audience: PrimaryAudience = .american
    ) -> String {
        return Decimal(self).accessibleCurrencyString(currency: currency, audience: audience)
    }
    
    // MARK: - Specialized Formatting
    
    /// Format for financial reports (always uses full precision)
    public func financialReportString(
        currency: SupportedCurrency,
        audience: PrimaryAudience
    ) -> String {
        return Decimal(self).financialReportString(currency: currency, audience: audience)
    }
    
    /// Format for dashboard display (uses abbreviation for large amounts)
    public func dashboardString(
        currency: SupportedCurrency,
        audience: PrimaryAudience
    ) -> String {
        return Decimal(self).dashboardString(currency: currency, audience: audience)
    }
    
    /// Format for export (CSV-friendly, no currency symbols, standard decimal separator)
    public func exportString() -> String {
        return Decimal(self).exportString()
    }
    
    /// Format percentage with cultural preferences
    public func percentageString(for audience: PrimaryAudience, decimalPlaces: Int = 2) -> String {
        return Decimal(self).percentageString(for: audience, decimalPlaces: decimalPlaces)
    }
    
    // MARK: - Comparison Helpers
    
    /// Check if this amount is considered "large" for the given audience
    public func isLargeAmount(for audience: PrimaryAudience) -> Bool {
        return Decimal(self).isLargeAmount(for: audience)
    }
    
    /// Get appropriate formatting style based on amount size
    public func suggestedAbbreviation(for audience: PrimaryAudience) -> Bool {
        return Decimal(self).suggestedAbbreviation(for: audience)
    }
    
    // MARK: - Utility Methods
    
    /// Round to currency precision (typically 2 decimal places)
    public func roundedToCurrency(_ currency: SupportedCurrency) -> Double {
        let decimalResult = Decimal(self).roundedToCurrency(currency)
        return (decimalResult as NSDecimalNumber).doubleValue
    }
    
    /// Check if value is effectively zero (within currency precision)
    public func isEffectivelyZero(for currency: SupportedCurrency) -> Bool {
        return Decimal(self).isEffectivelyZero(for: currency)
    }
    
    /// Validate that the double can be properly represented in the given currency
    public func isValidAmount(for currency: SupportedCurrency) -> Bool {
        return Decimal(self).isValidAmount(for: currency)
    }
    
    /// Get validation error message if amount is invalid for currency
    public func validationError(for currency: SupportedCurrency) -> String? {
        return Decimal(self).validationError(for: currency)
    }
    
    // MARK: - Safe Conversion to Decimal
    
    /// Convert to Decimal with proper rounding for financial calculations
    public var financialDecimal: Decimal {
        // Use string conversion to avoid floating point precision issues
        let stringValue = String(format: "%.15f", self)
        return Decimal(string: stringValue) ?? Decimal(self)
    }
    
    /// Convert to Decimal rounded to currency precision
    public func toDecimal(for currency: SupportedCurrency) -> Decimal {
        let decimal = financialDecimal
        return decimal.roundedToCurrency(currency)
    }
}

// MARK: - String to Double Parsing

extension Double {
    
    /// Parse localized number string
    public static func from(
        localizedString string: String,
        audience: PrimaryAudience
    ) -> Double? {
        if let decimal = Decimal.from(localizedString: string, audience: audience) {
            return (decimal as NSDecimalNumber).doubleValue
        }
        return nil
    }
    
    /// Parse localized currency string
    public static func from(
        currencyString string: String,
        currency: SupportedCurrency,
        audience: PrimaryAudience
    ) -> Double? {
        if let decimal = Decimal.from(
            currencyString: string,
            currency: currency,
            audience: audience
        ) {
            return (decimal as NSDecimalNumber).doubleValue
        }
        return nil
    }
    
    /// Parse export format string (CSV-friendly)
    public static func fromExportString(_ string: String) -> Double? {
        if let decimal = Decimal.fromExportString(string) {
            return (decimal as NSDecimalNumber).doubleValue
        }
        return nil
    }
}

// MARK: - Financial Ma th Helpers

extension Double {
    
    /// Format as rate (percentage) with proper precision
    public func rateString(for audience: PrimaryAudience, decimalPlaces: Int = 4) -> String {
        let config = NumberFormatterConfiguration.forAudience(audience, abbreviated: false)
        var modifiedConfig = NumberFormatterConfiguration(
            numberingSystem: config.numberingSystem,
            audience: config.audience,
            minimumFractionDigits: decimalPlaces,
            maximumFractionDigits: decimalPlaces,
            usesGroupingSeparator: config.usesGroupingSeparator,
            useAbbreviation: false,
            abbreviationThreshold: Decimal.greatestFiniteMagnitude,
            localeIdentifier: config.localeIdentifier
        )
        
        let formatter = LocalizedNumberFormatter(configuration: modifiedConfig)
        let formattedNumber = formatter.string(from: Decimal(self))
        let percentSymbol = NSLocalizedString("symbol.percent", value: "%", comment: "Percent symbol")
        
        return "\(formattedNumber)\(percentSymbol)"
    }
    
    /// Format as basis points (1% = 100 bps)
    public func basisPointsString(for audience: PrimaryAudience) -> String {
        let basisPoints = self * 10000
        let config = NumberFormatterConfiguration.forAudience(audience, abbreviated: false)
        let formatter = LocalizedNumberFormatter(configuration: config)
        
        let formattedNumber = formatter.string(from: Decimal(basisPoints))
        return "\(formattedNumber) bps"
    }
    
    /// Format as multiplier (e.g., 2.5x)
    public func multiplierString(for audience: PrimaryAudience, decimalPlaces: Int = 2) -> String {
        let config = NumberFormatterConfiguration(
            numberingSystem: CulturalNumberingSystem.forAudience(audience),
            audience: audience,
            minimumFractionDigits: 1,
            maximumFractionDigits: decimalPlaces,
            usesGroupingSeparator: false,
            useAbbreviation: false,
            abbreviationThreshold: Decimal.greatestFiniteMagnitude,
            localeIdentifier: audience.preferredLocale.identifier
        )
        
        let formatter = LocalizedNumberFormatter(configuration: config)
        let formattedNumber = formatter.string(from: Decimal(self))
        return "\(formattedNumber)x"
    }
    
    /// Format as return percentage with sign
    public func returnString(for audience: PrimaryAudience, showSign: Bool = true) -> String {
        let percentage = self * 100
        let config = NumberFormatterConfiguration.forAudience(audience, abbreviated: false)
        let formatter = LocalizedNumberFormatter(configuration: config)
        
        let formattedNumber = formatter.string(from: Decimal(percentage))
        let percentSymbol = NSLocalizedString("symbol.percent", value: "%", comment: "Percent symbol")
        
        if showSign && self > 0 {
            return "+\(formattedNumber)\(percentSymbol)"
        } else {
            return "\(formattedNumber)\(percentSymbol)"
        }
    }
}

// MARK: - Input Validation Helpers

extension Double {
    
    /// Check if the value is within reasonable financial bounds
    public var isReasonableFinancialValue: Bool {
        // Check for infinity, NaN, and extremely large values
        guard isFinite && !isNaN else { return false }
        
        // Check for reasonable bounds (adjust based on use case)
        let maxValue: Double = 1_000_000_000_000 // 1 trillion
        let minValue: Double = -1_000_000_000_000
        
        return self <= maxValue && self >= minValue
    }
    
    /// Sanitize for financial calculations (handle edge cases)
    public var sanitizedForFinance: Double {
        guard isReasonableFinancialValue else { return 0.0 }
        return self
    }
    
    /// Check if the value has excessive precision for currency
    public func hasExcessivePrecision(for currency: SupportedCurrency) -> Bool {
        let decimalPlaces = currency.decimalPlaces
        let multiplier = pow(10.0, Double(decimalPlaces))
        let scaled = self * multiplier
        let rounded = scaled.rounded()
        
        // Allow small floating point errors
        let epsilon = 1e-10
        return abs(scaled - rounded) > epsilon
    }
    
    /// Clean up floating point precision issues
    public func cleanedForCurrency(_ currency: SupportedCurrency) -> Double {
        let decimalPlaces = currency.decimalPlaces
        let multiplier = pow(10.0, Double(decimalPlaces))
        return (self * multiplier).rounded() / multiplier
    }
}
