//
//  SecurityServiceAdapter.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Security Service Adapter
//

import Foundation

/// Adapter that provides unified security service interface
/// Integrates encryption, key management, and authentication services
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class SecurityServiceAdapter: SecurityServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    public let encryptionService: EncryptionServiceProtocol
    public let keyManager: SecureKeyManagementProtocol
    public let biometricAuth: BiometricAuthenticationProtocol
    public let authStateManager: AuthenticationStateProtocol
    public let validationService: SecurityValidationProtocol
    
    private var masterKey: SecureKey?
    
    // MARK: - Initialization
    
    public init(
        encryptionService: EncryptionServiceProtocol,
        keyManager: SecureKeyManagementProtocol,
        biometricAuth: BiometricAuthenticationProtocol,
        authStateManager: AuthenticationStateProtocol,
        validationService: SecurityValidationProtocol
    ) {
        self.encryptionService = encryptionService
        self.keyManager = keyManager
        self.biometricAuth = biometricAuth
        self.authStateManager = authStateManager
        self.validationService = validationService
        
        // Initialize master key
        Task { @MainActor in
            await self.initializeMasterKey()
        }
    }
    
    // MARK: - SecurityServiceProtocol Implementation
    
    public func encryptData(_ data: Data) async throws -> EncryptedData {
        guard let key = masterKey else {
            throw SecurityServiceError.masterKeyNotInitialized
        }
        
        return try await encryptionService.encrypt(data, using: key)
    }
    
    public func decryptData(_ encryptedData: EncryptedData) async throws -> Data {
        guard let key = masterKey else {
            throw SecurityServiceError.masterKeyNotInitialized
        }
        
        return try await encryptionService.decrypt(encryptedData, using: key)
    }
    
    public func authenticateUser(reason: String) async throws -> AuthenticationResult {
        return try await biometricAuth.authenticateWithBiometrics(reason: reason)
    }
    
    public func validateDeviceSecurity() async -> Bool {
        return await validationService.isAppIntegrityValid()
    }
    
    public func generateSecureKey(identifier: String) throws -> SecureKey {
        return try keyManager.generateSecureKey(
            identifier: identifier,
            accessibility: .secureEnclave
        )
    }
    
    // MARK: - Private Methods
    
    private func initializeMasterKey() async {
        do {
            // Try to retrieve existing master key
            if let existingKey = try keyManager.retrieveKey(identifier: SecurityConfiguration.MasterKeyIdentifier) {
                masterKey = existingKey
            } else {
                // Generate new master key
                let newKey = try keyManager.generateSecureKey(
                    identifier: SecurityConfiguration.MasterKeyIdentifier,
                    accessibility: .secureEnclave
                )
                masterKey = newKey
            }
        } catch {
            print(NSLocalizedString("master_key_init_failed", comment: "Failed to initialize master key: \(error)"))
        }
    }
}

// MARK: - Security Service Errors

public enum SecurityServiceError: Error, LocalizedError {
    case masterKeyNotInitialized
    case encryptionFailed
    case decryptionFailed
    case authenticationFailed
    case validationFailed
    
    public var errorDescription: String? {
        switch self {
        case .masterKeyNotInitialized:
            return NSLocalizedString(
                "master_key_not_initialized",
                comment: "Master encryption key not initialized"
            )
        case .encryptionFailed:
            return NSLocalizedString(
                "encryption_failed",
                comment: "Data encryption failed"
            )
        case .decryptionFailed:
            return NSLocalizedString(
                "decryption_failed",
                comment: "Data decryption failed"
            )
        case .authenticationFailed:
            return NSLocalizedString(
                "authentication_failed",
                comment: "User authentication failed"
            )
        case .validationFailed:
            return NSLocalizedString(
                "security_validation_failed",
                comment: "Security validation failed"
            )
        }
    }
}

// MARK: - Factory Extension

@available(iOS 18.6, macOS 15.6, *)
extension SecurityServiceAdapter {
    /// Create default security service
    public static func createDefault() -> SecurityServiceProtocol {
        let keyManager = SecureKeyManager()
        let encryptionService = EncryptionService(keyManager: keyManager)
        let biometricAuth = BiometricAuthenticationManager()
        let authStateManager = AuthenticationStateManager()
        let validationService = SecurityValidationService()
        
        return SecurityServiceAdapter(
            encryptionService: encryptionService,
            keyManager: keyManager,
            biometricAuth: biometricAuth,
            authStateManager: authStateManager,
            validationService: validationService
        )
    }
}

// MARK: - Security Configuration Extension

extension SecurityConfiguration {
    /// Master key identifier for app-wide encryption
    public static let MasterKeyIdentifier = "com.wealthwise.masterkey"
}
