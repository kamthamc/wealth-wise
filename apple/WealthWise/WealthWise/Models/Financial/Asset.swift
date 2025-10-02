//
//  Asset.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Financial Models Foundation - Asset Management System
//

import Foundation
import SwiftData

/// Asset model for tracking individual financial assets
/// Supports multi-currency assets with comprehensive metadata
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Asset {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var symbol: String?
    public var assetType: AssetType
    
    // MARK: - Financial Information
    
    public var currentValue: Decimal
    public var currency: String
    public var purchasePrice: Decimal?
    public var purchaseDate: Date?
    public var quantity: Decimal?
    
    // MARK: - Encrypted Fields (stored as Data for encryption)
    
    private var encryptedAccountNumber: Data?
    private var encryptedNotes: Data?
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Relationships
    
    @Relationship(inverse: \Portfolio.assets)
    public var portfolio: Portfolio?
    
    @Relationship(deleteRule: .cascade)
    public var transactions: [Transaction]
    
    // MARK: - Computed Properties
    
    /// Account number (decrypted access)
    public var accountNumber: String? {
        get {
            guard let encrypted = encryptedAccountNumber else { return nil }
            // TODO: Implement decryption using EncryptionService
            return String(data: encrypted, encoding: .utf8)
        }
        set {
            guard let value = newValue else {
                encryptedAccountNumber = nil
                return
            }
            // TODO: Implement encryption using EncryptionService
            encryptedAccountNumber = value.data(using: .utf8)
        }
    }
    
    /// Notes (decrypted access)
    public var notes: String? {
        get {
            guard let encrypted = encryptedNotes else { return nil }
            // TODO: Implement decryption using EncryptionService
            return String(data: encrypted, encoding: .utf8)
        }
        set {
            guard let value = newValue else {
                encryptedNotes = nil
                return
            }
            // TODO: Implement encryption using EncryptionService
            encryptedNotes = value.data(using: .utf8)
        }
    }
    
    /// Total cost basis
    public var costBasis: Decimal {
        guard let purchasePrice = purchasePrice, let quantity = quantity else {
            return 0
        }
        return purchasePrice * quantity
    }
    
    /// Total market value
    public var marketValue: Decimal {
        guard let quantity = quantity else {
            return currentValue
        }
        return currentValue * quantity
    }
    
    /// Unrealized gain/loss
    public var unrealizedGainLoss: Decimal {
        return marketValue - costBasis
    }
    
    /// Unrealized gain/loss percentage
    public var unrealizedGainLossPercentage: Decimal {
        guard costBasis > 0 else { return 0 }
        return (unrealizedGainLoss / costBasis) * 100
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        symbol: String? = nil,
        assetType: AssetType,
        currentValue: Decimal,
        currency: String,
        purchasePrice: Decimal? = nil,
        purchaseDate: Date? = nil,
        quantity: Decimal? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.assetType = assetType
        self.currentValue = currentValue
        self.currency = currency
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.quantity = quantity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.transactions = []
    }
}

// MARK: - Helper Methods

@available(iOS 18.6, macOS 15.6, *)
extension Asset {
    
    /// Update current value
    public func updateValue(_ newValue: Decimal) {
        currentValue = newValue
        updatedAt = Date()
    }
    
    /// Add a transaction
    public func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        updatedAt = Date()
    }
}
