package com.wealthwise.android.data.local.dao

import androidx.room.*
import com.wealthwise.android.data.model.Budget
import kotlinx.coroutines.flow.Flow
import java.time.LocalDateTime

/**
 * Data Access Object for Budget entity
 * 
 * Provides budget management operations:
 * - CRUD operations for budgets
 * - Query active budgets
 * - Budget period filtering
 * - Spending calculations
 */
@Dao
interface BudgetDao {
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(budget: Budget): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(budgets: List<Budget>)
    
    @Update
    suspend fun update(budget: Budget)
    
    @Delete
    suspend fun delete(budget: Budget)
    
    @Query("DELETE FROM budgets WHERE id = :budgetId")
    suspend fun deleteById(budgetId: String)
    
    @Query("SELECT * FROM budgets ORDER BY startDate DESC")
    fun getAllFlow(): Flow<List<Budget>>
    
    @Query("SELECT * FROM budgets ORDER BY startDate DESC")
    suspend fun getAll(): List<Budget>
    
    @Query("SELECT * FROM budgets WHERE id = :budgetId")
    fun getByIdFlow(budgetId: String): Flow<Budget?>
    
    @Query("SELECT * FROM budgets WHERE id = :budgetId")
    suspend fun getById(budgetId: String): Budget?
    
    /**
     * Get active budgets (current date within budget period)
     */
    @Query("SELECT * FROM budgets WHERE date('now') BETWEEN startDate AND endDate ORDER BY startDate DESC")
    fun getActiveBudgetsFlow(): Flow<List<Budget>>
    
    /**
     * Get budgets by period
     */
    @Query("SELECT * FROM budgets WHERE period = :period ORDER BY startDate DESC")
    fun getByPeriodFlow(period: Budget.BudgetPeriod): Flow<List<Budget>>
    
    /**
     * Get budgets that need sync
     */
    @Query("SELECT * FROM budgets WHERE lastSyncedAt IS NULL OR datetime(lastSyncedAt) < datetime('now', '-15 minutes')")
    suspend fun getBudgetsNeedingSync(): List<Budget>
    
    /**
     * Update current spent amount
     */
    @Query("UPDATE budgets SET currentSpent = :amount, updatedAt = datetime('now') WHERE id = :budgetId")
    suspend fun updateSpent(budgetId: String, amount: String)
    
    /**
     * Mark budget as synced
     */
    @Query("UPDATE budgets SET lastSyncedAt = datetime('now'), updatedAt = datetime('now') WHERE id = :budgetId")
    suspend fun markSynced(budgetId: String)
    
    @Query("DELETE FROM budgets")
    suspend fun deleteAll()
}
