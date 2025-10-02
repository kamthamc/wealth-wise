//
//  TransactionImporter.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Transaction Importer with Duplicate Detection
//

import Foundation
import SwiftData

/// Import validation result
public struct ImportValidationResult: Sendable {
    public let isValid: Bool
    public let isDuplicate: Bool
    public let errors: [String]
    public let warnings: [String]
    public let rowIndex: Int
    
    public init(isValid: Bool, isDuplicate: Bool = false, errors: [String] = [], warnings: [String] = [], rowIndex: Int = 0) {
        self.isValid = isValid
        self.isDuplicate = isDuplicate
        self.errors = errors
        self.warnings = warnings
        self.rowIndex = rowIndex
    }
}

/// Imported transaction preview
public struct ImportedTransactionPreview: Sendable, Identifiable {
    public let id: UUID
    public let rowIndex: Int
    public let amount: Decimal
    public let date: Date
    public let description: String
    public let category: String?
    public let validationResult: ImportValidationResult
    
    public init(id: UUID = UUID(), rowIndex: Int, amount: Decimal, date: Date, description: String, category: String? = nil, validationResult: ImportValidationResult) {
        self.id = id
        self.rowIndex = rowIndex
        self.amount = amount
        self.date = date
        self.description = description
        self.category = category
        self.validationResult = validationResult
    }
}

/// Transaction importer with duplicate detection and validation
@available(iOS 18.6, macOS 15.6, *)
public actor TransactionImporter {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let configuration: ImportConfiguration
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext, configuration: ImportConfiguration) {
        self.modelContext = modelContext
        self.configuration = configuration
    }
    
    // MARK: - Public Methods
    
    /// Preview import with validation and duplicate detection
    public func preview(csvData: CSVData) async throws -> [ImportedTransactionPreview] {
        var previews: [ImportedTransactionPreview] = []
        
        for (index, row) in csvData.rows.enumerated() {
            do {
                let transaction = try parseTransaction(row: row, headers: csvData.headers, rowIndex: index)
                let validation = await validateTransaction(transaction, rowIndex: index)
                
                let preview = ImportedTransactionPreview(
                    rowIndex: index,
                    amount: transaction.amount,
                    date: transaction.date,
                    description: transaction.description,
                    category: transaction.category,
                    validationResult: validation
                )
                previews.append(preview)
            } catch {
                let validation = ImportValidationResult(
                    isValid: false,
                    errors: [error.localizedDescription],
                    rowIndex: index
                )
                // Create placeholder preview with error
                let preview = ImportedTransactionPreview(
                    rowIndex: index,
                    amount: 0,
                    date: Date(),
                    description: NSLocalizedString("import_invalid_row", comment: "Invalid row"),
                    validationResult: validation
                )
                previews.append(preview)
            }
        }
        
        return previews
    }
    
    /// Import transactions from CSV data
    public func importTransactions(csvData: CSVData, importJob: ImportJob) async throws -> [Transaction] {
        var importedTransactions: [Transaction] = []
        
        importJob.start()
        importJob.totalRecords = csvData.rows.count
        
        for (index, row) in csvData.rows.enumerated() {
            do {
                let parsedData = try parseTransaction(row: row, headers: csvData.headers, rowIndex: index)
                let validation = await validateTransaction(parsedData, rowIndex: index)
                
                if validation.isDuplicate && configuration.detectDuplicates {
                    importJob.recordDuplicate()
                    continue
                }
                
                if !validation.isValid {
                    let errorMessage = validation.errors.joined(separator: ", ")
                    importJob.recordFailure(error: "Row \(index + 1): \(errorMessage)")
                    continue
                }
                
                // Create transaction
                let transaction = Transaction(
                    amount: parsedData.amount,
                    currency: parsedData.currency ?? configuration.defaultCurrency,
                    transactionDescription: parsedData.description,
                    notes: parsedData.notes,
                    date: parsedData.date,
                    transactionType: parsedData.type,
                    category: parsedData.categoryEnum ?? .other,
                    status: .completed,
                    source: .import
                )
                
                modelContext.insert(transaction)
                importedTransactions.append(transaction)
                importJob.recordSuccess()
                
            } catch {
                importJob.recordFailure(error: "Row \(index + 1): \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
        importJob.complete()
        
        return importedTransactions
    }
    
    // MARK: - Private Methods
    
    /// Parse transaction from CSV row
    private func parseTransaction(row: [String], headers: [String], rowIndex: Int) throws -> ParsedTransactionData {
        var parsedData = ParsedTransactionData()
        
        for mapping in configuration.mappings {
            guard let columnIndex = headers.firstIndex(of: mapping.sourceColumn) else {
                continue
            }
            
            guard columnIndex < row.count else {
                continue
            }
            
            let value = row[columnIndex]
            
            switch mapping.targetField {
            case .date:
                parsedData.date = try parseDate(value, formats: configuration.dateFormats)
            case .amount:
                parsedData.amount = try parseAmount(value)
            case .description:
                parsedData.description = value
            case .category:
                parsedData.category = value
            case .type:
                parsedData.typeString = value
            case .account:
                parsedData.account = value
            case .currency:
                parsedData.currency = value
            case .notes:
                parsedData.notes = value
            case .merchant:
                parsedData.merchant = value
            case .referenceNumber:
                parsedData.referenceNumber = value
            case .ignore:
                continue
            }
        }
        
        // Validate required fields
        guard parsedData.date != nil else {
            throw CSVParseError.rowParseError(row: rowIndex, reason: NSLocalizedString("import_error_missing_date", comment: "Missing date"))
        }
        
        guard parsedData.amount != nil else {
            throw CSVParseError.rowParseError(row: rowIndex, reason: NSLocalizedString("import_error_missing_amount", comment: "Missing amount"))
        }
        
        guard !parsedData.description.isEmpty else {
            throw CSVParseError.rowParseError(row: rowIndex, reason: NSLocalizedString("import_error_missing_description", comment: "Missing description"))
        }
        
        return parsedData
    }
    
    /// Parse date from string with multiple format attempts
    private func parseDate(_ value: String, formats: [String]) throws -> Date {
        let formatter = DateFormatter()
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        
        throw CSVParseError.rowParseError(row: 0, reason: NSLocalizedString("import_error_invalid_date", comment: "Invalid date format"))
    }
    
    /// Parse amount from string
    private func parseAmount(_ value: String) throws -> Decimal {
        // Remove currency symbols and formatting
        var cleaned = value
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: configuration.thousandsSeparator, with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Handle negative amounts in parentheses
        if cleaned.hasPrefix("(") && cleaned.hasSuffix(")") {
            cleaned = "-" + cleaned.dropFirst().dropLast()
        }
        
        // Replace decimal separator if needed
        if configuration.decimalSeparator != "." {
            cleaned = cleaned.replacingOccurrences(of: configuration.decimalSeparator, with: ".")
        }
        
        guard let decimal = Decimal(string: cleaned) else {
            throw CSVParseError.rowParseError(row: 0, reason: NSLocalizedString("import_error_invalid_amount", comment: "Invalid amount format"))
        }
        
        return decimal
    }
    
    /// Validate transaction and check for duplicates
    private func validateTransaction(_ data: ParsedTransactionData, rowIndex: Int) async -> ImportValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        var isDuplicate = false
        
        // Check for duplicates if enabled
        if configuration.detectDuplicates {
            isDuplicate = await checkForDuplicate(data)
        }
        
        // Validate amount
        if let amount = data.amount, amount == 0 {
            warnings.append(NSLocalizedString("import_warning_zero_amount", comment: "Transaction has zero amount"))
        }
        
        // Validate date is not in future
        if let date = data.date, date > Date() {
            warnings.append(NSLocalizedString("import_warning_future_date", comment: "Transaction date is in the future"))
        }
        
        let isValid = errors.isEmpty && !isDuplicate
        
        return ImportValidationResult(
            isValid: isValid,
            isDuplicate: isDuplicate,
            errors: errors,
            warnings: warnings,
            rowIndex: rowIndex
        )
    }
    
    /// Check if transaction is a duplicate
    private func checkForDuplicate(_ data: ParsedTransactionData) async -> Bool {
        guard let date = data.date, let amount = data.amount else {
            return false
        }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -configuration.duplicateThresholdDays, to: date) ?? date
        let endDate = calendar.date(byAdding: .day, value: configuration.duplicateThresholdDays, to: date) ?? date
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.date >= startDate &&
                transaction.date <= endDate &&
                transaction.amount == amount &&
                transaction.transactionDescription == data.description
            }
        )
        
        do {
            let matches = try modelContext.fetch(descriptor)
            return !matches.isEmpty
        } catch {
            return false
        }
    }
}

// MARK: - Supporting Types

/// Parsed transaction data from CSV
private struct ParsedTransactionData {
    var date: Date?
    var amount: Decimal?
    var description: String = ""
    var category: String?
    var typeString: String?
    var account: String?
    var currency: String?
    var notes: String?
    var merchant: String?
    var referenceNumber: String?
    
    var type: TransactionType {
        guard let typeString = typeString?.lowercased() else {
            // Infer type from amount
            if let amount = amount {
                return amount >= 0 ? .income : .expense
            }
            return .expense
        }
        
        if typeString.contains("income") || typeString.contains("credit") || typeString.contains("deposit") {
            return .income
        } else if typeString.contains("expense") || typeString.contains("debit") || typeString.contains("withdrawal") {
            return .expense
        } else if typeString.contains("investment") {
            return .investment
        } else if typeString.contains("transfer") {
            return .transfer
        }
        
        return .expense
    }
    
    var categoryEnum: TransactionCategory? {
        guard let category = category?.lowercased() else { return nil }
        
        // Map common category strings to enum values
        if category.contains("food") || category.contains("dining") {
            return .food_dining
        } else if category.contains("transport") {
            return .transportation
        } else if category.contains("shop") {
            return .shopping
        } else if category.contains("entertainment") {
            return .entertainment
        } else if category.contains("utilities") {
            return .utilities
        } else if category.contains("medical") || category.contains("health") {
            return .medical
        } else if category.contains("education") {
            return .education
        } else if category.contains("travel") {
            return .travel
        } else if category.contains("salary") {
            return .salary
        }
        
        return nil
    }
}
