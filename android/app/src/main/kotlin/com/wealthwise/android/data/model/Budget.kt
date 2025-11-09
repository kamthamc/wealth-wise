package com.wealthwise.android.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.wealthwise.android.data.local.converters.DateConverter
import com.wealthwise.android.data.local.converters.DecimalConverter
import com.wealthwise.android.data.local.converters.StringListConverter
import kotlinx.serialization.Serializable
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.UUID

/**
 * Budget entity matching Firebase webapp schema
 * 
 * Tracks spending limits across categories with different time periods:
 * - Monthly budgets for regular expenses
 * - Quarterly budgets for periodic costs
 * - Yearly budgets for long-term planning
 * 
 * Features:
 * - Real-time spending tracking
 * - Category-based allocation
 * - Alert notifications when approaching limits
 * - Historical budget analysis
 * 
 * Security:
 * - Budget data encrypted at rest
 * - Secure sync with Firebase
 */
@Entity(tableName = "budgets")
@TypeConverters(DateConverter::class, DecimalConverter::class, StringListConverter::class)
@Serializable
data class Budget(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    
    val userId: String,
    
    val name: String,
    
    val amount: BigDecimal,
    
    val period: BudgetPeriod,
    
    val categories: List<String>,
    
    val startDate: LocalDateTime,
    
    val endDate: LocalDateTime,
    
    val currentSpent: BigDecimal = BigDecimal.ZERO,
    
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    
    val lastSyncedAt: LocalDateTime? = null
) {
    
    /**
     * Budget periods
     */
    enum class BudgetPeriod {
        MONTHLY,
        QUARTERLY,
        YEARLY;
        
        companion object {
            fun fromString(value: String): BudgetPeriod {
                return when (value.lowercase()) {
                    "monthly" -> MONTHLY
                    "quarterly" -> QUARTERLY
                    "yearly" -> YEARLY
                    else -> MONTHLY
                }
            }
        }
        
        fun toFirestore(): String {
            return when (this) {
                MONTHLY -> "monthly"
                QUARTERLY -> "quarterly"
                YEARLY -> "yearly"
            }
        }
        
        fun getDisplayName(): String {
            return when (this) {
                MONTHLY -> "Monthly"
                QUARTERLY -> "Quarterly"
                YEARLY -> "Yearly"
            }
        }
    }
    
    /**
     * Calculate percentage spent
     */
    fun getPercentageSpent(): Double {
        if (amount == BigDecimal.ZERO) return 0.0
        return (currentSpent.divide(amount, 2, BigDecimal.ROUND_HALF_UP) * BigDecimal(100)).toDouble()
    }
    
    /**
     * Calculate remaining amount
     */
    fun getRemainingAmount(): BigDecimal {
        return (amount - currentSpent).max(BigDecimal.ZERO)
    }
    
    /**
     * Check if budget is exceeded
     */
    fun isExceeded(): Boolean {
        return currentSpent > amount
    }
    
    /**
     * Check if budget is approaching limit (>= 80%)
     */
    fun isApproachingLimit(): Boolean {
        return getPercentageSpent() >= 80.0
    }
    
    /**
     * Check if budget is active for current date
     */
    fun isActive(): Boolean {
        val now = LocalDateTime.now()
        return now.isAfter(startDate) && now.isBefore(endDate)
    }
    
    /**
     * Get days remaining in budget period
     */
    fun getDaysRemaining(): Long {
        val now = LocalDateTime.now()
        if (now.isAfter(endDate)) return 0
        return java.time.Duration.between(now, endDate).toDays()
    }
    
    /**
     * Check if budget needs sync
     */
    fun needsSync(): Boolean {
        val lastSync = lastSyncedAt ?: return true
        val minutesSinceSync = java.time.Duration.between(lastSync, LocalDateTime.now()).toMinutes()
        return minutesSinceSync >= 15 // Sync if more than 15 minutes old
    }
    
    /**
     * Create a copy marked as synced
     */
    fun markSynced(): Budget {
        return copy(
            lastSyncedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
    }
    
    /**
     * Get status color
     */
    fun getStatusColor(): BudgetStatus {
        return when {
            isExceeded() -> BudgetStatus.EXCEEDED
            isApproachingLimit() -> BudgetStatus.WARNING
            else -> BudgetStatus.HEALTHY
        }
    }
    
    enum class BudgetStatus {
        HEALTHY,
        WARNING,
        EXCEEDED
    }
}
