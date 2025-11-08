//
//  AccountRepository.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-08.
//  Repository pattern for Account data access and sync
//

import Foundation
import SwiftData

/// Repository for Account management with Firebase sync
/// Provides offline-first access with background synchronization
@MainActor
final class AccountRepository: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let modelContext: ModelContext
    private let firebaseService: FirebaseService
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, firebaseService: FirebaseService = .shared) {
        self.modelContext = modelContext
        self.firebaseService = firebaseService
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all accounts from local storage
    func fetchLocal() throws {
        let descriptor = FetchDescriptor<Account>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        accounts = try modelContext.fetch(descriptor)
    }
    
    /// Sync with Firebase and update local storage
    func sync() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch from Firebase
            let remoteAccounts = try await firebaseService.fetchAccounts()
            
            // Clear local storage
            try modelContext.delete(model: Account.self)
            
            // Insert remote accounts
            for account in remoteAccounts {
                modelContext.insert(account)
            }
            
            try modelContext.save()
            
            // Update published property
            try fetchLocal()
            
            error = nil
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Fetch account by ID
    func fetchById(_ id: UUID) -> Account? {
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    // MARK: - Create/Update Operations
    
    /// Create new account
    func create(_ account: Account) async throws {
        // Save locally
        modelContext.insert(account)
        try modelContext.save()
        
        // Sync to Firebase
        try await firebaseService.saveAccount(account)
        
        // Refresh local list
        try fetchLocal()
    }
    
    /// Update existing account
    func update(_ account: Account) async throws {
        account.updatedAt = Date()
        try modelContext.save()
        
        // Sync to Firebase
        try await firebaseService.saveAccount(account)
        
        // Refresh local list
        try fetchLocal()
    }
    
    // MARK: - Delete Operations
    
    /// Delete account
    func delete(_ account: Account) async throws {
        // Delete from Firebase
        try await firebaseService.deleteAccount(account.id)
        
        // Delete locally
        modelContext.delete(account)
        try modelContext.save()
        
        // Refresh local list
        try fetchLocal()
    }
    
    /// Archive account (soft delete)
    func archive(_ account: Account) async throws {
        account.isArchived = true
        try await update(account)
    }
    
    /// Unarchive account
    func unarchive(_ account: Account) async throws {
        account.isArchived = false
        try await update(account)
    }
    
    // MARK: - Helper Methods
    
    /// Get active (non-archived) accounts
    func activeAccounts() -> [Account] {
        accounts.filter { !$0.isArchived }
    }
    
    /// Get accounts by type
    func accounts(ofType type: Account.AccountType) -> [Account] {
        accounts.filter { $0.type == type }
    }
    
    /// Calculate total balance across all accounts
    func totalBalance() -> Decimal {
        activeAccounts().reduce(Decimal(0)) { $0 + $1.currentBalance }
    }
    
    /// Recalculate balances for all accounts
    func recalculateAllBalances() async throws {
        for account in accounts {
            account.recalculateBalance()
        }
        try modelContext.save()
        
        // Sync updated balances to Firebase
        for account in accounts {
            try await firebaseService.saveAccount(account)
        }
    }
}

// MARK: - Static Accessor

extension AccountRepository {
    static func create(with modelContext: ModelContext) -> AccountRepository {
        AccountRepository(modelContext: modelContext)
    }
}
