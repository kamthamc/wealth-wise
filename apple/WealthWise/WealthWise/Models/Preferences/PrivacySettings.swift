//
//  PrivacySettings.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Privacy and Security Settings
//

import Foundation
import SwiftUI

/// Privacy and security settings for data protection and user control
/// Implements comprehensive privacy controls and GDPR compliance
@MainActor
@Observable
public final class PrivacySettings: Codable {
    
    // MARK: - Data Collection Settings
    
    /// Allow analytics data collection
    public var analyticsEnabled: Bool = false
    
    /// Allow crash reporting
    public var crashReportingEnabled: Bool = true
    
    /// Allow usage statistics collection
    public var usageStatisticsEnabled: Bool = false
    
    /// Allow performance monitoring
    public var performanceMonitoringEnabled: Bool = false
    
    /// Share diagnostic data with developers
    public var diagnosticDataSharingEnabled: Bool = false
    
    // MARK: - Data Processing Settings
    
    /// Data processing consent given
    public var dataProcessingConsent: Bool = false
    
    /// Marketing communications consent
    public var marketingConsent: Bool = false
    
    /// Third-party data sharing consent
    public var thirdPartyDataSharingConsent: Bool = false
    
    /// Personalization consent (for recommendations)
    public var personalizationConsent: Bool = false
    
    /// Cross-border data transfer consent
    public var crossBorderDataTransferConsent: Bool = false
    
    // MARK: - Data Retention Settings
    
    /// Automatic data cleanup enabled
    public var automaticDataCleanupEnabled: Bool = true
    
    /// Data retention period in days
    public var dataRetentionPeriodDays: Int = 365
    
    /// Delete inactive data automatically
    public var deleteInactiveDataEnabled: Bool = true
    
    /// Inactive data threshold in days
    public var inactiveDataThresholdDays: Int = 90
    
    /// Backup data retention period
    public var backupRetentionPeriodDays: Int = 30
    
    // MARK: - Security Settings
    
    /// Enable data encryption at rest
    public var encryptionAtRestEnabled: Bool = true
    
    /// Enable data encryption in transit
    public var encryptionInTransitEnabled: Bool = true
    
    /// Security level preference
    public var securityLevel: PrivacySecurityLevel = .standard
    
    /// Biometric data usage consent
    public var biometricDataUsageConsent: Bool = false
    
    /// Location data usage consent
    public var locationDataUsageConsent: Bool = false
    
    // MARK: - Sharing and Sync Settings
    
    /// Allow data synchronization across devices
    public var dataSyncEnabled: Bool = false
    
    /// Cloud backup enabled
    public var cloudBackupEnabled: Bool = false
    
    /// Share data with family members
    public var familySharingEnabled: Bool = false
    
    /// Allow export to external services
    public var externalServiceExportEnabled: Bool = false
    
    /// Third-party integrations enabled
    public var thirdPartyIntegrationsEnabled: Bool = false
    
    // MARK: - Communication Settings
    
    /// In-app notifications enabled
    public var inAppNotificationsEnabled: Bool = true
    
    /// Push notifications enabled
    public var pushNotificationsEnabled: Bool = true
    
    /// Email communications enabled
    public var emailCommunicationsEnabled: Bool = false
    
    /// SMS notifications enabled
    public var smsNotificationsEnabled: Bool = false
    
    /// Marketing notifications enabled
    public var marketingNotificationsEnabled: Bool = false
    
    // MARK: - Tracking and Cookies
    
    /// Allow functional cookies
    public var functionalCookiesEnabled: Bool = true
    
    /// Allow analytics cookies
    public var analyticsCookiesEnabled: Bool = false
    
    /// Allow marketing cookies
    public var marketingCookiesEnabled: Bool = false
    
    /// Allow cross-site tracking
    public var crossSiteTrackingEnabled: Bool = false
    
    /// Advertising identifier usage
    public var advertisingIdentifierEnabled: Bool = false
    
    // MARK: - Compliance Settings
    
    /// GDPR compliance region
    public var gdprRegion: Bool = false
    
    /// CCPA compliance region
    public var ccpaRegion: Bool = false
    
    /// Age verification completed
    public var ageVerificationCompleted: Bool = false
    
    /// Minimum age for service
    public var minimumAge: Int = 13
    
    /// Parental consent required
    public var parentalConsentRequired: Bool = false
    
    // MARK: - Audit and Logging
    
    /// Privacy settings version
    public var privacySettingsVersion: Int = 1
    
    /// Consent timestamp
    public var consentTimestamp: Date?
    
    /// Last privacy update date
    public var lastPrivacyUpdateDate: Date = Date()
    
    /// Privacy policy version accepted
    public var privacyPolicyVersionAccepted: String?
    
    /// Terms of service version accepted
    public var termsOfServiceVersionAccepted: String?
    
    // MARK: - Initialization
    
    public init() {
        configureDefaults()
    }
    
    public init(forRegion region: PrivacyRegion) {
        configureDefaults()
        configureForRegion(region)
    }
    
    // MARK: - Configuration
    
    private func configureDefaults() {
        // Set conservative defaults for privacy
        analyticsEnabled = false
        crashReportingEnabled = true // Essential for app stability
        usageStatisticsEnabled = false
        performanceMonitoringEnabled = false
        diagnosticDataSharingEnabled = false
        
        // Security defaults
        encryptionAtRestEnabled = true
        encryptionInTransitEnabled = true
        securityLevel = .high
        
        // Communication defaults
        inAppNotificationsEnabled = true
        pushNotificationsEnabled = true
        
        // Essential cookies only
        functionalCookiesEnabled = true
        analyticsCookiesEnabled = false
        marketingCookiesEnabled = false
        
        lastPrivacyUpdateDate = Date()
    }
    
    public func configureForRegion(_ region: PrivacyRegion) {
        switch region {
        case .europeanUnion:
            gdprRegion = true
            // GDPR requires explicit consent for all non-essential processing
            analyticsEnabled = false
            usageStatisticsEnabled = false
            marketingConsent = false
            thirdPartyDataSharingConsent = false
            crossBorderDataTransferConsent = false
            analyticsCookiesEnabled = false
            marketingCookiesEnabled = false
            
        case .california:
            ccpaRegion = true
            // CCPA allows opt-out approach
            thirdPartyDataSharingConsent = false
            crossSiteTrackingEnabled = false
            advertisingIdentifierEnabled = false
            
        case .canada:
            // PIPEDA compliance
            dataProcessingConsent = true
            crossBorderDataTransferConsent = false
            
        case .australia:
            // Privacy Act compliance
            dataProcessingConsent = true
            crossBorderDataTransferConsent = false
            
        case .india:
            // PDPB (proposed) compliance
            dataProcessingConsent = true
            crossBorderDataTransferConsent = false
            
        case .singapore:
            // PDPA compliance
            dataProcessingConsent = true
            marketingConsent = false
            
        case .unitedKingdom:
            // UK GDPR compliance
            gdprRegion = true
            analyticsEnabled = false
            marketingConsent = false
            
        case .other:
            // Conservative defaults
            break
        }
    }
    
    // MARK: - Consent Management
    
    /// Record user consent with timestamp
    public func recordConsent() {
        consentTimestamp = Date()
        lastPrivacyUpdateDate = Date()
    }
    
    /// Check if consent is still valid
    public func isConsentValid() -> Bool {
        guard let consentDate = consentTimestamp else { return false }
        
        // Consent valid for 12 months (can be adjusted based on regulation)
        let expiryDate = Calendar.current.date(byAdding: .year, value: 1, to: consentDate)
        return Date() < (expiryDate ?? Date())
    }
    
    /// Withdraw all consent
    public func withdrawAllConsent() {
        analyticsEnabled = false
        usageStatisticsEnabled = false
        performanceMonitoringEnabled = false
        diagnosticDataSharingEnabled = false
        dataProcessingConsent = false
        marketingConsent = false
        thirdPartyDataSharingConsent = false
        personalizationConsent = false
        crossBorderDataTransferConsent = false
        biometricDataUsageConsent = false
        locationDataUsageConsent = false
        dataSyncEnabled = false
        cloudBackupEnabled = false
        familySharingEnabled = false
        externalServiceExportEnabled = false
        thirdPartyIntegrationsEnabled = false
        emailCommunicationsEnabled = false
        smsNotificationsEnabled = false
        marketingNotificationsEnabled = false
        analyticsCookiesEnabled = false
        marketingCookiesEnabled = false
        crossSiteTrackingEnabled = false
        advertisingIdentifierEnabled = false
        
        recordConsent()
    }
    
    // MARK: - Data Rights
    
    /// Get summary of collected data types
    public func getDataCollectionSummary() -> [String] {
        var dataTypes: [String] = []
        
        if analyticsEnabled { dataTypes.append("Usage Analytics") }
        if usageStatisticsEnabled { dataTypes.append("Usage Statistics") }
        if performanceMonitoringEnabled { dataTypes.append("Performance Data") }
        if crashReportingEnabled { dataTypes.append("Crash Reports") }
        if biometricDataUsageConsent { dataTypes.append("Biometric Data") }
        if locationDataUsageConsent { dataTypes.append("Location Data") }
        if functionalCookiesEnabled { dataTypes.append("Functional Cookies") }
        if analyticsCookiesEnabled { dataTypes.append("Analytics Cookies") }
        if marketingCookiesEnabled { dataTypes.append("Marketing Cookies") }
        
        return dataTypes
    }
    
    /// Check if user has right to data portability
    public var hasDataPortabilityRight: Bool {
        return gdprRegion || ccpaRegion
    }
    
    /// Check if user has right to be forgotten
    public var hasRightToBeForgotten: Bool {
        return gdprRegion
    }
    
    // MARK: - Validation
    
    public func validate() -> [String] {
        var issues: [String] = []
        
        // Validate age requirements
        if minimumAge < 13 {
            issues.append("Minimum age cannot be less than 13")
        }
        
        // Validate data retention periods
        if dataRetentionPeriodDays < 1 || dataRetentionPeriodDays > 3650 {
            issues.append("Data retention period must be between 1 and 3650 days")
        }
        
        if inactiveDataThresholdDays < 1 || inactiveDataThresholdDays > dataRetentionPeriodDays {
            issues.append("Inactive data threshold must be less than retention period")
        }
        
        // Validate backup retention
        if backupRetentionPeriodDays < 1 || backupRetentionPeriodDays > 365 {
            issues.append("Backup retention period must be between 1 and 365 days")
        }
        
        // Check for conflicting settings
        if marketingNotificationsEnabled && !marketingConsent {
            issues.append("Marketing notifications enabled without marketing consent")
        }
        
        if thirdPartyIntegrationsEnabled && !thirdPartyDataSharingConsent {
            issues.append("Third-party integrations enabled without consent")
        }
        
        return issues
    }
}

// MARK: - Supporting Types

/// Security level preferences
public enum PrivacySecurityLevel: String, CaseIterable, Codable {
    case basic = "basic"
    case standard = "standard"
    case high = "high"
    case maximum = "maximum"
    
    public var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .standard: return "Standard"
        case .high: return "High"
        case .maximum: return "Maximum"
        }
    }
    
    public var description: String {
        switch self {
        case .basic: return "Basic encryption and security measures"
        case .standard: return "Standard encryption with biometric authentication"
        case .high: return "High-level encryption with enhanced security features"
        case .maximum: return "Maximum security with all advanced features enabled"
        }
    }
}

/// Privacy regulation regions
public enum PrivacyRegion: String, CaseIterable, Codable {
    case europeanUnion = "eu"
    case california = "ca_us"
    case canada = "ca"
    case australia = "au"
    case india = "in"
    case singapore = "sg"
    case unitedKingdom = "uk"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .europeanUnion: return "European Union (GDPR)"
        case .california: return "California, USA (CCPA)"
        case .canada: return "Canada (PIPEDA)"
        case .australia: return "Australia (Privacy Act)"
        case .india: return "India (PDPB)"
        case .singapore: return "Singapore (PDPA)"
        case .unitedKingdom: return "United Kingdom (UK GDPR)"
        case .other: return "Other"
        }
    }
    
    public var regulationName: String {
        switch self {
        case .europeanUnion: return "GDPR"
        case .california: return "CCPA"
        case .canada: return "PIPEDA"
        case .australia: return "Privacy Act 1988"
        case .india: return "PDPB (Proposed)"
        case .singapore: return "PDPA"
        case .unitedKingdom: return "UK GDPR"
        case .other: return "Local Regulations"
        }
    }
}