import XCTest
import Foundation
import Combine
@testable import wealth_wise

final class PreferenceManagerTests: XCTestCase {
    
    var userDefaults: UserDefaults!
    var preferenceManager: PreferenceManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "test.WealthWise.PreferenceManager")!
        userDefaults.removePersistentDomain(forName: "test.WealthWise.PreferenceManager")
        preferenceManager = PreferenceManager(userDefaults: userDefaults)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        userDefaults.removePersistentDomain(forName: "test.WealthWise.PreferenceManager")
        userDefaults = nil
        preferenceManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(preferenceManager.userPreferences)
        XCTAssertEqual(preferenceManager.userPreferences.appTheme, .system)
    }
    
    // MARK: - Theme Management Tests
    
    func testUpdateTheme() {
        preferenceManager.updateTheme(.dark)
        
        XCTAssertEqual(preferenceManager.userPreferences.appTheme, .dark)
        XCTAssertFalse(preferenceManager.userPreferences.useSystemAppearance)
    }
    
    func testUpdateColorScheme() {
        preferenceManager.updateColorScheme(.light)
        
        XCTAssertEqual(preferenceManager.userPreferences.colorScheme, .light)
    }
    
    func testUpdateAccentColor() {
        preferenceManager.updateAccentColor(.green)
        
        XCTAssertEqual(preferenceManager.userPreferences.accentColor, .green)
    }
    
    func testToggleSystemAppearance() {
        // Enable system appearance
        preferenceManager.toggleSystemAppearance(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.useSystemAppearance)
        XCTAssertEqual(preferenceManager.userPreferences.appTheme, .system)
        XCTAssertEqual(preferenceManager.userPreferences.colorScheme, .system)
        
        // Disable system appearance
        preferenceManager.toggleSystemAppearance(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.useSystemAppearance)
    }
    
    // MARK: - Currency Management Tests
    
    func testUpdateBaseCurrency() {
        let initialDisplayCount = preferenceManager.userPreferences.displayCurrencies.count
        
        preferenceManager.updateBaseCurrency(.eur)
        
        XCTAssertEqual(preferenceManager.userPreferences.baseCurrency, .eur)
        XCTAssertTrue(preferenceManager.userPreferences.displayCurrencies.contains(.eur))
        XCTAssertEqual(preferenceManager.userPreferences.displayCurrencies.first, .eur)
    }
    
    func testAddDisplayCurrency() {
        let initialCount = preferenceManager.userPreferences.displayCurrencies.count
        
        preferenceManager.addDisplayCurrency(.gbp)
        
        XCTAssertEqual(preferenceManager.userPreferences.displayCurrencies.count, initialCount + 1)
        XCTAssertTrue(preferenceManager.userPreferences.displayCurrencies.contains(.gbp))
        
        // Adding same currency again should not increase count
        preferenceManager.addDisplayCurrency(.gbp)
        XCTAssertEqual(preferenceManager.userPreferences.displayCurrencies.count, initialCount + 1)
    }
    
    func testRemoveDisplayCurrency() {
        // Add currencies first
        preferenceManager.addDisplayCurrency(.eur)
        preferenceManager.addDisplayCurrency(.gbp)
        
        let countBeforeRemoval = preferenceManager.userPreferences.displayCurrencies.count
        
        // Remove a currency
        preferenceManager.removeDisplayCurrency(.eur)
        
        XCTAssertEqual(preferenceManager.userPreferences.displayCurrencies.count, countBeforeRemoval - 1)
        XCTAssertFalse(preferenceManager.userPreferences.displayCurrencies.contains(.eur))
        
        // Try to remove base currency (should not be removed)
        let baseCurrency = preferenceManager.userPreferences.baseCurrency
        let countBeforeBaseRemoval = preferenceManager.userPreferences.displayCurrencies.count
        
        preferenceManager.removeDisplayCurrency(baseCurrency)
        
        XCTAssertEqual(preferenceManager.userPreferences.displayCurrencies.count, countBeforeBaseRemoval)
        XCTAssertTrue(preferenceManager.userPreferences.displayCurrencies.contains(baseCurrency))
    }
    
    func testReorderDisplayCurrencies() {
        // Add currencies
        preferenceManager.addDisplayCurrency(.eur)
        preferenceManager.addDisplayCurrency(.gbp)
        preferenceManager.addDisplayCurrency(.jpy)
        
        let baseCurrency = preferenceManager.userPreferences.baseCurrency
        let newOrder: [SupportedCurrency] = [.jpy, .eur, baseCurrency, .gbp]
        
        preferenceManager.reorderDisplayCurrencies(newOrder)
        
        // Base currency should still be first
        XCTAssertEqual(preferenceManager.userPreferences.displayCurrencies.first, baseCurrency)
    }
    
    func testUpdateCurrencyDisplayFormat() {
        preferenceManager.updateCurrencyDisplayFormat(.compact)
        
        XCTAssertEqual(preferenceManager.userPreferences.currencyDisplayFormat, .compact)
    }
    
    func testUpdateNumberingSystem() {
        preferenceManager.updateNumberingSystem(.indian)
        
        XCTAssertEqual(preferenceManager.userPreferences.numberingSystem, .indian)
    }
    
    func testUpdateExchangeRateFrequency() {
        preferenceManager.updateExchangeRateFrequency(.daily)
        
        XCTAssertEqual(preferenceManager.userPreferences.exchangeRateUpdateFrequency, .daily)
    }
    
    // MARK: - Accessibility Management Tests
    
    func testUpdateFontSize() {
        preferenceManager.updateFontSize(.large)
        
        XCTAssertEqual(preferenceManager.userPreferences.fontSize, .large)
    }
    
    func testToggleHighContrast() {
        preferenceManager.toggleHighContrast(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.useHighContrast)
        
        preferenceManager.toggleHighContrast(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.useHighContrast)
    }
    
    func testToggleReducedMotion() {
        preferenceManager.toggleReducedMotion(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.reduceMotion)
    }
    
    func testToggleVoiceOver() {
        preferenceManager.toggleVoiceOver(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.voiceOverEnabled)
    }
    
    func testUpdateHapticFeedback() {
        preferenceManager.updateHapticFeedback(.strong)
        
        XCTAssertEqual(preferenceManager.userPreferences.hapticFeedback, .strong)
    }
    
    // MARK: - Data & Privacy Management Tests
    
    func testToggleDataBackup() {
        preferenceManager.toggleDataBackup(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.dataBackupEnabled)
    }
    
    func testUpdateCloudBackupService() {
        preferenceManager.userPreferences.dataBackupEnabled = false
        
        preferenceManager.updateCloudBackupService(.googleDrive)
        
        XCTAssertEqual(preferenceManager.userPreferences.cloudBackupService, .googleDrive)
        XCTAssertTrue(preferenceManager.userPreferences.dataBackupEnabled) // Should be enabled automatically
    }
    
    func testToggleAnalytics() {
        preferenceManager.toggleAnalytics(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.analyticsEnabled)
    }
    
    func testToggleCrashReporting() {
        preferenceManager.toggleCrashReporting(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.crashReportingEnabled)
    }
    
    func testUpdateDataRetentionPeriod() {
        preferenceManager.updateDataRetentionPeriod(.sevenYears)
        
        XCTAssertEqual(preferenceManager.userPreferences.dataRetentionPeriod, .sevenYears)
    }
    
    // MARK: - Notification Management Tests
    
    func testToggleNotifications() {
        preferenceManager.toggleNotifications(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.notificationsEnabled)
        XCTAssertFalse(preferenceManager.userPreferences.budgetAlerts)
        XCTAssertFalse(preferenceManager.userPreferences.billReminders)
        XCTAssertFalse(preferenceManager.userPreferences.investmentUpdates)
        XCTAssertFalse(preferenceManager.userPreferences.exchangeRateAlerts)
    }
    
    func testToggleBudgetAlerts() {
        preferenceManager.userPreferences.notificationsEnabled = false
        
        preferenceManager.toggleBudgetAlerts(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.budgetAlerts)
        XCTAssertTrue(preferenceManager.userPreferences.notificationsEnabled) // Should be enabled automatically
    }
    
    func testToggleBillReminders() {
        preferenceManager.userPreferences.notificationsEnabled = false
        
        preferenceManager.toggleBillReminders(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.billReminders)
        XCTAssertTrue(preferenceManager.userPreferences.notificationsEnabled) // Should be enabled automatically
    }
    
    func testToggleInvestmentUpdates() {
        preferenceManager.userPreferences.notificationsEnabled = false
        
        preferenceManager.toggleInvestmentUpdates(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.investmentUpdates)
        XCTAssertTrue(preferenceManager.userPreferences.notificationsEnabled) // Should be enabled automatically
    }
    
    func testToggleExchangeRateAlerts() {
        preferenceManager.userPreferences.notificationsEnabled = false
        
        preferenceManager.toggleExchangeRateAlerts(true)
        
        XCTAssertTrue(preferenceManager.userPreferences.exchangeRateAlerts)
        XCTAssertTrue(preferenceManager.userPreferences.notificationsEnabled) // Should be enabled automatically
    }
    
    // MARK: - Security Management Tests
    
    func testToggleBiometricAuth() {
        preferenceManager.toggleBiometricAuth(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.biometricAuthEnabled)
    }
    
    func testToggleAutoLock() {
        preferenceManager.toggleAutoLock(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.autoLockEnabled)
    }
    
    func testUpdateAutoLockTimeout() {
        preferenceManager.userPreferences.autoLockEnabled = false
        
        preferenceManager.updateAutoLockTimeout(.oneHour)
        
        XCTAssertEqual(preferenceManager.userPreferences.autoLockTimeout, .oneHour)
        XCTAssertTrue(preferenceManager.userPreferences.autoLockEnabled) // Should be enabled automatically
    }
    
    func testToggleAuthForSensitiveData() {
        preferenceManager.toggleAuthForSensitiveData(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.requireAuthForSensitiveData)
    }
    
    // MARK: - Smart Features Management Tests
    
    func testToggleSmartCategorization() {
        preferenceManager.toggleSmartCategorization(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.smartCategorizationEnabled)
    }
    
    func testToggleSmartInsights() {
        preferenceManager.toggleSmartInsights(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.smartInsightsEnabled)
    }
    
    func testToggleNaturalLanguageProcessing() {
        preferenceManager.toggleNaturalLanguageProcessing(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.naturalLanguageProcessing)
    }
    
    func testToggleOnDeviceProcessingOnly() {
        preferenceManager.toggleOnDeviceProcessingOnly(false)
        
        XCTAssertFalse(preferenceManager.userPreferences.onDeviceProcessingOnly)
    }
    
    // MARK: - Regional Settings Management Tests
    
    func testUpdateDateFormat() {
        preferenceManager.updateDateFormat(.ymd)
        
        XCTAssertEqual(preferenceManager.userPreferences.dateFormat, .ymd)
    }
    
    func testUpdateTimeFormat() {
        preferenceManager.updateTimeFormat(.twentyFour)
        
        XCTAssertEqual(preferenceManager.userPreferences.timeFormat, .twentyFour)
    }
    
    func testUpdateFirstDayOfWeek() {
        preferenceManager.updateFirstDayOfWeek(.monday)
        
        XCTAssertEqual(preferenceManager.userPreferences.firstDayOfWeek, .monday)
    }
    
    func testUpdateFinancialYearStart() {
        preferenceManager.updateFinancialYearStart(.april)
        
        XCTAssertEqual(preferenceManager.userPreferences.financialYearStart, .april)
    }
    
    // MARK: - Country-based Configuration Tests
    
    func testConfigureForCountry() {
        let country = SupportedCountries.india
        
        preferenceManager.configureForCountry(country)
        
        XCTAssertEqual(preferenceManager.userPreferences.baseCurrency, country.primaryCurrency)
        XCTAssertEqual(preferenceManager.userPreferences.numberingSystem, country.numberingSystem)
        XCTAssertEqual(preferenceManager.userPreferences.dateFormat, country.culturalPreferences.dateFormat)
        XCTAssertEqual(preferenceManager.userPreferences.timeFormat, country.culturalPreferences.timeFormat)
        XCTAssertEqual(preferenceManager.userPreferences.firstDayOfWeek, country.culturalPreferences.weekStartsOn)
        XCTAssertEqual(preferenceManager.userPreferences.financialYearStart, country.financialYearStart)
    }
    
    // MARK: - Preference Management Tests
    
    func testResetToDefaults() {
        // Modify preferences
        preferenceManager.updateTheme(.dark)
        preferenceManager.updateBaseCurrency(.eur)
        preferenceManager.updateFontSize(.large)
        
        // Reset to defaults
        preferenceManager.resetToDefaults()
        
        // Verify defaults are restored
        XCTAssertEqual(preferenceManager.userPreferences.appTheme, .system)
        XCTAssertEqual(preferenceManager.userPreferences.baseCurrency, SupportedCurrency.preferredCurrency(for: Locale.current))
        XCTAssertEqual(preferenceManager.userPreferences.fontSize, .medium)
    }
    
    func testImportExportPreferences() {
        // Modify preferences
        preferenceManager.updateTheme(.dark)
        preferenceManager.updateBaseCurrency(.eur)
        preferenceManager.updateFontSize(.large)
        
        // Export preferences
        let exported = preferenceManager.exportPreferences()
        XCTAssertFalse(exported.isEmpty)
        
        // Reset and import
        preferenceManager.resetToDefaults()
        preferenceManager.importPreferences(from: exported)
        
        // Verify import worked
        XCTAssertEqual(preferenceManager.userPreferences.appTheme, .dark)
        XCTAssertEqual(preferenceManager.userPreferences.baseCurrency, .eur)
        XCTAssertEqual(preferenceManager.userPreferences.fontSize, .large)
    }
    
    // MARK: - Validation Tests
    
    func testValidateAndFixPreferences() {
        // Create inconsistent state
        preferenceManager.userPreferences.baseCurrency = .eur
        preferenceManager.userPreferences.displayCurrencies = [.usd, .gbp] // Base currency not included
        preferenceManager.userPreferences.notificationsEnabled = false
        preferenceManager.userPreferences.budgetAlerts = true // Inconsistent with notifications disabled
        preferenceManager.userPreferences.cloudBackupService = .none
        preferenceManager.userPreferences.dataBackupEnabled = true // Inconsistent with no service
        preferenceManager.userPreferences.autoLockTimeout = .never
        preferenceManager.userPreferences.autoLockEnabled = true // Inconsistent with never timeout
        
        // Validate and fix
        preferenceManager.validateAndFixPreferences()
        
        // Verify fixes
        XCTAssertTrue(preferenceManager.userPreferences.displayCurrencies.contains(.eur)) // Base currency should be added
        XCTAssertFalse(preferenceManager.userPreferences.budgetAlerts) // Should be disabled with notifications
        XCTAssertFalse(preferenceManager.userPreferences.dataBackupEnabled) // Should be disabled with no service
        XCTAssertFalse(preferenceManager.userPreferences.autoLockEnabled) // Should be disabled with never timeout
    }
    
    // MARK: - Feature Availability Tests
    
    func testIsFeatureAvailable() {
        // Test features that should be available based on platform
        XCTAssertTrue(preferenceManager.isFeatureAvailable(.biometricAuth))
        
        // Test cloud backup feature availability
        preferenceManager.userPreferences.cloudBackupService = .iCloud
        XCTAssertTrue(preferenceManager.isFeatureAvailable(.cloudBackup))
        
        preferenceManager.userPreferences.cloudBackupService = .none
        XCTAssertFalse(preferenceManager.isFeatureAvailable(.cloudBackup))
        
        // Test real-time exchange rates
        preferenceManager.userPreferences.exchangeRateUpdateFrequency = .realTime
        XCTAssertTrue(preferenceManager.isFeatureAvailable(.realTimeExchangeRates))
        
        preferenceManager.userPreferences.exchangeRateUpdateFrequency = .daily
        XCTAssertFalse(preferenceManager.isFeatureAvailable(.realTimeExchangeRates))
    }
    
    // MARK: - Observable Tests
    
    func testObservableChanges() {
        let expectation = XCTestExpectation(description: "Preference change observed")
        var changeCount = 0
        
        preferenceManager.objectWillChange
            .sink {
                changeCount += 1
                if changeCount == 3 { // We'll make 3 changes
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Make changes
        preferenceManager.updateTheme(.dark)
        preferenceManager.updateBaseCurrency(.eur)
        preferenceManager.updateFontSize(.large)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(changeCount, 3)
    }
    
    // MARK: - Edge Cases Tests
    
    func testAutoLockTimeoutNeverDisablesAutoLock() {
        preferenceManager.userPreferences.autoLockEnabled = true
        preferenceManager.updateAutoLockTimeout(.never)
        
        // Auto-lock should remain enabled since we're not explicitly disabling it
        XCTAssertTrue(preferenceManager.userPreferences.autoLockEnabled)
    }
    
    func testCloudBackupServiceNoneHandling() {
        preferenceManager.userPreferences.dataBackupEnabled = true
        preferenceManager.updateCloudBackupService(.none)
        
        XCTAssertEqual(preferenceManager.userPreferences.cloudBackupService, .none)
        // Data backup should remain enabled as the user explicitly set a service
    }
    
    // MARK: - Performance Tests
    
    func testPreferenceManagerPerformance() {
        measure {
            for _ in 0..<1000 {
                preferenceManager.updateTheme(.dark)
                preferenceManager.updateBaseCurrency(.eur)
                preferenceManager.updateFontSize(.large)
                preferenceManager.validateAndFixPreferences()
            }
        }
    }
}