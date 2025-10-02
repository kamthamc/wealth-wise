# Portfolio Management API Documentation

## Overview

The Portfolio Management Module provides comprehensive tracking for stocks, mutual funds, and ETFs with real-time valuation, P&L calculations, and performance analytics. Built with SwiftData for iOS 18.6+ and macOS 15.6+.

## Core Models

### Portfolio

A portfolio represents a collection of investment holdings with unified tracking and analytics.

```swift
@Model
public final class Portfolio {
    public var id: UUID
    public var name: String
    public var portfolioDescription: String?
    public var portfolioType: PortfolioType
    public var baseCurrency: String
    public var riskProfile: InvestorProfile
    public var isActive: Bool
    public var targetAllocation: [String: Decimal]?
    public var holdings: [Holding]
    public var transactions: [PortfolioTransaction]
    
    // Computed Properties
    public var totalValue: Decimal
    public var totalInvested: Decimal
    public var unrealizedGainLoss: Decimal
    public var unrealizedGainLossPercentage: Double
    public var realizedGains: Decimal
}
```

#### Portfolio Types

```swift
public enum PortfolioType {
    case diversified    // Balanced multi-asset portfolio
    case equity         // Equity-focused portfolio
    case fixedIncome    // Fixed income focused
    case retirement     // Retirement/pension portfolio
    case growth         // Growth-oriented portfolio
    case income         // Income-generating portfolio
    case custom         // Custom strategy
}
```

#### Investor Profiles

```swift
public enum InvestorProfile {
    case conservative   // Low risk tolerance
    case moderate       // Medium risk tolerance
    case aggressive     // High risk tolerance
    case growth         // Growth-focused
    case income         // Income-focused
}
```

### Holding

A holding represents an individual asset position within a portfolio.

```swift
@Model
public final class Holding {
    public var id: UUID
    public var symbol: String           // Stock ticker, MF code, ISIN
    public var name: String
    public var assetType: AssetType
    public var assetClass: String       // "Stock", "Mutual Fund", "ETF"
    public var quantity: Decimal
    public var averageCost: Decimal
    public var currentPrice: Decimal
    public var currency: String
    
    // Computed Properties
    public var totalCost: Decimal
    public var currentValue: Decimal
    public var unrealizedGainLoss: Decimal
    public var unrealizedGainLossPercentage: Double
    public var isProfitable: Bool
    
    // Methods
    public func updatePrice(_ newPrice: Decimal)
    public func addUnits(quantity: Decimal, costPerUnit: Decimal)
    public func removeUnits(quantity: Decimal) -> Decimal?
    public func portfolioWeight(in portfolio: Portfolio) -> Double
}
```

### PortfolioTransaction

Tracks all buy/sell/dividend transactions for comprehensive history.

```swift
@Model
public final class PortfolioTransaction {
    public var id: UUID
    public var transactionType: PortfolioTransactionType
    public var symbol: String
    public var assetName: String
    public var date: Date
    public var quantity: Decimal
    public var pricePerUnit: Decimal
    public var totalAmount: Decimal
    public var currency: String
    public var brokerage: Decimal?
    public var taxes: Decimal?
    public var otherCharges: Decimal?
    public var realizedGainLoss: Decimal?      // For sell transactions
    public var averageCostBasis: Decimal?       // Cost basis at sale
    
    // Computed Properties
    public var totalCost: Decimal
    public var netProceeds: Decimal
}
```

#### Transaction Types

```swift
public enum PortfolioTransactionType {
    case buy        // Purchase of assets
    case sell       // Sale of assets
    case dividend   // Dividend payment
    case split      // Stock split
    case bonus      // Bonus shares
    case merger     // Corporate merger
    case spinoff    // Corporate spinoff
    case rights     // Rights issue
}
```

## PortfolioService API

The `PortfolioService` provides all CRUD operations and analytics for portfolio management.

### Initialization

```swift
let modelContext = ModelContext(modelContainer)
let portfolioService = PortfolioService(modelContext: modelContext)
```

### Portfolio Operations

#### Create Portfolio

```swift
@MainActor
public func createPortfolio(_ portfolio: Portfolio) async throws
```

**Example:**
```swift
let portfolio = Portfolio(
    name: "My Investment Portfolio",
    portfolioDescription: "Long-term growth portfolio",
    portfolioType: .diversified,
    baseCurrency: "INR",
    riskProfile: .moderate
)

try await portfolioService.createPortfolio(portfolio)
```

#### Update Portfolio

```swift
@MainActor
public func updatePortfolio(_ portfolio: Portfolio) async throws
```

**Example:**
```swift
portfolio.name = "Updated Portfolio Name"
portfolio.riskProfile = .aggressive
try await portfolioService.updatePortfolio(portfolio)
```

#### Delete Portfolio

```swift
@MainActor
public func deletePortfolio(_ portfolio: Portfolio) async throws
```

#### Get Portfolio by ID

```swift
@MainActor
public func getPortfolio(by id: UUID) async throws -> Portfolio?
```

### Holding Operations

#### Add Holding

```swift
@MainActor
public func addHolding(_ holding: Holding, to portfolio: Portfolio) async throws
```

**Example:**
```swift
let holding = Holding(
    symbol: "RELIANCE",
    name: "Reliance Industries",
    assetType: .publicEquityDomestic,
    assetClass: "Stock",
    quantity: 10,
    averageCost: 2400,
    currentPrice: 2450,
    currency: "INR"
)

try await portfolioService.addHolding(holding, to: portfolio)
```

#### Update Holding

```swift
@MainActor
public func updateHolding(_ holding: Holding) async throws
```

**Example:**
```swift
holding.updatePrice(2500)
try await portfolioService.updateHolding(holding)
```

#### Remove Holding

```swift
@MainActor
public func removeHolding(_ holding: Holding, from portfolio: Portfolio) async throws
```

### Transaction Operations

#### Add Transaction

```swift
@MainActor
public func addTransaction(_ transaction: PortfolioTransaction, to portfolio: Portfolio) async throws
```

**Buy Transaction Example:**
```swift
let buyTransaction = PortfolioTransaction(
    transactionType: .buy,
    symbol: "TCS",
    assetName: "Tata Consultancy Services",
    quantity: 5,
    pricePerUnit: 3620,
    currency: "INR",
    brokerage: 20,
    taxes: 15
)

try await portfolioService.addTransaction(buyTransaction, to: portfolio)
```

**Sell Transaction Example:**
```swift
let sellTransaction = PortfolioTransaction(
    transactionType: .sell,
    symbol: "TCS",
    assetName: "Tata Consultancy Services",
    quantity: 3,
    pricePerUnit: 3700,
    currency: "INR",
    brokerage: 20,
    taxes: 30
)

try await portfolioService.addTransaction(sellTransaction, to: portfolio)
```

### Analytics Operations

#### Calculate Portfolio Value

```swift
public func calculatePortfolioValue(_ portfolio: Portfolio) -> PortfolioValue
```

**Returns:**
```swift
public struct PortfolioValue {
    public let totalValue: Decimal
    public let totalCost: Decimal
    public let unrealizedGainLoss: Decimal
    public let unrealizedGainLossPercentage: Double
    public let realizedGains: Decimal
    public let currency: String
}
```

**Example:**
```swift
let portfolioValue = portfolioService.calculatePortfolioValue(portfolio)
print("Total Value: ₹\(portfolioValue.totalValue)")
print("Total Cost: ₹\(portfolioValue.totalCost)")
print("Unrealized Gain/Loss: ₹\(portfolioValue.unrealizedGainLoss)")
print("Unrealized %: \(portfolioValue.unrealizedGainLossPercentage)%")
print("Realized Gains: ₹\(portfolioValue.realizedGains)")
```

#### Calculate Performance Metrics

```swift
public func calculatePerformanceMetrics(_ portfolio: Portfolio) -> PortfolioPerformanceMetrics
```

**Returns:**
```swift
public struct PortfolioPerformanceMetrics {
    public let xirr: Double?                    // Extended Internal Rate of Return
    public let cagr: Double?                    // Compound Annual Growth Rate
    public let absoluteReturn: Double           // Total return percentage
    public let diversificationScore: Double     // 0-100 score
    public let topHoldings: [TopHoldingInfo]    // Top 5 holdings
    public let totalHoldings: Int
    public let lastUpdated: Date
}
```

**Example:**
```swift
let metrics = portfolioService.calculatePerformanceMetrics(portfolio)
if let xirr = metrics.xirr {
    print("XIRR: \(xirr)%")
}
if let cagr = metrics.cagr {
    print("CAGR: \(cagr)%")
}
print("Absolute Return: \(metrics.absoluteReturn)%")
print("Diversification Score: \(metrics.diversificationScore)")
print("Total Holdings: \(metrics.totalHoldings)")
```

## MarketDataService API

The `MarketDataService` provides real-time and historical price data with offline support.

### Initialization

```swift
// Mock/Offline mode (default)
let marketDataService = MarketDataService(isRealTimeEnabled: false)

// Real-time mode
let marketDataService = MarketDataService(isRealTimeEnabled: true)
```

### Toggle Real-time Mode

```swift
marketDataService.isRealTimeEnabled = true  // Enable real-time
marketDataService.isRealTimeEnabled = false // Enable offline/mock mode
```

### Get Current Price

```swift
public func getCurrentPrice(symbol: String) async throws -> PriceData?
```

**Returns:**
```swift
public struct PriceData {
    public let symbol: String
    public let price: Decimal
    public let currency: String
    public let timestamp: Date
    public let change: Decimal?
    public let changePercentage: Double?
    public let volume: Int64?
    public let source: String
}
```

**Example:**
```swift
if let priceData = try await marketDataService.getCurrentPrice(symbol: "RELIANCE") {
    print("\(priceData.symbol): ₹\(priceData.price)")
    if let change = priceData.changePercentage {
        print("Change: \(change)%")
    }
}
```

### Get Historical Prices

```swift
public func getHistoricalPrices(symbol: String, from: Date, to: Date) async throws -> [PriceData]
```

**Example:**
```swift
let endDate = Date()
let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

let prices = try await marketDataService.getHistoricalPrices(
    symbol: "TCS",
    from: startDate,
    to: endDate
)

for price in prices {
    print("\(price.timestamp): ₹\(price.price)")
}
```

### Update Prices for Holdings

```swift
public func updatePrices(for holdings: [Holding]) async throws
```

**Example:**
```swift
try await marketDataService.updatePrices(for: portfolio.holdings)
print("Updated prices for \(portfolio.holdings.count) holdings")
print("Last update: \(marketDataService.lastUpdateTime ?? Date())")
```

## Error Handling

### Portfolio Errors

```swift
public enum PortfolioError: LocalizedError {
    case creationFailed(Error)
    case updateFailed(Error)
    case deletionFailed(Error)
    case fetchFailed(Error)
    case holdingOperationFailed(Error)
    case transactionFailed(Error)
    case invalidPortfolioName
    case invalidCurrency
    case invalidHoldingSymbol
    case invalidQuantity
    case invalidPrice
    case duplicateHolding(String)
    case holdingNotFound(String)
    case insufficientQuantity(String, Decimal)
}
```

**Example:**
```swift
do {
    try await portfolioService.createPortfolio(portfolio)
} catch PortfolioError.invalidPortfolioName {
    print("Portfolio name cannot be empty")
} catch PortfolioError.duplicateHolding(let symbol) {
    print("Holding \(symbol) already exists")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

### Market Data Errors

```swift
public enum MarketDataError: LocalizedError {
    case fetchFailed(String, Error)
    case invalidSymbol(String)
    case noDataAvailable(String)
    case rateLimitExceeded
    case networkError(Error)
}
```

## Usage Examples

### Complete Portfolio Workflow

```swift
// 1. Create a new portfolio
let portfolio = Portfolio(
    name: "Retirement Portfolio",
    portfolioDescription: "Long-term retirement savings",
    portfolioType: .retirement,
    baseCurrency: "INR",
    riskProfile: .moderate
)
try await portfolioService.createPortfolio(portfolio)

// 2. Add initial holdings
let holdings = [
    Holding(symbol: "RELIANCE", name: "Reliance", assetType: .publicEquityDomestic, 
            assetClass: "Stock", quantity: 10, averageCost: 2400, currentPrice: 2450),
    Holding(symbol: "TCS", name: "TCS", assetType: .publicEquityDomestic,
            assetClass: "Stock", quantity: 5, averageCost: 3600, currentPrice: 3620),
    Holding(symbol: "NIFTYBEES", name: "Nifty ETF", assetType: .equityETFs,
            assetClass: "ETF", quantity: 100, averageCost: 240, currentPrice: 245)
]

for holding in holdings {
    try await portfolioService.addHolding(holding, to: portfolio)
}

// 3. Update prices with market data
try await marketDataService.updatePrices(for: portfolio.holdings)

// 4. Calculate portfolio value and performance
let value = portfolioService.calculatePortfolioValue(portfolio)
let metrics = portfolioService.calculatePerformanceMetrics(portfolio)

print("Portfolio Value: ₹\(value.totalValue)")
print("Unrealized Gain: ₹\(value.unrealizedGainLoss) (\(value.unrealizedGainLossPercentage)%)")
print("CAGR: \(metrics.cagr ?? 0)%")
print("Diversification Score: \(metrics.diversificationScore)")

// 5. Record a sell transaction
let sellTransaction = PortfolioTransaction(
    transactionType: .sell,
    symbol: "TCS",
    assetName: "TCS",
    quantity: 2,
    pricePerUnit: 3700,
    currency: "INR"
)
try await portfolioService.addTransaction(sellTransaction, to: portfolio)

// 6. Get updated metrics
let updatedValue = portfolioService.calculatePortfolioValue(portfolio)
print("Realized Gains: ₹\(updatedValue.realizedGains)")
```

### Tracking Multiple Portfolios

```swift
// Create different portfolios for different goals
let growthPortfolio = Portfolio(name: "Growth", portfolioType: .growth, riskProfile: .aggressive)
let incomePortfolio = Portfolio(name: "Income", portfolioType: .income, riskProfile: .conservative)
let retirementPortfolio = Portfolio(name: "Retirement", portfolioType: .retirement, riskProfile: .moderate)

try await portfolioService.createPortfolio(growthPortfolio)
try await portfolioService.createPortfolio(incomePortfolio)
try await portfolioService.createPortfolio(retirementPortfolio)

// Get all portfolios
let allPortfolios = portfolioService.portfolios

// Calculate total net worth across all portfolios
let totalNetWorth = allPortfolios.reduce(Decimal.zero) { $0 + $1.totalValue }
print("Total Net Worth: ₹\(totalNetWorth)")
```

## Localization Support

All user-facing strings are localized in English, Hindi, and Tamil. Use `NSLocalizedString` for any UI text:

```swift
// Portfolio types
Text(portfolio.portfolioType.displayName) // Automatically localized

// Error messages
if let error = portfolioService.error {
    Text(error.localizedDescription) // Automatically localized
}
```

## Testing

Comprehensive unit tests are provided in:
- `PortfolioManagementTests.swift` - 30+ tests for portfolio operations
- `MarketDataServiceTests.swift` - 20+ tests for market data operations

Run tests:
```bash
xcodebuild -project apple/WealthWise/WealthWise.xcodeproj \
    -scheme WealthWise \
    -destination "generic/platform=macOS" \
    test
```

## Performance Considerations

- **Batch Operations**: Use `updatePrices(for: holdings)` to update multiple holdings efficiently
- **Background Processing**: Large portfolio calculations run asynchronously
- **Caching**: Price data includes timestamps for cache management
- **SwiftData**: Leverages SwiftData's efficient persistence and queries

## Future Enhancements

- Real-time WebSocket price updates
- CSV/Excel import/export for transactions
- Integration with Indian brokers (Zerodha, Upstox, etc.)
- Advanced charting and visualization
- Portfolio comparison and benchmarking
- Tax optimization suggestions
- Automated rebalancing recommendations

## Related Documentation

- [Market Data Integration](market-data-integration.md)
- [Cross-Border Asset Management](cross-border-asset-management.md)
- [macOS Architecture](macos-architecture.md)
- [Security Framework](security-framework.md)
