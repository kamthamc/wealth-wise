//
//  Budget.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-08.
//  Budget management matching Firebase webapp schema
//

import Foundation
import SwiftData

/// Budget model matching the Firebase webapp implementation
/// Tracks spending limits across categories with different time periods
@available(iOS 18, macOS 16, *)
@Model
public final class Budget {
    
    // MARK: - Primary Properties
    
    /// Unique identifier matching Firestore document ID
    @Attribute(.unique) public var id: UUID
    
    /// User ID from Firebase Authentication
    public var userId: String
    
    /// Budget name
    public var name: String
    
    /// Budget amount limit
    public var amount: Decimal
    
    /// Budget period (monthly, quarterly, yearly)
    public var period: BudgetPeriod
    
    /// Categories included in this budget
    public var categories: [String]
    
    /// Budget start date
    public var startDate: Date
    
    /// Budget end date (calculated from start date + period)
    public var endDate: Date
    
    /// Creation timestamp
    public var createdAt: Date
    
    /// Last update timestamp
    public var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Current spending (calculated from transactions)
    public var currentSpent: Decimal = 0
    
    /// Remaining amount
    public var remaining: Decimal {
        amount - currentSpent
    }
    
    /// Progress percentage (0-100)
    public var progressPercentage: Double {
        guard amount > 0 else { return 0 }
        let progress = Double(truncating: currentSpent as NSNumber) / Double(truncating: amount as NSNumber)
        return min(progress * 100, 100)
    }
    
    /// Whether budget is over limit
    public var isOverBudget: Bool {
        currentSpent > amount
    }
    
    /// Budget status color
    public var statusColor: String {
        if isOverBudget {
            return "red"
        } else if progressPercentage > 80 {
            return "orange"
        } else {
            return "green"
        }
    }
    
    /// Period display name
    public var periodDisplayName: String {
        switch period {
        case .monthly:
            return NSLocalizedString("budget_period_monthly", comment: "Monthly")
        case .quarterly:
            return NSLocalizedString("budget_period_quarterly", comment: "Quarterly")
        case .yearly:
            return NSLocalizedString("budget_period_yearly", comment: "Yearly")
        }
    }
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        amount: Decimal,
        period: BudgetPeriod,
        categories: [String],
        startDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.period = period
        self.categories = categories
        self.startDate = startDate
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Calculate end date based on period
        let calendar = Calendar.current
        switch period {
        case .monthly:
            self.endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!
        case .quarterly:
            self.endDate = calendar.date(byAdding: .month, value: 3, to: startDate)!
        case .yearly:
            self.endDate = calendar.date(byAdding: .year, value: 1, to: startDate)!
        }
    }
    
    // MARK: - Methods
    
    /// Calculate spent amount from transactions
    public func calculateSpent(from transactions: [WebAppTransaction]) {
        let spent = transactions
            .filter { transaction in
                transaction.type == .debit &&
                categories.contains(transaction.category) &&
                transaction.date >= startDate &&
                transaction.date <= endDate
            }
            .reduce(Decimal(0)) { $0 + $1.amount }
        
        currentSpent = spent
        updatedAt = Date()
    }
    
    /// Convert to Firestore dictionary
    public func toFirestore() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "amount": NSDecimalNumber(decimal: amount).doubleValue,
            "period": period.rawValue,
            "categories": categories,
            "startDate": startDate,
            "endDate": endDate,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

// MARK: - Budget Period

extension Budget {
    /// Budget period matching webapp BudgetPeriod
    public enum BudgetPeriod: String, Codable, CaseIterable {
        case monthly = "monthly"
        case quarterly = "quarterly"
        case yearly = "yearly"
    }
}

// MARK: - Sample Data

#if DEBUG
extension Budget {
    static var sampleMonthly: Budget {
        Budget(
            userId: "sample_user",
            name: "Monthly Expenses",
            amount: 50000,
            period: .monthly,
            categories: ["Groceries", "Transport", "Food & Dining"]
        )
    }
    
    static var sampleYearly: Budget {
        Budget(
            userId: "sample_user",
            name: "Annual Savings Goal",
            amount: 500000,
            period: .yearly,
            categories: ["Mutual Funds", "Fixed Deposit", "Stocks"]
        )
    }
    
    static var samples: [Budget] {
        [sampleMonthly, sampleYearly]
    }
}
#endif
