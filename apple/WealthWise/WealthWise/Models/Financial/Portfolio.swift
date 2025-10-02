//
//  Portfolio.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Financial Models Foundation - Portfolio Management System
//

import Foundation
import SwiftData

/// Portfolio model for grouping and managing financial assets
/// Supports multi-currency portfolios with comprehensive tracking
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Portfolio {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var portfolioDescription: String?
    public var currency: String // Base currency for portfolio
    public var isDefault: Bool
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .cascade, inverse: \Asset.portfolio)
    public var assets: [Asset]
    
    @Relationship(deleteRule: .cascade)
    public var transactions: [Transaction]
    
    // MARK: - Computed Properties
    
    /// Total value of portfolio in base currency
    public var totalValue: Decimal {
        assets.reduce(0) { $0 + $1.currentValue }
    }
    
    /// Number of assets in portfolio
    public var assetCount: Int {
        assets.count
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        portfolioDescription: String? = nil,
        currency: String = "USD",
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.portfolioDescription = portfolioDescription
        self.currency = currency
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.assets = []
        self.transactions = []
    }
}

// MARK: - Helper Methods

@available(iOS 18.6, macOS 15.6, *)
extension Portfolio {
    
    /// Add an asset to the portfolio
    public func addAsset(_ asset: Asset) {
        assets.append(asset)
        updatedAt = Date()
    }
    
    /// Remove an asset from the portfolio
    public func removeAsset(_ asset: Asset) {
        assets.removeAll { $0.id == asset.id }
        updatedAt = Date()
    }
    
    /// Get assets by type
    public func assets(ofType type: AssetType) -> [Asset] {
        assets.filter { $0.assetType == type }
    }
}
