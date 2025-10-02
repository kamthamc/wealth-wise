import Foundation

/// Protocol that all country-specific tax calculators must implement
public protocol TaxCalculatorProtocol: Sendable {
    
    /// Country code for this calculator (ISO 3166-1 alpha-3)
    var countryCode: String { get }
    
    /// Tax year this calculator is configured for
    var taxYear: String { get }
    
    /// Currency used for calculations
    var currency: String { get }
    
    /// Calculate tax liability for given income and deductions
    /// - Parameters:
    ///   - grossIncome: Total gross income before deductions
    ///   - incomeBreakdown: Breakdown of income by type
    ///   - residencyStatus: Tax residency status
    ///   - deductions: List of applicable deductions
    /// - Returns: Complete tax calculation result
    func calculateTax(
        grossIncome: Decimal,
        incomeBreakdown: IncomeBreakdown,
        residencyStatus: ResidencyType,
        deductions: [TaxDeduction]
    ) async -> TaxCalculation
    
    /// Get tax brackets for the jurisdiction
    /// - Parameter residencyStatus: Residency status affects brackets in some countries
    /// - Returns: Array of tax brackets sorted by income level
    func getTaxBrackets(for residencyStatus: ResidencyType) -> [TaxBracket]
    
    /// Get available deductions for residency status
    /// - Parameter residencyStatus: Residency status affects available deductions
    /// - Returns: Array of deduction types available
    func getAvailableDeductions(for residencyStatus: ResidencyType) -> [TaxDeductionType]
    
    /// Calculate withholding tax on specific income type
    /// - Parameters:
    ///   - amount: Income amount
    ///   - incomeType: Type of income
    ///   - sourceCountry: Country where income originates
    /// - Returns: Withholding tax amount
    func calculateWithholdingTax(
        amount: Decimal,
        incomeType: IncomeType,
        sourceCountry: String
    ) async -> Decimal
    
    /// Get filing deadlines for the tax year
    /// - Returns: Array of filing deadline dates with descriptions
    func getFilingDeadlines() -> [FilingDeadline]
    
    /// Generate tax optimization suggestions
    /// - Parameters:
    ///   - grossIncome: Total gross income
    ///   - deductionsApplied: Deductions already claimed
    ///   - residencyStatus: Tax residency status
    /// - Returns: Array of optimization suggestions
    func generateOptimizationSuggestions(
        grossIncome: Decimal,
        deductionsApplied: [TaxDeduction],
        residencyStatus: ResidencyType
    ) async -> [TaxOptimizationSuggestion]
}

/// Types of income for tax purposes
public enum IncomeType: String, CaseIterable, Codable, Sendable {
    case salary = "salary"
    case business = "business"
    case capitalGains = "capitalGains"
    case dividend = "dividend"
    case interest = "interest"
    case rental = "rental"
    case royalty = "royalty"
    case pension = "pension"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .salary: return "Salary Income"
        case .business: return "Business Income"
        case .capitalGains: return "Capital Gains"
        case .dividend: return "Dividend Income"
        case .interest: return "Interest Income"
        case .rental: return "Rental Income"
        case .royalty: return "Royalty Income"
        case .pension: return "Pension Income"
        case .other: return "Other Income"
        }
    }
}

/// Filing deadline information
public struct FilingDeadline: Sendable, Codable, Hashable {
    public let date: Date
    public let description: String
    public let isRequired: Bool
    public let penaltyForMissing: String?
    
    public init(
        date: Date,
        description: String,
        isRequired: Bool = true,
        penaltyForMissing: String? = nil
    ) {
        self.date = date
        self.description = description
        self.isRequired = isRequired
        self.penaltyForMissing = penaltyForMissing
    }
}

/// Base tax calculator providing common functionality
@MainActor
open class BaseTaxCalculator: TaxCalculatorProtocol {
    
    public let countryCode: String
    public let taxYear: String
    public let currency: String
    
    public init(countryCode: String, taxYear: String, currency: String) {
        self.countryCode = countryCode
        self.taxYear = taxYear
        self.currency = currency
    }
    
    // Must be implemented by subclasses
    open func calculateTax(
        grossIncome: Decimal,
        incomeBreakdown: IncomeBreakdown,
        residencyStatus: ResidencyType,
        deductions: [TaxDeduction]
    ) async -> TaxCalculation {
        fatalError("Subclass must implement calculateTax")
    }
    
    open func getTaxBrackets(for residencyStatus: ResidencyType) -> [TaxBracket] {
        fatalError("Subclass must implement getTaxBrackets")
    }
    
    open func getAvailableDeductions(for residencyStatus: ResidencyType) -> [TaxDeductionType] {
        fatalError("Subclass must implement getAvailableDeductions")
    }
    
    open func calculateWithholdingTax(
        amount: Decimal,
        incomeType: IncomeType,
        sourceCountry: String
    ) async -> Decimal {
        // Default implementation - override if needed
        return 0
    }
    
    open func getFilingDeadlines() -> [FilingDeadline] {
        fatalError("Subclass must implement getFilingDeadlines")
    }
    
    open func generateOptimizationSuggestions(
        grossIncome: Decimal,
        deductionsApplied: [TaxDeduction],
        residencyStatus: ResidencyType
    ) async -> [TaxOptimizationSuggestion] {
        // Default implementation - can be overridden
        return []
    }
    
    // MARK: - Helper Methods
    
    /// Calculate progressive tax across multiple brackets
    nonisolated func calculateProgressiveTax(income: Decimal, brackets: [TaxBracket]) -> Decimal {
        var totalTax: Decimal = 0
        
        for bracket in brackets.sorted() {
            let taxInBracket = bracket.calculateTax(for: income)
            totalTax += taxInBracket
        }
        
        return totalTax
    }
    
    /// Determine marginal tax rate for given income
    nonisolated func getMarginalRate(income: Decimal, brackets: [TaxBracket]) -> Double {
        for bracket in brackets.sorted().reversed() {
            if bracket.applies(to: income) {
                return bracket.rate
            }
        }
        return 0
    }
    
    /// Calculate total deduction amount
    nonisolated func calculateTotalDeductions(_ deductions: [TaxDeduction]) -> Decimal {
        return deductions.reduce(0) { $0 + $1.effectiveAmount }
    }
}
