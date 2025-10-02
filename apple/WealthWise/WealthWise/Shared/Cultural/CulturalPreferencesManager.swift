//
//  CulturalPreferencesManager.swift
//  WealthWise
//
//  Created by GitHub Copilot on 02/10/2025.
//  Comprehensive cultural preferences management with reactive updates
//

import Foundation
import SwiftUI
import Combine
import os.log
#if canImport(UIKit)
import UIKit
#endif

/// Comprehensive cultural preferences manager coordinating all cultural adaptations
/// Provides reactive updates, persistence, and integration with all formatting components
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class CulturalPreferencesManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current cultural context
    @Published public private(set) var currentContext: CulturalContext
    
    /// Available cultural contexts (saved presets)
    @Published public private(set) var availableContexts: [CulturalContext] = []
    
    /// Whether context is being switched
    @Published public private(set) var isSwitching: Bool = false
    
    /// Last switch timestamp for performance monitoring
    @Published public private(set) var lastSwitchTimestamp: Date?
    
    // MARK: - Dependencies
    
    private let validation: CulturalValidation
    private let uiAdaptation: CulturalUIAdaptation
    private let accessibilityPatterns: CulturalAccessibilityPatterns
    private let stringCatalogManager: StringCatalogManager
    
    // Formatters
    private var numberFormatter: LocalizedNumberFormatter
    private var currencyFormatter: LocalizedCurrencyFormatter
    private var dateFormatter: LocalizedDateFormatter
    
    // MARK: - Storage
    
    private let userDefaults = UserDefaults.standard
    private let contextStorageKey = "culturalContext"
    private let savedContextsKey = "savedCulturalContexts"
    
    // MARK: - Logging
    
    private let logger = Logger(subsystem: "com.wealthwise.cultural", category: "PreferencesManager")
    
    // MARK: - Combine
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Performance Metrics
    
    private var contextSwitchTimes: [TimeInterval] = []
    private let maxMetricsSamples = 100
    
    // MARK: - Initialization
    
    public init(
        stringCatalogManager: StringCatalogManager? = nil,
        initialContext: CulturalContext? = nil
    ) {
        // Initialize with saved or default context
        let context = initialContext ?? Self.loadSavedContext() ?? CulturalContext()
        self.currentContext = context
        
        // Initialize dependencies
        self.validation = CulturalValidation(culturalContext: context)
        self.uiAdaptation = CulturalUIAdaptation(culturalContext: context)
        self.accessibilityPatterns = CulturalAccessibilityPatterns(culturalContext: context)
        
        // Initialize string catalog manager
        if let manager = stringCatalogManager {
            self.stringCatalogManager = manager
        } else {
            self.stringCatalogManager = StringCatalogManager()
        }
        
        // Initialize formatters
        let numberConfig = NumberFormatterConfiguration.forAudience(context.audience)
        self.numberFormatter = LocalizedNumberFormatter(configuration: numberConfig)
        
        let currencyConfig = NumberFormatterConfiguration.forAudience(context.audience)
        self.currencyFormatter = LocalizedCurrencyFormatter(
            currency: Self.currencyForAudience(context.audience),
            configuration: currencyConfig
        )
        
        let dateConfig = DateFormatterConfiguration.forAudience(context.audience)
        self.dateFormatter = LocalizedDateFormatter(configuration: dateConfig)
        
        // Load saved contexts
        loadSavedContexts()
        
        // Setup reactive updates
        setupReactiveUpdates()
        
        logger.info("CulturalPreferencesManager initialized for audience: \(context.audience.displayName)")
    }
    
    // MARK: - Public API - Context Management
    
    /// Switch to a different audience
    public func switchAudience(to audience: PrimaryAudience) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        isSwitching = true
        defer {
            isSwitching = false
            let switchTime = CFAbsoluteTimeGetCurrent() - startTime
            recordSwitchTime(switchTime)
            logger.info("Audience switched to \(audience.displayName) in \(String(format: "%.3f", switchTime))s")
        }
        
        // Update context
        currentContext.updateAudience(audience)
        
        // Update formatters
        await updateFormatters()
        
        // Update locale
        stringCatalogManager.changeLocale(to: currentContext.currentLocale)
        
        // Save context
        saveCurrentContext()
        
        // Notify observers
        NotificationCenter.default.post(
            name: .culturalContextDidChange,
            object: self,
            userInfo: ["audience": audience]
        )
        
        lastSwitchTimestamp = Date()
    }
    
    /// Switch to a saved context
    public func switchContext(to context: CulturalContext) async {
        await switchAudience(to: context.audience)
        
        // Apply additional context settings
        currentContext = context.copy()
        await updateFormatters()
        saveCurrentContext()
    }
    
    /// Update text direction
    public func updateTextDirection(_ direction: TextDirection) {
        currentContext.updateTextDirection(direction)
        saveCurrentContext()
        
        NotificationCenter.default.post(
            name: .textDirectionDidChange,
            object: self,
            userInfo: ["direction": direction]
        )
    }
    
    /// Update accessibility settings
    public func updateAccessibility(
        enabled: Bool,
        highContrast: Bool = false,
        reducedMotion: Bool = false
    ) {
        currentContext.updateAccessibility(
            enabled: enabled,
            highContrast: highContrast,
            reducedMotion: reducedMotion
        )
        saveCurrentContext()
        
        NotificationCenter.default.post(
            name: .accessibilityDidChange,
            object: self,
            userInfo: [
                "enabled": enabled,
                "highContrast": highContrast,
                "reducedMotion": reducedMotion
            ]
        )
    }
    
    // MARK: - Public API - Formatting
    
    /// Format number according to cultural preferences
    public func formatNumber(_ value: Decimal) -> String {
        numberFormatter.string(from: value)
    }
    
    /// Format currency according to cultural preferences
    public func formatCurrency(_ value: Decimal) -> String {
        currencyFormatter.string(from: value)
    }
    
    /// Format date according to cultural preferences
    public func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
    
    /// Format date for accessibility
    public func formatDateAccessible(_ date: Date) -> String {
        dateFormatter.accessibleString(from: date)
    }
    
    // MARK: - Public API - Validation
    
    /// Validate number string
    public func validateNumber(_ string: String) -> ValidationResult {
        validation.validateNumberString(string)
    }
    
    /// Validate currency string
    public func validateCurrency(_ string: String) -> ValidationResult {
        validation.validateCurrencyString(string)
    }
    
    /// Validate date string
    public func validateDate(_ string: String) -> ValidationResult {
        validation.validateDateString(string)
    }
    
    // MARK: - Public API - UI Adaptation
    
    /// Get UI adapter for current context
    public func getUIAdapter() -> CulturalUIAdaptation {
        uiAdaptation
    }
    
    /// Get accessibility patterns for current context
    public func getAccessibilityPatterns() -> CulturalAccessibilityPatterns {
        accessibilityPatterns
    }
    
    // MARK: - Public API - Persistence
    
    /// Save current context as preset
    public func saveContextAsPreset(name: String) {
        var context = currentContext.copy()
        availableContexts.append(context)
        saveContextsToStorage()
        
        logger.info("Saved context preset: \(name)")
    }
    
    /// Delete a saved context
    public func deleteContext(_ context: CulturalContext) {
        availableContexts.removeAll { $0 == context }
        saveContextsToStorage()
    }
    
    /// Reset to default context
    public func resetToDefault() async {
        let defaultContext = CulturalContext()
        await switchContext(to: defaultContext)
        logger.info("Reset to default context")
    }
    
    // MARK: - Public API - Performance
    
    /// Get performance metrics
    public func getPerformanceMetrics() -> CulturalPerformanceMetrics {
        let averageSwitchTime = contextSwitchTimes.isEmpty ? 0 :
            contextSwitchTimes.reduce(0, +) / Double(contextSwitchTimes.count)
        
        return CulturalPerformanceMetrics(
            averageContextSwitchTime: averageSwitchTime,
            totalContextSwitches: contextSwitchTimes.count,
            lastSwitchTimestamp: lastSwitchTimestamp,
            localizationMetrics: stringCatalogManager.getPerformanceMetrics()
        )
    }
    
    // MARK: - Private Implementation
    
    private func setupReactiveUpdates() {
        // Observe system locale changes
        NotificationCenter.default.publisher(for: NSLocale.currentLocaleDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleSystemLocaleChange()
                }
            }
            .store(in: &cancellables)
        
        // Observe accessibility changes
        #if canImport(UIKit)
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleAccessibilityChange()
                }
            }
            .store(in: &cancellables)
        #endif
    }
    
    private func handleSystemLocaleChange() async {
        logger.info("System locale changed, updating context")
        // Optionally auto-adapt to system locale
        // await updateFormatters()
    }
    
    private func handleAccessibilityChange() {
        #if canImport(UIKit)
        let isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        updateAccessibility(enabled: isVoiceOverRunning)
        logger.info("VoiceOver status changed: \(isVoiceOverRunning)")
        #endif
    }
    
    private func updateFormatters() async {
        let numberConfig = NumberFormatterConfiguration.forAudience(currentContext.audience)
        numberFormatter = LocalizedNumberFormatter(configuration: numberConfig)
        
        let currencyConfig = NumberFormatterConfiguration.forAudience(currentContext.audience)
        currencyFormatter = LocalizedCurrencyFormatter(
            currency: Self.currencyForAudience(currentContext.audience),
            configuration: currencyConfig
        )
        
        let dateConfig = DateFormatterConfiguration(audience: currentContext.audience)
        dateFormatter = LocalizedDateFormatter(configuration: dateConfig)
    }
    
    private func recordSwitchTime(_ time: TimeInterval) {
        contextSwitchTimes.append(time)
        if contextSwitchTimes.count > maxMetricsSamples {
            contextSwitchTimes.removeFirst()
        }
    }
    
    // MARK: - Persistence
    
    private func saveCurrentContext() {
        do {
            let data = try JSONEncoder().encode(currentContext)
            userDefaults.set(data, forKey: contextStorageKey)
            logger.debug("Saved current context")
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    private static func loadSavedContext() -> CulturalContext? {
        guard let data = UserDefaults.standard.data(forKey: "culturalContext") else {
            return nil
        }
        
        do {
            let context = try JSONDecoder().decode(CulturalContext.self, from: data)
            return context
        } catch {
            return nil
        }
    }
    
    private func loadSavedContexts() {
        guard let data = userDefaults.data(forKey: savedContextsKey) else {
            return
        }
        
        do {
            let contexts = try JSONDecoder().decode([CulturalContext].self, from: data)
            availableContexts = contexts
            logger.info("Loaded \(contexts.count) saved contexts")
        } catch {
            logger.error("Failed to load saved contexts: \(error.localizedDescription)")
        }
    }
    
    private func saveContextsToStorage() {
        do {
            let data = try JSONEncoder().encode(availableContexts)
            userDefaults.set(data, forKey: savedContextsKey)
            logger.debug("Saved \(availableContexts.count) contexts")
        } catch {
            logger.error("Failed to save contexts: \(error.localizedDescription)")
        }
    }
    
    private static func currencyForAudience(_ audience: PrimaryAudience) -> SupportedCurrency {
        switch audience {
        case .indian: return .INR
        case .american: return .USD
        case .british: return .GBP
        case .canadian: return .CAD
        case .australian: return .AUD
        case .singaporean: return .SGD
        case .german, .french, .dutch, .irish, .luxembourgish: return .EUR
        case .swiss: return .CHF
        case .japanese: return .JPY
        case .hongKongese: return .HKD
        case .newZealander: return .NZD
        case .malaysian: return .MYR
        case .thai: return .THB
        case .filipino: return .PHP
        case .emirati: return .AED
        case .qatari: return .QAR
        case .saudi: return .SAR
        case .brazilian: return .BRL
        case .mexican: return .MXN
        }
    }
}

// MARK: - Supporting Types

/// Performance metrics for cultural preferences system
public struct CulturalPerformanceMetrics {
    public let averageContextSwitchTime: TimeInterval
    public let totalContextSwitches: Int
    public let lastSwitchTimestamp: Date?
    public let localizationMetrics: LocalizationPerformanceMetrics
    
    public var description: String {
        """
        Cultural Performance Metrics:
        - Average switch time: \(String(format: "%.3f", averageContextSwitchTime))s
        - Total switches: \(totalContextSwitches)
        - Cache hit rate: \(String(format: "%.1f", localizationMetrics.cacheHitRate * 100))%
        """
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let culturalContextDidChange = Notification.Name("CulturalContextDidChange")
    static let textDirectionDidChange = Notification.Name("TextDirectionDidChange")
    static let accessibilityDidChange = Notification.Name("AccessibilityDidChange")
}

// MARK: - Environment Support

@available(iOS 18.6, macOS 15.6, *)
struct CulturalPreferencesManagerKey: EnvironmentKey {
    static let defaultValue: CulturalPreferencesManager? = nil
}

@available(iOS 18.6, macOS 15.6, *)
public extension EnvironmentValues {
    var culturalPreferencesManager: CulturalPreferencesManager? {
        get { self[CulturalPreferencesManagerKey.self] }
        set { self[CulturalPreferencesManagerKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Extension

@available(iOS 18.6, macOS 15.6, *)
public extension View {
    /// Inject cultural preferences manager into environment
    func culturalPreferences(_ manager: CulturalPreferencesManager) -> some View {
        self.environment(\.culturalPreferencesManager, manager)
    }
}
