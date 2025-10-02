//
//  DashboardCoordinator.swift
//  WealthWise
//
//  Central coordinator for dashboard state and data management
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class DashboardCoordinator {
    
    // MARK: - Dashboard State
    
    var currentView: DashboardViewType = .overview
    var selectedTimeframe: DashboardTimeFrame = .month
    var displayCurrency: String = "INR"
    var isLoading: Bool = false
    var lastUpdated: Date = Date()
    
    // MARK: - Dashboard Data
    
    var dashboardData: DashboardData = DashboardData()
    
    // MARK: - Singleton
    
    static let shared = DashboardCoordinator()
    
    private init() {
        loadInitialData()
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() {
        Task {
            await refreshDashboardData()
        }
    }
    
    func refreshDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load net worth data
            dashboardData.netWorth = await loadNetWorthData()
            
            // Load asset allocation
            dashboardData.assetAllocation = await loadAssetAllocation()
            
            // Load recent transactions
            dashboardData.recentTransactions = await loadRecentTransactions()
            
            // Load performance metrics
            dashboardData.performanceMetrics = await loadPerformanceMetrics()
            
            // Load alerts
            dashboardData.alerts = await loadAlerts()
            
            lastUpdated = Date()
        }
    }
    
    // MARK: - Data Loaders
    
    private func loadNetWorthData() async -> NetWorthData {
        var netWorthData = NetWorthData()
        netWorthData.currency = displayCurrency
        
        // Generate sample historical data for demonstration
        let calendar = Calendar.current
        let now = Date()
        
        // Generate last 30 days of net worth history
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                let baseValue: Decimal = 5000000 // 50 lakh base
                let variation = Decimal(Double.random(in: -100000...200000))
                let value = baseValue + variation + Decimal(i * 10000)
                
                netWorthData.history.append(
                    NetWorthHistoryPoint(date: date, value: value)
                )
            }
        }
        
        // Calculate current total and changes
        if let latest = netWorthData.history.first,
           let monthAgo = netWorthData.history.last {
            netWorthData.total = latest.value
            netWorthData.monthlyChange = latest.value - monthAgo.value
            
            if monthAgo.value > 0 {
                netWorthData.monthlyChangePercent = Double(truncating: (netWorthData.monthlyChange / monthAgo.value * 100) as NSDecimalNumber)
            }
        }
        
        // Generate asset breakdown
        netWorthData.assetBreakdown = [
            AssetBreakdownItem(category: NSLocalizedString("asset.type.stocks", comment: "Stocks"), value: 2000000, percentage: 40, color: .blue),
            AssetBreakdownItem(category: NSLocalizedString("asset.type.mutual_funds", comment: "Mutual Funds"), value: 1500000, percentage: 30, color: .green),
            AssetBreakdownItem(category: NSLocalizedString("asset.type.real_estate", comment: "Real Estate"), value: 1000000, percentage: 20, color: .orange),
            AssetBreakdownItem(category: NSLocalizedString("asset.type.fixed_deposits", comment: "Fixed Deposits"), value: 500000, percentage: 10, color: .purple)
        ]
        
        return netWorthData
    }
    
    private func loadAssetAllocation() async -> [AssetAllocationSummary] {
        return [
            AssetAllocationSummary(type: NSLocalizedString("asset.type.stocks", comment: "Stocks"), value: 2000000, percentage: 40, count: 15),
            AssetAllocationSummary(type: NSLocalizedString("asset.type.mutual_funds", comment: "Mutual Funds"), value: 1500000, percentage: 30, count: 8),
            AssetAllocationSummary(type: NSLocalizedString("asset.type.real_estate", comment: "Real Estate"), value: 1000000, percentage: 20, count: 2),
            AssetAllocationSummary(type: NSLocalizedString("asset.type.fixed_deposits", comment: "Fixed Deposits"), value: 500000, percentage: 10, count: 5)
        ]
    }
    
    private func loadRecentTransactions() async -> [TransactionSummary] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            TransactionSummary(
                description: NSLocalizedString("transaction.salary", comment: "Monthly Salary"),
                amount: 150000,
                currency: displayCurrency,
                date: now,
                type: NSLocalizedString("transaction_type_income", comment: "Income"),
                category: NSLocalizedString("category_salary", comment: "Salary")
            ),
            TransactionSummary(
                description: NSLocalizedString("transaction.mutual_fund_investment", comment: "Mutual Fund Investment"),
                amount: 50000,
                currency: displayCurrency,
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                type: NSLocalizedString("transaction_type_investment", comment: "Investment"),
                category: NSLocalizedString("category_mutual_funds", comment: "Mutual Funds")
            ),
            TransactionSummary(
                description: NSLocalizedString("transaction.grocery_shopping", comment: "Grocery Shopping"),
                amount: 5000,
                currency: displayCurrency,
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                type: NSLocalizedString("transaction_type_expense", comment: "Expense"),
                category: NSLocalizedString("category_food_dining", comment: "Food & Dining")
            ),
            TransactionSummary(
                description: NSLocalizedString("transaction.electricity_bill", comment: "Electricity Bill"),
                amount: 2500,
                currency: displayCurrency,
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                type: NSLocalizedString("transaction_type_expense", comment: "Expense"),
                category: NSLocalizedString("category_utilities", comment: "Utilities")
            )
        ]
    }
    
    private func loadPerformanceMetrics() async -> PerformanceMetricsSummary {
        var metrics = PerformanceMetricsSummary()
        metrics.return1Month = 2.5
        metrics.return3Month = 8.3
        metrics.return6Month = 15.2
        metrics.return1Year = 28.7
        metrics.volatility = 12.5
        metrics.sharpeRatio = 1.8
        return metrics
    }
    
    private func loadAlerts() async -> [DashboardAlert] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            DashboardAlert(
                title: NSLocalizedString("alert.tax_payment_due", comment: "Tax Payment Due"),
                message: NSLocalizedString("alert.tax_payment_due_message", comment: "Advance tax payment due in 15 days"),
                severity: .warning,
                date: now,
                actionRequired: true
            ),
            DashboardAlert(
                title: NSLocalizedString("alert.goal_milestone", comment: "Goal Milestone Reached"),
                message: NSLocalizedString("alert.goal_milestone_message", comment: "You've reached 75% of your retirement goal"),
                severity: .info,
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                actionRequired: false
            )
        ]
    }
    
    // MARK: - Actions
    
    func switchTimeframe(_ timeframe: DashboardTimeFrame) {
        selectedTimeframe = timeframe
        Task {
            await refreshDashboardData()
        }
    }
    
    func switchView(_ view: DashboardViewType) {
        currentView = view
    }
    
    func switchCurrency(_ currency: String) {
        displayCurrency = currency
        Task {
            await refreshDashboardData()
        }
    }
}
