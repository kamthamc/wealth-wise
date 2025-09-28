//
//  SecureSettingsStorage.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Secure Settings Storage
//

import Foundation
import Security
import Combine

/// High-level secure storage manager for user settings
/// Provides abstraction over KeychainManager with settings-specific functionality
@MainActor
public final class SecureSettingsStorage {
    
    // MARK: - Properties
    
    private let keychainManager: KeychainManager
    private let userDefaults: UserDefaults
    
    @Published public private(set) var isSecureStorageAvailable = true
    @Published public private(set) var lastSecurityCheck: Date?
    
    // MARK: - Storage Categories
    
    public enum StorageCategory {
        case privacy           // Privacy settings - always secure
        case biometric        // Biometric preferences - always secure
        case security         // Security settings - always secure
        case theme            // Theme preferences - standard
        case accessibility    // Accessibility settings - standard
        case localization     // Localization config - standard
        case general          // General settings - standard
        
        var requiresSecureStorage: Bool {
            switch self {
            case .privacy, .biometric, .security:
                return true
            case .theme, .accessibility, .localization, .general:
                return false
            }
        }
        
        var keychainService: String {
            switch self {
            case .privacy:
                return KeychainManager.ServiceIdentifiers.privacySettings
            case .biometric:
                return KeychainManager.ServiceIdentifiers.biometricSettings
            case .security:
                return KeychainManager.ServiceIdentifiers.securitySettings
            default:
                return KeychainManager.ServiceIdentifiers.userPreferences
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.keychainManager = KeychainManager()
        self.userDefaults = userDefaults
        
        // Perform initial security check
        Task {
            await performSecurityCheck()
        }
    }
    
    // MARK: - Storage Operations
    
    /// Store setting with automatic storage selection based on sensitivity
    public func store<T: Codable & Sendable>(_ object: T, key: String, category: StorageCategory) async throws {
        if category.requiresSecureStorage {
            try await storeSecurely(object, key: key, category: category)
        } else {
            try storeStandard(object, key: key)
        }
    }
    
    /// Retrieve setting with automatic storage selection
    public func retrieve<T: Codable & Sendable>(_ type: T.Type, key: String, category: StorageCategory) async throws -> T? {
        if category.requiresSecureStorage {
            return try await retrieveSecurely(type, key: key, category: category)
        } else {
            return try retrieveStandard(type, key: key)
        }
    }
    
    /// Delete setting from appropriate storage
    public func delete(key: String, category: StorageCategory) async throws {
        if category.requiresSecureStorage {
            try await deleteSecurely(key: key, category: category)
        } else {
            try deleteStandard(key: key)
        }
    }
    
    /// Check if setting exists
    public func exists(key: String, category: StorageCategory) async -> Bool {
        if category.requiresSecureStorage {
            return await existsSecurely(key: key, category: category)
        } else {
            return existsStandard(key: key)
        }
    }
    
    // MARK: - Secure Storage (Keychain)
    
    private func storeSecurely<T: Codable & Sendable>(_ object: T, key: String, category: StorageCategory) async throws {
        let categoryKeychain = KeychainManager(service: category.keychainService)
        
        do {
            try categoryKeychain.store(object, key: key)
        } catch {
            // If secure storage fails, don't fall back to insecure storage
            throw SecureStorageError.secureStorageFailed(error)
        }
    }
    
    private func retrieveSecurely<T: Codable & Sendable>(_ type: T.Type, key: String, category: StorageCategory) async throws -> T? {
        let categoryKeychain = KeychainManager(service: category.keychainService)
        
        do {
            return try categoryKeychain.retrieve(type, key: key)
        } catch {
            throw SecureStorageError.secureRetrievalFailed(error)
        }
    }
    
    private func deleteSecurely(key: String, category: StorageCategory) async throws {
        let categoryKeychain = KeychainManager(service: category.keychainService)
        
        do {
            try categoryKeychain.delete(key: key)
        } catch {
            throw SecureStorageError.secureDeletionFailed(error)
        }
    }
    
    private func existsSecurely(key: String, category: StorageCategory) async -> Bool {
        let categoryKeychain = KeychainManager(service: category.keychainService)
        return categoryKeychain.exists(key: key)
    }
    
    // MARK: - Standard Storage (UserDefaults)
    
    private func storeStandard<T: Codable>(_ object: T, key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(object)
        userDefaults.set(data, forKey: key)
    }
    
    private func retrieveStandard<T: Codable>(_ type: T.Type, key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(type, from: data)
    }
    
    private func deleteStandard(key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
    
    private func existsStandard(key: String) -> Bool {
        return userDefaults.data(forKey: key) != nil
    }
    
    // MARK: - Biometric-Protected Storage
    
    /// Store setting with biometric protection
    public func storeBiometricProtected<T: Codable & Sendable>(_ object: T, key: String, reason: String = "Access secure settings") async throws {
        let biometricKeychain = KeychainManager(service: KeychainManager.ServiceIdentifiers.biometricSettings)
        
        do {
            try biometricKeychain.storeBiometricProtected(object, key: key, reason: reason)
        } catch {
            throw SecureStorageError.biometricStorageFailed(error)
        }
    }
    
    /// Retrieve biometric-protected setting
    public func retrieveBiometricProtected<T: Codable & Sendable>(_ type: T.Type, key: String, reason: String = "Access secure settings") async throws -> T? {
        let biometricKeychain = KeychainManager(service: KeychainManager.ServiceIdentifiers.biometricSettings)
        
        do {
            return try await biometricKeychain.retrieveBiometricProtected(type, key: key, reason: reason)
        } catch {
            throw SecureStorageError.biometricRetrievalFailed(error)
        }
    }
    
    // MARK: - Batch Operations
    
    /// Store multiple settings efficiently
    public func storeBatch<T: Codable & Sendable>(_ items: [String: (T, StorageCategory)]) async throws {
        var secureItems: [StorageCategory: [String: Any]] = [:]
        var standardItems: [String: T] = [:]
        
        // Group items by storage type
        for (key, (value, category)) in items {
            if category.requiresSecureStorage {
                if secureItems[category] == nil {
                    secureItems[category] = [:]
                }
                secureItems[category]?[key] = value
            } else {
                standardItems[key] = value
            }
        }
        
        // Store secure items
        for (category, categoryItems) in secureItems {
            let categoryKeychain = KeychainManager(service: category.keychainService)
            for (key, value) in categoryItems {
                if let codableValue = value as? T {
                    try categoryKeychain.store(codableValue, key: key)
                }
            }
        }
        
        // Store standard items
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        for (key, value) in standardItems {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        }
    }
    
    // MARK: - Security Management
    
    /// Perform comprehensive security check
    public func performSecurityCheck() async {
        var securityIssues: [String] = []
        
        // Check keychain accessibility
        do {
            let testKey = "security_check_\(UUID().uuidString)"
            let testData = "test".data(using: .utf8)!
            
            try keychainManager.storeData(testData, key: testKey)
            let retrieved = try keychainManager.retrieveData(key: testKey)
            try keychainManager.deleteItem(key: testKey)
            
            if retrieved != testData {
                securityIssues.append("Keychain data integrity issue")
            }
            
        } catch {
            securityIssues.append("Keychain accessibility issue: \(error.localizedDescription)")
            isSecureStorageAvailable = false
        }
        
        // Check UserDefaults accessibility
        let testKey = "security_check_userdefaults"
        userDefaults.set("test", forKey: testKey)
        if userDefaults.string(forKey: testKey) != "test" {
            securityIssues.append("UserDefaults accessibility issue")
        }
        userDefaults.removeObject(forKey: testKey)
        
        lastSecurityCheck = Date()
        
        // Log security issues if any
        if !securityIssues.isEmpty {
            print("Security check found issues: \(securityIssues)")
        }
    }
    
    /// Migrate data from insecure to secure storage
    public func migrateToSecureStorage(keys: [String], fromCategory: StorageCategory, toCategory: StorageCategory) async throws {
        guard !fromCategory.requiresSecureStorage && toCategory.requiresSecureStorage else {
            throw SecureStorageError.invalidMigration
        }
        
        var migratedCount = 0
        var errors: [Error] = []
        
        for key in keys {
            do {
                // Try to retrieve from standard storage
                if let data = userDefaults.data(forKey: key) {
                    // Store in secure storage
                    let secureKeychain = KeychainManager(service: toCategory.keychainService)
                    try secureKeychain.storeData(data, key: key)
                    
                    // Remove from standard storage
                    userDefaults.removeObject(forKey: key)
                    migratedCount += 1
                }
            } catch {
                errors.append(error)
            }
        }
        
        if !errors.isEmpty {
            throw SecureStorageError.migrationPartialFailure(migratedCount, errors)
        }
    }
    
    // MARK: - Storage Analytics
    
    /// Get storage usage statistics
    public func getStorageStats() async throws -> StorageStats {
        var keychainStats: [StorageCategory: KeychainStorageStats] = [:]
        var userDefaultsSize = 0
        var userDefaultsCount = 0
        
        // Get keychain stats for each category
        for category in [StorageCategory.privacy, .biometric, .security] {
            let categoryKeychain = KeychainManager(service: category.keychainService)
            do {
                keychainStats[category] = try categoryKeychain.getStorageStats()
            } catch {
                print("Failed to get keychain stats for \(category): \(error)")
            }
        }
        
        // Estimate UserDefaults size (approximate)
        let userDefaultsDict = userDefaults.dictionaryRepresentation()
        for (key, value) in userDefaultsDict {
            if key.hasPrefix("com.wealthwise.") {
                userDefaultsCount += 1
                if let data = value as? Data {
                    userDefaultsSize += data.count
                } else {
                    // Rough estimation for other types
                    userDefaultsSize += 100
                }
            }
        }
        
        return StorageStats(
            keychainStats: keychainStats,
            userDefaultsSize: userDefaultsSize,
            userDefaultsCount: userDefaultsCount
        )
    }
    
    /// Clear all settings data
    public func clearAllData() async throws {
        var errors: [Error] = []
        
        // Clear keychain data for each category
        for category in [StorageCategory.privacy, .biometric, .security] {
            let categoryKeychain = KeychainManager(service: category.keychainService)
            do {
                try categoryKeychain.clearAll()
            } catch {
                errors.append(error)
            }
        }
        
        // Clear UserDefaults data
        let userDefaultsDict = userDefaults.dictionaryRepresentation()
        for key in userDefaultsDict.keys {
            if key.hasPrefix("com.wealthwise.") {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        if !errors.isEmpty {
            throw SecureStorageError.clearAllPartialFailure(errors)
        }
    }
}

// MARK: - Supporting Types

/// Storage statistics
public struct StorageStats {
    public let keychainStats: [SecureSettingsStorage.StorageCategory: KeychainStorageStats]
    public let userDefaultsSize: Int
    public let userDefaultsCount: Int
    
    public var totalKeychainSize: Int {
        keychainStats.values.reduce(0) { $0 + $1.totalSize }
    }
    
    public var totalKeychainItems: Int {
        keychainStats.values.reduce(0) { $0 + $1.itemCount }
    }
    
    public var totalSize: Int {
        totalKeychainSize + userDefaultsSize
    }
    
    public var totalItems: Int {
        totalKeychainItems + userDefaultsCount
    }
}

/// Secure storage specific errors
public enum SecureStorageError: LocalizedError {
    case secureStorageFailed(Error)
    case secureRetrievalFailed(Error)
    case secureDeletionFailed(Error)
    case biometricStorageFailed(Error)
    case biometricRetrievalFailed(Error)
    case invalidMigration
    case migrationPartialFailure(Int, [Error])
    case clearAllPartialFailure([Error])
    
    public var errorDescription: String? {
        switch self {
        case .secureStorageFailed(let error):
            return "Failed to store data securely: \(error.localizedDescription)"
        case .secureRetrievalFailed(let error):
            return "Failed to retrieve secure data: \(error.localizedDescription)"
        case .secureDeletionFailed(let error):
            return "Failed to delete secure data: \(error.localizedDescription)"
        case .biometricStorageFailed(let error):
            return "Failed to store biometric-protected data: \(error.localizedDescription)"
        case .biometricRetrievalFailed(let error):
            return "Failed to retrieve biometric-protected data: \(error.localizedDescription)"
        case .invalidMigration:
            return "Invalid migration: cannot migrate from secure to insecure storage"
        case .migrationPartialFailure(let count, let errors):
            return "Migration partially failed: \(count) items migrated, \(errors.count) errors"
        case .clearAllPartialFailure(let errors):
            return "Failed to clear all data: \(errors.count) errors occurred"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .biometricStorageFailed, .biometricRetrievalFailed:
            return "Check biometric authentication settings and try again"
        case .invalidMigration:
            return "Migration direction is not allowed for security reasons"
        case .migrationPartialFailure, .clearAllPartialFailure:
            return "Some operations failed - check individual error details"
        default:
            return "Please try again or contact support if the issue persists"
        }
    }
}