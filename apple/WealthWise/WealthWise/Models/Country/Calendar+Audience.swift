import Foundation

/// Extensions to Foundation's Calendar for audience-specific calendar operations
extension Calendar {
    
    /// Create a calendar configured for a specific audience/cultural context
    public static func calendar(for culturalContext: String) -> Calendar {
        var calendar = Calendar.current
        
        // Configure first day of week based on cultural context
        switch culturalContext.lowercased() {
        case "american":
            calendar.firstWeekday = 1  // Sunday
        case "indian", "british", "european", "asian":
            calendar.firstWeekday = 2  // Monday
        default:
            calendar.firstWeekday = 2  // Monday (most common internationally)
        }
        
        return calendar
    }
    
    /// Get the financial year start date for a given year
    public func financialYearStart(for year: Int, startMonth: Int = 4) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = startMonth
        components.day = 1
        
        return self.date(from: components)
    }
    
    /// Get the financial year end date for a given year
    public func financialYearEnd(for year: Int, startMonth: Int = 4) -> Date? {
        let endMonth = startMonth == 1 ? 12 : startMonth - 1
        let endYear = startMonth == 1 ? year : year + 1
        
        var components = DateComponents()
        components.year = endYear
        components.month = endMonth
        components.day = self.range(of: .day, in: .month, for: self.date(from: components) ?? Date())?.upperBound ?? 31
        
        return self.date(from: components)
    }
    
    /// Check if a date falls within a specific financial year
    public func isDate(_ date: Date, inFinancialYear year: Int, startMonth: Int = 4) -> Bool {
        guard let startDate = financialYearStart(for: year, startMonth: startMonth),
              let endDate = financialYearEnd(for: year, startMonth: startMonth) else {
            return false
        }
        
        return date >= startDate && date <= endDate
    }
    
    /// Get the financial year for a given date
    public func financialYear(for date: Date, startMonth: Int = 4) -> Int {
        let year = self.component(.year, from: date)
        let month = self.component(.month, from: date)
        
        if startMonth == 1 {
            return year  // Calendar year
        } else if month >= startMonth {
            return year  // Financial year starts in current calendar year
        } else {
            return year - 1  // Financial year started in previous calendar year
        }
    }
    
    /// Get all months in a financial year
    public func monthsInFinancialYear(_ year: Int, startMonth: Int = 4) -> [Date] {
        guard let startDate = financialYearStart(for: year, startMonth: startMonth) else {
            return []
        }
        
        var months: [Date] = []
        var currentDate = startDate
        
        for _ in 0..<12 {
            months.append(currentDate)
            guard let nextMonth = self.date(byAdding: .month, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextMonth
        }
        
        return months
    }
    
    /// Get quarter information for a date in financial year context
    public func financialQuarter(for date: Date, startMonth: Int = 4) -> (quarter: Int, year: Int) {
        let financialYear = self.financialYear(for: date, startMonth: startMonth)
        let month = self.component(.month, from: date)
        
        let adjustedMonth = (month - startMonth + 12) % 12 + 1
        let quarter = (adjustedMonth - 1) / 3 + 1
        
        return (quarter: quarter, year: financialYear)
    }
    
    /// Get the start date of a financial quarter
    public func financialQuarterStart(quarter: Int, year: Int, startMonth: Int = 4) -> Date? {
        guard quarter >= 1 && quarter <= 4 else { return nil }
        
        let monthOffset = (quarter - 1) * 3
        let quarterStartMonth = (startMonth + monthOffset - 1) % 12 + 1
        let quarterYear = startMonth + monthOffset <= 12 ? year : year + 1
        
        var components = DateComponents()
        components.year = quarterYear
        components.month = quarterStartMonth
        components.day = 1
        
        return self.date(from: components)
    }
    
    /// Check if two dates are in the same financial year
    public func areDatesInSameFinancialYear(_ date1: Date, _ date2: Date, startMonth: Int = 4) -> Bool {
        let fy1 = financialYear(for: date1, startMonth: startMonth)
        let fy2 = financialYear(for: date2, startMonth: startMonth)
        return fy1 == fy2
    }
    
    /// Get business days between two dates (excluding weekends)
    public func businessDaysBetween(_ startDate: Date, and endDate: Date) -> Int {
        guard startDate <= endDate else { return 0 }
        
        var businessDays = 0
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = self.component(.weekday, from: currentDate)
            // Weekday 1 = Sunday, 7 = Saturday
            if weekday != 1 && weekday != 7 {
                businessDays += 1
            }
            guard let nextDay = self.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }
        
        return businessDays
    }
    
    /// Check if a date is a weekend
    public func isWeekend(_ date: Date) -> Bool {
        let weekday = self.component(.weekday, from: date)
        return weekday == 1 || weekday == 7  // Sunday or Saturday
    }
    
    /// Get the next business day (skipping weekends)
    public func nextBusinessDay(after date: Date) -> Date? {
        var nextDay = self.date(byAdding: .day, value: 1, to: date)
        
        while let day = nextDay, isWeekend(day) {
            nextDay = self.date(byAdding: .day, value: 1, to: day)
        }
        
        return nextDay
    }
    
    /// Get the previous business day (skipping weekends)
    public func previousBusinessDay(before date: Date) -> Date? {
        var previousDay = self.date(byAdding: .day, value: -1, to: date)
        
        while let day = previousDay, isWeekend(day) {
            previousDay = self.date(byAdding: .day, value: -1, to: day)
        }
        
        return previousDay
    }
}

// MARK: - Financial Year Utilities

/// Utility struct for financial year operations
public struct FinancialYear {
    public let year: Int
    public let startMonth: Int
    
    public init(year: Int, startMonth: Int = 4) {
        self.year = year
        self.startMonth = startMonth
    }
    
    /// Create financial year from a date
    public init(from date: Date, startMonth: Int = 4, calendar: Calendar = .current) {
        self.year = calendar.financialYear(for: date, startMonth: startMonth)
        self.startMonth = startMonth
    }
    
    /// Get the start date of this financial year
    public func startDate(calendar: Calendar = .current) -> Date? {
        return calendar.financialYearStart(for: year, startMonth: startMonth)
    }
    
    /// Get the end date of this financial year
    public func endDate(calendar: Calendar = .current) -> Date? {
        return calendar.financialYearEnd(for: year, startMonth: startMonth)
    }
    
    /// Get display string for this financial year
    public var displayString: String {
        if startMonth == 1 {
            return "\(year)"
        } else {
            return "FY \(year)-\(String(year + 1).suffix(2))"
        }
    }
    
    /// Get short display string for this financial year
    public var shortDisplayString: String {
        if startMonth == 1 {
            return "\(year)"
        } else {
            return "\(year)-\(String(year + 1).suffix(2))"
        }
    }
    
    /// Check if this financial year contains a specific date
    public func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        return calendar.isDate(date, inFinancialYear: year, startMonth: startMonth)
    }
    
    /// Get the next financial year
    public var next: FinancialYear {
        return FinancialYear(year: year + 1, startMonth: startMonth)
    }
    
    /// Get the previous financial year
    public var previous: FinancialYear {
        return FinancialYear(year: year - 1, startMonth: startMonth)
    }
}

// MARK: - FinancialYear Conformances

extension FinancialYear: Comparable {
    public static func < (lhs: FinancialYear, rhs: FinancialYear) -> Bool {
        return lhs.year < rhs.year
    }
}

extension FinancialYear: Equatable {
    public static func == (lhs: FinancialYear, rhs: FinancialYear) -> Bool {
        return lhs.year == rhs.year && lhs.startMonth == rhs.startMonth
    }
}

extension FinancialYear: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(startMonth)
    }
}

extension FinancialYear: Codable {}

extension FinancialYear: CustomStringConvertible {
    public var description: String {
        return displayString
    }
}