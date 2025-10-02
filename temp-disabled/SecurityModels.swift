import Foundation

/// Security & Authentication System Models
/// Created for Issue #47: Security & Authentication System
/// Using Codable for JSON persistence instead of SwiftData for better compatibility

public struct AuthenticatedUser: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userIdentifier: String
    public let displayName: String?
    public let authenticationMethod: AuthenticationMethod
    public let lastSuccessfulLogin: Date?
    public let failedLoginAttempts: Int
    public let isLockedOut: Bool
    public let lockoutExpiresAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(userIdentifier: String, authenticationMethod: AuthenticationMethod, displayName: String? = nil) {
        self.id = UUID()
        self.userIdentifier = userIdentifier
        self.authenticationMethod = authenticationMethod
        self.displayName = displayName
        self.failedLoginAttempts = 0
        self.isLockedOut = false
        self.lockoutExpiresAt = nil
        self.lastSuccessfulLogin = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

public struct SecurityAuditLog: Codable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let eventType: SecurityEventType
    public let userId: String?
    public let deviceId: String?
    public let ipAddress: String?
    public let eventDescription: String
    public let riskLevel: SecurityRiskLevel
    public let metadata: [String: String]?
    
    public init(eventType: SecurityEventType, description: String, riskLevel: SecurityRiskLevel, userId: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.eventType = eventType
        self.eventDescription = description
        self.riskLevel = riskLevel
        self.userId = userId
        self.deviceId = nil
        self.ipAddress = nil
        self.metadata = nil
    }
}

public struct SecurityThreatRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let detectedAt: Date
    public let threatType: SecurityThreat
    public let severity: ThreatSeverity
    public let threatDescription: String
    public let deviceFingerprint: String?
    public let isResolved: Bool
    public let resolvedAt: Date?
    
    public init(threatType: SecurityThreat, severity: ThreatSeverity, description: String) {
        self.id = UUID()
        self.detectedAt = Date()
        self.threatType = threatType
        self.severity = severity
        self.threatDescription = description
        self.deviceFingerprint = nil
        self.isResolved = false
        self.resolvedAt = nil
    }
}

public struct SecuritySession: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: String
    public let deviceId: String
    public let sessionToken: String
    public let createdAt: Date
    public let lastActiveAt: Date
    public let expiresAt: Date
    public let isActive: Bool
    public let ipAddress: String?
    public let userAgent: String?
    
    public init(userId: String, deviceId: String, sessionToken: String, expiresAt: Date) {
        self.id = UUID()
        self.userId = userId
        self.deviceId = deviceId
        self.sessionToken = sessionToken
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.expiresAt = expiresAt
        self.isActive = true
        self.ipAddress = nil
        self.userAgent = nil
    }
}

// MARK: - Security Enums

public enum SecurityRiskLevel: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return NSLocalizedString("risk_low", comment: "Low risk")
        case .medium: return NSLocalizedString("risk_medium", comment: "Medium risk")
        case .high: return NSLocalizedString("risk_high", comment: "High risk")
        case .critical: return NSLocalizedString("risk_critical", comment: "Critical risk")
        }
    }
}