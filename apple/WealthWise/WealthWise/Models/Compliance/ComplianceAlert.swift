//
//  ComplianceAlert.swift
//  WealthWise
//
//  Compliance alert model for notifying users of regulatory requirements
//

import Foundation

/// Compliance alert for notifying users about regulatory requirements and deadlines
public struct ComplianceAlert: Codable, Hashable, Identifiable, Sendable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public var alertType: AlertType
    public var severityLevel: SeverityLevel
    public var title: String
    public var message: String
    public var detailedDescription: String?
    
    // MARK: - Related Entities
    
    /// Associated compliance rule ID
    public var ruleId: UUID?
    
    /// Associated asset IDs
    public var relatedAssetIds: Set<UUID>
    
    /// Country codes this alert applies to
    public var countryCodes: Set<String>
    
    // MARK: - Timing
    
    /// When this alert was generated
    public let generatedAt: Date
    
    /// Deadline for compliance action
    public var actionDeadline: Date?
    
    /// Days remaining until deadline
    public var daysUntilDeadline: Int? {
        guard let deadline = actionDeadline else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: deadline).day
    }
    
    // MARK: - Status & Actions
    
    /// Alert status
    public var status: AlertStatus
    
    /// Required actions to resolve
    public var requiredActions: [String]
    
    /// Recommended actions
    public var recommendedActions: [String]
    
    /// Whether user action is required
    public var requiresUserAction: Bool
    
    /// Whether this can be automatically resolved
    public var isAutoResolvable: Bool
    
    // MARK: - User Interaction
    
    /// When user acknowledged this alert
    public var acknowledgedAt: Date?
    
    /// When alert was resolved
    public var resolvedAt: Date?
    
    /// Resolution notes
    public var resolutionNotes: String?
    
    /// Whether user dismissed this alert
    public var isDismissed: Bool
    
    /// Dismiss reason
    public var dismissReason: String?
    
    // MARK: - Links & Resources
    
    /// External reference URL (regulation, forms, etc.)
    public var referenceURL: String?
    
    /// Document IDs needed for compliance
    public var requiredDocumentIds: [UUID]
    
    /// Help article or guidance link
    public var helpArticleURL: String?
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        alertType: AlertType,
        severityLevel: SeverityLevel,
        title: String,
        message: String,
        actionDeadline: Date? = nil,
        requiresUserAction: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.alertType = alertType
        self.severityLevel = severityLevel
        self.title = title
        self.message = message
        self.actionDeadline = actionDeadline
        self.requiresUserAction = requiresUserAction
        self.generatedAt = createdAt
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.status = .active
        self.relatedAssetIds = Set()
        self.countryCodes = Set()
        self.requiredActions = []
        self.recommendedActions = []
        self.isAutoResolvable = false
        self.isDismissed = false
        self.requiredDocumentIds = []
    }
    
    // MARK: - Computed Properties
    
    /// Whether this alert is overdue
    public var isOverdue: Bool {
        guard let deadline = actionDeadline else { return false }
        return Date() > deadline
    }
    
    /// Whether this alert is urgent (within 7 days of deadline)
    public var isUrgent: Bool {
        guard let days = daysUntilDeadline else { return false }
        return days <= 7 && days >= 0
    }
    
    /// Whether this alert needs immediate attention
    public var needsImmediateAttention: Bool {
        return (severityLevel == .critical || severityLevel == .high) && (isUrgent || isOverdue)
    }
    
    /// Priority score for sorting alerts
    public var priorityScore: Int {
        var score = severityLevel.numericValue * 10
        
        if let days = daysUntilDeadline {
            if days < 0 {
                score += 50 // Overdue
            } else if days <= 7 {
                score += 30 // Urgent
            } else if days <= 30 {
                score += 10 // Soon
            }
        }
        
        if requiresUserAction {
            score += 5
        }
        
        return score
    }
}

// MARK: - Supporting Enums

/// Type of compliance alert
public enum AlertType: String, CaseIterable, Codable, Sendable {
    case thresholdExceeded = "thresholdExceeded"
    case deadlineApproaching = "deadlineApproaching"
    case documentExpiring = "documentExpiring"
    case reportingRequired = "reportingRequired"
    case taxFilingDue = "taxFilingDue"
    case disclosureRequired = "disclosureRequired"
    case complianceViolation = "complianceViolation"
    case regulationChange = "regulationChange"
    case renewalRequired = "renewalRequired"
    case informational = "informational"
    
    public var displayName: String {
        switch self {
        case .thresholdExceeded: return NSLocalizedString("threshold_exceeded", comment: "Threshold exceeded alert")
        case .deadlineApproaching: return NSLocalizedString("deadline_approaching", comment: "Deadline approaching alert")
        case .documentExpiring: return NSLocalizedString("document_expiring", comment: "Document expiring alert")
        case .reportingRequired: return NSLocalizedString("reporting_required", comment: "Reporting required alert")
        case .taxFilingDue: return NSLocalizedString("tax_filing_due", comment: "Tax filing due alert")
        case .disclosureRequired: return NSLocalizedString("disclosure_required", comment: "Disclosure required alert")
        case .complianceViolation: return NSLocalizedString("compliance_violation", comment: "Compliance violation alert")
        case .regulationChange: return NSLocalizedString("regulation_change", comment: "Regulation change alert")
        case .renewalRequired: return NSLocalizedString("renewal_required", comment: "Renewal required alert")
        case .informational: return NSLocalizedString("informational_alert", comment: "Informational alert")
        }
    }
}

/// Status of compliance alert
public enum AlertStatus: String, CaseIterable, Codable, Sendable {
    case active = "active"
    case acknowledged = "acknowledged"
    case inProgress = "inProgress"
    case resolved = "resolved"
    case dismissed = "dismissed"
    case expired = "expired"
    
    public var displayName: String {
        switch self {
        case .active: return NSLocalizedString("active_status", comment: "Active status")
        case .acknowledged: return NSLocalizedString("acknowledged_status", comment: "Acknowledged status")
        case .inProgress: return NSLocalizedString("in_progress_status", comment: "In progress status")
        case .resolved: return NSLocalizedString("resolved_status", comment: "Resolved status")
        case .dismissed: return NSLocalizedString("dismissed_status", comment: "Dismissed status")
        case .expired: return NSLocalizedString("expired_status", comment: "Expired status")
        }
    }
    
    public var isActionable: Bool {
        return self == .active || self == .acknowledged || self == .inProgress
    }
}

// MARK: - Extensions

extension ComplianceAlert {
    
    /// Acknowledge this alert
    public mutating func acknowledge() {
        status = .acknowledged
        acknowledgedAt = Date()
        updatedAt = Date()
    }
    
    /// Mark alert as in progress
    public mutating func markInProgress() {
        status = .inProgress
        updatedAt = Date()
    }
    
    /// Resolve this alert
    public mutating func resolve(notes: String? = nil) {
        status = .resolved
        resolvedAt = Date()
        resolutionNotes = notes
        updatedAt = Date()
    }
    
    /// Dismiss this alert
    public mutating func dismiss(reason: String? = nil) {
        status = .dismissed
        isDismissed = true
        dismissReason = reason
        updatedAt = Date()
    }
    
    /// Add required action
    public mutating func addRequiredAction(_ action: String) {
        requiredActions.append(action)
        updatedAt = Date()
    }
    
    /// Add recommended action
    public mutating func addRecommendedAction(_ action: String) {
        recommendedActions.append(action)
        updatedAt = Date()
    }
    
    /// Add related asset
    public mutating func addRelatedAsset(_ assetId: UUID) {
        relatedAssetIds.insert(assetId)
        updatedAt = Date()
    }
    
    /// Add country code
    public mutating func addCountryCode(_ code: String) {
        countryCodes.insert(code)
        updatedAt = Date()
    }
}

// MARK: - Hashable & Equatable

extension ComplianceAlert {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ComplianceAlert, rhs: ComplianceAlert) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Comparable

extension ComplianceAlert: Comparable {
    public static func < (lhs: ComplianceAlert, rhs: ComplianceAlert) -> Bool {
        // Sort by priority score
        if lhs.priorityScore != rhs.priorityScore {
            return lhs.priorityScore > rhs.priorityScore
        }
        // Then by creation date
        return lhs.createdAt < rhs.createdAt
    }
}
