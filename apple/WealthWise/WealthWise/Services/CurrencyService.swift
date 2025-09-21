import Foundation
import Combine

/// Protocol for external currency data sources
public protocol CurrencyDataSource {
    func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet
    var name: String { get }
    var isAvailable: Bool { get }
}

/// Main service for currency operations
@MainActor
public class CurrencyService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastError: Error?
    
    // MARK: - Private Properties
    private let currencyManager: any CurrencyManagerProtocol
    private let currencyFormatter: CurrencyFormatter
    private var dataSources: [any CurrencyDataSource] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(currencyManager: any CurrencyManagerProtocol = CurrencyManager.shared,
                currencyFormatter: CurrencyFormatter = CurrencyFormatter.shared) {
        self.currencyManager = currencyManager
        self.currencyFormatter = currencyFormatter
        setupDataSources()
        observeManagerUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Get formatted currency amount
    public func formatAmount(_ amount: Decimal, currency: SupportedCurrency, locale: Locale? = nil) -> String {
        return currencyFormatter.format(amount, currency: currency, locale: locale)
    }
    
    /// Get formatted currency amount (Double version)
    public func formatAmount(_ amount: Double, currency: SupportedCurrency, locale: Locale? = nil) -> String {
        return currencyFormatter.format(amount, currency: currency, locale: locale)
    }
    
    /// Convert and format amount between currencies
    public func convertAndFormat(_ amount: Decimal,
                               from: SupportedCurrency,
                               to: SupportedCurrency,
                               locale: Locale? = nil) -> String? {
        guard let convertedAmount = currencyManager.convert(amount, from: from, to: to) else {
            return nil
        }
        return currencyFormatter.format(convertedAmount, currency: to, locale: locale)
    }
    
    /// Convert and format amount between currencies (Double version)
    public func convertAndFormat(_ amount: Double,
                               from: SupportedCurrency,
                               to: SupportedCurrency,
                               locale: Locale? = nil) -> String? {
        return convertAndFormat(Decimal(amount), from: from, to: to, locale: locale)
    }
    
    /// Get exchange rate between currencies
    public func getExchangeRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate? {
        return currencyManager.getExchangeRate(from: from, to: to)
    }
    
    /// Get formatted exchange rate
    public func getFormattedExchangeRate(from: SupportedCurrency, to: SupportedCurrency) -> String? {
        guard let rate = getExchangeRate(from: from, to: to) else { return nil }
        return currencyFormatter.formatExchangeRate(rate)
    }
    
    /// Convert amount between currencies
    public func convert(_ amount: Decimal, from: SupportedCurrency, to: SupportedCurrency) -> Decimal? {
        return currencyManager.convert(amount, from: from, to: to)
    }
    
    /// Convert amount between currencies (Double version)
    public func convert(_ amount: Double, from: SupportedCurrency, to: SupportedCurrency) -> Double? {
        return currencyManager.convert(amount, from: from, to: to)
    }
    
    /// Parse currency string to decimal
    public func parseAmount(_ string: String, currency: SupportedCurrency, locale: Locale? = nil) -> Decimal? {
        return currencyFormatter.parseAmount(string, currency: currency, locale: locale)
    }
    
    /// Update exchange rates from external sources
    public func updateExchangeRates() async {
        isLoading = true
        lastError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            try await currencyManager.updateExchangeRates()
        } catch {
            lastError = error
        }
    }
    
    /// Get all supported currencies
    public func getSupportedCurrencies() -> [SupportedCurrency] {
        return SupportedCurrency.allCases
    }
    
    /// Get currencies for specific region
    public func getCurrenciesForRegion(_ region: CurrencyRegion) -> [SupportedCurrency] {
        return SupportedCurrency.allCases.filter { currency in
            switch region {
            case .americas:
                return [.USD, .CAD].contains(currency)
            case .europe:
                return [.EUR, .GBP, .CHF, .SEK, .NOK, .DKK, .PLN, .CZK, .HUF, .RUB].contains(currency)
            case .asiaPacific:
                return [.INR, .JPY, .CNY, .AUD, .NZD, .SGD, .HKD, .KRW].contains(currency)
            case .all:
                return true
            }
        }
    }
    
    /// Get popular currencies
    public func getPopularCurrencies() -> [SupportedCurrency] {
        return [.USD, .EUR, .GBP, .JPY, .INR, .AUD, .CAD, .CHF]
    }
    
    /// Check if currency conversion is available
    public func isConversionAvailable(from: SupportedCurrency, to: SupportedCurrency) -> Bool {
        return getExchangeRate(from: from, to: to) != nil
    }
    
    /// Get currency information
    public func getCurrencyInfo(for currency: SupportedCurrency) -> CurrencyInfo {
        return CurrencyInfo(
            currency: currency,
            name: currency.displayName,
            symbol: currency.symbol,
            code: currency.rawValue,
            decimalPlaces: currency.decimalPlaces,
            preferredLocale: currency.preferredLocale
        )
    }
    
    // MARK: - Private Methods
    
    private func setupDataSources() {
        // Add mock data source for development
        dataSources.append(MockCurrencyDataSource())
        
        // In production, add real data sources like:
        // dataSources.append(ExchangeRateAPIDataSource())
        // dataSources.append(CurrencyAPIDataSource())
    }
    
    private func observeManagerUpdates() {
        // Observe currency manager loading state
        if let manager = currencyManager as? CurrencyManager {
            manager.$isUpdatingRates
                .receive(on: DispatchQueue.main)
                .assign(to: \.isLoading, on: self)
                .store(in: &cancellables)
            
            manager.$lastUpdateError
                .receive(on: DispatchQueue.main)
                .assign(to: \.lastError, on: self)
                .store(in: &cancellables)
        }
    }
}

// MARK: - Supporting Types

public enum CurrencyRegion {
    case americas
    case europe
    case asiaPacific
    case all
}

public struct CurrencyInfo {
    public let currency: SupportedCurrency
    public let name: String
    public let symbol: String
    public let code: String
    public let decimalPlaces: Int
    public let preferredLocale: Locale
    
    public init(currency: SupportedCurrency, name: String, symbol: String, code: String, decimalPlaces: Int, preferredLocale: Locale) {
        self.currency = currency
        self.name = name
        self.symbol = symbol
        self.code = code
        self.decimalPlaces = decimalPlaces
        self.preferredLocale = preferredLocale
    }
}

// MARK: - Mock Data Source

private class MockCurrencyDataSource: CurrencyDataSource {
    let name = "Mock Currency API"
    let isAvailable = true
    
    func fetchExchangeRates(baseCurrency: SupportedCurrency) async throws -> ExchangeRateSet {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock exchange rates based on INR
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
        
        // Convert to proper dictionary
        let properRates: [SupportedCurrency: ExchangeRate] = Dictionary(
            uniqueKeysWithValues: mockRates.compactMap { (currency, rate) in
                guard currency != baseCurrency else { return nil }
                return (currency, ExchangeRate(from: baseCurrency, to: currency, rate: rate, source: name))
            }
        )
        
        return ExchangeRateSet(baseCurrency: baseCurrency, rates: properRates)
    }
}

// MARK: - Singleton Access
extension CurrencyService {
    public static let shared = CurrencyService()
}