import Foundation

/// Represents a tax deduction with type, amount, and limits
public struct TaxDeduction: Sendable, Codable, Hashable, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let type: TaxDeductionType
    public var amount: Decimal
    public let currency: String
    public let taxYear: String
    public var description: String?
    public var documentReference: String?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        type: TaxDeductionType,
        amount: Decimal,
        currency: String,
        taxYear: String,
        description: String? = nil,
        documentReference: String? = nil
    ) {
        self.id = id
        self.type = type
        self.amount = amount
        self.currency = currency
        self.taxYear = taxYear
        self.description = description
        self.documentReference = documentReference
    }
    
    // MARK: - Computed Properties
    
    /// Display name for the deduction
    public var displayName: String {
        return type.displayName
    }
    
    /// Maximum allowed deduction for this type
    public var maxAllowedAmount: Decimal? {
        return type.maxAmount
    }
    
    /// Whether the deduction amount is valid
    public var isValid: Bool {
        guard amount > 0 else { return false }
        if let max = maxAllowedAmount {
            return amount <= max
        }
        return true
    }
    
    /// Effective deduction amount (capped at maximum if applicable)
    public var effectiveAmount: Decimal {
        guard let max = maxAllowedAmount else { return amount }
        return min(amount, max)
    }
}

/// Types of tax deductions supported across jurisdictions
public enum TaxDeductionType: String, CaseIterable, Codable, Sendable {
    
    // India-specific deductions
    case section80C = "section80C"  // EPF, PPF, ELSS, Life Insurance
    case section80D = "section80D"  // Health Insurance
    case section80G = "section80G"  // Charitable Donations
    case nps = "nps"  // National Pension Scheme (additional 50k)
    case hra = "hra"  // House Rent Allowance
    case homeLoanInterest = "homeLoanInterest"
    case educationLoan = "educationLoan"
    case standardDeduction = "standardDeduction"
    
    // US-specific deductions
    case mortgageInterest = "mortgageInterest"
    case stateLocalTax = "stateLocalTax"
    case charitableContributions = "charitableContributions"
    case studentLoanInterest = "studentLoanInterest"
    case ira401k = "ira401k"
    
    // UK-specific deductions
    case personalAllowance = "personalAllowance"
    case pensionContributions = "pensionContributions"
    case marriageAllowance = "marriageAllowance"
    
    // Canada-specific deductions
    case rrsp = "rrsp"  // Registered Retirement Savings Plan
    case tfsa = "tfsa"  // Tax-Free Savings Account
    case childCare = "childCare"
    case movingExpenses = "movingExpenses"
    
    // Australia-specific deductions
    case superannuation = "superannuation"
    case workRelatedExpenses = "workRelatedExpenses"
    case investmentPropertyExpenses = "investmentPropertyExpenses"
    
    // Singapore-specific deductions
    case cpf = "cpf"  // Central Provident Fund
    case srs = "srs"  // Supplementary Retirement Scheme
    case courseFeesRelief = "courseFeesRelief"
    
    // Universal deductions
    case businessExpenses = "businessExpenses"
    case medicalExpenses = "medicalExpenses"
    case dependentRelief = "dependentRelief"
    case other = "other"
    
    public var displayName: String {
        switch self {
        // India
        case .section80C: return "80C: EPF/PPF/ELSS/Life Insurance"
        case .section80D: return "80D: Health Insurance"
        case .section80G: return "80G: Charitable Donations"
        case .nps: return "NPS Additional Deduction"
        case .hra: return "House Rent Allowance"
        case .homeLoanInterest: return "Home Loan Interest"
        case .educationLoan: return "Education Loan Interest"
        case .standardDeduction: return "Standard Deduction"
            
        // US
        case .mortgageInterest: return "Mortgage Interest"
        case .stateLocalTax: return "State & Local Tax"
        case .charitableContributions: return "Charitable Contributions"
        case .studentLoanInterest: return "Student Loan Interest"
        case .ira401k: return "IRA/401(k) Contributions"
            
        // UK
        case .personalAllowance: return "Personal Allowance"
        case .pensionContributions: return "Pension Contributions"
        case .marriageAllowance: return "Marriage Allowance"
            
        // Canada
        case .rrsp: return "RRSP Contributions"
        case .tfsa: return "TFSA Contributions"
        case .childCare: return "Child Care Expenses"
        case .movingExpenses: return "Moving Expenses"
            
        // Australia
        case .superannuation: return "Superannuation Contributions"
        case .workRelatedExpenses: return "Work-Related Expenses"
        case .investmentPropertyExpenses: return "Investment Property Expenses"
            
        // Singapore
        case .cpf: return "CPF Contributions"
        case .srs: return "SRS Contributions"
        case .courseFeesRelief: return "Course Fees Relief"
            
        // Universal
        case .businessExpenses: return "Business Expenses"
        case .medicalExpenses: return "Medical Expenses"
        case .dependentRelief: return "Dependent Relief"
        case .other: return "Other Deductions"
        }
    }
    
    /// Maximum deduction amount in the base currency (nil = no limit)
    public var maxAmount: Decimal? {
        switch self {
        // India (INR)
        case .section80C: return 150000
        case .section80D: return 50000  // Can be 100k for senior citizens
        case .nps: return 50000
        case .standardDeduction: return 75000
            
        // US (USD)
        case .stateLocalTax: return 10000
        case .studentLoanInterest: return 2500
            
        // UK (GBP)
        case .personalAllowance: return 12570
        case .marriageAllowance: return 1260
            
        // Canada (CAD)
        case .rrsp: return nil  // Limit based on income
        case .childCare: return 8000  // Per child under 7
            
        // Australia (AUD)
        case .superannuation: return 27500  // Concessional cap
            
        default: return nil
        }
    }
    
    /// Applicable countries for this deduction
    public var applicableCountries: [String] {
        switch self {
        case .section80C, .section80D, .section80G, .nps, .hra, .educationLoan:
            return ["IN"]
        case .mortgageInterest, .stateLocalTax, .charitableContributions, .studentLoanInterest, .ira401k:
            return ["US"]
        case .personalAllowance, .pensionContributions, .marriageAllowance:
            return ["GB", "UK"]
        case .rrsp, .tfsa, .childCare, .movingExpenses:
            return ["CA"]
        case .superannuation, .workRelatedExpenses, .investmentPropertyExpenses:
            return ["AU"]
        case .cpf, .srs, .courseFeesRelief:
            return ["SG"]
        case .homeLoanInterest, .standardDeduction, .businessExpenses, .medicalExpenses, .dependentRelief, .other:
            return []  // Universal or multiple countries
        }
    }
}
