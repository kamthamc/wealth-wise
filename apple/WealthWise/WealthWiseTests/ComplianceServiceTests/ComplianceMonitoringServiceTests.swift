//
//  ComplianceMonitoringServiceTests.swift
//  WealthWiseTests
//
//  Unit tests for ComplianceMonitoringService
//

import XCTest
@testable import WealthWise

@MainActor
final class ComplianceMonitoringServiceTests: XCTestCase {
    
    var service: ComplianceMonitoringService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = ComplianceMonitoringService()
    }
    
    override func tearDown() async throws {
        service.stopMonitoring()
        service = nil
        try await super.tearDown()
    }
    
    func testServiceInitialization() {
        XCTAssertNotNil(service)
        XCTAssertFalse(service.isMonitoring)
        XCTAssertTrue(service.activeAlerts.isEmpty)
        XCTAssertNil(service.lastUpdate)
    }
    
    func testStartMonitoring() async {
        await service.startMonitoring()
        
        XCTAssertTrue(service.isMonitoring)
        XCTAssertNotNil(service.lastUpdate)
    }
    
    func testStopMonitoring() async {
        await service.startMonitoring()
        XCTAssertTrue(service.isMonitoring)
        
        service.stopMonitoring()
        XCTAssertFalse(service.isMonitoring)
    }
    
    func testMonitorAsset() async {
        let asset = CrossBorderAsset(
            name: "Test Asset",
            assetType: .publicEquityInternational,
            domicileCountryCode: "US",
            ownerCountryCode: "IN",
            currentValue: 250000,
            nativeCurrencyCode: "USD"
        )
        
        await service.startMonitoring()
        await service.monitorAsset(asset)
        
        // Service should process the asset
        XCTAssertNotNil(service.complianceStatus)
    }
    
    func testMonitorTaxResidency() async {
        let status = TaxResidencyStatus(
            countryCode: "IN",
            residencyType: .taxResident,
            taxYear: "FY2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        await service.startMonitoring()
        await service.monitorTaxResidency(status)
        
        XCTAssertNotNil(service.complianceStatus)
    }
    
    func testGetActiveAlerts() async {
        await service.startMonitoring()
        
        let alerts = service.getActiveAlerts()
        XCTAssertNotNil(alerts)
    }
    
    func testGetAlertsBySeverity() async {
        await service.startMonitoring()
        
        let criticalAlerts = service.getAlerts(bySeverity: .critical)
        XCTAssertNotNil(criticalAlerts)
    }
    
    func testGenerateComplianceReport() async {
        let asset = CrossBorderAsset(
            name: "Test Asset",
            assetType: .publicEquityInternational,
            domicileCountryCode: "US",
            ownerCountryCode: "IN",
            currentValue: 100000,
            nativeCurrencyCode: "USD"
        )
        
        await service.startMonitoring()
        
        let report = await service.generateComplianceReport(for: [asset])
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report.assets.count, 1)
        XCTAssertFalse(report.summary.isEmpty)
    }
    
    func testGetDashboardData() async {
        await service.startMonitoring()
        
        let dashboard = await service.getDashboardData()
        
        XCTAssertNotNil(dashboard)
        XCTAssertGreaterThanOrEqual(dashboard.complianceScore, 0)
        XCTAssertLessThanOrEqual(dashboard.complianceScore, 100)
        XCTAssertFalse(dashboard.healthStatus.isEmpty)
    }
    
    func testPerformanceMonitoringLargePortfolio() async {
        var assets: [CrossBorderAsset] = []
        
        for i in 0..<100 {
            let asset = CrossBorderAsset(
                name: "Asset \(i)",
                assetType: .publicEquityInternational,
                domicileCountryCode: "US",
                ownerCountryCode: "IN",
                currentValue: Decimal(100000 + i * 1000),
                nativeCurrencyCode: "USD"
            )
            assets.append(asset)
        }
        
        await service.startMonitoring()
        
        measure {
            Task {
                await service.monitorAssets(assets)
            }
        }
    }
}
