//
//  BackupMetadata.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Backup Metadata Model
//

import Foundation

/// Backup metadata for encrypted backups
public struct BackupMetadata: Codable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let appVersion: String
    public let dataVersion: String
    public let deviceName: String
    public let deviceId: String
    
    // Backup content information
    public let transactionCount: Int
    public let accountCount: Int
    public let goalCount: Int
    public let assetCount: Int
    
    // Encryption information
    public let encryptionAlgorithm: String
    public let keyDerivationAlgorithm: String
    public let keyDerivationIterations: Int
    public let salt: String // Base64 encoded
    
    // Integrity verification
    public let dataHash: String // SHA-256 hash of encrypted data
    public let metadataHash: String // SHA-256 hash of metadata
    
    // Optional cloud sync
    public let cloudBackupId: String?
    public let cloudProvider: String?
    
    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        appVersion: String,
        dataVersion: String,
        deviceName: String,
        deviceId: String,
        transactionCount: Int,
        accountCount: Int,
        goalCount: Int,
        assetCount: Int,
        encryptionAlgorithm: String = "AES-256-GCM",
        keyDerivationAlgorithm: String = "PBKDF2-SHA256",
        keyDerivationIterations: Int = 100000,
        salt: String,
        dataHash: String,
        metadataHash: String,
        cloudBackupId: String? = nil,
        cloudProvider: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.dataVersion = dataVersion
        self.deviceName = deviceName
        self.deviceId = deviceId
        self.transactionCount = transactionCount
        self.accountCount = accountCount
        self.goalCount = goalCount
        self.assetCount = assetCount
        self.encryptionAlgorithm = encryptionAlgorithm
        self.keyDerivationAlgorithm = keyDerivationAlgorithm
        self.keyDerivationIterations = keyDerivationIterations
        self.salt = salt
        self.dataHash = dataHash
        self.metadataHash = metadataHash
        self.cloudBackupId = cloudBackupId
        self.cloudProvider = cloudProvider
    }
    
    /// Display name for the backup
    public var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Backup - \(formatter.string(from: createdAt))"
    }
    
    /// Total item count
    public var totalItemCount: Int {
        return transactionCount + accountCount + goalCount + assetCount
    }
}

/// Backup validation result
public struct BackupValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    
    public init(isValid: Bool, errors: [String] = [], warnings: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
    
    public var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    public var hasWarnings: Bool {
        return !warnings.isEmpty
    }
}
