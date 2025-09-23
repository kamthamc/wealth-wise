//
//  UserSettings.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Main Settings Container
//

import Foundation
import SwiftUI
import Combine

/// Main user settings container that consolidates all user preferences
/// Provides centralized access to localization, accessibility, theme, and privacy settings
@MainActor
@Observable
public final class UserSettings: Codable {
    
    // MARK: - Properties
    
    /// Current app version for migration purposes
    public var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    /// Settings version for migration tracking
    public var settingsVersion: Int = 1
    
    /// User's preferred primary currency
    public var primaryCurrency: SupportedCurrency = .INR
    
    /// User's preferred audience/market
    public var primaryAudience: PrimaryAudience = .indian
    
    /// Localization configuration
    public var localization: LocalizationConfig = LocalizationConfig()
    
    /// Accessibility preferences
    public var accessibility: AccessibilityPreferences = AccessibilityPreferences()
    
    /// Theme preferences
    public var theme: ThemePreferences = ThemePreferences()
    
    /// Privacy settings
    public var privacy: PrivacySettings = PrivacySettings()
    
    /// Auto-lock timeout in seconds (default: 15 minutes)
    public var autoLockTimeout: TimeInterval = 15 * 60
    
    /// Enable haptic feedback
    public var hapticFeedbackEnabled: Bool = true
    
    /// Enable biometric authentication
    public var biometricAuthEnabled: Bool = true
    
    /// Enable notifications
    public var notificationsEnabled: Bool = true
    
    /// Data sync preferences
    public var dataSyncEnabled: Bool = false
    
    /// Last settings sync timestamp
    public var lastSyncTimestamp: Date?
    
    /// Settings modification timestamp
    public var lastModified: Date = Date()
    
    // MARK: - Computed Properties
    
    /// Check if settings require migration
    public var requiresMigration: Bool {
        settingsVersion < UserSettings.currentSettingsVersion
    }
    
    /// Current settings version
    public static let currentSettingsVersion: Int = 1
    
    // MARK: - CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case appVersion
        case settingsVersion
        case primaryCurrency
        case primaryAudience
        case localization
        case accessibility
        case theme
        case privacy
        case autoLockTimeout
        case hapticFeedbackEnabled
        case biometricAuthEnabled
        case notificationsEnabled
        case dataSyncEnabled
        case lastSyncTimestamp
        case lastModified
    }
    
    // MARK: - Initialization
    
    public init() {
        setupDefaultSettings()
    }
    
    /// Initialize with default settings for specific audience
    public init(forAudience audience: PrimaryAudience) {
        self.primaryAudience = audience
        setupDefaultSettings()
        configureForAudience(audience)
    }
    
    // MARK: - Default Configuration
    
    private func setupDefaultSettings() {
        // Set default currency based on audience
        switch primaryAudience {
        case .indian:
            primaryCurrency = .INR
        case .american:
            primaryCurrency = .USD
        case .british:
            primaryCurrency = .GBP
        case .canadian:
            primaryCurrency = .CAD
        case .australian:
            primaryCurrency = .AUD
        case .singaporean:
            primaryCurrency = .SGD
        default:
            primaryCurrency = .USD
        }
        
        lastModified = Date()
    }
    
    private func configureForAudience(_ audience: PrimaryAudience) {
        localization.configureForAudience(audience)
        accessibility.configureForAudience(audience)
        theme.configureForAudience(audience)
    }
    
    // MARK: - Settings Validation
    
    /// Validate all settings for consistency
    public func validateSettings() -> [String] {
        var issues: [String] = []
        
        // Validate timeout values
        if autoLockTimeout < 60 || autoLockTimeout > 3600 {
            issues.append("Auto-lock timeout must be between 1 minute and 1 hour")
        }
        
        // Validate currency and audience consistency
        if !primaryCurrency.isValidForAudience(primaryAudience) {
            issues.append("Selected currency may not be optimal for the chosen audience")
        }
        
        // Validate sub-settings
        issues.append(contentsOf: localization.validate())
        issues.append(contentsOf: accessibility.validate())
        issues.append(contentsOf: theme.validate())
        issues.append(contentsOf: privacy.validate())
        
        return issues
    }
    
    // MARK: - Settings Updates
    
    /// Update a specific setting using KeyPath and mark as modified
    public func updateSettings<T>(_ keyPath: WritableKeyPath<UserSettings, T>, value: T) {
        switch keyPath {
        case \UserSettings.primaryCurrency:
            if let currencyValue = value as? SupportedCurrency {
                primaryCurrency = currencyValue
            }
        case \UserSettings.primaryAudience:
            if let audienceValue = value as? PrimaryAudience {
                primaryAudience = audienceValue
            }
        case \UserSettings.hapticFeedbackEnabled:
            if let boolValue = value as? Bool {
                hapticFeedbackEnabled = boolValue
            }
        case \UserSettings.biometricAuthEnabled:
            if let boolValue = value as? Bool {
                biometricAuthEnabled = boolValue
            }
        case \UserSettings.autoLockTimeout:
            if let timeValue = value as? TimeInterval {
                autoLockTimeout = timeValue
            }
        default:
            break // Ignore unsupported keypaths
        }
        lastModified = Date()
    }
    
    /// Update settings and mark as modified
    public func markAsModified() {
        lastModified = Date()
    }
    
    /// Reset to default settings
    public func resetToDefaults() {
        setupDefaultSettings()
        localization = LocalizationConfig()
        accessibility = AccessibilityPreferences()
        theme = ThemePreferences()
        privacy = PrivacySettings()
        configureForAudience(primaryAudience)
    }
    

    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(settingsVersion, forKey: .settingsVersion)
        try container.encode(primaryCurrency, forKey: .primaryCurrency)
        try container.encode(primaryAudience, forKey: .primaryAudience)
        try container.encode(localization, forKey: .localization)
        try container.encode(accessibility, forKey: .accessibility)
        try container.encode(theme, forKey: .theme)
        try container.encode(privacy, forKey: .privacy)
        try container.encode(autoLockTimeout, forKey: .autoLockTimeout)
        try container.encode(hapticFeedbackEnabled, forKey: .hapticFeedbackEnabled)
        try container.encode(biometricAuthEnabled, forKey: .biometricAuthEnabled)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(dataSyncEnabled, forKey: .dataSyncEnabled)
        try container.encode(lastSyncTimestamp, forKey: .lastSyncTimestamp)
        try container.encode(lastModified, forKey: .lastModified)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        settingsVersion = try container.decode(Int.self, forKey: .settingsVersion)
        primaryCurrency = try container.decode(SupportedCurrency.self, forKey: .primaryCurrency)
        primaryAudience = try container.decode(PrimaryAudience.self, forKey: .primaryAudience)
        localization = try container.decode(LocalizationConfig.self, forKey: .localization)
        accessibility = try container.decode(AccessibilityPreferences.self, forKey: .accessibility)
        theme = try container.decode(ThemePreferences.self, forKey: .theme)
        privacy = try container.decode(PrivacySettings.self, forKey: .privacy)
        autoLockTimeout = try container.decode(TimeInterval.self, forKey: .autoLockTimeout)
        hapticFeedbackEnabled = try container.decode(Bool.self, forKey: .hapticFeedbackEnabled)
        biometricAuthEnabled = try container.decode(Bool.self, forKey: .biometricAuthEnabled)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        dataSyncEnabled = try container.decode(Bool.self, forKey: .dataSyncEnabled)
        lastSyncTimestamp = try container.decodeIfPresent(Date.self, forKey: .lastSyncTimestamp)
        lastModified = try container.decode(Date.self, forKey: .lastModified)
    }
}

// MARK: - Extensions

extension SupportedCurrency {
    /// Check if currency is commonly used for a specific audience
    func isValidForAudience(_ audience: PrimaryAudience) -> Bool {
        switch audience {
        case .indian:
            return self == .INR || self == .USD || self == .EUR || self == .GBP
        case .american:
            return self == .USD || self == .CAD || self == .EUR || self == .GBP
        case .british:
            return self == .GBP || self == .USD || self == .EUR
        case .canadian:
            return self == .CAD || self == .USD
        case .australian:
            return self == .AUD || self == .USD || self == .NZD
        case .singaporean:
            return self == .SGD || self == .USD || self == .MYR
        default:
            return true // Allow flexibility for other audiences
        }
    }
}