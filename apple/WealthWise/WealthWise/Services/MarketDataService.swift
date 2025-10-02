//
//  MarketDataService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Portfolio Management System: Market data integration service
//

import Foundation
import OSLog

/// Market data service protocol for real-time and historical price data
@available(iOS 18.6, macOS 15.6, *)
public protocol MarketDataServiceProtocol {
    func getCurrentPrice(symbol: String) async throws -> PriceData?
    func getHistoricalPrices(symbol: String, from: Date, to: Date) async throws -> [PriceData]
    func updatePrices(for holdings: [Holding]) async throws
}

/// Market data service implementation with toggle for real-time vs. offline mode
@available(iOS 18.6, macOS 15.6, *)
@Observable
public final class MarketDataService: MarketDataServiceProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.wealthwise.app", category: "MarketDataService")
    private var provider: MarketDataProvider
    
    /// Toggle for real-time data (true) vs. offline/mock data (false)
    public var isRealTimeEnabled: Bool {
        didSet {
            updateProvider()
        }
    }
    
    public private(set) var isLoading: Bool = false
    public private(set) var error: MarketDataError?
    public private(set) var lastUpdateTime: Date?
    
    // MARK: - Initialization
    
    public init(isRealTimeEnabled: Bool = false) {
        self.isRealTimeEnabled = isRealTimeEnabled
        self.provider = isRealTimeEnabled ? RealTimeMarketDataProvider() : MockMarketDataProvider()
    }
    
    // MARK: - Public Methods
    
    /// Get current price for a symbol
    public func getCurrentPrice(symbol: String) async throws -> PriceData? {
        logger.info("Fetching current price for: \(symbol)")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let price = try await provider.getCurrentPrice(symbol: symbol)
            lastUpdateTime = Date()
            return price
        } catch {
            logger.error("Failed to fetch price for \(symbol): \(error.localizedDescription)")
            self.error = .fetchFailed(symbol, error)
            throw MarketDataError.fetchFailed(symbol, error)
        }
    }
    
    /// Get historical prices for a symbol
    public func getHistoricalPrices(symbol: String, from: Date, to: Date) async throws -> [PriceData] {
        logger.info("Fetching historical prices for: \(symbol)")
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let prices = try await provider.getHistoricalPrices(symbol: symbol, from: from, to: to)
            return prices
        } catch {
            logger.error("Failed to fetch historical prices for \(symbol): \(error.localizedDescription)")
            self.error = .fetchFailed(symbol, error)
            throw MarketDataError.fetchFailed(symbol, error)
        }
    }
    
    /// Update prices for multiple holdings
    public func updatePrices(for holdings: [Holding]) async throws {
        logger.info("Updating prices for \(holdings.count) holdings")
        
        isLoading = true
        defer { isLoading = false }
        
        for holding in holdings {
            do {
                if let priceData = try await getCurrentPrice(symbol: holding.symbol) {
                    holding.updatePrice(priceData.price)
                }
            } catch {
                logger.warning("Failed to update price for \(holding.symbol): \(error.localizedDescription)")
                // Continue with other holdings even if one fails
            }
        }
        
        lastUpdateTime = Date()
    }
    
    // MARK: - Private Methods
    
    private func updateProvider() {
        provider = isRealTimeEnabled ? RealTimeMarketDataProvider() : MockMarketDataProvider()
        logger.info("Switched to \(isRealTimeEnabled ? "real-time" : "mock") market data provider")
    }
}

// MARK: - Market Data Provider Protocol

protocol MarketDataProvider {
    func getCurrentPrice(symbol: String) async throws -> PriceData?
    func getHistoricalPrices(symbol: String, from: Date, to: Date) async throws -> [PriceData]
}

// MARK: - Mock Market Data Provider

/// Mock provider for offline/testing mode with realistic price simulation
class MockMarketDataProvider: MarketDataProvider {
    
    private let logger = Logger(subsystem: "com.wealthwise.app", category: "MockMarketDataProvider")
    
    // Mock price database with common symbols
    private let mockPrices: [String: Decimal] = [
        // Indian stocks
        "RELIANCE": 2450.50,
        "TCS": 3620.75,
        "INFY": 1545.30,
        "HDFCBANK": 1650.25,
        "ICICIBANK": 985.60,
        "ITC": 420.15,
        "SBIN": 612.40,
        "BHARTIARTL": 1285.90,
        "KOTAKBANK": 1750.20,
        "LT": 3215.50,
        
        // US stocks
        "AAPL": 175.50,
        "GOOGL": 140.25,
        "MSFT": 380.75,
        "AMZN": 145.90,
        "TSLA": 245.60,
        
        // ETFs
        "NIFTYBEES": 245.30,
        "GOLDBEES": 56.80,
        "LIQUIDBEES": 1000.00,
        
        // Mutual Funds (NAV)
        "HDFC-TOP-100": 875.45,
        "SBI-BLUECHIP": 72.35,
        "ICICI-EQUITY": 1250.60
    ]
    
    func getCurrentPrice(symbol: String) async throws -> PriceData? {
        logger.info("Mock: Fetching price for \(symbol)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Get base price or generate random one
        let basePrice = mockPrices[symbol] ?? generateRandomPrice(for: symbol)
        
        // Add small random variation (+/- 2%)
        let variation = Double.random(in: -0.02...0.02)
        let currentPrice = basePrice * Decimal(1 + variation)
        
        // Calculate change
        let change = currentPrice - basePrice
        let changePercentage = Double(truncating: (change / basePrice * 100) as NSDecimalNumber)
        
        return PriceData(
            symbol: symbol,
            price: currentPrice,
            currency: symbol.contains("USD") || ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"].contains(symbol) ? "USD" : "INR",
            timestamp: Date(),
            change: change,
            changePercentage: changePercentage,
            volume: Int64.random(in: 100000...10000000),
            source: "Mock Data"
        )
    }
    
    func getHistoricalPrices(symbol: String, from: Date, to: Date) async throws -> [PriceData] {
        logger.info("Mock: Fetching historical prices for \(symbol)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        var prices: [PriceData] = []
        let basePrice = mockPrices[symbol] ?? generateRandomPrice(for: symbol)
        
        // Generate daily prices between dates
        var currentDate = from
        let calendar = Calendar.current
        
        while currentDate <= to {
            let daysSinceStart = calendar.dateComponents([.day], from: from, to: currentDate).day ?? 0
            let trend = Double(daysSinceStart) * 0.001 // Slight upward trend
            let noise = Double.random(in: -0.03...0.03) // Daily volatility
            
            let price = basePrice * Decimal(1 + trend + noise)
            let change = price - basePrice
            let changePercentage = Double(truncating: (change / basePrice * 100) as NSDecimalNumber)
            
            prices.append(PriceData(
                symbol: symbol,
                price: price,
                currency: "INR",
                timestamp: currentDate,
                change: change,
                changePercentage: changePercentage,
                volume: Int64.random(in: 100000...10000000),
                source: "Mock Data"
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? to
        }
        
        return prices
    }
    
    private func generateRandomPrice(for symbol: String) -> Decimal {
        // Generate price based on asset type heuristics
        if symbol.contains("MF") || symbol.contains("FUND") {
            return Decimal(Double.random(in: 50...1500)) // Mutual fund NAV range
        } else if symbol.contains("ETF") || symbol.contains("BEES") {
            return Decimal(Double.random(in: 50...300)) // ETF price range
        } else {
            return Decimal(Double.random(in: 100...3000)) // Stock price range
        }
    }
}

// MARK: - Real-Time Market Data Provider

/// Real-time provider for actual market data (placeholder for future implementation)
class RealTimeMarketDataProvider: MarketDataProvider {
    
    private let logger = Logger(subsystem: "com.wealthwise.app", category: "RealTimeMarketDataProvider")
    
    func getCurrentPrice(symbol: String) async throws -> PriceData? {
        logger.info("Real-time: Fetching price for \(symbol)")
        
        // TODO: Implement actual API integration
        // For now, fallback to mock data
        logger.warning("Real-time data not implemented, using mock data")
        
        let mockProvider = MockMarketDataProvider()
        return try await mockProvider.getCurrentPrice(symbol: symbol)
    }
    
    func getHistoricalPrices(symbol: String, from: Date, to: Date) async throws -> [PriceData] {
        logger.info("Real-time: Fetching historical prices for \(symbol)")
        
        // TODO: Implement actual API integration
        // For now, fallback to mock data
        logger.warning("Real-time data not implemented, using mock data")
        
        let mockProvider = MockMarketDataProvider()
        return try await mockProvider.getHistoricalPrices(symbol: symbol, from: from, to: to)
    }
}

// MARK: - Supporting Types

/// Price data structure
public struct PriceData: Codable {
    public let symbol: String
    public let price: Decimal
    public let currency: String
    public let timestamp: Date
    public let change: Decimal?
    public let changePercentage: Double?
    public let volume: Int64?
    public let source: String
    
    public init(
        symbol: String,
        price: Decimal,
        currency: String,
        timestamp: Date,
        change: Decimal? = nil,
        changePercentage: Double? = nil,
        volume: Int64? = nil,
        source: String
    ) {
        self.symbol = symbol
        self.price = price
        self.currency = currency
        self.timestamp = timestamp
        self.change = change
        self.changePercentage = changePercentage
        self.volume = volume
        self.source = source
    }
}

/// Market data errors
public enum MarketDataError: LocalizedError {
    case fetchFailed(String, Error)
    case invalidSymbol(String)
    case noDataAvailable(String)
    case rateLimitExceeded
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let symbol, let error):
            return NSLocalizedString("error_market_data_fetch_failed", comment: "Market data fetch failed") + ": \(symbol) - \(error.localizedDescription)"
        case .invalidSymbol(let symbol):
            return NSLocalizedString("error_invalid_symbol", comment: "Invalid symbol") + ": \(symbol)"
        case .noDataAvailable(let symbol):
            return NSLocalizedString("error_no_data_available", comment: "No data available") + ": \(symbol)"
        case .rateLimitExceeded:
            return NSLocalizedString("error_rate_limit_exceeded", comment: "Rate limit exceeded")
        case .networkError(let error):
            return NSLocalizedString("error_network_error", comment: "Network error") + ": \(error.localizedDescription)"
        }
    }
}
