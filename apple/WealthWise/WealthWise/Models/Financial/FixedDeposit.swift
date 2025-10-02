//
//  FixedDeposit.swift
//  WealthWise
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - Fixed Deposit Management
//

import Foundation
import SwiftData

/// Comprehensive fixed deposit model with maturity tracking and interest calculations
/// Supports various fixed deposit types with automatic maturity alerts
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class FixedDeposit {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var depositName: String
    public var certificateNumber: String?
    public var bankName: String
    public var branchName: String?
    
    // MARK: - Deposit Details
    
    public var principalAmount: Decimal
    public var currency: String
    public var interestRate: Decimal // Annual interest rate as percentage
    public var compoundingFrequency: CompoundingFrequency
    
    // MARK: - Timeline
    
    public var depositDate: Date
    public var maturityDate: Date
    public var tenureInMonths: Int
    public var tenureInDays: Int
    
    // MARK: - Maturity Details
    
    public var maturityAmount: Decimal
    public var interestEarned: Decimal
    public var effectiveAnnualRate: Decimal
    public var isMatured: Bool
    public var actualMaturityDate: Date?
    
    // MARK: - Renewal and Preferences
    
    public var autoRenew: Bool
    public var renewalInstructions: RenewalInstructions
    public var interestPayoutMode: InterestPayoutMode
    public var nomineeDetails: String?
    
    // MARK: - Tax Details
    
    public var tdsApplicable: Bool
    public var tdsRate: Decimal
    public var tdsDeducted: Decimal
    public var panNumber: String?
    public var form15GSubmitted: Bool
    public var form15HSubmitted: Bool
    
    // MARK: - Deposit Type and Features
    
    public var depositType: FixedDepositType
    public var isPrematureWithdrawalAllowed: Bool
    public var penaltyOnPrematureWithdrawal: Decimal
    public var loanAgainstDeposit: Bool
    public var maxLoanPercentage: Decimal?
    
    // MARK: - Status and Tracking
    
    public var status: DepositStatus
    public var lastUpdated: Date
    public var createdAt: Date
    public var notes: String?
    public var tags: [String]
    
    // MARK: - Alerts
    
    public var maturityAlertDays: Int
    public var hasMaturityAlert: Bool
    public var alertSent: Bool
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify, inverse: \BankAccount.fixedDeposits) 
    public var linkedAccount: BankAccount?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        depositName: String,
        certificateNumber: String? = nil,
        bankName: String,
        branchName: String? = nil,
        principalAmount: Decimal,
        currency: String = "INR",
        interestRate: Decimal,
        compoundingFrequency: CompoundingFrequency = .quarterly,
        depositDate: Date = Date(),
        tenureInMonths: Int,
        depositType: FixedDepositType = .regular,
        autoRenew: Bool = false,
        interestPayoutMode: InterestPayoutMode = .onMaturity,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.depositName = depositName
        self.certificateNumber = certificateNumber
        self.bankName = bankName
        self.branchName = branchName
        self.principalAmount = principalAmount
        self.currency = currency
        self.interestRate = interestRate
        self.compoundingFrequency = compoundingFrequency
        self.depositDate = depositDate
        self.tenureInMonths = tenureInMonths
        self.depositType = depositType
        self.autoRenew = autoRenew
        self.interestPayoutMode = interestPayoutMode
        self.createdAt = createdAt
        self.lastUpdated = createdAt
        
        // Calculate maturity date
        let calendar = Calendar.current
        self.maturityDate = calendar.date(byAdding: .month, value: tenureInMonths, to: depositDate) ?? depositDate
        
        // Calculate days
        let components = calendar.dateComponents([.day], from: depositDate, to: maturityDate)
        self.tenureInDays = components.day ?? 0
        
        // Calculate maturity amount
        let years = Decimal(tenureInMonths) / 12
        let result = CompoundInterestCalculator.calculateCompoundInterest(
            principal: principalAmount,
            annualRate: interestRate / 100,
            timeInYears: years,
            compoundingFrequency: compoundingFrequency.toCalculatorFrequency()
        )
        
        self.maturityAmount = result.futureValue
        self.interestEarned = result.totalInterest
        self.effectiveAnnualRate = result.effectiveAnnualRate * 100
        
        // Initialize defaults
        self.isMatured = false
        self.status = .active
        self.renewalInstructions = .contactMe
        self.tdsApplicable = false
        self.tdsRate = 10
        self.tdsDeducted = 0
        self.form15GSubmitted = false
        self.form15HSubmitted = false
        self.isPrematureWithdrawalAllowed = true
        self.penaltyOnPrematureWithdrawal = 1.0
        self.loanAgainstDeposit = false
        self.tags = []
        self.maturityAlertDays = 30
        self.hasMaturityAlert = true
        self.alertSent = false
    }
    
    // MARK: - Computed Properties
    
    /// Days remaining until maturity
    public var daysToMaturity: Int {
        guard !isMatured else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: maturityDate)
        return max(components.day ?? 0, 0)
    }
    
    /// Whether maturity alert should be shown
    public var shouldShowMaturityAlert: Bool {
        return !isMatured && daysToMaturity <= maturityAlertDays && !alertSent
    }
    
    /// Display principal amount with formatting
    public var displayPrincipal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: principalAmount as NSDecimalNumber) ?? "\(principalAmount)"
    }
    
    /// Display maturity amount with formatting
    public var displayMaturityAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: maturityAmount as NSDecimalNumber) ?? "\(maturityAmount)"
    }
    
    /// Progress percentage (0-100)
    public var progressPercentage: Double {
        guard tenureInDays > 0 else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: depositDate, to: Date())
        let daysElapsed = components.day ?? 0
        return min(Double(daysElapsed) / Double(tenureInDays) * 100, 100)
    }
    
    /// Current value based on time elapsed
    public var currentValue: Decimal {
        guard !isMatured else { return maturityAmount }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: depositDate, to: Date())
        let daysElapsed = Decimal(components.day ?? 0)
        let years = daysElapsed / 365
        
        let result = CompoundInterestCalculator.calculateCompoundInterest(
            principal: principalAmount,
            annualRate: interestRate / 100,
            timeInYears: years,
            compoundingFrequency: compoundingFrequency.toCalculatorFrequency()
        )
        
        return result.futureValue
    }
    
    // MARK: - Methods
    
    /// Calculate premature withdrawal amount
    public func calculatePrematureWithdrawal(on date: Date = Date()) -> PrematureWithdrawalResult {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: depositDate, to: date)
        let daysElapsed = Decimal(components.day ?? 0)
        let years = daysElapsed / 365
        
        // Reduced interest rate for premature withdrawal
        let reducedRate = max(interestRate - penaltyOnPrematureWithdrawal, 0)
        
        let result = CompoundInterestCalculator.calculateCompoundInterest(
            principal: principalAmount,
            annualRate: reducedRate / 100,
            timeInYears: years,
            compoundingFrequency: compoundingFrequency.toCalculatorFrequency()
        )
        
        let penalty = (maturityAmount - result.futureValue) * (penaltyOnPrematureWithdrawal / 100)
        
        return PrematureWithdrawalResult(
            withdrawalAmount: result.futureValue,
            interestEarned: result.totalInterest,
            penaltyAmount: penalty,
            effectiveRate: reducedRate
        )
    }
    
    /// Mark deposit as matured
    public func markAsMatured() {
        self.isMatured = true
        self.status = .matured
        self.actualMaturityDate = Date()
        self.lastUpdated = Date()
    }
    
    /// Renew the fixed deposit
    public func renew(
        newPrincipal: Decimal? = nil,
        newInterestRate: Decimal? = nil,
        newTenure: Int? = nil
    ) {
        // Reset for renewal
        self.depositDate = Date()
        self.principalAmount = newPrincipal ?? self.maturityAmount
        self.interestRate = newInterestRate ?? self.interestRate
        self.tenureInMonths = newTenure ?? self.tenureInMonths
        
        // Recalculate maturity
        let calendar = Calendar.current
        self.maturityDate = calendar.date(byAdding: .month, value: tenureInMonths, to: depositDate) ?? depositDate
        
        let components = calendar.dateComponents([.day], from: depositDate, to: maturityDate)
        self.tenureInDays = components.day ?? 0
        
        let years = Decimal(tenureInMonths) / 12
        let result = CompoundInterestCalculator.calculateCompoundInterest(
            principal: principalAmount,
            annualRate: interestRate / 100,
            timeInYears: years,
            compoundingFrequency: compoundingFrequency.toCalculatorFrequency()
        )
        
        self.maturityAmount = result.futureValue
        self.interestEarned = result.totalInterest
        self.effectiveAnnualRate = result.effectiveAnnualRate * 100
        
        self.isMatured = false
        self.status = .active
        self.alertSent = false
        self.lastUpdated = Date()
    }
}

// MARK: - Supporting Types

/// Compounding frequency for fixed deposits
public enum CompoundingFrequency: String, CaseIterable, Codable, Hashable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case halfYearly = "half_yearly"
    case annually = "annually"
    
    public var displayName: String {
        switch self {
        case .monthly: return NSLocalizedString("compounding.monthly", comment: "Monthly")
        case .quarterly: return NSLocalizedString("compounding.quarterly", comment: "Quarterly")
        case .halfYearly: return NSLocalizedString("compounding.half_yearly", comment: "Half-yearly")
        case .annually: return NSLocalizedString("compounding.annually", comment: "Annually")
        }
    }
    
    func toCalculatorFrequency() -> CompoundInterestCalculator.CompoundingFrequency {
        switch self {
        case .monthly: return .monthly
        case .quarterly: return .quarterly
        case .halfYearly: return .semiAnnually
        case .annually: return .annually
        }
    }
}

/// Fixed deposit types
public enum FixedDepositType: String, CaseIterable, Codable, Hashable {
    case regular = "regular"
    case tax_saving = "tax_saving"
    case senior_citizen = "senior_citizen"
    case nri = "nri"
    case corporate = "corporate"
    case cumulative = "cumulative"
    case nonCumulative = "non_cumulative"
    
    public var displayName: String {
        switch self {
        case .regular: return NSLocalizedString("fd_type.regular", comment: "Regular FD")
        case .tax_saving: return NSLocalizedString("fd_type.tax_saving", comment: "Tax Saving FD")
        case .senior_citizen: return NSLocalizedString("fd_type.senior_citizen", comment: "Senior Citizen FD")
        case .nri: return NSLocalizedString("fd_type.nri", comment: "NRI FD")
        case .corporate: return NSLocalizedString("fd_type.corporate", comment: "Corporate FD")
        case .cumulative: return NSLocalizedString("fd_type.cumulative", comment: "Cumulative FD")
        case .nonCumulative: return NSLocalizedString("fd_type.non_cumulative", comment: "Non-Cumulative FD")
        }
    }
}

/// Deposit status
public enum DepositStatus: String, CaseIterable, Codable, Hashable {
    case active = "active"
    case matured = "matured"
    case closed = "closed"
    case withdrawn = "withdrawn"
    case suspended = "suspended"
    
    public var displayName: String {
        switch self {
        case .active: return NSLocalizedString("deposit_status.active", comment: "Active")
        case .matured: return NSLocalizedString("deposit_status.matured", comment: "Matured")
        case .closed: return NSLocalizedString("deposit_status.closed", comment: "Closed")
        case .withdrawn: return NSLocalizedString("deposit_status.withdrawn", comment: "Withdrawn")
        case .suspended: return NSLocalizedString("deposit_status.suspended", comment: "Suspended")
        }
    }
}

/// Renewal instructions
public enum RenewalInstructions: String, CaseIterable, Codable, Hashable {
    case autoRenew = "auto_renew"
    case renewPrincipal = "renew_principal"
    case renewAll = "renew_all"
    case contactMe = "contact_me"
    case doNotRenew = "do_not_renew"
    
    public var displayName: String {
        switch self {
        case .autoRenew: return NSLocalizedString("renewal.auto_renew", comment: "Auto-renew")
        case .renewPrincipal: return NSLocalizedString("renewal.renew_principal", comment: "Renew principal only")
        case .renewAll: return NSLocalizedString("renewal.renew_all", comment: "Renew with interest")
        case .contactMe: return NSLocalizedString("renewal.contact_me", comment: "Contact me")
        case .doNotRenew: return NSLocalizedString("renewal.do_not_renew", comment: "Do not renew")
        }
    }
}

/// Interest payout mode
public enum InterestPayoutMode: String, CaseIterable, Codable, Hashable {
    case onMaturity = "on_maturity"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case annually = "annually"
    case cumulative = "cumulative"
    
    public var displayName: String {
        switch self {
        case .onMaturity: return NSLocalizedString("payout.on_maturity", comment: "On maturity")
        case .monthly: return NSLocalizedString("payout.monthly", comment: "Monthly")
        case .quarterly: return NSLocalizedString("payout.quarterly", comment: "Quarterly")
        case .annually: return NSLocalizedString("payout.annually", comment: "Annually")
        case .cumulative: return NSLocalizedString("payout.cumulative", comment: "Cumulative")
        }
    }
}

/// Premature withdrawal calculation result
public struct PrematureWithdrawalResult {
    public let withdrawalAmount: Decimal
    public let interestEarned: Decimal
    public let penaltyAmount: Decimal
    public let effectiveRate: Decimal
    
    public var displayWithdrawalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale.current
        return formatter.string(from: withdrawalAmount as NSDecimalNumber) ?? "\(withdrawalAmount)"
    }
}
