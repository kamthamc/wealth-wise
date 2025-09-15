// Core Data Model for iOS
// UnifiedBanking.xcdatamodeld equivalent in Swift

import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Stack

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "UnifiedBanking")
        
        // Enable encryption
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

// MARK: - Account Entity

@objc(Account)
public class Account: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var accountTypeRaw: String
    @NSManaged public var institutionName: String
    @NSManaged public var accountNumber: String?
    @NSManaged public var currentBalance: Double
    @NSManaged public var currency: String
    @NSManaged public var isActive: Bool
    @NSManaged public var lastSynced: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // Relationships
    @NSManaged public var transactions: NSSet?
    
    var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .savings }
        set { accountTypeRaw = newValue.rawValue }
    }
}

extension Account {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }
    
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)
    
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)
}

// MARK: - Transaction Entity

@objc(Transaction)
public class Transaction: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var accountId: UUID
    @NSManaged public var amount: Double
    @NSManaged public var currency: String
    @NSManaged public var transactionTypeRaw: String
    @NSManaged public var categoryRaw: String
    @NSManaged public var subcategory: String?
    @NSManaged public var transactionDescription: String
    @NSManaged public var merchantName: String?
    @NSManaged public var location: String?
    @NSManaged public var transactionDate: Date
    @NSManaged public var processedDate: Date?
    @NSManaged public var referenceNumber: String?
    @NSManaged public var linkedTransactionId: UUID?
    @NSManaged public var tagsString: String?
    @NSManaged public var notes: String?
    @NSManaged public var receiptPath: String?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var recurringGroupId: UUID?
    @NSManaged public var categoryConfidence: Double
    @NSManaged public var isManuallyVerified: Bool
    @NSManaged public var syncStatusRaw: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var importSourceRaw: String?
    
    // Relationships
    @NSManaged public var account: Account?
    
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeRaw) ?? .expense }
        set { transactionTypeRaw = newValue.rawValue }
    }
    
    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRaw) ?? .other_expense }
        set { categoryRaw = newValue.rawValue }
    }
    
    var tags: [String] {
        get { tagsString?.components(separatedBy: ",") ?? [] }
        set { tagsString = newValue.joined(separator: ",") }
    }
    
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
    
    var importSource: ImportSource? {
        get { ImportSource(rawValue: importSourceRaw ?? "") }
        set { importSourceRaw = newValue?.rawValue }
    }
}

extension Transaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }
}

// MARK: - Budget Entity

@objc(Budget)
public class Budget: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var budgetTypeRaw: String
    @NSManaged public var periodRaw: String
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date?
    @NSManaged public var totalBudget: Double
    @NSManaged public var spentAmount: Double
    @NSManaged public var remainingAmount: Double
    @NSManaged public var currency: String
    @NSManaged public var includedCategoriesString: String
    @NSManaged public var excludedCategoriesString: String?
    @NSManaged public var includedAccountsString: String?
    @NSManaged public var alertThresholdsString: String
    @NSManaged public var isAlertEnabled: Bool
    @NSManaged public var allowRollover: Bool
    @NSManaged public var rolloverAmount: Double
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    var budgetType: BudgetType {
        get { BudgetType(rawValue: budgetTypeRaw) ?? .monthly }
        set { budgetTypeRaw = newValue.rawValue }
    }
    
    var period: BudgetPeriod {
        get { BudgetPeriod(rawValue: periodRaw) ?? .monthly }
        set { periodRaw = newValue.rawValue }
    }
    
    var includedCategories: [TransactionCategory] {
        get {
            includedCategoriesString.components(separatedBy: ",")
                .compactMap { TransactionCategory(rawValue: $0) }
        }
        set {
            includedCategoriesString = newValue.map { $0.rawValue }.joined(separator: ",")
        }
    }
    
    var alertThresholds: [Double] {
        get {
            alertThresholdsString.components(separatedBy: ",")
                .compactMap { Double($0) }
        }
        set {
            alertThresholdsString = newValue.map { String($0) }.joined(separator: ",")
        }
    }
}

// MARK: - Asset Entity

@objc(Asset)
public class Asset: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var assetTypeRaw: String
    @NSManaged public var assetDescription: String?
    @NSManaged public var purchaseValue: Double
    @NSManaged public var currentValue: Double
    @NSManaged public var valuationDate: Date
    @NSManaged public var currency: String
    @NSManaged public var purchaseDate: Date
    @NSManaged public var purchaseLocation: String?
    @NSManaged public var vendor: String?
    @NSManaged public var quantity: Double
    @NSManaged public var unit: String
    @NSManaged public var photosString: String?
    @NSManaged public var isInsured: Bool
    @NSManaged public var insuranceProvider: String?
    @NSManaged public var insuranceValue: Double
    @NSManaged public var insuranceExpiryDate: Date?
    @NSManaged public var warrantyExpiryDate: Date?
    @NSManaged public var depreciationRate: Double
    @NSManaged public var estimatedLifespan: Double
    @NSManaged public var tagsString: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // Relationships
    @NSManaged public var documents: NSSet?
    
    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRaw) ?? .other }
        set { assetTypeRaw = newValue.rawValue }
    }
    
    var photos: [String] {
        get { photosString?.components(separatedBy: ",") ?? [] }
        set { photosString = newValue.joined(separator: ",") }
    }
    
    var tags: [String] {
        get { tagsString?.components(separatedBy: ",") ?? [] }
        set { tagsString = newValue.joined(separator: ",") }
    }
}

// MARK: - Loan Entity

@objc(Loan)
public class Loan: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var loanTypeRaw: String
    @NSManaged public var lenderName: String
    @NSManaged public var principalAmount: Double
    @NSManaged public var currentOutstanding: Double
    @NSManaged public var interestRate: Double
    @NSManaged public var tenure: Int32
    @NSManaged public var emiAmount: Double
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var nextEmiDate: Date?
    @NSManaged public var totalPaidAmount: Double
    @NSManaged public var principalPaid: Double
    @NSManaged public var interestPaid: Double
    @NSManaged public var penaltyPaid: Double
    @NSManaged public var statusRaw: String
    @NSManaged public var accountId: UUID?
    @NSManaged public var loanAccountNumber: String?
    @NSManaged public var notes: String?
    @NSManaged public var allowPrepayment: Bool
    @NSManaged public var prepaymentPenalty: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    var loanType: LoanType {
        get { LoanType(rawValue: loanTypeRaw) ?? .other }
        set { loanTypeRaw = newValue.rawValue }
    }
    
    var status: LoanStatus {
        get { LoanStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
}

// MARK: - Investment Entity

@objc(Investment)
public class Investment: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var investmentTypeRaw: String
    @NSManaged public var symbol: String?
    @NSManaged public var totalInvested: Double
    @NSManaged public var currentValue: Double
    @NSManaged public var quantity: Double
    @NSManaged public var averagePrice: Double
    @NSManaged public var currentPrice: Double
    @NSManaged public var totalReturn: Double
    @NSManaged public var totalReturnPercentage: Double
    @NSManaged public var dayReturn: Double
    @NSManaged public var dayReturnPercentage: Double
    @NSManaged public var firstInvestmentDate: Date
    @NSManaged public var lastInvestmentDate: Date?
    @NSManaged public var maturityDate: Date?
    @NSManaged public var accountId: UUID?
    @NSManaged public var brokerName: String?
    @NSManaged public var isinCode: String?
    @NSManaged public var riskLevelRaw: String?
    @NSManaged public var category: String?
    @NSManaged public var subcategory: String?
    @NSManaged public var taxCategoryRaw: String?
    @NSManaged public var lockInPeriod: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    var investmentType: InvestmentType {
        get { InvestmentType(rawValue: investmentTypeRaw) ?? .other }
        set { investmentTypeRaw = newValue.rawValue }
    }
    
    var riskLevel: RiskLevel? {
        get { RiskLevel(rawValue: riskLevelRaw ?? "") }
        set { riskLevelRaw = newValue?.rawValue }
    }
    
    var taxCategory: TaxCategory? {
        get { TaxCategory(rawValue: taxCategoryRaw ?? "") }
        set { taxCategoryRaw = newValue?.rawValue }
    }
}

// MARK: - Supporting Enums

enum AccountType: String, CaseIterable {
    case savings = "savings"
    case current = "current"
    case salary = "salary"
    case overdraft = "overdraft"
    case creditCard = "credit_card"
    case chargeCard = "charge_card"
    case upi = "upi"
    case wallet = "wallet"
    case prepaidCard = "prepaid_card"
    case demat = "demat"
    case trading = "trading"
    case mutualFund = "mutual_fund"
    case pf = "provident_fund"
    case ppf = "ppf"
    case nsc = "nsc"
    case homeLoan = "home_loan"
    case personalLoan = "personal_loan"
    case carLoan = "car_loan"
    case educationLoan = "education_loan"
    case goldLoan = "gold_loan"
    case cash = "cash"
    case offlineAsset = "offline_asset"
}

enum TransactionType: String, CaseIterable {
    case income = "income"
    case expense = "expense"
    case transfer = "transfer"
    case investment = "investment"
    case withdrawal = "withdrawal"
    case deposit = "deposit"
    case refund = "refund"
    case fee = "fee"
    case interest = "interest"
    case dividend = "dividend"
    case bonus = "bonus"
    case penalty = "penalty"
}

enum TransactionCategory: String, CaseIterable {
    case salary = "salary"
    case freelance = "freelance"
    case business = "business"
    case investmentReturn = "investment_return"
    case rentalIncome = "rental_income"
    case otherIncome = "other_income"
    case foodDining = "food_dining"
    case groceries = "groceries"
    case transportation = "transportation"
    case fuel = "fuel"
    case utilities = "utilities"
    case rent = "rent"
    case medical = "medical"
    case insurance = "insurance"
    case education = "education"
    case entertainment = "entertainment"
    case shopping = "shopping"
    case travel = "travel"
    case personalCare = "personal_care"
    case giftsDonations = "gifts_donations"
    case taxes = "taxes"
    case bankFees = "bank_fees"
    case loanPayment = "loan_payment"
    case investmentPurchase = "investment_purchase"
    case otherExpense = "other_expense"
    case internalTransfer = "internal_transfer"
    case externalTransfer = "external_transfer"
    case upiTransfer = "upi_transfer"
    case walletTransfer = "wallet_transfer"
}

enum BudgetType: String, CaseIterable {
    case monthly = "monthly"
    case weekly = "weekly"
    case yearly = "yearly"
    case eventBased = "event_based"
    case projectBased = "project_based"
}

enum BudgetPeriod: String, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    case custom = "custom"
}

enum AssetType: String, CaseIterable {
    case realEstate = "real_estate"
    case gold = "gold"
    case silver = "silver"
    case jewelry = "jewelry"
    case vehicle = "vehicle"
    case electronics = "electronics"
    case artwork = "artwork"
    case collectibles = "collectibles"
    case bonds = "bonds"
    case fixedDeposit = "fixed_deposit"
    case insurancePolicy = "insurance_policy"
    case other = "other"
}

enum LoanType: String, CaseIterable {
    case homeLoan = "home_loan"
    case personalLoan = "personal_loan"
    case carLoan = "car_loan"
    case educationLoan = "education_loan"
    case goldLoan = "gold_loan"
    case businessLoan = "business_loan"
    case creditCardDebt = "credit_card_debt"
    case lendingToOthers = "lending_to_others"
    case other = "other"
}

enum LoanStatus: String, CaseIterable {
    case active = "active"
    case paidOff = "paid_off"
    case defaulted = "defaulted"
    case prepaid = "prepaid"
    case restructured = "restructured"
}

enum InvestmentType: String, CaseIterable {
    case mutualFund = "mutual_fund"
    case stock = "stock"
    case bond = "bond"
    case etf = "etf"
    case fd = "fixed_deposit"
    case rd = "recurring_deposit"
    case ppf = "ppf"
    case nsc = "nsc"
    case elss = "elss"
    case nps = "nps"
    case cryptocurrency = "cryptocurrency"
    case commodity = "commodity"
    case other = "other"
}

enum SyncStatus: String, CaseIterable {
    case synced = "synced"
    case pending = "pending"
    case conflict = "conflict"
}

enum ImportSource: String, CaseIterable {
    case manual = "manual"
    case csv = "csv"
    case bankApi = "bank_api"
    case sms = "sms"
    case email = "email"
}

enum RiskLevel: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

enum TaxCategory: String, CaseIterable {
    case equity = "equity"
    case debt = "debt"
    case hybrid = "hybrid"
}