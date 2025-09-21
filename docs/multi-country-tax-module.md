# WealthWise Multi-Country Tax Module

## Overview
A comprehensive tax calculation system supporting multiple countries with resident/non-resident status, tax treaties, and cross-border tax implications for global asset management.

## Tax Module Architecture

### 1. Core Tax System Types
```swift
enum SupportedCountry: String, CaseIterable, Codable {
    case india = "IN"
    case unitedStates = "US"
    case unitedKingdom = "GB"
    case canada = "CA"
    case australia = "AU"
    case singapore = "SG"
    case hongKong = "HK"
    case uae = "AE"
    case germany = "DE"
    case france = "FR"
    
    var displayName: String {
        switch self {
        case .india: return "India"
        case .unitedStates: return "United States"
        case .unitedKingdom: return "United Kingdom"
        case .canada: return "Canada"
        case .australia: return "Australia"
        case .singapore: return "Singapore"
        case .hongKong: return "Hong Kong"
        case .uae: return "United Arab Emirates"
        case .germany: return "Germany"
        case .france: return "France"
        }
    }
    
    var currency: SupportedCurrency {
        switch self {
        case .india: return .inr
        case .unitedStates: return .usd
        case .unitedKingdom: return .gbp
        case .canada: return .cad
        case .australia: return .aud
        case .singapore: return .sgd
        case .hongKong: return .hkd
        case .uae: return .aed
        case .germany, .france: return .eur
        }
    }
    
    var taxYear: TaxYear {
        switch self {
        case .india: return .april // April to March
        case .australia: return .july // July to June
        default: return .january // January to December
        }
    }
    
    var locale: Locale {
        switch self {
        case .india: return Locale(identifier: "en_IN")
        case .unitedStates: return Locale(identifier: "en_US")
        case .unitedKingdom: return Locale(identifier: "en_GB")
        case .canada: return Locale(identifier: "en_CA")
        case .australia: return Locale(identifier: "en_AU")
        case .singapore: return Locale(identifier: "en_SG")
        case .hongKong: return Locale(identifier: "en_HK")
        case .uae: return Locale(identifier: "ar_AE")
        case .germany: return Locale(identifier: "de_DE")
        case .france: return Locale(identifier: "fr_FR")
        }
    }
}

enum TaxYear {
    case january  // Jan 1 - Dec 31
    case april    // Apr 1 - Mar 31
    case july     // Jul 1 - Jun 30
}

enum ResidencyStatus: String, CaseIterable, Codable {
    case resident = "resident"
    case nonResident = "non_resident"
    case dualResident = "dual_resident"
    case nominalResident = "nominal_resident" // Australia specific
    case ordinarilyResident = "ordinarily_resident" // India specific
    
    var displayName: String {
        switch self {
        case .resident: return "Tax Resident"
        case .nonResident: return "Non-Resident"
        case .dualResident: return "Dual Resident"
        case .nominalResident: return "Nominal Resident"
        case .ordinarilyResident: return "Ordinarily Resident"
        }
    }
}

struct TaxProfile: Identifiable, Codable {
    let id = UUID()
    let country: SupportedCountry
    var residencyStatus: ResidencyStatus
    var taxYear: String // "2024-25" format
    
    // Personal Information
    var dateOfBirth: Date?
    var citizenshipCountries: [SupportedCountry] = []
    var residencyDays: [SupportedCountry: Int] = [:] // Days spent in each country
    
    // Income Sources
    var incomeByCountry: [SupportedCountry: CountryIncome] = [:]
    var globalIncome: CurrencyAmount = CurrencyAmount(value: 0, currency: .usd)
    
    // Tax Payments
    var taxPaidByCountry: [SupportedCountry: CurrencyAmount] = [:]
    var advanceTaxPaid: [SupportedCountry: [AdvanceTaxPayment]] = [:]
    var witholdingTax: [SupportedCountry: CurrencyAmount] = [:]
    
    // Tax Treaties
    var applicableTreaties: [TaxTreaty] = []
    var treatyBenefits: [TreatyBenefit] = []
    
    // Compliance Status
    var filingRequirements: [FilingRequirement] = []
    var complianceStatus: [SupportedCountry: ComplianceStatus] = [:]
}

struct CountryIncome: Codable {
    var salaryIncome: CurrencyAmount = CurrencyAmount(value: 0, currency: .usd)
    var businessIncome: CurrencyAmount = CurrencyAmount(value: 0, currency: .usd)
    var investmentIncome: CurrencyAmount = CurrencyAmount(value: 0, currency: .usd)
    var rentalIncome: CurrencyAmount = CurrencyAmount(value: 0, currency: .usd)
    var capitalGains: CurrencyAmount = CurrencyAmount(value: 0, currency: .usd)
    var otherIncome: CurrencyAmount = CurrencyAmount(value: 0, currency: .usd)
    
    var totalIncome: CurrencyAmount {
        let total = salaryIncome.value + businessIncome.value + investmentIncome.value + 
                   rentalIncome.value + capitalGains.value + otherIncome.value
        // Use the currency of the largest income component
        let currency = [salaryIncome, businessIncome, investmentIncome, rentalIncome, capitalGains]
            .max(by: { $0.value < $1.value })?.currency ?? .usd
        return CurrencyAmount(value: total, currency: currency)
    }
}

enum ComplianceStatus: String, CaseIterable {
    case compliant = "compliant"
    case pending = "pending"
    case overdue = "overdue"
    case notRequired = "not_required"
}
```

### 2. Tax Calculator Protocols
```swift
protocol TaxCalculatorProtocol {
    var country: SupportedCountry { get }
    var taxYear: String { get }
    
    func calculateTaxLiability(
        income: CurrencyAmount,
        residencyStatus: ResidencyStatus,
        deductions: [TaxDeduction]
    ) -> TaxCalculationResult
    
    func calculateWithholdingTax(
        income: CurrencyAmount,
        incomeType: IncomeType,
        sourceCountry: SupportedCountry
    ) -> CurrencyAmount
    
    func getAvailableDeductions(residencyStatus: ResidencyStatus) -> [TaxDeductionType]
    func getTaxBrackets(residencyStatus: ResidencyStatus) -> [TaxBracket]
    func getFilingDeadlines() -> [FilingDeadline]
}

struct TaxCalculationResult {
    let taxableIncome: CurrencyAmount
    let taxLiability: CurrencyAmount
    let effectiveRate: Double
    let marginalRate: Double
    let deductionsApplied: [TaxDeduction]
    let taxBreakdown: [TaxComponent]
    let additionalRequirements: [String]
}

struct TaxComponent {
    let name: String
    let amount: CurrencyAmount
    let rate: Double?
    let description: String
}

struct TaxBracket {
    let minIncome: CurrencyAmount
    let maxIncome: CurrencyAmount?
    let rate: Double
    let description: String
}

enum IncomeType: String, CaseIterable {
    case salary = "salary"
    case business = "business"
    case investment = "investment"
    case rental = "rental"
    case capitalGains = "capital_gains"
    case dividend = "dividend"
    case interest = "interest"
    case royalty = "royalty"
    case pension = "pension"
}
```

### 3. Country-Specific Tax Calculators
```swift
// MARK: - India Tax Calculator
class IndiaTaxCalculator: TaxCalculatorProtocol {
    let country: SupportedCountry = .india
    let taxYear: String
    
    init(taxYear: String = "2025-26") {
        self.taxYear = taxYear
    }
    
    func calculateTaxLiability(
        income: CurrencyAmount,
        residencyStatus: ResidencyStatus,
        deductions: [TaxDeduction]
    ) -> TaxCalculationResult {
        let incomeInINR = CurrencyManager.shared.convert(
            amount: income.value,
            from: income.currency,
            to: .inr
        )
        
        // Apply deductions
        let totalDeductions = deductions.reduce(Decimal(0)) { sum, deduction in
            sum + CurrencyManager.shared.convert(
                amount: deduction.amount.value,
                from: deduction.amount.currency,
                to: .inr
            )
        }
        
        let taxableIncome = max(0, incomeInINR - totalDeductions)
        
        // Calculate tax based on regime and residency
        let taxLiability = calculateIndianTax(
            taxableIncome: taxableIncome,
            residencyStatus: residencyStatus
        )
        
        return TaxCalculationResult(
            taxableIncome: CurrencyAmount(value: taxableIncome, currency: .inr),
            taxLiability: CurrencyAmount(value: taxLiability, currency: .inr),
            effectiveRate: Double(truncating: (taxLiability / incomeInINR) as NSNumber),
            marginalRate: getMarginalTaxRate(income: taxableIncome, residencyStatus: residencyStatus),
            deductionsApplied: deductions,
            taxBreakdown: getIndianTaxBreakdown(taxableIncome: taxableIncome, residencyStatus: residencyStatus),
            additionalRequirements: getIndianFilingRequirements(income: incomeInINR, residencyStatus: residencyStatus)
        )
    }
    
    private func calculateIndianTax(taxableIncome: Decimal, residencyStatus: ResidencyStatus) -> Decimal {
        var tax: Decimal = 0
        
        // Old tax regime slabs (default)
        if taxableIncome > 250000 {
            tax += min(taxableIncome - 250000, 250000) * 0.05 // 5% for 2.5L-5L
        }
        if taxableIncome > 500000 {
            tax += min(taxableIncome - 500000, 500000) * 0.20 // 20% for 5L-10L
        }
        if taxableIncome > 1000000 {
            tax += (taxableIncome - 1000000) * 0.30 // 30% above 10L
        }
        
        // Add surcharge for high income
        if taxableIncome > 5000000 {
            tax += tax * 0.10 // 10% surcharge for income > 50L
        } else if taxableIncome > 10000000 {
            tax += tax * 0.15 // 15% surcharge for income > 1Cr
        }
        
        // Add cess (4% on tax + surcharge)
        tax += tax * 0.04
        
        // Non-resident additional considerations
        if residencyStatus == .nonResident {
            // Minimum alternate tax might apply
            let alternateMinTax = taxableIncome * 0.18
            tax = max(tax, alternateMinTax)
        }
        
        return tax
    }
    
    func calculateWithholdingTax(
        income: CurrencyAmount,
        incomeType: IncomeType,
        sourceCountry: SupportedCountry
    ) -> CurrencyAmount {
        let incomeInINR = CurrencyManager.shared.convert(
            amount: income.value,
            from: income.currency,
            to: .inr
        )
        
        let withholdingRate: Double
        switch incomeType {
        case .salary: withholdingRate = 0.0 // TDS as per slab
        case .interest: withholdingRate = 0.10 // 10% TDS on interest
        case .dividend: withholdingRate = 0.10 // 10% TDS on dividends
        case .rental: withholdingRate = 0.10 // 10% TDS on rent
        case .capitalGains: withholdingRate = 0.01 // 1% TDS on property sale
        default: withholdingRate = 0.10
        }
        
        return CurrencyAmount(value: incomeInINR * Decimal(withholdingRate), currency: .inr)
    }
    
    func getAvailableDeductions(residencyStatus: ResidencyStatus) -> [TaxDeductionType] {
        var deductions: [TaxDeductionType] = [
            .section80C, .section80D, .section80G, .section80E,
            .standardDeduction, .hra, .lta
        ]
        
        if residencyStatus == .resident || residencyStatus == .ordinarilyResident {
            deductions.append(contentsOf: [.section80CCD1B, .section80TTA])
        }
        
        return deductions
    }
    
    func getTaxBrackets(residencyStatus: ResidencyStatus) -> [TaxBracket] {
        return [
            TaxBracket(
                minIncome: CurrencyAmount(value: 0, currency: .inr),
                maxIncome: CurrencyAmount(value: 250000, currency: .inr),
                rate: 0.0,
                description: "No tax"
            ),
            TaxBracket(
                minIncome: CurrencyAmount(value: 250000, currency: .inr),
                maxIncome: CurrencyAmount(value: 500000, currency: .inr),
                rate: 0.05,
                description: "5% tax"
            ),
            TaxBracket(
                minIncome: CurrencyAmount(value: 500000, currency: .inr),
                maxIncome: CurrencyAmount(value: 1000000, currency: .inr),
                rate: 0.20,
                description: "20% tax"
            ),
            TaxBracket(
                minIncome: CurrencyAmount(value: 1000000, currency: .inr),
                maxIncome: nil,
                rate: 0.30,
                description: "30% tax"
            )
        ]
    }
    
    func getFilingDeadlines() -> [FilingDeadline] {
        return [
            FilingDeadline(
                type: .incomeTaxReturn,
                dueDate: Calendar.current.date(from: DateComponents(year: 2026, month: 7, day: 31))!,
                description: "ITR filing deadline",
                penalties: "₹5,000 late filing fee"
            ),
            FilingDeadline(
                type: .advanceTax,
                dueDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!,
                description: "First advance tax installment",
                penalties: "Interest @ 1% per month"
            )
        ]
    }
    
    private func getMarginalTaxRate(income: Decimal, residencyStatus: ResidencyStatus) -> Double {
        if income <= 250000 { return 0.0 }
        else if income <= 500000 { return 0.05 }
        else if income <= 1000000 { return 0.20 }
        else { return 0.30 }
    }
    
    private func getIndianTaxBreakdown(taxableIncome: Decimal, residencyStatus: ResidencyStatus) -> [TaxComponent] {
        var components: [TaxComponent] = []
        
        // Calculate each tax component
        if taxableIncome > 250000 {
            let amount = min(taxableIncome - 250000, 250000) * 0.05
            components.append(TaxComponent(
                name: "Income Tax (5%)",
                amount: CurrencyAmount(value: amount, currency: .inr),
                rate: 0.05,
                description: "Tax on income ₹2.5L - ₹5L"
            ))
        }
        
        if taxableIncome > 500000 {
            let amount = min(taxableIncome - 500000, 500000) * 0.20
            components.append(TaxComponent(
                name: "Income Tax (20%)",
                amount: CurrencyAmount(value: amount, currency: .inr),
                rate: 0.20,
                description: "Tax on income ₹5L - ₹10L"
            ))
        }
        
        if taxableIncome > 1000000 {
            let amount = (taxableIncome - 1000000) * 0.30
            components.append(TaxComponent(
                name: "Income Tax (30%)",
                amount: CurrencyAmount(value: amount, currency: .inr),
                rate: 0.30,
                description: "Tax on income above ₹10L"
            ))
        }
        
        return components
    }
    
    private func getIndianFilingRequirements(income: Decimal, residencyStatus: ResidencyStatus) -> [String] {
        var requirements: [String] = []
        
        if income > 250000 {
            requirements.append("Income Tax Return (ITR) filing required")
        }
        
        if income > 1000000 {
            requirements.append("Advance tax payment required")
        }
        
        if residencyStatus == .nonResident {
            requirements.append("Form 10F submission for treaty benefits")
        }
        
        return requirements
    }
}

// MARK: - US Tax Calculator
class USTaxCalculator: TaxCalculatorProtocol {
    let country: SupportedCountry = .unitedStates
    let taxYear: String
    
    init(taxYear: String = "2025") {
        self.taxYear = taxYear
    }
    
    func calculateTaxLiability(
        income: CurrencyAmount,
        residencyStatus: ResidencyStatus,
        deductions: [TaxDeduction]
    ) -> TaxCalculationResult {
        let incomeInUSD = CurrencyManager.shared.convert(
            amount: income.value,
            from: income.currency,
            to: .usd
        )
        
        // Standard deduction for 2025
        let standardDeduction: Decimal = 15000 // Single filer
        
        let totalDeductions = deductions.reduce(standardDeduction) { sum, deduction in
            sum + CurrencyManager.shared.convert(
                amount: deduction.amount.value,
                from: deduction.amount.currency,
                to: .usd
            )
        }
        
        let taxableIncome = max(0, incomeInUSD - totalDeductions)
        let taxLiability = calculateUSFederalTax(taxableIncome: taxableIncome, residencyStatus: residencyStatus)
        
        return TaxCalculationResult(
            taxableIncome: CurrencyAmount(value: taxableIncome, currency: .usd),
            taxLiability: CurrencyAmount(value: taxLiability, currency: .usd),
            effectiveRate: Double(truncating: (taxLiability / incomeInUSD) as NSNumber),
            marginalRate: getUSMarginalTaxRate(income: taxableIncome),
            deductionsApplied: deductions,
            taxBreakdown: getUSTaxBreakdown(taxableIncome: taxableIncome),
            additionalRequirements: getUSFilingRequirements(income: incomeInUSD, residencyStatus: residencyStatus)
        )
    }
    
    private func calculateUSFederalTax(taxableIncome: Decimal, residencyStatus: ResidencyStatus) -> Decimal {
        var tax: Decimal = 0
        
        // 2025 tax brackets (single filer)
        if taxableIncome > 11600 {
            tax += min(taxableIncome - 11600, 35550) * 0.12 // 12% bracket
        }
        if taxableIncome > 47150 {
            tax += min(taxableIncome - 47150, 53700) * 0.22 // 22% bracket
        }
        if taxableIncome > 100850 {
            tax += min(taxableIncome - 100850, 90750) * 0.24 // 24% bracket
        }
        if taxableIncome > 191600 {
            tax += min(taxableIncome - 191600, 251950) * 0.32 // 32% bracket
        }
        if taxableIncome > 443550 {
            tax += min(taxableIncome - 443550, 215950) * 0.35 // 35% bracket
        }
        if taxableIncome > 659500 {
            tax += (taxableIncome - 659500) * 0.37 // 37% bracket
        }
        
        // Non-resident alien may have different rates
        if residencyStatus == .nonResident {
            // Flat 30% on FDAP income, graduated rates on ECI
            // This is simplified - actual calculation is more complex
        }
        
        return tax
    }
    
    func calculateWithholdingTax(
        income: CurrencyAmount,
        incomeType: IncomeType,
        sourceCountry: SupportedCountry
    ) -> CurrencyAmount {
        let incomeInUSD = CurrencyManager.shared.convert(
            amount: income.value,
            from: income.currency,
            to: .usd
        )
        
        let withholdingRate: Double
        switch incomeType {
        case .dividend: withholdingRate = 0.30 // 30% for non-residents
        case .interest: withholdingRate = 0.30
        case .royalty: withholdingRate = 0.30
        case .rental: withholdingRate = 0.30
        default: withholdingRate = 0.0
        }
        
        return CurrencyAmount(value: incomeInUSD * Decimal(withholdingRate), currency: .usd)
    }
    
    func getAvailableDeductions(residencyStatus: ResidencyStatus) -> [TaxDeductionType] {
        var deductions: [TaxDeductionType] = [
            .standardDeduction, .mortgageInterest, .stateAndLocalTax,
            .charitableContributions, .retirementContributions
        ]
        
        if residencyStatus == .resident {
            deductions.append(contentsOf: [.studentLoanInterest, .educationCredits])
        }
        
        return deductions
    }
    
    func getTaxBrackets(residencyStatus: ResidencyStatus) -> [TaxBracket] {
        return [
            TaxBracket(minIncome: CurrencyAmount(value: 0, currency: .usd),
                      maxIncome: CurrencyAmount(value: 11600, currency: .usd),
                      rate: 0.10, description: "10% tax bracket"),
            TaxBracket(minIncome: CurrencyAmount(value: 11600, currency: .usd),
                      maxIncome: CurrencyAmount(value: 47150, currency: .usd),
                      rate: 0.12, description: "12% tax bracket"),
            TaxBracket(minIncome: CurrencyAmount(value: 47150, currency: .usd),
                      maxIncome: CurrencyAmount(value: 100850, currency: .usd),
                      rate: 0.22, description: "22% tax bracket"),
            TaxBracket(minIncome: CurrencyAmount(value: 100850, currency: .usd),
                      maxIncome: nil,
                      rate: 0.32, description: "32% tax bracket and above")
        ]
    }
    
    func getFilingDeadlines() -> [FilingDeadline] {
        return [
            FilingDeadline(
                type: .incomeTaxReturn,
                dueDate: Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 15))!,
                description: "Form 1040 filing deadline",
                penalties: "$485 or more late filing penalty"
            ),
            FilingDeadline(
                type: .estimatedTax,
                dueDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15))!,
                description: "Q2 estimated tax payment",
                penalties: "Underpayment interest and penalties"
            )
        ]
    }
    
    private func getUSMarginalTaxRate(income: Decimal) -> Double {
        if income <= 11600 { return 0.10 }
        else if income <= 47150 { return 0.12 }
        else if income <= 100850 { return 0.22 }
        else if income <= 191600 { return 0.24 }
        else if income <= 443550 { return 0.32 }
        else if income <= 659500 { return 0.35 }
        else { return 0.37 }
    }
    
    private func getUSTaxBreakdown(taxableIncome: Decimal) -> [TaxComponent] {
        var components: [TaxComponent] = []
        
        if taxableIncome > 11600 {
            let amount = min(taxableIncome - 11600, 35550) * 0.12
            components.append(TaxComponent(
                name: "Federal Tax (12%)",
                amount: CurrencyAmount(value: amount, currency: .usd),
                rate: 0.12,
                description: "Tax on income $11,600 - $47,150"
            ))
        }
        
        // Add more brackets as needed...
        
        return components
    }
    
    private func getUSFilingRequirements(income: Decimal, residencyStatus: ResidencyStatus) -> [String] {
        var requirements: [String] = []
        
        if income > 13850 { // 2025 threshold
            requirements.append("Form 1040 filing required")
        }
        
        if residencyStatus == .nonResident {
            requirements.append("Form 1040NR for non-resident aliens")
            requirements.append("Form 8843 for days present in US")
        }
        
        return requirements
    }
}
```

### 4. Tax Treaty Management
```swift
struct TaxTreaty: Identifiable, Codable {
    let id = UUID()
    let country1: SupportedCountry
    let country2: SupportedCountry
    let treatyName: String
    let effectiveDate: Date
    let benefits: [TreatyBenefit]
    
    var displayName: String {
        return "\(country1.displayName) - \(country2.displayName) Tax Treaty"
    }
}

struct TreatyBenefit: Identifiable, Codable {
    let id = UUID()
    let incomeType: IncomeType
    let reducedRate: Double?
    let exemptionConditions: [String]
    let documentation: [String]
    let description: String
    
    var applicableRate: Double {
        return reducedRate ?? 0.0
    }
}

class TaxTreatyManager: ObservableObject {
    @Published var availableTreaties: [TaxTreaty] = []
    @Published var applicableTreaties: [TaxTreaty] = []
    
    init() {
        loadTaxTreaties()
    }
    
    func findApplicableTreaties(
        residenceCountry: SupportedCountry,
        sourceCountry: SupportedCountry
    ) -> [TaxTreaty] {
        return availableTreaties.filter { treaty in
            (treaty.country1 == residenceCountry && treaty.country2 == sourceCountry) ||
            (treaty.country1 == sourceCountry && treaty.country2 == residenceCountry)
        }
    }
    
    func getTreatyBenefits(
        treaty: TaxTreaty,
        incomeType: IncomeType,
        amount: CurrencyAmount
    ) -> TreatyBenefit? {
        return treaty.benefits.first { $0.incomeType == incomeType }
    }
    
    func calculateWithholdingWithTreaty(
        income: CurrencyAmount,
        incomeType: IncomeType,
        sourceCountry: SupportedCountry,
        residenceCountry: SupportedCountry
    ) -> CurrencyAmount {
        let applicableTreaties = findApplicableTreaties(
            residenceCountry: residenceCountry,
            sourceCountry: sourceCountry
        )
        
        guard let treaty = applicableTreaties.first,
              let benefit = getTreatyBenefits(treaty: treaty, incomeType: incomeType, amount: income) else {
            // No treaty benefit, use domestic rate
            return calculateDomesticWithholding(income: income, incomeType: incomeType, country: sourceCountry)
        }
        
        let treatyRate = benefit.applicableRate
        return CurrencyAmount(
            value: income.value * Decimal(treatyRate),
            currency: income.currency
        )
    }
    
    private func calculateDomesticWithholding(
        income: CurrencyAmount,
        incomeType: IncomeType,
        country: SupportedCountry
    ) -> CurrencyAmount {
        // This would call the appropriate country calculator
        // For now, return a default rate
        let defaultRate: Double = 0.30
        return CurrencyAmount(
            value: income.value * Decimal(defaultRate),
            currency: income.currency
        )
    }
    
    private func loadTaxTreaties() {
        // Load from embedded JSON or API
        availableTreaties = [
            TaxTreaty(
                country1: .india,
                country2: .unitedStates,
                treatyName: "India-US DTAA",
                effectiveDate: Date(),
                benefits: [
                    TreatyBenefit(
                        incomeType: .dividend,
                        reducedRate: 0.15,
                        exemptionConditions: ["Beneficial ownership"],
                        documentation: ["Form 10F", "Tax residency certificate"],
                        description: "Reduced withholding on dividends"
                    ),
                    TreatyBenefit(
                        incomeType: .interest,
                        reducedRate: 0.10,
                        exemptionConditions: ["Beneficial ownership", "Not contingent interest"],
                        documentation: ["Form 10F", "Tax residency certificate"],
                        description: "Reduced withholding on interest"
                    )
                ]
            )
            // Add more treaties...
        ]
    }
}
```

### 5. Multi-Country Tax Manager
```swift
class MultiCountryTaxManager: ObservableObject {
    @Published var taxProfiles: [TaxProfile] = []
    @Published var globalTaxSummary: GlobalTaxSummary?
    @Published var crossBorderImplications: [CrossBorderImplication] = []
    
    private let taxCalculators: [SupportedCountry: TaxCalculatorProtocol]
    private let treatyManager = TaxTreatyManager()
    
    init() {
        // Initialize country-specific calculators
        self.taxCalculators = [
            .india: IndiaTaxCalculator(),
            .unitedStates: USTaxCalculator(),
            // Add more calculators...
        ]
        
        loadTaxProfiles()
    }
    
    func addTaxProfile(country: SupportedCountry, residencyStatus: ResidencyStatus) -> TaxProfile {
        let profile = TaxProfile(
            country: country,
            residencyStatus: residencyStatus,
            taxYear: getCurrentTaxYear(for: country)
        )
        
        taxProfiles.append(profile)
        calculateGlobalTaxSummary()
        return profile
    }
    
    func updateResidencyStatus(profileId: UUID, status: ResidencyStatus) {
        if let index = taxProfiles.firstIndex(where: { $0.id == profileId }) {
            taxProfiles[index].residencyStatus = status
            calculateGlobalTaxSummary()
        }
    }
    
    func calculateGlobalTaxSummary() {
        var totalGlobalIncome = CurrencyAmount(value: 0, currency: .usd)
        var totalTaxLiability = CurrencyAmount(value: 0, currency: .usd)
        var countryTaxSummaries: [CountryTaxSummary] = []
        
        for profile in taxProfiles {
            guard let calculator = taxCalculators[profile.country] else { continue }
            
            // Calculate tax for this country
            let result = calculator.calculateTaxLiability(
                income: profile.globalIncome,
                residencyStatus: profile.residencyStatus,
                deductions: [] // Would get from profile
            )
            
            let summary = CountryTaxSummary(
                country: profile.country,
                taxableIncome: result.taxableIncome,
                taxLiability: result.taxLiability,
                effectiveRate: result.effectiveRate,
                residencyStatus: profile.residencyStatus,
                filingRequired: !result.additionalRequirements.isEmpty
            )
            
            countryTaxSummaries.append(summary)
            
            // Convert to USD for global totals
            let incomeInUSD = CurrencyManager.shared.convertToDisplayCurrency(
                amount: result.taxableIncome
            )
            let taxInUSD = CurrencyManager.shared.convertToDisplayCurrency(
                amount: result.taxLiability
            )
            
            totalGlobalIncome = CurrencyAmount(
                value: totalGlobalIncome.value + incomeInUSD.value,
                currency: totalGlobalIncome.currency
            )
            totalTaxLiability = CurrencyAmount(
                value: totalTaxLiability.value + taxInUSD.value,
                currency: totalTaxLiability.currency
            )
        }
        
        globalTaxSummary = GlobalTaxSummary(
            totalGlobalIncome: totalGlobalIncome,
            totalTaxLiability: totalTaxLiability,
            countryBreakdown: countryTaxSummaries,
            treaties: treatyManager.applicableTreaties,
            crossBorderImplications: calculateCrossBorderImplications()
        )
    }
    
    private func calculateCrossBorderImplications() -> [CrossBorderImplication] {
        var implications: [CrossBorderImplication] = []
        
        // Check for potential double taxation
        let residentCountries = taxProfiles.filter { $0.residencyStatus == .resident }
        if residentCountries.count > 1 {
            implications.append(CrossBorderImplication(
                type: .doubleTaxation,
                countries: residentCountries.map { $0.country },
                description: "Multiple tax residencies may lead to double taxation",
                recommendation: "Consider tax treaty benefits and foreign tax credits",
                priority: .high
            ))
        }
        
        // Check for filing requirements
        for profile in taxProfiles {
            if let calculator = taxCalculators[profile.country],
               !calculator.getFilingDeadlines().isEmpty {
                implications.append(CrossBorderImplication(
                    type: .filingRequirement,
                    countries: [profile.country],
                    description: "Tax filing required in \(profile.country.displayName)",
                    recommendation: "Ensure compliance with local filing requirements",
                    priority: .medium
                ))
            }
        }
        
        return implications
    }
    
    private func getCurrentTaxYear(for country: SupportedCountry) -> String {
        let calendar = Calendar.current
        let currentDate = Date()
        
        switch country.taxYear {
        case .april: // India (Apr-Mar)
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            if month >= 4 {
                return "\(year)-\(String(year + 1).suffix(2))"
            } else {
                return "\(year - 1)-\(String(year).suffix(2))"
            }
        case .july: // Australia (Jul-Jun)
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)
            if month >= 7 {
                return "\(year)-\(String(year + 1).suffix(2))"
            } else {
                return "\(year - 1)-\(String(year).suffix(2))"
            }
        case .january: // Most countries (Jan-Dec)
            return String(calendar.component(.year, from: currentDate))
        }
    }
    
    private func loadTaxProfiles() {
        // Load from persistent storage
        if let data = UserDefaults.standard.data(forKey: "taxProfiles"),
           let profiles = try? JSONDecoder().decode([TaxProfile].self, from: data) {
            taxProfiles = profiles
            calculateGlobalTaxSummary()
        }
    }
    
    func saveTaxProfiles() {
        if let data = try? JSONEncoder().encode(taxProfiles) {
            UserDefaults.standard.set(data, forKey: "taxProfiles")
        }
    }
}

struct GlobalTaxSummary {
    let totalGlobalIncome: CurrencyAmount
    let totalTaxLiability: CurrencyAmount
    let countryBreakdown: [CountryTaxSummary]
    let treaties: [TaxTreaty]
    let crossBorderImplications: [CrossBorderImplication]
    
    var effectiveGlobalTaxRate: Double {
        guard totalGlobalIncome.value > 0 else { return 0.0 }
        return Double(truncating: (totalTaxLiability.value / totalGlobalIncome.value) as NSNumber)
    }
}

struct CountryTaxSummary {
    let country: SupportedCountry
    let taxableIncome: CurrencyAmount
    let taxLiability: CurrencyAmount
    let effectiveRate: Double
    let residencyStatus: ResidencyStatus
    let filingRequired: Bool
}

struct CrossBorderImplication {
    let type: ImplicationType
    let countries: [SupportedCountry]
    let description: String
    let recommendation: String
    let priority: Priority
    
    enum ImplicationType {
        case doubleTaxation
        case filingRequirement
        case treatyBenefit
        case witholdingTax
        case transferPricing
    }
    
    enum Priority {
        case high, medium, low
    }
}
```

### 6. Supporting Types
```swift
enum TaxDeductionType: String, CaseIterable {
    // India
    case section80C = "80C"
    case section80D = "80D"
    case section80G = "80G"
    case section80E = "80E"
    case section80CCD1B = "80CCD(1B)"
    case section80TTA = "80TTA"
    case hra = "HRA"
    case lta = "LTA"
    case standardDeduction = "standard_deduction"
    
    // US
    case mortgageInterest = "mortgage_interest"
    case stateAndLocalTax = "state_local_tax"
    case charitableContributions = "charitable_contributions"
    case retirementContributions = "retirement_contributions"
    case studentLoanInterest = "student_loan_interest"
    case educationCredits = "education_credits"
    
    // Add more as needed
}

struct TaxDeduction: Identifiable, Codable {
    let id = UUID()
    let type: TaxDeductionType
    let amount: CurrencyAmount
    let description: String
    let supportingDocuments: [String]
}

enum FilingType {
    case incomeTaxReturn
    case advanceTax
    case estimatedTax
    case witholdingTax
    case gstReturn
    case vatReturn
}

struct FilingRequirement {
    let type: FilingType
    let country: SupportedCountry
    let dueDate: Date
    let description: String
    let penalties: String
    let completed: Bool
}

struct FilingDeadline {
    let type: FilingType
    let dueDate: Date
    let description: String
    let penalties: String
}

struct AdvanceTaxPayment: Identifiable, Codable {
    let id = UUID()
    let country: SupportedCountry
    let amount: CurrencyAmount
    let paymentDate: Date
    let installmentNumber: Int
    let referenceNumber: String
}
```

This multi-country tax module provides:

1. **Resident/Non-Resident Support**: Handles different tax rates and rules based on residency status
2. **Cross-Border Tax Treaties**: Manages treaty benefits and reduced withholding rates
3. **Multiple Country Filing**: Tracks filing requirements across all countries
4. **Currency Conversion**: Handles tax calculations in local currencies with conversion
5. **Global Tax Summary**: Unified view of worldwide tax obligations
6. **Compliance Tracking**: Monitors filing deadlines and compliance status

The modular design allows easy addition of new countries and tax rules while maintaining consistent interfaces.