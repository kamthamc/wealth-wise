package com.wealthwise.android.data.local.dao

import androidx.room.*
import com.wealthwise.android.data.model.Goal
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for Goal entity
 * 
 * Provides goal management operations:
 * - CRUD operations for goals
 * - Query by status, type, priority
 * - Progress tracking
 * - Contribution management
 */
@Dao
interface GoalDao {
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(goal: Goal): Long
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(goals: List<Goal>)
    
    @Update
    suspend fun update(goal: Goal)
    
    @Delete
    suspend fun delete(goal: Goal)
    
    @Query("DELETE FROM goals WHERE id = :goalId")
    suspend fun deleteById(goalId: String)
    
    @Query("SELECT * FROM goals ORDER BY priority DESC, targetDate ASC")
    fun getAllFlow(): Flow<List<Goal>>
    
    @Query("SELECT * FROM goals ORDER BY priority DESC, targetDate ASC")
    suspend fun getAll(): List<Goal>
    
    @Query("SELECT * FROM goals WHERE id = :goalId")
    fun getByIdFlow(goalId: String): Flow<Goal?>
    
    @Query("SELECT * FROM goals WHERE id = :goalId")
    suspend fun getById(goalId: String): Goal?
    
    /**
     * Get active goals (not completed, not overdue)
     */
    @Query("SELECT * FROM goals WHERE currentAmount < targetAmount AND targetDate > datetime('now') ORDER BY priority DESC, targetDate ASC")
    fun getActiveGoalsFlow(): Flow<List<Goal>>
    
    /**
     * Get completed goals
     */
    @Query("SELECT * FROM goals WHERE currentAmount >= targetAmount ORDER BY updatedAt DESC")
    fun getCompletedGoalsFlow(): Flow<List<Goal>>
    
    /**
     * Get goals by type
     */
    @Query("SELECT * FROM goals WHERE type = :type ORDER BY priority DESC, targetDate ASC")
    fun getByTypeFlow(type: Goal.GoalType): Flow<List<Goal>>
    
    /**
     * Get goals by priority
     */
    @Query("SELECT * FROM goals WHERE priority = :priority ORDER BY targetDate ASC")
    fun getByPriorityFlow(priority: Goal.GoalPriority): Flow<List<Goal>>
    
    /**
     * Get goals that need sync
     */
    @Query("SELECT * FROM goals WHERE lastSyncedAt IS NULL OR datetime(lastSyncedAt) < datetime('now', '-15 minutes')")
    suspend fun getGoalsNeedingSync(): List<Goal>
    
    /**
     * Update current amount
     */
    @Query("UPDATE goals SET currentAmount = :amount, updatedAt = datetime('now') WHERE id = :goalId")
    suspend fun updateCurrentAmount(goalId: String, amount: String)
    
    /**
     * Add contribution to goal
     */
    @Query("UPDATE goals SET currentAmount = currentAmount + :amount, updatedAt = datetime('now') WHERE id = :goalId")
    suspend fun addContribution(goalId: String, amount: String)
    
    /**
     * Mark goal as synced
     */
    @Query("UPDATE goals SET lastSyncedAt = datetime('now'), updatedAt = datetime('now') WHERE id = :goalId")
    suspend fun markSynced(goalId: String)
    
    @Query("DELETE FROM goals")
    suspend fun deleteAll()
}
