import XCTest
@testable import WealthWise

final class CurrencyFormatterTests: XCTestCase {
    
    var formatter: CurrencyFormatter!
    
    override func setUp() {
        super.setUp()
        formatter = CurrencyFormatter(locale: Locale(identifier: "en_US"))
    }
    
    override func tearDown() {
        formatter = nil
        super.tearDown()
    }
    
    // MARK: - Standard Formatting Tests
    
    func testStandardFormatting() {
        let amount: Decimal = 1234.56
        
        let usdFormatted = formatter.formatCurrency(amount, currency: .usd, style: .standard)
        XCTAssertTrue(usdFormatted.contains("$"))
        XCTAssertTrue(usdFormatted.contains("1"))
        
        let eurFormatted = formatter.formatCurrency(amount, currency: .eur, style: .standard)
        XCTAssertTrue(eurFormatted.contains("€"))
        
        let inrFormatted = formatter.formatCurrency(amount, currency: .inr, style: .standard)
        XCTAssertTrue(inrFormatted.contains("₹"))
    }
    
    func testZeroAmountFormatting() {
        let amount: Decimal = 0.0
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .standard)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("0"))
    }
    
    func testNegativeAmountFormatting() {
        let amount: Decimal = -1234.56
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .standard)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("1"))
        // Should handle negative formatting according to locale
    }
    
    func testLargeAmountFormatting() {
        let amount: Decimal = 1_234_567.89
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .standard)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("1"))
        // Should include proper thousands separators
    }
    
    // MARK: - Compact Formatting Tests
    
    func testCompactFormattingSmallAmounts() {
        let amount: Decimal = 123.45
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .compact)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("123"))
    }
    
    func testCompactFormattingThousands() {
        let amount: Decimal = 12_345
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .compact)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("K") || formatted.contains("12"))
    }
    
    func testCompactFormattingMillions() {
        let amount: Decimal = 12_345_678
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .compact)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("M") || formatted.contains("12"))
    }
    
    func testCompactFormattingBillions() {
        let amount: Decimal = 12_345_678_901
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .compact)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("B") || formatted.contains("12"))
    }
    
    // MARK: - Indian Numbering System Tests
    
    func testIndianCurrencyFormattingLakhs() {
        let amount: Decimal = 1_234_567 // > 1 lakh
        
        let formatted = formatter.formatIndianCurrency(amount)
        XCTAssertTrue(formatted.contains("₹"))
        XCTAssertTrue(formatted.contains("L") || formatted.contains("12"))
    }
    
    func testIndianCurrencyFormattingCrores() {
        let amount: Decimal = 123_456_789 // > 1 crore
        
        let formatted = formatter.formatIndianCurrency(amount)
        XCTAssertTrue(formatted.contains("₹"))
        XCTAssertTrue(formatted.contains("Cr") || formatted.contains("12"))
    }
    
    func testIndianCurrencyFormattingThousands() {
        let amount: Decimal = 12_345 // < 1 lakh
        
        let formatted = formatter.formatIndianCurrency(amount)
        XCTAssertTrue(formatted.contains("₹"))
        XCTAssertTrue(formatted.contains("K") || formatted.contains("12"))
    }
    
    func testIndianCurrencyFormattingSmallAmounts() {
        let amount: Decimal = 123
        
        let formatted = formatter.formatIndianCurrency(amount)
        XCTAssertTrue(formatted.contains("₹"))
        XCTAssertTrue(formatted.contains("123"))
    }
    
    func testIndianCurrencyFormattingNegative() {
        let amount: Decimal = -1_234_567
        
        let formatted = formatter.formatIndianCurrency(amount)
        XCTAssertTrue(formatted.contains("-"))
        XCTAssertTrue(formatted.contains("₹"))
    }
    
    // MARK: - Western Numbering System Tests
    
    func testWesternCurrencyFormattingThousands() {
        let amount: Decimal = 12_345
        
        let formatted = formatter.formatWesternCurrency(amount, currency: .usd)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("K") || formatted.contains("12"))
    }
    
    func testWesternCurrencyFormattingMillions() {
        let amount: Decimal = 12_345_678
        
        let formatted = formatter.formatWesternCurrency(amount, currency: .usd)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("M") || formatted.contains("12"))
    }
    
    func testWesternCurrencyFormattingBillions() {
        let amount: Decimal = 12_345_678_901
        
        let formatted = formatter.formatWesternCurrency(amount, currency: .usd)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("B") || formatted.contains("12"))
    }
    
    // MARK: - Symbol Only Formatting Tests
    
    func testSymbolOnlyFormatting() {
        let amount: Decimal = 1234.56
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .symbolOnly)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("1234"))
        XCTAssertFalse(formatted.contains("USD"))
    }
    
    // MARK: - Code Only Formatting Tests
    
    func testCodeOnlyFormatting() {
        let amount: Decimal = 1234.56
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .codeOnly)
        XCTAssertTrue(formatted.contains("USD"))
        XCTAssertTrue(formatted.contains("1234"))
        XCTAssertFalse(formatted.contains("$"))
    }
    
    // MARK: - Accessible Formatting Tests
    
    func testAccessibleFormatting() {
        let amount: Decimal = 1234.56
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .accessible)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("1234"))
        XCTAssertTrue(formatted.contains("Dollar") || formatted.lowercased().contains("dollar"))
    }
    
    // MARK: - Decimal Places Tests
    
    func testZeroDecimalPlaceCurrencies() {
        let amount: Decimal = 1234.56
        
        let jpyFormatted = formatter.formatCurrency(amount, currency: .jpy, style: .standard)
        XCTAssertTrue(jpyFormatted.contains("¥"))
        XCTAssertTrue(jpyFormatted.contains("1235") || jpyFormatted.contains("1234"))
        XCTAssertFalse(jpyFormatted.contains("."))
        
        let krwFormatted = formatter.formatCurrency(amount, currency: .krw, style: .standard)
        XCTAssertTrue(krwFormatted.contains("₩"))
        XCTAssertFalse(krwFormatted.contains("."))
    }
    
    func testThreeDecimalPlaceCurrencies() {
        let amount: Decimal = 1234.567
        
        let bhdFormatted = formatter.formatCurrency(amount, currency: .bhd, style: .standard)
        // Should handle 3 decimal places for Bahraini Dinar
        XCTAssertTrue(bhdFormatted.contains("1234"))
    }
    
    // MARK: - LocalizedCurrencyFormatter Tests
    
    func testLocalizedCurrencyFormatterShared() {
        let sharedFormatter = LocalizedCurrencyFormatter.shared
        XCTAssertNotNil(sharedFormatter)
        
        let amount: Decimal = 1234.56
        let formatted = sharedFormatter.formatCurrency(amount, currency: .usd)
        XCTAssertTrue(formatted.contains("$"))
    }
    
    func testLocalizedCurrencyFormatterWithDifferentLocales() {
        let sharedFormatter = LocalizedCurrencyFormatter.shared
        
        let amount: Decimal = 1234.56
        
        let usFormatted = sharedFormatter.formatCurrency(
            amount,
            currency: .usd,
            locale: Locale(identifier: "en_US")
        )
        
        let deFormatted = sharedFormatter.formatCurrency(
            amount,
            currency: .eur,
            locale: Locale(identifier: "de_DE")
        )
        
        XCTAssertTrue(usFormatted.contains("$"))
        XCTAssertTrue(deFormatted.contains("€"))
        
        // Formats should be different due to locale differences
        XCTAssertNotEqual(usFormatted, deFormatted)
    }
    
    func testLocalizedCurrencyFormatterCaching() {
        let sharedFormatter = LocalizedCurrencyFormatter.shared
        
        let locale = Locale(identifier: "en_US")
        let formatter1 = sharedFormatter.formatter(for: locale)
        let formatter2 = sharedFormatter.formatter(for: locale)
        
        // Should return the same cached instance
        XCTAssertTrue(formatter1 === formatter2)
    }
    
    func testLocalizedCurrencyFormatterClearCache() {
        let sharedFormatter = LocalizedCurrencyFormatter.shared
        
        let locale = Locale(identifier: "en_US")
        let formatter1 = sharedFormatter.formatter(for: locale)
        
        sharedFormatter.clearCache()
        
        let formatter2 = sharedFormatter.formatter(for: locale)
        
        // Should be different instances after cache clear
        XCTAssertFalse(formatter1 === formatter2)
    }
    
    // MARK: - Decimal Extension Tests
    
    func testDecimalFormattedExtension() {
        let amount: Decimal = 1234.56
        
        let formatted = amount.formatted(as: .usd, style: .standard)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("1234"))
    }
    
    func testDecimalIndianCurrencyExtension() {
        let amount: Decimal = 1_234_567
        
        let formatted = amount.formattedAsIndianCurrency()
        XCTAssertTrue(formatted.contains("₹"))
        XCTAssertTrue(formatted.contains("L") || formatted.contains("12"))
    }
    
    // MARK: - Performance Tests
    
    func testFormattingPerformance() {
        let amount: Decimal = 1234.56
        
        measure {
            for _ in 0..<1000 {
                _ = formatter.formatCurrency(amount, currency: .usd, style: .standard)
            }
        }
    }
    
    func testIndianFormattingPerformance() {
        let amount: Decimal = 12_345_678
        
        measure {
            for _ in 0..<1000 {
                _ = formatter.formatIndianCurrency(amount)
            }
        }
    }
    
    func testCompactFormattingPerformance() {
        let amount: Decimal = 12_345_678
        
        measure {
            for _ in 0..<1000 {
                _ = formatter.formatCurrency(amount, currency: .usd, style: .compact)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testVeryLargeAmountFormatting() {
        let amount: Decimal = 999_999_999_999_999
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .compact)
        XCTAssertTrue(formatted.contains("$"))
        // Should handle very large numbers gracefully
    }
    
    func testVerySmallPositiveAmountFormatting() {
        let amount: Decimal = 0.01
        
        let formatted = formatter.formatCurrency(amount, currency: .usd, style: .standard)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("0.01") || formatted.contains("1"))
    }
    
    func testFractionalAmountWithZeroDecimalCurrency() {
        let amount: Decimal = 1234.78
        
        let formatted = formatter.formatCurrency(amount, currency: .jpy, style: .standard)
        XCTAssertTrue(formatted.contains("¥"))
        // Should round to nearest whole number for JPY
        XCTAssertFalse(formatted.contains("."))
    }
    
    func testDifferentLocaleFormattingConsistency() {
        let amount: Decimal = 1234.56
        
        let usFormatter = CurrencyFormatter(locale: Locale(identifier: "en_US"))
        let inFormatter = CurrencyFormatter(locale: Locale(identifier: "en_IN"))
        
        let usFormatted = usFormatter.formatCurrency(amount, currency: .usd, style: .standard)
        let inFormatted = inFormatter.formatCurrency(amount, currency: .usd, style: .standard)
        
        // Both should contain the currency symbol and amount
        XCTAssertTrue(usFormatted.contains("$"))
        XCTAssertTrue(inFormatted.contains("$"))
        XCTAssertTrue(usFormatted.contains("1234"))
        XCTAssertTrue(inFormatted.contains("1234"))
    }
}