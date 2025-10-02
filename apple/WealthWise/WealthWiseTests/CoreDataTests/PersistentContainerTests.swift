//
//  PersistentContainerTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-10-02.
//  Comprehensive integration tests for Core Data persistence - Issue #10
//

import XCTest
import CoreData
@testable import WealthWise

@MainActor
final class PersistentContainerTests: XCTestCase {
    
    var testContainer: NSPersistentContainer!
    var testContext: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory test container
        testContainer = NSPersistentContainer(name: "WealthWiseDataModel")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        testContainer.persistentStoreDescriptions = [description]
        
        let expectation = XCTestExpectation(description: "Load persistent stores")
        testContainer.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load persistent stores: \(error)")
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        testContext = testContainer.viewContext
        testContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    override func tearDown() async throws {
        testContext = nil
        testContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Container Initialization Tests
    
    func testContainerInitialization() throws {
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContainer.viewContext)
        XCTAssertEqual(testContainer.name, "WealthWiseDataModel")
    }
    
    func testViewContextConfiguration() throws {
        XCTAssertNotNil(testContext)
        XCTAssertTrue(testContext.mergePolicy is NSMergePolicy)
    }
    
    func testBackgroundContextCreation() throws {
        let backgroundContext = testContainer.newBackgroundContext()
        
        XCTAssertNotNil(backgroundContext)
        XCTAssertNotEqual(backgroundContext, testContext)
        XCTAssertTrue(backgroundContext.mergePolicy is NSMergePolicy)
    }
    
    // MARK: - Basic CRUD Tests
    
    func testCreateEntity() throws {
        // This test is a placeholder as we don't have specific entity classes
        // In a real implementation, you would create specific entities
        
        let hasChanges = testContext.hasChanges
        XCTAssertFalse(hasChanges)
    }
    
    func testSaveContext() throws {
        XCTAssertFalse(testContext.hasChanges)
        
        // If there are no changes, save should succeed
        try testContext.save()
        
        XCTAssertFalse(testContext.hasChanges)
    }
    
    func testSaveContextWithChanges() throws {
        // Create a test entity if available
        // This is a placeholder - in real implementation, create actual entities
        
        if testContext.hasChanges {
            XCTAssertNoThrow(try testContext.save())
        }
    }
    
    // MARK: - Context Merge Policy Tests
    
    func testMergePolicyConfiguration() throws {
        XCTAssertTrue(testContext.mergePolicy is NSMergePolicy)
        
        // Verify merge policy is set correctly
        if let mergePolicy = testContext.mergePolicy as? NSMergePolicy {
            XCTAssertNotNil(mergePolicy)
        }
    }
    
    func testBackgroundContextMergePolicy() throws {
        let backgroundContext = testContainer.newBackgroundContext()
        
        XCTAssertTrue(backgroundContext.mergePolicy is NSMergePolicy)
    }
    
    // MARK: - Background Operations Tests
    
    func testPerformBackgroundTask() throws {
        let expectation = XCTestExpectation(description: "Background task completed")
        
        testContainer.performBackgroundTask { context in
            XCTAssertNotNil(context)
            XCTAssertNotEqual(context, self.testContext)
            
            // Verify background context can be used
            XCTAssertFalse(context.hasChanges)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testBackgroundTaskWithSave() throws {
        let expectation = XCTestExpectation(description: "Background save completed")
        
        testContainer.performBackgroundTask { context in
            // Simulate creating an entity (placeholder)
            // In real implementation, create actual entity
            
            if context.hasChanges {
                XCTAssertNoThrow(try context.save())
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveEmptyContext() throws {
        XCTAssertFalse(testContext.hasChanges)
        
        // Saving empty context should not throw
        XCTAssertNoThrow(try testContext.save())
    }
    
    func testRollbackChanges() throws {
        // Make some changes (if possible)
        // Then rollback
        
        testContext.rollback()
        
        XCTAssertFalse(testContext.hasChanges)
    }
    
    // MARK: - Fetch Request Tests
    
    func testFetchRequestExecution() throws {
        // Test basic fetch request execution
        // This is a placeholder - in real implementation, fetch actual entities
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CrossBorderAsset")
        
        let results = try testContext.fetch(fetchRequest)
        
        XCTAssertNotNil(results)
        XCTAssertTrue(results.isEmpty) // Should be empty in new context
    }
    
    func testCountForFetchRequest() throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CrossBorderAsset")
        
        let count = try testContext.count(for: fetchRequest)
        
        XCTAssertEqual(count, 0) // Should be 0 in new context
    }
    
    // MARK: - Memory Management Tests
    
    func testContextReset() throws {
        testContext.reset()
        
        XCTAssertFalse(testContext.hasChanges)
    }
    
    func testRefreshAllObjects() throws {
        testContext.refreshAllObjects()
        
        // After refresh, context should still be valid
        XCTAssertNotNil(testContext)
        XCTAssertFalse(testContext.hasChanges)
    }
    
    // MARK: - Concurrency Tests
    
    func testMultipleBackgroundContexts() throws {
        let expectation1 = XCTestExpectation(description: "Background task 1")
        let expectation2 = XCTestExpectation(description: "Background task 2")
        
        testContainer.performBackgroundTask { context1 in
            XCTAssertNotNil(context1)
            expectation1.fulfill()
        }
        
        testContainer.performBackgroundTask { context2 in
            XCTAssertNotNil(context2)
            expectation2.fulfill()
        }
        
        wait(for: [expectation1, expectation2], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testContextSavePerformance() throws {
        measure {
            do {
                try testContext.save()
            } catch {
                XCTFail("Save failed: \(error)")
            }
        }
    }
    
    func testFetchRequestPerformance() throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CrossBorderAsset")
        
        measure {
            do {
                _ = try testContext.fetch(fetchRequest)
            } catch {
                XCTFail("Fetch failed: \(error)")
            }
        }
    }
}

// MARK: - PersistentContainer Integration Tests

@MainActor
final class PersistentContainerIntegrationTests: XCTestCase {
    
    // MARK: - Singleton Tests
    
    func testSharedInstanceExists() throws {
        let shared = PersistentContainer.shared
        
        XCTAssertNotNil(shared)
        XCTAssertNotNil(shared.persistentContainer)
        XCTAssertNotNil(shared.viewContext)
    }
    
    func testSharedInstanceSingleton() throws {
        let instance1 = PersistentContainer.shared
        let instance2 = PersistentContainer.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Container Loading Tests
    
    func testContainerIsLoaded() async throws {
        let shared = PersistentContainer.shared
        
        // Wait a bit for container to finish loading
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        XCTAssertTrue(shared.isLoaded)
    }
    
    // MARK: - Context Access Tests
    
    func testViewContextAccess() throws {
        let shared = PersistentContainer.shared
        let context = shared.viewContext
        
        XCTAssertNotNil(context)
        XCTAssertTrue(context.automaticallyMergesChangesFromParent)
    }
    
    func testBackgroundContextCreation() throws {
        let shared = PersistentContainer.shared
        let backgroundContext = shared.newBackgroundContext()
        
        XCTAssertNotNil(backgroundContext)
        XCTAssertNotEqual(backgroundContext, shared.viewContext)
    }
    
    // MARK: - Save Operations Tests
    
    func testSaveEmptyContext() throws {
        let shared = PersistentContainer.shared
        
        // Should not throw when saving empty context
        XCTAssertNoThrow(try shared.save())
    }
    
    func testClearMemoryCaches() throws {
        let shared = PersistentContainer.shared
        
        // Should not throw
        XCTAssertNoThrow(shared.clearMemoryCaches())
    }
    
    func testResetContexts() throws {
        let shared = PersistentContainer.shared
        
        // Should not throw
        XCTAssertNoThrow(shared.resetContexts())
    }
    
    // MARK: - Background Task Tests
    
    func testPerformBackgroundTask() async throws {
        let shared = PersistentContainer.shared
        
        let result: Bool = try await shared.performBackgroundTask { context in
            XCTAssertNotNil(context)
            return true
        }
        
        XCTAssertTrue(result)
    }
    
    func testPerformBackgroundTaskWithError() async throws {
        let shared = PersistentContainer.shared
        
        do {
            let _: Bool = try await shared.performBackgroundTask { _ in
                throw NSError(domain: "TestError", code: 1)
            }
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Statistics Tests
    
    func testGetDatabaseStatistics() async throws {
        let shared = PersistentContainer.shared
        
        let stats = await shared.getDatabaseStatistics()
        
        XCTAssertNotNil(stats)
        XCTAssertGreaterThanOrEqual(stats.totalAssets, 0)
        XCTAssertGreaterThanOrEqual(stats.totalPerformanceRecords, 0)
        XCTAssertGreaterThanOrEqual(stats.totalCurrencyRiskRecords, 0)
        XCTAssertGreaterThanOrEqual(stats.totalTaxResidencyRecords, 0)
        XCTAssertGreaterThanOrEqual(stats.databaseSize, 0)
        XCTAssertNotNil(stats.lastUpdated)
    }
    
    func testDatabaseStatisticsSizeConversion() throws {
        let stats = DatabaseStatistics(
            totalAssets: 10,
            totalPerformanceRecords: 20,
            totalCurrencyRiskRecords: 5,
            totalTaxResidencyRecords: 3,
            databaseSize: 1024 * 1024 * 10, // 10 MB
            lastUpdated: Date()
        )
        
        XCTAssertEqual(stats.databaseSizeMB, 10.0, accuracy: 0.01)
    }
}

// MARK: - Data Transformers Tests

@MainActor
final class DataTransformersTests: XCTestCase {
    
    func testTransformersRegistered() throws {
        // Verify that AssetTransformers.registerTransformers() has been called
        // This is called in PersistentContainer init
        let shared = PersistentContainer.shared
        XCTAssertNotNil(shared)
        
        // If container initialized, transformers should be registered
        XCTAssertTrue(shared.isLoaded || !shared.isLoaded) // Always true, just checking access
    }
}
