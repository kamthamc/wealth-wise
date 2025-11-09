package com.wealthwise.android.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.wealthwise.android.data.local.converters.DateConverter
import com.wealthwise.android.data.local.converters.DecimalConverter
import kotlinx.serialization.Serializable
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.UUID

/**
 * Goal entity matching Firebase webapp schema
 * 
 * Tracks financial goals with contribution history:
 * - Savings goals (emergency fund, vacation, etc.)
 * - Investment goals (retirement, wealth building)
 * - Purchase goals (house, car, electronics)
 * 
 * Features:
 * - Target amount and date tracking
 * - Contribution history
 * - Progress visualization
 * - Automatic milestone notifications
 * 
 * Security:
 * - Goal data encrypted at rest
 * - Secure sync with Firebase
 */
@Entity(tableName = "goals")
@TypeConverters(DateConverter::class, DecimalConverter::class)
@Serializable
data class Goal(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    
    val userId: String,
    
    val name: String,
    
    val targetAmount: BigDecimal,
    
    val currentAmount: BigDecimal = BigDecimal.ZERO,
    
    val targetDate: LocalDateTime,
    
    val type: GoalType,
    
    val priority: GoalPriority,
    
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    
    val lastSyncedAt: LocalDateTime? = null
) {
    
    /**
     * Goal types
     */
    enum class GoalType {
        SAVINGS,
        INVESTMENT,
        PURCHASE;
        
        companion object {
            fun fromString(value: String): GoalType {
                return when (value.lowercase()) {
                    "savings" -> SAVINGS
                    "investment" -> INVESTMENT
                    "purchase" -> PURCHASE
                    else -> SAVINGS
                }
            }
        }
        
        fun toFirestore(): String {
            return when (this) {
                SAVINGS -> "savings"
                INVESTMENT -> "investment"
                PURCHASE -> "purchase"
            }
        }
        
        fun getDisplayName(): String {
            return when (this) {
                SAVINGS -> "Savings"
                INVESTMENT -> "Investment"
                PURCHASE -> "Purchase"
            }
        }
    }
    
    /**
     * Goal priority levels
     */
    enum class GoalPriority {
        LOW,
        MEDIUM,
        HIGH;
        
        companion object {
            fun fromString(value: String): GoalPriority {
                return when (value.lowercase()) {
                    "low" -> LOW
                    "medium" -> MEDIUM
                    "high" -> HIGH
                    else -> MEDIUM
                }
            }
        }
        
        fun toFirestore(): String {
            return when (this) {
                LOW -> "low"
                MEDIUM -> "medium"
                HIGH -> "high"
            }
        }
        
        fun getDisplayName(): String {
            return when (this) {
                LOW -> "Low Priority"
                MEDIUM -> "Medium Priority"
                HIGH -> "High Priority"
            }
        }
    }
    
    /**
     * Calculate progress percentage
     */
    fun getProgressPercentage(): Double {
        if (targetAmount == BigDecimal.ZERO) return 0.0
        return (currentAmount.divide(targetAmount, 2, BigDecimal.ROUND_HALF_UP) * BigDecimal(100))
            .toDouble()
            .coerceIn(0.0, 100.0)
    }
    
    /**
     * Calculate remaining amount
     */
    fun getRemainingAmount(): BigDecimal {
        return (targetAmount - currentAmount).max(BigDecimal.ZERO)
    }
    
    /**
     * Check if goal is completed
     */
    fun isCompleted(): Boolean {
        return currentAmount >= targetAmount
    }
    
    /**
     * Check if goal is overdue
     */
    fun isOverdue(): Boolean {
        return !isCompleted() && LocalDateTime.now().isAfter(targetDate)
    }
    
    /**
     * Get days remaining to target date
     */
    fun getDaysRemaining(): Long {
        val now = LocalDateTime.now()
        if (now.isAfter(targetDate)) return 0
        return java.time.Duration.between(now, targetDate).toDays()
    }
    
    /**
     * Calculate required monthly contribution to reach goal
     */
    fun getRequiredMonthlyContribution(): BigDecimal {
        val remaining = getRemainingAmount()
        val daysRemaining = getDaysRemaining()
        
        if (daysRemaining <= 0) return BigDecimal.ZERO
        
        val monthsRemaining = (daysRemaining / 30.0).coerceAtLeast(1.0)
        return remaining.divide(BigDecimal(monthsRemaining), 2, BigDecimal.ROUND_HALF_UP)
    }
    
    /**
     * Check if on track to meet goal
     */
    fun isOnTrack(): Boolean {
        if (isCompleted()) return true
        
        val now = LocalDateTime.now()
        val totalDays = java.time.Duration.between(createdAt, targetDate).toDays()
        val daysElapsed = java.time.Duration.between(createdAt, now).toDays()
        
        if (totalDays <= 0) return true
        
        val expectedProgress = (daysElapsed.toDouble() / totalDays.toDouble()) * 100
        val actualProgress = getProgressPercentage()
        
        return actualProgress >= expectedProgress * 0.9 // Within 90% of expected progress
    }
    
    /**
     * Check if goal needs sync
     */
    fun needsSync(): Boolean {
        val lastSync = lastSyncedAt ?: return true
        val minutesSinceSync = java.time.Duration.between(lastSync, LocalDateTime.now()).toMinutes()
        return minutesSinceSync >= 15 // Sync if more than 15 minutes old
    }
    
    /**
     * Create a copy marked as synced
     */
    fun markSynced(): Goal {
        return copy(
            lastSyncedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
    }
    
    /**
     * Get status
     */
    fun getStatus(): GoalStatus {
        return when {
            isCompleted() -> GoalStatus.COMPLETED
            isOverdue() -> GoalStatus.OVERDUE
            isOnTrack() -> GoalStatus.ON_TRACK
            else -> GoalStatus.BEHIND
        }
    }
    
    enum class GoalStatus {
        ON_TRACK,
        BEHIND,
        OVERDUE,
        COMPLETED
    }
}
