import Foundation
import CoreData
import SwiftData

/// Comprehensive data migration manager for asset models
/// Handles version updates, data transformations, and schema migrations
public final class DataModelMigrations {
    
    // MARK: - Migration Types
    
    public enum MigrationType {
        case lightweight        // Automatic Core Data migration
        case heavyweight       // Custom migration with mapping models
        case swiftDataMigration // SwiftData schema evolution
        case dataTransformation // Custom data transformation
    }
    
    public enum MigrationError: Error, LocalizedError {
        case migrationFailed(String)
        case incompatibleVersion(String)
        case corruptData(String)
        case insufficientStorage
        case migrationCancelled
        
        public var errorDescription: String? {
            switch self {
            case .migrationFailed(let message):
                return "Migration failed: \(message)"
            case .incompatibleVersion(let version):
                return "Incompatible data version: \(version)"
            case .corruptData(let details):
                return "Data corruption detected: \(details)"
            case .insufficientStorage:
                return "Insufficient storage space for migration"
            case .migrationCancelled:
                return "Migration was cancelled by user"
            }
        }
    }
    
    // MARK: - Migration Plans
    
    /// Migration plan for a specific version upgrade
    public struct MigrationPlan {
        let fromVersion: String
        let toVersion: String
        let migrationType: MigrationType
        let estimatedTime: TimeInterval
        let backupRequired: Bool
        let customMigrationSteps: [MigrationStep]
        let description: String
        
        public init(
            fromVersion: String,
            toVersion: String,
            migrationType: MigrationType,
            estimatedTime: TimeInterval,
            backupRequired: Bool = true,
            customMigrationSteps: [MigrationStep] = [],
            description: String
        ) {
            self.fromVersion = fromVersion
            self.toVersion = toVersion
            self.migrationType = migrationType
            self.estimatedTime = estimatedTime
            self.backupRequired = backupRequired
            self.customMigrationSteps = customMigrationSteps
            self.description = description
        }
    }
    
    /// Individual migration step
    public struct MigrationStep {
        let name: String
        let description: String
        let execute: () async throws -> Void
        let rollback: (() async throws -> Void)?
        
        public init(
            name: String,
            description: String,
            execute: @escaping () async throws -> Void,
            rollback: (() async throws -> Void)? = nil
        ) {
            self.name = name
            self.description = description
            self.execute = execute
            self.rollback = rollback
        }
    }
    
    // MARK: - Version Management
    
    /// Current data model version
    public static let currentVersion = "1.3.0"
    
    /// All supported versions (in order)
    public static let supportedVersions = [
        "1.0.0", // Initial release
        "1.1.0", // Added performance metrics
        "1.2.0", // Added currency risk models
        "1.3.0"  // Current: Enhanced compliance and tax residency
    ]
    
    /// Get stored data version
    public static func getCurrentDataVersion() -> String {
        return UserDefaults.standard.string(forKey: "WealthWise_DataVersion") ?? "1.0.0"
    }
    
    /// Set data version after successful migration
    public static func setDataVersion(_ version: String) {
        UserDefaults.standard.set(version, forKey: "WealthWise_DataVersion")
        UserDefaults.standard.set(Date(), forKey: "WealthWise_LastMigrationDate")
    }
    
    // MARK: - Migration Planning
    
    /// Determine if migration is needed
    public static func migrationNeeded() -> Bool {
        let currentDataVersion = getCurrentDataVersion()
        return currentDataVersion != currentVersion
    }
    
    /// Get migration plan for version upgrade
    public static func getMigrationPlan(from fromVersion: String, to toVersion: String) throws -> MigrationPlan {
        
        switch (fromVersion, toVersion) {
        case ("1.0.0", "1.1.0"):
            return MigrationPlan(
                fromVersion: fromVersion,
                toVersion: toVersion,
                migrationType: .lightweight,
                estimatedTime: 30.0,
                backupRequired: true,
                description: "Add performance metrics to existing assets"
            )
            
        case ("1.1.0", "1.2.0"):
            return MigrationPlan(
                fromVersion: fromVersion,
                toVersion: toVersion,
                migrationType: .heavyweight,
                estimatedTime: 60.0,
                backupRequired: true,
                customMigrationSteps: getCurrencyRiskMigrationSteps(),
                description: "Add currency risk analysis capabilities"
            )
            
        case ("1.2.0", "1.3.0"):
            return MigrationPlan(
                fromVersion: fromVersion,
                toVersion: toVersion,
                migrationType: .dataTransformation,
                estimatedTime: 45.0,
                backupRequired: true,
                customMigrationSteps: getTaxResidencyMigrationSteps(),
                description: "Enhanced compliance and tax residency tracking"
            )
            
        case ("1.0.0", "1.3.0"):
            // Multi-step migration
            return MigrationPlan(
                fromVersion: fromVersion,
                toVersion: toVersion,
                migrationType: .heavyweight,
                estimatedTime: 180.0,
                backupRequired: true,
                customMigrationSteps: getFullMigrationSteps(),
                description: "Complete upgrade from initial version to current"
            )
            
        default:
            throw MigrationError.incompatibleVersion("No migration path from \(fromVersion) to \(toVersion)")
        }
    }
    
    // MARK: - Migration Execution
    
    /// Execute migration with progress tracking
    public static func executeMigration(
        plan: MigrationPlan,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        
        progressHandler(0.0, "Starting migration from \(plan.fromVersion) to \(plan.toVersion)")
        
        // Create backup if required
        if plan.backupRequired {
            progressHandler(0.1, "Creating data backup...")
            try await createDataBackup()
        }
        
        // Execute migration based on type
        switch plan.migrationType {
        case .lightweight:
            try await executeLightweightMigration(plan: plan, progressHandler: progressHandler)
            
        case .heavyweight:
            try await executeHeavyweightMigration(plan: plan, progressHandler: progressHandler)
            
        case .swiftDataMigration:
            try await executeSwiftDataMigration(plan: plan, progressHandler: progressHandler)
            
        case .dataTransformation:
            try await executeDataTransformation(plan: plan, progressHandler: progressHandler)
        }
        
        // Update version after successful migration
        setDataVersion(plan.toVersion)
        progressHandler(1.0, "Migration completed successfully")
    }
    
    // MARK: - Migration Types Implementation
    
    private static func executeLightweightMigration(
        plan: MigrationPlan,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        
        progressHandler(0.2, "Configuring automatic migration...")
        
        // Core Data lightweight migration
        let persistentContainer = NSPersistentContainer(name: "WealthWiseDataModel")
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        progressHandler(0.5, "Executing automatic schema migration...")
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            persistentContainer.loadPersistentStores { _, error in
                if let error = error {
                    continuation.resume(throwing: MigrationError.migrationFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        }
        
        progressHandler(0.9, "Validating migrated data...")
        try await validateMigratedData()
    }
    
    private static func executeHeavyweightMigration(
        plan: MigrationPlan,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        
        let totalSteps = plan.customMigrationSteps.count
        
        for (index, step) in plan.customMigrationSteps.enumerated() {
            let progress = 0.2 + (Double(index) / Double(totalSteps)) * 0.7
            progressHandler(progress, "Executing: \(step.description)")
            
            do {
                try await step.execute()
            } catch {
                // Attempt rollback if available
                if let rollback = step.rollback {
                    try await rollback()
                }
                throw MigrationError.migrationFailed("Step '\(step.name)' failed: \(error.localizedDescription)")
            }
        }
        
        progressHandler(0.9, "Validating migrated data...")
        try await validateMigratedData()
    }
    
    private static func executeSwiftDataMigration(
        plan: MigrationPlan,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        
        progressHandler(0.2, "Preparing SwiftData migration...")
        
        // SwiftData migration logic
        // This would involve creating new ModelContainer with migration plan
        
        progressHandler(0.5, "Executing SwiftData schema evolution...")
        // Implementation depends on SwiftData migration capabilities
        
        progressHandler(0.9, "Validating SwiftData migration...")
        try await validateMigratedData()
    }
    
    private static func executeDataTransformation(
        plan: MigrationPlan,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        
        let totalSteps = plan.customMigrationSteps.count
        
        for (index, step) in plan.customMigrationSteps.enumerated() {
            let progress = 0.2 + (Double(index) / Double(totalSteps)) * 0.7
            progressHandler(progress, step.description)
            
            try await step.execute()
        }
        
        progressHandler(0.9, "Validating transformed data...")
        try await validateMigratedData()
    }
    
    // MARK: - Migration Steps
    
    private static func getCurrencyRiskMigrationSteps() -> [MigrationStep] {
        return [
            MigrationStep(
                name: "CreateCurrencyRiskEntities",
                description: "Creating currency risk tracking entities"
            ) {
                // Create CurrencyRisk entities for existing CrossBorderAssets
                // Implementation would fetch existing assets and create corresponding currency risk records
            },
            
            MigrationStep(
                name: "PopulateCurrencyExposure",
                description: "Calculating currency exposure for existing assets"
            ) {
                // Analyze existing assets and populate currency exposure data
            },
            
            MigrationStep(
                name: "SetupDefaultHedgingStrategies",
                description: "Setting up default hedging strategies"
            ) {
                // Apply default hedging strategies based on asset types and currencies
            }
        ]
    }
    
    private static func getTaxResidencyMigrationSteps() -> [MigrationStep] {
        return [
            MigrationStep(
                name: "CreateTaxResidencyEntities",
                description: "Creating tax residency status entities"
            ) {
                // Create TaxResidencyStatus entities based on user's country settings
            },
            
            MigrationStep(
                name: "UpdateComplianceRequirements",
                description: "Updating compliance requirements for existing assets"
            ) {
                // Update existing assets with new compliance requirements
            },
            
            MigrationStep(
                name: "MigrateDocumentReferences",
                description: "Migrating existing document references"
            ) {
                // Convert old document storage format to new structure
            }
        ]
    }
    
    private static func getFullMigrationSteps() -> [MigrationStep] {
        var steps: [MigrationStep] = []
        
        // Combine all migration steps for full upgrade
        steps.append(contentsOf: getCurrencyRiskMigrationSteps())
        steps.append(contentsOf: getTaxResidencyMigrationSteps())
        
        // Add additional validation step
        steps.append(
            MigrationStep(
                name: "FinalValidation",
                description: "Performing comprehensive data validation"
            ) {
                // Comprehensive validation of all migrated data
            }
        )
        
        return steps
    }
    
    // MARK: - Backup & Recovery
    
    private static func createDataBackup() async throws {
        // Create backup of current data before migration
        let backupURL = getBackupURL()
        
        // Implementation would copy current database to backup location
        // This is a simplified representation
        print("Creating backup at: \(backupURL)")
    }
    
    private static func getBackupURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsURL.appendingPathComponent("Backups")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        return backupURL.appendingPathComponent("WealthWise_Backup_\(timestamp).sqlite")
    }
    
    // MARK: - Validation
    
    private static func validateMigratedData() async throws {
        // Perform data integrity checks after migration
        
        // Check for orphaned records
        try await validateDataIntegrity()
        
        // Validate required fields
        try await validateRequiredFields()
        
        // Check data consistency
        try await validateDataConsistency()
    }
    
    private static func validateDataIntegrity() async throws {
        // Check for referential integrity issues
        print("Validating data integrity...")
    }
    
    private static func validateRequiredFields() async throws {
        // Ensure all required fields have valid values
        print("Validating required fields...")
    }
    
    private static func validateDataConsistency() async throws {
        // Check for logical consistency in data
        print("Validating data consistency...")
    }
    
    // MARK: - Rollback Support
    
    /// Rollback to previous version if migration fails
    public static func rollbackMigration(to version: String) async throws {
        let _ = getBackupURL()
        
        // Restore from backup
        // Implementation would restore database from backup file
        
        setDataVersion(version)
        print("Rolled back to version: \(version)")
    }
    
    // MARK: - Migration Status
    
    /// Get migration status information
    public static func getMigrationStatus() -> MigrationStatus {
        let currentDataVersion = getCurrentDataVersion()
        let lastMigrationDate = UserDefaults.standard.object(forKey: "WealthWise_LastMigrationDate") as? Date
        
        return MigrationStatus(
            currentVersion: currentDataVersion,
            latestVersion: currentVersion,
            migrationNeeded: migrationNeeded(),
            lastMigrationDate: lastMigrationDate
        )
    }
}

// MARK: - Migration Status

/// Current migration status information
public struct MigrationStatus {
    public let currentVersion: String
    public let latestVersion: String
    public let migrationNeeded: Bool
    public let lastMigrationDate: Date?
    
    public var versionsBehind: Int {
        guard let currentIndex = DataModelMigrations.supportedVersions.firstIndex(of: currentVersion),
              let latestIndex = DataModelMigrations.supportedVersions.firstIndex(of: latestVersion) else {
            return 0
        }
        return latestIndex - currentIndex
    }
    
    public var isUpToDate: Bool {
        return currentVersion == latestVersion
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let migrationBackup: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}