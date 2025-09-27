import XCTest
@testable import WealthWise

/// Comprehensive tests for LocalizedCurrencyFormatter
@available(iOS 18.6, macOS 15.6, *)
final class LocalizedCurrencyFormatterTests: XCTestCase {
    
    var indianRupeeFormatter: LocalizedCurrencyFormatter!
    var usDollarFormatter: LocalizedCurrencyFormatter!
    var britishPoundFormatter: LocalizedCurrencyFormatter!
    var euroFormatter: LocalizedCurrencyFormatter!
    
    override func setUp() {
        super.setUp()
        indianRupeeFormatter = LocalizedCurrencyFormatter.indianRupeeFormatter()
        usDollarFormatter = LocalizedCurrencyFormatter.usDollarFormatter()
        britishPoundFormatter = LocalizedCurrencyFormatter.britishPoundFormatter()
        euroFormatter = LocalizedCurrencyFormatter.euroFormatter()
    }
    
    override func tearDown() {
        indianRupeeFormatter = nil
        usDollarFormatter = nil
        britishPoundFormatter = nil
        euroFormatter = nil
        super.tearDown()
    }
    
    // MARK: - Indian Rupee Formatting Tests
    
    func testIndianRupeeFormatting() {
        // Test basic amounts
        XCTAssertTrue(indianRupeeFormatter.string(from: 1000).contains("₹"))
        XCTAssertTrue(indianRupeeFormatter.string(from: 100000).contains("1,00,000"))
        XCTAssertTrue(indianRupeeFormatter.string(from: 10000000).contains("1,00,00,000"))
        
        // Test decimal amounts
        let result = indianRupeeFormatter.string(from: 1234.56)
        XCTAssertTrue(result.contains("₹"))
        XCTAssertTrue(result.contains("1,234.56"))
    }
    
    func testIndianRupeeAbbreviations() {
        let abbreviatedFormatter = LocalizedCurrencyFormatter.indianRupeeFormatter(abbreviated: true)
        
        // Test lakh abbreviations
        let lakhResult = abbreviatedFormatter.string(from: 100000)
        XCTAssertTrue(lakhResult.contains("₹"))
        XCTAssertTrue(lakhResult.contains("1L"))
        
        // Test crore abbreviations
        let croreResult = abbreviatedFormatter.string(from: 10000000)
        XCTAssertTrue(croreResult.contains("₹"))
        XCTAssertTrue(croreResult.contains("1Cr"))
    }
    
    func testIndianRupeeSymbolPosition() {
        let result = indianRupeeFormatter.string(from: 1000)
        
        // Symbol should be before the amount for Indian formatting
        XCTAssertTrue(result.hasPrefix("₹") || result.hasPrefix("₹ "))
    }
    
    // MARK: - US Dollar Formatting Tests
    
    func testUSDollarFormatting() {
        // Test basic amounts
        XCTAssertTrue(usDollarFormatter.string(from: 1000).contains("$"))
        XCTAssertTrue(usDollarFormatter.string(from: 1000000).contains("1,000,000"))
        
        // Test decimal amounts
        let result = usDollarFormatter.string(from: 1234.56)
        XCTAssertTrue(result.contains("$"))
        XCTAssertTrue(result.contains("1,234.56"))
    }
    
    func testUSDollarAbbreviations() {
        let abbreviatedFormatter = LocalizedCurrencyFormatter.usDollarFormatter(abbreviated: true)
        
        // Test million abbreviations
        let millionResult = abbreviatedFormatter.string(from: 1000000)
        XCTAssertTrue(millionResult.contains("$"))
        XCTAssertTrue(millionResult.contains("1M"))
        
        // Test billion abbreviations
        let billionResult = abbreviatedFormatter.string(from: 1000000000)
        XCTAssertTrue(billionResult.contains("$"))
        XCTAssertTrue(billionResult.contains("1B"))
    }
    
    // MARK: - British Pound Formatting Tests
    
    func testBritishPoundFormatting() {
        // Test basic amounts
        XCTAssertTrue(britishPoundFormatter.string(from: 1000).contains("£"))
        XCTAssertTrue(britishPoundFormatter.string(from: 1000000).contains("1,000,000"))
        
        // Test decimal amounts
        let result = britishPoundFormatter.string(from: 1234.56)
        XCTAssertTrue(result.contains("£"))
        XCTAssertTrue(result.contains("1,234.56"))
    }
    
    // MARK: - Euro Formatting Tests
    
    func testEuroFormatting() {
        // Test basic amounts
        XCTAssertTrue(euroFormatter.string(from: 1000).contains("€"))
        
        // Test decimal amounts
        let result = euroFormatter.string(from: 1234.56)
        XCTAssertTrue(result.contains("€"))
    }
    
    // MARK: - Currency Symbol Tests
    
    func testCurrencySymbols() {
        XCTAssertEqual(indianRupeeFormatter.currency.symbol, "₹")
        XCTAssertEqual(usDollarFormatter.currency.symbol, "$")
        XCTAssertEqual(britishPoundFormatter.currency.symbol, "£")
        XCTAssertEqual(euroFormatter.currency.symbol, "€")
    }
    
    func testCurrencySymbolWithSpacing() {
        // Test symbol with spacing
        let symbolWithSpacing = indianRupeeFormatter.currencySymbol(withSpacing: true)
        let symbolWithoutSpacing = indianRupeeFormatter.currencySymbol(withSpacing: false)
        
        XCTAssertTrue(symbolWithSpacing.contains(" ") || symbolWithSpacing == "₹")
        XCTAssertEqual(symbolWithoutSpacing, "₹")
    }
    
    // MARK: - Negative Amount Tests
    
    func testNegativeAmounts() {
        let negativeResult = indianRupeeFormatter.string(from: -1000)
        XCTAssertTrue(negativeResult.contains("-"))
        XCTAssertTrue(negativeResult.contains("₹"))
        XCTAssertTrue(negativeResult.contains("1,000"))
    }
    
    // MARK: - Zero Amount Tests
    
    func testZeroAmounts() {
        let zeroResult = indianRupeeFormatter.string(from: 0)
        XCTAssertTrue(zeroResult.contains("₹"))
        XCTAssertTrue(zeroResult.contains("0"))
    }
    
    // MARK: - Parsing Tests
    
    func testParsingIndianRupee() {
        // Test parsing formatted currency strings
        let amount1 = indianRupeeFormatter.decimal(from: "₹ 1,000")
        XCTAssertEqual(amount1, 1000)
        
        let amount2 = indianRupeeFormatter.decimal(from: "₹ 1,00,000")
        XCTAssertEqual(amount2, 100000)
        
        // Test parsing abbreviated strings
        let abbreviatedFormatter = LocalizedCurrencyFormatter.indianRupeeFormatter(abbreviated: true)
        let amount3 = abbreviatedFormatter.decimal(from: "₹1L")
        XCTAssertEqual(amount3, 100000)
        
        let amount4 = abbreviatedFormatter.decimal(from: "₹1Cr")
        XCTAssertEqual(amount4, 10000000)
    }
    
    func testParsingUSDollar() {
        // Test parsing formatted currency strings
        let amount1 = usDollarFormatter.decimal(from: "$1,000")
        XCTAssertEqual(amount1, 1000)
        
        let amount2 = usDollarFormatter.decimal(from: "$1,000,000")
        XCTAssertEqual(amount2, 1000000)
        
        // Test parsing abbreviated strings
        let abbreviatedFormatter = LocalizedCurrencyFormatter.usDollarFormatter(abbreviated: true)
        let amount3 = abbreviatedFormatter.decimal(from: "$1M")
        XCTAssertEqual(amount3, 1000000)
        
        let amount4 = abbreviatedFormatter.decimal(from: "$1B")
        XCTAssertEqual(amount4, 1000000000)
    }
    
    // MARK: - Configuration Change Tests
    
    func testCurrencyChange() {
        let formatter = LocalizedCurrencyFormatter(currency: .USD, configuration: .american)
        
        // Initial currency
        XCTAssertTrue(formatter.string(from: 1000).contains("$"))
        
        // Change currency
        formatter.currency = .INR
        XCTAssertTrue(formatter.string(from: 1000).contains("₹"))
    }
    
    func testConfigurationChange() {
        let formatter = LocalizedCurrencyFormatter(currency: .USD, configuration: .american)
        
        // Initial configuration
        let americanResult = formatter.string(from: 1000000)
        XCTAssertTrue(americanResult.contains("1,000,000"))
        
        // Change to Indian configuration
        formatter.configuration = .indian
        let indianResult = formatter.string(from: 1000000)
        XCTAssertTrue(indianResult.contains("10,00,000"))
    }
    
    // MARK: - Multi-Currency Tests
    
    func testMultipleCurrencies() {
        let currencies: [SupportedCurrency] = [.INR, .USD, .EUR, .GBP, .JPY]
        let amount = Decimal(1000)
        
        for currency in currencies {
            let formatter = LocalizedCurrencyFormatter.formatter(
                for: currency,
                audience: .american,
                abbreviated: false
            )
            
            let result = formatter.string(from: amount)
            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains(currency.symbol))
        }
    }
    
    // MARK: - Decimal Precision Tests
    
    func testDecimalPrecision() {
        // Test different decimal precisions
        let amount = Decimal(string: "1234.5678")!
        
        // Default precision (2 decimal places)
        let defaultResult = indianRupeeFormatter.string(from: amount)
        XCTAssertTrue(defaultResult.contains("1,234.57") || defaultResult.contains("1,234.56"))
        
        // Create formatter with higher precision
        var config = NumberFormatterConfiguration.indian
        config = NumberFormatterConfiguration(
            numberingSystem: config.numberingSystem,
            audience: config.audience,
            minimumFractionDigits: 4,
            maximumFractionDigits: 4,
            usesGroupingSeparator: config.usesGroupingSeparator,
            useAbbreviation: config.useAbbreviation,
            abbreviationThreshold: config.abbreviationThreshold,
            localeIdentifier: config.localeIdentifier
        )
        
        let precisionFormatter = LocalizedCurrencyFormatter(currency: .INR, configuration: config)
        let precisionResult = precisionFormatter.string(from: amount)
        XCTAssertTrue(precisionResult.contains("1,234.5678"))
    }
    
    // MARK: - Edge Cases Tests
    
    func testVeryLargeAmounts() {
        let largeAmount = Decimal(string: "999999999999999")!
        
        let result = indianRupeeFormatter.string(from: largeAmount)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("₹"))
    }
    
    func testVerySmallAmounts() {
        let smallAmount = Decimal(string: "0.01")!
        
        let result = indianRupeeFormatter.string(from: smallAmount)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("₹"))
        XCTAssertTrue(result.contains("0.01"))
    }
    
    func testInvalidParsingStrings() {
        XCTAssertNil(indianRupeeFormatter.decimal(from: ""))
        XCTAssertNil(indianRupeeFormatter.decimal(from: "invalid"))
        XCTAssertNil(indianRupeeFormatter.decimal(from: "₹₹1000"))
        XCTAssertNil(usDollarFormatter.decimal(from: "₹1L")) // Wrong currency and format
    }
    
    // MARK: - Performance Tests
    
    func testFormattingPerformance() {
        let amounts = (1...1000).map { Decimal($0 * 1000) }
        
        measure {
            for amount in amounts {
                _ = indianRupeeFormatter.string(from: amount)
            }
        }
    }
    
    func testParsingPerformance() {
        let strings = (1...1000).map { "₹\($0 * 1000)" }
        
        measure {
            for string in strings {
                _ = indianRupeeFormatter.decimal(from: string)
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityFormatter() {
        let accessibilityFormatter = LocalizedCurrencyFormatter.accessibilityFormatter(
            for: .INR,
            audience: .indian
        )
        
        // Should never abbreviate for accessibility
        XCTAssertFalse(accessibilityFormatter.configuration.useAbbreviation)
        
        let result = accessibilityFormatter.string(from: 1000000)
        XCTAssertTrue(result.contains("₹"))
        XCTAssertTrue(result.contains("10,00,000")) // Full format, not abbreviated
    }
    
    // MARK: - Cache Tests
    
    func testCacheEffectiveness() {
        let testAmount = Decimal(123456)
        
        // First call should populate cache
        let result1 = indianRupeeFormatter.string(from: testAmount)
        
        // Subsequent calls should use cache
        let result2 = indianRupeeFormatter.string(from: testAmount)
        let result3 = indianRupeeFormatter.string(from: testAmount)
        
        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
    }
    
    func testCacheClearance() {
        let testAmount = Decimal(123456)
        
        // Populate cache
        _ = indianRupeeFormatter.string(from: testAmount)
        
        // Clear cache
        indianRupeeFormatter.clearCache()
        
        // Should still work after cache clear
        let result = indianRupeeFormatter.string(from: testAmount)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("₹"))
    }
}