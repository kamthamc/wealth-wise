//
//  SecurityConfiguration.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Configuration
//

import Foundation
import CryptoKit
import Security

// MARK: - Type Aliases for Compatibility

/// Key derivation function types
public enum KeyDerivationFunction: String, CaseIterable, Codable, Sendable {
    case pbkdf2 = "pbkdf2"
    case scrypt = "scrypt"
    case argon2id = "argon2id"
    
    public var displayName: String {
        switch self {
        case .pbkdf2: return "PBKDF2"
        case .scrypt: return "Scrypt"
        case .argon2id: return "Argon2id"
        }
    }
}

/// Security accessibility type alias
public typealias SecAccessibility = CFString

// MARK: - Security Accessibility Constants

public extension CFString {
    static let biometricCurrentSet: CFString = kSecAttrAccessibleBiometryCurrentSet
    static let biometricCurrentSetDevicePasscode: CFString = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    static let biometricCurrentSetApplicationPassword: CFString = kSecAttrAccessibleApplicationPassword
    static let biometricAny: CFString = kSecAttrAccessibleBiometryAny
    static let applicationPassword: CFString = kSecAttrAccessibleApplicationPassword
}

/// Encryption algorithm compatibility aliases
public enum EncryptionAlgorithm: String, CaseIterable, Codable, Sendable {
    case aes256gcm = "aes256gcm"
    case chacha20poly1305 = "chacha20poly1305"
    case postQuantumHybrid = "postQuantumHybrid"
}

/// Security level configuration structure
public struct SecurityLevelConfig: Sendable {
    let encryption: EncryptionAlgorithm
    let keyDerivation: KeyDerivationFunction
    let biometricRequired: Bool
    let secureEnclaveRequired: Bool
    let postQuantumEnabled: Bool
    let sessionTimeout: TimeInterval
}

/// Key accessibility type for cleaner API
public typealias KeyAccessibility = SecAccessibility

/// Comprehensive security configuration for iOS 18.6+ with Swift 6 features
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct SecurityConfiguration: Sendable {
    
    // MARK: - Session Management
    
    /// Session timeout duration (15 minutes for high security)
    public static let sessionTimeout: TimeInterval = 15 * 60
    
    /// Session refresh threshold (5 minutes before expiry)
    public static let sessionRefreshThreshold: TimeInterval = 5 * 60
    
    /// Maximum concurrent sessions per user
    public static let maxConcurrentSessions: Int = 3
    
    /// Session monitoring interval (1 second)
    public static let sessionMonitoringInterval: TimeInterval = 1.0
    
    /// Background session check interval (5 minutes)
    public static let backgroundSessionInterval: TimeInterval = 5 * 60
    
    // MARK: - Biometric Configuration
    
    /// Biometric authentication timeout (30 seconds)
    public static let biometricTimeout: TimeInterval = 30
    
    /// Maximum biometric failures before lockout
    public static let maxBiometricFailures: Int = 5
    
    /// Biometric lockout duration (5 minutes)
    public static let biometricLockoutDuration: TimeInterval = 5 * 60
    
    /// Fallback to device passcode after failures
    public static let fallbackToPasscodeAfterFailures: Int = 3
    
    // MARK: - Encryption Configuration
    
    /// AES encryption key size (256 bits)
    public static let aesKeySize: Int = 32
    
    /// GCM authentication tag size (16 bytes)
    public static let gcmTagSize: Int = 16
    
    /// Initialization vector size (12 bytes for GCM)
    public static let ivSize: Int = 12
    
    /// Salt size for key derivation (32 bytes)
    public static let saltSize: Int = 32
    
    /// PBKDF2 iteration count (600,000 for iOS 18.6+)
    public static let pbkdf2Iterations: Int = 600_000
    
    /// Scrypt parameters for high security
    public static let scryptN: Int = 32_768  // CPU/Memory cost
    public static let scryptR: Int = 8       // Block size
    public static let scryptP: Int = 1       // Parallelization
    
    /// Argon2id parameters (iOS 18.6+)
    public static let argon2Iterations: Int = 3
    public static let argon2MemorySize: Int = 64 * 1024  // 64 MB
    public static let argon2Parallelism: Int = 4
    
    // MARK: - Post-Quantum Cryptography
    
    /// Kyber key encapsulation mechanism levels
    public enum KyberLevel: Int, CaseIterable, Sendable {
        case kyber512 = 512
        case kyber768 = 768
        case kyber1024 = 1024
        
        public var securityLevel: Int {
            switch self {
            case .kyber512: return 1
            case .kyber768: return 3
            case .kyber1024: return 5
            }
        }
    }
    
    /// Dilithium digital signature levels
    public enum DilithiumLevel: Int, CaseIterable, Sendable {
        case dilithium2 = 2
        case dilithium3 = 3
        case dilithium5 = 5
        
        public var securityLevel: Int {
            return rawValue
        }
    }
    
    /// Default post-quantum configuration
    public static let defaultKyberLevel: KyberLevel = .kyber768
    public static let defaultDilithiumLevel: DilithiumLevel = .dilithium3
    
    // MARK: - Key Management
    
    /// Keychain service identifier
    public static let keychainService = "com.wealthwise.keychain"
    
    /// Key rotation interval (90 days)
    public static let keyRotationInterval: TimeInterval = 90 * 24 * 60 * 60
    
    /// Key derivation function preferences (ordered by preference)
    public static let keyDerivationPreferences: [KeyDerivationFunction] = [
        .argon2id,
        .scrypt,
        .pbkdf2
    ]
    
    /// Key accessibility levels for different security requirements
    public struct KeyAccessibility: Sendable {
        public static let standard: SecAccessibility = .biometricCurrentSet
        public static let high: SecAccessibility = .biometricCurrentSetDevicePasscode
        public static let quantum: SecAccessibility = .biometricCurrentSetApplicationPassword
        public static let background: SecAccessibility = .biometricAny
        public static let applicationProtected: SecAccessibility = .applicationPassword
    }
    
    /// Secure Enclave configuration
    public struct SecureEnclave: Sendable {
        public static let isRequired: Bool = true
        public static let fallbackAllowed: Bool = false
        public static let keySize: Int = 256
    }
    
    // MARK: - Key Identifiers
    
    public struct KeyIdentifiers: Sendable {
        // Core authentication keys
        public static let authenticationKey = "auth.primary.key"
        public static let sessionKey = "session.encryption.key"
        public static let biometricKey = "biometric.validation.key"
        
        // Encryption keys
        public static let dataEncryptionKey = "data.encryption.master"
        public static let backupEncryptionKey = "backup.encryption.key"
        public static let cloudSyncKey = "cloud.sync.encryption"
        
        // Post-quantum keys
        public static let kyberPublicKey = "kyber.public.key"
        public static let kyberPrivateKey = "kyber.private.key"
        public static let dilithiumPublicKey = "dilithium.public.key"
        public static let dilithiumPrivateKey = "dilithium.private.key"
        
        // Device-specific keys
        public static let deviceBindingKey = "device.binding.key"
        public static let hardwareKey = "hardware.secure.key"
        
        // Temporary keys
        public static let tempEncryptionKey = "temp.encryption.key"
        public static let exchangeKey = "key.exchange.temp"
    }
    
    // MARK: - Security Levels
    
    /// Security level thresholds and requirements
    public struct SecurityLevelRequirements: Sendable {
        public static let minimal = SecurityLevelConfig(
            encryption: .aes256gcm,
            keyDerivation: .pbkdf2,
            biometricRequired: false,
            secureEnclaveRequired: false,
            postQuantumEnabled: false,
            sessionTimeout: 30 * 60 // 30 minutes
        )
        
        public static let standard = SecurityLevelConfig(
            encryption: .aes256gcm,
            keyDerivation: .scrypt,
            biometricRequired: true,
            secureEnclaveRequired: true,
            postQuantumEnabled: false,
            sessionTimeout: 15 * 60 // 15 minutes
        )
        
        public static let high = SecurityLevelConfig(
            encryption: .aes256gcm,
            keyDerivation: .argon2id,
            biometricRequired: true,
            secureEnclaveRequired: true,
            postQuantumEnabled: true,
            sessionTimeout: 10 * 60 // 10 minutes
        )
        
        public static let maximum = SecurityLevelConfig(
            encryption: .chacha20poly1305,
            keyDerivation: .argon2id,
            biometricRequired: true,
            secureEnclaveRequired: true,
            postQuantumEnabled: true,
            sessionTimeout: 5 * 60 // 5 minutes
        )
        
        public static let quantum = SecurityLevelConfig(
            encryption: .postQuantumHybrid,
            keyDerivation: .argon2id,
            biometricRequired: true,
            secureEnclaveRequired: true,
            postQuantumEnabled: true,
            sessionTimeout: 3 * 60 // 3 minutes
        )
    }
    
    // MARK: - Network Security
    
    /// TLS and network security configuration
    public struct NetworkSecurity: Sendable {
        public static let minTLSVersion: tls_protocol_version_t = .TLSv13
        public static let requireCertificatePinning: Bool = true
        public static let allowSelfSignedCertificates: Bool = false
        public static let networkTimeout: TimeInterval = 30
        public static let maxRetries: Int = 3
        
        /// Cipher suites for TLS 1.3 (iOS 18.6+)
        public static let preferredCipherSuites: [String] = [
            "TLS_AES_256_GCM_SHA384",
            "TLS_CHACHA20_POLY1305_SHA256",
            "TLS_AES_128_GCM_SHA256"
        ]
    }
    
    // MARK: - Device Security
    
    /// Device security validation requirements
    public struct DeviceSecurity: Sendable {
        public static let requireJailbreakDetection: Bool = true
        public static let requireDebuggerDetection: Bool = true
        public static let requireAppIntegrityCheck: Bool = true
        public static let allowSimulator: Bool = false
        public static let requirePasscodeSet: Bool = true
        public static let requireBiometricsEnabled: Bool = false
        public static let requireSecureBootVerification: Bool = true
    }
    
    // MARK: - Audit and Logging
    
    /// Security audit and logging configuration
    public struct AuditConfiguration: Sendable {
        public static let enableSecurityLogging: Bool = true
        public static let logEncryptionEnabled: Bool = true
        public static let maxLogFileSize: Int = 10 * 1024 * 1024 // 10 MB
        public static let logRetentionDays: Int = 90
        public static let enableRealTimeMonitoring: Bool = true
        
        /// Events to log
        public static let loggedEvents: Set<String> = [
            "authentication_attempt",
            "authentication_success",
            "authentication_failure",
            "session_created",
            "session_expired",
            "biometric_enrollment",
            "key_rotation",
            "security_violation",
            "app_launch",
            "app_background"
        ]
    }
    
    // MARK: - Performance Tuning
    
    /// Performance optimization settings for iOS 18.6+
    public struct Performance: Sendable {
        public static let enableHardwareAcceleration: Bool = true
        public static let useConcurrentProcessing: Bool = true
        public static let maxConcurrentOperations: Int = 4
        public static let cacheEncryptionKeys: Bool = true
        public static let keyDerivationCacheTimeout: TimeInterval = 5 * 60
        
        /// Memory management
        public static let enableMemoryPressureMonitoring: Bool = true
        public static let clearSensitiveDataOnMemoryWarning: Bool = true
        public static let maxMemoryUsage: Int = 50 * 1024 * 1024 // 50 MB
    }
    
    // MARK: - Feature Flags
    
    /// Feature flags for progressive enhancement
    public struct FeatureFlags: Sendable {
        public static let enablePostQuantumCrypto: Bool = true
        public static let enableVoiceAuthentication: Bool = true
        public static let enablePasskeySupport: Bool = true
        public static let enableAppleWatchUnlock: Bool = true
        public static let enableQuantumKeyDistribution: Bool = false
        public static let enableAdvancedThreatDetection: Bool = true
        public static let enableZeroKnowledgeProofs: Bool = false
        public static let enableHomomorphicEncryption: Bool = false
    }
    
    // MARK: - Error Handling
    
    /// Security error handling configuration
    public struct ErrorHandling: Sendable {
        public static let maxRetryAttempts: Int = 3
        public static let retryDelay: TimeInterval = 1.0
        public static let exponentialBackoff: Bool = true
        public static let maxBackoffDelay: TimeInterval = 30.0
        public static let logAllErrors: Bool = true
        public static let notifyOnCriticalErrors: Bool = true
    }
}

// MARK: - Supporting Configuration Types

/// Security level configuration structure
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct SecurityLevelConfig: Sendable {
    public let encryption: EncryptionAlgorithm
    public let keyDerivation: KeyDerivationFunction
    public let biometricRequired: Bool
    public let secureEnclaveRequired: Bool
    public let postQuantumEnabled: Bool
    public let sessionTimeout: TimeInterval
    
    public init(
        encryption: EncryptionAlgorithm,
        keyDerivation: KeyDerivationFunction,
        biometricRequired: Bool,
        secureEnclaveRequired: Bool,
        postQuantumEnabled: Bool,
        sessionTimeout: TimeInterval
    ) {
        self.encryption = encryption
        self.keyDerivation = keyDerivation
        self.biometricRequired = biometricRequired
        self.secureEnclaveRequired = secureEnclaveRequired
        self.postQuantumEnabled = postQuantumEnabled
        self.sessionTimeout = sessionTimeout
    }
}

/// Device capability detection for iOS 18.6+
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct DeviceCapabilities: Sendable {
    
    /// Check if device supports Secure Enclave
    public static var hasSecureEnclave: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return SecureEnclave.isAvailable
        #endif
    }
    
    /// Check if device supports Neural Engine for on-device ML
    public static var hasNeuralEngine: Bool {
        #if os(iOS)
        if #available(iOS 18.6, *) {
            return ProcessInfo.processInfo.machineHardwareName.contains("iPhone") &&
                   ProcessInfo.processInfo.machineHardwareName.compare("iPhone12,1", options: .numeric) != .orderedAscending
        }
        #endif
        return false
    }
    
    /// Check for post-quantum cryptography support
    public static var supportsPostQuantumCrypto: Bool {
        return hasSecureEnclave && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 18
    }
    
    /// Available biometric types on current device
    public static var availableBiometricTypes: Set<BiometricType> {
        var types: Set<BiometricType> = []
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                types.insert(.faceID)
            case .touchID:
                types.insert(.touchID)
            case .opticID:
                if #available(iOS 18.6, *) {
                    types.insert(.opticID)
                }
            @unknown default:
                break
            }
        }
        
        // Check for voice authentication capability (iOS 18.6+)
        if #available(iOS 18.6, *), hasNeuralEngine {
            types.insert(.voiceID)
        }
        
        return types
    }
}

/// Hardware security module integration
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public struct HardwareSecurityModule: Sendable {
    
    /// Check if HSM is available
    public static var isAvailable: Bool {
        return DeviceCapabilities.hasSecureEnclave
    }
    
    /// HSM key generation parameters
    public static var keyGenerationParameters: [String: Any] {
        return [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrAccessControl as String: SecAccessControlCreateWithFlags(
                    nil,
                    SecurityConfiguration.KeyAccessibility.quantum,
                    [.privateKeyUsage, .biometryCurrentSet],
                    nil
                )!,
                kSecAttrIsPermanent as String: true
            ]
        ]
    }
}

extension ProcessInfo {
    var machineHardwareName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
    }
}