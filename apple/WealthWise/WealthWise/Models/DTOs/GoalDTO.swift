//
//  GoalDTO.swift
//  WealthWise
//
//  Data Transfer Object for Goal data from Cloud Functions
//

import Foundation
import SwiftData

/// Data Transfer Object matching Cloud Function goal response
@available(iOS 18.0, macOS 15.0, *)
struct GoalDTO: Codable {
    let id: String
    let userId: String
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let targetDate: String
    let type: String
    let priority: String
    let contributions: [ContributionDTO]
    let createdAt: String
    let updatedAt: String
    let lastSyncedAt: String?
    
    struct ContributionDTO: Codable {
        let amount: Double
        let date: String
        let note: String?
    }
    
    // TODO: Re-enable when Firebase is configured
    // /// Convert DTO to SwiftData WebAppGoal model
    // func toGoal() -> WebAppGoal {
    //     let dateFormatter = ISO8601DateFormatter()
    //     let target = dateFormatter.date(from: targetDate) ?? Date()
    //     
    //     let goal = WebAppGoal(
    //         userId: userId,
    //         name: name,
    //         targetAmount: Decimal(targetAmount),
    //         targetDate: target,
    //         type: GoalType(rawValue: type) ?? .savings,
    //         priority: GoalPriority(rawValue: priority) ?? .medium
    //     )
    //     
    //     // Set server-generated properties
    //     if let uuid = UUID(uuidString: id) {
    //         goal.id = uuid
    //     }
    //     goal.currentAmount = Decimal(currentAmount)
    //     
    //     // Convert contributions
    //     goal.contributions = contributions.map { dto in
    //         WebAppGoal.Contribution(
    //             amount: Decimal(dto.amount),
    //             date: dateFormatter.date(from: dto.date) ?? Date(),
    //             note: dto.note
    //         )
    //     }
    //     
    //     if let created = dateFormatter.date(from: createdAt) {
    //         goal.createdAt = created
    //     }
    //     if let updated = dateFormatter.date(from: updatedAt) {
    //         goal.updatedAt = updated
    //     }
    //     if let synced = lastSyncedAt, let syncedDate = dateFormatter.date(from: synced) {
    //         goal.lastSyncedAt = syncedDate
    //     }
    //     
    //     return goal
    // }
}

/// Request object for creating/updating goals
@available(iOS 18.0, macOS 15.0, *)
struct GoalRequestDTO: Codable {
    let goalId: String?
    let name: String
    let targetAmount: Double
    let targetDate: String
    let type: String
    let priority: String
    
    // TODO: Re-enable when Firebase is configured
    // /// Create request from SwiftData WebAppGoal model
    // init(from goal: WebAppGoal) {
    //     self.goalId = goal.id.uuidString
    //     self.name = goal.name
    //     self.targetAmount = NSDecimalNumber(decimal: goal.targetAmount).doubleValue
    //     
    //     let dateFormatter = ISO8601DateFormatter()
    //     self.targetDate = dateFormatter.string(from: goal.targetDate)
    //     
    //     self.type = goal.type.rawValue
    //     self.priority = goal.priority.rawValue
    // }
}
