package com.wealthwise.android.data.remote.firebase

import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.Source
import com.wealthwise.android.data.model.Account
import com.wealthwise.android.data.model.Budget
import com.wealthwise.android.data.model.Goal
import com.wealthwise.android.data.model.Transaction
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.math.BigDecimal
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for Firestore database operations.
 * 
 * Provides CRUD operations and real-time listeners for:
 * - Accounts
 * - Transactions
 * - Budgets
 * - Goals
 * 
 * All methods follow offline-first approach with Firestore cache.
 */
@Singleton
class FirestoreService @Inject constructor(
    private val firestore: FirebaseFirestore,
    private val authService: FirebaseAuthService
) {
    
    companion object {
        private const val COLLECTION_ACCOUNTS = "accounts"
        private const val COLLECTION_TRANSACTIONS = "transactions"
        private const val COLLECTION_BUDGETS = "budgets"
        private const val COLLECTION_GOALS = "goals"
        private const val FIELD_USER_ID = "userId"
        private const val FIELD_UPDATED_AT = "updatedAt"
    }
    
    private val userId: String
        get() = authService.currentUserId ?: throw IllegalStateException("User not signed in")
    
    // ============================================
    // Account Operations
    // ============================================
    
    /**
     * Get all accounts for the current user as a Flow.
     * Emits updates in real-time.
     */
    fun getAccountsFlow(): Flow<List<Account>> = callbackFlow {
        val registration = firestore.collection(COLLECTION_ACCOUNTS)
            .whereEqualTo(FIELD_USER_ID, userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val accounts = snapshot?.documents?.mapNotNull { doc ->
                    documentToAccount(doc)
                } ?: emptyList()
                
                trySend(accounts)
            }
        
        awaitClose { registration.remove() }
    }
    
    /**
     * Get a single account by ID.
     */
    suspend fun getAccount(accountId: String): Result<Account?> {
        return try {
            val doc = firestore.collection(COLLECTION_ACCOUNTS)
                .document(accountId)
                .get()
                .await()
            
            val account = documentToAccount(doc)
            Result.success(account)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Create a new account in Firestore.
     */
    suspend fun createAccount(account: Account): Result<Unit> {
        return try {
            val data = accountToMap(account)
            firestore.collection(COLLECTION_ACCOUNTS)
                .document(account.id)
                .set(data)
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing account in Firestore.
     */
    suspend fun updateAccount(account: Account): Result<Unit> {
        return try {
            val data = accountToMap(account)
            firestore.collection(COLLECTION_ACCOUNTS)
                .document(account.id)
                .set(data, SetOptions.merge())
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete an account from Firestore.
     */
    suspend fun deleteAccount(accountId: String): Result<Unit> {
        return try {
            firestore.collection(COLLECTION_ACCOUNTS)
                .document(accountId)
                .delete()
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // ============================================
    // Transaction Operations
    // ============================================
    
    /**
     * Get all transactions for the current user as a Flow.
     * Emits updates in real-time.
     */
    fun getTransactionsFlow(): Flow<List<Transaction>> = callbackFlow {
        val registration = firestore.collection(COLLECTION_TRANSACTIONS)
            .whereEqualTo(FIELD_USER_ID, userId)
            .orderBy("date", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val transactions = snapshot?.documents?.mapNotNull { doc ->
                    documentToTransaction(doc)
                } ?: emptyList()
                
                trySend(transactions)
            }
        
        awaitClose { registration.remove() }
    }
    
    /**
     * Get transactions for a specific account.
     */
    fun getTransactionsByAccountFlow(accountId: String): Flow<List<Transaction>> = callbackFlow {
        val registration = firestore.collection(COLLECTION_TRANSACTIONS)
            .whereEqualTo(FIELD_USER_ID, userId)
            .whereEqualTo("accountId", accountId)
            .orderBy("date", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val transactions = snapshot?.documents?.mapNotNull { doc ->
                    documentToTransaction(doc)
                } ?: emptyList()
                
                trySend(transactions)
            }
        
        awaitClose { registration.remove() }
    }
    
    /**
     * Create a new transaction in Firestore.
     */
    suspend fun createTransaction(transaction: Transaction): Result<Unit> {
        return try {
            val data = transactionToMap(transaction)
            firestore.collection(COLLECTION_TRANSACTIONS)
                .document(transaction.id)
                .set(data)
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing transaction in Firestore.
     */
    suspend fun updateTransaction(transaction: Transaction): Result<Unit> {
        return try {
            val data = transactionToMap(transaction)
            firestore.collection(COLLECTION_TRANSACTIONS)
                .document(transaction.id)
                .set(data, SetOptions.merge())
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete a transaction from Firestore.
     */
    suspend fun deleteTransaction(transactionId: String): Result<Unit> {
        return try {
            firestore.collection(COLLECTION_TRANSACTIONS)
                .document(transactionId)
                .delete()
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // ============================================
    // Budget Operations
    // ============================================
    
    /**
     * Get all budgets for the current user as a Flow.
     */
    fun getBudgetsFlow(): Flow<List<Budget>> = callbackFlow {
        val registration = firestore.collection(COLLECTION_BUDGETS)
            .whereEqualTo(FIELD_USER_ID, userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val budgets = snapshot?.documents?.mapNotNull { doc ->
                    documentToBudget(doc)
                } ?: emptyList()
                
                trySend(budgets)
            }
        
        awaitClose { registration.remove() }
    }
    
    /**
     * Create a new budget in Firestore.
     */
    suspend fun createBudget(budget: Budget): Result<Unit> {
        return try {
            val data = budgetToMap(budget)
            firestore.collection(COLLECTION_BUDGETS)
                .document(budget.id)
                .set(data)
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing budget in Firestore.
     */
    suspend fun updateBudget(budget: Budget): Result<Unit> {
        return try {
            val data = budgetToMap(budget)
            firestore.collection(COLLECTION_BUDGETS)
                .document(budget.id)
                .set(data, SetOptions.merge())
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete a budget from Firestore.
     */
    suspend fun deleteBudget(budgetId: String): Result<Unit> {
        return try {
            firestore.collection(COLLECTION_BUDGETS)
                .document(budgetId)
                .delete()
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // ============================================
    // Goal Operations
    // ============================================
    
    /**
     * Get all goals for the current user as a Flow.
     */
    fun getGoalsFlow(): Flow<List<Goal>> = callbackFlow {
        val registration = firestore.collection(COLLECTION_GOALS)
            .whereEqualTo(FIELD_USER_ID, userId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val goals = snapshot?.documents?.mapNotNull { doc ->
                    documentToGoal(doc)
                } ?: emptyList()
                
                trySend(goals)
            }
        
        awaitClose { registration.remove() }
    }
    
    /**
     * Create a new goal in Firestore.
     */
    suspend fun createGoal(goal: Goal): Result<Unit> {
        return try {
            val data = goalToMap(goal)
            firestore.collection(COLLECTION_GOALS)
                .document(goal.id)
                .set(data)
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update an existing goal in Firestore.
     */
    suspend fun updateGoal(goal: Goal): Result<Unit> {
        return try {
            val data = goalToMap(goal)
            firestore.collection(COLLECTION_GOALS)
                .document(goal.id)
                .set(data, SetOptions.merge())
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Delete a goal from Firestore.
     */
    suspend fun deleteGoal(goalId: String): Result<Unit> {
        return try {
            firestore.collection(COLLECTION_GOALS)
                .document(goalId)
                .delete()
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // ============================================
    // Conversion Methods
    // ============================================
    
    private fun documentToAccount(doc: DocumentSnapshot): Account? {
        return try {
            Account(
                id = doc.id,
                userId = doc.getString(FIELD_USER_ID) ?: return null,
                name = doc.getString("name") ?: return null,
                type = Account.AccountType.valueOf(doc.getString("type") ?: return null),
                institution = doc.getString("institution"),
                currentBalance = BigDecimal(doc.getString("currentBalance") ?: "0"),
                currency = doc.getString("currency") ?: "INR",
                isArchived = doc.getBoolean("isArchived") ?: false,
                createdAt = parseTimestamp(doc.getString("createdAt")),
                updatedAt = parseTimestamp(doc.getString("updatedAt")),
                lastSyncedAt = parseTimestamp(doc.getString("lastSyncedAt"))
            )
        } catch (e: Exception) {
            null
        }
    }
    
    private fun accountToMap(account: Account): Map<String, Any?> {
        return mapOf(
            FIELD_USER_ID to account.userId,
            "name" to account.name,
            "type" to account.type.name,
            "institution" to account.institution,
            "currentBalance" to account.currentBalance.toString(),
            "currency" to account.currency,
            "isArchived" to account.isArchived,
            "createdAt" to formatTimestamp(account.createdAt),
            "updatedAt" to formatTimestamp(LocalDateTime.now()),
            "lastSyncedAt" to formatTimestamp(LocalDateTime.now())
        )
    }
    
    private fun documentToTransaction(doc: DocumentSnapshot): Transaction? {
        return try {
            Transaction(
                id = doc.id,
                userId = doc.getString(FIELD_USER_ID) ?: return null,
                accountId = doc.getString("accountId") ?: return null,
                date = parseTimestamp(doc.getString("date")) ?: return null,
                amount = BigDecimal(doc.getString("amount") ?: return null),
                type = Transaction.TransactionType.valueOf(doc.getString("type") ?: return null),
                category = doc.getString("category") ?: "Other",
                description = doc.getString("description"),
                notes = doc.getString("notes"),
                createdAt = parseTimestamp(doc.getString("createdAt")),
                updatedAt = parseTimestamp(doc.getString("updatedAt")),
                lastSyncedAt = parseTimestamp(doc.getString("lastSyncedAt"))
            )
        } catch (e: Exception) {
            null
        }
    }
    
    private fun transactionToMap(transaction: Transaction): Map<String, Any?> {
        return mapOf(
            FIELD_USER_ID to transaction.userId,
            "accountId" to transaction.accountId,
            "date" to formatTimestamp(transaction.date),
            "amount" to transaction.amount.toString(),
            "type" to transaction.type.name,
            "category" to transaction.category,
            "description" to transaction.description,
            "notes" to transaction.notes,
            "createdAt" to formatTimestamp(transaction.createdAt),
            "updatedAt" to formatTimestamp(LocalDateTime.now()),
            "lastSyncedAt" to formatTimestamp(LocalDateTime.now())
        )
    }
    
    private fun documentToBudget(doc: DocumentSnapshot): Budget? {
        return try {
            Budget(
                id = doc.id,
                userId = doc.getString(FIELD_USER_ID) ?: return null,
                name = doc.getString("name") ?: return null,
                amount = BigDecimal(doc.getString("amount") ?: return null),
                period = Budget.BudgetPeriod.valueOf(doc.getString("period") ?: return null),
                categories = (doc.get("categories") as? List<*>)?.mapNotNull { it as? String } ?: emptyList(),
                startDate = parseTimestamp(doc.getString("startDate")) ?: return null,
                endDate = parseTimestamp(doc.getString("endDate")) ?: return null,
                currentSpent = BigDecimal(doc.getString("currentSpent") ?: "0"),
                createdAt = parseTimestamp(doc.getString("createdAt")),
                updatedAt = parseTimestamp(doc.getString("updatedAt")),
                lastSyncedAt = parseTimestamp(doc.getString("lastSyncedAt"))
            )
        } catch (e: Exception) {
            null
        }
    }
    
    private fun budgetToMap(budget: Budget): Map<String, Any?> {
        return mapOf(
            FIELD_USER_ID to budget.userId,
            "name" to budget.name,
            "amount" to budget.amount.toString(),
            "period" to budget.period.name,
            "categories" to budget.categories,
            "startDate" to formatTimestamp(budget.startDate),
            "endDate" to formatTimestamp(budget.endDate),
            "currentSpent" to budget.currentSpent.toString(),
            "createdAt" to formatTimestamp(budget.createdAt),
            "updatedAt" to formatTimestamp(LocalDateTime.now()),
            "lastSyncedAt" to formatTimestamp(LocalDateTime.now())
        )
    }
    
    private fun documentToGoal(doc: DocumentSnapshot): Goal? {
        return try {
            Goal(
                id = doc.id,
                userId = doc.getString(FIELD_USER_ID) ?: return null,
                name = doc.getString("name") ?: return null,
                targetAmount = BigDecimal(doc.getString("targetAmount") ?: return null),
                currentAmount = BigDecimal(doc.getString("currentAmount") ?: "0"),
                targetDate = parseTimestamp(doc.getString("targetDate")) ?: return null,
                type = Goal.GoalType.valueOf(doc.getString("type") ?: return null),
                priority = Goal.GoalPriority.valueOf(doc.getString("priority") ?: "MEDIUM"),
                createdAt = parseTimestamp(doc.getString("createdAt")),
                updatedAt = parseTimestamp(doc.getString("updatedAt")),
                lastSyncedAt = parseTimestamp(doc.getString("lastSyncedAt"))
            )
        } catch (e: Exception) {
            null
        }
    }
    
    private fun goalToMap(goal: Goal): Map<String, Any?> {
        return mapOf(
            FIELD_USER_ID to goal.userId,
            "name" to goal.name,
            "targetAmount" to goal.targetAmount.toString(),
            "currentAmount" to goal.currentAmount.toString(),
            "targetDate" to formatTimestamp(goal.targetDate),
            "type" to goal.type.name,
            "priority" to goal.priority.name,
            "createdAt" to formatTimestamp(goal.createdAt),
            "updatedAt" to formatTimestamp(LocalDateTime.now()),
            "lastSyncedAt" to formatTimestamp(LocalDateTime.now())
        )
    }
    
    private fun parseTimestamp(timestamp: String?): LocalDateTime? {
        if (timestamp == null) return null
        return try {
            LocalDateTime.parse(timestamp, DateTimeFormatter.ISO_DATE_TIME)
        } catch (e: Exception) {
            null
        }
    }
    
    private fun formatTimestamp(dateTime: LocalDateTime?): String? {
        return dateTime?.format(DateTimeFormatter.ISO_DATE_TIME)
    }
}
