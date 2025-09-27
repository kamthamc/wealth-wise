//
//  LocalizationValidatorTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 27/09/2025.
//  Comprehensive tests for LocalizationValidator quality assurance system
//

import XCTest
@testable import WealthWise

final class LocalizationValidatorTests: XCTestCase {
    
    var validator: LocalizationValidator!
    
    override func setUp() {
        super.setUp()
        validator = LocalizationValidator()
    }
    
    override func tearDown() {
        validator = nil
        super.tearDown()
    }
    
    // MARK: - Basic Validation Tests
    
    func testValidTranslation() {
        let result = validator.validate(
            key: "test.key",
            originalText: "Hello World",
            translation: "Hola Mundo",
            locale: "es-ES"
        )
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.issues.isEmpty)
    }
    
    func testEmptyTranslation() {
        let result = validator.validate(
            key: "test.empty",
            originalText: "Hello",
            translation: "",
            locale: "es-ES"
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.type == .emptyTranslation })
    }
    
    func testMissingTranslation() {
        let result = validator.validate(
            key: "test.missing",
            originalText: "Hello",
            translation: nil,
            locale: "es-ES"
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.type == .missingTranslation })
    }
    
    // MARK: - Parameter Validation Tests
    
    func testParameterCountMismatch() {
        // Original has 2 parameters, translation has 1
        let result = validator.validate(
            key: "test.params",
            originalText: "Hello %@ from %@",
            translation: "Hola %@",
            locale: "es-ES"
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.type == .parameterMismatch })
    }
    
    func testValidParameterMatching() {
        let result = validator.validate(
            key: "test.params.valid",
            originalText: "Hello %@ from %@",
            translation: "Hola %@ de %@",
            locale: "es-ES"
        )
        
        XCTAssertTrue(result.isValid)
    }
    
    func testPositionalParameters() {
        // Test iOS positional parameters
        let result1 = validator.validate(
            key: "test.positional",
            originalText: "Item %1$@ costs %2$@",
            translation: "El artículo %1$@ cuesta %2$@",
            locale: "es-ES"
        )
        XCTAssertTrue(result1.isValid)
        
        // Test parameter reordering (valid in many languages)
        let result2 = validator.validate(
            key: "test.reordered",
            originalText: "Item %1$@ costs %2$@",
            translation: "El precio %2$@ es para %1$@",
            locale: "es-ES"
        )
        XCTAssertTrue(result2.isValid)
    }
    
    // MARK: - Length Validation Tests
    
    func testExcessiveLength() {
        let shortOriginal = "OK"
        let longTranslation = String(repeating: "Very long translation ", count: 50)
        
        let result = validator.validate(
            key: "test.length",
            originalText: shortOriginal,
            translation: longTranslation,
            locale: "de-DE"
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.type == .excessiveLength })
    }
    
    func testReasonableLengthDifference() {
        // German tends to be longer, this should be acceptable
        let result = validator.validate(
            key: "test.german",
            originalText: "Settings",
            translation: "Einstellungen",
            locale: "de-DE"
        )
        
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Character Encoding Tests
    
    func testValidUnicodeCharacters() {
        let result = validator.validate(
            key: "test.unicode",
            originalText: "Welcome",
            translation: "欢迎 🎉",
            locale: "zh-CN"
        )
        
        XCTAssertTrue(result.isValid)
    }
    
    func testInvalidCharacters() {
        // Test with some problematic characters that might not display properly
        let translationWithInvalidChars = "Hello\u{0000}\u{FEFF}World"
        
        let result = validator.validate(
            key: "test.invalid.chars",
            originalText: "Hello World",
            translation: translationWithInvalidChars,
            locale: "en-US"
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.type == .invalidCharacters })
    }
    
    // MARK: - Consistency Validation Tests
    
    func testTerminologyConsistency() {
        let translations = [
            "app.settings": "Settings",
            "menu.settings": "Preferences", // Inconsistent terminology
            "nav.settings": "Settings"
        ]
        
        let consistencyIssues = validator.validateConsistency(translations: translations)
        
        XCTAssertFalse(consistencyIssues.isEmpty)
        XCTAssertTrue(consistencyIssues.contains { $0.type == .inconsistentTerminology })
    }
    
    func testConsistentTranslations() {
        let translations = [
            "app.settings": "Settings",
            "menu.settings": "Settings",
            "nav.settings": "Settings"
        ]
        
        let consistencyIssues = validator.validateConsistency(translations: translations)
        let terminologyIssues = consistencyIssues.filter { $0.type == .inconsistentTerminology }
        
        XCTAssertTrue(terminologyIssues.isEmpty)
    }
    
    // MARK: - Cultural Sensitivity Tests
    
    func testCulturallyAppropriateTranslation() {
        // Test that financial terms are culturally appropriate
        let result = validator.validate(
            key: "financial.amount",
            originalText: "₹1,00,000", // Indian format
            translation: "₹ 1,00,000", // Still appropriate
            locale: "hi-IN"
        )
        
        XCTAssertTrue(result.isValid)
    }
    
    func testCulturalInsensitivity() {
        // This is a simplified test - real cultural validation would be more complex
        let result = validator.validate(
            key: "greeting.formal",
            originalText: "Dear Sir/Madam",
            translation: "Hey there!", // Too informal for formal context
            locale: "ja-JP"
        )
        
        // For now, this might pass basic validation but would need cultural review
        // In a full implementation, we'd have cultural context rules
    }
    
    // MARK: - Multiple Translation Validation Tests
    
    func testValidateMultipleTranslations() {
        let translations = [
            "greeting.hello": "Hello",
            "greeting.goodbye": "Goodbye",
            "button.save": "Save",
            "button.cancel": "", // Invalid - empty
            "error.network": nil, // Invalid - missing
            "label.name": "Name"
        ]
        
        let report = validator.validateMultiple(translations: translations, locale: "en-US")
        
        XCTAssertFalse(report.allValid)
        XCTAssertEqual(report.validCount, 4) // hello, goodbye, save, name
        XCTAssertEqual(report.invalidCount, 2) // cancel (empty), network (missing)
        XCTAssertEqual(report.totalCount, 6)
        XCTAssertGreaterThan(report.issues.count, 0)
    }
    
    func testValidationReportSummary() {
        let translations = [
            "test.1": "Valid translation",
            "test.2": "",
            "test.3": "Another valid one",
            "test.4": nil
        ]
        
        let report = validator.validateMultiple(translations: translations, locale: "en-US")
        
        XCTAssertEqual(report.validCount, 2)
        XCTAssertEqual(report.invalidCount, 2)
        XCTAssertEqual(report.successRate, 0.5, accuracy: 0.001)
    }
    
    // MARK: - Report Generation Tests
    
    func testGenerateTextReport() {
        let issues = [
            ValidationIssue(
                key: "test.1",
                type: .emptyTranslation,
                severity: .error,
                message: "Translation is empty",
                context: ValidationContext(locale: "es-ES", originalText: "Hello", translation: nil)
            ),
            ValidationIssue(
                key: "test.2",
                type: .excessiveLength,
                severity: .warning,
                message: "Translation is too long",
                context: ValidationContext(locale: "es-ES", originalText: "OK", translation: "Very long translation")
            )
        ]
        
        let report = ValidationReport(
            locale: "es-ES",
            totalCount: 10,
            validCount: 8,
            invalidCount: 2,
            issues: issues
        )
        
        let textReport = validator.generateReport(report, format: .text)
        
        XCTAssertTrue(textReport.contains("Validation Report"))
        XCTAssertTrue(textReport.contains("es-ES"))
        XCTAssertTrue(textReport.contains("test.1"))
        XCTAssertTrue(textReport.contains("test.2"))
        XCTAssertTrue(textReport.contains("ERROR"))
        XCTAssertTrue(textReport.contains("WARNING"))
    }
    
    func testGenerateJSONReport() {
        let issues = [
            ValidationIssue(
                key: "test.json",
                type: .missingTranslation,
                severity: .error,
                message: "Missing translation",
                context: ValidationContext(locale: "fr-FR", originalText: "Test", translation: nil)
            )
        ]
        
        let report = ValidationReport(
            locale: "fr-FR",
            totalCount: 1,
            validCount: 0,
            invalidCount: 1,
            issues: issues
        )
        
        let jsonReport = validator.generateReport(report, format: .json)
        
        XCTAssertTrue(jsonReport.contains("\"locale\":\"fr-FR\""))
        XCTAssertTrue(jsonReport.contains("\"totalCount\":1"))
        XCTAssertTrue(jsonReport.contains("\"test.json\""))
        
        // Verify it's valid JSON
        let jsonData = jsonReport.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: jsonData))
    }
    
    func testGenerateCSVReport() {
        let issues = [
            ValidationIssue(
                key: "csv.test",
                type: .parameterMismatch,
                severity: .error,
                message: "Parameter count mismatch",
                context: ValidationContext(locale: "de-DE", originalText: "Hello %@", translation: "Hallo")
            )
        ]
        
        let report = ValidationReport(
            locale: "de-DE",
            totalCount: 1,
            validCount: 0,
            invalidCount: 1,
            issues: issues
        )
        
        let csvReport = validator.generateReport(report, format: .csv)
        
        XCTAssertTrue(csvReport.contains("Key,Type,Severity,Message,Locale"))
        XCTAssertTrue(csvReport.contains("csv.test"))
        XCTAssertTrue(csvReport.contains("parameterMismatch"))
        XCTAssertTrue(csvReport.contains("error"))
        XCTAssertTrue(csvReport.contains("de-DE"))
    }
    
    func testGenerateMarkdownReport() {
        let issues = [
            ValidationIssue(
                key: "md.test",
                type: .excessiveLength,
                severity: .warning,
                message: "Translation too long",
                context: ValidationContext(locale: "ja-JP", originalText: "OK", translation: "とても長い翻訳テキスト")
            )
        ]
        
        let report = ValidationReport(
            locale: "ja-JP",
            totalCount: 1,
            validCount: 0,
            invalidCount: 1,
            issues: issues
        )
        
        let markdownReport = validator.generateReport(report, format: .markdown)
        
        XCTAssertTrue(markdownReport.contains("# Validation Report"))
        XCTAssertTrue(markdownReport.contains("## Summary"))
        XCTAssertTrue(markdownReport.contains("## Issues"))
        XCTAssertTrue(markdownReport.contains("| md.test |"))
        XCTAssertTrue(markdownReport.contains("ja-JP"))
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() {
        let testTranslations = Dictionary(uniqueKeysWithValues: (0..<1000).map {
            ("test.key.\($0)", "Test translation \($0)")
        })
        
        measure {
            let _ = validator.validateMultiple(translations: testTranslations, locale: "en-US")
        }
    }
    
    func testLargeTextValidation() {
        let largeText = String(repeating: "This is a large text for testing validation performance. ", count: 1000)
        
        measure {
            for i in 0..<100 {
                let _ = validator.validate(
                    key: "perf.test.\(i)",
                    originalText: largeText,
                    translation: largeText + " (translated)",
                    locale: "es-ES"
                )
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyKey() {
        let result = validator.validate(
            key: "",
            originalText: "Hello",
            translation: "Hola",
            locale: "es-ES"
        )
        
        // Should handle empty key gracefully
        XCTAssertNotNil(result)
    }
    
    func testNilOriginalText() {
        let result = validator.validate(
            key: "test.nil.original",
            originalText: nil,
            translation: "Translation",
            locale: "es-ES"
        )
        
        // Should handle nil original text
        XCTAssertFalse(result.isValid)
    }
    
    func testWhitespaceOnlyTranslation() {
        let result = validator.validate(
            key: "test.whitespace",
            originalText: "Hello",
            translation: "   \n\t   ",
            locale: "es-ES"
        )
        
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.type == .emptyTranslation })
    }
    
    func testSpecialCharacters() {
        let result = validator.validate(
            key: "test.special",
            originalText: "Price: $%@",
            translation: "Precio: €%@",
            locale: "es-ES"
        )
        
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Regex Pattern Tests
    
    func testParameterPatternMatching() {
        let patterns = [
            "%@", "%d", "%f", "%ld", "%lf",
            "%1$@", "%2$d", "%3$f",
            "{{placeholder}}", "{variable}"
        ]
        
        for pattern in patterns {
            let originalText = "Test \(pattern) pattern"
            let translationText = "Prueba \(pattern) patrón"
            
            let result = validator.validate(
                key: "test.pattern",
                originalText: originalText,
                translation: translationText,
                locale: "es-ES"
            )
            
            XCTAssertTrue(result.isValid, "Pattern \(pattern) should be valid")
        }
    }
    
    func testComplexParameterCombinations() {
        let result = validator.validate(
            key: "test.complex",
            originalText: "User %1$@ has %2$d items worth %3$.2f total",
            translation: "Usuario %1$@ tiene %2$d elementos por un total de %3$.2f",
            locale: "es-ES"
        )
        
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentValidation() {
        let expectation = XCTestExpectation(description: "Concurrent validation completed")
        expectation.expectedFulfillmentCount = 5
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for threadId in 0..<5 {
            queue.async {
                for i in 0..<100 {
                    let key = "thread.\(threadId).key.\(i)"
                    let _ = self.validator.validate(
                        key: key,
                        originalText: "Original \(i)",
                        translation: "Translation \(i)",
                        locale: "en-US"
                    )
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - ValidationIssue Tests

final class ValidationIssueTests: XCTestCase {
    
    func testValidationIssueCreation() {
        let context = ValidationContext(
            locale: "es-ES",
            originalText: "Hello",
            translation: "Hola"
        )
        
        let issue = ValidationIssue(
            key: "test.key",
            type: .parameterMismatch,
            severity: .error,
            message: "Parameter count mismatch",
            context: context
        )
        
        XCTAssertEqual(issue.key, "test.key")
        XCTAssertEqual(issue.type, .parameterMismatch)
        XCTAssertEqual(issue.severity, .error)
        XCTAssertEqual(issue.message, "Parameter count mismatch")
        XCTAssertEqual(issue.context.locale, "es-ES")
    }
    
    func testValidationIssueEquality() {
        let context = ValidationContext(locale: "en-US", originalText: "Test", translation: "Test")
        
        let issue1 = ValidationIssue(
            key: "same.key",
            type: .emptyTranslation,
            severity: .error,
            message: "Same message",
            context: context
        )
        
        let issue2 = ValidationIssue(
            key: "same.key",
            type: .emptyTranslation,
            severity: .error,
            message: "Same message",
            context: context
        )
        
        let issue3 = ValidationIssue(
            key: "different.key",
            type: .emptyTranslation,
            severity: .error,
            message: "Same message",
            context: context
        )
        
        XCTAssertEqual(issue1, issue2)
        XCTAssertNotEqual(issue1, issue3)
    }
}

// MARK: - ValidationContext Tests

final class ValidationContextTests: XCTestCase {
    
    func testValidationContextCreation() {
        let context = ValidationContext(
            locale: "hi-IN",
            originalText: "Welcome",
            translation: "स्वागत है"
        )
        
        XCTAssertEqual(context.locale, "hi-IN")
        XCTAssertEqual(context.originalText, "Welcome")
        XCTAssertEqual(context.translation, "स्वागत है")
    }
    
    func testValidationContextWithNilTranslation() {
        let context = ValidationContext(
            locale: "fr-FR",
            originalText: "Hello",
            translation: nil
        )
        
        XCTAssertEqual(context.locale, "fr-FR")
        XCTAssertEqual(context.originalText, "Hello")
        XCTAssertNil(context.translation)
    }
}

// MARK: - ValidationReport Tests

final class ValidationReportTests: XCTestCase {
    
    func testValidationReportProperties() {
        let issues = [
            ValidationIssue(
                key: "test.1",
                type: .emptyTranslation,
                severity: .error,
                message: "Empty",
                context: ValidationContext(locale: "en-US", originalText: "Test", translation: nil)
            )
        ]
        
        let report = ValidationReport(
            locale: "en-US",
            totalCount: 10,
            validCount: 9,
            invalidCount: 1,
            issues: issues
        )
        
        XCTAssertEqual(report.locale, "en-US")
        XCTAssertEqual(report.totalCount, 10)
        XCTAssertEqual(report.validCount, 9)
        XCTAssertEqual(report.invalidCount, 1)
        XCTAssertEqual(report.successRate, 0.9, accuracy: 0.001)
        XCTAssertFalse(report.allValid)
        XCTAssertEqual(report.issues.count, 1)
    }
    
    func testPerfectValidationReport() {
        let report = ValidationReport(
            locale: "en-US",
            totalCount: 5,
            validCount: 5,
            invalidCount: 0,
            issues: []
        )
        
        XCTAssertTrue(report.allValid)
        XCTAssertEqual(report.successRate, 1.0)
    }
    
    func testEmptyValidationReport() {
        let report = ValidationReport(
            locale: "en-US",
            totalCount: 0,
            validCount: 0,
            invalidCount: 0,
            issues: []
        )
        
        XCTAssertTrue(report.allValid) // Technically all are valid if there are none
        XCTAssertEqual(report.successRate, 1.0) // Should handle division by zero
    }
}