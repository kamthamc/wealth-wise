import XCTest
@testable import WealthWise

/// Unit tests for the Country/Geography Types System
/// Tests comprehensive geographic and cultural data integration
final class CountryGeographySystemTests: XCTestCase {
    
    // MARK: - CountryCode Tests
    
    func testCountryCodeBasicProperties() {
        // Test India (primary target market)
        let india = CountryCode.IND
        XCTAssertEqual(india.rawValue, "IND")
        XCTAssertEqual(india.iso3166Alpha2, "IN")
        XCTAssertEqual(india.displayName, "India")
        XCTAssertEqual(india.flagEmoji, "🇮🇳")
        XCTAssertEqual(india.primaryCurrencyCode, "INR")
        XCTAssertEqual(india.primaryTimeZone, "Asia/Kolkata")
        XCTAssertTrue(india.primaryLanguages.contains("hi"))
        XCTAssertTrue(india.primaryLanguages.contains("en"))
        XCTAssertFalse(india.isRTL)
        XCTAssertEqual(india.financialYearStartMonth, 4)
        
        // Test USA (major international market)
        let usa = CountryCode.USA
        XCTAssertEqual(usa.rawValue, "USA")
        XCTAssertEqual(usa.iso3166Alpha2, "US")
        XCTAssertEqual(usa.displayName, "United States")
        XCTAssertEqual(usa.flagEmoji, "🇺🇸")
        XCTAssertEqual(usa.primaryCurrencyCode, "USD")
        XCTAssertEqual(usa.primaryTimeZone, "America/New_York")
        XCTAssertTrue(usa.primaryLanguages.contains("en"))
        XCTAssertFalse(usa.isRTL)
        XCTAssertEqual(usa.financialYearStartMonth, 1)
    }
    
    func testCountryCodeCurrentDetection() {
        // Test that current country code detection works
        let currentCountry = CountryCode.current
        XCTAssertNotNil(currentCountry)
        
        // Should be a valid country code
        XCTAssertTrue(CountryCode.allCases.contains(currentCountry))
    }
    
    func testCountryCodeRTLSupport() {
        // Test RTL countries
        let uae = CountryCode.ARE
        let qatar = CountryCode.QAT
        let saudi = CountryCode.SAU
        
        XCTAssertTrue(uae.isRTL)
        XCTAssertTrue(qatar.isRTL)
        XCTAssertTrue(saudi.isRTL)
        
        // Test LTR countries
        let india = CountryCode.IND
        let usa = CountryCode.USA
        let uk = CountryCode.GBR
        
        XCTAssertFalse(india.isRTL)
        XCTAssertFalse(usa.isRTL)
        XCTAssertFalse(uk.isRTL)
    }
    
    func testCountryCodeFinancialYears() {
        // Test April start (India, UK)
        XCTAssertEqual(CountryCode.IND.financialYearStartMonth, 4)
        XCTAssertEqual(CountryCode.GBR.financialYearStartMonth, 4)
        
        // Test January start (USA, Canada, Germany)
        XCTAssertEqual(CountryCode.USA.financialYearStartMonth, 1)
        XCTAssertEqual(CountryCode.CAN.financialYearStartMonth, 1)
        XCTAssertEqual(CountryCode.DEU.financialYearStartMonth, 1)
        
        // Test July start (Australia)
        XCTAssertEqual(CountryCode.AUS.financialYearStartMonth, 7)
    }
    
    // MARK: - PrimaryAudience Tests
    
    func testPrimaryAudienceBasicProperties() {
        // Test Indian audience
        let indian = PrimaryAudience.indian
        XCTAssertEqual(indian.rawValue, "indian")
        XCTAssertEqual(indian.displayName, "Indian")
        XCTAssertTrue(indian.associatedCountryCodes.contains("IND"))
        XCTAssertEqual(indian.primaryCountryCode, "IND")
        XCTAssertEqual(indian.numberFormatStyle, .indian)
        XCTAssertEqual(indian.dateFormatStyle, .ddMMYYYY)
        XCTAssertTrue(indian.primaryLanguages.contains("hi"))
        XCTAssertTrue(indian.primaryLanguages.contains("en"))
        XCTAssertFalse(indian.isRTL)
        XCTAssertEqual(indian.financialYearStartMonth, 4)
        
        // Test American audience
        let american = PrimaryAudience.american
        XCTAssertEqual(american.rawValue, "american")
        XCTAssertEqual(american.displayName, "American")
        XCTAssertTrue(american.associatedCountryCodes.contains("USA"))
        XCTAssertEqual(american.primaryCountryCode, "USA")
        XCTAssertEqual(american.numberFormatStyle, .western)
        XCTAssertEqual(american.dateFormatStyle, .mmDDYYYY)
        XCTAssertTrue(american.primaryLanguages.contains("en"))
        XCTAssertFalse(american.isRTL)
        XCTAssertEqual(american.financialYearStartMonth, 1)
    }
    
    func testPrimaryAudienceCurrentDetection() {
        // Test that current audience detection works
        let currentAudience = PrimaryAudience.current
        XCTAssertNotNil(currentAudience)
        
        // Should be a valid audience
        XCTAssertTrue(PrimaryAudience.allCases.contains(currentAudience))
    }
    
    func testPrimaryAudienceFromCountryCode() {
        // Test successful country code mapping
        let indianAudience = PrimaryAudience(from: "IND")
        XCTAssertEqual(indianAudience, .indian)
        
        let americanAudience = PrimaryAudience(from: "USA")
        XCTAssertEqual(americanAudience, .american)
        
        let britishAudience = PrimaryAudience(from: "GBR")
        XCTAssertEqual(britishAudience, .british)
        
        // Test invalid country code
        let invalidAudience = PrimaryAudience(from: "INVALID")
        XCTAssertNil(invalidAudience)
    }
    
    func testPrimaryAudienceGroupings() {
        // Test Indian expat audiences
        let indianExpatAudiences = PrimaryAudience.indianExpatAudiences
        XCTAssertTrue(indianExpatAudiences.contains(.american))
        XCTAssertTrue(indianExpatAudiences.contains(.british))
        XCTAssertTrue(indianExpatAudiences.contains(.canadian))
        XCTAssertTrue(indianExpatAudiences.contains(.australian))
        XCTAssertTrue(indianExpatAudiences.contains(.singaporean))
        XCTAssertTrue(indianExpatAudiences.contains(.emirati))
        
        // Test English-speaking audiences
        let englishSpeaking = PrimaryAudience.englishSpeaking
        XCTAssertTrue(englishSpeaking.contains(.american))
        XCTAssertTrue(englishSpeaking.contains(.british))
        XCTAssertTrue(englishSpeaking.contains(.canadian))
        XCTAssertTrue(englishSpeaking.contains(.australian))
        XCTAssertTrue(englishSpeaking.contains(.singaporean))
        XCTAssertFalse(englishSpeaking.contains(.german))
        XCTAssertFalse(englishSpeaking.contains(.japanese))
        
        // Test EU audiences
        let euAudiences = PrimaryAudience.europeanUnion
        XCTAssertTrue(euAudiences.contains(.german))
        XCTAssertTrue(euAudiences.contains(.french))
        XCTAssertTrue(euAudiences.contains(.dutch))
        XCTAssertTrue(euAudiences.contains(.irish))
        XCTAssertTrue(euAudiences.contains(.luxembourgish))
        XCTAssertFalse(euAudiences.contains(.british))  // Post-Brexit
        XCTAssertFalse(euAudiences.contains(.swiss))    // Not EU member
    }
    
    // MARK: - NumberFormatStyle Tests
    
    func testNumberFormatStyleProperties() {
        // Test all format styles have display names
        for style in NumberFormatStyle.allCases {
            XCTAssertFalse(style.displayName.isEmpty)
            XCTAssertFalse(style.rawValue.isEmpty)
        }
        
        // Test specific styles
        XCTAssertEqual(NumberFormatStyle.indian.displayName, "Indian (Lakh/Crore)")
        XCTAssertEqual(NumberFormatStyle.western.displayName, "Western (Million/Billion)")
        XCTAssertEqual(NumberFormatStyle.japanese.displayName, "Japanese (Man/Oku)")
    }
    
    // MARK: - DateFormatStyle Tests
    
    func testDateFormatStyleProperties() {
        // Test all format styles have display names and examples
        for style in DateFormatStyle.allCases {
            XCTAssertFalse(style.displayName.isEmpty)
            XCTAssertFalse(style.rawValue.isEmpty)
            XCTAssertFalse(style.example.isEmpty)
        }
        
        // Test specific styles
        XCTAssertEqual(DateFormatStyle.ddMMYYYY.displayName, "DD/MM/YYYY")
        XCTAssertEqual(DateFormatStyle.mmDDYYYY.displayName, "MM/DD/YYYY")
        XCTAssertEqual(DateFormatStyle.yyyyMMDD.displayName, "YYYY/MM/DD")
    }
    
    // MARK: - CulturalPreferences Tests
    
    func testCulturalPreferencesBasic() {
        // Test basic cultural preferences creation
        let indianPrefs = CulturalPreferences.indian
        XCTAssertEqual(indianPrefs.audienceIdentifier, "indian")
        XCTAssertTrue(indianPrefs.languages.contains("hi"))
        XCTAssertTrue(indianPrefs.languages.contains("en"))
        XCTAssertEqual(indianPrefs.numberFormatStyle, "indian")
        XCTAssertEqual(indianPrefs.dateFormatStyle, "ddMMYYYY")
        XCTAssertEqual(indianPrefs.textDirection, "ltr")
        XCTAssertEqual(indianPrefs.accentColor, "orange")
        XCTAssertEqual(indianPrefs.financialYearStartMonth, 4)
        
        let americanPrefs = CulturalPreferences.american
        XCTAssertEqual(americanPrefs.audienceIdentifier, "american")
        XCTAssertTrue(americanPrefs.languages.contains("en"))
        XCTAssertEqual(americanPrefs.numberFormatStyle, "western")
        XCTAssertEqual(americanPrefs.dateFormatStyle, "mmDDYYYY")
        XCTAssertEqual(americanPrefs.textDirection, "ltr")
        XCTAssertEqual(americanPrefs.accentColor, "blue")
        XCTAssertEqual(americanPrefs.financialYearStartMonth, 1)
    }
    
    func testCulturalPreferencesCurrent() {
        // Test current cultural preferences detection
        let currentPrefs = CulturalPreferences.current
        XCTAssertFalse(currentPrefs.audienceIdentifier.isEmpty)
        XCTAssertFalse(currentPrefs.languages.isEmpty)
        XCTAssertFalse(currentPrefs.numberFormatStyle.isEmpty)
        XCTAssertFalse(currentPrefs.dateFormatStyle.isEmpty)
        XCTAssertTrue(["ltr", "rtl"].contains(currentPrefs.textDirection))
        XCTAssertGreaterThanOrEqual(currentPrefs.financialYearStartMonth, 1)
        XCTAssertLessThanOrEqual(currentPrefs.financialYearStartMonth, 12)
    }
    
    // MARK: - RegionalMappings Tests
    
    func testRegionalMappingsCountryLookup() {
        // Test successful country lookups
        let indiaInfo = RegionalMappings.countryInfo(for: "IND")
        XCTAssertNotNil(indiaInfo)
        XCTAssertEqual(indiaInfo?.code, "IND")
        XCTAssertEqual(indiaInfo?.displayName, "India")
        XCTAssertEqual(indiaInfo?.flagEmoji, "🇮🇳")
        XCTAssertEqual(indiaInfo?.currencyCode, "INR")
        
        let usaInfo = RegionalMappings.countryInfo(for: "USA")
        XCTAssertNotNil(usaInfo)
        XCTAssertEqual(usaInfo?.code, "USA")
        XCTAssertEqual(usaInfo?.displayName, "United States")
        XCTAssertEqual(usaInfo?.currencyCode, "USD")
        
        // Test case insensitive lookup
        let indiaInfoLower = RegionalMappings.countryInfo(for: "ind")
        XCTAssertNotNil(indiaInfoLower)
        XCTAssertEqual(indiaInfoLower?.code, "IND")
        
        // Test invalid country code
        let invalidInfo = RegionalMappings.countryInfo(for: "INVALID")
        XCTAssertNil(invalidInfo)
    }
    
    func testRegionalMappingsAudienceLookup() {
        // Test successful audience lookups
        let indianAudience = RegionalMappings.audienceInfo(for: "indian")
        XCTAssertNotNil(indianAudience)
        XCTAssertEqual(indianAudience?.identifier, "indian")
        XCTAssertEqual(indianAudience?.displayName, "Indian")
        XCTAssertTrue(indianAudience?.countryCodes.contains("IND") == true)
        XCTAssertEqual(indianAudience?.numberFormatStyle, "indian")
        
        let americanAudience = RegionalMappings.audienceInfo(for: "american")
        XCTAssertNotNil(americanAudience)
        XCTAssertEqual(americanAudience?.identifier, "american")
        XCTAssertEqual(americanAudience?.numberFormatStyle, "western")
        
        // Test case insensitive lookup
        let indianAudienceUpper = RegionalMappings.audienceInfo(for: "INDIAN")
        XCTAssertNotNil(indianAudienceUpper)
        XCTAssertEqual(indianAudienceUpper?.identifier, "indian")
        
        // Test invalid audience
        let invalidAudience = RegionalMappings.audienceInfo(for: "invalid")
        XCTAssertNil(invalidAudience)
    }
    
    // MARK: - Locale Extensions Tests
    
    func testLocaleExtensions() {
        let currentLocale = Locale.current
        
        // Test country code detection
        let countryCode = currentLocale.countryCodeString
        // Should either be nil or a valid string
        if let code = countryCode {
            XCTAssertFalse(code.isEmpty)
            XCTAssertTrue(code.count >= 2)
        }
        
        // Test cultural preferences from locale
        let prefs = currentLocale.culturalPreferences
        XCTAssertFalse(prefs.localeIdentifier.isEmpty)
        XCTAssertFalse(prefs.countryCode.isEmpty)
        XCTAssertFalse(prefs.languageCode.isEmpty)
        XCTAssertFalse(prefs.currencyCode.isEmpty)
        XCTAssertTrue(["ltr", "rtl"].contains(prefs.textDirection))
        XCTAssertGreaterThanOrEqual(prefs.financialYearStartMonth, 1)
        XCTAssertLessThanOrEqual(prefs.financialYearStartMonth, 12)
    }
    
    func testSimpleCulturalPreferences() {
        let currentPrefs = SimpleCulturalPreferences.current
        
        // Test basic properties
        XCTAssertFalse(currentPrefs.localeIdentifier.isEmpty)
        XCTAssertFalse(currentPrefs.countryCode.isEmpty)
        XCTAssertFalse(currentPrefs.languageCode.isEmpty)
        XCTAssertFalse(currentPrefs.currencyCode.isEmpty)
        
        // Test market detection methods
        let isIndian = currentPrefs.isIndianMarket
        let isWestern = currentPrefs.isWesternMarket
        let isAsian = currentPrefs.isAsianMarket
        
        // Should be boolean values (test passes if no exceptions)
        XCTAssertTrue(isIndian == true || isIndian == false)
        XCTAssertTrue(isWestern == true || isWestern == false)
        XCTAssertTrue(isAsian == true || isAsian == false)
        
        // Test accent color preference
        let accentColor = currentPrefs.preferredAccentColor
        let validColors = ["orange", "blue", "red", "green", "system"]
        XCTAssertTrue(validColors.contains(accentColor))
    }
    
    // MARK: - Calendar Extensions Tests
    
    func testCalendarExtensions() {
        let calendar = Calendar.current
        let testDate = Date()
        
        // Test financial year calculations
        let fyStart = calendar.financialYearStart(for: 2024, startMonth: 4)
        XCTAssertNotNil(fyStart)
        
        let fyEnd = calendar.financialYearEnd(for: 2024, startMonth: 4)
        XCTAssertNotNil(fyEnd)
        
        if let start = fyStart, let end = fyEnd {
            XCTAssertTrue(start < end)
        }
        
        // Test financial year detection
        let fy = calendar.financialYear(for: testDate, startMonth: 4)
        XCTAssertGreaterThan(fy, 2020)
        XCTAssertLessThan(fy, 2030)
        
        // Test business day calculations
        let businessDays = calendar.businessDaysBetween(testDate, and: calendar.date(byAdding: .day, value: 7, to: testDate) ?? testDate)
        XCTAssertGreaterThanOrEqual(businessDays, 0)
        XCTAssertLessThanOrEqual(businessDays, 7)
        
        // Test weekend detection
        let isWeekend = calendar.isWeekend(testDate)
        XCTAssertTrue(isWeekend == true || isWeekend == false)
    }
    
    func testFinancialYear() {
        // Test financial year creation
        let fy2024 = FinancialYear(year: 2024, startMonth: 4)
        XCTAssertEqual(fy2024.year, 2024)
        XCTAssertEqual(fy2024.startMonth, 4)
        XCTAssertEqual(fy2024.displayString, "FY 2024-25")
        XCTAssertEqual(fy2024.shortDisplayString, "2024-25")
        
        // Test calendar year (January start)
        let cy2024 = FinancialYear(year: 2024, startMonth: 1)
        XCTAssertEqual(cy2024.displayString, "2024")
        XCTAssertEqual(cy2024.shortDisplayString, "2024")
        
        // Test navigation
        let nextFY = fy2024.next
        XCTAssertEqual(nextFY.year, 2025)
        XCTAssertEqual(nextFY.startMonth, 4)
        
        let prevFY = fy2024.previous
        XCTAssertEqual(prevFY.year, 2023)
        XCTAssertEqual(prevFY.startMonth, 4)
        
        // Test comparison
        XCTAssertTrue(prevFY < fy2024)
        XCTAssertTrue(fy2024 < nextFY)
        XCTAssertEqual(fy2024, FinancialYear(year: 2024, startMonth: 4))
    }
    
    // MARK: - Integration Tests
    
    func testCountryAudienceIntegration() {
        // Test that all countries have valid currency codes
        for country in CountryCode.allCases {
            XCTAssertFalse(country.primaryCurrencyCode.isEmpty)
            XCTAssertGreaterThanOrEqual(country.primaryCurrencyCode.count, 3)
        }
        
        // Test that all audiences have valid country associations
        for audience in PrimaryAudience.allCases {
            XCTAssertFalse(audience.associatedCountryCodes.isEmpty)
            XCTAssertFalse(audience.primaryCountryCode.isEmpty)
        }
        
        // Test that primary countries exist in CountryCode enum
        for audience in PrimaryAudience.allCases {
            let primaryCountryExists = CountryCode.allCases.contains { country in
                country.rawValue == audience.primaryCountryCode
            }
            XCTAssertTrue(primaryCountryExists, "Primary country \(audience.primaryCountryCode) for audience \(audience.rawValue) should exist in CountryCode enum")
        }
    }
    
    func testCulturalPreferencesIntegration() {
        // Test predefined preferences
        let presets = [
            CulturalPreferences.indian,
            CulturalPreferences.american,
            CulturalPreferences.british
        ]
        
        for preset in presets {
            XCTAssertFalse(preset.audienceIdentifier.isEmpty)
            XCTAssertFalse(preset.languages.isEmpty)
            XCTAssertFalse(preset.numberFormatStyle.isEmpty)
            XCTAssertFalse(preset.dateFormatStyle.isEmpty)
            XCTAssertTrue(["ltr", "rtl"].contains(preset.textDirection))
            XCTAssertGreaterThanOrEqual(preset.financialYearStartMonth, 1)
            XCTAssertLessThanOrEqual(preset.financialYearStartMonth, 12)
        }
    }
    
    // MARK: - Performance Tests
    
    func testCountryCodePerformance() throws {
        // Performance test for country code operations
        measure {
            for _ in 0..<1000 {
                let _ = CountryCode.allCases.randomElement()?.displayName
                let _ = CountryCode.allCases.randomElement()?.primaryCurrencyCode
                let _ = CountryCode.allCases.randomElement()?.primaryTimeZone
            }
        }
    }
    
    func testAudienceDetectionPerformance() throws {
        // Performance test for audience detection
        measure {
            for _ in 0..<1000 {
                let _ = PrimaryAudience.current
                let _ = PrimaryAudience(from: "IND")
                let _ = PrimaryAudience.allCases.randomElement()?.numberFormatStyle
            }
        }
    }
}