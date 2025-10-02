# Core Data Migration & Versioning Plan

## Overview

This document provides a comprehensive guide for managing Core Data schema migrations in WealthWise. The migration framework supports seamless version upgrades while ensuring data integrity, providing rollback capabilities, and maintaining backward compatibility.

## Table of Contents

1. [Migration Strategy](#migration-strategy)
2. [Version Management](#version-management)
3. [Migration Types](#migration-types)
4. [Migration Execution](#migration-execution)
5. [Testing Strategy](#testing-strategy)
6. [Rollback Procedures](#rollback-procedures)
7. [Backup Recommendations](#backup-recommendations)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

## Migration Strategy

### Core Principles

1. **Data Integrity First**: All migrations must preserve existing data without loss
2. **Backward Compatibility**: Support graceful degradation when possible
3. **Fail-Safe Design**: Automatic backup creation before migrations
4. **Progressive Enhancement**: Incremental migrations for complex schema changes
5. **Validation**: Post-migration data integrity checks

### Migration Philosophy

WealthWise uses a **version-based migration system** that:
- Tracks the current data model version
- Determines migration paths automatically
- Executes appropriate migration strategies based on schema changes
- Validates data integrity after each migration
- Provides rollback capabilities for failed migrations

## Version Management

### Version Numbering Scheme

WealthWise follows semantic versioning for data models:

```
Major.Minor.Patch
  │     │     │
  │     │     └─ Bug fixes, no schema changes
  │     └─────── New features, schema additions (backward compatible)
  └───────────── Breaking changes, major schema refactoring
```

### Supported Versions

| Version | Description | Release Date | Migration Type |
|---------|-------------|--------------|----------------|
| 1.0.0 | Initial release | - | N/A |
| 1.1.0 | Added performance metrics | - | Lightweight |
| 1.2.0 | Added currency risk models | - | Heavyweight |
| 1.3.0 | Enhanced compliance and tax residency | - | Data Transformation |

### Version Detection

The system automatically detects the current data version on application startup:

```swift
// Check if migration is needed
if DataModelMigrations.migrationNeeded() {
    let status = DataModelMigrations.getMigrationStatus()
    print("Current version: \(status.currentVersion)")
    print("Latest version: \(status.latestVersion)")
    print("Versions behind: \(status.versionsBehind)")
}
```

### Version Storage

Version information is stored in `UserDefaults`:
- **Key**: `WealthWise_DataVersion`
- **Default**: "1.0.0" (if not set)
- **Updated**: After successful migration completion
- **Migration Date**: Stored in `WealthWise_LastMigrationDate`

## Migration Types

### 1. Lightweight Migration

**When to Use:**
- Adding new optional attributes
- Adding new entities
- Renaming attributes/entities (with renaming identifiers)
- Changing attribute types (when compatible)

**Characteristics:**
- Automatic Core Data inference
- No custom mapping code required
- Fast execution (typically < 30 seconds)
- Minimal risk

**Example Scenario: 1.0.0 → 1.1.0**
```swift
// Adding performance metrics fields
// Core Data automatically infers the mapping
let plan = try DataModelMigrations.getMigrationPlan(
    from: "1.0.0",
    to: "1.1.0"
)
// Migration Type: .lightweight
// Estimated Time: 30 seconds
```

**Implementation:**
```swift
private static func executeLightweightMigration(
    plan: MigrationPlan,
    progressHandler: @escaping (Double, String) -> Void
) async throws {
    // Core Data handles the migration automatically
    let persistentContainer = NSPersistentContainer(name: "WealthWiseDataModel")
    let description = persistentContainer.persistentStoreDescriptions.first
    description?.shouldMigrateStoreAutomatically = true
    description?.shouldInferMappingModelAutomatically = true
    
    // Load stores triggers automatic migration
    try await withCheckedThrowingContinuation { continuation in
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
        }
    }
}
```

### 2. Heavyweight Migration

**When to Use:**
- Complex data transformations
- Structural schema changes
- Relationship modifications
- Data denormalization/normalization

**Characteristics:**
- Custom mapping models required
- Step-by-step data transformation
- Medium to long execution time (60-180 seconds)
- Moderate risk with rollback support

**Example Scenario: 1.1.0 → 1.2.0**
```swift
// Adding currency risk analysis with custom data population
let plan = try DataModelMigrations.getMigrationPlan(
    from: "1.1.0",
    to: "1.2.0"
)
// Migration Type: .heavyweight
// Estimated Time: 60 seconds
// Custom Steps: 3
```

**Migration Steps:**
```swift
private static func getCurrencyRiskMigrationSteps() -> [MigrationStep] {
    return [
        MigrationStep(
            name: "CreateCurrencyRiskEntities",
            description: "Creating currency risk tracking entities"
        ) {
            // 1. Create new entities
            // 2. Establish relationships with existing assets
        },
        
        MigrationStep(
            name: "PopulateCurrencyExposure",
            description: "Calculating currency exposure for existing assets"
        ) {
            // 1. Analyze existing asset currencies
            // 2. Calculate exposure percentages
            // 3. Store risk metrics
        },
        
        MigrationStep(
            name: "SetupDefaultHedgingStrategies",
            description: "Setting up default hedging strategies"
        ) {
            // 1. Determine asset types
            // 2. Apply appropriate hedging strategies
            // 3. Initialize tracking parameters
        }
    ]
}
```

### 3. SwiftData Migration

**When to Use:**
- Migrating from Core Data to SwiftData
- SwiftData schema evolution
- Modern persistence layer updates

**Characteristics:**
- Leverages SwiftData migration capabilities
- Gradual adoption possible
- Future-proof architecture
- iOS 17+/macOS 14+ requirement

**Implementation Approach:**
```swift
private static func executeSwiftDataMigration(
    plan: MigrationPlan,
    progressHandler: @escaping (Double, String) -> Void
) async throws {
    // Create new ModelContainer with migration plan
    // SwiftData handles schema evolution automatically
    
    progressHandler(0.5, "Executing SwiftData schema evolution...")
    
    // Implementation depends on SwiftData migration capabilities
    // This is prepared for future SwiftData adoption
}
```

### 4. Data Transformation

**When to Use:**
- Complex business logic changes
- Data format conversions
- Multi-entity coordination
- Compliance requirement updates

**Characteristics:**
- Custom transformation logic
- Flexible execution order
- Comprehensive validation
- Rollback support per step

**Example Scenario: 1.2.0 → 1.3.0**
```swift
// Enhanced compliance and tax residency tracking
let plan = try DataModelMigrations.getMigrationPlan(
    from: "1.2.0",
    to: "1.3.0"
)
// Migration Type: .dataTransformation
// Estimated Time: 45 seconds
// Custom Steps: 3
```

**Tax Residency Migration:**
```swift
private static func getTaxResidencyMigrationSteps() -> [MigrationStep] {
    return [
        MigrationStep(
            name: "CreateTaxResidencyEntities",
            description: "Creating tax residency status entities"
        ) {
            // Create TaxResidencyStatus based on user's country
        },
        
        MigrationStep(
            name: "UpdateComplianceRequirements",
            description: "Updating compliance requirements for existing assets"
        ) {
            // Update assets with new compliance data
        },
        
        MigrationStep(
            name: "MigrateDocumentReferences",
            description: "Migrating existing document references"
        ) {
            // Convert document storage format
        }
    ]
}
```

## Migration Execution

### Standard Migration Flow

```swift
// 1. Check if migration is needed
guard DataModelMigrations.migrationNeeded() else {
    print("Database is up to date")
    return
}

// 2. Get migration plan
let currentVersion = DataModelMigrations.getCurrentDataVersion()
let targetVersion = DataModelMigrations.currentVersion

do {
    let plan = try DataModelMigrations.getMigrationPlan(
        from: currentVersion,
        to: targetVersion
    )
    
    // 3. Execute migration with progress tracking
    try await DataModelMigrations.executeMigration(plan: plan) { progress, message in
        print("[\(Int(progress * 100))%] \(message)")
        // Update UI progress indicator
    }
    
    print("Migration completed successfully")
    
} catch DataModelMigrations.MigrationError.migrationFailed(let message) {
    print("Migration failed: \(message)")
    // Attempt rollback
    
} catch {
    print("Unexpected error: \(error)")
}
```

### Migration Phases

1. **Pre-Migration**
   - Version detection
   - Compatibility check
   - Storage space verification
   - Backup creation

2. **Migration Execution**
   - Progress tracking
   - Step-by-step execution
   - Error handling
   - Partial rollback support

3. **Post-Migration**
   - Data validation
   - Integrity checks
   - Version update
   - Backup cleanup (optional)

### Progress Tracking

The migration system provides detailed progress updates:

```swift
try await DataModelMigrations.executeMigration(plan: plan) { progress, message in
    // progress: 0.0 to 1.0
    // message: Human-readable description
    
    DispatchQueue.main.async {
        self.progressBar.progress = Float(progress)
        self.statusLabel.text = message
    }
}
```

**Progress Milestones:**
- 0.0: Starting migration
- 0.1: Backup created
- 0.2-0.9: Migration execution (varies by type)
- 0.9: Data validation
- 1.0: Migration completed

## Testing Strategy

### Unit Tests

Test individual migration components in isolation:

```swift
final class DataModelMigrationsTests: XCTestCase {
    
    // MARK: - Version Management Tests
    
    func testVersionDetection() {
        let currentVersion = DataModelMigrations.getCurrentDataVersion()
        XCTAssertFalse(currentVersion.isEmpty)
        XCTAssertTrue(DataModelMigrations.supportedVersions.contains(currentVersion))
    }
    
    func testMigrationNeeded() {
        // Test when versions match
        DataModelMigrations.setDataVersion(DataModelMigrations.currentVersion)
        XCTAssertFalse(DataModelMigrations.migrationNeeded())
        
        // Test when versions differ
        DataModelMigrations.setDataVersion("1.0.0")
        XCTAssertTrue(DataModelMigrations.migrationNeeded())
    }
    
    // MARK: - Migration Plan Tests
    
    func testLightweightMigrationPlan() throws {
        let plan = try DataModelMigrations.getMigrationPlan(
            from: "1.0.0",
            to: "1.1.0"
        )
        
        XCTAssertEqual(plan.fromVersion, "1.0.0")
        XCTAssertEqual(plan.toVersion, "1.1.0")
        XCTAssertEqual(plan.migrationType, .lightweight)
        XCTAssertTrue(plan.backupRequired)
        XCTAssertEqual(plan.estimatedTime, 30.0)
    }
    
    func testHeavyweightMigrationPlan() throws {
        let plan = try DataModelMigrations.getMigrationPlan(
            from: "1.1.0",
            to: "1.2.0"
        )
        
        XCTAssertEqual(plan.migrationType, .heavyweight)
        XCTAssertGreaterThan(plan.customMigrationSteps.count, 0)
    }
    
    func testIncompatibleVersionError() {
        XCTAssertThrowsError(
            try DataModelMigrations.getMigrationPlan(from: "2.0.0", to: "1.0.0")
        ) { error in
            guard case DataModelMigrations.MigrationError.incompatibleVersion = error else {
                XCTFail("Expected incompatibleVersion error")
                return
            }
        }
    }
    
    // MARK: - Migration Status Tests
    
    func testMigrationStatus() {
        let status = DataModelMigrations.getMigrationStatus()
        
        XCTAssertNotNil(status.currentVersion)
        XCTAssertEqual(status.latestVersion, DataModelMigrations.currentVersion)
        XCTAssertGreaterThanOrEqual(status.versionsBehind, 0)
    }
}
```

### Integration Tests

Test complete migration scenarios with actual Core Data:

```swift
final class MigrationIntegrationTests: XCTestCase {
    
    var testContainer: NSPersistentContainer!
    var tempStoreURL: URL!
    
    override func setUp() async throws {
        // Create temporary Core Data store
        tempStoreURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        
        // Initialize with older version
        createTestDataStore(version: "1.0.0")
    }
    
    override func tearDown() async throws {
        // Clean up temporary store
        try? FileManager.default.removeItem(at: tempStoreURL)
    }
    
    func testLightweightMigration() async throws {
        // Arrange: Set up v1.0.0 data
        DataModelMigrations.setDataVersion("1.0.0")
        
        // Act: Execute migration
        let plan = try DataModelMigrations.getMigrationPlan(
            from: "1.0.0",
            to: "1.1.0"
        )
        
        var progressUpdates: [(Double, String)] = []
        try await DataModelMigrations.executeMigration(plan: plan) { progress, message in
            progressUpdates.append((progress, message))
        }
        
        // Assert: Verify migration success
        XCTAssertEqual(DataModelMigrations.getCurrentDataVersion(), "1.1.0")
        XCTAssertGreaterThan(progressUpdates.count, 0)
        XCTAssertEqual(progressUpdates.last?.0, 1.0)
        
        // Verify data integrity
        try await verifyDataIntegrity()
    }
    
    func testHeavyweightMigration() async throws {
        // Arrange
        DataModelMigrations.setDataVersion("1.1.0")
        populateTestData()
        
        // Act
        let plan = try DataModelMigrations.getMigrationPlan(
            from: "1.1.0",
            to: "1.2.0"
        )
        
        try await DataModelMigrations.executeMigration(plan: plan) { _, _ in }
        
        // Assert
        XCTAssertEqual(DataModelMigrations.getCurrentDataVersion(), "1.2.0")
        try await verifyCustomMigrationSteps()
    }
    
    func testMultiVersionMigration() async throws {
        // Test migration from 1.0.0 to 1.3.0 (multi-step)
        DataModelMigrations.setDataVersion("1.0.0")
        
        let plan = try DataModelMigrations.getMigrationPlan(
            from: "1.0.0",
            to: "1.3.0"
        )
        
        XCTAssertEqual(plan.migrationType, .heavyweight)
        XCTAssertGreaterThan(plan.estimatedTime, 100.0)
        
        try await DataModelMigrations.executeMigration(plan: plan) { _, _ in }
        
        XCTAssertEqual(DataModelMigrations.getCurrentDataVersion(), "1.3.0")
    }
    
    // Helper methods
    private func createTestDataStore(version: String) {
        // Create Core Data store with specific version
    }
    
    private func populateTestData() {
        // Add test entities
    }
    
    private func verifyDataIntegrity() async throws {
        // Verify data after migration
    }
    
    private func verifyCustomMigrationSteps() async throws {
        // Verify custom migration logic executed correctly
    }
}
```

### Edge Case Tests

```swift
final class MigrationEdgeCaseTests: XCTestCase {
    
    func testMigrationWithEmptyDatabase() async throws {
        // Test migration when no data exists
        let plan = try DataModelMigrations.getMigrationPlan(
            from: "1.0.0",
            to: "1.1.0"
        )
        
        try await DataModelMigrations.executeMigration(plan: plan) { _, _ in }
        
        XCTAssertEqual(DataModelMigrations.getCurrentDataVersion(), "1.1.0")
    }
    
    func testMigrationWithCorruptData() async throws {
        // Test migration failure handling
        // Simulate corrupt data scenario
        
        let plan = try DataModelMigrations.getMigrationPlan(
            from: "1.0.0",
            to: "1.1.0"
        )
        
        do {
            try await DataModelMigrations.executeMigration(plan: plan) { _, _ in }
            XCTFail("Expected migration to fail with corrupt data")
        } catch DataModelMigrations.MigrationError.corruptData {
            // Expected error
        }
    }
    
    func testMigrationWithInsufficientStorage() async throws {
        // Test insufficient storage handling
        // This would require mocking FileManager
    }
    
    func testConcurrentMigrationAttempts() async throws {
        // Ensure only one migration runs at a time
    }
}
```

### Performance Tests

```swift
final class MigrationPerformanceTests: XCTestCase {
    
    func testLightweightMigrationPerformance() {
        measure {
            // Create large dataset
            createLargeTestDataset(entityCount: 10000)
            
            // Measure migration time
            let plan = try! DataModelMigrations.getMigrationPlan(
                from: "1.0.0",
                to: "1.1.0"
            )
            
            let expectation = XCTestExpectation(description: "Migration completes")
            Task {
                try await DataModelMigrations.executeMigration(plan: plan) { _, _ in }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 60.0)
        }
    }
    
    func testHeavyweightMigrationPerformance() {
        // Test performance with custom migration steps
    }
}
```

### Test Data Setup

```swift
extension XCTestCase {
    
    func createTestAsset(version: String) -> CrossBorderAsset {
        return CrossBorderAsset(
            name: "Test Asset",
            symbol: "TEST",
            assetType: .equity,
            primaryCountry: "US",
            primaryCurrency: "USD",
            currentValue: 1000.0
        )
    }
    
    func createTestDataset(count: Int, version: String) {
        for i in 0..<count {
            let asset = createTestAsset(version: version)
            asset.name = "Asset \(i)"
            // Save to context
        }
    }
}
```

## Rollback Procedures

### Automatic Rollback

The migration system supports automatic rollback on failure:

```swift
private static func executeHeavyweightMigration(
    plan: MigrationPlan,
    progressHandler: @escaping (Double, String) -> Void
) async throws {
    
    for (index, step) in plan.customMigrationSteps.enumerated() {
        do {
            try await step.execute()
        } catch {
            // Automatic rollback on failure
            if let rollback = step.rollback {
                try await rollback()
            }
            throw MigrationError.migrationFailed("Step '\(step.name)' failed")
        }
    }
}
```

### Manual Rollback

To manually rollback to a previous version:

```swift
do {
    // Rollback to specific version
    try await DataModelMigrations.rollbackMigration(to: "1.2.0")
    
    print("Successfully rolled back to version 1.2.0")
    
} catch {
    print("Rollback failed: \(error)")
    // Restore from backup manually
}
```

### Rollback Best Practices

1. **Always Create Backups**: Ensure backup exists before rollback
2. **Verify Target Version**: Confirm target version is valid and supported
3. **Test Rollback Path**: Test rollback procedures during development
4. **Document Rollback Steps**: Maintain clear rollback documentation
5. **Monitor Data Integrity**: Validate data after rollback

### Rollback Scenarios

#### Scenario 1: Failed Migration Step

```
1. Migration fails at step 2 of 3
2. System automatically executes rollback for step 2
3. Data returns to state before step 2
4. User can retry migration or stay on current version
```

#### Scenario 2: Data Corruption Detected

```
1. Post-migration validation detects corruption
2. System triggers automatic rollback
3. Database restored from pre-migration backup
4. User notified of rollback completion
5. Original data version restored
```

#### Scenario 3: User-Initiated Rollback

```
1. User experiences issues after migration
2. User triggers manual rollback
3. System restores from most recent backup
4. Version number reverted
5. User data validated for consistency
```

## Backup Recommendations

### Automatic Backup Strategy

The migration system automatically creates backups before migrations:

```swift
private static func createDataBackup() async throws {
    let backupURL = getBackupURL()
    
    // 1. Create backup directory if needed
    let backupDir = backupURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(
        at: backupDir,
        withIntermediateDirectories: true
    )
    
    // 2. Copy database file
    let sourceURL = getDatabaseURL()
    try FileManager.default.copyItem(at: sourceURL, to: backupURL)
    
    // 3. Copy WAL and SHM files if they exist
    try copyWALFiles(to: backupDir)
    
    print("Backup created: \(backupURL.path)")
}

private static func getBackupURL() -> URL {
    let documentsURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!
    
    let backupURL = documentsURL.appendingPathComponent("Backups")
    let timestamp = DateFormatter.migrationBackup.string(from: Date())
    
    return backupURL.appendingPathComponent("WealthWise_Backup_\(timestamp).sqlite")
}
```

### Backup Naming Convention

```
WealthWise_Backup_YYYY-MM-DD_HH-mm-ss.sqlite
WealthWise_Backup_2024-01-15_14-30-45.sqlite
```

### Backup Storage Location

- **iOS**: `Documents/Backups/`
- **macOS**: `~/Library/Application Support/WealthWise/Backups/`
- **Automatic Cleanup**: Backups older than 30 days removed automatically

### Backup Retention Policy

| Backup Age | Retention |
|------------|-----------|
| < 7 days | Keep all |
| 7-30 days | Keep weekly |
| > 30 days | Delete |

### Manual Backup

Users can manually trigger backups:

```swift
@MainActor
func createManualBackup() async {
    do {
        try await DataModelMigrations.createDataBackup()
        
        showAlert(
            title: "Backup Created",
            message: "Database backup created successfully"
        )
        
    } catch {
        showAlert(
            title: "Backup Failed",
            message: "Failed to create backup: \(error.localizedDescription)"
        )
    }
}
```

### Backup Verification

Verify backup integrity before and after creation:

```swift
private static func verifyBackup(at url: URL) throws {
    // 1. Check file exists
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw MigrationError.backupFailed("Backup file not found")
    }
    
    // 2. Check file size
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    guard let fileSize = attributes[.size] as? Int64, fileSize > 0 else {
        throw MigrationError.backupFailed("Backup file is empty")
    }
    
    // 3. Verify SQLite format
    // Open database and verify schema
}
```

### iCloud Backup Integration

For iOS/macOS, integrate with iCloud:

```swift
func exportBackupToiCloud(backupURL: URL) async throws {
    // 1. Get iCloud container
    guard let iCloudURL = FileManager.default.url(
        forUbiquityContainerIdentifier: nil
    )?.appendingPathComponent("Backups") else {
        throw MigrationError.iCloudNotAvailable
    }
    
    // 2. Create directory
    try FileManager.default.createDirectory(
        at: iCloudURL,
        withIntermediateDirectories: true
    )
    
    // 3. Copy backup
    let destination = iCloudURL.appendingPathComponent(backupURL.lastPathComponent)
    try FileManager.default.copyItem(at: backupURL, to: destination)
}
```

## Best Practices

### 1. Testing Migrations

✅ **DO:**
- Test migrations with production-size datasets
- Test all migration paths (direct and multi-step)
- Test rollback scenarios
- Verify data integrity after migration
- Test on all supported iOS/macOS versions

❌ **DON'T:**
- Skip testing with large datasets
- Only test happy paths
- Ignore migration performance
- Skip rollback testing

### 2. Schema Changes

✅ **DO:**
- Add new attributes as optional
- Use renaming identifiers when renaming
- Provide default values for new attributes
- Document schema changes in version history
- Consider backward compatibility

❌ **DON'T:**
- Add required attributes without defaults
- Delete attributes without migration path
- Change attribute types without mapping
- Skip version number increment

### 3. Migration Execution

✅ **DO:**
- Create backups before migration
- Track migration progress
- Validate data after migration
- Handle errors gracefully
- Provide user feedback

❌ **DON'T:**
- Skip backup creation
- Run migrations on main thread
- Ignore validation errors
- Hide migration progress from users

### 4. Version Management

✅ **DO:**
- Increment version for all schema changes
- Follow semantic versioning
- Document version changes
- Support direct and incremental paths
- Maintain version history

❌ **DON'T:**
- Reuse version numbers
- Skip versions
- Make undocumented changes
- Remove support for older versions prematurely

### 5. Error Handling

✅ **DO:**
- Provide specific error messages
- Log migration failures
- Implement retry mechanisms
- Support manual intervention
- Maintain error history

❌ **DON'T:**
- Use generic error messages
- Ignore migration failures
- Leave database in inconsistent state
- Hide errors from users

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Migration Fails to Start

**Symptoms:**
- Migration doesn't begin
- Error: "Migration already in progress"

**Solutions:**
```swift
// Check migration status
let status = DataModelMigrations.getMigrationStatus()
print("Migration needed: \(status.migrationNeeded)")

// Reset migration lock if stuck
UserDefaults.standard.removeObject(forKey: "WealthWise_MigrationInProgress")
```

#### Issue 2: Lightweight Migration Fails

**Symptoms:**
- Error: "Can't infer mapping model"
- Migration falls back to heavyweight

**Solutions:**
1. Verify renaming identifiers are set
2. Check attribute type compatibility
3. Add custom mapping model if needed

```swift
// Set renaming identifiers in Core Data model
// Entity: CrossBorderAsset
// Old name: "amount" → New name: "currentValue"
// Renaming ID: "amount"
```

#### Issue 3: Data Corruption After Migration

**Symptoms:**
- Validation errors
- Missing data
- Relationship inconsistencies

**Solutions:**
```swift
// 1. Restore from backup
try await DataModelMigrations.rollbackMigration(to: previousVersion)

// 2. Verify backup integrity
let backupURL = getLatestBackupURL()
try verifyDatabaseIntegrity(at: backupURL)

// 3. Retry migration with validation
try await executeMigrationWithValidation(plan: plan)
```

#### Issue 4: Insufficient Storage

**Symptoms:**
- Error: "Insufficient storage space"
- Migration fails during backup

**Solutions:**
```swift
// Check available storage before migration
func checkStorageSpace() -> Bool {
    let fileURL = URL(fileURLWithPath: NSHomeDirectory())
    
    if let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey]),
       let capacity = values.volumeAvailableCapacity {
        
        let requiredSpace: Int64 = 100_000_000 // 100 MB
        return capacity > requiredSpace
    }
    
    return false
}

// Clean up old backups
func cleanupOldBackups() throws {
    let backupDir = getBackupDirectory()
    let contents = try FileManager.default.contentsOfDirectory(at: backupDir)
    
    // Delete backups older than 30 days
    let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
    
    for fileURL in contents {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let creationDate = attributes[.creationDate] as? Date,
           creationDate < cutoffDate {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
```

#### Issue 5: Slow Migration Performance

**Symptoms:**
- Migration takes longer than expected
- UI becomes unresponsive

**Solutions:**
```swift
// 1. Run migration on background thread
Task.detached(priority: .userInitiated) {
    try await DataModelMigrations.executeMigration(plan: plan) { progress, message in
        await MainActor.run {
            updateUI(progress: progress, message: message)
        }
    }
}

// 2. Batch large operations
private func migrateLargeDataset() async throws {
    let batchSize = 1000
    let totalCount = getTotalEntityCount()
    
    for offset in stride(from: 0, to: totalCount, by: batchSize) {
        try await migrateBatch(offset: offset, limit: batchSize)
        
        // Release memory between batches
        autoreleasepool {
            context.reset()
        }
    }
}

// 3. Optimize Core Data configuration
let description = NSPersistentStoreDescription()
description.shouldMigrateStoreAutomatically = true
description.shouldInferMappingModelAutomatically = true
description.type = NSSQLiteStoreType

// Use journal mode for better performance
description.setOption("WAL" as NSObject, forKey: "journal_mode")
```

#### Issue 6: Rollback Fails

**Symptoms:**
- Rollback doesn't complete
- Data remains in inconsistent state

**Solutions:**
```swift
// 1. Manual restoration from backup
func restoreFromBackup(backupURL: URL) throws {
    let databaseURL = getDatabaseURL()
    
    // Remove current database
    try? FileManager.default.removeItem(at: databaseURL)
    
    // Copy backup to database location
    try FileManager.default.copyItem(at: backupURL, to: databaseURL)
    
    // Restore version number
    let backupVersion = extractVersionFromBackup(backupURL)
    DataModelMigrations.setDataVersion(backupVersion)
}

// 2. Verify restoration
func verifyRestoredDatabase() throws {
    let container = NSPersistentContainer(name: "WealthWiseDataModel")
    
    try container.loadPersistentStores { description, error in
        if let error = error {
            throw MigrationError.corruptData("Restored database is corrupt: \(error)")
        }
    }
    
    // Verify entity counts match pre-migration
    let context = container.viewContext
    let assetCount = try context.count(for: CrossBorderAsset.fetchRequest())
    print("Assets in restored database: \(assetCount)")
}
```

### Diagnostic Tools

#### Migration Logger

```swift
final class MigrationLogger {
    static let shared = MigrationLogger()
    
    private var logURL: URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        return documentsURL.appendingPathComponent("migration_log.txt")
    }
    
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(message)\n"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                let fileHandle = try? FileHandle(forWritingTo: logURL)
                fileHandle?.seekToEndOfFile()
                fileHandle?.write(data)
                fileHandle?.closeFile()
            } else {
                try? data.write(to: logURL)
            }
        }
    }
    
    func getMigrationLogs() -> String {
        return (try? String(contentsOf: logURL)) ?? "No logs available"
    }
}
```

#### Migration Validator

```swift
final class MigrationValidator {
    
    static func validateMigrationPath(from: String, to: String) -> ValidationResult {
        var issues: [String] = []
        
        // Check version format
        if !isValidVersion(from) {
            issues.append("Invalid source version format: \(from)")
        }
        
        if !isValidVersion(to) {
            issues.append("Invalid target version format: \(to)")
        }
        
        // Check version order
        guard let fromIndex = DataModelMigrations.supportedVersions.firstIndex(of: from),
              let toIndex = DataModelMigrations.supportedVersions.firstIndex(of: to) else {
            issues.append("Version not supported")
            return ValidationResult(isValid: false, issues: issues)
        }
        
        if fromIndex >= toIndex {
            issues.append("Cannot migrate backwards or to same version")
        }
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    private static func isValidVersion(_ version: String) -> Bool {
        let pattern = #"^\d+\.\d+\.\d+$"#
        return version.range(of: pattern, options: .regularExpression) != nil
    }
}

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
}
```

### Debug Mode

Enable detailed migration logging:

```swift
#if DEBUG
extension DataModelMigrations {
    static var debugMode = true
    
    static func debugLog(_ message: String) {
        if debugMode {
            print("🔧 [Migration Debug] \(message)")
            MigrationLogger.shared.log(message)
        }
    }
}
#endif
```

## Migration Checklist

Use this checklist when planning and executing migrations:

### Pre-Migration

- [ ] Determine migration type (lightweight, heavyweight, etc.)
- [ ] Create migration plan with estimated time
- [ ] Write migration steps if needed
- [ ] Add comprehensive tests
- [ ] Test with production-size dataset
- [ ] Test rollback procedures
- [ ] Update version number
- [ ] Document schema changes

### During Migration

- [ ] Verify sufficient storage space
- [ ] Create automatic backup
- [ ] Display progress to user
- [ ] Log migration steps
- [ ] Monitor for errors
- [ ] Validate data after each step

### Post-Migration

- [ ] Verify data integrity
- [ ] Check entity counts
- [ ] Validate relationships
- [ ] Update version number
- [ ] Clean up old backups
- [ ] Log migration completion
- [ ] Monitor for issues

### Emergency Procedures

- [ ] Know how to restore from backup
- [ ] Understand rollback procedures
- [ ] Have support contact information
- [ ] Document recovery steps
- [ ] Test emergency procedures

## Future Considerations

### Planned Enhancements

1. **SwiftData Migration Support**
   - Full SwiftData migration implementation
   - Gradual Core Data → SwiftData transition
   - Schema evolution automation

2. **Cloud Sync Migration**
   - CloudKit schema migrations
   - Conflict resolution strategies
   - Multi-device synchronization

3. **Performance Optimizations**
   - Parallel migration steps
   - Incremental migrations
   - Background migration processing

4. **Enhanced Validation**
   - Automated integrity checks
   - Pre-migration analysis
   - Post-migration verification

5. **Developer Tools**
   - Migration visualization
   - Interactive testing tools
   - Performance profiling

## Conclusion

The WealthWise Core Data migration framework provides a robust, tested, and maintainable approach to database schema evolution. By following the guidelines in this document, developers can ensure smooth migrations while maintaining data integrity and user trust.

### Key Takeaways

1. **Always backup** before migrations
2. **Test thoroughly** with production-like data
3. **Validate rigorously** after migrations
4. **Document clearly** for future maintainers
5. **Monitor actively** for migration issues

### Support and Resources

- **Code**: `apple/WealthWise/WealthWise/CoreData/DataModelMigrations.swift`
- **Tests**: `apple/WealthWise/WealthWiseTests/AssetDataModelsIntegrationTests.swift`
- **Documentation**: This document
- **Issue Tracking**: GitHub Issues with `migration` label

For questions or issues with migrations, consult this document first, then create an issue with:
- Current version
- Target version
- Error messages
- Migration logs
- Steps to reproduce

---

**Document Version**: 1.0.0  
**Last Updated**: 2024  
**Maintainer**: WealthWise Development Team
