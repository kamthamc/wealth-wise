//
//  ExportJob.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Export Job Model
//

import Foundation
import SwiftData

/// Export format type
public enum ExportFormat: String, CaseIterable, Codable, Sendable {
    case csv = "csv"
    case json = "json"
    case excel = "excel"
    case pdf = "pdf"
    case encryptedBackup = "encrypted_backup"
    
    public var displayName: String {
        switch self {
        case .csv:
            return NSLocalizedString("export_format_csv", comment: "CSV export format")
        case .json:
            return NSLocalizedString("export_format_json", comment: "JSON export format")
        case .excel:
            return NSLocalizedString("export_format_excel", comment: "Excel export format")
        case .pdf:
            return NSLocalizedString("export_format_pdf", comment: "PDF export format")
        case .encryptedBackup:
            return NSLocalizedString("export_format_backup", comment: "Encrypted backup format")
        }
    }
    
    public var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .excel: return "xlsx"
        case .pdf: return "pdf"
        case .encryptedBackup: return "wealthwise"
        }
    }
}

/// Export status
public enum ExportStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    public var displayName: String {
        switch self {
        case .pending:
            return NSLocalizedString("export_status_pending", comment: "Export status: pending")
        case .processing:
            return NSLocalizedString("export_status_processing", comment: "Export status: processing")
        case .completed:
            return NSLocalizedString("export_status_completed", comment: "Export status: completed")
        case .failed:
            return NSLocalizedString("export_status_failed", comment: "Export status: failed")
        }
    }
}

/// Export job for tracking data export operations
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class ExportJob {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var exportFormat: ExportFormat
    public var status: ExportStatus
    
    // MARK: - Configuration
    
    public var parameters: Data? // JSON-encoded export parameters
    public var includeAttachments: Bool
    public var dateRange: DateInterval?
    
    // MARK: - Output Information
    
    public var outputPath: String?
    public var outputSize: Int64
    public var recordCount: Int
    
    // MARK: - Timestamps
    
    public var requestedAt: Date
    public var startedAt: Date?
    public var completedAt: Date?
    
    // MARK: - Error Tracking
    
    public var errorMessage: String?
    
    // MARK: - Encryption (for backup)
    
    public var isEncrypted: Bool
    public var encryptionAlgorithm: String?
    public var backupHash: String? // SHA-256 hash for integrity
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        exportFormat: ExportFormat,
        status: ExportStatus = .pending,
        includeAttachments: Bool = false,
        requestedAt: Date = Date(),
        isEncrypted: Bool = false
    ) {
        self.id = id
        self.exportFormat = exportFormat
        self.status = status
        self.includeAttachments = includeAttachments
        self.requestedAt = requestedAt
        self.outputSize = 0
        self.recordCount = 0
        self.isEncrypted = isEncrypted
    }
    
    // MARK: - Computed Properties
    
    /// Whether export is in progress
    public var isInProgress: Bool {
        return status == .processing
    }
    
    /// Whether export is complete
    public var isComplete: Bool {
        return status == .completed || status == .failed
    }
    
    /// Duration of export
    public var duration: TimeInterval? {
        guard let startedAt = startedAt, let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
    
    /// Formatted file size
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: outputSize)
    }
    
    // MARK: - Business Logic Methods
    
    /// Start the export job
    public func start() {
        self.status = .processing
        self.startedAt = Date()
    }
    
    /// Mark export as completed
    public func complete(outputPath: String, size: Int64, recordCount: Int) {
        self.status = .completed
        self.completedAt = Date()
        self.outputPath = outputPath
        self.outputSize = size
        self.recordCount = recordCount
    }
    
    /// Mark export as failed
    public func fail(error: String) {
        self.status = .failed
        self.completedAt = Date()
        self.errorMessage = error
    }
}

/// Export configuration
public struct ExportConfiguration: Codable, Sendable {
    public var format: ExportFormat
    public var includeAttachments: Bool
    public var includeDeleted: Bool
    public var dateRange: DateInterval?
    public var categories: [String]?
    public var accounts: [String]?
    public var encrypt: Bool
    public var password: String?
    public var columns: [String]?
    
    public init(
        format: ExportFormat = .csv,
        includeAttachments: Bool = false,
        includeDeleted: Bool = false,
        dateRange: DateInterval? = nil,
        categories: [String]? = nil,
        accounts: [String]? = nil,
        encrypt: Bool = false,
        password: String? = nil,
        columns: [String]? = nil
    ) {
        self.format = format
        self.includeAttachments = includeAttachments
        self.includeDeleted = includeDeleted
        self.dateRange = dateRange
        self.categories = categories
        self.accounts = accounts
        self.encrypt = encrypt
        self.password = password
        self.columns = columns
    }
}
