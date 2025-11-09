package com.wealthwise.android.features.budgets

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wealthwise.android.data.model.Budget
import com.wealthwise.android.data.repository.BudgetRepository
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
 * ViewModel for budgets feature.
 * 
 * Manages budget list, creation, updates, and alerts.
 */
@HiltViewModel
class BudgetsViewModel @Inject constructor(
    private val budgetRepository: BudgetRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<BudgetsUiState>(BudgetsUiState.Loading)
    val uiState: StateFlow<BudgetsUiState> = _uiState.asStateFlow()
    
    private val _selectedPeriod = MutableStateFlow<Budget.BudgetPeriod?>(null)
    val selectedPeriod: StateFlow<Budget.BudgetPeriod?> = _selectedPeriod.asStateFlow()
    
    private val _showActiveOnly = MutableStateFlow(true)
    val showActiveOnly: StateFlow<Boolean> = _showActiveOnly.asStateFlow()
    
    private val _alerts = MutableStateFlow<List<BudgetRepository.BudgetAlert>>(emptyList())
    val alerts: StateFlow<List<BudgetRepository.BudgetAlert>> = _alerts.asStateFlow()
    
    /**
     * Budgets StateFlow with filters applied.
     */
    val budgets: StateFlow<List<Budget>> = combine(
        _showActiveOnly,
        _selectedPeriod
    ) { activeOnly, period ->
        Pair(activeOnly, period)
    }.catch { exception ->
        _uiState.value = BudgetsUiState.Error(exception.message ?: "Failed to load budgets")
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
    
    init {
        loadBudgets()
        loadAlerts()
    }
    
    /**
     * Load budgets with current filters.
     */
    private fun loadBudgets() {
        viewModelScope.launch {
            try {
                val baseFlow = if (_showActiveOnly.value) {
                    budgetRepository.getActiveBudgets()
                } else {
                    budgetRepository.getAllBudgets()
                }
                
                baseFlow.collect { budgetList ->
                    var filtered = budgetList
                    
                    // Filter by period if selected
                    _selectedPeriod.value?.let { period ->
                        filtered = filtered.filter { it.period == period }
                    }
                    
                    _uiState.value = if (filtered.isEmpty()) {
                        BudgetsUiState.Empty
                    } else {
                        BudgetsUiState.Success(filtered)
                    }
                }
            } catch (e: Exception) {
                _uiState.value = BudgetsUiState.Error(e.message ?: "Failed to load budgets")
            }
        }
    }
    
    /**
     * Load budget alerts.
     */
    private fun loadAlerts() {
        viewModelScope.launch {
            try {
                val alertsList = budgetRepository.getBudgetAlerts()
                _alerts.value = alertsList
            } catch (e: Exception) {
                // Handle error silently for alerts
            }
        }
    }
    
    /**
     * Create a new budget.
     */
    fun createBudget(
        userId: String,
        name: String,
        amount: String,
        period: Budget.BudgetPeriod,
        categories: List<String>,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ) {
        // Validate input
        if (name.isBlank()) {
            _uiState.value = BudgetsUiState.Error("Budget name is required")
            return
        }
        
        if (categories.isEmpty()) {
            _uiState.value = BudgetsUiState.Error("At least one category is required")
            return
        }
        
        val amountDecimal = try {
            BigDecimal(amount)
        } catch (e: Exception) {
            _uiState.value = BudgetsUiState.Error("Invalid amount")
            return
        }
        
        if (amountDecimal <= BigDecimal.ZERO) {
            _uiState.value = BudgetsUiState.Error("Amount must be greater than zero")
            return
        }
        
        if (startDate.isAfter(endDate)) {
            _uiState.value = BudgetsUiState.Error("Start date must be before end date")
            return
        }
        
        viewModelScope.launch {
            _uiState.value = BudgetsUiState.Loading
            
            val result = budgetRepository.createBudget(
                userId = userId,
                name = name,
                amount = amountDecimal,
                period = period,
                categories = categories,
                startDate = startDate,
                endDate = endDate
            )
            
            if (result.isSuccess) {
                loadBudgets()
                loadAlerts()
            } else {
                _uiState.value = BudgetsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to create budget"
                )
            }
        }
    }
    
    /**
     * Update an existing budget.
     */
    fun updateBudget(budget: Budget) {
        viewModelScope.launch {
            _uiState.value = BudgetsUiState.Loading
            
            val result = budgetRepository.updateBudget(budget)
            
            if (result.isSuccess) {
                loadBudgets()
                loadAlerts()
            } else {
                _uiState.value = BudgetsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to update budget"
                )
            }
        }
    }
    
    /**
     * Update budget spending.
     */
    fun updateSpending(budgetId: String, newSpent: BigDecimal) {
        viewModelScope.launch {
            val result = budgetRepository.updateSpending(budgetId, newSpent)
            
            if (result.isFailure) {
                _uiState.value = BudgetsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to update spending"
                )
            } else {
                loadAlerts()
            }
        }
    }
    
    /**
     * Delete a budget.
     */
    fun deleteBudget(budgetId: String) {
        viewModelScope.launch {
            val result = budgetRepository.deleteBudget(budgetId)
            
            if (result.isFailure) {
                _uiState.value = BudgetsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to delete budget"
                )
            }
        }
    }
    
    /**
     * Filter by budget period.
     */
    fun filterByPeriod(period: Budget.BudgetPeriod?) {
        _selectedPeriod.value = period
        loadBudgets()
    }
    
    /**
     * Toggle showing active budgets only.
     */
    fun toggleActiveOnly() {
        _showActiveOnly.value = !_showActiveOnly.value
        loadBudgets()
    }
    
    /**
     * Clear error state.
     */
    fun clearError() {
        if (_uiState.value is BudgetsUiState.Error) {
            loadBudgets()
        }
    }
    
    /**
     * Get budget status for a specific budget.
     */
    fun getBudgetStatus(budget: Budget): BudgetStatus {
        return when {
            budget.isExceeded() -> BudgetStatus.EXCEEDED
            budget.isApproachingLimit() -> BudgetStatus.WARNING
            else -> BudgetStatus.HEALTHY
        }
    }
    
    /**
     * Calculate days remaining in budget period.
     */
    fun getDaysRemaining(budget: Budget): Int {
        return budget.getDaysRemaining()
    }
    
    /**
     * Budget status enum.
     */
    enum class BudgetStatus {
        HEALTHY,
        WARNING,
        EXCEEDED
    }
    
    /**
     * UI state sealed class.
     */
    sealed class BudgetsUiState {
        object Loading : BudgetsUiState()
        object Empty : BudgetsUiState()
        data class Success(val budgets: List<Budget>) : BudgetsUiState()
        data class Error(val message: String) : BudgetsUiState()
    }
}
