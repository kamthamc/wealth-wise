//
//  TaxCalculation.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Tax Calculation Models
//

import Foundation
import SwiftData

/// Tax calculation model for financial year tax reporting
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class TaxCalculation {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var financialYear: String // "2024-25"
    public var calculatedAt: Date
    
    // MARK: - Capital Gains
    
    public var shortTermCapitalGains: Decimal // STCG (< 1 year for equity, < 3 years for debt)
    public var longTermCapitalGains: Decimal // LTCG (> 1 year for equity, > 3 years for debt)
    public var totalCapitalGains: Decimal
    
    // MARK: - Income Components
    
    public var totalDividendIncome: Decimal
    public var totalInterestIncome: Decimal
    public var totalRentalIncome: Decimal
    public var totalBusinessIncome: Decimal
    public var otherIncome: Decimal
    
    // MARK: - Tax Computation
    
    public var taxableIncome: Decimal
    public var taxOwed: Decimal
    public var taxPaid: Decimal // TDS + advance tax
    public var refundDue: Decimal // If tax paid > tax owed
    public var additionalTaxDue: Decimal // If tax owed > tax paid
    
    // MARK: - Deductions
    
    public var section80CDeductions: Decimal
    public var section80DDeductions: Decimal
    public var otherDeductions: Decimal
    public var totalDeductions: Decimal
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        financialYear: String,
        shortTermCapitalGains: Decimal = 0,
        longTermCapitalGains: Decimal = 0,
        totalDividendIncome: Decimal = 0,
        totalInterestIncome: Decimal = 0,
        calculatedAt: Date = Date()
    ) {
        self.id = id
        self.financialYear = financialYear
        self.calculatedAt = calculatedAt
        
        // Capital gains
        self.shortTermCapitalGains = shortTermCapitalGains
        self.longTermCapitalGains = longTermCapitalGains
        self.totalCapitalGains = shortTermCapitalGains + longTermCapitalGains
        
        // Income components
        self.totalDividendIncome = totalDividendIncome
        self.totalInterestIncome = totalInterestIncome
        self.totalRentalIncome = 0
        self.totalBusinessIncome = 0
        self.otherIncome = 0
        
        // Tax computation
        self.taxableIncome = 0
        self.taxOwed = 0
        self.taxPaid = 0
        self.refundDue = 0
        self.additionalTaxDue = 0
        
        // Deductions
        self.section80CDeductions = 0
        self.section80DDeductions = 0
        self.otherDeductions = 0
        self.totalDeductions = 0
        
        self.createdAt = calculatedAt
        self.updatedAt = calculatedAt
    }
    
    // MARK: - Computed Properties
    
    /// Total income before deductions
    public var grossIncome: Decimal {
        return totalCapitalGains + totalDividendIncome + totalInterestIncome +
               totalRentalIncome + totalBusinessIncome + otherIncome
    }
    
    /// Effective tax rate as percentage
    public var effectiveTaxRate: Double {
        guard grossIncome > 0 else { return 0 }
        return Double(truncating: (taxOwed / grossIncome * 100) as NSDecimalNumber)
    }
    
    /// Whether refund is due
    public var isRefundDue: Bool {
        return refundDue > 0
    }
    
    /// Whether additional tax payment is required
    public var isAdditionalTaxDue: Bool {
        return additionalTaxDue > 0
    }
}

/// Capital gains breakdown for detailed reporting
public struct CapitalGainsBreakdown: Codable, Identifiable, Sendable {
    public let id: UUID
    public let assetName: String
    public let assetType: String
    public let purchaseDate: Date
    public let saleDate: Date
    public let purchasePrice: Decimal
    public let salePrice: Decimal
    public let capitalGain: Decimal
    public let holdingPeriodDays: Int
    public let isLongTerm: Bool
    public let taxRate: Decimal
    public let taxAmount: Decimal
    
    public init(
        id: UUID = UUID(),
        assetName: String,
        assetType: String,
        purchaseDate: Date,
        saleDate: Date,
        purchasePrice: Decimal,
        salePrice: Decimal
    ) {
        self.id = id
        self.assetName = assetName
        self.assetType = assetType
        self.purchaseDate = purchaseDate
        self.saleDate = saleDate
        self.purchasePrice = purchasePrice
        self.salePrice = salePrice
        self.capitalGain = salePrice - purchasePrice
        
        // Calculate holding period
        let calendar = Calendar.current
        self.holdingPeriodDays = calendar.dateComponents([.day], from: purchaseDate, to: saleDate).day ?? 0
        
        // Determine if long-term based on asset type
        // Equity: > 1 year (365 days), Debt/Others: > 3 years (1095 days)
        if assetType.lowercased().contains("equity") || assetType.lowercased().contains("stock") {
            self.isLongTerm = holdingPeriodDays > 365
        } else {
            self.isLongTerm = holdingPeriodDays > 1095
        }
        
        // Tax rate based on gain type
        if isLongTerm {
            self.taxRate = 10.0 // LTCG: 10% (plus surcharge and cess)
        } else {
            self.taxRate = 15.0 // STCG: 15% for equity, add to income for debt
        }
        
        self.taxAmount = abs(capitalGain) * taxRate / 100
    }
    
    /// Display string for holding period
    public var holdingPeriodDisplay: String {
        let years = holdingPeriodDays / 365
        let months = (holdingPeriodDays % 365) / 30
        
        if years > 0 {
            return "\(years)y \(months)m"
        } else {
            return "\(months)m"
        }
    }
}

/// Dividend income breakdown
public struct DividendIncomeBreakdown: Codable, Identifiable, Sendable {
    public let id: UUID
    public let assetName: String
    public let dividendDate: Date
    public let dividendAmount: Decimal
    public let tdsDeducted: Decimal
    public let netDividend: Decimal
    
    public init(
        id: UUID = UUID(),
        assetName: String,
        dividendDate: Date,
        dividendAmount: Decimal,
        tdsDeducted: Decimal = 0
    ) {
        self.id = id
        self.assetName = assetName
        self.dividendDate = dividendDate
        self.dividendAmount = dividendAmount
        self.tdsDeducted = tdsDeducted
        self.netDividend = dividendAmount - tdsDeducted
    }
}

/// Interest income breakdown
public struct InterestIncomeBreakdown: Codable, Identifiable, Sendable {
    public let id: UUID
    public let sourceName: String
    public let sourceType: InterestSourceType
    public let interestAmount: Decimal
    public let tdsDeducted: Decimal
    public let netInterest: Decimal
    public let periodStart: Date
    public let periodEnd: Date
    
    public init(
        id: UUID = UUID(),
        sourceName: String,
        sourceType: InterestSourceType,
        interestAmount: Decimal,
        tdsDeducted: Decimal = 0,
        periodStart: Date,
        periodEnd: Date
    ) {
        self.id = id
        self.sourceName = sourceName
        self.sourceType = sourceType
        self.interestAmount = interestAmount
        self.tdsDeducted = tdsDeducted
        self.netInterest = interestAmount - tdsDeducted
        self.periodStart = periodStart
        self.periodEnd = periodEnd
    }
}

/// Interest source type
public enum InterestSourceType: String, CaseIterable, Codable, Sendable {
    case savingsAccount = "savings_account"
    case fixedDeposit = "fixed_deposit"
    case bonds = "bonds"
    case debtMutualFunds = "debt_mutual_funds"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .savingsAccount:
            return NSLocalizedString("interest_source_savings", comment: "Savings account")
        case .fixedDeposit:
            return NSLocalizedString("interest_source_fd", comment: "Fixed deposit")
        case .bonds:
            return NSLocalizedString("interest_source_bonds", comment: "Bonds")
        case .debtMutualFunds:
            return NSLocalizedString("interest_source_debt_mf", comment: "Debt mutual funds")
        case .other:
            return NSLocalizedString("interest_source_other", comment: "Other interest")
        }
    }
}

/// Tax saving investment tracking
public struct TaxSavingInvestment: Codable, Identifiable, Sendable {
    public let id: UUID
    public let section: TaxSection
    public let investmentName: String
    public let investmentAmount: Decimal
    public let investmentDate: Date
    public let taxBenefit: Decimal
    
    public init(
        id: UUID = UUID(),
        section: TaxSection,
        investmentName: String,
        investmentAmount: Decimal,
        investmentDate: Date,
        taxBenefit: Decimal
    ) {
        self.id = id
        self.section = section
        self.investmentName = investmentName
        self.investmentAmount = investmentAmount
        self.investmentDate = investmentDate
        self.taxBenefit = taxBenefit
    }
}

/// Tax sections for deductions
public enum TaxSection: String, CaseIterable, Codable, Sendable {
    case section80C = "80C"
    case section80CCD1B = "80CCD(1B)"
    case section80D = "80D"
    case section80E = "80E"
    case section80G = "80G"
    case section24 = "24"
    
    public var displayName: String {
        switch self {
        case .section80C:
            return NSLocalizedString("tax_section_80c", comment: "Section 80C (₹1.5L)")
        case .section80CCD1B:
            return NSLocalizedString("tax_section_80ccd1b", comment: "Section 80CCD(1B) (₹50K NPS)")
        case .section80D:
            return NSLocalizedString("tax_section_80d", comment: "Section 80D (Health insurance)")
        case .section80E:
            return NSLocalizedString("tax_section_80e", comment: "Section 80E (Education loan)")
        case .section80G:
            return NSLocalizedString("tax_section_80g", comment: "Section 80G (Donations)")
        case .section24:
            return NSLocalizedString("tax_section_24", comment: "Section 24 (Home loan interest)")
        }
    }
    
    public var limit: Decimal {
        switch self {
        case .section80C: return 150000
        case .section80CCD1B: return 50000
        case .section80D: return 25000 // 25k for self, 50k if parents above 60
        case .section80E: return 0 // No limit
        case .section80G: return 0 // Varies by donation type
        case .section24: return 200000
        }
    }
}
