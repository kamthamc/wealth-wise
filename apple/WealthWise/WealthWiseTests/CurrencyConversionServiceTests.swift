import XCTest
@testable import WealthWise

/// Comprehensive unit tests for CurrencyConversionService
/// Tests multi-provider support, caching, batch processing, and error handling
@MainActor
final class CurrencyConversionServiceTests: XCTestCase {
    
    var service: CurrencyConversionService!
    var mockProvider: MockExchangeRateProvider!
    var cache: ExchangeRateCache!
    var calculator: ConversionCalculator!
    var rateLimiter: RateLimiter!
    
    override func setUp() async throws {
        mockProvider = MockExchangeRateProvider()
        cache = ExchangeRateCache(userDefaults: UserDefaults(suiteName: "test")!)
        calculator = ConversionCalculator()
        rateLimiter = RateLimiter()
        
        service = CurrencyConversionService(
            providers: [mockProvider],
            cache: cache,
            calculator: calculator,
            rateLimiter: rateLimiter
        )
        
        // Clear cache before each test
        await cache.clearAll()
    }
    
    override func tearDown() async throws {
        await cache.clearAll()
        service = nil
        mockProvider = nil
        cache = nil
        calculator = nil
        rateLimiter = nil
    }
    
    // MARK: - Basic Conversion Tests
    
    func testConvertSameCurrency() async throws {
        let amount = Decimal(100)
        let result = try await service.convert(amount, from: .USD, to: .USD)
        
        XCTAssertEqual(result, amount, "Converting same currency should return original amount")
    }
    
    func testConvertDifferentCurrencies() async throws {
        let amount = Decimal(100)
        let result = try await service.convert(amount, from: .USD, to: .EUR)
        
        XCTAssertGreaterThan(result, 0, "Converted amount should be positive")
        XCTAssertNotEqual(result, amount, "Converted amount should differ from original")
    }
    
    func testConvertWithCaching() async throws {
        let amount = Decimal(100)
        
        // First conversion - fetches from provider
        let result1 = try await service.convert(amount, from: .USD, to: .EUR)
        
        // Second conversion - should use cache
        let result2 = try await service.convert(amount, from: .USD, to: .EUR)
        
        XCTAssertEqual(result1, result2, "Cached conversion should return same result")
    }
    
    // MARK: - Exchange Rate Tests
    
    func testGetExchangeRate() async throws {
        let rate = try await service.getExchangeRate(from: .USD, to: .EUR)
        
        XCTAssertEqual(rate.fromCurrency, .USD)
        XCTAssertEqual(rate.toCurrency, .EUR)
        XCTAssertGreaterThan(rate.rate, 0)
        XCTAssertNotNil(rate.timestamp)
        XCTAssertFalse(rate.source.isEmpty)
    }
    
    func testGetExchangeRateSameCurrency() async throws {
        let rate = try await service.getExchangeRate(from: .USD, to: .USD)
        
        XCTAssertEqual(rate.rate, 1.0, "Same currency rate should be 1.0")
    }
    
    func testGetExchangeRateWithCache() async throws {
        // First fetch - from provider
        let rate1 = try await service.getExchangeRate(from: .USD, to: .EUR)
        
        // Second fetch - from cache
        let rate2 = try await service.getExchangeRate(from: .USD, to: .EUR)
        
        XCTAssertEqual(rate1.rate, rate2.rate, "Cached rate should match original")
    }
    
    // MARK: - Batch Conversion Tests
    
    func testBatchConvert() async throws {
        let conversions = [
            ConversionRequest(amount: 100, sourceCurrency: .USD, targetCurrency: .EUR),
            ConversionRequest(amount: 200, sourceCurrency: .GBP, targetCurrency: .USD),
            ConversionRequest(amount: 300, sourceCurrency: .JPY, targetCurrency: .INR)
        ]
        
        let results = try await service.batchConvert(conversions)
        
        XCTAssertEqual(results.count, conversions.count, "Should return result for each conversion")
        
        for result in results {
            XCTAssertTrue(result.success, "All conversions should succeed")
            XCTAssertGreaterThan(result.result, 0, "Converted amount should be positive")
            XCTAssertNotNil(result.rate, "Rate should be present")
            XCTAssertNil(result.error, "Error should be nil for successful conversion")
        }
    }
    
    func testBatchConvertOptimization() async throws {
        // Create multiple conversions with same currency pair
        let conversions = [
            ConversionRequest(amount: 100, sourceCurrency: .USD, targetCurrency: .EUR),
            ConversionRequest(amount: 200, sourceCurrency: .USD, targetCurrency: .EUR),
            ConversionRequest(amount: 300, sourceCurrency: .USD, targetCurrency: .EUR)
        ]
        
        let results = try await service.batchConvert(conversions)
        
        XCTAssertEqual(results.count, 3, "Should return all results")
        
        // All should use the same rate (optimization)
        let rates = results.compactMap { $0.rate?.rate }
        XCTAssertEqual(Set(rates).count, 1, "Should use same rate for identical currency pairs")
    }
    
    // MARK: - Update Rates Tests
    
    func testUpdateAllRates() async throws {
        XCTAssertNil(service.lastUpdateDate, "Last update should be nil initially")
        
        try await service.updateAllRates(baseCurrency: .INR)
        
        XCTAssertNotNil(service.lastUpdateDate, "Last update date should be set")
        XCTAssertFalse(service.isUpdating, "Should not be updating after completion")
        XCTAssertNil(service.lastError, "Should have no error on success")
    }
    
    func testUpdateAllRatesWithCaching() async throws {
        try await service.updateAllRates(baseCurrency: .INR)
        
        // Verify rates are cached
        let cachedRate = await cache.getRate(from: .INR, to: .USD)
        XCTAssertNotNil(cachedRate, "Rates should be cached after update")
    }
    
    // MARK: - Historical Rate Tests
    
    func testGetHistoricalRate() async throws {
        let historicalDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        
        let rate = try await service.getHistoricalRate(
            from: .USD,
            to: .EUR,
            date: historicalDate
        )
        
        XCTAssertEqual(rate.fromCurrency, .USD)
        XCTAssertEqual(rate.toCurrency, .EUR)
        XCTAssertGreaterThan(rate.rate, 0)
    }
    
    func testGetHistoricalRateWithCaching() async throws {
        let historicalDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        // First fetch
        let rate1 = try await service.getHistoricalRate(from: .USD, to: .EUR, date: historicalDate)
        
        // Second fetch - should use cache
        let rate2 = try await service.getHistoricalRate(from: .USD, to: .EUR, date: historicalDate)
        
        XCTAssertEqual(rate1.rate, rate2.rate, "Cached historical rate should match")
    }
    
    // MARK: - Clear Cache Tests
    
    func testClearCache() async throws {
        // Add some rates
        try await service.updateAllRates(baseCurrency: .INR)
        
        // Verify cache has data
        let cachedRate = await cache.getRate(from: .INR, to: .USD)
        XCTAssertNotNil(cachedRate)
        
        // Clear cache
        await service.clearCache()
        
        // Verify cache is empty
        let clearedRate = await cache.getRate(from: .INR, to: .USD)
        XCTAssertNil(clearedRate)
    }
    
    // MARK: - Error Handling Tests
    
    func testConvertWithNoProviders() async throws {
        let serviceWithoutProviders = CurrencyConversionService(
            providers: [],
            cache: cache,
            calculator: calculator,
            rateLimiter: rateLimiter
        )
        
        do {
            _ = try await serviceWithoutProviders.convert(100, from: .USD, to: .EUR)
            XCTFail("Should throw error with no providers")
        } catch {
            XCTAssertTrue(error is CurrencyConversionError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() {
        measure {
            Task { @MainActor in
                do {
                    _ = try await service.convert(100, from: .USD, to: .EUR)
                } catch {
                    XCTFail("Conversion failed: \(error)")
                }
            }
        }
    }
    
    func testBatchConversionPerformance() {
        let conversions = (0..<100).map { _ in
            ConversionRequest(
                amount: Decimal.random(in: 1...10000),
                sourceCurrency: .USD,
                targetCurrency: .EUR
            )
        }
        
        measure {
            Task { @MainActor in
                do {
                    _ = try await service.batchConvert(conversions)
                } catch {
                    XCTFail("Batch conversion failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Helper Extensions

extension Decimal {
    static func random(in range: ClosedRange<Double>) -> Decimal {
        return Decimal(Double.random(in: range))
    }
}
