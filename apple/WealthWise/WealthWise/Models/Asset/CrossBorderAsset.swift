import Foundation

/// Comprehensive cross-border asset model supporting international portfolios
/// Handles multi-currency assets, regulatory compliance, and tax implications
public struct CrossBorderAsset: Codable, Hashable, Identifiable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public var name: String
    public var assetType: AssetType
    public var category: AssetCategory
    
    // MARK: - Geographic & Regulatory
    
    /// Country where the asset is domiciled/registered
    public var domicileCountryCode: String
    
    /// Country of the beneficial owner/investor
    public var ownerCountryCode: String
    
    /// Whether this is a cross-border asset (different domicile and owner countries)
    public var isCrossBorder: Bool {
        return domicileCountryCode != ownerCountryCode
    }
    
    /// Jurisdictions where this asset has tax implications
    public var taxJurisdictions: Set<String>
    
    /// Regulatory compliance requirements
    public var complianceRequirements: Set<ComplianceRequirement>
    
    // MARK: - Financial Information
    
    /// Current market value in asset's native currency
    public var currentValue: Decimal
    
    /// Currency of the asset's native valuation
    public var nativeCurrencyCode: String
    
    /// Original purchase/investment amount in native currency
    public var originalInvestment: Decimal?
    
    /// Date of acquisition/purchase
    public var acquisitionDate: Date?
    
    /// Quantity/units held (for securities, shares, etc.)
    public var quantity: Decimal?
    
    /// Current price per unit in native currency
    public var pricePerUnit: Decimal?
    
    // MARK: - Identification & Documentation
    
    /// Unique identifier within the institution (account number, ISIN, etc.)
    public var institutionIdentifier: String?
    
    /// Institution or broker where asset is held
    public var custodianInstitution: String?
    
    /// International securities identification (ISIN, CUSIP, etc.)
    public var securityIdentifier: String?
    
    /// Exchange where traded (if applicable)
    public var exchange: String?
    
    /// Sector classification
    public var sector: String?
    
    /// Industry classification
    public var industry: String?
    
    // MARK: - Income & Returns
    
    /// Expected annual income (dividends, interest, rent)
    public var expectedAnnualIncome: Decimal?
    
    /// Income frequency
    public var incomeFrequency: IncomeFrequency?
    
    /// Last income payment received
    public var lastIncomePayment: IncomePayment?
    
    /// Historical performance data
    public var performanceHistory: [PerformanceSnapshot]
    
    // MARK: - Risk & Analytics
    
    /// Asset-specific risk rating
    public var riskRating: RiskRating?
    
    /// Liquidity classification
    public var liquidityRating: LiquidityRating
    
    /// Environmental, Social, Governance (ESG) score
    public var esgScore: ESGScore?
    
    /// Correlation with other assets (for portfolio optimization)
    public var correlationData: [String: Decimal]
    
    // MARK: - Metadata
    
    /// User-defined tags for categorization
    public var tags: Set<String>
    
    /// User notes and comments
    public var notes: String?
    
    /// Asset creation date in the system
    public let createdAt: Date
    
    /// Last modification date
    public var updatedAt: Date
    
    /// Whether asset is actively held or historical
    public var isActive: Bool
    
    /// Whether asset is included in portfolio calculations
    public var isIncludedInPortfolio: Bool
    
    /// Data source for market prices
    public var dataSource: DataSource?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        assetType: AssetType,
        domicileCountryCode: String,
        ownerCountryCode: String,
        currentValue: Decimal,
        nativeCurrencyCode: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.assetType = assetType
        self.category = assetType.category
        self.domicileCountryCode = domicileCountryCode
        self.ownerCountryCode = ownerCountryCode
        self.currentValue = currentValue
        self.nativeCurrencyCode = nativeCurrencyCode
        self.createdAt = createdAt
        
        // Initialize collections and optional properties
        self.taxJurisdictions = Set([domicileCountryCode, ownerCountryCode])
        self.complianceRequirements = Set()
        self.performanceHistory = []
        self.correlationData = [:]
        self.tags = Set()
        self.updatedAt = createdAt
        self.isActive = true
        self.isIncludedInPortfolio = true
        self.liquidityRating = assetType.isLiquid ? .high : .low
        
        // Set compliance requirements for cross-border assets
        if isCrossBorder {
            self.complianceRequirements.insert(ComplianceRequirement.foreignAssetReporting)
            if assetType.requiresComplianceMonitoring {
                self.complianceRequirements.insert(ComplianceRequirement.enhancedDueDiligence)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Unrealized gain/loss in native currency
    public var unrealizedGainLoss: Decimal? {
        guard let original = originalInvestment else { return nil }
        return currentValue - original
    }
    
    /// Unrealized gain/loss percentage
    public var unrealizedGainLossPercentage: Double? {
        guard let original = originalInvestment, original > 0 else { return nil }
        let gainLoss = currentValue - original
        return Double(truncating: gainLoss / original * 100 as NSDecimalNumber)
    }
    
    /// Current yield (annual income / current value)
    public var currentYield: Double? {
        guard let income = expectedAnnualIncome, currentValue > 0 else { return nil }
        return Double(truncating: income / currentValue * 100 as NSDecimalNumber)
    }
    
    /// Whether this asset requires foreign exchange impact analysis
    public var requiresFXAnalysis: Bool {
        return isCrossBorder || nativeCurrencyCode != ownerCountryCode
    }
    
    /// Whether this asset has tax implications in multiple jurisdictions
    public var hasMultiJurisdictionTax: Bool {
        return taxJurisdictions.count > 1
    }
    
    /// Age of the investment in years
    public var investmentAgeYears: Double? {
        guard let acquisition = acquisitionDate else { return nil }
        return Date().timeIntervalSince(acquisition) / (365.25 * 24 * 60 * 60)
    }
    
    /// Whether this qualifies for long-term capital gains treatment (India: >1 year for equity, >3 years for debt/others)
    public var qualifiesForLongTermCapitalGains: Bool {
        guard let age = investmentAgeYears else { return false }
        
        switch category {
        case .equity:
            return age > 1.0  // 1 year for equity in India
        case .fixedIncome, .alternative:
            return age > 3.0  // 3 years for debt/others in India
        default:
            return age > 3.0  // Default to 3 years
        }
    }
    
    /// Whether this asset is considered liquid (can be easily converted to cash)
    public var isLiquid: Bool {
        return liquidityRating == .high || liquidityRating == .medium
    }
}

// MARK: - Supporting Types

/// Income frequency enumeration
public enum IncomeFrequency: String, CaseIterable, Codable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case semiAnnual = "semiAnnual"
    case annual = "annual"
    case irregular = "irregular"
    case none = "none"
    
    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiAnnual: return "Semi-Annual"
        case .annual: return "Annual"
        case .irregular: return "Irregular"
        case .none: return "No Income"
        }
    }
    
    /// Number of payments per year
    public var paymentsPerYear: Decimal {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .semiAnnual: return 2
        case .annual: return 1
        case .irregular: return 1
        case .none: return 0
        }
    }
}

/// Income payment record
public struct IncomePayment: Codable, Hashable {
    public let amount: Decimal
    public let currency: String
    public let paymentDate: Date
    public let type: IncomeType
    
    public init(amount: Decimal, currency: String, paymentDate: Date, type: IncomeType) {
        self.amount = amount
        self.currency = currency
        self.paymentDate = paymentDate
        self.type = type
    }
}

/// Type of income payment
public enum IncomeType: String, CaseIterable, Codable {
    case dividend = "dividend"
    case interest = "interest"
    case rent = "rent"
    case coupon = "coupon"
    case distribution = "distribution"
    case royalty = "royalty"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .dividend: return "Dividend"
        case .interest: return "Interest"
        case .rent: return "Rent"
        case .coupon: return "Coupon"
        case .distribution: return "Distribution"
        case .royalty: return "Royalty"
        case .other: return "Other Income"
        }
    }
}

/// Performance snapshot for historical tracking
public struct PerformanceSnapshot: Codable, Hashable {
    public let date: Date
    public let value: Decimal
    public let currency: String
    public let source: String?
    
    public init(date: Date, value: Decimal, currency: String, source: String? = nil) {
        self.date = date
        self.value = value
        self.currency = currency
        self.source = source
    }
}

/// Risk rating classification
public enum RiskRating: String, CaseIterable, Codable {
    case veryLow = "veryLow"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "veryHigh"
    
    public var displayName: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
    
    public var numericValue: Int {
        switch self {
        case .veryLow: return 1
        case .low: return 2
        case .medium: return 3
        case .high: return 4
        case .veryHigh: return 5
        }
    }
}

/// Liquidity rating classification
public enum LiquidityRating: String, CaseIterable, Codable {
    case high = "high"          // Can be sold within 1-2 days
    case medium = "medium"      // Can be sold within 1-4 weeks
    case low = "low"           // May take months to sell
    case veryLow = "veryLow"   // May take years or difficult to sell
    
    public var displayName: String {
        switch self {
        case .high: return "High Liquidity"
        case .medium: return "Medium Liquidity"
        case .low: return "Low Liquidity"
        case .veryLow: return "Very Low Liquidity"
        }
    }
    
    public var timeToSell: String {
        switch self {
        case .high: return "1-2 days"
        case .medium: return "1-4 weeks"
        case .low: return "1-6 months"
        case .veryLow: return "6+ months"
        }
    }
}

/// ESG (Environmental, Social, Governance) score
public struct ESGScore: Codable, Hashable {
    public let environmentalScore: Int    // 0-100
    public let socialScore: Int          // 0-100
    public let governanceScore: Int      // 0-100
    public let overallScore: Int         // 0-100
    public let ratingProvider: String
    public let lastUpdated: Date
    
    public init(environmental: Int, social: Int, governance: Int, provider: String, lastUpdated: Date = Date()) {
        self.environmentalScore = max(0, min(100, environmental))
        self.socialScore = max(0, min(100, social))
        self.governanceScore = max(0, min(100, governance))
        self.overallScore = (environmental + social + governance) / 3
        self.ratingProvider = provider
        self.lastUpdated = lastUpdated
    }
}

/// Compliance requirements for cross-border assets
public enum ComplianceRequirement: String, CaseIterable, Codable {
    case foreignAssetReporting = "foreignAssetReporting"           // Required for international assets
    case enhancedDueDiligence = "enhancedDueDiligence"            // Required for high-risk jurisdictions
    case fatcaReporting = "fatcaReporting"                         // US tax compliance
    case crsReporting = "crsReporting"                             // Common Reporting Standard
    case liberalisedRemittanceScheme = "liberalisedRemittanceScheme" // India's LRS compliance
    case kycDocumentation = "kycDocumentation"                     // Know Your Customer
    case sourceOfFunds = "sourceOfFunds"                           // Source of funds documentation
    case taxResidencyCertificate = "taxResidencyCertificate"      // Tax residency proof
    case regularValuation = "regularValuation"                    // Periodic valuation requirements
    case auditTrail = "auditTrail"                                // Audit trail maintenance
    
    public var displayName: String {
        switch self {
        case .foreignAssetReporting: return "Foreign Asset Reporting"
        case .enhancedDueDiligence: return "Enhanced Due Diligence"
        case .fatcaReporting: return "FATCA Reporting"
        case .crsReporting: return "CRS Reporting"
        case .liberalisedRemittanceScheme: return "LRS Compliance"
        case .kycDocumentation: return "KYC Documentation"
        case .sourceOfFunds: return "Source of Funds"
        case .taxResidencyCertificate: return "Tax Residency Certificate"
        case .regularValuation: return "Regular Valuation"
        case .auditTrail: return "Audit Trail"
        }
    }
    
    public var description: String {
        switch self {
        case .foreignAssetReporting:
            return "Report foreign assets to tax authorities"
        case .enhancedDueDiligence:
            return "Additional verification for high-risk investments"
        case .fatcaReporting:
            return "US Foreign Account Tax Compliance Act reporting"
        case .crsReporting:
            return "OECD Common Reporting Standard compliance"
        case .liberalisedRemittanceScheme:
            return "India's annual $250,000 overseas investment limit"
        case .kycDocumentation:
            return "Maintain know-your-customer documentation"
        case .sourceOfFunds:
            return "Document legitimate source of investment funds"
        case .taxResidencyCertificate:
            return "Maintain valid tax residency certificates"
        case .regularValuation:
            return "Periodic professional valuation required"
        case .auditTrail:
            return "Maintain complete transaction audit trail"
        }
    }
}

/// Data source for market pricing
public enum DataSource: String, CaseIterable, Codable {
    case manual = "manual"                    // User-entered values
    case exchangeOfficial = "exchangeOfficial" // Official exchange data
    case brokerStatement = "brokerStatement"   // From brokerage statements
    case marketDataProvider = "marketDataProvider" // Third-party data providers
    case bankStatement = "bankStatement"       // From bank statements
    case professionalValuation = "professionalValuation" // Professional appraisal
    case estimated = "estimated"              // Estimated/calculated values
    
    public var displayName: String {
        switch self {
        case .manual: return "Manual Entry"
        case .exchangeOfficial: return "Official Exchange"
        case .brokerStatement: return "Broker Statement"
        case .marketDataProvider: return "Market Data Provider"
        case .bankStatement: return "Bank Statement"
        case .professionalValuation: return "Professional Valuation"
        case .estimated: return "Estimated"
        }
    }
    
    public var reliability: Int {
        switch self {
        case .exchangeOfficial: return 5
        case .professionalValuation: return 5
        case .brokerStatement: return 4
        case .bankStatement: return 4
        case .marketDataProvider: return 3
        case .manual: return 2
        case .estimated: return 1
        }
    }
}

// MARK: - Extensions

extension CrossBorderAsset {
    
    /// Create a domestic asset (same domicile and owner country)
    public static func createDomesticAsset(
        name: String,
        assetType: AssetType,
        countryCode: String,
        currentValue: Decimal,
        currencyCode: String
    ) -> CrossBorderAsset {
        return CrossBorderAsset(
            name: name,
            assetType: assetType,
            domicileCountryCode: countryCode,
            ownerCountryCode: countryCode,
            currentValue: currentValue,
            nativeCurrencyCode: currencyCode
        )
    }
    
    /// Create an international asset
    public static func createInternationalAsset(
        name: String,
        assetType: AssetType,
        domicileCountryCode: String,
        ownerCountryCode: String,
        currentValue: Decimal,
        nativeCurrencyCode: String
    ) -> CrossBorderAsset {
        var asset = CrossBorderAsset(
            name: name,
            assetType: assetType,
            domicileCountryCode: domicileCountryCode,
            ownerCountryCode: ownerCountryCode,
            currentValue: currentValue,
            nativeCurrencyCode: nativeCurrencyCode
        )
        
        // Add additional compliance requirements for international assets
        asset.complianceRequirements.insert(ComplianceRequirement.foreignAssetReporting)
        asset.complianceRequirements.insert(ComplianceRequirement.kycDocumentation)
        asset.complianceRequirements.insert(ComplianceRequirement.sourceOfFunds)
        
        if domicileCountryCode == "USA" {
            asset.complianceRequirements.insert(ComplianceRequirement.fatcaReporting)
        }
        
        return asset
    }
    
    /// Update the current value and record performance snapshot
    public mutating func updateValue(_ newValue: Decimal, date: Date = Date(), source: DataSource = .manual) {
        let snapshot = PerformanceSnapshot(
            date: date,
            value: newValue,
            currency: nativeCurrencyCode,
            source: source.rawValue
        )
        
        performanceHistory.append(snapshot)
        currentValue = newValue
        updatedAt = date
        dataSource = source
        
        // Keep only last 100 performance snapshots to manage memory
        if performanceHistory.count > 100 {
            performanceHistory.removeFirst()
        }
    }
    
    /// Add or update income payment
    public mutating func recordIncomePayment(_ payment: IncomePayment) {
        lastIncomePayment = payment
        updatedAt = Date()
    }
    
    /// Add tags
    public mutating func addTags(_ newTags: Set<String>) {
        tags.formUnion(newTags)
        updatedAt = Date()
    }
    
    /// Remove tags
    public mutating func removeTags(_ tagsToRemove: Set<String>) {
        tags.subtract(tagsToRemove)
        updatedAt = Date()
    }
}

// MARK: - Hashable & Equatable
extension CrossBorderAsset {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: CrossBorderAsset, rhs: CrossBorderAsset) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Comparable
extension CrossBorderAsset: Comparable {
    public static func < (lhs: CrossBorderAsset, rhs: CrossBorderAsset) -> Bool {
        lhs.name < rhs.name
    }
}