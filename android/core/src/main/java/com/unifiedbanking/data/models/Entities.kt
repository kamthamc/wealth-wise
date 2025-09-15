// Android Room Database Models
// Kotlin data classes and Room entities for Android app

package com.unifiedbanking.data.models

import androidx.room.*
import androidx.room.ForeignKey.Companion.CASCADE
import java.time.LocalDateTime
import java.util.*

// MARK: - Account Entity

@Entity(
    tableName = "accounts",
    indices = [
        Index(value = ["account_number"], unique = true),
        Index(value = ["institution_name"])
    ]
)
data class AccountEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "account_type") val accountType: String,
    @ColumnInfo(name = "institution_name") val institutionName: String,
    @ColumnInfo(name = "account_number") val accountNumber: String? = null,
    @ColumnInfo(name = "current_balance") val currentBalance: Double,
    @ColumnInfo(name = "currency") val currency: String,
    @ColumnInfo(name = "is_active") val isActive: Boolean = true,
    @ColumnInfo(name = "last_synced") val lastSynced: LocalDateTime? = null,
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Transaction Entity

@Entity(
    tableName = "transactions",
    foreignKeys = [
        ForeignKey(
            entity = AccountEntity::class,
            parentColumns = ["id"],
            childColumns = ["account_id"],
            onDelete = CASCADE
        )
    ],
    indices = [
        Index(value = ["account_id"]),
        Index(value = ["transaction_date"]),
        Index(value = ["category"]),
        Index(value = ["reference_number"])
    ]
)
data class TransactionEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "account_id") val accountId: String,
    @ColumnInfo(name = "amount") val amount: Double,
    @ColumnInfo(name = "currency") val currency: String,
    @ColumnInfo(name = "transaction_type") val transactionType: String,
    @ColumnInfo(name = "category") val category: String,
    @ColumnInfo(name = "subcategory") val subcategory: String? = null,
    @ColumnInfo(name = "description") val description: String,
    @ColumnInfo(name = "merchant_name") val merchantName: String? = null,
    @ColumnInfo(name = "location") val location: String? = null,
    @ColumnInfo(name = "transaction_date") val transactionDate: LocalDateTime,
    @ColumnInfo(name = "processed_date") val processedDate: LocalDateTime? = null,
    @ColumnInfo(name = "reference_number") val referenceNumber: String? = null,
    @ColumnInfo(name = "linked_transaction_id") val linkedTransactionId: String? = null,
    @ColumnInfo(name = "tags") val tags: String? = null, // Comma-separated
    @ColumnInfo(name = "notes") val notes: String? = null,
    @ColumnInfo(name = "receipt_path") val receiptPath: String? = null,
    @ColumnInfo(name = "is_recurring") val isRecurring: Boolean = false,
    @ColumnInfo(name = "recurring_group_id") val recurringGroupId: String? = null,
    @ColumnInfo(name = "category_confidence") val categoryConfidence: Double = 0.0,
    @ColumnInfo(name = "is_manually_verified") val isManuallyVerified: Boolean = false,
    @ColumnInfo(name = "sync_status") val syncStatus: String = "pending",
    @ColumnInfo(name = "import_source") val importSource: String? = null,
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Budget Entity

@Entity(
    tableName = "budgets",
    indices = [
        Index(value = ["name"]),
        Index(value = ["start_date", "end_date"]),
        Index(value = ["is_active"])
    ]
)
data class BudgetEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "budget_type") val budgetType: String,
    @ColumnInfo(name = "period") val period: String,
    @ColumnInfo(name = "start_date") val startDate: LocalDateTime,
    @ColumnInfo(name = "end_date") val endDate: LocalDateTime? = null,
    @ColumnInfo(name = "total_budget") val totalBudget: Double,
    @ColumnInfo(name = "spent_amount") val spentAmount: Double = 0.0,
    @ColumnInfo(name = "remaining_amount") val remainingAmount: Double,
    @ColumnInfo(name = "currency") val currency: String,
    @ColumnInfo(name = "included_categories") val includedCategories: String, // Comma-separated
    @ColumnInfo(name = "excluded_categories") val excludedCategories: String? = null, // Comma-separated
    @ColumnInfo(name = "included_accounts") val includedAccounts: String? = null, // Comma-separated
    @ColumnInfo(name = "alert_thresholds") val alertThresholds: String, // Comma-separated percentages
    @ColumnInfo(name = "is_alert_enabled") val isAlertEnabled: Boolean = true,
    @ColumnInfo(name = "allow_rollover") val allowRollover: Boolean = false,
    @ColumnInfo(name = "rollover_amount") val rolloverAmount: Double = 0.0,
    @ColumnInfo(name = "is_active") val isActive: Boolean = true,
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Asset Entity

@Entity(
    tableName = "assets",
    indices = [
        Index(value = ["asset_type"]),
        Index(value = ["purchase_date"]),
        Index(value = ["valuation_date"])
    ]
)
data class AssetEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "asset_type") val assetType: String,
    @ColumnInfo(name = "description") val description: String? = null,
    @ColumnInfo(name = "purchase_value") val purchaseValue: Double,
    @ColumnInfo(name = "current_value") val currentValue: Double,
    @ColumnInfo(name = "valuation_date") val valuationDate: LocalDateTime,
    @ColumnInfo(name = "currency") val currency: String,
    @ColumnInfo(name = "purchase_date") val purchaseDate: LocalDateTime,
    @ColumnInfo(name = "purchase_location") val purchaseLocation: String? = null,
    @ColumnInfo(name = "vendor") val vendor: String? = null,
    @ColumnInfo(name = "quantity") val quantity: Double,
    @ColumnInfo(name = "unit") val unit: String,
    @ColumnInfo(name = "photos") val photos: String? = null, // Comma-separated file paths
    @ColumnInfo(name = "is_insured") val isInsured: Boolean = false,
    @ColumnInfo(name = "insurance_provider") val insuranceProvider: String? = null,
    @ColumnInfo(name = "insurance_value") val insuranceValue: Double = 0.0,
    @ColumnInfo(name = "insurance_expiry_date") val insuranceExpiryDate: LocalDateTime? = null,
    @ColumnInfo(name = "warranty_expiry_date") val warrantyExpiryDate: LocalDateTime? = null,
    @ColumnInfo(name = "depreciation_rate") val depreciationRate: Double = 0.0,
    @ColumnInfo(name = "estimated_lifespan") val estimatedLifespan: Double = 0.0,
    @ColumnInfo(name = "tags") val tags: String? = null, // Comma-separated
    @ColumnInfo(name = "notes") val notes: String? = null,
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Loan Entity

@Entity(
    tableName = "loans",
    indices = [
        Index(value = ["loan_type"]),
        Index(value = ["status"]),
        Index(value = ["next_emi_date"])
    ]
)
data class LoanEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "loan_type") val loanType: String,
    @ColumnInfo(name = "lender_name") val lenderName: String,
    @ColumnInfo(name = "principal_amount") val principalAmount: Double,
    @ColumnInfo(name = "current_outstanding") val currentOutstanding: Double,
    @ColumnInfo(name = "interest_rate") val interestRate: Double,
    @ColumnInfo(name = "tenure") val tenure: Int, // Months
    @ColumnInfo(name = "emi_amount") val emiAmount: Double,
    @ColumnInfo(name = "start_date") val startDate: LocalDateTime,
    @ColumnInfo(name = "end_date") val endDate: LocalDateTime,
    @ColumnInfo(name = "next_emi_date") val nextEmiDate: LocalDateTime? = null,
    @ColumnInfo(name = "total_paid_amount") val totalPaidAmount: Double = 0.0,
    @ColumnInfo(name = "principal_paid") val principalPaid: Double = 0.0,
    @ColumnInfo(name = "interest_paid") val interestPaid: Double = 0.0,
    @ColumnInfo(name = "penalty_paid") val penaltyPaid: Double = 0.0,
    @ColumnInfo(name = "status") val status: String = "active",
    @ColumnInfo(name = "account_id") val accountId: String? = null,
    @ColumnInfo(name = "loan_account_number") val loanAccountNumber: String? = null,
    @ColumnInfo(name = "notes") val notes: String? = null,
    @ColumnInfo(name = "allow_prepayment") val allowPrepayment: Boolean = true,
    @ColumnInfo(name = "prepayment_penalty") val prepaymentPenalty: Double = 0.0,
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Investment Entity

@Entity(
    tableName = "investments",
    indices = [
        Index(value = ["investment_type"]),
        Index(value = ["symbol"]),
        Index(value = ["first_investment_date"])
    ]
)
data class InvestmentEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "investment_type") val investmentType: String,
    @ColumnInfo(name = "symbol") val symbol: String? = null,
    @ColumnInfo(name = "total_invested") val totalInvested: Double,
    @ColumnInfo(name = "current_value") val currentValue: Double,
    @ColumnInfo(name = "quantity") val quantity: Double,
    @ColumnInfo(name = "average_price") val averagePrice: Double,
    @ColumnInfo(name = "current_price") val currentPrice: Double,
    @ColumnInfo(name = "total_return") val totalReturn: Double,
    @ColumnInfo(name = "total_return_percentage") val totalReturnPercentage: Double,
    @ColumnInfo(name = "day_return") val dayReturn: Double = 0.0,
    @ColumnInfo(name = "day_return_percentage") val dayReturnPercentage: Double = 0.0,
    @ColumnInfo(name = "first_investment_date") val firstInvestmentDate: LocalDateTime,
    @ColumnInfo(name = "last_investment_date") val lastInvestmentDate: LocalDateTime? = null,
    @ColumnInfo(name = "maturity_date") val maturityDate: LocalDateTime? = null,
    @ColumnInfo(name = "account_id") val accountId: String? = null,
    @ColumnInfo(name = "broker_name") val brokerName: String? = null,
    @ColumnInfo(name = "isin_code") val isinCode: String? = null,
    @ColumnInfo(name = "risk_level") val riskLevel: String? = null,
    @ColumnInfo(name = "category") val category: String? = null,
    @ColumnInfo(name = "subcategory") val subcategory: String? = null,
    @ColumnInfo(name = "tax_category") val taxCategory: String? = null,
    @ColumnInfo(name = "lock_in_period") val lockInPeriod: Int = 0, // Months
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Asset Document Entity

@Entity(
    tableName = "asset_documents",
    foreignKeys = [
        ForeignKey(
            entity = AssetEntity::class,
            parentColumns = ["id"],
            childColumns = ["asset_id"],
            onDelete = CASCADE
        )
    ]
)
data class AssetDocumentEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "asset_id") val assetId: String,
    @ColumnInfo(name = "type") val type: String,
    @ColumnInfo(name = "file_name") val fileName: String,
    @ColumnInfo(name = "file_path") val filePath: String,
    @ColumnInfo(name = "upload_date") val uploadDate: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "description") val description: String? = null
)

// MARK: - User Profile Entity

@Entity(tableName = "user_profile")
data class UserProfileEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "email") val email: String,
    @ColumnInfo(name = "first_name") val firstName: String,
    @ColumnInfo(name = "last_name") val lastName: String,
    @ColumnInfo(name = "currency") val currency: String = "INR",
    @ColumnInfo(name = "timezone") val timezone: String,
    @ColumnInfo(name = "locale") val locale: String = "en-IN",
    @ColumnInfo(name = "financial_year_start") val financialYearStart: String, // ISO date string
    @ColumnInfo(name = "subscription_tier") val subscriptionTier: String = "free",
    @ColumnInfo(name = "subscription_expiry_date") val subscriptionExpiryDate: LocalDateTime? = null,
    @ColumnInfo(name = "biometric_enabled") val biometricEnabled: Boolean = false,
    @ColumnInfo(name = "cloud_sync_enabled") val cloudSyncEnabled: Boolean = true,
    @ColumnInfo(name = "analytics_enabled") val analyticsEnabled: Boolean = true,
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Report Template Entity

@Entity(
    tableName = "report_templates",
    indices = [Index(value = ["category"])]
)
data class ReportTemplateEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "name") val name: String,
    @ColumnInfo(name = "description") val description: String? = null,
    @ColumnInfo(name = "category") val category: String,
    @ColumnInfo(name = "date_range_type") val dateRangeType: String,
    @ColumnInfo(name = "start_date") val startDate: LocalDateTime? = null,
    @ColumnInfo(name = "end_date") val endDate: LocalDateTime? = null,
    @ColumnInfo(name = "included_accounts") val includedAccounts: String? = null, // JSON array
    @ColumnInfo(name = "included_categories") val includedCategories: String? = null, // JSON array
    @ColumnInfo(name = "group_by") val groupBy: String,
    @ColumnInfo(name = "chart_type") val chartType: String,
    @ColumnInfo(name = "show_comparison") val showComparison: Boolean = false,
    @ColumnInfo(name = "comparison_period") val comparisonPeriod: String? = null,
    @ColumnInfo(name = "is_custom") val isCustom: Boolean = false,
    @ColumnInfo(name = "is_default") val isDefault: Boolean = false,
    @ColumnInfo(name = "created_at") val createdAt: LocalDateTime = LocalDateTime.now(),
    @ColumnInfo(name = "updated_at") val updatedAt: LocalDateTime = LocalDateTime.now()
)

// MARK: - Sync Metadata Entity

@Entity(
    tableName = "sync_metadata",
    indices = [
        Index(value = ["entity_type", "entity_id"], unique = true),
        Index(value = ["last_modified"])
    ]
)
data class SyncMetadataEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "entity_id") val entityId: String,
    @ColumnInfo(name = "entity_type") val entityType: String,
    @ColumnInfo(name = "last_modified") val lastModified: LocalDateTime,
    @ColumnInfo(name = "version") val version: Int = 1,
    @ColumnInfo(name = "checksum") val checksum: String,
    @ColumnInfo(name = "device_id") val deviceId: String
)

// MARK: - Enums as sealed classes

sealed class AccountType(val value: String) {
    object Savings : AccountType("savings")
    object Current : AccountType("current")
    object Salary : AccountType("salary")
    object Overdraft : AccountType("overdraft")
    object CreditCard : AccountType("credit_card")
    object ChargeCard : AccountType("charge_card")
    object UPI : AccountType("upi")
    object Wallet : AccountType("wallet")
    object PrepaidCard : AccountType("prepaid_card")
    object Demat : AccountType("demat")
    object Trading : AccountType("trading")
    object MutualFund : AccountType("mutual_fund")
    object PF : AccountType("provident_fund")
    object PPF : AccountType("ppf")
    object NSC : AccountType("nsc")
    object HomeLoan : AccountType("home_loan")
    object PersonalLoan : AccountType("personal_loan")
    object CarLoan : AccountType("car_loan")
    object EducationLoan : AccountType("education_loan")
    object GoldLoan : AccountType("gold_loan")
    object Cash : AccountType("cash")
    object OfflineAsset : AccountType("offline_asset")
    
    companion object {
        fun fromString(value: String): AccountType = when (value) {
            "savings" -> Savings
            "current" -> Current
            "salary" -> Salary
            "overdraft" -> Overdraft
            "credit_card" -> CreditCard
            "charge_card" -> ChargeCard
            "upi" -> UPI
            "wallet" -> Wallet
            "prepaid_card" -> PrepaidCard
            "demat" -> Demat
            "trading" -> Trading
            "mutual_fund" -> MutualFund
            "provident_fund" -> PF
            "ppf" -> PPF
            "nsc" -> NSC
            "home_loan" -> HomeLoan
            "personal_loan" -> PersonalLoan
            "car_loan" -> CarLoan
            "education_loan" -> EducationLoan
            "gold_loan" -> GoldLoan
            "cash" -> Cash
            "offline_asset" -> OfflineAsset
            else -> Cash
        }
    }
}

sealed class TransactionType(val value: String) {
    object Income : TransactionType("income")
    object Expense : TransactionType("expense")
    object Transfer : TransactionType("transfer")
    object Investment : TransactionType("investment")
    object Withdrawal : TransactionType("withdrawal")
    object Deposit : TransactionType("deposit")
    object Refund : TransactionType("refund")
    object Fee : TransactionType("fee")
    object Interest : TransactionType("interest")
    object Dividend : TransactionType("dividend")
    object Bonus : TransactionType("bonus")
    object Penalty : TransactionType("penalty")
    
    companion object {
        fun fromString(value: String): TransactionType = when (value) {
            "income" -> Income
            "expense" -> Expense
            "transfer" -> Transfer
            "investment" -> Investment
            "withdrawal" -> Withdrawal
            "deposit" -> Deposit
            "refund" -> Refund
            "fee" -> Fee
            "interest" -> Interest
            "dividend" -> Dividend
            "bonus" -> Bonus
            "penalty" -> Penalty
            else -> Expense
        }
    }
}

sealed class TransactionCategory(val value: String) {
    // Income categories
    object Salary : TransactionCategory("salary")
    object Freelance : TransactionCategory("freelance")
    object Business : TransactionCategory("business")
    object InvestmentReturn : TransactionCategory("investment_return")
    object RentalIncome : TransactionCategory("rental_income")
    object OtherIncome : TransactionCategory("other_income")
    
    // Expense categories
    object FoodDining : TransactionCategory("food_dining")
    object Groceries : TransactionCategory("groceries")
    object Transportation : TransactionCategory("transportation")
    object Fuel : TransactionCategory("fuel")
    object Utilities : TransactionCategory("utilities")
    object Rent : TransactionCategory("rent")
    object Medical : TransactionCategory("medical")
    object Insurance : TransactionCategory("insurance")
    object Education : TransactionCategory("education")
    object Entertainment : TransactionCategory("entertainment")
    object Shopping : TransactionCategory("shopping")
    object Travel : TransactionCategory("travel")
    object PersonalCare : TransactionCategory("personal_care")
    object GiftsDonations : TransactionCategory("gifts_donations")
    object Taxes : TransactionCategory("taxes")
    object BankFees : TransactionCategory("bank_fees")
    object LoanPayment : TransactionCategory("loan_payment")
    object InvestmentPurchase : TransactionCategory("investment_purchase")
    object OtherExpense : TransactionCategory("other_expense")
    
    // Transfer categories
    object InternalTransfer : TransactionCategory("internal_transfer")
    object ExternalTransfer : TransactionCategory("external_transfer")
    object UPITransfer : TransactionCategory("upi_transfer")
    object WalletTransfer : TransactionCategory("wallet_transfer")
    
    companion object {
        fun fromString(value: String): TransactionCategory = when (value) {
            "salary" -> Salary
            "freelance" -> Freelance
            "business" -> Business
            "investment_return" -> InvestmentReturn
            "rental_income" -> RentalIncome
            "other_income" -> OtherIncome
            "food_dining" -> FoodDining
            "groceries" -> Groceries
            "transportation" -> Transportation
            "fuel" -> Fuel
            "utilities" -> Utilities
            "rent" -> Rent
            "medical" -> Medical
            "insurance" -> Insurance
            "education" -> Education
            "entertainment" -> Entertainment
            "shopping" -> Shopping
            "travel" -> Travel
            "personal_care" -> PersonalCare
            "gifts_donations" -> GiftsDonations
            "taxes" -> Taxes
            "bank_fees" -> BankFees
            "loan_payment" -> LoanPayment
            "investment_purchase" -> InvestmentPurchase
            "other_expense" -> OtherExpense
            "internal_transfer" -> InternalTransfer
            "external_transfer" -> ExternalTransfer
            "upi_transfer" -> UPITransfer
            "wallet_transfer" -> WalletTransfer
            else -> OtherExpense
        }
    }
}