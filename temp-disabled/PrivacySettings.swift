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
    public var analyticsEnabled: Bool
    
    /// Allow crash reporting
    public var crashReportingEnabled: Bool
    
    /// Allow usage statistics collection
    public var usageStatisticsEnabled: Bool
    
    /// Allow performance monitoring
    public var performanceMonitoringEnabled: Bool
    
    /// Allow diagnostic data sharing
    public var diagnosticDataSharingEnabled: Bool
    
    // MARK: - Consent Management
    
    /// Consent for data processing
    public var dataProcessingConsent: Bool
    
    /// Consent for marketing communications
    public var marketingConsent: Bool
    
    /// Consent for third-party data sharing
    public var thirdPartyDataSharingConsent: Bool
    
    /// Consent for personalization
    public var personalizationConsent: Bool
    
    /// Consent for cross-border data transfer
    public var crossBorderDataTransferConsent: Bool
    
    // MARK: - Data Retention Settings
    
    /// Enable automatic data cleanup
    public var automaticDataCleanupEnabled: Bool
    
    /// Data retention period in days
    public var dataRetentionPeriod: Int
    
    /// Enable deletion of inactive data
    public var deleteInactiveDataEnabled: Bool
    
    /// Inactive data threshold in days
    public var inactiveDataThreshold: Int
    
    // MARK: - Security Settings
    
    /// Enable encryption at rest
    public var encryptionAtRestEnabled: Bool
    
    /// Enable encryption in transit
    public var encryptionInTransitEnabled: Bool
    
    /// Security level
    public var securityLevel: SecurityLevel
    
    /// Allow biometric data usage
    public var biometricDataUsageConsent: Bool
    
    /// Allow location data usage
    public var locationDataUsageConsent: Bool
    
    // MARK: - Data Sharing Settings
    
    /// Enable data synchronization
    public var dataSyncEnabled: Bool
    
    /// Enable cloud backup
    public var cloudBackupEnabled: Bool
    
    /// Enable family sharing
    public var familySharingEnabled: Bool
    
    /// Enable external service export
    public var externalServiceExportEnabled: Bool
    
    /// Enable third-party integrations
    public var thirdPartyIntegrationsEnabled: Bool
    
    // MARK: - Communication Preferences
    
    /// Enable in-app notifications
    public var inAppNotificationsEnabled: Bool
    
    /// Enable push notifications
    public var pushNotificationsEnabled: Bool
    
    /// Enable email communications
    public var emailCommunicationsEnabled: Bool
    
    /// Enable SMS notifications
    public var smsNotificationsEnabled: Bool
    
    /// Enable marketing notifications
    public var marketingNotificationsEnabled: Bool
    
    // MARK: - Tracking and Cookies
    
    /// Enable functional cookies
    public var functionalCookiesEnabled: Bool
    
    /// Enable analytics cookies
    public var analyticsCookiesEnabled: Bool
    
    /// Enable marketing cookies
    public var marketingCookiesEnabled: Bool
    
    /// Enable cross-site tracking
    public var crossSiteTrackingEnabled: Bool
    
    /// Enable advertising identifier
    public var advertisingIdentifierEnabled: Bool
    
    // MARK: - Regional Compliance
    
    /// GDPR region flag
    public var gdprRegion: Bool
    
    /// CCPA region flag
    public var ccpaRegion: Bool
    
    /// Selected privacy regulation
    public var privacyRegulation: PrivacyRegulation
    
    /// Last privacy policy acceptance date
    public var privacyPolicyAcceptanceDate: Date?
    
    /// Privacy policy version accepted
    public var privacyPolicyVersionAccepted: String?
    
    /// Data subject rights exercised
    public var dataSubjectRightsExercised: Set<String>
    
    // MARK: - Audit Trail
    
    /// Last updated timestamp
    public var lastUpdated: Date
    
    /// Settings change history
    public var changeHistory: [PrivacySettingChange]
    
    /// Privacy review reminders enabled
    public var reviewRemindersEnabled: Bool
    
    /// Next privacy review date
    public var nextReviewDate: Date?
    
    // MARK: - Initialization
    
    public init() {
        // Initialize all properties with secure defaults
        analyticsEnabled = false
        crashReportingEnabled = true // Essential for app stability
        usageStatisticsEnabled = false
        performanceMonitoringEnabled = false
        diagnosticDataSharingEnabled = false
        
        dataProcessingConsent = false
        marketingConsent = false
        thirdPartyDataSharingConsent = false
        personalizationConsent = false
        crossBorderDataTransferConsent = false
        
        automaticDataCleanupEnabled = true
        dataRetentionPeriod = 2555 // 7 years in days
        deleteInactiveDataEnabled = true
        inactiveDataThreshold = 730 // 2 years
        
        encryptionAtRestEnabled = true
        encryptionInTransitEnabled = true
        securityLevel = .high
        biometricDataUsageConsent = false
        locationDataUsageConsent = false
        
        dataSyncEnabled = false
        cloudBackupEnabled = false
        familySharingEnabled = false
        externalServiceExportEnabled = false
        thirdPartyIntegrationsEnabled = false
        
        inAppNotificationsEnabled = true
        pushNotificationsEnabled = true
        emailCommunicationsEnabled = false
        smsNotificationsEnabled = false
        marketingNotificationsEnabled = false
        
        functionalCookiesEnabled = true
        analyticsCookiesEnabled = false
        marketingCookiesEnabled = false
        crossSiteTrackingEnabled = false
        advertisingIdentifierEnabled = false
        
        gdprRegion = false
        ccpaRegion = false
        privacyRegulation = .other
        privacyPolicyAcceptanceDate = nil
        privacyPolicyVersionAccepted = nil
        dataSubjectRightsExercised = []
        
        lastUpdated = Date()
        changeHistory = []
        reviewRemindersEnabled = true
        nextReviewDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        
        // Auto-configure based on region
        configureForRegion()
    }
    
    public convenience init(forRegulation regulation: PrivacyRegulation) {
        self.init()
        self.privacyRegulation = regulation
        configureForRegulation(regulation)
    }
    
    // MARK: - Regional Configuration
    
    private func configureForRegion() {
        let locale = Locale.current
        
        if let regionCode = locale.region?.identifier {
            switch regionCode {
            case "GB", "DE", "FR", "IT", "ES", "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "GR", "HU", "IE", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK", "SI", "SE":
                // European Union - GDPR
                gdprRegion = true
                privacyRegulation = .europeanUnion
                configureForRegulation(.europeanUnion)
                
            case "US":
                if let stateCode = locale.region?.identifier.split(separator: "_").last, stateCode == "CA" {
                    // California - CCPA
                    ccpaRegion = true
                    privacyRegulation = .california
                } else {
                    privacyRegulation = .other
                }
                
            case "CA":
                privacyRegulation = .canada
                configureForRegulation(.canada)
                
            case "AU":
                privacyRegulation = .australia
                configureForRegulation(.australia)
                
            case "IN":
                privacyRegulation = .india
                configureForRegulation(.india)
                
            case "SG":
                privacyRegulation = .singapore
                configureForRegulation(.singapore)
                
            default:
                privacyRegulation = .other
            }
        }
    }
    
    private func configureForRegulation(_ regulation: PrivacyRegulation) {
        switch regulation {
        case .europeanUnion:
            // GDPR requires explicit consent
            gdprRegion = true
            dataProcessingConsent = true
            securityLevel = .maximum
            automaticDataCleanupEnabled = true
            
        case .california:
            // CCPA requirements
            ccpaRegion = true
            crossSiteTrackingEnabled = false
            advertisingIdentifierEnabled = false
            
        case .canada:
            // PIPEDA requirements
            dataProcessingConsent = true
            
        case .australia:
            // Privacy Act requirements
            dataProcessingConsent = true
            
        case .india:
            // PDPB requirements (when enacted)
            dataProcessingConsent = true
            
        case .singapore:
            // PDPA requirements
            dataProcessingConsent = true
            
        case .unitedKingdom:
            // UK GDPR
            gdprRegion = true
            dataProcessingConsent = true
            
        case .other:
            // Conservative defaults
            break
        }
    }
    
    // MARK: - Consent Management
    
    public func grantConsent(for type: ConsentType) {
        switch type {
        case .dataProcessing:
            dataProcessingConsent = true
        case .marketing:
            marketingConsent = true
        case .thirdPartySharing:
            thirdPartyDataSharingConsent = true
        case .personalization:
            personalizationConsent = true
        case .crossBorderTransfer:
            crossBorderDataTransferConsent = true
        case .biometricData:
            biometricDataUsageConsent = true
        case .locationData:
            locationDataUsageConsent = true
        }
        
        recordConsentChange(type: type, granted: true)
    }
    
    public func revokeConsent(for type: ConsentType) {
        switch type {
        case .dataProcessing:
            dataProcessingConsent = false
        case .marketing:
            marketingConsent = false
            marketingNotificationsEnabled = false
            marketingCookiesEnabled = false
        case .thirdPartySharing:
            thirdPartyDataSharingConsent = false
            thirdPartyIntegrationsEnabled = false
        case .personalization:
            personalizationConsent = false
            analyticsCookiesEnabled = false
        case .crossBorderTransfer:
            crossBorderDataTransferConsent = false
            cloudBackupEnabled = false
            dataSyncEnabled = false
        case .biometricData:
            biometricDataUsageConsent = false
        case .locationData:
            locationDataUsageConsent = false
        }
        
        recordConsentChange(type: type, granted: false)
    }
    
    private func recordConsentChange(type: ConsentType, granted: Bool) {
        let change = PrivacySettingChange(
            settingType: .consent,
            settingName: type.rawValue,
            oldValue: !granted,
            newValue: granted,
            timestamp: Date(),
            reason: granted ? "User granted consent" : "User revoked consent"
        )
        
        changeHistory.append(change)
        lastUpdated = Date()
    }
    
    // MARK: - Data Subject Rights
    
    public func exerciseDataSubjectRight(_ right: String) {
        dataSubjectRightsExercised.insert(right)
        
        let change = PrivacySettingChange(
            settingType: .dataSubjectRight,
            settingName: right,
            oldValue: false,
            newValue: true,
            timestamp: Date(),
            reason: "Data subject right exercised"
        )
        
        changeHistory.append(change)
        lastUpdated = Date()
    }
    
    // MARK: - Privacy Review
    
    public func scheduleNextReview(in timeInterval: TimeInterval) {
        nextReviewDate = Date().addingTimeInterval(timeInterval)
        lastUpdated = Date()
    }
    
    public func markReviewCompleted() {
        scheduleNextReview(in: 365 * 24 * 60 * 60) // 1 year
        
        let change = PrivacySettingChange(
            settingType: .review,
            settingName: "privacy_review",
            oldValue: false,
            newValue: true,
            timestamp: Date(),
            reason: "Privacy review completed"
        )
        
        changeHistory.append(change)
    }
    
    // MARK: - Validation
    
    public func validateCompliance() -> [String] {
        var violations: [String] = []
        
        if gdprRegion && !dataProcessingConsent {
            violations.append("GDPR requires explicit consent for data processing")
        }
        
        if ccpaRegion && crossSiteTrackingEnabled {
            violations.append("CCPA restricts cross-site tracking without explicit consent")
        }
        
        if !encryptionAtRestEnabled || !encryptionInTransitEnabled {
            violations.append("Encryption is required for financial data")
        }
        
        return violations
    }
    
    /// Validate privacy settings for consistency
    public func validate() -> [String] {
        return validateCompliance()
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case analyticsEnabled
        case crashReportingEnabled
        case usageStatisticsEnabled
        case performanceMonitoringEnabled
        case diagnosticDataSharingEnabled
        case dataProcessingConsent
        case marketingConsent
        case thirdPartyDataSharingConsent
        case personalizationConsent
        case crossBorderDataTransferConsent
        case automaticDataCleanupEnabled
        case dataRetentionPeriod
        case deleteInactiveDataEnabled
        case inactiveDataThreshold
        case encryptionAtRestEnabled
        case encryptionInTransitEnabled
        case securityLevel
        case biometricDataUsageConsent
        case locationDataUsageConsent
        case dataSyncEnabled
        case cloudBackupEnabled
        case familySharingEnabled
        case externalServiceExportEnabled
        case thirdPartyIntegrationsEnabled
        case inAppNotificationsEnabled
        case pushNotificationsEnabled
        case emailCommunicationsEnabled
        case smsNotificationsEnabled
        case marketingNotificationsEnabled
        case functionalCookiesEnabled
        case analyticsCookiesEnabled
        case marketingCookiesEnabled
        case crossSiteTrackingEnabled
        case advertisingIdentifierEnabled
        case gdprRegion
        case ccpaRegion
        case privacyRegulation
        case privacyPolicyAcceptanceDate
        case privacyPolicyVersionAccepted
        case dataSubjectRightsExercised
        case lastUpdated
        case changeHistory
        case reviewRemindersEnabled
        case nextReviewDate
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(analyticsEnabled, forKey: .analyticsEnabled)
        try container.encode(crashReportingEnabled, forKey: .crashReportingEnabled)
        try container.encode(usageStatisticsEnabled, forKey: .usageStatisticsEnabled)
        try container.encode(performanceMonitoringEnabled, forKey: .performanceMonitoringEnabled)
        try container.encode(diagnosticDataSharingEnabled, forKey: .diagnosticDataSharingEnabled)
        try container.encode(dataProcessingConsent, forKey: .dataProcessingConsent)
        try container.encode(marketingConsent, forKey: .marketingConsent)
        try container.encode(thirdPartyDataSharingConsent, forKey: .thirdPartyDataSharingConsent)
        try container.encode(personalizationConsent, forKey: .personalizationConsent)
        try container.encode(crossBorderDataTransferConsent, forKey: .crossBorderDataTransferConsent)
        try container.encode(automaticDataCleanupEnabled, forKey: .automaticDataCleanupEnabled)
        try container.encode(dataRetentionPeriod, forKey: .dataRetentionPeriod)
        try container.encode(deleteInactiveDataEnabled, forKey: .deleteInactiveDataEnabled)
        try container.encode(inactiveDataThreshold, forKey: .inactiveDataThreshold)
        try container.encode(encryptionAtRestEnabled, forKey: .encryptionAtRestEnabled)
        try container.encode(encryptionInTransitEnabled, forKey: .encryptionInTransitEnabled)
        try container.encode(securityLevel, forKey: .securityLevel)
        try container.encode(biometricDataUsageConsent, forKey: .biometricDataUsageConsent)
        try container.encode(locationDataUsageConsent, forKey: .locationDataUsageConsent)
        try container.encode(dataSyncEnabled, forKey: .dataSyncEnabled)
        try container.encode(cloudBackupEnabled, forKey: .cloudBackupEnabled)
        try container.encode(familySharingEnabled, forKey: .familySharingEnabled)
        try container.encode(externalServiceExportEnabled, forKey: .externalServiceExportEnabled)
        try container.encode(thirdPartyIntegrationsEnabled, forKey: .thirdPartyIntegrationsEnabled)
        try container.encode(inAppNotificationsEnabled, forKey: .inAppNotificationsEnabled)
        try container.encode(pushNotificationsEnabled, forKey: .pushNotificationsEnabled)
        try container.encode(emailCommunicationsEnabled, forKey: .emailCommunicationsEnabled)
        try container.encode(smsNotificationsEnabled, forKey: .smsNotificationsEnabled)
        try container.encode(marketingNotificationsEnabled, forKey: .marketingNotificationsEnabled)
        try container.encode(functionalCookiesEnabled, forKey: .functionalCookiesEnabled)
        try container.encode(analyticsCookiesEnabled, forKey: .analyticsCookiesEnabled)
        try container.encode(marketingCookiesEnabled, forKey: .marketingCookiesEnabled)
        try container.encode(crossSiteTrackingEnabled, forKey: .crossSiteTrackingEnabled)
        try container.encode(advertisingIdentifierEnabled, forKey: .advertisingIdentifierEnabled)
        try container.encode(gdprRegion, forKey: .gdprRegion)
        try container.encode(ccpaRegion, forKey: .ccpaRegion)
        try container.encode(privacyRegulation, forKey: .privacyRegulation)
        try container.encode(privacyPolicyAcceptanceDate, forKey: .privacyPolicyAcceptanceDate)
        try container.encode(privacyPolicyVersionAccepted, forKey: .privacyPolicyVersionAccepted)
        try container.encode(dataSubjectRightsExercised, forKey: .dataSubjectRightsExercised)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(changeHistory, forKey: .changeHistory)
        try container.encode(reviewRemindersEnabled, forKey: .reviewRemindersEnabled)
        try container.encode(nextReviewDate, forKey: .nextReviewDate)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        analyticsEnabled = try container.decode(Bool.self, forKey: .analyticsEnabled)
        crashReportingEnabled = try container.decode(Bool.self, forKey: .crashReportingEnabled)
        usageStatisticsEnabled = try container.decode(Bool.self, forKey: .usageStatisticsEnabled)
        performanceMonitoringEnabled = try container.decode(Bool.self, forKey: .performanceMonitoringEnabled)
        diagnosticDataSharingEnabled = try container.decode(Bool.self, forKey: .diagnosticDataSharingEnabled)
        dataProcessingConsent = try container.decode(Bool.self, forKey: .dataProcessingConsent)
        marketingConsent = try container.decode(Bool.self, forKey: .marketingConsent)
        thirdPartyDataSharingConsent = try container.decode(Bool.self, forKey: .thirdPartyDataSharingConsent)
        personalizationConsent = try container.decode(Bool.self, forKey: .personalizationConsent)
        crossBorderDataTransferConsent = try container.decode(Bool.self, forKey: .crossBorderDataTransferConsent)
        automaticDataCleanupEnabled = try container.decode(Bool.self, forKey: .automaticDataCleanupEnabled)
        dataRetentionPeriod = try container.decode(Int.self, forKey: .dataRetentionPeriod)
        deleteInactiveDataEnabled = try container.decode(Bool.self, forKey: .deleteInactiveDataEnabled)
        inactiveDataThreshold = try container.decode(Int.self, forKey: .inactiveDataThreshold)
        encryptionAtRestEnabled = try container.decode(Bool.self, forKey: .encryptionAtRestEnabled)
        encryptionInTransitEnabled = try container.decode(Bool.self, forKey: .encryptionInTransitEnabled)
        securityLevel = try container.decode(SecurityLevel.self, forKey: .securityLevel)
        biometricDataUsageConsent = try container.decode(Bool.self, forKey: .biometricDataUsageConsent)
        locationDataUsageConsent = try container.decode(Bool.self, forKey: .locationDataUsageConsent)
        dataSyncEnabled = try container.decode(Bool.self, forKey: .dataSyncEnabled)
        cloudBackupEnabled = try container.decode(Bool.self, forKey: .cloudBackupEnabled)
        familySharingEnabled = try container.decode(Bool.self, forKey: .familySharingEnabled)   
        externalServiceExportEnabled = try container.decode(Bool.self, forKey: .externalServiceExportEnabled)
        thirdPartyIntegrationsEnabled = try container.decode(Bool.self, forKey: .thirdPartyIntegrationsEnabled)
        inAppNotificationsEnabled = try container.decode(Bool.self, forKey: .inAppNotificationsEnabled)
        pushNotificationsEnabled = try container.decode(Bool.self, forKey: .pushNotificationsEnabled)
        emailCommunicationsEnabled = try container.decode(Bool.self, forKey: .emailCommunicationsEnabled)
        smsNotificationsEnabled = try container.decode(Bool.self, forKey: .smsNotificationsEnabled)
        marketingNotificationsEnabled = try container.decode(Bool.self, forKey: .marketingNotificationsEnabled)
        functionalCookiesEnabled = try container.decode(Bool.self, forKey: .functionalCookiesEnabled)
        analyticsCookiesEnabled = try container.decode(Bool.self, forKey: .analyticsCookiesEnabled)
        marketingCookiesEnabled = try container.decode(Bool.self, forKey: .marketingCookiesEnabled)
        crossSiteTrackingEnabled = try container.decode(Bool.self, forKey: .crossSiteTrackingEnabled)
        advertisingIdentifierEnabled = try container.decode(Bool.self, forKey: .advertisingIdentifierEnabled)
        gdprRegion = try container.decode(Bool.self, forKey: .gdprRegion)
        ccpaRegion = try container.decode(Bool.self, forKey: .ccpaRegion)
        privacyRegulation = try container.decode(PrivacyRegulation.self, forKey: .privacyRegulation)
        privacyPolicyAcceptanceDate = try container.decodeIfPresent(Date.self, forKey: .privacyPolicyAcceptanceDate)
        privacyPolicyVersionAccepted = try container.decodeIfPresent(String.self, forKey: .privacyPolicyVersionAccepted)
        dataSubjectRightsExercised = try container.decode(Set<String>.self, forKey: .dataSubjectRightsExercised)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        changeHistory = try container.decode([PrivacySettingChange].self, forKey: .changeHistory)
        reviewRemindersEnabled = try container.decode(Bool.self, forKey: .reviewRemindersEnabled)
        nextReviewDate = try container.decodeIfPresent(Date.self, forKey: .nextReviewDate)
    }
}

// MARK: - Supporting Types

// SecurityLevel is defined in SecurityProtocols.swift to avoid duplicate declarations

public enum PrivacyRegulation: String, CaseIterable, Codable {
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
        case .europeanUnion: return NSLocalizedString("GDPR (EU)", comment: "European Union GDPR")
        case .california: return NSLocalizedString("CCPA (California)", comment: "California Consumer Privacy Act")
        case .canada: return NSLocalizedString("PIPEDA (Canada)", comment: "Personal Information Protection and Electronic Documents Act")
        case .australia: return NSLocalizedString("Privacy Act (Australia)", comment: "Australian Privacy Act")
        case .india: return NSLocalizedString("PDPB (India)", comment: "Personal Data Protection Bill")
        case .singapore: return NSLocalizedString("PDPA (Singapore)", comment: "Personal Data Protection Act")
        case .unitedKingdom: return NSLocalizedString("UK GDPR", comment: "United Kingdom GDPR")
        case .other: return NSLocalizedString("Other/Regional", comment: "Other or regional privacy laws")
        }
    }
}

public enum ConsentType: String, CaseIterable, Codable {
    case dataProcessing = "data_processing"
    case marketing = "marketing"
    case thirdPartySharing = "third_party_sharing"
    case personalization = "personalization"
    case crossBorderTransfer = "cross_border_transfer"
    case biometricData = "biometric_data"
    case locationData = "location_data"
}

public struct PrivacySettingChange: Codable {
    public let settingType: SettingType
    public let settingName: String
    public let oldValue: Any
    public let newValue: Any
    public let timestamp: Date
    public let reason: String
    
    public enum SettingType: String, Codable {
        case consent = "consent"
        case security = "security"
        case dataRetention = "data_retention"
        case communication = "communication"
        case tracking = "tracking"
        case dataSubjectRight = "data_subject_right"
        case review = "review"
    }
    
    private enum CodingKeys: String, CodingKey {
        case settingType, settingName, timestamp, reason
        case oldValueString, newValueString
    }
    
    public init(settingType: SettingType, settingName: String, oldValue: Any, newValue: Any, timestamp: Date, reason: String) {
        self.settingType = settingType
        self.settingName = settingName
        self.oldValue = oldValue
        self.newValue = newValue
        self.timestamp = timestamp
        self.reason = reason
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settingType = try container.decode(SettingType.self, forKey: .settingType)
        settingName = try container.decode(String.self, forKey: .settingName)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        reason = try container.decode(String.self, forKey: .reason)
        
        let oldValueString = try container.decode(String.self, forKey: .oldValueString)
        let newValueString = try container.decode(String.self, forKey: .newValueString)
        
        oldValue = oldValueString
        newValue = newValueString
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(settingType, forKey: .settingType)
        try container.encode(settingName, forKey: .settingName)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(reason, forKey: .reason)
        
        try container.encode(String(describing: oldValue), forKey: .oldValueString)
        try container.encode(String(describing: newValue), forKey: .newValueString)
    }
}