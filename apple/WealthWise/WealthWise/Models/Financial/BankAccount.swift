//
//  BankAccount.swift
//  WealthWise
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - Bank Account Management
//

import Foundation
import SwiftData

/// Comprehensive bank account model supporting savings, current, and salary accounts
/// Provides balance tracking, interest calculation, and transaction management
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class BankAccount {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var accountName: String
    public var accountNumber: String
    public var accountType: BankAccountType
    public var bankName: String
    public var branchName: String?
    public var ifscCode: String?
    
    // MARK: - Balance Properties
    
    public var currentBalance: Decimal
    public var availableBalance: Decimal
    public var currency: String
    public var minimumBalance: Decimal
    public var overdraftLimit: Decimal?
    
    // MARK: - Interest Properties
    
    public var interestRate: Decimal // Annual interest rate as percentage
    public var interestCalculationType: InterestCalculationType
    public var lastInterestCreditDate: Date?
    public var totalInterestEarned: Decimal
    
    // MARK: - Account Status
    
    public var isActive: Bool
    public var isPrimary: Bool
    public var openingDate: Date
    public var closingDate: Date?
    public var lastTransactionDate: Date?
    
    // MARK: - Multi-Currency Support
    
    public var baseCurrency: String
    public var supportedCurrencies: [String]
    public var isMultiCurrency: Bool
    
    // MARK: - Compliance and Tax
    
    public var panNumber: String?
    public var taxResidencyCountry: String
    public var isTaxable: Bool
    public var tdsApplicable: Bool
    
    // MARK: - Account Holder Information
    
    public var accountHolderName: String
    public var accountHolderType: AccountHolderType
    public var isJointAccount: Bool
    public var jointHolderNames: [String]
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var updatedAt: Date
    public var notes: String?
    public var tags: [String]
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .cascade) public var transactions: [Transaction]?
    @Relationship(deleteRule: .cascade) public var fixedDeposits: [FixedDeposit]?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        accountName: String,
        accountNumber: String,
        accountType: BankAccountType,
        bankName: String,
        branchName: String? = nil,
        ifscCode: String? = nil,
        currentBalance: Decimal = 0,
        currency: String = "INR",
        minimumBalance: Decimal = 0,
        interestRate: Decimal = 3.5,
        interestCalculationType: InterestCalculationType = .compound,
        accountHolderName: String,
        accountHolderType: AccountHolderType = .individual,
        taxResidencyCountry: String = "IND",
        openingDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.accountName = accountName
        self.accountNumber = accountNumber
        self.accountType = accountType
        self.bankName = bankName
        self.branchName = branchName
        self.ifscCode = ifscCode
        self.currentBalance = currentBalance
        self.availableBalance = currentBalance
        self.currency = currency
        self.minimumBalance = minimumBalance
        self.interestRate = interestRate
        self.interestCalculationType = interestCalculationType
        self.accountHolderName = accountHolderName
        self.accountHolderType = accountHolderType
        self.taxResidencyCountry = taxResidencyCountry
        self.openingDate = openingDate
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize defaults
        self.totalInterestEarned = 0
        self.isActive = true
        self.isPrimary = false
        self.baseCurrency = currency
        self.supportedCurrencies = [currency]
        self.isMultiCurrency = false
        self.isTaxable = true
        self.tdsApplicable = false
        self.isJointAccount = false
        self.jointHolderNames = []
        self.tags = []
    }
    
    // MARK: - Computed Properties
    
    /// Display balance with proper formatting
    public var displayBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: currentBalance as NSDecimalNumber) ?? "\(currentBalance)"
    }
    
    /// Check if account is below minimum balance
    public var isBelowMinimumBalance: Bool {
        return currentBalance < minimumBalance
    }
    
    /// Available balance considering overdraft
    public var totalAvailableBalance: Decimal {
        let overdraft = overdraftLimit ?? 0
        return availableBalance + overdraft
    }
    
    /// Number of days account has been active
    public var daysActive: Int {
        let calendar = Calendar.current
        let endDate = closingDate ?? Date()
        return calendar.dateComponents([.day], from: openingDate, to: endDate).day ?? 0
    }
    
    /// Average balance (simplified calculation)
    public func calculateAverageBalance(forPeriod days: Int = 30) -> Decimal {
        // In a full implementation, this would calculate from transaction history
        return currentBalance
    }
    
    /// Calculate interest earned for a period
    public func calculateInterestEarned(
        forBalance balance: Decimal? = nil,
        days: Int = 365
    ) -> Decimal {
        let principal = balance ?? currentBalance
        let annualRate = interestRate / 100
        
        switch interestCalculationType {
        case .simple:
            // Simple Interest: I = P * R * T
            let years = Decimal(days) / 365
            return principal * annualRate * years
            
        case .compound:
            // Compound Interest: A = P(1 + r)^t
            let years = Decimal(days) / 365
            let result = CompoundInterestCalculator.calculateCompoundInterest(
                principal: principal,
                annualRate: annualRate,
                timeInYears: years,
                compoundingFrequency: .quarterly
            )
            return result.totalInterest
        }
    }
    
    /// Update balance
    public func updateBalance(newBalance: Decimal) {
        self.currentBalance = newBalance
        self.availableBalance = newBalance
        self.lastTransactionDate = Date()
        self.updatedAt = Date()
    }
    
    /// Add interest to account
    public func creditInterest(amount: Decimal) {
        self.currentBalance += amount
        self.availableBalance += amount
        self.totalInterestEarned += amount
        self.lastInterestCreditDate = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supporting Enums

/// Bank account types supported
public enum BankAccountType: String, CaseIterable, Codable, Hashable {
    case savings = "savings"
    case current = "current"
    case salary = "salary"
    case fixedDeposit = "fixed_deposit"
    case recurringDeposit = "recurring_deposit"
    case nri = "nri"
    case foreign = "foreign"
    
    public var displayName: String {
        switch self {
        case .savings: return NSLocalizedString("account_type.savings", comment: "Savings account")
        case .current: return NSLocalizedString("account_type.current", comment: "Current account")
        case .salary: return NSLocalizedString("account_type.salary", comment: "Salary account")
        case .fixedDeposit: return NSLocalizedString("account_type.fixed_deposit", comment: "Fixed deposit")
        case .recurringDeposit: return NSLocalizedString("account_type.recurring_deposit", comment: "Recurring deposit")
        case .nri: return NSLocalizedString("account_type.nri", comment: "NRI account")
        case .foreign: return NSLocalizedString("account_type.foreign", comment: "Foreign account")
        }
    }
    
    public var defaultMinimumBalance: Decimal {
        switch self {
        case .savings: return 1000
        case .salary: return 0
        case .current: return 5000
        case .nri: return 10000
        case .fixedDeposit, .recurringDeposit: return 0
        case .foreign: return 0
        }
    }
    
    public var defaultInterestRate: Decimal {
        switch self {
        case .savings: return 3.5
        case .salary: return 3.5
        case .current: return 0
        case .fixedDeposit: return 6.5
        case .recurringDeposit: return 6.0
        case .nri: return 4.0
        case .foreign: return 0.5
        }
    }
}

/// Interest calculation method
public enum InterestCalculationType: String, CaseIterable, Codable, Hashable {
    case simple = "simple"
    case compound = "compound"
    
    public var displayName: String {
        switch self {
        case .simple: return NSLocalizedString("interest_type.simple", comment: "Simple interest")
        case .compound: return NSLocalizedString("interest_type.compound", comment: "Compound interest")
        }
    }
}

/// Account holder type
public enum AccountHolderType: String, CaseIterable, Codable, Hashable {
    case individual = "individual"
    case joint = "joint"
    case minor = "minor"
    case corporate = "corporate"
    case trust = "trust"
    case partnership = "partnership"
    
    public var displayName: String {
        switch self {
        case .individual: return NSLocalizedString("holder_type.individual", comment: "Individual")
        case .joint: return NSLocalizedString("holder_type.joint", comment: "Joint")
        case .minor: return NSLocalizedString("holder_type.minor", comment: "Minor")
        case .corporate: return NSLocalizedString("holder_type.corporate", comment: "Corporate")
        case .trust: return NSLocalizedString("holder_type.trust", comment: "Trust")
        case .partnership: return NSLocalizedString("holder_type.partnership", comment: "Partnership")
        }
    }
}
