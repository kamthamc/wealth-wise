//
//  ReportExportServiceTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Report Export Service Tests
//

import XCTest
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class ReportExportServiceTests: XCTestCase {
    
    var exportService: ReportExportService!
    
    override func setUp() {
        exportService = ReportExportService()
    }
    
    override func tearDown() {
        exportService = nil
    }
    
    // MARK: - Tax Calculation Export Tests
    
    func testExportTaxCalculationToCSV() throws {
        // Create test tax calculation
        let taxCalc = TaxCalculation(
            financialYear: "2024-25",
            shortTermCapitalGains: 50000,
            longTermCapitalGains: 100000,
            totalDividendIncome: 25000,
            totalInterestIncome: 30000
        )
        taxCalc.section80CDeductions = 100000
        taxCalc.section80DDeductions = 15000
        taxCalc.totalDeductions = 115000
        taxCalc.taxableIncome = 90000
        taxCalc.taxOwed = 27000
        taxCalc.taxPaid = 5000
        taxCalc.additionalTaxDue = 22000
        
        let csv = try exportService.exportTaxCalculationToCSV(taxCalc)
        
        // Verify CSV contains expected data
        XCTAssertTrue(csv.contains("Tax Report - Financial Year 2024-25"))
        XCTAssertTrue(csv.contains("Capital Gains"))
        XCTAssertTrue(csv.contains("Short-term Capital Gains"))
        XCTAssertTrue(csv.contains("50000"))
        XCTAssertTrue(csv.contains("Long-term Capital Gains"))
        XCTAssertTrue(csv.contains("100000"))
        XCTAssertTrue(csv.contains("Dividend Income"))
        XCTAssertTrue(csv.contains("25000"))
        XCTAssertTrue(csv.contains("Section 80C"))
        XCTAssertTrue(csv.contains("100000"))
        XCTAssertTrue(csv.contains("Tax Summary"))
    }
    
    func testExportTaxCalculationToCSV_WithRefund() throws {
        // Create tax calculation with refund
        let taxCalc = TaxCalculation(
            financialYear: "2024-25",
            shortTermCapitalGains: 30000,
            longTermCapitalGains: 50000
        )
        taxCalc.taxOwed = 10000
        taxCalc.taxPaid = 15000
        taxCalc.refundDue = 5000
        
        let csv = try exportService.exportTaxCalculationToCSV(taxCalc)
        
        // Verify refund is shown
        XCTAssertTrue(csv.contains("Refund Due"))
        XCTAssertTrue(csv.contains("5000"))
    }
    
    // MARK: - Capital Gains Export Tests
    
    func testExportCapitalGainsToCSV() throws {
        // Create test capital gains breakdowns
        let breakdown1 = CapitalGainsBreakdown(
            assetName: "Apple Stock",
            assetType: "stocks",
            purchaseDate: Date(timeIntervalSinceNow: -400 * 24 * 60 * 60), // ~400 days ago
            saleDate: Date(),
            purchasePrice: 100000,
            salePrice: 130000
        )
        
        let breakdown2 = CapitalGainsBreakdown(
            assetName: "Google Stock",
            assetType: "stocks",
            purchaseDate: Date(timeIntervalSinceNow: -200 * 24 * 60 * 60), // ~200 days ago
            saleDate: Date(),
            purchasePrice: 50000,
            salePrice: 55000
        )
        
        let csv = try exportService.exportCapitalGainsToCSV([breakdown1, breakdown2])
        
        // Verify CSV structure
        XCTAssertTrue(csv.contains("Capital Gains Report"))
        XCTAssertTrue(csv.contains("Asset Name"))
        XCTAssertTrue(csv.contains("Purchase Price"))
        XCTAssertTrue(csv.contains("Sale Price"))
        XCTAssertTrue(csv.contains("Capital Gain"))
        XCTAssertTrue(csv.contains("Apple Stock"))
        XCTAssertTrue(csv.contains("Google Stock"))
        XCTAssertTrue(csv.contains("Summary"))
        XCTAssertTrue(csv.contains("Total Capital Gains"))
    }
    
    func testExportCapitalGainsToCSV_EmptyList() throws {
        let csv = try exportService.exportCapitalGainsToCSV([])
        
        // Should still generate valid CSV with headers
        XCTAssertTrue(csv.contains("Capital Gains Report"))
        XCTAssertTrue(csv.contains("Asset Name"))
        XCTAssertTrue(csv.contains("Summary"))
    }
    
    // MARK: - Dividend Income Export Tests
    
    func testExportDividendIncomeToCSV() throws {
        // Create test dividend breakdowns
        let dividend1 = DividendIncomeBreakdown(
            assetName: "Tech Mutual Fund",
            dividendDate: Date(),
            dividendAmount: 5000,
            tdsDeducted: 500
        )
        
        let dividend2 = DividendIncomeBreakdown(
            assetName: "Index Fund",
            dividendDate: Date(timeIntervalSinceNow: -30 * 24 * 60 * 60),
            dividendAmount: 3000,
            tdsDeducted: 300
        )
        
        let csv = try exportService.exportDividendIncomeToCSV([dividend1, dividend2])
        
        // Verify CSV structure
        XCTAssertTrue(csv.contains("Dividend Income Report"))
        XCTAssertTrue(csv.contains("Asset Name"))
        XCTAssertTrue(csv.contains("Dividend Amount"))
        XCTAssertTrue(csv.contains("TDS Deducted"))
        XCTAssertTrue(csv.contains("Net Dividend"))
        XCTAssertTrue(csv.contains("Tech Mutual Fund"))
        XCTAssertTrue(csv.contains("5000"))
        XCTAssertTrue(csv.contains("Summary"))
        XCTAssertTrue(csv.contains("Total Dividend"))
    }
    
    // MARK: - Insights Export Tests
    
    @MainActor
    func testExportInsightsToCSV() throws {
        // Create test insights
        let insight1 = Insight(
            category: .rebalancing,
            title: "Rebalance Portfolio",
            insightDescription: "Your equity allocation is too high",
            actionable: "Reduce equity by 10%",
            priority: .high,
            impactPercentage: 15.0
        )
        
        let insight2 = Insight(
            category: .taxSaving,
            title: "Tax Saving Opportunity",
            insightDescription: "Invest in 80C for tax benefits",
            actionable: "Invest in ELSS",
            priority: .medium,
            impactAmount: 45000
        )
        
        let csv = try exportService.exportInsightsToCSV([insight1, insight2])
        
        // Verify CSV structure
        XCTAssertTrue(csv.contains("Portfolio Insights Report"))
        XCTAssertTrue(csv.contains("Category"))
        XCTAssertTrue(csv.contains("Priority"))
        XCTAssertTrue(csv.contains("Title"))
        XCTAssertTrue(csv.contains("Description"))
        XCTAssertTrue(csv.contains("Action"))
        XCTAssertTrue(csv.contains("Rebalance Portfolio"))
        XCTAssertTrue(csv.contains("Tax Saving Opportunity"))
    }
    
    @MainActor
    func testExportInsightsToCSV_FiltersDismissed() throws {
        // Create insight that should be filtered
        let dismissedInsight = Insight(
            category: .rebalancing,
            title: "Dismissed Insight",
            insightDescription: "This was dismissed",
            priority: .low
        )
        dismissedInsight.dismiss()
        
        let activeInsight = Insight(
            category: .taxSaving,
            title: "Active Insight",
            insightDescription: "This is active",
            priority: .high
        )
        
        let csv = try exportService.exportInsightsToCSV([dismissedInsight, activeInsight])
        
        // Dismissed insight should not appear
        XCTAssertFalse(csv.contains("Dismissed Insight"))
        XCTAssertTrue(csv.contains("Active Insight"))
    }
    
    // MARK: - Portfolio Allocation Export Tests
    
    func testExportPortfolioAllocationToCSV() throws {
        // Create test assets
        let equity = CrossBorderAsset(
            name: "Equity Portfolio",
            assetType: .mutualFundsEquity,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 600000,
            nativeCurrencyCode: "INR"
        )
        
        let debt = CrossBorderAsset(
            name: "Debt Funds",
            assetType: .bonds,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 300000,
            nativeCurrencyCode: "INR"
        )
        
        let gold = CrossBorderAsset(
            name: "Gold ETF",
            assetType: .gold,
            domicileCountryCode: "IN",
            ownerCountryCode: "IN",
            currentValue: 100000,
            nativeCurrencyCode: "INR"
        )
        
        let csv = try exportService.exportPortfolioAllocationToCSV(assets: [equity, debt, gold])
        
        // Verify CSV structure
        XCTAssertTrue(csv.contains("Portfolio Allocation Report"))
        XCTAssertTrue(csv.contains("Asset Name"))
        XCTAssertTrue(csv.contains("Category"))
        XCTAssertTrue(csv.contains("Current Value"))
        XCTAssertTrue(csv.contains("Percentage"))
        XCTAssertTrue(csv.contains("Equity Portfolio"))
        XCTAssertTrue(csv.contains("60.00%")) // 600k/1M = 60%
        XCTAssertTrue(csv.contains("Allocation by Category"))
        XCTAssertTrue(csv.contains("Total Portfolio Value"))
        XCTAssertTrue(csv.contains("1000000")) // Total value
    }
    
    // MARK: - File Operations Tests
    
    func testGenerateFileName() {
        let fileName = exportService.generateFileName(for: .taxReport, format: "csv")
        
        // Verify file name format
        XCTAssertTrue(fileName.hasPrefix("WealthWise_"))
        XCTAssertTrue(fileName.contains("tax_report"))
        XCTAssertTrue(fileName.hasSuffix(".csv"))
    }
    
    func testSaveToFile() throws {
        let content = "Test CSV Content\nRow 1\nRow 2"
        let fileName = "test_report.csv"
        
        // Save to file
        let fileURL = try exportService.saveToFile(content, fileName: fileName)
        
        // Verify file was created
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Read content back
        let savedContent = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(savedContent, content)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // MARK: - CSV Format Tests
    
    func testCSVFormat_ProperEscaping() throws {
        // Create breakdown with special characters
        let breakdown = DividendIncomeBreakdown(
            assetName: "Fund with \"Quotes\" and, Commas",
            dividendDate: Date(),
            dividendAmount: 1000,
            tdsDeducted: 100
        )
        
        let csv = try exportService.exportDividendIncomeToCSV([breakdown])
        
        // Verify proper escaping - quotes should be escaped
        XCTAssertTrue(csv.contains("\"Fund with \"\"Quotes\"\" and, Commas\""))
    }
    
    func testCSVFormat_NumberFormatting() throws {
        // Create tax calculation with decimal values
        let taxCalc = TaxCalculation(
            financialYear: "2024-25",
            shortTermCapitalGains: 123456.78,
            longTermCapitalGains: 987654.32
        )
        
        let csv = try exportService.exportTaxCalculationToCSV(taxCalc)
        
        // Verify numbers are in export format (no grouping, standard decimal)
        XCTAssertTrue(csv.contains("123456.78") || csv.contains("123456"))
        XCTAssertTrue(csv.contains("987654.32") || csv.contains("987654"))
    }
    
    // MARK: - Performance Tests
    
    func testExportPerformance_LargeDataset() throws {
        // Create large dataset
        var breakdowns: [CapitalGainsBreakdown] = []
        
        for i in 0..<1000 {
            let breakdown = CapitalGainsBreakdown(
                assetName: "Asset \(i)",
                assetType: "stocks",
                purchaseDate: Date(timeIntervalSinceNow: -Double(i * 24 * 60 * 60)),
                saleDate: Date(),
                purchasePrice: Decimal(100000 + i * 100),
                salePrice: Decimal(120000 + i * 120)
            )
            breakdowns.append(breakdown)
        }
        
        measure {
            _ = try? exportService.exportCapitalGainsToCSV(breakdowns)
        }
    }
}
