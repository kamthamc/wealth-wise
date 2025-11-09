//
//  TransactionDTO.swift
//  WealthWise
//
//  Data Transfer Object for Transaction data from Cloud Functions
//

import Foundation
import SwiftData

/// Data Transfer Object matching Cloud Function transaction response
@available(iOS 18.0, macOS 15.0, *)
struct TransactionDTO: Codable {
    let id: String
    let userId: String
    let accountId: String
    let date: String
    let amount: Double
    let type: String
    let category: String
    let description: String
    let notes: String?
    let createdAt: String
    let updatedAt: String
    let lastSyncedAt: String?
    
    // TODO: Re-enable when Firebase is configured
    // /// Convert DTO to SwiftData WebAppTransaction model
    // func toTransaction() -> WebAppTransaction {
    //     let dateFormatter = ISO8601DateFormatter()
    //     let transactionDate = dateFormatter.date(from: date) ?? Date()
    //     
    //     let transaction = WebAppTransaction(
    //         userId: userId,
    //         accountId: UUID(uuidString: accountId) ?? UUID(),
    //         date: transactionDate,
    //         amount: Decimal(amount),
    //         type: WebAppTransaction.TransactionType(rawValue: type) ?? .debit,
    //         category: category,
    //         description: description,
    //         notes: notes
    //     )
    //     
    //     // Set server-generated properties
    //     if let uuid = UUID(uuidString: id) {
    //         transaction.id = uuid
    //     }
    //     
    //     if let created = dateFormatter.date(from: createdAt) {
    //         transaction.createdAt = created
    //     }
    //     if let updated = dateFormatter.date(from: updatedAt) {
    //         transaction.updatedAt = updated
    //     }
    //     if let synced = lastSyncedAt, let syncedDate = dateFormatter.date(from: synced) {
    //         transaction.lastSyncedAt = syncedDate
    //     }
    //     
    //     return transaction
    // }
}

/// Request object for creating/updating transactions
@available(iOS 18.0, macOS 15.0, *)
struct TransactionRequestDTO: Codable {
    let accountId: String
    let date: String
    let amount: Double
    let type: String
    let category: String
    let description: String
    let notes: String?
    
    // TODO: Re-enable when Firebase is configured
    // /// Create request from SwiftData WebAppTransaction model
    // init(from transaction: WebAppTransaction) {
    //     self.accountId = transaction.accountId.uuidString
    //     
    //     let dateFormatter = ISO8601DateFormatter()
    //     self.date = dateFormatter.string(from: transaction.date)
    //     
    //     self.amount = NSDecimalNumber(decimal: transaction.amount).doubleValue
    //     self.type = transaction.type.rawValue
    //     self.category = transaction.category
    //     self.description = transaction.transactionDescription
    //     self.notes = transaction.notes
    // }
}
