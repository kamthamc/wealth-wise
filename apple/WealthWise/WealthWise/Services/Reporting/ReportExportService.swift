//
//  ReportExportService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Report Export Service
//

import Foundation

/// Service for exporting reports to various formats (CSV, JSON)
@available(iOS 18.6, macOS 15.6, *)
public final class ReportExportService {
    
    // MARK: - CSV Export Methods
    
    /// Export tax calculation to CSV format
    public func exportTaxCalculationToCSV(_ taxCalc: TaxCalculation) throws -> String {
        var csv = ""
        
        // Header
        csv += "Tax Report - Financial Year \(taxCalc.financialYear)\n"
        csv += "Generated on: \(DateFormatter.localizedString(from: taxCalc.calculatedAt, dateStyle: .medium, timeStyle: .short))\n"
        csv += "\n"
        
        // Capital Gains Section
        csv += "Capital Gains\n"
        csv += "Type,Amount\n"
        csv += "Short-term Capital Gains,\(taxCalc.shortTermCapitalGains.exportString())\n"
        csv += "Long-term Capital Gains,\(taxCalc.longTermCapitalGains.exportString())\n"
        csv += "Total Capital Gains,\(taxCalc.totalCapitalGains.exportString())\n"
        csv += "\n"
        
        // Income Section
        csv += "Other Income\n"
        csv += "Type,Amount\n"
        csv += "Dividend Income,\(taxCalc.totalDividendIncome.exportString())\n"
        csv += "Interest Income,\(taxCalc.totalInterestIncome.exportString())\n"
        csv += "Rental Income,\(taxCalc.totalRentalIncome.exportString())\n"
        csv += "Business Income,\(taxCalc.totalBusinessIncome.exportString())\n"
        csv += "Other Income,\(taxCalc.otherIncome.exportString())\n"
        csv += "\n"
        
        // Deductions Section
        csv += "Deductions\n"
        csv += "Section,Amount\n"
        csv += "Section 80C,\(taxCalc.section80CDeductions.exportString())\n"
        csv += "Section 80D,\(taxCalc.section80DDeductions.exportString())\n"
        csv += "Other Deductions,\(taxCalc.otherDeductions.exportString())\n"
        csv += "Total Deductions,\(taxCalc.totalDeductions.exportString())\n"
        csv += "\n"
        
        // Tax Summary Section
        csv += "Tax Summary\n"
        csv += "Item,Amount\n"
        csv += "Gross Income,\(taxCalc.grossIncome.exportString())\n"
        csv += "Total Deductions,\(taxCalc.totalDeductions.exportString())\n"
        csv += "Taxable Income,\(taxCalc.taxableIncome.exportString())\n"
        csv += "Tax Owed,\(taxCalc.taxOwed.exportString())\n"
        csv += "Tax Paid,\(taxCalc.taxPaid.exportString())\n"
        
        if taxCalc.isRefundDue {
            csv += "Refund Due,\(taxCalc.refundDue.exportString())\n"
        } else if taxCalc.isAdditionalTaxDue {
            csv += "Additional Tax Due,\(taxCalc.additionalTaxDue.exportString())\n"
        }
        
        csv += "Effective Tax Rate,\(String(format: "%.2f", taxCalc.effectiveTaxRate))%\n"
        
        return csv
    }
    
    /// Export capital gains breakdown to CSV
    public func exportCapitalGainsToCSV(_ breakdowns: [CapitalGainsBreakdown]) throws -> String {
        var csv = ""
        
        // Header
        csv += "Capital Gains Report\n"
        csv += "Generated on: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n"
        csv += "\n"
        
        // Column headers
        csv += "Asset Name,Asset Type,Purchase Date,Sale Date,Purchase Price,Sale Price,Capital Gain,Holding Period,Gain Type,Tax Rate,Tax Amount\n"
        
        // Data rows
        for breakdown in breakdowns {
            let purchaseDateStr = DateFormatter.localizedString(from: breakdown.purchaseDate, dateStyle: .short, timeStyle: .none)
            let saleDateStr = DateFormatter.localizedString(from: breakdown.saleDate, dateStyle: .short, timeStyle: .none)
            let gainType = breakdown.isLongTerm ? "Long-term" : "Short-term"
            
            csv += "\"\(breakdown.assetName)\","
            csv += "\"\(breakdown.assetType)\","
            csv += "\(purchaseDateStr),"
            csv += "\(saleDateStr),"
            csv += "\(breakdown.purchasePrice.exportString()),"
            csv += "\(breakdown.salePrice.exportString()),"
            csv += "\(breakdown.capitalGain.exportString()),"
            csv += "\"\(breakdown.holdingPeriodDisplay)\","
            csv += "\(gainType),"
            csv += "\(breakdown.taxRate.exportString())%,"
            csv += "\(breakdown.taxAmount.exportString())\n"
        }
        
        // Summary
        let totalGains = breakdowns.reduce(Decimal.zero) { $0 + $1.capitalGain }
        let totalTax = breakdowns.reduce(Decimal.zero) { $0 + $1.taxAmount }
        
        csv += "\n"
        csv += "Summary\n"
        csv += "Total Capital Gains,\(totalGains.exportString())\n"
        csv += "Total Tax,\(totalTax.exportString())\n"
        
        return csv
    }
    
    /// Export dividend income to CSV
    public func exportDividendIncomeToCSV(_ breakdowns: [DividendIncomeBreakdown]) throws -> String {
        var csv = ""
        
        // Header
        csv += "Dividend Income Report\n"
        csv += "Generated on: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n"
        csv += "\n"
        
        // Column headers
        csv += "Asset Name,Date,Dividend Amount,TDS Deducted,Net Dividend\n"
        
        // Data rows
        for breakdown in breakdowns {
            let dateStr = DateFormatter.localizedString(from: breakdown.dividendDate, dateStyle: .short, timeStyle: .none)
            
            csv += "\"\(breakdown.assetName)\","
            csv += "\(dateStr),"
            csv += "\(breakdown.dividendAmount.exportString()),"
            csv += "\(breakdown.tdsDeducted.exportString()),"
            csv += "\(breakdown.netDividend.exportString())\n"
        }
        
        // Summary
        let totalDividend = breakdowns.reduce(Decimal.zero) { $0 + $1.dividendAmount }
        let totalTDS = breakdowns.reduce(Decimal.zero) { $0 + $1.tdsDeducted }
        let totalNet = breakdowns.reduce(Decimal.zero) { $0 + $1.netDividend }
        
        csv += "\n"
        csv += "Summary\n"
        csv += "Total Dividend,\(totalDividend.exportString())\n"
        csv += "Total TDS,\(totalTDS.exportString())\n"
        csv += "Net Dividend,\(totalNet.exportString())\n"
        
        return csv
    }
    
    /// Export insights to CSV
    public func exportInsightsToCSV(_ insights: [Insight]) throws -> String {
        var csv = ""
        
        // Header
        csv += "Portfolio Insights Report\n"
        csv += "Generated on: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n"
        csv += "\n"
        
        // Column headers
        csv += "Category,Priority,Title,Description,Action,Impact\n"
        
        // Data rows
        for insight in insights where insight.shouldShow {
            csv += "\"\(insight.category.displayName)\","
            csv += "\"\(insight.priority.displayName)\","
            csv += "\"\(insight.title)\","
            csv += "\"\(insight.insightDescription.replacingOccurrences(of: "\"", with: "\"\""))\","
            csv += "\"\(insight.actionable?.replacingOccurrences(of: "\"", with: "\"\"") ?? "")\","
            csv += "\"\(insight.impactDisplay)\"\n"
        }
        
        return csv
    }
    
    /// Export portfolio allocation to CSV
    public func exportPortfolioAllocationToCSV(assets: [CrossBorderAsset]) throws -> String {
        var csv = ""
        
        // Header
        csv += "Portfolio Allocation Report\n"
        csv += "Generated on: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n"
        csv += "\n"
        
        // Calculate total value
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        
        // Column headers
        csv += "Asset Name,Category,Current Value,Percentage,Currency\n"
        
        // Data rows
        for asset in assets {
            let percentage = totalValue > 0 
                ? Double(truncating: (asset.currentValue / totalValue * 100) as NSDecimalNumber)
                : 0.0
            
            csv += "\"\(asset.name)\","
            csv += "\"\(asset.category.displayName)\","
            csv += "\(asset.currentValue.exportString()),"
            csv += "\(String(format: "%.2f", percentage))%,"
            csv += "\(asset.nativeCurrencyCode)\n"
        }
        
        // Summary by category
        csv += "\n"
        csv += "Allocation by Category\n"
        csv += "Category,Total Value,Percentage\n"
        
        var categoryValues: [AssetCategory: Decimal] = [:]
        for asset in assets {
            categoryValues[asset.category, default: 0] += asset.currentValue
        }
        
        for (category, value) in categoryValues.sorted(by: { $0.value > $1.value }) {
            let percentage = totalValue > 0 
                ? Double(truncating: (value / totalValue * 100) as NSDecimalNumber)
                : 0.0
            
            csv += "\"\(category.displayName)\","
            csv += "\(value.exportString()),"
            csv += "\(String(format: "%.2f", percentage))%\n"
        }
        
        csv += "\n"
        csv += "Total Portfolio Value,\(totalValue.exportString())\n"
        
        return csv
    }
    
    // MARK: - File Export Methods
    
    /// Save CSV string to file
    public func saveToFile(_ content: String, fileName: String) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    /// Generate unique file name for report
    public func generateFileName(for reportType: ReportType, format: String = "csv") -> String {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        
        return "WealthWise_\(reportType.rawValue)_\(timestamp).\(format)"
    }
}
