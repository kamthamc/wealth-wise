import Foundation

/// Engine for managing and routing tax calculations to appropriate calculators
@MainActor
public final class TaxJurisdictionEngine {
    
    // MARK: - Singleton
    
    public static let shared = TaxJurisdictionEngine()
    
    // MARK: - Properties
    
    private var calculators: [String: any TaxCalculatorProtocol] = [:]
    
    // MARK: - Initialization
    
    private init() {
        registerDefaultCalculators()
    }
    
    // MARK: - Public Methods
    
    /// Register a tax calculator for a specific country
    /// - Parameters:
    ///   - calculator: The tax calculator instance
    ///   - countryCode: ISO 3166-1 alpha-3 country code
    public func registerCalculator(_ calculator: any TaxCalculatorProtocol, for countryCode: String) {
        calculators[countryCode] = calculator
    }
    
    /// Get tax calculator for a specific country
    /// - Parameter countryCode: ISO 3166-1 alpha-3 country code
    /// - Returns: Tax calculator if available, nil otherwise
    public func getCalculator(for countryCode: String) -> (any TaxCalculatorProtocol)? {
        return calculators[countryCode]
    }
    
    /// Check if calculator is available for country
    /// - Parameter countryCode: ISO 3166-1 alpha-3 country code
    /// - Returns: True if calculator is registered
    public func isSupported(countryCode: String) -> Bool {
        return calculators[countryCode] != nil
    }
    
    /// Get all supported country codes
    /// - Returns: Array of supported country codes
    public func getSupportedCountries() -> [String] {
        return Array(calculators.keys).sorted()
    }
    
    /// Calculate tax for a specific country
    /// - Parameters:
    ///   - countryCode: ISO 3166-1 alpha-3 country code
    ///   - grossIncome: Total gross income
    ///   - incomeBreakdown: Breakdown of income by type
    ///   - residencyStatus: Tax residency status
    ///   - deductions: Applicable deductions
    /// - Returns: Tax calculation result
    /// - Throws: TaxEngineError if calculator not found
    public func calculateTax(
        for countryCode: String,
        grossIncome: Decimal,
        incomeBreakdown: IncomeBreakdown,
        residencyStatus: ResidencyType,
        deductions: [TaxDeduction]
    ) async throws -> TaxCalculation {
        
        guard let calculator = getCalculator(for: countryCode) else {
            throw TaxEngineError.calculatorNotFound(countryCode: countryCode)
        }
        
        return await calculator.calculateTax(
            grossIncome: grossIncome,
            incomeBreakdown: incomeBreakdown,
            residencyStatus: residencyStatus,
            deductions: deductions
        )
    }
    
    /// Calculate tax for multiple countries (for cross-border scenarios)
    /// - Parameters:
    ///   - incomeByCountry: Dictionary of country code to income breakdown
    ///   - residencyByCountry: Dictionary of country code to residency status
    ///   - deductionsByCountry: Dictionary of country code to deductions
    /// - Returns: Dictionary of country code to tax calculation
    public func calculateMultiCountryTax(
        incomeByCountry: [String: (Decimal, IncomeBreakdown)],
        residencyByCountry: [String: ResidencyType],
        deductionsByCountry: [String: [TaxDeduction]]
    ) async -> [String: TaxCalculation] {
        
        var results: [String: TaxCalculation] = [:]
        
        for (countryCode, (grossIncome, breakdown)) in incomeByCountry {
            guard let calculator = getCalculator(for: countryCode) else {
                continue
            }
            
            let residency = residencyByCountry[countryCode] ?? .nonResidentNotOrdinary
            let deductions = deductionsByCountry[countryCode] ?? []
            
            let calculation = await calculator.calculateTax(
                grossIncome: grossIncome,
                incomeBreakdown: breakdown,
                residencyStatus: residency,
                deductions: deductions
            )
            
            results[countryCode] = calculation
        }
        
        return results
    }
    
    /// Get tax brackets for a country
    /// - Parameters:
    ///   - countryCode: ISO 3166-1 alpha-3 country code
    ///   - residencyStatus: Residency status
    /// - Returns: Array of tax brackets
    /// - Throws: TaxEngineError if calculator not found
    public func getTaxBrackets(
        for countryCode: String,
        residencyStatus: ResidencyType
    ) throws -> [TaxBracket] {
        
        guard let calculator = getCalculator(for: countryCode) else {
            throw TaxEngineError.calculatorNotFound(countryCode: countryCode)
        }
        
        return calculator.getTaxBrackets(for: residencyStatus)
    }
    
    /// Get available deductions for a country
    /// - Parameters:
    ///   - countryCode: ISO 3166-1 alpha-3 country code
    ///   - residencyStatus: Residency status
    /// - Returns: Array of available deduction types
    /// - Throws: TaxEngineError if calculator not found
    public func getAvailableDeductions(
        for countryCode: String,
        residencyStatus: ResidencyType
    ) throws -> [TaxDeductionType] {
        
        guard let calculator = getCalculator(for: countryCode) else {
            throw TaxEngineError.calculatorNotFound(countryCode: countryCode)
        }
        
        return calculator.getAvailableDeductions(for: residencyStatus)
    }
    
    /// Get filing deadlines for a country
    /// - Parameter countryCode: ISO 3166-1 alpha-3 country code
    /// - Returns: Array of filing deadlines
    /// - Throws: TaxEngineError if calculator not found
    public func getFilingDeadlines(for countryCode: String) throws -> [FilingDeadline] {
        guard let calculator = getCalculator(for: countryCode) else {
            throw TaxEngineError.calculatorNotFound(countryCode: countryCode)
        }
        
        return calculator.getFilingDeadlines()
    }
    
    // MARK: - Private Methods
    
    private func registerDefaultCalculators() {
        // Register India calculator
        let indiaCalculator = IndiaTaxCalculator(taxYear: "2025-26", regime: .new)
        registerCalculator(indiaCalculator, for: "IND")
        
        // Register US calculator
        let usCalculator = USTaxCalculator(taxYear: "2025", filingStatus: .single)
        registerCalculator(usCalculator, for: "USA")
        
        // Register UK calculator
        let ukCalculator = UKTaxCalculator(taxYear: "2025-26")
        registerCalculator(ukCalculator, for: "GBR")
        registerCalculator(ukCalculator, for: "UK")  // Alias
        
        // Note: Canada, Australia, Singapore calculators can be added here
        // when implemented
    }
}

// MARK: - Tax Engine Error

public enum TaxEngineError: Error, LocalizedError {
    case calculatorNotFound(countryCode: String)
    case invalidInput(message: String)
    case calculationFailed(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .calculatorNotFound(let code):
            return "Tax calculator not found for country code: \(code)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .calculationFailed(let reason):
            return "Tax calculation failed: \(reason)"
        }
    }
}
