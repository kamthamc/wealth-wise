import Foundation

/// Comprehensive asset type classification system for cross-border portfolio management
/// Supports Indian and international asset categories with regulatory compliance
public enum AssetType: String, CaseIterable, Codable, Hashable {
    
    // MARK: - Equity Instruments
    case publicEquityDomestic = "publicEquityDomestic"           // Listed stocks in home country
    case publicEquityInternational = "publicEquityInternational" // Foreign stocks
    case privateEquityDomestic = "privateEquityDomestic"         // Unlisted/private companies
    case privateEquityInternational = "privateEquityInternational" // Foreign private equity
    case startupInvestment = "startupInvestment"                 // Startup/angel investments
    case employeeStockOptions = "employeeStockOptions"           // ESOP/RSU/Stock options
    case equityMutualFunds = "equityMutualFunds"                // Equity mutual funds
    case equityETFs = "equityETFs"                               // Exchange-traded funds
    
    // MARK: - Fixed Income & Debt
    case governmentBonds = "governmentBonds"                     // Government securities
    case corporateBonds = "corporateBonds"                       // Corporate bonds/debentures
    case municipalBonds = "municipalBonds"                       // Municipal/local bonds
    case internationalBonds = "internationalBonds"               // Foreign bonds
    case debtMutualFunds = "debtMutualFunds"                    // Debt mutual funds
    case fixedDeposits = "fixedDeposits"                        // Bank FDs
    case recurringDeposits = "recurringDeposits"                // Bank RDs
    case postOfficeSchemes = "postOfficeSchemes"                // NSC, KVP, SSY, etc.
    case providentFund = "providentFund"                        // EPF, PPF, VPF
    case employeeProvidentFund = "employeeProvidentFund"        // Company EPF
    case publicProvidentFund = "publicProvidentFund"            // PPF accounts
    case voluntaryProvidentFund = "voluntaryProvidentFund"      // VPF contributions
    case nationalPensionScheme = "nationalPensionScheme"        // NPS Tier I & II
    
    // MARK: - Alternative Investments
    case realEstateResidential = "realEstateResidential"        // Residential property
    case realEstateCommercial = "realEstateCommercial"          // Commercial property
    case realEstateInternational = "realEstateInternational"    // Foreign real estate
    case realEstateInvestmentTrusts = "realEstateInvestmentTrusts" // REITs
    case goldPhysical = "goldPhysical"                          // Physical gold/jewelry
    case goldETFs = "goldETFs"                                  // Gold ETFs/funds
    case silverPhysical = "silverPhysical"                     // Physical silver
    case otherPreciousMetals = "otherPreciousMetals"           // Platinum, etc.
    case commodityETFs = "commodityETFs"                        // Commodity funds
    case commodityFutures = "commodityFutures"                  // Futures contracts
    case artAndCollectibles = "artAndCollectibles"              // Art, antiques, coins
    case intellectualProperty = "intellectualProperty"          // Patents, royalties
    case chitFunds = "chitFunds"                               // Traditional chit funds
    case traditionalInvestments = "traditionalInvestments"      // Other traditional schemes
    
    // MARK: - Insurance & Protection
    case lifeInsuranceTraditional = "lifeInsuranceTraditional"  // Traditional life insurance
    case lifeInsuranceULIP = "lifeInsuranceULIP"               // Unit-linked plans
    case healthInsurance = "healthInsurance"                    // Health insurance policies
    case termInsurance = "termInsurance"                        // Term life insurance
    case generalInsurance = "generalInsurance"                  // Motor, home, travel
    case annuityPlans = "annuityPlans"                         // Pension/annuity products
    
    // MARK: - Digital Assets
    case cryptocurrency = "cryptocurrency"                       // Bitcoin, Ethereum, etc.
    case cryptoETFs = "cryptoETFs"                              // Crypto ETFs (where legal)
    case digitalTokens = "digitalTokens"                        // NFTs, utility tokens
    case digitalCurrencies = "digitalCurrencies"               // CBDCs, stablecoins
    
    // MARK: - Business & Professional
    case businessOwnership = "businessOwnership"                // Sole proprietorship/partnership
    case businessInvestment = "businessInvestment"              // Investment in others' business
    case professionalPractice = "professionalPractice"          // Medical/legal practice
    case intellectualPropertyBusiness = "intellectualPropertyBusiness" // IP-based business
    case franchiseOwnership = "franchiseOwnership"              // Franchise investments
    
    // MARK: - Cash & Equivalents
    case savingsAccount = "savingsAccount"                      // Bank savings accounts
    case currentAccount = "currentAccount"                      // Current/checking accounts
    case cashInHand = "cashInHand"                             // Physical cash
    case moneyMarketFunds = "moneyMarketFunds"                 // Money market instruments
    case liquidFunds = "liquidFunds"                           // Ultra short-term funds
    case foreignCashAccounts = "foreignCashAccounts"           // Foreign bank accounts
    
    // MARK: - Vehicles & Equipment
    case personalVehicles = "personalVehicles"                  // Cars, motorcycles
    case commercialVehicles = "commercialVehicles"              // Trucks, commercial use
    case machinery = "machinery"                                // Industrial machinery
    case equipment = "equipment"                                // Professional equipment
    case furniture = "furniture"                                // Home/office furniture
    case electronics = "electronics"                            // Computers, gadgets
    
    // MARK: - Other Assets
    case otherTangible = "otherTangible"                       // Other physical assets
    case otherIntangible = "otherIntangible"                   // Other intangible assets
    case unknown = "unknown"                                    // Unclassified assets
    
    /// Display name for the asset type
    public var displayName: String {
        switch self {
        // Equity Instruments
        case .publicEquityDomestic: return "Domestic Stocks"
        case .publicEquityInternational: return "International Stocks"
        case .privateEquityDomestic: return "Private Equity (Domestic)"
        case .privateEquityInternational: return "Private Equity (International)"
        case .startupInvestment: return "Startup Investment"
        case .employeeStockOptions: return "Employee Stock Options"
        case .equityMutualFunds: return "Equity Mutual Funds"
        case .equityETFs: return "Equity ETFs"
        
        // Fixed Income & Debt
        case .governmentBonds: return "Government Bonds"
        case .corporateBonds: return "Corporate Bonds"
        case .municipalBonds: return "Municipal Bonds"
        case .internationalBonds: return "International Bonds"
        case .debtMutualFunds: return "Debt Mutual Funds"
        case .fixedDeposits: return "Fixed Deposits"
        case .recurringDeposits: return "Recurring Deposits"
        case .postOfficeSchemes: return "Post Office Schemes"
        case .providentFund: return "Provident Fund"
        case .employeeProvidentFund: return "Employee Provident Fund"
        case .publicProvidentFund: return "Public Provident Fund"
        case .voluntaryProvidentFund: return "Voluntary Provident Fund"
        case .nationalPensionScheme: return "National Pension Scheme"
        
        // Alternative Investments
        case .realEstateResidential: return "Residential Real Estate"
        case .realEstateCommercial: return "Commercial Real Estate"
        case .realEstateInternational: return "International Real Estate"
        case .realEstateInvestmentTrusts: return "REITs"
        case .goldPhysical: return "Physical Gold"
        case .goldETFs: return "Gold ETFs"
        case .silverPhysical: return "Physical Silver"
        case .otherPreciousMetals: return "Other Precious Metals"
        case .commodityETFs: return "Commodity ETFs"
        case .commodityFutures: return "Commodity Futures"
        case .artAndCollectibles: return "Art & Collectibles"
        case .intellectualProperty: return "Intellectual Property"
        case .chitFunds: return "Chit Funds"
        case .traditionalInvestments: return "Traditional Investments"
        
        // Insurance & Protection
        case .lifeInsuranceTraditional: return "Traditional Life Insurance"
        case .lifeInsuranceULIP: return "ULIP"
        case .healthInsurance: return "Health Insurance"
        case .termInsurance: return "Term Insurance"
        case .generalInsurance: return "General Insurance"
        case .annuityPlans: return "Annuity Plans"
        
        // Digital Assets
        case .cryptocurrency: return "Cryptocurrency"
        case .cryptoETFs: return "Crypto ETFs"
        case .digitalTokens: return "Digital Tokens"
        case .digitalCurrencies: return "Digital Currencies"
        
        // Business & Professional
        case .businessOwnership: return "Business Ownership"
        case .businessInvestment: return "Business Investment"
        case .professionalPractice: return "Professional Practice"
        case .intellectualPropertyBusiness: return "IP Business"
        case .franchiseOwnership: return "Franchise Ownership"
        
        // Cash & Equivalents
        case .savingsAccount: return "Savings Account"
        case .currentAccount: return "Current Account"
        case .cashInHand: return "Cash in Hand"
        case .moneyMarketFunds: return "Money Market Funds"
        case .liquidFunds: return "Liquid Funds"
        case .foreignCashAccounts: return "Foreign Cash Accounts"
        
        // Vehicles & Equipment
        case .personalVehicles: return "Personal Vehicles"
        case .commercialVehicles: return "Commercial Vehicles"
        case .machinery: return "Machinery"
        case .equipment: return "Equipment"
        case .furniture: return "Furniture"
        case .electronics: return "Electronics"
        
        // Other Assets
        case .otherTangible: return "Other Tangible Assets"
        case .otherIntangible: return "Other Intangible Assets"
        case .unknown: return "Unknown"
        }
    }
    
    /// Short display name for compact UI
    public var shortDisplayName: String {
        switch self {
        case .publicEquityDomestic: return "Stocks"
        case .publicEquityInternational: return "Foreign Stocks"
        case .privateEquityDomestic: return "Private Equity"
        case .employeeStockOptions: return "ESOP"
        case .equityMutualFunds: return "Equity MF"
        case .equityETFs: return "ETFs"
        case .governmentBonds: return "Govt Bonds"
        case .corporateBonds: return "Corp Bonds"
        case .fixedDeposits: return "FD"
        case .recurringDeposits: return "RD"
        case .publicProvidentFund: return "PPF"
        case .employeeProvidentFund: return "EPF"
        case .nationalPensionScheme: return "NPS"
        case .realEstateResidential: return "Home"
        case .goldPhysical: return "Gold"
        case .cryptocurrency: return "Crypto"
        case .savingsAccount: return "Savings"
        case .personalVehicles: return "Vehicle"
        default: return displayName
        }
    }
    
    /// Category grouping for the asset type
    public var category: AssetCategory {
        switch self {
        case .publicEquityDomestic, .publicEquityInternational, .privateEquityDomestic, 
             .privateEquityInternational, .startupInvestment, .employeeStockOptions,
             .equityMutualFunds, .equityETFs:
            return .equity
            
        case .governmentBonds, .corporateBonds, .municipalBonds, .internationalBonds,
             .debtMutualFunds, .fixedDeposits, .recurringDeposits, .postOfficeSchemes,
             .providentFund, .employeeProvidentFund, .publicProvidentFund,
             .voluntaryProvidentFund, .nationalPensionScheme:
            return .fixedIncome
            
        case .realEstateResidential, .realEstateCommercial, .realEstateInternational,
             .realEstateInvestmentTrusts, .goldPhysical, .goldETFs, .silverPhysical,
             .otherPreciousMetals, .commodityETFs, .commodityFutures, .artAndCollectibles,
             .intellectualProperty, .chitFunds, .traditionalInvestments:
            return .alternative
            
        case .lifeInsuranceTraditional, .lifeInsuranceULIP, .healthInsurance,
             .termInsurance, .generalInsurance, .annuityPlans:
            return .insurance
            
        case .cryptocurrency, .cryptoETFs, .digitalTokens, .digitalCurrencies:
            return .digital
            
        case .businessOwnership, .businessInvestment, .professionalPractice,
             .intellectualPropertyBusiness, .franchiseOwnership:
            return .business
            
        case .savingsAccount, .currentAccount, .cashInHand, .moneyMarketFunds,
             .liquidFunds, .foreignCashAccounts:
            return .cash
            
        case .personalVehicles, .commercialVehicles, .machinery, .equipment,
             .furniture, .electronics:
            return .tangible
            
        case .otherTangible, .otherIntangible, .unknown:
            return .other
        }
    }
    
    /// Whether this asset type is typically liquid (can be easily converted to cash)
    public var isLiquid: Bool {
        switch self {
        case .savingsAccount, .currentAccount, .cashInHand, .moneyMarketFunds,
             .liquidFunds, .foreignCashAccounts, .publicEquityDomestic,
             .publicEquityInternational, .equityMutualFunds, .equityETFs,
             .debtMutualFunds, .goldETFs, .commodityETFs, .cryptocurrency:
            return true
        default:
            return false
        }
    }
    
    /// Whether this asset type is subject to capital gains tax
    public var isSubjectToCapitalGains: Bool {
        switch self {
        case .publicEquityDomestic, .publicEquityInternational, .privateEquityDomestic,
             .privateEquityInternational, .startupInvestment, .employeeStockOptions,
             .equityMutualFunds, .equityETFs, .governmentBonds, .corporateBonds,
             .municipalBonds, .internationalBonds, .debtMutualFunds,
             .realEstateResidential, .realEstateCommercial, .realEstateInternational,
             .realEstateInvestmentTrusts, .goldPhysical, .goldETFs, .silverPhysical,
             .otherPreciousMetals, .commodityETFs, .commodityFutures,
             .artAndCollectibles, .cryptocurrency, .cryptoETFs:
            return true
        default:
            return false
        }
    }
    
    /// Whether this asset type is considered tax-advantaged in India
    public var isTaxAdvantaged: Bool {
        switch self {
        case .employeeProvidentFund, .publicProvidentFund, .voluntaryProvidentFund,
             .nationalPensionScheme, .postOfficeSchemes, .lifeInsuranceTraditional,
             .termInsurance, .healthInsurance:
            return true
        default:
            return false
        }
    }
    
    /// Whether this asset type requires regulatory compliance monitoring
    public var requiresComplianceMonitoring: Bool {
        switch self {
        case .publicEquityInternational, .privateEquityInternational,
             .internationalBonds, .realEstateInternational, .foreignCashAccounts,
             .cryptocurrency, .cryptoETFs, .digitalTokens, .businessInvestment:
            return true
        default:
            return false
        }
    }
    
    /// Icon name for UI display
    public var iconName: String {
        switch self.category {
        case .equity: return "chart.line.uptrend.xyaxis"
        case .fixedIncome: return "banknote"
        case .alternative: return "house"
        case .insurance: return "shield"
        case .digital: return "bitcoinsign.circle"
        case .business: return "building.2"
        case .cash: return "dollarsign.circle"
        case .tangible: return "car"
        case .other: return "questionmark.circle"
        }
    }
    
    /// Assets commonly held by Indian investors
    public static var commonIndianAssets: [AssetType] {
        return [
            .publicEquityDomestic, .equityMutualFunds, .equityETFs,
            .fixedDeposits, .recurringDeposits, .postOfficeSchemes,
            .employeeProvidentFund, .publicProvidentFund, .nationalPensionScheme,
            .realEstateResidential, .goldPhysical, .goldETFs,
            .lifeInsuranceTraditional, .lifeInsuranceULIP, .healthInsurance,
            .savingsAccount, .personalVehicles
        ]
    }
    
    /// Assets commonly held for international diversification
    public static var internationalDiversificationAssets: [AssetType] {
        return [
            .publicEquityInternational, .internationalBonds,
            .realEstateInternational, .foreignCashAccounts,
            .cryptocurrency, .commodityETFs
        ]
    }
    
    /// Tax-advantaged assets for optimization
    public static var taxAdvantagedAssets: [AssetType] {
        return allCases.filter { $0.isTaxAdvantaged }
    }
    
    /// Liquid assets for emergency fund calculation
    public static var liquidAssets: [AssetType] {
        return allCases.filter { $0.isLiquid }
    }
}

/// High-level asset category classification
public enum AssetCategory: String, CaseIterable, Codable, Hashable {
    case equity = "equity"
    case fixedIncome = "fixedIncome"
    case alternative = "alternative"
    case insurance = "insurance"
    case digital = "digital"
    case business = "business"
    case cash = "cash"
    case tangible = "tangible"
    case other = "other"
    
    /// Display name for the category
    public var displayName: String {
        switch self {
        case .equity: return "Equity"
        case .fixedIncome: return "Fixed Income"
        case .alternative: return "Alternative"
        case .insurance: return "Insurance"
        case .digital: return "Digital Assets"
        case .business: return "Business"
        case .cash: return "Cash & Equivalents"
        case .tangible: return "Tangible Assets"
        case .other: return "Other"
        }
    }
    
    /// Color for UI representation
    public var color: String {
        switch self {
        case .equity: return "blue"
        case .fixedIncome: return "green"
        case .alternative: return "orange"
        case .insurance: return "purple"
        case .digital: return "yellow"
        case .business: return "indigo"
        case .cash: return "gray"
        case .tangible: return "brown"
        case .other: return "secondary"
        }
    }
    
    /// Whether this category is considered growth-oriented
    public var isGrowthOriented: Bool {
        switch self {
        case .equity, .alternative, .digital, .business:
            return true
        case .fixedIncome, .insurance, .cash, .tangible, .other:
            return false
        }
    }
    
    /// Whether this category provides regular income
    public var providesRegularIncome: Bool {
        switch self {
        case .fixedIncome, .insurance, .business:
            return true
        case .equity, .alternative, .digital, .cash, .tangible, .other:
            return false
        }
    }
}

// MARK: - Comparable
extension AssetType: Comparable {
    public static func < (lhs: AssetType, rhs: AssetType) -> Bool {
        lhs.displayName < rhs.displayName
    }
}

// MARK: - CustomStringConvertible
extension AssetType: CustomStringConvertible {
    public var description: String {
        displayName
    }
}

extension AssetCategory: Comparable {
    public static func < (lhs: AssetCategory, rhs: AssetCategory) -> Bool {
        lhs.displayName < rhs.displayName
    }
}