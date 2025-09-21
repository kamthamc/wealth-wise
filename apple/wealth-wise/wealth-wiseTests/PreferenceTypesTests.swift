import XCTest
import Foundation
@testable import wealth_wise

final class PreferenceTypesTests: XCTestCase {
    
    // MARK: - AppTheme Tests
    
    func testAppThemeDisplayNames() {
        XCTAssertFalse(AppTheme.light.displayName.isEmpty)
        XCTAssertFalse(AppTheme.dark.displayName.isEmpty)
        XCTAssertFalse(AppTheme.system.displayName.isEmpty)
    }
    
    func testAppThemeCaseIterable() {
        let allCases = AppTheme.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.light))
        XCTAssertTrue(allCases.contains(.dark))
        XCTAssertTrue(allCases.contains(.system))
    }
    
    // MARK: - ColorScheme Tests
    
    func testColorSchemeDisplayNames() {
        XCTAssertFalse(ColorScheme.light.displayName.isEmpty)
        XCTAssertFalse(ColorScheme.dark.displayName.isEmpty)
        XCTAssertFalse(ColorScheme.system.displayName.isEmpty)
    }
    
    // MARK: - AccentColor Tests
    
    func testAccentColorDisplayNames() {
        for color in AccentColor.allCases {
            XCTAssertFalse(color.displayName.isEmpty, "Display name should not be empty for \(color)")
        }
    }
    
    func testAccentColorCaseCount() {
        XCTAssertEqual(AccentColor.allCases.count, 10)
    }
    
    // MARK: - CurrencyDisplayFormat Tests
    
    func testCurrencyDisplayFormatDisplayNames() {
        for format in CurrencyDisplayFormat.allCases {
            XCTAssertFalse(format.displayName.isEmpty, "Display name should not be empty for \(format)")
        }
    }
    
    // MARK: - NumberingSystem Tests
    
    func testNumberingSystemDisplayNames() {
        for system in NumberingSystem.allCases {
            XCTAssertFalse(system.displayName.isEmpty, "Display name should not be empty for \(system)")
        }
    }
    
    func testNumberingSystemDetection() {
        // Test locale-based detection
        let usLocale = Locale(identifier: "en_US")
        let numberingSystem = NumberingSystem.detectFromLocale()
        
        // Test that detection returns a valid system
        XCTAssertTrue(NumberingSystem.allCases.contains(numberingSystem))
    }
    
    func testNumberingSystemFormatting() {
        let testNumber = 1234567.89
        
        // Test Western formatting
        let westernFormatted = NumberingSystem.western.formatNumber(testNumber)
        XCTAssertFalse(westernFormatted.isEmpty)
        
        // Test Indian formatting
        let indianFormatted = NumberingSystem.indian.formatNumber(testNumber)
        XCTAssertFalse(indianFormatted.isEmpty)
        
        // Test that different systems produce different results
        XCTAssertNotEqual(westernFormatted, indianFormatted)
    }
    
    func testIndianNumberingSpecificCases() {
        let numberingSystem = NumberingSystem.indian
        
        // Test lakh formatting
        let lakhNumber = 123456.0
        let lakhFormatted = numberingSystem.formatNumber(lakhNumber)
        XCTAssertTrue(lakhFormatted.contains("L"), "Should contain 'L' for lakh: \(lakhFormatted)")
        
        // Test crore formatting
        let croreNumber = 12345678.0
        let croreFormatted = numberingSystem.formatNumber(croreNumber)
        XCTAssertTrue(croreFormatted.contains("Cr"), "Should contain 'Cr' for crore: \(croreFormatted)")
        
        // Test negative numbers
        let negativeNumber = -123456.0
        let negativeFormatted = numberingSystem.formatNumber(negativeNumber)
        XCTAssertTrue(negativeFormatted.hasPrefix("-"), "Should handle negative numbers: \(negativeFormatted)")
    }
    
    // MARK: - ExchangeRateUpdateFrequency Tests
    
    func testExchangeRateUpdateFrequencyDisplayNames() {
        for frequency in ExchangeRateUpdateFrequency.allCases {
            XCTAssertFalse(frequency.displayName.isEmpty, "Display name should not be empty for \(frequency)")
        }
    }
    
    func testExchangeRateUpdateIntervals() {
        XCTAssertEqual(ExchangeRateUpdateFrequency.realTime.updateInterval, 5)
        XCTAssertEqual(ExchangeRateUpdateFrequency.everyFiveMinutes.updateInterval, 300)
        XCTAssertEqual(ExchangeRateUpdateFrequency.everyFifteenMinutes.updateInterval, 900)
        XCTAssertEqual(ExchangeRateUpdateFrequency.hourly.updateInterval, 3600)
        XCTAssertEqual(ExchangeRateUpdateFrequency.daily.updateInterval, 86400)
        XCTAssertEqual(ExchangeRateUpdateFrequency.weekly.updateInterval, 604800)
        XCTAssertNil(ExchangeRateUpdateFrequency.manual.updateInterval)
    }
    
    // MARK: - FontSize Tests
    
    func testFontSizeDisplayNames() {
        for fontSize in FontSize.allCases {
            XCTAssertFalse(fontSize.displayName.isEmpty, "Display name should not be empty for \(fontSize)")
        }
    }
    
    func testFontSizeScaleFactors() {
        XCTAssertEqual(FontSize.extraSmall.scaleFactor, 0.8)
        XCTAssertEqual(FontSize.small.scaleFactor, 0.9)
        XCTAssertEqual(FontSize.medium.scaleFactor, 1.0)
        XCTAssertEqual(FontSize.large.scaleFactor, 1.15)
        XCTAssertEqual(FontSize.extraLarge.scaleFactor, 1.3)
        XCTAssertEqual(FontSize.accessibility1.scaleFactor, 1.5)
        XCTAssertEqual(FontSize.accessibility2.scaleFactor, 1.75)
        XCTAssertEqual(FontSize.accessibility3.scaleFactor, 2.0)
    }
    
    func testFontSizeProgression() {
        let sizes = FontSize.allCases
        for i in 1..<sizes.count {
            XCTAssertGreaterThan(sizes[i].scaleFactor, sizes[i-1].scaleFactor, 
                               "Font sizes should be in ascending order")
        }
    }
    
    // MARK: - HapticFeedbackLevel Tests
    
    func testHapticFeedbackLevelDisplayNames() {
        for level in HapticFeedbackLevel.allCases {
            XCTAssertFalse(level.displayName.isEmpty, "Display name should not be empty for \(level)")
        }
    }
    
    // MARK: - CloudBackupService Tests
    
    func testCloudBackupServiceDisplayNames() {
        for service in CloudBackupService.allCases {
            XCTAssertFalse(service.displayName.isEmpty, "Display name should not be empty for \(service)")
        }
    }
    
    func testCloudBackupServicePlatformDetection() {
        let detectedService = CloudBackupService.detectFromPlatform()
        XCTAssertTrue(CloudBackupService.allCases.contains(detectedService))
        
        #if os(iOS) || os(macOS)
        XCTAssertEqual(detectedService, .iCloud)
        #elseif os(Windows)
        XCTAssertEqual(detectedService, .oneDrive)
        #else
        XCTAssertEqual(detectedService, .none)
        #endif
    }
    
    // MARK: - DataRetentionPeriod Tests
    
    func testDataRetentionPeriodDisplayNames() {
        for period in DataRetentionPeriod.allCases {
            XCTAssertFalse(period.displayName.isEmpty, "Display name should not be empty for \(period)")
        }
    }
    
    func testDataRetentionPeriodTimeIntervals() {
        XCTAssertEqual(DataRetentionPeriod.oneYear.timeInterval, 365 * 24 * 60 * 60)
        XCTAssertEqual(DataRetentionPeriod.twoYears.timeInterval, 2 * 365 * 24 * 60 * 60)
        XCTAssertEqual(DataRetentionPeriod.threeYears.timeInterval, 3 * 365 * 24 * 60 * 60)
        XCTAssertEqual(DataRetentionPeriod.fiveYears.timeInterval, 5 * 365 * 24 * 60 * 60)
        XCTAssertEqual(DataRetentionPeriod.sevenYears.timeInterval, 7 * 365 * 24 * 60 * 60)
        XCTAssertEqual(DataRetentionPeriod.tenYears.timeInterval, 10 * 365 * 24 * 60 * 60)
        XCTAssertNil(DataRetentionPeriod.indefinite.timeInterval)
    }
    
    // MARK: - AutoLockTimeout Tests
    
    func testAutoLockTimeoutDisplayNames() {
        for timeout in AutoLockTimeout.allCases {
            XCTAssertFalse(timeout.displayName.isEmpty, "Display name should not be empty for \(timeout)")
        }
    }
    
    func testAutoLockTimeoutIntervals() {
        XCTAssertEqual(AutoLockTimeout.immediate.timeInterval, 0)
        XCTAssertEqual(AutoLockTimeout.thirtySeconds.timeInterval, 30)
        XCTAssertEqual(AutoLockTimeout.oneMinute.timeInterval, 60)
        XCTAssertEqual(AutoLockTimeout.twoMinutes.timeInterval, 120)
        XCTAssertEqual(AutoLockTimeout.fiveMinutes.timeInterval, 300)
        XCTAssertEqual(AutoLockTimeout.tenMinutes.timeInterval, 600)
        XCTAssertEqual(AutoLockTimeout.fifteenMinutes.timeInterval, 900)
        XCTAssertEqual(AutoLockTimeout.thirtyMinutes.timeInterval, 1800)
        XCTAssertEqual(AutoLockTimeout.oneHour.timeInterval, 3600)
        XCTAssertNil(AutoLockTimeout.never.timeInterval)
    }
    
    // MARK: - DateFormatStyle Tests
    
    func testDateFormatStyleDisplayNames() {
        for format in DateFormatStyle.allCases {
            XCTAssertFalse(format.displayName.isEmpty, "Display name should not be empty for \(format)")
        }
    }
    
    func testDateFormatStrings() {
        XCTAssertEqual(DateFormatStyle.mdy.dateFormat, "MM/dd/yyyy")
        XCTAssertEqual(DateFormatStyle.dmy.dateFormat, "dd/MM/yyyy")
        XCTAssertEqual(DateFormatStyle.ymd.dateFormat, "yyyy/MM/dd")
        XCTAssertEqual(DateFormatStyle.dmyDash.dateFormat, "dd-MM-yyyy")
        XCTAssertEqual(DateFormatStyle.ymdDash.dateFormat, "yyyy-MM-dd")
        XCTAssertEqual(DateFormatStyle.dmyDot.dateFormat, "dd.MM.yyyy")
    }
    
    // MARK: - TimeFormat Tests
    
    func testTimeFormatDisplayNames() {
        XCTAssertFalse(TimeFormat.twelve.displayName.isEmpty)
        XCTAssertFalse(TimeFormat.twentyFour.displayName.isEmpty)
    }
    
    // MARK: - Weekday Tests
    
    func testWeekdayDisplayNames() {
        for weekday in Weekday.allCases {
            XCTAssertFalse(weekday.displayName.isEmpty, "Display name should not be empty for \(weekday)")
        }
    }
    
    func testWeekdayRawValues() {
        XCTAssertEqual(Weekday.sunday.rawValue, 1)
        XCTAssertEqual(Weekday.monday.rawValue, 2)
        XCTAssertEqual(Weekday.tuesday.rawValue, 3)
        XCTAssertEqual(Weekday.wednesday.rawValue, 4)
        XCTAssertEqual(Weekday.thursday.rawValue, 5)
        XCTAssertEqual(Weekday.friday.rawValue, 6)
        XCTAssertEqual(Weekday.saturday.rawValue, 7)
    }
    
    // MARK: - FinancialYearStart Tests
    
    func testFinancialYearStartDisplayNames() {
        for start in FinancialYearStart.allCases {
            XCTAssertFalse(start.displayName.isEmpty, "Display name should not be empty for \(start)")
        }
    }
    
    func testFinancialYearStartMonthNumbers() {
        XCTAssertEqual(FinancialYearStart.january.monthNumber, 1)
        XCTAssertEqual(FinancialYearStart.april.monthNumber, 4)
        XCTAssertEqual(FinancialYearStart.july.monthNumber, 7)
        XCTAssertEqual(FinancialYearStart.october.monthNumber, 10)
    }
    
    func testFinancialYearDateCalculations() {
        let calendar = Calendar.current
        let year = 2024
        
        // Test January start
        let januaryStart = FinancialYearStart.january
        let januaryStartDate = januaryStart.startDate(for: year)
        let januaryStartComponents = calendar.dateComponents([.year, .month, .day], from: januaryStartDate)
        XCTAssertEqual(januaryStartComponents.year, year)
        XCTAssertEqual(januaryStartComponents.month, 1)
        XCTAssertEqual(januaryStartComponents.day, 1)
        
        let januaryEndDate = januaryStart.endDate(for: year)
        let januaryEndComponents = calendar.dateComponents([.year, .month, .day], from: januaryEndDate)
        XCTAssertEqual(januaryEndComponents.year, year + 1)
        XCTAssertEqual(januaryEndComponents.month, 12)
        XCTAssertEqual(januaryEndComponents.day, 31)
        
        // Test April start (Indian financial year)
        let aprilStart = FinancialYearStart.april
        let aprilStartDate = aprilStart.startDate(for: year)
        let aprilStartComponents = calendar.dateComponents([.year, .month, .day], from: aprilStartDate)
        XCTAssertEqual(aprilStartComponents.year, year)
        XCTAssertEqual(aprilStartComponents.month, 4)
        XCTAssertEqual(aprilStartComponents.day, 1)
        
        let aprilEndDate = aprilStart.endDate(for: year)
        let aprilEndComponents = calendar.dateComponents([.year, .month, .day], from: aprilEndDate)
        XCTAssertEqual(aprilEndComponents.year, year + 1)
        XCTAssertEqual(aprilEndComponents.month, 3)
        XCTAssertEqual(aprilEndComponents.day, 31)
    }
    
    // MARK: - Codability Tests
    
    func testEnumCodability() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test AppTheme
        let appTheme = AppTheme.dark
        let appThemeData = try! encoder.encode(appTheme)
        let decodedAppTheme = try! decoder.decode(AppTheme.self, from: appThemeData)
        XCTAssertEqual(appTheme, decodedAppTheme)
        
        // Test CurrencyDisplayFormat
        let currencyFormat = CurrencyDisplayFormat.compact
        let currencyFormatData = try! encoder.encode(currencyFormat)
        let decodedCurrencyFormat = try! decoder.decode(CurrencyDisplayFormat.self, from: currencyFormatData)
        XCTAssertEqual(currencyFormat, decodedCurrencyFormat)
        
        // Test FontSize
        let fontSize = FontSize.large
        let fontSizeData = try! encoder.encode(fontSize)
        let decodedFontSize = try! decoder.decode(FontSize.self, from: fontSizeData)
        XCTAssertEqual(fontSize, decodedFontSize)
        
        // Test AutoLockTimeout
        let autoLockTimeout = AutoLockTimeout.fiveMinutes
        let autoLockTimeoutData = try! encoder.encode(autoLockTimeout)
        let decodedAutoLockTimeout = try! decoder.decode(AutoLockTimeout.self, from: autoLockTimeoutData)
        XCTAssertEqual(autoLockTimeout, decodedAutoLockTimeout)
        
        // Test FinancialYearStart
        let financialYearStart = FinancialYearStart.april
        let financialYearStartData = try! encoder.encode(financialYearStart)
        let decodedFinancialYearStart = try! decoder.decode(FinancialYearStart.self, from: financialYearStartData)
        XCTAssertEqual(financialYearStart, decodedFinancialYearStart)
    }
}