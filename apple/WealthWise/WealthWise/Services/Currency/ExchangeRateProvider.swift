import Foundation

/// Protocol for external exchange rate data providers
public protocol ExchangeRateProvider: Sendable {
    var name: String { get }
    var isAvailable: Bool { get }
    var supportsHistoricalRates: Bool { get }
    
    func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet
    func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> ExchangeRate
    func fetchHistoricalRate(from: SupportedCurrency, to: SupportedCurrency, date: Date) async throws -> ExchangeRate
}

// MARK: - ExchangeRate.host Provider

public struct ExchangeRateHostProvider: ExchangeRateProvider {
    public let name = "ExchangeRate.host"
    public let isAvailable = true
    public let supportsHistoricalRates = true
    
    private let baseURL = "https://api.exchangerate.host"
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet {
        let urlString = "\(baseURL)/latest?base=\(baseCurrency.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(ExchangeRateHostResponse.self, from: data)
        
        guard apiResponse.success else {
            throw CurrencyConversionError.invalidResponse
        }
        
        // Convert API response to ExchangeRateSet
        let rates = apiResponse.rates.compactMapValues { rateValue -> ExchangeRate? in
            guard let currency = SupportedCurrency(rawValue: $0.key) else { return nil }
            return ExchangeRate(
                from: baseCurrency,
                to: currency,
                rate: Decimal(rateValue),
                timestamp: Date(timeIntervalSince1970: TimeInterval(apiResponse.timestamp)),
                source: name
            )
        }
        
        return ExchangeRateSet(
            baseCurrency: baseCurrency,
            rates: Dictionary(uniqueKeysWithValues: rates.map { ($0.key, $0.value) })
        )
    }
    
    public func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> ExchangeRate {
        let urlString = "\(baseURL)/convert?from=\(from.rawValue)&to=\(to.rawValue)&amount=1"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(ExchangeRateHostConvertResponse.self, from: data)
        
        guard apiResponse.success else {
            throw CurrencyConversionError.invalidResponse
        }
        
        return ExchangeRate(
            from: from,
            to: to,
            rate: Decimal(apiResponse.result),
            timestamp: Date(timeIntervalSince1970: TimeInterval(apiResponse.info.timestamp)),
            source: name
        )
    }
    
    public func fetchHistoricalRate(from: SupportedCurrency, to: SupportedCurrency, date: Date) async throws -> ExchangeRate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)/\(dateString)?base=\(from.rawValue)&symbols=\(to.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(ExchangeRateHostResponse.self, from: data)
        
        guard apiResponse.success,
              let rateValue = apiResponse.rates[to.rawValue] else {
            throw CurrencyConversionError.historicalRateNotAvailable(date: date)
        }
        
        return ExchangeRate(
            from: from,
            to: to,
            rate: Decimal(rateValue),
            timestamp: date,
            source: name
        )
    }
}

// MARK: - Fixer.io Provider

public struct FixerIOProvider: ExchangeRateProvider {
    public let name = "Fixer.io"
    public let isAvailable: Bool
    public let supportsHistoricalRates = true
    
    private let baseURL = "https://api.fixer.io"
    private let apiKey: String?
    private let session: URLSession
    
    public init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        self.isAvailable = apiKey != nil
    }
    
    public func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet {
        guard let apiKey = apiKey else {
            throw CurrencyConversionError.noProvidersAvailable
        }
        
        let urlString = "\(baseURL)/latest?access_key=\(apiKey)&base=\(baseCurrency.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(FixerIOResponse.self, from: data)
        
        guard apiResponse.success else {
            throw CurrencyConversionError.invalidResponse
        }
        
        // Convert API response to ExchangeRateSet
        let rates = apiResponse.rates.compactMapValues { rateValue -> ExchangeRate? in
            guard let currency = SupportedCurrency(rawValue: $0.key) else { return nil }
            return ExchangeRate(
                from: baseCurrency,
                to: currency,
                rate: Decimal(rateValue),
                timestamp: Date(timeIntervalSince1970: TimeInterval(apiResponse.timestamp)),
                source: name
            )
        }
        
        return ExchangeRateSet(
            baseCurrency: baseCurrency,
            rates: Dictionary(uniqueKeysWithValues: rates.map { ($0.key, $0.value) })
        )
    }
    
    public func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> ExchangeRate {
        guard let apiKey = apiKey else {
            throw CurrencyConversionError.noProvidersAvailable
        }
        
        let urlString = "\(baseURL)/latest?access_key=\(apiKey)&base=\(from.rawValue)&symbols=\(to.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(FixerIOResponse.self, from: data)
        
        guard apiResponse.success,
              let rateValue = apiResponse.rates[to.rawValue] else {
            throw CurrencyConversionError.invalidResponse
        }
        
        return ExchangeRate(
            from: from,
            to: to,
            rate: Decimal(rateValue),
            timestamp: Date(timeIntervalSince1970: TimeInterval(apiResponse.timestamp)),
            source: name
        )
    }
    
    public func fetchHistoricalRate(from: SupportedCurrency, to: SupportedCurrency, date: Date) async throws -> ExchangeRate {
        guard let apiKey = apiKey else {
            throw CurrencyConversionError.noProvidersAvailable
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)/\(dateString)?access_key=\(apiKey)&base=\(from.rawValue)&symbols=\(to.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(FixerIOResponse.self, from: data)
        
        guard apiResponse.success,
              let rateValue = apiResponse.rates[to.rawValue] else {
            throw CurrencyConversionError.historicalRateNotAvailable(date: date)
        }
        
        return ExchangeRate(
            from: from,
            to: to,
            rate: Decimal(rateValue),
            timestamp: date,
            source: name
        )
    }
}

// MARK: - Mock Provider for Testing

public struct MockExchangeRateProvider: ExchangeRateProvider {
    public let name = "Mock Provider"
    public let isAvailable = true
    public let supportsHistoricalRates = true
    
    public init() {}
    
    public func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Mock exchange rates
        let mockRates: [SupportedCurrency: Double] = [
            .USD: 0.012,
            .EUR: 0.011,
            .GBP: 0.0095,
            .JPY: 1.8,
            .AUD: 0.018,
            .CAD: 0.016,
            .CHF: 0.011,
            .CNY: 0.087,
            .SEK: 0.13,
            .NZD: 0.02,
            .SGD: 0.016,
            .HKD: 0.094,
            .NOK: 0.13,
            .DKK: 0.082,
            .PLN: 0.049,
            .CZK: 0.28,
            .HUF: 4.3,
            .RUB: 1.1,
            .KRW: 16.2
        ]
        
        let rates = Dictionary(uniqueKeysWithValues: mockRates.compactMap { (currency, rate) -> (SupportedCurrency, ExchangeRate)? in
            guard currency != baseCurrency else { return nil }
            return (currency, ExchangeRate(from: baseCurrency, to: currency, rate: rate, source: name))
        })
        
        return ExchangeRateSet(baseCurrency: baseCurrency, rates: rates)
    }
    
    public func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> ExchangeRate {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Calculate mock rate
        let mockRate = Double.random(in: 0.5...2.0)
        
        return ExchangeRate(from: from, to: to, rate: mockRate, source: name)
    }
    
    public func fetchHistoricalRate(from: SupportedCurrency, to: SupportedCurrency, date: Date) async throws -> ExchangeRate {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Calculate mock historical rate with slight variation based on date
        let daysSinceReference = date.timeIntervalSinceReferenceDate / (24 * 60 * 60)
        let variation = sin(daysSinceReference / 30.0) * 0.1 + 1.0
        let mockRate = 0.012 * variation
        
        return ExchangeRate(from: from, to: to, rate: mockRate, timestamp: date, source: name)
    }
}

// MARK: - API Response Models

private struct ExchangeRateHostResponse: Codable {
    let success: Bool
    let timestamp: Int
    let base: String
    let date: String
    let rates: [String: Double]
}

private struct ExchangeRateHostConvertResponse: Codable {
    let success: Bool
    let query: Query
    let info: Info
    let result: Double
    
    struct Query: Codable {
        let from: String
        let to: String
        let amount: Int
    }
    
    struct Info: Codable {
        let timestamp: Int
        let rate: Double
    }
}

private struct FixerIOResponse: Codable {
    let success: Bool
    let timestamp: Int
    let base: String
    let date: String
    let rates: [String: Double]
}
