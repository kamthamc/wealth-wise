package com.wealthwise.android.data.repository

import com.wealthwise.android.data.local.dao.AccountDao
import com.wealthwise.android.data.model.Account
import com.wealthwise.android.data.remote.firebase.FirestoreService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for account data operations.
 * 
 * Implements offline-first pattern:
 * - All reads come from local database
 * - All writes go to local database first, then sync to Firestore
 * - Conflicts resolved using last-write-wins strategy
 */
@Singleton
class AccountRepository @Inject constructor(
    private val accountDao: AccountDao,
    private val firestoreService: FirestoreService
) {
    
    /**
     * Get all accounts as a Flow.
     * Returns data from local database for instant display.
     */
    fun getAllAccounts(): Flow<List<Account>> {
        return accountDao.getAllFlow()
    }
    
    /**
     * Get active (non-archived) accounts.
     */
    fun getActiveAccounts(): Flow<List<Account>> {
        return accountDao.getActiveAccountsFlow()
    }
    
    /**
     * Get a single account by ID.
     */
    suspend fun getAccountById(accountId: String): Account? {
        return accountDao.getById(accountId)
    }
    
    /**
     * Get total balance across all active accounts.
     */
    suspend fun getTotalBalance(): BigDecimal {
        return accountDao.getTotalBalance()
    }
    
    /**
     * Create a new account.
     * 
     * @param userId User ID
     * @param name Account name
     * @param type Account type
     * @param institution Bank/institution name
     * @param initialBalance Initial account balance
     * @param currency Currency code (default: INR)
     * @return Result containing the created account or error
     */
    suspend fun createAccount(
        userId: String,
        name: String,
        type: Account.AccountType,
        institution: String?,
        initialBalance: BigDecimal,
        currency: String = "INR"
    ): Result<Account> {
        return try {
            val account = Account(
                id = UUID.randomUUID().toString(),
                userId = userId,
                name = name,
                type = type,
                institution = institution,
                currentBalance = initialBalance,
                currency = currency,
                isArchived = false,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null // Will be synced
            )
            
            // Insert into local database
            accountDao.insert(account)
            
            // Sync to Firestore in background
            syncAccountToFirestore(account)
            
            Result.success(account)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing account.
     */
    suspend fun updateAccount(account: Account): Result<Unit> {
        return try {
            val updatedAccount = account.copy(
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null // Mark as needs sync
            )
            
            accountDao.update(updatedAccount)
            syncAccountToFirestore(updatedAccount)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update account balance.
     */
    suspend fun updateBalance(accountId: String, newBalance: BigDecimal): Result<Unit> {
        return try {
            accountDao.updateBalance(accountId, newBalance, LocalDateTime.now())
            
            // Get updated account and sync
            val account = accountDao.getById(accountId)
            if (account != null) {
                syncAccountToFirestore(account)
            }
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Archive an account.
     */
    suspend fun archiveAccount(accountId: String): Result<Unit> {
        return try {
            val account = accountDao.getById(accountId) ?: return Result.failure(
                Exception("Account not found")
            )
            
            val archivedAccount = account.copy(
                isArchived = true,
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            accountDao.update(archivedAccount)
            syncAccountToFirestore(archivedAccount)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Unarchive an account.
     */
    suspend fun unarchiveAccount(accountId: String): Result<Unit> {
        return try {
            val account = accountDao.getById(accountId) ?: return Result.failure(
                Exception("Account not found")
            )
            
            val unarchivedAccount = account.copy(
                isArchived = false,
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            accountDao.update(unarchivedAccount)
            syncAccountToFirestore(unarchivedAccount)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete an account and all its transactions.
     */
    suspend fun deleteAccount(accountId: String): Result<Unit> {
        return try {
            // Delete from local database (cascade delete will handle transactions)
            accountDao.deleteById(accountId)
            
            // Delete from Firestore
            firestoreService.deleteAccount(accountId)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Search accounts by name or institution.
     */
    fun searchAccounts(query: String): Flow<List<Account>> {
        return accountDao.searchAccounts(query)
    }
    
    /**
     * Sync account to Firestore.
     * Runs in background and doesn't block UI.
     */
    private suspend fun syncAccountToFirestore(account: Account) {
        try {
            val result = firestoreService.updateAccount(account)
            if (result.isSuccess) {
                // Mark as synced in local database
                accountDao.markSynced(account.id, LocalDateTime.now())
            }
        } catch (e: Exception) {
            // Silent failure - will retry on next sync
            // TODO: Add to sync queue for retry
        }
    }
    
    /**
     * Force sync all accounts that need syncing.
     */
    suspend fun syncPendingAccounts(): Result<Int> {
        return try {
            val accounts = accountDao.getAccountsNeedingSync()
            var syncedCount = 0
            
            accounts.forEach { account ->
                val result = firestoreService.updateAccount(account)
                if (result.isSuccess) {
                    accountDao.markSynced(account.id, LocalDateTime.now())
                    syncedCount++
                }
            }
            
            Result.success(syncedCount)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
