//
//  ReportingThresholdMonitor.swift
//  WealthWise
//
//  Monitor reporting thresholds for FBAR, FA forms, and LRS compliance
//

import Foundation

/// Monitors reporting thresholds across multiple jurisdictions
public actor ReportingThresholdMonitor {
    
    // MARK: - Properties
    
    private var trackedThresholds: [UUID: ThresholdTracker] = [:]
    private var assetAggregates: [String: Decimal] = [:]  // countryCode -> aggregate value
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Threshold Monitoring
    
    /// Monitor all configured thresholds
    public func monitorAllThresholds(rules: [ComplianceRule]) async -> [ComplianceAlert] {
        var alerts: [ComplianceAlert] = []
        
        for rule in rules where rule.thresholdAmount != nil {
            // Check if threshold monitoring is needed
            if let alert = await checkThresholdForRule(rule) {
                alerts.append(alert)
            }
        }
        
        return alerts
    }
    
    /// Check thresholds for specific asset
    public func checkThresholds(for asset: CrossBorderAsset, rules: [ComplianceRule]) async -> [ComplianceAlert] {
        var alerts: [ComplianceAlert] = []
        
        for rule in rules {
            guard let thresholdAmount = rule.thresholdAmount else { continue }
            
            if rule.isThresholdExceeded(for: asset.currentValue) {
                let alert = ComplianceAlert(
                    alertType: .thresholdExceeded,
                    severityLevel: rule.severityLevel,
                    title: rule.title,
                    message: String(format: NSLocalizedString("threshold_exceeded_msg", comment: "Asset value exceeds %@ threshold"), rule.thresholdCurrency ?? "")
                )
                alerts.append(alert)
            }
        }
        
        return alerts
    }
    
    /// Update aggregate tracking for country
    public func updateAggregate(countryCode: String, value: Decimal) {
        assetAggregates[countryCode] = value
    }
    
    /// Get current aggregate for country
    public func getAggregate(for countryCode: String) -> Decimal {
        return assetAggregates[countryCode] ?? 0
    }
    
    /// Check if aggregate exceeds threshold
    public func checkAggregateThreshold(for countryCode: String, threshold: Decimal) -> Bool {
        let aggregate = getAggregate(for: countryCode)
        return aggregate >= threshold
    }
    
    // MARK: - Private Methods
    
    private func checkThresholdForRule(_ rule: ComplianceRule) async -> ComplianceAlert? {
        guard let thresholdAmount = rule.thresholdAmount,
              let thresholdCurrency = rule.thresholdCurrency else {
            return nil
        }
        
        // Get aggregate for country
        let aggregate = getAggregate(for: rule.countryCode)
        
        if aggregate >= thresholdAmount {
            return ComplianceAlert(
                alertType: .thresholdExceeded,
                severityLevel: rule.severityLevel,
                title: rule.title,
                message: String(format: NSLocalizedString("country_threshold_exceeded", comment: "Total assets in %@ exceed %@ threshold"), rule.countryCode, thresholdCurrency)
            )
        }
        
        return nil
    }
}

// MARK: - Supporting Types

/// Tracker for individual threshold
private struct ThresholdTracker {
    let ruleId: UUID
    var currentValue: Decimal
    var lastChecked: Date
    var alertGenerated: Bool
}
