//
//  LocalizationValidator.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  Comprehensive localization validation with quality assurance and multiple report formats
//

import Foundation
import Combine
import os.log

/// Protocol for localization validation, enabling testability and dependency injection
public protocol LocalizationValidatorProtocol: AnyObject {
    /// Validate translations for a specific locale
    /// - Parameters:
    ///   - translations: Dictionary of key-value translations
    ///   - locale: Target locale identifier
    /// - Returns: Validation result with issues and statistics
    func validate(translations: [String: String], for locale: String) -> LocalizationValidationResult
    
    /// Generate validation report in specified format
    /// - Parameters:
    ///   - result: Validation result
    ///   - format: Report format (text, JSON, CSV, markdown)
    /// - Returns: Formatted report string
    func generateTextReport(from result: LocalizationValidationResult) -> String
    func generateJSONReport(from result: LocalizationValidationResult) -> String
    func generateCSVReport(from result: LocalizationValidationResult) -> String
    func generateMarkdownReport(from result: LocalizationValidationResult) -> String
}

/// Comprehensive validation system for localization quality assurance
/// Supports parameter validation, length checking, consistency validation, and multiple report formats
@MainActor
public final class LocalizationValidator: ObservableObject, LocalizationValidatorProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.wealthwise.localization", category: "LocalizationValidator")
    private let requiredParameters: [String: [String]]
    private let maxLengthLimits: [String: Int]
    private let criticalKeys: Set<String>
    
    // MARK: - Initialization
    
    public init() {
        // Define required parameters for specific keys
        self.requiredParameters = [
            "dashboard.portfolio.value": ["amount", "currency"],
            "goals.savings.target": ["amount", "currency", "date"],
            "notifications.trade.executed": ["symbol", "quantity", "price"],
            "alerts.goal.progress": ["goalName", "percentage"],
            "dashboard.performance.gain": ["amount", "percentage"]
        ]
        
        // Define maximum length limits for UI components
        self.maxLengthLimits = [
            "tab.dashboard": 20,
            "tab.portfolio": 20,
            "tab.goals": 20,
            "tab.settings": 20,
            "button.cancel": 15,
            "button.save": 15,
            "button.delete": 15,
            "alert.title": 60,
            "notification.title": 80
        ]
        
        // Define critical keys that must be present
        self.criticalKeys = Set([
            "error.network.connection",
            "error.authentication.failed",
            "alert.data.corruption",
            "security.biometric.prompt",
            "backup.restore.confirmation"
        ])
        
        logger.info("LocalizationValidator initialized with \(self.requiredParameters.count) parameter rules")
    }
    
    // MARK: - Validation Methods
    
    /// Validate translations for a specific locale
    /// - Parameters:
    ///   - translations: Dictionary of key-value translations
    ///   - locale: Target locale identifier
    /// - Returns: Validation result with issues and statistics
    public func validate(translations: [String: String], for locale: String) -> LocalizationValidationResult {
        logger.info("Starting validation for locale: \(locale) with \(translations.count) translations")
        
        var issues: [ValidationIssue] = []
        var statistics = ValidationStatistics()
        
        // Track validation metrics
        statistics.totalKeys = translations.count
        statistics.locale = locale
        statistics.validationDate = Date()
        
        // Validate critical keys presence
        let criticalIssues = validateCriticalKeys(translations: translations)
        issues.append(contentsOf: criticalIssues)
        statistics.criticalIssues = criticalIssues.count
        
        // Validate each translation
        for (key, value) in translations {
            let keyIssues = validateTranslation(key: key, value: value, locale: locale)
            issues.append(contentsOf: keyIssues)
            
            // Update statistics
            if keyIssues.isEmpty {
                statistics.validKeys += 1
            } else {
                statistics.invalidKeys += 1
                for issue in keyIssues {
                    switch issue.severity {
                    case .error:
                        statistics.errorCount += 1
                    case .warning:
                        statistics.warningCount += 1
                    case .info:
                        statistics.infoCount += 1
                    }
                }
            }
        }
        
        // Calculate overall score
        statistics.overallScore = calculateOverallScore(statistics: statistics)
        
        logger.info("Validation completed: \(issues.count) issues found, score: \(String(format: "%.1f", statistics.overallScore))")
        
        return LocalizationValidationResult(
            locale: locale,
            issues: issues,
            statistics: statistics
        )
    }
    
    /// Validate a single translation entry
    /// - Parameters:
    ///   - key: Localization key
    ///   - value: Translation value
    ///   - locale: Target locale
    /// - Returns: Array of validation issues
    public func validateTranslation(key: String, value: String, locale: String) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check for empty values
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(ValidationIssue(
                key: key,
                type: .emptyValue,
                severity: .error,
                message: "Translation value is empty or contains only whitespace",
                suggestion: "Provide a meaningful translation for key '\(key)'"
            ))
        }
        
        // Validate parameters
        if let requiredParams = requiredParameters[key] {
            let parameterIssues = validateParameters(key: key, value: value, requiredParams: requiredParams)
            issues.append(contentsOf: parameterIssues)
        }
        
        // Validate length limits
        if let maxLength = maxLengthLimits[key] {
            if value.count > maxLength {
                issues.append(ValidationIssue(
                    key: key,
                    type: .lengthExceeded,
                    severity: .warning,
                    message: "Translation exceeds maximum length of \(maxLength) characters (current: \(value.count))",
                    suggestion: "Shorten the translation to fit UI constraints"
                ))
            }
        }
        
        // Check for placeholder consistency
        let placeholderIssues = validatePlaceholders(key: key, value: value)
        issues.append(contentsOf: placeholderIssues)
        
        // Validate locale-specific formatting
        let formattingIssues = validateFormatting(key: key, value: value, locale: locale)
        issues.append(contentsOf: formattingIssues)
        
        return issues
    }
    
    /// Validate critical keys are present
    /// - Parameter translations: Dictionary of translations
    /// - Returns: Array of validation issues for missing critical keys
    private func validateCriticalKeys(translations: [String: String]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        for criticalKey in criticalKeys {
            if translations[criticalKey] == nil {
                issues.append(ValidationIssue(
                    key: criticalKey,
                    type: .missingKey,
                    severity: .error,
                    message: "Critical localization key is missing",
                    suggestion: "Add translation for critical key '\(criticalKey)'"
                ))
            }
        }
        
        return issues
    }
    
    /// Validate required parameters in translation
    /// - Parameters:
    ///   - key: Localization key
    ///   - value: Translation value
    ///   - requiredParams: Array of required parameter names
    /// - Returns: Array of parameter validation issues
    private func validateParameters(key: String, value: String, requiredParams: [String]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        for param in requiredParams {
            let patterns = [
                "%{\\w*\(param)\\w*}",  // {parameter} format
                "%\\w*@\\w*",           // %@ format
                "%\\d+\\$\\w*@\\w*",   // %1$@ positional format
                "\\{\(param)\\}"        // Swift string interpolation
            ]
            
            let hasParameter = patterns.contains { pattern in
                value.range(of: pattern, options: .regularExpression) != nil
            }
            
            if !hasParameter {
                issues.append(ValidationIssue(
                    key: key,
                    type: .missingParameter,
                    severity: .error,
                    message: "Required parameter '\(param)' is missing from translation",
                    suggestion: "Add parameter '\(param)' to the translation using appropriate format"
                ))
            }
        }
        
        return issues
    }
    
    /// Validate placeholder consistency
    /// - Parameters:
    ///   - key: Localization key
    ///   - value: Translation value
    /// - Returns: Array of placeholder validation issues
    private func validatePlaceholders(key: String, value: String) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check for unmatched braces
        let openBraces = value.components(separatedBy: "{").count - 1
        let closeBraces = value.components(separatedBy: "}").count - 1
        
        if openBraces != closeBraces {
            issues.append(ValidationIssue(
                key: key,
                type: .invalidFormat,
                severity: .error,
                message: "Unmatched braces in placeholder format (open: \(openBraces), close: \(closeBraces))",
                suggestion: "Ensure all placeholder braces are properly matched"
            ))
        }
        
        // Check for malformed placeholders
        let malformedPattern = "\\{[^}]*\\{|\\}[^{]*\\}"
        if value.range(of: malformedPattern, options: .regularExpression) != nil {
            issues.append(ValidationIssue(
                key: key,
                type: .invalidFormat,
                severity: .warning,
                message: "Potentially malformed placeholder detected",
                suggestion: "Review placeholder format for correct syntax"
            ))
        }
        
        return issues
    }
    
    /// Validate locale-specific formatting
    /// - Parameters:
    ///   - key: Localization key
    ///   - value: Translation value
    ///   - locale: Target locale
    /// - Returns: Array of formatting validation issues
    private func validateFormatting(key: String, value: String, locale: String) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // Check for currency formatting consistency
        if key.contains("currency") || key.contains("amount") || key.contains("price") {
            let currencyPatterns = ["₹", "$", "€", "£", "¥"]
            let hasCurrencySymbol = currencyPatterns.contains { value.contains($0) }
            
            if !hasCurrencySymbol && value.contains("%{") {
                issues.append(ValidationIssue(
                    key: key,
                    type: .inconsistentFormatting,
                    severity: .info,
                    message: "Currency-related key might benefit from explicit currency formatting",
                    suggestion: "Consider using NumberFormatter for consistent currency display"
                ))
            }
        }
        
        // Check for date formatting
        if key.contains("date") || key.contains("time") {
            let datePatterns = ["dd", "MM", "yyyy", "HH", "mm"]
            let hasDateFormat = datePatterns.contains { pattern in
                value.contains(pattern)
            }
            
            if hasDateFormat {
                issues.append(ValidationIssue(
                    key: key,
                    type: .inconsistentFormatting,
                    severity: .info,
                    message: "Consider using DateFormatter for locale-appropriate date formatting",
                    suggestion: "Use DateFormatter with appropriate locale settings"
                ))
            }
        }
        
        return issues
    }
    
    /// Calculate overall validation score
    /// - Parameter statistics: Validation statistics
    /// - Returns: Score from 0.0 to 100.0
    private func calculateOverallScore(statistics: ValidationStatistics) -> Double {
        guard statistics.totalKeys > 0 else { return 0.0 }
        
        let baseScore = Double(statistics.validKeys) / Double(statistics.totalKeys) * 100.0
        
        // Apply penalties for issues
        let errorPenalty = Double(statistics.errorCount) * 5.0
        let warningPenalty = Double(statistics.warningCount) * 2.0
        let criticalPenalty = Double(statistics.criticalIssues) * 10.0
        
        let finalScore = max(0.0, baseScore - errorPenalty - warningPenalty - criticalPenalty)
        return min(100.0, finalScore)
    }
    
    // MARK: - Report Generation
    
    /// Generate validation report in text format
    /// - Parameter result: Validation result
    /// - Returns: Formatted text report
    public func generateTextReport(from result: LocalizationValidationResult) -> String {
        var report = """
        ================================
        LOCALIZATION VALIDATION REPORT
        ================================
        
        Locale: \(result.locale)
        Date: \(DateFormatter.reportDateFormatter.string(from: result.statistics.validationDate))
        Overall Score: \(String(format: "%.1f", result.statistics.overallScore))/100.0
        
        SUMMARY
        -------
        Total Keys: \(result.statistics.totalKeys)
        Valid Keys: \(result.statistics.validKeys)
        Invalid Keys: \(result.statistics.invalidKeys)
        Critical Issues: \(result.statistics.criticalIssues)
        
        ISSUE BREAKDOWN
        ---------------
        Errors: \(result.statistics.errorCount)
        Warnings: \(result.statistics.warningCount)
        Info: \(result.statistics.infoCount)
        
        """
        
        if !result.issues.isEmpty {
            report += "\nDETAILED ISSUES\n"
            report += "===============\n\n"
            
            let groupedIssues = Dictionary(grouping: result.issues) { $0.severity }
            
            for severity in [ValidationSeverity.error, .warning, .info] {
                if let issues = groupedIssues[severity], !issues.isEmpty {
                    report += "\(severity.rawValue.uppercased()) (\(issues.count)):\n"
                    report += String(repeating: "-", count: severity.rawValue.count + 10) + "\n"
                    
                    for issue in issues {
                        report += "• Key: \(issue.key)\n"
                        report += "  Type: \(issue.type.rawValue)\n"
                        report += "  Message: \(issue.message)\n"
                        if let suggestion = issue.suggestion {
                            report += "  Suggestion: \(suggestion)\n"
                        }
                        report += "\n"
                    }
                }
            }
        }
        
        return report
    }
    
    /// Generate validation report in JSON format
    /// - Parameter result: Validation result
    /// - Returns: JSON report string
    public func generateJSONReport(from result: LocalizationValidationResult) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(result)
            return String(data: data, encoding: .utf8) ?? "Error encoding JSON"
        } catch {
            return "Error generating JSON report: \(error.localizedDescription)"
        }
    }
    
    /// Generate validation report in CSV format
    /// - Parameter result: Validation result
    /// - Returns: CSV report string
    public func generateCSVReport(from result: LocalizationValidationResult) -> String {
        var csv = "Key,Type,Severity,Message,Suggestion\n"
        
        for issue in result.issues {
            let key = "\"\(issue.key.replacingOccurrences(of: "\"", with: "\"\""))\""
            let type = "\"\(issue.type.rawValue)\""
            let severity = "\"\(issue.severity.rawValue)\""
            let message = "\"\(issue.message.replacingOccurrences(of: "\"", with: "\"\""))\""
            let suggestion = "\"\(issue.suggestion?.replacingOccurrences(of: "\"", with: "\"\"") ?? "")\""
            
            csv += "\(key),\(type),\(severity),\(message),\(suggestion)\n"
        }
        
        return csv
    }
    
    /// Generate validation report in Markdown format
    /// - Parameter result: Validation result
    /// - Returns: Markdown report string
    public func generateMarkdownReport(from result: LocalizationValidationResult) -> String {
        var markdown = """
        # Localization Validation Report
        
        **Locale:** \(result.locale)  
        **Date:** \(DateFormatter.reportDateFormatter.string(from: result.statistics.validationDate))  
        **Overall Score:** \(String(format: "%.1f", result.statistics.overallScore))/100.0
        
        ## Summary
        
        | Metric | Count |
        |--------|-------|
        | Total Keys | \(result.statistics.totalKeys) |
        | Valid Keys | \(result.statistics.validKeys) |
        | Invalid Keys | \(result.statistics.invalidKeys) |
        | Critical Issues | \(result.statistics.criticalIssues) |
        
        ## Issue Breakdown
        
        | Severity | Count |
        |----------|-------|
        | Errors | \(result.statistics.errorCount) |
        | Warnings | \(result.statistics.warningCount) |
        | Info | \(result.statistics.infoCount) |
        
        """
        
        if !result.issues.isEmpty {
            markdown += "\n## Detailed Issues\n\n"
            
            let groupedIssues = Dictionary(grouping: result.issues) { $0.severity }
            
            for severity in [ValidationSeverity.error, .warning, .info] {
                if let issues = groupedIssues[severity], !issues.isEmpty {
                    markdown += "### \(severity.rawValue.capitalized) (\(issues.count))\n\n"
                    
                    for issue in issues {
                        markdown += "**Key:** `\(issue.key)`  \n"
                        markdown += "**Type:** \(issue.type.rawValue)  \n"
                        markdown += "**Message:** \(issue.message)  \n"
                        if let suggestion = issue.suggestion {
                            markdown += "**Suggestion:** \(suggestion)  \n"
                        }
                        markdown += "\n---\n\n"
                    }
                }
            }
        }
        
        return markdown
    }
}

// MARK: - Supporting Types

/// Represents a validation issue found during localization validation
public struct ValidationIssue: Codable, Identifiable, Equatable {
    public var id = UUID()
    public let key: String
    public let type: ValidationType
    public let severity: ValidationSeverity
    public let message: String
    public let suggestion: String?
    
    public init(key: String, type: ValidationType, severity: ValidationSeverity, message: String, suggestion: String? = nil) {
        self.key = key
        self.type = type
        self.severity = severity
        self.message = message
        self.suggestion = suggestion
    }
    
    public static func == (lhs: ValidationIssue, rhs: ValidationIssue) -> Bool {
        return lhs.key == rhs.key &&
               lhs.type == rhs.type &&
               lhs.severity == rhs.severity &&
               lhs.message == rhs.message
    }
}

/// Types of validation issues
public enum ValidationType: String, Codable, CaseIterable {
    case emptyValue = "empty_value"
    case missingKey = "missing_key"
    case missingParameter = "missing_parameter"
    case lengthExceeded = "length_exceeded"
    case invalidFormat = "invalid_format"
    case inconsistentFormatting = "inconsistent_formatting"
    case duplicateKey = "duplicate_key"
    case unusedKey = "unused_key"
}

/// Severity levels for validation issues
public enum ValidationSeverity: String, Codable, CaseIterable {
    case error = "error"
    case warning = "warning"
    case info = "info"
}

/// Statistics collected during validation
public struct ValidationStatistics: Codable {
    public var locale: String = ""
    public var totalKeys: Int = 0
    public var validKeys: Int = 0
    public var invalidKeys: Int = 0
    public var criticalIssues: Int = 0
    public var errorCount: Int = 0
    public var warningCount: Int = 0
    public var infoCount: Int = 0
    public var overallScore: Double = 0.0
    public var validationDate: Date = Date()
    
    public init() {}
}

/// Complete validation result
public struct LocalizationValidationResult: Codable {
    public let locale: String
    public let issues: [ValidationIssue]
    public let statistics: ValidationStatistics
    
    public init(locale: String, issues: [ValidationIssue], statistics: ValidationStatistics) {
        self.locale = locale
        self.issues = issues
        self.statistics = statistics
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let reportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}