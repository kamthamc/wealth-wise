//
//  DataExportService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Service for exporting financial data to CSV and PDF formats
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 18, macOS 15, *)
@MainActor
final class DataExportService {
    
    // MARK: - Error Types
    
    enum ExportError: LocalizedError {
        case pdfGenerationNotSupported
        case pdfGenerationFailed
        
        var errorDescription: String? {
            switch self {
            case .pdfGenerationNotSupported:
                return NSLocalizedString("export_error_pdf_not_supported", comment: "PDF export is not supported on this platform")
            case .pdfGenerationFailed:
                return NSLocalizedString("export_error_pdf_failed", comment: "Failed to generate PDF")
            }
        }
    }
    
    // MARK: - CSV Export
    
    enum CSVColumn: String, CaseIterable {
        case date = "Date"
        case description = "Description"
        case category = "Category"
        case amount = "Amount"
        case type = "Type"
        case account = "Account"
        case notes = "Notes"
    }
    
    struct CSVExportOptions {
        var columns: Set<CSVColumn> = Set(CSVColumn.allCases)
        var dateFormat: String = "dd/MM/yyyy"
        var includeHeaders: Bool = true
    }
    
    func exportToCSV(
        transactions: [WebAppTransaction],
        accounts: [Account],
        options: CSVExportOptions = CSVExportOptions()
    ) throws -> URL {
        var csvString = ""
        
        // Add headers
        if options.includeHeaders {
            let headers = options.columns.sorted { $0.rawValue < $1.rawValue }
                .map { $0.rawValue }
                .joined(separator: ",")
            csvString += headers + "\n"
        }
        
        // Date formatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = options.dateFormat
        
        // Add data rows
        for transaction in transactions {
            var row: [String] = []
            
            for column in options.columns.sorted(by: { $0.rawValue < $1.rawValue }) {
                let value: String
                
                switch column {
                case .date:
                    value = dateFormatter.string(from: transaction.date)
                    
                case .description:
                    value = escapeCSVValue(transaction.description)
                    
                case .category:
                    value = escapeCSVValue(transaction.category)
                    
                case .amount:
                    value = String(describing: transaction.amount)
                    
                case .type:
                    value = transaction.type == .debit ? "Expense" : "Income"
                    
                case .account:
                    let account = accounts.first { $0.id == transaction.accountId }
                    value = escapeCSVValue(account?.name ?? "Unknown")
                    
                case .notes:
                    value = escapeCSVValue(transaction.notes ?? "")
                }
                
                row.append(value)
            }
            
            csvString += row.joined(separator: ",") + "\n"
        }
        
        // Write to temporary file
        let fileName = "WealthWise_Export_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
        
        return tempURL
    }
    
    private func escapeCSVValue(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
    
    // MARK: - PDF Export
    
    enum ReportType {
        case monthly(Date)
        case quarterly(Date)
        case annual(Date)
        case custom(start: Date, end: Date)
        
        var title: String {
            let formatter = DateFormatter()
            
            switch self {
            case .monthly(let date):
                formatter.dateFormat = "MMMM yyyy"
                return "Monthly Report - \(formatter.string(from: date))"
                
            case .quarterly(let date):
                let quarter = Calendar.current.component(.quarter, from: date)
                formatter.dateFormat = "yyyy"
                return "Q\(quarter) \(formatter.string(from: date)) Report"
                
            case .annual(let date):
                formatter.dateFormat = "yyyy"
                return "Annual Report - \(formatter.string(from: date))"
                
            case .custom(let start, let end):
                formatter.dateFormat = "dd MMM yyyy"
                return "Report: \(formatter.string(from: start)) - \(formatter.string(from: end))"
            }
        }
        
        var dateRange: (start: Date, end: Date) {
            let calendar = Calendar.current
            
            switch self {
            case .monthly(let date):
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                return (start, end)
                
            case .quarterly(let date):
                let month = calendar.component(.month, from: date)
                let quarterStartMonth = ((month - 1) / 3) * 3 + 1
                var components = calendar.dateComponents([.year], from: date)
                components.month = quarterStartMonth
                components.day = 1
                let start = calendar.date(from: components)!
                let end = calendar.date(byAdding: .month, value: 3, to: start)!
                return (start, end)
                
            case .annual(let date):
                let start = calendar.date(from: calendar.dateComponents([.year], from: date))!
                let end = calendar.date(byAdding: .year, value: 1, to: start)!
                return (start, end)
                
            case .custom(let start, let end):
                return (start, end)
            }
        }
    }
    
    struct ReportData {
        var totalIncome: Decimal = 0
        var totalExpenses: Decimal = 0
        var netIncome: Decimal { totalIncome - totalExpenses }
        var savingsRate: Double {
            guard totalIncome > 0 else { return 0 }
            return Double(truncating: (netIncome / totalIncome * 100) as NSNumber)
        }
        var categoryBreakdown: [(category: String, amount: Decimal)] = []
        var topTransactions: [WebAppTransaction] = []
        var transactionCount: Int = 0
    }
    
    func exportToPDF(
        reportType: ReportType,
        transactions: [WebAppTransaction],
        accounts: [Account]
    ) throws -> URL {
        // Filter transactions by date range
        let range = reportType.dateRange
        let filteredTransactions = transactions.filter { $0.date >= range.start && $0.date < range.end }
        
        // Calculate report data
        let reportData = calculateReportData(from: filteredTransactions)
        
        // Create PDF
        let pdfMetaData = [
            kCGPDFContextTitle: reportType.title,
            kCGPDFContextAuthor: "WealthWise",
            kCGPDFContextCreator: "WealthWise App"
        ]
        
        #if canImport(UIKit)
        // iOS/iPadOS implementation
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth: CGFloat = 612 // 8.5 inches
        let pageHeight: CGFloat = 792 // 11 inches
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 60
            
            // Title
            yPosition = drawTitle(reportType.title, at: yPosition, in: pageRect)
            yPosition += 30
            
            // Summary section
            yPosition = drawSummarySection(reportData, at: yPosition, in: pageRect)
            yPosition += 30
            
            // Category breakdown
            yPosition = drawCategoryBreakdown(reportData.categoryBreakdown, at: yPosition, in: pageRect)
            yPosition += 30
            
            // Top transactions
            if yPosition < pageHeight - 200 {
                yPosition = drawTopTransactions(reportData.topTransactions, accounts: accounts, at: yPosition, in: pageRect)
            }
            
            // Footer
            drawFooter(at: pageHeight - 50, in: pageRect)
        }
        #else
        // macOS implementation using NSGraphicsContext
        let pageWidth: CGFloat = 612 // 8.5 inches
        let pageHeight: CGFloat = 792 // 11 inches
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let pdfData = NSMutableData()
        
        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: nil, pdfMetaData as CFDictionary) else {
            throw ExportError.pdfGenerationFailed
        }
        
        // Begin PDF page
        var mediaBox = pageRect
        pdfContext.beginPDFPage(nil)
        
        // Save graphics state
        pdfContext.saveGState()
        
        // Flip coordinate system for macOS (origin at bottom-left)
        pdfContext.translateBy(x: 0, y: pageHeight)
        pdfContext.scaleBy(x: 1.0, y: -1.0)
        
        var yPosition: CGFloat = 60
        
        // Title
        yPosition = drawTitleMacOS(reportType.title, at: yPosition, in: pageRect, context: pdfContext)
        yPosition += 30
        
        // Summary section
        yPosition = drawSummarySectionMacOS(reportData, at: yPosition, in: pageRect, context: pdfContext)
        yPosition += 30
        
        // Category breakdown
        yPosition = drawCategoryBreakdownMacOS(reportData.categoryBreakdown, at: yPosition, in: pageRect, context: pdfContext)
        yPosition += 30
        
        // Top transactions
        if yPosition < pageHeight - 200 {
            yPosition = drawTopTransactionsMacOS(reportData.topTransactions, accounts: accounts, at: yPosition, in: pageRect, context: pdfContext)
        }
        
        // Footer
        drawFooterMacOS(at: pageHeight - 50, in: pageRect, context: pdfContext)
        
        // Restore graphics state
        pdfContext.restoreGState()
        
        // End PDF page
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        #endif
        
        // Write to temporary file
        let fileName = "WealthWise_Report_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try pdfData.write(to: tempURL)
        
        return tempURL
    }
    
    private func calculateReportData(from transactions: [WebAppTransaction]) -> ReportData {
        var data = ReportData()
        
        data.transactionCount = transactions.count
        
        for transaction in transactions {
            if transaction.type == .credit {
                data.totalIncome += transaction.amount
            } else {
                data.totalExpenses += transaction.amount
            }
        }
        
        // Category breakdown
        var categoryTotals: [String: Decimal] = [:]
        for transaction in transactions where transaction.type == .debit {
            categoryTotals[transaction.category, default: 0] += transaction.amount
        }
        
        data.categoryBreakdown = categoryTotals.map { ($0.key, $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(10)
            .map { $0 }
        
        // Top transactions
        data.topTransactions = transactions
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }
        
        return data
    }
    
    // MARK: - PDF Drawing Functions (iOS/iPadOS Only)
    
    #if canImport(UIKit)
    
    private func drawTitle(_ title: String, at y: CGFloat, in rect: CGRect) -> CGFloat {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.label
        ]
        
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleRect = CGRect(x: 60, y: y, width: rect.width - 120, height: 40)
        titleString.draw(in: titleRect)
        
        return y + 40
    }
    
    private func drawSummarySection(_ data: ReportData, at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionTitle = NSAttributedString(
            string: "Financial Summary",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
        )
        sectionTitle.draw(at: CGPoint(x: 60, y: currentY))
        currentY += 30
        
        // Summary items
        let summaryItems = [
            ("Total Income", formatCurrency(data.totalIncome), UIColor.systemGreen),
            ("Total Expenses", formatCurrency(data.totalExpenses), UIColor.systemRed),
            ("Net Income", formatCurrency(data.netIncome), data.netIncome >= 0 ? UIColor.systemGreen : UIColor.systemRed),
            ("Savings Rate", String(format: "%.1f%%", data.savingsRate), UIColor.systemBlue),
            ("Total Transactions", "\(data.transactionCount)", UIColor.label)
        ]
        
        for (label, value, color) in summaryItems {
            currentY = drawSummaryItem(label: label, value: value, color: color, at: currentY, in: rect)
            currentY += 25
        }
        
        return currentY
    }
    
    private func drawSummaryItem(label: String, value: String, color: UIColor, at y: CGFloat, in rect: CGRect) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: color
        ]
        
        let labelString = NSAttributedString(string: label, attributes: labelAttributes)
        let valueString = NSAttributedString(string: value, attributes: valueAttributes)
        
        labelString.draw(at: CGPoint(x: 80, y: y))
        valueString.draw(at: CGPoint(x: rect.width - 200, y: y))
        
        return y
    }
    
    private func drawCategoryBreakdown(_ categories: [(String, Decimal)], at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionTitle = NSAttributedString(
            string: "Top Categories",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
        )
        sectionTitle.draw(at: CGPoint(x: 60, y: currentY))
        currentY += 30
        
        for (category, amount) in categories {
            currentY = drawCategoryItem(category: category, amount: amount, at: currentY, in: rect)
            currentY += 25
        }
        
        return currentY
    }
    
    private func drawCategoryItem(category: String, amount: Decimal, at y: CGFloat, in rect: CGRect) -> CGFloat {
        let categoryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.label
        ]
        
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.systemRed
        ]
        
        let categoryString = NSAttributedString(string: category, attributes: categoryAttributes)
        let amountString = NSAttributedString(string: formatCurrency(amount), attributes: amountAttributes)
        
        categoryString.draw(at: CGPoint(x: 80, y: y))
        amountString.draw(at: CGPoint(x: rect.width - 200, y: y))
        
        return y
    }
    
    private func drawTopTransactions(_ transactions: [WebAppTransaction], accounts: [Account], at y: CGFloat, in rect: CGRect) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionTitle = NSAttributedString(
            string: "Top Transactions",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
        )
        sectionTitle.draw(at: CGPoint(x: 60, y: currentY))
        currentY += 30
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        for transaction in transactions {
            let account = accounts.first { $0.id == transaction.accountId }
            
            currentY = drawTransactionItem(
                date: dateFormatter.string(from: transaction.date),
                description: transaction.description,
                account: account?.name ?? "Unknown",
                amount: formatCurrency(transaction.amount),
                type: transaction.type,
                at: currentY,
                in: rect
            )
            currentY += 35
        }
        
        return currentY
    }
    
    private func drawTransactionItem(date: String, description: String, account: String, amount: String, type: WebAppTransaction.TransactionType, at y: CGFloat, in rect: CGRect) -> CGFloat {
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.label
        ]
        
        let accountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: type == .debit ? UIColor.systemRed : UIColor.systemGreen
        ]
        
        let dateString = NSAttributedString(string: date, attributes: dateAttributes)
        let descString = NSAttributedString(string: description, attributes: descAttributes)
        let accountString = NSAttributedString(string: account, attributes: accountAttributes)
        let amountString = NSAttributedString(string: amount, attributes: amountAttributes)
        
        dateString.draw(at: CGPoint(x: 80, y: y))
        descString.draw(at: CGPoint(x: 80, y: y + 13))
        accountString.draw(at: CGPoint(x: 80, y: y + 28))
        amountString.draw(at: CGPoint(x: rect.width - 200, y: y + 10))
        
        return y
    }
    
    private func drawFooter(at y: CGFloat, in rect: CGRect) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy, hh:mm a"
        
        let footerText = "Generated by WealthWise on \(dateFormatter.string(from: Date()))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        let footerString = NSAttributedString(string: footerText, attributes: footerAttributes)
        let footerRect = CGRect(x: 60, y: y, width: rect.width - 120, height: 20)
        footerString.draw(in: footerRect)
    }
    
    #endif // canImport(UIKit)
    
    // MARK: - Common Helper Functions
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSNumber) ?? "₹0"
    }
    
    // MARK: - PDF Drawing Functions (macOS Only)
    
    #if canImport(AppKit)
    
    private func drawTitleMacOS(_ title: String, at y: CGFloat, in rect: CGRect, context: CGContext) -> CGFloat {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.labelColor
        ]
        
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let titleRect = CGRect(x: 60, y: y, width: rect.width - 120, height: 40)
        titleString.draw(in: titleRect)
        
        return y + 40
    }
    
    private func drawSummarySectionMacOS(_ data: ReportData, at y: CGFloat, in rect: CGRect, context: CGContext) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionTitle = NSAttributedString(
            string: "Financial Summary",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 18),
                .foregroundColor: NSColor.labelColor
            ]
        )
        sectionTitle.draw(at: CGPoint(x: 60, y: currentY))
        currentY += 30
        
        // Summary items
        let summaryItems = [
            ("Total Income", formatCurrency(data.totalIncome), NSColor.systemGreen),
            ("Total Expenses", formatCurrency(data.totalExpenses), NSColor.systemRed),
            ("Net Income", formatCurrency(data.netIncome), data.netIncome >= 0 ? NSColor.systemGreen : NSColor.systemRed),
            ("Savings Rate", String(format: "%.1f%%", data.savingsRate), NSColor.systemBlue),
            ("Total Transactions", "\(data.transactionCount)", NSColor.labelColor)
        ]
        
        for (label, value, color) in summaryItems {
            currentY = drawSummaryItemMacOS(label: label, value: value, color: color, at: currentY, in: rect, context: context)
            currentY += 25
        }
        
        return currentY
    }
    
    private func drawSummaryItemMacOS(label: String, value: String, color: NSColor, at y: CGFloat, in rect: CGRect, context: CGContext) -> CGFloat {
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: color
        ]
        
        let labelString = NSAttributedString(string: label, attributes: labelAttributes)
        let valueString = NSAttributedString(string: value, attributes: valueAttributes)
        
        labelString.draw(at: CGPoint(x: 80, y: y))
        valueString.draw(at: CGPoint(x: rect.width - 200, y: y))
        
        return y
    }
    
    private func drawCategoryBreakdownMacOS(_ categories: [(String, Decimal)], at y: CGFloat, in rect: CGRect, context: CGContext) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionTitle = NSAttributedString(
            string: "Top Categories",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 18),
                .foregroundColor: NSColor.labelColor
            ]
        )
        sectionTitle.draw(at: CGPoint(x: 60, y: currentY))
        currentY += 30
        
        for (category, amount) in categories {
            currentY = drawCategoryItemMacOS(category: category, amount: amount, at: currentY, in: rect, context: context)
            currentY += 25
        }
        
        return currentY
    }
    
    private func drawCategoryItemMacOS(category: String, amount: Decimal, at y: CGFloat, in rect: CGRect, context: CGContext) -> CGFloat {
        let categoryAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor
        ]
        
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.systemRed
        ]
        
        let categoryString = NSAttributedString(string: category, attributes: categoryAttributes)
        let amountString = NSAttributedString(string: formatCurrency(amount), attributes: amountAttributes)
        
        categoryString.draw(at: CGPoint(x: 80, y: y))
        amountString.draw(at: CGPoint(x: rect.width - 200, y: y))
        
        return y
    }
    
    private func drawTopTransactionsMacOS(_ transactions: [WebAppTransaction], accounts: [Account], at y: CGFloat, in rect: CGRect, context: CGContext) -> CGFloat {
        var currentY = y
        
        // Section title
        let sectionTitle = NSAttributedString(
            string: "Top Transactions",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 18),
                .foregroundColor: NSColor.labelColor
            ]
        )
        sectionTitle.draw(at: CGPoint(x: 60, y: currentY))
        currentY += 30
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        for transaction in transactions {
            let account = accounts.first { $0.id == transaction.accountId }
            
            currentY = drawTransactionItemMacOS(
                date: dateFormatter.string(from: transaction.date),
                description: transaction.transactionDescription,
                account: account?.name ?? "Unknown",
                amount: formatCurrency(transaction.amount),
                type: transaction.type,
                at: currentY,
                in: rect,
                context: context
            )
            currentY += 35
        }
        
        return currentY
    }
    
    private func drawTransactionItemMacOS(date: String, description: String, account: String, amount: String, type: WebAppTransaction.TransactionType, at y: CGFloat, in rect: CGRect, context: CGContext) -> CGFloat {
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor
        ]
        
        let accountAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let amountAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: type == .debit ? NSColor.systemRed : NSColor.systemGreen
        ]
        
        let dateString = NSAttributedString(string: date, attributes: dateAttributes)
        let descString = NSAttributedString(string: description, attributes: descAttributes)
        let accountString = NSAttributedString(string: account, attributes: accountAttributes)
        let amountString = NSAttributedString(string: amount, attributes: amountAttributes)
        
        dateString.draw(at: CGPoint(x: 80, y: y))
        descString.draw(at: CGPoint(x: 80, y: y + 13))
        accountString.draw(at: CGPoint(x: 80, y: y + 28))
        amountString.draw(at: CGPoint(x: rect.width - 200, y: y + 10))
        
        return y
    }
    
    private func drawFooterMacOS(at y: CGFloat, in rect: CGRect, context: CGContext) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy, hh:mm a"
        
        let footerText = "Generated by WealthWise on \(dateFormatter.string(from: Date()))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let footerString = NSAttributedString(string: footerText, attributes: footerAttributes)
        let footerRect = CGRect(x: 60, y: y, width: rect.width - 120, height: 20)
        footerString.draw(in: footerRect)
    }
    
    #endif // canImport(AppKit)
}
