package com.wealthwise.android.features.transactions

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wealthwise.android.data.model.Transaction
import com.wealthwise.android.data.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.math.BigDecimal
import java.time.LocalDateTime
import javax.inject.Inject

/**
 * ViewModel for transactions feature.
 * 
 * Manages transaction list, creation, updates, deletion, and filtering.
 */
@HiltViewModel
class TransactionsViewModel @Inject constructor(
    private val transactionRepository: TransactionRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<TransactionsUiState>(TransactionsUiState.Loading)
    val uiState: StateFlow<TransactionsUiState> = _uiState.asStateFlow()
    
    private val _selectedAccountId = MutableStateFlow<String?>(null)
    val selectedAccountId: StateFlow<String?> = _selectedAccountId.asStateFlow()
    
    private val _selectedCategory = MutableStateFlow<String?>(null)
    val selectedCategory: StateFlow<String?> = _selectedCategory.asStateFlow()
    
    private val _selectedType = MutableStateFlow<Transaction.TransactionType?>(null)
    val selectedType: StateFlow<Transaction.TransactionType?> = _selectedType.asStateFlow()
    
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()
    
    private val _dateRange = MutableStateFlow<Pair<LocalDateTime, LocalDateTime>?>(null)
    val dateRange: StateFlow<Pair<LocalDateTime, LocalDateTime>?> = _dateRange.asStateFlow()
    
    /**
     * Transactions StateFlow with filters applied.
     */
    val transactions: StateFlow<List<Transaction>> = combine(
        _selectedAccountId,
        _selectedCategory,
        _selectedType,
        _searchQuery,
        _dateRange
    ) { accountId, category, type, query, dateRange ->
        FilterCriteria(accountId, category, type, query, dateRange)
    }.catch { exception ->
        _uiState.value = TransactionsUiState.Error(exception.message ?: "Failed to load transactions")
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
    
    init {
        loadTransactions()
    }
    
    /**
     * Load transactions with current filters.
     */
    private fun loadTransactions() {
        viewModelScope.launch {
            try {
                // Start with base query
                val baseFlow = when {
                    _selectedAccountId.value != null -> {
                        transactionRepository.getTransactionsByAccount(_selectedAccountId.value!!)
                    }
                    _dateRange.value != null -> {
                        val (start, end) = _dateRange.value!!
                        transactionRepository.getTransactionsByDateRange(start, end)
                    }
                    _searchQuery.value.isNotBlank() -> {
                        transactionRepository.searchTransactions(_searchQuery.value)
                    }
                    else -> {
                        transactionRepository.getRecentTransactions(days = 30, limit = 200)
                    }
                }
                
                // Apply additional filters
                baseFlow.collect { txns ->
                    var filtered = txns
                    
                    // Filter by category
                    _selectedCategory.value?.let { category ->
                        filtered = filtered.filter { it.category == category }
                    }
                    
                    // Filter by type
                    _selectedType.value?.let { type ->
                        filtered = filtered.filter { it.type == type }
                    }
                    
                    _uiState.value = if (filtered.isEmpty()) {
                        TransactionsUiState.Empty
                    } else {
                        TransactionsUiState.Success(filtered)
                    }
                }
            } catch (e: Exception) {
                _uiState.value = TransactionsUiState.Error(e.message ?: "Failed to load transactions")
            }
        }
    }
    
    /**
     * Create a new transaction.
     */
    fun createTransaction(
        userId: String,
        accountId: String,
        date: LocalDateTime,
        amount: String,
        type: Transaction.TransactionType,
        category: String,
        description: String?,
        notes: String?
    ) {
        // Validate input
        if (accountId.isBlank()) {
            _uiState.value = TransactionsUiState.Error("Account is required")
            return
        }
        
        if (category.isBlank()) {
            _uiState.value = TransactionsUiState.Error("Category is required")
            return
        }
        
        val amountDecimal = try {
            BigDecimal(amount)
        } catch (e: Exception) {
            _uiState.value = TransactionsUiState.Error("Invalid amount")
            return
        }
        
        if (amountDecimal <= BigDecimal.ZERO) {
            _uiState.value = TransactionsUiState.Error("Amount must be greater than zero")
            return
        }
        
        viewModelScope.launch {
            _uiState.value = TransactionsUiState.Loading
            
            val result = transactionRepository.createTransaction(
                userId = userId,
                accountId = accountId,
                date = date,
                amount = amountDecimal,
                type = type,
                category = category,
                description = description,
                notes = notes
            )
            
            if (result.isSuccess) {
                loadTransactions()
            } else {
                _uiState.value = TransactionsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to create transaction"
                )
            }
        }
    }
    
    /**
     * Update an existing transaction.
     */
    fun updateTransaction(transaction: Transaction) {
        viewModelScope.launch {
            _uiState.value = TransactionsUiState.Loading
            
            val result = transactionRepository.updateTransaction(transaction)
            
            if (result.isSuccess) {
                loadTransactions()
            } else {
                _uiState.value = TransactionsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to update transaction"
                )
            }
        }
    }
    
    /**
     * Delete a transaction.
     */
    fun deleteTransaction(transactionId: String) {
        viewModelScope.launch {
            val result = transactionRepository.deleteTransaction(transactionId)
            
            if (result.isFailure) {
                _uiState.value = TransactionsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to delete transaction"
                )
            }
        }
    }
    
    /**
     * Delete multiple transactions.
     */
    fun deleteTransactions(transactionIds: List<String>) {
        viewModelScope.launch {
            val result = transactionRepository.deleteTransactions(transactionIds)
            
            if (result.isFailure) {
                _uiState.value = TransactionsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to delete transactions"
                )
            }
        }
    }
    
    /**
     * Filter by account.
     */
    fun filterByAccount(accountId: String?) {
        _selectedAccountId.value = accountId
        loadTransactions()
    }
    
    /**
     * Filter by category.
     */
    fun filterByCategory(category: String?) {
        _selectedCategory.value = category
        loadTransactions()
    }
    
    /**
     * Filter by transaction type.
     */
    fun filterByType(type: Transaction.TransactionType?) {
        _selectedType.value = type
        loadTransactions()
    }
    
    /**
     * Update search query.
     */
    fun updateSearchQuery(query: String) {
        _searchQuery.value = query
        loadTransactions()
    }
    
    /**
     * Set date range filter.
     */
    fun setDateRange(start: LocalDateTime, end: LocalDateTime) {
        _dateRange.value = Pair(start, end)
        loadTransactions()
    }
    
    /**
     * Clear all filters.
     */
    fun clearFilters() {
        _selectedAccountId.value = null
        _selectedCategory.value = null
        _selectedType.value = null
        _searchQuery.value = ""
        _dateRange.value = null
        loadTransactions()
    }
    
    /**
     * Get spending by category.
     */
    fun getExpensesByCategory(): StateFlow<Map<String, Double>> {
        val expenses = MutableStateFlow<Map<String, Double>>(emptyMap())
        
        viewModelScope.launch {
            try {
                val expensesMap = transactionRepository.getExpensesByCategory()
                expenses.value = expensesMap
            } catch (e: Exception) {
                // Handle error silently
            }
        }
        
        return expenses.asStateFlow()
    }
    
    /**
     * Clear error state.
     */
    fun clearError() {
        if (_uiState.value is TransactionsUiState.Error) {
            loadTransactions()
        }
    }
    
    /**
     * Filter criteria data class.
     */
    private data class FilterCriteria(
        val accountId: String?,
        val category: String?,
        val type: Transaction.TransactionType?,
        val query: String,
        val dateRange: Pair<LocalDateTime, LocalDateTime>?
    )
    
    /**
     * UI state sealed class.
     */
    sealed class TransactionsUiState {
        object Loading : TransactionsUiState()
        object Empty : TransactionsUiState()
        data class Success(val transactions: List<Transaction>) : TransactionsUiState()
        data class Error(val message: String) : TransactionsUiState()
    }
}
