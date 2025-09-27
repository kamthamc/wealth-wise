import Foundation

/// Extensions to Calendar for audience-specific calendar operations and cultural adaptations
extension Calendar {
    
    /// Create a calendar configured for a specific audience
    /// - Parameter audience: The target audience for cultural calendar preferences
    /// - Returns: Configured Calendar instance
    public static func calendar(for audience: PrimaryAudience) -> Calendar {
        var calendar = Calendar.current
        
        // Configure first day of week based on cultural preferences
        calendar.firstWeekday = audience.firstWeekday
        
        // Configure time zone if needed (most apps use system timezone)
        // calendar.timeZone = audience.preferredTimeZone
        
        return calendar
    }
    
    /// Get localized month names for the audience
    /// - Parameter audience: The target audience
    /// - Returns: Array of localized month names
    public func monthNames(for audience: PrimaryAudience) -> [String] {
        let locale = Locale(identifier: audience.preferredLocaleIdentifier)
        let formatter = DateFormatter()
        formatter.locale = locale
        return formatter.monthSymbols
    }
    
    /// Get localized abbreviated month names for the audience
    /// - Parameter audience: The target audience
    /// - Returns: Array of localized abbreviated month names
    public func shortMonthNames(for audience: PrimaryAudience) -> [String] {
        let locale = Locale(identifier: audience.preferredLocaleIdentifier)
        let formatter = DateFormatter()
        formatter.locale = locale
        return formatter.shortMonthSymbols
    }
    
    /// Get localized weekday names for the audience
    /// - Parameter audience: The target audience
    /// - Returns: Array of localized weekday names
    public func weekdayNames(for audience: PrimaryAudience) -> [String] {
        let locale = Locale(identifier: audience.preferredLocaleIdentifier)
        let formatter = DateFormatter()
        formatter.locale = locale
        return formatter.weekdaySymbols
    }
    
    /// Get localized short weekday names for the audience
    /// - Parameter audience: The target audience
    /// - Returns: Array of localized short weekday names
    public func shortWeekdayNames(for audience: PrimaryAudience) -> [String] {
        let locale = Locale(identifier: audience.preferredLocaleIdentifier)
        let formatter = DateFormatter()
        formatter.locale = locale
        return formatter.shortWeekdaySymbols
    }
    
    /// Check if a date is a weekend based on audience preferences
    /// - Parameters:
    ///   - date: The date to check
    ///   - audience: The target audience for weekend definitions
    /// - Returns: True if the date is a weekend
    public func isWeekend(_ date: Date, for audience: PrimaryAudience) -> Bool {
        let weekday = component(.weekday, from: date)
        return audience.weekendDays.contains(weekday)
    }
    
    /// Get the next business day for a given date and audience
    /// - Parameters:
    ///   - date: The starting date
    ///   - audience: The target audience for business day rules
    /// - Returns: The next business day
    public func nextBusinessDay(after date: Date, for audience: PrimaryAudience) -> Date {
        var nextDay = date
        repeat {
            guard let candidateDate = self.date(byAdding: .day, value: 1, to: nextDay) else {
                return date
            }
            nextDay = candidateDate
        } while isWeekend(nextDay, for: audience)
        
        return nextDay
    }
    
    /// Get the previous business day for a given date and audience
    /// - Parameters:
    ///   - date: The starting date
    ///   - audience: The target audience for business day rules
    /// - Returns: The previous business day
    public func previousBusinessDay(before date: Date, for audience: PrimaryAudience) -> Date {
        var previousDay = date
        repeat {
            guard let candidateDate = self.date(byAdding: .day, value: -1, to: previousDay) else {
                return date
            }
            previousDay = candidateDate
        } while isWeekend(previousDay, for: audience)
        
        return previousDay
    }
    
    /// Calculate the number of business days between two dates
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    ///   - audience: The target audience for business day rules
    /// - Returns: Number of business days
    public func businessDaysBetween(_ startDate: Date, and endDate: Date, for audience: PrimaryAudience) -> Int {
        let calendar = self
        var businessDays = 0
        var currentDate = startDate
        
        while currentDate < endDate {
            if !isWeekend(currentDate, for: audience) {
                businessDays += 1
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return businessDays
    }
}

// MARK: - PrimaryAudience Calendar Extensions

extension PrimaryAudience {
    
    /// First day of week for this audience (1=Sunday, 2=Monday, etc.)
    public var firstWeekday: Int {
        switch self {
        case .american, .canadian, .brazilian, .mexican:
            return 1  // Sunday
        case .indian, .british, .australian, .singaporean:
            return 2  // Monday
        case .german, .french, .dutch, .swiss, .irish, .luxembourgish:
            return 2  // Monday
        case .japanese, .hongKongese, .newZealander, .malaysian, .thai, .filipino:
            return 2  // Monday (most Asian countries)
        case .emirati, .qatari, .saudi:
            return 7  // Saturday (many Middle Eastern countries)
        }
    }
    
    /// Weekend days for this audience (1=Sunday, 2=Monday, etc.)
    public var weekendDays: Set<Int> {
        switch self {
        case .american, .canadian, .brazilian, .mexican, .indian, .british, .australian, .singaporean:
            return [1, 7]  // Saturday and Sunday
        case .german, .french, .dutch, .swiss, .irish, .luxembourgish:
            return [1, 7]  // Saturday and Sunday
        case .japanese, .hongKongese, .newZealander, .malaysian, .thai, .filipino:
            return [1, 7]  // Saturday and Sunday
        case .emirati, .qatari, .saudi:
            return [6, 7]  // Friday and Saturday
        }
    }
    
    /// Preferred locale identifier for this audience
    public var preferredLocaleIdentifier: String {
        switch self {
        case .indian:
            return "en_IN"
        case .american:
            return "en_US"
        case .british:
            return "en_GB"
        case .canadian:
            return "en_CA"
        case .australian:
            return "en_AU"
        case .singaporean:
            return "en_SG"
        case .german:
            return "de_DE"
        case .french:
            return "fr_FR"
        case .dutch:
            return "nl_NL"
        case .swiss:
            return "de_CH"
        case .irish:
            return "en_IE"
        case .luxembourgish:
            return "fr_LU"
        case .japanese:
            return "ja_JP"
        case .hongKongese:
            return "en_HK"
        case .newZealander:
            return "en_NZ"
        case .malaysian:
            return "en_MY"
        case .thai:
            return "th_TH"
        case .filipino:
            return "en_PH"
        case .emirati:
            return "ar_AE"
        case .qatari:
            return "ar_QA"
        case .saudi:
            return "ar_SA"
        case .brazilian:
            return "pt_BR"
        case .mexican:
            return "es_MX"
        }
    }
    
    /// Whether this audience uses 12-hour or 24-hour time format preference
    public var prefers24HourTime: Bool {
        switch self {
        case .american, .canadian, .filipino:
            return false  // 12-hour preference
        default:
            return true   // 24-hour preference
        }
    }
}