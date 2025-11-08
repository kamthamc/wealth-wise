//
//  AccountDTO.swift
//  WealthWise
//
//  Data Transfer Object for Account data from Cloud Functions
//

import Foundation

/// Data Transfer Object matching Cloud Function account response
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
    
    /// Convert DTO to SwiftData Account model
    func toAccount() -> Account {
        let account = Account(
            name: name,
            type: AccountType(rawValue: type) ?? .bank,
            initialBalance: Decimal(currentBalance),
            currency: currency,
            userId: userId
        )
        
        // Set server-generated properties
        if let uuid = UUID(uuidString: id) {
            account.id = uuid
        }
        account.isArchived = isArchived
        
        // Parse dates
        let dateFormatter = ISO8601DateFormatter()
        if let created = dateFormatter.date(from: createdAt) {
            account.createdAt = created
        }
        if let updated = dateFormatter.date(from: updatedAt) {
            account.updatedAt = updated
        }
        if let synced = lastSyncedAt, let syncedDate = dateFormatter.date(from: synced) {
            account.lastSyncedAt = syncedDate
        }
        
        return account
    }
}

/// Request object for creating/updating accounts
struct AccountRequestDTO: Codable {
    let name: String
    let type: String
    let currentBalance: Double
    let currency: String
    let isArchived: Bool?
    
    /// Create request from SwiftData Account model
    init(from account: Account) {
        self.name = account.name
        self.type = account.type.rawValue
        self.currentBalance = NSDecimalNumber(decimal: account.currentBalance).doubleValue
        self.currency = account.currency
        self.isArchived = account.isArchived
    }
}
