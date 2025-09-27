import Foundation

/// Configuration object for date formatters with cultural preferences
@available(iOS 18.6, macOS 15.6, *)
public struct DateFormatterConfiguration: Hashable {
    
    // MARK: - Core Properties
    
    /// The primary audience for cultural preferences
    public let audience: PrimaryAudience
    
    /// Preferred date style for formatting
    public let dateStyle: DateFormatter.Style
    
    /// Preferred time style for formatting
    public let timeStyle: DateFormatter.Style
    
    /// Whether to use relative date formatting when appropriate
    public let useRelativeFormatting: Bool
    
    /// Whether to show financial year context
    public let showFinancialYearContext: Bool
    
    /// Whether to use accessibility-optimized formatting
    public let accessibilityOptimized: Bool
    
    /// Custom date format string (overrides style if provided)
    public let customFormat: String?
    
    /// Time zone for date formatting
    public let timeZone: TimeZone
    
    // MARK: - Initialization
    
    public init(
        audience: PrimaryAudience,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none,
        useRelativeFormatting: Bool = false,
        showFinancialYearContext: Bool = false,
        accessibilityOptimized: Bool = false,
        customFormat: String? = nil,
        timeZone: TimeZone = .current
    ) {
        self.audience = audience
        self.dateStyle = dateStyle
        self.timeStyle = timeStyle
        self.useRelativeFormatting = useRelativeFormatting
        self.showFinancialYearContext = showFinancialYearContext
        self.accessibilityOptimized = accessibilityOptimized
        self.customFormat = customFormat
        self.timeZone = timeZone
    }
    
    // MARK: - Predefined Configurations
    
    /// Standard date configuration for Indian audience
    public static let indian = DateFormatterConfiguration(
        audience: .indian,
        dateStyle: .medium,
        showFinancialYearContext: true
    )
    
    /// Standard date configuration for American audience
    public static let american = DateFormatterConfiguration(
        audience: .american,
        dateStyle: .medium
    )
    
    /// Standard date configuration for British audience
    public static let british = DateFormatterConfiguration(
        audience: .british,
        dateStyle: .medium
    )
    
    /// Standard date configuration for Canadian audience
    public static let canadian = DateFormatterConfiguration(
        audience: .canadian,
        dateStyle: .medium
    )
    
    /// Accessibility-optimized configuration
    public static func accessibility(for audience: PrimaryAudience) -> DateFormatterConfiguration {
        return DateFormatterConfiguration(
            audience: audience,
            dateStyle: .full,
            timeStyle: .none,
            useRelativeFormatting: true,
            showFinancialYearContext: true,
            accessibilityOptimized: true
        )
    }
    
    /// Relative date configuration (for recent transactions, etc.)
    public static func relative(for audience: PrimaryAudience) -> DateFormatterConfiguration {
        return DateFormatterConfiguration(
            audience: audience,
            dateStyle: .medium,
            timeStyle: .none,
            useRelativeFormatting: true
        )
    }
    
    /// Financial year context configuration
    public static func financialYear(for audience: PrimaryAudience) -> DateFormatterConfiguration {
        return DateFormatterConfiguration(
            audience: audience,
            dateStyle: .medium,
            timeStyle: .none,
            showFinancialYearContext: true
        )
    }
    
    /// Short date configuration (for compact displays)
    public static func compact(for audience: PrimaryAudience) -> DateFormatterConfiguration {
        return DateFormatterConfiguration(
            audience: audience,
            dateStyle: .short,
            timeStyle: .none
        )
    }
    
    /// Full datetime configuration
    public static func fullDateTime(for audience: PrimaryAudience) -> DateFormatterConfiguration {
        return DateFormatterConfiguration(
            audience: audience,
            dateStyle: .full,
            timeStyle: .medium
        )
    }
    
    // MARK: - Cultural Format Patterns
    
    /// Get the cultural date format pattern for this configuration
    public var culturalDateFormat: String {
        if let customFormat = customFormat {
            return customFormat
        }
        
        switch audience {
        case .indian, .british, .australian, .newZealander, .singaporean:
            return "dd/MM/yyyy"  // DD/MM/YYYY format
        case .american, .canadian, .filipino:
            return "MM/dd/yyyy"  // MM/DD/YYYY format
        case .japanese, .hongKongese:
            return "yyyy/MM/dd"  // YYYY/MM/DD format
        case .german, .french, .dutch, .swiss, .irish, .luxembourgish:
            return "dd.MM.yyyy"  // DD.MM.YYYY format
        case .malaysian, .thai:
            return "dd/MM/yyyy"  // DD/MM/YYYY format
        case .emirati, .qatari, .saudi:
            return "dd/MM/yyyy"  // DD/MM/YYYY format (English format in financial contexts)
        case .brazilian:
            return "dd/MM/yyyy"  // DD/MM/YYYY format
        case .mexican:
            return "dd/MM/yyyy"  // DD/MM/YYYY format
        }
    }
    
    /// Get the cultural time format pattern for this configuration
    public var culturalTimeFormat: String {
        let use24Hour = audience.prefers24HourTime
        
        switch timeStyle {
        case .none:
            return ""
        case .short:
            return use24Hour ? "HH:mm" : "h:mm a"
        case .medium:
            return use24Hour ? "HH:mm:ss" : "h:mm:ss a"
        case .long:
            return use24Hour ? "HH:mm:ss z" : "h:mm:ss a z"
        case .full:
            return use24Hour ? "HH:mm:ss zzzz" : "h:mm:ss a zzzz"
        @unknown default:
            return use24Hour ? "HH:mm" : "h:mm a"
        }
    }
    
    /// Get the locale for this configuration
    public var locale: Locale {
        return Locale(identifier: audience.preferredLocaleIdentifier)
    }
    
    /// Get the calendar for this configuration
    public var calendar: Calendar {
        return Calendar.calendar(for: audience)
    }
    
    // MARK: - Hashable & Codable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(audience)
        hasher.combine(dateStyle)
        hasher.combine(timeStyle)
        hasher.combine(useRelativeFormatting)
        hasher.combine(showFinancialYearContext)
        hasher.combine(accessibilityOptimized)
        hasher.combine(customFormat)
        hasher.combine(timeZone.identifier)
    }
}

// MARK: - DateFormatterConfiguration Extensions

extension DateFormatterConfiguration {
    
    /// Create a copy of this configuration with modified properties
    public func with(
        dateStyle: DateFormatter.Style? = nil,
        timeStyle: DateFormatter.Style? = nil,
        useRelativeFormatting: Bool? = nil,
        showFinancialYearContext: Bool? = nil,
        accessibilityOptimized: Bool? = nil,
        customFormat: String? = nil,
        timeZone: TimeZone? = nil
    ) -> DateFormatterConfiguration {
        return DateFormatterConfiguration(
            audience: self.audience,
            dateStyle: dateStyle ?? self.dateStyle,
            timeStyle: timeStyle ?? self.timeStyle,
            useRelativeFormatting: useRelativeFormatting ?? self.useRelativeFormatting,
            showFinancialYearContext: showFinancialYearContext ?? self.showFinancialYearContext,
            accessibilityOptimized: accessibilityOptimized ?? self.accessibilityOptimized,
            customFormat: customFormat ?? self.customFormat,
            timeZone: timeZone ?? self.timeZone
        )
    }
}