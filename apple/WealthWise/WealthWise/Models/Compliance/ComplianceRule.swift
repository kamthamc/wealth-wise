//
//  ComplianceRule.swift
//  WealthWise
//
//  Comprehensive compliance rule model for multi-country regulatory requirements
//

import Foundation

/// Compliance rule defining regulatory requirements and thresholds
public struct ComplianceRule: Codable, Hashable, Identifiable, Sendable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public var ruleCode: String
    public var ruleType: RuleType
    public var countryCode: String
    public var title: String
    public var description: String
    
    // MARK: - Threshold Configuration
    
    /// Threshold value for triggering compliance requirement
    public var thresholdAmount: Decimal?
    
    /// Currency for threshold amount
    public var thresholdCurrency: String?
    
    /// Threshold type (annual, transaction, total balance, etc.)
    public var thresholdType: ThresholdType
    
    // MARK: - Timing & Deadlines
    
    /// When this rule becomes effective
    public var effectiveDate: Date
    
    /// When this rule expires (if applicable)
    public var expiryDate: Date?
    
    /// Deadline type (annual, quarterly, transaction-based, etc.)
    public var deadlineType: DeadlineType
    
    /// Days before deadline to trigger alert
    public var alertDaysBefore: Int
    
    // MARK: - Applicable Contexts
    
    /// Asset types this rule applies to
    public var applicableAssetTypes: Set<String>
    
    /// Residency types this rule applies to
    public var applicableResidencyTypes: Set<String>
    
    /// Transaction types this rule applies to
    public var applicableTransactionTypes: Set<String>
    
    // MARK: - Severity & Priority
    
    /// Severity level of non-compliance
    public var severityLevel: SeverityLevel
    
    /// Whether this is a mandatory compliance requirement
    public var isMandatory: Bool
    
    /// Whether failure to comply can result in penalties
    public var hasPenalties: Bool
    
    /// Estimated penalty range description
    public var penaltyDescription: String?
    
    // MARK: - Documentation
    
    /// Official regulation reference
    public var regulationReference: String?
    
    /// Regulatory authority
    public var regulatoryAuthority: String?
    
    /// Required documentation
    public var requiredDocuments: [String]
    
    /// Additional notes and guidance
    public var notes: String?
    
    // MARK: - Metadata
    
    public let createdAt: Date
    public var updatedAt: Date
    public var isActive: Bool
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        ruleCode: String,
        ruleType: RuleType,
        countryCode: String,
        title: String,
        description: String,
        thresholdType: ThresholdType,
        effectiveDate: Date,
        deadlineType: DeadlineType,
        alertDaysBefore: Int,
        severityLevel: SeverityLevel,
        isMandatory: Bool,
        hasPenalties: Bool,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ruleCode = ruleCode
        self.ruleType = ruleType
        self.countryCode = countryCode
        self.title = title
        self.description = description
        self.thresholdType = thresholdType
        self.effectiveDate = effectiveDate
        self.deadlineType = deadlineType
        self.alertDaysBefore = alertDaysBefore
        self.severityLevel = severityLevel
        self.isMandatory = isMandatory
        self.hasPenalties = hasPenalties
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isActive = true
        self.applicableAssetTypes = Set()
        self.applicableResidencyTypes = Set()
        self.applicableTransactionTypes = Set()
        self.requiredDocuments = []
    }
    
    // MARK: - Computed Properties
    
    /// Whether this rule is currently effective
    public var isEffective: Bool {
        let now = Date()
        if let expiry = expiryDate {
            return now >= effectiveDate && now <= expiry
        }
        return now >= effectiveDate
    }
    
    /// Days until rule expires (if applicable)
    public var daysUntilExpiry: Int? {
        guard let expiry = expiryDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: expiry).day
    }
    
    /// Whether this rule applies to a specific asset type
    public func appliesTo(assetType: String) -> Bool {
        return applicableAssetTypes.isEmpty || applicableAssetTypes.contains(assetType)
    }
    
    /// Whether this rule applies to a specific residency type
    public func appliesTo(residencyType: String) -> Bool {
        return applicableResidencyTypes.isEmpty || applicableResidencyTypes.contains(residencyType)
    }
}

// MARK: - Supporting Enums

/// Type of compliance rule
public enum RuleType: String, CaseIterable, Codable, Sendable {
    case reporting = "reporting"
    case disclosure = "disclosure"
    case withholding = "withholding"
    case documentation = "documentation"
    case threshold = "threshold"
    case deadline = "deadline"
    case prohibition = "prohibition"
    case registration = "registration"
    
    public var displayName: String {
        switch self {
        case .reporting: return NSLocalizedString("reporting_rule", comment: "Reporting rule type")
        case .disclosure: return NSLocalizedString("disclosure_rule", comment: "Disclosure rule type")
        case .withholding: return NSLocalizedString("withholding_rule", comment: "Withholding rule type")
        case .documentation: return NSLocalizedString("documentation_rule", comment: "Documentation rule type")
        case .threshold: return NSLocalizedString("threshold_rule", comment: "Threshold rule type")
        case .deadline: return NSLocalizedString("deadline_rule", comment: "Deadline rule type")
        case .prohibition: return NSLocalizedString("prohibition_rule", comment: "Prohibition rule type")
        case .registration: return NSLocalizedString("registration_rule", comment: "Registration rule type")
        }
    }
}

/// Type of threshold measurement
public enum ThresholdType: String, CaseIterable, Codable, Sendable {
    case annualAggregate = "annualAggregate"
    case transactionBased = "transactionBased"
    case totalBalance = "totalBalance"
    case monthlyAggregate = "monthlyAggregate"
    case quarterlyAggregate = "quarterlyAggregate"
    case perAsset = "perAsset"
    case none = "none"
    
    public var displayName: String {
        switch self {
        case .annualAggregate: return NSLocalizedString("annual_aggregate", comment: "Annual aggregate threshold")
        case .transactionBased: return NSLocalizedString("transaction_based", comment: "Transaction-based threshold")
        case .totalBalance: return NSLocalizedString("total_balance", comment: "Total balance threshold")
        case .monthlyAggregate: return NSLocalizedString("monthly_aggregate", comment: "Monthly aggregate threshold")
        case .quarterlyAggregate: return NSLocalizedString("quarterly_aggregate", comment: "Quarterly aggregate threshold")
        case .perAsset: return NSLocalizedString("per_asset", comment: "Per asset threshold")
        case .none: return NSLocalizedString("no_threshold", comment: "No threshold")
        }
    }
}

/// Type of compliance deadline
public enum DeadlineType: String, CaseIterable, Codable, Sendable {
    case annual = "annual"
    case quarterly = "quarterly"
    case monthly = "monthly"
    case transactionBased = "transactionBased"
    case eventBased = "eventBased"
    case continuous = "continuous"
    case none = "none"
    
    public var displayName: String {
        switch self {
        case .annual: return NSLocalizedString("annual_deadline", comment: "Annual deadline")
        case .quarterly: return NSLocalizedString("quarterly_deadline", comment: "Quarterly deadline")
        case .monthly: return NSLocalizedString("monthly_deadline", comment: "Monthly deadline")
        case .transactionBased: return NSLocalizedString("transaction_deadline", comment: "Transaction-based deadline")
        case .eventBased: return NSLocalizedString("event_deadline", comment: "Event-based deadline")
        case .continuous: return NSLocalizedString("continuous_compliance", comment: "Continuous compliance")
        case .none: return NSLocalizedString("no_deadline", comment: "No deadline")
        }
    }
}

/// Severity level of compliance violation
public enum SeverityLevel: String, CaseIterable, Codable, Sendable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case informational = "informational"
    
    public var displayName: String {
        switch self {
        case .critical: return NSLocalizedString("critical_severity", comment: "Critical severity")
        case .high: return NSLocalizedString("high_severity", comment: "High severity")
        case .medium: return NSLocalizedString("medium_severity", comment: "Medium severity")
        case .low: return NSLocalizedString("low_severity", comment: "Low severity")
        case .informational: return NSLocalizedString("informational_severity", comment: "Informational severity")
        }
    }
    
    public var numericValue: Int {
        switch self {
        case .critical: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .informational: return 1
        }
    }
}

// MARK: - Extensions

extension ComplianceRule {
    
    /// Check if threshold is exceeded for given amount
    public func isThresholdExceeded(for amount: Decimal) -> Bool {
        guard let threshold = thresholdAmount else { return false }
        return amount >= threshold
    }
    
    /// Add applicable asset types
    public mutating func addApplicableAssetTypes(_ types: Set<String>) {
        applicableAssetTypes.formUnion(types)
        updatedAt = Date()
    }
    
    /// Add applicable residency types
    public mutating func addApplicableResidencyTypes(_ types: Set<String>) {
        applicableResidencyTypes.formUnion(types)
        updatedAt = Date()
    }
    
    /// Add required documents
    public mutating func addRequiredDocuments(_ documents: [String]) {
        requiredDocuments.append(contentsOf: documents)
        updatedAt = Date()
    }
}

// MARK: - Hashable & Equatable

extension ComplianceRule {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ComplianceRule, rhs: ComplianceRule) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Comparable

extension ComplianceRule: Comparable {
    public static func < (lhs: ComplianceRule, rhs: ComplianceRule) -> Bool {
        if lhs.severityLevel.numericValue != rhs.severityLevel.numericValue {
            return lhs.severityLevel.numericValue > rhs.severityLevel.numericValue
        }
        return lhs.title < rhs.title
    }
}
