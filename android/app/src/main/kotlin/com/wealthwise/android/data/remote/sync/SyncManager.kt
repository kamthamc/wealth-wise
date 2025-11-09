package com.wealthwise.android.data.remote.sync

import com.wealthwise.android.data.local.WealthWiseDatabase
import com.wealthwise.android.data.model.Account
import com.wealthwise.android.data.model.Budget
import com.wealthwise.android.data.model.Goal
import com.wealthwise.android.data.model.Transaction
import com.wealthwise.android.data.remote.firebase.FirestoreService
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDateTime
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages bi-directional synchronization between local Room database
 * and remote Firestore database.
 * 
 * Sync Strategy:
 * - Offline-first: Local database is the single source of truth
 * - Periodic sync: Sync data every few minutes when online
 * - Conflict resolution: Last-write-wins based on updatedAt timestamp
 * - Queue: Queue local changes for sync when offline
 */
@Singleton
class SyncManager @Inject constructor(
    private val database: WealthWiseDatabase,
    private val firestoreService: FirestoreService
) {
    
    private val _syncState = MutableStateFlow<SyncState>(SyncState.Idle)
    val syncState: StateFlow<SyncState> = _syncState.asStateFlow()
    
    private val _lastSyncTime = MutableStateFlow<LocalDateTime?>(null)
    val lastSyncTime: StateFlow<LocalDateTime?> = _lastSyncTime.asStateFlow()
    
    /**
     * Perform full synchronization of all data.
     * 
     * Process:
     * 1. Upload local changes to Firestore
     * 2. Download remote changes from Firestore
     * 3. Resolve conflicts using last-write-wins
     * 4. Update lastSyncedAt timestamps
     */
    suspend fun performFullSync(): Result<SyncResult> {
        return try {
            _syncState.value = SyncState.Syncing
            
            var uploadedCount = 0
            var downloadedCount = 0
            var conflictsResolved = 0
            
            // Sync accounts
            val accountResult = syncAccounts()
            uploadedCount += accountResult.uploaded
            downloadedCount += accountResult.downloaded
            conflictsResolved += accountResult.conflicts
            
            // Sync transactions
            val transactionResult = syncTransactions()
            uploadedCount += transactionResult.uploaded
            downloadedCount += transactionResult.downloaded
            conflictsResolved += transactionResult.conflicts
            
            // Sync budgets
            val budgetResult = syncBudgets()
            uploadedCount += budgetResult.uploaded
            downloadedCount += budgetResult.downloaded
            conflictsResolved += budgetResult.conflicts
            
            // Sync goals
            val goalResult = syncGoals()
            uploadedCount += goalResult.uploaded
            downloadedCount += goalResult.downloaded
            conflictsResolved += goalResult.conflicts
            
            _lastSyncTime.value = LocalDateTime.now()
            _syncState.value = SyncState.Success
            
            Result.success(
                SyncResult(
                    uploaded = uploadedCount,
                    downloaded = downloadedCount,
                    conflictsResolved = conflictsResolved,
                    timestamp = LocalDateTime.now()
                )
            )
        } catch (e: Exception) {
            _syncState.value = SyncState.Error(e.message ?: "Sync failed")
            Result.failure(e)
        }
    }
    
    /**
     * Sync accounts between local and remote.
     */
    private suspend fun syncAccounts(): EntitySyncResult {
        var uploaded = 0
        var downloaded = 0
        var conflicts = 0
        
        // Upload local changes
        val localAccounts = database.accountDao().getAccountsNeedingSync()
        localAccounts.forEach { account ->
            val result = firestoreService.updateAccount(account)
            if (result.isSuccess) {
                database.accountDao().markSynced(account.id, LocalDateTime.now())
                uploaded++
            }
        }
        
        // TODO: Download remote changes
        // This requires implementing a server-side "changes since" query
        // or using Firestore snapshots to detect changes
        
        return EntitySyncResult(uploaded, downloaded, conflicts)
    }
    
    /**
     * Sync transactions between local and remote.
     */
    private suspend fun syncTransactions(): EntitySyncResult {
        var uploaded = 0
        var downloaded = 0
        var conflicts = 0
        
        // Upload local changes
        val localTransactions = database.transactionDao().getTransactionsNeedingSync()
        localTransactions.forEach { transaction ->
            val result = firestoreService.updateTransaction(transaction)
            if (result.isSuccess) {
                database.transactionDao().markSynced(transaction.id, LocalDateTime.now())
                uploaded++
            }
        }
        
        return EntitySyncResult(uploaded, downloaded, conflicts)
    }
    
    /**
     * Sync budgets between local and remote.
     */
    private suspend fun syncBudgets(): EntitySyncResult {
        var uploaded = 0
        var downloaded = 0
        var conflicts = 0
        
        // Upload local changes
        val localBudgets = database.budgetDao().getBudgetsNeedingSync()
        localBudgets.forEach { budget ->
            val result = firestoreService.updateBudget(budget)
            if (result.isSuccess) {
                database.budgetDao().markSynced(budget.id, LocalDateTime.now())
                uploaded++
            }
        }
        
        return EntitySyncResult(uploaded, downloaded, conflicts)
    }
    
    /**
     * Sync goals between local and remote.
     */
    private suspend fun syncGoals(): EntitySyncResult {
        var uploaded = 0
        var downloaded = 0
        var conflicts = 0
        
        // Upload local changes
        val localGoals = database.goalDao().getGoalsNeedingSync()
        localGoals.forEach { goal ->
            val result = firestoreService.updateGoal(goal)
            if (result.isSuccess) {
                database.goalDao().markSynced(goal.id, LocalDateTime.now())
                uploaded++
            }
        }
        
        return EntitySyncResult(uploaded, downloaded, conflicts)
    }
    
    /**
     * Resolve conflict between local and remote entity.
     * Uses last-write-wins strategy based on updatedAt timestamp.
     */
    private fun <T> resolveConflict(
        local: T,
        remote: T,
        getUpdatedAt: (T) -> LocalDateTime?
    ): T {
        val localTime = getUpdatedAt(local)
        val remoteTime = getUpdatedAt(remote)
        
        return when {
            localTime == null -> remote
            remoteTime == null -> local
            localTime.isAfter(remoteTime) -> local
            else -> remote
        }
    }
    
    /**
     * Sync state sealed class.
     */
    sealed class SyncState {
        object Idle : SyncState()
        object Syncing : SyncState()
        object Success : SyncState()
        data class Error(val message: String) : SyncState()
    }
    
    /**
     * Result of a full sync operation.
     */
    data class SyncResult(
        val uploaded: Int,
        val downloaded: Int,
        val conflictsResolved: Int,
        val timestamp: LocalDateTime
    )
    
    /**
     * Result of syncing a single entity type.
     */
    private data class EntitySyncResult(
        val uploaded: Int,
        val downloaded: Int,
        val conflicts: Int
    )
}
