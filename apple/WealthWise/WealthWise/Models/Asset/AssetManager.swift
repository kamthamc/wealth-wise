import Foundation

/// Asset management utilities and helper functions
/// Provides comprehensive asset analysis, categorization, and portfolio management support
public struct AssetManager {
    
    // MARK: - Asset Classification
    
    /// Classify assets into common portfolio allocation categories
    public static func getPortfolioAllocationCategory(for assetType: AssetType) -> PortfolioAllocationCategory {
        switch assetType.category {
        case .equity:
            if assetType.rawValue.contains("International") {
                return .internationalEquity
            } else {
                return .domesticEquity
            }
        case .fixedIncome:
            if assetType.rawValue.contains("international") {
                return .internationalBonds
            } else {
                return .domesticBonds
            }
        case .alternative:
            return .alternatives
        case .cash:
            return .cash
        case .business, .tangible, .digital, .insurance, .other:
            return .others
        }
    }
    
    /// Get recommended asset allocation for different investor profiles
    public static func getRecommendedAllocation(for profile: InvestorProfile, age: Int? = nil) -> [PortfolioAllocationCategory: Double] {
        let adjustedProfile = adjustProfileForAge(profile, age: age)
        
        switch adjustedProfile {
        case .conservative:
            return [
                .cash: 15.0,
                .domesticBonds: 50.0,
                .internationalBonds: 10.0,
                .domesticEquity: 20.0,
                .internationalEquity: 5.0,
                .alternatives: 0.0,
                .others: 0.0
            ]
        case .moderate:
            return [
                .cash: 10.0,
                .domesticBonds: 30.0,
                .internationalBonds: 10.0,
                .domesticEquity: 35.0,
                .internationalEquity: 10.0,
                .alternatives: 5.0,
                .others: 0.0
            ]
        case .aggressive:
            return [
                .cash: 5.0,
                .domesticBonds: 15.0,
                .internationalBonds: 5.0,
                .domesticEquity: 50.0,
                .internationalEquity: 15.0,
                .alternatives: 10.0,
                .others: 0.0
            ]
        case .growth:
            return [
                .cash: 5.0,
                .domesticBonds: 10.0,
                .internationalBonds: 0.0,
                .domesticEquity: 60.0,
                .internationalEquity: 20.0,
                .alternatives: 5.0,
                .others: 0.0
            ]
        case .income:
            return [
                .cash: 10.0,
                .domesticBonds: 60.0,
                .internationalBonds: 10.0,
                .domesticEquity: 15.0,
                .internationalEquity: 0.0,
                .alternatives: 5.0,
                .others: 0.0
            ]
        }
    }
    
    /// Adjust investor profile based on age (lifecycle investing)
    private static func adjustProfileForAge(_ profile: InvestorProfile, age: Int?) -> InvestorProfile {
        guard let age = age else { return profile }
        
        // Rule of thumb: equity allocation = 100 - age
        switch age {
        case 0..<30:
            return profile == .conservative ? .moderate : profile
        case 30..<50:
            return profile
        case 50..<65:
            return profile == .aggressive ? .moderate : profile
        case 65...:
            return profile == .aggressive ? .moderate : (profile == .moderate ? .conservative : profile)
        default:
            return profile
        }
    }
    
    // MARK: - Portfolio Analysis
    
    /// Calculate portfolio allocation percentages
    public static func calculatePortfolioAllocation(assets: [CrossBorderAsset]) -> [PortfolioAllocationCategory: Double] {
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        guard totalValue > 0 else { return [:] }
        
        var allocation: [PortfolioAllocationCategory: Decimal] = [:]
        
        for asset in assets {
            guard asset.isIncludedInPortfolio else { continue }
            let category = getPortfolioAllocationCategory(for: asset.assetType)
            allocation[category, default: 0] += asset.currentValue
        }
        
        var percentageAllocation: [PortfolioAllocationCategory: Double] = [:]
        for (category, value) in allocation {
            percentageAllocation[category] = Double(truncating: (value / totalValue * 100) as NSDecimalNumber)
        }
        
        return percentageAllocation
    }
    
    /// Calculate diversification score (0-100)
    public static func calculateDiversificationScore(assets: [CrossBorderAsset]) -> Double {
        let allocation = calculatePortfolioAllocation(assets: assets)
        
        // Calculate Herfindahl-Hirschman Index (HHI) for concentration
        let hhi = allocation.values.reduce(0) { $0 + ($1 * $1) }
        
        // Convert HHI to diversification score (100 - normalized HHI)
        let maxHHI = 10000.0 // Maximum concentration (100% in one category)
        let diversificationScore = max(0, 100 - (hhi / maxHHI * 100))
        
        return diversificationScore
    }
    
    /// Identify overweight and underweight categories compared to target allocation
    public static func analyzeAllocationDeviation(
        currentAssets: [CrossBorderAsset],
        targetAllocation: [PortfolioAllocationCategory: Double],
        tolerance: Double = 5.0
    ) -> AllocationAnalysis {
        let currentAllocation = calculatePortfolioAllocation(assets: currentAssets)
        
        var overweight: [PortfolioAllocationCategory: Double] = [:]
        var underweight: [PortfolioAllocationCategory: Double] = [:]
        var onTarget: [PortfolioAllocationCategory] = []
        
        for (category, targetPercent) in targetAllocation {
            let currentPercent = currentAllocation[category] ?? 0.0
            let deviation = currentPercent - targetPercent
            
            if abs(deviation) <= tolerance {
                onTarget.append(category)
            } else if deviation > 0 {
                overweight[category] = deviation
            } else {
                underweight[category] = abs(deviation)
            }
        }
        
        return AllocationAnalysis(
            overweight: overweight,
            underweight: underweight,
            onTarget: onTarget,
            totalDeviation: overweight.values.reduce(0, +) + underweight.values.reduce(0, +)
        )
    }
    
    // MARK: - Risk Analysis
    
    /// Calculate portfolio risk score (weighted average)
    public static func calculatePortfolioRiskScore(assets: [CrossBorderAsset]) -> Double {
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        guard totalValue > 0 else { return 0.0 }
        
        var weightedRiskSum = 0.0
        
        for asset in assets {
            guard asset.isIncludedInPortfolio else { continue }
            let weight = Double(truncating: (asset.currentValue / totalValue) as NSDecimalNumber)
            let riskScore = asset.riskRating?.numericValue ?? getDefaultRiskScore(for: asset.assetType)
            weightedRiskSum += weight * Double(riskScore)
        }
        
        return weightedRiskSum
    }
    
    /// Get default risk score for asset type
    private static func getDefaultRiskScore(for assetType: AssetType) -> Int {
        switch assetType.category {
        case .cash: return 1
        case .fixedIncome: return 2
        case .insurance: return 2
        case .equity: return assetType.rawValue.contains("International") ? 4 : 3
        case .alternative: return 4
        case .digital: return 5
        case .business: return 4
        case .tangible: return 3
        case .other: return 3
        }
    }
    
    /// Calculate portfolio liquidity score
    public static func calculatePortfolioLiquidityScore(assets: [CrossBorderAsset]) -> Double {
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        guard totalValue > 0 else { return 0.0 }
        
        var weightedLiquiditySum = 0.0
        
        for asset in assets {
            guard asset.isIncludedInPortfolio else { continue }
            let weight = Double(truncating: (asset.currentValue / totalValue) as NSDecimalNumber)
            let liquidityScore = getLiquidityScore(for: asset.liquidityRating)
            weightedLiquiditySum += weight * liquidityScore
        }
        
        return weightedLiquiditySum
    }
    
    /// Convert liquidity rating to numeric score
    private static func getLiquidityScore(for rating: LiquidityRating) -> Double {
        switch rating {
        case .high: return 4.0
        case .medium: return 3.0
        case .low: return 2.0
        case .veryLow: return 1.0
        }
    }
    
    // MARK: - Tax Optimization
    
    /// Calculate tax efficiency score
    public static func calculateTaxEfficiencyScore(assets: [CrossBorderAsset]) -> Double {
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        guard totalValue > 0 else { return 0.0 }
        
        var weightedTaxEfficiencySum = 0.0
        
        for asset in assets {
            guard asset.isIncludedInPortfolio else { continue }
            let weight = Double(truncating: (asset.currentValue / totalValue) as NSDecimalNumber)
            let taxEfficiencyScore = getTaxEfficiencyScore(for: asset.assetType)
            weightedTaxEfficiencySum += weight * taxEfficiencyScore
        }
        
        return weightedTaxEfficiencySum
    }
    
    /// Get tax efficiency score for asset type
    private static func getTaxEfficiencyScore(for assetType: AssetType) -> Double {
        if assetType.isTaxAdvantaged {
            return 5.0  // Highest score for tax-advantaged assets
        } else if assetType.isSubjectToCapitalGains {
            return 3.0  // Medium score for capital gains assets
        } else {
            return 4.0  // Good score for non-taxed assets
        }
    }
    
    /// Identify tax optimization opportunities
    public static func identifyTaxOptimizationOpportunities(assets: [CrossBorderAsset]) -> [TaxOptimizationOpportunity] {
        var opportunities: [TaxOptimizationOpportunity] = []
        
        // Check for tax loss harvesting opportunities
        let assetsWithLosses = assets.filter { asset in
            guard let unrealizedGain = asset.unrealizedGainLoss else { return false }
            return unrealizedGain < 0 && asset.isLiquid && asset.qualifiesForLongTermCapitalGains
        }
        
        if !assetsWithLosses.isEmpty {
            opportunities.append(.taxLossHarvesting(assets: assetsWithLosses))
        }
        
        // Check for assets that could be moved to tax-advantaged accounts
        let nonTaxAdvantagedAssets = assets.filter { !$0.assetType.isTaxAdvantaged && $0.assetType.isSubjectToCapitalGains }
        if !nonTaxAdvantagedAssets.isEmpty {
            opportunities.append(.moveToTaxAdvantagedAccount(assets: nonTaxAdvantagedAssets))
        }
        
        // Check for assets approaching long-term capital gains qualification
        let nearLongTermAssets = assets.filter { asset in
            if let age = asset.investmentAgeYears {
                return age > 0.8 && age < 1.0 && !asset.qualifiesForLongTermCapitalGains
            }
            return false
        }
        
        if !nearLongTermAssets.isEmpty {
            opportunities.append(.holdForLongTermCapitalGains(assets: nearLongTermAssets))
        }
        
        return opportunities
    }
    
    // MARK: - Rebalancing
    
    /// Generate rebalancing recommendations
    public static func generateRebalancingRecommendations(
        currentAssets: [CrossBorderAsset],
        targetAllocation: [PortfolioAllocationCategory: Double],
        minimumTradeAmount: Decimal = 1000
    ) -> [RebalancingAction] {
        let analysis = analyzeAllocationDeviation(currentAssets: currentAssets, targetAllocation: targetAllocation)
        let totalPortfolioValue = currentAssets.reduce(Decimal.zero) { $0 + $1.currentValue }
        
        var actions: [RebalancingAction] = []
        
        // Generate sell recommendations for overweight categories
        for (category, overweightPercent) in analysis.overweight {
            let overweightValue = totalPortfolioValue * Decimal(overweightPercent / 100.0)
            if overweightValue >= minimumTradeAmount {
                let assetsInCategory = currentAssets.filter { 
                    getPortfolioAllocationCategory(for: $0.assetType) == category && $0.isLiquid 
                }
                if !assetsInCategory.isEmpty {
                    actions.append(.sell(category: category, amount: overweightValue, suggestedAssets: assetsInCategory))
                }
            }
        }
        
        // Generate buy recommendations for underweight categories
        for (category, underweightPercent) in analysis.underweight {
            let underweightValue = totalPortfolioValue * Decimal(underweightPercent / 100.0)
            if underweightValue >= minimumTradeAmount {
                actions.append(.buy(category: category, amount: underweightValue))
            }
        }
        
        return actions
    }
}

// MARK: - Supporting Types

/// Portfolio allocation categories for analysis
public enum PortfolioAllocationCategory: String, CaseIterable, Codable {
    case domesticEquity = "domesticEquity"
    case internationalEquity = "internationalEquity"
    case domesticBonds = "domesticBonds"
    case internationalBonds = "internationalBonds"
    case alternatives = "alternatives"
    case cash = "cash"
    case others = "others"
    
    public var displayName: String {
        switch self {
        case .domesticEquity: return "Domestic Equity"
        case .internationalEquity: return "International Equity"
        case .domesticBonds: return "Domestic Bonds"
        case .internationalBonds: return "International Bonds"
        case .alternatives: return "Alternatives"
        case .cash: return "Cash & Equivalents"
        case .others: return "Others"
        }
    }
}

/// Investor risk profiles
public enum InvestorProfile: String, CaseIterable, Codable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"
    case growth = "growth"
    case income = "income"
    
    public var displayName: String {
        switch self {
        case .conservative: return "Conservative"
        case .moderate: return "Moderate"
        case .aggressive: return "Aggressive"
        case .growth: return "Growth-Focused"
        case .income: return "Income-Focused"
        }
    }
    
    public var description: String {
        switch self {
        case .conservative: return "Capital preservation with minimal risk"
        case .moderate: return "Balanced growth and stability"
        case .aggressive: return "High growth potential with higher risk"
        case .growth: return "Maximum capital appreciation"
        case .income: return "Regular income generation"
        }
    }
}

/// Portfolio allocation analysis results
public struct AllocationAnalysis: Codable {
    public let overweight: [PortfolioAllocationCategory: Double]
    public let underweight: [PortfolioAllocationCategory: Double]
    public let onTarget: [PortfolioAllocationCategory]
    public let totalDeviation: Double
    
    public var needsRebalancing: Bool {
        return totalDeviation > 10.0  // Threshold for rebalancing recommendation
    }
}

/// Tax optimization opportunities
public enum TaxOptimizationOpportunity {
    case taxLossHarvesting(assets: [CrossBorderAsset])
    case moveToTaxAdvantagedAccount(assets: [CrossBorderAsset])
    case holdForLongTermCapitalGains(assets: [CrossBorderAsset])
    
    public var description: String {
        switch self {
        case .taxLossHarvesting:
            return "Harvest tax losses to offset gains"
        case .moveToTaxAdvantagedAccount:
            return "Move assets to tax-advantaged accounts"
        case .holdForLongTermCapitalGains:
            return "Hold assets for long-term capital gains treatment"
        }
    }
}

/// Rebalancing action recommendations
public enum RebalancingAction {
    case buy(category: PortfolioAllocationCategory, amount: Decimal)
    case sell(category: PortfolioAllocationCategory, amount: Decimal, suggestedAssets: [CrossBorderAsset])
    
    public var description: String {
        switch self {
        case .buy(let category, let amount):
            return "Buy \(category.displayName): \(amount)"
        case .sell(let category, let amount, _):
            return "Sell \(category.displayName): \(amount)"
        }
    }
}