import Foundation

/// Protocol for localized date formatting to enable dependency injection
public protocol LocalizedDateFormatterProtocol: AnyObject {
    func string(from date: Date) -> String
    func string(from date: Date, configuration: DateFormatterConfiguration) -> String
    func relativeString(from date: Date) -> String
    func accessibleString(from date: Date) -> String
}

/// Sophisticated localized date formatter supporting cultural preferences and financial year contexts
/// Handles audience-specific date formats, financial years, and accessibility requirements
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class LocalizedDateFormatter: LocalizedDateFormatterProtocol {
    
    // MARK: - Properties
    
    /// Current formatting configuration
    public var configuration: DateFormatterConfiguration {
        didSet {
            configureFormatter()
        }
    }
    
    /// Underlying Foundation DateFormatter
    private let dateFormatter: DateFormatter
    
    /// Cache for frequently used formatted strings
    private var formattingCache: [String: String] = [:]
    
    /// Maximum cache size to prevent memory issues
    private let maxCacheSize: Int = 500
    
    /// Financial year formatter for FY-specific formatting
    private let financialYearFormatter: FinancialYearFormatter
    
    /// Relative date formatter for "2 days ago" style formatting
    private let relativeDateFormatter: RelativeDateFormatter
    
    /// Accessibility-optimized formatter
    private let accessibleDateFormatter: AccessibleDateFormatter
    
    // MARK: - Initialization
    
    public init(configuration: DateFormatterConfiguration = .indian) {
        self.configuration = configuration
        self.dateFormatter = DateFormatter()
        self.financialYearFormatter = FinancialYearFormatter(audience: configuration.audience)
        self.relativeDateFormatter = RelativeDateFormatter(audience: configuration.audience)
        self.accessibleDateFormatter = AccessibleDateFormatter(audience: configuration.audience)
        
        configureFormatter()
    }
    
    // MARK: - Public Methods
    
    /// Format a date according to the current configuration
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    public func string(from date: Date) -> String {
        let cacheKey = "\(date.timeIntervalSince1970)_\(configuration.hashValue)"
        
        // Check cache first
        if let cachedResult = formattingCache[cacheKey] {
            return cachedResult
        }
        
        let formattedString = formatDate(date)
        
        // Cache the result
        cacheResult(formattedString, for: cacheKey)
        
        return formattedString
    }
    
    /// Format a date with a specific configuration
    /// - Parameters:
    ///   - date: The date to format
    ///   - configuration: The configuration to use for formatting
    /// - Returns: Formatted date string
    public func string(from date: Date, configuration: DateFormatterConfiguration) -> String {
        let originalConfig = self.configuration
        self.configuration = configuration
        let result = string(from: date)
        self.configuration = originalConfig
        return result
    }
    
    /// Format a date using relative formatting ("2 days ago", "tomorrow", etc.)
    /// - Parameter date: The date to format
    /// - Returns: Relative formatted date string
    public func relativeString(from date: Date) -> String {
        return relativeDateFormatter.string(from: date)
    }
    
    /// Format a date for accessibility/VoiceOver
    /// - Parameter date: The date to format
    /// - Returns: Accessibility-optimized date string
    public func accessibleString(from date: Date) -> String {
        return accessibleDateFormatter.string(from: date)
    }
    
    /// Format a date with financial year context
    /// - Parameter date: The date to format
    /// - Returns: Date string with financial year information
    public func financialYearString(from date: Date) -> String {
        return financialYearFormatter.string(from: date)
    }
    
    /// Format a date range (e.g., "Jan 1 - Dec 31, 2024")
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    /// - Returns: Formatted date range string
    public func string(from startDate: Date, to endDate: Date) -> String {
        let calendar = configuration.calendar
        
        // Check if both dates are in the same year
        if calendar.isDate(startDate, equalTo: endDate, toGranularity: .year) {
            // Same year - optimize format
            let startFormatter = createDateFormatter()
            let endFormatter = createDateFormatter()
            
            if calendar.isDate(startDate, equalTo: endDate, toGranularity: .month) {
                // Same month - show "Jan 1-15, 2024"
                startFormatter.dateFormat = "MMM d"
                endFormatter.dateFormat = "d, yyyy"
            } else {
                // Different months - show "Jan 1 - Dec 31, 2024"
                startFormatter.dateFormat = "MMM d"
                endFormatter.dateFormat = " - MMM d, yyyy"
            }
            
            let startString = startFormatter.string(from: startDate)
            let endString = endFormatter.string(from: endDate)
            return startString + endString
        } else {
            // Different years - show full format
            let formatter = createDateFormatter()
            formatter.dateFormat = configuration.culturalDateFormat
            
            let startString = formatter.string(from: startDate)
            let endString = formatter.string(from: endDate)
            
            return String(format: NSLocalizedString("date_range_format", comment: "Date range format"), startString, endString)
        }
    }
    
    /// Clear the formatting cache
    public func clearCache() {
        formattingCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func formatDate(_ date: Date) -> String {
        // Check for relative formatting first
        if configuration.useRelativeFormatting && shouldUseRelativeFormat(for: date) {
            return relativeString(from: date)
        }
        
        // Check for financial year context
        if configuration.showFinancialYearContext {
            return financialYearString(from: date)
        }
        
        // Check for accessibility optimization
        if configuration.accessibilityOptimized {
            return accessibleString(from: date)
        }
        
        // Use standard formatting
        return dateFormatter.string(from: date)
    }
    
    private func shouldUseRelativeFormat(for date: Date) -> Bool {
        let now = Date()
        let daysDifference = abs(date.daysBetween(now))
        
        // Use relative format for dates within the last 7 days or next 7 days
        return daysDifference <= 7
    }
    
    private func createDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = configuration.locale
        formatter.timeZone = configuration.timeZone
        formatter.calendar = configuration.calendar
        return formatter
    }
    
    private func configureFormatter() {
        dateFormatter.locale = configuration.locale
        dateFormatter.timeZone = configuration.timeZone
        dateFormatter.calendar = configuration.calendar
        dateFormatter.dateStyle = configuration.dateStyle
        dateFormatter.timeStyle = configuration.timeStyle
        
        // Apply custom format if provided
        if let customFormat = configuration.customFormat {
            dateFormatter.dateFormat = customFormat
        } else {
            // Use cultural format based on audience
            let dateFormat = configuration.culturalDateFormat
            let timeFormat = configuration.culturalTimeFormat
            
            if !timeFormat.isEmpty {
                dateFormatter.dateFormat = "\(dateFormat) \(timeFormat)"
            } else {
                dateFormatter.dateFormat = dateFormat
            }
        }
        
        // Clear cache when configuration changes
        clearCache()
    }
    
    private func cacheResult(_ result: String, for key: String) {
        // Prevent cache from growing too large
        if formattingCache.count >= maxCacheSize {
            // Remove oldest entries (simple FIFO)
            let keysToRemove = Array(formattingCache.keys.prefix(maxCacheSize / 4))
            keysToRemove.forEach { formattingCache.removeValue(forKey: $0) }
        }
        
        formattingCache[key] = result
    }
}

// MARK: - Static Factory Methods

extension LocalizedDateFormatter {
    
    /// Create a formatter optimized for Indian audience
    public static func indian() -> LocalizedDateFormatter {
        return LocalizedDateFormatter(configuration: .indian)
    }
    
    /// Create a formatter optimized for American audience
    public static func american() -> LocalizedDateFormatter {
        return LocalizedDateFormatter(configuration: .american)
    }
    
    /// Create a formatter optimized for British audience
    public static func british() -> LocalizedDateFormatter {
        return LocalizedDateFormatter(configuration: .british)
    }
    
    /// Create a formatter for accessibility
    public static func accessibility(for audience: PrimaryAudience) -> LocalizedDateFormatter {
        return LocalizedDateFormatter(configuration: .accessibility(for: audience))
    }
    
    /// Create a formatter for relative dates
    public static func relative(for audience: PrimaryAudience) -> LocalizedDateFormatter {
        return LocalizedDateFormatter(configuration: .relative(for: audience))
    }
    
    /// Create a formatter for financial contexts
    public static func financialYear(for audience: PrimaryAudience) -> LocalizedDateFormatter {
        return LocalizedDateFormatter(configuration: .financialYear(for: audience))
    }
}