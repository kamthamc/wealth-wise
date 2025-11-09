//
//  AccountDTO.swift
//  WealthWise
//
//  Data Transfer Object for Account data from Cloud Functions
//

import Foundation
import SwiftData

/// Data Transfer Object matching Cloud Function account response
@available(iOS 18.0, macOS 15.0, *)
struct AccountDTO: Codable {
    let id: String
    let userId: String
    let name: String
    let type: String
    let currentBalance: Double
    let currency: String
    let isArchived: Bool
    let createdAt: String
    let updatedAt: String
    let lastSyncedAt: String?
    
    // TODO: Re-enable when Firebase is configured
    // /// Convert DTO to SwiftData Account model
    // func toAccount() -> Account {
    //     let account = Account(
    //       userId: userId, name: name,
    //       type: Account.AccountType(rawValue: type) ?? .bank,
    //       currency: currency
    //     )
    //     
    //     // Set server-generated properties
    //     if let uuid = UUID(uuidString: id) {
    //         account.id = uuid
    //     }
    //     account.isArchived = isArchived
    //     
    //     // Parse dates
    //     let dateFormatter = ISO8601DateFormatter()
    //     if let created = dateFormatter.date(from: createdAt) {
    //         account.createdAt = created
    //     }
    //     if let updated = dateFormatter.date(from: updatedAt) {
    //         account.updatedAt = updated
    //     }
    //     if let synced = lastSyncedAt, let syncedDate = dateFormatter.date(from: synced) {
    //         account.lastSyncedAt = syncedDate
    //     }
    //     
    //     return account
    // }
}

/// Request object for creating/updating accounts
@available(iOS 18.0, macOS 15.0, *)
struct AccountRequestDTO: Codable {
    let name: String
    let type: String
    let currentBalance: Double
    let currency: String
    let isArchived: Bool?
    
    // TODO: Re-enable when Firebase is configured
    // /// Create request from SwiftData Account model
    // init(from account: Account) {
    //     self.name = account.name
    //     self.type = account.type.rawValue
    //     self.currentBalance = NSDecimalNumber(decimal: account.currentBalance).doubleValue
    //     self.currency = account.currency
    //     self.isArchived = account.isArchived
    // }
}
