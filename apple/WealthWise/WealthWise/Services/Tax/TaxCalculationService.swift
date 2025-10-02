import Foundation
import Combine

/// Main tax calculation service providing high-level tax operations
/// Coordinates between jurisdiction engine, optimization, and treaty management
@MainActor
public final class TaxCalculationService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isCalculating: Bool = false
    @Published public private(set) var lastError: Error?
    @Published public private(set) var cachedCalculations: [String: TaxCalculation] = [:]
    
    // MARK: - Dependencies
    
    private let jurisdictionEngine: TaxJurisdictionEngine
    private let optimizationService: TaxOptimizationService
    
    // MARK: - Initialization
    
    public init(
        jurisdictionEngine: TaxJurisdictionEngine = .shared,
        optimizationService: TaxOptimizationService = TaxOptimizationService()
    ) {
        self.jurisdictionEngine = jurisdictionEngine
        self.optimizationService = optimizationService
    }
    
    // MARK: - Public Methods - Single Country Calculations
    
    /// Calculate tax for a single country
    /// - Parameters:
    ///   - countryCode: ISO 3166-1 alpha-3 country code
    ///   - grossIncome: Total gross income
    ///   - incomeBreakdown: Breakdown of income by type
    ///   - residencyStatus: Tax residency status
    ///   - deductions: Applicable deductions
    /// - Returns: Complete tax calculation result
    public func calculateTax(
        for countryCode: String,
        grossIncome: Decimal,
        incomeBreakdown: IncomeBreakdown,
        residencyStatus: ResidencyType,
        deductions: [TaxDeduction] = []
    ) async -> Result<TaxCalculation, Error> {
        
        isCalculating = true
        lastError = nil
        
        defer {
            isCalculating = false
        }
        
        do {
            let calculation = try await jurisdictionEngine.calculateTax(
                for: countryCode,
                grossIncome: grossIncome,
                incomeBreakdown: incomeBreakdown,
                residencyStatus: residencyStatus,
                deductions: deductions
            )
            
            // Cache the result
            cachedCalculations[countryCode] = calculation
            
            return .success(calculation)
            
        } catch {
            lastError = error
            return .failure(error)
        }
    }
    
    /// Calculate tax with simple income (convenience method)
    /// - Parameters:
    ///   - countryCode: Country code
    ///   - income: Total income amount
    ///   - residencyStatus: Residency status
    /// - Returns: Tax calculation result
    public func calculateSimpleTax(
        for countryCode: String,
        income: Decimal,
        residencyStatus: ResidencyType = .taxResident
    ) async -> Result<TaxCalculation, Error> {
        
        let breakdown = IncomeBreakdown(salary: income)
        
        return await calculateTax(
            for: countryCode,
            grossIncome: income,
            incomeBreakdown: breakdown,
            residencyStatus: residencyStatus,
            deductions: []
        )
    }
    
    // MARK: - Multi-Country Calculations
    
    /// Calculate tax across multiple countries for cross-border scenarios
    /// - Parameters:
    ///   - incomeByCountry: Income per country
    ///   - residencyByCountry: Residency status per country
    ///   - deductionsByCountry: Deductions per country
    /// - Returns: Dictionary of calculations by country
    public func calculateMultiCountryTax(
        incomeByCountry: [String: (Decimal, IncomeBreakdown)],
        residencyByCountry: [String: ResidencyType],
        deductionsByCountry: [String: [TaxDeduction]] = [:]
    ) async -> [String: TaxCalculation] {
        
        isCalculating = true
        
        let results = await jurisdictionEngine.calculateMultiCountryTax(
            incomeByCountry: incomeByCountry,
            residencyByCountry: residencyByCountry,
            deductionsByCountry: deductionsByCountry
        )
        
        // Cache all results
        for (country, calculation) in results {
            cachedCalculations[country] = calculation
        }
        
        isCalculating = false
        
        return results
    }
    
    /// Get total tax liability across all countries
    /// - Parameter calculations: Dictionary of calculations by country
    /// - Returns: Total tax in each currency
    public func getTotalTaxLiability(
        from calculations: [String: TaxCalculation]
    ) -> [String: Decimal] {
        
        var totalByCurrency: [String: Decimal] = [:]
        
        for (_, calculation) in calculations {
            let currency = calculation.currency
            let currentTotal = totalByCurrency[currency] ?? 0
            totalByCurrency[currency] = currentTotal + calculation.totalTax
        }
        
        return totalByCurrency
    }
    
    // MARK: - Tax Information Queries
    
    /// Get supported countries
    /// - Returns: Array of supported country codes
    public func getSupportedCountries() -> [String] {
        return jurisdictionEngine.getSupportedCountries()
    }
    
    /// Check if country is supported
    /// - Parameter countryCode: Country code to check
    /// - Returns: True if supported
    public func isCountrySupported(_ countryCode: String) -> Bool {
        return jurisdictionEngine.isSupported(countryCode: countryCode)
    }
    
    /// Get tax brackets for a country
    /// - Parameters:
    ///   - countryCode: Country code
    ///   - residencyStatus: Residency status
    /// - Returns: Array of tax brackets or nil if not available
    public func getTaxBrackets(
        for countryCode: String,
        residencyStatus: ResidencyType
    ) -> [TaxBracket]? {
        
        do {
            return try jurisdictionEngine.getTaxBrackets(
                for: countryCode,
                residencyStatus: residencyStatus
            )
        } catch {
            lastError = error
            return nil
        }
    }
    
    /// Get available deductions for a country
    /// - Parameters:
    ///   - countryCode: Country code
    ///   - residencyStatus: Residency status
    /// - Returns: Array of deduction types or nil if not available
    public func getAvailableDeductions(
        for countryCode: String,
        residencyStatus: ResidencyType
    ) -> [TaxDeductionType]? {
        
        do {
            return try jurisdictionEngine.getAvailableDeductions(
                for: countryCode,
                residencyStatus: residencyStatus
            )
        } catch {
            lastError = error
            return nil
        }
    }
    
    /// Get filing deadlines for a country
    /// - Parameter countryCode: Country code
    /// - Returns: Array of filing deadlines or nil if not available
    public func getFilingDeadlines(for countryCode: String) -> [FilingDeadline]? {
        do {
            return try jurisdictionEngine.getFilingDeadlines(for: countryCode)
        } catch {
            lastError = error
            return nil
        }
    }
    
    // MARK: - Tax Optimization
    
    /// Get tax optimization suggestions for a country
    /// - Parameters:
    ///   - countryCode: Country code
    ///   - calculation: Existing tax calculation
    /// - Returns: Array of optimization suggestions
    public func getOptimizationSuggestions(
        for countryCode: String,
        calculation: TaxCalculation
    ) async -> [TaxOptimizationSuggestion] {
        
        return await optimizationService.generateSuggestions(
            for: countryCode,
            calculation: calculation
        )
    }
    
    /// Compare tax burden between countries
    /// - Parameters:
    ///   - income: Income amount
    ///   - countryCodes: Countries to compare
    ///   - residencyStatus: Residency status
    /// - Returns: Dictionary of tax calculations by country
    public func compareTaxBurden(
        income: Decimal,
        across countryCodes: [String],
        residencyStatus: ResidencyType = .taxResident
    ) async -> [String: TaxCalculation] {
        
        var comparisons: [String: TaxCalculation] = [:]
        
        for countryCode in countryCodes {
            let result = await calculateSimpleTax(
                for: countryCode,
                income: income,
                residencyStatus: residencyStatus
            )
            
            if case .success(let calculation) = result {
                comparisons[countryCode] = calculation
            }
        }
        
        return comparisons
    }
    
    // MARK: - Cached Results
    
    /// Get cached calculation for a country
    /// - Parameter countryCode: Country code
    /// - Returns: Cached calculation if available
    public func getCachedCalculation(for countryCode: String) -> TaxCalculation? {
        return cachedCalculations[countryCode]
    }
    
    /// Clear cached calculations
    public func clearCache() {
        cachedCalculations.removeAll()
    }
    
    /// Clear cached calculation for specific country
    /// - Parameter countryCode: Country code
    public func clearCache(for countryCode: String) {
        cachedCalculations.removeValue(forKey: countryCode)
    }
}

// MARK: - Singleton Access
extension TaxCalculationService {
    public static let shared = TaxCalculationService()
}
