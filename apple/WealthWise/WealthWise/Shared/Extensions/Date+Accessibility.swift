import Foundation

/// Extensions to Date for accessibility features and VoiceOver support
extension Date {
    
    /// Generate accessibility-friendly description of this date
    /// - Parameter audience: The target audience for cultural context
    /// - Returns: VoiceOver-friendly date description
    public func accessibilityDescription(for audience: PrimaryAudience) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        
        return formatter.string(from: self)
    }
    
    /// Generate accessibility-friendly relative date description
    /// - Parameter audience: The target audience for cultural context
    /// - Returns: VoiceOver-friendly relative date description
    public func accessibilityRelativeDescription(for audience: PrimaryAudience) -> String {
        let now = Date()
        let daysDifference = daysBetween(now)
        
        // Handle special cases first
        if isToday {
            return NSLocalizedString("accessibility_today", comment: "Accessibility description for today")
        }
        
        if isYesterday {
            return NSLocalizedString("accessibility_yesterday", comment: "Accessibility description for yesterday")
        }
        
        if isTomorrow {
            return NSLocalizedString("accessibility_tomorrow", comment: "Accessibility description for tomorrow")
        }
        
        // Handle relative descriptions
        let absDay = abs(daysDifference)
        
        if absDay <= 7 {
            // Within a week
            if daysDifference < 0 {
                return String(format: NSLocalizedString("accessibility_days_ago", comment: "Accessibility: X days ago"), absDay)
            } else {
                return String(format: NSLocalizedString("accessibility_days_from_now", comment: "Accessibility: in X days"), absDay)
            }
        }
        
        // For longer periods, use absolute date with context
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        formatter.dateStyle = .medium
        
        let dateString = formatter.string(from: self)
        
        if daysDifference < 0 {
            return String(format: NSLocalizedString("accessibility_past_date", comment: "Accessibility: date in the past"), dateString)
        } else {
            return String(format: NSLocalizedString("accessibility_future_date", comment: "Accessibility: date in the future"), dateString)
        }
    }
    
    /// Generate accessibility description for financial year context
    /// - Parameter audience: The target audience for cultural context
    /// - Returns: VoiceOver-friendly financial year description
    public func accessibilityFinancialYearDescription(for audience: PrimaryAudience) -> String {
        let fy = financialYear(for: audience)
        let quarter = financialQuarter(for: audience)
        
        switch audience.financialYearType {
        case .aprilToMarch:
            return String(format: NSLocalizedString("accessibility_financial_year_fy", comment: "Accessibility: Financial Year FY format"), fy, quarter)
        case .januaryToDecember, .custom:
            return String(format: NSLocalizedString("accessibility_financial_year_standard", comment: "Accessibility: Standard year format"), fy, quarter)
        }
    }
    
    /// Generate short accessibility label for date inputs
    /// - Parameter audience: The target audience for cultural context
    /// - Returns: Short VoiceOver label for date controls
    public func accessibilityLabel(for audience: PrimaryAudience) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: self)
    }
    
    /// Generate accessibility hint for date controls
    /// - Parameter audience: The target audience for cultural context
    /// - Returns: VoiceOver hint for date interaction
    public func accessibilityHint(for audience: PrimaryAudience) -> String {
        return NSLocalizedString("accessibility_date_hint", comment: "Accessibility hint for date controls")
    }
    
    /// Generate accessibility value for date controls with additional context
    /// - Parameters:
    ///   - audience: The target audience for cultural context
    ///   - context: Additional context like "Transaction Date", "Due Date", etc.
    /// - Returns: VoiceOver value with context
    public func accessibilityValue(for audience: PrimaryAudience, context: String? = nil) -> String {
        let dateDescription = accessibilityLabel(for: audience)
        
        if let context = context {
            return String(format: NSLocalizedString("accessibility_date_with_context", comment: "Accessibility: date with context"), context, dateDescription)
        }
        
        return dateDescription
    }
    
    /// Generate pronunciation guide for date components
    /// - Parameter audience: The target audience for cultural context
    /// - Returns: Phonetic pronunciation guide for VoiceOver
    public func accessibilityPronunciationGuide(for audience: PrimaryAudience) -> String? {
        // This is particularly useful for non-English locales or special financial terms
        let fy = financialYear(for: audience)
        
        switch audience {
        case .indian:
            // Help with FY pronunciation in Indian context
            return String(format: NSLocalizedString("accessibility_fy_pronunciation", comment: "Pronunciation guide for Financial Year"), fy)
        default:
            return nil
        }
    }
    
    /// Check if this date requires special accessibility handling
    /// - Parameter audience: The target audience for cultural context
    /// - Returns: True if date needs special accessibility treatment
    public func requiresSpecialAccessibilityHandling(for audience: PrimaryAudience) -> Bool {
        // Special handling for financial year boundaries, religious dates, etc.
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)
        
        switch audience {
        case .indian:
            // Special handling for FY start/end dates
            return (month == 3 && day == 31) || (month == 4 && day == 1)
        default:
            // Special handling for calendar year boundaries
            return (month == 12 && day == 31) || (month == 1 && day == 1)
        }
    }
}