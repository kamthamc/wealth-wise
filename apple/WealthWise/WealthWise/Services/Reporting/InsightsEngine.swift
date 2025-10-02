//
//  InsightsEngine.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Insights Generation Service
//

import Foundation
import SwiftData

/// Service for generating intelligent portfolio insights and recommendations
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class InsightsEngine {
    
    private let modelContext: ModelContext
    
    // Target allocations for portfolio rebalancing
    private let targetEquityAllocation: Double = 60.0
    private let targetDebtAllocation: Double = 30.0
    private let targetGoldAllocation: Double = 10.0
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Insight Generation
    
    /// Generate all insights for the portfolio
    public func generateInsights(
        transactions: [Transaction],
        goals: [Goal],
        assets: [CrossBorderAsset]
    ) async throws -> [Insight] {
        
        var insights: [Insight] = []
        
        // Generate rebalancing insights
        insights.append(contentsOf: try await generateRebalancingInsights(assets: assets))
        
        // Generate tax saving insights
        insights.append(contentsOf: try await generateTaxSavingInsights(transactions: transactions))
        
        // Generate performance insights
        insights.append(contentsOf: try await generatePerformanceInsights(assets: assets))
        
        // Generate goal alignment insights
        insights.append(contentsOf: try await generateGoalAlignmentInsights(goals: goals, transactions: transactions))
        
        // Generate diversification insights
        insights.append(contentsOf: try await generateDiversificationInsights(assets: assets))
        
        // Save insights to model context
        for insight in insights {
            modelContext.insert(insight)
        }
        try modelContext.save()
        
        return insights
    }
    
    // MARK: - Rebalancing Insights
    
    /// Generate portfolio rebalancing insights
    private func generateRebalancingInsights(assets: [CrossBorderAsset]) async throws -> [Insight] {
        var insights: [Insight] = []
        
        guard !assets.isEmpty else { return insights }
        
        // Calculate current allocation
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        guard totalValue > 0 else { return insights }
        
        // Calculate allocations by category
        let equityValue = assets.filter { $0.category == .equity }.reduce(Decimal.zero) { $0 + $1.currentValue }
        let debtValue = assets.filter { $0.category == .fixedIncome }.reduce(Decimal.zero) { $0 + $1.currentValue }
        let goldValue = assets.filter { $0.category == .alternative && $0.assetType == .gold }.reduce(Decimal.zero) { $0 + $1.currentValue }
        
        let equityPercent = Double(truncating: (equityValue / totalValue * 100) as NSDecimalNumber)
        let debtPercent = Double(truncating: (debtValue / totalValue * 100) as NSDecimalNumber)
        let goldPercent = Double(truncating: (goldValue / totalValue * 100) as NSDecimalNumber)
        
        // Check for significant deviations (>5%)
        let equityDeviation = abs(equityPercent - targetEquityAllocation)
        let debtDeviation = abs(debtPercent - targetDebtAllocation)
        let goldDeviation = abs(goldPercent - targetGoldAllocation)
        
        if equityDeviation > 5.0 || debtDeviation > 5.0 || goldDeviation > 5.0 {
            let description = NSLocalizedString(
                "rebalancing_needed_desc",
                comment: "Your portfolio allocation deviates from target. Consider rebalancing."
            )
            
            let actionable = NSLocalizedString(
                "rebalancing_action",
                comment: "Review allocation and adjust investments to match target percentages."
            )
            
            let insight = Insight(
                category: .rebalancing,
                title: NSLocalizedString("rebalancing_needed_title", comment: "Portfolio Rebalancing Needed"),
                insightDescription: description,
                actionable: actionable,
                priority: equityDeviation > 10.0 ? .high : .medium,
                impactPercentage: max(equityDeviation, debtDeviation, goldDeviation)
            )
            
            insights.append(insight)
        }
        
        return insights
    }
    
    // MARK: - Tax Saving Insights
    
    /// Generate tax saving opportunity insights
    private func generateTaxSavingInsights(transactions: [Transaction]) async throws -> [Insight] {
        var insights: [Insight] = []
        
        // Calculate current 80C investments for this financial year
        let fyStart = getFinancialYearStart()
        let fyEnd = getFinancialYearEnd()
        
        let taxSavingTransactions = transactions.filter { transaction in
            transaction.date >= fyStart && transaction.date <= fyEnd &&
            (transaction.category == .tax_saving_investment || transaction.category == .life_insurance)
        }
        
        let invested80C = taxSavingTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        let remaining80C = max(0, 150000 - invested80C)
        
        if remaining80C > 10000 {
            // Significant tax saving opportunity exists
            let potentialSaving = remaining80C * 0.30 // Assume 30% tax bracket
            
            let description = String(
                format: NSLocalizedString(
                    "tax_saving_opportunity_desc",
                    comment: "You can invest ₹%@ more in 80C to save ₹%@ in taxes"
                ),
                remaining80C.indianRupeeString(abbreviated: true),
                potentialSaving.indianRupeeString(abbreviated: true)
            )
            
            let actionable = NSLocalizedString(
                "tax_saving_action",
                comment: "Invest in ELSS, PPF, or NPS before March 31"
            )
            
            let insight = Insight(
                category: .taxSaving,
                title: NSLocalizedString("tax_saving_opportunity_title", comment: "Tax Saving Opportunity"),
                insightDescription: description,
                actionable: actionable,
                priority: remaining80C > 50000 ? .high : .medium,
                impactAmount: potentialSaving
            )
            
            insights.append(insight)
        }
        
        return insights
    }
    
    // MARK: - Performance Insights
    
    /// Generate asset performance insights
    private func generatePerformanceInsights(assets: [CrossBorderAsset]) async throws -> [Insight] {
        var insights: [Insight] = []
        
        // Analyze each asset's performance
        for asset in assets {
            guard let gainLossPercent = asset.unrealizedGainLossPercentage else { continue }
            
            // Flag underperforming assets (losing more than 10%)
            if gainLossPercent < -10.0 {
                let description = String(
                    format: NSLocalizedString(
                        "underperforming_asset_desc",
                        comment: "%@ is underperforming with %.1f%% loss"
                    ),
                    asset.name,
                    abs(gainLossPercent)
                )
                
                let actionable = NSLocalizedString(
                    "underperforming_action",
                    comment: "Review this investment and consider reallocation"
                )
                
                let insight = Insight(
                    category: .underperforming,
                    title: NSLocalizedString("underperforming_asset_title", comment: "Underperforming Asset"),
                    insightDescription: description,
                    actionable: actionable,
                    priority: gainLossPercent < -20.0 ? .high : .medium,
                    impactPercentage: abs(gainLossPercent)
                )
                insight.relatedEntityId = asset.id.uuidString
                insight.relatedEntityType = "Asset"
                
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    // MARK: - Goal Alignment Insights
    
    /// Generate goal alignment insights
    private func generateGoalAlignmentInsights(goals: [Goal], transactions: [Transaction]) async throws -> [Insight] {
        var insights: [Insight] = []
        
        for goal in goals where goal.isActive && !goal.isCompleted {
            // Check if goal is off track
            if !goal.isOnTrack {
                let shortfall = goal.remainingAmount
                let monthlyRequired = goal.requiredMonthlyContribution
                
                let description = String(
                    format: NSLocalizedString(
                        "goal_off_track_desc",
                        comment: "%@ is off track. Need ₹%@ monthly to achieve target"
                    ),
                    goal.title,
                    monthlyRequired.indianRupeeString(abbreviated: true)
                )
                
                let actionable = NSLocalizedString(
                    "goal_off_track_action",
                    comment: "Increase monthly contributions or extend target date"
                )
                
                let insight = Insight(
                    category: .goalAlignment,
                    title: NSLocalizedString("goal_off_track_title", comment: "Goal Off Track"),
                    insightDescription: description,
                    actionable: actionable,
                    priority: goal.priority == .critical ? .urgent : .high,
                    impactAmount: shortfall
                )
                insight.relatedEntityId = goal.id.uuidString
                insight.relatedEntityType = "Goal"
                
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    // MARK: - Diversification Insights
    
    /// Generate diversification insights
    private func generateDiversificationInsights(assets: [CrossBorderAsset]) async throws -> [Insight] {
        var insights: [Insight] = []
        
        guard !assets.isEmpty else { return insights }
        
        // Check sector concentration
        var sectorValues: [String: Decimal] = [:]
        let totalValue = assets.reduce(Decimal.zero) { $0 + $1.currentValue }
        
        for asset in assets {
            let sector = asset.sector ?? "Unknown"
            sectorValues[sector, default: 0] += asset.currentValue
        }
        
        // Find sectors with >30% concentration
        for (sector, value) in sectorValues {
            let concentration = Double(truncating: (value / totalValue * 100) as NSDecimalNumber)
            
            if concentration > 30.0 {
                let description = String(
                    format: NSLocalizedString(
                        "sector_concentration_desc",
                        comment: "%@ sector represents %.1f%% of portfolio. Consider diversification"
                    ),
                    sector,
                    concentration
                )
                
                let actionable = NSLocalizedString(
                    "diversification_action",
                    comment: "Spread investments across different sectors"
                )
                
                let insight = Insight(
                    category: .diversification,
                    title: NSLocalizedString("sector_concentration_title", comment: "Sector Concentration Risk"),
                    insightDescription: description,
                    actionable: actionable,
                    priority: concentration > 50.0 ? .high : .medium,
                    impactPercentage: concentration
                )
                
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    /// Get financial year start date (April 1)
    private func getFinancialYearStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        var components = DateComponents()
        components.year = month >= 4 ? year : year - 1
        components.month = 4
        components.day = 1
        
        return calendar.date(from: components) ?? now
    }
    
    /// Get financial year end date (March 31)
    private func getFinancialYearEnd() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        var components = DateComponents()
        components.year = month >= 4 ? year + 1 : year
        components.month = 3
        components.day = 31
        
        return calendar.date(from: components) ?? now
    }
}
