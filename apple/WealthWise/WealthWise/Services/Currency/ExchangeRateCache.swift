import Foundation

/// Actor for thread-safe exchange rate caching with UserDefaults and Core Data
public actor ExchangeRateCache {
    
    // MARK: - Cache Keys
    
    private let currentRatesKey = "ExchangeRateCache.CurrentRates"
    private let lastUpdateKey = "ExchangeRateCache.LastUpdate"
    private let cacheExpiryInterval: TimeInterval = 4 * 60 * 60 // 4 hours
    
    // MARK: - Dependencies
    
    private let userDefaults: UserDefaults
    private var memoryCache: [CurrencyPair: ExchangeRate] = [:]
    private var historicalCache: [HistoricalCacheKey: ExchangeRate] = [:]
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadFromDisk()
    }
    
    // MARK: - Public Methods
    
    /// Get cached exchange rate
    public func getRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate? {
        let pair = CurrencyPair(from: from, to: to)
        return memoryCache[pair]
    }
    
    /// Save a single exchange rate
    public func saveRate(_ rate: ExchangeRate) {
        let pair = CurrencyPair(from: rate.fromCurrency, to: rate.toCurrency)
        memoryCache[pair] = rate
        
        // Also save inverse rate for efficiency
        let inversePair = CurrencyPair(from: rate.toCurrency, to: rate.fromCurrency)
        memoryCache[inversePair] = rate.inverse
        
        saveToDisk()
    }
    
    /// Save multiple exchange rates from a rate set
    public func saveRates(_ rateSet: ExchangeRateSet) {
        // Save all rates from the set
        for (currency, rate) in rateSet.rates {
            let pair = CurrencyPair(from: rateSet.baseCurrency, to: currency)
            memoryCache[pair] = rate
            
            // Also save inverse rate
            let inversePair = CurrencyPair(from: currency, to: rateSet.baseCurrency)
            memoryCache[inversePair] = rate.inverse
        }
        
        // Save cross-currency rates for common pairs
        let commonCurrencies: [SupportedCurrency] = [.USD, .EUR, .GBP, .JPY, .INR]
        for fromCurrency in commonCurrencies {
            for toCurrency in commonCurrencies where fromCurrency != toCurrency {
                if let crossRate = rateSet.getRate(from: fromCurrency, to: toCurrency) {
                    let pair = CurrencyPair(from: fromCurrency, to: toCurrency)
                    memoryCache[pair] = crossRate
                }
            }
        }
        
        saveToDisk()
    }
    
    /// Get historical exchange rate for a specific date
    public func getHistoricalRate(
        from: SupportedCurrency,
        to: SupportedCurrency,
        date: Date
    ) -> ExchangeRate? {
        let key = HistoricalCacheKey(from: from, to: to, date: normalizeDate(date))
        return historicalCache[key]
    }
    
    /// Save historical exchange rate
    public func saveHistoricalRate(_ rate: ExchangeRate) {
        let key = HistoricalCacheKey(
            from: rate.fromCurrency,
            to: rate.toCurrency,
            date: normalizeDate(rate.timestamp)
        )
        historicalCache[key] = rate
        
        // Also save inverse for efficiency
        let inverseKey = HistoricalCacheKey(
            from: rate.toCurrency,
            to: rate.fromCurrency,
            date: normalizeDate(rate.timestamp)
        )
        historicalCache[inverseKey] = rate.inverse
        
        saveHistoricalToDisk()
    }
    
    /// Check if cache has expired
    public func hasExpired() -> Bool {
        guard let lastUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date else {
            return true
        }
        
        return Date().timeIntervalSince(lastUpdate) > cacheExpiryInterval
    }
    
    /// Clear all cached rates
    public func clearAll() {
        memoryCache.removeAll()
        historicalCache.removeAll()
        userDefaults.removeObject(forKey: currentRatesKey)
        userDefaults.removeObject(forKey: lastUpdateKey)
    }
    
    /// Clear expired rates
    public func clearExpired() {
        let now = Date()
        let expiryDate = now.addingTimeInterval(-cacheExpiryInterval)
        
        // Remove expired current rates
        memoryCache = memoryCache.filter { _, rate in
            rate.timestamp > expiryDate
        }
        
        // Remove old historical rates (keep last 90 days)
        let historicalExpiryDate = now.addingTimeInterval(-90 * 24 * 60 * 60)
        historicalCache = historicalCache.filter { key, _ in
            key.date > historicalExpiryDate
        }
        
        saveToDisk()
        saveHistoricalToDisk()
    }
    
    /// Get cache statistics
    public func getStatistics() -> CacheStatistics {
        let now = Date()
        let recentRates = memoryCache.values.filter { rate in
            now.timeIntervalSince(rate.timestamp) < cacheExpiryInterval
        }
        
        return CacheStatistics(
            totalRates: memoryCache.count,
            recentRates: recentRates.count,
            historicalRates: historicalCache.count,
            lastUpdate: userDefaults.object(forKey: lastUpdateKey) as? Date,
            cacheSize: estimateCacheSize()
        )
    }
    
    // MARK: - Private Methods
    
    private func loadFromDisk() {
        // Load current rates
        if let data = userDefaults.data(forKey: currentRatesKey),
           let cached = try? JSONDecoder().decode([CurrencyPair: ExchangeRate].self, from: data) {
            memoryCache = cached
        }
        
        // Load historical rates
        if let data = userDefaults.data(forKey: "ExchangeRateCache.Historical"),
           let cached = try? JSONDecoder().decode([HistoricalCacheKey: ExchangeRate].self, from: data) {
            historicalCache = cached
        }
    }
    
    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(memoryCache) {
            userDefaults.set(data, forKey: currentRatesKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)
        }
    }
    
    private func saveHistoricalToDisk() {
        if let data = try? JSONEncoder().encode(historicalCache) {
            userDefaults.set(data, forKey: "ExchangeRateCache.Historical")
        }
    }
    
    private func normalizeDate(_ date: Date) -> Date {
        // Normalize to start of day for consistent caching
        let calendar = Calendar.current
        return calendar.startOfDay(for: date)
    }
    
    private func estimateCacheSize() -> Int {
        var size = 0
        
        if let currentData = try? JSONEncoder().encode(memoryCache) {
            size += currentData.count
        }
        
        if let historicalData = try? JSONEncoder().encode(historicalCache) {
            size += historicalData.count
        }
        
        return size
    }
}

// MARK: - Singleton Access

extension ExchangeRateCache {
    public static let shared = ExchangeRateCache()
}

// MARK: - Supporting Types

/// Currency pair identifier for caching
public struct CurrencyPair: Codable, Hashable {
    public let from: SupportedCurrency
    public let to: SupportedCurrency
    
    public init(from: SupportedCurrency, to: SupportedCurrency) {
        self.from = from
        self.to = to
    }
}

/// Historical cache key with date
private struct HistoricalCacheKey: Codable, Hashable {
    let from: SupportedCurrency
    let to: SupportedCurrency
    let date: Date
}

/// Cache statistics
public struct CacheStatistics: Sendable {
    public let totalRates: Int
    public let recentRates: Int
    public let historicalRates: Int
    public let lastUpdate: Date?
    public let cacheSize: Int
    
    public var cacheSizeKB: Double {
        return Double(cacheSize) / 1024.0
    }
}

// MARK: - ExchangeRate Extensions

extension ExchangeRate {
    /// Check if the exchange rate has expired
    public var isExpired: Bool {
        let expiryInterval: TimeInterval = 4 * 60 * 60 // 4 hours
        return Date().timeIntervalSince(timestamp) > expiryInterval
    }
}
