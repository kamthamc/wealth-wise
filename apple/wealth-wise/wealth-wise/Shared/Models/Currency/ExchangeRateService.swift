import Foundation
import Combine

/// Protocol for exchange rate data providers
public protocol ExchangeRateProvider {
    func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> [SupportedCurrency: Decimal]
    func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> Decimal
}

/// Network-based exchange rate service
public class NetworkExchangeRateService: ExchangeRateProvider {
    private let source: ExchangeRateSource
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private var requestCount: Int = 0
    private var lastRequestTime: Date = Date()
    
    public init(source: ExchangeRateSource = .exchangeRateHost, session: URLSession = .shared) {
        self.source = source
        self.session = session
        self.decoder = JSONDecoder()
        
        // Configure decoder for different API formats
        decoder.dateDecodingStrategy = .secondsSince1970
    }
    
    public func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> [SupportedCurrency: Decimal] {
        try await checkRateLimit()
        
        let url = buildURL(for: baseCurrency)
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw ExchangeRateError.apiError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        return try parseExchangeRates(data: data, baseCurrency: baseCurrency)
    }
    
    public func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> Decimal {
        if from == to { return 1.0 }
        
        let rates = try await fetchExchangeRates(baseCurrency: from)
        guard let rate = rates[to] else {
            throw ExchangeRateError.invalidCurrencyPair
        }
        
        return rate
    }
    
    // MARK: - Private Methods
    
    private func buildURL(for baseCurrency: SupportedCurrency) -> URL {
        var urlString = source.baseURL
        
        switch source.name {
        case "ExchangeRate-API":
            urlString += "/\(baseCurrency.rawValue)"
        case "Fixer.io":
            urlString += "?base=\(baseCurrency.rawValue)"
            if let apiKey = source.apiKey {
                urlString += "&access_key=\(apiKey)"
            }
        case "Open Exchange Rates":
            urlString += "?base=\(baseCurrency.rawValue)"
            if let apiKey = source.apiKey {
                urlString += "&app_id=\(apiKey)"
            }
        default:
            urlString += "/\(baseCurrency.rawValue)"
        }
        
        return URL(string: urlString)!
    }
    
    private func parseExchangeRates(data: Data, baseCurrency: SupportedCurrency) throws -> [SupportedCurrency: Decimal] {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let rates = json?["rates"] as? [String: Double] else {
                throw ExchangeRateError.invalidResponse
            }
            
            var exchangeRates: [SupportedCurrency: Decimal] = [:]
            
            for (currencyCode, rate) in rates {
                if let currency = SupportedCurrency(rawValue: currencyCode) {
                    exchangeRates[currency] = Decimal(rate)
                }
            }
            
            return exchangeRates
        } catch {
            throw ExchangeRateError.invalidResponse
        }
    }
    
    private func checkRateLimit() async throws {
        let now = Date()
        let hoursSinceLastRequest = now.timeIntervalSince(lastRequestTime) / 3600
        
        if hoursSinceLastRequest >= 1.0 {
            requestCount = 0
            lastRequestTime = now
        }
        
        guard requestCount < source.rateLimit else {
            throw ExchangeRateError.rateLimitExceeded
        }
        
        requestCount += 1
    }
}

// MARK: - Mock Service for Testing
public class MockExchangeRateService: ExchangeRateProvider {
    private let mockRates: [SupportedCurrency: [SupportedCurrency: Decimal]]
    
    public init() {
        // Predefined mock exchange rates for testing
        self.mockRates = [
            .usd: [
                .inr: 83.50,
                .eur: 0.85,
                .gbp: 0.73,
                .jpy: 110.0,
                .cad: 1.25,
                .aud: 1.35,
                .sgd: 1.30
            ],
            .inr: [
                .usd: 0.012,
                .eur: 0.010,
                .gbp: 0.0087,
                .jpy: 1.32,
                .cad: 0.015,
                .aud: 0.016,
                .sgd: 0.0156
            ],
            .eur: [
                .usd: 1.18,
                .inr: 98.50,
                .gbp: 0.86,
                .jpy: 130.0,
                .cad: 1.47,
                .aud: 1.59,
                .sgd: 1.53
            ]
        ]
    }
    
    public func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> [SupportedCurrency: Decimal] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        guard let rates = mockRates[baseCurrency] else {
            throw ExchangeRateError.noDataAvailable
        }
        
        return rates
    }
    
    public func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> Decimal {
        if from == to { return 1.0 }
        
        let rates = try await fetchExchangeRates(baseCurrency: from)
        guard let rate = rates[to] else {
            // Try inverse rate
            let inverseRates = try await fetchExchangeRates(baseCurrency: to)
            if let inverseRate = inverseRates[from] {
                return 1 / inverseRate
            }
            throw ExchangeRateError.invalidCurrencyPair
        }
        
        return rate
    }
}