package com.wealthwise.android.data.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.wealthwise.android.data.local.converters.DateConverter
import com.wealthwise.android.data.local.converters.DecimalConverter
import kotlinx.serialization.Serializable
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.UUID

/**
 * Transaction entity matching Firebase webapp schema
 * 
 * Represents financial transactions across all account types:
 * - Income (salary, business income, dividends)
 * - Expenses (groceries, utilities, entertainment)
 * - Transfers between accounts
 * 
 * Features:
 * - Local-first with Room persistence
 * - Offline support with sync queue
 * - Category-based organization
 * - Full-text search capability
 * 
 * Security:
 * - Transaction data encrypted at rest
 * - Secure sync with Firebase
 */
@Entity(
    tableName = "transactions",
    foreignKeys = [
        ForeignKey(
            entity = Account::class,
            parentColumns = ["id"],
            childColumns = ["accountId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["accountId"]),
        Index(value = ["date"]),
        Index(value = ["category"]),
        Index(value = ["type"])
    ]
)
@TypeConverters(DateConverter::class, DecimalConverter::class)
@Serializable
data class Transaction(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    
    val userId: String,
    
    val accountId: String,
    
    val date: LocalDateTime,
    
    val amount: BigDecimal,
    
    val type: TransactionType,
    
    val category: String,
    
    val description: String,
    
    val notes: String? = null,
    
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    
    val lastSyncedAt: LocalDateTime? = null
) {
    
    /**
     * Transaction types
     */
    enum class TransactionType {
        DEBIT,
        CREDIT;
        
        companion object {
            fun fromString(value: String): TransactionType {
                return when (value.lowercase()) {
                    "debit" -> DEBIT
                    "credit" -> CREDIT
                    else -> DEBIT
                }
            }
        }
        
        fun toFirestore(): String {
            return when (this) {
                DEBIT -> "debit"
                CREDIT -> "credit"
            }
        }
    }
    
    /**
     * Default categories by transaction type
     */
    object Categories {
        val INCOME_CATEGORIES = listOf(
            "Salary",
            "Business Income",
            "Freelance",
            "Investment Returns",
            "Rental Income",
            "Other Income"
        )
        
        val EXPENSE_CATEGORIES = listOf(
            "Groceries",
            "Food & Dining",
            "Transport",
            "Healthcare",
            "Entertainment",
            "Shopping",
            "Utilities",
            "Rent",
            "Education",
            "Insurance",
            "Other Expense"
        )
        
        val INVESTMENT_CATEGORIES = listOf(
            "Mutual Funds",
            "Stocks",
            "Fixed Deposits",
            "PPF",
            "NPS",
            "Real Estate"
        )
        
        fun getCategoriesForType(type: TransactionType): List<String> {
            return when (type) {
                TransactionType.CREDIT -> INCOME_CATEGORIES
                TransactionType.DEBIT -> EXPENSE_CATEGORIES + INVESTMENT_CATEGORIES
            }
        }
    }
    
    /**
     * Get signed amount (negative for debit, positive for credit)
     */
    fun getSignedAmount(): BigDecimal {
        return when (type) {
            TransactionType.DEBIT -> -amount
            TransactionType.CREDIT -> amount
        }
    }
    
    /**
     * Check if transaction needs sync
     */
    fun needsSync(): Boolean {
        val lastSync = lastSyncedAt ?: return true
        val minutesSinceSync = java.time.Duration.between(lastSync, LocalDateTime.now()).toMinutes()
        return minutesSinceSync >= 5 // Sync if more than 5 minutes old
    }
    
    /**
     * Create a copy marked as synced
     */
    fun markSynced(): Transaction {
        return copy(
            lastSyncedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
    }
    
    /**
     * Get display icon for category
     */
    fun getCategoryIcon(): String {
        return when (category.lowercase()) {
            "salary" -> "payments"
            "groceries" -> "shopping_cart"
            "food & dining" -> "restaurant"
            "transport" -> "directions_car"
            "healthcare" -> "local_hospital"
            "entertainment" -> "movie"
            "shopping" -> "shopping_bag"
            "utilities" -> "lightbulb"
            "rent" -> "home"
            "education" -> "school"
            "insurance" -> "shield"
            "mutual funds" -> "trending_up"
            "stocks" -> "show_chart"
            else -> "payments"
        }
    }
}
