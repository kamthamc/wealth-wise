//
//  WebAppTransaction.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-08.
//  Transaction model matching Firebase webapp schema
//

import Foundation
import SwiftData

/// Simplified transaction model matching the Firebase webapp implementation
/// This model focuses on core transaction tracking for the web app parity
@available(iOS 18, macOS 16, *)
@Model
public final class WebAppTransaction {
    
    // MARK: - Primary Properties
    
    /// Unique identifier matching Firestore document ID
    @Attribute(.unique) public var id: UUID
    
    /// User ID from Firebase Authentication
    public var userId: String
    
    /// Account ID this transaction belongs to
    public var accountId: UUID
    
    /// Transaction date
    public var date: Date
    
    /// Transaction amount (always positive)
    public var amount: Decimal
    
    /// Transaction type (debit or credit)
    public var type: TransactionType
    
    /// Category name (from 31 default categories or custom)
    public var category: String
    
    /// Transaction description
    public var transactionDescription: String
    
    /// Optional notes
    public var notes: String?
    
    /// Creation timestamp
    public var createdAt: Date
    
    /// Last update timestamp
    public var updatedAt: Date
    
    // MARK: - Relationships
    
    /// Related account ID (using UUID instead of relationship for now)
    // TODO: Re-enable relationship once all files are in Xcode target
    // @Relationship(inverse: \Account.transactions)
    // public var account: Account?
    
    // MARK: - Computed Properties
    
    /// Signed amount (negative for debits, positive for credits)
    public var signedAmount: Decimal {
        type == .debit ? -amount : amount
    }
    
    /// Transaction type display name
    public var typeDisplayName: String {
        type == .debit 
            ? NSLocalizedString("transaction_type_debit", comment: "Expense")
            : NSLocalizedString("transaction_type_credit", comment: "Income")
    }
    
    /// Formatted date string
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        userId: String,
        accountId: UUID,
        date: Date,
        amount: Decimal,
        type: TransactionType,
        category: String,
        description: String,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.accountId = accountId
        self.date = date
        self.amount = amount
        self.type = type
        self.category = category
        self.transactionDescription = description
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
    
    // MARK: - Methods
    
    /// Convert to Firestore dictionary
    public func toFirestore() -> [String: Any] {
        return [
            "userId": userId,
            "accountId": accountId.uuidString,
            "date": date,
            "amount": NSDecimalNumber(decimal: amount).doubleValue,
            "type": type.rawValue,
            "category": category,
            "description": transactionDescription,
            "notes": notes as Any,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

// MARK: - Transaction Type

extension WebAppTransaction {
    /// Transaction type matching webapp TransactionType
    public enum TransactionType: String, Codable, CaseIterable {
        case debit = "debit"
        case credit = "credit"
    }
}

// MARK: - Default Categories

extension WebAppTransaction {
    /// 31 default categories matching webapp
    public static let defaultCategories: [String: CategoryType] = [
        // Income (9 categories)
        "Salary": .income,
        "Business Income": .income,
        "Freelance": .income,
        "Investment Returns": .income,
        "Rental Income": .income,
        "Gift Received": .income,
        "Refund": .income,
        "Bonus": .income,
        "Other Income": .income,
        
        // Expenses (15 categories)
        "Groceries": .expense,
        "Rent": .expense,
        "Utilities": .expense,
        "Transport": .expense,
        "Healthcare": .expense,
        "Education": .expense,
        "Entertainment": .expense,
        "Shopping": .expense,
        "Food & Dining": .expense,
        "Insurance": .expense,
        "EMI": .expense,
        "Taxes": .expense,
        "Gift Given": .expense,
        "Personal Care": .expense,
        "Other Expenses": .expense,
        
        // Savings/Investment (7 categories)
        "Mutual Funds": .investment,
        "Stocks": .investment,
        "Fixed Deposit": .investment,
        "Recurring Deposit": .investment,
        "Gold": .investment,
        "PPF": .investment,
        "Other Investment": .investment
    ]
    
    public enum CategoryType: String {
        case income
        case expense
        case investment
    }
}

// MARK: - Sample Data

#if DEBUG
extension WebAppTransaction {
    static var sampleExpense: WebAppTransaction {
        WebAppTransaction(
            userId: "sample_user",
            accountId: UUID(),
            date: Date(),
            amount: 1200,
            type: .debit,
            category: "Groceries",
            description: "Weekly groceries at supermarket"
        )
    }
    
    static var sampleIncome: WebAppTransaction {
        WebAppTransaction(
            userId: "sample_user",
            accountId: UUID(),
            date: Date(),
            amount: 50000,
            type: .credit,
            category: "Salary",
            description: "Monthly salary"
        )
    }
    
    static var samples: [WebAppTransaction] {
        [sampleExpense, sampleIncome]
    }
}
#endif
