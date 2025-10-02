import XCTest
@testable import WealthWise

/// Comprehensive unit tests for ExchangeRateCache
/// Tests caching, expiry, historical rates, and persistence
final class ExchangeRateCacheTests: XCTestCase {
    
    var cache: ExchangeRateCache!
    var testDefaults: UserDefaults!
    
    override func setUp() async throws {
        testDefaults = UserDefaults(suiteName: "test.cache")!
        cache = ExchangeRateCache(userDefaults: testDefaults)
        await cache.clearAll()
    }
    
    override func tearDown() async throws {
        await cache.clearAll()
        testDefaults.removePersistentDomain(forName: "test.cache")
        cache = nil
        testDefaults = nil
    }
    
    // MARK: - Basic Cache Tests
    
    func testSaveAndGetRate() async {
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        await cache.saveRate(rate)
        
        let retrieved = await cache.getRate(from: .USD, to: .EUR)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.rate, rate.rate)
        XCTAssertEqual(retrieved?.fromCurrency, .USD)
        XCTAssertEqual(retrieved?.toCurrency, .EUR)
    }
    
    func testSaveRateAlsoSavesInverse() async {
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        await cache.saveRate(rate)
        
        // Check inverse rate is also cached
        let inverseRate = await cache.getRate(from: .EUR, to: .USD)
        XCTAssertNotNil(inverseRate)
        XCTAssertEqual(inverseRate?.fromCurrency, .EUR)
        XCTAssertEqual(inverseRate?.toCurrency, .USD)
        
        // Inverse rate should be approximately 1/0.85
        let expectedInverse = 1 / rate.rate
        let actualInverse = inverseRate!.rate
        XCTAssertEqual(Double(actualInverse), Double(expectedInverse), accuracy: 0.0001)
    }
    
    func testSaveMultipleRates() async {
        let rates: [ExchangeRate] = [
            ExchangeRate(from: .USD, to: .EUR, rate: 0.85),
            ExchangeRate(from: .USD, to: .GBP, rate: 0.73),
            ExchangeRate(from: .USD, to: .JPY, rate: 110.0)
        ]
        
        for rate in rates {
            await cache.saveRate(rate)
        }
        
        // Verify all rates are cached
        for rate in rates {
            let retrieved = await cache.getRate(from: rate.fromCurrency, to: rate.toCurrency)
            XCTAssertNotNil(retrieved)
            XCTAssertEqual(retrieved?.rate, rate.rate)
        }
    }
    
    // MARK: - Rate Set Tests
    
    func testSaveRatesFromSet() async {
        let rates: [SupportedCurrency: ExchangeRate] = [
            .EUR: ExchangeRate(from: .USD, to: .EUR, rate: 0.85),
            .GBP: ExchangeRate(from: .USD, to: .GBP, rate: 0.73),
            .JPY: ExchangeRate(from: .USD, to: .JPY, rate: 110.0)
        ]
        
        let rateSet = ExchangeRateSet(baseCurrency: .USD, rates: rates)
        
        await cache.saveRates(rateSet)
        
        // Verify all rates are cached
        for (currency, _) in rates {
            let retrieved = await cache.getRate(from: .USD, to: currency)
            XCTAssertNotNil(retrieved, "Rate for USD to \(currency) should be cached")
        }
    }
    
    func testSaveRatesCreatesCommonCrossPairs() async {
        let rates: [SupportedCurrency: ExchangeRate] = [
            .EUR: ExchangeRate(from: .INR, to: .EUR, rate: 0.011),
            .USD: ExchangeRate(from: .INR, to: .USD, rate: 0.012)
        ]
        
        let rateSet = ExchangeRateSet(baseCurrency: .INR, rates: rates)
        
        await cache.saveRates(rateSet)
        
        // Check if cross-currency rate is cached
        let crossRate = await cache.getRate(from: .USD, to: .EUR)
        XCTAssertNotNil(crossRate, "Cross-currency rate should be cached")
    }
    
    // MARK: - Historical Rate Tests
    
    func testSaveAndGetHistoricalRate() async {
        let historicalDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85, timestamp: historicalDate)
        
        await cache.saveHistoricalRate(rate)
        
        let retrieved = await cache.getHistoricalRate(from: .USD, to: .EUR, date: historicalDate)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.rate, rate.rate)
    }
    
    func testHistoricalRateDateNormalization() async {
        // Create rates with different times on the same day
        let date1 = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!
        let date2 = Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!
        
        let rate1 = ExchangeRate(from: .USD, to: .EUR, rate: 0.85, timestamp: date1)
        await cache.saveHistoricalRate(rate1)
        
        // Should retrieve same rate when querying with different time on same day
        let retrieved = await cache.getHistoricalRate(from: .USD, to: .EUR, date: date2)
        XCTAssertNotNil(retrieved, "Should normalize dates to same day")
        XCTAssertEqual(retrieved?.rate, rate1.rate)
    }
    
    func testHistoricalRateSavesInverse() async {
        let historicalDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85, timestamp: historicalDate)
        
        await cache.saveHistoricalRate(rate)
        
        // Check inverse historical rate
        let inverse = await cache.getHistoricalRate(from: .EUR, to: .USD, date: historicalDate)
        XCTAssertNotNil(inverse)
        XCTAssertEqual(inverse?.fromCurrency, .EUR)
        XCTAssertEqual(inverse?.toCurrency, .USD)
    }
    
    // MARK: - Cache Expiry Tests
    
    func testHasExpired() async {
        XCTAssertTrue(await cache.hasExpired(), "Cache should be expired initially")
        
        // Add a rate
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        await cache.saveRate(rate)
        
        XCTAssertFalse(await cache.hasExpired(), "Cache should not be expired after save")
    }
    
    func testClearExpired() async {
        // Add fresh rate
        let freshRate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        await cache.saveRate(freshRate)
        
        // Add old rate
        let oldDate = Date().addingTimeInterval(-5 * 60 * 60) // 5 hours ago
        let oldRate = ExchangeRate(from: .GBP, to: .USD, rate: 1.27, timestamp: oldDate)
        await cache.saveRate(oldRate)
        
        await cache.clearExpired()
        
        // Fresh rate should still be there
        let freshRetrieved = await cache.getRate(from: .USD, to: .EUR)
        XCTAssertNotNil(freshRetrieved)
        
        // Old rate should be removed
        let oldRetrieved = await cache.getRate(from: .GBP, to: .USD)
        XCTAssertNil(oldRetrieved, "Expired rate should be cleared")
    }
    
    // MARK: - Clear Cache Tests
    
    func testClearAll() async {
        // Add some rates
        await cache.saveRate(ExchangeRate(from: .USD, to: .EUR, rate: 0.85))
        await cache.saveRate(ExchangeRate(from: .GBP, to: .USD, rate: 1.27))
        
        // Verify they're cached
        XCTAssertNotNil(await cache.getRate(from: .USD, to: .EUR))
        XCTAssertNotNil(await cache.getRate(from: .GBP, to: .USD))
        
        // Clear all
        await cache.clearAll()
        
        // Verify cache is empty
        XCTAssertNil(await cache.getRate(from: .USD, to: .EUR))
        XCTAssertNil(await cache.getRate(from: .GBP, to: .USD))
    }
    
    // MARK: - Statistics Tests
    
    func testGetStatistics() async {
        // Empty cache
        var stats = await cache.getStatistics()
        XCTAssertEqual(stats.totalRates, 0)
        XCTAssertEqual(stats.recentRates, 0)
        XCTAssertEqual(stats.historicalRates, 0)
        
        // Add some rates
        await cache.saveRate(ExchangeRate(from: .USD, to: .EUR, rate: 0.85))
        await cache.saveRate(ExchangeRate(from: .GBP, to: .USD, rate: 1.27))
        
        stats = await cache.getStatistics()
        XCTAssertGreaterThan(stats.totalRates, 0)
        XCTAssertGreaterThan(stats.recentRates, 0)
        XCTAssertNotNil(stats.lastUpdate)
    }
    
    func testCacheSizeEstimate() async {
        let stats1 = await cache.getStatistics()
        let initialSize = stats1.cacheSize
        
        // Add rates
        for i in 0..<10 {
            let rate = ExchangeRate(
                from: .USD,
                to: .EUR,
                rate: Decimal(0.85 + Double(i) * 0.01)
            )
            await cache.saveRate(rate)
        }
        
        let stats2 = await cache.getStatistics()
        XCTAssertGreaterThan(stats2.cacheSize, initialSize, "Cache size should increase")
    }
    
    // MARK: - Performance Tests
    
    func testSaveRatePerformance() {
        measure {
            Task {
                for _ in 0..<100 {
                    let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
                    await cache.saveRate(rate)
                }
            }
        }
    }
    
    func testGetRatePerformance() {
        Task {
            // Pre-populate cache
            await cache.saveRate(ExchangeRate(from: .USD, to: .EUR, rate: 0.85))
        }
        
        measure {
            Task {
                for _ in 0..<100 {
                    _ = await cache.getRate(from: .USD, to: .EUR)
                }
            }
        }
    }
}
