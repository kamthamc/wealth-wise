import Foundation

/// India tax calculator implementing Indian Income Tax Act
/// Supports new and old tax regimes, resident/non-resident calculations
@MainActor
public final class IndiaTaxCalculator: BaseTaxCalculator {
    
    // MARK: - Tax Regime
    
    public enum TaxRegime: String, Codable, Sendable {
        case new = "new"
        case old = "old"
        
        var displayName: String {
            switch self {
            case .new: return "New Tax Regime (Lower Rates)"
            case .old: return "Old Tax Regime (Deductions)"
            }
        }
    }
    
    private let regime: TaxRegime
    
    // MARK: - Initialization
    
    public init(taxYear: String = "2025-26", regime: TaxRegime = .new) {
        self.regime = regime
        super.init(countryCode: "IND", taxYear: taxYear, currency: "INR")
    }
    
    // MARK: - TaxCalculatorProtocol Implementation
    
    public override func calculateTax(
        grossIncome: Decimal,
        incomeBreakdown: IncomeBreakdown,
        residencyStatus: ResidencyType,
        deductions: [TaxDeduction]
    ) async -> TaxCalculation {
        
        // Calculate total deductions (only for old regime)
        let totalDeductions: Decimal
        if regime == .old {
            totalDeductions = calculateTotalDeductions(deductions)
        } else {
            // New regime only allows standard deduction
            let standardDed = deductions.first { $0.type == .standardDeduction }
            totalDeductions = standardDed?.effectiveAmount ?? 0
        }
        
        // Calculate taxable income
        let taxableIncome = max(0, grossIncome - totalDeductions)
        
        // Get tax brackets
        let brackets = getTaxBrackets(for: residencyStatus)
        
        // Calculate base tax
        let baseTax = calculateProgressiveTax(income: taxableIncome, brackets: brackets)
        
        // Calculate cess (4% health and education cess)
        let cess = baseTax * Decimal(0.04)
        
        // Calculate surcharge if applicable
        let surcharge = calculateSurcharge(taxableIncome: taxableIncome, baseTax: baseTax)
        
        // Total tax liability
        let taxLiability = baseTax + cess + surcharge
        
        // Calculate rates
        let effectiveRate = taxableIncome > 0 ? Double(truncating: (taxLiability / taxableIncome * 100) as NSNumber) : 0
        let marginalRate = getMarginalRate(income: taxableIncome, brackets: brackets) * 100
        
        // Build tax breakdown
        let taxBreakdown = buildTaxBreakdown(
            baseTax: baseTax,
            cess: cess,
            surcharge: surcharge,
            brackets: brackets,
            taxableIncome: taxableIncome
        )
        
        // Get filing requirements
        let filingReqs = getFilingRequirements(
            income: grossIncome,
            residencyStatus: residencyStatus
        )
        
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
            taxLiability: taxLiability,
            effectiveRate: effectiveRate,
            marginalRate: marginalRate,
            taxBreakdown: taxBreakdown,
            cess: cess,
            surcharge: surcharge > 0 ? surcharge : nil,
            residencyStatus: residencyStatus,
            filingRequirements: filingReqs,
            optimizationSuggestions: suggestions
        )
    }
    
    public override func getTaxBrackets(for residencyStatus: ResidencyType) -> [TaxBracket] {
        if regime == .new {
            return getNewRegimeBrackets()
        } else {
            return getOldRegimeBrackets()
        }
    }
    
    public override func getAvailableDeductions(for residencyStatus: ResidencyType) -> [TaxDeductionType] {
        if regime == .new {
            // New regime only allows standard deduction
            return [.standardDeduction]
        } else {
            // Old regime allows multiple deductions
            return [
                .standardDeduction,
                .section80C,
                .section80D,
                .section80G,
                .nps,
                .hra,
                .homeLoanInterest,
                .educationLoan
            ]
        }
    }
    
    public override func calculateWithholdingTax(
        amount: Decimal,
        incomeType: IncomeType,
        sourceCountry: String
    ) async -> Decimal {
        // TDS rates for different income types
        let rate: Double
        switch incomeType {
        case .salary:
            rate = 0.0  // TDS based on actual tax liability
        case .interest:
            rate = 0.10  // 10% TDS on interest income
        case .dividend:
            rate = 0.10  // 10% TDS on dividends
        case .rental:
            rate = 0.10  // 10% TDS on rent above threshold
        case .capitalGains:
            rate = 0.10  // Varies by holding period
        default:
            rate = 0.10  // Default 10%
        }
        
        return amount * Decimal(rate)
    }
    
    public override func getFilingDeadlines() -> [FilingDeadline] {
        let calendar = Calendar.current
        let currentYear = Int(taxYear.prefix(4)) ?? 2025
        
        var deadlines: [FilingDeadline] = []
        
        // July 31 - For individuals (non-audit)
        if let july31 = calendar.date(from: DateComponents(year: currentYear, month: 7, day: 31)) {
            deadlines.append(FilingDeadline(
                date: july31,
                description: "ITR filing deadline for individuals (non-audit)",
                penaltyForMissing: "Late fee of ₹5,000 (₹1,000 if income < ₹5 lakh)"
            ))
        }
        
        // October 31 - For businesses requiring audit
        if let oct31 = calendar.date(from: DateComponents(year: currentYear, month: 10, day: 31)) {
            deadlines.append(FilingDeadline(
                date: oct31,
                description: "ITR filing deadline for audit cases",
                penaltyForMissing: "Late fee of ₹5,000 and interest on unpaid tax"
            ))
        }
        
        // Advance tax installments
        let advanceTaxDates = [
            (6, 15, "15% of estimated tax"),
            (9, 15, "45% of estimated tax (cumulative)"),
            (12, 15, "75% of estimated tax (cumulative)"),
            (3, 15, "100% of estimated tax")
        ]
        
        for (month, day, desc) in advanceTaxDates {
            if let date = calendar.date(from: DateComponents(year: currentYear, month: month, day: day)) {
                deadlines.append(FilingDeadline(
                    date: date,
                    description: "Advance Tax: \(desc)",
                    isRequired: false,
                    penaltyForMissing: "Interest of 1% per month on shortfall"
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
        
        // Only for old regime - suggest deductions
        if regime == .old {
            // 80C optimization
            let section80CUsed = deductionsApplied.filter { $0.type == .section80C }.reduce(Decimal(0)) { $0 + $1.amount }
            let section80CRemaining = max(0, 150000 - section80CUsed)
            
            if section80CRemaining > 0 {
                let potentialSaving = section80CRemaining * Decimal(0.30)  // Assuming 30% tax bracket
                suggestions.append(TaxOptimizationSuggestion(
                    type: .deductionMaximization,
                    title: "Maximize Section 80C Deduction",
                    description: "You can save ₹\(section80CRemaining) more in 80C investments (EPF, PPF, ELSS, Life Insurance)",
                    potentialSaving: potentialSaving,
                    currency: currency,
                    priority: section80CRemaining > 50000 ? .high : .medium,
                    actionRequired: "Invest in 80C eligible instruments before March 31",
                    deadline: getFinancialYearEnd(),
                    relatedDeduction: .section80C,
                    country: countryCode
                ))
            }
            
            // NPS additional 50k deduction
            let npsUsed = deductionsApplied.filter { $0.type == .nps }.reduce(Decimal(0)) { $0 + $1.amount }
            if npsUsed < 50000 {
                let npsRemaining = 50000 - npsUsed
                let saving = npsRemaining * Decimal(0.30)
                suggestions.append(TaxOptimizationSuggestion(
                    type: .retirementContribution,
                    title: "Additional NPS Deduction Available",
                    description: "Invest ₹\(npsRemaining) more in NPS to claim additional 80CCD(1B) deduction",
                    potentialSaving: saving,
                    currency: currency,
                    priority: .medium,
                    actionRequired: "Make NPS contribution before March 31",
                    deadline: getFinancialYearEnd(),
                    relatedDeduction: .nps,
                    country: countryCode
                ))
            }
            
            // Health insurance under 80D
            let healthInsUsed = deductionsApplied.filter { $0.type == .section80D }.reduce(Decimal(0)) { $0 + $1.amount }
            if healthInsUsed < 25000 {
                let remaining = 25000 - healthInsUsed
                let saving = remaining * Decimal(0.30)
                suggestions.append(TaxOptimizationSuggestion(
                    type: .deductionMaximization,
                    title: "Health Insurance Premium Deduction",
                    description: "Pay ₹\(remaining) more in health insurance premiums for 80D deduction",
                    potentialSaving: saving,
                    currency: currency,
                    priority: .low,
                    actionRequired: "Purchase or upgrade health insurance before March 31",
                    deadline: getFinancialYearEnd(),
                    relatedDeduction: .section80D,
                    country: countryCode
                ))
            }
        } else {
            // New regime - suggest regime comparison
            suggestions.append(TaxOptimizationSuggestion(
                type: .taxRegimeOptimization,
                title: "Compare with Old Tax Regime",
                description: "Consider switching to old regime if you have significant deductions available",
                potentialSaving: 0,  // Would need full calculation
                currency: currency,
                priority: .medium,
                actionRequired: "Calculate tax under both regimes and choose optimal one",
                country: countryCode
            ))
        }
        
        // Advance tax suggestion if income is high
        if grossIncome > 1000000 {
            suggestions.append(TaxOptimizationSuggestion(
                type: .advanceTaxPlanning,
                title: "Plan Advance Tax Payments",
                description: "Income exceeds ₹10 lakhs - advance tax applicable",
                potentialSaving: 0,
                currency: currency,
                priority: .high,
                actionRequired: "Pay advance tax by quarterly deadlines to avoid interest",
                country: countryCode
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Private Helper Methods
    
    private func getNewRegimeBrackets() -> [TaxBracket] {
        return [
            TaxBracket(minIncome: 0, maxIncome: 300000, rate: 0, description: "Up to ₹3 lakh"),
            TaxBracket(minIncome: 300000, maxIncome: 700000, rate: 0.05, description: "₹3L - ₹7L"),
            TaxBracket(minIncome: 700000, maxIncome: 1000000, rate: 0.10, description: "₹7L - ₹10L"),
            TaxBracket(minIncome: 1000000, maxIncome: 1200000, rate: 0.15, description: "₹10L - ₹12L"),
            TaxBracket(minIncome: 1200000, maxIncome: 1500000, rate: 0.20, description: "₹12L - ₹15L"),
            TaxBracket(minIncome: 1500000, maxIncome: nil, rate: 0.30, description: "Above ₹15L")
        ]
    }
    
    private func getOldRegimeBrackets() -> [TaxBracket] {
        return [
            TaxBracket(minIncome: 0, maxIncome: 250000, rate: 0, description: "Up to ₹2.5 lakh"),
            TaxBracket(minIncome: 250000, maxIncome: 500000, rate: 0.05, description: "₹2.5L - ₹5L"),
            TaxBracket(minIncome: 500000, maxIncome: 1000000, rate: 0.20, description: "₹5L - ₹10L"),
            TaxBracket(minIncome: 1000000, maxIncome: nil, rate: 0.30, description: "Above ₹10L")
        ]
    }
    
    private func calculateSurcharge(taxableIncome: Decimal, baseTax: Decimal) -> Decimal {
        // Surcharge applicable for high income
        if taxableIncome > 10000000 {
            return baseTax * Decimal(0.15)  // 15% surcharge
        } else if taxableIncome > 5000000 {
            return baseTax * Decimal(0.10)  // 10% surcharge
        }
        return 0
    }
    
    private func buildTaxBreakdown(
        baseTax: Decimal,
        cess: Decimal,
        surcharge: Decimal,
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
                    description: "Tax at \(bracket.ratePercentage)"
                ))
            }
        }
        
        // Add cess
        components.append(TaxComponent(
            name: "Health & Education Cess",
            amount: cess,
            rate: 0.04,
            description: "4% cess on income tax"
        ))
        
        // Add surcharge if applicable
        if surcharge > 0 {
            let surchargeRate = taxableIncome > 10000000 ? 0.15 : 0.10
            components.append(TaxComponent(
                name: "Surcharge",
                amount: surcharge,
                rate: surchargeRate,
                description: "Surcharge on high income"
            ))
        }
        
        return components
    }
    
    private func getFilingRequirements(income: Decimal, residencyStatus: ResidencyType) -> [String] {
        var requirements: [String] = []
        
        if income > 250000 {
            requirements.append("Income Tax Return (ITR) filing mandatory")
        }
        
        if income > 1000000 {
            requirements.append("Advance tax payment required (4 installments)")
        }
        
        if residencyStatus == .nonResidentNotOrdinary || residencyStatus == .nonResidentOrdinary {
            requirements.append("Form 10F submission for treaty benefits (if applicable)")
            requirements.append("Non-resident tax rates applicable")
        }
        
        requirements.append("Link PAN with Aadhaar")
        requirements.append("File ITR before July 31 to avoid late fees")
        
        return requirements
    }
    
    private func getFinancialYearEnd() -> Date? {
        let calendar = Calendar.current
        let currentYear = Int(taxYear.prefix(4)) ?? 2025
        return calendar.date(from: DateComponents(year: currentYear + 1, month: 3, day: 31))
    }
}
