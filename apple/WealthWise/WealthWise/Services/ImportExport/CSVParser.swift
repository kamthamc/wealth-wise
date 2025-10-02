//
//  CSVParser.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - CSV Parser Service
//

import Foundation

/// CSV parsing error
public enum CSVParseError: Error, LocalizedError {
    case invalidFormat
    case emptyFile
    case encodingError
    case invalidDelimiter
    case headerMissing
    case rowParseError(row: Int, reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return NSLocalizedString("csv_error_invalid_format", comment: "Invalid CSV format")
        case .emptyFile:
            return NSLocalizedString("csv_error_empty_file", comment: "CSV file is empty")
        case .encodingError:
            return NSLocalizedString("csv_error_encoding", comment: "CSV encoding error")
        case .invalidDelimiter:
            return NSLocalizedString("csv_error_invalid_delimiter", comment: "Invalid CSV delimiter")
        case .headerMissing:
            return NSLocalizedString("csv_error_header_missing", comment: "CSV header missing")
        case .rowParseError(let row, let reason):
            return String(format: NSLocalizedString("csv_error_row_parse", comment: "Error parsing row %d: %@"), row, reason)
        }
    }
}

/// Parsed CSV data structure
public struct CSVData: Sendable {
    public let headers: [String]
    public let rows: [[String]]
    public let rowCount: Int
    public let columnCount: Int
    
    public init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
        self.rowCount = rows.count
        self.columnCount = headers.count
    }
}

/// CSV Parser service with support for various formats
@available(iOS 18.6, macOS 15.6, *)
public actor CSVParser {
    
    // MARK: - Properties
    
    private let delimiter: String
    private let encoding: String.Encoding
    private let hasHeader: Bool
    
    // MARK: - Initialization
    
    public init(delimiter: String = ",", encoding: String.Encoding = .utf8, hasHeader: Bool = true) {
        self.delimiter = delimiter
        self.encoding = encoding
        self.hasHeader = hasHeader
    }
    
    // MARK: - Public Methods
    
    /// Parse CSV file from URL
    public func parse(fileURL: URL) async throws -> CSVData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw CSVParseError.emptyFile
        }
        
        let content = try String(contentsOf: fileURL, encoding: encoding)
        return try await parse(content: content)
    }
    
    /// Parse CSV content from string
    public func parse(content: String) async throws -> CSVData {
        guard !content.isEmpty else {
            throw CSVParseError.emptyFile
        }
        
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !lines.isEmpty else {
            throw CSVParseError.emptyFile
        }
        
        var headers: [String] = []
        var rows: [[String]] = []
        var startIndex = 0
        
        // Parse header if present
        if hasHeader {
            guard let firstLine = lines.first else {
                throw CSVParseError.headerMissing
            }
            headers = try parseRow(firstLine, rowNumber: 0)
            startIndex = 1
        } else {
            // Generate generic headers if no header row
            let firstRow = try parseRow(lines[0], rowNumber: 0)
            headers = (0..<firstRow.count).map { "Column_\($0)" }
            startIndex = 0
        }
        
        // Parse data rows
        for (index, line) in lines.enumerated() where index >= startIndex {
            do {
                let row = try parseRow(line, rowNumber: index)
                
                // Ensure row has same number of columns as header
                if row.count == headers.count {
                    rows.append(row)
                } else if row.count < headers.count {
                    // Pad with empty strings
                    var paddedRow = row
                    paddedRow.append(contentsOf: Array(repeating: "", count: headers.count - row.count))
                    rows.append(paddedRow)
                } else {
                    // Truncate extra columns
                    rows.append(Array(row.prefix(headers.count)))
                }
            } catch {
                throw CSVParseError.rowParseError(row: index, reason: error.localizedDescription)
            }
        }
        
      return await CSVData(headers: headers, rows: rows)
    }
    
    /// Detect delimiter from content
    public func detectDelimiter(content: String) async -> String {
        let possibleDelimiters = [",", ";", "\t", "|"]
        let firstLine = content.components(separatedBy: .newlines).first ?? ""
        
        var delimiterCounts: [String: Int] = [:]
        for delimiter in possibleDelimiters {
            delimiterCounts[delimiter] = firstLine.components(separatedBy: delimiter).count
        }
        
        // Return delimiter with highest count
        return delimiterCounts.max(by: { $0.value < $1.value })?.key ?? ","
    }
    
    /// Validate CSV structure
    public func validate(fileURL: URL) async throws -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        do {
            let csvData = try await parse(fileURL: fileURL)
            
            // Check if file has data
            if csvData.rowCount == 0 {
                errors.append(NSLocalizedString("csv_validation_no_data", comment: "CSV file has no data rows"))
            }
            
            // Check if columns are consistent
            for (index, row) in csvData.rows.enumerated() {
                if row.count != csvData.columnCount {
                    errors.append(String(format: NSLocalizedString("csv_validation_inconsistent_columns", comment: "Row %d has inconsistent column count"), index + 1))
                }
            }
            
        } catch {
            errors.append(error.localizedDescription)
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Preview first N rows
    public func preview(fileURL: URL, rows: Int = 10) async throws -> CSVData {
        let csvData = try await parse(fileURL: fileURL)
        let previewRows = Array(csvData.rows.prefix(rows))
      return await CSVData(headers: csvData.headers, rows: previewRows)
    }
    
    // MARK: - Private Methods
    
    /// Parse a single CSV row handling quoted fields
    private func parseRow(_ line: String, rowNumber: Int) throws -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var previousChar: Character?
        
        for char in line {
            if char == "\"" {
                // Handle escaped quotes
                if previousChar == "\"" && insideQuotes {
                    currentField.append(char)
                    previousChar = nil
                    continue
                }
                insideQuotes.toggle()
            } else if char == delimiter.first && !insideQuotes {
                // End of field
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
            previousChar = char
        }
        
        // Add last field
        fields.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return fields
    }
}

/// CSV Writer for export functionality
@available(iOS 18.6, macOS 15.6, *)
public actor CSVWriter {
    
    // MARK: - Properties
    
    private let delimiter: String
    private let encoding: String.Encoding
    
    // MARK: - Initialization
    
    public init(delimiter: String = ",", encoding: String.Encoding = .utf8) {
        self.delimiter = delimiter
        self.encoding = encoding
    }
    
    // MARK: - Public Methods
    
    /// Write CSV data to file
    public func write(headers: [String], rows: [[String]], to fileURL: URL) async throws {
        var content = ""
        
        // Write header
        content += headers.map { escapeField($0) }.joined(separator: delimiter)
        content += "\n"
        
        // Write rows
        for row in rows {
            content += row.map { escapeField($0) }.joined(separator: delimiter)
            content += "\n"
        }
        
        try content.write(to: fileURL, atomically: true, encoding: encoding)
    }
    
    /// Write CSV data to string
    public func writeToString(headers: [String], rows: [[String]]) async -> String {
        var content = ""
        
        // Write header
        content += headers.map { escapeField($0) }.joined(separator: delimiter)
        content += "\n"
        
        // Write rows
        for row in rows {
            content += row.map { escapeField($0) }.joined(separator: delimiter)
            content += "\n"
        }
        
        return content
    }
    
    // MARK: - Private Methods
    
    /// Escape CSV field (add quotes if needed)
    private func escapeField(_ field: String) -> String {
        if field.contains(delimiter) || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
