import Foundation
import Combine
import SwiftData

/// Comprehensive currency manager with real-time conversion, caching, and localized formatting
@MainActor
public class CurrencyManager: ObservableObject {
    public static let shared = CurrencyManager()
    
    // MARK: - Published Properties
    @Published public private(set) var exchangeRates: [CurrencyPair: ExchangeRate] = [:]
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastUpdated: Date?
    @Published public private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    private let exchangeRateService: ExchangeRateProvider
    private let cacheManager: ExchangeRateCacheManager
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // Configuration
    private let cacheExpiryInterval: TimeInterval = 3600 // 1 hour
    private let autoRefreshInterval: TimeInterval = 1800 // 30 minutes
    
    // MARK: - Initialization
    public init(
        exchangeRateService: ExchangeRateProvider = NetworkExchangeRateService(),
        cacheManager: ExchangeRateCacheManager = ExchangeRateCacheManager()
    ) {
        self.exchangeRateService = exchangeRateService
        self.cacheManager = cacheManager
        
        setupPeriodicRefresh()
        loadCachedRates()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Converts an amount from one currency to another
    public func convert(
        amount: Decimal,
        from fromCurrency: SupportedCurrency,
        to toCurrency: SupportedCurrency
    ) async -> Decimal {
        if fromCurrency == toCurrency {
            return amount
        }
        
        do {
            let rate = try await getExchangeRate(from: fromCurrency, to: toCurrency)
            return amount * rate
        } catch {
            print("Currency conversion error: \(error)")
            return amount // Return original amount on error
        }
    }
    
    /// Synchronous conversion using cached rates (returns nil if not available)
    public func convertSync(
        amount: Decimal,
        from fromCurrency: SupportedCurrency,
        to toCurrency: SupportedCurrency
    ) -> Decimal? {
        if fromCurrency == toCurrency {
            return amount
        }
        
        let pair = CurrencyPair(from: fromCurrency, to: toCurrency)
        
        if let cachedRate = exchangeRates[pair], cachedRate.isFresh {
            return amount * cachedRate.rate
        }
        
        // Try inverse rate
        let inversePair = pair.reversed
        if let cachedInverseRate = exchangeRates[inversePair], cachedInverseRate.isFresh {
            return amount / cachedInverseRate.rate
        }
        
        return nil
    }
    
    /// Gets exchange rate between two currencies
    public func getExchangeRate(
        from fromCurrency: SupportedCurrency,
        to toCurrency: SupportedCurrency
    ) async throws -> Decimal {
        if fromCurrency == toCurrency {
            return 1.0
        }
        
        let pair = CurrencyPair(from: fromCurrency, to: toCurrency)
        
        // Check cache first
        if let cachedRate = exchangeRates[pair], cachedRate.isFresh {
            return cachedRate.rate
        }
        
        // Check inverse rate in cache
        let inversePair = pair.reversed
        if let cachedInverseRate = exchangeRates[inversePair], cachedInverseRate.isFresh {
            let rate = 1 / cachedInverseRate.rate
            await cacheExchangeRate(ExchangeRate(from: fromCurrency, to: toCurrency, rate: rate))
            return rate
        }
        
        // Fetch from network
        return try await fetchAndCacheExchangeRate(from: fromCurrency, to: toCurrency)
    }
    
    /// Refreshes all exchange rates
    public func refreshExchangeRates() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Refresh rates for major currencies
            let majorCurrencies = SupportedCurrency.majorCurrencies
            
            for baseCurrency in majorCurrencies {
                let rates = try await exchangeRateService.fetchExchangeRates(baseCurrency: baseCurrency)
                
                for (targetCurrency, rate) in rates {
                    let exchangeRate = ExchangeRate(
                        from: baseCurrency,
                        to: targetCurrency,
                        rate: rate,
                        source: "network"
                    )
                    await cacheExchangeRate(exchangeRate)
                }
            }
            
            await MainActor.run {
                lastUpdated = Date()
                userDefaults.set(lastUpdated, forKey: "exchange_rates_last_updated")
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    /// Preloads exchange rates for a set of currencies
    public func preloadExchangeRates(for currencies: [SupportedCurrency]) async {
        for currency in currencies {
            do {
                let rates = try await exchangeRateService.fetchExchangeRates(baseCurrency: currency)
                for (targetCurrency, rate) in rates {
                    let exchangeRate = ExchangeRate(
                        from: currency,
                        to: targetCurrency,
                        rate: rate,
                        source: "preload"
                    )
                    await cacheExchangeRate(exchangeRate)
                }
            } catch {
                print("Failed to preload rates for \(currency): \(error)")
            }
        }
    }
    
    /// Gets cached exchange rate (may be stale)
    public func getCachedExchangeRate(
        from fromCurrency: SupportedCurrency,
        to toCurrency: SupportedCurrency
    ) -> ExchangeRate? {
        let pair = CurrencyPair(from: fromCurrency, to: toCurrency)
        return exchangeRates[pair]
    }
    
    /// Clears all cached exchange rates
    public func clearCache() {
        exchangeRates.removeAll()
        cacheManager.clearCache()
        userDefaults.removeObject(forKey: "exchange_rates_last_updated")
        lastUpdated = nil
    }
    
    // MARK: - Private Methods
    
    private func fetchAndCacheExchangeRate(
        from fromCurrency: SupportedCurrency,
        to toCurrency: SupportedCurrency
    ) async throws -> Decimal {
        let rate = try await exchangeRateService.fetchExchangeRate(from: fromCurrency, to: toCurrency)
        let exchangeRate = ExchangeRate(from: fromCurrency, to: toCurrency, rate: rate, source: "network")
        await cacheExchangeRate(exchangeRate)
        return rate
    }
    
    private func cacheExchangeRate(_ exchangeRate: ExchangeRate) async {
        let pair = CurrencyPair(from: exchangeRate.from, to: exchangeRate.to)
        exchangeRates[pair] = exchangeRate
        
        // Also cache the inverse rate
        let inversePair = pair.reversed
        let inverseRate = exchangeRate.inverse
        exchangeRates[inversePair] = inverseRate
        
        // Persist to disk
        await cacheManager.cacheExchangeRate(exchangeRate)
    }
    
    private func loadCachedRates() {
        Task {
            let cachedRates = await cacheManager.loadCachedRates()
            await MainActor.run {
                for rate in cachedRates {
                    let pair = CurrencyPair(from: rate.from, to: rate.to)
                    exchangeRates[pair] = rate
                }
                lastUpdated = userDefaults.object(forKey: "exchange_rates_last_updated") as? Date
            }
        }
    }
    
    private func setupPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshExchangeRates()
            }
        }
    }
}

// MARK: - Cache Manager
public class ExchangeRateCacheManager {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    public init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ExchangeRateCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    public func cacheExchangeRate(_ exchangeRate: ExchangeRate) async {
        let pair = CurrencyPair(from: exchangeRate.from, to: exchangeRate.to)
        let filename = "\(pair.pairString).json"
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        do {
            let data = try JSONEncoder().encode(exchangeRate)
            try data.write(to: fileURL)
        } catch {
            print("Failed to cache exchange rate: \(error)")
        }
    }
    
    public func loadCachedRates() async -> [ExchangeRate] {
        var cachedRates: [ExchangeRate] = []
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let exchangeRate = try JSONDecoder().decode(ExchangeRate.self, from: data)
                    
                    // Only load rates that aren't too old
                    if !exchangeRate.isStale {
                        cachedRates.append(exchangeRate)
                    } else {
                        // Remove stale cache files
                        try? fileManager.removeItem(at: fileURL)
                    }
                } catch {
                    print("Failed to load cached rate from \(fileURL): \(error)")
                    // Remove corrupted cache files
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("Failed to load cached rates: \(error)")
        }
        
        return cachedRates
    }
    
    public func clearCache() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    public static let exchangeRatesUpdated = Notification.Name("exchangeRatesUpdated")
    public static let currencyChanged = Notification.Name("currencyChanged")
}

// MARK: - Currency Change Info
public struct CurrencyChangeInfo {
    public let from: SupportedCurrency
    public let to: SupportedCurrency
    public let timestamp: Date
    
    public init(from: SupportedCurrency, to: SupportedCurrency) {
        self.from = from
        self.to = to
        self.timestamp = Date()
    }
}