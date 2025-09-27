//
//  StringCatalogManagerTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 27/09/2025.
//  Comprehensive tests for StringCatalogManager functionality
//

import XCTest
@testable import WealthWise

@MainActor
final class StringCatalogManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var stringCatalogManager: StringCatalogManager!
    private var mockTranslationCache: MockTranslationCache!
    private var mockLocalizationValidator: MockLocalizationValidator!
    
    // MARK: - Test Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockTranslationCache = MockTranslationCache()
        mockLocalizationValidator = MockLocalizationValidator()
        
        stringCatalogManager = StringCatalogManager(
            translationCache: mockTranslationCache,
            localizationValidator: mockLocalizationValidator
        )
    }
    
    override func tearDown() async throws {
        stringCatalogManager = nil
        mockTranslationCache = nil
        mockLocalizationValidator = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(stringCatalogManager)
        XCTAssertEqual(stringCatalogManager.currentLocale, Locale.current)
        XCTAssertFalse(stringCatalogManager.availableLocales.isEmpty)
        XCTAssertFalse(stringCatalogManager.isLoading)
    }
    
    func testSupportedLocales() {
        let expectedLocales = ["en", "hi", "ar", "ta", "te", "bn", "mr", "gu", "kn", "ms"]
        let actualIdentifiers = stringCatalogManager.availableLocales.map { $0.languageCode ?? $0.identifier }
        
        for expectedLocale in expectedLocales {
            XCTAssertTrue(
                actualIdentifiers.contains(expectedLocale),
                "Expected locale \(expectedLocale) not found in available locales"
            )
        }
    }
    
    // MARK: - String Retrieval Tests
    
    func testLocalizedStringRetrieval() {
        // Test basic string retrieval
        let localizedString = stringCatalogManager.localizedString(for: .generalLoading)
        XCTAssertFalse(localizedString.isEmpty)
        XCTAssertNotEqual(localizedString, LocalizationKey.generalLoading.rawValue)
    }
    
    func testLocalizedStringWithArguments() {
        // Test string with format arguments
        let amount = 1000.0
        let formattedString = stringCatalogManager.localizedString(
            for: .finAmount,
            arguments: amount
        )
        
        XCTAssertFalse(formattedString.isEmpty)
        // Note: Actual formatting would depend on the string catalog content
    }
    
    func testLocalizedStringCaching() {
        let key = LocalizationKey.generalError
        
        // First call should be cache miss
        let firstCall = stringCatalogManager.localizedString(for: key)
        XCTAssertTrue(mockTranslationCache.cacheStringCalled)
        
        // Reset mock
        mockTranslationCache.reset()
        mockTranslationCache.shouldReturnCachedString = true
        mockTranslationCache.cachedStringToReturn = firstCall
        
        // Second call should be cache hit
        let secondCall = stringCatalogManager.localizedString(for: key)
        XCTAssertTrue(mockTranslationCache.cachedStringCalled)
        XCTAssertEqual(firstCall, secondCall)
    }
    
    func testLocalizedStringWithContext() {
        let key = LocalizationKey.finAmount
        
        // Test different contexts
        let standardString = stringCatalogManager.localizedString(
            for: key,
            context: .standard
        )
        
        let accessibilityString = stringCatalogManager.localizedString(
            for: key,
            context: .accessibility
        )
        
        let financialString = stringCatalogManager.localizedString(
            for: key,
            context: .financial
        )
        
        XCTAssertFalse(standardString.isEmpty)
        XCTAssertFalse(accessibilityString.isEmpty)
        XCTAssertFalse(financialString.isEmpty)
        
        // Accessibility context should potentially have additional context
        // This would depend on implementation details
    }
    
    func testLocalizedStringWithAudience() {
        let key = LocalizationKey.numberMillion
        
        // Test cultural adaptation
        let indianString = stringCatalogManager.localizedString(
            for: key,
            context: .cultural,
            audience: .indian
        )
        
        let americanString = stringCatalogManager.localizedString(
            for: key,
            context: .cultural,
            audience: .american
        )
        
        XCTAssertFalse(indianString.isEmpty)
        XCTAssertFalse(americanString.isEmpty)
        
        // For Indian audience, million might be adapted to lakh/crore
        // This depends on the cultural adaptation implementation
    }
    
    // MARK: - Locale Management Tests
    
    func testLocaleChange() {
        let newLocale = Locale(identifier: "hi")
        let changeResult = stringCatalogManager.changeLocale(to: newLocale)
        
        XCTAssertTrue(changeResult)
        XCTAssertEqual(stringCatalogManager.currentLocale, newLocale)
        XCTAssertTrue(mockTranslationCache.clearCacheCalled)
    }
    
    func testInvalidLocaleChange() {
        let unsupportedLocale = Locale(identifier: "xyz")
        let changeResult = stringCatalogManager.changeLocale(to: unsupportedLocale)
        
        XCTAssertFalse(changeResult)
        XCTAssertNotEqual(stringCatalogManager.currentLocale, unsupportedLocale)
    }
    
    func testLocaleChangeNotification() {
        let expectation = expectation(forNotification: .localeDidChange, object: stringCatalogManager)
        
        let newLocale = Locale(identifier: "ta")
        _ = stringCatalogManager.changeLocale(to: newLocale)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Validation Tests
    
    func testStringValidation() async {
        let locale = Locale(identifier: "en")
        var mockStats = ValidationStatistics()
        mockStats.locale = locale.identifier
        mockStats.totalKeys = 100
        mockStats.validKeys = 90
        mockStats.overallScore = 90.0
        
        mockLocalizationValidator.mockValidationResult = LocalizationValidationResult(
            locale: locale.identifier,
            issues: [],
            statistics: mockStats
        )
        
        let result = await stringCatalogManager.validateStrings(for: locale)
        
        XCTAssertTrue(mockLocalizationValidator.validateAllStringsCalled)
        XCTAssertEqual(result.statistics.totalKeys, 100)
        XCTAssertEqual(result.statistics.validKeys, 90)
        XCTAssertEqual(result.statistics.overallScore, 90.0, accuracy: 0.01)
    }
    
    func testMissingTranslations() {
        let locale = Locale(identifier: "hi")
        let missingKeys = stringCatalogManager.getMissingTranslations(for: locale)
        
        // The actual missing keys would depend on what's in the bundle
        // This test verifies the method runs without crashing
        XCTAssertNotNil(missingKeys)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMetrics() {
        // Generate some activity
        for _ in 0..<10 {
            _ = stringCatalogManager.localizedString(for: .generalLoading)
        }
        
        let metrics = stringCatalogManager.getPerformanceMetrics()
        
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThanOrEqual(metrics.cacheHitRate, 0.0)
        XCTAssertLessThanOrEqual(metrics.cacheHitRate, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.totalCacheHits, 0)
        XCTAssertGreaterThanOrEqual(metrics.totalCacheMisses, 0)
    }
    
    func testCacheRefresh() async {
        await stringCatalogManager.refreshCache()
        
        XCTAssertTrue(mockTranslationCache.clearCacheCalled)
        XCTAssertNotNil(stringCatalogManager.lastCacheRefresh)
    }
    
    // MARK: - Data Export Tests
    
    func testLocalizationDataExport() {
        let locale = Locale(identifier: "en")
        let exportData = stringCatalogManager.exportLocalizationData(for: locale)
        
        XCTAssertNotNil(exportData["locale"])
        XCTAssertNotNil(exportData["language"])
        XCTAssertNotNil(exportData["export_date"])
        XCTAssertNotNil(exportData["strings"])
        XCTAssertNotNil(exportData["metadata"])
        
        if let strings = exportData["strings"] as? [String: Any] {
            XCTAssertFalse(strings.isEmpty)
        }
        
        if let metadata = exportData["metadata"] as? [String: Any] {
            XCTAssertNotNil(metadata["total_keys"])
            XCTAssertNotNil(metadata["categories"])
            XCTAssertNotNil(metadata["performance_metrics"])
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testStringRetrievalWithNilArguments() {
        // Test that nil arguments don't crash the system
        let result = stringCatalogManager.localizedString(for: .generalError)
        XCTAssertFalse(result.isEmpty)
    }
    
    func testStringRetrievalWithMismatchedArguments() {
        // Test that mismatched format arguments are handled gracefully
        let result = stringCatalogManager.localizedString(
            for: .generalError,
            arguments: "unexpected", 123, 45.67
        )
        XCTAssertFalse(result.isEmpty)
        // The result might contain formatting errors, but shouldn't crash
    }
    
    // MARK: - Cultural Adaptation Tests
    
    func testIndianNumberingSystem() {
        // Test adaptation for Indian audience
        let millionKey = LocalizationKey.numberMillion
        let billionKey = LocalizationKey.numberBillion
        
        // These should adapt to lakh/crore for Indian audience
        let adaptedMillion = stringCatalogManager.localizedString(
            for: millionKey,
            context: .cultural,
            audience: .indian
        )
        
        let adaptedBillion = stringCatalogManager.localizedString(
            for: billionKey,
            context: .cultural,
            audience: .indian
        )
        
        XCTAssertFalse(adaptedMillion.isEmpty)
        XCTAssertFalse(adaptedBillion.isEmpty)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentStringRetrieval() async {
        let expectation = expectation(description: "Concurrent string retrieval")
        expectation.expectedFulfillmentCount = 10
        
        // Launch multiple concurrent tasks
        for i in 0..<10 {
            Task {
                let key = LocalizationKey.allCases[i % LocalizationKey.allCases.count]
                let result = stringCatalogManager.localizedString(for: key)
                XCTAssertFalse(result.isEmpty)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock Classes

class MockTranslationCache: TranslationCacheProtocol {
    var cachedStringCalled = false
    var cacheStringCalled = false
    var clearCacheCalled = false
    var shouldReturnCachedString = false
    var cachedStringToReturn: String?
    
    // MARK: - TranslationCacheProtocol
    
    var count: Int = 0
    var totalHits: Int = 0
    var totalMisses: Int = 0
    var hitRate: Double = 0.0
    var estimatedMemoryUsage: Int = 0
    
    func get(key: String, locale: String) -> String? {
        cachedStringCalled = true
        return shouldReturnCachedString ? cachedStringToReturn : nil
    }
    
    func set(key: String, locale: String, translation: String) {
        cacheStringCalled = true
        count += 1
    }
    
    func clear() {
        clearCacheCalled = true
        count = 0
    }
    
    func cacheKey(for key: String, locale: String) -> String {
        return "\(key)_\(locale)"
    }
    
    func performMaintenance() {
        // Mock maintenance
    }
    
    func reset() {
        cachedStringCalled = false
        cacheStringCalled = false
        clearCacheCalled = false
        shouldReturnCachedString = false
        cachedStringToReturn = nil
        count = 0
        totalHits = 0
        totalMisses = 0
        hitRate = 0.0
        estimatedMemoryUsage = 0
    }
}

class MockLocalizationValidator: LocalizationValidatorProtocol {
    var validateAllStringsCalled = false
    var mockValidationResult: LocalizationValidationResult?
    
    func validate(translations: [String: String], for locale: String) -> LocalizationValidationResult {
        validateAllStringsCalled = true
        
        return mockValidationResult ?? LocalizationValidationResult(
            locale: locale,
            issues: [],
            statistics: ValidationStatistics()
        )
    }
    
    func generateTextReport(from result: LocalizationValidationResult) -> String {
        return "Mock text report"
    }
    
    func generateJSONReport(from result: LocalizationValidationResult) -> String {
        return "{\"mock\": \"json\"}"
    }
    
    func generateCSVReport(from result: LocalizationValidationResult) -> String {
        return "key,value\nmock,csv"
    }
    
    func generateMarkdownReport(from result: LocalizationValidationResult) -> String {
        return "# Mock Markdown Report"
    }
}