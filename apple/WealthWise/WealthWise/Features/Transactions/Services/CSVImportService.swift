//
//  CSVImportService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  CSV parsing and import service with column mapping support
//

import Foundation
import SwiftData

@available(iOS 18, macOS 15, *)
@MainActor
final class CSVImportService {
    
    // MARK: - Types
    
    enum ImportError: LocalizedError {
        case invalidFile
        case emptyFile
        case parsingFailed(String)
        case invalidFormat(String)
        case missingRequiredColumns([String])
        
        var errorDescription: String? {
            switch self {
            case .invalidFile:
                return NSLocalizedString("invalid_csv_file", comment: "Invalid CSV file")
            case .emptyFile:
                return NSLocalizedString("empty_csv_file", comment: "CSV file is empty")
            case .parsingFailed(let details):
                return String(format: NSLocalizedString("csv_parsing_failed", comment: "Failed to parse CSV: %@"), details)
            case .invalidFormat(let details):
                return String(format: NSLocalizedString("invalid_csv_format", comment: "Invalid format: %@"), details)
            case .missingRequiredColumns(let columns):
                return String(format: NSLocalizedString("missing_required_columns", comment: "Missing required columns: %@"), columns.joined(separator: ", "))
            }
        }
    }
    
    struct CSVRow {
        let values: [String]
        let lineNumber: Int
    }
    
    struct ParsedTransaction {
        let date: Date?
        let description: String
        let amount: Decimal?
        let type: WebAppTransaction.TransactionType?
        let category: String?
        let notes: String?
        let lineNumber: Int
        
        var isValid: Bool {
            date != nil && amount != nil && !description.isEmpty
        }
        
        var validationErrors: [String] {
            var errors: [String] = []
            if date == nil {
                errors.append("Invalid date")
            }
            if amount == nil {
                errors.append("Invalid amount")
            }
            if description.isEmpty {
                errors.append("Missing description")
            }
            return errors
        }
    }
    
    enum BankFormat {
        case hdfc
        case generic
        case custom
        
        var displayName: String {
            switch self {
            case .hdfc: return "HDFC Bank"
            case .generic: return "Generic CSV"
            case .custom: return "Custom Mapping"
            }
        }
    }
    
    struct ColumnMapping {
        var dateColumn: Int?
        var descriptionColumn: Int?
        var amountColumn: Int?
        var typeColumn: Int?
        var categoryColumn: Int?
        var notesColumn: Int?
        
        var isValid: Bool {
            dateColumn != nil && descriptionColumn != nil && amountColumn != nil
        }
        
        var missingColumns: [String] {
            var missing: [String] = []
            if dateColumn == nil { missing.append("Date") }
            if descriptionColumn == nil { missing.append("Description") }
            if amountColumn == nil { missing.append("Amount") }
            return missing
        }
    }
    
    // MARK: - Properties
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        return formatter
    }()
    
    // MARK: - Public Methods
    
    func parseCSV(from url: URL) throws -> (headers: [String], rows: [CSVRow]) {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.invalidFile
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw ImportError.invalidFile
        }
        
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }
        
        // Parse header
        let headerLine = lines[0]
        let headers = parseCSVLine(headerLine)
        
        // Parse data rows
        var rows: [CSVRow] = []
        for (index, line) in lines.dropFirst().enumerated() {
            let values = parseCSVLine(line)
            rows.append(CSVRow(values: values, lineNumber: index + 2))
        }
        
        return (headers: headers, rows: rows)
    }
    
    func detectBankFormat(headers: [String]) -> BankFormat {
        let lowercaseHeaders = headers.map { $0.lowercased() }
        
        // HDFC Bank format detection
        if lowercaseHeaders.contains("narration") && 
           lowercaseHeaders.contains("withdrawal amt.") &&
           lowercaseHeaders.contains("deposit amt.") {
            return .hdfc
        }
        
        return .generic
    }
    
    func suggestColumnMapping(for headers: [String], format: BankFormat) -> ColumnMapping {
        var mapping = ColumnMapping()
        
        switch format {
        case .hdfc:
            mapping = mapHDFCColumns(headers: headers)
        case .generic:
            mapping = mapGenericColumns(headers: headers)
        case .custom:
            break
        }
        
        return mapping
    }
    
    func parseTransactions(
        rows: [CSVRow],
        mapping: ColumnMapping,
        defaultAccount: UUID
    ) -> [ParsedTransaction] {
        rows.map { row in
            parseTransaction(row: row, mapping: mapping)
        }
    }
    
    func importTransactions(
        _ transactions: [ParsedTransaction],
        to accountId: UUID,
        modelContext: ModelContext
    ) async throws -> Int {
        var importCount = 0
        
        for parsed in transactions where parsed.isValid {
            let transaction = WebAppTransaction(
                userId: "current_user", // Will be set by auth system
                accountId: accountId,
                date: parsed.date!,
                amount: parsed.amount!,
                type: parsed.type ?? .debit,
                category: parsed.category ?? "Other",
                description: parsed.description
            )
            
            if let notes = parsed.notes {
                transaction.notes = notes
            }
            
            modelContext.insert(transaction)
            importCount += 1
        }
        
        try modelContext.save()
        return importCount
    }
    
    // MARK: - Private Methods
    
    private func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        values.append(currentValue.trimmingCharacters(in: .whitespaces))
        return values
    }
    
    private func mapHDFCColumns(headers: [String]) -> ColumnMapping {
        var mapping = ColumnMapping()
        
        for (index, header) in headers.enumerated() {
            let lowercase = header.lowercased()
            
            switch lowercase {
            case "date":
                mapping.dateColumn = index
            case "narration":
                mapping.descriptionColumn = index
            case "withdrawal amt.", "withdrawal amt":
                mapping.amountColumn = index
            case "deposit amt.", "deposit amt":
                if mapping.amountColumn == nil {
                    mapping.amountColumn = index
                }
            case "chq./ref.no.", "chq./ref.no":
                mapping.notesColumn = index
            default:
                break
            }
        }
        
        return mapping
    }
    
    private func mapGenericColumns(headers: [String]) -> ColumnMapping {
        var mapping = ColumnMapping()
        
        for (index, header) in headers.enumerated() {
            let lowercase = header.lowercased()
            
            if lowercase.contains("date") && mapping.dateColumn == nil {
                mapping.dateColumn = index
            } else if (lowercase.contains("description") || lowercase.contains("narration") || 
                      lowercase.contains("details")) && mapping.descriptionColumn == nil {
                mapping.descriptionColumn = index
            } else if (lowercase.contains("amount") || lowercase.contains("withdrawal") || 
                      lowercase.contains("debit") || lowercase.contains("deposit") || 
                      lowercase.contains("credit")) && mapping.amountColumn == nil {
                mapping.amountColumn = index
            } else if (lowercase.contains("type") || lowercase.contains("transaction type")) && 
                     mapping.typeColumn == nil {
                mapping.typeColumn = index
            } else if lowercase.contains("category") && mapping.categoryColumn == nil {
                mapping.categoryColumn = index
            } else if (lowercase.contains("note") || lowercase.contains("memo") || 
                      lowercase.contains("reference")) && mapping.notesColumn == nil {
                mapping.notesColumn = index
            }
        }
        
        return mapping
    }
    
    private func parseTransaction(row: CSVRow, mapping: ColumnMapping) -> ParsedTransaction {
        let date = parseDate(row: row, column: mapping.dateColumn)
        let description = parseString(row: row, column: mapping.descriptionColumn)
        let amount = parseAmount(row: row, column: mapping.amountColumn)
        let type = parseType(row: row, column: mapping.typeColumn, amount: amount)
        let category = parseString(row: row, column: mapping.categoryColumn)
        let notes = parseString(row: row, column: mapping.notesColumn)
        
        return ParsedTransaction(
            date: date,
            description: description,
            amount: amount?.magnitude,
            type: type,
            category: category,
            notes: notes,
            lineNumber: row.lineNumber
        )
    }
    
    private func parseDate(row: CSVRow, column: Int?) -> Date? {
        guard let column = column, column < row.values.count else { return nil }
        let value = row.values[column]
        
        // Try common date formats
        let formats = [
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yy",
            "dd-MM-yy"
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: value) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseString(row: CSVRow, column: Int?) -> String {
        guard let column = column, column < row.values.count else { return "" }
        return row.values[column]
    }
    
    private func parseAmount(row: CSVRow, column: Int?) -> Decimal? {
        guard let column = column, column < row.values.count else { return nil }
        let value = row.values[column]
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        return Decimal(string: value)
    }
    
    private func parseType(row: CSVRow, column: Int?, amount: Decimal?) -> WebAppTransaction.TransactionType? {
        if let column = column, column < row.values.count {
            let value = row.values[column].lowercased()
            if value.contains("debit") || value.contains("withdrawal") || value.contains("expense") {
                return .debit
            } else if value.contains("credit") || value.contains("deposit") || value.contains("income") {
                return .credit
            }
        }
        
        // Infer from amount sign
        if let amount = amount {
            return amount < 0 ? .debit : .credit
        }
        
        return nil
    }
}
