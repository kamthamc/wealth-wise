//
//  CashHolding.swift
//  WealthWise
//
//  Created by GitHub Copilot on 2025-10-02.
//  Banking & Deposits Module - Multi-Currency Cash Management
//

import Foundation
import SwiftData

/// Multi-currency cash holdings tracking model
/// Supports physical cash, digital wallets, and foreign currency management
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class CashHolding {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var holdingType: CashHoldingType
    public var amount: Decimal
    public var currency: String
    
    // MARK: - Location and Storage
    
    public var location: CashLocation
    public var storageLocation: String?
    public var isAccessible: Bool
    
    // MARK: - Multi-Currency Details
    
    public var baseCurrency: String
    public var exchangeRate: Decimal?
    public var baseCurrencyAmount: Decimal
    public var lastExchangeRateUpdate: Date?
    
    // MARK: - Denomination Details (for physical cash)
    
    public var denominations: [CashDenomination]
    public var hasDenominationDetails: Bool
    
    // MARK: - Purpose and Classification
    
    public var purpose: CashPurpose
    public var isEmergencyFund: Bool
    public var targetEmergencyAmount: Decimal?
    
    // MARK: - Metadata
    
    public var createdAt: Date
    public var lastUpdated: Date
    public var lastVerified: Date?
    public var notes: String?
    public var tags: [String]
    
    // MARK: - Security
    
    public var isSecured: Bool
    public var securityMeasure: String?
    public var insuranceCovered: Bool
    public var insuranceAmount: Decimal?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        name: String,
        holdingType: CashHoldingType,
        amount: Decimal,
        currency: String = "INR",
        location: CashLocation = .wallet,
        baseCurrency: String = "INR",
        purpose: CashPurpose = .general,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.holdingType = holdingType
        self.amount = amount
        self.currency = currency
        self.location = location
        self.baseCurrency = baseCurrency
        self.purpose = purpose
        self.createdAt = createdAt
        self.lastUpdated = createdAt
        
        // Calculate base currency amount if different currency
        if currency == baseCurrency {
            self.baseCurrencyAmount = amount
        } else {
            // In real implementation, this would fetch exchange rate
            self.baseCurrencyAmount = amount
        }
        
        // Initialize defaults
        self.isAccessible = true
        self.denominations = []
        self.hasDenominationDetails = false
        self.isEmergencyFund = false
        self.tags = []
        self.isSecured = false
        self.insuranceCovered = false
    }
    
    // MARK: - Computed Properties
    
    /// Display amount with formatting
    public var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
    
    /// Display base currency amount
    public var displayBaseCurrencyAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = baseCurrency
        formatter.locale = Locale.current
        return formatter.string(from: baseCurrencyAmount as NSDecimalNumber) ?? "\(baseCurrencyAmount)"
    }
    
    /// Check if currency is foreign
    public var isForeignCurrency: Bool {
        return currency != baseCurrency
    }
    
    /// Total value of all denominations
    public var denominationTotal: Decimal {
        return denominations.reduce(0) { total, denomination in
            total + (denomination.value * Decimal(denomination.count))
        }
    }
    
    /// Check if denomination details match amount
    public var isDenominationConsistent: Bool {
        guard hasDenominationDetails else { return true }
        return abs(denominationTotal - amount) < 0.01
    }
    
    // MARK: - Methods
    
    /// Update amount and recalculate base currency
    public func updateAmount(_ newAmount: Decimal, exchangeRate: Decimal? = nil) {
        self.amount = newAmount
        
        if let rate = exchangeRate {
            self.exchangeRate = rate
            self.baseCurrencyAmount = newAmount * rate
            self.lastExchangeRateUpdate = Date()
        } else if currency == baseCurrency {
            self.baseCurrencyAmount = newAmount
        }
        
        self.lastUpdated = Date()
    }
    
    /// Add denomination
    public func addDenomination(value: Decimal, count: Int) {
        if let index = denominations.firstIndex(where: { $0.value == value }) {
            denominations[index].count += count
        } else {
            denominations.append(CashDenomination(value: value, count: count))
        }
        
        hasDenominationDetails = true
        lastUpdated = Date()
    }
    
    /// Verify and mark as verified
    public func verifyHolding() {
        self.lastVerified = Date()
        self.lastUpdated = Date()
    }
    
    /// Convert to different currency
    public func convertToCurrency(_ targetCurrency: String, rate: Decimal) -> Decimal {
        if currency == targetCurrency {
            return amount
        }
        
        // Convert to base currency first, then to target
        let baseAmount = baseCurrencyAmount
        return baseAmount * rate
    }
}

// MARK: - Supporting Types

/// Cash holding types
public enum CashHoldingType: String, CaseIterable, Codable, Hashable {
    case physical = "physical"
    case wallet = "wallet"
    case safe = "safe"
    case locker = "locker"
    case emergency = "emergency"
    case foreign = "foreign"
    case petty = "petty"
    
    public var displayName: String {
        switch self {
        case .physical: return NSLocalizedString("cash_type.physical", comment: "Physical cash")
        case .wallet: return NSLocalizedString("cash_type.wallet", comment: "Wallet")
        case .safe: return NSLocalizedString("cash_type.safe", comment: "Home safe")
        case .locker: return NSLocalizedString("cash_type.locker", comment: "Bank locker")
        case .emergency: return NSLocalizedString("cash_type.emergency", comment: "Emergency fund")
        case .foreign: return NSLocalizedString("cash_type.foreign", comment: "Foreign currency")
        case .petty: return NSLocalizedString("cash_type.petty", comment: "Petty cash")
        }
    }
}

/// Cash storage location
public enum CashLocation: String, CaseIterable, Codable, Hashable {
    case wallet = "wallet"
    case home = "home"
    case safe = "safe"
    case locker = "locker"
    case office = "office"
    case vehicle = "vehicle"
    case travel = "travel"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .wallet: return NSLocalizedString("location.wallet", comment: "Wallet")
        case .home: return NSLocalizedString("location.home", comment: "Home")
        case .safe: return NSLocalizedString("location.safe", comment: "Safe")
        case .locker: return NSLocalizedString("location.locker", comment: "Bank locker")
        case .office: return NSLocalizedString("location.office", comment: "Office")
        case .vehicle: return NSLocalizedString("location.vehicle", comment: "Vehicle")
        case .travel: return NSLocalizedString("location.travel", comment: "Travel")
        case .other: return NSLocalizedString("location.other", comment: "Other")
        }
    }
    
    public var securityLevel: Int {
        switch self {
        case .locker: return 5
        case .safe: return 4
        case .home: return 3
        case .office: return 3
        case .wallet: return 2
        case .vehicle: return 1
        case .travel: return 1
        case .other: return 2
        }
    }
}

/// Cash purpose
public enum CashPurpose: String, CaseIterable, Codable, Hashable {
    case general = "general"
    case emergency = "emergency"
    case travel = "travel"
    case business = "business"
    case petty = "petty"
    case savings = "savings"
    case specific = "specific"
    
    public var displayName: String {
        switch self {
        case .general: return NSLocalizedString("purpose.general", comment: "General expenses")
        case .emergency: return NSLocalizedString("purpose.emergency", comment: "Emergency fund")
        case .travel: return NSLocalizedString("purpose.travel", comment: "Travel expenses")
        case .business: return NSLocalizedString("purpose.business", comment: "Business expenses")
        case .petty: return NSLocalizedString("purpose.petty", comment: "Petty expenses")
        case .savings: return NSLocalizedString("purpose.savings", comment: "Savings")
        case .specific: return NSLocalizedString("purpose.specific", comment: "Specific purpose")
        }
    }
}

/// Cash denomination structure (for physical cash tracking)
public struct CashDenomination: Codable, Hashable, Identifiable {
    public var id: UUID
    public var value: Decimal
    public var count: Int
    public var currency: String
    
    public init(id: UUID = UUID(), value: Decimal, count: Int, currency: String = "INR") {
        self.id = id
        self.value = value
        self.count = count
        self.currency = currency
    }
    
    public var total: Decimal {
        return value * Decimal(count)
    }
    
    public var displayTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: total as NSDecimalNumber) ?? "\(total)"
    }
}
