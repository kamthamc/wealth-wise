import Foundation

/// Represents an exchange rate between two currencies
public struct ExchangeRate: Codable, Hashable, Equatable {
    public let fromCurrency: SupportedCurrency
    public let toCurrency: SupportedCurrency
    public let rate: Decimal
    public let timestamp: Date
    public let source: String
    
    public init(from: SupportedCurrency, to: SupportedCurrency, rate: Decimal, timestamp: Date = Date(), source: String = "Manual") {
        self.fromCurrency = from
        self.toCurrency = to
        self.rate = rate
        self.timestamp = timestamp
        self.source = source
    }
    
    /// Creates an exchange rate with Double value
    public init(from: SupportedCurrency, to: SupportedCurrency, rate: Double, timestamp: Date = Date(), source: String = "Manual") {
        self.init(from: from, to: to, rate: Decimal(rate), timestamp: timestamp, source: source)
    }
    
    /// Inverse exchange rate
    public var inverse: ExchangeRate {
        return ExchangeRate(
            from: toCurrency,
            to: fromCurrency,
            rate: 1 / rate,
            timestamp: timestamp,
            source: source
        )
    }
    
    /// Check if exchange rate is recent (within 24 hours)
    public var isRecent: Bool {
        return Date().timeIntervalSince(timestamp) < 24 * 60 * 60
    }
    
    /// Age of the exchange rate
    public var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
    
    /// Convert amount using this exchange rate
    public func convert(_ amount: Decimal) -> Decimal {
        return amount * rate
    }
    
    /// Convert amount using this exchange rate with Double
    public func convert(_ amount: Double) -> Double {
        let decimalAmount = Decimal(amount)
        let result = convert(decimalAmount)
        return NSDecimalNumber(decimal: result).doubleValue
    }
}

/// Collection of exchange rates
public struct ExchangeRateSet: Codable {
    public let baseCurrency: SupportedCurrency
    public let rates: [SupportedCurrency: ExchangeRate]
    public let lastUpdated: Date
    
    public init(baseCurrency: SupportedCurrency, rates: [SupportedCurrency: ExchangeRate], lastUpdated: Date = Date()) {
        self.baseCurrency = baseCurrency
        self.rates = rates
        self.lastUpdated = lastUpdated
    }
    
    /// Get exchange rate for specific currency pair
    public func getRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate? {
        if from == to {
            return ExchangeRate(from: from, to: to, rate: 1.0)
        }
        
        if from == baseCurrency {
            return rates[to]
        }
        
        if to == baseCurrency {
            return rates[from]?.inverse
        }
        
        // Cross-currency conversion through base currency
        guard let fromToBase = rates[from],
              let baseToTarget = rates[to] else {
            return nil
        }
        
        let crossRate = 1 / fromToBase.rate * baseToTarget.rate
        return ExchangeRate(
            from: from,
            to: to,
            rate: crossRate,
            timestamp: min(fromToBase.timestamp, baseToTarget.timestamp),
            source: "Calculated via \(baseCurrency.rawValue)"
        )
    }
    
    /// Convert amount between currencies
    public func convert(_ amount: Decimal, from: SupportedCurrency, to: SupportedCurrency) -> Decimal? {
        guard let rate = getRate(from: from, to: to) else { return nil }
        return rate.convert(amount)
    }
    
    /// Convert amount between currencies with Double
    public func convert(_ amount: Double, from: SupportedCurrency, to: SupportedCurrency) -> Double? {
        guard let rate = getRate(from: from, to: to) else { return nil }
        return rate.convert(amount)
    }
    
    /// Check if exchange rates are recent
    public var areRatesRecent: Bool {
        return rates.values.allSatisfy { $0.isRecent }
    }
    
    /// Get oldest exchange rate timestamp
    public var oldestRateTimestamp: Date? {
        return rates.values.map { $0.timestamp }.min()
    }
}