//
//  MarketDataServiceAdapter.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Market Data Service Adapter
//

import Foundation
import Combine

/// Adapter that bridges CurrencyService to MarketDataServiceProtocol
/// Provides clean interface for currency and market data operations
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class MarketDataServiceAdapter: MarketDataServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let currencyService: CurrencyService
    private let currencyManager: any CurrencyManagerProtocol
    private let currencyFormatter: CurrencyFormatter
    
    // MARK: - Initialization
    
    public init(
        currencyService: CurrencyService,
        currencyManager: any CurrencyManagerProtocol,
        currencyFormatter: CurrencyFormatter
    ) {
        self.currencyService = currencyService
        self.currencyManager = currencyManager
        self.currencyFormatter = currencyFormatter
    }
    
    // MARK: - MarketDataServiceProtocol Implementation
    
    public var baseCurrency: SupportedCurrency {
        get {
            return currencyManager.baseCurrency
        }
        set {
            currencyManager.baseCurrency = newValue
        }
    }
    
    public var isUpdating: Bool {
        return currencyService.isLoading
    }
    
    public var lastError: Error? {
        return currencyService.lastError
    }
    
    public func updateExchangeRates() async throws {
        await currencyService.updateExchangeRates()
        
        // Check if there was an error
        if let error = currencyService.lastError {
            throw error
        }
    }
    
    public func getExchangeRate(from: SupportedCurrency, to: SupportedCurrency) -> ExchangeRate? {
        return currencyService.getExchangeRate(from: from, to: to)
    }
    
    public func convert(_ amount: Decimal, from: SupportedCurrency, to: SupportedCurrency) -> Decimal? {
        return currencyService.convert(amount, from: from, to: to)
    }
    
    public func formatAmount(_ amount: Decimal, currency: SupportedCurrency, locale: Locale?) -> String {
        return currencyService.formatAmount(amount, currency: currency, locale: locale)
    }
    
    public func getSupportedCurrencies() -> [SupportedCurrency] {
        return currencyService.getSupportedCurrencies()
    }
}

// MARK: - Factory Extension

@available(iOS 18.6, macOS 15.6, *)
extension MarketDataServiceAdapter {
    /// Create default market data service
    public static func createDefault() -> MarketDataServiceProtocol {
        let currencyManager = CurrencyManager()
        let currencyFormatter = CurrencyFormatter.shared
        let currencyService = CurrencyService(
            currencyManager: currencyManager,
            currencyFormatter: currencyFormatter
        )
        
        return MarketDataServiceAdapter(
            currencyService: currencyService,
            currencyManager: currencyManager,
            currencyFormatter: currencyFormatter
        )
    }
}
