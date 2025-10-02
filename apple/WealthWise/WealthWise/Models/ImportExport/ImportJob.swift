//
//  ImportJob.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Import Job Model
//

import Foundation
import SwiftData

/// Import job status
public enum ImportStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .pending:
            return NSLocalizedString("import_status_pending", comment: "Import status: pending")
        case .processing:
            return NSLocalizedString("import_status_processing", comment: "Import status: processing")
        case .completed:
            return NSLocalizedString("import_status_completed", comment: "Import status: completed")
        case .failed:
            return NSLocalizedString("import_status_failed", comment: "Import status: failed")
        case .cancelled:
            return NSLocalizedString("import_status_cancelled", comment: "Import status: cancelled")
        }
    }
}

/// Import source type
public enum ImportSourceType: String, CaseIterable, Codable, Sendable {
    case csv = "csv"
    case excel = "excel"
    case json = "json"
    case bankStatement = "bank_statement"
    case manualEntry = "manual_entry"
    case backup = "backup"
    
    public var displayName: String {
        switch self {
        case .csv:
            return NSLocalizedString("import_source_csv", comment: "CSV file import source")
        case .excel:
            return NSLocalizedString("import_source_excel", comment: "Excel file import source")
        case .json:
            return NSLocalizedString("import_source_json", comment: "JSON file import source")
        case .bankStatement:
            return NSLocalizedString("import_source_bank_statement", comment: "Bank statement import source")
        case .manualEntry:
            return NSLocalizedString("import_source_manual", comment: "Manual entry import source")
        case .backup:
            return NSLocalizedString("import_source_backup", comment: "Backup file import source")
        }
    }
}

/// Import job for tracking CSV/data import operations
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class ImportJob {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var filename: String
    public var sourceType: ImportSourceType
    public var status: ImportStatus
    
    // MARK: - Progress Tracking
    
    public var totalRecords: Int
    public var successfulRecords: Int
    public var failedRecords: Int
    public var duplicateRecords: Int
    
    // MARK: - Timestamps
    
    public var createdAt: Date
    public var startedAt: Date?
    public var completedAt: Date?
    
    // MARK: - Error Tracking
    
    public var errorLog: String?
    public var warnings: [String]
    
    // MARK: - File Information
    
    public var fileSize: Int64
    public var filePath: String?
    public var fileHash: String? // SHA-256 hash for duplicate detection
    
    // MARK: - Configuration
    
    public var importConfiguration: Data? // JSON-encoded configuration
    public var columnMappings: Data? // JSON-encoded column mappings
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        filename: String,
        sourceType: ImportSourceType,
        status: ImportStatus = .pending,
        totalRecords: Int = 0,
        fileSize: Int64 = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.sourceType = sourceType
        self.status = status
        self.totalRecords = totalRecords
        self.successfulRecords = 0
        self.failedRecords = 0
        self.duplicateRecords = 0
        self.fileSize = fileSize
        self.warnings = []
        self.createdAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// Success rate percentage
    public var successRate: Double {
        guard totalRecords > 0 else { return 0 }
        return Double(successfulRecords) / Double(totalRecords) * 100
    }
    
    /// Whether import is in progress
    public var isInProgress: Bool {
        return status == .processing
    }
    
    /// Whether import is complete (success or failed)
    public var isComplete: Bool {
        return status == .completed || status == .failed || status == .cancelled
    }
    
    /// Duration of import
    public var duration: TimeInterval? {
        guard let startedAt = startedAt, let completedAt = completedAt else { return nil }
        return completedAt.timeIntervalSince(startedAt)
    }
    
    /// Progress percentage
    public var progressPercentage: Double {
        guard totalRecords > 0 else { return 0 }
        let processed = successfulRecords + failedRecords + duplicateRecords
        return Double(processed) / Double(totalRecords) * 100
    }
    
    // MARK: - Business Logic Methods
    
    /// Start the import job
    public func start() {
        self.status = .processing
        self.startedAt = Date()
    }
    
    /// Mark import as completed
    public func complete() {
        self.status = .completed
        self.completedAt = Date()
    }
    
    /// Mark import as failed
    public func fail(error: String) {
        self.status = .failed
        self.completedAt = Date()
        self.errorLog = error
    }
    
    /// Cancel the import
    public func cancel() {
        self.status = .cancelled
        self.completedAt = Date()
    }
    
    /// Record successful import
    public func recordSuccess() {
        self.successfulRecords += 1
    }
    
    /// Record failed import
    public func recordFailure(error: String) {
        self.failedRecords += 1
        addWarning(error)
    }
    
    /// Record duplicate detection
    public func recordDuplicate() {
        self.duplicateRecords += 1
    }
    
    /// Add warning message
    public func addWarning(_ warning: String) {
        warnings.append(warning)
    }
}
