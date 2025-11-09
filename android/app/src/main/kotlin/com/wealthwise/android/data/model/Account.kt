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
 * Account entity matching Firebase webapp schema
 * 
 * Supports multiple account types:
 * - Bank accounts
 * - Credit cards
 * - UPI wallets
 * - Brokerage accounts
 * 
 * Features:
 * - Room local persistence with encryption
 * - Firebase Firestore synchronization
 * - Automatic balance calculation from transactions
 * 
 * Security:
 * - Sensitive data encrypted at rest
 * - Account details secured with Android Keystore
 */
@Entity(tableName = "accounts")
@TypeConverters(DateConverter::class, DecimalConverter::class)
@Serializable
data class Account(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    
    val userId: String,
    
    val name: String,
    
    val type: AccountType,
    
    val institution: String? = null,
    
    val currentBalance: BigDecimal = BigDecimal.ZERO,
    
    val currency: String = "INR",
    
    val isArchived: Boolean = false,
    
    val createdAt: LocalDateTime = LocalDateTime.now(),
    
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    
    val lastSyncedAt: LocalDateTime? = null
) {
    
    /**
     * Account types supported by the system
     */
    enum class AccountType {
        BANK,
        CREDIT_CARD,
        UPI,
        BROKERAGE;
        
        companion object {
            fun fromString(value: String): AccountType {
                return when (value.lowercase()) {
                    "bank" -> BANK
                    "credit_card" -> CREDIT_CARD
                    "upi" -> UPI
                    "brokerage" -> BROKERAGE
                    else -> BANK
                }
            }
        }
        
        fun toFirestore(): String {
            return when (this) {
                BANK -> "bank"
                CREDIT_CARD -> "credit_card"
                UPI -> "upi"
                BROKERAGE -> "brokerage"
            }
        }
    }
    
    /**
     * Get display icon for account type
     */
    fun getIconName(): String {
        return when (type) {
            AccountType.BANK -> "account_balance"
            AccountType.CREDIT_CARD -> "credit_card"
            AccountType.UPI -> "currency_rupee"
            AccountType.BROKERAGE -> "trending_up"
        }
    }
    
    /**
     * Check if account needs sync
     */
    fun needsSync(): Boolean {
        val lastSync = lastSyncedAt ?: return true
        val hoursSinceSync = java.time.Duration.between(lastSync, LocalDateTime.now()).toHours()
        return hoursSinceSync >= 1 // Sync if more than 1 hour old
    }
    
    /**
     * Create a copy marked as synced
     */
    fun markSynced(): Account {
        return copy(
            lastSyncedAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )
    }
}
