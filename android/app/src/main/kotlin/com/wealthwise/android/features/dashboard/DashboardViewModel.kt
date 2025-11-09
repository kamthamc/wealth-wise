package com.wealthwise.android.features.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wealthwise.android.data.model.Transaction
import com.wealthwise.android.data.remote.firebase.CloudFunctionsService
import com.wealthwise.android.data.repository.AccountRepository
import com.wealthwise.android.data.repository.BudgetRepository
import com.wealthwise.android.data.repository.GoalRepository
import com.wealthwise.android.data.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import java.math.BigDecimal
import javax.inject.Inject

/**
 * ViewModel for dashboard/overview screen.
 * 
 * Aggregates data from all repositories to provide:
 * - Total balance across accounts
 * - Recent transactions
 * - Budget alerts
 * - Goal progress
 * - Income/expense summary
 */
@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val accountRepository: AccountRepository,
    private val transactionRepository: TransactionRepository,
    private val budgetRepository: BudgetRepository,
    private val goalRepository: GoalRepository,
    private val cloudFunctionsService: CloudFunctionsService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<DashboardUiState>(DashboardUiState.Loading)
    val uiState: StateFlow<DashboardUiState> = _uiState.asStateFlow()
    
    private val _totalBalance = MutableStateFlow(BigDecimal.ZERO)
    val totalBalance: StateFlow<BigDecimal> = _totalBalance.asStateFlow()
    
    private val _recentTransactions = MutableStateFlow<List<Transaction>>(emptyList())
    val recentTransactions: StateFlow<List<Transaction>> = _recentTransactions.asStateFlow()
    
    private val _budgetAlerts = MutableStateFlow<List<BudgetRepository.BudgetAlert>>(emptyList())
    val budgetAlerts: StateFlow<List<BudgetRepository.BudgetAlert>> = _budgetAlerts.asStateFlow()
    
    private val _goalsSummary = MutableStateFlow<GoalRepository.GoalProgressSummary?>(null)
    val goalsSummary: StateFlow<GoalRepository.GoalProgressSummary?> = _goalsSummary.asStateFlow()
    
    private val _monthlyIncome = MutableStateFlow(BigDecimal.ZERO)
    val monthlyIncome: StateFlow<BigDecimal> = _monthlyIncome.asStateFlow()
    
    private val _monthlyExpenses = MutableStateFlow(BigDecimal.ZERO)
    val monthlyExpenses: StateFlow<BigDecimal> = _monthlyExpenses.asStateFlow()
    
    private val _expensesByCategory = MutableStateFlow<Map<String, Double>>(emptyMap())
    val expensesByCategory: StateFlow<Map<String, Double>> = _expensesByCategory.asStateFlow()
    
    init {
        loadDashboardData()
    }
    
    /**
     * Load all dashboard data.
     */
    fun loadDashboardData() {
        viewModelScope.launch {
            try {
                _uiState.value = DashboardUiState.Loading
                
                // Load total balance
                loadTotalBalance()
                
                // Load recent transactions
                loadRecentTransactions()
                
                // Load budget alerts
                loadBudgetAlerts()
                
                // Load goals summary
                loadGoalsSummary()
                
                // Load income/expense summary
                loadIncomeExpenseSummary()
                
                // Load expenses by category
                loadExpensesByCategory()
                
                _uiState.value = DashboardUiState.Success
            } catch (e: Exception) {
                _uiState.value = DashboardUiState.Error(e.message ?: "Failed to load dashboard data")
            }
        }
    }
    
    /**
     * Load total balance across all accounts.
     */
    private suspend fun loadTotalBalance() {
        try {
            val balance = accountRepository.getTotalBalance()
            _totalBalance.value = balance
        } catch (e: Exception) {
            // Handle error silently
        }
    }
    
    /**
     * Load recent transactions (last 7 days).
     */
    private fun loadRecentTransactions() {
        viewModelScope.launch {
            try {
                transactionRepository.getRecentTransactions(days = 7, limit = 10)
                    .collect { transactions ->
                        _recentTransactions.value = transactions
                    }
            } catch (e: Exception) {
                // Handle error silently
            }
        }
    }
    
    /**
     * Load budget alerts.
     */
    private suspend fun loadBudgetAlerts() {
        try {
            val alerts = budgetRepository.getBudgetAlerts()
            _budgetAlerts.value = alerts
        } catch (e: Exception) {
            // Handle error silently
        }
    }
    
    /**
     * Load goals summary.
     */
    private suspend fun loadGoalsSummary() {
        try {
            val summary = goalRepository.getGoalProgressSummary()
            _goalsSummary.value = summary
        } catch (e: Exception) {
            // Handle error silently
        }
    }
    
    /**
     * Load monthly income and expense summary.
     */
    private suspend fun loadIncomeExpenseSummary() {
        try {
            val income = transactionRepository.getTotalByType(Transaction.TransactionType.CREDIT)
            val expenses = transactionRepository.getTotalByType(Transaction.TransactionType.DEBIT)
            
            _monthlyIncome.value = income
            _monthlyExpenses.value = expenses
        } catch (e: Exception) {
            // Handle error silently
        }
    }
    
    /**
     * Load expenses grouped by category.
     */
    private suspend fun loadExpensesByCategory() {
        try {
            val expenses = transactionRepository.getExpensesByCategory()
            _expensesByCategory.value = expenses
        } catch (e: Exception) {
            // Handle error silently
        }
    }
    
    /**
     * Calculate net savings for the month.
     */
    fun getNetSavings(): StateFlow<BigDecimal> {
        return combine(_monthlyIncome, _monthlyExpenses) { income, expenses ->
            income - expenses
        }.stateIn(
            scope = viewModelScope,
            started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(5000),
            initialValue = BigDecimal.ZERO
        )
    }
    
    /**
     * Get savings rate percentage.
     */
    fun getSavingsRate(): StateFlow<Double> {
        return combine(_monthlyIncome, _monthlyExpenses) { income, expenses ->
            if (income > BigDecimal.ZERO) {
                val savings = income - expenses
                (savings.toDouble() / income.toDouble()) * 100
            } else {
                0.0
            }
        }.stateIn(
            scope = viewModelScope,
            started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(5000),
            initialValue = 0.0
        )
    }
    
    /**
     * Generate analytics for a specific period.
     */
    fun generateAnalytics(
        userId: String,
        period: CloudFunctionsService.AnalyticsPeriod
    ) {
        viewModelScope.launch {
            _uiState.value = DashboardUiState.Loading
            
            val result = cloudFunctionsService.generateAnalytics(userId, period)
            
            if (result.isSuccess) {
                val analytics = result.getOrNull()
                analytics?.let {
                    _monthlyIncome.value = BigDecimal.valueOf(it.totalIncome)
                    _monthlyExpenses.value = BigDecimal.valueOf(it.totalExpenses)
                    _expensesByCategory.value = it.categoryBreakdown
                }
                _uiState.value = DashboardUiState.Success
            } else {
                _uiState.value = DashboardUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to generate analytics"
                )
            }
        }
    }
    
    /**
     * Calculate tax summary for financial year.
     */
    fun calculateTaxSummary(userId: String, financialYear: String) {
        viewModelScope.launch {
            val result = cloudFunctionsService.calculateTaxSummary(userId, financialYear)
            
            if (result.isFailure) {
                _uiState.value = DashboardUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to calculate tax"
                )
            }
        }
    }
    
    /**
     * Refresh dashboard data.
     */
    fun refresh() {
        loadDashboardData()
    }
    
    /**
     * Clear error state.
     */
    fun clearError() {
        if (_uiState.value is DashboardUiState.Error) {
            _uiState.value = DashboardUiState.Success
        }
    }
    
    /**
     * Dashboard summary data class.
     */
    data class DashboardSummary(
        val totalBalance: BigDecimal,
        val monthlyIncome: BigDecimal,
        val monthlyExpenses: BigDecimal,
        val netSavings: BigDecimal,
        val savingsRate: Double,
        val activeAccounts: Int,
        val activeGoals: Int,
        val completedGoals: Int,
        val budgetAlerts: Int
    )
    
    /**
     * Get complete dashboard summary.
     */
    fun getDashboardSummary(): StateFlow<DashboardSummary?> {
        return combine(
            _totalBalance,
            _monthlyIncome,
            _monthlyExpenses,
            _budgetAlerts,
            _goalsSummary
        ) { balance, income, expenses, alerts, goalsSummary ->
            val netSavings = income - expenses
            val savingsRate = if (income > BigDecimal.ZERO) {
                (netSavings.toDouble() / income.toDouble()) * 100
            } else {
                0.0
            }
            
            DashboardSummary(
                totalBalance = balance,
                monthlyIncome = income,
                monthlyExpenses = expenses,
                netSavings = netSavings,
                savingsRate = savingsRate,
                activeAccounts = 0, // TODO: Get from accounts repository
                activeGoals = goalsSummary?.activeGoals ?: 0,
                completedGoals = goalsSummary?.completedGoals ?: 0,
                budgetAlerts = alerts.size
            )
        }.stateIn(
            scope = viewModelScope,
            started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(5000),
            initialValue = null
        )
    }
    
    /**
     * UI state sealed class.
     */
    sealed class DashboardUiState {
        object Loading : DashboardUiState()
        object Success : DashboardUiState()
        data class Error(val message: String) : DashboardUiState()
    }
}
