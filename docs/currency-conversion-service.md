# Currency Conversion Service Documentation

## Overview

The Currency Conversion Service provides a robust, production-ready solution for currency conversion with real-time exchange rates, offline caching, batch processing, and comprehensive error handling.

## Architecture

### Components

1. **CurrencyConversionService** - Main service orchestrating all currency operations
2. **ExchangeRateProvider** - Protocol for external rate data sources
3. **ExchangeRateCache** - Actor-based caching with persistence
4. **ConversionCalculator** - High-performance batch processing
5. **RateLimiter** - API quota management

### Design Patterns

- **Actor Isolation**: All components use Swift 6 actor isolation for thread safety
- **Provider Pattern**: Multiple fallback providers for high availability
- **Cache-First Strategy**: Minimizes API calls by checking cache before fetching
- **Batch Optimization**: Groups conversions by currency pair to reduce API calls

## Basic Usage

### Single Currency Conversion

```swift
let service = CurrencyConversionService.shared

// Convert amount
let convertedAmount = try await service.convert(
    100,
    from: .USD,
    to: .EUR
)

print("100 USD = \(convertedAmount) EUR")
```

### Get Exchange Rate

```swift
let rate = try await service.getExchangeRate(
    from: .USD,
    to: .EUR
)

print("1 USD = \(rate.rate) EUR")
print("Source: \(rate.source)")
print("Timestamp: \(rate.timestamp)")
```

### Batch Conversion (Portfolio)

```swift
let conversions = [
    ConversionRequest(amount: 1000, sourceCurrency: .USD, targetCurrency: .INR),
    ConversionRequest(amount: 2000, sourceCurrency: .EUR, targetCurrency: .INR),
    ConversionRequest(amount: 3000, sourceCurrency: .GBP, targetCurrency: .INR)
]

let results = try await service.batchConvert(conversions)

for result in results {
    if result.success {
        print("\(result.request.amount) \(result.request.sourceCurrency) = \(result.result) \(result.request.targetCurrency)")
    } else {
        print("Conversion failed: \(result.error?.localizedDescription ?? "Unknown error")")
    }
}
```

### Portfolio Value Calculation

```swift
let calculator = ConversionCalculator.shared
let service = CurrencyConversionService.shared

let holdings = [
    PortfolioHolding(assetId: "stock1", value: 10000, currency: .USD),
    PortfolioHolding(assetId: "bond1", value: 5000, currency: .EUR),
    PortfolioHolding(assetId: "fund1", value: 8000, currency: .GBP)
]

let portfolioValue = try await calculator.calculatePortfolioValue(
    holdings,
    targetCurrency: .INR,
    using: service
)

print("Total Portfolio Value: \(portfolioValue.totalValue) INR")
print("Success Rate: \(portfolioValue.successRate * 100)%")
```

### Currency Breakdown

```swift
let breakdown = try await calculator.calculateCurrencyBreakdown(
    holdings,
    targetCurrency: .INR,
    using: service
)

print("Total: \(breakdown.totalValue) \(breakdown.targetCurrency)")

for item in breakdown.items {
    print("\(item.currency): \(item.nativeValue) = \(item.convertedValue) \(item.targetCurrency) (\(item.percentage)%)")
}
```

## Advanced Usage

### Historical Exchange Rates

```swift
let historicalDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

let historicalRate = try await service.getHistoricalRate(
    from: .USD,
    to: .EUR,
    date: historicalDate
)

print("Rate on \(historicalDate): \(historicalRate.rate)")
```

### Manual Rate Updates

```swift
// Update all rates from providers
try await service.updateAllRates(baseCurrency: .INR)

print("Rates updated at: \(service.lastUpdateDate ?? Date())")
```

### Cache Management

```swift
// Clear all cached rates
await service.clearCache()

// Check cache statistics
let cache = ExchangeRateCache.shared
let stats = await cache.getStatistics()

print("Total cached rates: \(stats.totalRates)")
print("Recent rates: \(stats.recentRates)")
print("Historical rates: \(stats.historicalRates)")
print("Cache size: \(stats.cacheSizeKB) KB")
```

### Rate Limiter Monitoring

```swift
let rateLimiter = RateLimiter.shared

// Check usage for a provider
if let stats = await rateLimiter.getUsageStats(for: "ExchangeRate.host") {
    print("Requests this minute: \(stats.requestsThisMinute)")
    print("Remaining: \(stats.remainingMinute)")
    print("Utilization: \(stats.utilizationPercentage)%")
    
    if stats.isNearLimit {
        print("Warning: Near rate limit!")
    }
}

// Get recommended wait time
if let waitTime = await rateLimiter.recommendedWaitTime(for: "ExchangeRate.host") {
    print("Wait \(waitTime) seconds before next request")
}
```

## Exchange Rate Providers

### ExchangeRate.host (Default, Free)

- **API**: https://exchangerate.host
- **Rate Limits**: 60/min, 1000/hour, 10000/day
- **Features**: Current rates, historical rates, free tier
- **Authentication**: Not required

### Fixer.io (Premium)

- **API**: https://fixer.io
- **Rate Limits**: 10/min, 100/hour, 1000/day (free tier)
- **Features**: Current rates, historical rates, accurate data
- **Authentication**: API key required

Configuration:
```swift
let fixerProvider = FixerIOProvider(apiKey: "YOUR_API_KEY")
let service = CurrencyConversionService(providers: [fixerProvider])
```

### Mock Provider (Testing)

- **Purpose**: Testing and development
- **Rate Limits**: 100/min, 10000/hour, 100000/day
- **Features**: Instant responses, no network calls
- **Authentication**: Not required

## Error Handling

### Error Types

```swift
enum CurrencyConversionError: LocalizedError {
    case rateNotAvailable(from: SupportedCurrency, to: SupportedCurrency)
    case historicalRateNotAvailable(date: Date)
    case allProvidersFailed(underlyingError: Error)
    case noProvidersAvailable
    case rateLimitExceeded(provider: String)
    case networkError(Error)
    case invalidResponse
}
```

### Best Practices

```swift
do {
    let rate = try await service.getExchangeRate(from: .USD, to: .EUR)
    // Use rate
} catch CurrencyConversionError.rateNotAvailable(let from, let to) {
    print("Rate not available: \(from) to \(to)")
} catch CurrencyConversionError.rateLimitExceeded(let provider) {
    print("Rate limit exceeded for: \(provider)")
    // Wait and retry
} catch CurrencyConversionError.networkError(let error) {
    print("Network error: \(error.localizedDescription)")
    // Use cached rates if available
} catch {
    print("Unexpected error: \(error.localizedDescription)")
}
```

## Performance Optimization

### Batch Processing

When converting multiple amounts, always use batch conversion:

```swift
// ❌ Inefficient - Multiple API calls
for conversion in conversions {
    let result = try await service.convert(
        conversion.amount,
        from: conversion.sourceCurrency,
        to: conversion.targetCurrency
    )
}

// ✅ Efficient - Grouped API calls
let results = try await service.batchConvert(conversions)
```

### Pre-fetch Rates

For large portfolios, pre-fetch all needed rates:

```swift
// Update all rates once
try await service.updateAllRates(baseCurrency: .INR)

// Then use cached rates for multiple conversions
let conversions = // ... large list
let results = try await service.batchConvert(conversions)
```

### Cache Expiry

Default cache expiry is 4 hours. Adjust based on needs:

```swift
// Check if cache has expired
let hasExpired = await cache.hasExpired()

if hasExpired {
    try await service.updateAllRates()
}
```

## Testing

### Unit Tests

The service includes comprehensive test coverage:

- `CurrencyConversionServiceTests` - Service functionality
- `ExchangeRateCacheTests` - Caching behavior
- `ConversionCalculatorTests` - Calculation accuracy

Run tests:
```bash
xcodebuild test -project apple/WealthWise/WealthWise.xcodeproj -scheme WealthWise
```

### Mock Provider

Use the mock provider for testing:

```swift
let mockProvider = MockExchangeRateProvider()
let testService = CurrencyConversionService(providers: [mockProvider])

// No network calls, instant responses
let rate = try await testService.getExchangeRate(from: .USD, to: .EUR)
```

### Test Cache

Use separate UserDefaults for tests:

```swift
let testDefaults = UserDefaults(suiteName: "test")!
let testCache = ExchangeRateCache(userDefaults: testDefaults)

// Run tests
// ...

// Cleanup
await testCache.clearAll()
testDefaults.removePersistentDomain(forName: "test")
```

## Observing State Changes

The service is an `ObservableObject` for SwiftUI integration:

```swift
@StateObject private var service = CurrencyConversionService.shared

var body: some View {
    VStack {
        if service.isUpdating {
            ProgressView("Updating rates...")
        }
        
        if let error = service.lastError {
            Text("Error: \(error.localizedDescription)")
                .foregroundColor(.red)
        }
        
        if let lastUpdate = service.lastUpdateDate {
            Text("Last updated: \(lastUpdate, style: .relative)")
                .font(.caption)
        }
    }
}
```

## Background Refresh

The service automatically refreshes rates every 30 minutes:

```swift
// Automatic background refresh is enabled by default
let service = CurrencyConversionService.shared

// Disable by creating service without timer
// (Custom implementation would be needed)
```

## API Key Security

Store API keys securely:

```swift
// ❌ Don't hardcode API keys
let provider = FixerIOProvider(apiKey: "hardcoded_key")

// ✅ Use environment variables or Keychain
import Foundation

extension Bundle {
    var fixerAPIKey: String? {
        return infoDictionary?["FIXER_API_KEY"] as? String
    }
}

let provider = FixerIOProvider(apiKey: Bundle.main.fixerAPIKey)
```

## Integration with Existing Systems

### CurrencyService Integration

The new service works alongside the existing `CurrencyService`:

```swift
// Use existing CurrencyService for formatting
let currencyService = CurrencyService.shared
let formattedAmount = currencyService.formatAmount(amount, currency: .USD)

// Use new CurrencyConversionService for conversion
let conversionService = CurrencyConversionService.shared
let converted = try await conversionService.convert(amount, from: .USD, to: .EUR)
```

### Core Data Integration

The cache can be extended to use Core Data for historical rates:

```swift
// Current implementation uses UserDefaults
// For production, consider Core Data for better performance
// See ExchangeRateCache implementation for extension points
```

## Rate Limits Summary

| Provider | Per Minute | Per Hour | Per Day |
|----------|-----------|----------|---------|
| ExchangeRate.host | 60 | 1,000 | 10,000 |
| Fixer.io (Free) | 10 | 100 | 1,000 |
| Mock Provider | 100 | 10,000 | 100,000 |

## Troubleshooting

### Issue: Rate not available

**Solution**: Check if providers are configured correctly and have valid API keys.

### Issue: Rate limit exceeded

**Solution**: Implement exponential backoff or use cached rates until limit resets.

### Issue: Stale cache

**Solution**: Manually clear cache or reduce cache expiry interval.

### Issue: Network errors

**Solution**: Ensure internet connectivity and provider API status. Fallback providers will be tried automatically.

## Future Enhancements

- Core Data persistence for historical rates
- WebSocket support for real-time rate updates
- Additional provider integrations (CurrencyAPI, Open Exchange Rates)
- Machine learning for rate prediction
- Cryptocurrency support
- Custom rate expiry per currency pair

## License

This implementation is part of the WealthWise project and follows the same license.

## Support

For issues or questions, please refer to the main WealthWise documentation or open an issue on GitHub.
