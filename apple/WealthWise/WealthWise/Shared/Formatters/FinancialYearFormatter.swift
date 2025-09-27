import Foundation

/// Specialized formatter for financial year contexts and tax year boundaries
/// Handles Indian FY (April-March) vs Western calendar year formatting
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class FinancialYearFormatter {
    
    // MARK: - Properties
    
    /// Target audience for financial year calculations
    public let audience: PrimaryAudience
    
    /// Underlying date formatter
    private let dateFormatter: DateFormatter
    
    /// Calendar configured for the audience
    private let calendar: Calendar
    
    // MARK: - Initialization
    
    public init(audience: PrimaryAudience) {
        self.audience = audience
        self.dateFormatter = DateFormatter()
        self.calendar = Calendar.calendar(for: audience)
        
        configureDateFormatter()
    }
    
    // MARK: - Public Methods
    
    /// Format a date with financial year context
    /// - Parameter date: The date to format
    /// - Returns: Date string with financial year information
    public func string(from date: Date) -> String {
        let basicDateString = dateFormatter.string(from: date)
        let fyContext = financialYearContext(for: date)
        
        return String(format: NSLocalizedString("date_with_financial_year", comment: "Date with financial year context"), basicDateString, fyContext)
    }
    
    /// Get just the financial year label for a date
    /// - Parameter date: The date to get FY for
    /// - Returns: Financial year string (e.g., "FY2024", "2024")
    public func financialYearLabel(for date: Date) -> String {
        let fy = date.financialYear(for: audience)
        
        switch audience.financialYearType {
        case .aprilToMarch:
            return String(format: NSLocalizedString("financial_year_fy_format", comment: "FY format for Indian financial year"), fy)
        case .januaryToDecember, .custom:
            return String(format: NSLocalizedString("financial_year_standard_format", comment: "Standard year format"), fy)
        }
    }
    
    /// Get the financial quarter label for a date
    /// - Parameter date: The date to get quarter for
    /// - Returns: Quarter string (e.g., "Q1 FY2024", "Q3 2024")
    public func quarterLabel(for date: Date) -> String {
        return date.financialQuarterName(for: audience)
    }
    
    /// Format a financial year range (start to end dates)
    /// - Parameter date: Any date within the financial year
    /// - Returns: Financial year range string
    public func financialYearRange(for date: Date) -> String {
        let startDate = date.financialYearStart(for: audience)
        let endDate = date.financialYearEnd(for: audience)
        
        let rangeFormatter = DateFormatter()
        rangeFormatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        rangeFormatter.dateFormat = "MMM yyyy"
        
        let startString = rangeFormatter.string(from: startDate)
        let endString = rangeFormatter.string(from: endDate)
        
        return String(format: NSLocalizedString("financial_year_range", comment: "Financial year range format"), startString, endString)
    }
    
    /// Check if a date is at the beginning of a financial year
    /// - Parameter date: The date to check
    /// - Returns: True if date is within first month of FY
    public func isFinancialYearStart(_ date: Date) -> Bool {
        let fyStart = date.financialYearStart(for: audience)
        return calendar.isDate(date, equalTo: fyStart, toGranularity: .month)
    }
    
    /// Check if a date is at the end of a financial year
    /// - Parameter date: The date to check
    /// - Returns: True if date is within last month of FY
    public func isFinancialYearEnd(_ date: Date) -> Bool {
        let fyEnd = date.financialYearEnd(for: audience)
        return calendar.isDate(date, equalTo: fyEnd, toGranularity: .month)
    }
    
    /// Get the number of days remaining in the current financial year
    /// - Parameter date: The reference date
    /// - Returns: Days remaining in financial year
    public func daysRemainingInFinancialYear(from date: Date) -> Int {
        let fyEnd = date.financialYearEnd(for: audience)
        return date.daysBetween(fyEnd)
    }
    
    /// Get the number of days elapsed in the current financial year
    /// - Parameter date: The reference date
    /// - Returns: Days elapsed in financial year
    public func daysElapsedInFinancialYear(from date: Date) -> Int {
        let fyStart = date.financialYearStart(for: audience)
        return fyStart.daysBetween(date)
    }
    
    /// Format a date with tax year context (important for tax calculations)
    /// - Parameter date: The date to format
    /// - Returns: Date string with tax year information
    public func taxYearString(from date: Date) -> String {
        let basicDateString = dateFormatter.string(from: date)
        let taxYear = date.financialYear(for: audience)
        
        switch audience {
        case .indian:
            // Indian tax year is same as financial year (April-March)
            return String(format: NSLocalizedString("date_with_tax_year_india", comment: "Date with Indian tax year"), basicDateString, taxYear)
        default:
            // Most other countries use calendar year for tax
            return String(format: NSLocalizedString("date_with_tax_year_standard", comment: "Date with standard tax year"), basicDateString, taxYear)
        }
    }
    
    /// Get financial year progress as percentage
    /// - Parameter date: The reference date
    /// - Returns: Progress through financial year (0.0 - 1.0)
    public func financialYearProgress(for date: Date) -> Double {
        let fyStart = date.financialYearStart(for: audience)
        let fyEnd = date.financialYearEnd(for: audience)
        
        let totalDays = fyStart.daysBetween(fyEnd)
        let elapsedDays = fyStart.daysBetween(date)
        
        guard totalDays > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(elapsedDays) / Double(totalDays)))
    }
    
    // MARK: - Private Methods
    
    private func configureDateFormatter() {
        dateFormatter.locale = Locale(identifier: audience.preferredLocaleIdentifier)
        dateFormatter.calendar = calendar
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
    }
    
    private func financialYearContext(for date: Date) -> String {
        let fy = date.financialYear(for: audience)
        let quarter = date.financialQuarter(for: audience)
        
        switch audience.financialYearType {
        case .aprilToMarch:
            return String(format: NSLocalizedString("financial_context_fy", comment: "FY context with quarter"), quarter, fy)
        case .januaryToDecember, .custom:
            return String(format: NSLocalizedString("financial_context_standard", comment: "Standard year context with quarter"), quarter, fy)
        }
    }
}

// MARK: - Static Factory Methods

extension FinancialYearFormatter {
    
    /// Create a formatter for Indian financial year
    public static func indian() -> FinancialYearFormatter {
        return FinancialYearFormatter(audience: .indian)
    }
    
    /// Create a formatter for American calendar year
    public static func american() -> FinancialYearFormatter {
        return FinancialYearFormatter(audience: .american)
    }
    
    /// Create a formatter for British calendar year
    public static func british() -> FinancialYearFormatter {
        return FinancialYearFormatter(audience: .british)
    }
    
    /// Create a formatter for any audience
    public static func formatter(for audience: PrimaryAudience) -> FinancialYearFormatter {
        return FinancialYearFormatter(audience: audience)
    }
}