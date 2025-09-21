import Foundation

/// Represents an exchange rate between two currencies at a specific point in time
public struct ExchangeRate: Codable, Identifiable {
    public let id: UUID
    public let from: SupportedCurrency
    public let to: SupportedCurrency
    public let rate: Decimal
    public let timestamp: Date
    public let source: String
    
    public init(
        from: SupportedCurrency,
        to: SupportedCurrency,
        rate: Decimal,
        timestamp: Date = Date(),
        source: String = "unknown"
    ) {
        self.id = UUID()
        self.from = from
        self.to = to
        self.rate = rate
        self.timestamp = timestamp
        self.source = source
    }
    
    /// Creates the inverse exchange rate
    public var inverse: ExchangeRate {
        return ExchangeRate(
            from: to,
            to: from,
            rate: 1 / rate,
            timestamp: timestamp,
            source: source
        )
    }
    
    /// Age of this exchange rate
    public var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
    
    /// Whether this exchange rate is considered fresh (less than 1 hour old)
    public var isFresh: Bool {
        return age < 3600 // 1 hour
    }
    
    /// Whether this exchange rate is stale (more than 24 hours old)
    public var isStale: Bool {
        return age > 86400 // 24 hours
    }
}

/// Configuration for exchange rate data sources
public struct ExchangeRateSource {
    public let name: String
    public let baseURL: String
    public let apiKey: String?
    public let rateLimit: Int // requests per hour
    public let isReliable: Bool
    
    public init(
        name: String,
        baseURL: String,
        apiKey: String? = nil,
        rateLimit: Int = 1000,
        isReliable: Bool = true
    ) {
        self.name = name
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.rateLimit = rateLimit
        self.isReliable = isReliable
    }
    
    /// Built-in exchange rate sources
    public static let exchangeRateHost = ExchangeRateSource(
        name: "ExchangeRate-API",
        baseURL: "https://api.exchangerate-api.com/v4/latest",
        rateLimit: 1500,
        isReliable: true
    )
    
    public static let fixer = ExchangeRateSource(
        name: "Fixer.io",
        baseURL: "https://api.fixer.io/latest",
        rateLimit: 1000,
        isReliable: true
    )
    
    public static let openExchangeRates = ExchangeRateSource(
        name: "Open Exchange Rates",
        baseURL: "https://openexchangerates.org/api/latest.json",
        rateLimit: 1000,
        isReliable: true
    )
}

/// Error types for exchange rate operations
public enum ExchangeRateError: LocalizedError {
    case invalidCurrencyPair
    case networkError(Error)
    case apiError(String)
    case rateLimitExceeded
    case invalidResponse
    case noDataAvailable
    case cacheMiss
    case conversionError
    
    public var errorDescription: String? {
        switch self {
        case .invalidCurrencyPair:
            return NSLocalizedString("exchange.error.invalid_pair", 
                                    value: "Invalid currency pair", 
                                    comment: "Error for invalid currency pair")
        case .networkError(let error):
            return NSLocalizedString("exchange.error.network", 
                                    value: "Network error: \(error.localizedDescription)", 
                                    comment: "Error for network issues")
        case .apiError(let message):
            return NSLocalizedString("exchange.error.api", 
                                    value: "API error: \(message)", 
                                    comment: "Error from API")
        case .rateLimitExceeded:
            return NSLocalizedString("exchange.error.rate_limit", 
                                    value: "Rate limit exceeded", 
                                    comment: "Error for rate limit")
        case .invalidResponse:
            return NSLocalizedString("exchange.error.invalid_response", 
                                    value: "Invalid response from server", 
                                    comment: "Error for invalid response")
        case .noDataAvailable:
            return NSLocalizedString("exchange.error.no_data", 
                                    value: "No exchange rate data available", 
                                    comment: "Error for no data")
        case .cacheMiss:
            return NSLocalizedString("exchange.error.cache_miss", 
                                    value: "Exchange rate not found in cache", 
                                    comment: "Error for cache miss")
        case .conversionError:
            return NSLocalizedString("exchange.error.conversion", 
                                    value: "Currency conversion failed", 
                                    comment: "Error for conversion failure")
        }
    }
}