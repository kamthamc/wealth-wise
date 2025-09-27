import Foundation

/// Sophisticated localized currency formatter with cultural symbol positioning
/// Supports different currency display formats and cultural preferences
@available(iOS 18.6, macOS 15.6, *)
public final class LocalizedCurrencyFormatter {
    
    // MARK: - Properties
    
    /// Current formatting configuration
    public var configuration: NumberFormatterConfiguration {
        didSet {
            configureFormatter()
        }
    }
    
    /// Currency to format with
    public var currency: SupportedCurrency {
        didSet {
            configureFormatter()
        }
    }
    
    /// Underlying Foundation NumberFormatter
    private let currencyFormatter: NumberFormatter
    
    /// Cache for frequently used formatted strings
    private var formattingCache: [String: String] = [:]
    
    /// Maximum cache size to prevent memory issues
    private let maxCacheSize: Int = 1000
    
    // MARK: - Initialization
    
    public init(
        currency: SupportedCurrency = .USD,
        configuration: NumberFormatterConfiguration = .american
    ) {
        self.currency = currency
        self.configuration = configuration
        self.currencyFormatter = NumberFormatter()
        configureFormatter()
    }
    
    // MARK: - Public Methods
    
    /// Format a decimal amount with currency symbol
    public func string(from value: Decimal) -> String {
        let cacheKey = "\(value)_\(currency.rawValue)_\(configuration.hashValue)"
        
        // Check cache first
        if let cachedResult = formattingCache[cacheKey] {
            return cachedResult
        }
        
        let formattedString: String
        
        if configuration.useAbbreviation && abs(value) >= configuration.abbreviationThreshold {
            // Use abbreviated format with currency
            formattedString = abbreviatedCurrencyString(from: value) ?? fallbackCurrencyString(from: value)
        } else {
            // Use full format with currency
            formattedString = fullCurrencyString(from: value)
        }
        
        // Cache the result
        cacheFormattedString(formattedString, for: cacheKey)
        
        return formattedString
    }
    
    /// Format a double amount with currency symbol
    public func string(from value: Double) -> String {
        return string(from: Decimal(value))
    }
    
    /// Format an integer amount with currency symbol
    public func string(from value: Int) -> String {
        return string(from: Decimal(value))
    }
    
    /// Format a NSNumber amount with currency symbol
    public func string(from value: NSNumber) -> String {
        return string(from: value.decimalValue)
    }
    
    /// Parse a currency string to decimal value
    public func decimal(from string: String) -> Decimal? {
        // Remove currency symbols and clean the string
        let cleanString = removeCurrencySymbols(from: string)
        
        // Remove abbreviation suffixes
        let numberString = removeAbbreviations(from: cleanString)
        
        // Handle different decimal separators
        let normalizedString = normalizeDecimalSeparators(numberString)
        
        // Use NumberFormatter to parse
        if let number = currencyFormatter.number(from: normalizedString) {
            return number.decimalValue
        }
        
        return nil
    }
    
    /// Get currency symbol with proper spacing
    public func currencySymbol(withSpacing: Bool = true) -> String {
        let symbol = currency.symbol
        let preferences = CulturalPreferences.forAudience(configuration.audience)
        
        if preferences.currencySymbolPosition == "before" {
            return withSpacing ? "\(symbol) " : symbol
        } else {
            return withSpacing ? " \(symbol)" : symbol
        }
    }
    
    /// Clear formatting cache
    public func clearCache() {
        formattingCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Configure the underlying NumberFormatter
    private func configureFormatter() {
        let separators = configuration.numberingSystem.separators
        
        currencyFormatter.locale = Locale(identifier: configuration.localeIdentifier) 
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = currency.rawValue
        currencyFormatter.minimumFractionDigits = configuration.minimumFractionDigits
        currencyFormatter.maximumFractionDigits = configuration.maximumFractionDigits
        currencyFormatter.usesGroupingSeparator = configuration.usesGroupingSeparator
        currencyFormatter.roundingMode = configuration.roundingMode.numberFormatterRoundingMode
        
        // Configure separators
        currencyFormatter.decimalSeparator = separators.decimalSeparator
        currencyFormatter.groupingSeparator = separators.groupingSeparator
        
        // Configure currency symbol position
        configureCurrencySymbolPosition()
        
        // Configure grouping size for Indian numbering system
        if configuration.numberingSystem == .indian {
            configureIndianGrouping()
        }
        
        // Clear cache when configuration changes
        clearCache()
    }
    
    /// Configure currency symbol position based on cultural preferences
    private func configureCurrencySymbolPosition() {
        let preferences = CulturalPreferences.forAudience(configuration.audience)
        
        if preferences.currencySymbolPosition == "before" {
            currencyFormatter.positiveFormat = "¤ #,##0.00"
            currencyFormatter.negativeFormat = "-¤ #,##0.00"
        } else {
            currencyFormatter.positiveFormat = "#,##0.00 ¤"
            currencyFormatter.negativeFormat = "-#,##0.00 ¤"
        }
        
        // Override currency symbol
        currencyFormatter.currencySymbol = currency.symbol
    }
    
    /// Configure Indian-style grouping (1,00,00,000)
    private func configureIndianGrouping() {
        currencyFormatter.usesGroupingSeparator = configuration.usesGroupingSeparator
        
        if configuration.usesGroupingSeparator {
            // Indian grouping: first group of 3, then groups of 2
            currencyFormatter.groupingSize = 3
            currencyFormatter.secondaryGroupingSize = 2
        }
        
        // Update format strings for Indian grouping
        let preferences = CulturalPreferences.forAudience(configuration.audience)
        if preferences.currencySymbolPosition == "before" {
            currencyFormatter.positiveFormat = "¤ #,##,##0.00"
            currencyFormatter.negativeFormat = "-¤ #,##,##0.00"
        } else {
            currencyFormatter.positiveFormat = "#,##,##0.00 ¤"
            currencyFormatter.negativeFormat = "-#,##,##0.00 ¤"
        }
    }
    
    /// Get full formatted currency string
    private func fullCurrencyString(from value: Decimal) -> String {
        let nsValue = value as NSDecimalNumber
        return currencyFormatter.string(from: nsValue) ?? fallbackCurrencyString(from: value)
    }
    
    /// Get abbreviated currency string for large amounts
    private func abbreviatedCurrencyString(from value: Decimal) -> String? {
        guard let abbreviation = configuration.numberingSystem.abbreviation(for: value) else {
            return nil
        }
        
        let preferences = CulturalPreferences.forAudience(configuration.audience)
        let symbol = currency.symbol
        
        if preferences.currencySymbolPosition == "before" {
            return "\(symbol)\(abbreviation)"
        } else {
            return "\(abbreviation) \(symbol)"
        }
    }
    
    /// Fallback currency string formatting
    private func fallbackCurrencyString(from value: Decimal) -> String {
        let nsValue = value as NSDecimalNumber
        let numberString = nsValue.stringValue
        let symbol = currency.symbol
        
        let preferences = CulturalPreferences.forAudience(configuration.audience)
        
        if preferences.currencySymbolPosition == "before" {
            return "\(symbol) \(numberString)"
        } else {
            return "\(numberString) \(symbol)"
        }
    }
    
    /// Remove currency symbols from string
    private func removeCurrencySymbols(from string: String) -> String {
        var cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove all known currency symbols
        for currency in SupportedCurrency.allCases {
            cleanString = cleanString.replacingOccurrences(of: currency.symbol, with: "")
        }
        
        // Remove extra whitespace
        cleanString = cleanString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanString
    }
    
    /// Remove abbreviation suffixes from string (reused from LocalizedNumberFormatter)
    private func removeAbbreviations(from string: String) -> String {
        var cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Indian abbreviations
        let indianSuffixes = ["Cr", "L", "K"]
        let indianMultipliers: [String: Decimal] = ["Cr": 10_000_000, "L": 100_000, "K": 1_000]
        
        // Western abbreviations
        let westernSuffixes = ["B", "M", "K", "k"]
        let westernMultipliers: [String: Decimal] = ["B": 1_000_000_000, "M": 1_000_000, "K": 1_000, "k": 1_000]
        
        // European abbreviations
        let europeanSuffixes = ["Md", "M", "k"]
        let europeanMultipliers: [String: Decimal] = ["Md": 1_000_000_000, "M": 1_000_000, "k": 1_000]
        
        let allSuffixes = indianSuffixes + westernSuffixes + europeanSuffixes
        let allMultipliers = indianMultipliers.merging(westernMultipliers) { $1 }
            .merging(europeanMultipliers) { $1 }
        
        for suffix in allSuffixes {
            if cleanString.hasSuffix(suffix) {
                let numberPart = String(cleanString.dropLast(suffix.count))
                if let number = Decimal(string: numberPart),
                   let multiplier = allMultipliers[suffix] {
                    let expandedValue = number * multiplier
                    cleanString = expandedValue.description
                    break
                }
            }
        }
        
        return cleanString
    }
    
    /// Normalize decimal separators (reused from LocalizedNumberFormatter)
    private func normalizeDecimalSeparators(_ string: String) -> String {
        let separators = configuration.numberingSystem.separators
        
        // If using European style (comma as decimal separator)
        if separators.decimalSeparator == "," && separators.groupingSeparator == "." {
            // Replace the last comma with a period for parsing
            if let lastCommaIndex = string.lastIndex(of: ",") {
                var normalized = string
                normalized.replaceSubrange(lastCommaIndex...lastCommaIndex, with: ".")
                // Remove grouping separators (periods)
                normalized = normalized.replacingOccurrences(of: ".", with: "", options: [], range: nil)
                // Put back the decimal separator
                if let lastPeriodIndex = normalized.lastIndex(of: ".") {
                    normalized.replaceSubrange(lastPeriodIndex...lastPeriodIndex, with: ".")
                }
                return normalized
            }
        }
        
        return string
    }
    
    /// Cache formatted string with size management
    private func cacheFormattedString(_ string: String, for key: String) {
        if formattingCache.count >= maxCacheSize {
            // Remove oldest entries (simplified approach)
            let keysToRemove = Array(formattingCache.keys.prefix(maxCacheSize / 4))
            for keyToRemove in keysToRemove {
                formattingCache.removeValue(forKey: keyToRemove)
            }
        }
        
        formattingCache[key] = string
    }
}

// MARK: - Convenience Factory Methods

@available(iOS 18.6, macOS 15.6, *)
extension LocalizedCurrencyFormatter {
    
    /// Create INR formatter for Indian audience
    public static func indianRupeeFormatter(abbreviated: Bool = false) -> LocalizedCurrencyFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.indianAbbreviated : NumberFormatterConfiguration.indian
        return LocalizedCurrencyFormatter(currency: .INR, configuration: config)
    }
    
    /// Create USD formatter for American audience
    public static func usDollarFormatter(abbreviated: Bool = false) -> LocalizedCurrencyFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.americanAbbreviated : NumberFormatterConfiguration.american
        return LocalizedCurrencyFormatter(currency: .USD, configuration: config)
    }
    
    /// Create GBP formatter for British audience
    public static func britishPoundFormatter(abbreviated: Bool = false) -> LocalizedCurrencyFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.forAudience(.british, abbreviated: true) : NumberFormatterConfiguration.british
        return LocalizedCurrencyFormatter(currency: .GBP, configuration: config)
    }
    
    /// Create EUR formatter for European audience
    public static func euroFormatter(abbreviated: Bool = false) -> LocalizedCurrencyFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.forAudience(.german, abbreviated: true) : NumberFormatterConfiguration.european
        return LocalizedCurrencyFormatter(currency: .EUR, configuration: config)
    }
    
    /// Create formatter for specific currency and audience
    public static func formatter(
        for currency: SupportedCurrency,
        audience: PrimaryAudience,
        abbreviated: Bool = false
    ) -> LocalizedCurrencyFormatter {
        let config = NumberFormatterConfiguration.forAudience(audience, abbreviated: abbreviated)
        return LocalizedCurrencyFormatter(currency: currency, configuration: config)
    }
    
    /// Create accessibility-optimized currency formatter
    public static func accessibilityFormatter(
        for currency: SupportedCurrency,
        audience: PrimaryAudience = .american
    ) -> LocalizedCurrencyFormatter {
        let config = NumberFormatterConfiguration.accessibilityConfiguration(for: audience)
        return LocalizedCurrencyFormatter(currency: currency, configuration: config)
    }
}

// MARK: - CulturalPreferences Extension

extension CulturalPreferences {
    /// Get cultural preferences for audience
    static func forAudience(_ audience: PrimaryAudience) -> CulturalPreferences {
        switch audience {
        case .indian:
            return .indian
        case .american:
            return .american
        case .british:
            return .british
        default:
            return .american
        }
    }
}