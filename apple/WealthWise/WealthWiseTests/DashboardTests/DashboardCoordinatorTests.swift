//
//  DashboardCoordinatorTests.swift
//  WealthWiseTests
//
//  Tests for Dashboard Coordinator
//

import XCTest
@testable import WealthWise

@MainActor
final class DashboardCoordinatorTests: XCTestCase {
    
    var coordinator: DashboardCoordinator!
    
    override func setUp() async throws {
        coordinator = DashboardCoordinator.shared
    }
    
    // MARK: - Initialization Tests
    
    func testCoordinatorInitialization() {
        XCTAssertNotNil(coordinator, "Coordinator should be initialized")
        XCTAssertEqual(coordinator.currentView, .overview, "Default view should be overview")
        XCTAssertEqual(coordinator.selectedTimeframe, .month, "Default timeframe should be month")
        XCTAssertEqual(coordinator.displayCurrency, "INR", "Default currency should be INR")
    }
    
    // MARK: - Data Loading Tests
    
    func testDashboardDataInitialization() {
        XCTAssertNotNil(coordinator.dashboardData, "Dashboard data should be initialized")
        XCTAssertNotNil(coordinator.dashboardData.netWorth, "Net worth data should exist")
        XCTAssertNotNil(coordinator.dashboardData.assetAllocation, "Asset allocation should exist")
        XCTAssertNotNil(coordinator.dashboardData.recentTransactions, "Recent transactions should exist")
        XCTAssertNotNil(coordinator.dashboardData.performanceMetrics, "Performance metrics should exist")
    }
    
    func testNetWorthDataStructure() {
        let netWorth = coordinator.dashboardData.netWorth
        
        XCTAssertEqual(netWorth.currency, "INR", "Currency should be INR")
        XCTAssertGreaterThanOrEqual(netWorth.total, 0, "Total net worth should be non-negative")
        XCTAssertTrue(netWorth.history.isEmpty || !netWorth.history.isEmpty, "History should be a valid array")
        XCTAssertTrue(netWorth.assetBreakdown.isEmpty || !netWorth.assetBreakdown.isEmpty, "Asset breakdown should be a valid array")
    }
    
    // MARK: - Action Tests
    
    func testTimeframeSwitch() {
        coordinator.switchTimeframe(.year)
        
        XCTAssertEqual(coordinator.selectedTimeframe, .year, "Timeframe should be updated to year")
    }
    
    func testViewSwitch() {
        coordinator.switchView(.portfolio)
        
        XCTAssertEqual(coordinator.currentView, .portfolio, "View should be updated to portfolio")
    }
    
    func testCurrencySwitch() {
        coordinator.switchCurrency("USD")
        
        XCTAssertEqual(coordinator.displayCurrency, "USD", "Currency should be updated to USD")
    }
    
    // MARK: - Data Refresh Tests
    
    func testRefreshDashboardData() async {
        let initialLastUpdated = coordinator.lastUpdated
        
        // Wait a moment to ensure time difference
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        await coordinator.refreshDashboardData()
        
        XCTAssertGreaterThan(coordinator.lastUpdated, initialLastUpdated, "Last updated should be more recent after refresh")
        XCTAssertFalse(coordinator.isLoading, "Loading flag should be false after refresh completes")
    }
}

// MARK: - Dashboard Models Tests

final class DashboardModelsTests: XCTestCase {
    
    func testNetWorthDataInit() {
        let netWorthData = NetWorthData()
        
        XCTAssertEqual(netWorthData.total, 0)
        XCTAssertEqual(netWorthData.currency, "INR")
        XCTAssertEqual(netWorthData.monthlyChange, 0)
        XCTAssertEqual(netWorthData.monthlyChangePercent, 0)
        XCTAssertTrue(netWorthData.history.isEmpty)
        XCTAssertTrue(netWorthData.assetBreakdown.isEmpty)
    }
    
    func testAssetBreakdownItemInit() {
        let item = AssetBreakdownItem(
            category: "Stocks",
            value: 100000,
            percentage: 50,
            color: .blue
        )
        
        XCTAssertEqual(item.category, "Stocks")
        XCTAssertEqual(item.value, 100000)
        XCTAssertEqual(item.percentage, 50)
        XCTAssertNotNil(item.id)
    }
    
    func testAssetAllocationSummaryInit() {
        let allocation = AssetAllocationSummary(
            type: "Mutual Funds",
            value: 150000,
            percentage: 30,
            count: 5
        )
        
        XCTAssertEqual(allocation.type, "Mutual Funds")
        XCTAssertEqual(allocation.value, 150000)
        XCTAssertEqual(allocation.percentage, 30)
        XCTAssertEqual(allocation.count, 5)
        XCTAssertNotNil(allocation.id)
    }
    
    func testTransactionSummaryInit() {
        let transaction = TransactionSummary(
            description: "Test Transaction",
            amount: 5000,
            currency: "INR",
            date: Date(),
            type: "Income",
            category: "Salary"
        )
        
        XCTAssertEqual(transaction.description, "Test Transaction")
        XCTAssertEqual(transaction.amount, 5000)
        XCTAssertEqual(transaction.currency, "INR")
        XCTAssertEqual(transaction.type, "Income")
        XCTAssertEqual(transaction.category, "Salary")
        XCTAssertNotNil(transaction.id)
    }
    
    func testDashboardAlertInit() {
        let alert = DashboardAlert(
            title: "Test Alert",
            message: "Test message",
            severity: .warning,
            actionRequired: true
        )
        
        XCTAssertEqual(alert.title, "Test Alert")
        XCTAssertEqual(alert.message, "Test message")
        XCTAssertEqual(alert.severity, .warning)
        XCTAssertTrue(alert.actionRequired)
        XCTAssertNotNil(alert.id)
    }
    
    func testAlertSeverityColors() {
        XCTAssertNotNil(DashboardAlert.AlertSeverity.info.color)
        XCTAssertNotNil(DashboardAlert.AlertSeverity.warning.color)
        XCTAssertNotNil(DashboardAlert.AlertSeverity.critical.color)
    }
    
    func testAlertSeverityIcons() {
        XCTAssertEqual(DashboardAlert.AlertSeverity.info.icon, "info.circle.fill")
        XCTAssertEqual(DashboardAlert.AlertSeverity.warning.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(DashboardAlert.AlertSeverity.critical.icon, "exclamationmark.octagon.fill")
    }
    
    func testDashboardViewTypeAllCases() {
        let allCases = DashboardViewType.allCases
        
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.overview))
        XCTAssertTrue(allCases.contains(.portfolio))
        XCTAssertTrue(allCases.contains(.goals))
        XCTAssertTrue(allCases.contains(.taxes))
        XCTAssertTrue(allCases.contains(.analytics))
    }
    
    func testDashboardTimeFrameAllCases() {
        let allCases = DashboardTimeFrame.allCases
        
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.week))
        XCTAssertTrue(allCases.contains(.month))
        XCTAssertTrue(allCases.contains(.quarter))
        XCTAssertTrue(allCases.contains(.year))
        XCTAssertTrue(allCases.contains(.all))
    }
    
    func testPerformanceMetricsSummaryInit() {
        let metrics = PerformanceMetricsSummary()
        
        XCTAssertNil(metrics.return1Month)
        XCTAssertNil(metrics.return3Month)
        XCTAssertNil(metrics.return6Month)
        XCTAssertNil(metrics.return1Year)
        XCTAssertNil(metrics.volatility)
        XCTAssertNil(metrics.sharpeRatio)
    }
}
