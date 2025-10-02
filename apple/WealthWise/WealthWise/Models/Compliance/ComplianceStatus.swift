//
//  ComplianceStatus.swift
//  WealthWise
//
//  Model for tracking overall compliance status and dashboard data
//

import Foundation

/// Overall compliance status for assets and portfolios
public struct ComplianceStatus: Codable, Hashable, Identifiable, Sendable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    
    /// Entity this status applies to (user, portfolio, asset)
    public var entityId: UUID
    public var entityType: EntityType
    
    /// Overall compliance health score (0-100)
    public var complianceScore: Int
    
    /// Overall status
    public var overallStatus: Status
    
    // MARK: - Alert Counts
    
    /// Number of critical alerts
    public var criticalAlertsCount: Int
    
    /// Number of high priority alerts
    public var highAlertsCount: Int
    
    /// Number of medium priority alerts
    public var mediumAlertsCount: Int
    
    /// Number of low priority alerts
    public var lowAlertsCount: Int
    
    /// Number of informational alerts
    public var informationalAlertsCount: Int
    
    /// Total active alerts
    public var totalActiveAlerts: Int {
        return criticalAlertsCount + highAlertsCount + mediumAlertsCount + lowAlertsCount + informationalAlertsCount
    }
    
    // MARK: - Requirement Tracking
    
    /// Total compliance requirements applicable
    public var totalRequirements: Int
    
    /// Number of requirements in compliance
    public var compliantRequirements: Int
    
    /// Number of requirements with pending actions
    public var pendingRequirements: Int
    
    /// Number of overdue requirements
    public var overdueRequirements: Int
    
    /// Number of upcoming deadlines (within 30 days)
    public var upcomingDeadlines: Int
    
    // MARK: - Document Status
    
    /// Total documents tracked
    public var totalDocuments: Int
    
    /// Documents expiring within 90 days
    public var expiringDocuments: Int
    
    /// Expired documents
    public var expiredDocuments: Int
    
    /// Documents pending verification
    public var pendingVerificationDocuments: Int
    
    // MARK: - Reporting Status
    
    /// Reporting requirements due
    public var reportingDue: [ReportingStatus]
    
    /// Last reporting completed
    public var lastReportingDate: Date?
    
    /// Next reporting deadline
    public var nextReportingDeadline: Date?
    
    // MARK: - Risk Assessment
    
    /// Risk level based on compliance status
    public var riskLevel: RiskLevel
    
    /// Risk factors contributing to current status
    public var riskFactors: [String]
    
    // MARK: - Country-Specific Status
    
    /// Compliance status by country
    public var countryStatus: [String: CountryComplianceStatus]
    
    // MARK: - Metadata
    
    /// When this status was last calculated
    public var lastCalculated: Date
    
    /// When next calculation is scheduled
    public var nextCalculation: Date
    
    public let createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        entityId: UUID,
        entityType: EntityType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.entityId = entityId
        self.entityType = entityType
        self.complianceScore = 100
        self.overallStatus = .compliant
        self.criticalAlertsCount = 0
        self.highAlertsCount = 0
        self.mediumAlertsCount = 0
        self.lowAlertsCount = 0
        self.informationalAlertsCount = 0
        self.totalRequirements = 0
        self.compliantRequirements = 0
        self.pendingRequirements = 0
        self.overdueRequirements = 0
        self.upcomingDeadlines = 0
        self.totalDocuments = 0
        self.expiringDocuments = 0
        self.expiredDocuments = 0
        self.pendingVerificationDocuments = 0
        self.reportingDue = []
        self.riskLevel = .low
        self.riskFactors = []
        self.countryStatus = [:]
        self.lastCalculated = createdAt
        self.nextCalculation = Calendar.current.date(byAdding: .hour, value: 24, to: createdAt) ?? createdAt
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// Whether there are any critical issues
    public var hasCriticalIssues: Bool {
        return criticalAlertsCount > 0 || overdueRequirements > 0 || expiredDocuments > 0
    }
    
    /// Whether action is needed soon
    public var needsAttention: Bool {
        return hasCriticalIssues || upcomingDeadlines > 0 || expiringDocuments > 0
    }
    
    /// Compliance percentage
    public var compliancePercentage: Double {
        guard totalRequirements > 0 else { return 100.0 }
        return (Double(compliantRequirements) / Double(totalRequirements)) * 100.0
    }
}

// MARK: - Supporting Types

/// Entity type for compliance tracking
public enum EntityType: String, CaseIterable, Codable, Sendable {
    case user = "user"
    case portfolio = "portfolio"
    case asset = "asset"
    case account = "account"
    
    public var displayName: String {
        switch self {
        case .user: return NSLocalizedString("user_entity", comment: "User entity")
        case .portfolio: return NSLocalizedString("portfolio_entity", comment: "Portfolio entity")
        case .asset: return NSLocalizedString("asset_entity", comment: "Asset entity")
        case .account: return NSLocalizedString("account_entity", comment: "Account entity")
        }
    }
}

/// Overall compliance status
public enum Status: String, CaseIterable, Codable, Sendable {
    case compliant = "compliant"
    case partiallyCompliant = "partiallyCompliant"
    case nonCompliant = "nonCompliant"
    case unknown = "unknown"
    case pendingReview = "pendingReview"
    
    public var displayName: String {
        switch self {
        case .compliant: return NSLocalizedString("compliant_status", comment: "Compliant status")
        case .partiallyCompliant: return NSLocalizedString("partially_compliant", comment: "Partially compliant status")
        case .nonCompliant: return NSLocalizedString("non_compliant", comment: "Non-compliant status")
        case .unknown: return NSLocalizedString("unknown_status", comment: "Unknown status")
        case .pendingReview: return NSLocalizedString("pending_review", comment: "Pending review status")
        }
    }
    
    public var isCompliant: Bool {
        return self == .compliant
    }
}

/// Risk level assessment
public enum RiskLevel: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return NSLocalizedString("low_risk", comment: "Low risk")
        case .medium: return NSLocalizedString("medium_risk", comment: "Medium risk")
        case .high: return NSLocalizedString("high_risk", comment: "High risk")
        case .critical: return NSLocalizedString("critical_risk", comment: "Critical risk")
        }
    }
    
    public var numericValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

/// Reporting status for specific requirement
public struct ReportingStatus: Codable, Hashable, Sendable {
    public var requirementId: UUID
    public var formName: String
    public var deadline: Date
    public var status: String
    public var daysUntilDeadline: Int
    
    public init(requirementId: UUID, formName: String, deadline: Date, status: String) {
        self.requirementId = requirementId
        self.formName = formName
        self.deadline = deadline
        self.status = status
        let calendar = Calendar.current
        self.daysUntilDeadline = calendar.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
}

/// Country-specific compliance status
public struct CountryComplianceStatus: Codable, Hashable, Sendable {
    public var countryCode: String
    public var status: Status
    public var activeRequirements: Int
    public var compliantRequirements: Int
    public var pendingActions: Int
    public var nextDeadline: Date?
    
    public init(countryCode: String, status: Status, activeRequirements: Int, compliantRequirements: Int, pendingActions: Int) {
        self.countryCode = countryCode
        self.status = status
        self.activeRequirements = activeRequirements
        self.compliantRequirements = compliantRequirements
        self.pendingActions = pendingActions
    }
    
    public var compliancePercentage: Double {
        guard activeRequirements > 0 else { return 100.0 }
        return (Double(compliantRequirements) / Double(activeRequirements)) * 100.0
    }
}

// MARK: - Extensions

extension ComplianceStatus {
    
    /// Update alert counts
    public mutating func updateAlertCounts(critical: Int, high: Int, medium: Int, low: Int, informational: Int) {
        criticalAlertsCount = critical
        highAlertsCount = high
        mediumAlertsCount = medium
        lowAlertsCount = low
        informationalAlertsCount = informational
        updatedAt = Date()
    }
    
    /// Update requirement counts
    public mutating func updateRequirementCounts(total: Int, compliant: Int, pending: Int, overdue: Int, upcoming: Int) {
        totalRequirements = total
        compliantRequirements = compliant
        pendingRequirements = pending
        overdueRequirements = overdue
        upcomingDeadlines = upcoming
        updatedAt = Date()
    }
    
    /// Update document counts
    public mutating func updateDocumentCounts(total: Int, expiring: Int, expired: Int, pendingVerification: Int) {
        totalDocuments = total
        expiringDocuments = expiring
        expiredDocuments = expired
        pendingVerificationDocuments = pendingVerification
        updatedAt = Date()
    }
    
    /// Calculate overall compliance score
    public mutating func calculateComplianceScore() {
        var score = 100
        
        // Deduct for alerts
        score -= criticalAlertsCount * 20
        score -= highAlertsCount * 10
        score -= mediumAlertsCount * 5
        score -= lowAlertsCount * 2
        
        // Deduct for non-compliance
        score -= overdueRequirements * 15
        score -= expiredDocuments * 10
        score -= pendingRequirements * 3
        
        complianceScore = max(0, min(100, score))
        
        // Update overall status
        if complianceScore >= 90 {
            overallStatus = .compliant
            riskLevel = .low
        } else if complianceScore >= 70 {
            overallStatus = .partiallyCompliant
            riskLevel = .medium
        } else if complianceScore >= 50 {
            overallStatus = .partiallyCompliant
            riskLevel = .high
        } else {
            overallStatus = .nonCompliant
            riskLevel = .critical
        }
        
        lastCalculated = Date()
        updatedAt = Date()
    }
    
    /// Add country status
    public mutating func addCountryStatus(_ countryStatus: CountryComplianceStatus) {
        self.countryStatus[countryStatus.countryCode] = countryStatus
        updatedAt = Date()
    }
    
    /// Add risk factor
    public mutating func addRiskFactor(_ factor: String) {
        if !riskFactors.contains(factor) {
            riskFactors.append(factor)
            updatedAt = Date()
        }
    }
}

// MARK: - Hashable & Equatable

extension ComplianceStatus {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ComplianceStatus, rhs: ComplianceStatus) -> Bool {
        return lhs.id == rhs.id
    }
}
