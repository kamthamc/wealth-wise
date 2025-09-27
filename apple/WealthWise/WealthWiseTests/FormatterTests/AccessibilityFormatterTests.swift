import XCTest
@testable import WealthWise

/// Comprehensive tests for AccessibleNumberFormatter
@available(iOS 18.6, macOS 15.6, *)
final class AccessibilityFormatterTests: XCTestCase {
    
    var indianAccessibilityFormatter: AccessibleNumberFormatter!
    var americanAccessibilityFormatter: AccessibleNumberFormatter!
    
    override func setUp() {
        super.setUp()
        indianAccessibilityFormatter = AccessibleNumberFormatter.indianAccessibilityFormatter()
        americanAccessibilityFormatter = AccessibleNumberFormatter.americanAccessibilityFormatter()
    }
    
    override func tearDown() {
        indianAccessibilityFormatter = nil
        americanAccessibilityFormatter = nil
        super.tearDown()
    }
    
    // MARK: - Indian Number System Accessibility Tests
    
    func testIndianNumberAccessibility() {
        // Test basic numbers
        XCTAssertEqual(indianAccessibilityFormatter.accessibleString(from: 0), "zero")
        XCTAssertEqual(indianAccessibilityFormatter.accessibleString(from: 1000), "1,000")
        
        // Test lakh
        let lakhResult = indianAccessibilityFormatter.accessibleString(from: 100000)
        XCTAssertTrue(lakhResult.contains("lakh") || lakhResult.contains("1,00,000"))
        
        // Test crore
        let croreResult = indianAccessibilityFormatter.accessibleString(from: 10000000)
        XCTAssertTrue(croreResult.contains("crore") || croreResult.contains("1,00,00,000"))
        
        // Test mixed amounts
        let mixedResult = indianAccessibilityFormatter.accessibleString(from: 12345678)
        XCTAssertFalse(mixedResult.isEmpty)
    }
    
    func testIndianNegativeNumbers() {
        let negativeResult = indianAccessibilityFormatter.accessibleString(from: -100000)
        XCTAssertTrue(negativeResult.contains("negative"))
        XCTAssertTrue(negativeResult.contains("lakh") || negativeResult.contains("1,00,000"))
    }
    
    // MARK: - American Number System Accessibility Tests
    
    func testAmericanNumberAccessibility() {
        // Test basic numbers
        XCTAssertEqual(americanAccessibilityFormatter.accessibleString(from: 0), "zero")
        XCTAssertEqual(americanAccessibilityFormatter.accessibleString(from: 1000), "1,000")
        
        // Test thousand
        let thousandResult = americanAccessibilityFormatter.accessibleString(from: 1000)
        XCTAssertTrue(thousandResult.contains("thousand") || thousandResult.contains("1,000"))
        
        // Test million
        let millionResult = americanAccessibilityFormatter.accessibleString(from: 1000000)
        XCTAssertTrue(millionResult.contains("million") || millionResult.contains("1,000,000"))
        
        // Test billion
        let billionResult = americanAccessibilityFormatter.accessibleString(from: 1000000000)
        XCTAssertTrue(billionResult.contains("billion") || billionResult.contains("1,000,000,000"))
    }
    
    func testAmericanNegativeNumbers() {
        let negativeResult = americanAccessibilityFormatter.accessibleString(from: -1000000)
        XCTAssertTrue(negativeResult.contains("negative"))
        XCTAssertTrue(negativeResult.contains("million") || negativeResult.contains("1,000,000"))
    }
    
    // MARK: - Currency Accessibility Tests
    
    func testIndianRupeeCurrencyAccessibility() {
        // Test whole rupees
        let wholeRupeesResult = indianAccessibilityFormatter.accessibleCurrencyString(
            from: 1000,
            currency: .INR
        )
        XCTAssertTrue(wholeRupeesResult.contains("rupees"))
        XCTAssertFalse(wholeRupeesResult.contains("paise"))
        
        // Test rupees with paise
        let rupeesWithPaiseResult = indianAccessibilityFormatter.accessibleCurrencyString(
            from: 1000.50,
            currency: .INR
        )
        XCTAssertTrue(rupeesWithPaiseResult.contains("rupees"))
        XCTAssertTrue(rupeesWithPaiseResult.contains("paise"))
        XCTAssertTrue(rupeesWithPaiseResult.contains("and"))
    }
    
    func testUSDollarCurrencyAccessibility() {
        // Test whole dollars
        let wholeDollarsResult = americanAccessibilityFormatter.accessibleCurrencyString(
            from: 1000,
            currency: .USD
        )
        XCTAssertTrue(wholeDollarsResult.contains("dollars"))
        XCTAssertFalse(wholeDollarsResult.contains("cents"))
        
        // Test dollars with cents
        let dollarsWithCentsResult = americanAccessibilityFormatter.accessibleCurrencyString(
            from: 1000.25,
            currency: .USD
        )
        XCTAssertTrue(dollarsWithCentsResult.contains("dollars"))
        XCTAssertTrue(dollarsWithCentsResult.contains("cents"))
        XCTAssertTrue(dollarsWithCentsResult.contains("and"))
    }
    
    func testBritishPoundCurrencyAccessibility() {
        // Test whole pounds
        let wholePoundsResult = americanAccessibilityFormatter.accessibleCurrencyString(
            from: 1000,
            currency: .GBP
        )
        XCTAssertTrue(wholePoundsResult.contains("pounds"))
        
        // Test pounds with pence
        let poundsWithPenceResult = americanAccessibilityFormatter.accessibleCurrencyString(
            from: 1000.50,
            currency: .GBP
        )
        XCTAssertTrue(poundsWithPenceResult.contains("pounds"))
        XCTAssertTrue(poundsWithPenceResult.contains("pence"))
        XCTAssertTrue(poundsWithPenceResult.contains("and"))
    }
    
    func testJapaneseYenCurrencyAccessibility() {
        // Test yen (no fractional units)
        let yenResult = americanAccessibilityFormatter.accessibleCurrencyString(
            from: 1000,
            currency: .JPY
        )
        XCTAssertTrue(yenResult.contains("yen"))
        XCTAssertFalse(yenResult.contains("and")) // No fractional units
    }
    
    // MARK: - Phonetic Representation Tests
    
    func testPhoneticString() {
        let phoneticResult = indianAccessibilityFormatter.phoneticString(from: 1000)
        XCTAssertFalse(phoneticResult.isEmpty)
        
        // Should contain phonetic markers or at least the original string
        XCTAssertTrue(phoneticResult.contains("1,000") || phoneticResult.contains("break"))
    }
    
    // MARK: - Zero and Edge Cases Tests
    
    func testZeroCurrency() {
        let zeroRupeesResult = indianAccessibilityFormatter.accessibleCurrencyString(
            from: 0,
            currency: .INR
        )
        XCTAssertTrue(zeroRupeesResult.contains("zero"))
        XCTAssertTrue(zeroRupeesResult.contains("rupees"))
    }
    
    func testVerySmallCurrency() {
        let smallAmountResult = indianAccessibilityFormatter.accessibleCurrencyString(
            from: 0.01,
            currency: .INR
        )
        XCTAssertTrue(smallAmountResult.contains("paise") || smallAmountResult.contains("0.01"))
    }
    
    func testVeryLargeNumbers() {
        let largeNumber = Decimal(string: "123456789012345")!
        let result = indianAccessibilityFormatter.accessibleString(from: largeNumber)
        XCTAssertFalse(result.isEmpty)
        
        // Should handle large numbers gracefully
        XCTAssertTrue(result.contains("crore") || result.contains("123456789012345"))
    }
    
    // MARK: - Decimal Handling Tests
    
    func testDecimalNumbers() {
        let decimalResult = indianAccessibilityFormatter.accessibleString(from: 1234.56)
        XCTAssertFalse(decimalResult.isEmpty)
        XCTAssertTrue(decimalResult.contains("1,234.56") || decimalResult.contains("1234.56"))
    }
    
    func testDecimalCurrency() {
        let decimalCurrencyResult = indianAccessibilityFormatter.accessibleCurrencyString(
            from: 1234.56,
            currency: .USD
        )
        XCTAssertTrue(decimalCurrencyResult.contains("dollars"))
        XCTAssertTrue(decimalCurrencyResult.contains("cents"))
        XCTAssertTrue(decimalCurrencyResult.contains("and"))
    }
    
    // MARK: - Configuration Tests
    
    func testAccessibilityConfiguration() {
        let config = indianAccessibilityFormatter.configuration
        
        // Accessibility formatter should never abbreviate
        XCTAssertFalse(config.useAbbreviation)
        XCTAssertEqual(config.abbreviationThreshold, Decimal.greatestFiniteMagnitude)
        XCTAssertTrue(config.useAccessibilityFormatting)
    }
    
    func testDifferentAudienceFormatters() {
        let audiences: [PrimaryAudience] = [.indian, .american, .british, .canadian]
        
        for audience in audiences {
            let formatter = AccessibleNumberFormatter.accessibilityFormatter(for: audience)
            let result = formatter.accessibleString(from: 1000000)
            
            XCTAssertFalse(result.isEmpty)
            
            // Different audiences should produce different results
            switch audience {
            case .indian:
                XCTAssertTrue(result.contains("lakh") || result.contains("10,00,000"))
            case .american, .british, .canadian:
                XCTAssertTrue(result.contains("million") || result.contains("1,000,000"))
            default:
                break
            }
        }
    }
    
    // MARK: - Localization Tests
    
    func testLocalizedStrings() {
        // Test that localized strings are not empty
        let zeroResult = indianAccessibilityFormatter.accessibleString(from: 0)
        XCTAssertFalse(zeroResult.isEmpty)
        
        let negativeResult = indianAccessibilityFormatter.accessibleString(from: -100)
        XCTAssertTrue(negativeResult.contains("negative") || negativeResult.contains("-"))
    }
    
    // MARK: - Performance Tests
    
    func testAccessibilityFormattingPerformance() {
        let numbers = (1...100).map { Decimal($0 * 10000) }
        
        measure {
            for number in numbers {
                _ = indianAccessibilityFormatter.accessibleString(from: number)
            }
        }
    }
    
    func testCurrencyAccessibilityPerformance() {
        let amounts = (1...100).map { Decimal($0 * 1000) }
        
        measure {
            for amount in amounts {
                _ = indianAccessibilityFormatter.accessibleCurrencyString(from: amount, currency: .INR)
            }
        }
    }
    
    // MARK: - Speech Synthesis Tests
    
    func testPronunciationTesting() {
        let expectation = expectation(description: "Pronunciation test completion")
        
        indianAccessibilityFormatter.testPronunciation(of: 1000) { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Complex Number Tests
    
    func testComplexIndianNumbers() {
        // Test 1,23,45,678 (1 crore 23 lakh 45 thousand 6 hundred 78)
        let complexNumber = Decimal(12345678)
        let result = indianAccessibilityFormatter.accessibleString(from: complexNumber)
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("crore") || result.contains("1,23,45,678"))
    }
    
    func testComplexAmericanNumbers() {
        // Test 123,456,789 (123 million 456 thousand 789)
        let complexNumber = Decimal(123456789)
        let result = americanAccessibilityFormatter.accessibleString(from: complexNumber)
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("million") || result.contains("123,456,789"))
    }
    
    // MARK: - Multiple Currency Tests
    
    func testMultipleCurrencyAccessibility() {
        let currencies: [SupportedCurrency] = [.INR, .USD, .EUR, .GBP, .JPY, .CAD, .AUD]
        let amount = Decimal(1000)
        
        for currency in currencies {
            let result = indianAccessibilityFormatter.accessibleCurrencyString(
                from: amount,
                currency: currency
            )
            
            XCTAssertFalse(result.isEmpty)
            
            // Each currency should have appropriate accessibility description
            switch currency {
            case .INR:
                XCTAssertTrue(result.contains("rupees"))
            case .USD:
                XCTAssertTrue(result.contains("dollars"))
            case .EUR:
                XCTAssertTrue(result.contains("euros"))
            case .GBP:
                XCTAssertTrue(result.contains("pounds"))
            case .JPY:
                XCTAssertTrue(result.contains("yen"))
            default:
                // Should contain some currency identifier
                XCTAssertTrue(result.count > 4) // More than just the number
            }
        }
    }
}