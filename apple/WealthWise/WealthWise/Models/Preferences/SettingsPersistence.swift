//
//  SettingsPersistence.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Settings Persistence Layer
//

import Foundation
import Security
import Combine

/// Centralized settings persistence layer with secure storage
/// Handles UserDefaults for non-sensitive data and Keychain for sensitive preferences
@MainActor
public final class SettingsPersistence {
    
    // MARK: - Constants
    
    private struct Keys {
        // UserDefaults Keys
        static let userSettings = "user_settings"
        static let localizationConfig = "localization_config"
        static let accessibilityPreferences = "accessibility_preferences"
        static let themePreference = "theme_preferences"
        static let settingsVersion = "settings_version"
        static let lastMigrationVersion = "last_migration_version"
        
        // Keychain Keys
        static let privacySettings = "privacy_settings"
        static let encryptionKeys = "encryption_keys"
        static let biometricSettings = "biometric_settings"
        static let securityTokens = "security_tokens"
    }
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let keychainService: String
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: Error?
    
    // MARK: - Initialization
    
    public init(
        userDefaults: UserDefaults = .standard,
        keychainService: String = "com.wealthwise.settings"
    ) {
        self.userDefaults = userDefaults
        self.keychainService = keychainService
        
        // Configure JSON coding
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
        
        self.jsonDecoder = JSONDecoder()
        self.jsonDecoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Public Interface
    
    /// Load complete user settings
    public func loadUserSettings() async throws -> UserSettings {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load main settings from UserDefaults
            var settings = try loadFromUserDefaults(UserSettings.self, key: Keys.userSettings) ?? UserSettings()
            
            // Load privacy settings from Keychain
            if let privacySettings = try loadFromKeychain(PrivacySettings.self, key: Keys.privacySettings) {
                settings.privacy = privacySettings
            }
            
            // Perform migration if needed
            if settings.requiresMigration {
                settings = try await migrateSettings(settings)
            }
            
            lastError = nil
            return settings
            
        } catch {
            lastError = error
            throw SettingsPersistenceError.loadFailure(error)
        }
    }
    
    /// Save complete user settings
    public func saveUserSettings(_ settings: UserSettings) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Update last modified timestamp
            settings.lastModified = Date()
            
            // Save main settings to UserDefaults
            try saveToUserDefaults(settings, key: Keys.userSettings)
            
            // Save privacy settings to Keychain (sensitive data)
            try saveToKeychain(settings.privacy, key: Keys.privacySettings)
            
            // Save individual components for easier access
            try saveToUserDefaults(settings.localization, key: Keys.localizationConfig)
            try saveToUserDefaults(settings.accessibility, key: Keys.accessibilityPreferences)
            try saveToUserDefaults(settings.theme, key: Keys.themePreference)
            
            lastError = nil
            
        } catch {
            lastError = error
            throw SettingsPersistenceError.saveFailure(error)
        }
    }
    
    /// Load specific settings component
    public func loadComponent<T: Codable>(_ type: T.Type, key: String, secure: Bool = false) throws -> T? {
        if secure {
            return try loadFromKeychain(type, key: key)
        } else {
            return try loadFromUserDefaults(type, key: key)
        }
    }
    
    /// Save specific settings component
    public func saveComponent<T: Codable>(_ component: T, key: String, secure: Bool = false) throws {
        if secure {
            try saveToKeychain(component, key: key)
        } else {
            try saveToUserDefaults(component, key: key)
        }
    }
    
    /// Delete all settings
    public func deleteAllSettings() throws {
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: Keys.userSettings)
        userDefaults.removeObject(forKey: Keys.localizationConfig)
        userDefaults.removeObject(forKey: Keys.accessibilityPreferences)
        userDefaults.removeObject(forKey: Keys.themePreference)
        userDefaults.removeObject(forKey: Keys.settingsVersion)
        userDefaults.removeObject(forKey: Keys.lastMigrationVersion)
        
        // Remove from Keychain
        try deleteFromKeychain(key: Keys.privacySettings)
        try deleteFromKeychain(key: Keys.encryptionKeys)
        try deleteFromKeychain(key: Keys.biometricSettings)
        try deleteFromKeychain(key: Keys.securityTokens)
    }
    
    /// Export settings to data (for backup)
    public func exportSettings() async throws -> Data {
        let settings = try await loadUserSettings()
        return try jsonEncoder.encode(settings)
    }
    
    /// Import settings from data (for restore)
    public func importSettings(from data: Data) async throws {
        let settings = try jsonDecoder.decode(UserSettings.self, from: data)
        try await saveUserSettings(settings)
    }
    
    // MARK: - UserDefaults Operations
    
    private func loadFromUserDefaults<T: Codable>(_ type: T.Type, key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try jsonDecoder.decode(type, from: data)
    }
    
    private func saveToUserDefaults<T: Codable>(_ object: T, key: String) throws {
        let data = try jsonEncoder.encode(object)
        userDefaults.set(data, forKey: key)
    }
    
    // MARK: - Keychain Operations
    
    private func loadFromKeychain<T: Codable>(_ type: T.Type, key: String) throws -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw SettingsPersistenceError.keychainDataCorrupted
            }
            return try jsonDecoder.decode(type, from: data)
            
        case errSecItemNotFound:
            return nil
            
        default:
            throw SettingsPersistenceError.keychainError(status)
        }
    }
    
    private func saveToKeychain<T: Codable>(_ object: T, key: String) throws {
        let data = try jsonEncoder.encode(object)
        
        // Try to update existing item first
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, create new one
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw SettingsPersistenceError.keychainError(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw SettingsPersistenceError.keychainError(updateStatus)
        }
    }
    
    private func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SettingsPersistenceError.keychainError(status)
        }
    }
    
    // MARK: - Migration
    
    private func migrateSettings(_ settings: UserSettings) async throws -> UserSettings {
        var migratedSettings = settings
        let currentVersion = UserSettings.currentSettingsVersion
        
        // Perform version-specific migrations
        for version in (settings.settingsVersion + 1)...currentVersion {
            migratedSettings = try await performMigration(migratedSettings, toVersion: version)
        }
        
        // Update version numbers
        migratedSettings.settingsVersion = currentVersion
        userDefaults.set(currentVersion, forKey: Keys.lastMigrationVersion)
        
        return migratedSettings
    }
    
    private func performMigration(_ settings: UserSettings, toVersion version: Int) async throws -> UserSettings {
        let migratedSettings = settings
        
        switch version {
        case 1:
            // Initial version - no migration needed
            break
            
        case 2:
            // Future migration example
            // migratedSettings = try await migrateToVersion2(settings)
            break
            
        default:
            // Handle unknown versions gracefully
            break
        }
        
        return migratedSettings
    }
    
    // MARK: - Validation
    
    /// Validate settings integrity
    public func validateSettings(_ settings: UserSettings) -> [String] {
        var issues: [String] = []
        
        // Validate core settings
        issues.append(contentsOf: settings.validateSettings())
        
        // Check for data consistency
        if settings.privacy.dataSyncEnabled && !settings.dataSyncEnabled {
            issues.append("Inconsistent data sync settings")
        }
        
        // Validate security settings alignment
        if settings.biometricAuthEnabled && !settings.privacy.biometricDataUsageConsent {
            issues.append("Biometric auth enabled without consent")
        }
        
        return issues
    }
    
    // MARK: - Utility Methods
    
    /// Get settings storage size
    public func getStorageSize() -> Int {
        var totalSize = 0
        
        // Calculate UserDefaults size
        let userDefaultsKeys = [Keys.userSettings, Keys.localizationConfig, Keys.accessibilityPreferences, Keys.themePreference]
        for key in userDefaultsKeys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += data.count
            }
        }
        
        // Note: Keychain item sizes are harder to calculate precisely
        // This is an approximation
        totalSize += 1024 // Estimated keychain overhead
        
        return totalSize
    }
    
    /// Check if settings exist
    public func settingsExist() -> Bool {
        return userDefaults.data(forKey: Keys.userSettings) != nil
    }
    
    /// Get last settings modification date
    public func getLastModificationDate() -> Date? {
        guard let settings = try? loadFromUserDefaults(UserSettings.self, key: Keys.userSettings) else {
            return nil
        }
        return settings.lastModified
    }
}

// MARK: - Error Types

public enum SettingsPersistenceError: LocalizedError {
    case loadFailure(Error)
    case saveFailure(Error)
    case keychainError(OSStatus)
    case keychainDataCorrupted
    case migrationFailure(Error)
    case validationFailure([String])
    
    public var errorDescription: String? {
        switch self {
        case .loadFailure(let error):
            return "Failed to load settings: \(error.localizedDescription)"
        case .saveFailure(let error):
            return "Failed to save settings: \(error.localizedDescription)"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .keychainDataCorrupted:
            return "Keychain data is corrupted"
        case .migrationFailure(let error):
            return "Settings migration failed: \(error.localizedDescription)"
        case .validationFailure(let issues):
            return "Settings validation failed: \(issues.joined(separator: ", "))"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .loadFailure:
            return "Try restarting the app or reset settings to defaults"
        case .saveFailure:
            return "Check available storage space and try again"
        case .keychainError:
            return "Check device passcode and biometric settings"
        case .keychainDataCorrupted:
            return "Reset security settings to restore functionality"
        case .migrationFailure:
            return "Settings will be reset to defaults"
        case .validationFailure:
            return "Check settings for invalid values"
        }
    }
}