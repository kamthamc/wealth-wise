import Foundation

/// US tax calculator implementing federal income tax
/// Supports single, married filing jointly, and head of household filing statuses
@MainActor
public final class USTaxCalculator: BaseTaxCalculator {
    
    // MARK: - Filing Status
    
    public enum FilingStatus: String, Codable, Sendable {
        case single = "single"
        case marriedJoint = "marriedJoint"
        case marriedSeparate = "marriedSeparate"
        case headOfHousehold = "headOfHousehold"
        
        var displayName: String {
            switch self {
            case .single: return "Single"
            case .marriedJoint: return "Married Filing Jointly"
            case .marriedSeparate: return "Married Filing Separately"
            case .headOfHousehold: return "Head of Household"
            }
        }
    }
    
    private let filingStatus: FilingStatus
    
    // MARK: - Initialization
    
    public init(taxYear: String = "2025", filingStatus: FilingStatus = .single) {
        self.filingStatus = filingStatus
        super.init(countryCode: "USA", taxYear: taxYear, currency: "USD")
    }
    
    // MARK: - TaxCalculatorProtocol Implementation
    
    public override func calculateTax(
        grossIncome: Decimal,
        incomeBreakdown: IncomeBreakdown,
        residencyStatus: ResidencyType,
        deductions: [TaxDeduction]
    ) async -> TaxCalculation {
        
        // Standard deduction for 2025
        let standardDeduction = getStandardDeduction()
        
        // Use standard deduction or itemized, whichever is higher
        let itemizedDeductions = calculateTotalDeductions(deductions)
        let totalDeductions = max(standardDeduction, itemizedDeductions)
        
        // Calculate taxable income
        let taxableIncome = max(0, grossIncome - totalDeductions)
        
        // Get tax brackets
        let brackets = getTaxBrackets(for: residencyStatus)
        
        // Calculate federal tax
        let federalTax = calculateProgressiveTax(income: taxableIncome, brackets: brackets)
        
        // Calculate rates
        let effectiveRate = taxableIncome > 0 ? Double(truncating: (federalTax / taxableIncome * 100) as NSNumber) : 0
        let marginalRate = getMarginalRate(income: taxableIncome, brackets: brackets) * 100
        
        // Build tax breakdown
        let taxBreakdown = buildTaxBreakdown(
            federalTax: federalTax,
            brackets: brackets,
            taxableIncome: taxableIncome
        )
        
        // Get filing requirements
        let filingReqs = getFilingRequirements(income: grossIncome, residencyStatus: residencyStatus)
        
        // Generate optimization suggestions
        let suggestions = await generateOptimizationSuggestions(
            grossIncome: grossIncome,
            deductionsApplied: deductions,
            residencyStatus: residencyStatus
        )
        
        return TaxCalculation(
            country: countryCode,
            taxYear: taxYear,
            grossIncome: grossIncome,
            currency: currency,
            incomeBreakdown: incomeBreakdown,
            totalDeductions: totalDeductions,
            deductionsApplied: deductions,
            taxableIncome: taxableIncome,
            taxLiability: federalTax,
            effectiveRate: effectiveRate,
            marginalRate: marginalRate,
            taxBreakdown: taxBreakdown,
            residencyStatus: residencyStatus,
            filingRequirements: filingReqs,
            optimizationSuggestions: suggestions
        )
    }
    
    public override func getTaxBrackets(for residencyStatus: ResidencyType) -> [TaxBracket] {
        return getBracketsForFilingStatus()
    }
    
    public override func getAvailableDeductions(for residencyStatus: ResidencyType) -> [TaxDeductionType] {
        return [
            .standardDeduction,
            .ira401k,
            .mortgageInterest,
            .stateLocalTax,
            .charitableContributions,
            .studentLoanInterest,
            .medicalExpenses
        ]
    }
    
    public override func calculateWithholdingTax(
        amount: Decimal,
        incomeType: IncomeType,
        sourceCountry: String
    ) async -> Decimal {
        // Withholding rates for non-residents
        let rate: Double
        switch incomeType {
        case .dividend:
            rate = 0.30  // 30% for non-resident aliens
        case .interest:
            rate = 0.30  // 30% unless treaty applies
        case .rental:
            rate = 0.30  // 30% withholding
        case .capitalGains:
            rate = 0.30  // Generally not taxed for NRAs unless real estate
        default:
            rate = 0.30  // Default 30%
        }
        
        return amount * Decimal(rate)
    }
    
    public override func getFilingDeadlines() -> [FilingDeadline] {
        let calendar = Calendar.current
        let currentYear = Int(taxYear) ?? 2025
        
        var deadlines: [FilingDeadline] = []
        
        // April 15 - Tax filing deadline
        if let april15 = calendar.date(from: DateComponents(year: currentYear, month: 4, day: 15)) {
            deadlines.append(FilingDeadline(
                date: april15,
                description: "Federal tax return filing deadline",
                penaltyForMissing: "Late filing penalty of 5% per month (max 25%)"
            ))
        }
        
        // Quarterly estimated tax payments
        let quarterlyDates = [
            (4, 15, "Q1 Estimated Tax"),
            (6, 15, "Q2 Estimated Tax"),
            (9, 15, "Q3 Estimated Tax"),
            (1, 15, "Q4 Estimated Tax (next year)")
        ]
        
        for (month, day, desc) in quarterlyDates {
            let year = month == 1 ? currentYear + 1 : currentYear
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                deadlines.append(FilingDeadline(
                    date: date,
                    description: desc,
                    isRequired: false,
                    penaltyForMissing: "Underpayment penalty if total payments < 90% of tax"
                ))
            }
        }
        
        return deadlines.sorted { $0.date < $1.date }
    }
    
    public override func generateOptimizationSuggestions(
        grossIncome: Decimal,
        deductionsApplied: [TaxDeduction],
        residencyStatus: ResidencyType
    ) async -> [TaxOptimizationSuggestion] {
        
        var suggestions: [TaxOptimizationSuggestion] = []
        
        // 401(k) / IRA maximization
        let retirementContribUsed = deductionsApplied.filter { $0.type == .ira401k }.reduce(Decimal(0)) { $0 + $1.amount }
        let retirementLimit: Decimal = 23000  // 2025 401(k) limit
        let remaining = retirementLimit - retirementContribUsed
        
        if remaining > 0 {
            let marginal = getMarginalRate(income: grossIncome, brackets: getBracketsForFilingStatus())
            let saving = remaining * Decimal(marginal)
            suggestions.append(TaxOptimizationSuggestion(
                type: .retirementContribution,
                title: "Maximize 401(k) Contributions",
                description: "Contribute $\(remaining) more to 401(k) to reduce taxable income",
                potentialSaving: saving,
                currency: currency,
                priority: remaining > 5000 ? .high : .medium,
                actionRequired: "Increase 401(k) contribution before December 31",
                deadline: getYearEnd(),
                relatedDeduction: .ira401k,
                country: countryCode
            ))
        }
        
        // HSA contribution suggestion
        suggestions.append(TaxOptimizationSuggestion(
            type: .deductionMaximization,
            title: "Health Savings Account (HSA)",
            description: "If eligible, contribute to HSA for triple tax advantage",
            potentialSaving: 0,
            currency: currency,
            priority: .medium,
            actionRequired: "Open HSA and contribute up to $4,150 (single) or $8,300 (family)",
            deadline: getYearEnd(),
            country: countryCode
        ))
        
        // Charitable donations
        let charitableUsed = deductionsApplied.filter { $0.type == .charitableContributions }.reduce(Decimal(0)) { $0 + $1.amount }
        if charitableUsed > 0 {
            suggestions.append(TaxOptimizationSuggestion(
                type: .charitableDonation,
                title: "Charitable Contribution Strategy",
                description: "Consider donating appreciated assets for additional tax benefits",
                potentialSaving: 0,
                currency: currency,
                priority: .low,
                actionRequired: "Donate appreciated stocks or mutual funds instead of cash",
                relatedDeduction: .charitableContributions,
                country: countryCode
            ))
        }
        
        // Capital gains tax timing
        if grossIncome > 50000 {
            suggestions.append(TaxOptimizationSuggestion(
                type: .capitalGainsTiming,
                title: "Long-term Capital Gains Planning",
                description: "Hold investments > 1 year for preferential tax rates",
                potentialSaving: 0,
                currency: currency,
                priority: .medium,
                actionRequired: "Review investment holdings and plan sales strategically",
                country: countryCode
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Private Helper Methods
    
    private func getStandardDeduction() -> Decimal {
        // 2025 standard deduction amounts
        switch filingStatus {
        case .single:
            return 15000
        case .marriedJoint:
            return 30000
        case .marriedSeparate:
            return 15000
        case .headOfHousehold:
            return 22500
        }
    }
    
    private func getBracketsForFilingStatus() -> [TaxBracket] {
        // 2025 tax brackets (estimated based on inflation adjustments)
        switch filingStatus {
        case .single:
            return [
                TaxBracket(minIncome: 0, maxIncome: 11600, rate: 0.10, description: "10% bracket"),
                TaxBracket(minIncome: 11600, maxIncome: 47150, rate: 0.12, description: "12% bracket"),
                TaxBracket(minIncome: 47150, maxIncome: 100525, rate: 0.22, description: "22% bracket"),
                TaxBracket(minIncome: 100525, maxIncome: 191950, rate: 0.24, description: "24% bracket"),
                TaxBracket(minIncome: 191950, maxIncome: 243725, rate: 0.32, description: "32% bracket"),
                TaxBracket(minIncome: 243725, maxIncome: 609350, rate: 0.35, description: "35% bracket"),
                TaxBracket(minIncome: 609350, maxIncome: nil, rate: 0.37, description: "37% bracket")
            ]
            
        case .marriedJoint:
            return [
                TaxBracket(minIncome: 0, maxIncome: 23200, rate: 0.10, description: "10% bracket"),
                TaxBracket(minIncome: 23200, maxIncome: 94300, rate: 0.12, description: "12% bracket"),
                TaxBracket(minIncome: 94300, maxIncome: 201050, rate: 0.22, description: "22% bracket"),
                TaxBracket(minIncome: 201050, maxIncome: 383900, rate: 0.24, description: "24% bracket"),
                TaxBracket(minIncome: 383900, maxIncome: 487450, rate: 0.32, description: "32% bracket"),
                TaxBracket(minIncome: 487450, maxIncome: 731200, rate: 0.35, description: "35% bracket"),
                TaxBracket(minIncome: 731200, maxIncome: nil, rate: 0.37, description: "37% bracket")
            ]
            
        case .marriedSeparate:
            return [
                TaxBracket(minIncome: 0, maxIncome: 11600, rate: 0.10, description: "10% bracket"),
                TaxBracket(minIncome: 11600, maxIncome: 47150, rate: 0.12, description: "12% bracket"),
                TaxBracket(minIncome: 47150, maxIncome: 100525, rate: 0.22, description: "22% bracket"),
                TaxBracket(minIncome: 100525, maxIncome: 191950, rate: 0.24, description: "24% bracket"),
                TaxBracket(minIncome: 191950, maxIncome: 243725, rate: 0.32, description: "32% bracket"),
                TaxBracket(minIncome: 243725, maxIncome: 365600, rate: 0.35, description: "35% bracket"),
                TaxBracket(minIncome: 365600, maxIncome: nil, rate: 0.37, description: "37% bracket")
            ]
            
        case .headOfHousehold:
            return [
                TaxBracket(minIncome: 0, maxIncome: 16550, rate: 0.10, description: "10% bracket"),
                TaxBracket(minIncome: 16550, maxIncome: 63100, rate: 0.12, description: "12% bracket"),
                TaxBracket(minIncome: 63100, maxIncome: 100500, rate: 0.22, description: "22% bracket"),
                TaxBracket(minIncome: 100500, maxIncome: 191950, rate: 0.24, description: "24% bracket"),
                TaxBracket(minIncome: 191950, maxIncome: 243700, rate: 0.32, description: "32% bracket"),
                TaxBracket(minIncome: 243700, maxIncome: 609350, rate: 0.35, description: "35% bracket"),
                TaxBracket(minIncome: 609350, maxIncome: nil, rate: 0.37, description: "37% bracket")
            ]
        }
    }
    
    private func buildTaxBreakdown(
        federalTax: Decimal,
        brackets: [TaxBracket],
        taxableIncome: Decimal
    ) -> [TaxComponent] {
        
        var components: [TaxComponent] = []
        
        // Add bracket-wise breakdown
        for bracket in brackets.sorted() {
            let taxInBracket = bracket.calculateTax(for: taxableIncome)
            if taxInBracket > 0 {
                components.append(TaxComponent(
                    name: bracket.description,
                    amount: taxInBracket,
                    rate: bracket.rate,
                    description: "Federal income tax at \(String(format: "%.0f%%", bracket.rate * 100))"
                ))
            }
        }
        
        // Note: State taxes would be calculated separately
        components.append(TaxComponent(
            name: "Total Federal Tax",
            amount: federalTax,
            description: "Total federal income tax liability"
        ))
        
        return components
    }
    
    private func getFilingRequirements(income: Decimal, residencyStatus: ResidencyType) -> [String] {
        var requirements: [String] = []
        
        let filingThreshold = getStandardDeduction()
        if income > filingThreshold {
            requirements.append("Form 1040 federal tax return required")
        }
        
        if residencyStatus == .nonResidentNotOrdinary || residencyStatus == .nonResidentOrdinary {
            requirements.append("Form 1040-NR for non-resident aliens")
            requirements.append("Form 8843 for days present in US")
            requirements.append("Form W-8BEN for treaty benefits")
        }
        
        if income > 200000 {
            requirements.append("Additional Medicare Tax (0.9%) may apply")
        }
        
        requirements.append("File by April 15 or request extension")
        requirements.append("Pay estimated taxes quarterly if self-employed")
        
        return requirements
    }
    
    private func getYearEnd() -> Date? {
        let calendar = Calendar.current
        let currentYear = Int(taxYear) ?? 2025
        return calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31))
    }
}
