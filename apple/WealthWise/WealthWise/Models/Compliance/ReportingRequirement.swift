//
//  ReportingRequirement.swift
//  WealthWise
//
//  Model for tracking regulatory reporting requirements and thresholds
//

import Foundation

/// Regulatory reporting requirement with threshold tracking
public struct ReportingRequirement: Codable, Hashable, Identifiable, Sendable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public var requirementCode: String
    public var countryCode: String
    public var formName: String
    public var title: String
    public var description: String
    
    // MARK: - Threshold Configuration
    
    /// Reporting threshold amount
    public var thresholdAmount: Decimal
    
    /// Currency for threshold
    public var thresholdCurrency: String
    
    /// Type of threshold calculation
    public var calculationType: CalculationType
    
    /// Period for threshold calculation
    public var calculationPeriod: CalculationPeriod
    
    // MARK: - Timing
    
    /// Filing deadline (annual, quarterly, etc.)
    public var filingDeadline: FilingDeadline
    
    /// Specific deadline date (if fixed)
    public var deadlineDate: Date?
    
    /// Days before deadline to trigger alert
    public var alertDaysBefore: Int
    
    // MARK: - Applicability
    
    /// Asset types this requirement applies to
    public var applicableAssetTypes: Set<String>
    
    /// Transaction types that trigger reporting
    public var applicableTransactionTypes: Set<String>
    
    /// Residency types this applies to
    public var applicableResidencyTypes: Set<String>
    
    // MARK: - Documentation
    
    /// Regulatory authority
    public var regulatoryAuthority: String
    
    /// Official form URL
    public var formURL: String?
    
    /// Instructions URL
    public var instructionsURL: String?
    
    /// Required supporting documents
    public var requiredDocuments: [String]
    
    /// Penalties for non-compliance
    public var penaltyDescription: String?
    
    // MARK: - Status Tracking
    
    /// Whether this requirement is currently active
    public var isActive: Bool
    
    /// Effective date
    public var effectiveDate: Date
    
    /// Expiry date (if applicable)
    public var expiryDate: Date?
    
    // MARK: - Metadata
    
    public let createdAt: Date
    public var updatedAt: Date
    public var notes: String?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        requirementCode: String,
        countryCode: String,
        formName: String,
        title: String,
        description: String,
        thresholdAmount: Decimal,
        thresholdCurrency: String,
        calculationType: CalculationType,
        calculationPeriod: CalculationPeriod,
        filingDeadline: FilingDeadline,
        alertDaysBefore: Int,
        regulatoryAuthority: String,
        effectiveDate: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.requirementCode = requirementCode
        self.countryCode = countryCode
        self.formName = formName
        self.title = title
        self.description = description
        self.thresholdAmount = thresholdAmount
        self.thresholdCurrency = thresholdCurrency
        self.calculationType = calculationType
        self.calculationPeriod = calculationPeriod
        self.filingDeadline = filingDeadline
        self.alertDaysBefore = alertDaysBefore
        self.regulatoryAuthority = regulatoryAuthority
        self.effectiveDate = effectiveDate
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isActive = true
        self.applicableAssetTypes = Set()
        self.applicableTransactionTypes = Set()
        self.applicableResidencyTypes = Set()
        self.requiredDocuments = []
    }
    
    // MARK: - Computed Properties
    
    /// Whether threshold is exceeded for given amount
    public func isThresholdExceeded(for amount: Decimal) -> Bool {
        return amount >= thresholdAmount
    }
    
    /// Whether this requirement is currently effective
    public var isEffective: Bool {
        let now = Date()
        if let expiry = expiryDate {
            return now >= effectiveDate && now <= expiry && isActive
        }
        return now >= effectiveDate && isActive
    }
}

// MARK: - Supporting Enums

/// Type of threshold calculation
public enum CalculationType: String, CaseIterable, Codable, Sendable {
    case aggregateValue = "aggregateValue"           // Total value of all applicable assets
    case individualValue = "individualValue"         // Each asset individually
    case transactionValue = "transactionValue"       // Per transaction amount
    case cumulativeTransactions = "cumulativeTransactions" // Sum of transactions in period
    case balanceAtPeriodEnd = "balanceAtPeriodEnd"  // Balance on specific date
    case averageBalance = "averageBalance"           // Average balance over period
    case maximumBalance = "maximumBalance"           // Maximum balance in period
    
    public var displayName: String {
        switch self {
        case .aggregateValue: return NSLocalizedString("aggregate_value", comment: "Aggregate value calculation")
        case .individualValue: return NSLocalizedString("individual_value", comment: "Individual value calculation")
        case .transactionValue: return NSLocalizedString("transaction_value", comment: "Transaction value calculation")
        case .cumulativeTransactions: return NSLocalizedString("cumulative_transactions", comment: "Cumulative transactions calculation")
        case .balanceAtPeriodEnd: return NSLocalizedString("balance_period_end", comment: "Balance at period end calculation")
        case .averageBalance: return NSLocalizedString("average_balance", comment: "Average balance calculation")
        case .maximumBalance: return NSLocalizedString("maximum_balance", comment: "Maximum balance calculation")
        }
    }
}

/// Period for threshold calculation
public enum CalculationPeriod: String, CaseIterable, Codable, Sendable {
    case annual = "annual"           // Calendar or fiscal year
    case quarterly = "quarterly"     // 3-month period
    case monthly = "monthly"         // 1-month period
    case daily = "daily"            // Single day
    case transactionBased = "transactionBased" // Per transaction
    case continuous = "continuous"   // Continuous monitoring
    
    public var displayName: String {
        switch self {
        case .annual: return NSLocalizedString("annual_period", comment: "Annual period")
        case .quarterly: return NSLocalizedString("quarterly_period", comment: "Quarterly period")
        case .monthly: return NSLocalizedString("monthly_period", comment: "Monthly period")
        case .daily: return NSLocalizedString("daily_period", comment: "Daily period")
        case .transactionBased: return NSLocalizedString("transaction_based_period", comment: "Transaction-based period")
        case .continuous: return NSLocalizedString("continuous_period", comment: "Continuous period")
        }
    }
}

/// Filing deadline specification
public enum FilingDeadline: String, CaseIterable, Codable, Sendable {
    case annualTaxDay = "annualTaxDay"         // Tax filing deadline (varies by country)
    case fiscalYearEnd = "fiscalYearEnd"       // End of fiscal year
    case calendarYearEnd = "calendarYearEnd"   // December 31
    case quarterEnd = "quarterEnd"             // End of quarter
    case monthEnd = "monthEnd"                 // End of month
    case specificDate = "specificDate"         // Specific date set in deadlineDate
    case transactionDate = "transactionDate"   // Relative to transaction date
    case eventBased = "eventBased"             // Based on specific event
    
    public var displayName: String {
        switch self {
        case .annualTaxDay: return NSLocalizedString("annual_tax_day", comment: "Annual tax day deadline")
        case .fiscalYearEnd: return NSLocalizedString("fiscal_year_end", comment: "Fiscal year end deadline")
        case .calendarYearEnd: return NSLocalizedString("calendar_year_end", comment: "Calendar year end deadline")
        case .quarterEnd: return NSLocalizedString("quarter_end", comment: "Quarter end deadline")
        case .monthEnd: return NSLocalizedString("month_end", comment: "Month end deadline")
        case .specificDate: return NSLocalizedString("specific_date", comment: "Specific date deadline")
        case .transactionDate: return NSLocalizedString("transaction_date", comment: "Transaction date deadline")
        case .eventBased: return NSLocalizedString("event_based", comment: "Event-based deadline")
        }
    }
}

// MARK: - Extensions

extension ReportingRequirement {
    
    /// Add applicable asset types
    public mutating func addApplicableAssetTypes(_ types: Set<String>) {
        applicableAssetTypes.formUnion(types)
        updatedAt = Date()
    }
    
    /// Add applicable transaction types
    public mutating func addApplicableTransactionTypes(_ types: Set<String>) {
        applicableTransactionTypes.formUnion(types)
        updatedAt = Date()
    }
    
    /// Add applicable residency types
    public mutating func addApplicableResidencyTypes(_ types: Set<String>) {
        applicableResidencyTypes.formUnion(types)
        updatedAt = Date()
    }
    
    /// Check if requirement applies to asset type
    public func appliesTo(assetType: String) -> Bool {
        return applicableAssetTypes.isEmpty || applicableAssetTypes.contains(assetType)
    }
    
    /// Check if requirement applies to transaction type
    public func appliesTo(transactionType: String) -> Bool {
        return applicableTransactionTypes.isEmpty || applicableTransactionTypes.contains(transactionType)
    }
    
    /// Check if requirement applies to residency type
    public func appliesTo(residencyType: String) -> Bool {
        return applicableResidencyTypes.isEmpty || applicableResidencyTypes.contains(residencyType)
    }
}

// MARK: - Hashable & Equatable

extension ReportingRequirement {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ReportingRequirement, rhs: ReportingRequirement) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Comparable

extension ReportingRequirement: Comparable {
    public static func < (lhs: ReportingRequirement, rhs: ReportingRequirement) -> Bool {
        return lhs.title < rhs.title
    }
}
