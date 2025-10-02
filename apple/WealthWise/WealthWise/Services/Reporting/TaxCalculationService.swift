//
//  TaxCalculationService.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-10-02.
//  Reporting & Insights Engine - Tax Calculation Service
//

import Foundation
import SwiftData

/// Service for calculating tax obligations from transactions and investments
@available(iOS 18.6, macOS 15.6, *)
@MainActor
public final class TaxCalculationService {
    
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Tax Calculation Methods
    
    /// Calculate comprehensive tax for a financial year
    public func calculateTax(
        for financialYear: String,
        transactions: [Transaction]
    ) async throws -> TaxCalculation {
        
        // Filter transactions for the financial year
        let fyTransactions = filterTransactionsForFinancialYear(transactions, year: financialYear)
        
        // Calculate capital gains
        let capitalGainsBreakdown = calculateCapitalGains(from: fyTransactions)
        let shortTermGains = capitalGainsBreakdown.filter { !$0.isLongTerm }.reduce(Decimal.zero) { $0 + $1.capitalGain }
        let longTermGains = capitalGainsBreakdown.filter { $0.isLongTerm }.reduce(Decimal.zero) { $0 + $1.capitalGain }
        
        // Calculate dividend income
        let dividendBreakdown = calculateDividendIncome(from: fyTransactions)
        let totalDividend = dividendBreakdown.reduce(Decimal.zero) { $0 + $1.dividendAmount }
        
        // Calculate interest income
        let interestBreakdown = calculateInterestIncome(from: fyTransactions)
        let totalInterest = interestBreakdown.reduce(Decimal.zero) { $0 + $1.interestAmount }
        
        // Calculate deductions
        let section80C = calculate80CDeductions(from: fyTransactions)
        let section80D = calculate80DDeductions(from: fyTransactions)
        
        // Create tax calculation
        let taxCalc = TaxCalculation(
            financialYear: financialYear,
            shortTermCapitalGains: shortTermGains,
            longTermCapitalGains: longTermGains,
            totalDividendIncome: totalDividend,
            totalInterestIncome: totalInterest
        )
        
        // Set deductions
        taxCalc.section80CDeductions = section80C
        taxCalc.section80DDeductions = section80D
        taxCalc.totalDeductions = section80C + section80D
        
        // Calculate taxable income
        taxCalc.taxableIncome = taxCalc.grossIncome - taxCalc.totalDeductions
        
        // Calculate tax owed (simplified - using 30% bracket for demo)
        taxCalc.taxOwed = calculateTaxOwed(taxableIncome: taxCalc.taxableIncome)
        
        // Calculate TDS and advance tax paid
        let tdsPaid = fyTransactions
            .filter { $0.tdsAmount != nil }
            .reduce(Decimal.zero) { $0 + ($1.tdsAmount ?? 0) }
        taxCalc.taxPaid = tdsPaid
        
        // Calculate refund or additional tax due
        if taxCalc.taxPaid > taxCalc.taxOwed {
            taxCalc.refundDue = taxCalc.taxPaid - taxCalc.taxOwed
            taxCalc.additionalTaxDue = 0
        } else {
            taxCalc.additionalTaxDue = taxCalc.taxOwed - taxCalc.taxPaid
            taxCalc.refundDue = 0
        }
        
        taxCalc.updatedAt = Date()
        
        // Save to model context
        modelContext.insert(taxCalc)
        try modelContext.save()
        
        return taxCalc
    }
    
    /// Calculate capital gains from transactions
    public func calculateCapitalGains(from transactions: [Transaction]) -> [CapitalGainsBreakdown] {
        var breakdowns: [CapitalGainsBreakdown] = []
        
        // Filter investment transactions with gains
        let investmentTransactions = transactions.filter { 
            $0.transactionType == .capital_gain || $0.transactionType == .capital_loss 
        }
        
        for transaction in investmentTransactions {
            guard let assetId = transaction.assetId,
                  let units = transaction.units,
                  let pricePerUnit = transaction.pricePerUnit else {
                continue
            }
            
            // For simplicity, using transaction date as both purchase and sale
            // In real implementation, would track actual purchase date
            let purchaseDate = Calendar.current.date(byAdding: .year, value: -1, to: transaction.date) ?? transaction.date
            let purchasePrice = pricePerUnit * units
            let salePrice = transaction.amount
            
            let breakdown = CapitalGainsBreakdown(
                assetName: assetId,
                assetType: transaction.category.rawValue,
                purchaseDate: purchaseDate,
                saleDate: transaction.date,
                purchasePrice: purchasePrice,
                salePrice: salePrice
            )
            
            breakdowns.append(breakdown)
        }
        
        return breakdowns
    }
    
    /// Calculate dividend income from transactions
    public func calculateDividendIncome(from transactions: [Transaction]) -> [DividendIncomeBreakdown] {
        var breakdowns: [DividendIncomeBreakdown] = []
        
        let dividendTransactions = transactions.filter { $0.transactionType == .dividend }
        
        for transaction in dividendTransactions {
            let breakdown = DividendIncomeBreakdown(
                assetName: transaction.assetId ?? transaction.transactionDescription,
                dividendDate: transaction.date,
                dividendAmount: transaction.amount,
                tdsDeducted: transaction.tdsAmount ?? 0
            )
            breakdowns.append(breakdown)
        }
        
        return breakdowns
    }
    
    /// Calculate interest income from transactions
    public func calculateInterestIncome(from transactions: [Transaction]) -> [InterestIncomeBreakdown] {
        var breakdowns: [InterestIncomeBreakdown] = []
        
        let interestTransactions = transactions.filter { $0.transactionType == .interest }
        
        for transaction in interestTransactions {
            // Determine source type from category
            let sourceType: InterestSourceType
            switch transaction.category {
            case .bonds:
                sourceType = .bonds
            case .mutual_funds:
                sourceType = .debtMutualFunds
            default:
                sourceType = .savingsAccount
            }
            
            let breakdown = InterestIncomeBreakdown(
                sourceName: transaction.transactionDescription,
                sourceType: sourceType,
                interestAmount: transaction.amount,
                tdsDeducted: transaction.tdsAmount ?? 0,
                periodStart: transaction.date,
                periodEnd: transaction.date
            )
            breakdowns.append(breakdown)
        }
        
        return breakdowns
    }
    
    // MARK: - Deduction Calculations
    
    /// Calculate 80C deductions from tax-saving investments
    private func calculate80CDeductions(from transactions: [Transaction]) -> Decimal {
        let taxSavingTransactions = transactions.filter { 
            $0.category == .tax_saving_investment || $0.category == .life_insurance
        }
        
        let total = taxSavingTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        return min(total, 150000) // 80C limit is ₹1.5 lakh
    }
    
    /// Calculate 80D deductions from health insurance
    private func calculate80DDeductions(from transactions: [Transaction]) -> Decimal {
        let healthInsuranceTransactions = transactions.filter { 
            $0.category == .health_insurance
        }
        
        let total = healthInsuranceTransactions.reduce(Decimal.zero) { $0 + $1.amount }
        return min(total, 25000) // 80D limit is ₹25k for self (simplified)
    }
    
    // MARK: - Helper Methods
    
    /// Filter transactions for a specific financial year
    private func filterTransactionsForFinancialYear(_ transactions: [Transaction], year: String) -> [Transaction] {
        // Parse financial year (e.g., "2024-25")
        let components = year.split(separator: "-")
        guard components.count == 2,
              let startYear = Int(components[0]) else {
            return []
        }
        
        let calendar = Calendar.current
        
        // Financial year in India: April 1 to March 31
        var startComponents = DateComponents()
        startComponents.year = startYear
        startComponents.month = 4
        startComponents.day = 1
        
        var endComponents = DateComponents()
        endComponents.year = startYear + 1
        endComponents.month = 3
        endComponents.day = 31
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return []
        }
        
        return transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
    }
    
    /// Calculate tax owed based on taxable income (simplified)
    private func calculateTaxOwed(taxableIncome: Decimal) -> Decimal {
        // Simplified tax calculation using new tax regime slabs
        var tax: Decimal = 0
        
        if taxableIncome > 300000 {
            tax += min(taxableIncome - 300000, 300000) * 0.05 // 5% for 3L-6L
        }
        if taxableIncome > 600000 {
            tax += min(taxableIncome - 600000, 300000) * 0.10 // 10% for 6L-9L
        }
        if taxableIncome > 900000 {
            tax += min(taxableIncome - 900000, 300000) * 0.15 // 15% for 9L-12L
        }
        if taxableIncome > 1200000 {
            tax += min(taxableIncome - 1200000, 300000) * 0.20 // 20% for 12L-15L
        }
        if taxableIncome > 1500000 {
            tax += (taxableIncome - 1500000) * 0.30 // 30% above 15L
        }
        
        // Add cess (4% on tax)
        tax += tax * 0.04
        
        return tax
    }
    
    /// Get current financial year
    public func getCurrentFinancialYear() -> String {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        
        if month >= 4 {
            return "\(year)-\(String(year + 1).suffix(2))"
        } else {
            return "\(year - 1)-\(String(year).suffix(2))"
        }
    }
}
