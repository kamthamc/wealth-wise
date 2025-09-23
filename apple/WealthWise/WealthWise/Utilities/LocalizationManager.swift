import Foundation
import SwiftUI
import Combine

/// Modern localization manager for WealthWise application
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class LocalizationManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = LocalizationManager()
    
    // MARK: - Properties
    @Published public private(set) var currentLocale: Locale = .current
    @Published public private(set) var isRTL: Bool = false
    @Published public private(set) var supportedLocales: [Locale] = []
    
    private var cachedStrings: [String: [String: String]] = [:]
    private var loadedBundles: Set<String> = []
    
    // MARK: - String Keys Enum
    public enum StringKey: String, CaseIterable {
        // MARK: - Asset Types
        case assetTypeStocks = "asset.type.stocks"
        case assetTypeBonds = "asset.type.bonds"
        case assetTypeMutualFunds = "asset.type.mutual_funds"
        case assetTypeETFs = "asset.type.etfs"
        case assetTypeRealEstate = "asset.type.real_estate"
        case assetTypeCommodities = "asset.type.commodities"
        case assetTypeCryptocurrency = "asset.type.cryptocurrency"
        case assetTypeCash = "asset.type.cash"
        case assetTypeFixedDeposits = "asset.type.fixed_deposits"
        case assetTypePPF = "asset.type.ppf"
        case assetTypeEPF = "asset.type.epf"
        case assetTypeNSC = "asset.type.nsc"
        case assetTypeGoldBonds = "asset.type.gold_bonds"
        case assetTypeTreasuryBills = "asset.type.treasury_bills"
        case assetTypeCorporateBonds = "asset.type.corporate_bonds"
        case assetTypeInternationalStocks = "asset.type.international_stocks"
        case assetTypePrivateBusiness = "asset.type.private_business"
        case assetTypeAlternativeInvestments = "asset.type.alternative_investments"
        case assetTypeInsurance = "asset.type.insurance"
        case assetTypeOther = "asset.type.other"
        
        // MARK: - Currencies
        case currencyINR = "currency.inr"
        case currencyUSD = "currency.usd"
        case currencyEUR = "currency.eur"
        case currencyGBP = "currency.gbp"
        case currencyJPY = "currency.jpy"
        case currencyCAD = "currency.cad"
        case currencyAUD = "currency.aud"
        case currencyCHF = "currency.chf"
        case currencyCNY = "currency.cny"
        case currencySGD = "currency.sgd"
        
        // MARK: - Countries
        case countryIndia = "country.india"
        case countryUnitedStates = "country.united_states"
        case countryUnitedKingdom = "country.united_kingdom"
        case countryCanada = "country.canada"
        case countryAustralia = "country.australia"
        case countrySingapore = "country.singapore"
        case countryGermany = "country.germany"  
        case countryFrance = "country.france"
        case countryJapan = "country.japan"
        case countrySwitzerland = "country.switzerland"
        
        // MARK: - General UI
        case generalLoading = "general.loading"
        case generalError = "general.error"
        case generalCancel = "general.cancel"
        case generalOK = "general.ok"
        case generalSave = "general.save"
        case generalDelete = "general.delete"
        case generalEdit = "general.edit"
        case generalAdd = "general.add"
        case generalRemove = "general.remove"
        case generalSettings = "general.settings"
        case generalBack = "general.back"
        case generalNext = "general.next"
        case generalDone = "general.done"
        case generalAppName = "general.app_name"
        
        // MARK: - Financial Terms
        case financialPortfolio = "financial.portfolio"
        case financialAssets = "financial.assets"
        case financialLiabilities = "financial.liabilities"
        case financialInvestment = "financial.investment"
        case financialReturns = "financial.returns"
        case financialRisk = "financial.risk"
        case financialAllocation = "financial.allocation"
        case financialPerformance = "financial.performance"
        case financialDividend = "financial.dividend"
        case financialInterest = "financial.interest"
        case financialCapitalGains = "financial.capital_gains"
        case financialNetWorth = "financial.net_worth"
        case financialTotalValue = "financial.total_value"
        case financialUnrealizedGain = "financial.unrealized_gain"
        case financialRealizedGain = "financial.realized_gain"
        
        // MARK: - Error Messages
        case errorNetwork = "error.network"
        case errorInvalidData = "error.invalid_data"
        case errorAuthentication = "error.authentication"
        case errorPermissionDenied = "error.permission_denied"
        case errorFileNotFound = "error.file_not_found"
        case errorUnknown = "error.unknown"
        
        // MARK: - Success Messages
        case successSaved = "success.saved"
        case successUpdated = "success.updated"
        case successDeleted = "success.deleted"
        case successUploaded = "success.uploaded"
        case successSynchronized = "success.synchronized"
        
        // MARK: - Time Periods
        case timeDaily = "time.daily"
        case timeWeekly = "time.weekly"
        case timeMonthly = "time.monthly"
        case timeQuarterly = "time.quarterly"
        case timeYearly = "time.yearly"
        case timeAllTime = "time.all_time"
        case time1Year = "time.1_year"
        case time3Years = "time.3_years"
        case time5Years = "time.5_years"
        
        // MARK: - Number Formats
        case formatLakh = "format.lakh"
        case formatCrore = "format.crore"
        case formatMillion = "format.million"
        case formatBillion = "format.billion"
        case formatThousand = "format.thousand"
    }
    
    // MARK: - Supported Locales
    public static let defaultLocales: [String] = [
        "en-IN", "hi-IN", "ta-IN", "bn-IN", "te-IN", "mr-IN", "gu-IN", 
        "kn-IN", "ml-IN", "pa-IN", "en-US", "en-GB", "en-CA", "en-AU", 
        "de-DE", "fr-FR", "ja-JP", "zh-CN", "ar-SA", "es-ES", "pt-BR", 
        "ru-RU", "ko-KR"
    ]
    
    // MARK: - Initialization
    private init() {
        setupSupportedLocales()
        updateLocaleInfo()
        
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.updateLocaleInfo()
                self.clearCache()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    /// Get localized string with fallback mechanism
    public func localizedString(for key: StringKey, defaultValue: String? = nil) -> String {
        let keyString = key.rawValue
        let bundle = Bundle.main
        
        // Try current locale first
        if let localizedString = getLocalizedString(key: keyString, locale: currentLocale.identifier, bundle: bundle),
           !localizedString.isEmpty && localizedString != keyString {
            return localizedString
        }
        
        // Fallback to English (India)
        if currentLocale.identifier != "en-IN" {
            if let fallbackString = getLocalizedString(key: keyString, locale: "en-IN", bundle: bundle),
               !fallbackString.isEmpty && fallbackString != keyString {
                return fallbackString
            }
        }
        
        // Fallback to base English
        if !currentLocale.identifier.hasPrefix("en") {
            if let englishString = getLocalizedString(key: keyString, locale: "en", bundle: bundle),
               !englishString.isEmpty && englishString != keyString {
                return englishString
            }
        }
        
        // Use provided default or key as last resort
        return defaultValue ?? keyString.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: ".", with: " ").capitalized
    }
    
    /// Format currency with localization
    public func formatCurrency(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = currentLocale
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
    
    /// Format large numbers with cultural preferences
    public func formatLargeNumber(_ value: Decimal) -> String {
        let number = value as NSDecimalNumber
        let doubleValue = number.doubleValue
        
        // Use Indian numbering system for Indian locales
        if currentLocale.identifier.hasPrefix("en-IN") || currentLocale.identifier.hasPrefix("hi") {
            if doubleValue >= 10_000_000 {
                return String(format: "%.2f %@", doubleValue / 10_000_000, localizedString(for: .formatCrore))
            } else if doubleValue >= 100_000 {
                return String(format: "%.2f %@", doubleValue / 100_000, localizedString(for: .formatLakh))
            } else if doubleValue >= 1_000 {
                return String(format: "%.2f %@", doubleValue / 1_000, localizedString(for: .formatThousand))
            }
        } else {
            // International system (Million, Billion)
            if doubleValue >= 1_000_000_000 {
                return String(format: "%.2f %@", doubleValue / 1_000_000_000, localizedString(for: .formatBillion))
            } else if doubleValue >= 1_000_000 {
                return String(format: "%.2f %@", doubleValue / 1_000_000, localizedString(for: .formatMillion))
            } else if doubleValue >= 1_000 {
                return String(format: "%.2f %@", doubleValue / 1_000, localizedString(for: .formatThousand))
            }
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = currentLocale
        return formatter.string(from: number) ?? "0"
    }
    
    // MARK: - Private Methods
    
    private func setupSupportedLocales() {
        supportedLocales = Self.defaultLocales.compactMap { Locale(identifier: $0) }
    }
    
    private func updateLocaleInfo() {
        currentLocale = .current
        // Use backward compatible approach for RTL detection
        isRTL = Locale.Language(identifier: currentLocale.language.languageCode?.identifier ?? "en").characterDirection == .rightToLeft
    }
    
    private func clearCache() {
        cachedStrings.removeAll()
        loadedBundles.removeAll()
    }
    
    private func getLocalizedString(key: String, locale: String, bundle: Bundle) -> String? {
        // Check cache first
        if let cachedValue = cachedStrings[locale]?[key] {
            return cachedValue
        }
        
        // Load from bundle
        guard let path = bundle.path(forResource: locale, ofType: "lproj"),
              let localeBundle = Bundle(path: path) else {
            return nil
        }
        
        let localizedString = localeBundle.localizedString(forKey: key, value: nil, table: nil)
        
        // Cache the result
        if cachedStrings[locale] == nil {
            cachedStrings[locale] = [:]
        }
        cachedStrings[locale]?[key] = localizedString
        
        return localizedString == key ? nil : localizedString
    }
    
    // MARK: - Static Convenience Methods
    public static func localized(_ key: StringKey) -> String {
        return shared.localizedString(for: key)
    }
}

// MARK: - SwiftUI Integration

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
extension Text {
    /// Initialize Text with localized string key
    public init(_ key: LocalizationManager.StringKey) {
        self = Text(LocalizationManager.shared.localizedString(for: key))
    }
}
