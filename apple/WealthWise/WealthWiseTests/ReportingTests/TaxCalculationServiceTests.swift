//
//  TaxCalculationServiceTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Tax Calculation Service Tests
//

import XCTest
import SwiftData
@testable import WealthWise

@available(iOS 18.6, macOS 15.6, *)
final class TaxCalculationServiceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var taxService: TaxCalculationService!
    
    @MainActor
    override func setUp() async throws {
        // Create in-memory model container
        let schema = Schema([
            Transaction.self,
            Goal.self,
            Report.self,
            TaxCalculation.self,
            Insight.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        
        taxService = TaxCalculationService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        taxService = nil
    }
    
    // MARK: - Capital Gains Tests
    
    @MainActor
    func testCalculateCapitalGains_ShortTerm() async throws {
        // Create test transactions with short-term gains
        let transaction = Transaction(
            amount: 120000, // Sale price
            transactionDescription: "Stock sale",
            date: Date(),
            transactionType: .capital_gain,
            category: .stocks
        )
        transaction.linkToAsset(assetId: "AAPL", units: 10, pricePerUnit: 10000) // Purchase price: 100,000
        
        let breakdowns = taxService.calculateCapitalGains(from: [transaction])
        
        XCTAssertEqual(breakdowns.count, 1)
        XCTAssertFalse(breakdowns[0].isLongTerm)
        XCTAssertEqual(breakdowns[0].capitalGain, 20000) // 120k - 100k
        XCTAssertEqual(breakdowns[0].taxRate, 15.0)
    }
    
    @MainActor
    func testCalculateCapitalGains_LongTerm() async throws {
        // Create test transaction with long-term gain
        let purchaseDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let transaction = Transaction(
            amount: 150000, // Sale price
            transactionDescription: "Stock sale",
            date: Date(),
            transactionType: .capital_gain,
            category: .stocks
        )
        transaction.linkToAsset(assetId: "GOOGL", units: 10, pricePerUnit: 10000)
        
        let breakdowns = taxService.calculateCapitalGains(from: [transaction])
        
        XCTAssertEqual(breakdowns.count, 1)
        XCTAssertTrue(breakdowns[0].isLongTerm)
        XCTAssertEqual(breakdowns[0].taxRate, 10.0)
    }
    
    // MARK: - Dividend Income Tests
    
    @MainActor
    func testCalculateDividendIncome() async throws {
        // Create test dividend transactions
        let dividend1 = Transaction(
            amount: 5000,
            transactionDescription: "Dividend from mutual fund",
            date: Date(),
            transactionType: .dividend,
            category: .dividend_income
        )
        dividend1.tdsAmount = 500 // 10% TDS
        
        let dividend2 = Transaction(
            amount: 3000,
            transactionDescription: "Stock dividend",
            date: Date(),
            transactionType: .dividend,
            category: .dividend_income
        )
        dividend2.tdsAmount = 300
        
        let breakdowns = taxService.calculateDividendIncome(from: [dividend1, dividend2])
        
        XCTAssertEqual(breakdowns.count, 2)
        XCTAssertEqual(breakdowns[0].dividendAmount, 5000)
        XCTAssertEqual(breakdowns[0].tdsDeducted, 500)
        XCTAssertEqual(breakdowns[0].netDividend, 4500)
        XCTAssertEqual(breakdowns[1].dividendAmount, 3000)
    }
    
    // MARK: - Interest Income Tests
    
    @MainActor
    func testCalculateInterestIncome() async throws {
        // Create test interest transactions
        let interest1 = Transaction(
            amount: 12000,
            transactionDescription: "FD interest",
            date: Date(),
            transactionType: .interest,
            category: .bonds
        )
        interest1.tdsAmount = 1200
        
        let interest2 = Transaction(
            amount: 800,
            transactionDescription: "Savings account interest",
            date: Date(),
            transactionType: .interest,
            category: .salary // Will default to savings account
        )
        
        let breakdowns = taxService.calculateInterestIncome(from: [interest1, interest2])
        
        XCTAssertEqual(breakdowns.count, 2)
        XCTAssertEqual(breakdowns[0].interestAmount, 12000)
        XCTAssertEqual(breakdowns[0].sourceType, .bonds)
        XCTAssertEqual(breakdowns[1].sourceType, .savingsAccount)
    }
    
    // MARK: - Tax Calculation Tests
    
    @MainActor
    func testCalculateTax_ComprehensiveReport() async throws {
        // Create comprehensive set of transactions for a financial year
        let calendar = Calendar.current
        var fyComponents = DateComponents()
        fyComponents.year = 2024
        fyComponents.month = 4
        fyComponents.day = 1
        let fyStart = calendar.date(from: fyComponents)!
        
        // Capital gains transaction
        let capitalGain = Transaction(
            amount: 150000,
            transactionDescription: "Stock sale gain",
            date: fyStart,
            transactionType: .capital_gain,
            category: .stocks
        )
        capitalGain.linkToAsset(assetId: "MSFT", units: 10, pricePerUnit: 10000)
        
        // Dividend transaction
        let dividend = Transaction(
            amount: 20000,
            transactionDescription: "Mutual fund dividend",
            date: calendar.date(byAdding: .month, value: 3, to: fyStart)!,
            transactionType: .dividend,
            category: .dividend_income
        )
        dividend.tdsAmount = 2000
        
        // Interest transaction
        let interest = Transaction(
            amount: 30000,
            transactionDescription: "FD interest",
            date: calendar.date(byAdding: .month, value: 6, to: fyStart)!,
            transactionType: .interest,
            category: .bonds
        )
        interest.tdsAmount = 3000
        
        // Tax saving investment
        let taxSaving = Transaction(
            amount: 100000,
            transactionDescription: "ELSS investment",
            date: calendar.date(byAdding: .month, value: 9, to: fyStart)!,
            transactionType: .investment,
            category: .tax_saving_investment
        )
        
        // Health insurance
        let healthInsurance = Transaction(
            amount: 15000,
            transactionDescription: "Health insurance premium",
            date: calendar.date(byAdding: .month, value: 10, to: fyStart)!,
            transactionType: .expense,
            category: .health_insurance
        )
        
        let transactions = [capitalGain, dividend, interest, taxSaving, healthInsurance]
        
        // Calculate tax
        let taxCalc = try await taxService.calculateTax(
            for: "2024-25",
            transactions: transactions
        )
        
        // Verify calculations
        XCTAssertEqual(taxCalc.financialYear, "2024-25")
        XCTAssertGreaterThan(taxCalc.shortTermCapitalGains, 0)
        XCTAssertEqual(taxCalc.totalDividendIncome, 20000)
        XCTAssertEqual(taxCalc.totalInterestIncome, 30000)
        XCTAssertEqual(taxCalc.section80CDeductions, 100000)
        XCTAssertEqual(taxCalc.section80DDeductions, 15000)
        XCTAssertGreaterThan(taxCalc.grossIncome, 0)
        XCTAssertGreaterThan(taxCalc.taxOwed, 0)
    }
    
    @MainActor
    func testGetCurrentFinancialYear() {
        let currentFY = taxService.getCurrentFinancialYear()
        
        // Verify format is correct (e.g., "2024-25")
        XCTAssertTrue(currentFY.contains("-"))
        let components = currentFY.split(separator: "-")
        XCTAssertEqual(components.count, 2)
        
        // Verify years are consecutive
        if let year1 = Int(components[0]),
           let year2 = Int("20\(components[1])") {
            XCTAssertEqual(year2, year1 + 1)
        } else {
            XCTFail("Invalid financial year format")
        }
    }
    
    // MARK: - Deduction Tests
    
    @MainActor
    func testCalculate80CDeductions_BelowLimit() async throws {
        // Create tax saving investments below limit
        let transaction1 = Transaction(
            amount: 50000,
            transactionDescription: "PPF investment",
            date: Date(),
            transactionType: .investment,
            category: .tax_saving_investment
        )
        
        let transaction2 = Transaction(
            amount: 30000,
            transactionDescription: "ELSS investment",
            date: Date(),
            transactionType: .investment,
            category: .tax_saving_investment
        )
        
        // The service calculates deductions internally in calculateTax
        // We can verify by creating a full tax calculation
        let taxCalc = try await taxService.calculateTax(
            for: "2024-25",
            transactions: [transaction1, transaction2]
        )
        
        XCTAssertEqual(taxCalc.section80CDeductions, 80000) // Total of both investments
    }
    
    @MainActor
    func testCalculate80CDeductions_AboveLimit() async throws {
        // Create tax saving investments above limit
        let transaction = Transaction(
            amount: 200000,
            transactionDescription: "Large PPF investment",
            date: Date(),
            transactionType: .investment,
            category: .tax_saving_investment
        )
        
        let taxCalc = try await taxService.calculateTax(
            for: "2024-25",
            transactions: [transaction]
        )
        
        XCTAssertEqual(taxCalc.section80CDeductions, 150000) // Capped at limit
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testTaxCalculationPerformance() async throws {
        // Create a large set of transactions
        var transactions: [Transaction] = []
        
        for i in 0..<100 {
            let transaction = Transaction(
                amount: Decimal(10000 + i * 100),
                transactionDescription: "Transaction \(i)",
                date: Date(),
                transactionType: .income,
                category: .salary
            )
            transactions.append(transaction)
        }
        
        measure {
            Task { @MainActor in
                _ = try? await taxService.calculateTax(
                    for: "2024-25",
                    transactions: transactions
                )
            }
        }
    }
}
