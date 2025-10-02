import Foundation

/// Complete result of a tax calculation including breakdown and metadata
public struct TaxCalculation: Sendable, Codable, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let country: String
    public let taxYear: String
    public let calculatedDate: Date
    
    // Income Details
    public let grossIncome: Decimal
    public let currency: String
    public let incomeBreakdown: IncomeBreakdown
    
    // Deductions
    public let totalDeductions: Decimal
    public let deductionsApplied: [TaxDeduction]
    
    // Tax Calculation
    public let taxableIncome: Decimal
    public let taxLiability: Decimal
    public let effectiveRate: Double  // As percentage
    public let marginalRate: Double   // As percentage
    public let taxBreakdown: [TaxComponent]
    
    // Additional Components
    public let cess: Decimal?  // India-specific
    public let surcharge: Decimal?  // High income surcharge
    public let withholdingTax: Decimal?
    public let foreignTaxCredit: Decimal?
    
    // Metadata
    public let residencyStatus: ResidencyType
    public let treatyBenefits: [TreatyBenefit]
    public let filingRequirements: [String]
    public let optimizationSuggestions: [TaxOptimizationSuggestion]
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        country: String,
        taxYear: String,
        calculatedDate: Date = Date(),
        grossIncome: Decimal,
        currency: String,
        incomeBreakdown: IncomeBreakdown,
        totalDeductions: Decimal,
        deductionsApplied: [TaxDeduction],
        taxableIncome: Decimal,
        taxLiability: Decimal,
        effectiveRate: Double,
        marginalRate: Double,
        taxBreakdown: [TaxComponent],
        cess: Decimal? = nil,
        surcharge: Decimal? = nil,
        withholdingTax: Decimal? = nil,
        foreignTaxCredit: Decimal? = nil,
        residencyStatus: ResidencyType,
        treatyBenefits: [TreatyBenefit] = [],
        filingRequirements: [String] = [],
        optimizationSuggestions: [TaxOptimizationSuggestion] = []
    ) {
        self.id = id
        self.country = country
        self.taxYear = taxYear
        self.calculatedDate = calculatedDate
        self.grossIncome = grossIncome
        self.currency = currency
        self.incomeBreakdown = incomeBreakdown
        self.totalDeductions = totalDeductions
        self.deductionsApplied = deductionsApplied
        self.taxableIncome = taxableIncome
        self.taxLiability = taxLiability
        self.effectiveRate = effectiveRate
        self.marginalRate = marginalRate
        self.taxBreakdown = taxBreakdown
        self.cess = cess
        self.surcharge = surcharge
        self.withholdingTax = withholdingTax
        self.foreignTaxCredit = foreignTaxCredit
        self.residencyStatus = residencyStatus
        self.treatyBenefits = treatyBenefits
        self.filingRequirements = filingRequirements
        self.optimizationSuggestions = optimizationSuggestions
    }
    
    // MARK: - Computed Properties
    
    /// Total tax including all components
    public var totalTax: Decimal {
        var total = taxLiability
        if let cessAmount = cess {
            total += cessAmount
        }
        if let surchargeAmount = surcharge {
            total += surchargeAmount
        }
        return total
    }
    
    /// Net income after tax
    public var netIncome: Decimal {
        return grossIncome - totalTax
    }
    
    /// Tax savings from deductions
    public var taxSavings: Decimal {
        return totalDeductions * Decimal(marginalRate / 100)
    }
}

/// Breakdown of income by type
public struct IncomeBreakdown: Sendable, Codable {
    public var salary: Decimal
    public var business: Decimal
    public var capitalGains: Decimal
    public var dividend: Decimal
    public var interest: Decimal
    public var rental: Decimal
    public var other: Decimal
    
    public init(
        salary: Decimal = 0,
        business: Decimal = 0,
        capitalGains: Decimal = 0,
        dividend: Decimal = 0,
        interest: Decimal = 0,
        rental: Decimal = 0,
        other: Decimal = 0
    ) {
        self.salary = salary
        self.business = business
        self.capitalGains = capitalGains
        self.dividend = dividend
        self.interest = interest
        self.rental = rental
        self.other = other
    }
    
    public var total: Decimal {
        return salary + business + capitalGains + dividend + interest + rental + other
    }
}

/// Component of tax calculation (e.g., federal, state, local)
public struct TaxComponent: Sendable, Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let amount: Decimal
    public let rate: Double?
    public let description: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        rate: Double? = nil,
        description: String
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.rate = rate
        self.description = description
    }
    
    /// Display rate as percentage
    public var ratePercentage: String? {
        guard let rate = rate else { return nil }
        return String(format: "%.1f%%", rate * 100)
    }
}

/// Tax treaty benefit applied to calculation
public struct TreatyBenefit: Sendable, Codable, Hashable, Identifiable {
    public let id: UUID
    public let treatyName: String
    public let country1: String
    public let country2: String
    public let benefitType: String
    public let reducedRate: Double?
    public let exemptionAmount: Decimal?
    public let description: String
    
    public init(
        id: UUID = UUID(),
        treatyName: String,
        country1: String,
        country2: String,
        benefitType: String,
        reducedRate: Double? = nil,
        exemptionAmount: Decimal? = nil,
        description: String
    ) {
        self.id = id
        self.treatyName = treatyName
        self.country1 = country1
        self.country2 = country2
        self.benefitType = benefitType
        self.reducedRate = reducedRate
        self.exemptionAmount = exemptionAmount
        self.description = description
    }
}
