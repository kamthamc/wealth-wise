//
//  LocalizationKeyTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 27/09/2025.
//  Comprehensive tests for LocalizationKey enum and categorization
//

import XCTest
@testable import WealthWise

final class LocalizationKeyTests: XCTestCase {
    
    // MARK: - Basic Functionality Tests
    
    func testLocalizationKeyCount() {
        // Verify we have a substantial number of localization keys
        XCTAssertGreaterThan(LocalizationKey.allCases.count, 100)
        print("Total localization keys: \(LocalizationKey.allCases.count)")
    }
    
    func testRawValueUniqueness() {
        let rawValues = LocalizationKey.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        
        XCTAssertEqual(rawValues.count, uniqueValues.count, "All localization keys must have unique raw values")
    }
    
    func testLocalizedStringProperty() {
        // Test that localizedString property works
        let key = LocalizationKey.generalLoading
        let localizedString = key.localizedString
        
        XCTAssertFalse(localizedString.isEmpty)
        XCTAssertNotEqual(localizedString, key.rawValue) // Should be different from raw value if localized
    }
    
    func testLocalizedStringWithArguments() {
        let key = LocalizationKey.finAmount
        let result = key.localizedString(with: 1000.0, "USD")
        
        XCTAssertFalse(result.isEmpty)
        // The actual format would depend on the string catalog content
    }
    
    // MARK: - Category Tests
    
    func testCategoryProperty() {
        // Test specific key categorizations
        XCTAssertEqual(LocalizationKey.assetTypeStocks.category, .assets)
        XCTAssertEqual(LocalizationKey.currencyINR.category, .currencies)
        XCTAssertEqual(LocalizationKey.countryIndia.category, .countries)
        XCTAssertEqual(LocalizationKey.generalLoading.category, .general)
        XCTAssertEqual(LocalizationKey.navDashboard.category, .navigation)
        XCTAssertEqual(LocalizationKey.finAmount.category, .financial)
        XCTAssertEqual(LocalizationKey.goalTitle.category, .goals)
        XCTAssertEqual(LocalizationKey.errorNetwork.category, .errors)
        XCTAssertEqual(LocalizationKey.accessibilityButton.category, .accessibility)
        XCTAssertEqual(LocalizationKey.dateToday.category, .dateTime)
        XCTAssertEqual(LocalizationKey.numberLakh.category, .numbers)
        XCTAssertEqual(LocalizationKey.culturalIndian.category, .cultural)
        XCTAssertEqual(LocalizationKey.stateEmpty.category, .states)
    }
    
    func testAllKeysHaveValidCategories() {
        for key in LocalizationKey.allCases {
            let category = key.category
            XCTAssertTrue(LocalizationCategory.allCases.contains(category),
                         "Key \(key.rawValue) has invalid category: \(category)")
        }
    }
    
    func testCategoryDistribution() {
        let categoryDistribution = Dictionary(grouping: LocalizationKey.allCases) { $0.category }
        
        // Verify all categories have at least one key
        for category in LocalizationCategory.allCases {
            let keyCount = categoryDistribution[category]?.count ?? 0
            XCTAssertGreaterThan(keyCount, 0, "Category \(category) should have at least one key")
        }
        
        // Print distribution for analysis
        for category in LocalizationCategory.allCases {
            let count = categoryDistribution[category]?.count ?? 0
            print("Category \(category.rawValue): \(count) keys")
        }
    }
    
    // MARK: - Comment Tests
    
    func testCommentProperty() {
        let key = LocalizationKey.assetTypeStocks
        let comment = key.comment
        
        XCTAssertFalse(comment.isEmpty)
        XCTAssertNotEqual(comment, key.rawValue)
        XCTAssertTrue(comment.contains("Stock") || comment.contains("stock"))
    }
    
    func testAllKeysHaveComments() {
        for key in LocalizationKey.allCases {
            let comment = key.comment
            XCTAssertFalse(comment.isEmpty, "Key \(key.rawValue) should have a comment")
        }
    }
    
    func testCommentsAreDescriptive() {
        // Test that comments are reasonably descriptive (more than just the key)
        for key in LocalizationKey.allCases {
            let comment = key.comment
            XCTAssertGreaterThan(comment.count, 10, "Comment for \(key.rawValue) should be descriptive")
        }
    }
    
    // MARK: - Asset Type Key Tests
    
    func testAssetTypeKeys() {
        let assetKeys = LocalizationKey.allCases.filter { $0.category == .assets }
        
        XCTAssertGreaterThan(assetKeys.count, 15) // Should have substantial asset types
        
        // Test specific asset types are present
        XCTAssertTrue(assetKeys.contains(.assetTypeStocks))
        XCTAssertTrue(assetKeys.contains(.assetTypeBonds))
        XCTAssertTrue(assetKeys.contains(.assetTypeMutualFunds))
        XCTAssertTrue(assetKeys.contains(.assetTypeRealEstate))
        XCTAssertTrue(assetKeys.contains(.assetTypePPF))
        XCTAssertTrue(assetKeys.contains(.assetTypeEPF))
    }
    
    // MARK: - Currency Key Tests
    
    func testCurrencyKeys() {
        let currencyKeys = LocalizationKey.allCases.filter { $0.category == .currencies }
        
        XCTAssertGreaterThan(currencyKeys.count, 20) // Should have many currencies
        
        // Test major currencies are present
        XCTAssertTrue(currencyKeys.contains(.currencyINR))
        XCTAssertTrue(currencyKeys.contains(.currencyUSD))
        XCTAssertTrue(currencyKeys.contains(.currencyEUR))
        XCTAssertTrue(currencyKeys.contains(.currencyGBP))
        XCTAssertTrue(currencyKeys.contains(.currencyJPY))
    }
    
    // MARK: - Country Key Tests
    
    func testCountryKeys() {
        let countryKeys = LocalizationKey.allCases.filter { $0.category == .countries }
        
        XCTAssertGreaterThan(countryKeys.count, 15) // Should have many countries
        
        // Test major countries are present
        XCTAssertTrue(countryKeys.contains(.countryIndia))
        XCTAssertTrue(countryKeys.contains(.countryUnitedStates))
        XCTAssertTrue(countryKeys.contains(.countryUnitedKingdom))
        XCTAssertTrue(countryKeys.contains(.countryCanada))
        XCTAssertTrue(countryKeys.contains(.countryAustralia))
    }
    
    // MARK: - Financial Key Tests
    
    func testFinancialKeys() {
        let financialKeys = LocalizationKey.allCases.filter { $0.category == .financial }
        
        XCTAssertGreaterThan(financialKeys.count, 25) // Should have comprehensive financial terms
        
        // Test core financial terms are present
        XCTAssertTrue(financialKeys.contains(.finAmount))
        XCTAssertTrue(financialKeys.contains(.finBalance))
        XCTAssertTrue(financialKeys.contains(.finNetWorth))
        XCTAssertTrue(financialKeys.contains(.finPortfolio))
        XCTAssertTrue(financialKeys.contains(.finCapitalGains))
        XCTAssertTrue(financialKeys.contains(.finCompoundInterest))
    }
    
    // MARK: - Goal Tracking Key Tests
    
    func testGoalKeys() {
        let goalKeys = LocalizationKey.allCases.filter { $0.category == .goals }
        
        XCTAssertGreaterThan(goalKeys.count, 10) // Should have goal tracking terms
        
        // Test goal-specific terms are present
        XCTAssertTrue(goalKeys.contains(.goalTitle))
        XCTAssertTrue(goalKeys.contains(.goalTarget))
        XCTAssertTrue(goalKeys.contains(.goalProgress))
        XCTAssertTrue(goalKeys.contains(.goalMilestone))
        XCTAssertTrue(goalKeys.contains(.goalContribution))
    }
    
    // MARK: - Error Key Tests
    
    func testErrorKeys() {
        let errorKeys = LocalizationKey.allCases.filter { $0.category == .errors }
        
        XCTAssertGreaterThan(errorKeys.count, 10) // Should have comprehensive error messages
        
        // Test common error types are present
        XCTAssertTrue(errorKeys.contains(.errorNetwork))
        XCTAssertTrue(errorKeys.contains(.errorInvalidInput))
        XCTAssertTrue(errorKeys.contains(.errorAuthentication))
        XCTAssertTrue(errorKeys.contains(.errorServerError))
    }
    
    // MARK: - Accessibility Key Tests
    
    func testAccessibilityKeys() {
        let accessibilityKeys = LocalizationKey.allCases.filter { $0.category == .accessibility }
        
        XCTAssertGreaterThan(accessibilityKeys.count, 8) // Should have accessibility terms
        
        // Test accessibility terms are present
        XCTAssertTrue(accessibilityKeys.contains(.accessibilityButton))
        XCTAssertTrue(accessibilityKeys.contains(.accessibilityLabel))
        XCTAssertTrue(accessibilityKeys.contains(.accessibilitySelected))
        XCTAssertTrue(accessibilityKeys.contains(.accessibilityExpanded))
    }
    
    // MARK: - Cultural Key Tests
    
    func testCulturalKeys() {
        let culturalKeys = LocalizationKey.allCases.filter { $0.category == .cultural }
        
        XCTAssertGreaterThan(culturalKeys.count, 5) // Should have cultural context terms
        
        // Test cultural terms are present
        XCTAssertTrue(culturalKeys.contains(.culturalIndian))
        XCTAssertTrue(culturalKeys.contains(.culturalWestern))
        XCTAssertTrue(culturalKeys.contains(.culturalBritish))
        XCTAssertTrue(culturalKeys.contains(.culturalGlobal))
    }
    
    // MARK: - Number System Key Tests
    
    func testNumberKeys() {
        let numberKeys = LocalizationKey.allCases.filter { $0.category == .numbers }
        
        XCTAssertGreaterThan(numberKeys.count, 5) // Should have number system terms
        
        // Test Indian and Western number systems are present
        XCTAssertTrue(numberKeys.contains(.numberLakh))
        XCTAssertTrue(numberKeys.contains(.numberCrore))
        XCTAssertTrue(numberKeys.contains(.numberMillion))
        XCTAssertTrue(numberKeys.contains(.numberBillion))
    }
    
    // MARK: - Naming Convention Tests
    
    func testNamingConventions() {
        for key in LocalizationKey.allCases {
            let rawValue = key.rawValue
            
            // Should contain at least one dot (category separator)
            XCTAssertTrue(rawValue.contains("."), "Key \(rawValue) should follow category.item naming convention")
            
            // Should be lowercase with underscores
            XCTAssertEqual(rawValue, rawValue.lowercased(), "Key \(rawValue) should be lowercase")
            XCTAssertFalse(rawValue.contains(" "), "Key \(rawValue) should not contain spaces")
            
            // Should not start or end with dot or underscore
            XCTAssertFalse(rawValue.hasPrefix("."), "Key \(rawValue) should not start with dot")
            XCTAssertFalse(rawValue.hasSuffix("."), "Key \(rawValue) should not end with dot")
            XCTAssertFalse(rawValue.hasPrefix("_"), "Key \(rawValue) should not start with underscore")
            XCTAssertFalse(rawValue.hasSuffix("_"), "Key \(rawValue) should not end with underscore")
        }
    }
    
    // MARK: - Performance Tests
    
    func testKeyLookupPerformance() {
        measure {
            for _ in 0..<1000 {
                let randomIndex = Int.random(in: 0..<LocalizationKey.allCases.count)
                let key = LocalizationKey.allCases[randomIndex]
                _ = key.rawValue
                _ = key.category
                _ = key.comment
            }
        }
    }
    
    func testLocalizedStringPerformance() {
        let testKeys = Array(LocalizationKey.allCases.prefix(50)) // Test first 50 keys
        
        measure {
            for key in testKeys {
                _ = key.localizedString
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testKeyWithSpecialCharacters() {
        // Test that keys with special characters are handled properly
        for key in LocalizationKey.allCases {
            let rawValue = key.rawValue
            
            // Should not contain problematic characters
            XCTAssertFalse(rawValue.contains("'"), "Key should not contain single quotes")
            XCTAssertFalse(rawValue.contains("\""), "Key should not contain double quotes")
            XCTAssertFalse(rawValue.contains("\\"), "Key should not contain backslashes")
        }
    }
    
    func testCaseIterableConformance() {
        // Test CaseIterable conformance
        let allCases = LocalizationKey.allCases
        XCTAssertFalse(allCases.isEmpty)
        
        // Test that each case appears exactly once
        let caseCounts = Dictionary(grouping: allCases) { $0 }.mapValues { $0.count }
        for (key, count) in caseCounts {
            XCTAssertEqual(count, 1, "Key \(key.rawValue) should appear exactly once in allCases")
        }
    }
}

// MARK: - LocalizationCategory Tests

final class LocalizationCategoryTests: XCTestCase {
    
    func testCategoryCount() {
        XCTAssertGreaterThan(LocalizationCategory.allCases.count, 10)
    }
    
    func testCategoryDisplayNames() {
        for category in LocalizationCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertEqual(category.displayName, category.rawValue)
        }
    }
    
    func testCategoryKeys() {
        for category in LocalizationCategory.allCases {
            let keys = category.keys
            XCTAssertGreaterThan(keys.count, 0, "Category \(category) should have at least one key")
            
            // Verify all keys in this category actually belong to it
            for key in keys {
                XCTAssertEqual(key.category, category, "Key \(key.rawValue) category mismatch")
            }
        }
    }
    
    func testCategoryUniqueness() {
        let rawValues = LocalizationCategory.allCases.map { $0.rawValue }
        let uniqueValues = Set(rawValues)
        
        XCTAssertEqual(rawValues.count, uniqueValues.count, "All categories must have unique raw values")
    }
    
    func testCategoryNaming() {
        for category in LocalizationCategory.allCases {
            let rawValue = category.rawValue
            
            // Should be title case with spaces
            XCTAssertTrue(rawValue.first!.isUppercase, "Category \(rawValue) should start with uppercase")
        }
    }
}