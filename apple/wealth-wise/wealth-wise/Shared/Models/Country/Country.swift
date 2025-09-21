import Foundation

/// Represents a country with financial and cultural context for WealthWise
public struct Country: Codable, Hashable, Identifiable {
    public let id: String // ISO 3166-1 alpha-2 country code
    public let name: String
    public let displayName: String
    public let flag: String
    public let primaryCurrency: SupportedCurrency
    public let secondaryCurrencies: [SupportedCurrency]
    public let region: GeographicRegion
    public let regulatoryZone: RegulatoryZone
    public let financialYearStart: FinancialYearStart
    public let numberingSystem: NumberingSystem
    public let taxSystem: TaxSystemType
    public let retirementAge: RetirementAge
    public let commonInvestmentTypes: [InvestmentType]
    public let bankingFeatures: BankingFeatures
    public let culturalPreferences: CulturalPreferences
    
    public init(
        id: String,
        name: String,
        displayName: String,
        flag: String,
        primaryCurrency: SupportedCurrency,
        secondaryCurrencies: [SupportedCurrency] = [],
        region: GeographicRegion,
        regulatoryZone: RegulatoryZone,
        financialYearStart: FinancialYearStart,
        numberingSystem: NumberingSystem,
        taxSystem: TaxSystemType,
        retirementAge: RetirementAge,
        commonInvestmentTypes: [InvestmentType],
        bankingFeatures: BankingFeatures,
        culturalPreferences: CulturalPreferences
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.flag = flag
        self.primaryCurrency = primaryCurrency
        self.secondaryCurrencies = secondaryCurrencies
        self.region = region
        self.regulatoryZone = regulatoryZone
        self.financialYearStart = financialYearStart
        self.numberingSystem = numberingSystem
        self.taxSystem = taxSystem
        self.retirementAge = retirementAge
        self.commonInvestmentTypes = commonInvestmentTypes
        self.bankingFeatures = bankingFeatures
        self.culturalPreferences = culturalPreferences
    }
}

// MARK: - Supporting Types

public enum GeographicRegion: String, Codable, CaseIterable {
    case northAmerica = "north_america"
    case southAmerica = "south_america"
    case europe = "europe"
    case asia = "asia"
    case oceania = "oceania"
    case africa = "africa"
    case middleEast = "middle_east"
    
    public var displayName: String {
        switch self {
        case .northAmerica: return "North America"
        case .southAmerica: return "South America"
        case .europe: return "Europe"
        case .asia: return "Asia"
        case .oceania: return "Oceania"
        case .africa: return "Africa"
        case .middleEast: return "Middle East"
        }
    }
}

public enum RegulatoryZone: String, Codable, CaseIterable {
    case gdpr = "gdpr" // European Union
    case ccpa = "ccpa" // California/US
    case pipeda = "pipeda" // Canada
    case appi = "appi" // Japan
    case pdpa = "pdpa" // Singapore/Thailand
    case lgpd = "lgpd" // Brazil
    case dpia = "dpia" // India (Data Protection and Privacy Act)
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .gdpr: return "GDPR (EU)"
        case .ccpa: return "CCPA (California)"
        case .pipeda: return "PIPEDA (Canada)"
        case .appi: return "APPI (Japan)"
        case .pdpa: return "PDPA (Singapore/Thailand)"
        case .lgpd: return "LGPD (Brazil)"
        case .dpia: return "DPIA (India)"
        case .other: return "Other"
        }
    }
    
    public var requiresExplicitConsent: Bool {
        switch self {
        case .gdpr, .lgpd, .dpia: return true
        case .ccpa, .pipeda, .appi, .pdpa, .other: return false
        }
    }
    
    public var dataRetentionLimit: TimeInterval? {
        switch self {
        case .gdpr: return 365 * 24 * 60 * 60 * 7 // 7 years
        case .ccpa: return 365 * 24 * 60 * 60 * 2 // 2 years
        case .dpia: return 365 * 24 * 60 * 60 * 5 // 5 years
        default: return nil
        }
    }
}

public enum FinancialYearStart: String, Codable, CaseIterable {
    case january = "january" // Calendar year (US, Europe, etc.)
    case april = "april" // India, Japan, UK (corporate)
    case july = "july" // Australia
    case october = "october" // Some corporates
    
    public var displayName: String {
        switch self {
        case .january: return "January (Calendar Year)"
        case .april: return "April (India/Japan style)"
        case .july: return "July (Australia style)"
        case .october: return "October (Corporate)"
        }
    }
    
    public var startMonth: Int {
        switch self {
        case .january: return 1
        case .april: return 4
        case .july: return 7
        case .october: return 10
        }
    }
}

public enum NumberingSystem: String, Codable, CaseIterable {
    case western = "western" // 1,000,000 (million)
    case indian = "indian" // 10,00,000 (lakh)
    case chinese = "chinese" // 100万 (wan)
    case arabic = "arabic" // ١٢٣٤٥٦٧
    
    public var displayName: String {
        switch self {
        case .western: return "Western (Million/Billion)"
        case .indian: return "Indian (Lakh/Crore)"
        case .chinese: return "Chinese (Wan/Yi)"
        case .arabic: return "Arabic Numerals"
        }
    }
    
    public var thousandsSeparator: String {
        switch self {
        case .western: return ","
        case .indian: return ","
        case .chinese: return ","
        case .arabic: return "٬"
        }
    }
    
    public var decimalSeparator: String {
        switch self {
        case .western, .indian, .chinese: return "."
        case .arabic: return "٫"
        }
    }
}

public enum TaxSystemType: String, Codable, CaseIterable {
    case progressive = "progressive" // Higher income = higher rate
    case flat = "flat" // Single rate for all
    case regressive = "regressive" // Lower income = higher effective rate
    case dual = "dual" // Separate rates for different income types
    
    public var displayName: String {
        switch self {
        case .progressive: return "Progressive Tax System"
        case .flat: return "Flat Tax System"
        case .regressive: return "Regressive Tax System"
        case .dual: return "Dual Tax System"
        }
    }
}

public struct RetirementAge: Codable, Hashable {
    public let standard: Int
    public let early: Int?
    public let maximum: Int?
    public let pensionEligibility: Int?
    
    public init(standard: Int, early: Int? = nil, maximum: Int? = nil, pensionEligibility: Int? = nil) {
        self.standard = standard
        self.early = early
        self.maximum = maximum
        self.pensionEligibility = pensionEligibility
    }
}

public enum InvestmentType: String, Codable, CaseIterable {
    // Retirement & Tax-Advantaged
    case retirement401k = "retirement_401k"
    case retirementIRA = "retirement_ira"
    case retirementRoth = "retirement_roth"
    case retirementPPF = "retirement_ppf" // India Public Provident Fund
    case retirementEPF = "retirement_epf" // India Employee Provident Fund
    case retirementNSC = "retirement_nsc" // India National Savings Certificate
    case retirementELSS = "retirement_elss" // India Equity Linked Savings Scheme
    case retirementSuperannuation = "retirement_superannuation" // Australia
    
    // Stocks & Equity
    case stocksLocal = "stocks_local"
    case stocksInternational = "stocks_international"
    case stocksETF = "stocks_etf"
    case stocksMutualFunds = "stocks_mutual_funds"
    case stocksIndexFunds = "stocks_index_funds"
    
    // Fixed Income
    case bondsGovernment = "bonds_government"
    case bondsCorporate = "bonds_corporate"
    case bondsFixed = "bonds_fixed"
    case bondsInflationLinked = "bonds_inflation_linked"
    
    // Real Estate
    case realEstateREIT = "real_estate_reit"
    case realEstateDirect = "real_estate_direct"
    case realEstateCommercial = "real_estate_commercial"
    
    // Alternative
    case alternativeGold = "alternative_gold"
    case alternativeCrypto = "alternative_crypto"
    case alternativeCommodities = "alternative_commodities"
    case alternativeP2P = "alternative_p2p"
    
    // Cash & Equivalents
    case cashSavings = "cash_savings"
    case cashCD = "cash_cd"
    case cashMoneyMarket = "cash_money_market"
    
    public var displayName: String {
        switch self {
        case .retirement401k: return "401(k)"
        case .retirementIRA: return "IRA"
        case .retirementRoth: return "Roth IRA"
        case .retirementPPF: return "PPF (Public Provident Fund)"
        case .retirementEPF: return "EPF (Employee Provident Fund)"
        case .retirementNSC: return "NSC (National Savings Certificate)"
        case .retirementELSS: return "ELSS (Tax Saving Mutual Funds)"
        case .retirementSuperannuation: return "Superannuation"
        case .stocksLocal: return "Local Stocks"
        case .stocksInternational: return "International Stocks"
        case .stocksETF: return "ETFs"
        case .stocksMutualFunds: return "Mutual Funds"
        case .stocksIndexFunds: return "Index Funds"
        case .bondsGovernment: return "Government Bonds"
        case .bondsCorporate: return "Corporate Bonds"
        case .bondsFixed: return "Fixed Deposits"
        case .bondsInflationLinked: return "Inflation-Linked Bonds"
        case .realEstateREIT: return "REITs"
        case .realEstateDirect: return "Direct Real Estate"
        case .realEstateCommercial: return "Commercial Real Estate"
        case .alternativeGold: return "Gold"
        case .alternativeCrypto: return "Cryptocurrency"
        case .alternativeCommodities: return "Commodities"
        case .alternativeP2P: return "P2P Lending"
        case .cashSavings: return "Savings Account"
        case .cashCD: return "Certificate of Deposit"
        case .cashMoneyMarket: return "Money Market"
        }
    }
    
    public var category: InvestmentCategory {
        switch self {
        case .retirement401k, .retirementIRA, .retirementRoth, .retirementPPF, .retirementEPF, .retirementNSC, .retirementELSS, .retirementSuperannuation:
            return .retirement
        case .stocksLocal, .stocksInternational, .stocksETF, .stocksMutualFunds, .stocksIndexFunds:
            return .equity
        case .bondsGovernment, .bondsCorporate, .bondsFixed, .bondsInflationLinked:
            return .fixedIncome
        case .realEstateREIT, .realEstateDirect, .realEstateCommercial:
            return .realEstate
        case .alternativeGold, .alternativeCrypto, .alternativeCommodities, .alternativeP2P:
            return .alternative
        case .cashSavings, .cashCD, .cashMoneyMarket:
            return .cash
        }
    }
}

public enum InvestmentCategory: String, Codable, CaseIterable {
    case retirement = "retirement"
    case equity = "equity"
    case fixedIncome = "fixed_income"
    case realEstate = "real_estate"
    case alternative = "alternative"
    case cash = "cash"
    
    public var displayName: String {
        switch self {
        case .retirement: return "Retirement & Tax-Advantaged"
        case .equity: return "Stocks & Equity"
        case .fixedIncome: return "Fixed Income & Bonds"
        case .realEstate: return "Real Estate"
        case .alternative: return "Alternative Investments"
        case .cash: return "Cash & Cash Equivalents"
        }
    }
}

public struct BankingFeatures: Codable, Hashable {
    public let hasUPI: Bool // Unified Payments Interface (India)
    public let hasOpenBanking: Bool // PSD2 (Europe), Open Banking (UK)
    public let hasInstantTransfers: Bool
    public let hasWireTransfers: Bool
    public let hasACH: Bool // Automated Clearing House (US)
    public let hasSEPA: Bool // Single Euro Payments Area
    public let hasRTGS: Bool // Real Time Gross Settlement (India)
    public let hasNEFT: Bool // National Electronic Funds Transfer (India)
    public let hasInterac: Bool // Canada
    public let supportedAccountTypes: [BankAccountType]
    
    public init(
        hasUPI: Bool = false,
        hasOpenBanking: Bool = false,
        hasInstantTransfers: Bool = false,
        hasWireTransfers: Bool = true,
        hasACH: Bool = false,
        hasSEPA: Bool = false,
        hasRTGS: Bool = false,
        hasNEFT: Bool = false,
        hasInterac: Bool = false,
        supportedAccountTypes: [BankAccountType]
    ) {
        self.hasUPI = hasUPI
        self.hasOpenBanking = hasOpenBanking
        self.hasInstantTransfers = hasInstantTransfers
        self.hasWireTransfers = hasWireTransfers
        self.hasACH = hasACH
        self.hasSEPA = hasSEPA
        self.hasRTGS = hasRTGS
        self.hasNEFT = hasNEFT
        self.hasInterac = hasInterac
        self.supportedAccountTypes = supportedAccountTypes
    }
}

public enum BankAccountType: String, Codable, CaseIterable {
    case checking = "checking"
    case savings = "savings"
    case moneyMarket = "money_market"
    case cd = "certificate_deposit"
    case business = "business"
    case joint = "joint"
    case trust = "trust"
    case currentAccount = "current_account" // Business account in India/UK
    case fixedDeposit = "fixed_deposit" // India/Asia
    case recurringDeposit = "recurring_deposit" // India
    
    public var displayName: String {
        switch self {
        case .checking: return "Checking Account"
        case .savings: return "Savings Account"
        case .moneyMarket: return "Money Market Account"
        case .cd: return "Certificate of Deposit"
        case .business: return "Business Account"
        case .joint: return "Joint Account"
        case .trust: return "Trust Account"
        case .currentAccount: return "Current Account"
        case .fixedDeposit: return "Fixed Deposit"
        case .recurringDeposit: return "Recurring Deposit"
        }
    }
}

public struct CulturalPreferences: Codable, Hashable {
    public let dateFormat: DateFormatStyle
    public let weekStartsOn: Weekday
    public let workingDays: [Weekday]
    public let commonHolidays: [String] // Holiday names
    public let timeFormat: TimeFormat
    public let familyFinanceStyle: FamilyFinanceStyle
    public let savingsPreference: SavingsPreference
    public let investmentRiskTolerance: RiskTolerance
    
    public init(
        dateFormat: DateFormatStyle,
        weekStartsOn: Weekday,
        workingDays: [Weekday],
        commonHolidays: [String],
        timeFormat: TimeFormat,
        familyFinanceStyle: FamilyFinanceStyle,
        savingsPreference: SavingsPreference,
        investmentRiskTolerance: RiskTolerance
    ) {
        self.dateFormat = dateFormat
        self.weekStartsOn = weekStartsOn
        self.workingDays = workingDays
        self.commonHolidays = commonHolidays
        self.timeFormat = timeFormat
        self.familyFinanceStyle = familyFinanceStyle
        self.savingsPreference = savingsPreference
        self.investmentRiskTolerance = investmentRiskTolerance
    }
}

public enum DateFormatStyle: String, Codable, CaseIterable {
    case monthDayYear = "mm_dd_yyyy" // US: 12/31/2023
    case dayMonthYear = "dd_mm_yyyy" // Europe/India: 31/12/2023
    case yearMonthDay = "yyyy_mm_dd" // ISO 8601: 2023-12-31
    
    public var displayName: String {
        switch self {
        case .monthDayYear: return "MM/DD/YYYY (US Style)"
        case .dayMonthYear: return "DD/MM/YYYY (European/Indian Style)"
        case .yearMonthDay: return "YYYY-MM-DD (ISO 8601)"
        }
    }
}

public enum Weekday: String, Codable, CaseIterable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"
    
    public var displayName: String {
        return self.rawValue.capitalized
    }
}

public enum TimeFormat: String, Codable, CaseIterable {
    case twelve = "12_hour" // 12:30 PM
    case twentyFour = "24_hour" // 12:30
    
    public var displayName: String {
        switch self {
        case .twelve: return "12-hour (AM/PM)"
        case .twentyFour: return "24-hour"
        }
    }
}

public enum FamilyFinanceStyle: String, Codable, CaseIterable {
    case individual = "individual" // Personal finance management
    case joint = "joint" // Shared family finances
    case hybrid = "hybrid" // Mix of individual and shared
    
    public var displayName: String {
        switch self {
        case .individual: return "Individual Finance Management"
        case .joint: return "Joint Family Finances"
        case .hybrid: return "Hybrid (Individual + Shared)"
        }
    }
}

public enum SavingsPreference: String, Codable, CaseIterable {
    case conservative = "conservative" // High safety, low risk
    case balanced = "balanced" // Balanced risk/return
    case aggressive = "aggressive" // High growth, higher risk
    case goalBased = "goal_based" // Different strategies for different goals
    
    public var displayName: String {
        switch self {
        case .conservative: return "Conservative (Safety First)"
        case .balanced: return "Balanced (Moderate Risk)"
        case .aggressive: return "Aggressive (Growth Focused)"
        case .goalBased: return "Goal-Based Strategy"
        }
    }
}

public enum RiskTolerance: String, Codable, CaseIterable {
    case veryLow = "very_low"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"
    
    public var displayName: String {
        switch self {
        case .veryLow: return "Very Low Risk"
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .veryHigh: return "Very High Risk"
        }
    }
    
    public var volatilityTolerance: Double {
        switch self {
        case .veryLow: return 0.05 // 5%
        case .low: return 0.10 // 10%
        case .moderate: return 0.20 // 20%
        case .high: return 0.35 // 35%
        case .veryHigh: return 0.50 // 50%
        }
    }
}