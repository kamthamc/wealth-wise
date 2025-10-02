//
//  PortfolioTransaction.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Portfolio Management System: Portfolio transaction data model
//

import Foundation
import SwiftData

/// Portfolio transaction model for tracking buy/sell/dividend transactions
/// Supports detailed transaction history with P&L tracking
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class PortfolioTransaction {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var transactionType: PortfolioTransactionType
    public var symbol: String
    public var assetName: String
    
    // MARK: - Transaction Details
    
    public var date: Date
    public var quantity: Decimal
    public var pricePerUnit: Decimal
    public var totalAmount: Decimal
    public var currency: String
    
    // MARK: - Costs and Fees
    
    public var brokerage: Decimal?
    public var taxes: Decimal?
    public var otherCharges: Decimal?
    
    // MARK: - P&L Tracking
    
    public var realizedGainLoss: Decimal?      // For sell transactions
    public var averageCostBasis: Decimal?       // Cost basis at time of sale
    
    // MARK: - Reference Information
    
    public var referenceNumber: String?
    public var broker: String?
    public var exchange: String?
    public var notes: String?
    
    // MARK: - Timestamps
    
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Relationships
    
    @Relationship(inverse: \Portfolio.transactions) public var portfolio: Portfolio?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        transactionType: PortfolioTransactionType,
        symbol: String,
        assetName: String,
        date: Date = Date(),
        quantity: Decimal,
        pricePerUnit: Decimal,
        currency: String = "INR",
        brokerage: Decimal? = nil,
        taxes: Decimal? = nil,
        otherCharges: Decimal? = nil,
        realizedGainLoss: Decimal? = nil,
        averageCostBasis: Decimal? = nil,
        referenceNumber: String? = nil,
        broker: String? = nil,
        exchange: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.transactionType = transactionType
        self.symbol = symbol
        self.assetName = assetName
        self.date = date
        self.quantity = quantity
        self.pricePerUnit = pricePerUnit
        self.totalAmount = quantity * pricePerUnit
        self.currency = currency
        self.brokerage = brokerage
        self.taxes = taxes
        self.otherCharges = otherCharges
        self.realizedGainLoss = realizedGainLoss
        self.averageCostBasis = averageCostBasis
        self.referenceNumber = referenceNumber
        self.broker = broker
        self.exchange = exchange
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    // MARK: - Computed Properties
    
    /// Total transaction cost including all fees
    public var totalCost: Decimal {
        let fees = (brokerage ?? 0) + (taxes ?? 0) + (otherCharges ?? 0)
        return totalAmount + fees
    }
    
    /// Net proceeds (for sell transactions, after fees)
    public var netProceeds: Decimal {
        guard transactionType == .sell else { return 0 }
        let fees = (brokerage ?? 0) + (taxes ?? 0) + (otherCharges ?? 0)
        return totalAmount - fees
    }
    
    /// Display description for transaction
    public var displayDescription: String {
        let action = transactionType.displayName
        let qtyFormatted = String(format: "%.2f", Double(truncating: quantity as NSDecimalNumber))
        return "\(action) \(qtyFormatted) units of \(symbol)"
    }
}

// MARK: - Supporting Types

/// Portfolio transaction type
public enum PortfolioTransactionType: String, Codable, CaseIterable {
    case buy = "buy"
    case sell = "sell"
    case dividend = "dividend"
    case split = "split"
    case bonus = "bonus"
    case merger = "merger"
    case spinoff = "spinoff"
    case rights = "rights"
    
    public var displayName: String {
        switch self {
        case .buy:
            return NSLocalizedString("transaction_type_buy", comment: "Buy transaction")
        case .sell:
            return NSLocalizedString("transaction_type_sell", comment: "Sell transaction")
        case .dividend:
            return NSLocalizedString("transaction_type_dividend", comment: "Dividend transaction")
        case .split:
            return NSLocalizedString("transaction_type_split", comment: "Stock split transaction")
        case .bonus:
            return NSLocalizedString("transaction_type_bonus", comment: "Bonus shares transaction")
        case .merger:
            return NSLocalizedString("transaction_type_merger", comment: "Merger transaction")
        case .spinoff:
            return NSLocalizedString("transaction_type_spinoff", comment: "Spinoff transaction")
        case .rights:
            return NSLocalizedString("transaction_type_rights", comment: "Rights issue transaction")
        }
    }
    
    public var affectsQuantity: Bool {
        switch self {
        case .buy, .sell, .bonus, .split, .rights:
            return true
        case .dividend, .merger, .spinoff:
            return false
        }
    }
    
    public var increasesQuantity: Bool {
        switch self {
        case .buy, .bonus, .split, .rights:
            return true
        case .sell, .dividend, .merger, .spinoff:
            return false
        }
    }
}
