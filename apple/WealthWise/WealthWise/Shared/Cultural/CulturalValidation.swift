//
//  CulturalValidation.swift
//  WealthWise
//
//  Created by GitHub Copilot on 02/10/2025.
//  Cultural validation for data input and display
//

import Foundation

/// Validation rules for cultural data input and display
@available(iOS 18.6, macOS 15.6, *)
public final class CulturalValidation: Sendable {
    
    // MARK: - Properties
    
    private let culturalContext: CulturalContext
    
    // MARK: - Initialization
    
    public init(culturalContext: CulturalContext) {
        self.culturalContext = culturalContext
    }
    
    // MARK: - Number Validation
    
    /// Validate a number string according to cultural formatting rules
    public func validateNumberString(_ string: String) -> ValidationResult {
        guard !string.isEmpty else {
            return .failure(error: NSLocalizedString("validation.error.empty", comment: "Empty input"))
        }
        
        let cleanedString = cleanNumberString(string)
        
        // Check for valid number format based on locale
        let locale = culturalContext.currentLocale
        let formatter = NumberFormatter()
        formatter.locale = locale
        
        if let _ = formatter.number(from: cleanedString) {
            return .success
        } else {
            return .failure(error: NSLocalizedString("validation.error.invalidNumber", comment: "Invalid number format"))
        }
    }
    
    /// Validate a currency amount string
    public func validateCurrencyString(_ string: String) -> ValidationResult {
        guard !string.isEmpty else {
            return .failure(error: NSLocalizedString("validation.error.empty", comment: "Empty input"))
        }
        
        let cleanedString = removeCurrencySymbols(from: string)
        
        // Validate as number
        let numberValidation = validateNumberString(cleanedString)
        guard case .success = numberValidation else {
            return numberValidation
        }
        
        // Additional currency-specific validation
        if let value = Decimal(string: cleanedString), value < 0 {
            return .failure(error: NSLocalizedString("validation.error.negativeCurrency", comment: "Currency amount cannot be negative"))
        }
        
        return .success
    }
    
    // MARK: - Date Validation
    
    /// Validate a date string according to cultural date format
    public func validateDateString(_ string: String, format: LocalizationDateFormatStyle? = nil) -> ValidationResult {
        guard !string.isEmpty else {
            return .failure(error: NSLocalizedString("validation.error.empty", comment: "Empty input"))
        }
        
        let dateFormat = format ?? culturalContext.localizationConfig.dateFormat
        let formatter = DateFormatter()
        formatter.locale = culturalContext.currentLocale
        
        // Set format based on preference
        switch dateFormat {
        case .ddmmyyyy:
            formatter.dateFormat = "dd/MM/yyyy"
        case .mmddyyyy:
            formatter.dateFormat = "MM/dd/yyyy"
        case .yyyymmdd:
            formatter.dateFormat = "yyyy-MM-dd"
        case .system, .relative:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }
        
        if let _ = formatter.date(from: string) {
            return .success
        } else {
            return .failure(error: NSLocalizedString("validation.error.invalidDate", comment: "Invalid date format"))
        }
    }
    
    // MARK: - Text Direction Validation
    
    /// Validate text direction consistency
    public func validateTextDirection(for text: String) -> ValidationResult {
        let detector = TextDirectionDetector()
        let detectedDirection = detector.detectDirection(from: text)
        
        // Warn if text direction conflicts with UI direction
        if culturalContext.isRTL && detectedDirection == .leftToRight {
            return .warning(message: NSLocalizedString("validation.warning.textDirectionMismatch", comment: "Text direction may not match UI"))
        }
        
        return .success
    }
    
    // MARK: - Cultural Format Validation
    
    /// Validate that data conforms to cultural expectations
    public func validateCulturalFormat(data: [String: Any]) -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        // Validate number formats
        if let numberStrings = data["numbers"] as? [String] {
            for numberString in numberStrings {
                results.append(validateNumberString(numberString))
            }
        }
        
        // Validate date formats
        if let dateStrings = data["dates"] as? [String] {
            for dateString in dateStrings {
                results.append(validateDateString(dateString))
            }
        }
        
        // Validate currency formats
        if let currencyStrings = data["currencies"] as? [String] {
            for currencyString in currencyStrings {
                results.append(validateCurrencyString(currencyString))
            }
        }
        
        return results
    }
    
    // MARK: - Accessibility Validation
    
    /// Validate accessibility compliance
    public func validateAccessibility(for element: AccessibleElement) -> ValidationResult {
        var issues: [String] = []
        
        // Check for accessibility label
        if element.label.isEmpty {
            issues.append(NSLocalizedString("validation.accessibility.missingLabel", comment: "Missing accessibility label"))
        }
        
        // Check for sufficient contrast (if applicable)
        if let colors = element.colors {
            if !hasAdequateContrast(foreground: colors.foreground, background: colors.background) {
                issues.append(NSLocalizedString("validation.accessibility.lowContrast", comment: "Insufficient color contrast"))
            }
        }
        
        // Check for appropriate font size in accessibility mode
        if culturalContext.isAccessibilityEnabled && element.fontSize < 17 {
            issues.append(NSLocalizedString("validation.accessibility.smallFont", comment: "Font size too small for accessibility"))
        }
        
        if issues.isEmpty {
            return .success
        } else {
            return .failure(error: issues.joined(separator: "; "))
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func cleanNumberString(_ string: String) -> String {
        // Remove thousands separators and clean up
        var cleaned = string.trimmingCharacters(in: .whitespaces)
        
        // Handle different thousand separators
        let locale = culturalContext.currentLocale
        if let groupingSeparator = locale.groupingSeparator {
            cleaned = cleaned.replacingOccurrences(of: groupingSeparator, with: "")
        }
        
        return cleaned
    }
    
    private func removeCurrencySymbols(from string: String) -> String {
        var cleaned = string
        
        // Remove common currency symbols
        let currencySymbols = ["$", "€", "£", "¥", "₹", "₽", "₩", "₪", "₨"]
        for symbol in currencySymbols {
            cleaned = cleaned.replacingOccurrences(of: symbol, with: "")
        }
        
        // Remove currency codes (like USD, EUR, etc.)
        let currencyCodePattern = "[A-Z]{3}"
        if let regex = try? NSRegularExpression(pattern: currencyCodePattern, options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
    
    private func hasAdequateContrast(foreground: String, background: String) -> Bool {
        // Simplified contrast check - in production would use WCAG formula
        // This is a placeholder that always returns true for now
        // TODO: Implement proper WCAG 2.1 contrast ratio calculation
        return true
    }
}

// MARK: - Supporting Types

/// Result of a validation operation
public enum ValidationResult: Sendable {
    case success
    case warning(message: String)
    case failure(error: String)
    
    public var isValid: Bool {
        switch self {
        case .success, .warning:
            return true
        case .failure:
            return false
        }
    }
    
    public var message: String? {
        switch self {
        case .success:
            return nil
        case .warning(let msg):
            return msg
        case .failure(let error):
            return error
        }
    }
}

/// Represents an accessible UI element for validation
public struct AccessibleElement: Sendable {
    public let label: String
    public let hint: String?
    public let value: String?
    public let colors: AccessibleColors?
    public let fontSize: CGFloat
    
    public init(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        colors: AccessibleColors? = nil,
        fontSize: CGFloat = 17
    ) {
        self.label = label
        self.hint = hint
        self.value = value
        self.colors = colors
        self.fontSize = fontSize
    }
}

/// Color information for accessibility validation
public struct AccessibleColors: Sendable {
    public let foreground: String
    public let background: String
    
    public init(foreground: String, background: String) {
        self.foreground = foreground
        self.background = background
    }
}
