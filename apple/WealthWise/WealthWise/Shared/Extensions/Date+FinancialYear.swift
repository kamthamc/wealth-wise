import Foundation

/// Extensions to Date for financial year calculations and date operations
/// Supports Indian Financial Year (April-March) and Western Calendar Year (January-December)
extension Date {
    
    // MARK: - Financial Year Operations
    
    /// Get the financial year for this date based on cultural preferences
    /// - Parameter audience: The audience/culture context determining FY calculation
    /// - Returns: The financial year as an integer
    public func financialYear(for audience: PrimaryAudience) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: self)
        let month = calendar.component(.month, from: self)
        
        switch audience.financialYearType {
        case .aprilToMarch:
            // Indian FY: If month is Jan-Mar, it's previous calendar year's FY
            return month >= 4 ? year : year - 1
        case .januaryToDecember:
            // Western calendar year
            return year
        case .custom(let startMonth):
            // Custom start month
            return month >= startMonth ? year : year - 1
        }
    }
    
    /// Get the start date of the financial year for this date
    /// - Parameter audience: The audience/culture context
    /// - Returns: The first day of the financial year
    public func financialYearStart(for audience: PrimaryAudience) -> Date {
        let calendar = Calendar.current
        let fy = financialYear(for: audience)
        
        var components = DateComponents()
        components.year = fy
        components.month = audience.financialYearType.startMonth
        components.day = 1
        
        return calendar.date(from: components) ?? self
    }
    
    /// Get the end date of the financial year for this date
    /// - Parameter audience: The audience/culture context
    /// - Returns: The last day of the financial year
    public func financialYearEnd(for audience: PrimaryAudience) -> Date {
        let calendar = Calendar.current
        let startDate = financialYearStart(for: audience)
        
        // Add 1 year and subtract 1 day
        guard let nextYearStart = calendar.date(byAdding: .year, value: 1, to: startDate),
              let endDate = calendar.date(byAdding: .day, value: -1, to: nextYearStart) else {
            return self
        }
        
        return endDate
    }
    
    /// Check if this date is in the same financial year as another date
    /// - Parameters:
    ///   - otherDate: The date to compare with
    ///   - audience: The audience/culture context
    /// - Returns: True if both dates are in the same financial year
    public func isInSameFinancialYear(as otherDate: Date, for audience: PrimaryAudience) -> Bool {
        return financialYear(for: audience) == otherDate.financialYear(for: audience)
    }
    
    /// Get the financial quarter (1-4) for this date
    /// - Parameter audience: The audience/culture context
    /// - Returns: Quarter number (1-4)
    public func financialQuarter(for audience: PrimaryAudience) -> Int {
        let calendar = Calendar.current
        let startDate = financialYearStart(for: audience)
        let monthsFromStart = calendar.dateComponents([.month], from: startDate, to: self).month ?? 0
        
        return min(4, max(1, (monthsFromStart / 3) + 1))
    }
    
    /// Get the quarter name in localized format
    /// - Parameter audience: The audience/culture context
    /// - Returns: Localized quarter name (e.g., "Q1 FY2024", "Q3 2024")
    public func financialQuarterName(for audience: PrimaryAudience) -> String {
        let quarter = financialQuarter(for: audience)
        let year = financialYear(for: audience)
        
        switch audience.financialYearType {
        case .aprilToMarch:
            return String(format: NSLocalizedString("financial_quarter_fy", comment: "Financial quarter with FY prefix"), quarter, year)
        case .januaryToDecember, .custom:
            return String(format: NSLocalizedString("financial_quarter_standard", comment: "Standard quarter format"), quarter, year)
        }
    }
    
    // MARK: - Relative Date Calculations
    
    /// Check if this date is today
    public var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if this date is yesterday
    public var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// Check if this date is tomorrow
    public var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Check if this date is in the current week
    public var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    /// Check if this date is in the current month
    public var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Check if this date is in the current year
    public var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }
    
    /// Get the number of days between this date and another date
    /// - Parameter otherDate: The date to compare with
    /// - Returns: Number of days (positive if otherDate is in the future)
    public func daysBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: otherDate)
        return components.day ?? 0
    }
    
    /// Get the number of months between this date and another date
    /// - Parameter otherDate: The date to compare with
    /// - Returns: Number of months
    public func monthsBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: self, to: otherDate)
        return components.month ?? 0
    }
    
    /// Get the number of years between this date and another date
    /// - Parameter otherDate: The date to compare with
    /// - Returns: Number of years
    public func yearsBetween(_ otherDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self, to: otherDate)
        return components.year ?? 0
    }
}

// MARK: - Financial Year Type

extension PrimaryAudience {
    /// The type of financial year used by this audience
    public var financialYearType: FinancialYearType {
        switch self {
        case .indian:
            return .aprilToMarch
        case .american, .canadian, .british, .australian, .singaporean:
            return .januaryToDecember
        case .german, .french, .dutch, .swiss, .irish, .luxembourgish:
            return .januaryToDecember
        case .japanese, .hongKongese, .newZealander, .malaysian, .thai, .filipino:
            return .januaryToDecember
        case .emirati, .qatari, .saudi:
            return .januaryToDecember
        case .brazilian, .mexican:
            return .januaryToDecember
        }
    }
}

/// Financial year calculation types
public enum FinancialYearType {
    case aprilToMarch        // Indian financial year
    case januaryToDecember   // Calendar year
    case custom(startMonth: Int)  // Custom start month
    
    public var startMonth: Int {
        switch self {
        case .aprilToMarch:
            return 4
        case .januaryToDecember:
            return 1
        case .custom(let month):
            return month
        }
    }
}