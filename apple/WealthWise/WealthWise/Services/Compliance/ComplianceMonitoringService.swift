//
//  ComplianceMonitoringService.swift
//  WealthWise
//
//  Comprehensive compliance monitoring service for multi-country regulatory requirements
//

import Foundation
import Combine

/// Main compliance monitoring service with reactive monitoring and alert generation
@MainActor
public final class ComplianceMonitoringService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Active compliance alerts
    @Published public private(set) var activeAlerts: [ComplianceAlert] = []
    
    /// Overall compliance status
    @Published public private(set) var complianceStatus: ComplianceStatus?
    
    /// Active compliance rules
    @Published public private(set) var activeRules: [ComplianceRule] = []
    
    /// Service status
    @Published public private(set) var isMonitoring: Bool = false
    
    /// Last monitoring update
    @Published public private(set) var lastUpdate: Date?
    
    // MARK: - Dependencies
    
    private let ruleEngine: ComplianceRuleEngine
    private let thresholdMonitor: ReportingThresholdMonitor
    private let documentTracker: DocumentExpiryTracker
    private let alertManager: ComplianceAlertManager
    
    // MARK: - Configuration
    
    private let monitoringQueue = DispatchQueue(label: "compliance-monitoring", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    
    /// Service configuration
    public struct Configuration: Sendable {
        public let monitoringInterval: TimeInterval
        public let enableAutomaticMonitoring: Bool
        public let alertRetentionDays: Int
        public let defaultCountryCodes: Set<String>
        
        public init(
            monitoringInterval: TimeInterval = 3600,
            enableAutomaticMonitoring: Bool = true,
            alertRetentionDays: Int = 90,
            defaultCountryCodes: Set<String> = ["IN", "US", "GB", "CA"]
        ) {
            self.monitoringInterval = monitoringInterval
            self.enableAutomaticMonitoring = enableAutomaticMonitoring
            self.alertRetentionDays = alertRetentionDays
            self.defaultCountryCodes = defaultCountryCodes
        }
        
        public static let indianMarket = Configuration(
            monitoringInterval: 3600,
            enableAutomaticMonitoring: true,
            alertRetentionDays: 90,
            defaultCountryCodes: ["IN"]
        )
    }
    
    private let configuration: Configuration
    
    // MARK: - Initialization
    
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        self.ruleEngine = ComplianceRuleEngine(countryCodes: configuration.defaultCountryCodes)
        self.thresholdMonitor = ReportingThresholdMonitor()
        self.documentTracker = DocumentExpiryTracker()
        self.alertManager = ComplianceAlertManager()
        
        setupMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        await loadActiveRules()
        
        if configuration.enableAutomaticMonitoring {
            setupAutomaticMonitoring()
        }
        
        await performMonitoringCycle()
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    public func performMonitoringCycle() async {
        lastUpdate = Date()
        
        await monitorThresholds()
        await checkDocumentExpiry()
        await updateComplianceStatus()
        await processAlerts()
    }
    
    // MARK: - Asset Monitoring
    
    public func monitorAssets(_ assets: [CrossBorderAsset]) async {
        for asset in assets {
            await monitorAsset(asset)
        }
    }
    
    public func monitorAsset(_ asset: CrossBorderAsset) async {
        let applicableRules = ruleEngine.getRulesForAsset(asset)
        let thresholdAlerts = await thresholdMonitor.checkThresholds(for: asset, rules: applicableRules)
        
        for alert in thresholdAlerts {
            await alertManager.addAlert(alert)
        }
        
        await checkComplianceRequirements(for: asset, rules: applicableRules)
    }
    
    public func monitorTaxResidency(_ status: TaxResidencyStatus) async {
        if let expiryAlert = await documentTracker.checkDocumentExpiry(for: status) {
            await alertManager.addAlert(expiryAlert)
        }
        
        await checkComplianceObligations(for: status)
    }
    
    // MARK: - Alert Management
    
    public func getActiveAlerts() -> [ComplianceAlert] {
        return activeAlerts.sorted()
    }
    
    public func getAlerts(bySeverity severity: SeverityLevel) -> [ComplianceAlert] {
        return activeAlerts.filter { $0.severityLevel == severity }
    }
    
    public func getAlerts(byStatus status: AlertStatus) -> [ComplianceAlert] {
        return activeAlerts.filter { $0.status == status }
    }
    
    public func acknowledgeAlert(_ alertId: UUID) async {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].acknowledge()
        }
    }
    
    public func resolveAlert(_ alertId: UUID, notes: String? = nil) async {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].resolve(notes: notes)
            activeAlerts.remove(at: index)
        }
    }
    
    public func dismissAlert(_ alertId: UUID, reason: String? = nil) async {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].dismiss(reason: reason)
            activeAlerts.remove(at: index)
        }
    }
    
    // MARK: - Reporting
    
    public func generateComplianceReport(for assets: [CrossBorderAsset]) async -> ComplianceReport {
        return ComplianceReport(
            generatedAt: Date(),
            assets: assets,
            alerts: activeAlerts,
            status: complianceStatus
        )
    }
    
    public func getDashboardData() async -> ComplianceDashboardData {
        let criticalAlerts = activeAlerts.filter { $0.severityLevel == .critical }.count
        let upcomingDeadlines = activeAlerts.filter { $0.isUrgent }.count
        let overdueItems = activeAlerts.filter { $0.isOverdue }.count
        
        return ComplianceDashboardData(
            complianceScore: complianceStatus?.complianceScore ?? 100,
            totalAlerts: activeAlerts.count,
            criticalAlerts: criticalAlerts,
            upcomingDeadlines: upcomingDeadlines,
            overdueItems: overdueItems,
            lastUpdate: lastUpdate ?? Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func setupMonitoring() {
        $activeAlerts
            .sink { [weak self] alerts in
                self?.updateComplianceStatusFromAlerts(alerts)
            }
            .store(in: &cancellables)
    }
    
    private func setupAutomaticMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: configuration.monitoringInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performMonitoringCycle()
            }
        }
    }
    
    private func loadActiveRules() async {
        activeRules = ruleEngine.getActiveRules()
    }
    
    private func monitorThresholds() async {
        let thresholdAlerts = await thresholdMonitor.monitorAllThresholds(rules: activeRules)
        
        for alert in thresholdAlerts {
            await alertManager.addAlert(alert)
        }
    }
    
    private func checkDocumentExpiry() async {
        let expiryAlerts = await documentTracker.checkAllDocuments()
        
        for alert in expiryAlerts {
            await alertManager.addAlert(alert)
        }
    }
    
    private func updateComplianceStatus() async {
        var status = complianceStatus ?? ComplianceStatus(
            entityId: UUID(),
            entityType: .user
        )
        
        let critical = activeAlerts.filter { $0.severityLevel == .critical }.count
        let high = activeAlerts.filter { $0.severityLevel == .high }.count
        let medium = activeAlerts.filter { $0.severityLevel == .medium }.count
        let low = activeAlerts.filter { $0.severityLevel == .low }.count
        let info = activeAlerts.filter { $0.severityLevel == .informational }.count
        
        status.updateAlertCounts(critical: critical, high: high, medium: medium, low: low, informational: info)
        status.calculateComplianceScore()
        
        complianceStatus = status
    }
    
    private func processAlerts() async {
        activeAlerts = await alertManager.getActiveAlerts()
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -configuration.alertRetentionDays, to: Date()) ?? Date()
        activeAlerts.removeAll { alert in
            (alert.status == .resolved || alert.status == .dismissed) && alert.updatedAt < cutoffDate
        }
    }
    
    private func checkComplianceRequirements(for asset: CrossBorderAsset, rules: [ComplianceRule]) async {
        for rule in rules where rule.isEffective {
            if rule.appliesTo(assetType: asset.assetType.rawValue) {
                if let thresholdAmount = rule.thresholdAmount {
                    if asset.currentValue >= thresholdAmount {
                        let alert = ComplianceAlert(
                            alertType: .thresholdExceeded,
                            severityLevel: rule.severityLevel,
                            title: rule.title,
                            message: rule.description
                        )
                        await alertManager.addAlert(alert)
                    }
                }
            }
        }
    }
    
    private func checkComplianceObligations(for status: TaxResidencyStatus) async {
        for obligation in status.complianceObligations {
            let rules = ruleEngine.getRulesForObligation(obligation, countryCode: status.countryCode)
            
            for rule in rules where rule.isEffective {
                if rule.deadlineType != .none {
                    let alert = ComplianceAlert(
                        alertType: .deadlineApproaching,
                        severityLevel: rule.severityLevel,
                        title: obligation.displayName,
                        message: obligation.description
                    )
                    await alertManager.addAlert(alert)
                }
            }
        }
    }
    
    private func updateComplianceStatusFromAlerts(_ alerts: [ComplianceAlert]) {
        guard var status = complianceStatus else { return }
        
        let overdueCount = alerts.filter { $0.isOverdue }.count
        let upcomingCount = alerts.filter { $0.isUrgent }.count
        
        status.updateRequirementCounts(
            total: activeRules.count,
            compliant: activeRules.count - alerts.count,
            pending: alerts.filter { $0.status == .active }.count,
            overdue: overdueCount,
            upcoming: upcomingCount
        )
        
        status.calculateComplianceScore()
        complianceStatus = status
    }
}

// MARK: - Supporting Types

public struct ComplianceReport: Sendable {
    public let generatedAt: Date
    public let assets: [CrossBorderAsset]
    public let alerts: [ComplianceAlert]
    public let status: ComplianceStatus?
    
    public var summary: String {
        let totalAssets = assets.count
        let totalAlerts = alerts.count
        let criticalAlerts = alerts.filter { $0.severityLevel == .critical }.count
        
        return String(format: NSLocalizedString("compliance_report_summary", comment: "%d assets, %d alerts (%d critical)"), totalAssets, totalAlerts, criticalAlerts)
    }
}

public struct ComplianceDashboardData: Sendable {
    public let complianceScore: Int
    public let totalAlerts: Int
    public let criticalAlerts: Int
    public let upcomingDeadlines: Int
    public let overdueItems: Int
    public let lastUpdate: Date
    
    public var healthStatus: String {
        if complianceScore >= 90 {
            return NSLocalizedString("compliance_excellent", comment: "Excellent compliance")
        } else if complianceScore >= 70 {
            return NSLocalizedString("compliance_good", comment: "Good compliance")
        } else if complianceScore >= 50 {
            return NSLocalizedString("compliance_needs_attention", comment: "Needs attention")
        } else {
            return NSLocalizedString("compliance_critical", comment: "Critical - immediate action required")
        }
    }
}
