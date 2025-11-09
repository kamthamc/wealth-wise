package com.wealthwise.android.data.repository

import com.wealthwise.android.data.local.dao.GoalDao
import com.wealthwise.android.data.model.Goal
import com.wealthwise.android.data.remote.firebase.FirestoreService
import kotlinx.coroutines.flow.Flow
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for financial goal data operations.
 * 
 * Handles goal tracking, contributions, and progress calculations.
 */
@Singleton
class GoalRepository @Inject constructor(
    private val goalDao: GoalDao,
    private val firestoreService: FirestoreService
) {
    
    /**
     * Get all goals as a Flow.
     */
    fun getAllGoals(): Flow<List<Goal>> {
        return goalDao.getAllFlow()
    }
    
    /**
     * Get active goals (not yet completed).
     */
    fun getActiveGoals(): Flow<List<Goal>> {
        return goalDao.getActiveGoalsFlow()
    }
    
    /**
     * Get completed goals.
     */
    fun getCompletedGoals(): Flow<List<Goal>> {
        return goalDao.getCompletedGoalsFlow()
    }
    
    /**
     * Get goals by type.
     */
    fun getGoalsByType(type: Goal.GoalType): Flow<List<Goal>> {
        return goalDao.getByTypeFlow(type)
    }
    
    /**
     * Get goals by priority.
     */
    fun getGoalsByPriority(priority: Goal.GoalPriority): Flow<List<Goal>> {
        return goalDao.getByPriorityFlow(priority)
    }
    
    /**
     * Get a single goal by ID.
     */
    suspend fun getGoalById(goalId: String): Goal? {
        return goalDao.getById(goalId)
    }
    
    /**
     * Create a new goal.
     */
    suspend fun createGoal(
        userId: String,
        name: String,
        targetAmount: BigDecimal,
        targetDate: LocalDateTime,
        type: Goal.GoalType,
        priority: Goal.GoalPriority,
        initialAmount: BigDecimal = BigDecimal.ZERO
    ): Result<Goal> {
        return try {
            val goal = Goal(
                id = UUID.randomUUID().toString(),
                userId = userId,
                name = name,
                targetAmount = targetAmount,
                currentAmount = initialAmount,
                targetDate = targetDate,
                type = type,
                priority = priority,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            goalDao.insert(goal)
            syncGoalToFirestore(goal)
            
            Result.success(goal)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing goal.
     */
    suspend fun updateGoal(goal: Goal): Result<Unit> {
        return try {
            val updatedGoal = goal.copy(
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            goalDao.update(updatedGoal)
            syncGoalToFirestore(updatedGoal)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Add a contribution to a goal.
     */
    suspend fun addContribution(goalId: String, amount: BigDecimal): Result<Unit> {
        return try {
            val goal = goalDao.getById(goalId) ?: return Result.failure(
                Exception("Goal not found")
            )
            
            val newAmount = goal.currentAmount + amount
            goalDao.updateCurrentAmount(goalId, newAmount, LocalDateTime.now())
            
            val updatedGoal = goal.copy(
                currentAmount = newAmount,
                updatedAt = LocalDateTime.now()
            )
            syncGoalToFirestore(updatedGoal)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete a goal.
     */
    suspend fun deleteGoal(goalId: String): Result<Unit> {
        return try {
            goalDao.deleteById(goalId)
            firestoreService.deleteGoal(goalId)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Get goals that are behind schedule.
     */
    suspend fun getBehindScheduleGoals(): List<Goal> {
        val activeGoals = goalDao.getActiveGoals()
        return activeGoals.filter { goal ->
            !goal.isOnTrack() && !goal.isCompleted()
        }
    }
    
    /**
     * Get goal progress summary.
     */
    suspend fun getGoalProgressSummary(): GoalProgressSummary {
        val allGoals = goalDao.getAll()
        val activeGoals = allGoals.filter { !it.isCompleted() }
        val completedGoals = allGoals.filter { it.isCompleted() }
        
        val totalTargetAmount = allGoals.sumOf { it.targetAmount }
        val totalCurrentAmount = allGoals.sumOf { it.currentAmount }
        val averageProgress = if (allGoals.isNotEmpty()) {
            allGoals.sumOf { it.getProgressPercentage().toBigDecimal() } / allGoals.size.toBigDecimal()
        } else {
            BigDecimal.ZERO
        }
        
        return GoalProgressSummary(
            totalGoals = allGoals.size,
            activeGoals = activeGoals.size,
            completedGoals = completedGoals.size,
            totalTargetAmount = totalTargetAmount,
            totalCurrentAmount = totalCurrentAmount,
            averageProgress = averageProgress.toDouble()
        )
    }
    
    /**
     * Sync goal to Firestore.
     */
    private suspend fun syncGoalToFirestore(goal: Goal) {
        try {
            val result = firestoreService.updateGoal(goal)
            if (result.isSuccess) {
                goalDao.markSynced(goal.id, LocalDateTime.now())
            }
        } catch (e: Exception) {
            // Silent failure
        }
    }
    
    /**
     * Force sync all pending goals.
     */
    suspend fun syncPendingGoals(): Result<Int> {
        return try {
            val goals = goalDao.getGoalsNeedingSync()
            var syncedCount = 0
            
            goals.forEach { goal ->
                val result = firestoreService.updateGoal(goal)
                if (result.isSuccess) {
                    goalDao.markSynced(goal.id, LocalDateTime.now())
                    syncedCount++
                }
            }
            
            Result.success(syncedCount)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Goal progress summary data class.
     */
    data class GoalProgressSummary(
        val totalGoals: Int,
        val activeGoals: Int,
        val completedGoals: Int,
        val totalTargetAmount: BigDecimal,
        val totalCurrentAmount: BigDecimal,
        val averageProgress: Double
    )
}
