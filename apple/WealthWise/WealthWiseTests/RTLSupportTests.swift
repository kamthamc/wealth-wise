//
//  RTLSupportTests.swift
//  WealthWiseTests
//
//  Comprehensive tests for RTL support system
//

import XCTest
import SwiftUI
@testable import WealthWise

final class RTLSupportTests: XCTestCase {
    
    var textDirectionDetector: TextDirectionDetector!
    var rtlLayoutManager: RTLLayoutManager!
    var biDirectionalHandler: BiDirectionalTextHandler!
    var rtlAccessibilityHelper: RTLAccessibilityHelper!
    
    override func setUp() {
        super.setUp()
        textDirectionDetector = TextDirectionDetector()
        rtlLayoutManager = RTLLayoutManager()
        biDirectionalHandler = BiDirectionalTextHandler()
        rtlAccessibilityHelper = RTLAccessibilityHelper()
    }
    
    override func tearDown() {
        textDirectionDetector = nil
        rtlLayoutManager = nil
        biDirectionalHandler = nil
        rtlAccessibilityHelper = nil
        super.tearDown()
    }
    
    // MARK: - Text Direction Detection Tests
    
    func testEnglishTextDetection() {
        let englishText = "Hello World"
        let direction = textDirectionDetector.detectDirection(for: englishText)
        XCTAssertEqual(direction, .leftToRight, "English text should be detected as LTR")
    }
    
    func testArabicTextDetection() {
        let arabicText = "مرحبا بالعالم"
        let direction = textDirectionDetector.detectDirection(for: arabicText)
        XCTAssertEqual(direction, .rightToLeft, "Arabic text should be detected as RTL")
    }
    
    func testHebrewTextDetection() {
        let hebrewText = "שלום עולם"
        let direction = textDirectionDetector.detectDirection(for: hebrewText)
        XCTAssertEqual(direction, .rightToLeft, "Hebrew text should be detected as RTL")
    }
    
    func testMixedTextDetection() {
        let mixedText = "Hello مرحبا World"
        let direction = textDirectionDetector.detectDirection(for: mixedText)
        // Should detect overall direction based on majority content
        XCTAssertNotEqual(direction, .auto, "Mixed text should have a determined direction")
    }
    
    func testEmptyTextDetection() {
        let emptyText = ""
        let direction = textDirectionDetector.detectDirection(for: emptyText)
        XCTAssertEqual(direction, .leftToRight, "Empty text should default to LTR")
    }
    
    func testNumbersAndSymbolsDetection() {
        let numbersText = "123 456 $100"
        let direction = textDirectionDetector.detectDirection(for: numbersText)
        XCTAssertEqual(direction, .leftToRight, "Numbers and symbols should default to LTR")
    }
    
    // MARK: - RTL Layout Manager Tests
    
    func testLayoutDirectionForRTL() {
        let layoutDirection = rtlLayoutManager.layoutDirection(for: .rightToLeft)
        XCTAssertEqual(layoutDirection, .rightToLeft, "RTL text should have RTL layout direction")
    }
    
    func testLayoutDirectionForLTR() {
        let layoutDirection = rtlLayoutManager.layoutDirection(for: .leftToRight)
        XCTAssertEqual(layoutDirection, .leftToRight, "LTR text should have LTR layout direction")
    }
    
    func testIconMirroringDecision() {
        let shouldMirrorNavigational = rtlLayoutManager.shouldMirrorIcon(type: .navigational, in: .rightToLeft)
        XCTAssertTrue(shouldMirrorNavigational, "Navigational icons should be mirrored in RTL")
        
        let shouldMirrorContent = rtlLayoutManager.shouldMirrorIcon(type: .content, in: .rightToLeft)
        XCTAssertFalse(shouldMirrorContent, "Content icons should not be mirrored in RTL")
    }
    
    func testPaddingCalculation() {
        let originalPadding = EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 30)
        let rtlPadding = rtlLayoutManager.calculateRTLPadding(originalPadding)
        
        XCTAssertEqual(rtlPadding.top, originalPadding.top)
        XCTAssertEqual(rtlPadding.bottom, originalPadding.bottom)
        XCTAssertEqual(rtlPadding.leading, originalPadding.trailing)
        XCTAssertEqual(rtlPadding.trailing, originalPadding.leading)
    }
    
    // MARK: - Bidirectional Text Handler Tests
    
    func testBiDirectionalTextAnalysis() {
        let mixedText = "Hello مرحبا World עולם"
        let analysis = biDirectionalHandler.analyzeBiDiText(mixedText)
        
        XCTAssertTrue(analysis.isMixed, "Text with multiple scripts should be detected as mixed")
        XCTAssertTrue(analysis.hasRTLContent, "Should detect RTL content")
        XCTAssertTrue(analysis.hasLTRContent, "Should detect LTR content")
        XCTAssertGreaterThan(analysis.segments.count, 1, "Should have multiple segments")
    }
    
    func testCurrencyFormattingRTL() {
        let formattedCurrency = biDirectionalHandler.formatCurrency("100", symbol: "﷼", direction: .rightToLeft)
        XCTAssertTrue(formattedCurrency.contains("100"), "Should contain the amount")
        XCTAssertTrue(formattedCurrency.contains("﷼"), "Should contain the currency symbol")
        // In RTL, symbol typically comes after amount
        let symbolIndex = formattedCurrency.firstIndex(of: "﷼")
        let amountRange = formattedCurrency.range(of: "100")
        XCTAssertNotNil(symbolIndex)
        XCTAssertNotNil(amountRange)
    }
    
    func testCurrencyFormattingLTR() {
        let formattedCurrency = biDirectionalHandler.formatCurrency("100", symbol: "$", direction: .leftToRight)
        XCTAssertTrue(formattedCurrency.contains("100"), "Should contain the amount")
        XCTAssertTrue(formattedCurrency.contains("$"), "Should contain the currency symbol")
        // In LTR, symbol typically comes before amount
        let symbolIndex = formattedCurrency.firstIndex(of: "$")
        let amountRange = formattedCurrency.range(of: "100")
        XCTAssertNotNil(symbolIndex)
        XCTAssertNotNil(amountRange)
    }
    
    func testNumberFormattingInRTL() {
        let number = "1234.56"
        let formattedNumber = biDirectionalHandler.formatNumber(number, in: .rightToLeft)
        
        XCTAssertTrue(formattedNumber.contains(number), "Should contain the original number")
        // Should contain RTL formatting marks
        XCTAssertTrue(formattedNumber.contains("\u{200F}") || formattedNumber.contains("\u{200E}"), 
                     "Should contain directional formatting marks")
    }
    
    func testDirectionalMarksWrapping() {
        let text = "Test Text"
        let wrappedRTL = biDirectionalHandler.wrapWithDirectionalMarks(text, direction: .rightToLeft)
        let wrappedLTR = biDirectionalHandler.wrapWithDirectionalMarks(text, direction: .leftToRight)
        
        XCTAssertNotEqual(wrappedRTL, text, "RTL wrapped text should be different from original")
        XCTAssertNotEqual(wrappedLTR, text, "LTR wrapped text should be different from original")
        XCTAssertNotEqual(wrappedRTL, wrappedLTR, "RTL and LTR wrapped text should be different")
    }
    
    // MARK: - RTL Accessibility Tests
    
    func testAccessibilityLabelCreation() {
        let text = "مرحبا Hello"
        let label = rtlAccessibilityHelper.createAccessibilityLabel(for: text, context: "greeting")
        
        XCTAssertTrue(label.contains("greeting"), "Should contain context")
        XCTAssertTrue(label.contains(text) || label.contains("content"), "Should reference the text or content type")
    }
    
    func testCurrencyAccessibilityFormatting() {
        let accessibilityText = rtlAccessibilityHelper.formatCurrencyForAccessibility(
            amount: "100",
            currency: "USD",
            direction: .rightToLeft
        )
        
        XCTAssertTrue(accessibilityText.contains("100"), "Should contain amount")
        XCTAssertFalse(accessibilityText.isEmpty, "Should not be empty")
    }
    
    func testNavigationHintCreation() {
        let hint = rtlAccessibilityHelper.createNavigationHint(action: "next", direction: .rightToLeft)
        XCTAssertFalse(hint.isEmpty, "Navigation hint should not be empty")
    }
    
    func testAccessibilityTraitsForRTL() {
        let traits = rtlAccessibilityHelper.accessibilityTraits(for: "button", isRTL: true)
        XCTAssertTrue(traits.contains(.isButton), "Should include button trait")
    }
    
    func testReadingOrderConfiguration() {
        let elements = ["first", "second", "third"]
        let reorderedElements = rtlAccessibilityHelper.configureReadingOrder(for: elements, direction: .rightToLeft)
        
        XCTAssertEqual(reorderedElements.count, elements.count, "Should have same number of elements")
        XCTAssertFalse(reorderedElements.isEmpty, "Should not be empty")
    }
    
    func testVoiceOverGestureMapping() {
        let mappedGesture = rtlAccessibilityHelper.getVoiceOverGestureMapping(for: "swipeRight", isRTL: true)
        XCTAssertNotEqual(mappedGesture, "swipeRight", "RTL should map right swipe to different gesture")
        
        let unmappedGesture = rtlAccessibilityHelper.getVoiceOverGestureMapping(for: "swipeRight", isRTL: false)
        XCTAssertEqual(unmappedGesture, "swipeRight", "LTR should not change gesture mapping")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteRTLWorkflow() {
        // Test complete workflow from detection to formatting
        let arabicText = "مرحبا بالعالم"
        
        // 1. Detect direction
        let detectedDirection = textDirectionDetector.detectDirection(for: arabicText)
        XCTAssertEqual(detectedDirection, .rightToLeft)
        
        // 2. Create layout
        let layoutDirection = rtlLayoutManager.layoutDirection(for: detectedDirection)
        XCTAssertEqual(layoutDirection, .rightToLeft)
        
        // 3. Analyze bidirectional content
        let analysis = biDirectionalHandler.analyzeBiDiText(arabicText)
        XCTAssertFalse(analysis.isMixed)
        XCTAssertTrue(analysis.hasRTLContent)
        
        // 4. Create accessibility label
        let accessibilityLabel = rtlAccessibilityHelper.createAccessibilityLabel(for: arabicText)
        XCTAssertFalse(accessibilityLabel.isEmpty)
    }
    
    func testMixedContentWorkflow() {
        // Test workflow with mixed RTL/LTR content
        let mixedText = "Hello مرحبا World"
        
        let detectedDirection = textDirectionDetector.detectDirection(for: mixedText)
        let analysis = biDirectionalHandler.analyzeBiDiText(mixedText)
        
        XCTAssertTrue(analysis.isMixed, "Should detect mixed content")
        XCTAssertGreaterThan(analysis.segments.count, 1, "Should have multiple segments")
        
        let attributedString = biDirectionalHandler.createAttributedString(from: mixedText)
        XCTAssertGreaterThan(attributedString.length, 0, "Should create non-empty attributed string")
    }
    
    // MARK: - Performance Tests
    
    func testTextDirectionDetectionPerformance() {
        let longText = String(repeating: "Hello مرحبا World שלום ", count: 1000)
        
        measure {
            _ = textDirectionDetector.detectDirection(for: longText)
        }
    }
    
    func testBiDirectionalAnalysisPerformance() {
        let complexText = String(repeating: "English العربية עברית 123 ", count: 500)
        
        measure {
            _ = biDirectionalHandler.analyzeBiDiText(complexText)
        }
    }
    
    // MARK: - Edge Cases
    
    func testEdgeCases() {
        // Test with only numbers
        let numbersOnly = "123456789"
        let numberDirection = textDirectionDetector.detectDirection(for: numbersOnly)
        XCTAssertEqual(numberDirection, .leftToRight)
        
        // Test with only punctuation
        let punctuationOnly = "!@#$%^&*()"
        let punctuationDirection = textDirectionDetector.detectDirection(for: punctuationOnly)
        XCTAssertEqual(punctuationDirection, .leftToRight)
        
        // Test with whitespace only
        let whitespaceOnly = "   \n\t  "
        let whitespaceDirection = textDirectionDetector.detectDirection(for: whitespaceOnly)
        XCTAssertEqual(whitespaceDirection, .leftToRight)
        
        // Test very long single word
        let longWord = String(repeating: "مرحبا", count: 100)
        let longWordDirection = textDirectionDetector.detectDirection(for: longWord)
        XCTAssertEqual(longWordDirection, .rightToLeft)
    }
}

// MARK: - Test Extensions

extension RTLSupportTests {
    
    func createTestLocale(languageCode: String) -> Locale {
        return Locale(identifier: languageCode)
    }
    
    func assertDirectionalMarksPresent(in text: String) {
        let rtlMark = "\u{200F}"
        let ltrMark = "\u{200E}"
        let rtlOverride = "\u{202E}"
        let ltrOverride = "\u{202D}"
        let popDirectional = "\u{202C}"
        
        let hasDirectionalMarks = text.contains(rtlMark) || 
                                 text.contains(ltrMark) || 
                                 text.contains(rtlOverride) || 
                                 text.contains(ltrOverride) || 
                                 text.contains(popDirectional)
        
        XCTAssertTrue(hasDirectionalMarks, "Text should contain directional formatting marks")
    }
}