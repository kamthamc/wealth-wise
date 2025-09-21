import XCTest
@testable import WealthWise

final class BasicCurrencyTests: XCTestCase {
    
    func testSupportedCurrencyBasics() {
        // Test basic currency properties
        XCTAssertEqual(SupportedCurrency.usd.rawValue, "USD")
        XCTAssertEqual(SupportedCurrency.usd.symbol, "$")
        XCTAssertEqual(SupportedCurrency.usd.displayName, "US Dollar")
        
        XCTAssertEqual(SupportedCurrency.inr.rawValue, "INR")
        XCTAssertEqual(SupportedCurrency.inr.symbol, "₹")
        XCTAssertEqual(SupportedCurrency.inr.displayName, "Indian Rupee")
    }
    
    func testExchangeRateBasics() {
        let rate = ExchangeRate(
            fromCurrency: .usd,
            toCurrency: .inr,
            rate: 83.25,
            timestamp: Date(),
            source: .mock
        )
        
        XCTAssertEqual(rate.fromCurrency, .usd)
        XCTAssertEqual(rate.toCurrency, .inr)
        XCTAssertEqual(rate.rate, 83.25)
        XCTAssertTrue(rate.isValid)
    }
}