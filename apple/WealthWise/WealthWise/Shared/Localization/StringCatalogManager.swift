//
//  StringCatalogManager.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Advanced string catalog management with caching and performance optimization
//

import Foundation
import Combine
import os.log

/// Comprehensive string catalog manager providing efficient localization services
/// with caching, validation, and performance optimization for WealthWise application
@MainActor
public final class StringCatalogManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current locale for string retrieval
    @Published public private(set) var currentLocale: Locale = Locale.current
    
    /// Available locales supported by the application
    @Published public private(set) var availableLocales: [Locale] = []
    
    /// Loading state for async operations
    @Published public private(set) var isLoading: Bool = false
    
    /// Last cache refresh timestamp
    @Published public private(set) var lastCacheRefresh: Date?
    
    // MARK: - Dependencies
    
    private let translationCache: TranslationCacheProtocol
    private let localizationValidator: LocalizationValidatorProtocol
    private let logger = Logger(subsystem: "com.wealthwise.localization", category: "StringCatalogManager")
    
    // MARK: - Configuration
    
    private let supportedLocaleIdentifiers = [
        "en", // English (base)
        "hi", // Hindi
        "ar", // Arabic
        "ta", // Tamil
        "te", // Telugu
        "bn", // Bengali
        "mr", // Marathi
        "gu", // Gujarati
        "kn", // Kannada
        "ms"  // Malay
    ]
    
    // MARK: - Performance Metrics
    
    private var cacheHitCount: Int = 0
    private var cacheMissCount: Int = 0
    private var stringRetrievalTimes: [TimeInterval] = []
    
    // MARK: - Initialization
    
    public init(
        translationCache: TranslationCacheProtocol = TranslationCache(),
        localizationValidator: LocalizationValidatorProtocol = LocalizationValidator()
    ) {
        self.translationCache = translationCache
        self.localizationValidator = localizationValidator
        
        setupLocaleSupport()
        loadInitialCache()
        
        logger.info("StringCatalogManager initialized with \(self.availableLocales.count) supported locales")
    }
    
    // MARK: - Public API
    
    /// Get localized string for a key with performance optimization
    /// - Parameters:
    ///   - key: Localization key
    ///   - locale: Optional specific locale (defaults to current locale)
    ///   - arguments: Arguments for string interpolation
    /// - Returns: Localized and formatted string
    public func localizedString(
        for key: LocalizationKey,
        locale: Locale? = nil,
        arguments: CVarArg...
    ) -> String {
        let startTime = CFAbsoluteTimeGetCurrent()
        let targetLocale = locale ?? currentLocale
        
        // Check cache first for performance
        if let cachedString = translationCache.get(key: key.rawValue, locale: targetLocale.identifier) {
            cacheHitCount += 1
            let retrievalTime = CFAbsoluteTimeGetCurrent() - startTime
            stringRetrievalTimes.append(retrievalTime)
            
            return formatString(cachedString, with: arguments)
        }
        
        // Cache miss - retrieve from system
        cacheMissCount += 1
        let bundle = Bundle.main
        let localizedString = bundle.localizedString(forKey: key.rawValue, value: nil, table: nil)
        
        // Store in cache for future retrieval
        translationCache.set(key: key.rawValue, locale: targetLocale.identifier, translation: localizedString)
        
        let retrievalTime = CFAbsoluteTimeGetCurrent() - startTime
        stringRetrievalTimes.append(retrievalTime)
        
        logger.debug("Retrieved string for key: \(key.rawValue) in \(String(format: "%.3f", retrievalTime))ms")
        
        return formatString(localizedString, with: arguments)
    }
    
    /// Get localized string with contextual information
    /// - Parameters:
    ///   - key: Localization key
    ///   - context: Additional context for translation
    ///   - audience: Target audience for cultural adaptation
    /// - Returns: Contextually appropriate localized string
    public func localizedString(
        for key: LocalizationKey,
        context: LocalizationContext,
        audience: PrimaryAudience? = nil
    ) -> String {
        // Cultural adaptation based on audience
        if let audience = audience {
            let culturalKey = adaptKeyForAudience(key, audience: audience)
            if culturalKey != key {
                return localizedString(for: culturalKey)
            }
        }
        
        // Context-specific handling
        switch context {
        case .accessibility:
            return accessibilityOptimizedString(for: key)
        case .financial:
            return financialTermOptimizedString(for: key)
        case .cultural:
            return culturallyAdaptedString(for: key)
        case .standard:
            return localizedString(for: key)
        }
    }
    
    /// Change current locale with validation
    /// - Parameter locale: New locale to set
    /// - Returns: Success status of locale change
    @discardableResult
    public func changeLocale(to locale: Locale) -> Bool {
        guard availableLocales.contains(locale) else {
            logger.warning("Attempted to change to unsupported locale: \(locale.identifier)")
            return false
        }
        
        currentLocale = locale
        clearCache() // Clear cache to force reload with new locale
        
        logger.info("Locale changed to: \(locale.identifier)")
        
        // Notify observers of locale change
        NotificationCenter.default.post(
            name: .localeDidChange,
            object: self,
            userInfo: ["newLocale": locale]
        )
        
        return true
    }
    
    /// Validate all strings for a specific locale
    /// - Parameter locale: Locale to validate
    /// - Returns: Validation results
    public func validateStrings(for locale: Locale) async -> LocalizationValidationResult {
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Starting string validation for locale: \(locale.identifier)")
        
        // Get all translations for the locale
        let translations = LocalizationKey.allCases.reduce(into: [String: String]()) { result, key in
            result[key.rawValue] = localizedString(for: key, locale: locale)
        }
        
        let result = localizationValidator.validate(translations: translations, for: locale.identifier)
        
        logger.info("Validation completed for \(locale.identifier): \(result.statistics.validKeys) valid, \(result.statistics.invalidKeys) invalid")
        
        return result
    }
    
    /// Get performance metrics for optimization
    /// - Returns: Current performance statistics
    public func getPerformanceMetrics() -> LocalizationPerformanceMetrics {
        let averageRetrievalTime = stringRetrievalTimes.isEmpty ? 0 :
            stringRetrievalTimes.reduce(0, +) / Double(stringRetrievalTimes.count)
        
        let cacheHitRate = (cacheHitCount + cacheMissCount) == 0 ? 0 :
            Double(cacheHitCount) / Double(cacheHitCount + cacheMissCount)
        
        return LocalizationPerformanceMetrics(
            cacheHitRate: cacheHitRate,
            averageRetrievalTime: averageRetrievalTime,
            totalCacheHits: cacheHitCount,
            totalCacheMisses: cacheMissCount,
            cacheSize: translationCache.count,
            lastCacheRefresh: lastCacheRefresh
        )
    }
    
    /// Refresh cache and reload strings
    public func refreshCache() async {
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Refreshing localization cache")
        
        clearCache()
        await preloadFrequentlyUsedStrings()
        
        lastCacheRefresh = Date()
        
        logger.info("Cache refresh completed")
    }
    
    /// Get all missing translations for a locale
    /// - Parameter locale: Locale to check
    /// - Returns: Array of missing localization keys
    public func getMissingTranslations(for locale: Locale) -> [LocalizationKey] {
        LocalizationKey.allCases.filter { key in
            let string = Bundle.main.localizedString(forKey: key.rawValue, value: nil, table: nil)
            return string == key.rawValue // System returns key if translation missing
        }
    }
    
    /// Export localization data for translation services
    /// - Parameter locale: Locale to export
    /// - Returns: Dictionary suitable for external translation services
    public func exportLocalizationData(for locale: Locale) -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        exportData["locale"] = locale.identifier
        exportData["language"] = locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "en")
        exportData["export_date"] = ISO8601DateFormatter().string(from: Date())
        
        var strings: [String: Any] = [:]
        
        for category in LocalizationCategory.allCases {
            var categoryStrings: [String: String] = [:]
            
            for key in category.keys {
                let localizedString = localizedString(for: key, locale: locale)
                categoryStrings[key.rawValue] = localizedString
            }
            
            strings[category.rawValue] = categoryStrings
        }
        
        exportData["strings"] = strings
        exportData["metadata"] = [
            "total_keys": LocalizationKey.allCases.count,
            "categories": LocalizationCategory.allCases.count,
            "performance_metrics": getPerformanceMetrics().toDictionary()
        ]
        
        return exportData
    }
    
    // MARK: - Private Implementation
    
    private func setupLocaleSupport() {
        availableLocales = supportedLocaleIdentifiers.compactMap { identifier in
            Locale(identifier: identifier)
        }
        
        // Ensure current locale is supported, fallback to English if not
        if !availableLocales.contains(currentLocale) {
            currentLocale = Locale(identifier: "en")
        }
    }
    
    private func loadInitialCache() {
        Task {
            await preloadFrequentlyUsedStrings()
        }
    }
    
    private func preloadFrequentlyUsedStrings() async {
        let frequentKeys: [LocalizationKey] = [
            .generalLoading, .generalError, .generalCancel, .generalSave,
            .navDashboard, .navAssets, .navGoals,
            .finAmount, .finBalance, .finValue,
            .errorNetwork, .errorInvalidInput
        ]
        
        for key in frequentKeys {
            _ = localizedString(for: key)
        }
        
        logger.debug("Preloaded \(frequentKeys.count) frequently used strings")
    }
    
    private func formatString(_ string: String, with arguments: [CVarArg]) -> String {
        guard !arguments.isEmpty else { return string }
        return String(format: string, arguments: arguments)
    }
    
    private func clearCache() {
        translationCache.clear()
        cacheHitCount = 0
        cacheMissCount = 0
        stringRetrievalTimes.removeAll()
    }
    
    private func adaptKeyForAudience(_ key: LocalizationKey, audience: PrimaryAudience) -> LocalizationKey {
        // Cultural adaptation logic
        switch (key, audience) {
        case (.numberMillion, .indian):
            return .numberLakh
        case (.numberBillion, .indian):
            return .numberCrore
        default:
            return key
        }
    }
    
    private func accessibilityOptimizedString(for key: LocalizationKey) -> String {
        let baseString = localizedString(for: key)
        
        // Add accessibility context where appropriate
        switch key.category {
        case .financial:
            return "\(LocalizationKey.accessibilityValue.localizedString): \(baseString)"
        case .general where key.rawValue.contains("button"):
            return "\(LocalizationKey.accessibilityButton.localizedString): \(baseString)"
        default:
            return baseString
        }
    }
    
    private func financialTermOptimizedString(for key: LocalizationKey) -> String {
        let baseString = localizedString(for: key)
        
        // Add financial context for better understanding
        if key.category == .financial {
            // Could add additional context or formatting for financial terms
            return baseString
        }
        
        return baseString
    }
    
    private func culturallyAdaptedString(for key: LocalizationKey) -> String {
        // Cultural adaptation based on current locale
        let baseString = localizedString(for: key)
        
        // Apply cultural formatting rules if needed
        return baseString
    }
}

// MARK: - Supporting Types

/// Context for localization requests
public enum LocalizationContext {
    case standard
    case accessibility
    case financial
    case cultural
}

/// Performance metrics for localization system
public struct LocalizationPerformanceMetrics {
    public let cacheHitRate: Double
    public let averageRetrievalTime: TimeInterval
    public let totalCacheHits: Int
    public let totalCacheMisses: Int
    public let cacheSize: Int
    public let lastCacheRefresh: Date?
    
    public func toDictionary() -> [String: Any] {
        [
            "cache_hit_rate": cacheHitRate,
            "average_retrieval_time": averageRetrievalTime,
            "total_cache_hits": totalCacheHits,
            "total_cache_misses": totalCacheMisses,
            "cache_size": cacheSize,
            "last_cache_refresh": lastCacheRefresh?.timeIntervalSince1970 ?? 0
        ]
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let localeDidChange = Notification.Name("LocaleDidChange")
}