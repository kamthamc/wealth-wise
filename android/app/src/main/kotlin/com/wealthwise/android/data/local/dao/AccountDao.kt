package com.wealthwise.android.data.local.dao

import androidx.room.*
import com.wealthwise.android.data.model.Account
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for Account entity
 * 
 * Provides type-safe database operations:
 * - CRUD operations for accounts
 * - Query by type, status
 * - Flow-based reactive queries
 * - Foreign key cascade deletes
 */
@Dao
interface AccountDao {
    
    /**
     * Insert new account
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(account: Account): Long
    
    /**
     * Insert multiple accounts
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(accounts: List<Account>)
    
    /**
     * Update existing account
     */
    @Update
    suspend fun update(account: Account)
    
    /**
     * Delete account
     */
    @Delete
    suspend fun delete(account: Account)
    
    /**
     * Delete account by ID
     */
    @Query("DELETE FROM accounts WHERE id = :accountId")
    suspend fun deleteById(accountId: String)
    
    /**
     * Get all accounts as Flow (reactive)
     */
    @Query("SELECT * FROM accounts ORDER BY createdAt DESC")
    fun getAllFlow(): Flow<List<Account>>
    
    /**
     * Get all accounts (one-time)
     */
    @Query("SELECT * FROM accounts ORDER BY createdAt DESC")
    suspend fun getAll(): List<Account>
    
    /**
     * Get account by ID as Flow
     */
    @Query("SELECT * FROM accounts WHERE id = :accountId")
    fun getByIdFlow(accountId: String): Flow<Account?>
    
    /**
     * Get account by ID (one-time)
     */
    @Query("SELECT * FROM accounts WHERE id = :accountId")
    suspend fun getById(accountId: String): Account?
    
    /**
     * Get active (non-archived) accounts
     */
    @Query("SELECT * FROM accounts WHERE isArchived = 0 ORDER BY createdAt DESC")
    fun getActiveAccountsFlow(): Flow<List<Account>>
    
    /**
     * Get accounts by type
     */
    @Query("SELECT * FROM accounts WHERE type = :type AND isArchived = 0 ORDER BY createdAt DESC")
    fun getAccountsByTypeFlow(type: Account.AccountType): Flow<List<Account>>
    
    /**
     * Get accounts that need sync
     */
    @Query("SELECT * FROM accounts WHERE lastSyncedAt IS NULL OR datetime(lastSyncedAt) < datetime('now', '-1 hour')")
    suspend fun getAccountsNeedingSync(): List<Account>
    
    /**
     * Archive account
     */
    @Query("UPDATE accounts SET isArchived = 1, updatedAt = datetime('now') WHERE id = :accountId")
    suspend fun archive(accountId: String)
    
    /**
     * Unarchive account
     */
    @Query("UPDATE accounts SET isArchived = 0, updatedAt = datetime('now') WHERE id = :accountId")
    suspend fun unarchive(accountId: String)
    
    /**
     * Update account balance
     */
    @Query("UPDATE accounts SET currentBalance = :balance, updatedAt = datetime('now') WHERE id = :accountId")
    suspend fun updateBalance(accountId: String, balance: String)
    
    /**
     * Mark account as synced
     */
    @Query("UPDATE accounts SET lastSyncedAt = datetime('now'), updatedAt = datetime('now') WHERE id = :accountId")
    suspend fun markSynced(accountId: String)
    
    /**
     * Get total balance across all active accounts
     */
    @Query("SELECT SUM(CAST(currentBalance AS REAL)) FROM accounts WHERE isArchived = 0")
    suspend fun getTotalBalance(): Double?
    
    /**
     * Search accounts by name
     */
    @Query("SELECT * FROM accounts WHERE name LIKE '%' || :query || '%' AND isArchived = 0 ORDER BY createdAt DESC")
    fun searchAccounts(query: String): Flow<List<Account>>
    
    /**
     * Delete all accounts (for testing)
     */
    @Query("DELETE FROM accounts")
    suspend fun deleteAll()
}
