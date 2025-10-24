//
//  ColumnMapping.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-24.
//  Data Import & Export Features - Column Mapping Configuration
//

import Foundation

/// Target field for import mapping
public enum ImportTargetField: String, CaseIterable, Codable, Sendable {
    case date = "date"
    case amount = "amount"
    case description = "description"
    case category = "category"
    case type = "type"
    case account = "account"
    case currency = "currency"
    case notes = "notes"
    case merchant = "merchant"
    case referenceNumber = "reference_number"
    case ignore = "ignore"
    
    public var displayName: String {
        switch self {
        case .date:
            return NSLocalizedString("import_field_date", comment: "Date field for import")
        case .amount:
            return NSLocalizedString("import_field_amount", comment: "Amount field for import")
        case .description:
            return NSLocalizedString("import_field_description", comment: "Description field for import")
        case .category:
            return NSLocalizedString("import_field_category", comment: "Category field for import")
        case .type:
            return NSLocalizedString("import_field_type", comment: "Transaction type field for import")
        case .account:
            return NSLocalizedString("import_field_account", comment: "Account field for import")
        case .currency:
            return NSLocalizedString("import_field_currency", comment: "Currency field for import")
        case .notes:
            return NSLocalizedString("import_field_notes", comment: "Notes field for import")
        case .merchant:
            return NSLocalizedString("import_field_merchant", comment: "Merchant field for import")
        case .referenceNumber:
            return NSLocalizedString("import_field_reference", comment: "Reference number field for import")
        case .ignore:
            return NSLocalizedString("import_field_ignore", comment: "Ignore field for import")
        }
    }
    
    public var isRequired: Bool {
        switch self {
        case .date, .amount, .description:
            return true
        default:
            return false
        }
    }
}

/// Data type for field transformation
public enum ImportDataType: String, CaseIterable, Codable, Sendable {
    case string = "string"
    case decimal = "decimal"
    case integer = "integer"
    case date = "date"
    case boolean = "boolean"
    case currency = "currency"
    
    public var displayName: String {
        switch self {
        case .string:
            return NSLocalizedString("import_datatype_string", comment: "String data type")
        case .decimal:
            return NSLocalizedString("import_datatype_decimal", comment: "Decimal data type")
        case .integer:
            return NSLocalizedString("import_datatype_integer", comment: "Integer data type")
        case .date:
            return NSLocalizedString("import_datatype_date", comment: "Date data type")
        case .boolean:
            return NSLocalizedString("import_datatype_boolean", comment: "Boolean data type")
        case .currency:
            return NSLocalizedString("import_datatype_currency", comment: "Currency data type")
        }
    }
}

/// Column mapping configuration for CSV import
public struct ColumnMapping: Codable, Sendable, Identifiable {
    public let id: UUID
    public var sourceColumn: String
    public var targetField: ImportTargetField
    public var dataType: ImportDataType
    public var transformation: String?
    public var defaultValue: String?
    public var dateFormat: String?
    
    public init(
        id: UUID = UUID(),
        sourceColumn: String,
        targetField: ImportTargetField,
        dataType: ImportDataType,
        transformation: String? = nil,
        defaultValue: String? = nil,
        dateFormat: String? = nil
    ) {
        self.id = id
        self.sourceColumn = sourceColumn
        self.targetField = targetField
        self.dataType = dataType
        self.transformation = transformation
        self.defaultValue = defaultValue
        self.dateFormat = dateFormat
    }
    
    /// Create default mapping for common CSV column names
    public static func detectMapping(for columnName: String) -> ColumnMapping? {
        let normalized = columnName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Date detection
        if normalized.contains("date") || normalized.contains("time") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .date,
                dataType: .date,
                dateFormat: "yyyy-MM-dd"
            )
        }
        
        // Amount detection
        if normalized.contains("amount") || normalized.contains("value") || 
           normalized.contains("total") || normalized.contains("sum") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .amount,
                dataType: .decimal
            )
        }
        
        // Description detection
        if normalized.contains("description") || normalized.contains("narration") ||
           normalized.contains("details") || normalized.contains("particulars") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .description,
                dataType: .string
            )
        }
        
        // Category detection
        if normalized.contains("category") || normalized.contains("type") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .category,
                dataType: .string
            )
        }
        
        // Merchant detection
        if normalized.contains("merchant") || normalized.contains("vendor") ||
           normalized.contains("payee") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .merchant,
                dataType: .string
            )
        }
        
        // Account detection
        if normalized.contains("account") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .account,
                dataType: .string
            )
        }
        
        // Currency detection
        if normalized.contains("currency") || normalized.contains("ccy") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .currency,
                dataType: .string,
                defaultValue: "INR"
            )
        }
        
        // Reference number detection
        if normalized.contains("reference") || normalized.contains("ref") ||
           normalized.contains("transaction id") || normalized.contains("txn") {
            return ColumnMapping(
                sourceColumn: columnName,
                targetField: .referenceNumber,
                dataType: .string
            )
        }
        
        // Default to ignore unknown columns
        return ColumnMapping(
            sourceColumn: columnName,
            targetField: .ignore,
            dataType: .string
        )
    }
}

/// Import configuration with column mappings
public struct ImportConfiguration: Codable, Sendable {
    public var mappings: [ColumnMapping]
    public var skipFirstRow: Bool
    public var delimiter: String
    public var encoding: String
    public var dateFormats: [String]
    public var decimalSeparator: String
    public var thousandsSeparator: String
    public var defaultCurrency: String
    public var detectDuplicates: Bool
    public var duplicateThresholdDays: Int
    
    public init(
        mappings: [ColumnMapping] = [],
        skipFirstRow: Bool = true,
        delimiter: String = ",",
        encoding: String = "UTF-8",
        dateFormats: [String] = ["yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "dd-MMM-yyyy"],
        decimalSeparator: String = ".",
        thousandsSeparator: String = ",",
        defaultCurrency: String = "INR",
        detectDuplicates: Bool = true,
        duplicateThresholdDays: Int = 7
    ) {
        self.mappings = mappings
        self.skipFirstRow = skipFirstRow
        self.delimiter = delimiter
        self.encoding = encoding
        self.dateFormats = dateFormats
        self.decimalSeparator = decimalSeparator
        self.thousandsSeparator = thousandsSeparator
        self.defaultCurrency = defaultCurrency
        self.detectDuplicates = detectDuplicates
        self.duplicateThresholdDays = duplicateThresholdDays
    }
}
