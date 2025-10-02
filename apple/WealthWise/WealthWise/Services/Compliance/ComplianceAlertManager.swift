//
//  ComplianceAlertManager.swift
//  WealthWise
//
//  Manage compliance alerts with deduplication and prioritization
//

import Foundation

/// Manages compliance alerts with deduplication and prioritization
public actor ComplianceAlertManager {
    
    // MARK: - Properties
    
    private var alerts: [UUID: ComplianceAlert] = [:]
    private var alertsByType: [AlertType: Set<UUID>] = [:]
    private var alertsBySeverity: [SeverityLevel: Set<UUID>] = [:]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Alert Management
    
    /// Add new alert (with deduplication)
    public func addAlert(_ alert: ComplianceAlert) {
        // Check for duplicate alerts
        if !isDuplicate(alert) {
            alerts[alert.id] = alert
            
            // Index by type
            var typeSet = alertsByType[alert.alertType] ?? Set()
            typeSet.insert(alert.id)
            alertsByType[alert.alertType] = typeSet
            
            // Index by severity
            var severitySet = alertsBySeverity[alert.severityLevel] ?? Set()
            severitySet.insert(alert.id)
            alertsBySeverity[alert.severityLevel] = severitySet
        }
    }
    
    /// Remove alert
    public func removeAlert(_ alertId: UUID) {
        guard let alert = alerts[alertId] else { return }
        
        alerts.removeValue(forKey: alertId)
        
        // Remove from indices
        alertsByType[alert.alertType]?.remove(alertId)
        alertsBySeverity[alert.severityLevel]?.remove(alertId)
    }
    
    /// Get all active alerts
    public func getActiveAlerts() -> [ComplianceAlert] {
        return alerts.values.filter { $0.status.isActionable }.sorted()
    }
    
    /// Get alerts by severity
    public func getAlerts(bySeverity severity: SeverityLevel) -> [ComplianceAlert] {
        guard let alertIds = alertsBySeverity[severity] else { return [] }
        return alertIds.compactMap { alerts[$0] }.sorted()
    }
    
    /// Get alerts by type
    public func getAlerts(byType type: AlertType) -> [ComplianceAlert] {
        guard let alertIds = alertsByType[type] else { return [] }
        return alertIds.compactMap { alerts[$0] }.sorted()
    }
    
    /// Get alert by ID
    public func getAlert(_ alertId: UUID) -> ComplianceAlert? {
        return alerts[alertId]
    }
    
    /// Update alert
    public func updateAlert(_ alert: ComplianceAlert) {
        alerts[alert.id] = alert
    }
    
    /// Clear resolved/dismissed alerts older than specified days
    public func cleanupOldAlerts(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let alertsToRemove = alerts.values.filter { alert in
            (alert.status == .resolved || alert.status == .dismissed) && alert.updatedAt < cutoffDate
        }
        
        for alert in alertsToRemove {
            removeAlert(alert.id)
        }
    }
    
    /// Get alert statistics
    public func getAlertStatistics() -> AlertStatistics {
        let activeAlerts = getActiveAlerts()
        
        return AlertStatistics(
            total: activeAlerts.count,
            critical: activeAlerts.filter { $0.severityLevel == .critical }.count,
            high: activeAlerts.filter { $0.severityLevel == .high }.count,
            medium: activeAlerts.filter { $0.severityLevel == .medium }.count,
            low: activeAlerts.filter { $0.severityLevel == .low }.count,
            urgent: activeAlerts.filter { $0.isUrgent }.count,
            overdue: activeAlerts.filter { $0.isOverdue }.count
        )
    }
    
    // MARK: - Private Methods
    
    private func isDuplicate(_ newAlert: ComplianceAlert) -> Bool {
        // Check for similar alerts of same type
        guard let existingIds = alertsByType[newAlert.alertType] else { return false }
        
        let existingAlerts = existingIds.compactMap { alerts[$0] }
        
        return existingAlerts.contains { existing in
            existing.title == newAlert.title &&
            existing.message == newAlert.message &&
            existing.status.isActionable &&
            existing.relatedAssetIds == newAlert.relatedAssetIds
        }
    }
}

// MARK: - Supporting Types

/// Alert statistics summary
public struct AlertStatistics: Sendable {
    public let total: Int
    public let critical: Int
    public let high: Int
    public let medium: Int
    public let low: Int
    public let urgent: Int
    public let overdue: Int
    
    public var needsImmediateAttention: Bool {
        return critical > 0 || overdue > 0
    }
}
