import Foundation
import Combine

/// Manager for handling user preferences across the application
public class PreferenceManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var userPreferences: UserPreferences
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userPreferences = UserPreferences(userDefaults: userDefaults)
        
        // Observe preferences changes for any additional processing
        userPreferences.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Theme Management
    
    /// Updates the app theme and related appearance settings
    public func updateTheme(_ theme: AppTheme) {
        userPreferences.appTheme = theme
        
        // Update system appearance setting based on theme
        if theme != .system {
            userPreferences.useSystemAppearance = false
        }
    }
    
    /// Updates color scheme
    public func updateColorScheme(_ colorScheme: ColorScheme) {
        userPreferences.colorScheme = colorScheme
    }
    
    /// Updates accent color
    public func updateAccentColor(_ accentColor: AccentColor) {
        userPreferences.accentColor = accentColor
    }
    
    /// Toggles system appearance following
    public func toggleSystemAppearance(_ enabled: Bool) {
        userPreferences.useSystemAppearance = enabled
        
        if enabled {
            userPreferences.appTheme = .system
            userPreferences.colorScheme = .system
        }
    }
    
    // MARK: - Currency Management
    
    /// Updates the base currency and related settings
    public func updateBaseCurrency(_ currency: SupportedCurrency) {
        userPreferences.baseCurrency = currency
        
        // Add to display currencies if not already present
        if !userPreferences.displayCurrencies.contains(currency) {
            userPreferences.displayCurrencies.insert(currency, at: 0)
        }
    }
    
    /// Adds a currency to display list
    public func addDisplayCurrency(_ currency: SupportedCurrency) {
        if !userPreferences.displayCurrencies.contains(currency) {
            userPreferences.displayCurrencies.append(currency)
        }
    }
    
    /// Removes a currency from display list
    public func removeDisplayCurrency(_ currency: SupportedCurrency) {
        // Don't allow removing the base currency
        guard currency != userPreferences.baseCurrency else { return }
        
        userPreferences.displayCurrencies.removeAll { $0 == currency }
    }
    
    /// Reorders display currencies
    public func reorderDisplayCurrencies(_ currencies: [SupportedCurrency]) {
        // Ensure base currency is always first
        var orderedCurrencies = currencies
        if let baseCurrency = orderedCurrencies.first(where: { $0 == userPreferences.baseCurrency }) {
            orderedCurrencies.removeAll { $0 == baseCurrency }
            orderedCurrencies.insert(baseCurrency, at: 0)
        }
        
        userPreferences.displayCurrencies = orderedCurrencies
    }
    
    /// Updates currency display format
    public func updateCurrencyDisplayFormat(_ format: CurrencyDisplayFormat) {
        userPreferences.currencyDisplayFormat = format
    }
    
    /// Updates numbering system
    public func updateNumberingSystem(_ system: NumberingSystem) {
        userPreferences.numberingSystem = system
    }
    
    /// Updates exchange rate update frequency
    public func updateExchangeRateFrequency(_ frequency: ExchangeRateUpdateFrequency) {
        userPreferences.exchangeRateUpdateFrequency = frequency
    }
    
    // MARK: - Accessibility Management
    
    /// Updates font size
    public func updateFontSize(_ fontSize: FontSize) {
        userPreferences.fontSize = fontSize
    }
    
    /// Toggles high contrast mode
    public func toggleHighContrast(_ enabled: Bool) {
        userPreferences.useHighContrast = enabled
    }
    
    /// Toggles reduced motion
    public func toggleReducedMotion(_ enabled: Bool) {
        userPreferences.reduceMotion = enabled
    }
    
    /// Toggles VoiceOver support
    public func toggleVoiceOver(_ enabled: Bool) {
        userPreferences.voiceOverEnabled = enabled
    }
    
    /// Updates haptic feedback level
    public func updateHapticFeedback(_ level: HapticFeedbackLevel) {
        userPreferences.hapticFeedback = level
    }
    
    // MARK: - Data & Privacy Management
    
    /// Toggles data backup
    public func toggleDataBackup(_ enabled: Bool) {
        userPreferences.dataBackupEnabled = enabled
    }
    
    /// Updates cloud backup service
    public func updateCloudBackupService(_ service: CloudBackupService) {
        userPreferences.cloudBackupService = service
        
        // Enable backup if a service is selected
        if service != .none && !userPreferences.dataBackupEnabled {
            userPreferences.dataBackupEnabled = true
        }
    }
    
    /// Toggles analytics
    public func toggleAnalytics(_ enabled: Bool) {
        userPreferences.analyticsEnabled = enabled
    }
    
    /// Toggles crash reporting
    public func toggleCrashReporting(_ enabled: Bool) {
        userPreferences.crashReportingEnabled = enabled
    }
    
    /// Updates data retention period
    public func updateDataRetentionPeriod(_ period: DataRetentionPeriod) {
        userPreferences.dataRetentionPeriod = period
    }
    
    // MARK: - Notification Management
    
    /// Toggles all notifications
    public func toggleNotifications(_ enabled: Bool) {
        userPreferences.notificationsEnabled = enabled
        
        // If disabling notifications, disable all notification types
        if !enabled {
            userPreferences.budgetAlerts = false
            userPreferences.billReminders = false
            userPreferences.investmentUpdates = false
            userPreferences.exchangeRateAlerts = false
        }
    }
    
    /// Toggles budget alerts
    public func toggleBudgetAlerts(_ enabled: Bool) {
        userPreferences.budgetAlerts = enabled
        
        // Enable general notifications if enabling budget alerts
        if enabled && !userPreferences.notificationsEnabled {
            userPreferences.notificationsEnabled = true
        }
    }
    
    /// Toggles bill reminders
    public func toggleBillReminders(_ enabled: Bool) {
        userPreferences.billReminders = enabled
        
        // Enable general notifications if enabling bill reminders
        if enabled && !userPreferences.notificationsEnabled {
            userPreferences.notificationsEnabled = true
        }
    }
    
    /// Toggles investment updates
    public func toggleInvestmentUpdates(_ enabled: Bool) {
        userPreferences.investmentUpdates = enabled
        
        // Enable general notifications if enabling investment updates
        if enabled && !userPreferences.notificationsEnabled {
            userPreferences.notificationsEnabled = true
        }
    }
    
    /// Toggles exchange rate alerts
    public func toggleExchangeRateAlerts(_ enabled: Bool) {
        userPreferences.exchangeRateAlerts = enabled
        
        // Enable general notifications if enabling exchange rate alerts
        if enabled && !userPreferences.notificationsEnabled {
            userPreferences.notificationsEnabled = true
        }
    }
    
    // MARK: - Security Management
    
    /// Toggles biometric authentication
    public func toggleBiometricAuth(_ enabled: Bool) {
        userPreferences.biometricAuthEnabled = enabled
    }
    
    /// Toggles auto-lock
    public func toggleAutoLock(_ enabled: Bool) {
        userPreferences.autoLockEnabled = enabled
    }
    
    /// Updates auto-lock timeout
    public func updateAutoLockTimeout(_ timeout: AutoLockTimeout) {
        userPreferences.autoLockTimeout = timeout
        
        // Enable auto-lock if setting a timeout
        if timeout != .never && !userPreferences.autoLockEnabled {
            userPreferences.autoLockEnabled = true
        }
    }
    
    /// Toggles authentication requirement for sensitive data
    public func toggleAuthForSensitiveData(_ enabled: Bool) {
        userPreferences.requireAuthForSensitiveData = enabled
    }
    
    // MARK: - Smart Features Management
    
    /// Toggles smart categorization
    public func toggleSmartCategorization(_ enabled: Bool) {
        userPreferences.smartCategorizationEnabled = enabled
    }
    
    /// Toggles smart insights
    public func toggleSmartInsights(_ enabled: Bool) {
        userPreferences.smartInsightsEnabled = enabled
    }
    
    /// Toggles natural language processing
    public func toggleNaturalLanguageProcessing(_ enabled: Bool) {
        userPreferences.naturalLanguageProcessing = enabled
    }
    
    /// Toggles on-device processing only
    public func toggleOnDeviceProcessingOnly(_ enabled: Bool) {
        userPreferences.onDeviceProcessingOnly = enabled
    }
    
    // MARK: - Regional Settings Management
    
    /// Updates date format
    public func updateDateFormat(_ format: DateFormatStyle) {
        userPreferences.dateFormat = format
    }
    
    /// Updates time format
    public func updateTimeFormat(_ format: TimeFormat) {
        userPreferences.timeFormat = format
    }
    
    /// Updates first day of week
    public func updateFirstDayOfWeek(_ weekday: Weekday) {
        userPreferences.firstDayOfWeek = weekday
    }
    
    /// Updates financial year start
    public func updateFinancialYearStart(_ start: FinancialYearStart) {
        userPreferences.financialYearStart = start
    }
    
    // MARK: - Country-based Configuration
    
    /// Updates all preferences for a specific country
    public func configureForCountry(_ country: Country) {
        userPreferences.updateForCountry(country)
    }
    
    // MARK: - Preference Management
    
    /// Resets all preferences to defaults
    public func resetToDefaults() {
        userPreferences.resetToDefaults()
    }
    
    /// Imports preferences from another instance
    public func importPreferences(_ preferences: UserPreferences) {
        userPreferences.importFrom(preferences)
    }
    
    /// Exports current preferences
    public func exportPreferences() -> [String: Any] {
        return userPreferences.exportPreferences()
    }
    
    /// Imports preferences from dictionary
    public func importPreferences(from dictionary: [String: Any]) {
        userPreferences.importPreferences(dictionary)
    }
    
    // MARK: - Validation
    
    /// Validates current preferences and fixes any conflicts
    public func validateAndFixPreferences() {
        // Ensure base currency is in display currencies
        if !userPreferences.displayCurrencies.contains(userPreferences.baseCurrency) {
            userPreferences.displayCurrencies.insert(userPreferences.baseCurrency, at: 0)
        }
        
        // Ensure notification consistency
        if !userPreferences.notificationsEnabled {
            userPreferences.budgetAlerts = false
            userPreferences.billReminders = false
            userPreferences.investmentUpdates = false
            userPreferences.exchangeRateAlerts = false
        }
        
        // Ensure backup service consistency
        if userPreferences.cloudBackupService == .none {
            userPreferences.dataBackupEnabled = false
        }
        
        // Ensure auto-lock consistency
        if userPreferences.autoLockTimeout == .never {
            userPreferences.autoLockEnabled = false
        }
    }
}

// MARK: - Extensions

extension PreferenceManager {
    
    /// Checks if a feature is available on the current device
    public func isFeatureAvailable(_ feature: WealthWiseFeature) -> Bool {
        switch feature {
        case .smartCategorization, .smartInsights, .naturalLanguageProcessing:
            return deviceSupportsOnDeviceML()
        case .biometricAuth:
            return deviceSupportsBiometrics()
        case .hapticFeedback:
            return deviceSupportsHaptics()
        case .cloudBackup:
            return userPreferences.cloudBackupService != .none
        case .realTimeExchangeRates:
            return userPreferences.exchangeRateUpdateFrequency == .realTime
        }
    }
    
    private func deviceSupportsOnDeviceML() -> Bool {
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
    
    private func deviceSupportsBiometrics() -> Bool {
        #if os(iOS)
        return true // Face ID/Touch ID
        #elseif os(macOS)
        return true // Touch ID on supported Macs
        #elseif os(Windows)
        return true // Windows Hello
        #else
        return false
        #endif
    }
    
    private func deviceSupportsHaptics() -> Bool {
        #if os(iOS)
        return true // Haptic Engine
        #elseif os(macOS)
        return true // Force Touch trackpad
        #elseif os(Windows)
        return false // Limited haptic support
        #else
        return false
        #endif
    }
}

// MARK: - Supporting Types

public enum WealthWiseFeature {
    case smartCategorization
    case smartInsights
    case naturalLanguageProcessing
    case biometricAuth
    case hapticFeedback
    case cloudBackup
    case realTimeExchangeRates
}