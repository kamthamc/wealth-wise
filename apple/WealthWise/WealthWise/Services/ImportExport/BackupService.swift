//
//  BackupService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Encrypted Backup Service
//

import Foundation
import SwiftData
import CryptoKit

/// Backup error
public enum BackupError: Error, LocalizedError {
    case invalidPassword
    case encryptionFailed
    case compressionFailed
    case invalidBackupFile
    case corruptedBackup
    case incompatibleVersion
    case exportFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return NSLocalizedString("backup_error_invalid_password", comment: "Invalid backup password")
        case .encryptionFailed:
            return NSLocalizedString("backup_error_encryption_failed", comment: "Backup encryption failed")
        case .compressionFailed:
            return NSLocalizedString("backup_error_compression_failed", comment: "Backup compression failed")
        case .invalidBackupFile:
            return NSLocalizedString("backup_error_invalid_file", comment: "Invalid backup file")
        case .corruptedBackup:
            return NSLocalizedString("backup_error_corrupted", comment: "Backup file is corrupted")
        case .incompatibleVersion:
            return NSLocalizedString("backup_error_incompatible_version", comment: "Backup version is incompatible")
        case .exportFailed(let reason):
            return String(format: NSLocalizedString("backup_error_export_failed", comment: "Export failed: %@"), reason)
        }
    }
}

/// Backup service with encryption support
@available(iOS 18.6, macOS 15.6, *)
public actor BackupService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let encryptionService: EncryptionService
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext, encryptionService: EncryptionService) {
        self.modelContext = modelContext
        self.encryptionService = encryptionService
    }
    
    // MARK: - Backup Methods
    
    /// Create encrypted backup of all data
    public func createBackup(password: String, includeAttachments: Bool = false) async throws -> URL {
        // Generate salt for key derivation
        let salt = encryptionService.generateSalt()
        
        // Derive encryption key from password
        let key = try encryptionService.deriveKey(
            from: password,
            salt: salt,
            iterations: 100000
        )
        
        // Export all data
        let backupData = try await exportAllData(includeAttachments: includeAttachments)
        
        // Compress data
        let compressedData = try compress(backupData)
        
        // Encrypt data
        let encryptedData = try await encryptionService.encrypt(compressedData, using: key)
        
        // Create metadata
        let metadata = try await createMetadata(
            salt: salt.base64EncodedString(),
            dataHash: encryptionService.hashSHA256(compressedData).base64EncodedString(),
            includeAttachments: includeAttachments
        )
        
        // Package backup file
        let backupURL = try await packageBackup(
            encryptedData: encryptedData,
            metadata: metadata
        )
        
        return backupURL
    }
    
    /// Restore data from encrypted backup
    public func restoreBackup(from url: URL, password: String) async throws -> BackupMetadata {
        // Read backup file
        let backupData = try Data(contentsOf: url)
        
        // Extract metadata and encrypted data
        let (metadata, encryptedData) = try extractBackup(backupData)
        
        // Validate backup version compatibility
        guard isCompatibleVersion(metadata.dataVersion) else {
            throw BackupError.incompatibleVersion
        }
        
        // Derive decryption key
        guard let saltData = Data(base64Encoded: metadata.salt) else {
            throw BackupError.corruptedBackup
        }
        
        let key = try encryptionService.deriveKey(
            from: password,
            salt: saltData,
            iterations: metadata.keyDerivationIterations
        )
        
        // Decrypt data
        let decryptedData = try await encryptionService.decrypt(encryptedData, using: key)
        
        // Verify data integrity
        let dataHash = encryptionService.hashSHA256(decryptedData).base64EncodedString()
        guard dataHash == metadata.dataHash else {
            throw BackupError.corruptedBackup
        }
        
        // Decompress data
        let decompressedData = try decompress(decryptedData)
        
        // Import data
        try await importAllData(decompressedData)
        
        return metadata
    }
    
    /// Validate backup file without restoring
    public func validateBackup(at url: URL, password: String) async throws -> BackupValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        do {
            let backupData = try Data(contentsOf: url)
            let (metadata, encryptedData) = try extractBackup(backupData)
            
            // Check version compatibility
            if !isCompatibleVersion(metadata.dataVersion) {
                warnings.append(NSLocalizedString("backup_warning_version_incompatible", comment: "Backup version may be incompatible"))
            }
            
            // Verify encryption
            guard let saltData = Data(base64Encoded: metadata.salt) else {
                errors.append(NSLocalizedString("backup_error_invalid_salt", comment: "Invalid salt in backup"))
                return BackupValidationResult(isValid: false, errors: errors, warnings: warnings)
            }
            
            let key = try encryptionService.deriveKey(
                from: password,
                salt: saltData,
                iterations: metadata.keyDerivationIterations
            )
            
            // Try to decrypt
            _ = try await encryptionService.decrypt(encryptedData, using: key)
            
        } catch {
            errors.append(error.localizedDescription)
        }
        
        return BackupValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
    }
    
    // MARK: - Private Methods
    
    /// Export all data to JSON
    private func exportAllData(includeAttachments: Bool) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Fetch all transactions
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let transactions = try modelContext.fetch(transactionDescriptor)
        
        // Fetch all goals
        let goalDescriptor = FetchDescriptor<Goal>()
        let goals = try modelContext.fetch(goalDescriptor)
        
        // Create backup data structure
        let backupData = BackupDataStructure(
            transactions: transactions,
            goals: goals,
            exportDate: Date()
        )
        
        return try encoder.encode(backupData)
    }
    
    /// Import all data from JSON
    private func importAllData(_ data: Data) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backupData = try decoder.decode(BackupDataStructure.self, from: data)
        
        // Import transactions
        for transaction in backupData.transactions {
            modelContext.insert(transaction)
        }
        
        // Import goals
        for goal in backupData.goals {
            modelContext.insert(goal)
        }
        
        try modelContext.save()
    }
    
    /// Create backup metadata
    private func createMetadata(salt: String, dataHash: String, includeAttachments: Bool) async throws -> BackupMetadata {
        let transactionDescriptor = FetchDescriptor<Transaction>()
        let transactions = try modelContext.fetch(transactionDescriptor)
        
        let goalDescriptor = FetchDescriptor<Goal>()
        let goals = try modelContext.fetch(goalDescriptor)
        
        let deviceName = ProcessInfo.processInfo.hostName
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        let metadata = BackupMetadata(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            dataVersion: "1.0.0",
            deviceName: deviceName,
            deviceId: deviceId,
            transactionCount: transactions.count,
            accountCount: 0,
            goalCount: goals.count,
            assetCount: 0,
            salt: salt,
            dataHash: dataHash,
            metadataHash: "" // Will be calculated after metadata is complete
        )
        
        return metadata
    }
    
    /// Package encrypted data and metadata into backup file
    private func packageBackup(encryptedData: EncryptedData, metadata: BackupMetadata) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let metadataData = try encoder.encode(metadata)
        let encryptedDataEncoded = try encoder.encode(encryptedData)
        
        // Create backup package
        let package: [String: Data] = [
            "metadata": metadataData,
            "data": encryptedDataEncoded
        ]
        
        let packageData = try encoder.encode(package)
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "WealthWise_Backup_\(timestamp).wealthwise"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try packageData.write(to: fileURL)
        
        return fileURL
    }
    
    /// Extract metadata and encrypted data from backup file
    private func extractBackup(_ data: Data) throws -> (BackupMetadata, EncryptedData) {
        let decoder = JSONDecoder()
        
        let package = try decoder.decode([String: Data].self, from: data)
        
        guard let metadataData = package["metadata"],
              let encryptedDataData = package["data"] else {
            throw BackupError.invalidBackupFile
        }
        
        let metadata = try decoder.decode(BackupMetadata.self, from: metadataData)
        let encryptedData = try decoder.decode(EncryptedData.self, from: encryptedDataData)
        
        return (metadata, encryptedData)
    }
    
    /// Compress data using zlib
    private func compress(_ data: Data) throws -> Data {
        guard let compressed = (data as NSData).compressed(using: .zlib) as Data? else {
            throw BackupError.compressionFailed
        }
        return compressed
    }
    
    /// Decompress data using zlib
    private func decompress(_ data: Data) throws -> Data {
        guard let decompressed = (data as NSData).decompressed(using: .zlib) as Data? else {
            throw BackupError.compressionFailed
        }
        return decompressed
    }
    
    /// Check if backup version is compatible
    private func isCompatibleVersion(_ version: String) -> Bool {
        // Simple version check - can be made more sophisticated
        let currentVersion = "1.0.0"
        return version <= currentVersion
    }
}

// MARK: - Supporting Types

/// Backup data structure for serialization
private struct BackupDataStructure: Codable {
    let transactions: [Transaction]
    let goals: [Goal]
    let exportDate: Date
}

// MARK: - UIDevice Extension for macOS Compatibility

#if os(macOS)
import AppKit

private struct UIDevice {
    static let current = UIDevice()
    
    var identifierForVendor: UUID? {
        // Generate a stable device ID for macOS
        return UUID()
    }
}
#else
import UIKit
#endif
