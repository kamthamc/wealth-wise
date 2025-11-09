package com.wealthwise.android.features.goals

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wealthwise.android.data.model.Goal
import com.wealthwise.android.data.repository.GoalRepository
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
 * ViewModel for financial goals feature.
 * 
 * Manages goal list, creation, updates, contributions, and progress tracking.
 */
@HiltViewModel
class GoalsViewModel @Inject constructor(
    private val goalRepository: GoalRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<GoalsUiState>(GoalsUiState.Loading)
    val uiState: StateFlow<GoalsUiState> = _uiState.asStateFlow()
    
    private val _showCompleted = MutableStateFlow(false)
    val showCompleted: StateFlow<Boolean> = _showCompleted.asStateFlow()
    
    private val _selectedType = MutableStateFlow<Goal.GoalType?>(null)
    val selectedType: StateFlow<Goal.GoalType?> = _selectedType.asStateFlow()
    
    private val _selectedPriority = MutableStateFlow<Goal.GoalPriority?>(null)
    val selectedPriority: StateFlow<Goal.GoalPriority?> = _selectedPriority.asStateFlow()
    
    private val _progressSummary = MutableStateFlow<GoalRepository.GoalProgressSummary?>(null)
    val progressSummary: StateFlow<GoalRepository.GoalProgressSummary?> = _progressSummary.asStateFlow()
    
    /**
     * Goals StateFlow with filters applied.
     */
    val goals: StateFlow<List<Goal>> = combine(
        _showCompleted,
        _selectedType,
        _selectedPriority
    ) { showCompleted, type, priority ->
        Triple(showCompleted, type, priority)
    }.catch { exception ->
        _uiState.value = GoalsUiState.Error(exception.message ?: "Failed to load goals")
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
    
    init {
        loadGoals()
        loadProgressSummary()
    }
    
    /**
     * Load goals with current filters.
     */
    private fun loadGoals() {
        viewModelScope.launch {
            try {
                val baseFlow = if (_showCompleted.value) {
                    goalRepository.getAllGoals()
                } else {
                    goalRepository.getActiveGoals()
                }
                
                baseFlow.collect { goalList ->
                    var filtered = goalList
                    
                    // Filter by type
                    _selectedType.value?.let { type ->
                        filtered = filtered.filter { it.type == type }
                    }
                    
                    // Filter by priority
                    _selectedPriority.value?.let { priority ->
                        filtered = filtered.filter { it.priority == priority }
                    }
                    
                    // Sort by priority (HIGH -> MEDIUM -> LOW) and then by target date
                    filtered = filtered.sortedWith(
                        compareBy<Goal> { goal ->
                            when (goal.priority) {
                                Goal.GoalPriority.HIGH -> 0
                                Goal.GoalPriority.MEDIUM -> 1
                                Goal.GoalPriority.LOW -> 2
                            }
                        }.thenBy { it.targetDate }
                    )
                    
                    _uiState.value = if (filtered.isEmpty()) {
                        GoalsUiState.Empty
                    } else {
                        GoalsUiState.Success(filtered)
                    }
                }
            } catch (e: Exception) {
                _uiState.value = GoalsUiState.Error(e.message ?: "Failed to load goals")
            }
        }
    }
    
    /**
     * Load progress summary.
     */
    private fun loadProgressSummary() {
        viewModelScope.launch {
            try {
                val summary = goalRepository.getGoalProgressSummary()
                _progressSummary.value = summary
            } catch (e: Exception) {
                // Handle error silently
            }
        }
    }
    
    /**
     * Create a new goal.
     */
    fun createGoal(
        userId: String,
        name: String,
        targetAmount: String,
        targetDate: LocalDateTime,
        type: Goal.GoalType,
        priority: Goal.GoalPriority,
        initialAmount: String = "0"
    ) {
        // Validate input
        if (name.isBlank()) {
            _uiState.value = GoalsUiState.Error("Goal name is required")
            return
        }
        
        val targetDecimal = try {
            BigDecimal(targetAmount)
        } catch (e: Exception) {
            _uiState.value = GoalsUiState.Error("Invalid target amount")
            return
        }
        
        if (targetDecimal <= BigDecimal.ZERO) {
            _uiState.value = GoalsUiState.Error("Target amount must be greater than zero")
            return
        }
        
        val initialDecimal = try {
            BigDecimal(initialAmount)
        } catch (e: Exception) {
            _uiState.value = GoalsUiState.Error("Invalid initial amount")
            return
        }
        
        if (initialDecimal < BigDecimal.ZERO) {
            _uiState.value = GoalsUiState.Error("Initial amount cannot be negative")
            return
        }
        
        if (targetDate.isBefore(LocalDateTime.now())) {
            _uiState.value = GoalsUiState.Error("Target date must be in the future")
            return
        }
        
        viewModelScope.launch {
            _uiState.value = GoalsUiState.Loading
            
            val result = goalRepository.createGoal(
                userId = userId,
                name = name,
                targetAmount = targetDecimal,
                targetDate = targetDate,
                type = type,
                priority = priority,
                initialAmount = initialDecimal
            )
            
            if (result.isSuccess) {
                loadGoals()
                loadProgressSummary()
            } else {
                _uiState.value = GoalsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to create goal"
                )
            }
        }
    }
    
    /**
     * Update an existing goal.
     */
    fun updateGoal(goal: Goal) {
        viewModelScope.launch {
            _uiState.value = GoalsUiState.Loading
            
            val result = goalRepository.updateGoal(goal)
            
            if (result.isSuccess) {
                loadGoals()
                loadProgressSummary()
            } else {
                _uiState.value = GoalsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to update goal"
                )
            }
        }
    }
    
    /**
     * Add a contribution to a goal.
     */
    fun addContribution(goalId: String, amount: String) {
        val amountDecimal = try {
            BigDecimal(amount)
        } catch (e: Exception) {
            _uiState.value = GoalsUiState.Error("Invalid contribution amount")
            return
        }
        
        if (amountDecimal <= BigDecimal.ZERO) {
            _uiState.value = GoalsUiState.Error("Contribution must be greater than zero")
            return
        }
        
        viewModelScope.launch {
            val result = goalRepository.addContribution(goalId, amountDecimal)
            
            if (result.isSuccess) {
                loadProgressSummary()
            } else {
                _uiState.value = GoalsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to add contribution"
                )
            }
        }
    }
    
    /**
     * Delete a goal.
     */
    fun deleteGoal(goalId: String) {
        viewModelScope.launch {
            val result = goalRepository.deleteGoal(goalId)
            
            if (result.isFailure) {
                _uiState.value = GoalsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to delete goal"
                )
            } else {
                loadProgressSummary()
            }
        }
    }
    
    /**
     * Filter by goal type.
     */
    fun filterByType(type: Goal.GoalType?) {
        _selectedType.value = type
        loadGoals()
    }
    
    /**
     * Filter by priority.
     */
    fun filterByPriority(priority: Goal.GoalPriority?) {
        _selectedPriority.value = priority
        loadGoals()
    }
    
    /**
     * Toggle showing completed goals.
     */
    fun toggleShowCompleted() {
        _showCompleted.value = !_showCompleted.value
        loadGoals()
    }
    
    /**
     * Get goals behind schedule.
     */
    fun getBehindScheduleGoals(): StateFlow<List<Goal>> {
        val behindGoals = MutableStateFlow<List<Goal>>(emptyList())
        
        viewModelScope.launch {
            try {
                val goals = goalRepository.getBehindScheduleGoals()
                behindGoals.value = goals
            } catch (e: Exception) {
                // Handle error silently
            }
        }
        
        return behindGoals.asStateFlow()
    }
    
    /**
     * Calculate required monthly contribution for a goal.
     */
    fun getRequiredMonthlyContribution(goal: Goal): BigDecimal {
        return goal.getRequiredMonthlyContribution()
    }
    
    /**
     * Check if goal is on track.
     */
    fun isGoalOnTrack(goal: Goal): Boolean {
        return goal.isOnTrack()
    }
    
    /**
     * Get goal progress percentage.
     */
    fun getGoalProgress(goal: Goal): Double {
        return goal.getProgressPercentage()
    }
    
    /**
     * Clear error state.
     */
    fun clearError() {
        if (_uiState.value is GoalsUiState.Error) {
            loadGoals()
        }
    }
    
    /**
     * UI state sealed class.
     */
    sealed class GoalsUiState {
        object Loading : GoalsUiState()
        object Empty : GoalsUiState()
        data class Success(val goals: List<Goal>) : GoalsUiState()
        data class Error(val message: String) : GoalsUiState()
    }
}
