//
//  MarketDataServiceTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Tests for Market Data Service - Issue #4
//

import XCTest
@testable import WealthWise

@MainActor
final class MarketDataServiceTests: XCTestCase {
    
    var marketDataService: MarketDataService!
    
    override func setUp() async throws {
        try await super.setUp()
        marketDataService = MarketDataService(isRealTimeEnabled: false) // Use mock data
    }
    
    override func tearDown() async throws {
        marketDataService = nil
        try await super.tearDown()
    }
    
    // MARK: - Mock Data Provider Tests
    
    func testGetCurrentPriceForKnownSymbol() async throws {
        // Given
        let symbol = "RELIANCE"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then
        XCTAssertNotNil(priceData)
        XCTAssertEqual(priceData?.symbol, symbol)
        XCTAssertGreaterThan(priceData?.price ?? 0, 0)
        XCTAssertEqual(priceData?.currency, "INR")
        XCTAssertNotNil(priceData?.timestamp)
        XCTAssertEqual(priceData?.source, "Mock Data")
    }
    
    func testGetCurrentPriceForUSStock() async throws {
        // Given
        let symbol = "AAPL"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then
        XCTAssertNotNil(priceData)
        XCTAssertEqual(priceData?.symbol, symbol)
        XCTAssertEqual(priceData?.currency, "USD")
        XCTAssertGreaterThan(priceData?.price ?? 0, 0)
    }
    
    func testGetCurrentPriceForUnknownSymbol() async throws {
        // Given
        let symbol = "UNKNOWN123"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then - Should still return mock data
        XCTAssertNotNil(priceData)
        XCTAssertEqual(priceData?.symbol, symbol)
        XCTAssertGreaterThan(priceData?.price ?? 0, 0)
    }
    
    func testGetCurrentPriceHasVariation() async throws {
        // Given
        let symbol = "TCS"
        
        // When - Fetch price multiple times
        let price1 = try await marketDataService.getCurrentPrice(symbol: symbol)
        let price2 = try await marketDataService.getCurrentPrice(symbol: symbol)
        let price3 = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then - Prices should vary slightly (within 2% as per mock implementation)
        XCTAssertNotNil(price1)
        XCTAssertNotNil(price2)
        XCTAssertNotNil(price3)
        
        // At least one should be different (statistically very likely)
        let allPricesSame = price1?.price == price2?.price && price2?.price == price3?.price
        XCTAssertFalse(allPricesSame, "Mock prices should have variation")
    }
    
    func testGetCurrentPriceIncludesChangeData() async throws {
        // Given
        let symbol = "INFY"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then
        XCTAssertNotNil(priceData?.change)
        XCTAssertNotNil(priceData?.changePercentage)
        XCTAssertNotNil(priceData?.volume)
    }
    
    // MARK: - Historical Prices Tests
    
    func testGetHistoricalPrices() async throws {
        // Given
        let symbol = "HDFCBANK"
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        // When
        let prices = try await marketDataService.getHistoricalPrices(symbol: symbol, from: startDate, to: endDate)
        
        // Then
        XCTAssertFalse(prices.isEmpty)
        XCTAssertGreaterThanOrEqual(prices.count, 30) // Should have ~30 days of data
        
        // Verify dates are in order
        for i in 0..<(prices.count - 1) {
            XCTAssertLessThanOrEqual(prices[i].timestamp, prices[i+1].timestamp)
        }
        
        // Verify all have the correct symbol
        for price in prices {
            XCTAssertEqual(price.symbol, symbol)
        }
    }
    
    func testHistoricalPricesShowTrend() async throws {
        // Given
        let symbol = "ICICIBANK"
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate)!
        
        // When
        let prices = try await marketDataService.getHistoricalPrices(symbol: symbol, from: startDate, to: endDate)
        
        // Then
        XCTAssertFalse(prices.isEmpty)
        
        // Check for general upward trend (as per mock implementation)
        let firstPrice = prices.first?.price ?? 0
        let lastPrice = prices.last?.price ?? 0
        
        XCTAssertGreaterThan(lastPrice, firstPrice * Decimal(0.95)) // Should not decline more than 5%
    }
    
    // MARK: - Update Multiple Holdings Tests
    
    func testUpdatePricesForHoldings() async throws {
        // Given
        let holdings = [
            Holding(symbol: "RELIANCE", name: "Reliance", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 2400, currentPrice: 2400),
            Holding(symbol: "TCS", name: "TCS", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 5, averageCost: 3600, currentPrice: 3600),
            Holding(symbol: "INFY", name: "Infosys", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 15, averageCost: 1500, currentPrice: 1500)
        ]
        
        let oldPrices = holdings.map { $0.currentPrice }
        
        // When
        try await marketDataService.updatePrices(for: holdings)
        
        // Then
        XCTAssertNotNil(marketDataService.lastUpdateTime)
        
        // At least some prices should have changed (statistically very likely)
        let newPrices = holdings.map { $0.currentPrice }
        XCTAssertNotEqual(oldPrices, newPrices)
        
        // All holdings should have updated prices
        for holding in holdings {
            XCTAssertGreaterThan(holding.currentPrice, 0)
            XCTAssertNotNil(holding.lastPriceUpdate)
        }
    }
    
    func testUpdatePricesHandlesFailureGracefully() async throws {
        // Given - Even with potential failures, should continue updating others
        let holdings = [
            Holding(symbol: "VALID1", name: "Valid 1", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 100, currentPrice: 100),
            Holding(symbol: "VALID2", name: "Valid 2", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 200, currentPrice: 200),
            Holding(symbol: "VALID3", name: "Valid 3", assetType: .publicEquityDomestic, assetClass: "Stock", quantity: 10, averageCost: 300, currentPrice: 300)
        ]
        
        // When
        try await marketDataService.updatePrices(for: holdings)
        
        // Then - All should be processed despite any individual failures
        for holding in holdings {
            XCTAssertGreaterThan(holding.currentPrice, 0)
        }
    }
    
    // MARK: - Real-time Toggle Tests
    
    func testToggleRealTimeMode() async throws {
        // Given
        let service = MarketDataService(isRealTimeEnabled: false)
        XCTAssertFalse(service.isRealTimeEnabled)
        
        // When
        service.isRealTimeEnabled = true
        
        // Then
        XCTAssertTrue(service.isRealTimeEnabled)
        
        // Should still work (will fallback to mock in current implementation)
        let priceData = try await service.getCurrentPrice(symbol: "RELIANCE")
        XCTAssertNotNil(priceData)
    }
    
    func testDefaultMockMode() {
        // Given/When
        let service = MarketDataService()
        
        // Then
        XCTAssertFalse(service.isRealTimeEnabled) // Should default to mock/offline mode
    }
    
    // MARK: - ETF and Mutual Fund Tests
    
    func testGetPriceForETF() async throws {
        // Given
        let symbol = "NIFTYBEES"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then
        XCTAssertNotNil(priceData)
        XCTAssertEqual(priceData?.symbol, symbol)
        XCTAssertGreaterThan(priceData?.price ?? 0, 0)
    }
    
    func testGetPriceForMutualFund() async throws {
        // Given
        let symbol = "HDFC-TOP-100"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then
        XCTAssertNotNil(priceData)
        XCTAssertEqual(priceData?.symbol, symbol)
        XCTAssertGreaterThan(priceData?.price ?? 0, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testServiceTracksErrors() async throws {
        // Given
        let service = MarketDataService(isRealTimeEnabled: false)
        
        // When - Fetch data successfully
        let _ = try await service.getCurrentPrice(symbol: "RELIANCE")
        
        // Then - Should have no errors
        XCTAssertNil(service.error)
    }
    
    // MARK: - Performance Tests
    
    func testGetCurrentPricePerformance() {
        measure {
            Task {
                let _ = try? await marketDataService.getCurrentPrice(symbol: "RELIANCE")
            }
        }
    }
    
    func testGetHistoricalPricesPerformance() {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        measure {
            Task {
                let _ = try? await marketDataService.getHistoricalPrices(symbol: "TCS", from: startDate, to: endDate)
            }
        }
    }
    
    func testUpdateMultipleHoldingsPerformance() {
        let holdings = (1...20).map { i in
            Holding(
                symbol: "STOCK\(i)",
                name: "Stock \(i)",
                assetType: .publicEquityDomestic,
                assetClass: "Stock",
                quantity: 10,
                averageCost: 100,
                currentPrice: 100
            )
        }
        
        measure {
            Task {
                try? await marketDataService.updatePrices(for: holdings)
            }
        }
    }
    
    // MARK: - Price Data Tests
    
    func testPriceDataStructure() async throws {
        // Given
        let symbol = "BHARTIARTL"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then - Verify all required fields
        XCTAssertNotNil(priceData)
        XCTAssertEqual(priceData?.symbol, symbol)
        XCTAssertGreaterThan(priceData?.price ?? 0, 0)
        XCTAssertFalse(priceData?.currency.isEmpty ?? true)
        XCTAssertNotNil(priceData?.timestamp)
        XCTAssertFalse(priceData?.source.isEmpty ?? true)
    }
    
    func testPriceDataIsReasonable() async throws {
        // Given
        let symbol = "RELIANCE"
        
        // When
        let priceData = try await marketDataService.getCurrentPrice(symbol: symbol)
        
        // Then - Price should be in reasonable range for Indian stocks
        XCTAssertNotNil(priceData)
        XCTAssertGreaterThan(priceData?.price ?? 0, 10) // Above ₹10
        XCTAssertLessThan(priceData?.price ?? 100000, 10000) // Below ₹10,000
    }
}
