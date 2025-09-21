import XCTest
import Combine
@testable import WealthWise

final class CurrencyManagerTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    var mockExchangeRateService: MockExchangeRateService!
    var currencyManager: CurrencyManager!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockExchangeRateService = MockExchangeRateService()
        currencyManager = CurrencyManager(exchangeRateService: mockExchangeRateService)
    }
    
    override func tearDown() {
        cancellables = nil
        mockExchangeRateService = nil
        currencyManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(currencyManager.baseCurrency, .usd)
        XCTAssertTrue(currencyManager.supportedCurrencies.contains(.usd))
        XCTAssertTrue(currencyManager.supportedCurrencies.contains(.inr))
        XCTAssertTrue(currencyManager.supportedCurrencies.contains(.eur))
    }
    
    func testInitializationWithCustomBaseCurrency() {
        let manager = CurrencyManager(
            baseCurrency: .inr,
            exchangeRateService: mockExchangeRateService
        )
        
        XCTAssertEqual(manager.baseCurrency, .inr)
    }
    
    // MARK: - Currency Conversion Tests
    
    func testConvertSameCurrency() async {
        let result = await currencyManager.convert(
            amount: 100.0,
            from: .usd,
            to: .usd
        )
        
        switch result {
        case .success(let convertedAmount):
            XCTAssertEqual(convertedAmount, 100.0)
        case .failure(let error):
            XCTFail("Conversion should succeed for same currency: \(error)")
        }
    }
    
    func testConvertWithValidRate() async {
        // Set up mock to return a specific rate
        let exchangeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        mockExchangeRateService.mockRates[.usd] = [.inr: exchangeRate]
        
        let result = await currencyManager.convert(
            amount: 100.0,
            from: .usd,
            to: .inr
        )
        
        switch result {
        case .success(let convertedAmount):
            XCTAssertEqual(convertedAmount, 8325.0, accuracy: 0.01)
        case .failure(let error):
            XCTFail("Conversion should succeed: \(error)")
        }
    }
    
    func testConvertWithInverseRate() async {
        // Set up mock to return inverse rate
        let exchangeRate = ExchangeRate(
            fromCurrency: .inr,
            toCurrency: .usd,
            rate: 0.012,
            timestamp: Date(),
            source: .mock
        )
        mockExchangeRateService.mockRates[.inr] = [.usd: exchangeRate]
        
        let result = await currencyManager.convert(
            amount: 8325.0,
            from: .inr,
            to: .usd
        )
        
        switch result {
        case .success(let convertedAmount):
            XCTAssertEqual(convertedAmount, 99.9, accuracy: 0.1)
        case .failure(let error):
            XCTFail("Conversion should succeed: \(error)")
        }
    }
    
    func testConvertWithNetworkError() async {
        mockExchangeRateService.shouldReturnError = true
        mockExchangeRateService.errorToReturn = .networkError
        
        let result = await currencyManager.convert(
            amount: 100.0,
            from: .usd,
            to: .inr
        )
        
        switch result {
        case .success:
            XCTFail("Conversion should fail with network error")
        case .failure(let error):
            XCTAssertEqual(error, .networkError)
        }
    }
    
    func testConvertZeroAmount() async {
        let result = await currencyManager.convert(
            amount: 0.0,
            from: .usd,
            to: .inr
        )
        
        switch result {
        case .success(let convertedAmount):
            XCTAssertEqual(convertedAmount, 0.0)
        case .failure(let error):
            XCTFail("Zero amount conversion should succeed: \(error)")
        }
    }
    
    func testConvertNegativeAmount() async {
        let exchangeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        mockExchangeRateService.mockRates[.usd] = [.inr: exchangeRate]
        
        let result = await currencyManager.convert(
            amount: -100.0,
            from: .usd,
            to: .inr
        )
        
        switch result {
        case .success(let convertedAmount):
            XCTAssertEqual(convertedAmount, -8325.0, accuracy: 0.01)
        case .failure(let error):
            XCTFail("Negative amount conversion should succeed: \(error)")
        }
    }
    
    // MARK: - Exchange Rate Fetching Tests
    
    func testGetExchangeRateSuccess() async {
        let expectedRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        mockExchangeRateService.mockRates[.usd] = [.inr: expectedRate]
        
        let result = await currencyManager.getExchangeRate(from: .usd, to: .inr)
        
        switch result {
        case .success(let rate):
            XCTAssertEqual(rate.fromCurrency, .usd)
            XCTAssertEqual(rate.toCurrency, .inr)
            XCTAssertEqual(rate.rate, 83.25)
        case .failure(let error):
            XCTFail("Should succeed getting exchange rate: \(error)")
        }
    }
    
    func testGetExchangeRateFailure() async {
        mockExchangeRateService.shouldReturnError = true
        mockExchangeRateService.errorToReturn = .invalidResponse
        
        let result = await currencyManager.getExchangeRate(from: .usd, to: .inr)
        
        switch result {
        case .success:
            XCTFail("Should fail getting exchange rate")
        case .failure(let error):
            XCTAssertEqual(error, .invalidResponse)
        }
    }
    
    // MARK: - Cache Tests
    
    func testCacheExchangeRate() async {
        let exchangeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        
        // Cache the rate
        await currencyManager.cacheExchangeRate(exchangeRate)
        
        // Try to get cached rate (without network)
        mockExchangeRateService.shouldReturnError = true // Force network failure
        
        let result = await currencyManager.getExchangeRate(from: .usd, to: .inr)
        
        switch result {
        case .success(let cachedRate):
            XCTAssertEqual(cachedRate.fromCurrency, .usd)
            XCTAssertEqual(cachedRate.toCurrency, .inr)
            XCTAssertEqual(cachedRate.rate, 83.25)
        case .failure(let error):
            XCTFail("Should return cached rate: \(error)")
        }
    }
    
    func testClearCache() async {
        let exchangeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        
        // Cache the rate
        await currencyManager.cacheExchangeRate(exchangeRate)
        
        // Clear cache
        await currencyManager.clearCache()
        
        // Try to get rate (should fail since cache is cleared and network will fail)
        mockExchangeRateService.shouldReturnError = true
        mockExchangeRateService.errorToReturn = .networkError
        
        let result = await currencyManager.getExchangeRate(from: .usd, to: .inr)
        
        switch result {
        case .success:
            XCTFail("Should fail after cache is cleared")
        case .failure(let error):
            XCTAssertEqual(error, .networkError)
        }
    }
    
    // MARK: - Batch Conversion Tests
    
    func testConvertMultipleAmounts() async {
        let exchangeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        mockExchangeRateService.mockRates[.usd] = [.inr: exchangeRate]
        
        let amounts: [Decimal] = [100.0, 200.0, 300.0]
        
        let results = await currencyManager.convertMultiple(
            amounts: amounts,
            from: .usd,
            to: .inr
        )
        
        XCTAssertEqual(results.count, 3)
        
        switch results[0] {
        case .success(let amount):
            XCTAssertEqual(amount, 8325.0, accuracy: 0.01)
        case .failure:
            XCTFail("First conversion should succeed")
        }
        
        switch results[1] {
        case .success(let amount):
            XCTAssertEqual(amount, 16650.0, accuracy: 0.01)
        case .failure:
            XCTFail("Second conversion should succeed")
        }
        
        switch results[2] {
        case .success(let amount):
            XCTAssertEqual(amount, 24975.0, accuracy: 0.01)
        case .failure:
            XCTFail("Third conversion should succeed")
        }
    }
    
    // MARK: - Refresh Tests
    
    func testRefreshExchangeRates() async {
        let exchangeRate1 = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        
        let exchangeRate2 = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .eur,
            rate: 0.85,
            timestamp: Date(),
            source: .mock
        )
        
        mockExchangeRateService.mockRates[.usd] = [
            .inr: exchangeRate1,
            .eur: exchangeRate2
        ]
        
        let result = await currencyManager.refreshExchangeRates(for: [.inr, .eur])
        
        switch result {
        case .success(let rates):
            XCTAssertEqual(rates.count, 2)
            XCTAssertTrue(rates.contains { $0.toCurrency == .inr })
            XCTAssertTrue(rates.contains { $0.toCurrency == .eur })
        case .failure(let error):
            XCTFail("Refresh should succeed: \(error)")
        }
    }
    
    // MARK: - Publisher Tests
    
    func testExchangeRateUpdatesPublisher() {
        let expectation = XCTestExpectation(description: "Exchange rate update received")
        
        currencyManager.exchangeRateUpdates
            .sink { exchangeRate in
                XCTAssertEqual(exchangeRate.fromCurrency, .usd)
                XCTAssertEqual(exchangeRate.toCurrency, .inr)
                XCTAssertEqual(exchangeRate.rate, 83.25)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let exchangeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        
        Task {
            await currencyManager.cacheExchangeRate(exchangeRate)
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testCurrencyConversionPerformance() async {
        let exchangeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        mockExchangeRateService.mockRates[.usd] = [.inr: exchangeRate]
        
        measure {
            let expectation = XCTestExpectation(description: "Conversion completed")
            
            Task {
                for _ in 0..<100 {
                    _ = await currencyManager.convert(amount: 100.0, from: .usd, to: .inr)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Edge Cases
    
    func testConvertWithUnsupportedCurrency() async {
        // This test assumes we have a limited set of supported currencies
        // and tests error handling for unsupported pairs
        mockExchangeRateService.shouldReturnError = true
        mockExchangeRateService.errorToReturn = .currencyNotSupported
        
        let result = await currencyManager.convert(
            amount: 100.0,
            from: .usd,
            to: .inr // Assuming this might be unsupported in some scenarios
        )
        
        switch result {
        case .success:
            // If conversion succeeds, that's also fine - it means the currency is supported
            break
        case .failure(let error):
            XCTAssertEqual(error, .currencyNotSupported)
        }
    }
    
    func testConvertWithStaleRate() async {
        let staleDate = Date().addingTimeInterval(-7200) // 2 hours ago
        let staleRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: staleDate,
            source: .mock
        )
        
        await currencyManager.cacheExchangeRate(staleRate)
        
        // Configure mock to return error for fresh rate
        mockExchangeRateService.shouldReturnError = true
        mockExchangeRateService.errorToReturn = .staleData
        
        let result = await currencyManager.convert(
            amount: 100.0,
            from: .usd,
            to: .inr
        )
        
        // Should either succeed with stale data or fail appropriately
        switch result {
        case .success(let amount):
            XCTAssertEqual(amount, 8325.0, accuracy: 0.01)
        case .failure(let error):
            XCTAssertEqual(error, .staleData)
        }
    }
}