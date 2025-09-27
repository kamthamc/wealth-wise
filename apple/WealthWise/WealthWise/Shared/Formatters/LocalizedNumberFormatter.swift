import Foundation

/// Sophisticated localized number formatter supporting cultural preferences
/// Handles Indian lakh/crore system vs Western million/billion system
@available(iOS 18.6, macOS 15.6, *)
public final class LocalizedNumberFormatter {
    
    // MARK: - Properties
    
    /// Current formatting configuration
    public var configuration: NumberFormatterConfiguration {
        didSet {
            configureFormatter()
        }
    }
    
    /// Underlying Foundation NumberFormatter
    private let numberFormatter: NumberFormatter
    
    /// Cache for frequently used formatted strings
    private var formattingCache: [String: String] = [:]
    
    /// Maximum cache size to prevent memory issues
    private let maxCacheSize: Int = 1000
    
    // MARK: - Initialization
    
    public init(configuration: NumberFormatterConfiguration = .american) {
        self.configuration = configuration
        self.numberFormatter = NumberFormatter()
        configureFormatter()
    }
    
    // MARK: - Public Methods
    
    /// Format a decimal number according to cultural preferences
    public func string(from value: Decimal) -> String {
        let cacheKey = "\(value)_\(configuration.hashValue)"
        
        // Check cache first
        if let cachedResult = formattingCache[cacheKey] {
            return cachedResult
        }
        
        let formattedString: String
        
        if configuration.useAbbreviation && abs(value) >= configuration.abbreviationThreshold {
            // Use abbreviated format
            formattedString = abbreviatedString(from: value) ?? fallbackString(from: value)
        } else {
            // Use full format
            formattedString = fullString(from: value)
        }
        
        // Cache the result
        cacheFormattedString(formattedString, for: cacheKey)
        
        return formattedString
    }
    
    /// Format a double number according to cultural preferences
    public func string(from value: Double) -> String {
        return string(from: Decimal(value))
    }
    
    /// Format an integer number according to cultural preferences
    public func string(from value: Int) -> String {
        return string(from: Decimal(value))
    }
    
    /// Format a NSNumber according to cultural preferences
    public func string(from value: NSNumber) -> String {
        return string(from: value.decimalValue)
    }
    
    /// Parse a string to decimal using current cultural preferences
    public func decimal(from string: String) -> Decimal? {
        // Remove abbreviation suffixes first
        let cleanString = removeAbbreviations(from: string)
        
        // Handle different decimal separators
        let normalizedString = normalizeDecimalSeparators(cleanString)
        
        // Use NumberFormatter to parse
        if let number = numberFormatter.number(from: normalizedString) {
            return number.decimalValue
        }
        
        return nil
    }
    
    /// Clear formatting cache
    public func clearCache() {
        formattingCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Configure the underlying NumberFormatter
    private func configureFormatter() {
        let separators = configuration.numberingSystem.separators
        
        numberFormatter.locale = Locale(identifier: configuration.localeIdentifier)
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = configuration.minimumFractionDigits
        numberFormatter.maximumFractionDigits = configuration.maximumFractionDigits
        numberFormatter.usesGroupingSeparator = configuration.usesGroupingSeparator
        numberFormatter.roundingMode = configuration.roundingMode.numberFormatterRoundingMode
        
        // Configure separators
        numberFormatter.decimalSeparator = separators.decimalSeparator
        numberFormatter.groupingSeparator = separators.groupingSeparator
        
        // Configure grouping size for Indian numbering system
        if configuration.numberingSystem == .indian {
            configureIndianGrouping()
        }
        
        // Clear cache when configuration changes
        clearCache()
    }
    
    /// Configure Indian-style grouping (1,00,00,000)
    private func configureIndianGrouping() {
        numberFormatter.usesGroupingSeparator = configuration.usesGroupingSeparator
        
        if configuration.usesGroupingSeparator {
            // Indian grouping: first group of 3, then groups of 2
            numberFormatter.groupingSize = 3
            numberFormatter.secondaryGroupingSize = 2
        }
    }
    
    /// Get full formatted string without abbreviation
    private func fullString(from value: Decimal) -> String {
        let nsValue = value as NSDecimalNumber
        return numberFormatter.string(from: nsValue) ?? fallbackString(from: value)
    }
    
    /// Get abbreviated string for large numbers
    private func abbreviatedString(from value: Decimal) -> String? {
        return configuration.numberingSystem.abbreviation(for: value)
    }
    
    /// Fallback string formatting
    private func fallbackString(from value: Decimal) -> String {
        let nsValue = value as NSDecimalNumber
        return nsValue.stringValue
    }
    
    /// Remove abbreviation suffixes from string
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
    
    /// Normalize decimal separators based on configuration
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
extension LocalizedNumberFormatter {
    
    /// Create formatter for Indian audience
    public static func indianFormatter(abbreviated: Bool = false) -> LocalizedNumberFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.indianAbbreviated : NumberFormatterConfiguration.indian
        return LocalizedNumberFormatter(configuration: config)
    }
    
    /// Create formatter for American audience
    public static func americanFormatter(abbreviated: Bool = false) -> LocalizedNumberFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.americanAbbreviated : NumberFormatterConfiguration.american
        return LocalizedNumberFormatter(configuration: config)
    }
    
    /// Create formatter for British audience
    public static func britishFormatter(abbreviated: Bool = false) -> LocalizedNumberFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.forAudience(.british, abbreviated: true) : NumberFormatterConfiguration.british
        return LocalizedNumberFormatter(configuration: config)
    }
    
    /// Create formatter for European audience
    public static func europeanFormatter(abbreviated: Bool = false) -> LocalizedNumberFormatter {
        let config = abbreviated ? NumberFormatterConfiguration.forAudience(.german, abbreviated: true) : NumberFormatterConfiguration.european
        return LocalizedNumberFormatter(configuration: config)
    }
    
    /// Create formatter for specific audience
    public static func formatter(for audience: PrimaryAudience, abbreviated: Bool = false) -> LocalizedNumberFormatter {
        let config = NumberFormatterConfiguration.forAudience(audience, abbreviated: abbreviated)
        return LocalizedNumberFormatter(configuration: config)
    }
    
    /// Create accessibility-optimized formatter
    public static func accessibilityFormatter(for audience: PrimaryAudience = .american) -> LocalizedNumberFormatter {
        let config = NumberFormatterConfiguration.accessibilityConfiguration(for: audience)
        return LocalizedNumberFormatter(configuration: config)
    }
}