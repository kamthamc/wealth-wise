//
//  Portfolio.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Portfolio Management System: Core portfolio data model
//

import Foundation
import SwiftData

/// Portfolio model for managing a collection of investment holdings
/// Supports portfolio-level analytics, performance tracking, and diversification analysis
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Portfolio {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var portfolioDescription: String?
    public var portfolioType: PortfolioType
    
    // MARK: - Timestamps
    
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Configuration
    
    public var baseCurrency: String
    public var riskProfile: InvestorProfile
    public var isActive: Bool
    
    // MARK: - Target Allocation (optional)
    
    public var targetAllocation: [String: Decimal]? // Category -> Target %
    
    // MARK: - Metadata
    
    public var tags: [String]
    public var notes: String?
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .cascade) public var holdings: [Holding]
    @Relationship(deleteRule: .cascade) public var transactions: [PortfolioTransaction]
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        portfolioDescription: String? = nil,
        portfolioType: PortfolioType = .diversified,
        baseCurrency: String = "INR",
        riskProfile: InvestorProfile = .moderate,
        isActive: Bool = true,
        targetAllocation: [String: Decimal]? = nil,
        tags: [String] = [],
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.portfolioDescription = portfolioDescription
        self.portfolioType = portfolioType
        self.baseCurrency = baseCurrency
        self.riskProfile = riskProfile
        self.isActive = isActive
        self.targetAllocation = targetAllocation
        self.tags = tags
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.holdings = []
        self.transactions = []
    }
    
    // MARK: - Computed Properties
    
    /// Total portfolio value in base currency
    public var totalValue: Decimal {
        return holdings.reduce(0) { $0 + $1.currentValue }
    }
    
    /// Total invested amount (cost basis)
    public var totalInvested: Decimal {
        return holdings.reduce(0) { $0 + $1.totalCost }
    }
    
    /// Total unrealized gain/loss
    public var unrealizedGainLoss: Decimal {
        return totalValue - totalInvested
    }
    
    /// Total unrealized gain/loss percentage
    public var unrealizedGainLossPercentage: Double {
        guard totalInvested > 0 else { return 0 }
        return Double(truncating: (unrealizedGainLoss / totalInvested * 100) as NSDecimalNumber)
    }
    
    /// Total realized gains from transactions
    public var realizedGains: Decimal {
        return transactions
            .filter { $0.transactionType == .sell }
            .reduce(0) { $0 + ($1.realizedGainLoss ?? 0) }
    }
    
    /// Number of holdings in portfolio
    public var holdingsCount: Int {
        return holdings.count
    }
    
    /// Active holdings (non-zero quantity)
    public var activeHoldings: [Holding] {
        return holdings.filter { $0.quantity > 0 }
    }
}

// MARK: - Supporting Types

/// Portfolio type classification
public enum PortfolioType: String, Codable, CaseIterable {
    case diversified = "diversified"       // Balanced multi-asset portfolio
    case equity = "equity"                 // Equity-focused portfolio
    case fixedIncome = "fixedIncome"      // Fixed income focused
    case retirement = "retirement"         // Retirement/pension portfolio
    case growth = "growth"                 // Growth-oriented portfolio
    case income = "income"                 // Income-generating portfolio
    case custom = "custom"                 // Custom strategy
    
    public var displayName: String {
        switch self {
        case .diversified:
            return NSLocalizedString("portfolio_type_diversified", comment: "Diversified portfolio type")
        case .equity:
            return NSLocalizedString("portfolio_type_equity", comment: "Equity portfolio type")
        case .fixedIncome:
            return NSLocalizedString("portfolio_type_fixed_income", comment: "Fixed income portfolio type")
        case .retirement:
            return NSLocalizedString("portfolio_type_retirement", comment: "Retirement portfolio type")
        case .growth:
            return NSLocalizedString("portfolio_type_growth", comment: "Growth portfolio type")
        case .income:
            return NSLocalizedString("portfolio_type_income", comment: "Income portfolio type")
        case .custom:
            return NSLocalizedString("portfolio_type_custom", comment: "Custom portfolio type")
        }
    }
}

/// Investor risk profile (from AssetManager.swift)
public enum InvestorProfile: String, Codable, CaseIterable {
    case conservative = "conservative"
    case moderate = "moderate"
    case aggressive = "aggressive"
    case growth = "growth"
    case income = "income"
    
    public var displayName: String {
        switch self {
        case .conservative:
            return NSLocalizedString("investor_profile_conservative", comment: "Conservative investor profile")
        case .moderate:
            return NSLocalizedString("investor_profile_moderate", comment: "Moderate investor profile")
        case .aggressive:
            return NSLocalizedString("investor_profile_aggressive", comment: "Aggressive investor profile")
        case .growth:
            return NSLocalizedString("investor_profile_growth", comment: "Growth investor profile")
        case .income:
            return NSLocalizedString("investor_profile_income", comment: "Income investor profile")
        }
    }
}

/// Portfolio allocation category (from AssetManager.swift)
public enum PortfolioAllocationCategory: String, Codable, CaseIterable {
    case domesticEquity = "domesticEquity"
    case internationalEquity = "internationalEquity"
    case domesticBonds = "domesticBonds"
    case internationalBonds = "internationalBonds"
    case alternatives = "alternatives"
    case cash = "cash"
    case others = "others"
    
    public var displayName: String {
        switch self {
        case .domesticEquity:
            return NSLocalizedString("allocation_domestic_equity", comment: "Domestic equity allocation")
        case .internationalEquity:
            return NSLocalizedString("allocation_international_equity", comment: "International equity allocation")
        case .domesticBonds:
            return NSLocalizedString("allocation_domestic_bonds", comment: "Domestic bonds allocation")
        case .internationalBonds:
            return NSLocalizedString("allocation_international_bonds", comment: "International bonds allocation")
        case .alternatives:
            return NSLocalizedString("allocation_alternatives", comment: "Alternative investments allocation")
        case .cash:
            return NSLocalizedString("allocation_cash", comment: "Cash allocation")
        case .others:
            return NSLocalizedString("allocation_others", comment: "Other assets allocation")
        }
    }
}
