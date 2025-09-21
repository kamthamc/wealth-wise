import XCTest
import Foundation
@testable import wealth_wise

final class UserPreferencesTests: XCTestCase {
    
    var userDefaults: UserDefaults!
    var userPreferences: UserPreferences!
    
    override func setUp() {
        super.setUp()
        // Use a test-specific UserDefaults suite to avoid affecting actual preferences
        userDefaults = UserDefaults(suiteName: "test.WealthWise.UserPreferences")!
        userDefaults.removePersistentDomain(forName: "test.WealthWise.UserPreferences")
        userPreferences = UserPreferences(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "test.WealthWise.UserPreferences")
        userDefaults = nil
        userPreferences = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitializationWithDefaults() {
        XCTAssertEqual(userPreferences.appTheme, .system)
        XCTAssertEqual(userPreferences.colorScheme, .system)
        XCTAssertEqual(userPreferences.accentColor, .blue)
        XCTAssertTrue(userPreferences.useSystemAppearance)
        
        // Currency defaults should be based on current locale
        let expectedCurrency = SupportedCurrency.preferredCurrency(for: Locale.current)
        XCTAssertEqual(userPreferences.baseCurrency, expectedCurrency)
        XCTAssertEqual(userPreferences.displayCurrencies, [expectedCurrency])
        XCTAssertEqual(userPreferences.currencyDisplayFormat, .standard)
        
        // Accessibility defaults
        XCTAssertEqual(userPreferences.fontSize, .medium)
        XCTAssertFalse(userPreferences.useHighContrast)
        XCTAssertFalse(userPreferences.reduceMotion)
        XCTAssertFalse(userPreferences.voiceOverEnabled)
        XCTAssertEqual(userPreferences.hapticFeedback, .medium)
        
        // Data & Privacy defaults
        XCTAssertTrue(userPreferences.dataBackupEnabled)
        XCTAssertEqual(userPreferences.cloudBackupService, .detectFromPlatform())
        XCTAssertFalse(userPreferences.analyticsEnabled)
        XCTAssertTrue(userPreferences.crashReportingEnabled)
        XCTAssertEqual(userPreferences.dataRetentionPeriod, .fiveYears)
        
        // Notification defaults
        XCTAssertTrue(userPreferences.notificationsEnabled)
        XCTAssertTrue(userPreferences.budgetAlerts)
        XCTAssertTrue(userPreferences.billReminders)
        XCTAssertFalse(userPreferences.investmentUpdates)
        XCTAssertFalse(userPreferences.exchangeRateAlerts)
        
        // Security defaults
        XCTAssertTrue(userPreferences.biometricAuthEnabled)
        XCTAssertTrue(userPreferences.autoLockEnabled)
        XCTAssertEqual(userPreferences.autoLockTimeout, .fiveMinutes)
        XCTAssertTrue(userPreferences.requireAuthForSensitiveData)
        
        // Regional defaults should be based on current country
        let expectedCountry = SupportedCountries.preferredCountry(for: Locale.current)
        XCTAssertEqual(userPreferences.dateFormat, expectedCountry.culturalPreferences.dateFormat)
        XCTAssertEqual(userPreferences.timeFormat, expectedCountry.culturalPreferences.timeFormat)
        XCTAssertEqual(userPreferences.firstDayOfWeek, expectedCountry.culturalPreferences.weekStartsOn)
        XCTAssertEqual(userPreferences.financialYearStart, expectedCountry.financialYearStart)
    }
    
    // MARK: - Theme & Appearance Tests
    
    func testThemeChanges() {
        // Test theme changes are persisted
        userPreferences.appTheme = .dark
        XCTAssertEqual(userPreferences.appTheme, .dark)
        
        // Create new instance to verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.appTheme, .dark)
    }
    
    func testColorSchemeChanges() {
        userPreferences.colorScheme = .light
        XCTAssertEqual(userPreferences.colorScheme, .light)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.colorScheme, .light)
    }
    
    func testAccentColorChanges() {
        userPreferences.accentColor = .green
        XCTAssertEqual(userPreferences.accentColor, .green)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.accentColor, .green)
    }
    
    // MARK: - Currency Tests
    
    func testBaseCurrencyChanges() {
        userPreferences.baseCurrency = .eur
        XCTAssertEqual(userPreferences.baseCurrency, .eur)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.baseCurrency, .eur)
    }
    
    func testDisplayCurrencies() {
        let currencies: [SupportedCurrency] = [.usd, .eur, .gbp]
        userPreferences.displayCurrencies = currencies
        XCTAssertEqual(userPreferences.displayCurrencies, currencies)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.displayCurrencies, currencies)
    }
    
    func testCurrencyDisplayFormat() {
        userPreferences.currencyDisplayFormat = .compact
        XCTAssertEqual(userPreferences.currencyDisplayFormat, .compact)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.currencyDisplayFormat, .compact)
    }
    
    func testNumberingSystem() {
        userPreferences.numberingSystem = .indian
        XCTAssertEqual(userPreferences.numberingSystem, .indian)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.numberingSystem, .indian)
    }
    
    // MARK: - Accessibility Tests
    
    func testFontSizeChanges() {
        userPreferences.fontSize = .large
        XCTAssertEqual(userPreferences.fontSize, .large)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.fontSize, .large)
    }
    
    func testAccessibilityFlags() {
        userPreferences.useHighContrast = true
        userPreferences.reduceMotion = true
        userPreferences.voiceOverEnabled = true
        
        XCTAssertTrue(userPreferences.useHighContrast)
        XCTAssertTrue(userPreferences.reduceMotion)
        XCTAssertTrue(userPreferences.voiceOverEnabled)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertTrue(newPreferences.useHighContrast)
        XCTAssertTrue(newPreferences.reduceMotion)
        XCTAssertTrue(newPreferences.voiceOverEnabled)
    }
    
    func testHapticFeedbackLevel() {
        userPreferences.hapticFeedback = .strong
        XCTAssertEqual(userPreferences.hapticFeedback, .strong)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.hapticFeedback, .strong)
    }
    
    // MARK: - Data & Privacy Tests
    
    func testDataBackupSettings() {
        userPreferences.dataBackupEnabled = false
        userPreferences.cloudBackupService = .googleDrive
        
        XCTAssertFalse(userPreferences.dataBackupEnabled)
        XCTAssertEqual(userPreferences.cloudBackupService, .googleDrive)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertFalse(newPreferences.dataBackupEnabled)
        XCTAssertEqual(newPreferences.cloudBackupService, .googleDrive)
    }
    
    func testAnalyticsSettings() {
        userPreferences.analyticsEnabled = true
        userPreferences.crashReportingEnabled = false
        
        XCTAssertTrue(userPreferences.analyticsEnabled)
        XCTAssertFalse(userPreferences.crashReportingEnabled)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertTrue(newPreferences.analyticsEnabled)
        XCTAssertFalse(newPreferences.crashReportingEnabled)
    }
    
    func testDataRetentionPeriod() {
        userPreferences.dataRetentionPeriod = .sevenYears
        XCTAssertEqual(userPreferences.dataRetentionPeriod, .sevenYears)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.dataRetentionPeriod, .sevenYears)
    }
    
    // MARK: - Notification Tests
    
    func testNotificationSettings() {
        userPreferences.notificationsEnabled = false
        userPreferences.budgetAlerts = false
        userPreferences.billReminders = false
        userPreferences.investmentUpdates = true
        userPreferences.exchangeRateAlerts = true
        
        XCTAssertFalse(userPreferences.notificationsEnabled)
        XCTAssertFalse(userPreferences.budgetAlerts)
        XCTAssertFalse(userPreferences.billReminders)
        XCTAssertTrue(userPreferences.investmentUpdates)
        XCTAssertTrue(userPreferences.exchangeRateAlerts)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertFalse(newPreferences.notificationsEnabled)
        XCTAssertFalse(newPreferences.budgetAlerts)
        XCTAssertFalse(newPreferences.billReminders)
        XCTAssertTrue(newPreferences.investmentUpdates)
        XCTAssertTrue(newPreferences.exchangeRateAlerts)
    }
    
    // MARK: - Security Tests
    
    func testSecuritySettings() {
        userPreferences.biometricAuthEnabled = false
        userPreferences.autoLockEnabled = false
        userPreferences.autoLockTimeout = .oneHour
        userPreferences.requireAuthForSensitiveData = false
        
        XCTAssertFalse(userPreferences.biometricAuthEnabled)
        XCTAssertFalse(userPreferences.autoLockEnabled)
        XCTAssertEqual(userPreferences.autoLockTimeout, .oneHour)
        XCTAssertFalse(userPreferences.requireAuthForSensitiveData)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertFalse(newPreferences.biometricAuthEnabled)
        XCTAssertFalse(newPreferences.autoLockEnabled)
        XCTAssertEqual(newPreferences.autoLockTimeout, .oneHour)
        XCTAssertFalse(newPreferences.requireAuthForSensitiveData)
    }
    
    // MARK: - Smart Features Tests
    
    func testSmartFeatureSettings() {
        userPreferences.smartCategorizationEnabled = false
        userPreferences.smartInsightsEnabled = false
        userPreferences.naturalLanguageProcessing = false
        userPreferences.onDeviceProcessingOnly = false
        
        XCTAssertFalse(userPreferences.smartCategorizationEnabled)
        XCTAssertFalse(userPreferences.smartInsightsEnabled)
        XCTAssertFalse(userPreferences.naturalLanguageProcessing)
        XCTAssertFalse(userPreferences.onDeviceProcessingOnly)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertFalse(newPreferences.smartCategorizationEnabled)
        XCTAssertFalse(newPreferences.smartInsightsEnabled)
        XCTAssertFalse(newPreferences.naturalLanguageProcessing)
        XCTAssertFalse(newPreferences.onDeviceProcessingOnly)
    }
    
    // MARK: - Regional Settings Tests
    
    func testRegionalSettings() {
        userPreferences.dateFormat = .ymd
        userPreferences.timeFormat = .twentyFour
        userPreferences.firstDayOfWeek = .monday
        userPreferences.financialYearStart = .april
        
        XCTAssertEqual(userPreferences.dateFormat, .ymd)
        XCTAssertEqual(userPreferences.timeFormat, .twentyFour)
        XCTAssertEqual(userPreferences.firstDayOfWeek, .monday)
        XCTAssertEqual(userPreferences.financialYearStart, .april)
        
        // Verify persistence
        let newPreferences = UserPreferences(userDefaults: userDefaults)
        XCTAssertEqual(newPreferences.dateFormat, .ymd)
        XCTAssertEqual(newPreferences.timeFormat, .twentyFour)
        XCTAssertEqual(newPreferences.firstDayOfWeek, .monday)
        XCTAssertEqual(newPreferences.financialYearStart, .april)
    }
    
    // MARK: - Convenience Methods Tests
    
    func testResetToDefaults() {
        // Modify preferences
        userPreferences.appTheme = .dark
        userPreferences.baseCurrency = .eur
        userPreferences.fontSize = .large
        userPreferences.dataBackupEnabled = false
        
        // Reset to defaults
        userPreferences.resetToDefaults()
        
        // Verify defaults are restored
        XCTAssertEqual(userPreferences.appTheme, .system)
        XCTAssertEqual(userPreferences.baseCurrency, SupportedCurrency.preferredCurrency(for: Locale.current))
        XCTAssertEqual(userPreferences.fontSize, .medium)
        XCTAssertTrue(userPreferences.dataBackupEnabled)
    }
    
    func testUpdateForCountry() {
        let country = SupportedCountries.india
        
        userPreferences.updateForCountry(country)
        
        XCTAssertEqual(userPreferences.baseCurrency, country.primaryCurrency)
        XCTAssertEqual(userPreferences.numberingSystem, country.numberingSystem)
        XCTAssertEqual(userPreferences.dateFormat, country.culturalPreferences.dateFormat)
        XCTAssertEqual(userPreferences.timeFormat, country.culturalPreferences.timeFormat)
        XCTAssertEqual(userPreferences.firstDayOfWeek, country.culturalPreferences.weekStartsOn)
        XCTAssertEqual(userPreferences.financialYearStart, country.financialYearStart)
    }
    
    func testImportExportPreferences() {
        // Modify preferences
        userPreferences.appTheme = .dark
        userPreferences.baseCurrency = .eur
        userPreferences.fontSize = .large
        
        // Export preferences
        let exported = userPreferences.exportPreferences()
        XCTAssertFalse(exported.isEmpty)
        
        // Create new preferences instance and import
        let newUserDefaults = UserDefaults(suiteName: "test.WealthWise.Import")!
        newUserDefaults.removePersistentDomain(forName: "test.WealthWise.Import")
        let newPreferences = UserPreferences(userDefaults: newUserDefaults)
        
        // Import preferences
        newPreferences.importPreferences(exported)
        
        // Verify import worked
        XCTAssertEqual(newPreferences.appTheme, .dark)
        XCTAssertEqual(newPreferences.baseCurrency, .eur)
        XCTAssertEqual(newPreferences.fontSize, .large)
        
        // Clean up
        newUserDefaults.removePersistentDomain(forName: "test.WealthWise.Import")
    }
    
    func testImportFromAnotherPreferences() {
        // Create source preferences
        let sourceUserDefaults = UserDefaults(suiteName: "test.WealthWise.Source")!
        sourceUserDefaults.removePersistentDomain(forName: "test.WealthWise.Source")
        let sourcePreferences = UserPreferences(userDefaults: sourceUserDefaults)
        
        // Modify source preferences
        sourcePreferences.appTheme = .light
        sourcePreferences.baseCurrency = .gbp
        sourcePreferences.fontSize = .extraLarge
        
        // Import to target preferences
        userPreferences.importFrom(sourcePreferences)
        
        // Verify import
        XCTAssertEqual(userPreferences.appTheme, .light)
        XCTAssertEqual(userPreferences.baseCurrency, .gbp)
        XCTAssertEqual(userPreferences.fontSize, .extraLarge)
        
        // Clean up
        sourceUserDefaults.removePersistentDomain(forName: "test.WealthWise.Source")
    }
    
    // MARK: - Performance Tests
    
    func testPreferenceChangePerformance() {
        measure {
            for _ in 0..<1000 {
                userPreferences.appTheme = .dark
                userPreferences.appTheme = .light
                userPreferences.baseCurrency = .eur
                userPreferences.baseCurrency = .usd
                userPreferences.fontSize = .large
                userPreferences.fontSize = .small
            }
        }
    }
    
    func testInitializationPerformance() {
        measure {
            for _ in 0..<100 {
                let testDefaults = UserDefaults(suiteName: "test.performance")!
                let _ = UserPreferences(userDefaults: testDefaults)
                testDefaults.removePersistentDomain(forName: "test.performance")
            }
        }
    }
}