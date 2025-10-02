import Foundation

/// UK tax calculator implementing HMRC income tax
@MainActor
public final class UKTaxCalculator: BaseTaxCalculator {
    
    // MARK: - Initialization
    
    public init(taxYear: String = "2025-26") {
        super.init(countryCode: "GBR", taxYear: taxYear, currency: "GBP")
    }
    
    // MARK: - TaxCalculatorProtocol Implementation
    
    public override func calculateTax(
        grossIncome: Decimal,
        incomeBreakdown: IncomeBreakdown,
        residencyStatus: ResidencyType,
        deductions: [TaxDeduction]
    ) async -> TaxCalculation {
        
        // Personal allowance
        let personalAllowance: Decimal = 12570
        
        // Calculate taxable income
        let taxableIncome = max(0, grossIncome - personalAllowance)
        
        // Get tax brackets
        let brackets = getTaxBrackets(for: residencyStatus)
        
        // Calculate tax
        let incomeTax = calculateProgressiveTax(income: taxableIncome, brackets: brackets)
        
        // National Insurance (approximate)
        let nationalInsurance = calculateNationalInsurance(income: grossIncome)
        
        let totalTax = incomeTax + nationalInsurance
        
        // Calculate rates
        let effectiveRate = grossIncome > 0 ? Double(truncating: (totalTax / grossIncome * 100) as NSNumber) : 0
        let marginalRate = getMarginalRate(income: taxableIncome, brackets: brackets) * 100
        
        let taxBreakdown = [
            TaxComponent(name: "Income Tax", amount: incomeTax, description: "HMRC income tax"),
            TaxComponent(name: "National Insurance", amount: nationalInsurance, description: "Class 1 NI contributions")
        ]
        
        return TaxCalculation(
            country: countryCode,
            taxYear: taxYear,
            grossIncome: grossIncome,
            currency: currency,
            incomeBreakdown: incomeBreakdown,
            totalDeductions: personalAllowance,
            deductionsApplied: [],
            taxableIncome: taxableIncome,
            taxLiability: totalTax,
            effectiveRate: effectiveRate,
            marginalRate: marginalRate,
            taxBreakdown: taxBreakdown,
            residencyStatus: residencyStatus,
            filingRequirements: getFilingRequirements(income: grossIncome, residencyStatus: residencyStatus)
        )
    }
    
    public override func getTaxBrackets(for residencyStatus: ResidencyType) -> [TaxBracket] {
        return [
            TaxBracket(minIncome: 0, maxIncome: 12570, rate: 0, description: "Personal Allowance"),
            TaxBracket(minIncome: 12570, maxIncome: 50270, rate: 0.20, description: "Basic rate"),
            TaxBracket(minIncome: 50270, maxIncome: 125140, rate: 0.40, description: "Higher rate"),
            TaxBracket(minIncome: 125140, maxIncome: nil, rate: 0.45, description: "Additional rate")
        ]
    }
    
    public override func getAvailableDeductions(for residencyStatus: ResidencyType) -> [TaxDeductionType] {
        return [
            .personalAllowance,
            .pensionContributions,
            .charitableContributions
        ]
    }
    
    public override func getFilingDeadlines() -> [FilingDeadline] {
        let calendar = Calendar.current
        let currentYear = Int(taxYear.prefix(4)) ?? 2025
        
        var deadlines: [FilingDeadline] = []
        
        // January 31 - Online self-assessment deadline
        if let jan31 = calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 31)) {
            deadlines.append(FilingDeadline(
                date: jan31,
                description: "Self Assessment tax return deadline (online)",
                penaltyForMissing: "£100 automatic penalty, increasing over time"
            ))
        }
        
        return deadlines
    }
    
    private func calculateNationalInsurance(income: Decimal) -> Decimal {
        // Simplified NI calculation (Class 1 employee)
        let lowerLimit: Decimal = 12570
        let upperLimit: Decimal = 50270
        
        if income <= lowerLimit {
            return 0
        }
        
        let niableIncome = min(income - lowerLimit, upperLimit - lowerLimit)
        let niBelow = niableIncome * Decimal(0.12)  // 12% between limits
        
        let niAbove: Decimal
        if income > upperLimit {
            niAbove = (income - upperLimit) * Decimal(0.02)  // 2% above upper limit
        } else {
            niAbove = 0
        }
        
        return niBelow + niAbove
    }
    
    private func getFilingRequirements(income: Decimal, residencyStatus: ResidencyType) -> [String] {
        var requirements: [String] = []
        
        if income > 100000 {
            requirements.append("Self Assessment tax return required")
        }
        
        if residencyStatus == .nonResidentNotOrdinary || residencyStatus == .nonResidentOrdinary {
            requirements.append("Non-resident tax return if UK income")
        }
        
        requirements.append("File by January 31 (online) or October 31 (paper)")
        return requirements
    }
}
