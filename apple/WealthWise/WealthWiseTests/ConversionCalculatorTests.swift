import XCTest
@testable import WealthWise

/// Comprehensive unit tests for ConversionCalculator
/// Tests single conversions, batch processing, and portfolio calculations
final class ConversionCalculatorTests: XCTestCase {
    
    var calculator: ConversionCalculator!
    
    override func setUp() async throws {
        calculator = ConversionCalculator()
    }
    
    override func tearDown() async throws {
        calculator = nil
    }
    
    // MARK: - Single Conversion Tests
    
    func testConvertWithDecimal() async {
        let amount = Decimal(100)
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        let result = await calculator.convert(amount, using: rate)
        
        XCTAssertEqual(result, Decimal(85), "100 USD * 0.85 = 85 EUR")
    }
    
    func testConvertWithDouble() async {
        let amount = 100.0
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        let result = await calculator.convert(amount, using: rate)
        
        XCTAssertEqual(result, 85.0, accuracy: 0.001, "100 USD * 0.85 = 85 EUR")
    }
    
    func testConvertZeroAmount() async {
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        let result = await calculator.convert(Decimal(0), using: rate)
        
        XCTAssertEqual(result, 0, "Converting 0 should return 0")
    }
    
    func testConvertNegativeAmount() async {
        let amount = Decimal(-100)
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        let result = await calculator.convert(amount, using: rate)
        
        XCTAssertEqual(result, Decimal(-85), "Negative amounts should work")
    }
    
    func testConvertLargeAmount() async {
        let amount = Decimal(1_000_000_000) // 1 billion
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        let result = await calculator.convert(amount, using: rate)
        
        XCTAssertEqual(result, Decimal(850_000_000), "Large amounts should convert correctly")
    }
    
    func testConvertSmallAmount() async {
        let amount = Decimal(0.01)
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        let result = await calculator.convert(amount, using: rate)
        
        XCTAssertGreaterThan(result, 0, "Small amounts should convert correctly")
    }
    
    // MARK: - Batch Conversion Tests
    
    func testBatchConvertWithPreFetchedRates() async {
        let conversions = [
            ConversionRequest(amount: 100, sourceCurrency: .USD, targetCurrency: .EUR),
            ConversionRequest(amount: 200, sourceCurrency: .GBP, targetCurrency: .USD),
            ConversionRequest(amount: 300, sourceCurrency: .JPY, targetCurrency: .INR)
        ]
        
        let rates: [CurrencyPair: ExchangeRate] = [
            CurrencyPair(from: .USD, to: .EUR): ExchangeRate(from: .USD, to: .EUR, rate: 0.85),
            CurrencyPair(from: .GBP, to: .USD): ExchangeRate(from: .GBP, to: .USD, rate: 1.27),
            CurrencyPair(from: .JPY, to: .INR): ExchangeRate(from: .JPY, to: .INR, rate: 0.64)
        ]
        
        let results = await calculator.batchConvertWithRates(conversions, rates: rates)
        
        XCTAssertEqual(results.count, conversions.count, "Should return result for each conversion")
        
        for result in results {
            XCTAssertTrue(result.success, "All conversions should succeed with valid rates")
            XCTAssertGreaterThan(result.result, 0, "Converted amounts should be positive")
            XCTAssertNotNil(result.rate, "Rate should be present")
            XCTAssertNil(result.error, "No error should be present")
        }
    }
    
    func testBatchConvertWithMissingRates() async {
        let conversions = [
            ConversionRequest(amount: 100, sourceCurrency: .USD, targetCurrency: .EUR),
            ConversionRequest(amount: 200, sourceCurrency: .GBP, targetCurrency: .USD) // Missing rate
        ]
        
        let rates: [CurrencyPair: ExchangeRate] = [
            CurrencyPair(from: .USD, to: .EUR): ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
            // GBP to USD rate is missing
        ]
        
        let results = await calculator.batchConvertWithRates(conversions, rates: rates)
        
        XCTAssertEqual(results.count, 2)
        
        // First should succeed
        XCTAssertTrue(results[0].success)
        XCTAssertNil(results[0].error)
        
        // Second should fail
        XCTAssertFalse(results[1].success)
        XCTAssertNotNil(results[1].error)
    }
    
    func testBatchConvertEmptyList() async {
        let conversions: [ConversionRequest] = []
        let rates: [CurrencyPair: ExchangeRate] = [:]
        
        let results = await calculator.batchConvertWithRates(conversions, rates: rates)
        
        XCTAssertEqual(results.count, 0, "Empty conversions should return empty results")
    }
    
    // MARK: - Portfolio Value Calculation Tests
    
    func testCalculatePortfolioValue() async throws {
        let service = CurrencyConversionService(
            providers: [MockExchangeRateProvider()],
            cache: ExchangeRateCache(userDefaults: UserDefaults(suiteName: "test")!),
            calculator: calculator,
            rateLimiter: RateLimiter()
        )
        
        let holdings = [
            PortfolioHolding(assetId: "asset1", value: 1000, currency: .USD),
            PortfolioHolding(assetId: "asset2", value: 2000, currency: .EUR),
            PortfolioHolding(assetId: "asset3", value: 3000, currency: .GBP)
        ]
        
        let portfolioValue = try await calculator.calculatePortfolioValue(
            holdings,
            targetCurrency: .USD,
            using: service
        )
        
        XCTAssertGreaterThan(portfolioValue.totalValue, 0, "Total value should be positive")
        XCTAssertEqual(portfolioValue.currency, .USD)
        XCTAssertEqual(portfolioValue.successfulConversions, holdings.count)
        XCTAssertEqual(portfolioValue.failedConversions, 0)
        XCTAssertEqual(portfolioValue.holdingValues.count, holdings.count)
    }
    
    func testCalculatePortfolioValueSameCurrency() async throws {
        let service = CurrencyConversionService(
            providers: [MockExchangeRateProvider()],
            cache: ExchangeRateCache(userDefaults: UserDefaults(suiteName: "test")!),
            calculator: calculator,
            rateLimiter: RateLimiter()
        )
        
        let holdings = [
            PortfolioHolding(assetId: "asset1", value: 1000, currency: .USD),
            PortfolioHolding(assetId: "asset2", value: 2000, currency: .USD)
        ]
        
        let portfolioValue = try await calculator.calculatePortfolioValue(
            holdings,
            targetCurrency: .USD,
            using: service
        )
        
        // When all holdings are in same currency as target, total should be simple sum
        XCTAssertEqual(portfolioValue.totalValue, Decimal(3000))
    }
    
    func testCalculatePortfolioValueEmpty() async throws {
        let service = CurrencyConversionService(
            providers: [MockExchangeRateProvider()],
            cache: ExchangeRateCache(userDefaults: UserDefaults(suiteName: "test")!),
            calculator: calculator,
            rateLimiter: RateLimiter()
        )
        
        let holdings: [PortfolioHolding] = []
        
        let portfolioValue = try await calculator.calculatePortfolioValue(
            holdings,
            targetCurrency: .USD,
            using: service
        )
        
        XCTAssertEqual(portfolioValue.totalValue, 0)
        XCTAssertEqual(portfolioValue.successfulConversions, 0)
        XCTAssertEqual(portfolioValue.holdingValues.count, 0)
    }
    
    // MARK: - Currency Breakdown Tests
    
    func testCalculateCurrencyBreakdown() async throws {
        let service = CurrencyConversionService(
            providers: [MockExchangeRateProvider()],
            cache: ExchangeRateCache(userDefaults: UserDefaults(suiteName: "test")!),
            calculator: calculator,
            rateLimiter: RateLimiter()
        )
        
        let holdings = [
            PortfolioHolding(assetId: "asset1", value: 1000, currency: .USD),
            PortfolioHolding(assetId: "asset2", value: 2000, currency: .USD),
            PortfolioHolding(assetId: "asset3", value: 3000, currency: .EUR),
            PortfolioHolding(assetId: "asset4", value: 4000, currency: .GBP)
        ]
        
        let breakdown = try await calculator.calculateCurrencyBreakdown(
            holdings,
            targetCurrency: .USD,
            using: service
        )
        
        XCTAssertEqual(breakdown.items.count, 3, "Should have 3 currencies")
        XCTAssertEqual(breakdown.targetCurrency, .USD)
        XCTAssertGreaterThan(breakdown.totalValue, 0)
        
        // Check percentages sum to approximately 100
        let totalPercentage = breakdown.items.reduce(Decimal(0)) { $0 + $1.percentage }
        XCTAssertEqual(Double(totalPercentage), 100.0, accuracy: 0.1)
        
        // Items should be sorted by converted value descending
        for i in 0..<(breakdown.items.count - 1) {
            XCTAssertGreaterThanOrEqual(breakdown.items[i].convertedValue, breakdown.items[i + 1].convertedValue)
        }
    }
    
    func testCalculateCurrencyBreakdownSingleCurrency() async throws {
        let service = CurrencyConversionService(
            providers: [MockExchangeRateProvider()],
            cache: ExchangeRateCache(userDefaults: UserDefaults(suiteName: "test")!),
            calculator: calculator,
            rateLimiter: RateLimiter()
        )
        
        let holdings = [
            PortfolioHolding(assetId: "asset1", value: 1000, currency: .USD),
            PortfolioHolding(assetId: "asset2", value: 2000, currency: .USD)
        ]
        
        let breakdown = try await calculator.calculateCurrencyBreakdown(
            holdings,
            targetCurrency: .USD,
            using: service
        )
        
        XCTAssertEqual(breakdown.items.count, 1, "Should have 1 currency")
        XCTAssertEqual(breakdown.items[0].currency, .USD)
        XCTAssertEqual(breakdown.items[0].percentage, 100)
        XCTAssertEqual(breakdown.items[0].assetCount, 2)
    }
    
    // MARK: - Performance Tests
    
    func testSingleConversionPerformance() {
        let rate = ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        
        measure {
            Task {
                for _ in 0..<1000 {
                    _ = await calculator.convert(Decimal(100), using: rate)
                }
            }
        }
    }
    
    func testBatchConversionPerformance() {
        let conversions = (0..<1000).map { i in
            ConversionRequest(
                amount: Decimal(100 + i),
                sourceCurrency: .USD,
                targetCurrency: .EUR
            )
        }
        
        let rates: [CurrencyPair: ExchangeRate] = [
            CurrencyPair(from: .USD, to: .EUR): ExchangeRate(from: .USD, to: .EUR, rate: 0.85)
        ]
        
        measure {
            Task {
                _ = await calculator.batchConvertWithRates(conversions, rates: rates)
            }
        }
    }
}
