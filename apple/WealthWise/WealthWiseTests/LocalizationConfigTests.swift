//
//  LocalizationConfigTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-09-23.
//  Foundation: User Preference Models - Localization Config Tests
//

import XCTest
@testable import WealthWise

@MainActor
final class LocalizationConfigTests: XCTestCase {
    
    var localizationConfig: LocalizationConfig!
    
    override func setUp() {
        super.setUp()
        localizationConfig = LocalizationConfig()
    }
    
    override func tearDown() {
        localizationConfig = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testDefaultInitialization() {
        XCTAssertEqual(localizationConfig.appLanguage, .english)
        XCTAssertEqual(localizationConfig.numberSystem, .western)
        XCTAssertEqual(localizationConfig.dateFormat, .system)
        XCTAssertEqual(localizationConfig.weekStartDay, .monday)
        XCTAssertFalse(localizationConfig.isRTLEnabled)
    }
    
    func testAudienceSpecificConfiguration() {
        // Test Indian configuration
        let indianConfig = LocalizationConfig(forAudience: .indian)
        XCTAssertEqual(indianConfig.appLanguage, .english)
        XCTAssertEqual(indianConfig.region, "en_IN")
        XCTAssertEqual(indianConfig.numberSystem, .indian)
        XCTAssertTrue(indianConfig.useFinancialYear)
        XCTAssertEqual(indianConfig.weekStartDay, .monday)
        
        // Test American configuration
        let americanConfig = LocalizationConfig(forAudience: .american)
        XCTAssertEqual(americanConfig.appLanguage, .english)
        XCTAssertEqual(americanConfig.region, "en_US")
        XCTAssertEqual(americanConfig.numberSystem, .western)
        XCTAssertFalse(americanConfig.useFinancialYear)
        XCTAssertEqual(americanConfig.weekStartDay, .sunday)
        
        // Test German configuration
        let germanConfig = LocalizationConfig(forAudience: .german)
        XCTAssertEqual(germanConfig.appLanguage, .german)
        XCTAssertEqual(germanConfig.region, "de_DE")
        XCTAssertEqual(germanConfig.weekStartDay, .monday)
    }
    
    // MARK: - Language Tests
    
    func testAppLanguageProperties() {
        // Test English
        XCTAssertEqual(AppLanguage.english.displayName, "English")
        XCTAssertEqual(AppLanguage.english.languageCode, "en")
        XCTAssertFalse(AppLanguage.english.isRTL)
        
        // Test Hindi
        XCTAssertEqual(AppLanguage.hindi.displayName, "हिंदी")
        XCTAssertEqual(AppLanguage.hindi.languageCode, "hi")
        XCTAssertFalse(AppLanguage.hindi.isRTL)
        
        // Test Arabic (RTL)
        XCTAssertEqual(AppLanguage.arabic.displayName, "العربية")
        XCTAssertEqual(AppLanguage.arabic.languageCode, "ar")
        XCTAssertTrue(AppLanguage.arabic.isRTL)
        
        // Test other languages
        XCTAssertEqual(AppLanguage.tamil.displayName, "தமிழ்")
        XCTAssertEqual(AppLanguage.chinese.displayName, "中文")
        XCTAssertEqual(AppLanguage.japanese.displayName, "日本語")
    }
    
    func testRTLConfiguration() {
        localizationConfig.appLanguage = .arabic
        localizationConfig.configureForAudience(.indian) // This should update RTL setting
        
        XCTAssertTrue(localizationConfig.isRTLEnabled)
    }
    
    // MARK: - Number System Tests
    
    func testNumberSystemProperties() {
        XCTAssertEqual(NumberSystem.western.displayName, "Western (Million/Billion)")
        XCTAssertEqual(NumberSystem.indian.displayName, "Indian (Lakh/Crore)")
    }
    
    // MARK: - Date Format Tests
    
    func testDateFormatProperties() {
        XCTAssertEqual(LocalizationDateFormatStyle.system.displayName, "System Default")
        XCTAssertEqual(LocalizationDateFormatStyle.ddmmyyyy.displayName, "DD/MM/YYYY")
        XCTAssertEqual(LocalizationDateFormatStyle.mmddyyyy.displayName, "MM/DD/YYYY")
        XCTAssertEqual(LocalizationDateFormatStyle.yyyymmdd.displayName, "YYYY-MM-DD")
        XCTAssertEqual(LocalizationDateFormatStyle.relative.displayName, "Relative (2 days ago)")
    }
    
    // MARK: - Time Format Tests
    
    func testTimeFormatProperties() {
        XCTAssertEqual(TimeFormat.system.displayName, "System Default")
        XCTAssertEqual(TimeFormat.twelve.displayName, "12 Hour (AM/PM)")
        XCTAssertEqual(TimeFormat.twentyFour.displayName, "24 Hour")
    }
    
    // MARK: - Week Day Tests
    
    func testWeekDayProperties() {
        XCTAssertEqual(WeekDay.sunday.rawValue, 1)
        XCTAssertEqual(WeekDay.monday.rawValue, 2)
        XCTAssertEqual(WeekDay.saturday.rawValue, 7)
    }
    
    // MARK: - Calendar System Tests
    
    func testCalendarSystemProperties() {
        XCTAssertEqual(CalendarSystem.gregorian.displayName, "Gregorian")
        XCTAssertEqual(CalendarSystem.gregorian.identifier, .gregorian)
        
        XCTAssertEqual(CalendarSystem.islamic.displayName, "Islamic")
        XCTAssertEqual(CalendarSystem.islamic.identifier, .islamic)
        
        XCTAssertEqual(CalendarSystem.indian.displayName, "Indian National")
        XCTAssertEqual(CalendarSystem.indian.identifier, .indian)
    }
    
    // MARK: - Computed Properties Tests
    
    func testCurrentLocale() {
        localizationConfig.region = "en_IN"
        let locale = localizationConfig.currentLocale
        XCTAssertEqual(locale.identifier, "en_IN")
    }
    
    func testCurrentCalendar() {
        localizationConfig.calendarSystem = .gregorian
        localizationConfig.weekStartDay = .sunday
        
        let calendar = localizationConfig.currentCalendar
        XCTAssertEqual(calendar.identifier, .gregorian)
        XCTAssertEqual(calendar.firstWeekday, 1) // Sunday
    }
    
    // MARK: - Validation Tests
    
    func testValidConfiguration() {
        let issues = localizationConfig.validate()
        XCTAssertTrue(issues.isEmpty, "Default configuration should be valid")
    }
    
    func testInvalidRegionFormat() {
        localizationConfig.region = "invalid"
        let issues = localizationConfig.validate()
        XCTAssertTrue(issues.contains("Invalid region format"))
        
        localizationConfig.region = "en"
        let issues2 = localizationConfig.validate()
        XCTAssertTrue(issues2.contains("Invalid region format"))
    }
    
    func testRTLInconsistency() {
        localizationConfig.appLanguage = .english
        localizationConfig.isRTLEnabled = true
        
        let issues = localizationConfig.validate()
        XCTAssertTrue(issues.contains("RTL enabled for non-RTL language"))
    }
    
    // MARK: - Codable Tests
    
    func testCodableRoundTrip() throws {
        // Configure with non-default values
        localizationConfig.appLanguage = .hindi
        localizationConfig.region = "hi_IN"
        localizationConfig.numberSystem = .indian
        localizationConfig.useFinancialYear = true
        localizationConfig.weekStartDay = .sunday
        localizationConfig.voiceOverLanguage = "hi-IN"
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(localizationConfig)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(LocalizationConfig.self, from: data)
        
        // Verify
        XCTAssertEqual(decodedConfig.appLanguage, localizationConfig.appLanguage)
        XCTAssertEqual(decodedConfig.region, localizationConfig.region)
        XCTAssertEqual(decodedConfig.numberSystem, localizationConfig.numberSystem)
        XCTAssertEqual(decodedConfig.useFinancialYear, localizationConfig.useFinancialYear)
        XCTAssertEqual(decodedConfig.weekStartDay, localizationConfig.weekStartDay)
        XCTAssertEqual(decodedConfig.voiceOverLanguage, localizationConfig.voiceOverLanguage)
    }
    
    // MARK: - Configuration Consistency Tests
    
    func testConfigurationConsistency() {
        // Test that RTL is properly set for Arabic
        localizationConfig.appLanguage = .arabic
        localizationConfig.configureForAudience(.indian)
        XCTAssertTrue(localizationConfig.isRTLEnabled)
        
        // Test that financial year is set for Indian audience
        localizationConfig.configureForAudience(.indian)
        XCTAssertTrue(localizationConfig.useFinancialYear)
        
        // Test that financial year is not set for Western audiences
        localizationConfig.configureForAudience(.american)
        XCTAssertFalse(localizationConfig.useFinancialYear)
    }
    
    // MARK: - Edge Cases
    
    func testAllLanguagesHaveDisplayNames() {
        for language in AppLanguage.allCases {
            XCTAssertFalse(language.displayName.isEmpty, "Language \(language) should have a display name")
            XCTAssertFalse(language.languageCode.isEmpty, "Language \(language) should have a language code")
        }
    }
    
    func testAllNumberSystemsHaveDisplayNames() {
        for numberSystem in NumberSystem.allCases {
            XCTAssertFalse(numberSystem.displayName.isEmpty, "Number system \(numberSystem) should have a display name")
        }
    }
    
    func testAllDateFormatsHaveDisplayNames() {
        for dateFormat in LocalizationDateFormatStyle.allCases {
            XCTAssertFalse(dateFormat.displayName.isEmpty, "Date format \(dateFormat) should have a display name")
        }
    }
    
    func testAllTimeFormatsHaveDisplayNames() {
        for timeFormat in TimeFormat.allCases {
            XCTAssertFalse(timeFormat.displayName.isEmpty, "Time format \(timeFormat) should have a display name")
        }
    }
    
    func testAllCalendarSystemsHaveValidIdentifiers() {
        for calendarSystem in CalendarSystem.allCases {
            XCTAssertFalse(calendarSystem.displayName.isEmpty, "Calendar system \(calendarSystem) should have a display name")
            
            // Test that the identifier can create a valid calendar
            let calendar = Calendar(identifier: calendarSystem.identifier)
            XCTAssertEqual(calendar.identifier, calendarSystem.identifier)
        }
    }
    
    // MARK: - Performance Tests
    
    func testConfigurationPerformance() {
        measure {
            for audience in PrimaryAudience.allCases {
                let config = LocalizationConfig(forAudience: audience)
                _ = config.validate()
            }
        }
    }
    
    func testLocaleCreationPerformance() {
        localizationConfig.region = "en_US"
        
        measure {
            for _ in 0..<1000 {
                _ = localizationConfig.currentLocale
            }
        }
    }
}