import Foundation
import CoreData
import Combine

/// Simplified persistent storage manager for WealthWise
/// Handles Core Data integration with proper concurrency and localization
@MainActor
public final class PersistentContainer: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isLoaded = false
    
    // MARK: - Singleton
    
    public static let shared = PersistentContainer()
    
    // MARK: - Core Data
    
    /// Core Data persistent container
    public let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WealthWiseDataModel")
        
        // Configure persistent store description
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            
            // Enable tracking for change notifications
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Set up file protection (iOS only)
            #if os(iOS)
            if #available(iOS 4.0, *) {
                description.setOption(NSFileProtectionComplete, forKey: NSPersistentStoreFileProtectionKey)
            }
            #endif
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Handle the error appropriately in production
                let errorMessage = NSLocalizedString("Core Data error: \(error.localizedDescription)", comment: "Core Data loading error")
                fatalError(errorMessage)
            }
        }
        
        // Configure merge policy
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    // MARK: - Contexts
    
    /// Main view context for UI operations
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// Background context for heavy operations
    nonisolated public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }
    
    // MARK: - Initialization
    
    private init() {
        // Register custom transformers
        AssetTransformers.registerTransformers()
        
        // Setup notifications
        setupNotificationObservers()
        
        // Trigger container loading by accessing it
        _ = persistentContainer
        
        // Set as loaded after container is initialized
        Task { @MainActor in
            self.isLoaded = true
        }
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func managedObjectContextDidSave(notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }
        
        // Merge changes into view context if from background context
        if context !== viewContext {
            Task { @MainActor in
                self.viewContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
    
    // MARK: - Core Data Operations
    
    /// Save the main context
    public func save() throws {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            let errorMessage = NSLocalizedString("Failed to save context: \(error.localizedDescription)", comment: "Save context error")
            print(errorMessage)
            throw error
        }
    }
    
    /// Save a background context
    nonisolated public func saveBackground(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let errorMessage = NSLocalizedString("Failed to save background context: \(error.localizedDescription)", comment: "Save background context error")
            print(errorMessage)
            throw error
        }
    }
    
    /// Perform batch operation in background
    nonisolated public func performBackgroundTask<T>(
        _ operation: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                do {
                    let result = try operation(context)
                    try context.save()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Memory Management
    
    /// Clear memory caches
    public func clearMemoryCaches() {
        viewContext.refreshAllObjects()
        
        let message = NSLocalizedString("Memory caches cleared", comment: "Cache clearing confirmation")
        print(message)
    }
    
    /// Reset contexts (for testing or cleanup)
    public func resetContexts() {
        viewContext.reset()
        
        let message = NSLocalizedString("Contexts reset", comment: "Context reset confirmation")
        print(message)
    }
    
    // MARK: - Statistics
    
    /// Get basic database statistics
    nonisolated public func getDatabaseStatistics() async -> DatabaseStatistics {
        return await withCheckedContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                let stats = DatabaseStatistics(
                    totalAssets: self.getEntityCount("CrossBorderAsset", context: context),
                    totalPerformanceRecords: self.getEntityCount("PerformanceMetrics", context: context),
                    totalCurrencyRiskRecords: self.getEntityCount("CurrencyRisk", context: context),
                    totalTaxResidencyRecords: self.getEntityCount("TaxResidencyStatus", context: context),
                    databaseSize: self.getDatabaseSize(),
                    lastUpdated: Date()
                )
                continuation.resume(returning: stats)
            }
        }
    }
    
    nonisolated private func getEntityCount(_ entityName: String, context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    nonisolated private func getDatabaseSize() -> Int64 {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url else {
            return 0
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Supporting Types

/// Database statistics
public struct DatabaseStatistics: Sendable {
    public let totalAssets: Int
    public let totalPerformanceRecords: Int
    public let totalCurrencyRiskRecords: Int
    public let totalTaxResidencyRecords: Int
    public let databaseSize: Int64
    public let lastUpdated: Date
    
    public var databaseSizeMB: Double {
        return Double(databaseSize) / (1024 * 1024)
    }
}

/// Persistent container errors
public enum PersistentContainerError: Error, LocalizedError {
    case storeNotFound
    case migrationFailed
    case backupFailed
    case restoreFailed
    
    public var errorDescription: String? {
        switch self {
        case .storeNotFound:
            return NSLocalizedString("Persistent store not found", comment: "Store not found error")
        case .migrationFailed:
            return NSLocalizedString("Data migration failed", comment: "Migration failed error")
        case .backupFailed:
            return NSLocalizedString("Backup creation failed", comment: "Backup failed error")
        case .restoreFailed:
            return NSLocalizedString("Restore from backup failed", comment: "Restore failed error")
        }
    }
}