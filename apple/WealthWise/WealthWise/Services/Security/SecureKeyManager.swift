//
//  SecureKeyManager.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Secure Key Management
//

import Foundation
import CryptoKit
import Security
import OSLog

// Import SecurityProtocols for SecureKey and SecurityLevel
import CryptoKit
import Combine
import LocalAuthentication

/// Secure key management implementation using iOS Keychain
/// Provides secure storage, retrieval, and management of cryptographic keys
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
@MainActor
public final class SecureKeyManager: SecureKeyManagementProtocol, ObservableObject, @unchecked Sendable {
    
    // MARK: - Properties
    private let service: String
    private let accessGroup: String?
    private let queue = DispatchQueue(label: "com.wealthwise.keymanager", qos: .userInitiated)
    
    @Published public private(set) var storedKeyIdentifiers: Set<String> = []
    
    // MARK: - Initialization
    
    public init(service: String = SecurityConfiguration.ServiceIdentifiers.main, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
        refreshStoredKeys()
    }
    
    // MARK: - SecureKeyManagementProtocol Implementation
    
    /// Generate a new secure cryptographic key
    public func generateSecureKey(identifier: String, accessibility: KeyAccessibility = .secureEnclave) throws -> SecureKey {
        // Generate key using CryptoKit
        let symmetricKey = SymmetricKey(size: .bits256)
        let keyData = symmetricKey.withUnsafeBytes { Data($0) }
        
        let secureKey = SecureKey(
            keyData: keyData,
            identifier: identifier,
            algorithm: .aes256,
            keySize: 256,
            createdAt: Date(),
            accessibility: accessibility,
            securityLevel: .maximum
        )
        
        // Store the key immediately
        try storeKey(secureKey, identifier: identifier, accessibility: accessibility)
        
        return secureKey
    }
    
    /// Store a key securely in the Keychain
    public func storeKey(_ key: SecureKey, identifier: String, accessibility: KeyAccessibility) throws {
        let query = buildKeychainQuery(identifier: identifier)
        
        // Delete existing key if present
        SecItemDelete(query as CFDictionary)
        
        // Prepare key metadata
        let keyMetadata = KeyMetadata(
            identifier: identifier,
            algorithm: key.algorithm,
            keySize: key.keySize,
            createdAt: key.createdAt,
            accessibility: accessibility,
            version: 1
        )
        
        guard let metadataData = try? JSONEncoder().encode(keyMetadata) else {
            throw KeyManagementError.keyStorageFailed("Failed to encode key metadata")
        }
        
        // Prepare storage attributes
        var attributes = query
    attributes[kSecValueData as String] = key.keyData
    attributes[kSecAttrAccessible as String] = accessibility.keychainAccessibility
    attributes[kSecAttrDescription as String] = "WealthWise Secure Key"
    attributes[kSecAttrComment as String] = metadataData
        
        // Add enhanced biometric protection for iOS 18.6+
        if accessibility == .biometricAny || accessibility == .biometricCurrentSet || accessibility == .secureEnclave || accessibility == .biometricOrWatch {
            var accessControl: SecAccessControl?
            
            let flags: SecAccessControlCreateFlags = {
                switch accessibility {
                case .biometricAny: return .biometryAny
                case .biometricCurrentSet: return .biometryCurrentSet
                case .secureEnclave: return [.privateKeyUsage, .biometryCurrentSet]
                case .biometricOrWatch: return [.biometryCurrentSet, .companion]
                default: return .biometryCurrentSet
                }
            }()
            
            accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                accessibility.keychainAccessibility,
                flags,
                nil
            )
            
            if let accessControl = accessControl {
                attributes[kSecAttrAccessControl as String] = accessControl
                attributes.removeValue(forKey: kSecAttrAccessible as String)
                
                // Enable Secure Enclave for maximum security on iOS 18.6+
                if accessibility == .secureEnclave {
                    attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
                }
            }
        }
        
        // Store in Keychain
        let result = SecItemAdd(attributes as CFDictionary, nil)
        
        guard result == errSecSuccess else {
            throw KeyManagementError.keychainError(result)
        }
        
        // Update stored keys set
        DispatchQueue.main.async { [weak self] in
            self?.storedKeyIdentifiers.insert(identifier)
        }
    }
    
    /// Retrieve a stored key from the Keychain
    public func retrieveKey(identifier: String) throws -> SecureKey? {
        var query = buildKeychainQuery(identifier: identifier)
    query[kSecReturnData as String] = true
    query[kSecReturnAttributes as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var item: CFTypeRef?
        let result = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard result == errSecSuccess else {
            if result == errSecItemNotFound {
                return nil
            }
            throw KeyManagementError.keychainError(result)
        }
        
        guard let existingItem = item as? [String: Any],
              let keyData = existingItem[kSecValueData as String] as? Data,
              let metadataData = existingItem[kSecAttrComment as String] as? Data else {
            throw KeyManagementError.keyRetrievalFailed("Invalid key format in Keychain")
        }
        
        // Decode metadata
        let metadata: KeyMetadata
        do {
            metadata = try JSONDecoder().decode(KeyMetadata.self, from: metadataData)
        } catch {
            // Fallback for keys without metadata - use enhanced defaults for iOS 18.6+
            metadata = KeyMetadata(
                identifier: identifier,
                algorithm: .aes256,
                keySize: 256,
                createdAt: Date(),
                accessibility: .secureEnclave,
                version: 1,
                securityLevel: .maximum
            )
        }
        
        return SecureKey(
            keyData: keyData,
            identifier: metadata.identifier,
            algorithm: metadata.algorithm,
            keySize: metadata.keySize,
            createdAt: metadata.createdAt,
            accessibility: metadata.accessibility,
            securityLevel: metadata.securityLevel ?? .maximum
        )
    }
    
    /// Delete a stored key from the Keychain
    public func deleteKey(identifier: String) throws {
        let query = buildKeychainQuery(identifier: identifier)
        let result = SecItemDelete(query as CFDictionary)
        
        guard result == errSecSuccess || result == errSecItemNotFound else {
            throw KeyManagementError.keychainError(result)
        }
        
        // Update stored keys set
        DispatchQueue.main.async { [weak self] in
            self?.storedKeyIdentifiers.remove(identifier)
        }
    }
    
    /// Check if a key exists in the Keychain
    public func keyExists(identifier: String) -> Bool {
        var query = buildKeychainQuery(identifier: identifier)
    query[kSecReturnData as String] = false
    query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        let result = SecItemCopyMatching(query as CFDictionary, nil)
        return result == errSecSuccess
    }
    
    /// Update key accessibility settings
    public func updateKeyAccessibility(identifier: String, accessibility: KeyAccessibility) throws {
        // Retrieve existing key
        guard let existingKey = try retrieveKey(identifier: identifier) else {
            throw KeyManagementError.keyNotFound(identifier)
        }
        
        // Create new key with updated accessibility
        let updatedKey = SecureKey(
            keyData: existingKey.keyData,
            identifier: existingKey.identifier,
            algorithm: existingKey.algorithm,
            keySize: existingKey.keySize,
            createdAt: existingKey.createdAt,
            accessibility: accessibility,
            securityLevel: existingKey.securityLevel
        )
        
        // Store updated key
        try storeKey(updatedKey, identifier: identifier, accessibility: accessibility)
    }
    
    // MARK: - Extended Key Management
    
    /// Generate key with custom algorithm and size
    public func generateKey(identifier: String, algorithm: KeyAlgorithm, accessibility: KeyAccessibility = .whenUnlockedThisDeviceOnly) throws -> SecureKey {
        let keyData: Data
        
        switch algorithm {
        case .aes128:
            keyData = SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }
        case .aes192:
            keyData = SymmetricKey(size: .bits192).withUnsafeBytes { Data($0) }
        case .aes256:
            keyData = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        case .p256:
            let privateKey = P256.KeyAgreement.PrivateKey()
            keyData = privateKey.rawRepresentation
        case .p384:
            let privateKey = P384.KeyAgreement.PrivateKey()
            keyData = privateKey.rawRepresentation
        case .p521:
            let privateKey = P521.KeyAgreement.PrivateKey()
            keyData = privateKey.rawRepresentation
        default:
            throw KeyManagementError.keyGenerationFailed("Unsupported algorithm: \(algorithm)")
        }
        
        let secureKey = SecureKey(
            keyData: keyData,
            identifier: identifier,
            algorithm: algorithm,
            keySize: algorithm.keySize,
            createdAt: Date(),
            accessibility: accessibility,
            securityLevel: .maximum
        )
        
        try storeKey(secureKey, identifier: identifier, accessibility: accessibility)
        return secureKey
    }
    
    /// List all stored key identifiers
    public func listStoredKeys() throws -> [String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var items: CFTypeRef?
        let result = SecItemCopyMatching(query as CFDictionary, &items)
        
        guard result == errSecSuccess else {
            if result == errSecItemNotFound {
                return []
            }
            throw KeyManagementError.keychainError(result)
        }
        
        guard let itemArray = items as? [[String: Any]] else {
            return []
        }
        
        let identifiers = itemArray.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.storedKeyIdentifiers = Set(identifiers)
        }
        
        return identifiers
    }
    
    /// Get key metadata without retrieving the actual key data
    public func getKeyMetadata(identifier: String) throws -> KeyMetadata? {
        var query = buildKeychainQuery(identifier: identifier)
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var item: CFTypeRef?
        let result = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard result == errSecSuccess else {
            if result == errSecItemNotFound {
                return nil
            }
            throw KeyManagementError.keychainError(result)
        }
        
        guard let existingItem = item as? [String: Any],
              let metadataData = existingItem[kSecAttrComment as String] as? Data else {
            return nil
        }
        
        return try JSONDecoder().decode(KeyMetadata.self, from: metadataData)
    }
    
    /// Backup key to encrypted data (for export)
    public func backupKey(identifier: String, encryptionKey: SecureKey) async throws -> Data {
        guard let key = try retrieveKey(identifier: identifier) else {
            throw KeyManagementError.keyNotFound(identifier)
        }
        
        let keyBackup = KeyBackup(
            secureKey: key,
            exportedAt: Date(),
            version: 1
        )
        
        let backupData = try JSONEncoder().encode(keyBackup)
        
        // Encrypt backup data
    let encryptionService = EncryptionService(keyManager: self)
    let encryptedBackup = try await encryptionService.encrypt(backupData, using: encryptionKey)
        
        return encryptedBackup.combinedData
    }
    
    /// Restore key from encrypted backup data
    public func restoreKey(from backupData: Data, encryptionKey: SecureKey, newIdentifier: String? = nil) async throws -> SecureKey {
        // Decrypt backup data
    let encryptionService = EncryptionService(keyManager: self)
        guard let encryptedData = EncryptedData(from: backupData) else {
            throw KeyManagementError.invalidKeyFormat
        }
        
    let decryptedData = try await encryptionService.decrypt(encryptedData, using: encryptionKey)
        
        // Decode key backup
        let keyBackup = try JSONDecoder().decode(KeyBackup.self, from: decryptedData)
        
        // Use new identifier if provided
        let identifier = newIdentifier ?? keyBackup.secureKey.identifier
        
        let restoredKey = SecureKey(
            keyData: keyBackup.secureKey.keyData,
            identifier: identifier,
            algorithm: keyBackup.secureKey.algorithm,
            keySize: keyBackup.secureKey.keySize,
            createdAt: Date(), // Set new creation date
            accessibility: keyBackup.secureKey.accessibility
        )
        
        try storeKey(restoredKey, identifier: identifier, accessibility: restoredKey.accessibility)
        return restoredKey
    }
    
    /// Rotate key (generate new key and update references)
    public func rotateKey(identifier: String) throws -> SecureKey {
        guard let existingKey = try retrieveKey(identifier: identifier) else {
            throw KeyManagementError.keyNotFound(identifier)
        }
        
        // Generate new key with same parameters
        let newKey = try generateKey(
            identifier: "\(identifier)-rotated-\(Date().timeIntervalSince1970)",
            algorithm: existingKey.algorithm,
            accessibility: existingKey.accessibility
        )
        
        // Delete old key
        try deleteKey(identifier: identifier)
        
        // Store new key with original identifier
        let rotatedKey = SecureKey(
            keyData: newKey.keyData,
            identifier: identifier,
            algorithm: newKey.algorithm,
            keySize: newKey.keySize,
            createdAt: Date(),
            accessibility: newKey.accessibility
        )
        
        try storeKey(rotatedKey, identifier: identifier, accessibility: rotatedKey.accessibility)
        return rotatedKey
    }
    
    /// Clear all stored keys (dangerous operation)
    public func clearAllKeys() throws {
        let identifiers = try listStoredKeys()
        
        for identifier in identifiers {
            try deleteKey(identifier: identifier)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.storedKeyIdentifiers.removeAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func buildKeychainQuery(identifier: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    private func refreshStoredKeys() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let keys = try self.listStoredKeys()
                self.storedKeyIdentifiers = Set(keys)
            } catch {
                print("⚠️ Failed to refresh stored keys: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

/// Key metadata for storage and management
public struct KeyMetadata: Codable, Sendable {
    public let identifier: String
    public let algorithm: KeyAlgorithm
    public let keySize: Int
    public let createdAt: Date
    public let accessibility: KeyAccessibility
    public let version: Int
    public let securityLevel: SecurityLevel?
    
    public init(identifier: String, algorithm: KeyAlgorithm, keySize: Int, createdAt: Date, accessibility: KeyAccessibility, version: Int, securityLevel: SecurityLevel? = .maximum) {
        self.identifier = identifier
        self.algorithm = algorithm
        self.keySize = keySize
        self.createdAt = createdAt
        self.accessibility = accessibility
        self.version = version
        self.securityLevel = securityLevel
    }
}

/// Key backup structure for export/import
public struct KeyBackup: Codable, Sendable {
    public let secureKey: SecureKey
    public let exportedAt: Date
    public let version: Int
    public let securityLevel: SecurityLevel
    
    public init(secureKey: SecureKey, exportedAt: Date, version: Int) {
        self.secureKey = secureKey
        self.exportedAt = exportedAt
        self.version = version
        self.securityLevel = .high
    }
}

// MARK: - SecureKey Codable Conformance

extension SecureKey: Codable {
    enum CodingKeys: String, CodingKey {
        case keyData, identifier, algorithm, keySize, createdAt, accessibility
    }
    
    public init(from decoder: Decoder) throws {
      let c = try decoder.container(keyedBy: CodingKeys.self)
      
      self.keyData       = try c.decode(Data.self, forKey: .keyData)
      self.identifier    = try c.decode(String.self, forKey: .identifier)
      self.algorithm     = try c.decode(KeyAlgorithm.self, forKey: .algorithm)
      self.keySize       = try c.decode(Int.self, forKey: .keySize)
      self.createdAt     = try c.decode(Date.self, forKey: .createdAt)
      self.accessibility = try c.decode(KeyAccessibility.self, forKey: .accessibility)
      self.securityLevel = .maximum // Default for backward compatibility
      self.keyDerivationContext = nil // Not encoded/decoded
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyData, forKey: .keyData)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(algorithm, forKey: .algorithm)
        try container.encode(keySize, forKey: .keySize)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(accessibility, forKey: .accessibility)
    }
}

// MARK: - Key Accessibility Codable Conformance

extension KeyAccessibility: Codable {}
extension KeyAlgorithm: Codable {}

// MARK: - Mock Key Manager for Testing

#if DEBUG
/// Mock implementation for testing and previews
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
@MainActor
public final class MockSecureKeyManager: SecureKeyManagementProtocol, ObservableObject, @unchecked Sendable {
    private var mockKeys: [String: SecureKey] = [:]
    @Published public private(set) var storedKeyIdentifiers: Set<String> = []
    
    public init() {}
    
    public func generateSecureKey(identifier: String, accessibility: KeyAccessibility) throws -> SecureKey {
        let keyData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let key = SecureKey(keyData: keyData, identifier: identifier, accessibility: accessibility, securityLevel: .high)
        mockKeys[identifier] = key
        storedKeyIdentifiers.insert(identifier)
        return key
    }
    
    public func storeKey(_ key: SecureKey, identifier: String, accessibility: KeyAccessibility) throws {
        mockKeys[identifier] = key
        storedKeyIdentifiers.insert(identifier)
    }
    
    public func retrieveKey(identifier: String) throws -> SecureKey? {
        return mockKeys[identifier]
    }
    
    public func deleteKey(identifier: String) throws {
        mockKeys.removeValue(forKey: identifier)
        storedKeyIdentifiers.remove(identifier)
    }
    
    public func keyExists(identifier: String) -> Bool {
        return mockKeys[identifier] != nil
    }
    
    public func updateKeyAccessibility(identifier: String, accessibility: KeyAccessibility) throws {
        guard let key = mockKeys[identifier] else {
            throw KeyManagementError.keyNotFound(identifier)
        }
        // Create new key with updated accessibility (SecureKey is immutable)
        let updatedKey = SecureKey(
            keyData: key.keyData,
            identifier: key.identifier,
            algorithm: key.algorithm,
            keySize: key.keySize,
            createdAt: key.createdAt,
            accessibility: accessibility,
            securityLevel: key.securityLevel
        )
        mockKeys[identifier] = updatedKey
    }
}
#endif
