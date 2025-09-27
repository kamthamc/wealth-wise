import Foundation

/// Specialized formatter for relative date descriptions ("2 days ago", "next month", etc.)
/// Provides culturally appropriate relative date formatting for different audiences
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class RelativeDateFormatter {
    
    // MARK: - Properties
    
    /// Target audience for cultural adaptations
    public let audience: PrimaryAudience
    
    /// Underlying RelativeDateTimeFormatter for system-level relative formatting
    private let relativeDateTimeFormatter: RelativeDateTimeFormatter
    
    /// Regular date formatter for fallback
    private let dateFormatter: DateFormatter
    
    /// Calendar configured for the audience
    private let calendar: Calendar
    
    // MARK: - Initialization
    
    public init(audience: PrimaryAudience) {
        self.audience = audience
        self.relativeDateTimeFormatter = RelativeDateTimeFormatter()
        self.dateFormatter = DateFormatter()
        self.calendar = Calendar.calendar(for: audience)
        
        configureFormatters()
    }
    
    // MARK: - Public Methods
    
    /// Format a date as a relative string
    /// - Parameter date: The date to format
    /// - Returns: Relative date string (e.g., "2 days ago", "tomorrow")
    public func string(from date: Date) -> String {
        let now = Date()
        let daysDifference = date.daysBetween(now)
        
        // Handle special cases first
        if date.isToday {
            return NSLocalizedString("relative_today", comment: "Today")
        }
        
        if date.isYesterday {
            return NSLocalizedString("relative_yesterday", comment: "Yesterday")
        }
        
        if date.isTomorrow {
            return NSLocalizedString("relative_tomorrow", comment: "Tomorrow")
        }
        
        // Handle this week
        if date.isThisWeek {
            return weekdayString(for: date)
        }
        
        // Handle relative descriptions for longer periods
        return longerPeriodString(for: date, daysDifference: daysDifference)
    }
    
    /// Format a date as a short relative string (for compact displays)
    /// - Parameter date: The date to format
    /// - Returns: Short relative date string
    public func shortString(from date: Date) -> String {
        let now = Date()
        let daysDifference = date.daysBetween(now)
        
        if date.isToday {
            return NSLocalizedString("relative_today_short", comment: "Today (short)")
        }
        
        if date.isYesterday {
            return NSLocalizedString("relative_yesterday_short", comment: "Yesterday (short)")
        }
        
        if date.isTomorrow {
            return NSLocalizedString("relative_tomorrow_short", comment: "Tomorrow (short)")
        }
        
        // For other dates, use abbreviated format
        let absDay = abs(daysDifference)
        
        if absDay <= 7 {
            if daysDifference < 0 {
                return String(format: NSLocalizedString("relative_days_ago_short", comment: "X days ago (short)"), absDay)
            } else {
                return String(format: NSLocalizedString("relative_days_from_now_short", comment: "In X days (short)"), absDay)
            }
        }
        
        // Fall back to short date format
        dateFormatter.dateStyle = .short
        return dateFormatter.string(from: date)
    }
    
    /// Format a date with contextual relative information
    /// - Parameters:
    ///   - date: The date to format
    ///   - context: Context like "Due", "Transaction", etc.
    /// - Returns: Contextual relative date string
    public func contextualString(from date: Date, context: String) -> String {
        let relativeString = string(from: date)
        return String(format: NSLocalizedString("relative_with_context", comment: "Relative date with context"), context, relativeString)
    }
    
    /// Get the relative time difference as a descriptive string
    /// - Parameter date: The date to compare with now
    /// - Returns: Time difference description
    public func timeDifferenceString(from date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        let absInterval = abs(timeInterval)
        
        // Seconds
        if absInterval < 60 {
            let seconds = Int(absInterval)
            if timeInterval < 0 {
                return String(format: NSLocalizedString("relative_seconds_ago", comment: "X seconds ago"), seconds)
            } else {
                return String(format: NSLocalizedString("relative_seconds_from_now", comment: "In X seconds"), seconds)
            }
        }
        
        // Minutes
        if absInterval < 3600 {
            let minutes = Int(absInterval / 60)
            if timeInterval < 0 {
                return String(format: NSLocalizedString("relative_minutes_ago", comment: "X minutes ago"), minutes)
            } else {
                return String(format: NSLocalizedString("relative_minutes_from_now", comment: "In X minutes"), minutes)
            }
        }
        
        // Hours
        if absInterval < 86400 {
            let hours = Int(absInterval / 3600)
            if timeInterval < 0 {
                return String(format: NSLocalizedString("relative_hours_ago", comment: "X hours ago"), hours)
            } else {
                return String(format: NSLocalizedString("relative_hours_from_now", comment: "In X hours"), hours)
            }
        }
        
        // Fall back to day-based relative formatting
        return string(from: date)
    }
    
    /// Check if a date should use relative formatting
    /// - Parameter date: The date to check
    /// - Returns: True if relative formatting is appropriate
    public func shouldUseRelativeFormat(for date: Date) -> Bool {
        let daysDifference = abs(date.daysBetween(Date()))
        return daysDifference <= 30  // Use relative format for dates within 30 days
    }
    
    // MARK: - Private Methods
    
    private func configureFormatters() {
        // Configure relative formatter
        relativeDateTimeFormatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        relativeDateTimeFormatter.calendar = calendar
        relativeDateTimeFormatter.unitsStyle = .full
        
        // Configure fallback date formatter
        dateFormatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        dateFormatter.calendar = calendar
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
    }
    
    private func weekdayString(for date: Date) -> String {
        let daysDifference = date.daysBetween(Date())
        
        if abs(daysDifference) <= 1 {
            // Already handled by today/yesterday/tomorrow
            return string(from: date)
        }
        
        // Use weekday name
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        formatter.dateFormat = "EEEE"  // Full weekday name
        
        let weekdayName = formatter.string(from: date)
        
        if daysDifference < 0 {
            return String(format: NSLocalizedString("relative_last_weekday", comment: "Last [weekday]"), weekdayName)
        } else {
            return String(format: NSLocalizedString("relative_next_weekday", comment: "Next [weekday]"), weekdayName)
        }
    }
    
    private func longerPeriodString(for date: Date, daysDifference: Int) -> String {
        let absDay = abs(daysDifference)
        
        // Handle weeks
        if absDay <= 30 {
            let weeks = absDay / 7
            let remainingDays = absDay % 7
            
            if weeks > 0 {
                if daysDifference < 0 {
                    if remainingDays == 0 {
                        return String(format: NSLocalizedString("relative_weeks_ago", comment: "X weeks ago"), weeks)
                    } else {
                        return String(format: NSLocalizedString("relative_weeks_days_ago", comment: "X weeks Y days ago"), weeks, remainingDays)
                    }
                } else {
                    if remainingDays == 0 {
                        return String(format: NSLocalizedString("relative_weeks_from_now", comment: "In X weeks"), weeks)
                    } else {
                        return String(format: NSLocalizedString("relative_weeks_days_from_now", comment: "In X weeks Y days"), weeks, remainingDays)
                    }
                }
            } else {
                if daysDifference < 0 {
                    return String(format: NSLocalizedString("relative_days_ago", comment: "X days ago"), absDay)
                } else {
                    return String(format: NSLocalizedString("relative_days_from_now", comment: "In X days"), absDay)
                }
            }
        }
        
        // Handle months
        let monthsDifference = date.monthsBetween(Date())
        let absMonth = abs(monthsDifference)
        
        if absMonth <= 12 {
            if monthsDifference < 0 {
                return String(format: NSLocalizedString("relative_months_ago", comment: "X months ago"), absMonth)
            } else {
                return String(format: NSLocalizedString("relative_months_from_now", comment: "In X months"), absMonth)
            }
        }
        
        // Handle years
        let yearsDifference = date.yearsBetween(Date())
        let absYear = abs(yearsDifference)
        
        if yearsDifference < 0 {
            return String(format: NSLocalizedString("relative_years_ago", comment: "X years ago"), absYear)
        } else {
            return String(format: NSLocalizedString("relative_years_from_now", comment: "In X years"), absYear)
        }
    }
}

// MARK: - Static Factory Methods

extension RelativeDateFormatter {
    
    /// Create a formatter for Indian audience
    public static func indian() -> RelativeDateFormatter {
        return RelativeDateFormatter(audience: .indian)
    }
    
    /// Create a formatter for American audience
    public static func american() -> RelativeDateFormatter {
        return RelativeDateFormatter(audience: .american)
    }
    
    /// Create a formatter for British audience
    public static func british() -> RelativeDateFormatter {
        return RelativeDateFormatter(audience: .british)
    }
    
    /// Create a formatter for any audience
    public static func formatter(for audience: PrimaryAudience) -> RelativeDateFormatter {
        return RelativeDateFormatter(audience: audience)
    }
}