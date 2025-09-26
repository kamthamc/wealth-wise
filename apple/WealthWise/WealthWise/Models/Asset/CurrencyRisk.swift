import Foundation

/// Currency risk analysis and hedging tracking for cross-border assets
/// Handles multi-currency exposure, hedging strategies, and FX impact analysis
public final class CurrencyRisk: Sendable, Codable {
    
    // MARK: - Core Properties
    
    public let id: UUID
    public var assetId: UUID
    public var analysisDate: Date
    public var baseCurrency: String // User's reporting currency
    
    // MARK: - Currency Exposure
    
    /// Primary currency exposure (asset's native currency)
    public var primaryCurrency: String
    public var primaryExposureAmount: Decimal
    public var primaryExposurePercentage: Double
    
    /// Secondary currency exposures (for multi-currency assets)
    public var secondaryExposures: [CurrencyExposure]
    
    /// Total unhedged exposure by currency
    public var unhedgedExposure: [String: Decimal]
    
    /// Total hedged exposure by currency
    public var hedgedExposure: [String: Decimal]
    
    // MARK: - Risk Metrics
    
    /// Currency volatility (standard deviation of exchange rate)
    public var currencyVolatility: [String: Double]
    
    /// Value at Risk from currency movements (95% confidence, 1 month)
    public var currencyVaR: Decimal?
    
    /// Maximum historical drawdown from FX movements
    public var maxFXDrawdown: Double?
    
    /// Correlation between currencies in the portfolio
    public var currencyCorrelations: [String: [String: Double]]
    
    // MARK: - Hedging Analysis
    
    /// Current hedging strategy
    public var hedgingStrategy: HedgingStrategy
    
    /// Hedging ratio (0 = no hedging, 1 = fully hedged)
    public var hedgingRatio: Double
    
    /// Hedging instruments used
    public var hedgingInstruments: Set<HedgingInstrument>
    
    /// Cost of hedging (annualized percentage)
    public var hedgingCost: Double?
    
    /// Effectiveness of current hedging
    public var hedgingEffectiveness: Double?
    
    // MARK: - Impact Analysis
    
    /// Currency impact on returns (current period)
    public var currencyReturnImpact: Double
    
    /// Currency impact on returns (YTD)
    public var currencyReturnImpactYTD: Double
    
    /// Currency translation gain/loss
    public var translationGainLoss: Decimal
    
    /// Attribution analysis by currency
    public var currencyAttribution: [String: CurrencyAttribution]
    
    // MARK: - Scenario Analysis
    
    /// Stress test scenarios
    public var stressTestResults: [String: StressTestResult]
    
    /// Sensitivity to major currency movements
    public var currencySensitivity: [String: Double] // Currency -> Impact per 1% move
    
    // MARK: - Recommendations
    
    /// Recommended hedging action
    public var recommendedAction: HedgingRecommendation?
    
    /// Optimal hedging ratio suggestion
    public var optimalHedgingRatio: Double?
    
    /// Risk reduction potential
    public var riskReductionPotential: Double?
    
    // MARK: - Metadata
    
    public let createdAt: Date
    public var updatedAt: Date
    public var dataSource: String?
    public var notes: String?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        assetId: UUID,
        baseCurrency: String,
        primaryCurrency: String,
        primaryExposureAmount: Decimal,
        primaryExposurePercentage: Double = 100.0,
        analysisDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.assetId = assetId
        self.baseCurrency = baseCurrency
        self.primaryCurrency = primaryCurrency
        self.primaryExposureAmount = primaryExposureAmount
        self.primaryExposurePercentage = primaryExposurePercentage
        self.analysisDate = analysisDate
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize collections and default values
        self.secondaryExposures = []
        self.unhedgedExposure = [primaryCurrency: primaryExposureAmount]
        self.hedgedExposure = [:]
        self.currencyVolatility = [:]
        self.currencyCorrelations = [:]
        self.currencyAttribution = [:]
        self.stressTestResults = [:]
        self.currencySensitivity = [:]
        self.hedgingInstruments = Set()
        
        // Initialize hedging properties with defaults first
        self.hedgingStrategy = .noHedging
        self.hedgingRatio = 0.0
        self.currencyReturnImpact = 0.0
        self.currencyReturnImpactYTD = 0.0
        self.translationGainLoss = 0.0
        
        // Set appropriate hedging strategy after initialization
        self.hedgingStrategy = Self.determinDefaultHedgingStrategy(from: primaryCurrency, to: baseCurrency)
    }
    
    // MARK: - Private Methods
    
    private static func determinDefaultHedgingStrategy(from: String, to: String) -> HedgingStrategy {
        // Major currency pairs typically don't need hedging for small exposures
        let majorCurrencies = Set(["USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD"])
        
        if majorCurrencies.contains(from) && majorCurrencies.contains(to) {
            return .selective
        } else {
            return .dynamic // Recommend hedging for emerging market currencies
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total currency exposure across all currencies
    public var totalCurrencyExposure: Decimal {
        let secondaryTotal = secondaryExposures.reduce(Decimal.zero) { sum, exposure in
            sum + exposure.exposureAmount
        }
        return primaryExposureAmount + secondaryTotal
    }
    
    /// Number of currencies the asset is exposed to
    public var currencyDiversification: Int {
        return 1 + secondaryExposures.count
    }
    
    /// Whether the asset has significant currency risk (>5% exposure to foreign currencies)
    public var hasSignificantCurrencyRisk: Bool {
        if primaryCurrency == baseCurrency {
            let foreignExposure = secondaryExposures.reduce(0.0) { sum, exposure in
                sum + exposure.exposurePercentage
            }
            return foreignExposure > 5.0
        } else {
            return primaryExposurePercentage > 5.0
        }
    }
    
    /// Currency risk level classification
    public var currencyRiskLevel: CurrencyRiskLevel {
        let foreignExposurePercentage = primaryCurrency == baseCurrency ? 
            secondaryExposures.reduce(0.0) { sum, exposure in sum + exposure.exposurePercentage } :
            primaryExposurePercentage
        
        switch foreignExposurePercentage {
        case 0..<5:
            return .low
        case 5..<25:
            return .moderate
        case 25..<50:
            return .high
        case 50..<75:
            return .veryHigh
        default:
            return .extreme
        }
    }
    
    /// Net currency exposure after hedging
    public var netCurrencyExposure: [String: Decimal] {
        var netExposure: [String: Decimal] = [:]
        
        for (currency, unhedged) in unhedgedExposure {
            let hedged = hedgedExposure[currency] ?? 0
            netExposure[currency] = unhedged - hedged
        }
        
        return netExposure
    }
    
    /// Hedging effectiveness score (0-100)
    public var hedgingEffectivenessScore: Int {
        guard let effectiveness = hedgingEffectiveness else { return 0 }
        return max(0, min(100, Int(effectiveness * 100)))
    }
    
    /// Currency diversification score (higher = more diversified)
    public var diversificationScore: Int {
        guard currencyDiversification > 1 else { return 0 }
        
        let totalExposure = totalCurrencyExposure
        guard totalExposure > 0 else { return 0 }
        
        // Calculate Herfindahl-Hirschman Index for currency concentration
        let primaryWeight = Double(truncating: primaryExposureAmount / totalExposure as NSDecimalNumber)
        var hhi = primaryWeight * primaryWeight
        
        for exposure in secondaryExposures {
            let weight = Double(truncating: exposure.exposureAmount / totalExposure as NSDecimalNumber)
            hhi += weight * weight
        }
        
        // Convert HHI to diversification score (lower HHI = higher diversification)
        let maxHHI = 1.0 // Fully concentrated
        let diversificationScore = (maxHHI - hhi) / maxHHI * 100
        
        return Int(diversificationScore)
    }
}

// MARK: - Supporting Types

/// Currency exposure details
public struct CurrencyExposure: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let currency: String
    public let exposureAmount: Decimal
    public let exposurePercentage: Double
    public let source: String? // Description of where this exposure comes from
    
    public init(
        id: UUID = UUID(),
        currency: String,
        exposureAmount: Decimal,
        exposurePercentage: Double,
        source: String? = nil
    ) {
        self.id = id
        self.currency = currency
        self.exposureAmount = exposureAmount
        self.exposurePercentage = exposurePercentage
        self.source = source
    }
}

/// Hedging strategy types
public enum HedgingStrategy: String, CaseIterable, Codable, Sendable {
    case noHedging = "noHedging"
    case fullHedging = "fullHedging"
    case partialHedging = "partialHedging"
    case selective = "selective"
    case dynamic = "dynamic"
    case natural = "natural"
    
    public var displayName: String {
        switch self {
        case .noHedging:
            return "No Hedging"
        case .fullHedging:
            return "Full Hedging"
        case .partialHedging:
            return "Partial Hedging"
        case .selective:
            return "Selective Hedging"
        case .dynamic:
            return "Dynamic Hedging"
        case .natural:
            return "Natural Hedging"
        }
    }
    
    public var description: String {
        switch self {
        case .noHedging:
            return "Accept full currency risk for potential upside"
        case .fullHedging:
            return "Hedge 90-100% of currency exposure"
        case .partialHedging:
            return "Hedge 50-75% of currency exposure"
        case .selective:
            return "Hedge only high-risk currency exposures"
        case .dynamic:
            return "Adjust hedging based on market conditions"
        case .natural:
            return "Use natural hedges within portfolio"
        }
    }
}

/// Types of hedging instruments
public enum HedgingInstrument: String, CaseIterable, Codable, Sendable {
    case forwardContract = "forwardContract"
    case futuresContract = "futuresContract"
    case currencyOption = "currencyOption"
    case currencySwap = "currencySwap"
    case currencyETF = "currencyETF"
    case currencyMutualFund = "currencyMutualFund"
    case naturalHedge = "naturalHedge"
    case crossCurrencyBond = "crossCurrencyBond"
    
    public var displayName: String {
        switch self {
        case .forwardContract:
            return "Forward Contract"
        case .futuresContract:
            return "Futures Contract"
        case .currencyOption:
            return "Currency Option"
        case .currencySwap:
            return "Currency Swap"
        case .currencyETF:
            return "Currency ETF"
        case .currencyMutualFund:
            return "Currency Mutual Fund"
        case .naturalHedge:
            return "Natural Hedge"
        case .crossCurrencyBond:
            return "Cross-Currency Bond"
        }
    }
    
    public var complexity: HedgingComplexity {
        switch self {
        case .currencyETF, .currencyMutualFund, .naturalHedge:
            return .low
        case .forwardContract, .futuresContract:
            return .medium
        case .currencyOption, .currencySwap, .crossCurrencyBond:
            return .high
        }
    }
}

/// Complexity level of hedging instruments
public enum HedgingComplexity: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        switch self {
        case .low:
            return "Low Complexity"
        case .medium:
            return "Medium Complexity"
        case .high:
            return "High Complexity"
        }
    }
}

/// Currency risk level classification
public enum CurrencyRiskLevel: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "veryHigh"
    case extreme = "extreme"
    
    public var displayName: String {
        switch self {
        case .low:
            return "Low Currency Risk"
        case .moderate:
            return "Moderate Currency Risk"
        case .high:
            return "High Currency Risk"
        case .veryHigh:
            return "Very High Currency Risk"
        case .extreme:
            return "Extreme Currency Risk"
        }
    }
    
    public var color: String {
        switch self {
        case .low:
            return "systemGreen"
        case .moderate:
            return "systemYellow"
        case .high:
            return "systemOrange"
        case .veryHigh, .extreme:
            return "systemRed"
        }
    }
}

/// Currency attribution analysis
public struct CurrencyAttribution: Codable, Hashable, Sendable {
    public let currency: String
    public let returnContribution: Double // Percentage points
    public let riskContribution: Double // Percentage of total risk
    public let correlationWithBase: Double
    public let period: String // e.g., "1M", "YTD", "1Y"
    
    public init(
        currency: String,
        returnContribution: Double,
        riskContribution: Double,
        correlationWithBase: Double,
        period: String
    ) {
        self.currency = currency
        self.returnContribution = returnContribution
        self.riskContribution = riskContribution
        self.correlationWithBase = correlationWithBase
        self.period = period
    }
}

/// Stress test scenario results
public struct StressTestResult: Codable, Hashable, Sendable {
    public let scenarioName: String
    public let currencyMovements: [String: Double] // Currency -> % change
    public let portfolioImpact: Double // % impact on portfolio value
    public let probabilityEstimate: Double? // Estimated probability of scenario
    
    public init(
        scenarioName: String,
        currencyMovements: [String: Double],
        portfolioImpact: Double,
        probabilityEstimate: Double? = nil
    ) {
        self.scenarioName = scenarioName
        self.currencyMovements = currencyMovements
        self.portfolioImpact = portfolioImpact
        self.probabilityEstimate = probabilityEstimate
    }
}

/// Hedging recommendation
public struct HedgingRecommendation: Codable, Hashable, Sendable {
    public let action: HedgingAction
    public let targetHedgingRatio: Double
    public let recommendedInstruments: Set<HedgingInstrument>
    public let reasoning: String
    public let urgency: HedgingUrgency
    public let costBenefitAnalysis: String?
    
    public init(
        action: HedgingAction,
        targetHedgingRatio: Double,
        recommendedInstruments: Set<HedgingInstrument>,
        reasoning: String,
        urgency: HedgingUrgency,
        costBenefitAnalysis: String? = nil
    ) {
        self.action = action
        self.targetHedgingRatio = targetHedgingRatio
        self.recommendedInstruments = recommendedInstruments
        self.reasoning = reasoning
        self.urgency = urgency
        self.costBenefitAnalysis = costBenefitAnalysis
    }
}

/// Hedging action recommendations
public enum HedgingAction: String, CaseIterable, Codable, Sendable {
    case increaseHedging = "increaseHedging"
    case decreaseHedging = "decreaseHedging"
    case maintainHedging = "maintainHedging"
    case implementHedging = "implementHedging"
    case removeHedging = "removeHedging"
    case rebalanceHedging = "rebalanceHedging"
    
    public var displayName: String {
        switch self {
        case .increaseHedging:
            return "Increase Hedging"
        case .decreaseHedging:
            return "Decrease Hedging"
        case .maintainHedging:
            return "Maintain Current Hedging"
        case .implementHedging:
            return "Implement New Hedging"
        case .removeHedging:
            return "Remove Hedging"
        case .rebalanceHedging:
            return "Rebalance Hedging"
        }
    }
}

/// Urgency level for hedging recommendations
public enum HedgingUrgency: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    public var displayName: String {
        switch self {
        case .low:
            return "Low Priority"
        case .medium:
            return "Medium Priority"
        case .high:
            return "High Priority"
        case .urgent:
            return "Urgent Action Required"
        }
    }
    
    public var timeFrame: String {
        switch self {
        case .low:
            return "Within 3 months"
        case .medium:
            return "Within 1 month"
        case .high:
            return "Within 1 week"
        case .urgent:
            return "Immediate action"
        }
    }
}

// MARK: - Codable Implementation
extension CurrencyRisk {
    enum CodingKeys: CodingKey {
        case id, assetId, analysisDate, baseCurrency
        case primaryCurrency, primaryExposureAmount, primaryExposurePercentage
        case secondaryExposures, unhedgedExposure, hedgedExposure
        case currencyVolatility, currencyVaR, maxFXDrawdown, currencyCorrelations
        case hedgingStrategy, hedgingRatio, hedgingInstruments, hedgingCost, hedgingEffectiveness
        case currencyReturnImpact, currencyReturnImpactYTD, translationGainLoss, currencyAttribution
        case stressTestResults, currencySensitivity
        case recommendedAction, optimalHedgingRatio, riskReductionPotential
        case createdAt, updatedAt, dataSource, notes
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(assetId, forKey: .assetId)
        try container.encode(analysisDate, forKey: .analysisDate)
        try container.encode(baseCurrency, forKey: .baseCurrency)
        try container.encode(primaryCurrency, forKey: .primaryCurrency)
        try container.encode(primaryExposureAmount, forKey: .primaryExposureAmount)
        try container.encode(primaryExposurePercentage, forKey: .primaryExposurePercentage)
        try container.encode(secondaryExposures, forKey: .secondaryExposures)
        try container.encode(unhedgedExposure, forKey: .unhedgedExposure)
        try container.encode(hedgedExposure, forKey: .hedgedExposure)
        try container.encode(currencyVolatility, forKey: .currencyVolatility)
        try container.encodeIfPresent(currencyVaR, forKey: .currencyVaR)
        try container.encodeIfPresent(maxFXDrawdown, forKey: .maxFXDrawdown)
        try container.encode(currencyCorrelations, forKey: .currencyCorrelations)
        try container.encode(hedgingStrategy, forKey: .hedgingStrategy)
        try container.encode(hedgingRatio, forKey: .hedgingRatio)
        try container.encode(Array(hedgingInstruments), forKey: .hedgingInstruments)
        try container.encodeIfPresent(hedgingCost, forKey: .hedgingCost)
        try container.encodeIfPresent(hedgingEffectiveness, forKey: .hedgingEffectiveness)
        try container.encode(currencyReturnImpact, forKey: .currencyReturnImpact)
        try container.encode(currencyReturnImpactYTD, forKey: .currencyReturnImpactYTD)
        try container.encode(translationGainLoss, forKey: .translationGainLoss)
        try container.encode(currencyAttribution, forKey: .currencyAttribution)
        try container.encode(stressTestResults, forKey: .stressTestResults)
        try container.encode(currencySensitivity, forKey: .currencySensitivity)
        try container.encodeIfPresent(recommendedAction, forKey: .recommendedAction)
        try container.encodeIfPresent(optimalHedgingRatio, forKey: .optimalHedgingRatio)
        try container.encodeIfPresent(riskReductionPotential, forKey: .riskReductionPotential)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(dataSource, forKey: .dataSource)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let assetId = try container.decode(UUID.self, forKey: .assetId)
        let baseCurrency = try container.decode(String.self, forKey: .baseCurrency)
        let primaryCurrency = try container.decode(String.self, forKey: .primaryCurrency)
        let primaryExposureAmount = try container.decode(Decimal.self, forKey: .primaryExposureAmount)
        let primaryExposurePercentage = try container.decode(Double.self, forKey: .primaryExposurePercentage)
        let analysisDate = try container.decode(Date.self, forKey: .analysisDate)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        self.init(
            id: id,
            assetId: assetId,
            baseCurrency: baseCurrency,
            primaryCurrency: primaryCurrency,
            primaryExposureAmount: primaryExposureAmount,
            primaryExposurePercentage: primaryExposurePercentage,
            analysisDate: analysisDate,
            createdAt: createdAt
        )
        
        // Decode additional properties
        self.secondaryExposures = try container.decode([CurrencyExposure].self, forKey: .secondaryExposures)
        self.unhedgedExposure = try container.decode([String: Decimal].self, forKey: .unhedgedExposure)
        self.hedgedExposure = try container.decode([String: Decimal].self, forKey: .hedgedExposure)
        self.currencyVolatility = try container.decode([String: Double].self, forKey: .currencyVolatility)
        self.currencyVaR = try container.decodeIfPresent(Decimal.self, forKey: .currencyVaR)
        self.maxFXDrawdown = try container.decodeIfPresent(Double.self, forKey: .maxFXDrawdown)
        self.currencyCorrelations = try container.decode([String: [String: Double]].self, forKey: .currencyCorrelations)
        self.hedgingStrategy = try container.decode(HedgingStrategy.self, forKey: .hedgingStrategy)
        self.hedgingRatio = try container.decode(Double.self, forKey: .hedgingRatio)
        self.hedgingInstruments = Set(try container.decode([HedgingInstrument].self, forKey: .hedgingInstruments))
        self.hedgingCost = try container.decodeIfPresent(Double.self, forKey: .hedgingCost)
        self.hedgingEffectiveness = try container.decodeIfPresent(Double.self, forKey: .hedgingEffectiveness)
        self.currencyReturnImpact = try container.decode(Double.self, forKey: .currencyReturnImpact)
        self.currencyReturnImpactYTD = try container.decode(Double.self, forKey: .currencyReturnImpactYTD)
        self.translationGainLoss = try container.decode(Decimal.self, forKey: .translationGainLoss)
        self.currencyAttribution = try container.decode([String: CurrencyAttribution].self, forKey: .currencyAttribution)
        self.stressTestResults = try container.decode([String: StressTestResult].self, forKey: .stressTestResults)
        self.currencySensitivity = try container.decode([String: Double].self, forKey: .currencySensitivity)
        self.recommendedAction = try container.decodeIfPresent(HedgingRecommendation.self, forKey: .recommendedAction)
        self.optimalHedgingRatio = try container.decodeIfPresent(Double.self, forKey: .optimalHedgingRatio)
        self.riskReductionPotential = try container.decodeIfPresent(Double.self, forKey: .riskReductionPotential)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.dataSource = try container.decodeIfPresent(String.self, forKey: .dataSource)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

// MARK: - Extensions

extension CurrencyRisk {
    
    /// Add secondary currency exposure
    public func addSecondaryExposure(_ exposure: CurrencyExposure) {
        secondaryExposures.append(exposure)
        unhedgedExposure[exposure.currency] = (unhedgedExposure[exposure.currency] ?? 0) + exposure.exposureAmount
        updatedAt = Date()
    }
    
    /// Remove secondary currency exposure
    public func removeSecondaryExposure(currency: String) {
        secondaryExposures.removeAll { $0.currency == currency }
        unhedgedExposure.removeValue(forKey: currency)
        hedgedExposure.removeValue(forKey: currency)
        updatedAt = Date()
    }
    
    /// Update hedging position
    public func updateHedging(
        strategy: HedgingStrategy,
        ratio: Double,
        instruments: Set<HedgingInstrument>,
        cost: Double? = nil
    ) {
        hedgingStrategy = strategy
        hedgingRatio = max(0, min(1, ratio))
        hedgingInstruments = instruments
        hedgingCost = cost
        updatedAt = Date()
        
        // Recalculate hedged exposures based on new ratio
        for (currency, unhedged) in unhedgedExposure {
            hedgedExposure[currency] = unhedged * Decimal(hedgingRatio)
        }
    }
    
    /// Add stress test scenario
    public func addStressTestScenario(_ result: StressTestResult) {
        stressTestResults[result.scenarioName] = result
        updatedAt = Date()
    }
    
    /// Update currency sensitivity analysis
    public func updateCurrencySensitivity(_ sensitivity: [String: Double]) {
        currencySensitivity = sensitivity
        updatedAt = Date()
    }
    
    /// Generate hedging recommendation based on current risk profile
    public func generateHedgingRecommendation() -> HedgingRecommendation {
        let currentRisk = currencyRiskLevel
        let currentRatio = hedgingRatio
        
        let (action, targetRatio, instruments, reasoning, urgency) = calculateRecommendation(
            riskLevel: currentRisk,
            currentRatio: currentRatio
        )
        
        let recommendation = HedgingRecommendation(
            action: action,
            targetHedgingRatio: targetRatio,
            recommendedInstruments: instruments,
            reasoning: reasoning,
            urgency: urgency
        )
        
        self.recommendedAction = recommendation
        self.optimalHedgingRatio = targetRatio
        updatedAt = Date()
        
        return recommendation
    }
    
    private func calculateRecommendation(
        riskLevel: CurrencyRiskLevel,
        currentRatio: Double
    ) -> (HedgingAction, Double, Set<HedgingInstrument>, String, HedgingUrgency) {
        
        switch riskLevel {
        case .low:
            return (
                .maintainHedging,
                currentRatio,
                [.naturalHedge],
                "Low currency risk - maintain current strategy",
                .low
            )
            
        case .moderate:
            let targetRatio = currentRatio < 0.25 ? 0.25 : currentRatio
            return (
                currentRatio < 0.25 ? .increaseHedging : .maintainHedging,
                targetRatio,
                [.currencyETF, .forwardContract],
                "Moderate risk - consider partial hedging",
                .medium
            )
            
        case .high:
            let targetRatio = max(0.50, currentRatio)
            return (
                currentRatio < 0.50 ? .increaseHedging : .maintainHedging,
                targetRatio,
                [.forwardContract, .currencySwap],
                "High currency risk - implement significant hedging",
                .high
            )
            
        case .veryHigh:
            let targetRatio = max(0.75, currentRatio)
            return (
                currentRatio < 0.75 ? .increaseHedging : .maintainHedging,
                targetRatio,
                [.forwardContract, .currencyOption, .currencySwap],
                "Very high risk - substantial hedging recommended",
                .urgent
            )
            
        case .extreme:
            return (
                .implementHedging,
                0.90,
                [.forwardContract, .currencyOption],
                "Extreme currency risk - near-full hedging required",
                .urgent
            )
        }
    }
    
    /// Calculate potential risk reduction from recommended hedging
    public func calculateRiskReduction() -> Double? {
        guard let optimalRatio = optimalHedgingRatio,
              let currentVaR = currencyVaR else { return nil }
        
        // Simplified calculation: assume linear risk reduction with hedging
        let currentHedgedPortion = hedgingRatio
        let additionalHedging = optimalRatio - currentHedgedPortion
        let potentialReduction = additionalHedging * Double(truncating: currentVaR as NSDecimalNumber)
        
        riskReductionPotential = potentialReduction
        return potentialReduction
    }
}

// MARK: - Hashable & Equatable
extension CurrencyRisk: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: CurrencyRisk, rhs: CurrencyRisk) -> Bool {
        return lhs.id == rhs.id
    }
}