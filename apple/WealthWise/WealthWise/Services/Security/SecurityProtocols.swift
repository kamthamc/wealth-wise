//
//  SecurityProtocols.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Core Protocols
//

import Foundation
import Security
import CryptoKit
import LocalAuthentication
import Combine

// MARK: - Core Security Protocols

/// Protocol defining biometric authentication capabilities
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public protocol BiometricAuthenticationProtocol: AnyObject, Sendable {
    /// Check if biometric authentication is available on device
    func isBiometricAuthenticationAvailable() -> Bool
    
    /// Get the type of biometric authentication available
    func availableBiometricType() -> BiometricType
    
    /// Authenticate user using biometrics
    func authenticateWithBiometrics(reason: String) async throws -> AuthenticationResult
    
    /// Check if biometric authentication is enrolled
    func isBiometricEnrolled() -> Bool
}

/// Protocol defining secure key management operations
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public protocol SecureKeyManagementProtocol: AnyObject, Sendable {
    /// Generate a new secure key
    func generateSecureKey(identifier: String, accessibility: KeyAccessibility) throws -> SecureKey
    
    /// Store a key securely
    func storeKey(_ key: SecureKey, identifier: String, accessibility: KeyAccessibility) throws
    
    /// Retrieve a stored key
    func retrieveKey(identifier: String) throws -> SecureKey?
    
    /// Delete a stored key
    func deleteKey(identifier: String) throws
    
    /// Check if a key exists
    func keyExists(identifier: String) -> Bool
    
    /// Update key accessibility
    func updateKeyAccessibility(identifier: String, accessibility: KeyAccessibility) throws
}

/// Protocol defining encryption and decryption operations
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public protocol EncryptionServiceProtocol: AnyObject, Sendable {
    /// Encrypt data using AES-256-GCM with structured concurrency
    func encrypt(_ data: Data, using key: SecureKey) async throws -> EncryptedData
    
    /// Decrypt data using AES-256-GCM with structured concurrency
    func decrypt(_ encryptedData: EncryptedData, using key: SecureKey) async throws -> Data
    
    /// Generate a secure random key
    func generateRandomKey() -> SecureKey
    
    /// Derive key from password using PBKDF2
    func deriveKey(from password: String, salt: Data, iterations: Int) throws -> SecureKey
}

/// Protocol defining authentication state management
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public protocol AuthenticationStateProtocol: ObservableObject, Sendable {
    /// Current authentication state
    var authenticationState: AuthenticationState { get }
    
    /// Whether user is currently authenticated
    var isAuthenticated: Bool { get }
    
    /// Time of last successful authentication
    var lastAuthenticationTime: Date? { get }
    
    /// Update authentication state
    func updateAuthenticationState(_ state: AuthenticationState)
    
    /// Check if session is valid
    func isSessionValid() -> Bool
    
    /// Invalidate current session
    func invalidateSession()
    
    /// Start session timeout monitoring
    func startSessionTimeout()
    
    /// Reset session timeout
    func resetSessionTimeout()
}

/// Protocol defining security validation operations
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public protocol SecurityValidationProtocol: AnyObject, Sendable {
    /// Check if device is jailbroken/rooted with async validation
    func isDeviceCompromised() async -> Bool
    
    /// Validate app integrity with enhanced iOS 18 checks (bool helper)
    func isAppIntegrityValid() async -> Bool
    
    /// Check if app is running in debug mode
    func isDebuggerAttached() -> Bool
    
    /// Validate certificate pinning
    func validateCertificatePinning(for url: URL) -> Bool
    
    /// Check for suspicious activities
    func detectSuspiciousActivity() -> [SecurityThreat]
}

// MARK: - Supporting Types

/// Types of biometric authentication available
public enum BiometricType: String, CaseIterable, Sendable, Codable {
    case none = "none"
    case touchID = "touchID"
    case faceID = "faceID"
    case opticID = "opticID"           // Apple Vision Pro, iPad Pro M4
    case voiceID = "voiceID"           // iOS 18+ Voice Recognition
    case appleWatch = "appleWatch"     // Apple Watch Authentication
    case fingerprint = "fingerprint"  // Android
    case face = "face"                // Android
    case iris = "iris"                // Android/Samsung
    case windowsHello = "windowsHello" // Windows
    case windowsFingerprint = "windowsFingerprint" // Windows Enhanced
    case passkeyBiometric = "passkeyBiometric"     // iOS 18 Passkey integration
    
    public nonisolated var displayName: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        case .voiceID: return "Voice ID"
        case .appleWatch: return "Apple Watch"
        case .fingerprint: return "Fingerprint"
        case .face: return "Face Recognition"
        case .iris: return "Iris Recognition"
        case .windowsHello: return "Windows Hello"
        case .windowsFingerprint: return "Windows Fingerprint"
        case .passkeyBiometric: return "Passkey Biometric"
        }
    }
    
    public var isAvailable: Bool {
        #if os(iOS)
        let context = LAContext()
        var error: NSError?
        
        switch self {
        case .touchID:
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) &&
                   context.biometryType == .touchID
        case .faceID:
            return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) &&
                   context.biometryType == .faceID
        case .opticID:
            if #available(iOS 18.0, *) {
                return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) &&
                       context.biometryType == .opticID
            }
            return false
        case .voiceID:
            if #available(iOS 18.6, *) {
                return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            }
            return false
        case .appleWatch:
            if #available(iOS 18.6, *) {
                return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
            }
            return false
        case .passkeyBiometric:
            if #available(iOS 18.6, *) {
                return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            }
            return false
        default:
            return false
        }
        #elseif os(macOS)
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        #else
        return false
        #endif
    }
}

/// Key accessibility levels for secure storage
public enum KeyAccessibility: String, CaseIterable, Sendable {
    case whenUnlocked = "whenUnlocked"
    case whenUnlockedThisDeviceOnly = "whenUnlockedThisDeviceOnly"
    case afterFirstUnlock = "afterFirstUnlock"
    case afterFirstUnlockThisDeviceOnly = "afterFirstUnlockThisDeviceOnly"
    case whenPasscodeSetThisDeviceOnly = "whenPasscodeSetThisDeviceOnly"
    case biometricAny = "biometricAny"
    case biometricCurrentSet = "biometricCurrentSet"
    case applicationPassword = "applicationPassword"      // iOS 18.6+ App-specific password
    case biometricOrWatch = "biometricOrWatch"          // iOS 18.6+ Apple Watch unlock
    case secureEnclave = "secureEnclave"                // iOS 18.6+ Secure Enclave only
    
    public var keychainAccessibility: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked as CFString
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as CFString
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock as CFString
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as CFString
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as CFString
        case .applicationPassword:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as CFString
          case .secureEnclave, .biometricAny, .biometricCurrentSet, .biometricOrWatch:
            // Use existing Secure Enclave accessibility or fallback
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as CFString
        }
    }
}

/// Security levels for enhanced protection classification
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public enum SecurityLevel: String, CaseIterable, Sendable, Codable {
    case minimal = "minimal"     // Basic encryption, suitable for non-sensitive data
    case standard = "standard"   // Standard AES-256 encryption
    case high = "high"          // Enhanced encryption with additional security measures
    case maximum = "maximum"    // Highest security with Secure Enclave and attestation
    case quantum = "quantum"    // Quantum-resistant algorithms (future-proofing)
    
    public nonisolated var displayName: String {
        switch self {
        case .minimal: return "Minimal Security"
        case .standard: return "Standard Security"
        case .high: return "High Security"
        case .maximum: return "Maximum Security"
        case .quantum: return "Quantum-Resistant Security"
        }
    }
    
    public var requiredKeySize: Int {
        switch self {
        case .minimal: return 128
        case .standard: return 256
        case .high: return 256
        case .maximum: return 256
        case .quantum: return 512
        }
    }
    
    public var requiresSecureEnclave: Bool {
        switch self {
        case .maximum, .quantum: return true
        default: return false
        }
    }
}

/// Key derivation context for enhanced key management
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct KeyDerivationContext: Sendable, Hashable {
    public let method: KeyDerivationMethod
    public let iterations: Int
    public let salt: Data
    public let info: Data?
    public let algorithm: KeyDerivationAlgorithm
    
    public init(method: KeyDerivationMethod, iterations: Int, salt: Data, info: Data? = nil, algorithm: KeyDerivationAlgorithm = .pbkdf2SHA256) {
        self.method = method
        self.iterations = iterations
        self.salt = salt
        self.info = info
        self.algorithm = algorithm
    }
}

/// Key derivation methods
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public enum KeyDerivationMethod: String, CaseIterable, Sendable {
    case pbkdf2 = "pbkdf2"
    case scrypt = "scrypt"
    case argon2id = "argon2id"
    case hkdf = "hkdf"
    
    public var displayName: String {
        switch self {
        case .pbkdf2: return "PBKDF2"
        case .scrypt: return "scrypt"
        case .argon2id: return "Argon2id"
        case .hkdf: return "HKDF"
        }
    }
}

/// Key derivation algorithms
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public enum KeyDerivationAlgorithm: String, CaseIterable, Sendable {
    case pbkdf2SHA256 = "pbkdf2-sha256"
    case pbkdf2SHA512 = "pbkdf2-sha512"
    case scryptDefault = "scrypt-default"
    case argon2idDefault = "argon2id-default"
    case hkdfSHA256 = "hkdf-sha256"
    case hkdfSHA512 = "hkdf-sha512"
    
    public var displayName: String {
        switch self {
        case .pbkdf2SHA256: return "PBKDF2-SHA256"
        case .pbkdf2SHA512: return "PBKDF2-SHA512"
        case .scryptDefault: return "scrypt"
        case .argon2idDefault: return "Argon2id"
        case .hkdfSHA256: return "HKDF-SHA256"
        case .hkdfSHA512: return "HKDF-SHA512"
        }
    }
}

/// Authentication state enumeration
public enum AuthenticationState: String, CaseIterable, Sendable {
    case unauthenticated = "unauthenticated"
    case authenticating = "authenticating"
    case authenticated = "authenticated"
    case biometricRequired = "biometricRequired"
    case passcodeRequired = "passcodeRequired"
    case sessionExpired = "sessionExpired"
    case locked = "locked"
    case compromised = "compromised"
    
    public var displayName: String {
        switch self {
        case .unauthenticated: return "Not Authenticated"
        case .authenticating: return "Authenticating..."
        case .authenticated: return "Authenticated"
        case .biometricRequired: return "Biometric Authentication Required"
        case .passcodeRequired: return "Passcode Required"
        case .sessionExpired: return "Session Expired"
        case .locked: return "Account Locked"
        case .compromised: return "Security Compromised"
        }
    }
    
    public var isSecure: Bool {
        switch self {
        case .authenticated:
            return true
        default:
            return false
        }
    }
}

/// Authentication result with detailed information
public struct AuthenticationResult: Sendable, Codable, Equatable, Hashable {
    public let success: Bool
    public let biometricType: BiometricType
    public let timestamp: Date
    public let error: AuthenticationError?
    public let userID: String?
    public let securityLevel: SecurityLevel
    
    public init(success: Bool, biometricType: BiometricType, timestamp: Date = Date(), error: AuthenticationError? = nil, userID: String? = nil, securityLevel: SecurityLevel = .high) {
        self.success = success
        self.biometricType = biometricType
        self.timestamp = timestamp
        self.error = error
        self.userID = userID
        self.securityLevel = securityLevel
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        biometricType = try container.decode(BiometricType.self, forKey: .biometricType)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        error = try container.decodeIfPresent(AuthenticationError.self, forKey: .error)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        securityLevel = try container.decode(SecurityLevel.self, forKey: .securityLevel)
    }
    
    private enum CodingKeys: String, CodingKey {
        case success, biometricType, timestamp, error, userID, securityLevel
    }
    
    /// Convenient access to error message
    public var errorMessage: String? {
        return error?.errorMessage
    }
    
    /// Create a security validation failed result
    public static func securityValidationFailed(message: String) -> AuthenticationResult {
        return AuthenticationResult(
            success: false,
            biometricType: .none,
            error: .authenticationFailed(message),
            securityLevel: .minimal
        )
    }
}

// MARK: - Equatable & Hashable Conformance
extension AuthenticationResult {
    public static func == (lhs: AuthenticationResult, rhs: AuthenticationResult) -> Bool {
        return lhs.success == rhs.success &&
               lhs.biometricType == rhs.biometricType &&
               lhs.timestamp == rhs.timestamp &&
               lhs.error == rhs.error &&
               lhs.userID == rhs.userID &&
               lhs.securityLevel == rhs.securityLevel
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(success)
        hasher.combine(biometricType)
        hasher.combine(timestamp)
        hasher.combine(error)
        hasher.combine(userID)
        hasher.combine(securityLevel)
    }
}

/// Secure key wrapper with metadata
public struct SecureKey: Sendable, Hashable {
    public let keyData: Data
    public let identifier: String
    public let algorithm: KeyAlgorithm
    public let keySize: Int
    public let createdAt: Date
    public let accessibility: KeyAccessibility
    public let securityLevel: SecurityLevel
    public let keyDerivationContext: KeyDerivationContext?
    
    public init(keyData: Data, identifier: String, algorithm: KeyAlgorithm = .aes256, keySize: Int = 256, createdAt: Date = Date(), accessibility: KeyAccessibility = .whenUnlockedThisDeviceOnly, securityLevel: SecurityLevel = .high, keyDerivationContext: KeyDerivationContext? = nil) {
        self.keyData = keyData
        self.identifier = identifier
        self.algorithm = algorithm
        self.keySize = keySize
        self.createdAt = createdAt
        self.accessibility = accessibility
        self.securityLevel = securityLevel
        self.keyDerivationContext = keyDerivationContext
    }
}

/// Encrypted data container with metadata
public struct EncryptedData: Sendable, Hashable, Codable {
    public let ciphertext: Data
    public let nonce: Data
    public let tag: Data
    public let algorithm: EncryptionAlgorithm
    public let timestamp: Date
    public let securityLevel: SecurityLevel
    public let keyIdentifier: String?
    
    public init(ciphertext: Data, nonce: Data, tag: Data, algorithm: EncryptionAlgorithm = .aes256GCM, timestamp: Date = Date(), securityLevel: SecurityLevel = .high, keyIdentifier: String? = nil) {
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.algorithm = algorithm
        self.timestamp = timestamp
        self.securityLevel = securityLevel
        self.keyIdentifier = keyIdentifier
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ciphertext = try container.decode(Data.self, forKey: .ciphertext)
        nonce = try container.decode(Data.self, forKey: .nonce)
        tag = try container.decode(Data.self, forKey: .tag)
        algorithm = try container.decode(EncryptionAlgorithm.self, forKey: .algorithm)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        securityLevel = try container.decode(SecurityLevel.self, forKey: .securityLevel)
        keyIdentifier = try container.decodeIfPresent(String.self, forKey: .keyIdentifier)
    }
    
    private enum CodingKeys: String, CodingKey {
        case ciphertext, nonce, tag, algorithm, timestamp, securityLevel, keyIdentifier
    }
    
    /// Combine all components into a single data blob
    public var combinedData: Data {
        var combined = Data()
        combined.append(nonce)
        combined.append(tag)
        combined.append(ciphertext)
        return combined
    }
    
    /// Initialize from combined data blob
    public init?(from combinedData: Data, algorithm: EncryptionAlgorithm = .aes256GCM) {
        guard combinedData.count >= 28 else { return nil } // 12 (nonce) + 16 (tag) minimum
        
        let nonce = combinedData.prefix(12)
        let tag = combinedData.dropFirst(12).prefix(16)
        let ciphertext = combinedData.dropFirst(28)
        
        self.init(
            ciphertext: Data(ciphertext),
            nonce: Data(nonce),
            tag: Data(tag),
            algorithm: algorithm
        )
    }
}

/// Supported key algorithms
public enum KeyAlgorithm: String, CaseIterable, Sendable {
    case aes128 = "aes128"
    case aes192 = "aes192"
    case aes256 = "aes256"
    case rsa2048 = "rsa2048"
    case rsa4096 = "rsa4096"
    case p256 = "p256"
    case p384 = "p384"
    case p521 = "p521"
    case kyber512 = "kyber512"     // Post-quantum key encapsulation
    case kyber768 = "kyber768"     // Post-quantum key encapsulation
    case kyber1024 = "kyber1024"   // Post-quantum key encapsulation
    case dilithium2 = "dilithium2" // Post-quantum signatures
    
    public var keySize: Int {
        switch self {
        case .aes128: return 128
        case .aes192: return 192
        case .aes256: return 256
        case .rsa2048: return 2048
        case .rsa4096: return 4096
        case .p256: return 256
        case .p384: return 384
        case .p521: return 521
        case .kyber512: return 512
        case .kyber768: return 768
        case .kyber1024: return 1024
        case .dilithium2: return 256
        }
    }
}

/// Supported encryption algorithms
public enum EncryptionAlgorithm: String, CaseIterable, Sendable, Codable {
    case aes256GCM = "aes256gcm"
    case aes192GCM = "aes192gcm"
    case aes128GCM = "aes128gcm"
    case chacha20Poly1305 = "chacha20poly1305"
    case xchacha20Poly1305 = "xchacha20poly1305"   // Extended nonce ChaCha20
    case aes256OCB = "aes256ocb"                   // iOS 18.6+ OCB mode
    case quantumResistant = "quantumresistant"     // Post-quantum hybrid encryption
    
    public nonisolated var displayName: String {
        switch self {
        case .aes256GCM: return "AES-256-GCM"
        case .aes192GCM: return "AES-192-GCM"
        case .aes128GCM: return "AES-128-GCM"
        case .chacha20Poly1305: return "ChaCha20-Poly1305"
        case .xchacha20Poly1305: return "XChaCha20-Poly1305"
        case .aes256OCB: return "AES-256-OCB"
        case .quantumResistant: return "Quantum-Resistant Hybrid"
        }
    }
    
    /// Compatibility aliases for SecurityConfiguration
    public static let aes256gcm = EncryptionAlgorithm.aes256GCM
    public static let chacha20poly1305 = EncryptionAlgorithm.chacha20Poly1305
    public static let postQuantumHybrid = EncryptionAlgorithm.quantumResistant
}

/// Security event types for audit logging
public enum SecurityEventType: String, CaseIterable, Sendable, Codable {
    case loginSuccess = "loginSuccess"
    case loginFailure = "loginFailure"
    case accountLocked = "accountLocked"
    case sessionExpired = "sessionExpired"
    case biometricAuthSuccess = "biometricAuthSuccess"
    case biometricAuthFailure = "biometricAuthFailure"
    case pinAuthSuccess = "pinAuthSuccess"
    case pinAuthFailure = "pinAuthFailure"
    case sessionStarted = "sessionStarted"
    case sessionEnded = "sessionEnded"
    case deviceCompromised = "deviceCompromised"
    case securityThreatDetected = "securityThreatDetected"
    case encryptionFailure = "encryptionFailure"
    case keyManagementFailure = "keyManagementFailure"
    case unauthorizedAccess = "unauthorizedAccess"
    case dataIntegrityViolation = "dataIntegrityViolation"
}

/// Security event for audit logging
public struct SecurityEvent: Sendable, Codable, Identifiable {
    public let id: UUID
    public let type: SecurityEventType
    public let description: String
    public let riskLevel: SecurityRiskLevel
    public let timestamp: Date
    public let userID: String?
    public let additionalData: [String: String]
    
    public init(
        type: SecurityEventType,
        description: String,
        riskLevel: SecurityRiskLevel,
        userID: String? = nil,
        additionalData: [String: String] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.description = description
        self.riskLevel = riskLevel
        self.timestamp = Date()
        self.userID = userID
        self.additionalData = additionalData
    }
}

/// Security risk levels
public enum SecurityRiskLevel: String, CaseIterable, Sendable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .medium: return "Medium Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
}

/// Simple authentication method enum for AuthenticationService
public enum AuthenticationMethod: String, CaseIterable, Sendable, Codable {
    case none = "none"
    case pin = "pin"
    case biometric = "biometric"
    case password = "password"
    
    public var displayName: String {
        switch self {
        case .none: return "None"
        case .pin: return "PIN"
        case .biometric: return "Biometric"
        case .password: return "Password"
        }
    }
}

/// Security threat types
public enum SecurityThreat: String, CaseIterable, Sendable {
    case jailbrokenDevice = "jailbrokenDevice"
    case debuggerAttached = "debuggerAttached"
    case suspiciousApp = "suspiciousApp"
    case networkAttack = "networkAttack"
    case integrityViolation = "integrityViolation"
    case unauthorizedAccess = "unauthorizedAccess"
    case dataLeakage = "dataLeakage"
    case maliciousCode = "maliciousCode"
    
    public nonisolated var displayName: String {
        switch self {
        case .jailbrokenDevice: return "Jailbroken/Rooted Device"
        case .debuggerAttached: return "Debugger Attached"
        case .suspiciousApp: return "Suspicious Application"  
        case .networkAttack: return "Network Attack"
        case .integrityViolation: return "Integrity Violation"
        case .unauthorizedAccess: return "Unauthorized Access"
        case .dataLeakage: return "Data Leakage"
        case .maliciousCode: return "Malicious Code"
        }
    }
    
    public var severity: ThreatSeverity {
        switch self {
        case .jailbrokenDevice, .debuggerAttached, .maliciousCode:
            return .critical
        case .suspiciousApp, .networkAttack, .integrityViolation:
            return .high
        case .unauthorizedAccess, .dataLeakage:
            return .medium
        }
    }
}

/// Threat severity levels
public enum ThreatSeverity: String, CaseIterable, Comparable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public static func < (lhs: ThreatSeverity, rhs: ThreatSeverity) -> Bool {
        let order: [ThreatSeverity] = [.low, .medium, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Error Types

/// Authentication-related errors
public enum AuthenticationError: Error, LocalizedError, Sendable, Codable, Equatable, Hashable {
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricLockout
    case userCancel
    case userFallback
    case systemCancel
    case passcodeNotSet
    case biometricFailure
    case invalidCredentials
    case sessionExpired
    case deviceCompromised
    case authenticationFailed(String)
    case setupRequired
    case weakCredentials
    case userAlreadyExists
    case userNotFound
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricNotEnrolled:
            return "No biometric authentication is enrolled"
        case .biometricLockout:
            return "Biometric authentication is locked due to too many failed attempts"
        case .userCancel:
            return "Authentication was cancelled by user"
        case .userFallback:
            return "User chose to use fallback authentication"
        case .systemCancel:
            return "Authentication was cancelled by system"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .biometricFailure:
            return "Biometric authentication failed"
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .sessionExpired:
            return "Authentication session has expired"
        case .deviceCompromised:
            return "Device security has been compromised"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .setupRequired:
            return "Authentication setup is required"
        case .weakCredentials:
            return "Credentials are too weak"
        case .userAlreadyExists:
            return "User already exists"
        case .userNotFound:
            return "User not found"
        case .unknown(let error):
            return "Unknown authentication error: \(error.localizedDescription)"
        }
    }
    
    /// Convenient access to error message
    public var errorMessage: String {
        return errorDescription ?? "Unknown error"
    }
    
    // MARK: - Codable Implementation
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .biometricNotAvailable:
            try container.encode("biometricNotAvailable", forKey: .type)
        case .biometricNotEnrolled:
            try container.encode("biometricNotEnrolled", forKey: .type)
        case .biometricLockout:
            try container.encode("biometricLockout", forKey: .type)
        case .userCancel:
            try container.encode("userCancel", forKey: .type)
        case .userFallback:
            try container.encode("userFallback", forKey: .type)
        case .systemCancel:
            try container.encode("systemCancel", forKey: .type)
        case .passcodeNotSet:
            try container.encode("passcodeNotSet", forKey: .type)
        case .biometricFailure:
            try container.encode("biometricFailure", forKey: .type)
        case .invalidCredentials:
            try container.encode("invalidCredentials", forKey: .type)
        case .sessionExpired:
            try container.encode("sessionExpired", forKey: .type)
        case .deviceCompromised:
            try container.encode("deviceCompromised", forKey: .type)
        case .setupRequired:
            try container.encode("setupRequired", forKey: .type)
        case .weakCredentials:
            try container.encode("weakCredentials", forKey: .type)
        case .userAlreadyExists:
            try container.encode("userAlreadyExists", forKey: .type)
        case .userNotFound:
            try container.encode("userNotFound", forKey: .type)
        case .unknown(let error):
            try container.encode("unknown", forKey: .type)
            try container.encode(error.localizedDescription, forKey: .message)
        case .authenticationFailed(_):
          try container.encode("unknown", forKey: .type)
          try container.encode(self.errorMessage, forKey: .message)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "biometricNotAvailable":
            self = .biometricNotAvailable
        case "biometricNotEnrolled":
            self = .biometricNotEnrolled
        case "biometricLockout":
            self = .biometricLockout
        case "userCancel":
            self = .userCancel
        case "userFallback":
            self = .userFallback
        case "systemCancel":
            self = .systemCancel
        case "passcodeNotSet":
            self = .passcodeNotSet
        case "biometricFailure":
            self = .biometricFailure
        case "invalidCredentials":
            self = .invalidCredentials
        case "sessionExpired":
            self = .sessionExpired
        case "deviceCompromised":
            self = .deviceCompromised
        case "setupRequired":
            self = .setupRequired
        case "weakCredentials":
            self = .weakCredentials
        case "userAlreadyExists":
            self = .userAlreadyExists
        case "userNotFound":
            self = .userNotFound
        case "unknown":
            let message = try container.decode(String.self, forKey: .message)
            self = .unknown(NSError(domain: "AuthenticationError", code: -1, userInfo: [NSLocalizedDescriptionKey: message]))
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown AuthenticationError type: \(type)"))
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case message
    }
}

// MARK: - Equatable & Hashable for AuthenticationError
extension AuthenticationError {
    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        switch (lhs, rhs) {
        case (.biometricNotAvailable, .biometricNotAvailable),
             (.biometricNotEnrolled, .biometricNotEnrolled),
             (.biometricLockout, .biometricLockout),
             (.userCancel, .userCancel),
             (.userFallback, .userFallback),
             (.systemCancel, .systemCancel),
             (.passcodeNotSet, .passcodeNotSet),
             (.biometricFailure, .biometricFailure),
             (.invalidCredentials, .invalidCredentials),
             (.sessionExpired, .sessionExpired),
             (.deviceCompromised, .deviceCompromised):
            return true
        case (.authenticationFailed(let lm), .authenticationFailed(let rm)):
            return lm == rm
        case (.unknown(let le), .unknown(let re)):
            return (le as NSError).domain == (re as NSError).domain && (le as NSError).code == (re as NSError).code && (le as NSError).localizedDescription == (re as NSError).localizedDescription
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .biometricNotAvailable:
            hasher.combine(0)
        case .biometricNotEnrolled:
            hasher.combine(1)
        case .biometricLockout:
            hasher.combine(2)
        case .userCancel:
            hasher.combine(3)
        case .userFallback:
            hasher.combine(4)
        case .systemCancel:
            hasher.combine(5)
        case .passcodeNotSet:
            hasher.combine(6)
        case .biometricFailure:
            hasher.combine(7)
        case .invalidCredentials:
            hasher.combine(8)
        case .sessionExpired:
            hasher.combine(9)
        case .deviceCompromised:
            hasher.combine(10)
        case .authenticationFailed(let message):
            hasher.combine(11)
            hasher.combine(message)
        case .setupRequired:
            hasher.combine(12)
        case .weakCredentials:
            hasher.combine(13)
        case .userAlreadyExists:
            hasher.combine(14)
        case .userNotFound:
            hasher.combine(15)
        case .unknown(let error):
            let nserr = error as NSError
            hasher.combine(16)
            hasher.combine(nserr.domain)
            hasher.combine(nserr.code)
            hasher.combine(nserr.localizedDescription)
        }
    }
}

/// Key management errors
public enum KeyManagementError: Error, LocalizedError, Sendable {
    case keyGenerationFailed(String)
    case keyStorageFailed(String)
    case keyRetrievalFailed(String)
    case keyDeletionFailed(String)
    case keyNotFound(String)
    case invalidKeyFormat
    case accessibilityNotSupported
    case keychainError(OSStatus)
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .keyGenerationFailed(let identifier):
            return "Failed to generate key: \(identifier)"
        case .keyStorageFailed(let identifier):
            return "Failed to store key: \(identifier)"
        case .keyRetrievalFailed(let identifier):
            return "Failed to retrieve key: \(identifier)"
        case .keyDeletionFailed(let identifier):
            return "Failed to delete key: \(identifier)"
        case .keyNotFound(let identifier):
            return "Key not found: \(identifier)"
        case .invalidKeyFormat:
            return "Invalid key format"
        case .accessibilityNotSupported:
            return "Key accessibility level not supported"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .unknown(let error):
            return "Unknown key management error: \(error.localizedDescription)"
        }
    }
}

/// Encryption-related errors
public enum EncryptionError: Error, LocalizedError, Sendable {
    case encryptionFailed(String)
    case decryptionFailed(String)
    case invalidKey
    case invalidData
    case keyDerivationFailed
    case algorithmNotSupported
    case insufficientKeySize
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .encryptionFailed(let reason):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason):
            return "Decryption failed: \(reason)"
        case .invalidKey:
            return "Invalid encryption key"
        case .invalidData:
            return "Invalid data for encryption/decryption"
        case .keyDerivationFailed:
            return "Key derivation failed"
        case .algorithmNotSupported:
            return "Encryption algorithm not supported"
        case .insufficientKeySize:
            return "Insufficient key size for algorithm"
        case .unknown(let error):
            return "Unknown encryption error: \(error.localizedDescription)"
        }
    }
}

/// Security validation errors
public enum SecurityValidationError: Error, LocalizedError, Sendable {
    case deviceCompromised(SecurityThreat)
    case integrityCheckFailed
    case certificateValidationFailed
    case networkSecurityFailure
    case suspiciousActivityDetected([SecurityThreat])
    case validationTimeout
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .deviceCompromised(let threat):
            return "Device compromised: \(threat.displayName)"
        case .integrityCheckFailed:
            return "App integrity check failed"
        case .certificateValidationFailed:
            return "Certificate validation failed"
        case .networkSecurityFailure:
            return "Network security failure"
        case .suspiciousActivityDetected(let threats):
            return "Suspicious activity detected: \(threats.map { $0.displayName }.joined(separator: ", "))"
        case .validationTimeout:
            return "Security validation timeout"
        case .unknown(let error):
            return "Unknown security validation error: \(error.localizedDescription)"
        }
    }
}

/// Security validation result with comprehensive details
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct ValidationResult: Sendable, Codable {
    public let isValid: Bool
    public let violations: [SecurityViolation]
    public let warnings: [String]
    public let validatedAt: Date
    public let riskScore: Double
    
    public init(isValid: Bool, violations: [SecurityViolation], warnings: [String], validatedAt: Date = Date(), riskScore: Double = 0.0) {
        self.isValid = isValid
        self.violations = violations
        self.warnings = warnings
        self.validatedAt = validatedAt
        self.riskScore = riskScore
    }
}

/// Security violations detected during validation
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public enum SecurityViolation: Sendable, Codable {
    case jailbreakDetected(String)
    case appIntegrityCompromised(String)
    case codeSigningInvalid(String)
    case runtimeCompromised(String)
    case tamperingDetected(String)
    case debuggingDetected(String)
    case codeInjectionDetected(String)
    case dynamicInstrumentationDetected(String)
    case sandboxEscapeDetected(String)
    case memoryManipulationDetected(String)
    case simulatorDetected
    case passcodeNotSet
    case biometricsDisabled
    case biometricsLocked
    case encryptionDisabled
    case outdatedOS(String)
    
    public nonisolated var displayName: String {
        switch self {
        case .jailbreakDetected(let details):
            return "Jailbreak Detected: \(details)"
        case .appIntegrityCompromised(let details):
            return "App Integrity Compromised: \(details)"
        case .codeSigningInvalid(let details):
            return "Code Signing Invalid: \(details)"
        case .runtimeCompromised(let details):
            return "Runtime Compromised: \(details)"
        case .tamperingDetected(let details):
            return "Tampering Detected: \(details)"
        case .debuggingDetected(let details):
            return "Debugging Detected: \(details)"
        case .codeInjectionDetected(let details):
            return "Code Injection Detected: \(details)"
        case .dynamicInstrumentationDetected(let details):
            return "Dynamic Instrumentation Detected: \(details)"
        case .sandboxEscapeDetected(let details):
            return "Sandbox Escape Detected: \(details)"
        case .memoryManipulationDetected(let details):
            return "Memory Manipulation Detected: \(details)"
        case .simulatorDetected:
            return "Simulator Environment Detected"
        case .passcodeNotSet:
            return "Device Passcode Not Set"
        case .biometricsDisabled:
            return "Biometrics Disabled"
        case .biometricsLocked:
            return "Biometrics Locked"
        case .encryptionDisabled:
            return "Device Encryption Disabled"
        case .outdatedOS(let version):
            return "Outdated OS Version: \(version)"
        }
    }
    
    public var severity: SecuritySeverity {
        switch self {
        case .jailbreakDetected, .codeInjectionDetected, .runtimeCompromised:
            return .critical
        case .appIntegrityCompromised, .codeSigningInvalid, .tamperingDetected:
            return .high
        case .debuggingDetected, .dynamicInstrumentationDetected, .sandboxEscapeDetected:
            return .high
        case .memoryManipulationDetected, .encryptionDisabled:
            return .medium
        case .simulatorDetected, .outdatedOS:
            return .low
        case .passcodeNotSet, .biometricsDisabled, .biometricsLocked:
            return .medium
        }
    }
}

/// Security violation severity levels
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public enum SecuritySeverity: String, CaseIterable, Sendable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
    
    public var color: String {
        switch self {
        case .low:
            return "green"
        case .medium:
            return "yellow"
        case .high:
            return "orange"
        case .critical:
            return "red"
        }
    }
}

// MARK: - Constants
