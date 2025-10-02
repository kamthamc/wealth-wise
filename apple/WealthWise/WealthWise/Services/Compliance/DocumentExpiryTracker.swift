//
//  DocumentExpiryTracker.swift
//  WealthWise
//
//  Track document expiry and generate renewal reminders
//

import Foundation

/// Tracks document expiry and generates renewal alerts
public actor DocumentExpiryTracker {
    
    // MARK: - Properties
    
    private var trackedDocuments: [UUID: DocumentStatus] = [:]
    private let expiryWarningDays: Int = 90  // Warn 90 days before expiry
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Document Tracking
    
    /// Check all tracked documents for expiry
    public func checkAllDocuments() async -> [ComplianceAlert] {
        var alerts: [ComplianceAlert] = []
        
        for (_, docStatus) in trackedDocuments {
            if let alert = checkDocumentStatus(docStatus) {
                alerts.append(alert)
            }
        }
        
        return alerts
    }
    
    /// Check document expiry for tax residency status
    public func checkDocumentExpiry(for status: TaxResidencyStatus) async -> ComplianceAlert? {
        // Check if document is expiring soon
        if status.requiresRenewal {
            return ComplianceAlert(
                alertType: .documentExpiring,
                severityLevel: .high,
                title: NSLocalizedString("document_expiring", comment: "Document Expiring"),
                message: String(format: NSLocalizedString("tax_doc_expiring", comment: "Tax residency document for %@ expiring soon"), status.countryCode),
                actionDeadline: status.expiryDate
            )
        }
        
        // Check if document is expired
        if !status.isValid && status.expiryDate != nil {
            return ComplianceAlert(
                alertType: .renewalRequired,
                severityLevel: .critical,
                title: NSLocalizedString("document_expired", comment: "Document Expired"),
                message: String(format: NSLocalizedString("tax_doc_expired", comment: "Tax residency document for %@ has expired"), status.countryCode),
                actionDeadline: Date()
            )
        }
        
        return nil
    }
    
    /// Track new document
    public func trackDocument(id: UUID, expiryDate: Date, documentType: String) {
        let status = DocumentStatus(
            documentId: id,
            expiryDate: expiryDate,
            documentType: documentType,
            lastChecked: Date()
        )
        trackedDocuments[id] = status
    }
    
    /// Remove document from tracking
    public func removeDocument(id: UUID) {
        trackedDocuments.removeValue(forKey: id)
    }
    
    /// Get documents expiring within specified days
    public func getExpiringDocuments(withinDays days: Int) -> [DocumentStatus] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        return trackedDocuments.values.filter { status in
            status.expiryDate <= cutoffDate && status.expiryDate >= Date()
        }
    }
    
    /// Get expired documents
    public func getExpiredDocuments() -> [DocumentStatus] {
        let now = Date()
        return trackedDocuments.values.filter { $0.expiryDate < now }
    }
    
    // MARK: - Private Methods
    
    private func checkDocumentStatus(_ status: DocumentStatus) -> ComplianceAlert? {
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: status.expiryDate).day ?? 0
        
        if daysUntilExpiry < 0 {
            // Expired
            return ComplianceAlert(
                alertType: .documentExpiring,
                severityLevel: .critical,
                title: NSLocalizedString("document_expired_title", comment: "Document Expired"),
                message: String(format: NSLocalizedString("document_expired_msg", comment: "%@ has expired"), status.documentType),
                requiresUserAction: true
            )
        } else if daysUntilExpiry <= expiryWarningDays {
            // Expiring soon
            let severity: SeverityLevel = daysUntilExpiry <= 30 ? .high : .medium
            return ComplianceAlert(
                alertType: .documentExpiring,
                severityLevel: severity,
                title: NSLocalizedString("document_expiring_title", comment: "Document Expiring Soon"),
                message: String(format: NSLocalizedString("document_expiring_msg", comment: "%@ expires in %d days"), status.documentType, daysUntilExpiry),
                actionDeadline: status.expiryDate,
                requiresUserAction: true
            )
        }
        
        return nil
    }
}

// MARK: - Supporting Types

/// Document tracking status
public struct DocumentStatus: Sendable {
    public let documentId: UUID
    public let expiryDate: Date
    public let documentType: String
    public var lastChecked: Date
    
    public var isExpired: Bool {
        return expiryDate < Date()
    }
    
    public var daysUntilExpiry: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }
}
