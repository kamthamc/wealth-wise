//
//  TaxCalculationService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-11-09.
//  Service for calculating income tax based on Indian tax laws
//

import Foundation

/// Service for calculating income tax based on user's income and jurisdiction
@available(iOS 18.0, macOS 15.0, *)
final class TaxCalculationService {
    
    // MARK: - Singleton
    
    static let shared = TaxCalculationService()
    
    private init() {}
    
    // MARK: - Tax Calculation
    
    /// Calculate tax bracket rate based on annual income
    /// - Parameters:
    ///   - annualIncome: User's total annual income
    ///   - regime: Tax regime (old or new)
    /// - Returns: Applicable tax rate as decimal (0.0 to 1.0)
    func calculateTaxBracketRate(
        annualIncome: Decimal,
        regime: TaxRegime = .new
    ) -> Decimal {
        switch regime {
        case .old:
            return calculateOldRegimeTaxRate(income: annualIncome)
        case .new:
            return calculateNewRegimeTaxRate(income: annualIncome)
        }
    }
    
    /// Get tax bracket information for display
    func getTaxBracketInfo(
        annualIncome: Decimal,
        regime: TaxRegime = .new
    ) -> TaxBracketInfo {
        let rate = calculateTaxBracketRate(annualIncome: annualIncome, regime: regime)
        let bracket = getTaxBracket(income: annualIncome, regime: regime)
        let estimatedTax = calculateEstimatedTax(income: annualIncome, regime: regime)
        
        return TaxBracketInfo(
            bracket: bracket,
            rate: rate,
            estimatedAnnualTax: estimatedTax,
            regime: regime
        )
    }
    
    // MARK: - Private Methods - Old Regime
    
    private func calculateOldRegimeTaxRate(income: Decimal) -> Decimal {
        // Old tax regime slabs (FY 2024-25)
        if income <= 250000 {
            return 0.0
        } else if income <= 500000 {
            return 0.05
        } else if income <= 1000000 {
            return 0.20
        } else {
            return 0.30
        }
    }
    
    private func calculateOldRegimeTax(income: Decimal) -> Decimal {
        var tax: Decimal = 0
        
        // Slab 1: Up to ₹2.5L - 0%
        // Slab 2: ₹2.5L to ₹5L - 5%
        if income > 250000 {
            let taxableInSlab = min(income - 250000, 250000)
            tax += taxableInSlab * 0.05
        }
        
        // Slab 3: ₹5L to ₹10L - 20%
        if income > 500000 {
            let taxableInSlab = min(income - 500000, 500000)
            tax += taxableInSlab * 0.20
        }
        
        // Slab 4: Above ₹10L - 30%
        if income > 1000000 {
            let taxableInSlab = income - 1000000
            tax += taxableInSlab * 0.30
        }
        
        // Add 4% cess
        tax = tax * 1.04
        
        return tax
    }
    
    // MARK: - Private Methods - New Regime
    
    private func calculateNewRegimeTaxRate(income: Decimal) -> Decimal {
        // New tax regime slabs (FY 2024-25)
        if income <= 300000 {
            return 0.0
        } else if income <= 700000 {
            return 0.05
        } else if income <= 1000000 {
            return 0.10
        } else if income <= 1200000 {
            return 0.15
        } else if income <= 1500000 {
            return 0.20
        } else {
            return 0.30
        }
    }
    
    private func calculateNewRegimeTax(income: Decimal) -> Decimal {
        var tax: Decimal = 0
        
        // Slab 1: Up to ₹3L - 0%
        // Slab 2: ₹3L to ₹7L - 5%
        if income > 300000 {
            let taxableInSlab = min(income - 300000, 400000)
            tax += taxableInSlab * 0.05
        }
        
        // Slab 3: ₹7L to ₹10L - 10%
        if income > 700000 {
            let taxableInSlab = min(income - 700000, 300000)
            tax += taxableInSlab * 0.10
        }
        
        // Slab 4: ₹10L to ₹12L - 15%
        if income > 1000000 {
            let taxableInSlab = min(income - 1000000, 200000)
            tax += taxableInSlab * 0.15
        }
        
        // Slab 5: ₹12L to ₹15L - 20%
        if income > 1200000 {
            let taxableInSlab = min(income - 1200000, 300000)
            tax += taxableInSlab * 0.20
        }
        
        // Slab 6: Above ₹15L - 30%
        if income > 1500000 {
            let taxableInSlab = income - 1500000
            tax += taxableInSlab * 0.30
        }
        
        // Standard deduction of ₹50,000 in new regime
        if income > 750000 {
            tax = max(0, tax - (50000 * calculateNewRegimeTaxRate(income: income)))
        }
        
        // Add 4% cess
        tax = tax * 1.04
        
        return tax
    }
    
    // MARK: - Helper Methods
    
    private func calculateEstimatedTax(income: Decimal, regime: TaxRegime) -> Decimal {
        switch regime {
        case .old:
            return calculateOldRegimeTax(income: income)
        case .new:
            return calculateNewRegimeTax(income: income)
        }
    }
    
    private func getTaxBracket(income: Decimal, regime: TaxRegime) -> TaxBracket {
        let rate = calculateTaxBracketRate(annualIncome: income, regime: regime)
        
        if rate == 0 {
            return .noTax
        } else if rate <= 0.05 {
            return .bracket5
        } else if rate <= 0.10 {
            return .bracket10
        } else if rate <= 0.15 {
            return .bracket15
        } else if rate <= 0.20 {
            return .bracket20
        } else {
            return .bracket30
        }
    }
}

// MARK: - Supporting Types

extension TaxCalculationService {
    
    /// Tax regime options in India
    enum TaxRegime: String, Codable, CaseIterable {
        case old = "old"
        case new = "new"
        
        var displayName: String {
            switch self {
            case .old:
                return NSLocalizedString("tax_regime_old", comment: "Old Tax Regime (with deductions)")
            case .new:
                return NSLocalizedString("tax_regime_new", comment: "New Tax Regime (simplified)")
            }
        }
        
        var description: String {
            switch self {
            case .old:
                return NSLocalizedString("tax_regime_old_desc", comment: "Allows deductions under sections 80C, 80D, etc.")
            case .new:
                return NSLocalizedString("tax_regime_new_desc", comment: "Lower rates but no deductions")
            }
        }
    }
    
    /// Tax brackets
    enum TaxBracket: String, Codable {
        case noTax = "no_tax"
        case bracket5 = "5_percent"
        case bracket10 = "10_percent"
        case bracket15 = "15_percent"
        case bracket20 = "20_percent"
        case bracket30 = "30_percent"
        
        var displayName: String {
            switch self {
            case .noTax:
                return NSLocalizedString("tax_bracket_no_tax", comment: "No Tax")
            case .bracket5:
                return NSLocalizedString("tax_bracket_5", comment: "5% Tax Bracket")
            case .bracket10:
                return NSLocalizedString("tax_bracket_10", comment: "10% Tax Bracket")
            case .bracket15:
                return NSLocalizedString("tax_bracket_15", comment: "15% Tax Bracket")
            case .bracket20:
                return NSLocalizedString("tax_bracket_20", comment: "20% Tax Bracket")
            case .bracket30:
                return NSLocalizedString("tax_bracket_30", comment: "30% Tax Bracket")
            }
        }
        
        var incomeRange: String {
            switch self {
            case .noTax:
                return "Up to ₹3 lakh"
            case .bracket5:
                return "₹3 - ₹7 lakh"
            case .bracket10:
                return "₹7 - ₹10 lakh"
            case .bracket15:
                return "₹10 - ₹12 lakh"
            case .bracket20:
                return "₹12 - ₹15 lakh"
            case .bracket30:
                return "Above ₹15 lakh"
            }
        }
    }
    
    /// Tax bracket information
    struct TaxBracketInfo {
        let bracket: TaxBracket
        let rate: Decimal
        let estimatedAnnualTax: Decimal
        let regime: TaxRegime
        
        var effectiveTaxRate: Decimal {
            // Effective rate considering all slabs
            rate
        }
    }
}
