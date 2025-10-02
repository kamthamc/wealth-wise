import Foundation
import Combine
import CoreData

/// Main service for currency conversion with multiple data sources, caching, and batch processing
@MainActor
public final class CurrencyConversionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isUpdating: Bool = false
    @Published public private(set) var lastUpdateDate: Date?
    @Published public private(set) var lastError: Error?
    
    // MARK: - Dependencies
    
    private let providers: [ExchangeRateProvider]
    private let cache: ExchangeRateCache
    private let calculator: ConversionCalculator
    private let rateLimiter: RateLimiter
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    
    private let cacheExpiryInterval: TimeInterval = 4 * 60 * 60 // 4 hours
    private let backgroundRefreshInterval: TimeInterval = 30 * 60 // 30 minutes
    private var backgroundRefreshTimer: AnyCancellable?
    
    // MARK: - Initialization
    
    public init(
        providers: [ExchangeRateProvider]? = nil,
        cache: ExchangeRateCache? = nil,
        calculator: ConversionCalculator? = nil,
        rateLimiter: RateLimiter? = nil
    ) {
        self.providers = providers ?? Self.defaultProviders()
        self.cache = cache ?? ExchangeRateCache.shared
        self.calculator = calculator ?? ConversionCalculator.shared
        self.rateLimiter = rateLimiter ?? RateLimiter.shared
        
        setupBackgroundRefresh()
    }
    
    // MARK: - Public Methods
    
    /// Convert a single amount between currencies
    public func convert(
        _ amount: Decimal,
        from sourceCurrency: SupportedCurrency,
        to targetCurrency: SupportedCurrency
    ) async throws -> Decimal {
        // Return same amount if currencies are identical
        guard sourceCurrency != targetCurrency else { return amount }
        
        // Try to get rate from cache first
        if let cachedRate = await cache.getRate(from: sourceCurrency, to: targetCurrency),
           !cachedRate.isExpired {
            return calculator.convert(amount, using: cachedRate)
        }
        
        // Fetch fresh rate if cache miss or expired
        let rate = try await fetchExchangeRate(from: sourceCurrency, to: targetCurrency)
        return calculator.convert(amount, using: rate)
    }
    
    /// Batch convert multiple amounts for portfolio calculations
    public func batchConvert(
        _ conversions: [ConversionRequest]
    ) async throws -> [ConversionResult] {
        return try await calculator.batchConvert(conversions, using: self)
    }
    
    /// Get current exchange rate between currencies
    public func getExchangeRate(
        from sourceCurrency: SupportedCurrency,
        to targetCurrency: SupportedCurrency
    ) async throws -> ExchangeRate {
        // Return identity rate if currencies are identical
        guard sourceCurrency != targetCurrency else {
            return ExchangeRate(from: sourceCurrency, to: targetCurrency, rate: 1.0)
        }
        
        // Try cache first
        if let cachedRate = await cache.getRate(from: sourceCurrency, to: targetCurrency),
           !cachedRate.isExpired {
            return cachedRate
        }
        
        // Fetch fresh rate
        return try await fetchExchangeRate(from: sourceCurrency, to: targetCurrency)
    }
    
    /// Update all exchange rates from providers
    public func updateAllRates(baseCurrency: SupportedCurrency = .INR) async throws {
        isUpdating = true
        lastError = nil
        
        defer {
            isUpdating = false
        }
        
        // Try each provider until one succeeds
        var lastProviderError: Error?
        
        for provider in providers where provider.isAvailable {
            // Check rate limit
            guard await rateLimiter.canMakeRequest(for: provider.name) else {
                continue
            }
            
            do {
                await rateLimiter.recordRequest(for: provider.name)
                let rateSet = try await provider.fetchExchangeRates(baseCurrency: baseCurrency)
                
                // Save to cache
                await cache.saveRates(rateSet)
                
                lastUpdateDate = Date()
                return
            } catch {
                lastProviderError = error
                continue
            }
        }
        
        // All providers failed
        if let error = lastProviderError {
            lastError = error
            throw CurrencyConversionError.allProvidersFailed(underlyingError: error)
        } else {
            let error = CurrencyConversionError.noProvidersAvailable
            lastError = error
            throw error
        }
    }
    
    /// Get historical exchange rate for a specific date
    public func getHistoricalRate(
        from sourceCurrency: SupportedCurrency,
        to targetCurrency: SupportedCurrency,
        date: Date
    ) async throws -> ExchangeRate {
        // Try cache first
        if let historicalRate = await cache.getHistoricalRate(
            from: sourceCurrency,
            to: targetCurrency,
            date: date
        ) {
            return historicalRate
        }
        
        // Try providers that support historical data
        for provider in providers where provider.supportsHistoricalRates && provider.isAvailable {
            guard await rateLimiter.canMakeRequest(for: provider.name) else {
                continue
            }
            
            do {
                await rateLimiter.recordRequest(for: provider.name)
                let rate = try await provider.fetchHistoricalRate(
                    from: sourceCurrency,
                    to: targetCurrency,
                    date: date
                )
                
                // Save to cache
                await cache.saveHistoricalRate(rate)
                
                return rate
            } catch {
                continue
            }
        }
        
        throw CurrencyConversionError.historicalRateNotAvailable(date: date)
    }
    
    /// Clear all cached rates
    public func clearCache() async {
        await cache.clearAll()
    }
    
    // MARK: - Private Methods
    
    private func fetchExchangeRate(
        from sourceCurrency: SupportedCurrency,
        to targetCurrency: SupportedCurrency
    ) async throws -> ExchangeRate {
        // Try each provider until one succeeds
        for provider in providers where provider.isAvailable {
            // Check rate limit
            guard await rateLimiter.canMakeRequest(for: provider.name) else {
                continue
            }
            
            do {
                await rateLimiter.recordRequest(for: provider.name)
                let rate = try await provider.fetchExchangeRate(
                    from: sourceCurrency,
                    to: targetCurrency
                )
                
                // Save to cache
                await cache.saveRate(rate)
                
                return rate
            } catch {
                continue
            }
        }
        
        throw CurrencyConversionError.rateNotAvailable(from: sourceCurrency, to: targetCurrency)
    }
    
    private func setupBackgroundRefresh() {
        // Set up periodic background refresh
        backgroundRefreshTimer = Timer.publish(
            every: backgroundRefreshInterval,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                try? await self.updateAllRates()
            }
        }
    }
    
    private static func defaultProviders() -> [ExchangeRateProvider] {
        return [
            ExchangeRateHostProvider(),
            FixerIOProvider(),
            MockExchangeRateProvider()
        ]
    }
}

// MARK: - Singleton Access

extension CurrencyConversionService {
    public static let shared = CurrencyConversionService()
}

// MARK: - Error Types

public enum CurrencyConversionError: LocalizedError {
    case rateNotAvailable(from: SupportedCurrency, to: SupportedCurrency)
    case historicalRateNotAvailable(date: Date)
    case allProvidersFailed(underlyingError: Error)
    case noProvidersAvailable
    case rateLimitExceeded(provider: String)
    case networkError(Error)
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .rateNotAvailable(let from, let to):
            return NSLocalizedString(
                "Exchange rate not available from \(from.rawValue) to \(to.rawValue)",
                comment: "Rate not available error"
            )
        case .historicalRateNotAvailable(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return NSLocalizedString(
                "Historical rate not available for \(formatter.string(from: date))",
                comment: "Historical rate not available error"
            )
        case .allProvidersFailed(let error):
            return NSLocalizedString(
                "All providers failed: \(error.localizedDescription)",
                comment: "All providers failed error"
            )
        case .noProvidersAvailable:
            return NSLocalizedString(
                "No exchange rate providers available",
                comment: "No providers available error"
            )
        case .rateLimitExceeded(let provider):
            return NSLocalizedString(
                "Rate limit exceeded for provider: \(provider)",
                comment: "Rate limit exceeded error"
            )
        case .networkError(let error):
            return NSLocalizedString(
                "Network error: \(error.localizedDescription)",
                comment: "Network error"
            )
        case .invalidResponse:
            return NSLocalizedString(
                "Invalid response from exchange rate provider",
                comment: "Invalid response error"
            )
        }
    }
}
