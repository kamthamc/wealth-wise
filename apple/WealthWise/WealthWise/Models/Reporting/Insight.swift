//
//  Insight.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Insights Models
//

import Foundation
import SwiftData

/// Insight model for intelligent portfolio suggestions and recommendations
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Insight {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var category: InsightCategory
    public var title: String
    public var insightDescription: String
    public var actionable: String? // Specific action user can take
    
    // MARK: - Priority and Impact
    
    public var priority: InsightPriority
    public var impactAmount: Decimal? // Financial impact if applicable
    public var impactPercentage: Double? // Percentage impact
    
    // MARK: - Status
    
    public var generatedAt: Date
    public var expiresAt: Date? // When insight becomes stale
    public var isDismissed: Bool
    public var dismissedAt: Date?
    public var isActedUpon: Bool
    public var actedUponAt: Date?
    
    // MARK: - Metadata
    
    public var tags: [String]
    public var relatedEntityId: String? // ID of related goal, asset, or transaction
    public var relatedEntityType: String? // Type of related entity
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        category: InsightCategory,
        title: String,
        insightDescription: String,
        actionable: String? = nil,
        priority: InsightPriority = .medium,
        impactAmount: Decimal? = nil,
        impactPercentage: Double? = nil,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.insightDescription = insightDescription
        self.actionable = actionable
        self.priority = priority
        self.impactAmount = impactAmount
        self.impactPercentage = impactPercentage
        self.generatedAt = generatedAt
        self.isDismissed = false
        self.isActedUpon = false
        self.tags = []
        
        // Set expiration date based on category (insights expire after 30 days by default)
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 30, to: generatedAt)
    }
    
    // MARK: - Computed Properties
    
    /// Whether this insight is still valid
    public var isValid: Bool {
        guard let expiresAt = expiresAt else { return true }
        return Date() < expiresAt
    }
    
    /// Whether this insight should be shown to user
    public var shouldShow: Bool {
        return !isDismissed && !isActedUpon && isValid
    }
    
    /// Impact display string
    public var impactDisplay: String {
        if let amount = impactAmount {
            return amount.indianRupeeString(abbreviated: true)
        } else if let percentage = impactPercentage {
            return String(format: "%.1f%%", percentage)
        }
        return NSLocalizedString("insight_impact_unknown", comment: "Impact unknown")
    }
    
    // MARK: - Actions
    
    /// Mark insight as dismissed
    @MainActor
    public func dismiss() {
        self.isDismissed = true
        self.dismissedAt = Date()
    }
    
    /// Mark insight as acted upon
    @MainActor
    public func markAsActedUpon() {
        self.isActedUpon = true
        self.actedUponAt = Date()
    }
}

// MARK: - Supporting Types

/// Insight category enumeration
public enum InsightCategory: String, CaseIterable, Codable, Sendable {
    case rebalancing = "rebalancing"
    case taxSaving = "tax_saving"
    case underperforming = "underperforming"
    case diversification = "diversification"
    case goalAlignment = "goal_alignment"
    case riskManagement = "risk_management"
    case costOptimization = "cost_optimization"
    case opportunity = "opportunity"
    
    public var displayName: String {
        switch self {
        case .rebalancing:
            return NSLocalizedString("insight_category_rebalancing", comment: "Portfolio rebalancing")
        case .taxSaving:
            return NSLocalizedString("insight_category_tax_saving", comment: "Tax saving opportunity")
        case .underperforming:
            return NSLocalizedString("insight_category_underperforming", comment: "Underperforming asset")
        case .diversification:
            return NSLocalizedString("insight_category_diversification", comment: "Diversification needed")
        case .goalAlignment:
            return NSLocalizedString("insight_category_goal_alignment", comment: "Goal alignment")
        case .riskManagement:
            return NSLocalizedString("insight_category_risk_management", comment: "Risk management")
        case .costOptimization:
            return NSLocalizedString("insight_category_cost_optimization", comment: "Cost optimization")
        case .opportunity:
            return NSLocalizedString("insight_category_opportunity", comment: "Investment opportunity")
        }
    }
    
    public var icon: String {
        switch self {
        case .rebalancing: return "chart.pie.fill"
        case .taxSaving: return "indianrupeesign.circle.fill"
        case .underperforming: return "arrow.down.circle.fill"
        case .diversification: return "square.grid.2x2.fill"
        case .goalAlignment: return "target"
        case .riskManagement: return "shield.fill"
        case .costOptimization: return "dollarsign.circle.fill"
        case .opportunity: return "lightbulb.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .rebalancing: return "blue"
        case .taxSaving: return "green"
        case .underperforming: return "red"
        case .diversification: return "orange"
        case .goalAlignment: return "purple"
        case .riskManagement: return "yellow"
        case .costOptimization: return "teal"
        case .opportunity: return "indigo"
        }
    }
}

/// Insight priority levels
public enum InsightPriority: String, CaseIterable, Codable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    public var displayName: String {
        switch self {
        case .low:
            return NSLocalizedString("priority_low", comment: "Low priority")
        case .medium:
            return NSLocalizedString("priority_medium", comment: "Medium priority")
        case .high:
            return NSLocalizedString("priority_high", comment: "High priority")
        case .urgent:
            return NSLocalizedString("priority_urgent", comment: "Urgent priority")
        }
    }
    
    public var sortOrder: Int {
        switch self {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

/// Portfolio rebalancing suggestion
public struct RebalancingSuggestion: Codable, Identifiable, Sendable {
    public let id: UUID
    public let assetCategory: String
    public let currentAllocation: Double // Percentage
    public let targetAllocation: Double // Percentage
    public let deviation: Double // Percentage points
    public let action: RebalancingAction
    public let suggestedAmount: Decimal
    
    public init(
        id: UUID = UUID(),
        assetCategory: String,
        currentAllocation: Double,
        targetAllocation: Double,
        suggestedAmount: Decimal
    ) {
        self.id = id
        self.assetCategory = assetCategory
        self.currentAllocation = currentAllocation
        self.targetAllocation = targetAllocation
        self.deviation = currentAllocation - targetAllocation
        
        // Determine action based on deviation
        if deviation > 0 {
            self.action = .reduce
        } else if deviation < 0 {
            self.action = .increase
        } else {
            self.action = .maintain
        }
        
        self.suggestedAmount = suggestedAmount
    }
    
    public var deviationDisplay: String {
        let absDeviation = abs(deviation)
        return String(format: "%.1f%%", absDeviation)
    }
}

/// Rebalancing action
public enum RebalancingAction: String, CaseIterable, Codable, Sendable {
    case increase = "increase"
    case reduce = "reduce"
    case maintain = "maintain"
    
    public var displayName: String {
        switch self {
        case .increase:
            return NSLocalizedString("rebalancing_increase", comment: "Increase allocation")
        case .reduce:
            return NSLocalizedString("rebalancing_reduce", comment: "Reduce allocation")
        case .maintain:
            return NSLocalizedString("rebalancing_maintain", comment: "Maintain allocation")
        }
    }
    
    public var icon: String {
        switch self {
        case .increase: return "arrow.up.circle.fill"
        case .reduce: return "arrow.down.circle.fill"
        case .maintain: return "checkmark.circle.fill"
        }
    }
}

/// Tax saving opportunity
public struct TaxSavingOpportunity: Codable, Identifiable, Sendable {
    public let id: UUID
    public let section: TaxSection
    public let currentInvestment: Decimal
    public let remainingLimit: Decimal
    public let potentialSaving: Decimal
    public let suggestion: String
    public let deadline: Date?
    
    public init(
        id: UUID = UUID(),
        section: TaxSection,
        currentInvestment: Decimal,
        remainingLimit: Decimal,
        potentialSaving: Decimal,
        suggestion: String,
        deadline: Date? = nil
    ) {
        self.id = id
        self.section = section
        self.currentInvestment = currentInvestment
        self.remainingLimit = remainingLimit
        self.potentialSaving = potentialSaving
        self.suggestion = suggestion
        self.deadline = deadline
    }
    
    public var utilizationPercentage: Double {
        let limit = section.limit
        guard limit > 0 else { return 0 }
        return Double(truncating: (currentInvestment / limit * 100) as NSDecimalNumber)
    }
}

/// Performance analysis result
public struct PerformanceAnalysis: Codable, Identifiable, Sendable {
    public let id: UUID
    public let assetName: String
    public let assetId: String
    public let returnPercentage: Double
    public let benchmarkReturn: Double
    public let relativePerformance: Double // vs benchmark
    public let isUnderperforming: Bool
    public let recommendation: String
    
    public init(
        id: UUID = UUID(),
        assetName: String,
        assetId: String,
        returnPercentage: Double,
        benchmarkReturn: Double,
        recommendation: String
    ) {
        self.id = id
        self.assetName = assetName
        self.assetId = assetId
        self.returnPercentage = returnPercentage
        self.benchmarkReturn = benchmarkReturn
        self.relativePerformance = returnPercentage - benchmarkReturn
        self.isUnderperforming = relativePerformance < -2.0 // Underperforming if 2% below benchmark
        self.recommendation = recommendation
    }
}
