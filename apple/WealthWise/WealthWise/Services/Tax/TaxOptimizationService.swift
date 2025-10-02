import Foundation

/// Service for generating tax optimization suggestions and savings opportunities
@MainActor
public final class TaxOptimizationService {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Generate optimization suggestions based on tax calculation
    /// - Parameters:
    ///   - countryCode: Country code
    ///   - calculation: Current tax calculation
    /// - Returns: Array of optimization suggestions
    public func generateSuggestions(
        for countryCode: String,
        calculation: TaxCalculation
    ) async -> [TaxOptimizationSuggestion] {
        
        // Return suggestions already included in calculation
        // This can be enhanced with cross-country optimizations
        return calculation.optimizationSuggestions
    }
    
    /// Analyze potential tax savings from additional deductions
    /// - Parameters:
    ///   - currentCalculation: Current tax calculation
    ///   - additionalDeductions: Potential additional deductions
    ///   - countryCode: Country code
    /// - Returns: Estimated tax savings
    public func analyzePotentialSavings(
        currentCalculation: TaxCalculation,
        additionalDeductions: [TaxDeduction],
        countryCode: String
    ) async -> Decimal {
        
        let additionalAmount = additionalDeductions.reduce(Decimal(0)) { $0 + $1.effectiveAmount }
        let marginalRate = Decimal(currentCalculation.marginalRate / 100)
        
        return additionalAmount * marginalRate
    }
    
    /// Compare tax regimes (for countries with multiple regimes like India)
    /// - Parameters:
    ///   - income: Gross income
    ///   - deductions: Available deductions
    ///   - countryCode: Country code
    /// - Returns: Comparison of tax liabilities under different regimes
    public func compareRegimes(
        income: Decimal,
        deductions: [TaxDeduction],
        countryCode: String
    ) async -> [String: Decimal] {
        
        // This would require multiple calculations with different regime settings
        // For now, return empty - can be enhanced with actual calculations
        return [:]
    }
    
    /// Generate year-end tax planning suggestions
    /// - Parameters:
    ///   - calculation: Current year calculation
    ///   - monthsRemaining: Months remaining in tax year
    ///   - countryCode: Country code
    /// - Returns: Time-sensitive suggestions
    public func generateYearEndSuggestions(
        calculation: TaxCalculation,
        monthsRemaining: Int,
        countryCode: String
    ) async -> [TaxOptimizationSuggestion] {
        
        var suggestions: [TaxOptimizationSuggestion] = []
        
        if monthsRemaining <= 3 {
            // Urgent year-end suggestions
            suggestions.append(TaxOptimizationSuggestion(
                type: .deductionMaximization,
                title: "Year-End Tax Planning Deadline",
                description: "Only \(monthsRemaining) month(s) remaining to maximize deductions",
                potentialSaving: 0,
                currency: calculation.currency,
                priority: .high,
                actionRequired: "Review and maximize all available deductions before year-end",
                country: countryCode
            ))
        }
        
        return suggestions
    }
    
    /// Analyze cross-border tax optimization opportunities
    /// - Parameters:
    ///   - calculations: Tax calculations for multiple countries
    ///   - residencyStatuses: Residency status in each country
    /// - Returns: Cross-border optimization suggestions
    public func analyzeCrossBorderOptimization(
        calculations: [String: TaxCalculation],
        residencyStatuses: [String: ResidencyType]
    ) async -> [TaxOptimizationSuggestion] {
        
        var suggestions: [TaxOptimizationSuggestion] = []
        
        // Check for dual residency scenarios
        let residentCountries = residencyStatuses.filter { $0.value == .taxResident }.keys
        
        if residentCountries.count > 1 {
            suggestions.append(TaxOptimizationSuggestion(
                type: .residencyPlanning,
                title: "Dual Tax Residency Optimization",
                description: "Review tax treaty benefits for dual resident status",
                potentialSaving: 0,
                currency: "USD",
                priority: .high,
                actionRequired: "Consult tax advisor for treaty benefits and tie-breaker rules",
                country: "MULTI"
            ))
        }
        
        // Check for foreign tax credit opportunities
        let totalTax = calculations.values.reduce(Decimal(0)) { $0 + $1.totalTax }
        if totalTax > 0 && calculations.count > 1 {
            suggestions.append(TaxOptimizationSuggestion(
                type: .treatyBenefits,
                title: "Foreign Tax Credit Opportunity",
                description: "Claim foreign tax credits to avoid double taxation",
                potentialSaving: 0,
                currency: "USD",
                priority: .high,
                actionRequired: "File for foreign tax credits in home country",
                country: "MULTI"
            ))
        }
        
        return suggestions
    }
    
    /// Calculate tax efficiency score
    /// - Parameter calculation: Tax calculation
    /// - Returns: Score from 0-100 indicating tax efficiency
    public func calculateTaxEfficiencyScore(calculation: TaxCalculation) -> Double {
        // Simple efficiency score based on effective rate and deduction utilization
        let effectiveRate = calculation.effectiveRate
        let deductionRatio = calculation.totalDeductions > 0 ? 
            Double(truncating: (calculation.totalDeductions / calculation.grossIncome * 100) as NSNumber) : 0
        
        // Lower effective rate and higher deduction ratio = better efficiency
        let rateScore = max(0, 100 - effectiveRate)
        let deductionScore = min(100, deductionRatio * 2)
        
        return (rateScore + deductionScore) / 2
    }
    
    /// Generate deduction checklist for year-end planning
    /// - Parameters:
    ///   - countryCode: Country code
    ///   - residencyStatus: Residency status
    ///   - appliedDeductions: Already applied deductions
    /// - Returns: Checklist of deductions to consider
    public func generateDeductionChecklist(
        for countryCode: String,
        residencyStatus: ResidencyType,
        appliedDeductions: [TaxDeduction]
    ) async -> [DeductionChecklistItem] {
        
        // Get available deduction types for the country
        let engine = TaxJurisdictionEngine.shared
        
        guard let availableTypes = try? engine.getAvailableDeductions(
            for: countryCode,
            residencyStatus: residencyStatus
        ) else {
            return []
        }
        
        // Create checklist items
        let appliedTypes = Set(appliedDeductions.map { $0.type })
        
        return availableTypes.map { type in
            let isApplied = appliedTypes.contains(type)
            let appliedAmount = appliedDeductions
                .filter { $0.type == type }
                .reduce(Decimal(0)) { $0 + $1.amount }
            
            return DeductionChecklistItem(
                type: type,
                isApplied: isApplied,
                appliedAmount: isApplied ? appliedAmount : nil,
                maxAmount: type.maxAmount,
                remainingAmount: type.maxAmount.map { max(0, $0 - appliedAmount) }
            )
        }
    }
}

// MARK: - Supporting Types

/// Checklist item for deduction planning
public struct DeductionChecklistItem: Identifiable {
    public let id = UUID()
    public let type: TaxDeductionType
    public let isApplied: Bool
    public let appliedAmount: Decimal?
    public let maxAmount: Decimal?
    public let remainingAmount: Decimal?
    
    public var status: String {
        if isApplied {
            if let remaining = remainingAmount, remaining > 0 {
                return "Partially Used"
            } else {
                return "Maximized"
            }
        } else {
            return "Not Applied"
        }
    }
}
