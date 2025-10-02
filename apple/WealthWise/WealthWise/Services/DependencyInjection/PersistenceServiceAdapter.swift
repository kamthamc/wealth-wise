//
//  PersistenceServiceAdapter.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Dependency Injection System - Persistence Service Adapter
//

import Foundation
import CoreData

/// Adapter that bridges PersistentContainer to PersistenceServiceProtocol
/// Provides clean interface for dependency injection
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class PersistenceServiceAdapter: PersistenceServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let persistentContainer: PersistentContainer
    
    // MARK: - Initialization
    
    public init(persistentContainer: PersistentContainer = .shared) {
        self.persistentContainer = persistentContainer
    }
    
    // MARK: - PersistenceServiceProtocol Implementation
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    public var isLoaded: Bool {
        return persistentContainer.isLoaded
    }
    
    nonisolated public func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    public func save() throws {
        try persistentContainer.save()
    }
    
    nonisolated public func saveBackground(context: NSManagedObjectContext) throws {
        try persistentContainer.saveBackground(context: context)
    }
    
    nonisolated public func performBackgroundTask<T>(
        _ operation: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        return try await persistentContainer.performBackgroundTask(operation)
    }
    
    nonisolated public func getDatabaseStatistics() async -> DatabaseStatistics {
        return await persistentContainer.getDatabaseStatistics()
    }
    
    public func clearMemoryCaches() {
        persistentContainer.clearMemoryCaches()
    }
    
    public func resetContexts() {
        persistentContainer.resetContexts()
    }
}

// MARK: - Factory Extension

@available(iOS 18.6, macOS 15.6, *)
extension PersistenceServiceAdapter {
    /// Create default persistence service
    public static func createDefault() -> PersistenceServiceProtocol {
        return PersistenceServiceAdapter(persistentContainer: .shared)
    }
}
