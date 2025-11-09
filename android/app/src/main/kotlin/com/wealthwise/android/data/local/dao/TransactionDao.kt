package com.wealthwise.android.data.local.dao

import androidx.room.*
import com.wealthwise.android.data.model.Transaction
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

/**
 * Data Access Object for Transaction entity
 * 
 * Provides comprehensive transaction operations:
 * - CRUD operations
 * - Filtering by date, category, type, account
 * - Statistics and aggregations
 * - Full-text search
 * - Flow-based reactive queries
 */
@Dao
interface TransactionDao {
    
    /**
     * Insert new transaction
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(transaction: Transaction): Long
    
    /**
     * Insert multiple transactions
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(transactions: List<Transaction>)
    
    /**
     * Update existing transaction
     */
    @Update
    suspend fun update(transaction: Transaction)
    
    /**
     * Delete transaction
     */
    @Delete
    suspend fun delete(transaction: Transaction)
    
    /**
     * Delete transaction by ID
     */
    @Query("DELETE FROM transactions WHERE id = :transactionId")
    suspend fun deleteById(transactionId: String)
    
    /**
     * Delete multiple transactions
     */
    @Query("DELETE FROM transactions WHERE id IN (:transactionIds)")
    suspend fun deleteByIds(transactionIds: List<String>)
    
    /**
     * Get all transactions as Flow
     */
    @Query("SELECT * FROM transactions ORDER BY date DESC, createdAt DESC")
    fun getAllFlow(): Flow<List<Transaction>>
    
    /**
     * Get all transactions (one-time)
     */
    @Query("SELECT * FROM transactions ORDER BY date DESC, createdAt DESC")
    suspend fun getAll(): List<Transaction>
    
    /**
     * Get transaction by ID as Flow
     */
    @Query("SELECT * FROM transactions WHERE id = :transactionId")
    fun getByIdFlow(transactionId: String): Flow<Transaction?>
    
    /**
     * Get transaction by ID (one-time)
     */
    @Query("SELECT * FROM transactions WHERE id = :transactionId")
    suspend fun getById(transactionId: String): Transaction?
    
    /**
     * Get transactions for specific account
     */
    @Query("SELECT * FROM transactions WHERE accountId = :accountId ORDER BY date DESC, createdAt DESC")
    fun getByAccountIdFlow(accountId: String): Flow<List<Transaction>>
    
    /**
     * Get transactions by category
     */
    @Query("SELECT * FROM transactions WHERE category = :category ORDER BY date DESC, createdAt DESC")
    fun getByCategoryFlow(category: String): Flow<List<Transaction>>
    
    /**
     * Get transactions by type
     */
    @Query("SELECT * FROM transactions WHERE type = :type ORDER BY date DESC, createdAt DESC")
    fun getByTypeFlow(type: Transaction.TransactionType): Flow<List<Transaction>>
    
    /**
     * Get transactions in date range
     */
    @Query("SELECT * FROM transactions WHERE date BETWEEN :startDate AND :endDate ORDER BY date DESC, createdAt DESC")
    fun getByDateRangeFlow(startDate: LocalDateTime, endDate: LocalDateTime): Flow<List<Transaction>>
    
    /**
     * Get recent transactions (last N days)
     */
    @Query("SELECT * FROM transactions WHERE date >= datetime('now', '-' || :days || ' days') ORDER BY date DESC, createdAt DESC LIMIT :limit")
    fun getRecentTransactionsFlow(days: Int = 30, limit: Int = 100): Flow<List<Transaction>>
    
    /**
     * Get transactions that need sync
     */
    @Query("SELECT * FROM transactions WHERE lastSyncedAt IS NULL OR datetime(lastSyncedAt) < datetime('now', '-5 minutes')")
    suspend fun getTransactionsNeedingSync(): List<Transaction>
    
    /**
     * Search transactions
     */
    @Query("""
        SELECT * FROM transactions 
        WHERE description LIKE '%' || :query || '%' 
           OR category LIKE '%' || :query || '%'
           OR notes LIKE '%' || :query || '%'
        ORDER BY date DESC, createdAt DESC
    """)
    fun searchTransactions(query: String): Flow<List<Transaction>>
    
    /**
     * Get total amount by type for account
     */
    @Query("SELECT SUM(CAST(amount AS REAL)) FROM transactions WHERE accountId = :accountId AND type = :type")
    suspend fun getTotalByType(accountId: String, type: Transaction.TransactionType): Double?
    
    /**
     * Get total expenses by category
     */
    @Query("""
        SELECT category, SUM(CAST(amount AS REAL)) as total
        FROM transactions 
        WHERE type = 'DEBIT' AND date BETWEEN :startDate AND :endDate
        GROUP BY category
        ORDER BY total DESC
    """)
    suspend fun getExpensesByCategory(startDate: LocalDateTime, endDate: LocalDateTime): Map<String, Double>
    
    /**
     * Get transaction count for account
     */
    @Query("SELECT COUNT(*) FROM transactions WHERE accountId = :accountId")
    suspend fun getTransactionCount(accountId: String): Int
    
    /**
     * Mark transaction as synced
     */
    @Query("UPDATE transactions SET lastSyncedAt = datetime('now'), updatedAt = datetime('now') WHERE id = :transactionId")
    suspend fun markSynced(transactionId: String)
    
    /**
     * Delete all transactions (for testing)
     */
    @Query("DELETE FROM transactions")
    suspend fun deleteAll()
    
    /**
     * Delete transactions for account
     */
    @Query("DELETE FROM transactions WHERE accountId = :accountId")
    suspend fun deleteByAccountId(accountId: String)
}
