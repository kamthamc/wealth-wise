//
//  BudgetDTO.swift
//  WealthWise
//
//  Data Transfer Object for Budget data from Cloud Functions
//

import Foundation
import SwiftData

/// Data Transfer Object matching Cloud Function budget response
@available(iOS 18.0, macOS 15.0, *)
struct BudgetDTO: Codable {
    let id: String
    let userId: String
    let name: String
    let amount: Double
    let period: String
    let categories: [String]
    let startDate: String
    let endDate: String
    let currentSpent: Double
    let createdAt: String
    let updatedAt: String
    let lastSyncedAt: String?
    
    // TODO: Re-enable when Firebase is configured
    // /// Convert DTO to SwiftData Budget model
    // func toBudget() -> Budget {
    //     let dateFormatter = ISO8601DateFormatter()
    //     let start = dateFormatter.date(from: startDate) ?? Date()
    //     let end = dateFormatter.date(from: endDate) ?? Date()
    //     
    //     let budget = Budget(
    //       userId: userId, name: name,
    //       amount: Decimal(amount),
    //       period: Budget.BudgetPeriod(rawValue: period) ?? .monthly,
    //       categories: categories,
    //       startDate: start
    //     )
    //     
    //     // Set server-generated properties
    //     if let uuid = UUID(uuidString: id) {
    //         budget.id = uuid
    //     }
    //     budget.endDate = end
    //     budget.currentSpent = Decimal(currentSpent)
    //     
    //     if let created = dateFormatter.date(from: createdAt) {
    //         budget.createdAt = created
    //     }
    //     if let updated = dateFormatter.date(from: updatedAt) {
    //         budget.updatedAt = updated
    //     }
    //     // Note: Budget model doesn't have lastSyncedAt property
    //     
    //     return budget
    // }
}

/// Request object for creating/updating budgets
@available(iOS 18.0, macOS 15.0, *)
struct BudgetRequestDTO: Codable {
    let budgetId: String?
    let name: String
    let amount: Double
    let period: String
    let categories: [String]
    let startDate: String
    
    // TODO: Re-enable when Firebase is configured
    // /// Create request from SwiftData Budget model
    // init(from budget: Budget) {
    //     self.budgetId = budget.id.uuidString
    //     self.name = budget.name
    //     self.amount = NSDecimalNumber(decimal: budget.amount).doubleValue
    //     self.period = budget.period.rawValue
    //     self.categories = budget.categories
    //     
    //     let dateFormatter = ISO8601DateFormatter()
    //     self.startDate = dateFormatter.string(from: budget.startDate)
    // }
}

/// Budget report from Cloud Function
struct BudgetReportDTO: Codable {
    let budgetId: String
    let name: String
    let amount: Double
    let spent: Double
    let remaining: Double
    let percentageUsed: Double
    let period: String
    let startDate: String
    let endDate: String
    let categoryBreakdown: [CategorySpending]
    let isOverBudget: Bool
    let daysRemaining: Int
    
    struct CategorySpending: Codable {
        let category: String
        let spent: Double
        let percentage: Double
    }
}
