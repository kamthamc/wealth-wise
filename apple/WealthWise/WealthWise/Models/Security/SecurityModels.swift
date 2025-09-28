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
    public let eventType: SecurityEvent
    public let userId: String?
    public let deviceId: String?
    public let ipAddress: String?
    public let eventDescription: String
    public let riskLevel: SecurityRiskLevel
    public let metadata: [String: String]?
    
    public init(eventType: SecurityEvent, description: String, riskLevel: SecurityRiskLevel, userId: String? = nil) {
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

public struct SecurityThreat: Codable, Identifiable, Sendable {
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

public enum SecurityEvent: String, CaseIterable, Codable {
    case login = "login"
    case logout = "logout"
    case failedLogin = "failed_login"
    case accountLockout = "account_lockout"
    case passwordChange = "password_change"
    case biometricEnrollment = "biometric_enrollment"
    case suspiciousActivity = "suspicious_activity"
    case dataAccess = "data_access"
    case dataModification = "data_modification"
    case sessionTimeout = "session_timeout"
    case securityThreatDetected = "security_threat_detected"
    case encryptionKeyRotation = "encryption_key_rotation"
    case backupCreated = "backup_created"
    case backupRestored = "backup_restored"
}

public enum ThreatType: String, CaseIterable, Codable {
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

public enum ThreatSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public enum AuthenticationMethod: String, CaseIterable, Codable {
    case none = "none"
    case pin = "pin"
    case password = "password"
    case biometric = "biometric"
    case twoFactor = "two_factor"
    case passkey = "passkey"
    case hardware = "hardware"
    
    public var displayName: String {
        switch self {
        case .none: return NSLocalizedString("auth_none", comment: "No authentication")
        case .pin: return NSLocalizedString("auth_pin", comment: "PIN")
        case .password: return NSLocalizedString("auth_password", comment: "Password")
        case .biometric: return NSLocalizedString("auth_biometric", comment: "Biometric")
        case .twoFactor: return NSLocalizedString("auth_two_factor", comment: "Two-factor")
        case .passkey: return NSLocalizedString("auth_passkey", comment: "Passkey")
        case .hardware: return NSLocalizedString("auth_hardware", comment: "Hardware key")
        }
    }
    
    public var securityLevel: SecurityRiskLevel {
        switch self {
        case .none: return .low
        case .pin: return .medium
        case .password: return .medium
        case .biometric: return .high
        case .twoFactor: return .critical
        case .passkey: return .critical
        case .hardware: return .critical
        }
    }
}