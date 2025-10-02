//
//  Holding.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Portfolio Management System: Individual holding data model
//

import Foundation
import SwiftData

/// Holding model representing an individual asset position in a portfolio
/// Tracks quantity, cost basis, current value, and performance metrics
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Holding {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var symbol: String           // Stock symbol, MF code, ISIN, etc.
    public var name: String
    public var assetType: AssetType
    public var assetClass: String       // "Stock", "Mutual Fund", "ETF", etc.
    
    // MARK: - Position Details
    
    public var quantity: Decimal        // Number of units/shares held
    public var averageCost: Decimal     // Average cost per unit
    public var currentPrice: Decimal    // Current market price per unit
    public var currency: String
    
    // MARK: - Timestamps
    
    public var firstPurchaseDate: Date?
    public var lastTransactionDate: Date?
    public var lastPriceUpdate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Identification
    
    public var isin: String?           // International Securities Identification Number
    public var exchange: String?       // Exchange where traded
    public var sector: String?
    public var industry: String?
    
    // MARK: - Additional Details
    
    public var notes: String?
    public var tags: [String]
    
    // MARK: - Relationships
    
    @Relationship(inverse: \Portfolio.holdings) public var portfolio: Portfolio?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        assetType: AssetType,
        assetClass: String,
        quantity: Decimal,
        averageCost: Decimal,
        currentPrice: Decimal,
        currency: String = "INR",
        firstPurchaseDate: Date? = nil,
        lastTransactionDate: Date? = nil,
        lastPriceUpdate: Date? = nil,
        isin: String? = nil,
        exchange: String? = nil,
        sector: String? = nil,
        industry: String? = nil,
        notes: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.assetType = assetType
        self.assetClass = assetClass
        self.quantity = quantity
        self.averageCost = averageCost
        self.currentPrice = currentPrice
        self.currency = currency
        self.firstPurchaseDate = firstPurchaseDate
        self.lastTransactionDate = lastTransactionDate
        self.lastPriceUpdate = lastPriceUpdate
        self.isin = isin
        self.exchange = exchange
        self.sector = sector
        self.industry = industry
        self.notes = notes
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// Total cost basis (quantity × average cost)
    public var totalCost: Decimal {
        return quantity * averageCost
    }
    
    /// Current market value (quantity × current price)
    public var currentValue: Decimal {
        return quantity * currentPrice
    }
    
    /// Unrealized gain/loss in currency units
    public var unrealizedGainLoss: Decimal {
        return currentValue - totalCost
    }
    
    /// Unrealized gain/loss percentage
    public var unrealizedGainLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return Double(truncating: (unrealizedGainLoss / totalCost * 100) as NSDecimalNumber)
    }
    
    /// Whether this is a profitable position
    public var isProfitable: Bool {
        return unrealizedGainLoss > 0
    }
    
    /// Weight in portfolio (to be calculated by service layer with portfolio context)
    public func portfolioWeight(in portfolio: Portfolio) -> Double {
        let portfolioValue = portfolio.totalValue
        guard portfolioValue > 0 else { return 0 }
        return Double(truncating: (currentValue / portfolioValue * 100) as NSDecimalNumber)
    }
    
    /// Days since first purchase
    public var holdingPeriodDays: Int? {
        guard let firstPurchase = firstPurchaseDate else { return nil }
        return Calendar.current.dateComponents([.day], from: firstPurchase, to: Date()).day
    }
    
    /// Years since first purchase
    public var holdingPeriodYears: Double? {
        guard let days = holdingPeriodDays else { return nil }
        return Double(days) / 365.25
    }
    
    /// Annualized return percentage
    public var annualizedReturn: Double? {
        guard let years = holdingPeriodYears, years > 0, totalCost > 0 else { return nil }
        let growthFactor = Double(truncating: (currentValue / totalCost) as NSDecimalNumber)
        return (pow(growthFactor, 1.0 / years) - 1.0) * 100.0
    }
}

// MARK: - Helper Methods

extension Holding {
    
    /// Update the current price and timestamp
    public func updatePrice(_ newPrice: Decimal) {
        self.currentPrice = newPrice
        self.lastPriceUpdate = Date()
        self.updatedAt = Date()
    }
    
    /// Add units to the holding (for buy transactions)
    public func addUnits(quantity: Decimal, costPerUnit: Decimal) {
        let newTotalCost = self.totalCost + (quantity * costPerUnit)
        let newQuantity = self.quantity + quantity
        
        self.quantity = newQuantity
        self.averageCost = newQuantity > 0 ? newTotalCost / newQuantity : 0
        self.lastTransactionDate = Date()
        self.updatedAt = Date()
        
        if self.firstPurchaseDate == nil {
            self.firstPurchaseDate = Date()
        }
    }
    
    /// Remove units from the holding (for sell transactions)
    public func removeUnits(quantity: Decimal) -> Decimal? {
        guard quantity <= self.quantity else { return nil }
        
        self.quantity -= quantity
        self.lastTransactionDate = Date()
        self.updatedAt = Date()
        
        // Calculate realized gain/loss for the sold units
        let soldValue = quantity * currentPrice
        let soldCost = quantity * averageCost
        let realizedGainLoss = soldValue - soldCost
        
        return realizedGainLoss
    }
}
