import Foundation

/// Comprehensive performance metrics tracking for cross-border assets
/// Handles multi-currency performance analysis and risk-adjusted returns
public final class PerformanceMetrics: Sendable, Codable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public var assetId: UUID
    public var calculationDate: Date
    public var baseCurrency: String // User's preferred reporting currency
    
    // MARK: - Return Metrics
    
    /// Total return in base currency (includes price appreciation + income)
    public var totalReturnAmount: Decimal
    public var totalReturnPercentage: Double
    
    /// Price appreciation return (excludes dividends/income)
    public var priceReturnAmount: Decimal
    public var priceReturnPercentage: Double
    
    /// Income return (dividends, interest, rent)
    public var incomeReturnAmount: Decimal
    public var incomeReturnPercentage: Double
    
    // MARK: - Time-Based Returns
    
    /// Returns over different time periods (annualized where applicable)
    public var returns1Month: Double?
    public var returns3Month: Double?
    public var returns6Month: Double?
    public var returns1Year: Double?
    public var returns3Year: Double? // Annualized
    public var returns5Year: Double? // Annualized
    public var returnsSinceInception: Double? // Annualized
    
    // MARK: - Risk Metrics
    
    /// Standard deviation of returns (volatility)
    public var volatility: Double?
    
    /// Maximum drawdown from peak
    public var maxDrawdown: Double?
    
    /// Sharpe ratio (risk-adjusted return)
    public var sharpeRatio: Double?
    
    /// Beta relative to market index
    public var beta: Double?
    
    /// Alpha (excess return over market)
    public var alpha: Double?
    
    /// Value at Risk (5% probability of loss)
    public var valueAtRisk5Percent: Decimal?
    
    // MARK: - Currency Impact
    
    /// Currency exposure breakdown
    public var currencyExposure: [String: Double] // Currency -> Percentage
    
    /// Currency hedging ratio
    public var currencyHedgingRatio: Double?
    
    /// Currency return attribution
    public var currencyReturnImpact: Double?
    
    // MARK: - Comparative Metrics
    
    /// Performance relative to benchmark indices
    public var benchmarkComparisons: [String: BenchmarkComparison]
    
    /// Percentile ranking in asset category
    public var categoryPercentileRank: Int?
    
    /// Performance vs user's overall portfolio
    public var portfolioContribution: Double?
    
    // MARK: - Quality Metrics
    
    /// Data quality score (0-100)
    public var dataQualityScore: Int
    
    /// Number of data points used in calculation
    public var dataPointCount: Int
    
    /// Confidence level in calculations
    public var confidenceLevel: Double
    
    /// Last data update timestamp
    public var lastDataUpdate: Date
    
    // MARK: - Metadata
    
    public let createdAt: Date
    public var updatedAt: Date
    public var calculationMethod: CalculationMethod
    public var notes: String?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        assetId: UUID,
        baseCurrency: String,
        totalReturnAmount: Decimal,
        totalReturnPercentage: Double,
        calculationDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.assetId = assetId
        self.baseCurrency = baseCurrency
        self.totalReturnAmount = totalReturnAmount
        self.totalReturnPercentage = totalReturnPercentage
        self.calculationDate = calculationDate
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize default values
        self.priceReturnAmount = 0
        self.priceReturnPercentage = 0
        self.incomeReturnAmount = 0
        self.incomeReturnPercentage = 0
        self.currencyExposure = [:]
        self.benchmarkComparisons = [:]
        self.dataQualityScore = 100
        self.dataPointCount = 0
        self.confidenceLevel = 1.0
        self.lastDataUpdate = createdAt
        self.calculationMethod = .timeWeighted
    }
    
    // MARK: - Computed Properties
    
    /// Whether the performance data is recent (within last 24 hours)
    public var isDataFresh: Bool {
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return lastDataUpdate > dayAgo
    }
    
    /// Risk level based on volatility
    public var riskLevel: RiskLevel {
        guard let vol = volatility else { return .unknown }
        
        switch vol {
        case 0..<0.05:
            return .veryLow
        case 0.05..<0.15:
            return .low
        case 0.15..<0.25:
            return .medium
        case 0.25..<0.40:
            return .high
        default:
            return .veryHigh
        }
    }
    
    /// Performance rating based on returns and risk
    public var performanceRating: PerformanceRating {
        guard let returns1Year = returns1Year else { return .notRated }
        
        let adjustedReturn = returns1Year - (volatility ?? 0) * 100
        
        switch adjustedReturn {
        case 20...:
            return .excellent
        case 10..<20:
            return .good
        case 0..<10:
            return .average
        case -10..<0:
            return .belowAverage
        default:
            return .poor
        }
    }
    
    /// Currency diversification score (0-100)
    public var currencyDiversificationScore: Int {
        guard !currencyExposure.isEmpty else { return 0 }
        
        let sortedExposures = currencyExposure.values.sorted(by: >)
        let topCurrencyExposure = sortedExposures.first ?? 0
        
        // Lower concentration = higher diversification score
        return max(0, 100 - Int(topCurrencyExposure * 100))
    }
    
    /// Effective yield (income return annualized)
    public var effectiveYield: Double {
        return incomeReturnPercentage
    }
    
    /// Risk-adjusted return score (combines return and risk)
    public var riskAdjustedScore: Double {
        guard let sharpe = sharpeRatio else {
            return totalReturnPercentage
        }
        return sharpe * 100 // Convert to percentage-like scale
    }
}

// MARK: - Supporting Types

/// Method used for performance calculation
public enum CalculationMethod: String, CaseIterable, Codable, Sendable {
    case timeWeighted = "timeWeighted"           // TWR - Standard for investment performance
    case moneyWeighted = "moneyWeighted"         // MWR/IRR - Accounts for cash flows
    case dollarWeighted = "dollarWeighted"       // Dollar-weighted return
    case holdingPeriod = "holdingPeriod"        // Simple holding period return
    case logarithmic = "logarithmic"            // Log returns for statistical analysis
    
    public var displayName: String {
        switch self {
        case .timeWeighted:
            return "Time-Weighted Return"
        case .moneyWeighted:
            return "Money-Weighted Return (IRR)"
        case .dollarWeighted:
            return "Dollar-Weighted Return"
        case .holdingPeriod:
            return "Holding Period Return"
        case .logarithmic:
            return "Logarithmic Return"
        }
    }
    
    public var description: String {
        switch self {
        case .timeWeighted:
            return "Standard method eliminating impact of cash flows timing"
        case .moneyWeighted:
            return "Internal rate of return accounting for cash flow timing"
        case .dollarWeighted:
            return "Weighted by investment amount"
        case .holdingPeriod:
            return "Simple return from purchase to current date"
        case .logarithmic:
            return "Natural log of price relatives for statistical analysis"
        }
    }
}

/// Risk level classification
public enum RiskLevel: String, CaseIterable, Codable, Sendable {
    case veryLow = "veryLow"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "veryHigh"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .veryLow:
            return "Very Low Risk"
        case .low:
            return "Low Risk"
        case .medium:
            return "Medium Risk"
        case .high:
            return "High Risk"
        case .veryHigh:
            return "Very High Risk"
        case .unknown:
            return "Risk Unknown"
        }
    }
    
    public var color: String {
        switch self {
        case .veryLow:
            return "systemGreen"
        case .low:
            return "systemBlue"
        case .medium:
            return "systemYellow"
        case .high:
            return "systemOrange"
        case .veryHigh, .unknown:
            return "systemRed"
        }
    }
}

/// Performance rating
public enum PerformanceRating: String, CaseIterable, Codable, Sendable {
    case excellent = "excellent"
    case good = "good"
    case average = "average"
    case belowAverage = "belowAverage"
    case poor = "poor"
    case notRated = "notRated"
    
    public var displayName: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .average:
            return "Average"
        case .belowAverage:
            return "Below Average"
        case .poor:
            return "Poor"
        case .notRated:
            return "Not Rated"
        }
    }
    
    public var stars: Int {
        switch self {
        case .excellent:
            return 5
        case .good:
            return 4
        case .average:
            return 3
        case .belowAverage:
            return 2
        case .poor:
            return 1
        case .notRated:
            return 0
        }
    }
}

/// Benchmark comparison data
public struct BenchmarkComparison: Codable, Hashable, Sendable {
    public let benchmarkName: String
    public let benchmarkReturn: Double
    public let relativeReturn: Double // Asset return - Benchmark return
    public let trackingError: Double?
    public let informationRatio: Double?
    public let correlationCoefficient: Double?
    
    public init(
        benchmarkName: String,
        benchmarkReturn: Double,
        relativeReturn: Double,
        trackingError: Double? = nil,
        informationRatio: Double? = nil,
        correlationCoefficient: Double? = nil
    ) {
        self.benchmarkName = benchmarkName
        self.benchmarkReturn = benchmarkReturn
        self.relativeReturn = relativeReturn
        self.trackingError = trackingError
        self.informationRatio = informationRatio
        self.correlationCoefficient = correlationCoefficient
    }
    
    /// Whether the asset outperformed the benchmark
    public var outperformed: Bool {
        return relativeReturn > 0
    }
    
    /// Performance difference as percentage points
    public var performanceDifference: String {
        let sign = relativeReturn >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", relativeReturn))%"
    }
}

// MARK: - Codable Implementation
extension PerformanceMetrics {
    enum CodingKeys: CodingKey {
        case id, assetId, calculationDate, baseCurrency
        case totalReturnAmount, totalReturnPercentage, priceReturnAmount, priceReturnPercentage
        case incomeReturnAmount, incomeReturnPercentage
        case returns1Month, returns3Month, returns6Month, returns1Year, returns3Year, returns5Year, returnsSinceInception
        case volatility, maxDrawdown, sharpeRatio, beta, alpha, valueAtRisk5Percent
        case currencyExposure, currencyHedgingRatio, currencyReturnImpact
        case benchmarkComparisons, categoryPercentileRank, portfolioContribution
        case dataQualityScore, dataPointCount, confidenceLevel, lastDataUpdate
        case createdAt, updatedAt, calculationMethod, notes
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(assetId, forKey: .assetId)
        try container.encode(calculationDate, forKey: .calculationDate)
        try container.encode(baseCurrency, forKey: .baseCurrency)
        try container.encode(totalReturnAmount, forKey: .totalReturnAmount)
        try container.encode(totalReturnPercentage, forKey: .totalReturnPercentage)
        try container.encode(priceReturnAmount, forKey: .priceReturnAmount)
        try container.encode(priceReturnPercentage, forKey: .priceReturnPercentage)
        try container.encode(incomeReturnAmount, forKey: .incomeReturnAmount)
        try container.encode(incomeReturnPercentage, forKey: .incomeReturnPercentage)
        try container.encodeIfPresent(returns1Month, forKey: .returns1Month)
        try container.encodeIfPresent(returns3Month, forKey: .returns3Month)
        try container.encodeIfPresent(returns6Month, forKey: .returns6Month)
        try container.encodeIfPresent(returns1Year, forKey: .returns1Year)
        try container.encodeIfPresent(returns3Year, forKey: .returns3Year)
        try container.encodeIfPresent(returns5Year, forKey: .returns5Year)
        try container.encodeIfPresent(returnsSinceInception, forKey: .returnsSinceInception)
        try container.encodeIfPresent(volatility, forKey: .volatility)
        try container.encodeIfPresent(maxDrawdown, forKey: .maxDrawdown)
        try container.encodeIfPresent(sharpeRatio, forKey: .sharpeRatio)
        try container.encodeIfPresent(beta, forKey: .beta)
        try container.encodeIfPresent(alpha, forKey: .alpha)
        try container.encodeIfPresent(valueAtRisk5Percent, forKey: .valueAtRisk5Percent)
        try container.encode(currencyExposure, forKey: .currencyExposure)
        try container.encodeIfPresent(currencyHedgingRatio, forKey: .currencyHedgingRatio)
        try container.encodeIfPresent(currencyReturnImpact, forKey: .currencyReturnImpact)
        try container.encode(benchmarkComparisons, forKey: .benchmarkComparisons)
        try container.encodeIfPresent(categoryPercentileRank, forKey: .categoryPercentileRank)
        try container.encodeIfPresent(portfolioContribution, forKey: .portfolioContribution)
        try container.encode(dataQualityScore, forKey: .dataQualityScore)
        try container.encode(dataPointCount, forKey: .dataPointCount)
        try container.encode(confidenceLevel, forKey: .confidenceLevel)
        try container.encode(lastDataUpdate, forKey: .lastDataUpdate)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(calculationMethod, forKey: .calculationMethod)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let assetId = try container.decode(UUID.self, forKey: .assetId)
        let baseCurrency = try container.decode(String.self, forKey: .baseCurrency)
        let totalReturnAmount = try container.decode(Decimal.self, forKey: .totalReturnAmount)
        let totalReturnPercentage = try container.decode(Double.self, forKey: .totalReturnPercentage)
        let calculationDate = try container.decode(Date.self, forKey: .calculationDate)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        self.init(
            id: id,
            assetId: assetId,
            baseCurrency: baseCurrency,
            totalReturnAmount: totalReturnAmount,
            totalReturnPercentage: totalReturnPercentage,
            calculationDate: calculationDate,
            createdAt: createdAt
        )
        
        // Decode optional and additional properties
        self.priceReturnAmount = try container.decode(Decimal.self, forKey: .priceReturnAmount)
        self.priceReturnPercentage = try container.decode(Double.self, forKey: .priceReturnPercentage)
        self.incomeReturnAmount = try container.decode(Decimal.self, forKey: .incomeReturnAmount)
        self.incomeReturnPercentage = try container.decode(Double.self, forKey: .incomeReturnPercentage)
        self.returns1Month = try container.decodeIfPresent(Double.self, forKey: .returns1Month)
        self.returns3Month = try container.decodeIfPresent(Double.self, forKey: .returns3Month)
        self.returns6Month = try container.decodeIfPresent(Double.self, forKey: .returns6Month)
        self.returns1Year = try container.decodeIfPresent(Double.self, forKey: .returns1Year)
        self.returns3Year = try container.decodeIfPresent(Double.self, forKey: .returns3Year)
        self.returns5Year = try container.decodeIfPresent(Double.self, forKey: .returns5Year)
        self.returnsSinceInception = try container.decodeIfPresent(Double.self, forKey: .returnsSinceInception)
        self.volatility = try container.decodeIfPresent(Double.self, forKey: .volatility)
        self.maxDrawdown = try container.decodeIfPresent(Double.self, forKey: .maxDrawdown)
        self.sharpeRatio = try container.decodeIfPresent(Double.self, forKey: .sharpeRatio)
        self.beta = try container.decodeIfPresent(Double.self, forKey: .beta)
        self.alpha = try container.decodeIfPresent(Double.self, forKey: .alpha)
        self.valueAtRisk5Percent = try container.decodeIfPresent(Decimal.self, forKey: .valueAtRisk5Percent)
        self.currencyExposure = try container.decode([String: Double].self, forKey: .currencyExposure)
        self.currencyHedgingRatio = try container.decodeIfPresent(Double.self, forKey: .currencyHedgingRatio)
        self.currencyReturnImpact = try container.decodeIfPresent(Double.self, forKey: .currencyReturnImpact)
        self.benchmarkComparisons = try container.decode([String: BenchmarkComparison].self, forKey: .benchmarkComparisons)
        self.categoryPercentileRank = try container.decodeIfPresent(Int.self, forKey: .categoryPercentileRank)
        self.portfolioContribution = try container.decodeIfPresent(Double.self, forKey: .portfolioContribution)
        self.dataQualityScore = try container.decode(Int.self, forKey: .dataQualityScore)
        self.dataPointCount = try container.decode(Int.self, forKey: .dataPointCount)
        self.confidenceLevel = try container.decode(Double.self, forKey: .confidenceLevel)
        self.lastDataUpdate = try container.decode(Date.self, forKey: .lastDataUpdate)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.calculationMethod = try container.decode(CalculationMethod.self, forKey: .calculationMethod)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

// MARK: - Extensions

extension PerformanceMetrics {
    
    /// Update return metrics with new data
    public func updateReturns(
        totalReturn: Decimal,
        totalReturnPercentage: Double,
        priceReturn: Decimal? = nil,
        priceReturnPercentage: Double? = nil,
        incomeReturn: Decimal? = nil,
        incomeReturnPercentage: Double? = nil
    ) {
        self.totalReturnAmount = totalReturn
        self.totalReturnPercentage = totalReturnPercentage
        
        if let priceReturn = priceReturn {
            self.priceReturnAmount = priceReturn
        }
        if let priceReturnPercentage = priceReturnPercentage {
            self.priceReturnPercentage = priceReturnPercentage
        }
        if let incomeReturn = incomeReturn {
            self.incomeReturnAmount = incomeReturn
        }
        if let incomeReturnPercentage = incomeReturnPercentage {
            self.incomeReturnPercentage = incomeReturnPercentage
        }
        
        self.updatedAt = Date()
        self.lastDataUpdate = Date()
    }
    
    /// Update risk metrics
    public func updateRiskMetrics(
        volatility: Double? = nil,
        maxDrawdown: Double? = nil,
        sharpeRatio: Double? = nil,
        beta: Double? = nil,
        alpha: Double? = nil,
        valueAtRisk: Decimal? = nil
    ) {
        if let volatility = volatility {
            self.volatility = volatility
        }
        if let maxDrawdown = maxDrawdown {
            self.maxDrawdown = maxDrawdown
        }
        if let sharpeRatio = sharpeRatio {
            self.sharpeRatio = sharpeRatio
        }
        if let beta = beta {
            self.beta = beta
        }
        if let alpha = alpha {
            self.alpha = alpha
        }
        if let valueAtRisk = valueAtRisk {
            self.valueAtRisk5Percent = valueAtRisk
        }
        
        self.updatedAt = Date()
        self.lastDataUpdate = Date()
    }
    
    /// Add benchmark comparison
    public func addBenchmarkComparison(_ comparison: BenchmarkComparison) {
        benchmarkComparisons[comparison.benchmarkName] = comparison
        updatedAt = Date()
    }
    
    /// Remove benchmark comparison
    public func removeBenchmarkComparison(benchmarkName: String) {
        benchmarkComparisons.removeValue(forKey: benchmarkName)
        updatedAt = Date()
    }
    
    /// Update currency exposure
    public func updateCurrencyExposure(_ exposure: [String: Double]) {
        currencyExposure = exposure
        updatedAt = Date()
    }
    
    /// Set data quality score based on available data
    public func calculateDataQualityScore() {
        var score = 100
        
        // Reduce score for missing critical data
        if returns1Year == nil { score -= 10 }
        if volatility == nil { score -= 15 }
        if sharpeRatio == nil { score -= 10 }
        if benchmarkComparisons.isEmpty { score -= 15 }
        if currencyExposure.isEmpty { score -= 10 }
        
        // Reduce score for stale data
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastDataUpdate, to: Date()).day ?? 0
        if daysSinceUpdate > 7 {
            score -= min(20, daysSinceUpdate * 2)
        }
        
        // Reduce score for low data point count
        if dataPointCount < 30 {
            score -= (30 - dataPointCount)
        }
        
        self.dataQualityScore = max(0, score)
        updatedAt = Date()
    }
    
    /// Generate performance summary
    public func generatePerformanceSummary() -> String {
        var summary = "Performance Summary:\n"
        summary += "Total Return: \(String(format: "%.2f", totalReturnPercentage))%\n"
        
        if let returns1Year = returns1Year {
            summary += "1-Year Return: \(String(format: "%.2f", returns1Year))%\n"
        }
        
        if let vol = volatility {
            summary += "Volatility: \(String(format: "%.2f", vol * 100))%\n"
        }
        
        if let sharpe = sharpeRatio {
            summary += "Sharpe Ratio: \(String(format: "%.2f", sharpe))\n"
        }
        
        summary += "Risk Level: \(riskLevel.displayName)\n"
        summary += "Performance Rating: \(performanceRating.displayName)"
        
        return summary
    }
}

// MARK: - Hashable & Equatable
extension PerformanceMetrics: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: PerformanceMetrics, rhs: PerformanceMetrics) -> Bool {
        return lhs.id == rhs.id
    }
}