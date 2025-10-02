//
//  PortfolioManagementTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Tests for Portfolio Management Module - Issue #4
//

import XCTest
import SwiftData
@testable import WealthWise

@MainActor
final class PortfolioManagementTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var portfolioService: PortfolioService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            Portfolio.self,
            Holding.self,
            PortfolioTransaction.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        portfolioService = PortfolioService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
        portfolioService = nil
        try await super.tearDown()
    }
    
    // MARK: - Portfolio CRUD Tests
    
    func testCreatePortfolio() async throws {
        // Given
        let portfolio = Portfolio(
            name: "Test Portfolio",
            portfolioDescription: "A test portfolio for unit testing",
            portfolioType: .diversified,
            baseCurrency: "INR",
            riskProfile: .moderate
        )
        
        // When
        try await portfolioService.createPortfolio(portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        XCTAssertNotNil(fetchedPortfolio)
        XCTAssertEqual(fetchedPortfolio?.name, "Test Portfolio")
        XCTAssertEqual(fetchedPortfolio?.portfolioType, .diversified)
        XCTAssertEqual(fetchedPortfolio?.baseCurrency, "INR")
        XCTAssertEqual(fetchedPortfolio?.riskProfile, .moderate)
    }
    
    func testUpdatePortfolio() async throws {
        // Given
        let portfolio = Portfolio(name: "Original Name", portfolioType: .equity)
        try await portfolioService.createPortfolio(portfolio)
        
        // When
        portfolio.name = "Updated Name"
        portfolio.portfolioType = .growth
        try await portfolioService.updatePortfolio(portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        XCTAssertEqual(fetchedPortfolio?.name, "Updated Name")
        XCTAssertEqual(fetchedPortfolio?.portfolioType, .growth)
    }
    
    func testDeletePortfolio() async throws {
        // Given
        let portfolio = Portfolio(name: "To Be Deleted")
        try await portfolioService.createPortfolio(portfolio)
        
        // When
        try await portfolioService.deletePortfolio(portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        XCTAssertNil(fetchedPortfolio)
    }
    
    func testCreatePortfolioWithInvalidName() async throws {
        // Given
        let portfolio = Portfolio(name: "   ", portfolioType: .diversified)
        
        // When/Then
        do {
            try await portfolioService.createPortfolio(portfolio)
            XCTFail("Should throw invalidPortfolioName error")
        } catch PortfolioError.invalidPortfolioName {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Holding CRUD Tests
    
    func testAddHoldingToPortfolio() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let holding = Holding(
            symbol: "RELIANCE",
            name: "Reliance Industries",
            assetType: .publicEquityDomestic,
            assetClass: "Stock",
            quantity: 10,
            averageCost: 2400,
            currentPrice: 2450
        )
        
        // When
        try await portfolioService.addHolding(holding, to: portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        XCTAssertEqual(fetchedPortfolio?.holdings.count, 1)
        XCTAssertEqual(fetchedPortfolio?.holdings.first?.symbol, "RELIANCE")
    }
    
    func testRemoveHoldingFromPortfolio() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let holding = Holding(
            symbol: "TCS",
            name: "Tata Consultancy Services",
            assetType: .publicEquityDomestic,
            assetClass: "Stock",
            quantity: 5,
            averageCost: 3600,
            currentPrice: 3620
        )
        
        try await portfolioService.addHolding(holding, to: portfolio)
        
        // When
        try await portfolioService.removeHolding(holding, from: portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        XCTAssertEqual(fetchedPortfolio?.holdings.count, 0)
    }
    
    func testAddDuplicateHolding() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let holding1 = Holding(symbol: "INFY", name: "Infosys", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 1500, currentPrice: 1545)
        let holding2 = Holding(symbol: "INFY", name: "Infosys", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 5, averageCost: 1520, currentPrice: 1545)
        
        try await portfolioService.addHolding(holding1, to: portfolio)
        
        // When/Then
        do {
            try await portfolioService.addHolding(holding2, to: portfolio)
            XCTFail("Should throw duplicateHolding error")
        } catch PortfolioError.duplicateHolding(let symbol) {
            XCTAssertEqual(symbol, "INFY")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Transaction Tests
    
    func testBuyTransaction() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let transaction = PortfolioTransaction(
            transactionType: .buy,
            symbol: "HDFCBANK",
            assetName: "HDFC Bank",
            date: Date(),
            quantity: 20,
            pricePerUnit: 1650,
            currency: "INR"
        )
        
        // When
        try await portfolioService.addTransaction(transaction, to: portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        XCTAssertEqual(fetchedPortfolio?.holdings.count, 1)
        XCTAssertEqual(fetchedPortfolio?.holdings.first?.symbol, "HDFCBANK")
        XCTAssertEqual(fetchedPortfolio?.holdings.first?.quantity, 20)
        XCTAssertEqual(fetchedPortfolio?.holdings.first?.averageCost, 1650)
        XCTAssertEqual(fetchedPortfolio?.transactions.count, 1)
    }
    
    func testMultipleBuyTransactions() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let transaction1 = PortfolioTransaction(
            transactionType: .buy,
            symbol: "ICICIBANK",
            assetName: "ICICI Bank",
            quantity: 10,
            pricePerUnit: 980,
            currency: "INR"
        )
        
        let transaction2 = PortfolioTransaction(
            transactionType: .buy,
            symbol: "ICICIBANK",
            assetName: "ICICI Bank",
            quantity: 15,
            pricePerUnit: 990,
            currency: "INR"
        )
        
        // When
        try await portfolioService.addTransaction(transaction1, to: portfolio)
        try await portfolioService.addTransaction(transaction2, to: portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        let holding = fetchedPortfolio?.holdings.first
        
        XCTAssertEqual(holding?.quantity, 25) // 10 + 15
        
        // Average cost should be weighted: (10*980 + 15*990) / 25 = 986
        let expectedAvgCost = Decimal((10 * 980 + 15 * 990)) / 25
        XCTAssertEqual(holding?.averageCost, expectedAvgCost)
    }
    
    func testSellTransaction() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        // First buy some shares
        let buyTransaction = PortfolioTransaction(
            transactionType: .buy,
            symbol: "ITC",
            assetName: "ITC Limited",
            quantity: 100,
            pricePerUnit: 400,
            currency: "INR"
        )
        try await portfolioService.addTransaction(buyTransaction, to: portfolio)
        
        // Update current price
        let holding = portfolio.holdings.first!
        holding.updatePrice(420)
        
        // When - sell some shares
        let sellTransaction = PortfolioTransaction(
            transactionType: .sell,
            symbol: "ITC",
            assetName: "ITC Limited",
            quantity: 40,
            pricePerUnit: 420,
            currency: "INR"
        )
        try await portfolioService.addTransaction(sellTransaction, to: portfolio)
        
        // Then
        let fetchedPortfolio = try await portfolioService.getPortfolio(by: portfolio.id)
        let updatedHolding = fetchedPortfolio?.holdings.first
        
        XCTAssertEqual(updatedHolding?.quantity, 60) // 100 - 40
        
        // Check realized gain/loss
        let transaction = fetchedPortfolio?.transactions.last
        XCTAssertNotNil(transaction?.realizedGainLoss)
        
        // Realized gain = (420 - 400) * 40 = 800
        let expectedGain = Decimal((420 - 400) * 40)
        XCTAssertEqual(transaction?.realizedGainLoss, expectedGain)
    }
    
    func testSellMoreThanAvailable() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let buyTransaction = PortfolioTransaction(
            transactionType: .buy,
            symbol: "SBIN",
            assetName: "State Bank of India",
            quantity: 10,
            pricePerUnit: 600,
            currency: "INR"
        )
        try await portfolioService.addTransaction(buyTransaction, to: portfolio)
        
        // When/Then - try to sell more than available
        let sellTransaction = PortfolioTransaction(
            transactionType: .sell,
            symbol: "SBIN",
            assetName: "State Bank of India",
            quantity: 20, // More than available
            pricePerUnit: 620,
            currency: "INR"
        )
        
        do {
            try await portfolioService.addTransaction(sellTransaction, to: portfolio)
            XCTFail("Should throw insufficientQuantity error")
        } catch PortfolioError.insufficientQuantity(let symbol, let available) {
            XCTAssertEqual(symbol, "SBIN")
            XCTAssertEqual(available, 10)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - P&L Calculation Tests
    
    func testUnrealizedGainLossCalculation() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let holding = Holding(
            symbol: "BHARTIARTL",
            name: "Bharti Airtel",
            assetType: .publicEquityDomestic,
            assetClass: "Stock",
            quantity: 50,
            averageCost: 1250, // Bought at 1250
            currentPrice: 1285  // Now at 1285
        )
        
        try await portfolioService.addHolding(holding, to: portfolio)
        
        // When
        let portfolioValue = portfolioService.calculatePortfolioValue(portfolio)
        
        // Then
        let expectedCost = Decimal(50 * 1250) // 62,500
        let expectedValue = Decimal(50 * 1285) // 64,250
        let expectedGain = expectedValue - expectedCost // 1,750
        let expectedGainPct = Double(truncating: (expectedGain / expectedCost * 100) as NSDecimalNumber) // 2.8%
        
        XCTAssertEqual(portfolioValue.totalCost, expectedCost)
        XCTAssertEqual(portfolioValue.totalValue, expectedValue)
        XCTAssertEqual(portfolioValue.unrealizedGainLoss, expectedGain)
        XCTAssertEqual(portfolioValue.unrealizedGainLossPercentage, expectedGainPct, accuracy: 0.01)
    }
    
    func testRealizedGainsCalculation() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        // Buy transaction
        let buyTransaction = PortfolioTransaction(
            transactionType: .buy,
            symbol: "LT",
            assetName: "Larsen & Toubro",
            quantity: 30,
            pricePerUnit: 3000,
            currency: "INR"
        )
        try await portfolioService.addTransaction(buyTransaction, to: portfolio)
        
        // Update price
        let holding = portfolio.holdings.first!
        holding.updatePrice(3215)
        
        // Sell transaction
        let sellTransaction = PortfolioTransaction(
            transactionType: .sell,
            symbol: "LT",
            assetName: "Larsen & Toubro",
            quantity: 10,
            pricePerUnit: 3215,
            currency: "INR"
        )
        try await portfolioService.addTransaction(sellTransaction, to: portfolio)
        
        // When
        let portfolioValue = portfolioService.calculatePortfolioValue(portfolio)
        
        // Then
        let expectedRealizedGain = Decimal((3215 - 3000) * 10) // 2,150
        XCTAssertEqual(portfolioValue.realizedGains, expectedRealizedGain)
    }
    
    func testPortfolioWithMultipleHoldings() async throws {
        // Given
        let portfolio = Portfolio(name: "Diversified Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let holdings = [
            Holding(symbol: "RELIANCE", name: "Reliance", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 2400, currentPrice: 2450),
            Holding(symbol: "TCS", name: "TCS", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 5, averageCost: 3600, currentPrice: 3620),
            Holding(symbol: "INFY", name: "Infosys", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 15, averageCost: 1500, currentPrice: 1545),
            Holding(symbol: "HDFCBANK", name: "HDFC Bank", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 20, averageCost: 1650, currentPrice: 1650)
        ]
        
        for holding in holdings {
            try await portfolioService.addHolding(holding, to: portfolio)
        }
        
        // When
        let portfolioValue = portfolioService.calculatePortfolioValue(portfolio)
        
        // Then
        let expectedCost = Decimal(10*2400 + 5*3600 + 15*1500 + 20*1650) // 93,000
        let expectedValue = Decimal(10*2450 + 5*3620 + 15*1545 + 20*1650) // 95,675
        
        XCTAssertEqual(portfolioValue.totalCost, expectedCost)
        XCTAssertEqual(portfolioValue.totalValue, expectedValue)
        XCTAssertGreaterThan(portfolioValue.unrealizedGainLoss, 0)
    }
    
    // MARK: - Performance Metrics Tests
    
    func testPerformanceMetricsCalculation() async throws {
        // Given
        let portfolio = Portfolio(name: "Test Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        let holdings = [
            Holding(symbol: "RELIANCE", name: "Reliance", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 2400, currentPrice: 2450),
            Holding(symbol: "TCS", name: "TCS", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 5, averageCost: 3600, currentPrice: 3620),
            Holding(symbol: "INFY", name: "Infosys", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 15, averageCost: 1500, currentPrice: 1545)
        ]
        
        for holding in holdings {
            try await portfolioService.addHolding(holding, to: portfolio)
        }
        
        // When
        let metrics = portfolioService.calculatePerformanceMetrics(portfolio)
        
        // Then
        XCTAssertNotNil(metrics.xirr)
        XCTAssertGreaterThan(metrics.absoluteReturn, 0)
        XCTAssertGreaterThan(metrics.diversificationScore, 0)
        XCTAssertLessThanOrEqual(metrics.diversificationScore, 100)
        XCTAssertEqual(metrics.totalHoldings, 3)
        XCTAssertEqual(metrics.topHoldings.count, 3)
    }
    
    func testDiversificationScore() async throws {
        // Given - Concentrated portfolio (one large holding)
        let concentratedPortfolio = Portfolio(name: "Concentrated")
        try await portfolioService.createPortfolio(concentratedPortfolio)
        
        let concentratedHolding = Holding(symbol: "RELIANCE", name: "Reliance", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 100, averageCost: 2400, currentPrice: 2450)
        try await portfolioService.addHolding(concentratedHolding, to: concentratedPortfolio)
        
        // Given - Diversified portfolio (multiple holdings)
        let diversifiedPortfolio = Portfolio(name: "Diversified")
        try await portfolioService.createPortfolio(diversifiedPortfolio)
        
        let diversifiedHoldings = [
            Holding(symbol: "RELIANCE", name: "Reliance", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 2400, currentPrice: 2450),
            Holding(symbol: "TCS", name: "TCS", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 3600, currentPrice: 3620),
            Holding(symbol: "INFY", name: "Infosys", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 15, averageCost: 1500, currentPrice: 1545),
            Holding(symbol: "HDFCBANK", name: "HDFC Bank", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 20, averageCost: 1650, currentPrice: 1650),
            Holding(symbol: "ICICIBANK", name: "ICICI Bank", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 25, averageCost: 980, currentPrice: 985)
        ]
        
        for holding in diversifiedHoldings {
            try await portfolioService.addHolding(holding, to: diversifiedPortfolio)
        }
        
        // When
        let concentratedMetrics = portfolioService.calculatePerformanceMetrics(concentratedPortfolio)
        let diversifiedMetrics = portfolioService.calculatePerformanceMetrics(diversifiedPortfolio)
        
        // Then
        XCTAssertLessThan(concentratedMetrics.diversificationScore, diversifiedMetrics.diversificationScore)
    }
    
    // MARK: - Holding Helper Method Tests
    
    func testHoldingAddUnits() {
        // Given
        let holding = Holding(
            symbol: "TEST",
            name: "Test Stock",
            assetType: .publicEquityDomestic,
            assetClass: "Stock",
            quantity: 10,
            averageCost: 100,
            currentPrice: 110
        )
        
        // When
        holding.addUnits(quantity: 5, costPerUnit: 105)
        
        // Then
        XCTAssertEqual(holding.quantity, 15)
        
        // Average cost = (10*100 + 5*105) / 15 = 101.67
        let expectedAvgCost = Decimal((10*100 + 5*105)) / 15
        XCTAssertEqual(holding.averageCost, expectedAvgCost)
    }
    
    func testHoldingRemoveUnits() {
        // Given
        let holding = Holding(
            symbol: "TEST",
            name: "Test Stock",
            assetType: .publicEquityDomestic,
            assetClass: "Stock",
            quantity: 20,
            averageCost: 100,
            currentPrice: 120
        )
        
        // When
        let realizedGainLoss = holding.removeUnits(quantity: 10)
        
        // Then
        XCTAssertEqual(holding.quantity, 10)
        XCTAssertNotNil(realizedGainLoss)
        
        // Realized gain = (120 - 100) * 10 = 200
        let expectedGain = Decimal((120 - 100) * 10)
        XCTAssertEqual(realizedGainLoss, expectedGain)
    }
    
    func testHoldingUpdatePrice() {
        // Given
        let holding = Holding(
            symbol: "TEST",
            name: "Test Stock",
            assetType: .publicEquityDomestic,
            assetClass: "Stock",
            quantity: 10,
            averageCost: 100,
            currentPrice: 100
        )
        
        let oldUpdateTime = holding.lastPriceUpdate
        
        // When
        holding.updatePrice(120)
        
        // Then
        XCTAssertEqual(holding.currentPrice, 120)
        XCTAssertNotEqual(holding.lastPriceUpdate, oldUpdateTime)
    }
    
    // MARK: - Performance Tests
    
    func testPortfolioCreationPerformance() {
        measure {
            let portfolio = Portfolio(name: "Performance Test")
            XCTAssertNotNil(portfolio)
        }
    }
    
    func testHoldingCreationPerformance() {
        measure {
            let holding = Holding(
                symbol: "TEST",
                name: "Test Stock",
                assetType: .publicEquityDomestic,
                assetClass: "Stock",
                quantity: 10,
                averageCost: 100,
                currentPrice: 110
            )
            XCTAssertNotNil(holding)
        }
    }
    
    func testPortfolioValueCalculationPerformance() async throws {
        // Given - Portfolio with many holdings
        let portfolio = Portfolio(name: "Large Portfolio")
        try await portfolioService.createPortfolio(portfolio)
        
        for i in 1...50 {
            let holding = Holding(
                symbol: "STOCK\(i)",
                name: "Stock \(i)",
                assetType: .publicEquityDomestic,
                assetClass: "Stock",
                quantity: Decimal(Int.random(in: 10...100)),
                averageCost: Decimal(Int.random(in: 100...5000)),
                currentPrice: Decimal(Int.random(in: 100...5000))
            )
            try await portfolioService.addHolding(holding, to: portfolio)
        }
        
        // When/Then
        measure {
            let _ = portfolioService.calculatePortfolioValue(portfolio)
        }
    }
}
