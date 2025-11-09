package com.wealthwise.android.data.repository

import com.wealthwise.android.data.local.dao.BudgetDao
import com.wealthwise.android.data.model.Budget
import com.wealthwise.android.data.remote.firebase.FirestoreService
import kotlinx.coroutines.flow.Flow
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for budget data operations.
 * 
 * Handles budget tracking and spending calculations.
 */
@Singleton
class BudgetRepository @Inject constructor(
    private val budgetDao: BudgetDao,
    private val firestoreService: FirestoreService
) {
    
    /**
     * Get all budgets as a Flow.
     */
    fun getAllBudgets(): Flow<List<Budget>> {
        return budgetDao.getAllFlow()
    }
    
    /**
     * Get active budgets (current date within budget period).
     */
    fun getActiveBudgets(): Flow<List<Budget>> {
        return budgetDao.getActiveBudgetsFlow()
    }
    
    /**
     * Get budgets by period type.
     */
    fun getBudgetsByPeriod(period: Budget.BudgetPeriod): Flow<List<Budget>> {
        return budgetDao.getByPeriodFlow(period)
    }
    
    /**
     * Get a single budget by ID.
     */
    suspend fun getBudgetById(budgetId: String): Budget? {
        return budgetDao.getById(budgetId)
    }
    
    /**
     * Create a new budget.
     */
    suspend fun createBudget(
        userId: String,
        name: String,
        amount: BigDecimal,
        period: Budget.BudgetPeriod,
        categories: List<String>,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): Result<Budget> {
        return try {
            val budget = Budget(
                id = UUID.randomUUID().toString(),
                userId = userId,
                name = name,
                amount = amount,
                period = period,
                categories = categories,
                startDate = startDate,
                endDate = endDate,
                currentSpent = BigDecimal.ZERO,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            budgetDao.insert(budget)
            syncBudgetToFirestore(budget)
            
            Result.success(budget)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing budget.
     */
    suspend fun updateBudget(budget: Budget): Result<Unit> {
        return try {
            val updatedBudget = budget.copy(
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            budgetDao.update(updatedBudget)
            syncBudgetToFirestore(updatedBudget)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update budget spending amount.
     */
    suspend fun updateSpending(budgetId: String, newSpent: BigDecimal): Result<Unit> {
        return try {
            budgetDao.updateSpent(budgetId, newSpent, LocalDateTime.now())
            
            val budget = budgetDao.getById(budgetId)
            if (budget != null) {
                syncBudgetToFirestore(budget)
            }
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete a budget.
     */
    suspend fun deleteBudget(budgetId: String): Result<Unit> {
        return try {
            budgetDao.deleteById(budgetId)
            firestoreService.deleteBudget(budgetId)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Check if any budget is exceeded or approaching limit.
     */
    suspend fun getBudgetAlerts(): List<BudgetAlert> {
        val budgets = budgetDao.getActiveBudgets()
        val alerts = mutableListOf<BudgetAlert>()
        
        budgets.forEach { budget ->
            when {
                budget.isExceeded() -> {
                    alerts.add(
                        BudgetAlert(
                            budgetId = budget.id,
                            budgetName = budget.name,
                            severity = AlertSeverity.CRITICAL,
                            message = "Budget exceeded by ${budget.getPercentageSpent() - 100}%"
                        )
                    )
                }
                budget.isApproachingLimit() -> {
                    alerts.add(
                        BudgetAlert(
                            budgetId = budget.id,
                            budgetName = budget.name,
                            severity = AlertSeverity.WARNING,
                            message = "${budget.getPercentageSpent()}% of budget used"
                        )
                    )
                }
            }
        }
        
        return alerts
    }
    
    /**
     * Sync budget to Firestore.
     */
    private suspend fun syncBudgetToFirestore(budget: Budget) {
        try {
            val result = firestoreService.updateBudget(budget)
            if (result.isSuccess) {
                budgetDao.markSynced(budget.id, LocalDateTime.now())
            }
        } catch (e: Exception) {
            // Silent failure
        }
    }
    
    /**
     * Force sync all pending budgets.
     */
    suspend fun syncPendingBudgets(): Result<Int> {
        return try {
            val budgets = budgetDao.getBudgetsNeedingSync()
            var syncedCount = 0
            
            budgets.forEach { budget ->
                val result = firestoreService.updateBudget(budget)
                if (result.isSuccess) {
                    budgetDao.markSynced(budget.id, LocalDateTime.now())
                    syncedCount++
                }
            }
            
            Result.success(syncedCount)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Budget alert data class.
     */
    data class BudgetAlert(
        val budgetId: String,
        val budgetName: String,
        val severity: AlertSeverity,
        val message: String
    )
    
    enum class AlertSeverity {
        WARNING,
        CRITICAL
    }
}
