import Foundation

/// Security & Authentication System
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
    public let eventType: AuditSecurityEvent
    public let userId: String?
    public let deviceId: String?
    public let ipAddress: String?
    public let eventDescription: String
    public let riskLevel: SecurityRiskLevel
    public let metadata: [String: String]?
    
    public init(eventType: AuditSecurityEvent, description: String, riskLevel: SecurityRiskLevel, userId: String? = nil) {
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
    public let threatType: ThreatType
    public let severity: ThreatSeverity
    public let threatDescription: String
    public let deviceFingerprint: String?
    public let isResolved: Bool
    public let resolvedAt: Date?
  
    public init(threatType: ThreatType, severity: ThreatSeverity, description: String) {
        self.id = UUID()
        self.detectedAt = Date()
        self.threatType = threatType
        self.severity = severity
        self.threatDescription = description
        self.deviceFingerprint = nil
        self.isResolved = false
        self.resolvedAt = nil
    }
  
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.detectedAt = try container.decode(Date.self, forKey: .detectedAt)
        self.threatType = try container.decode(ThreatType.self, forKey: .threatType)
        self.severity = try container.decode(ThreatSeverity.self, forKey: .severity)
        self.threatDescription = try container.decode(String.self, forKey: .threatDescription)
        self.deviceFingerprint = try container.decodeIfPresent(String.self, forKey: .deviceFingerprint)
        self.isResolved = try container.decode(Bool.self, forKey: .isResolved)
        self.resolvedAt = try container.decodeIfPresent(Date.self, forKey: .resolvedAt)
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
  
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.id = try container.decode(UUID.self, forKey: .id)
      self.userId = try container.decode(String.self, forKey: .userId)
      self.deviceId = try container.decode(String.self, forKey: .deviceId)
      self.sessionToken = try container.decode(String.self, forKey: .sessionToken)
      self.createdAt = try container.decode(Date.self, forKey: .createdAt)
      self.lastActiveAt = try container.decode(Date.self, forKey: .lastActiveAt)
      self.expiresAt = try container.decode(Date.self, forKey: .expiresAt)
      self.isActive = try container.decode(Bool.self, forKey: .isActive)
      self.ipAddress = try container.decodeIfPresent(String.self, forKey: .ipAddress)
      self.userAgent = try container.decodeIfPresent(String.self, forKey: .userAgent)
                                                     
    }
}

// MARK: - Local Enums (not defined in SecurityProtocols.swift)

public enum ThreatType: String, CaseIterable, Codable, Sendable {
    case suspiciousNetworkActivity = "suspicious_network_activity"
    case multipleFailedLogins = "multiple_failed_logins"
    case unusualLocationAccess = "unusual_location_access"
    case deviceCompromiseIndicator = "device_compromise_indicator"
    case dataExfiltrationAttempt = "data_exfiltration_attempt"
    case maliciousAppDetection = "malicious_app_detection"
    case jailbreakDetection = "jailbreak_detection"
    case debuggerAttachment = "debugger_attachment"
    case certificatePinningBypass = "certificate_pinning_bypass"
    case screenRecordingDetection = "screen_recording_detection"
}

