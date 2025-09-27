import XCTest
@testable import WealthWise

/// Comprehensive tests for LocalizedNumberFormatter
@available(iOS 18.6, macOS 15.6, *)
final class LocalizedNumberFormatterTests: XCTestCase {
    
    var indianFormatter: LocalizedNumberFormatter!
    var americanFormatter: LocalizedNumberFormatter!
    var britishFormatter: LocalizedNumberFormatter!
    var europeanFormatter: LocalizedNumberFormatter!
    
    override func setUp() {
        super.setUp()
        indianFormatter = LocalizedNumberFormatter.indianFormatter()
        americanFormatter = LocalizedNumberFormatter.americanFormatter()
        britishFormatter = LocalizedNumberFormatter.britishFormatter()
        europeanFormatter = LocalizedNumberFormatter.europeanFormatter()
    }
    
    override func tearDown() {
        indianFormatter = nil
        americanFormatter = nil
        britishFormatter = nil
        europeanFormatter = nil
        super.tearDown()
    }
    
    // MARK: - Indian Number System Tests
    
    func testIndianNumberFormatting() {
        // Test basic numbers
        XCTAssertEqual(indianFormatter.string(from: 1000), "1,000")
        XCTAssertEqual(indianFormatter.string(from: 10000), "10,000")
        XCTAssertEqual(indianFormatter.string(from: 100000), "1,00,000")
        XCTAssertEqual(indianFormatter.string(from: 1000000), "10,00,000")
        XCTAssertEqual(indianFormatter.string(from: 10000000), "1,00,00,000")
        XCTAssertEqual(indianFormatter.string(from: 100000000), "10,00,00,000")
    }
    
    func testIndianAbbreviations() {
        let abbreviatedFormatter = LocalizedNumberFormatter.indianFormatter(abbreviated: true)
        
        // Test lakh abbreviations
        XCTAssertEqual(abbreviatedFormatter.string(from: 100000), "1L")
        XCTAssertEqual(abbreviatedFormatter.string(from: 150000), "1.5L")
        XCTAssertEqual(abbreviatedFormatter.string(from: 1500000), "15L")
        
        // Test crore abbreviations
        XCTAssertEqual(abbreviatedFormatter.string(from: 10000000), "1Cr")
        XCTAssertEqual(abbreviatedFormatter.string(from: 25000000), "2.5Cr")
        XCTAssertEqual(abbreviatedFormatter.string(from: 125000000), "12Cr") // Rounded to nearest integer
    }
    
    func testIndianDecimalFormatting() {
        // Test decimal numbers
        XCTAssertEqual(indianFormatter.string(from: 1234.56), "1,234.56")
        XCTAssertEqual(indianFormatter.string(from: 123456.78), "1,23,456.78")
        XCTAssertEqual(indianFormatter.string(from: 12345678.90), "1,23,45,678.90")
    }
    
    // MARK: - American Number System Tests
    
    func testAmericanNumberFormatting() {
        // Test basic numbers
        XCTAssertEqual(americanFormatter.string(from: 1000), "1,000")
        XCTAssertEqual(americanFormatter.string(from: 10000), "10,000")
        XCTAssertEqual(americanFormatter.string(from: 100000), "100,000")
        XCTAssertEqual(americanFormatter.string(from: 1000000), "1,000,000")
        XCTAssertEqual(americanFormatter.string(from: 10000000), "10,000,000")
        XCTAssertEqual(americanFormatter.string(from: 100000000), "100,000,000")
    }
    
    func testAmericanAbbreviations() {
        let abbreviatedFormatter = LocalizedNumberFormatter.americanFormatter(abbreviated: true)
        
        // Test thousand abbreviations
        XCTAssertEqual(abbreviatedFormatter.string(from: 1000), "1K")
        XCTAssertEqual(abbreviatedFormatter.string(from: 1500), "1.5K")
        XCTAssertEqual(abbreviatedFormatter.string(from: 15000), "15K")
        
        // Test million abbreviations
        XCTAssertEqual(abbreviatedFormatter.string(from: 1000000), "1M")
        XCTAssertEqual(abbreviatedFormatter.string(from: 2500000), "2.5M")
        XCTAssertEqual(abbreviatedFormatter.string(from: 125000000), "125M")
        
        // Test billion abbreviations
        XCTAssertEqual(abbreviatedFormatter.string(from: 1000000000), "1B")
        XCTAssertEqual(abbreviatedFormatter.string(from: 2500000000), "2.5B")
    }
    
    // MARK: - European Number System Tests
    
    func testEuropeanNumberFormatting() {
        // European style uses comma as decimal separator and period as grouping
        let config = NumberFormatterConfiguration.european
        let formatter = LocalizedNumberFormatter(configuration: config)
        
        // Note: Actual behavior depends on locale implementation
        // These tests verify the configuration is applied correctly
        XCTAssertEqual(formatter.configuration.numberingSystem.separators.decimalSeparator, ",")
        XCTAssertEqual(formatter.configuration.numberingSystem.separators.groupingSeparator, ".")
    }
    
    // MARK: - Negative Number Tests
    
    func testNegativeNumbers() {
        XCTAssertEqual(indianFormatter.string(from: -1000), "-1,000")
        XCTAssertEqual(indianFormatter.string(from: -100000), "-1,00,000")
        XCTAssertEqual(americanFormatter.string(from: -1000000), "-1,000,000")
    }
    
    // MARK: - Zero and Small Number Tests
    
    func testZeroAndSmallNumbers() {
        XCTAssertEqual(indianFormatter.string(from: 0), "0")
        XCTAssertEqual(indianFormatter.string(from: 1), "1")
        XCTAssertEqual(indianFormatter.string(from: 99), "99")
        XCTAssertEqual(indianFormatter.string(from: 999), "999")
    }
    
    // MARK: - Parsing Tests
    
    func testParsingIndianNumbers() {
        XCTAssertEqual(indianFormatter.decimal(from: "1,000"), 1000)
        XCTAssertEqual(indianFormatter.decimal(from: "1,00,000"), 100000)
        XCTAssertEqual(indianFormatter.decimal(from: "1,23,45,678"), 12345678)
        
        // Test abbreviated parsing
        let abbreviatedFormatter = LocalizedNumberFormatter.indianFormatter(abbreviated: true)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "1L"), 100000)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "1.5L"), 150000)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "1Cr"), 10000000)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "2.5Cr"), 25000000)
    }
    
    func testParsingAmericanNumbers() {
        XCTAssertEqual(americanFormatter.decimal(from: "1,000"), 1000)
        XCTAssertEqual(americanFormatter.decimal(from: "1,000,000"), 1000000)
        XCTAssertEqual(americanFormatter.decimal(from: "123,456,789"), 123456789)
        
        // Test abbreviated parsing
        let abbreviatedFormatter = LocalizedNumberFormatter.americanFormatter(abbreviated: true)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "1K"), 1000)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "1.5K"), 1500)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "1M"), 1000000)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "2.5M"), 2500000)
        XCTAssertEqual(abbreviatedFormatter.decimal(from: "1B"), 1000000000)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationChanges() {
        var config = NumberFormatterConfiguration.american
        let formatter = LocalizedNumberFormatter(configuration: config)
        
        XCTAssertEqual(formatter.string(from: 1000000), "1,000,000")
        
        // Change to Indian configuration
        formatter.configuration = NumberFormatterConfiguration.indian
        XCTAssertEqual(formatter.string(from: 1000000), "10,00,000")
    }
    
    func testAbbreviationThreshold() {
        var config = NumberFormatterConfiguration.american
        config = NumberFormatterConfiguration(
            numberingSystem: config.numberingSystem,
            audience: config.audience,
            minimumFractionDigits: config.minimumFractionDigits,
            maximumFractionDigits: config.maximumFractionDigits,
            usesGroupingSeparator: config.usesGroupingSeparator,
            useAbbreviation: true,
            abbreviationThreshold: 10000, // Lower threshold
            localeIdentifier: config.localeIdentifier
        )
        
        let formatter = LocalizedNumberFormatter(configuration: config)
        
        // Should not abbreviate below threshold
        XCTAssertEqual(formatter.string(from: 5000), "5,000")
        
        // Should abbreviate above threshold
        XCTAssertEqual(formatter.string(from: 15000), "15K")
    }
    
    // MARK: - Edge Cases Tests
    
    func testVeryLargeNumbers() {
        let largeNumber = Decimal(string: "123456789012345")!
        
        // Test Indian system with very large numbers
        let result = indianFormatter.string(from: largeNumber)
        XCTAssertFalse(result.isEmpty)
        
        // Test American system with very large numbers
        let americanResult = americanFormatter.string(from: largeNumber)
        XCTAssertFalse(americanResult.isEmpty)
    }
    
    func testVerySmallDecimals() {
        let smallDecimal = Decimal(string: "0.00000001")!
        
        let result = indianFormatter.string(from: smallDecimal)
        XCTAssertFalse(result.isEmpty)
    }
    
    func testInvalidStrings() {
        XCTAssertNil(indianFormatter.decimal(from: ""))
        XCTAssertNil(indianFormatter.decimal(from: "invalid"))
        XCTAssertNil(indianFormatter.decimal(from: "1,2,3"))
        XCTAssertNil(americanFormatter.decimal(from: "1L")) // American formatter shouldn't parse Indian abbreviations
    }
    
    // MARK: - Performance Tests
    
    func testFormattingPerformance() {
        let numbers = (1...1000).map { Decimal($0 * 1000) }
        
        measure {
            for number in numbers {
                _ = indianFormatter.string(from: number)
            }
        }
    }
    
    func testParsingPerformance() {
        let strings = (1...1000).map { "\($0 * 1000)" }
        
        measure {
            for string in strings {
                _ = americanFormatter.decimal(from: string)
            }
        }
    }
    
    func testCacheEffectiveness() {
        let testNumber = Decimal(123456)
        
        // First call should populate cache
        let result1 = indianFormatter.string(from: testNumber)
        
        // Subsequent calls should use cache
        let result2 = indianFormatter.string(from: testNumber)
        let result3 = indianFormatter.string(from: testNumber)
        
        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityConfiguration() {
        let accessibilityFormatter = LocalizedNumberFormatter.accessibilityFormatter(for: .indian)
        
        // Accessibility formatter should never abbreviate
        XCTAssertFalse(accessibilityFormatter.configuration.useAbbreviation)
        XCTAssertEqual(accessibilityFormatter.configuration.abbreviationThreshold, Decimal.greatestFiniteMagnitude)
        
        let result = accessibilityFormatter.string(from: 1000000)
        XCTAssertEqual(result, "10,00,000") // Full format, not abbreviated
    }
}