//
//  Report.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Report Data Models
//

import Foundation
import SwiftData

/// Report model for generated financial reports
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Report {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var reportType: ReportType
    public var reportDescription: String?
    
    // MARK: - Time Period
    
    public var periodStart: Date
    public var periodEnd: Date
    public var generatedAt: Date
    
    // MARK: - Report Data
    
    public var parameters: String? // JSON encoded parameters
    public var format: ReportFormat
    public var encryptedPath: String? // Path to exported file if saved
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var updatedAt: Date
    public var isArchived: Bool
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        reportType: ReportType,
        reportDescription: String? = nil,
        periodStart: Date,
        periodEnd: Date,
        format: ReportFormat = .summary,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.reportType = reportType
        self.reportDescription = reportDescription
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.generatedAt = createdAt
        self.format = format
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isArchived = false
    }
    
    // MARK: - Computed Properties
    
    /// Duration of the report period in days
    public var periodDurationDays: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: periodStart, to: periodEnd).day ?? 0
    }
    
    /// Whether this is a year-to-date report
    public var isYearToDate: Bool {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))
        return calendar.isDate(periodStart, inSameDayAs: startOfYear ?? Date())
    }
    
    /// Financial year string (e.g., "2024-25")
    public var financialYear: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: periodEnd)
        let month = calendar.component(.month, from: periodEnd)
        
        // Indian financial year: April to March
        if month >= 4 {
            return "\(year)-\(String(year + 1).suffix(2))"
        } else {
            return "\(year - 1)-\(String(year).suffix(2))"
        }
    }
}

// MARK: - Supporting Types

/// Report type enumeration
public enum ReportType: String, CaseIterable, Codable, Sendable {
    case taxReport = "tax_report"
    case capitalGainsReport = "capital_gains_report"
    case dividendReport = "dividend_report"
    case performanceReport = "performance_report"
    case allocationReport = "allocation_report"
    case netWorthReport = "net_worth_report"
    case incomeReport = "income_report"
    case expenseReport = "expense_report"
    
    public var displayName: String {
        switch self {
        case .taxReport:
            return NSLocalizedString("report_type_tax", comment: "Tax report")
        case .capitalGainsReport:
            return NSLocalizedString("report_type_capital_gains", comment: "Capital gains report")
        case .dividendReport:
            return NSLocalizedString("report_type_dividend", comment: "Dividend report")
        case .performanceReport:
            return NSLocalizedString("report_type_performance", comment: "Performance report")
        case .allocationReport:
            return NSLocalizedString("report_type_allocation", comment: "Asset allocation report")
        case .netWorthReport:
            return NSLocalizedString("report_type_net_worth", comment: "Net worth report")
        case .incomeReport:
            return NSLocalizedString("report_type_income", comment: "Income report")
        case .expenseReport:
            return NSLocalizedString("report_type_expense", comment: "Expense report")
        }
    }
    
    public var icon: String {
        switch self {
        case .taxReport: return "doc.text.fill"
        case .capitalGainsReport: return "chart.line.uptrend.xyaxis"
        case .dividendReport: return "percent.circle.fill"
        case .performanceReport: return "chart.bar.fill"
        case .allocationReport: return "chart.pie.fill"
        case .netWorthReport: return "banknote.fill"
        case .incomeReport: return "arrow.down.circle.fill"
        case .expenseReport: return "arrow.up.circle.fill"
        }
    }
}

/// Report format
public enum ReportFormat: String, CaseIterable, Codable, Sendable {
    case summary = "summary"
    case detailed = "detailed"
    case csv = "csv"
    case json = "json"
    
    public var displayName: String {
        switch self {
        case .summary:
            return NSLocalizedString("report_format_summary", comment: "Summary format")
        case .detailed:
            return NSLocalizedString("report_format_detailed", comment: "Detailed format")
        case .csv:
            return NSLocalizedString("report_format_csv", comment: "CSV format")
        case .json:
            return NSLocalizedString("report_format_json", comment: "JSON format")
        }
    }
}

/// Report template for reusable report configurations
public struct ReportTemplate: Codable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let reportType: ReportType
    public let category: ReportCategory
    public let isDefault: Bool
    public let templateData: String // JSON encoded template configuration
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        reportType: ReportType,
        category: ReportCategory,
        isDefault: Bool = false,
        templateData: String = "{}",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.reportType = reportType
        self.category = category
        self.isDefault = isDefault
        self.templateData = templateData
        self.createdAt = createdAt
    }
}

/// Report category
public enum ReportCategory: String, CaseIterable, Codable, Sendable {
    case tax = "tax"
    case investment = "investment"
    case budgeting = "budgeting"
    case netWorth = "net_worth"
    case compliance = "compliance"
    
    public var displayName: String {
        switch self {
        case .tax:
            return NSLocalizedString("report_category_tax", comment: "Tax reports")
        case .investment:
            return NSLocalizedString("report_category_investment", comment: "Investment reports")
        case .budgeting:
            return NSLocalizedString("report_category_budgeting", comment: "Budgeting reports")
        case .netWorth:
            return NSLocalizedString("report_category_net_worth", comment: "Net worth reports")
        case .compliance:
            return NSLocalizedString("report_category_compliance", comment: "Compliance reports")
        }
    }
}
