import XCTest
import SwiftData
import CoreData
@testable import WealthWise

/// Integration tests for asset data models and persistence layer
/// Tests SwiftData integration, Core Data transformers, and cross-model interactions
final class AssetDataModelsIntegrationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            CrossBorderAsset.self,
            TaxResidencyStatus.self,
            PerformanceMetrics.self,
            CurrencyRisk.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
        } catch {
            XCTFail("Failed to create ModelContainer: \(error)")
        }
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - SwiftData Persistence Tests
    
    func testCrossBorderAssetPersistence() throws {
        let asset = CrossBorderAsset(
            name: "Apple Inc.",
            symbol: "AAPL",
            assetType: .equity,
            primaryCountry: "US",
            primaryCurrency: "USD",
            currentValue: 15000
        )
        
        // Insert into context
        modelContext.insert(asset)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save asset: \(error)")
        }
        
        // Query back from context
        let descriptor = FetchDescriptor<CrossBorderAsset>(
            predicate: #Predicate { $0.symbol == "AAPL" }
        )
        
        let retrievedAssets = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(retrievedAssets.count, 1)
        let retrievedAsset = retrievedAssets.first!
        
        XCTAssertEqual(retrievedAsset.name, "Apple Inc.")
        XCTAssertEqual(retrievedAsset.symbol, "AAPL")
        XCTAssertEqual(retrievedAsset.assetType, .equity)
        XCTAssertEqual(retrievedAsset.primaryCountry, "US")
        XCTAssertEqual(retrievedAsset.primaryCurrency, "USD")
        XCTAssertEqual(retrievedAsset.currentValue, 15000)
    }
    
    func testTaxResidencyStatusPersistence() throws {
        let taxStatus = TaxResidencyStatus(
            countryCode: "US",
            residencyType: .taxResident,
            taxYear: "2024-25",
            effectiveDate: Date(),
            documentType: .taxResidencyCertificate
        )
        
        // Add compliance obligations
        taxStatus.addComplianceObligation(.fatcaCompliance)
        taxStatus.addComplianceObligation(.fbardReporting)
        
        // Insert into context
        modelContext.insert(taxStatus)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save tax status: \(error)")
        }
        
        // Query back from context
        let descriptor = FetchDescriptor<TaxResidencyStatus>(
            predicate: #Predicate { $0.countryCode == "US" }
        )
        
        let retrievedStatuses = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(retrievedStatuses.count, 1)
        let retrievedStatus = retrievedStatuses.first!
        
        XCTAssertEqual(retrievedStatus.countryCode, "US")
        XCTAssertEqual(retrievedStatus.residencyType, .taxResident)
        XCTAssertTrue(retrievedStatus.complianceObligations.contains(.fatcaCompliance))
        XCTAssertTrue(retrievedStatus.complianceObligations.contains(.fbardReporting))
    }
    
    func testPerformanceMetricsPersistence() throws {
        let assetId = UUID()
        let metrics = PerformanceMetrics(
            assetId: assetId,
            baseCurrency: "INR",
            totalReturnAmount: 25000,
            totalReturnPercentage: 20.5
        )
        
        metrics.returns1Year = 18.0
        metrics.volatility = 0.15
        metrics.sharpeRatio = 1.2
        
        // Add benchmark comparison
        let niftyComparison = BenchmarkComparison(
            benchmarkName: "NIFTY 50",
            benchmarkReturn: 15.0,
            relativeReturn: 3.0
        )
        metrics.addBenchmarkComparison(niftyComparison)
        
        // Insert into context
        modelContext.insert(metrics)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save performance metrics: \(error)")
        }
        
        // Query back from context
        let descriptor = FetchDescriptor<PerformanceMetrics>(
            predicate: #Predicate { $0.assetId == assetId }
        )
        
        let retrievedMetrics = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(retrievedMetrics.count, 1)
        let retrieved = retrievedMetrics.first!
        
        XCTAssertEqual(retrieved.assetId, assetId)
        XCTAssertEqual(retrieved.baseCurrency, "INR")
        XCTAssertEqual(retrieved.totalReturnAmount, 25000)
        XCTAssertEqual(retrieved.totalReturnPercentage, 20.5)
        XCTAssertEqual(retrieved.returns1Year, 18.0)
        XCTAssertEqual(retrieved.volatility, 0.15)
        XCTAssertEqual(retrieved.sharpeRatio, 1.2)
        XCTAssertEqual(retrieved.benchmarkComparisons.count, 1)
        XCTAssertNotNil(retrieved.benchmarkComparisons["NIFTY 50"])
    }
    
    func testCurrencyRiskPersistence() throws {
        let assetId = UUID()
        let risk = CurrencyRisk(
            assetId: assetId,
            baseCurrency: "INR",
            exposedCurrencies: ["USD", "EUR"]
        )
        
        risk.volatility = 0.18
        risk.valueAtRisk = -12000
        risk.hedgingPercentage = 60.0
        
        // Add currency exposure
        let usdExposure = CurrencyExposure(
            currency: "USD",
            amount: 50000,
            percentage: 70.0,
            volatility: 0.15,
            correlation: 0.30
        )
        risk.addCurrencyExposure(usdExposure)
        
        // Add hedging recommendation
        let recommendation = HedgingRecommendation(
            strategy: .forwardContracts,
            hedgeRatio: 0.75,
            estimatedCost: 0.025,
            expectedReduction: 0.60
        )
        risk.addHedgingRecommendation(recommendation)
        
        // Insert into context
        modelContext.insert(risk)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save currency risk: \(error)")
        }
        
        // Query back from context
        let descriptor = FetchDescriptor<CurrencyRisk>(
            predicate: #Predicate { $0.assetId == assetId }
        )
        
        let retrievedRisks = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(retrievedRisks.count, 1)
        let retrieved = retrievedRisks.first!
        
        XCTAssertEqual(retrieved.assetId, assetId)
        XCTAssertEqual(retrieved.baseCurrency, "INR")
        XCTAssertEqual(retrieved.exposedCurrencies, ["USD", "EUR"])
        XCTAssertEqual(retrieved.volatility, 0.18)
        XCTAssertEqual(retrieved.valueAtRisk, -12000)
        XCTAssertEqual(retrieved.hedgingPercentage, 60.0)
        XCTAssertEqual(retrieved.currencyExposures.count, 1)
        XCTAssertEqual(retrieved.hedgingRecommendations.count, 1)
    }
    
    // MARK: - Cross-Model Relationship Tests
    
    func testAssetWithCompleteDataModels() throws {
        let assetId = UUID()
        
        // Create main asset
        let asset = CrossBorderAsset(
            name: "Microsoft Corporation",
            symbol: "MSFT",
            assetType: .equity,
            primaryCountry: "US",
            primaryCurrency: "USD",
            currentValue: 30000
        )
        asset.id = assetId
        
        // Create related tax status
        let taxStatus = TaxResidencyStatus(
            country: "US",
            residencyType: .taxResident,
            effectiveDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .year, value: 1, to: Date())
        )
        
        // Create related performance metrics
        let metrics = PerformanceMetrics(
            assetId: assetId,
            baseCurrency: "INR",
            totalReturnAmount: 45000,
            totalReturnPercentage: 25.0
        )
        metrics.returns1Year = 22.0
        metrics.volatility = 0.16
        
        // Create related currency risk
        let risk = CurrencyRisk(
            assetId: assetId,
            baseCurrency: "INR",
            exposedCurrencies: ["USD"]
        )
        risk.volatility = 0.14
        risk.valueAtRisk = -8000
        
        // Insert all models
        modelContext.insert(asset)
        modelContext.insert(taxStatus)
        modelContext.insert(metrics)
        modelContext.insert(risk)
        
        do {
            try modelContext.save()
        } catch {
            XCTFail("Failed to save complete asset model: \(error)")
        }
        
        // Query and validate relationships
        let assetDescriptor = FetchDescriptor<CrossBorderAsset>(
            predicate: #Predicate { $0.id == assetId }
        )
        let retrievedAssets = try modelContext.fetch(assetDescriptor)
        XCTAssertEqual(retrievedAssets.count, 1)
        
        let metricsDescriptor = FetchDescriptor<PerformanceMetrics>(
            predicate: #Predicate { $0.assetId == assetId }
        )
        let retrievedMetrics = try modelContext.fetch(metricsDescriptor)
        XCTAssertEqual(retrievedMetrics.count, 1)
        
        let riskDescriptor = FetchDescriptor<CurrencyRisk>(
            predicate: #Predicate { $0.assetId == assetId }
        )
        let retrievedRisks = try modelContext.fetch(riskDescriptor)
        XCTAssertEqual(retrievedRisks.count, 1)
        
        // Validate data consistency
        let retrievedAsset = retrievedAssets.first!
        let retrievedMetric = retrievedMetrics.first!
        let retrievedRisk = retrievedRisks.first!
        
        XCTAssertEqual(retrievedAsset.id, assetId)
        XCTAssertEqual(retrievedMetric.assetId, assetId)
        XCTAssertEqual(retrievedRisk.assetId, assetId)
        XCTAssertEqual(retrievedAsset.primaryCurrency, "USD")
        XCTAssertTrue(retrievedRisk.exposedCurrencies.contains("USD"))
    }
    
    // MARK: - Core Data Transformer Tests
    
    func testAssetTransformers() {
        // Test DecimalTransformer
        let decimalTransformer = DecimalTransformer()
        let originalDecimal = Decimal(12345.67)
        
        let transformedData = decimalTransformer.transformedValue(originalDecimal) as? Data
        XCTAssertNotNil(transformedData)
        
        let reversedDecimal = decimalTransformer.reverseTransformedValue(transformedData) as? Decimal
        XCTAssertEqual(reversedDecimal, originalDecimal)
        
        // Test StringSetTransformer
        let stringSetTransformer = StringSetTransformer()
        let originalSet: Set<String> = ["USD", "EUR", "GBP"]
        
        let transformedSetData = stringSetTransformer.transformedValue(originalSet) as? Data
        XCTAssertNotNil(transformedSetData)
        
        let reversedSet = stringSetTransformer.reverseTransformedValue(transformedSetData) as? Set<String>
        XCTAssertEqual(reversedSet, originalSet)
        
        // Test DictionaryTransformer
        let dictionaryTransformer = DictionaryTransformer()
        let originalDict = ["USD": 60.0, "EUR": 40.0]
        
        let transformedDictData = dictionaryTransformer.transformedValue(originalDict) as? Data
        XCTAssertNotNil(transformedDictData)
        
        let reversedDict = dictionaryTransformer.reverseTransformedValue(transformedDictData) as? [String: Double]
        XCTAssertEqual(reversedDict, originalDict)
    }
    
    func testComplexDataTransformers() {
        // Test PerformanceHistoryTransformer
        let performanceTransformer = PerformanceHistoryTransformer()
        let originalHistory = [
            "2024-01-01": 10.5,
            "2024-02-01": 12.0,
            "2024-03-01": 11.5
        ]
        
        let transformedHistoryData = performanceTransformer.transformedValue(originalHistory) as? Data
        XCTAssertNotNil(transformedHistoryData)
        
        let reversedHistory = performanceTransformer.reverseTransformedValue(transformedHistoryData) as? [String: Double]
        XCTAssertEqual(reversedHistory, originalHistory)
        
        // Test ComplianceRequirementsTransformer
        let complianceTransformer = ComplianceRequirementsTransformer()
        let originalRequirements: Set<ComplianceObligation> = [.fatcaCompliance, .fbardReporting, .liberalizedRemittanceScheme]
        
        let transformedComplianceData = complianceTransformer.transformedValue(originalRequirements) as? Data
        XCTAssertNotNil(transformedComplianceData)
        
        let reversedRequirements = complianceTransformer.reverseTransformedValue(transformedComplianceData) as? Set<ComplianceObligation>
        XCTAssertEqual(reversedRequirements, originalRequirements)
    }
    
    // MARK: - Migration Tests
    
    func testDataModelMigration() {
        let migrationManager = DataModelMigrations()
        
        // Test migration plan creation
        let migrationPlan = migrationManager.createMigrationPlan(
            from: "AssetModelV1",
            to: "AssetModelV2"
        )
        
        XCTAssertNotNil(migrationPlan)
        XCTAssertEqual(migrationPlan?.sourceVersion, "AssetModelV1")
        XCTAssertEqual(migrationPlan?.targetVersion, "AssetModelV2")
        XCTAssertGreaterThan(migrationPlan?.steps.count ?? 0, 0)
        
        // Test migration step creation
        let step = migrationManager.createMigrationStep(
            description: "Add currency risk tracking",
            migrationBlock: { context in
                // Simulate adding new fields
                return true
            },
            rollbackBlock: { context in
                // Simulate removing new fields
                return true
            }
        )
        
        XCTAssertEqual(step.description, "Add currency risk tracking")
        XCTAssertNotNil(step.execute)
        XCTAssertNotNil(step.rollback)
    }
    
    func testMigrationVersionManagement() {
        let migrationManager = DataModelMigrations()
        
        // Test version comparison
        XCTAssertTrue(migrationManager.isVersionNewer("2.0", than: "1.9"))
        XCTAssertTrue(migrationManager.isVersionNewer("1.10", than: "1.9"))
        XCTAssertFalse(migrationManager.isVersionNewer("1.0", than: "1.1"))
        
        // Test version validation
        XCTAssertTrue(migrationManager.isValidVersion("1.0.0"))
        XCTAssertTrue(migrationManager.isValidVersion("2.1"))
        XCTAssertFalse(migrationManager.isValidVersion("invalid"))
        XCTAssertFalse(migrationManager.isValidVersion(""))
    }
    
    // MARK: - Persistent Container Tests
    
    func testPersistentContainerInitialization() {
        let container = PersistentContainer.shared
        
        XCTAssertNotNil(container.modelContainer)
        XCTAssertNotNil(container.persistentContainer)
        XCTAssertNotNil(container.viewContext)
        XCTAssertNotNil(container.backgroundContext)
    }
    
    func testPersistentContainerOperations() throws {
        let container = PersistentContainer.shared
        
        // Test save operation
        let asset = CrossBorderAsset(
            name: "Test Asset",  
            symbol: "TEST",
            assetType: .equity,
            primaryCountry: "US",
            primaryCurrency: "USD",
            currentValue: 1000
        )
        
        let success = container.save(asset)
        XCTAssertTrue(success)
        
        // Test fetch operation
        let assets: [CrossBorderAsset] = container.fetch(
            predicate: NSPredicate(format: "symbol == %@", "TEST")
        )
        
        XCTAssertEqual(assets.count, 1)
        XCTAssertEqual(assets.first?.symbol, "TEST")
        
        // Test delete operation
        let deleteSuccess = container.delete(assets.first!)
        XCTAssertTrue(deleteSuccess)
        
        // Verify deletion
        let remainingAssets: [CrossBorderAsset] = container.fetch(
            predicate: NSPredicate(format: "symbol == %@", "TEST")
        )
        XCTAssertEqual(remainingAssets.count, 0)
    }
    
    func testPersistentContainerBackgroundOperations() {
        let container = PersistentContainer.shared
        let expectation = self.expectation(description: "Background operation completed")
        
        container.performBackgroundTask { backgroundContext in
            let asset = CrossBorderAsset(
                name: "Background Asset",
                symbol: "BG",
                assetType: .equity,
                primaryCountry: "US",
                primaryCurrency: "USD",
                currentValue: 2000
            )
            
            backgroundContext.insert(asset)
            
            do {
                try backgroundContext.save()
                expectation.fulfill()
            } catch {
                XCTFail("Background save failed: \(error)")
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Data Validation Tests
    
    func testDataValidationIntegration() {
        let container = PersistentContainer.shared
        
        // Test invalid asset creation
        let invalidAsset = CrossBorderAsset(
            name: "", // Invalid: empty name
            symbol: "INVALID",
            assetType: .equity,
            primaryCountry: "XX", // Invalid: non-existent country
            primaryCurrency: "XXX", // Invalid: non-existent currency
            currentValue: -1000 // Invalid: negative value
        )
        
        let validationResult = container.validateEntity(invalidAsset)
        XCTAssertFalse(validationResult.isValid)
        XCTAssertGreaterThan(validationResult.errors.count, 0)
        
        // Test valid asset creation
        let validAsset = CrossBorderAsset(
            name: "Valid Asset",
            symbol: "VALID",
            assetType: .equity,
            primaryCountry: "US",
            primaryCurrency: "USD",
            currentValue: 1000
        )
        
        let validValidationResult = container.validateEntity(validAsset)
        XCTAssertTrue(validValidationResult.isValid)
        XCTAssertEqual(validValidationResult.errors.count, 0)
    }
    
    // MARK: - Performance Integration Tests
    
    func testBulkDataOperationsPerformance() {
        let container = PersistentContainer.shared
        
        measure {
            var assets: [CrossBorderAsset] = []
            
            // Create bulk data
            for i in 0..<100 {
                let asset = CrossBorderAsset(
                    name: "Asset \(i)",
                    symbol: "SYM\(i)",
                    assetType: .equity,
                    primaryCountry: "US",
                    primaryCurrency: "USD",
                    currentValue: Decimal(1000 + i)
                )
                
                let metrics = PerformanceMetrics(
                    assetId: asset.id,
                    baseCurrency: "INR",
                    totalReturnAmount: Decimal(1000 + i),
                    totalReturnPercentage: Double(i % 20)
                )
                
                let risk = CurrencyRisk(
                    assetId: asset.id,
                    baseCurrency: "INR",
                    exposedCurrencies: ["USD"]
                )
                
                assets.append(asset)
                
                // Save individual entities
                container.save(asset)
                container.save(metrics)
                container.save(risk)
            }
            
            // Query all back
            let retrievedAssets: [CrossBorderAsset] = container.fetch()
            XCTAssertGreaterThanOrEqual(retrievedAssets.count, 100)
            
            // Clean up
            for asset in assets {
                container.delete(asset)
            }
        }
    }
    
    func testComplexQueryPerformance() {
        let container = PersistentContainer.shared
        
        // Setup test data
        for i in 0..<50 {
            let asset = CrossBorderAsset(
                name: "Performance Asset \(i)",
                symbol: "PERF\(i)",
                assetType: i % 2 == 0 ? .equity : .bond,
                primaryCountry: i % 3 == 0 ? "US" : "IN",
                primaryCurrency: i % 3 == 0 ? "USD" : "INR",
                currentValue: Decimal(1000 * (i + 1))
            )
            
            let metrics = PerformanceMetrics(
                assetId: asset.id,
                baseCurrency: "INR",
                totalReturnAmount: Decimal(500 * (i + 1)),
                totalReturnPercentage: Double(i % 30 - 10) // -10 to 19
            )
            metrics.returns1Year = Double((i % 25) - 5) // -5 to 19
            
            container.save(asset)
            container.save(metrics)
        }
        
        measure {
            // Complex query: Assets with positive returns in specific countries
            let assets: [CrossBorderAsset] = container.fetch(
                predicate: NSPredicate(format: "primaryCountry IN %@ AND currentValue > %@", ["US", "IN"], NSDecimalNumber(value: 5000))
            )
            
            // Query related performance metrics
            let assetIds = assets.map { $0.id }
            let metrics: [PerformanceMetrics] = container.fetch(
                predicate: NSPredicate(format: "assetId IN %@ AND totalReturnPercentage > %@", assetIds, 0.0)
            )
            
            XCTAssertGreaterThan(assets.count, 0)
            XCTAssertGreaterThan(metrics.count, 0)
        }
        
        // Cleanup
        let allAssets: [CrossBorderAsset] = container.fetch(
            predicate: NSPredicate(format: "name BEGINSWITH %@", "Performance Asset")
        )
        for asset in allAssets {
            container.delete(asset)
        }
    }
}