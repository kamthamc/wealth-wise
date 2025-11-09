//
//  Account.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-08.
//  Account Management - Matches Firebase webapp schema
//

import Foundation
import SwiftData

/// Account model matching the Firebase webapp implementation
/// Supports Bank, Credit Card, UPI, and Brokerage accounts
@available(iOS 18.0, macOS 15.0, *)
@Model
public final class Account {
    
    // MARK: - Primary Properties
    
    /// Unique identifier matching Firestore document ID
    @Attribute(.unique) public var id: UUID
    
    /// User ID from Firebase Authentication
    public var userId: String
    
    /// Account display name
    public var name: String
    
    /// Account type (bank, credit_card, upi, brokerage)
    public var type: AccountType
    
    /// Financial institution name (optional)
    public var institution: String?
    
    /// Current balance calculated from transactions
    public var currentBalance: Decimal
    
    /// Currency code (default: INR)
    public var currency: String
    
    /// Whether account is archived/inactive
    public var isArchived: Bool
    
    /// Account creation timestamp
    public var createdAt: Date
    
    /// Last update timestamp
    public var updatedAt: Date
    
    // MARK: - Relationships
    
    /// All transactions for this account
    @Relationship(deleteRule: .cascade, inverse: \WebAppTransaction.account)
    public var transactions: [WebAppTransaction]? = []
    
    // MARK: - Computed Properties
    
    /// Account type display name
    public var typeDisplayName: String {
        switch type {
        case .bank:
            return NSLocalizedString("account_type_bank", comment: "Bank Account")
        case .creditCard:
            return NSLocalizedString("account_type_credit_card", comment: "Credit Card")
        case .upi:
            return NSLocalizedString("account_type_upi", comment: "UPI Wallet")
        case .brokerage:
            return NSLocalizedString("account_type_brokerage", comment: "Brokerage Account")
        }
    }
    
    /// Icon name for the account type
    public var iconName: String {
        switch type {
        case .bank: return "banknote"
        case .creditCard: return "creditcard"
        case .upi: return "indianrupeesign.circle"
        case .brokerage: return "chart.line.uptrend.xyaxis"
        }
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        type: AccountType,
        institution: String? = nil,
        currentBalance: Decimal = 0,
        currency: String = "INR",
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.institution = institution
        self.currentBalance = currentBalance
        self.currency = currency
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    // MARK: - Methods
    
    /// Recalculate balance from transactions
    public func recalculateBalance() {
        guard let transactions = transactions else {
            currentBalance = 0
            return
        }
        
        let total = transactions.reduce(Decimal(0)) { sum, transaction in
            switch transaction.type {
            case .credit:
                return sum + transaction.amount
            case .debit:
                return sum - transaction.amount
            }
        }
        
        currentBalance = total
        updatedAt = Date()
    }
    
    /// Convert to Firestore dictionary
    public func toFirestore() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "type": type.rawValue,
            "institution": institution as Any,
            "balance": NSDecimalNumber(decimal: currentBalance).doubleValue,
            "currency": currency,
            "isArchived": isArchived,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

// MARK: - Account Type

extension Account {
    /// Account type matching webapp AccountType
    public enum AccountType: String, Codable, CaseIterable {
        case bank = "bank"
        case creditCard = "credit_card"
        case upi = "upi"
        case brokerage = "brokerage"
    }
}

// MARK: - Sample Data

#if DEBUG
extension Account {
    static var sampleBank: Account {
        Account(
            userId: "sample_user",
            name: "HDFC Savings",
            type: .bank,
            institution: "HDFC Bank",
            currentBalance: 125000
        )
    }
    
    static var sampleCreditCard: Account {
        Account(
            userId: "sample_user",
            name: "ICICI Credit Card",
            type: .creditCard,
            institution: "ICICI Bank",
            currentBalance: -15000
        )
    }
    
    static var sampleUPI: Account {
        Account(
            userId: "sample_user",
            name: "Google Pay",
            type: .upi,
            currentBalance: 5000
        )
    }
    
    static var samples: [Account] {
        [sampleBank, sampleCreditCard, sampleUPI]
    }
}
#endif
