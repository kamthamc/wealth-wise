package com.wealthwise.android.data.repository

import com.wealthwise.android.data.local.dao.TransactionDao
import com.wealthwise.android.data.model.Transaction
import com.wealthwise.android.data.remote.firebase.FirestoreService
import kotlinx.coroutines.flow.Flow
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for transaction data operations.
 * 
 * Implements offline-first pattern with automatic balance updates.
 */
@Singleton
class TransactionRepository @Inject constructor(
    private val transactionDao: TransactionDao,
    private val firestoreService: FirestoreService,
    private val accountRepository: AccountRepository
) {
    
    /**
     * Get all transactions as a Flow.
     */
    fun getAllTransactions(): Flow<List<Transaction>> {
        return transactionDao.getAllFlow()
    }
    
    /**
     * Get transactions for a specific account.
     */
    fun getTransactionsByAccount(accountId: String): Flow<List<Transaction>> {
        return transactionDao.getByAccountFlow(accountId)
    }
    
    /**
     * Get recent transactions.
     * 
     * @param days Number of days to look back (default: 30)
     * @param limit Maximum number of transactions (default: 100)
     */
    fun getRecentTransactions(days: Int = 30, limit: Int = 100): Flow<List<Transaction>> {
        return transactionDao.getRecentTransactionsFlow(days, limit)
    }
    
    /**
     * Get transactions by date range.
     */
    fun getTransactionsByDateRange(
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): Flow<List<Transaction>> {
        return transactionDao.getByDateRangeFlow(startDate, endDate)
    }
    
    /**
     * Get transactions by category.
     */
    fun getTransactionsByCategory(category: String): Flow<List<Transaction>> {
        return transactionDao.getByCategoryFlow(category)
    }
    
    /**
     * Search transactions.
     */
    fun searchTransactions(query: String): Flow<List<Transaction>> {
        return transactionDao.searchTransactions(query)
    }
    
    /**
     * Get total by transaction type.
     */
    suspend fun getTotalByType(type: Transaction.TransactionType): BigDecimal {
        return transactionDao.getTotalByType(type)
    }
    
    /**
     * Get expenses grouped by category.
     */
    suspend fun getExpensesByCategory(): Map<String, Double> {
        return transactionDao.getExpensesByCategory()
    }
    
    /**
     * Create a new transaction.
     * Automatically updates account balance.
     */
    suspend fun createTransaction(
        userId: String,
        accountId: String,
        date: LocalDateTime,
        amount: BigDecimal,
        type: Transaction.TransactionType,
        category: String,
        description: String? = null,
        notes: String? = null
    ): Result<Transaction> {
        return try {
            val transaction = Transaction(
                id = UUID.randomUUID().toString(),
                userId = userId,
                accountId = accountId,
                date = date,
                amount = amount,
                type = type,
                category = category,
                description = description,
                notes = notes,
                createdAt = LocalDateTime.now(),
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            // Insert transaction
            transactionDao.insert(transaction)
            
            // Update account balance
            updateAccountBalance(accountId, transaction)
            
            // Sync to Firestore
            syncTransactionToFirestore(transaction)
            
            Result.success(transaction)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing transaction.
     * Recalculates account balance.
     */
    suspend fun updateTransaction(transaction: Transaction): Result<Unit> {
        return try {
            // Get old transaction to reverse its effect on balance
            val oldTransaction = transactionDao.getById(transaction.id)
            
            val updatedTransaction = transaction.copy(
                updatedAt = LocalDateTime.now(),
                lastSyncedAt = null
            )
            
            transactionDao.update(updatedTransaction)
            
            // Recalculate account balance
            if (oldTransaction != null) {
                reverseAccountBalance(transaction.accountId, oldTransaction)
            }
            updateAccountBalance(transaction.accountId, updatedTransaction)
            
            syncTransactionToFirestore(updatedTransaction)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete a transaction.
     * Reverses its effect on account balance.
     */
    suspend fun deleteTransaction(transactionId: String): Result<Unit> {
        return try {
            val transaction = transactionDao.getById(transactionId) ?: return Result.failure(
                Exception("Transaction not found")
            )
            
            // Reverse balance effect
            reverseAccountBalance(transaction.accountId, transaction)
            
            // Delete from local database
            transactionDao.deleteById(transactionId)
            
            // Delete from Firestore
            firestoreService.deleteTransaction(transactionId)
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete multiple transactions.
     */
    suspend fun deleteTransactions(transactionIds: List<String>): Result<Unit> {
        return try {
            // Get transactions to reverse balances
            val transactions = transactionIds.mapNotNull { id ->
                transactionDao.getById(id)
            }
            
            // Reverse balance effects
            transactions.forEach { transaction ->
                reverseAccountBalance(transaction.accountId, transaction)
            }
            
            // Delete from local database
            transactionDao.deleteByIds(transactionIds)
            
            // Delete from Firestore
            transactionIds.forEach { id ->
                firestoreService.deleteTransaction(id)
            }
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update account balance based on transaction.
     */
    private suspend fun updateAccountBalance(accountId: String, transaction: Transaction) {
        val account = accountRepository.getAccountById(accountId) ?: return
        
        val balanceChange = when (transaction.type) {
            Transaction.TransactionType.CREDIT -> transaction.amount
            Transaction.TransactionType.DEBIT -> -transaction.amount
        }
        
        val newBalance = account.currentBalance + balanceChange
        accountRepository.updateBalance(accountId, newBalance)
    }
    
    /**
     * Reverse account balance effect of a transaction.
     */
    private suspend fun reverseAccountBalance(accountId: String, transaction: Transaction) {
        val account = accountRepository.getAccountById(accountId) ?: return
        
        val balanceChange = when (transaction.type) {
            Transaction.TransactionType.CREDIT -> -transaction.amount
            Transaction.TransactionType.DEBIT -> transaction.amount
        }
        
        val newBalance = account.currentBalance + balanceChange
        accountRepository.updateBalance(accountId, newBalance)
    }
    
    /**
     * Sync transaction to Firestore.
     */
    private suspend fun syncTransactionToFirestore(transaction: Transaction) {
        try {
            val result = firestoreService.updateTransaction(transaction)
            if (result.isSuccess) {
                transactionDao.markSynced(transaction.id, LocalDateTime.now())
            }
        } catch (e: Exception) {
            // Silent failure - will retry on next sync
        }
    }
    
    /**
     * Force sync all pending transactions.
     */
    suspend fun syncPendingTransactions(): Result<Int> {
        return try {
            val transactions = transactionDao.getTransactionsNeedingSync()
            var syncedCount = 0
            
            transactions.forEach { transaction ->
                val result = firestoreService.updateTransaction(transaction)
                if (result.isSuccess) {
                    transactionDao.markSynced(transaction.id, LocalDateTime.now())
                    syncedCount++
                }
            }
            
            Result.success(syncedCount)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
