//
//  DashboardModels.swift
//  WealthWise
//
//  Dashboard data models and supporting types
//

import Foundation
import SwiftUI

// MARK: - Dashboard Data Models

/// Main dashboard data container
struct DashboardData: Sendable {
    var netWorth: NetWorthData
    var assetAllocation: [AssetAllocationSummary]
    var recentTransactions: [TransactionSummary]
    var performanceMetrics: PerformanceMetricsSummary
    var alerts: [DashboardAlert]
    
    init() {
        self.netWorth = NetWorthData()
        self.assetAllocation = []
        self.recentTransactions = []
        self.performanceMetrics = PerformanceMetricsSummary()
        self.alerts = []
    }
}

/// Net worth summary data
struct NetWorthData: Sendable {
    var total: Decimal
    var currency: String
    var monthlyChange: Decimal
    var monthlyChangePercent: Double
    var history: [NetWorthHistoryPoint]
    var assetBreakdown: [AssetBreakdownItem]
    
    init() {
        self.total = 0
        self.currency = "INR"
        self.monthlyChange = 0
        self.monthlyChangePercent = 0
        self.history = []
        self.assetBreakdown = []
    }
}

/// Historical net worth data point
struct NetWorthHistoryPoint: Identifiable, Sendable {
    let id: UUID
    let date: Date
    let value: Decimal
    let isFestival: Bool
    
    init(date: Date, value: Decimal, isFestival: Bool = false) {
        self.id = UUID()
        self.date = date
        self.value = value
        self.isFestival = isFestival
    }
}

/// Asset breakdown item for pie chart
struct AssetBreakdownItem: Identifiable, Sendable {
    let id: UUID
    let category: String
    let value: Decimal
    let percentage: Double
    let color: Color
    
    init(category: String, value: Decimal, percentage: Double, color: Color) {
        self.id = UUID()
        self.category = category
        self.value = value
        self.percentage = percentage
        self.color = color
    }
}

/// Asset allocation summary
struct AssetAllocationSummary: Identifiable, Sendable {
    let id: UUID
    let type: String
    let value: Decimal
    let percentage: Double
    let count: Int
    
    init(type: String, value: Decimal, percentage: Double, count: Int = 0) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.percentage = percentage
        self.count = count
    }
}

/// Transaction summary for dashboard
struct TransactionSummary: Identifiable, Sendable {
    let id: UUID
    let description: String
    let amount: Decimal
    let currency: String
    let date: Date
    let type: String
    let category: String
    
    init(id: UUID = UUID(), description: String, amount: Decimal, currency: String, date: Date, type: String, category: String) {
        self.id = id
        self.description = description
        self.amount = amount
        self.currency = currency
        self.date = date
        self.type = type
        self.category = category
    }
}

/// Performance metrics summary
struct PerformanceMetricsSummary: Sendable {
    var return1Month: Double?
    var return3Month: Double?
    var return6Month: Double?
    var return1Year: Double?
    var volatility: Double?
    var sharpeRatio: Double?
    
    init() {
        self.return1Month = nil
        self.return3Month = nil
        self.return6Month = nil
        self.return1Year = nil
        self.volatility = nil
        self.sharpeRatio = nil
    }
}

/// Dashboard alert
struct DashboardAlert: Identifiable, Sendable {
    let id: UUID
    let title: String
    let message: String
    let severity: AlertSeverity
    let date: Date
    let actionRequired: Bool
    
    init(id: UUID = UUID(), title: String, message: String, severity: AlertSeverity, date: Date = Date(), actionRequired: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.date = date
        self.actionRequired = actionRequired
    }
    
    enum AlertSeverity: String, Sendable {
        case info
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
}

// MARK: - Dashboard View Type

enum DashboardViewType: String, CaseIterable, Sendable {
    case overview = "overview"
    case portfolio = "portfolio"
    case goals = "goals"
    case taxes = "taxes"
    case analytics = "analytics"
    
    var displayName: String {
        switch self {
        case .overview:
            return NSLocalizedString("dashboard.view.overview", comment: "Overview view")
        case .portfolio:
            return NSLocalizedString("dashboard.view.portfolio", comment: "Portfolio view")
        case .goals:
            return NSLocalizedString("dashboard.view.goals", comment: "Goals view")
        case .taxes:
            return NSLocalizedString("dashboard.view.taxes", comment: "Taxes view")
        case .analytics:
            return NSLocalizedString("dashboard.view.analytics", comment: "Analytics view")
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .portfolio: return "chart.pie.fill"
        case .goals: return "target"
        case .taxes: return "doc.text.fill"
        case .analytics: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Time Frame

enum DashboardTimeFrame: String, CaseIterable, Sendable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .week:
            return NSLocalizedString("timeframe.week", comment: "1 Week")
        case .month:
            return NSLocalizedString("timeframe.month", comment: "1 Month")
        case .quarter:
            return NSLocalizedString("timeframe.quarter", comment: "3 Months")
        case .year:
            return NSLocalizedString("timeframe.year", comment: "1 Year")
        case .all:
            return NSLocalizedString("timeframe.all", comment: "All Time")
        }
    }
}
