//
//  Transaction.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-09-27.
//  Financial Models Foundation - Transaction Management System
//

import Foundation
import SwiftData

/// Comprehensive transaction model supporting multi-currency transactions with advanced categorization
/// Handles cross-border transactions, tax implications, and investment tracking
@available(iOS 18.6, macOS 15.6, *)
@Model
public final class Transaction {
    
    // MARK: - Primary Properties
    
    @Attribute(.unique) public var id: UUID
    public var amount: Decimal
    public var currency: String
    public var transactionDescription: String
    public var notes: String?
    
    // MARK: - Transaction Details
    
    public var date: Date
    public var valueDate: Date? // For cross-border transactions
    public var transactionType: TransactionType
    public var category: TransactionCategory
    public var subcategory: String?
    
    // MARK: - Account Information
    
    public var accountId: String? // Reference to account
    public var counterpartyAccount: String?
    public var counterpartyName: String?
    public var accountType: AccountType
    
    // MARK: - Multi-Currency Support
    
    public var originalAmount: Decimal? // Original amount in foreign currency
    public var originalCurrency: String? // Original currency code
    public var exchangeRate: Decimal? // Exchange rate used
    public var baseCurrencyAmount: Decimal // Amount in base currency (INR)
    
    // MARK: - Status and Metadata
    
    public var status: TransactionStatus
    public var isRecurring: Bool
    public var recurringPattern: RecurringPattern?
    public var createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Tax and Compliance
    
    public var isTaxable: Bool
    public var taxCategory: TaxCategory?
    public var taxAmount: Decimal?
    public var tdsAmount: Decimal? // Tax Deducted at Source
    public var taxResidencyCountry: String?
    
    // MARK: - Investment Tracking
    
    public var assetId: String? // Linked asset ID
    public var units: Decimal? // For investment transactions
    public var pricePerUnit: Decimal? // NAV or share price
    public var portfolioWeight: Decimal? // Percentage of portfolio
    
    // MARK: - Location and Source
    
    public var location: TransactionLocation?
    public var source: TransactionSource
    public var referenceNumber: String?
    public var merchantName: String?
    public var merchantCategory: String?
    
    // MARK: - Tags and Classification
    
    public var tags: [String]
    public var isInvestment: Bool
    public var isIncome: Bool
    public var isExpense: Bool
    public var isTransfer: Bool
    
    // MARK: - Relationships
    
    @Relationship(deleteRule: .nullify) public var linkedGoal: Goal?
    @Relationship(deleteRule: .cascade) public var attachments: [TransactionAttachment]?
    
    // MARK: - Initialization
    
    public init(
        id: UUID = UUID(),
        amount: Decimal,
        currency: String = "INR",
        transactionDescription: String,
        notes: String? = nil,
        date: Date = Date(),
        transactionType: TransactionType,
        category: TransactionCategory,
        subcategory: String? = nil,
        accountType: AccountType = .bank,
        status: TransactionStatus = .completed,
        source: TransactionSource = .manual,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.transactionDescription = transactionDescription
        self.notes = notes
        self.date = date
        self.transactionType = transactionType
        self.category = category
        self.subcategory = subcategory
        self.accountType = accountType
        self.status = status
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = createdAt
        
        // Initialize currency fields
        self.baseCurrencyAmount = amount // Will be converted if needed
        
        // Initialize flags
        self.isRecurring = false
        self.isTaxable = false
        self.tags = []
        
        // Set transaction type flags
        self.isIncome = transactionType == .income
        self.isExpense = transactionType == .expense
        self.isInvestment = transactionType == .investment
        self.isTransfer = transactionType == .transfer
    }
    
    // MARK: - Computed Properties
    
    /// Display amount with proper formatting
    public var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
    
    /// Tax efficiency score (0-100)
    public var taxEfficiencyScore: Double {
        guard isTaxable else { return 100 }
        
        let effectiveTaxRate = calculateEffectiveTaxRate()
        if effectiveTaxRate <= 0.10 { return 95 } // LTCG, tax-free bonds
        if effectiveTaxRate <= 0.20 { return 80 } // ELSS, PPF
        if effectiveTaxRate <= 0.30 { return 60 } // Regular income
        return 30 // High tax items
    }
    
    /// Whether transaction involves foreign exchange
    public var isCrossBorder: Bool {
        return originalCurrency != nil && originalCurrency != currency
    }
    
    /// Whether transaction is eligible for tax deduction
    public var isTaxDeductible: Bool {
        switch category {
        case .tax_saving_investment, .health_insurance, .life_insurance, .home_loan_emi:
            return true
        case .education:
            return subcategory == "tuition_fees" || subcategory == "education_loan_interest"
        case .medical:
            return amount >= 50000 // Medical expenses above 50k eligible
        default:
            return false
        }
    }
    
    /// Investment return percentage (for investment transactions)
    public var returnPercentage: Decimal? {
        guard isInvestment,
              let units = units,
              let purchasePrice = pricePerUnit,
              units > 0, purchasePrice > 0 else { return nil }
        
        let currentValue = amount // Assuming amount is current value
        let investedValue = units * purchasePrice
        guard investedValue > 0 else { return nil }
        
        return ((currentValue - investedValue) / investedValue) * 100
    }
    
    /// Month-year key for grouping
    public var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
    
    /// Financial quarter
    public var quarter: String {
        let month = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: date)
        let quarter = (month - 1) / 3 + 1
        return "Q\(quarter)-\(year)"
    }
    
    // MARK: - Business Logic Methods
    
    /// Convert amount to base currency (INR)
    public func convertToBaseCurrency(using exchangeRate: Decimal) {
        guard isCrossBorder else { return }
        
        self.exchangeRate = exchangeRate
        self.baseCurrencyAmount = amount * exchangeRate
        self.updatedAt = Date()
    }
    
    /// Add tax information
    public func addTaxInformation(
        taxCategory: TaxCategory,
        taxAmount: Decimal,
        tdsAmount: Decimal? = nil,
        taxResidencyCountry: String = "IN"
    ) {
        self.isTaxable = true
        self.taxCategory = taxCategory
        self.taxAmount = taxAmount
        self.tdsAmount = tdsAmount
        self.taxResidencyCountry = taxResidencyCountry
        self.updatedAt = Date()
    }
    
    /// Link to investment asset
    public func linkToAsset(assetId: String, units: Decimal, pricePerUnit: Decimal) {
        self.assetId = assetId
        self.units = units
        self.pricePerUnit = pricePerUnit
        self.isInvestment = true
        self.updatedAt = Date()
    }
    
    /// Add recurring pattern
    public func setRecurring(pattern: RecurringPattern) {
        self.isRecurring = true
        self.recurringPattern = pattern
        self.updatedAt = Date()
    }
    
    /// Add transaction tags
    public func addTags(_ newTags: [String]) {
        for tag in newTags {
            if !tags.contains(tag) {
                tags.append(tag)
            }
        }
        self.updatedAt = Date()
    }
    
    /// Update transaction status
    public func updateStatus(_ newStatus: TransactionStatus) {
        self.status = newStatus
        self.updatedAt = Date()
    }
    
    /// Calculate effective tax rate
    private func calculateEffectiveTaxRate() -> Decimal {
        guard let taxAmount = taxAmount, amount > 0 else { return 0 }
        return taxAmount / amount
    }
    
    /// Get tax saving potential
    @MainActor
    public func getTaxSavingPotential() -> TaxSavingPotential? {
        guard isTaxDeductible else { return nil }
        
        let deductionLimit = getDeductionLimit()
        let savingPercentage = getTaxBracketRate()
        let potentialSaving = min(amount, deductionLimit) * savingPercentage
        
        return TaxSavingPotential(
            deductibleAmount: min(amount, deductionLimit),
            taxSaving: potentialSaving,
            section: getTaxSection(),
            description: getTaxSavingDescription()
        )
    }
    
    /// Get applicable deduction limit
    private func getDeductionLimit() -> Decimal {
        switch category {
        case .tax_saving_investment: return 150000 // 80C limit
        case .health_insurance: return 25000 // 80D limit for self
        case .life_insurance: return 150000 // Part of 80C
        case .home_loan_emi: return 200000 // 80C principal + 24 interest
        case .education: return 150000 // 80E education loan interest
        case .medical: return 50000 // 80DDB medical expenses
        default: return 0
        }
    }
    
    /// Get tax bracket rate based on user's income bracket
    /// TODO: This should be calculated based on user's actual income and tax jurisdiction
    /// For now, using conservative estimate for high-income bracket
    private func getTaxBracketRate() -> Decimal {
        // This is a placeholder implementation - should be replaced with proper tax calculation
        // when Tax Calculation Service (Issue #29) is implemented
        return getUserTaxBracket() // Will be implemented in future tax service integration
    }
    
    /// Get user's applicable tax bracket (placeholder for future tax service integration)
    private func getUserTaxBracket() -> Decimal {
        // Conservative estimate for demonstration purposes
        // Will be replaced with actual user tax bracket calculation
        return 0.30 // 30% bracket for high earners
    }
    
    /// Get applicable tax section
    private func getTaxSection() -> String {
        switch category {
        case .tax_saving_investment: return "80C"
        case .health_insurance: return "80D"
        case .life_insurance: return "80C"
        case .home_loan_emi: return "80C/24"
        case .education: return "80E"
        case .medical: return "80DDB"
        default: return "N/A"
        }
    }
    
    /// Get tax saving description
    private func getTaxSavingDescription() -> String {
        switch category {
        case .tax_saving_investment:
            return NSLocalizedString("tax_saving_80c_desc", comment: "Tax saving investment under section 80C")
        case .health_insurance:
            return NSLocalizedString("tax_saving_80d_desc", comment: "Health insurance premium under section 80D")
        case .home_loan_emi:
            return NSLocalizedString("tax_saving_home_loan_desc", comment: "Home loan EMI tax benefits")
        default:
            return NSLocalizedString("tax_saving_general_desc", comment: "General tax saving benefit")
        }
    }
}

// MARK: - Supporting Types

/// Transaction type enumeration
public enum TransactionType: String, CaseIterable, Codable, Sendable {
    case income = "income"
    case expense = "expense"
    case investment = "investment"
    case transfer = "transfer"
    case refund = "refund"
    case dividend = "dividend"
    case interest = "interest"
    case capital_gain = "capital_gain"
    case capital_loss = "capital_loss"
    
    public var displayName: String {
        switch self {
        case .income:
            return NSLocalizedString("transaction_type_income", comment: "Income transaction type")
        case .expense:
            return NSLocalizedString("transaction_type_expense", comment: "Expense transaction type")
        case .investment:
            return NSLocalizedString("transaction_type_investment", comment: "Investment transaction type")
        case .transfer:
            return NSLocalizedString("transaction_type_transfer", comment: "Transfer transaction type")
        case .refund:
            return NSLocalizedString("transaction_type_refund", comment: "Refund transaction type")
        case .dividend:
            return NSLocalizedString("transaction_type_dividend", comment: "Dividend transaction type")
        case .interest:
            return NSLocalizedString("transaction_type_interest", comment: "Interest transaction type")
        case .capital_gain:
            return NSLocalizedString("transaction_type_capital_gain", comment: "Capital gain transaction type")
        case .capital_loss:
            return NSLocalizedString("transaction_type_capital_loss", comment: "Capital loss transaction type")
        }
    }
    
    public var isPositive: Bool {
        switch self {
        case .income, .refund, .dividend, .interest, .capital_gain:
            return true
        case .expense, .investment, .transfer, .capital_loss:
            return false
        }
    }
    
    public var systemImageName: String {
        switch self {
        case .income:
            return "plus.circle.fill"
        case .expense:
            return "minus.circle.fill"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        case .transfer:
            return "arrow.left.arrow.right"
        case .refund:
            return "arrow.counterclockwise.circle.fill"
        case .dividend:
            return "percent.circle.fill"
        case .interest:
            return "banknote.fill"
        case .capital_gain:
            return "arrow.up.circle.fill"
        case .capital_loss:
            return "arrow.down.circle.fill"
        }
    }
}

/// Transaction category for detailed classification
public enum TransactionCategory: String, CaseIterable, Codable, Sendable {
    // Income categories
    case salary = "salary"
    case bonus = "bonus"
    case freelance = "freelance"
    case business_income = "business_income"
    case rental_income = "rental_income"
    case dividend_income = "dividend_income"
    case interest_income = "interest_income"
    case capital_gains = "capital_gains"
    
    // Expense categories
    case food_dining = "food_dining"
    case transportation = "transportation"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case utilities = "utilities"
    case medical = "medical"
    case education = "education"
    case travel = "travel"
    case home_maintenance = "home_maintenance"
    case personal_care = "personal_care"
    
    // Investment categories
    case mutual_funds = "mutual_funds"
    case stocks = "stocks"
    case bonds = "bonds"
    case real_estate = "real_estate"
    case gold = "gold"
    case crypto = "crypto"
    case tax_saving_investment = "tax_saving_investment"
    case retirement_fund = "retirement_fund"
    
    // Insurance and Protection
    case life_insurance = "life_insurance"
    case health_insurance = "health_insurance"
    case vehicle_insurance = "vehicle_insurance"
    case home_insurance = "home_insurance"
    
    // Loans and EMIs
    case home_loan_emi = "home_loan_emi"
    case car_loan_emi = "car_loan_emi"
    case personal_loan_emi = "personal_loan_emi"
    case education_loan_emi = "education_loan_emi"
    case credit_card_payment = "credit_card_payment"
    
    // Transfers and Others
    case bank_transfer = "bank_transfer"
    case cash_withdrawal = "cash_withdrawal"
    case fee_charges = "fee_charges"
    case tax_payment = "tax_payment"
    case donation = "donation"
    case other = "other"
    case other_expense = "other_expense"
    
    public var displayName: String {
        switch self {
        case .salary:
            return NSLocalizedString("category_salary", comment: "Salary category")
        case .mutual_funds:
            return NSLocalizedString("category_mutual_funds", comment: "Mutual funds category")
        case .food_dining:
            return NSLocalizedString("category_food_dining", comment: "Food and dining category")
        case .tax_saving_investment:
            return NSLocalizedString("category_tax_saving", comment: "Tax saving investment category")
        case .home_loan_emi:
            return NSLocalizedString("category_home_loan", comment: "Home loan EMI category")
        case .other_expense:
            return NSLocalizedString("category_other_expense", comment: "Other expense category")
        // Add more localized strings as needed
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    public var icon: String {
        switch self {
        case .salary, .bonus: return "dollarsign.circle.fill"
        case .mutual_funds, .stocks: return "chart.line.uptrend.xyaxis"
        case .food_dining: return "fork.knife"
        case .transportation: return "car.fill"
        case .medical: return "cross.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .home_loan_emi, .real_estate: return "house.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .other_expense: return "questionmark.circle.fill"
        default: return "circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .salary, .bonus, .dividend_income, .interest_income:
            return "green"
        case .mutual_funds, .stocks, .tax_saving_investment:
            return "blue"
        case .food_dining, .shopping, .entertainment:
            return "orange"
        case .medical, .health_insurance:
            return "red"
        case .education:
            return "purple"
        default:
            return "gray"
        }
    }
    
    public var systemImageName: String {
        return icon
    }
}

/// Account type for categorization
public enum AccountType: String, CaseIterable, Codable, Sendable {
    case bank = "bank"
    case credit_card = "credit_card"
    case investment = "investment"
    case cash = "cash"
    case upi = "upi"
    case wallet = "wallet"
    case crypto_exchange = "crypto_exchange"
    case foreign_bank = "foreign_bank"
    case brokerage = "brokerage"
    case retirement = "retirement"
    
    public var displayName: String {
        switch self {
        case .bank:
            return NSLocalizedString("account_type_bank", comment: "Bank account type")
        case .credit_card:
            return NSLocalizedString("account_type_credit_card", comment: "Credit card account type")
        case .investment:
            return NSLocalizedString("account_type_investment", comment: "Investment account type")
        case .upi:
            return NSLocalizedString("account_type_upi", comment: "UPI account type")
        case .brokerage:
            return NSLocalizedString("account_type_brokerage", comment: "Brokerage account type")
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

/// Transaction status
public enum TransactionStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case disputed = "disputed"
    case refunded = "refunded"
    
    public var displayName: String {
        switch self {
        case .pending:
            return NSLocalizedString("status_pending", comment: "Pending status")
        case .completed:
            return NSLocalizedString("status_completed", comment: "Completed status")
        case .failed:
            return NSLocalizedString("status_failed", comment: "Failed status")
        case .cancelled:
            return NSLocalizedString("status_cancelled", comment: "Cancelled status")
        case .disputed:
            return NSLocalizedString("status_disputed", comment: "Disputed status")
        case .refunded:
            return NSLocalizedString("status_refunded", comment: "Refunded status")
        }
    }
}

/// Transaction source
public enum TransactionSource: String, CaseIterable, Codable, Sendable {
    case manual = "manual"
    case bank_sync = "bank_sync"
    case sms_import = "sms_import"
    case email_import = "email_import"
    case file_import = "file_import"
    case api_integration = "api_integration"
    case receipt_scan = "receipt_scan"
    
    public var displayName: String {
        switch self {
        case .manual:
            return NSLocalizedString("source_manual", comment: "Manual entry source")
        case .bank_sync:
            return NSLocalizedString("source_bank_sync", comment: "Bank sync source")
        case .sms_import:
            return NSLocalizedString("source_sms_import", comment: "SMS import source")
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

/// Tax category for Indian tax system
public enum TaxCategory: String, CaseIterable, Codable, Sendable {
    case short_term_capital_gain = "short_term_capital_gain" // <1 year
    case long_term_capital_gain = "long_term_capital_gain"   // >1 year
    case dividend_income = "dividend_income"
    case interest_income = "interest_income"
    case rental_income = "rental_income"
    case business_income = "business_income"
    case salary_income = "salary_income"
    case other_income = "other_income"
    case tax_free = "tax_free"
    
    public var displayName: String {
        switch self {
        case .short_term_capital_gain:
            return NSLocalizedString("tax_stcg", comment: "Short-term capital gain")
        case .long_term_capital_gain:
            return NSLocalizedString("tax_ltcg", comment: "Long-term capital gain")
        case .dividend_income:
            return NSLocalizedString("tax_dividend", comment: "Dividend income")
        case .tax_free:
            return NSLocalizedString("tax_free", comment: "Tax-free income")
        default:
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    public var taxRate: Decimal {
        switch self {
        case .short_term_capital_gain: return 15.0
        case .long_term_capital_gain: return 10.0 // Above 1L exemption
        case .dividend_income: return 30.0
        case .interest_income: return 30.0
        case .tax_free: return 0.0
        default: return 30.0
        }
    }
}

/// Recurring transaction pattern
public struct RecurringPattern: Codable, Sendable {
    public let frequency: RecurringFrequency
    public let interval: Int // Every X frequency units
    public let endDate: Date?
    public let maxOccurrences: Int?
    public var nextDueDate: Date
    
    public init(
        frequency: RecurringFrequency,
        interval: Int = 1,
        endDate: Date? = nil,
        maxOccurrences: Int? = nil,
        nextDueDate: Date
    ) {
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
        self.maxOccurrences = maxOccurrences
        self.nextDueDate = nextDueDate
    }
}

/// Recurring frequency
public enum RecurringFrequency: String, CaseIterable, Codable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case annually = "annually"
    
    public var displayName: String {
        switch self {
        case .daily:
            return NSLocalizedString("frequency_daily", comment: "Daily frequency")
        case .weekly:
            return NSLocalizedString("frequency_weekly", comment: "Weekly frequency")
        case .monthly:
            return NSLocalizedString("frequency_monthly", comment: "Monthly frequency")
        case .quarterly:
            return NSLocalizedString("frequency_quarterly", comment: "Quarterly frequency")
        case .annually:
            return NSLocalizedString("frequency_annually", comment: "Annual frequency")
        }
    }
}

/// Transaction location information
public struct TransactionLocation: Codable, Sendable {
    public let latitude: Double?
    public let longitude: Double?
    public let address: String?
    public let city: String?
    public let country: String?
    
    public init(
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        city: String? = nil,
        country: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.country = country
    }
}

/// Transaction attachment
public struct TransactionAttachment: Codable, Sendable, Identifiable {
    public let id: UUID
    public let fileName: String
    public let fileType: AttachmentType
    public let filePath: String
    public let uploadDate: Date
    public let fileSize: Int
    
    public init(
        id: UUID = UUID(),
        fileName: String,
        fileType: AttachmentType,
        filePath: String,
        uploadDate: Date = Date(),
        fileSize: Int
    ) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.filePath = filePath
        self.uploadDate = uploadDate
        self.fileSize = fileSize
    }
}

/// Attachment type
public enum AttachmentType: String, CaseIterable, Codable, Sendable {
    case receipt = "receipt"
    case invoice = "invoice"
    case contract = "contract"
    case statement = "statement"
    case photo = "photo"
    case document = "document"
    
    public var displayName: String {
        switch self {
        case .receipt:
            return NSLocalizedString("attachment_receipt", comment: "Receipt attachment")
        case .invoice:
            return NSLocalizedString("attachment_invoice", comment: "Invoice attachment")
        default:
            return rawValue.capitalized
        }
    }
}

/// Tax saving potential
public struct TaxSavingPotential: Codable, Sendable {
    public let deductibleAmount: Decimal
    public let taxSaving: Decimal
    public let section: String
    public let description: String
    
    public init(
        deductibleAmount: Decimal,
        taxSaving: Decimal,
        section: String,
        description: String
    ) {
        self.deductibleAmount = deductibleAmount
        self.taxSaving = taxSaving
        self.section = section
        self.description = description
    }
}

// MARK: - Extensions
// SwiftData @Model provides Hashable and Equatable conformance automatically

// MARK: - Factory Methods

extension Transaction {
    
    /// Create a salary transaction
    public static func createSalaryTransaction(
        amount: Decimal,
        date: Date = Date(),
        accountId: String? = nil
    ) -> Transaction {
        return Transaction(
            amount: amount,
            transactionDescription: NSLocalizedString("salary_transaction_desc", comment: "Monthly salary"),
            date: date,
            transactionType: .income,
            category: .salary,
            accountType: .bank
        )
    }
    
    /// Create a mutual fund investment transaction
    public static func createMutualFundInvestment(
        amount: Decimal,
        fundName: String,
        units: Decimal,
        nav: Decimal,
        date: Date = Date()
    ) -> Transaction {
        let transaction = Transaction(
            amount: amount,
            transactionDescription: "Investment in \(fundName)",
            date: date,
            transactionType: .investment,
            category: .mutual_funds,
            accountType: .investment
        )
        transaction.linkToAsset(assetId: fundName, units: units, pricePerUnit: nav)
        return transaction
    }
    
    /// Create a tax-saving investment transaction
    public static func createTaxSavingInvestment(
        amount: Decimal,
        description: String,
        date: Date = Date()
    ) -> Transaction {
        let transaction = Transaction(
            amount: amount,
            transactionDescription: description,
            date: date,
            transactionType: .investment,
            category: .tax_saving_investment,
            accountType: .investment
        )
        transaction.addTaxInformation(
            taxCategory: .tax_free,
            taxAmount: 0,
            taxResidencyCountry: "IN"
        )
        return transaction
    }
}