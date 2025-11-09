//
//  UserProfile.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  User profile model for storing tax and financial preferences
//

import Foundation
import SwiftData

/// User profile containing tax and financial preferences
@available(iOS 18.0, macOS 15.0, *)
@Model
final class UserProfile {
    
    // MARK: - Properties
    
    /// Unique identifier
    @Attribute(.unique) var id: UUID
    
    /// User's annual gross income
    var annualIncome: Decimal
    
    /// Selected tax regime
    var taxRegime: String  // TaxRegime.rawValue
    
    /// Financial year
    var financialYear: String  // e.g., "2024-25"
    
    /// Profile creation date
    var createdAt: Date
    
    /// Last update date
    var updatedAt: Date
    
    // MARK: - Deductions (Old Regime Only)
    
    /// Section 80C deductions (PPF, ELSS, Life Insurance, etc.)
    var section80CDeduction: Decimal?
    
    /// Section 80D deductions (Medical Insurance)
    var section80DDeduction: Decimal?
    
    /// Section 80E deductions (Education Loan Interest)
    var section80EDeduction: Decimal?
    
    /// Section 80G deductions (Donations)
    var section80GDeduction: Decimal?
    
    /// House Rent Allowance (HRA) claimed
    var hraDeduction: Decimal?
    
    // MARK: - Computed Properties
    
    /// Get tax regime enum
    var regime: TaxCalculationService.TaxRegime {
        get {
            TaxCalculationService.TaxRegime(rawValue: taxRegime) ?? .new
        }
        set {
            taxRegime = newValue.rawValue
        }
    }
    
    /// Total deductions claimed
    var totalDeductions: Decimal {
        var total: Decimal = 0
        
        if regime == .old {
            total += section80CDeduction ?? 0
            total += section80DDeduction ?? 0
            total += section80EDeduction ?? 0
            total += section80GDeduction ?? 0
            total += hraDeduction ?? 0
        }
        
        return total
    }
    
    /// Taxable income after deductions
    var taxableIncome: Decimal {
        max(0, annualIncome - totalDeductions)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        annualIncome: Decimal = 0,
        taxRegime: TaxCalculationService.TaxRegime = .new,
        financialYear: String = "2024-25",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.annualIncome = annualIncome
        self.taxRegime = taxRegime.rawValue
        self.financialYear = financialYear
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Public Methods
    
    /// Update annual income
    func updateIncome(_ income: Decimal) {
        annualIncome = income
        updatedAt = Date()
    }
    
    /// Update tax regime
    func updateTaxRegime(_ regime: TaxCalculationService.TaxRegime) {
        self.regime = regime
        updatedAt = Date()
        
        // Clear deductions if switching to new regime
        if regime == .new {
            clearDeductions()
        }
    }
    
    /// Update Section 80C deduction
    func updateSection80C(_ amount: Decimal?) {
        guard regime == .old else { return }
        section80CDeduction = min(amount ?? 0, 150000)  // Max limit ₹1.5L
        updatedAt = Date()
    }
    
    /// Update Section 80D deduction
    func updateSection80D(_ amount: Decimal?) {
        guard regime == .old else { return }
        section80DDeduction = min(amount ?? 0, 100000)  // Max limit ₹1L
        updatedAt = Date()
    }
    
    /// Update Section 80E deduction
    func updateSection80E(_ amount: Decimal?) {
        guard regime == .old else { return }
        section80EDeduction = amount  // No upper limit
        updatedAt = Date()
    }
    
    /// Update Section 80G deduction
    func updateSection80G(_ amount: Decimal?) {
        guard regime == .old else { return }
        section80GDeduction = amount  // Varies by donation type
        updatedAt = Date()
    }
    
    /// Update HRA deduction
    func updateHRA(_ amount: Decimal?) {
        guard regime == .old else { return }
        hraDeduction = amount
        updatedAt = Date()
    }
    
    /// Clear all deductions
    func clearDeductions() {
        section80CDeduction = nil
        section80DDeduction = nil
        section80EDeduction = nil
        section80GDeduction = nil
        hraDeduction = nil
        updatedAt = Date()
    }
    
    /// Get tax bracket information
    func getTaxInfo() -> TaxCalculationService.TaxBracketInfo {
        TaxCalculationService.shared.getTaxBracketInfo(
            annualIncome: taxableIncome,
            regime: regime
        )
    }
    
    /// Calculate estimated tax
    func calculateEstimatedTax() -> Decimal {
        let info = getTaxInfo()
        return info.estimatedAnnualTax
    }
}

// MARK: - Default Profile

@available(iOS 18.0, macOS 15.0, *)
extension UserProfile {
    
    /// Create a default profile for new users
    static func createDefault() -> UserProfile {
        UserProfile(
            annualIncome: 600000,  // Default ₹6 lakh
            taxRegime: .new,
            financialYear: getCurrentFinancialYear()
        )
    }
    
    /// Get current financial year string
    private static func getCurrentFinancialYear() -> String {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        // Financial year starts in April
        if month >= 4 {
            return "\(year)-\(String(year + 1).suffix(2))"
        } else {
            return "\(year - 1)-\(String(year).suffix(2))"
        }
    }
}
