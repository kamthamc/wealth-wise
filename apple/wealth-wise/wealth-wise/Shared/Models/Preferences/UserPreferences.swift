import Foundation
import Combine

/// User preferences for WealthWise application
public class UserPreferences: ObservableObject {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let keyPrefix = "WealthWise.UserPreferences."
    
    // MARK: - Theme & Appearance
    
    @Published public var appTheme: AppTheme {
        didSet { save(appTheme, for: .appTheme) }
    }
    
    @Published public var colorScheme: ColorScheme {
        didSet { save(colorScheme, for: .colorScheme) }
    }
    
    @Published public var accentColor: AccentColor {
        didSet { save(accentColor, for: .accentColor) }
    }
    
    @Published public var useSystemAppearance: Bool {
        didSet { save(useSystemAppearance, for: .useSystemAppearance) }
    }
    
    // MARK: - Currency & Financial
    
    @Published public var baseCurrency: SupportedCurrency {
        didSet { save(baseCurrency, for: .baseCurrency) }
    }
    
    @Published public var displayCurrencies: [SupportedCurrency] {
        didSet { save(displayCurrencies, for: .displayCurrencies) }
    }
    
    @Published public var currencyDisplayFormat: CurrencyDisplayFormat {
        didSet { save(currencyDisplayFormat, for: .currencyDisplayFormat) }
    }
    
    @Published public var numberingSystem: NumberingSystem {
        didSet { save(numberingSystem, for: .numberingSystem) }
    }
    
    @Published public var exchangeRateUpdateFrequency: ExchangeRateUpdateFrequency {
        didSet { save(exchangeRateUpdateFrequency, for: .exchangeRateUpdateFrequency) }
    }
    
    // MARK: - Accessibility
    
    @Published public var fontSize: FontSize {
        didSet { save(fontSize, for: .fontSize) }
    }
    
    @Published public var useHighContrast: Bool {
        didSet { save(useHighContrast, for: .useHighContrast) }
    }
    
    @Published public var reduceMotion: Bool {
        didSet { save(reduceMotion, for: .reduceMotion) }
    }
    
    @Published public var voiceOverEnabled: Bool {
        didSet { save(voiceOverEnabled, for: .voiceOverEnabled) }
    }
    
    @Published public var hapticFeedback: HapticFeedbackLevel {
        didSet { save(hapticFeedback, for: .hapticFeedbackLevel) }
    }
    
    // MARK: - Data & Privacy
    
    @Published public var dataBackupEnabled: Bool {
        didSet { save(dataBackupEnabled, for: .dataBackupEnabled) }
    }
    
    @Published public var cloudBackupService: CloudBackupService {
        didSet { save(cloudBackupService, for: .cloudBackupService) }
    }
    
    @Published public var analyticsEnabled: Bool {
        didSet { save(analyticsEnabled, for: .analyticsEnabled) }
    }
    
    @Published public var crashReportingEnabled: Bool {
        didSet { save(crashReportingEnabled, for: .crashReportingEnabled) }
    }
    
    @Published public var dataRetentionPeriod: DataRetentionPeriod {
        didSet { save(dataRetentionPeriod, for: .dataRetentionPeriod) }
    }
    
    // MARK: - Notifications
    
    @Published public var notificationsEnabled: Bool {
        didSet { save(notificationsEnabled, for: .notificationsEnabled) }
    }
    
    @Published public var budgetAlerts: Bool {
        didSet { save(budgetAlerts, for: .budgetAlerts) }
    }
    
    @Published public var billReminders: Bool {
        didSet { save(billReminders, for: .billReminders) }
    }
    
    @Published public var investmentUpdates: Bool {
        didSet { save(investmentUpdates, for: .investmentUpdates) }
    }
    
    @Published public var exchangeRateAlerts: Bool {
        didSet { save(exchangeRateAlerts, for: .exchangeRateAlerts) }
    }
    
    // MARK: - Security
    
    @Published public var biometricAuthEnabled: Bool {
        didSet { save(biometricAuthEnabled, for: .biometricAuthEnabled) }
    }
    
    @Published public var autoLockEnabled: Bool {
        didSet { save(autoLockEnabled, for: .autoLockEnabled) }
    }
    
    @Published public var autoLockTimeout: AutoLockTimeout {  
        didSet { save(autoLockTimeout, for: .autoLockTimeout) }
    }
    
    @Published public var requireAuthForSensitiveData: Bool {
        didSet { save(requireAuthForSensitiveData, for: .requireAuthForSensitiveData) }
    }
    
    // MARK: - Smart Features
    
    @Published public var smartCategorizationEnabled: Bool {
        didSet { save(smartCategorizationEnabled, for: .smartCategorizationEnabled) }
    }
    
    @Published public var smartInsightsEnabled: Bool {
        didSet { save(smartInsightsEnabled, for: .smartInsightsEnabled) }
    }
    
    @Published public var naturalLanguageProcessing: Bool {
        didSet { save(naturalLanguageProcessing, for: .naturalLanguageProcessing) }
    }
    
    @Published public var onDeviceProcessingOnly: Bool {
        didSet { save(onDeviceProcessingOnly, for: .onDeviceProcessingOnly) }
    }
    
    // MARK: - Regional Settings
    
    @Published public var dateFormat: DateFormatStyle {
        didSet { save(dateFormat, for: .dateFormat) }
    }
    
    @Published public var timeFormat: TimeFormat {
        didSet { save(timeFormat, for: .timeFormat) }
    }
    
    @Published public var firstDayOfWeek: Weekday {
        didSet { save(firstDayOfWeek, for: .firstDayOfWeek) }
    }
    
    @Published public var financialYearStart: FinancialYearStart {
        didSet { save(financialYearStart, for: .financialYearStart) }
    }
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Load or set defaults
        self.appTheme = load(AppTheme.self, for: .appTheme) ?? .system
        self.colorScheme = load(ColorScheme.self, for: .colorScheme) ?? .system
        self.accentColor = load(AccentColor.self, for: .accentColor) ?? .blue
        self.useSystemAppearance = load(Bool.self, for: .useSystemAppearance) ?? true
        
        self.baseCurrency = load(SupportedCurrency.self, for: .baseCurrency) ?? SupportedCurrency.preferredCurrency(for: Locale.current)
        self.displayCurrencies = load([SupportedCurrency].self, for: .displayCurrencies) ?? [baseCurrency]
        self.currencyDisplayFormat = load(CurrencyDisplayFormat.self, for: .currencyDisplayFormat) ?? .standard
        self.numberingSystem = load(NumberingSystem.self, for: .numberingSystem) ?? .detectFromLocale()
        self.exchangeRateUpdateFrequency = load(ExchangeRateUpdateFrequency.self, for: .exchangeRateUpdateFrequency) ?? .hourly
        
        self.fontSize = load(FontSize.self, for: .fontSize) ?? .medium
        self.useHighContrast = load(Bool.self, for: .useHighContrast) ?? false
        self.reduceMotion = load(Bool.self, for: .reduceMotion) ?? false
        self.voiceOverEnabled = load(Bool.self, for: .voiceOverEnabled) ?? false
        self.hapticFeedback = load(HapticFeedbackLevel.self, for: .hapticFeedbackLevel) ?? .medium
        
        self.dataBackupEnabled = load(Bool.self, for: .dataBackupEnabled) ?? true
        self.cloudBackupService = load(CloudBackupService.self, for: .cloudBackupService) ?? .detectFromPlatform()
        self.analyticsEnabled = load(Bool.self, for: .analyticsEnabled) ?? false
        self.crashReportingEnabled = load(Bool.self, for: .crashReportingEnabled) ?? true
        self.dataRetentionPeriod = load(DataRetentionPeriod.self, for: .dataRetentionPeriod) ?? .fiveYears
        
        self.notificationsEnabled = load(Bool.self, for: .notificationsEnabled) ?? true
        self.budgetAlerts = load(Bool.self, for: .budgetAlerts) ?? true
        self.billReminders = load(Bool.self, for: .billReminders) ?? true
        self.investmentUpdates = load(Bool.self, for: .investmentUpdates) ?? false
        self.exchangeRateAlerts = load(Bool.self, for: .exchangeRateAlerts) ?? false
        
        self.biometricAuthEnabled = load(Bool.self, for: .biometricAuthEnabled) ?? true
        self.autoLockEnabled = load(Bool.self, for: .autoLockEnabled) ?? true
        self.autoLockTimeout = load(AutoLockTimeout.self, for: .autoLockTimeout) ?? .fiveMinutes
        self.requireAuthForSensitiveData = load(Bool.self, for: .requireAuthForSensitiveData) ?? true
        
        let deviceHasMLCapabilities = Self.deviceSupportsOnDeviceML()
        self.smartCategorizationEnabled = load(Bool.self, for: .smartCategorizationEnabled) ?? deviceHasMLCapabilities
        self.smartInsightsEnabled = load(Bool.self, for: .smartInsightsEnabled) ?? deviceHasMLCapabilities
        self.naturalLanguageProcessing = load(Bool.self, for: .naturalLanguageProcessing) ?? deviceHasMLCapabilities
        self.onDeviceProcessingOnly = load(Bool.self, for: .onDeviceProcessingOnly) ?? true
        
        // Regional settings from current country or locale
        let country = SupportedCountries.preferredCountry(for: Locale.current)
        self.dateFormat = load(DateFormatStyle.self, for: .dateFormat) ?? country.culturalPreferences.dateFormat
        self.timeFormat = load(TimeFormat.self, for: .timeFormat) ?? country.culturalPreferences.timeFormat
        self.firstDayOfWeek = load(Weekday.self, for: .firstDayOfWeek) ?? country.culturalPreferences.weekStartsOn
        self.financialYearStart = load(FinancialYearStart.self, for: .financialYearStart) ?? country.financialYearStart
    }
    
    // MARK: - Convenience Methods
    
    /// Resets all preferences to default values
    public func resetToDefaults() {
        let country = SupportedCountries.preferredCountry(for: Locale.current)
        let deviceHasMLCapabilities = Self.deviceSupportsOnDeviceML()
        
        appTheme = .system
        colorScheme = .system
        accentColor = .blue
        useSystemAppearance = true
        
        baseCurrency = SupportedCurrency.preferredCurrency(for: Locale.current)
        displayCurrencies = [baseCurrency]
        currencyDisplayFormat = .standard
        numberingSystem = .detectFromLocale()
        exchangeRateUpdateFrequency = .hourly
        
        fontSize = .medium
        useHighContrast = false
        reduceMotion = false
        voiceOverEnabled = false
        hapticFeedback = .medium
        
        dataBackupEnabled = true
        cloudBackupService = .detectFromPlatform()
        analyticsEnabled = false
        crashReportingEnabled = true
        dataRetentionPeriod = .fiveYears
        
        notificationsEnabled = true
        budgetAlerts = true
        billReminders = true
        investmentUpdates = false
        exchangeRateAlerts = false
        
        biometricAuthEnabled = true
        autoLockEnabled = true
        autoLockTimeout = .fiveMinutes
        requireAuthForSensitiveData = true
        
        smartCategorizationEnabled = deviceHasMLCapabilities
        smartInsightsEnabled = deviceHasMLCapabilities
        naturalLanguageProcessing = deviceHasMLCapabilities
        onDeviceProcessingOnly = true
        
        dateFormat = country.culturalPreferences.dateFormat
        timeFormat = country.culturalPreferences.timeFormat
        firstDayOfWeek = country.culturalPreferences.weekStartsOn
        financialYearStart = country.financialYearStart
    }
    
    /// Updates preferences based on country selection
    public func updateForCountry(_ country: Country) {
        if baseCurrency != country.primaryCurrency {
            baseCurrency = country.primaryCurrency
        }
        
        numberingSystem = country.numberingSystem
        dateFormat = country.culturalPreferences.dateFormat
        timeFormat = country.culturalPreferences.timeFormat
        firstDayOfWeek = country.culturalPreferences.weekStartsOn
        financialYearStart = country.financialYearStart
        
        // Update data retention based on regulatory requirements
        if let retentionLimit = country.regulatoryZone.dataRetentionLimit {
            let years = Int(retentionLimit / (365 * 24 * 60 * 60))
            switch years {
            case 0...2:
                dataRetentionPeriod = .twoYears
            case 3:
                dataRetentionPeriod = .threeYears
            case 4...5:
                dataRetentionPeriod = .fiveYears
            case 6...7:
                dataRetentionPeriod = .sevenYears
            default:
                dataRetentionPeriod = .tenYears
            }
        }
    }
    
    /// Imports preferences from another UserPreferences instance
    public func importFrom(_ otherPreferences: UserPreferences) {
        appTheme = otherPreferences.appTheme
        colorScheme = otherPreferences.colorScheme
        accentColor = otherPreferences.accentColor
        useSystemAppearance = otherPreferences.useSystemAppearance
        
        baseCurrency = otherPreferences.baseCurrency
        displayCurrencies = otherPreferences.displayCurrencies
        currencyDisplayFormat = otherPreferences.currencyDisplayFormat
        numberingSystem = otherPreferences.numberingSystem
        exchangeRateUpdateFrequency = otherPreferences.exchangeRateUpdateFrequency
        
        fontSize = otherPreferences.fontSize
        useHighContrast = otherPreferences.useHighContrast
        reduceMotion = otherPreferences.reduceMotion
        voiceOverEnabled = otherPreferences.voiceOverEnabled
        hapticFeedback = otherPreferences.hapticFeedback
        
        dataBackupEnabled = otherPreferences.dataBackupEnabled
        cloudBackupService = otherPreferences.cloudBackupService
        analyticsEnabled = otherPreferences.analyticsEnabled
        crashReportingEnabled = otherPreferences.crashReportingEnabled
        dataRetentionPeriod = otherPreferences.dataRetentionPeriod
        
        notificationsEnabled = otherPreferences.notificationsEnabled
        budgetAlerts = otherPreferences.budgetAlerts
        billReminders = otherPreferences.billReminders
        investmentUpdates = otherPreferences.investmentUpdates
        exchangeRateAlerts = otherPreferences.exchangeRateAlerts
        
        biometricAuthEnabled = otherPreferences.biometricAuthEnabled
        autoLockEnabled = otherPreferences.autoLockEnabled
        autoLockTimeout = otherPreferences.autoLockTimeout
        requireAuthForSensitiveData = otherPreferences.requireAuthForSensitiveData
        
        smartCategorizationEnabled = otherPreferences.smartCategorizationEnabled
        smartInsightsEnabled = otherPreferences.smartInsightsEnabled
        naturalLanguageProcessing = otherPreferences.naturalLanguageProcessing
        onDeviceProcessingOnly = otherPreferences.onDeviceProcessingOnly
        
        dateFormat = otherPreferences.dateFormat
        timeFormat = otherPreferences.timeFormat
        firstDayOfWeek = otherPreferences.firstDayOfWeek
        financialYearStart = otherPreferences.financialYearStart
    }
    
    /// Exports preferences as a dictionary for backup/sync
    public func exportPreferences() -> [String: Any] {
        var preferences: [String: Any] = [:]
        
        for key in PreferenceKey.allCases {
            if let value = userDefaults.object(forKey: keyPrefix + key.rawValue) {
                preferences[key.rawValue] = value
            }
        }
        
        return preferences
    }
    
    /// Imports preferences from a dictionary
    public func importPreferences(_ preferences: [String: Any]) {
        for (key, value) in preferences {
            userDefaults.set(value, forKey: keyPrefix + key)
        }
        
        // Reload all preferences
        let newPrefs = UserPreferences(userDefaults: userDefaults)
        importFrom(newPrefs)
    }
    
    // MARK: - Private Methods
    
    private func save<T: Codable>(_ value: T, for key: PreferenceKey) {
        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: keyPrefix + key.rawValue)
        }
    }
    
    private func load<T: Codable>(_ type: T.Type, for key: PreferenceKey) -> T? {
        guard let data = userDefaults.data(forKey: keyPrefix + key.rawValue) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    private static func deviceSupportsOnDeviceML() -> Bool {
        #if os(iOS)
        return true // iOS 17+ with Neural Engine support assumed
        #elseif os(macOS)
        return true // macOS with Apple Silicon or Intel with ML capabilities
        #elseif os(Windows)
        return false // Windows ML.NET capabilities to be determined
        #else
        return false
        #endif
    }
}

// MARK: - Supporting Types

private enum PreferenceKey: String, CaseIterable {
    case appTheme = "appTheme"
    case colorScheme = "colorScheme"
    case accentColor = "accentColor"
    case useSystemAppearance = "useSystemAppearance"
    case baseCurrency = "baseCurrency"
    case displayCurrencies = "displayCurrencies"
    case currencyDisplayFormat = "currencyDisplayFormat"
    case numberingSystem = "numberingSystem"
    case exchangeRateUpdateFrequency = "exchangeRateUpdateFrequency"
    case fontSize = "fontSize"
    case useHighContrast = "useHighContrast"
    case reduceMotion = "reduceMotion"
    case voiceOverEnabled = "voiceOverEnabled"
    case hapticFeedbackLevel = "hapticFeedbackLevel"
    case dataBackupEnabled = "dataBackupEnabled"
    case cloudBackupService = "cloudBackupService"
    case analyticsEnabled = "analyticsEnabled"
    case crashReportingEnabled = "crashReportingEnabled"
    case dataRetentionPeriod = "dataRetentionPeriod"
    case notificationsEnabled = "notificationsEnabled"
    case budgetAlerts = "budgetAlerts"
    case billReminders = "billReminders"
    case investmentUpdates = "investmentUpdates"
    case exchangeRateAlerts = "exchangeRateAlerts"
    case biometricAuthEnabled = "biometricAuthEnabled"
    case autoLockEnabled = "autoLockEnabled"
    case autoLockTimeout = "autoLockTimeout"
    case requireAuthForSensitiveData = "requireAuthForSensitiveData"
    case smartCategorizationEnabled = "smartCategorizationEnabled"
    case smartInsightsEnabled = "smartInsightsEnabled"
    case naturalLanguageProcessing = "naturalLanguageProcessing"
    case onDeviceProcessingOnly = "onDeviceProcessingOnly"
    case dateFormat = "dateFormat"
    case timeFormat = "timeFormat"
    case firstDayOfWeek = "firstDayOfWeek"
    case financialYearStart = "financialYearStart"
}