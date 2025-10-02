import Foundation

/// High-performance calculator for currency conversions with batch processing optimization
public actor ConversionCalculator {
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Single Conversions
    
    /// Convert amount using exchange rate
    public func convert(_ amount: Decimal, using rate: ExchangeRate) -> Decimal {
        return amount * rate.rate
    }
    
    /// Convert amount using exchange rate (Double version)
    public func convert(_ amount: Double, using rate: ExchangeRate) -> Double {
        let decimalAmount = Decimal(amount)
        let result = convert(decimalAmount, using: rate)
        return NSDecimalNumber(decimal: result).doubleValue
    }
    
    // MARK: - Batch Conversions
    
    /// Batch convert multiple amounts for portfolio calculations
    /// Optimized for large-scale conversions by reusing exchange rates
    public func batchConvert(
        _ conversions: [ConversionRequest],
        using service: CurrencyConversionService
    ) async throws -> [ConversionResult] {
        // Group conversions by currency pair to minimize API calls
        let groupedConversions = Dictionary(grouping: conversions) { request in
            CurrencyPair(from: request.sourceCurrency, to: request.targetCurrency)
        }
        
        var results: [ConversionResult] = []
        
        // Process each currency pair group
        for (pair, requests) in groupedConversions {
            do {
                // Fetch rate once per currency pair
                let rate = try await service.getExchangeRate(
                    from: pair.from,
                    to: pair.to
                )
                
                // Convert all amounts using the same rate
                for request in requests {
                    let convertedAmount = convert(request.amount, using: rate)
                    results.append(ConversionResult(
                        request: request,
                        result: convertedAmount,
                        rate: rate,
                        success: true,
                        error: nil
                    ))
                }
            } catch {
                // Mark all requests in this group as failed
                for request in requests {
                    results.append(ConversionResult(
                        request: request,
                        result: 0,
                        rate: nil,
                        success: false,
                        error: error
                    ))
                }
            }
        }
        
        return results
    }
    
    /// Batch convert with pre-fetched rates (most efficient for large portfolios)
    public func batchConvertWithRates(
        _ conversions: [ConversionRequest],
        rates: [CurrencyPair: ExchangeRate]
    ) -> [ConversionResult] {
        return conversions.map { request in
            let pair = CurrencyPair(from: request.sourceCurrency, to: request.targetCurrency)
            
            guard let rate = rates[pair] else {
                return ConversionResult(
                    request: request,
                    result: 0,
                    rate: nil,
                    success: false,
                    error: CurrencyConversionError.rateNotAvailable(
                        from: request.sourceCurrency,
                        to: request.targetCurrency
                    )
                )
            }
            
            let convertedAmount = convert(request.amount, using: rate)
            return ConversionResult(
                request: request,
                result: convertedAmount,
                rate: rate,
                success: true,
                error: nil
            )
        }
    }
    
    // MARK: - Portfolio Calculations
    
    /// Calculate total portfolio value in target currency
    public func calculatePortfolioValue(
        _ holdings: [PortfolioHolding],
        targetCurrency: SupportedCurrency,
        using service: CurrencyConversionService
    ) async throws -> PortfolioValue {
        // Create conversion requests for all holdings
        let conversions = holdings.map { holding in
            ConversionRequest(
                amount: holding.value,
                sourceCurrency: holding.currency,
                targetCurrency: targetCurrency,
                metadata: ["assetId": holding.assetId]
            )
        }
        
        // Batch convert
        let results = try await batchConvert(conversions, using: service)
        
        // Calculate totals
        let totalValue = results.reduce(Decimal(0)) { total, result in
            total + (result.success ? result.result : 0)
        }
        
        let successfulConversions = results.filter { $0.success }.count
        let failedConversions = results.filter { !$0.success }.count
        
        return PortfolioValue(
            totalValue: totalValue,
            currency: targetCurrency,
            timestamp: Date(),
            successfulConversions: successfulConversions,
            failedConversions: failedConversions,
            holdingValues: Dictionary(uniqueKeysWithValues: results.compactMap { result in
                guard let assetId = result.request.metadata?["assetId"] as? String,
                      result.success else { return nil }
                return (assetId, result.result)
            })
        )
    }
    
    /// Calculate currency breakdown for portfolio
    public func calculateCurrencyBreakdown(
        _ holdings: [PortfolioHolding],
        targetCurrency: SupportedCurrency,
        using service: CurrencyConversionService
    ) async throws -> CurrencyBreakdown {
        // Group holdings by currency
        let groupedByCurrency = Dictionary(grouping: holdings) { $0.currency }
        
        var breakdownItems: [CurrencyBreakdownItem] = []
        var totalValue = Decimal(0)
        
        for (currency, currencyHoldings) in groupedByCurrency {
            let currencyTotal = currencyHoldings.reduce(Decimal(0)) { $0 + $1.value }
            
            // Convert to target currency
            let convertedValue: Decimal
            if currency == targetCurrency {
                convertedValue = currencyTotal
            } else {
                convertedValue = try await service.convert(
                    currencyTotal,
                    from: currency,
                    to: targetCurrency
                )
            }
            
            breakdownItems.append(CurrencyBreakdownItem(
                currency: currency,
                nativeValue: currencyTotal,
                convertedValue: convertedValue,
                targetCurrency: targetCurrency,
                assetCount: currencyHoldings.count
            ))
            
            totalValue += convertedValue
        }
        
        // Calculate percentages
        breakdownItems = breakdownItems.map { item in
            var mutableItem = item
            mutableItem.percentage = totalValue > 0 ? (item.convertedValue / totalValue) * 100 : 0
            return mutableItem
        }
        
        // Sort by converted value descending
        breakdownItems.sort { $0.convertedValue > $1.convertedValue }
        
        return CurrencyBreakdown(
            items: breakdownItems,
            totalValue: totalValue,
            targetCurrency: targetCurrency,
            timestamp: Date()
        )
    }
}

// MARK: - Singleton Access

extension ConversionCalculator {
    public static let shared = ConversionCalculator()
}

// MARK: - Supporting Types

/// Request for currency conversion
public struct ConversionRequest: Sendable, Codable {
    public let amount: Decimal
    public let sourceCurrency: SupportedCurrency
    public let targetCurrency: SupportedCurrency
    public let metadata: [String: String]?
    
    public init(
        amount: Decimal,
        sourceCurrency: SupportedCurrency,
        targetCurrency: SupportedCurrency,
        metadata: [String: String]? = nil
    ) {
        self.amount = amount
        self.sourceCurrency = sourceCurrency
        self.targetCurrency = targetCurrency
        self.metadata = metadata
    }
}

/// Result of currency conversion
public struct ConversionResult: Sendable {
    public let request: ConversionRequest
    public let result: Decimal
    public let rate: ExchangeRate?
    public let success: Bool
    public let error: Error?
    
    public init(
        request: ConversionRequest,
        result: Decimal,
        rate: ExchangeRate?,
        success: Bool,
        error: Error?
    ) {
        self.request = request
        self.result = result
        self.rate = rate
        self.success = success
        self.error = error
    }
}

/// Portfolio holding for conversion
public struct PortfolioHolding: Sendable {
    public let assetId: String
    public let value: Decimal
    public let currency: SupportedCurrency
    
    public init(assetId: String, value: Decimal, currency: SupportedCurrency) {
        self.assetId = assetId
        self.value = value
        self.currency = currency
    }
}

/// Portfolio value calculation result
public struct PortfolioValue: Sendable {
    public let totalValue: Decimal
    public let currency: SupportedCurrency
    public let timestamp: Date
    public let successfulConversions: Int
    public let failedConversions: Int
    public let holdingValues: [String: Decimal]
    
    public var totalConversions: Int {
        return successfulConversions + failedConversions
    }
    
    public var successRate: Double {
        guard totalConversions > 0 else { return 0 }
        return Double(successfulConversions) / Double(totalConversions)
    }
}

/// Currency breakdown for portfolio
public struct CurrencyBreakdown: Sendable {
    public let items: [CurrencyBreakdownItem]
    public let totalValue: Decimal
    public let targetCurrency: SupportedCurrency
    public let timestamp: Date
}

/// Individual currency breakdown item
public struct CurrencyBreakdownItem: Sendable {
    public let currency: SupportedCurrency
    public let nativeValue: Decimal
    public let convertedValue: Decimal
    public let targetCurrency: SupportedCurrency
    public let assetCount: Int
    public var percentage: Decimal = 0
}
