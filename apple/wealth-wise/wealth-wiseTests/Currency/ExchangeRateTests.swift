import XCTest
@testable import WealthWise

final class ExchangeRateTests: XCTestCase {
    
    // MARK: - ExchangeRate Tests
    
    func testExchangeRateInitialization() {
        let timestamp = Date()
        let rate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: timestamp,
            source: .exchangeRateAPI
        )
        
        XCTAssertEqual(rate.fromCurrency, .usd)
        XCTAssertEqual(rate.toCurrency, .inr)
        XCTAssertEqual(rate.rate, 83.25)
        XCTAssertEqual(rate.timestamp, timestamp)
        XCTAssertEqual(rate.source, .exchangeRateAPI)
    }
    
    func testExchangeRateIsValid() {
        let validRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        let zeroRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 0.0,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        let negativeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: -83.25,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        XCTAssertTrue(validRate.isValid)
        XCTAssertFalse(zeroRate.isValid)
        XCTAssertFalse(negativeRate.isValid)
    }
    
    func testExchangeRateAge() {
        let currentTime = Date()
        let oneHourAgo = currentTime.addingTimeInterval(-3600)
        let oneDayAgo = currentTime.addingTimeInterval(-86400)
        
        let recentRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: oneHourAgo,
            source: .exchangeRateAPI
        )
        
        let oldRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: oneDayAgo,
            source: .exchangeRateAPI
        )
        
        XCTAssertLessThan(recentRate.age, 3700) // Should be around 1 hour
        XCTAssertGreaterThan(oldRate.age, 86300) // Should be around 1 day
    }
    
    func testExchangeRateIsStale() {
        let currentTime = Date()
        let oneHourAgo = currentTime.addingTimeInterval(-3600)
        let twoHoursAgo = currentTime.addingTimeInterval(-7200)
        
        let freshRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: oneHourAgo,
            source: .exchangeRateAPI
        )
        
        let staleRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: twoHoursAgo,
            source: .exchangeRateAPI
        )
        
        XCTAssertFalse(freshRate.isStale(threshold: 5400)) // 1.5 hours threshold
        XCTAssertTrue(staleRate.isStale(threshold: 5400)) // 1.5 hours threshold
    }
    
    func testExchangeRateInverse() {
        let rate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 80.0,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        let inverseRate = rate.inverse()
        
        XCTAssertEqual(inverseRate.fromCurrency, .inr)
        XCTAssertEqual(inverseRate.toCurrency, .usd)
        XCTAssertEqual(inverseRate.rate, 0.0125, accuracy: 0.0001) // 1/80
        XCTAssertEqual(inverseRate.timestamp, rate.timestamp)
        XCTAssertEqual(inverseRate.source, rate.source)
    }
    
    func testExchangeRateInverseWithZeroRate() {
        let zeroRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 0.0,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        let inverseRate = zeroRate.inverse()
        
        XCTAssertEqual(inverseRate.rate, 0.0) // Should handle division by zero gracefully
    }
    
    // MARK: - ExchangeRateSource Tests
    
    func testExchangeRateSourceProperties() {
        XCTAssertEqual(ExchangeRateSource.exchangeRateAPI.baseURL, "https://api.exchangerate-api.com/v4/latest/")
        XCTAssertEqual(ExchangeRateSource.exchangeRateAPI.name, "ExchangeRate-API")
        XCTAssertEqual(ExchangeRateSource.exchangeRateAPI.rateLimitPerHour, 1500)
        XCTAssertTrue(ExchangeRateSource.exchangeRateAPI.requiresAuth)
        
        XCTAssertEqual(ExchangeRateSource.fixer.baseURL, "https://data.fixer.io/api/latest")
        XCTAssertEqual(ExchangeRateSource.fixer.name, "Fixer.io")
        XCTAssertEqual(ExchangeRateSource.fixer.rateLimitPerHour, 100)
        XCTAssertTrue(ExchangeRateSource.fixer.requiresAuth)
        
        XCTAssertEqual(ExchangeRateSource.currencyLayer.baseURL, "https://api.currencylayer.com/live")
        XCTAssertEqual(ExchangeRateSource.currencyLayer.name, "CurrencyLayer")
        XCTAssertEqual(ExchangeRateSource.currencyLayer.rateLimitPerHour, 1000)
        XCTAssertTrue(ExchangeRateSource.currencyLayer.requiresAuth)
        
        XCTAssertEqual(ExchangeRateSource.openExchangeRates.baseURL, "https://openexchangerates.org/api/latest.json")
        XCTAssertEqual(ExchangeRateSource.openExchangeRates.name, "Open Exchange Rates")
        XCTAssertEqual(ExchangeRateSource.openExchangeRates.rateLimitPerHour, 1000)
        XCTAssertTrue(ExchangeRateSource.openExchangeRates.requiresAuth)
        
        XCTAssertEqual(ExchangeRateSource.cache.baseURL, "")
        XCTAssertEqual(ExchangeRateSource.cache.name, "Local Cache")
        XCTAssertEqual(ExchangeRateSource.cache.rateLimitPerHour, Int.max)
        XCTAssertFalse(ExchangeRateSource.cache.requiresAuth)
        
        XCTAssertEqual(ExchangeRateSource.mock.baseURL, "")
        XCTAssertEqual(ExchangeRateSource.mock.name, "Mock Service")
        XCTAssertEqual(ExchangeRateSource.mock.rateLimitPerHour, Int.max)
        XCTAssertFalse(ExchangeRateSource.mock.requiresAuth)
    }
    
    func testExchangeRateSourceURL() {
        let source = ExchangeRateSource.exchangeRateAPI
        let url = source.url(for: .usd)
        
        XCTAssertEqual(url?.absoluteString, "https://api.exchangerate-api.com/v4/latest/USD")
    }
    
    func testExchangeRateSourceURLWithInvalidBaseURL() {
        // Create a source with invalid base URL
        let invalidSource = ExchangeRateSource.cache // Has empty base URL
        let url = invalidSource.url(for: .usd)
        
        XCTAssertNil(url)
    }
    
    // MARK: - ExchangeRateError Tests
    
    func testExchangeRateErrorMessages() {
        XCTAssertEqual(ExchangeRateError.networkError.localizedDescription, 
                      "Unable to connect to exchange rate service")
        XCTAssertEqual(ExchangeRateError.invalidResponse.localizedDescription, 
                      "Invalid response from exchange rate service")
        XCTAssertEqual(ExchangeRateError.rateLimitExceeded.localizedDescription, 
                      "Rate limit exceeded for exchange rate service")
        XCTAssertEqual(ExchangeRateError.invalidAPIKey.localizedDescription, 
                      "Invalid API key for exchange rate service")
        XCTAssertEqual(ExchangeRateError.currencyNotSupported.localizedDescription, 
                      "Currency not supported by exchange rate service")
        XCTAssertEqual(ExchangeRateError.noDataAvailable.localizedDescription, 
                      "No exchange rate data available")
        XCTAssertEqual(ExchangeRateError.cacheError.localizedDescription, 
                      "Error accessing exchange rate cache")
        XCTAssertEqual(ExchangeRateError.invalidCurrencyPair.localizedDescription, 
                      "Invalid currency pair for conversion")
        XCTAssertEqual(ExchangeRateError.staleData.localizedDescription, 
                      "Exchange rate data is too old")
        XCTAssertEqual(ExchangeRateError.conversionError.localizedDescription, 
                      "Error converting between currencies")
    }
    
    func testExchangeRateErrorEquality() {
        XCTAssertEqual(ExchangeRateError.networkError, ExchangeRateError.networkError)
        XCTAssertEqual(ExchangeRateError.invalidResponse, ExchangeRateError.invalidResponse)
        XCTAssertNotEqual(ExchangeRateError.networkError, ExchangeRateError.invalidResponse)
    }
    
    // MARK: - Codable Tests
    
    func testExchangeRateCodable() throws {
        let originalRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalRate)
        
        // Test decoding
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedRate = try decoder.decode(ExchangeRate.self, from: data)
        
        XCTAssertEqual(originalRate.fromCurrency, decodedRate.fromCurrency)
        XCTAssertEqual(originalRate.toCurrency, decodedRate.toCurrency)
        XCTAssertEqual(originalRate.rate, decodedRate.rate)
        XCTAssertEqual(originalRate.timestamp.timeIntervalSince1970, 
                      decodedRate.timestamp.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(originalRate.source, decodedRate.source)
    }
    
    func testExchangeRateSourceCodable() throws {
        let source = ExchangeRateSource.exchangeRateAPI
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(source)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedSource = try decoder.decode(ExchangeRateSource.self, from: data)
        
        XCTAssertEqual(source, decodedSource)
    }
    
    // MARK: - Performance Tests
    
    func testExchangeRateInversePerformance() {
        let rate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        measure {
            for _ in 0..<1000 {
                _ = rate.inverse()
            }
        }
    }
    
    func testExchangeRateAgeCalculationPerformance() {
        let rate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date().addingTimeInterval(-3600),
            source: .exchangeRateAPI
        )
        
        measure {
            for _ in 0..<1000 {
                _ = rate.age
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testExchangeRateWithSameCurrency() {
        let rate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .usd,
            rate: 1.0,
            timestamp: Date(),
            source: .cache
        )
        
        XCTAssertTrue(rate.isValid)
        XCTAssertEqual(rate.rate, 1.0)
        
        let inverse = rate.inverse()
        XCTAssertEqual(inverse.rate, 1.0)
    }
    
    func testExchangeRateWithVeryLargeRate() {
        let largeRate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .vnd, // Vietnamese Dong has large rates
            rate: 24000.0,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        XCTAssertTrue(largeRate.isValid)
        
        let inverse = largeRate.inverse()
        XCTAssertEqual(inverse.rate, 1.0/24000.0, accuracy: 0.000001)
    }
    
    func testExchangeRateWithVerySmallRate() {
        let smallRate = ExchangeRate(
            fromCurrency: .kwd, // Kuwaiti Dinar has small rates
            toCurrency: .usd,
            rate: 0.0032,
            timestamp: Date(),
            source: .exchangeRateAPI
        )
        
        XCTAssertTrue(smallRate.isValid)
        
        let inverse = smallRate.inverse()
        XCTAssertEqual(inverse.rate, 1.0/0.0032, accuracy: 0.1)
    }
}