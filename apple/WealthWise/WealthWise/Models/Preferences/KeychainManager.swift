//
//  KeychainManager.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Keychain Management
//

import Foundation
import Security
import LocalAuthentication

/// Keychain manager for secure storage of sensitive user preferences and settings
/// Integrates with existing security infrastructure while providing preferences-specific functionality
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
public final class KeychainManager: @unchecked Sendable {
    
    // MARK: - Constants
    
    public struct ServiceIdentifiers {
        public static let userPreferences = "com.wealthwise.preferences"
        public static let privacySettings = "com.wealthwise.privacy"
        public static let securitySettings = "com.wealthwise.security"
        public static let biometricSettings = "com.wealthwise.biometric"
        public static let encryptionKeys = "com.wealthwise.encryption"
    }
    
    // MARK: - Properties
    
    private let service: String
    private let accessGroup: String?
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    // MARK: - Initialization
    
    public init(service: String = ServiceIdentifiers.userPreferences, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
        
        // Configure JSON coding for preferences
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder.outputFormatting = .sortedKeys
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic Storage Methods
    
    /// Store codable object securely in keychain
    public func store<T: Codable & Sendable>(_ object: T, key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        let data = try jsonEncoder.encode(object)
        try storeData(data, key: key, accessibility: accessibility)
    }
    
    /// Retrieve codable object from keychain
    public func retrieve<T: Codable & Sendable>(_ type: T.Type, key: String) throws -> T? {
        guard let data = try retrieveData(key: key) else { return nil }
        return try jsonDecoder.decode(type, from: data)
    }
    
    /// Delete object from keychain
    public func delete(key: String) throws {
        try deleteItem(key: key)
    }
    
    /// Check if key exists in keychain
    public func exists(key: String) -> Bool {
        do {
            return try retrieveData(key: key) != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Data Storage Methods
    
    /// Store raw data in keychain
    public func storeData(_ data: Data, key: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        // Create base query
        var query = createBaseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = accessibility
        
        // Try to update existing item first
        let updateQuery = createBaseQuery(for: key)
        let updateAttributes: [String: Any] = [kSecValueData as String: data]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, create new one
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.additionFailed(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.updateFailed(updateStatus)
        }
    }
    
    /// Retrieve raw data from keychain
    public func retrieveData(key: String) throws -> Data? {
        var query = createBaseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.retrievalFailed(status)
        }
    }
    
    /// Delete item from keychain
    public func deleteItem(key: String) throws {
        let query = createBaseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status)
        }
    }
    
    // MARK: - Biometric-Protected Storage
    
    /// Store data with biometric protection
    public func storeBiometricProtected<T: Codable & Sendable>(_ object: T, key: String, reason: String) throws {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        
        // Create access control for biometric authentication
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            nil
        ) else {
            throw KeychainError.accessControlCreationFailed
        }
        
        let data = try jsonEncoder.encode(object)
        
        var query = createBaseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessControl as String] = accessControl
        query[kSecUseAuthenticationContext as String] = context
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.biometricStorageFailed(status)
        }
    }
    
    /// Retrieve biometric-protected data
    public func retrieveBiometricProtected<T: Codable & Sendable>(_ type: T.Type, key: String, reason: String) async throws -> T? {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        context.interactionNotAllowed = false
        
        var query = createBaseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = context
        
        return try await withCheckedThrowingContinuation { continuation in
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            switch status {
            case errSecSuccess:
                do {
                    guard let data = result as? Data else {
                        continuation.resume(throwing: KeychainError.dataCorrupted)
                        return
                    }
                    let object = try jsonDecoder.decode(type, from: data)
                    continuation.resume(returning: object)
                } catch {
                    continuation.resume(throwing: error)
                }
                
            case errSecItemNotFound:
                continuation.resume(returning: nil)
                
            case -128: // errSecUserCancel
                continuation.resume(throwing: KeychainError.userCancelled)
                
            case errSecAuthFailed:
                continuation.resume(throwing: KeychainError.authenticationFailed)
                
            default:
                continuation.resume(throwing: KeychainError.biometricRetrievalFailed(status))
            }
        }
    }
    
    // MARK: - Batch Operations
    
    /// Store multiple items in a single transaction
    public func storeBatch<T: Codable & Sendable>(_ items: [String: T], accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        for (key, value) in items {
            try store(value, key: key, accessibility: accessibility)
        }
    }
    
    /// Retrieve multiple items
    public func retrieveBatch<T: Codable & Sendable>(_ type: T.Type, keys: [String]) throws -> [String: T] {
        var results: [String: T] = [:]
        
        for key in keys {
            if let value = try retrieve(type, key: key) {
                results[key] = value
            }
        }
        
        return results
    }
    
    /// Delete multiple items
    public func deleteBatch(keys: [String]) throws {
        for key in keys {
            try delete(key: key)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get all stored keys for this service
    public func getAllKeys() throws -> [String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let items = result as? [[String: Any]] else { return [] }
            return items.compactMap { $0[kSecAttrAccount as String] as? String }
            
        case errSecItemNotFound:
            return []
            
        default:
            throw KeychainError.queryFailed(status)
        }
    }
    
    /// Clear all items for this service
    public func clearAll() throws {
        let query = createServiceQuery()
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.clearAllFailed(status)
        }
    }
    
    /// Get storage statistics
    public func getStorageStats() throws -> KeychainStorageStats {
        let keys = try getAllKeys()
        var totalSize = 0
        let itemCount = keys.count
        
        for key in keys {
            if let data = try retrieveData(key: key) {
                totalSize += data.count
            }
        }
        
        return KeychainStorageStats(itemCount: itemCount, totalSize: totalSize)
    }
    
    // MARK: - Private Helpers
    
    private func createBaseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    private func createServiceQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
}

// MARK: - Supporting Types

/// Keychain storage statistics
public struct KeychainStorageStats {
    public let itemCount: Int
    public let totalSize: Int
    
    public var averageItemSize: Int {
        guard itemCount > 0 else { return 0 }
        return totalSize / itemCount
    }
}

/// Keychain-specific errors
public enum KeychainError: LocalizedError {
    case additionFailed(OSStatus)
    case updateFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    case queryFailed(OSStatus)
    case clearAllFailed(OSStatus)
    case biometricStorageFailed(OSStatus)
    case biometricRetrievalFailed(OSStatus)
    case accessControlCreationFailed
    case dataCorrupted
    case userCancelled
    case authenticationFailed
    
    public var errorDescription: String? {
        switch self {
        case .additionFailed(let status):
            return "Failed to add item to keychain: \(status)"
        case .updateFailed(let status):
            return "Failed to update keychain item: \(status)"
        case .retrievalFailed(let status):
            return "Failed to retrieve item from keychain: \(status)"
        case .deletionFailed(let status):
            return "Failed to delete keychain item: \(status)"
        case .queryFailed(let status):
            return "Keychain query failed: \(status)"
        case .clearAllFailed(let status):
            return "Failed to clear keychain: \(status)"
        case .biometricStorageFailed(let status):
            return "Failed to store biometric-protected data: \(status)"
        case .biometricRetrievalFailed(let status):
            return "Failed to retrieve biometric-protected data: \(status)"
        case .accessControlCreationFailed:
            return "Failed to create access control for biometric protection"
        case .dataCorrupted:
            return "Keychain data is corrupted"
        case .userCancelled:
            return "User cancelled biometric authentication"
        case .authenticationFailed:
            return "Biometric authentication failed"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .userCancelled, .authenticationFailed:
            return "Please try again or use your device passcode"
        case .dataCorrupted:
            return "The stored data may need to be reset"
        case .accessControlCreationFailed:
            return "Check device biometric settings"
        default:
            return "Please try again or contact support if the problem persists"
        }
    }
}