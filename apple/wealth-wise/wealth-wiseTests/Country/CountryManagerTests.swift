import XCTest
import Combine
@testable import WealthWise

final class CountryManagerTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    var userDefaults: UserDefaults!
    var countryManager: CountryManager!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        // Use a test-specific UserDefaults suite
        userDefaults = UserDefaults(suiteName: "CountryManagerTests")!
        userDefaults.removePersistentDomain(forName: "CountryManagerTests")
        
        countryManager = CountryManager(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        cancellables = nil
        userDefaults.removePersistentDomain(forName: "CountryManagerTests")
        userDefaults = nil
        countryManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitializationWithDefaultLocale() {
        // CountryManager should initialize with a default country
        XCTAssertNotNil(countryManager.currentCountry)
        XCTAssertFalse(countryManager.availableCountries.isEmpty)
        XCTAssertFalse(countryManager.preferredCountries.isEmpty)
        
        // Should contain current country in preferred list
        XCTAssertTrue(countryManager.preferredCountries.contains { $0.id == countryManager.currentCountry.id })
    }
    
    func testInitializationWithStoredCountry() {
        // Store a country in UserDefaults first
        let india = SupportedCountries.india
        if let data = try? JSONEncoder().encode(india) {
            userDefaults.set(data, forKey: "WealthWise.CurrentCountry")
        }
        
        // Create new manager - should load stored country
        let newManager = CountryManager(userDefaults: userDefaults)
        XCTAssertEqual(newManager.currentCountry.id, "IN")
    }
    
    func testInitializationWithStoredPreferredCountries() {
        let preferredCountries = [SupportedCountries.india, SupportedCountries.unitedStates]
        if let data = try? JSONEncoder().encode(preferredCountries) {
            userDefaults.set(data, forKey: "WealthWise.PreferredCountries")
        }
        
        let newManager = CountryManager(userDefaults: userDefaults)
        XCTAssertEqual(newManager.preferredCountries.count, 2)
        XCTAssertTrue(newManager.preferredCountries.contains { $0.id == "IN" })
        XCTAssertTrue(newManager.preferredCountries.contains { $0.id == "US" })
    }
    
    // MARK: - Country Management Tests
    
    func testSetCurrentCountry() {
        let originalCountry = countryManager.currentCountry
        let newCountry = SupportedCountries.japan
        
        countryManager.setCurrentCountry(newCountry)
        
        XCTAssertEqual(countryManager.currentCountry.id, "JP")
        XCTAssertNotEqual(countryManager.currentCountry.id, originalCountry.id)
        
        // Should be added to preferred countries
        XCTAssertTrue(countryManager.preferredCountries.contains { $0.id == "JP" })
        
        // Should be persisted
        let newManager = CountryManager(userDefaults: userDefaults)
        XCTAssertEqual(newManager.currentCountry.id, "JP")
    }
    
    func testAddPreferredCountry() {
        let initialCount = countryManager.preferredCountries.count
        let singapore = SupportedCountries.singapore
        
        countryManager.addPreferredCountry(singapore)
        
        XCTAssertEqual(countryManager.preferredCountries.count, initialCount + 1)
        XCTAssertTrue(countryManager.preferredCountries.contains { $0.id == "SG" })
        
        // Adding same country again shouldn't increase count
        countryManager.addPreferredCountry(singapore)
        XCTAssertEqual(countryManager.preferredCountries.count, initialCount + 1)
    }
    
    func testRemovePreferredCountry() {
        // Add a country first
        let singapore = SupportedCountries.singapore
        countryManager.addPreferredCountry(singapore)
        
        let initialCount = countryManager.preferredCountries.count
        
        // Remove it
        countryManager.removePreferredCountry(singapore)
        
        XCTAssertEqual(countryManager.preferredCountries.count, initialCount - 1)
        XCTAssertFalse(countryManager.preferredCountries.contains { $0.id == "SG" })
    }
    
    func testCannotRemoveCurrentCountryFromPreferred() {
        let currentCountry = countryManager.currentCountry
        let initialCount = countryManager.preferredCountries.count
        
        // Try to remove current country
        countryManager.removePreferredCountry(currentCountry)
        
        // Should still be in preferred list
        XCTAssertEqual(countryManager.preferredCountries.count, initialCount)
        XCTAssertTrue(countryManager.preferredCountries.contains { $0.id == currentCountry.id })
    }
    
    func testReorderPreferredCountries() {
        // Add some countries
        countryManager.addPreferredCountry(SupportedCountries.singapore)
        countryManager.addPreferredCountry(SupportedCountries.japan)
        countryManager.addPreferredCountry(SupportedCountries.unitedKingdom)
        
        let newOrder = [
            SupportedCountries.japan,
            SupportedCountries.unitedKingdom,
            SupportedCountries.singapore
        ]
        
        countryManager.reorderPreferredCountries(newOrder)
        
        // Check order (current country might be inserted at beginning)
        let japanIndex = countryManager.preferredCountries.firstIndex { $0.id == "JP" }
        let ukIndex = countryManager.preferredCountries.firstIndex { $0.id == "GB" }
        let sgIndex = countryManager.preferredCountries.firstIndex { $0.id == "SG" }
        
        XCTAssertNotNil(japanIndex)
        XCTAssertNotNil(ukIndex)
        XCTAssertNotNil(sgIndex)
    }
    
    func testReorderPreferredCountriesEnsuresCurrentCountryIncluded() {
        let currentCountry = countryManager.currentCountry
        
        // Reorder without including current country
        let newOrder = [SupportedCountries.japan, SupportedCountries.singapore]
        
        countryManager.reorderPreferredCountries(newOrder)
        
        // Current country should still be included
        XCTAssertTrue(countryManager.preferredCountries.contains { $0.id == currentCountry.id })
    }
    
    // MARK: - Country Discovery Tests
    
    func testDetectSuitableCountries() {
        let suggestions = countryManager.detectSuitableCountries()
        
        XCTAssertFalse(suggestions.isEmpty)
        
        // Should include major markets
        XCTAssertTrue(suggestions.contains { $0.id == "US" })
        XCTAssertTrue(suggestions.contains { $0.id == "GB" })
        XCTAssertTrue(suggestions.contains { $0.id == "SG" })
        
        // Should be unique
        let uniqueSuggestions = Set(suggestions.map { $0.id })
        XCTAssertEqual(suggestions.count, uniqueSuggestions.count)
    }
    
    func testCountriesSupportingCurrency() {
        let usdCountries = countryManager.countries(supporting: .usd)
        let eurCountries = countryManager.countries(supporting: .eur)
        let inrCountries = countryManager.countries(supporting: .inr)
        
        // USD should be supported by US and as secondary by others
        XCTAssertTrue(usdCountries.contains { $0.id == "US" })
        XCTAssertGreaterThan(usdCountries.count, 1) // Should have secondary support too
        
        // EUR should be supported by European countries
        XCTAssertTrue(eurCountries.contains { $0.id == "DE" })
        
        // INR should primarily be supported by India
        XCTAssertTrue(inrCountries.contains { $0.id == "IN" })
    }
    
    func testCountriesSupportingInvestmentType() {
        let ppfCountries = countryManager.countries(supporting: .retirementPPF)
        let usa401kCountries = countryManager.countries(supporting: .retirement401k)
        let stockCountries = countryManager.countries(supporting: .stocksLocal)
        
        // PPF should be India-specific
        XCTAssertTrue(ppfCountries.contains { $0.id == "IN" })
        XCTAssert(ppfCountries.count <= 2) // Should be very few
        
        // 401k should be US-specific
        XCTAssertTrue(usa401kCountries.contains { $0.id == "US" })
        XCTAssert(usa401kCountries.count <= 2) // Should be very few
        
        // Stocks should be widely supported
        XCTAssertGreaterThan(stockCountries.count, 5)
    }
    
    func testCountriesWithBankingFeatures() {
        let upiCountries = countryManager.countries(with: .upi)
        let openBankingCountries = countryManager.countries(with: .openBanking)
        let achCountries = countryManager.countries(with: .ach)
        let sepaCountries = countryManager.countries(with: .sepa)
        
        // UPI should be India-specific
        XCTAssertTrue(upiCountries.contains { $0.id == "IN" })
        XCTAssertEqual(upiCountries.count, 1)
        
        // Open Banking should include UK and Germany
        XCTAssertTrue(openBankingCountries.contains { $0.id == "GB" })
        XCTAssertTrue(openBankingCountries.contains { $0.id == "DE" })
        
        // ACH should be US-specific
        XCTAssertTrue(achCountries.contains { $0.id == "US" })
        
        // SEPA should be European
        XCTAssertTrue(sepaCountries.contains { $0.id == "DE" })
    }
    
    // MARK: - Cultural Preferences Tests
    
    func testDateFormatter() {
        // Test with different countries
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        let usFormatter = countryManager.dateFormatter()
        XCTAssertTrue(usFormatter.locale.identifier.contains("en_US"))
        
        countryManager.setCurrentCountry(SupportedCountries.unitedKingdom)
        let ukFormatter = countryManager.dateFormatter()
        XCTAssertTrue(ukFormatter.locale.identifier.contains("en_GB"))
        
        countryManager.setCurrentCountry(SupportedCountries.canada)
        let caFormatter = countryManager.dateFormatter()
        XCTAssertTrue(caFormatter.locale.identifier.contains("en_CA"))
    }
    
    func testTimeFormatter() {
        // Test 12-hour format country
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        let us12HourFormatter = countryManager.timeFormatter()
        XCTAssertTrue(us12HourFormatter.dateFormat.contains("a")) // AM/PM
        
        // Test 24-hour format country
        countryManager.setCurrentCountry(SupportedCountries.germany)
        let germanFormatter = countryManager.timeFormatter()
        XCTAssertTrue(germanFormatter.dateFormat.contains("HH")) // 24-hour
        XCTAssertFalse(germanFormatter.dateFormat.contains("a")) // No AM/PM
    }
    
    func testCurrentFinancialYear() {
        // Test India (April start)
        countryManager.setCurrentCountry(SupportedCountries.india)
        let indiaFY = countryManager.currentFinancialYear()
        XCTAssertGreaterThan(indiaFY, 2020)
        XCTAssertLessThan(indiaFY, 2030)
        
        // Test US (January start)
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        let usFY = countryManager.currentFinancialYear()
        XCTAssertGreaterThan(usFY, 2020)
        XCTAssertLessThan(usFY, 2030)
    }
    
    func testWorkingDays() {
        // Test India (6-day work week)
        countryManager.setCurrentCountry(SupportedCountries.india)
        let indiaWorkingDays = countryManager.workingDays()
        XCTAssertEqual(indiaWorkingDays.count, 6)
        XCTAssertTrue(indiaWorkingDays.contains(.saturday))
        
        // Test US (5-day work week)
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        let usWorkingDays = countryManager.workingDays()
        XCTAssertEqual(usWorkingDays.count, 5)
        XCTAssertFalse(usWorkingDays.contains(.saturday))
        XCTAssertFalse(usWorkingDays.contains(.sunday))
    }
    
    func testIsWorkingDay() {
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        
        // Create specific dates
        let monday = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 8))! // Monday
        let saturday = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 13))! // Saturday
        let sunday = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 14))! // Sunday
        
        XCTAssertTrue(countryManager.isWorkingDay(monday))
        XCTAssertFalse(countryManager.isWorkingDay(saturday)) // US doesn't work Saturday
        XCTAssertFalse(countryManager.isWorkingDay(sunday))
        
        // Test India (works Saturday)
        countryManager.setCurrentCountry(SupportedCountries.india)
        XCTAssertTrue(countryManager.isWorkingDay(monday))
        XCTAssertTrue(countryManager.isWorkingDay(saturday)) // India works Saturday
        XCTAssertFalse(countryManager.isWorkingDay(sunday))
    }
    
    // MARK: - Investment Recommendations Tests
    
    func testRecommendedInvestments() {
        countryManager.setCurrentCountry(SupportedCountries.india)
        
        let defaultRecommendations = countryManager.recommendedInvestments()
        let lowRiskRecommendations = countryManager.recommendedInvestments(for: .low)
        let highRiskRecommendations = countryManager.recommendedInvestments(for: .high)
        
        XCTAssertFalse(defaultRecommendations.isEmpty)
        XCTAssertFalse(lowRiskRecommendations.isEmpty)
        XCTAssertFalse(highRiskRecommendations.isEmpty)
        
        // High risk should have more or equal options
        XCTAssertGreaterThanOrEqual(highRiskRecommendations.count, lowRiskRecommendations.count)
        
        // Should include India-specific investments
        XCTAssertTrue(defaultRecommendations.contains(.retirementPPF) || 
                     defaultRecommendations.contains(.stocksLocal))
    }
    
    func testInvestmentsByCategory() {
        countryManager.setCurrentCountry(SupportedCountries.india)
        
        let categorizedInvestments = countryManager.investmentsByCategory()
        
        XCTAssertFalse(categorizedInvestments.isEmpty)
        
        // Should have retirement category for India
        XCTAssertNotNil(categorizedInvestments[.retirement])
        XCTAssertTrue(categorizedInvestments[.retirement]?.contains(.retirementPPF) ?? false)
        
        // Should have equity category
        XCTAssertNotNil(categorizedInvestments[.equity])
        XCTAssertTrue(categorizedInvestments[.equity]?.contains(.stocksLocal) ?? false)
        
        // Categories should be comprehensive
        let allInvestments = categorizedInvestments.values.flatMap { $0 }
        XCTAssertEqual(Set(allInvestments).count, Set(countryManager.currentCountry.commonInvestmentTypes).count)
    }
    
    // MARK: - Compliance & Regulatory Tests
    
    func testRequiresExplicitConsent() {
        // GDPR country should require explicit consent
        countryManager.setCurrentCountry(SupportedCountries.germany)
        XCTAssertTrue(countryManager.requiresExplicitConsent())
        
        // DPIA country should require explicit consent
        countryManager.setCurrentCountry(SupportedCountries.india)
        XCTAssertTrue(countryManager.requiresExplicitConsent())
        
        // CCPA country should not require explicit consent
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        XCTAssertFalse(countryManager.requiresExplicitConsent())
    }
    
    func testDataRetentionLimit() {
        // GDPR country should have retention limit
        countryManager.setCurrentCountry(SupportedCountries.germany)
        XCTAssertNotNil(countryManager.dataRetentionLimit())
        
        // CCPA country should have retention limit
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        XCTAssertNotNil(countryManager.dataRetentionLimit())
        
        // Other zones might not have limits
        countryManager.setCurrentCountry(SupportedCountries.singapore)
        // Note: Singapore (PDPA) might or might not have limits - depends on implementation
    }
    
    func testComplianceRequirements() {
        // Test GDPR compliance
        countryManager.setCurrentCountry(SupportedCountries.germany)
        let gdprCompliance = countryManager.complianceRequirements()
        
        XCTAssertEqual(gdprCompliance.regulatoryZone, .gdpr)
        XCTAssertTrue(gdprCompliance.requiresExplicitConsent)
        XCTAssertNotNil(gdprCompliance.dataRetentionLimit)
        XCTAssertTrue(gdprCompliance.requiresPrivacyPolicy)
        XCTAssertTrue(gdprCompliance.requiresTermsOfService)
        XCTAssertFalse(gdprCompliance.allowsCookies) // Native app
        XCTAssertTrue(gdprCompliance.requiresDataProcessingAgreement)
        
        // Test CCPA compliance
        countryManager.setCurrentCountry(SupportedCountries.unitedStates)
        let ccpaCompliance = countryManager.complianceRequirements()
        
        XCTAssertEqual(ccpaCompliance.regulatoryZone, .ccpa)
        XCTAssertFalse(ccpaCompliance.requiresExplicitConsent)
        XCTAssertFalse(ccpaCompliance.requiresDataProcessingAgreement)
    }
    
    // MARK: - Persistence Tests
    
    func testCountryPersistence() {
        let originalCountry = countryManager.currentCountry
        let newCountry = SupportedCountries.singapore
        
        countryManager.setCurrentCountry(newCountry)
        
        // Create new manager - should load persisted country
        let newManager = CountryManager(userDefaults: userDefaults)
        XCTAssertEqual(newManager.currentCountry.id, newCountry.id)
        XCTAssertNotEqual(newManager.currentCountry.id, originalCountry.id)
    }
    
    func testPreferredCountriesPersistence() {
        countryManager.addPreferredCountry(SupportedCountries.singapore)
        countryManager.addPreferredCountry(SupportedCountries.japan)
        
        let preferredIds = countryManager.preferredCountries.map { $0.id }
        
        // Create new manager - should load persisted preferences
        let newManager = CountryManager(userDefaults: userDefaults)
        let newPreferredIds = newManager.preferredCountries.map { $0.id }
        
        XCTAssertTrue(newPreferredIds.contains("SG"))
        XCTAssertTrue(newPreferredIds.contains("JP"))
    }
    
    func testResetToDefaults() {
        // Modify settings
        countryManager.setCurrentCountry(SupportedCountries.singapore)
        countryManager.addPreferredCountry(SupportedCountries.japan)
        
        let originalCountryId = countryManager.currentCountry.id
        
        // Reset
        countryManager.resetToDefaults()
        
        // Should be reset to locale-based defaults
        XCTAssertNotEqual(countryManager.currentCountry.id, originalCountryId)
        
        // Should have default preferred countries
        let preferredIds = countryManager.preferredCountries.map { $0.id }
        XCTAssertTrue(preferredIds.contains("US")) // Major market
        XCTAssertTrue(preferredIds.contains("GB")) // Major market
    }
    
    // MARK: - Publisher Tests
    
    func testCountryUpdatePublishers() {
        let expectation = XCTestExpectation(description: "Country change published")
        expectation.expectedFulfillmentCount = 1
        
        countryManager.$currentCountry
            .dropFirst() // Skip initial value
            .sink { country in
                XCTAssertEqual(country.id, "SG")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        countryManager.setCurrentCountry(SupportedCountries.singapore)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testCountryManagerInitializationPerformance() {
        measure {
            for _ in 0..<100 {
                let testDefaults = UserDefaults(suiteName: "PerfTest")!
                _ = CountryManager(userDefaults: testDefaults)
                testDefaults.removePersistentDomain(forName: "PerfTest")
            }
        }
    }
    
    func testCountryDetectionPerformance() {
        measure {
            for _ in 0..<100 {
                _ = countryManager.detectSuitableCountries()
            }
        }
    }
    
    func testInvestmentRecommendationPerformance() {
        countryManager.setCurrentCountry(SupportedCountries.india)
        
        measure {
            for _ in 0..<1000 {
                _ = countryManager.recommendedInvestments(for: .moderate)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testCorruptedStorageRecovery() {
        // Store corrupted data
        userDefaults.set("invalid json", forKey: "WealthWise.CurrentCountry")
        userDefaults.set(Data([0xFF, 0xFE]), forKey: "WealthWise.PreferredCountries")
        
        // Should recover gracefully
        let newManager = CountryManager(userDefaults: userDefaults)
        XCTAssertNotNil(newManager.currentCountry)
        XCTAssertFalse(newManager.preferredCountries.isEmpty)
    }
    
    func testEmptyPreferredCountriesHandling() {
        countryManager.reorderPreferredCountries([])
        
        // Should still contain current country
        XCTAssertFalse(countryManager.preferredCountries.isEmpty)
        XCTAssertTrue(countryManager.preferredCountries.contains { $0.id == countryManager.currentCountry.id })
    }
}