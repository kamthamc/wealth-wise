# Currency API Integration Guide

## Overview

This guide provides detailed information about integrating external currency exchange rate APIs with the WealthWise Currency Conversion Service.

## Supported APIs

### 1. ExchangeRate.host API

#### Overview
- **URL**: https://api.exchangerate.host
- **Cost**: Free
- **Authentication**: None required
- **Rate Limits**: 60/min, 1000/hour, 10000/day

#### Endpoints

**Latest Rates**
```http
GET https://api.exchangerate.host/latest?base=USD
```

Response:
```json
{
  "success": true,
  "timestamp": 1633024800,
  "base": "USD",
  "date": "2021-09-30",
  "rates": {
    "EUR": 0.85,
    "GBP": 0.73,
    "JPY": 110.5,
    "INR": 74.2
  }
}
```

**Single Conversion**
```http
GET https://api.exchangerate.host/convert?from=USD&to=EUR&amount=100
```

Response:
```json
{
  "success": true,
  "query": {
    "from": "USD",
    "to": "EUR",
    "amount": 100
  },
  "info": {
    "timestamp": 1633024800,
    "rate": 0.85
  },
  "result": 85.0
}
```

**Historical Rates**
```http
GET https://api.exchangerate.host/2021-09-30?base=USD&symbols=EUR,GBP
```

Response:
```json
{
  "success": true,
  "timestamp": 1633024800,
  "base": "USD",
  "date": "2021-09-30",
  "rates": {
    "EUR": 0.85,
    "GBP": 0.73
  }
}
```

#### Implementation

```swift
public struct ExchangeRateHostProvider: ExchangeRateProvider {
    public let name = "ExchangeRate.host"
    public let isAvailable = true
    public let supportsHistoricalRates = true
    
    private let baseURL = "https://api.exchangerate.host"
    
    public func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet {
        let urlString = "\(baseURL)/latest?base=\(baseCurrency.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(ExchangeRateHostResponse.self, from: data)
        // Convert to ExchangeRateSet
        // ...
    }
}
```

### 2. Fixer.io API

#### Overview
- **URL**: https://api.fixer.io
- **Cost**: Free tier available, paid plans for higher limits
- **Authentication**: API key required
- **Rate Limits**: 100/month (free), unlimited (paid)

#### Registration

1. Sign up at https://fixer.io
2. Get your API key from dashboard
3. Configure in app:

```swift
let fixerProvider = FixerIOProvider(apiKey: "YOUR_API_KEY")
let service = CurrencyConversionService(providers: [fixerProvider])
```

#### Endpoints

**Latest Rates**
```http
GET https://api.fixer.io/latest?access_key=YOUR_API_KEY&base=USD
```

Response:
```json
{
  "success": true,
  "timestamp": 1633024800,
  "base": "USD",
  "date": "2021-09-30",
  "rates": {
    "EUR": 0.85,
    "GBP": 0.73,
    "JPY": 110.5
  }
}
```

**Historical Rates**
```http
GET https://api.fixer.io/2021-09-30?access_key=YOUR_API_KEY&base=USD
```

#### Security Best Practices

**Store API Keys Securely**

1. Use Info.plist:
```xml
<key>FIXER_API_KEY</key>
<string>your_api_key_here</string>
```

2. Load in code:
```swift
extension Bundle {
    var fixerAPIKey: String? {
        return infoDictionary?["FIXER_API_KEY"] as? String
    }
}
```

3. Use Keychain for production:
```swift
import Security

class KeychainService {
    static func saveAPIKey(_ key: String, for service: String) {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func getAPIKey(for service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// Usage
if let apiKey = KeychainService.getAPIKey(for: "fixer.io") {
    let provider = FixerIOProvider(apiKey: apiKey)
}
```

### 3. Custom Provider Implementation

You can implement your own provider by conforming to the `ExchangeRateProvider` protocol:

```swift
public protocol ExchangeRateProvider: Sendable {
    var name: String { get }
    var isAvailable: Bool { get }
    var supportsHistoricalRates: Bool { get }
    
    func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet
    func fetchExchangeRate(from: SupportedCurrency, to: SupportedCurrency) async throws -> ExchangeRate
    func fetchHistoricalRate(from: SupportedCurrency, to: SupportedCurrency, date: Date) async throws -> ExchangeRate
}
```

#### Example: Open Exchange Rates

```swift
public struct OpenExchangeRatesProvider: ExchangeRateProvider {
    public let name = "Open Exchange Rates"
    public let isAvailable: Bool
    public let supportsHistoricalRates = true
    
    private let baseURL = "https://openexchangerates.org/api"
    private let appId: String?
    private let session: URLSession
    
    public init(appId: String? = nil, session: URLSession = .shared) {
        self.appId = appId
        self.session = session
        self.isAvailable = appId != nil
    }
    
    public func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet {
        guard let appId = appId else {
            throw CurrencyConversionError.noProvidersAvailable
        }
        
        let urlString = "\(baseURL)/latest.json?app_id=\(appId)&base=\(baseCurrency.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(OpenExchangeRatesResponse.self, from: data)
        
        // Convert to ExchangeRateSet
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
        // Implementation similar to fetchExchangeRates but for single pair
        let rateSet = try await fetchExchangeRates(baseCurrency: from)
        guard let rate = rateSet.rates[to] else {
            throw CurrencyConversionError.rateNotAvailable(from: from, to: to)
        }
        return rate
    }
    
    public func fetchHistoricalRate(from: SupportedCurrency, to: SupportedCurrency, date: Date) async throws -> ExchangeRate {
        guard let appId = appId else {
            throw CurrencyConversionError.noProvidersAvailable
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let urlString = "\(baseURL)/historical/\(dateString).json?app_id=\(appId)&base=\(from.rawValue)&symbols=\(to.rawValue)"
        guard let url = URL(string: urlString) else {
            throw CurrencyConversionError.invalidResponse
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw CurrencyConversionError.networkError(URLError(.badServerResponse))
        }
        
        let apiResponse = try JSONDecoder().decode(OpenExchangeRatesResponse.self, from: data)
        
        guard let rateValue = apiResponse.rates[to.rawValue] else {
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

// Response model
private struct OpenExchangeRatesResponse: Codable {
    let timestamp: Int
    let base: String
    let rates: [String: Double]
}
```

## Rate Limiting Strategy

### Exponential Backoff

Implement retry logic with exponential backoff:

```swift
func fetchWithRetry<T>(
    maxAttempts: Int = 3,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            // Check if rate limit error
            if let conversionError = error as? CurrencyConversionError,
               case .rateLimitExceeded = conversionError {
                
                // Exponential backoff: 2^attempt seconds
                let waitTime = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                continue
            }
            
            // For other errors, fail immediately
            throw error
        }
    }
    
    throw lastError ?? CurrencyConversionError.allProvidersFailed(
        underlyingError: NSError(domain: "RetryExhausted", code: -1)
    )
}

// Usage
let rate = try await fetchWithRetry {
    try await service.getExchangeRate(from: .USD, to: .EUR)
}
```

### Request Queuing

Queue requests to respect rate limits:

```swift
actor RequestQueue {
    private var queue: [() async throws -> Void] = []
    private var isProcessing = false
    private let requestsPerSecond: Double
    
    init(requestsPerSecond: Double) {
        self.requestsPerSecond = requestsPerSecond
    }
    
    func enqueue(_ operation: @escaping () async throws -> Void) {
        queue.append(operation)
        if !isProcessing {
            Task {
                await processQueue()
            }
        }
    }
    
    private func processQueue() async {
        isProcessing = true
        
        while !queue.isEmpty {
            let operation = queue.removeFirst()
            
            do {
                try await operation()
            } catch {
                print("Operation failed: \(error)")
            }
            
            // Wait between requests to respect rate limit
            let waitTime = 1.0 / requestsPerSecond
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        isProcessing = false
    }
}

// Usage
let requestQueue = RequestQueue(requestsPerSecond: 1.0) // 1 request per second

await requestQueue.enqueue {
    _ = try await service.getExchangeRate(from: .USD, to: .EUR)
}
```

## Error Handling

### Network Errors

```swift
do {
    let rate = try await service.getExchangeRate(from: .USD, to: .EUR)
} catch CurrencyConversionError.networkError(let error) {
    // Check if offline
    if (error as NSError).code == NSURLErrorNotConnectedToInternet {
        // Use cached rates
        let cachedRate = await cache.getRate(from: .USD, to: .EUR)
        if let rate = cachedRate, !rate.isExpired {
            // Use cached rate
        } else {
            // Show offline message
        }
    }
}
```

### Provider Fallback

The service automatically tries fallback providers:

```swift
let service = CurrencyConversionService(
    providers: [
        ExchangeRateHostProvider(),  // Try first
        FixerIOProvider(apiKey: apiKey),  // Fallback if first fails
        MockExchangeRateProvider()   // Last resort (for testing)
    ]
)

// Service will try each provider in order until one succeeds
let rate = try await service.getExchangeRate(from: .USD, to: .EUR)
```

## Performance Monitoring

### Track API Response Times

```swift
actor PerformanceMonitor {
    private var responseTimes: [String: [TimeInterval]] = [:]
    
    func recordResponseTime(_ time: TimeInterval, for provider: String) {
        responseTimes[provider, default: []].append(time)
    }
    
    func getAverageResponseTime(for provider: String) -> TimeInterval? {
        guard let times = responseTimes[provider], !times.isEmpty else {
            return nil
        }
        return times.reduce(0, +) / TimeInterval(times.count)
    }
    
    func getStatistics() -> [String: Statistics] {
        return responseTimes.mapValues { times in
            Statistics(
                average: times.reduce(0, +) / TimeInterval(times.count),
                min: times.min() ?? 0,
                max: times.max() ?? 0,
                count: times.count
            )
        }
    }
}

struct Statistics {
    let average: TimeInterval
    let min: TimeInterval
    let max: TimeInterval
    let count: Int
}

// Usage
let monitor = PerformanceMonitor()

let startTime = Date()
let rate = try await service.getExchangeRate(from: .USD, to: .EUR)
let responseTime = Date().timeIntervalSince(startTime)

await monitor.recordResponseTime(responseTime, for: "ExchangeRate.host")
```

## Testing

### Mock Network Responses

```swift
class MockURLProtocol: URLProtocol {
    static var mockResponses: [URL: (Data, HTTPURLResponse)] = [:]
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let (data, response) = MockURLProtocol.mockResponses[url] else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

// Setup mock
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]
let mockSession = URLSession(configuration: config)

let mockURL = URL(string: "https://api.exchangerate.host/latest?base=USD")!
let mockData = """
{
  "success": true,
  "timestamp": 1633024800,
  "base": "USD",
  "date": "2021-09-30",
  "rates": {
    "EUR": 0.85
  }
}
""".data(using: .utf8)!

let mockResponse = HTTPURLResponse(
    url: mockURL,
    statusCode: 200,
    httpVersion: nil,
    headerFields: nil
)!

MockURLProtocol.mockResponses[mockURL] = (mockData, mockResponse)

// Test with mock session
let provider = ExchangeRateHostProvider(session: mockSession)
let rateSet = try await provider.fetchExchangeRates(baseCurrency: .USD)
```

## Best Practices

1. **Use Multiple Providers**: Configure multiple providers for redundancy
2. **Cache Aggressively**: Use cache to minimize API calls
3. **Handle Errors Gracefully**: Always have fallback mechanisms
4. **Monitor Rate Limits**: Track usage to avoid hitting limits
5. **Secure API Keys**: Never hardcode keys, use Keychain
6. **Test Thoroughly**: Use mock providers for testing
7. **Batch Requests**: Group conversions when possible
8. **Update Regularly**: Keep rates fresh with background updates

## Troubleshooting

### Common Issues

**Issue**: API returns 401 Unauthorized
**Solution**: Check API key is valid and properly configured

**Issue**: API returns 429 Too Many Requests
**Solution**: Implement rate limiting and exponential backoff

**Issue**: Slow response times
**Solution**: Use caching, batch requests, and monitor provider performance

**Issue**: Invalid currency codes
**Solution**: Ensure using `SupportedCurrency` enum values

## Resources

- [ExchangeRate.host Documentation](https://exchangerate.host/#/)
- [Fixer.io Documentation](https://fixer.io/documentation)
- [URLSession Documentation](https://developer.apple.com/documentation/foundation/urlsession)
- [Actor Isolation Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
