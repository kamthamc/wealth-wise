import Foundation
import Combine

/// Protocol for currency management operations
public protocol CurrencyManagerProtocol: ObservableObject {
    var currentExchangeRates: ExchangeRateSet? { get }
    var baseCurrency: SupportedCurrency { get set }
    var isUpdatingRates: Bool { get }
    var lastUpdateError: Error? { get }
    
    func updateExchangeRates() async throws
    func getExchangeRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate?
    func convert(_ amount: Decimal, from: SupportedCurrency, to: SupportedCurrency) -> Decimal?
    func convert(_ amount: Double, from: SupportedCurrency, to: SupportedCurrency) -> Double?
    func getCachedRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate?
    func clearCache()
}

/// Manages currency operations and exchange rates
@MainActor
public class CurrencyManager: ObservableObject, CurrencyManagerProtocol {
    // MARK: - Published Properties
    @Published public private(set) var currentExchangeRates: ExchangeRateSet?
    @Published public var baseCurrency: SupportedCurrency = .INR
    @Published public private(set) var isUpdatingRates: Bool = false
    @Published public private(set) var lastUpdateError: Error?
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "CurrencyManager.ExchangeRates"
    private let baseCurrencyKey = "CurrencyManager.BaseCurrency"
    private let lastUpdateKey = "CurrencyManager.LastUpdate"
    private let cacheExpiryInterval: TimeInterval = 4 * 60 * 60 // 4 hours
    
    // MARK: - Initialization
    public init() {
        loadFromCache()
        setupBaseCurrency()
    }
    
    // MARK: - Public Methods
    
    /// Update exchange rates from external source
    public func updateExchangeRates() async throws {
        isUpdatingRates = true
        lastUpdateError = nil
        
        defer {
            isUpdatingRates = false
        }
        
        do {
            let newRates = try await fetchExchangeRates()
            currentExchangeRates = newRates
            saveToCache()
        } catch {
            lastUpdateError = error
            throw error
        }
    }
    
    /// Get exchange rate between two currencies
    public func getExchangeRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate? {
        // Check if we need to update rates
        if shouldUpdateRates {
            Task {
                try? await updateExchangeRates()
            }
        }
        
        return currentExchangeRates?.getRate(from: from, to: to) ?? getCachedRate(from: from, to: to)
    }
    
    /// Convert amount between currencies
    public func convert(_ amount: Decimal, from: SupportedCurrency, to: SupportedCurrency) -> Decimal? {
        guard let rate = getExchangeRate(from: from, to: to) else { return nil }
        return rate.convert(amount)
    }
    
    /// Convert amount between currencies with Double
    public func convert(_ amount: Double, from: SupportedCurrency, to: SupportedCurrency) -> Double? {
        guard let rate = getExchangeRate(from: from, to: to) else { return nil }
        return rate.convert(amount)
    }
    
    /// Get cached exchange rate without triggering update
    public func getCachedRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate? {
        return currentExchangeRates?.getRate(from: from, to: to)
    }
    
    /// Clear cached exchange rates
    public func clearCache() {
        currentExchangeRates = nil
        userDefaults.removeObject(forKey: cacheKey)
        userDefaults.removeObject(forKey: lastUpdateKey)
    }
    
    // MARK: - Private Methods
    
    private func loadFromCache() {
        // Load base currency
        if let currencyRawValue = userDefaults.string(forKey: baseCurrencyKey),
           let currency = SupportedCurrency(rawValue: currencyRawValue) {
            baseCurrency = currency
        }
        
        // Load cached exchange rates
        guard let data = userDefaults.data(forKey: cacheKey),
              let rates = try? JSONDecoder().decode(ExchangeRateSet.self, from: data) else {
            return
        }
        
        currentExchangeRates = rates
    }
    
    private func saveToCache() {
        // Save base currency
        userDefaults.set(baseCurrency.rawValue, forKey: baseCurrencyKey)
        
        // Save exchange rates
        guard let rates = currentExchangeRates,
              let data = try? JSONEncoder().encode(rates) else {
            return
        }
        
        userDefaults.set(data, forKey: cacheKey)
        userDefaults.set(Date(), forKey: lastUpdateKey)
    }
    
    private func setupBaseCurrency() {
        // Set default base currency based on locale
        if baseCurrency == .INR { // Only if not set from cache
            let locale = Locale.current
            let currencyCode: String
            currencyCode = locale.currency?.identifier ?? "INR"
            
            if let currency = SupportedCurrency(rawValue: currencyCode) {
                baseCurrency = currency
            }
        }
    }
    
    private var shouldUpdateRates: Bool {
        guard let lastUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date else {
            return true
        }
        
        return Date().timeIntervalSince(lastUpdate) > cacheExpiryInterval
    }
    
    private func fetchExchangeRates() async throws -> ExchangeRateSet {
        // For now, return mock data. In production, this would fetch from a real API
        let mockRates: [SupportedCurrency: ExchangeRate] = [
            .USD: ExchangeRate(from: baseCurrency, to: .USD, rate: 0.012, source: "Mock API"),
            .EUR: ExchangeRate(from: baseCurrency, to: .EUR, rate: 0.011, source: "Mock API"),
            .GBP: ExchangeRate(from: baseCurrency, to: .GBP, rate: 0.0095, source: "Mock API"),
            .JPY: ExchangeRate(from: baseCurrency, to: .JPY, rate: 1.8, source: "Mock API"),
            .AUD: ExchangeRate(from: baseCurrency, to: .AUD, rate: 0.018, source: "Mock API"),
            .CAD: ExchangeRate(from: baseCurrency, to: .CAD, rate: 0.016, source: "Mock API"),
            .CHF: ExchangeRate(from: baseCurrency, to: .CHF, rate: 0.011, source: "Mock API"),
            .CNY: ExchangeRate(from: baseCurrency, to: .CNY, rate: 0.087, source: "Mock API"),
            .SEK: ExchangeRate(from: baseCurrency, to: .SEK, rate: 0.13, source: "Mock API"),
            .NZD: ExchangeRate(from: baseCurrency, to: .NZD, rate: 0.02, source: "Mock API")
        ].filter { $0.key != baseCurrency }
        
        return ExchangeRateSet(baseCurrency: baseCurrency, rates: Dictionary(uniqueKeysWithValues: mockRates.map { ($0.key, $0.value) }))
    }
}

/// Singleton instance for global access
extension CurrencyManager {
    public static let shared = CurrencyManager()
}

// MARK: - Error Types
public enum CurrencyManagerError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case unsupportedCurrency(String)
    case rateNotAvailable(from: SupportedCurrency, to: SupportedCurrency)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from exchange rate service"
        case .unsupportedCurrency(let currency):
            return "Unsupported currency: \(currency)"
        case .rateNotAvailable(let from, let to):
            return "Exchange rate not available from \(from.rawValue) to \(to.rawValue)"
        }
    }
}