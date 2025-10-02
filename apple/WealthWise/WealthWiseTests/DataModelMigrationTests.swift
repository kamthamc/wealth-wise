import XCTest
import CoreData
@testable import WealthWise

/// Comprehensive tests for Core Data migration scenarios
/// Tests version management, migration execution, rollback, and validation
final class DataModelMigrationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset version to known state before each test
        UserDefaults.standard.removeObject(forKey: "WealthWise_DataVersion")
        UserDefaults.standard.removeObject(forKey: "WealthWise_LastMigrationDate")
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: "WealthWise_DataVersion")
        UserDefaults.standard.removeObject(forKey: "WealthWise_LastMigrationDate")
        super.tearDown()
    }
    
    // MARK: - Version Management Tests
    
    func testGetCurrentDataVersion_DefaultsToInitialVersion() {
        let version = DataModelMigrations.getCurrentDataVersion()
        XCTAssertEqual(version, "1.0.0", "Default version should be 1.0.0")
    }
    
    func testSetDataVersion_UpdatesVersionAndDate() {
        let testVersion = "1.2.0"
        DataModelMigrations.setDataVersion(testVersion)
        
        let storedVersion = DataModelMigrations.getCurrentDataVersion()
        XCTAssertEqual(storedVersion, testVersion)
        
        let migrationDate = UserDefaults.standard.object(forKey: "WealthWise_LastMigrationDate") as? Date
        XCTAssertNotNil(migrationDate)
        XCTAssertTrue(Date().timeIntervalSince(migrationDate!) < 1.0, "Migration date should be recent")
    }
    
    func testMigrationNeeded_ReturnsTrueWhenVersionsDiffer() {
        DataModelMigrations.setDataVersion("1.0.0")
        XCTAssertTrue(DataModelMigrations.migrationNeeded())
    }
    
    func testMigrationNeeded_ReturnsFalseWhenVersionsMatch() {
        DataModelMigrations.setDataVersion(DataModelMigrations.currentVersion)
        XCTAssertFalse(DataModelMigrations.migrationNeeded())
    }
    
    func testSupportedVersions_ContainsExpectedVersions() {
        let versions = DataModelMigrations.supportedVersions
        
        XCTAssertTrue(versions.contains("1.0.0"))
        XCTAssertTrue(versions.contains("1.1.0"))
        XCTAssertTrue(versions.contains("1.2.0"))
        XCTAssertTrue(versions.contains("1.3.0"))
        XCTAssertEqual(versions.count, 4)
    }
    
    func testCurrentVersion_MatchesLatestSupported() {
        let currentVersion = DataModelMigrations.currentVersion
        let lastSupported = DataModelMigrations.supportedVersions.last
        
        XCTAssertEqual(currentVersion, lastSupported)
    }
    
    // MARK: - Migration Plan Tests
    
    func testGetMigrationPlan_LightweightMigration_1_0_to_1_1() throws {
        let plan = try DataModelMigrations.getMigrationPlan(from: "1.0.0", to: "1.1.0")
        
        XCTAssertEqual(plan.fromVersion, "1.0.0")
        XCTAssertEqual(plan.toVersion, "1.1.0")
        XCTAssertEqual(plan.migrationType, .lightweight)
        XCTAssertTrue(plan.backupRequired)
        XCTAssertEqual(plan.estimatedTime, 30.0)
        XCTAssertTrue(plan.description.contains("performance metrics"))
        XCTAssertTrue(plan.customMigrationSteps.isEmpty)
    }
    
    func testGetMigrationPlan_HeavyweightMigration_1_1_to_1_2() throws {
        let plan = try DataModelMigrations.getMigrationPlan(from: "1.1.0", to: "1.2.0")
        
        XCTAssertEqual(plan.fromVersion, "1.1.0")
        XCTAssertEqual(plan.toVersion, "1.2.0")
        XCTAssertEqual(plan.migrationType, .heavyweight)
        XCTAssertTrue(plan.backupRequired)
        XCTAssertEqual(plan.estimatedTime, 60.0)
        XCTAssertTrue(plan.description.contains("currency risk"))
        XCTAssertFalse(plan.customMigrationSteps.isEmpty)
        XCTAssertEqual(plan.customMigrationSteps.count, 3)
    }
    
    func testGetMigrationPlan_DataTransformation_1_2_to_1_3() throws {
        let plan = try DataModelMigrations.getMigrationPlan(from: "1.2.0", to: "1.3.0")
        
        XCTAssertEqual(plan.fromVersion, "1.2.0")
        XCTAssertEqual(plan.toVersion, "1.3.0")
        XCTAssertEqual(plan.migrationType, .dataTransformation)
        XCTAssertTrue(plan.backupRequired)
        XCTAssertEqual(plan.estimatedTime, 45.0)
        XCTAssertTrue(plan.description.contains("compliance"))
        XCTAssertFalse(plan.customMigrationSteps.isEmpty)
        XCTAssertEqual(plan.customMigrationSteps.count, 3)
    }
    
    func testGetMigrationPlan_MultiStepMigration_1_0_to_1_3() throws {
        let plan = try DataModelMigrations.getMigrationPlan(from: "1.0.0", to: "1.3.0")
        
        XCTAssertEqual(plan.fromVersion, "1.0.0")
        XCTAssertEqual(plan.toVersion, "1.3.0")
        XCTAssertEqual(plan.migrationType, .heavyweight)
        XCTAssertTrue(plan.backupRequired)
        XCTAssertEqual(plan.estimatedTime, 180.0)
        XCTAssertTrue(plan.description.contains("Complete upgrade"))
        XCTAssertGreaterThan(plan.customMigrationSteps.count, 5)
    }
    
    func testGetMigrationPlan_IncompatibleVersions_ThrowsError() {
        XCTAssertThrowsError(
            try DataModelMigrations.getMigrationPlan(from: "2.0.0", to: "1.0.0")
        ) { error in
            guard case DataModelMigrations.MigrationError.incompatibleVersion(let message) = error else {
                XCTFail("Expected incompatibleVersion error")
                return
            }
            XCTAssertTrue(message.contains("No migration path"))
        }
    }
    
    func testGetMigrationPlan_UnsupportedVersion_ThrowsError() {
        XCTAssertThrowsError(
            try DataModelMigrations.getMigrationPlan(from: "0.9.0", to: "1.0.0")
        )
    }
    
    // MARK: - Migration Status Tests
    
    func testGetMigrationStatus_InitialState() {
        DataModelMigrations.setDataVersion("1.0.0")
        
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertEqual(status.currentVersion, "1.0.0")
        XCTAssertEqual(status.latestVersion, DataModelMigrations.currentVersion)
        XCTAssertTrue(status.migrationNeeded)
        XCTAssertGreaterThan(status.versionsBehind, 0)
        XCTAssertFalse(status.isUpToDate)
    }
    
    func testGetMigrationStatus_UpToDate() {
        DataModelMigrations.setDataVersion(DataModelMigrations.currentVersion)
        
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertEqual(status.currentVersion, DataModelMigrations.currentVersion)
        XCTAssertFalse(status.migrationNeeded)
        XCTAssertEqual(status.versionsBehind, 0)
        XCTAssertTrue(status.isUpToDate)
    }
    
    func testGetMigrationStatus_OneVersionBehind() {
        DataModelMigrations.setDataVersion("1.2.0")
        
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertEqual(status.versionsBehind, 1)
        XCTAssertTrue(status.migrationNeeded)
    }
    
    func testGetMigrationStatus_MultipleVersionsBehind() {
        DataModelMigrations.setDataVersion("1.0.0")
        
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertEqual(status.versionsBehind, 3)
    }
    
    func testGetMigrationStatus_IncludesMigrationDate() {
        let beforeDate = Date()
        DataModelMigrations.setDataVersion("1.1.0")
        let afterDate = Date()
        
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertNotNil(status.lastMigrationDate)
        if let migrationDate = status.lastMigrationDate {
            XCTAssertTrue(migrationDate >= beforeDate)
            XCTAssertTrue(migrationDate <= afterDate)
        }
    }
    
    // MARK: - Migration Step Tests
    
    func testMigrationStep_Initialization() {
        var executeCallCount = 0
        var rollbackCallCount = 0
        
        let step = DataModelMigrations.MigrationStep(
            name: "TestStep",
            description: "Test migration step"
        ) {
            executeCallCount += 1
        } rollback: {
            rollbackCallCount += 1
        }
        
        XCTAssertEqual(step.name, "TestStep")
        XCTAssertEqual(step.description, "Test migration step")
        XCTAssertNotNil(step.execute)
        XCTAssertNotNil(step.rollback)
    }
    
    func testMigrationStep_ExecuteCanBeCalled() async throws {
        var executed = false
        
        let step = DataModelMigrations.MigrationStep(
            name: "ExecuteTest",
            description: "Test execute"
        ) {
            executed = true
        }
        
        try await step.execute()
        XCTAssertTrue(executed)
    }
    
    func testMigrationStep_RollbackCanBeCalled() async throws {
        var rolledBack = false
        
        let step = DataModelMigrations.MigrationStep(
            name: "RollbackTest",
            description: "Test rollback"
        ) {
            // Execute
        } rollback: {
            rolledBack = true
        }
        
        if let rollback = step.rollback {
            try await rollback()
            XCTAssertTrue(rolledBack)
        } else {
            XCTFail("Rollback should be available")
        }
    }
    
    func testMigrationStep_OptionalRollback() {
        let step = DataModelMigrations.MigrationStep(
            name: "NoRollback",
            description: "Step without rollback"
        ) {
            // Execute only
        }
        
        XCTAssertNil(step.rollback)
    }
    
    // MARK: - Migration Error Tests
    
    func testMigrationError_MigrationFailed_ErrorDescription() {
        let error = DataModelMigrations.MigrationError.migrationFailed("Test failure")
        
        XCTAssertEqual(error.errorDescription, "Migration failed: Test failure")
    }
    
    func testMigrationError_IncompatibleVersion_ErrorDescription() {
        let error = DataModelMigrations.MigrationError.incompatibleVersion("2.0.0")
        
        XCTAssertEqual(error.errorDescription, "Incompatible data version: 2.0.0")
    }
    
    func testMigrationError_CorruptData_ErrorDescription() {
        let error = DataModelMigrations.MigrationError.corruptData("Invalid format")
        
        XCTAssertEqual(error.errorDescription, "Data corruption detected: Invalid format")
    }
    
    func testMigrationError_InsufficientStorage_ErrorDescription() {
        let error = DataModelMigrations.MigrationError.insufficientStorage
        
        XCTAssertEqual(error.errorDescription, "Insufficient storage space for migration")
    }
    
    func testMigrationError_MigrationCancelled_ErrorDescription() {
        let error = DataModelMigrations.MigrationError.migrationCancelled
        
        XCTAssertEqual(error.errorDescription, "Migration was cancelled by user")
    }
    
    // MARK: - Migration Plan Structure Tests
    
    func testMigrationPlan_Initialization() {
        let steps = [
            DataModelMigrations.MigrationStep(
                name: "Step1",
                description: "First step"
            ) { }
        ]
        
        let plan = DataModelMigrations.MigrationPlan(
            fromVersion: "1.0.0",
            toVersion: "1.1.0",
            migrationType: .lightweight,
            estimatedTime: 30.0,
            backupRequired: true,
            customMigrationSteps: steps,
            description: "Test plan"
        )
        
        XCTAssertEqual(plan.fromVersion, "1.0.0")
        XCTAssertEqual(plan.toVersion, "1.1.0")
        XCTAssertEqual(plan.migrationType, .lightweight)
        XCTAssertEqual(plan.estimatedTime, 30.0)
        XCTAssertTrue(plan.backupRequired)
        XCTAssertEqual(plan.customMigrationSteps.count, 1)
        XCTAssertEqual(plan.description, "Test plan")
    }
    
    func testMigrationPlan_DefaultBackupRequired() {
        let plan = DataModelMigrations.MigrationPlan(
            fromVersion: "1.0.0",
            toVersion: "1.1.0",
            migrationType: .lightweight,
            estimatedTime: 30.0,
            description: "Test plan"
        )
        
        XCTAssertTrue(plan.backupRequired, "Backup should be required by default")
    }
    
    func testMigrationPlan_EmptyStepsByDefault() {
        let plan = DataModelMigrations.MigrationPlan(
            fromVersion: "1.0.0",
            toVersion: "1.1.0",
            migrationType: .lightweight,
            estimatedTime: 30.0,
            description: "Test plan"
        )
        
        XCTAssertTrue(plan.customMigrationSteps.isEmpty)
    }
    
    // MARK: - Edge Case Tests
    
    func testMigrationNeeded_WithInvalidStoredVersion() {
        UserDefaults.standard.set("invalid.version", forKey: "WealthWise_DataVersion")
        
        // Should handle gracefully
        let currentVersion = DataModelMigrations.getCurrentDataVersion()
        XCTAssertEqual(currentVersion, "invalid.version")
    }
    
    func testGetMigrationStatus_WithNoMigrationDate() {
        DataModelMigrations.setDataVersion("1.0.0")
        UserDefaults.standard.removeObject(forKey: "WealthWise_LastMigrationDate")
        
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertNil(status.lastMigrationDate)
    }
    
    func testVersionsBehind_WithInvalidVersions() {
        // Set an unsupported version
        UserDefaults.standard.set("0.5.0", forKey: "WealthWise_DataVersion")
        
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertEqual(status.versionsBehind, 0, "Should handle invalid versions gracefully")
    }
    
    // MARK: - Migration Type Tests
    
    func testMigrationType_AllCasesAvailable() {
        let types: [DataModelMigrations.MigrationType] = [
            .lightweight,
            .heavyweight,
            .swiftDataMigration,
            .dataTransformation
        ]
        
        XCTAssertEqual(types.count, 4)
    }
    
    // MARK: - Integration Tests
    
    func testFullMigrationFlow_VersionProgression() {
        // Start at 1.0.0
        DataModelMigrations.setDataVersion("1.0.0")
        XCTAssertTrue(DataModelMigrations.migrationNeeded())
        
        // Simulate migration to 1.1.0
        DataModelMigrations.setDataVersion("1.1.0")
        XCTAssertTrue(DataModelMigrations.migrationNeeded())
        
        // Simulate migration to 1.2.0
        DataModelMigrations.setDataVersion("1.2.0")
        XCTAssertTrue(DataModelMigrations.migrationNeeded())
        
        // Simulate migration to 1.3.0 (current)
        DataModelMigrations.setDataVersion("1.3.0")
        XCTAssertFalse(DataModelMigrations.migrationNeeded())
    }
    
    func testAllMigrationPaths_AreValid() throws {
        let versions = DataModelMigrations.supportedVersions
        
        // Test direct migrations between consecutive versions
        for i in 0..<(versions.count - 1) {
            let fromVersion = versions[i]
            let toVersion = versions[i + 1]
            
            XCTAssertNoThrow(
                try DataModelMigrations.getMigrationPlan(from: fromVersion, to: toVersion),
                "Migration path from \(fromVersion) to \(toVersion) should be valid"
            )
        }
    }
    
    func testMultiStepMigrationPath_IsValid() throws {
        // Test 1.0.0 -> 1.3.0 (multi-step)
        let plan = try DataModelMigrations.getMigrationPlan(from: "1.0.0", to: "1.3.0")
        
        XCTAssertGreaterThan(plan.estimatedTime, 60.0, "Multi-step migration should take longer")
        XCTAssertGreaterThan(plan.customMigrationSteps.count, 0, "Should have custom steps")
    }
    
    // MARK: - Performance Tests
    
    func testVersionDetectionPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = DataModelMigrations.getCurrentDataVersion()
            }
        }
    }
    
    func testMigrationPlanCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = try? DataModelMigrations.getMigrationPlan(from: "1.0.0", to: "1.1.0")
            }
        }
    }
    
    func testMigrationStatusPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = DataModelMigrations.getMigrationStatus()
            }
        }
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentVersionReads() async {
        // Test thread-safety of version reading
        await withTaskGroup(of: String.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    return DataModelMigrations.getCurrentDataVersion()
                }
            }
            
            var versions: [String] = []
            for await version in group {
                versions.append(version)
            }
            
            // All reads should return the same version
            XCTAssertEqual(Set(versions).count, 1)
        }
    }
    
    func testConcurrentStatusChecks() async {
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    return DataModelMigrations.migrationNeeded()
                }
            }
            
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            
            // All checks should return the same result
            XCTAssertEqual(Set(results).count, 1)
        }
    }
}
