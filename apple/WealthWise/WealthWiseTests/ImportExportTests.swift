//
//  ImportExportTests.swift
//  WealthWiseTests
//
//  Created by WealthWise Team on 2025-01-24.
//  Tests for Data Import & Export Features - Issue #8
//

import XCTest
import SwiftData
@testable import WealthWise

@MainActor
final class ImportExportTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        // Create in-memory model container for testing
        let schema = Schema([Transaction.self, Goal.self, ImportJob.self, ExportJob.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - CSV Parser Tests
    
    func testCSVParserBasicParsing() async throws {
        let parser = CSVParser()
        let csvContent = """
        Date,Amount,Description
        2024-01-15,1000.50,Grocery Shopping
        2024-01-16,-500.00,Restaurant
        """
        
        let csvData = try await parser.parse(content: csvContent)
        
        XCTAssertEqual(csvData.headers.count, 3)
        XCTAssertEqual(csvData.headers, ["Date", "Amount", "Description"])
        XCTAssertEqual(csvData.rowCount, 2)
        XCTAssertEqual(csvData.rows[0][0], "2024-01-15")
        XCTAssertEqual(csvData.rows[0][1], "1000.50")
        XCTAssertEqual(csvData.rows[0][2], "Grocery Shopping")
    }
    
    func testCSVParserWithQuotedFields() async throws {
        let parser = CSVParser()
        let csvContent = """
        Date,Amount,Description
        2024-01-15,1000.50,"Shopping at ""Big Bazaar"", Mumbai"
        2024-01-16,500.00,"Lunch, dinner"
        """
        
        let csvData = try await parser.parse(content: csvContent)
        
        XCTAssertEqual(csvData.rowCount, 2)
        XCTAssertTrue(csvData.rows[0][2].contains("Big Bazaar"))
        XCTAssertTrue(csvData.rows[1][2].contains(","))
    }
    
    func testCSVParserDelimiterDetection() async throws {
        let parser = CSVParser()
        
        // Test comma delimiter
        let commaContent = "Date,Amount,Description\n2024-01-15,1000,Test"
        let commaDelimiter = await parser.detectDelimiter(content: commaContent)
        XCTAssertEqual(commaDelimiter, ",")
        
        // Test semicolon delimiter
        let semicolonContent = "Date;Amount;Description\n2024-01-15;1000;Test"
        let semicolonDelimiter = await parser.detectDelimiter(content: semicolonContent)
        XCTAssertEqual(semicolonDelimiter, ";")
    }
    
    func testCSVParserEmptyFileError() async throws {
        let parser = CSVParser()
        
        do {
            _ = try await parser.parse(content: "")
            XCTFail("Should throw emptyFile error")
        } catch CSVParseError.emptyFile {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Column Mapping Tests
    
    func testColumnMappingDetection() {
        // Test date column detection
        if let mapping = ColumnMapping.detectMapping(for: "Transaction Date") {
            XCTAssertEqual(mapping.targetField, .date)
            XCTAssertEqual(mapping.dataType, .date)
        }
        
        // Test amount column detection
        if let mapping = ColumnMapping.detectMapping(for: "Amount") {
            XCTAssertEqual(mapping.targetField, .amount)
            XCTAssertEqual(mapping.dataType, .decimal)
        }
        
        // Test description column detection
        if let mapping = ColumnMapping.detectMapping(for: "Description") {
            XCTAssertEqual(mapping.targetField, .description)
            XCTAssertEqual(mapping.dataType, .string)
        }
    }
    
    func testImportConfiguration() {
        let config = ImportConfiguration(
            mappings: [],
            skipFirstRow: true,
            delimiter: ",",
            defaultCurrency: "INR",
            detectDuplicates: true
        )
        
        XCTAssertTrue(config.skipFirstRow)
        XCTAssertEqual(config.delimiter, ",")
        XCTAssertEqual(config.defaultCurrency, "INR")
        XCTAssertTrue(config.detectDuplicates)
    }
    
    // MARK: - Import Job Tests
    
    func testImportJobCreation() {
        let importJob = ImportJob(
            filename: "test.csv",
            sourceType: .csv,
            totalRecords: 100,
            fileSize: 1024
        )
        
        XCTAssertEqual(importJob.filename, "test.csv")
        XCTAssertEqual(importJob.sourceType, .csv)
        XCTAssertEqual(importJob.status, .pending)
        XCTAssertEqual(importJob.totalRecords, 100)
        XCTAssertEqual(importJob.successfulRecords, 0)
        XCTAssertEqual(importJob.failedRecords, 0)
    }
    
    func testImportJobProgressTracking() {
        let importJob = ImportJob(
            filename: "test.csv",
            sourceType: .csv,
            totalRecords: 10
        )
        
        importJob.start()
        XCTAssertEqual(importJob.status, .processing)
        XCTAssertNotNil(importJob.startedAt)
        
        importJob.recordSuccess()
        importJob.recordSuccess()
        importJob.recordSuccess()
        XCTAssertEqual(importJob.successfulRecords, 3)
        XCTAssertEqual(importJob.progressPercentage, 30.0, accuracy: 0.01)
        
        importJob.recordFailure(error: "Test error")
        XCTAssertEqual(importJob.failedRecords, 1)
        XCTAssertEqual(importJob.warnings.count, 1)
        
        importJob.complete()
        XCTAssertEqual(importJob.status, .completed)
        XCTAssertNotNil(importJob.completedAt)
    }
    
    func testImportJobSuccessRate() {
        let importJob = ImportJob(
            filename: "test.csv",
            sourceType: .csv,
            totalRecords: 100
        )
        
        // Record 80 successes and 20 failures
        for _ in 0..<80 {
            importJob.recordSuccess()
        }
        for _ in 0..<20 {
            importJob.recordFailure(error: "Test error")
        }
        
        XCTAssertEqual(importJob.successRate, 80.0, accuracy: 0.01)
    }
    
    // MARK: - Export Job Tests
    
    func testExportJobCreation() {
        let exportJob = ExportJob(
            exportFormat: .csv,
            includeAttachments: false
        )
        
        XCTAssertEqual(exportJob.exportFormat, .csv)
        XCTAssertEqual(exportJob.status, .pending)
        XCTAssertFalse(exportJob.includeAttachments)
    }
    
    func testExportJobCompletion() {
        let exportJob = ExportJob(exportFormat: .csv)
        
        exportJob.start()
        XCTAssertEqual(exportJob.status, .processing)
        
        exportJob.complete(
            outputPath: "/tmp/export.csv",
            size: 2048,
            recordCount: 50
        )
        
        XCTAssertEqual(exportJob.status, .completed)
        XCTAssertEqual(exportJob.outputPath, "/tmp/export.csv")
        XCTAssertEqual(exportJob.outputSize, 2048)
        XCTAssertEqual(exportJob.recordCount, 50)
    }
    
    func testExportFormatFileExtensions() {
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.excel.fileExtension, "xlsx")
        XCTAssertEqual(ExportFormat.pdf.fileExtension, "pdf")
        XCTAssertEqual(ExportFormat.encryptedBackup.fileExtension, "wealthwise")
    }
    
    // MARK: - Transaction Importer Tests
    
    func testTransactionImporterPreview() async throws {
        let config = ImportConfiguration(
            mappings: [
                ColumnMapping(sourceColumn: "Date", targetField: .date, dataType: .date, dateFormat: "yyyy-MM-dd"),
                ColumnMapping(sourceColumn: "Amount", targetField: .amount, dataType: .decimal),
                ColumnMapping(sourceColumn: "Description", targetField: .description, dataType: .string)
            ],
            defaultCurrency: "INR"
        )
        
        let importer = TransactionImporter(modelContext: modelContext, configuration: config)
        
        let csvData = CSVData(
            headers: ["Date", "Amount", "Description"],
            rows: [
                ["2024-01-15", "1000.50", "Grocery Shopping"],
                ["2024-01-16", "-500.00", "Restaurant"]
            ]
        )
        
        let previews = try await importer.preview(csvData: csvData)
        
        XCTAssertEqual(previews.count, 2)
        XCTAssertEqual(previews[0].amount, 1000.50)
        XCTAssertEqual(previews[0].description, "Grocery Shopping")
        XCTAssertTrue(previews[0].validationResult.isValid)
    }
    
    func testTransactionImporterWithInvalidData() async throws {
        let config = ImportConfiguration(
            mappings: [
                ColumnMapping(sourceColumn: "Date", targetField: .date, dataType: .date, dateFormat: "yyyy-MM-dd"),
                ColumnMapping(sourceColumn: "Amount", targetField: .amount, dataType: .decimal),
                ColumnMapping(sourceColumn: "Description", targetField: .description, dataType: .string)
            ]
        )
        
        let importer = TransactionImporter(modelContext: modelContext, configuration: config)
        
        let csvData = CSVData(
            headers: ["Date", "Amount", "Description"],
            rows: [
                ["invalid-date", "1000", "Test"],  // Invalid date
                ["2024-01-15", "invalid", "Test"]  // Invalid amount
            ]
        )
        
        let previews = try await importer.preview(csvData: csvData)
        
        XCTAssertEqual(previews.count, 2)
        XCTAssertFalse(previews[0].validationResult.isValid)
        XCTAssertFalse(previews[1].validationResult.isValid)
    }
    
    // MARK: - Backup Metadata Tests
    
    func testBackupMetadataCreation() {
        let metadata = BackupMetadata(
            appVersion: "1.0.0",
            dataVersion: "1.0.0",
            deviceName: "Test Device",
            deviceId: "test-device-id",
            transactionCount: 100,
            accountCount: 5,
            goalCount: 10,
            assetCount: 20,
            salt: "test-salt-base64",
            dataHash: "test-hash",
            metadataHash: "metadata-hash"
        )
        
        XCTAssertEqual(metadata.appVersion, "1.0.0")
        XCTAssertEqual(metadata.transactionCount, 100)
        XCTAssertEqual(metadata.totalItemCount, 135)
        XCTAssertEqual(metadata.encryptionAlgorithm, "AES-256-GCM")
        XCTAssertEqual(metadata.keyDerivationAlgorithm, "PBKDF2-SHA256")
    }
    
    func testBackupValidationResult() {
        let validResult = BackupValidationResult(isValid: true)
        XCTAssertTrue(validResult.isValid)
        XCTAssertFalse(validResult.hasErrors)
        XCTAssertFalse(validResult.hasWarnings)
        
        let invalidResult = BackupValidationResult(
            isValid: false,
            errors: ["Error 1", "Error 2"],
            warnings: ["Warning 1"]
        )
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertTrue(invalidResult.hasErrors)
        XCTAssertTrue(invalidResult.hasWarnings)
        XCTAssertEqual(invalidResult.errors.count, 2)
        XCTAssertEqual(invalidResult.warnings.count, 1)
    }
    
    // MARK: - CSV Writer Tests
    
    func testCSVWriterBasicExport() async throws {
        let writer = CSVWriter()
        let headers = ["Date", "Amount", "Description"]
        let rows = [
            ["2024-01-15", "1000.50", "Grocery"],
            ["2024-01-16", "500.00", "Restaurant"]
        ]
        
        let csvString = await writer.writeToString(headers: headers, rows: rows)
        
        XCTAssertTrue(csvString.contains("Date,Amount,Description"))
        XCTAssertTrue(csvString.contains("2024-01-15,1000.50,Grocery"))
        XCTAssertTrue(csvString.contains("2024-01-16,500.00,Restaurant"))
    }
    
    func testCSVWriterWithQuotedFields() async throws {
        let writer = CSVWriter()
        let headers = ["Date", "Amount", "Description"]
        let rows = [
            ["2024-01-15", "1000.50", "Shopping, lunch"]  // Contains comma
        ]
        
        let csvString = await writer.writeToString(headers: headers, rows: rows)
        
        // Field with comma should be quoted
        XCTAssertTrue(csvString.contains("\"Shopping, lunch\""))
    }
    
    // MARK: - Integration Tests
    
    func testFullImportWorkflow() async throws {
        // Create import configuration
        let config = ImportConfiguration(
            mappings: [
                ColumnMapping(sourceColumn: "Date", targetField: .date, dataType: .date, dateFormat: "yyyy-MM-dd"),
                ColumnMapping(sourceColumn: "Amount", targetField: .amount, dataType: .decimal),
                ColumnMapping(sourceColumn: "Description", targetField: .description, dataType: .string),
                ColumnMapping(sourceColumn: "Category", targetField: .category, dataType: .string)
            ],
            defaultCurrency: "INR"
        )
        
        // Parse CSV
        let parser = CSVParser()
        let csvContent = """
        Date,Amount,Description,Category
        2024-01-15,1000.50,Grocery Shopping,Food
        2024-01-16,500.00,Restaurant,Dining
        2024-01-17,2000.00,Salary,Income
        """
        
        let csvData = try await parser.parse(content: csvContent)
        
        // Create import job
        let importJob = ImportJob(
            filename: "test_import.csv",
            sourceType: .csv,
            totalRecords: csvData.rowCount
        )
        
        modelContext.insert(importJob)
        
        // Import transactions
        let importer = TransactionImporter(modelContext: modelContext, configuration: config)
        let transactions = try await importer.importTransactions(csvData: csvData, importJob: importJob)
        
        // Verify results
        XCTAssertEqual(transactions.count, 3)
        XCTAssertEqual(importJob.status, .completed)
        XCTAssertEqual(importJob.successfulRecords, 3)
        XCTAssertEqual(importJob.failedRecords, 0)
        
        // Verify transaction data
        XCTAssertEqual(transactions[0].amount, 1000.50)
        XCTAssertEqual(transactions[0].transactionDescription, "Grocery Shopping")
        XCTAssertEqual(transactions[0].currency, "INR")
    }
    
    // MARK: - Performance Tests
    
    func testCSVParserPerformance() throws {
        let parser = CSVParser()
        
        // Generate large CSV content
        var csvContent = "Date,Amount,Description\n"
        for i in 1...1000 {
            csvContent += "2024-01-\(i % 28 + 1),\(Double(i) * 100.5),Transaction \(i)\n"
        }
        
        measure {
            Task {
                _ = try? await parser.parse(content: csvContent)
            }
        }
    }
}
