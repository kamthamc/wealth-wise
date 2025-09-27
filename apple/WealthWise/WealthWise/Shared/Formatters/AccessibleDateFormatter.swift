import Foundation
#if os(iOS)
import UIKit
#endif

/// Specialized formatter for accessibility and VoiceOver support
/// Provides clear, unambiguous date descriptions for screen readers
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class AccessibleDateFormatter {
    
    // MARK: - Properties
    
    /// Target audience for cultural adaptations
    public let audience: PrimaryAudience
    
    /// Primary date formatter for accessibility
    private let dateFormatter: DateFormatter
    
    /// Calendar configured for the audience
    private let calendar: Calendar
    
    /// Relative date formatter for contextual descriptions
    private let relativeDateFormatter: RelativeDateFormatter
    
    // MARK: - Initialization
    
    public init(audience: PrimaryAudience) {
        self.audience = audience
        self.dateFormatter = DateFormatter()
        self.calendar = Calendar.calendar(for: audience)
        self.relativeDateFormatter = RelativeDateFormatter(audience: audience)
        
        configureDateFormatter()
    }
    
    // MARK: - Public Methods
    
    /// Format a date for VoiceOver accessibility
    /// - Parameter date: The date to format
    /// - Returns: VoiceOver-friendly date string
    public func string(from date: Date) -> String {
        return date.accessibilityDescription(for: audience)
    }
    
    /// Format a date with relative context for accessibility
    /// - Parameter date: The date to format
    /// - Returns: Accessible relative date description
    public func relativeString(from date: Date) -> String {
        let relativeDescription = date.accessibilityRelativeDescription(for: audience)
        let absoluteDescription = string(from: date)
        
        // Combine relative and absolute for better context
        return String(format: NSLocalizedString("accessibility_relative_with_absolute", comment: "Relative date with absolute fallback"), relativeDescription, absoluteDescription)
    }
    
    /// Format a date with financial year context for accessibility
    /// - Parameter date: The date to format
    /// - Returns: Accessible financial year description
    public func financialYearString(from date: Date) -> String {
        let basicDescription = string(from: date)
        let fyDescription = date.accessibilityFinancialYearDescription(for: audience)
        
        return String(format: NSLocalizedString("accessibility_date_with_fy", comment: "Date with financial year context"), basicDescription, fyDescription)
    }
    
    /// Generate accessibility label for date input controls
    /// - Parameter date: The current date value
    /// - Returns: VoiceOver label for date controls
    public func accessibilityLabel(for date: Date) -> String {
        return date.accessibilityLabel(for: audience)
    }
    
    /// Generate accessibility hint for date controls
    /// - Parameter date: The current date value
    /// - Returns: VoiceOver hint for date interaction
    public func accessibilityHint(for date: Date) -> String {
        return date.accessibilityHint(for: audience)
    }
    
    /// Generate accessibility value with context
    /// - Parameters:
    ///   - date: The date to format
    ///   - context: Context like "Transaction Date", "Due Date"
    /// - Returns: VoiceOver value with context
    public func accessibilityValue(for date: Date, context: String? = nil) -> String {
        return date.accessibilityValue(for: audience, context: context)
    }
    
    /// Format a date range for accessibility
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    /// - Returns: Accessible date range description
    public func accessibilityString(from startDate: Date, to endDate: Date) -> String {
        let startDescription = string(from: startDate)
        let endDescription = string(from: endDate)
        
        return String(format: NSLocalizedString("accessibility_date_range", comment: "Accessible date range"), startDescription, endDescription)
    }
    
    /// Generate pronunciation guide for complex dates
    /// - Parameter date: The date that might need pronunciation help
    /// - Returns: Phonetic pronunciation guide if needed
    public func pronunciationGuide(for date: Date) -> String? {
        return date.accessibilityPronunciationGuide(for: audience)
    }
    
    /// Check if a date needs special accessibility handling
    /// - Parameter date: The date to check
    /// - Returns: True if special handling is needed
    public func needsSpecialHandling(for date: Date) -> Bool {
        return date.requiresSpecialAccessibilityHandling(for: audience)
    }
    
    /// Format date with business day context for accessibility
    /// - Parameter date: The date to format
    /// - Returns: Description including business day information
    public func businessDayString(from date: Date) -> String {
        let basicDescription = string(from: date)
        let isWeekend = calendar.isWeekend(date, for: audience)
        
        if isWeekend {
            return String(format: NSLocalizedString("accessibility_weekend_date", comment: "Weekend date description"), basicDescription)
        } else {
            return String(format: NSLocalizedString("accessibility_weekday_date", comment: "Weekday date description"), basicDescription)
        }
    }
    
    /// Format date with urgency context for accessibility
    /// - Parameters:
    ///   - date: The date to format
    ///   - urgency: Urgency level ("high", "medium", "low")
    /// - Returns: Date description with urgency information
    public func urgencyString(from date: Date, urgency: String) -> String {
        let basicDescription = string(from: date)
        let relativeDescription = relativeDateFormatter.string(from: date)
        
        let urgencyLevel = NSLocalizedString("accessibility_urgency_\(urgency)", comment: "Urgency level for accessibility")
        
        return String(format: NSLocalizedString("accessibility_urgent_date", comment: "Date with urgency context"), urgencyLevel, relativeDescription, basicDescription)
    }
    
    /// Format date for screen reader table cells
    /// - Parameters:
    ///   - date: The date to format
    ///   - columnContext: Context like "Due Date Column"
    /// - Returns: Table cell accessible description
    public func tableCellString(from date: Date, columnContext: String) -> String {
        let dateDescription = string(from: date)
        return String(format: NSLocalizedString("accessibility_table_cell_date", comment: "Date in table cell"), columnContext, dateDescription)
    }
    
    /// Format date for form validation accessibility
    /// - Parameters:
    ///   - date: The date to format
    ///   - isValid: Whether the date is valid
    ///   - validationMessage: Validation message if invalid
    /// - Returns: Accessible validation description
    public func validationString(from date: Date, isValid: Bool, validationMessage: String? = nil) -> String {
        let dateDescription = string(from: date)
        
        if isValid {
            return String(format: NSLocalizedString("accessibility_valid_date", comment: "Valid date description"), dateDescription)
        } else {
            let message = validationMessage ?? NSLocalizedString("accessibility_invalid_date_default", comment: "Default invalid date message")
            return String(format: NSLocalizedString("accessibility_invalid_date", comment: "Invalid date description"), dateDescription, message)
        }
    }
    
    // MARK: - Private Methods
    
    private func configureDateFormatter() {
        dateFormatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        dateFormatter.calendar = calendar
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        
        // Configure for accessibility - use spelled-out style where possible
        dateFormatter.formattingContext = .standalone
    }
}

// MARK: - Static Factory Methods

extension AccessibleDateFormatter {
    
    /// Create a formatter for Indian audience
    public static func indian() -> AccessibleDateFormatter {
        return AccessibleDateFormatter(audience: .indian)
    }
    
    /// Create a formatter for American audience
    public static func american() -> AccessibleDateFormatter {
        return AccessibleDateFormatter(audience: .american)
    }
    
    /// Create a formatter for British audience
    public static func british() -> AccessibleDateFormatter {
        return AccessibleDateFormatter(audience: .british)
    }
    
    /// Create a formatter for any audience
    public static func formatter(for audience: PrimaryAudience) -> AccessibleDateFormatter {
        return AccessibleDateFormatter(audience: audience)
    }
}

// MARK: - Accessibility Configuration Extensions

extension AccessibleDateFormatter {
    
    /// Configure for specific accessibility needs
    /// - Parameters:
    ///   - voiceOverEnabled: Whether VoiceOver is enabled
    ///   - preferredContentSize: User's preferred content size
    #if os(iOS)
    public func configureForAccessibility(voiceOverEnabled: Bool, preferredContentSize: UIContentSizeCategory) {
        if voiceOverEnabled {
            // Use more verbose descriptions for VoiceOver
            dateFormatter.dateStyle = .full
        } else {
            // Use standard descriptions
            dateFormatter.dateStyle = .medium
        }
        
        // Adjust verbosity based on content size
        if preferredContentSize.isAccessibilityCategory {
            dateFormatter.formattingContext = .standalone
        }
    }
    #else
    public func configureForAccessibility(voiceOverEnabled: Bool, preferredContentSize: String = "large") {
        if voiceOverEnabled {
            // Use more verbose descriptions for VoiceOver
            dateFormatter.dateStyle = .full
        } else {
            // Use standard descriptions
            dateFormatter.dateStyle = .medium
        }
        
        // Adjust verbosity based on content size
        if preferredContentSize.contains("accessibility") {
            dateFormatter.formattingContext = .standalone
        }
    }
    #endif
}