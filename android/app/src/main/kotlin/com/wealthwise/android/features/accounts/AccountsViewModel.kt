package com.wealthwise.android.features.accounts

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wealthwise.android.data.model.Account
import com.wealthwise.android.data.repository.AccountRepository
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
import javax.inject.Inject

/**
 * ViewModel for accounts feature.
 * 
 * Manages account list, creation, updates, and deletion.
 */
@HiltViewModel
class AccountsViewModel @Inject constructor(
    private val accountRepository: AccountRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<AccountsUiState>(AccountsUiState.Loading)
    val uiState: StateFlow<AccountsUiState> = _uiState.asStateFlow()
    
    private val _showArchived = MutableStateFlow(false)
    val showArchived: StateFlow<Boolean> = _showArchived.asStateFlow()
    
    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()
    
    /**
     * Accounts StateFlow combining active/archived filter and search.
     */
    val accounts: StateFlow<List<Account>> = combine(
        _showArchived,
        _searchQuery
    ) { showArchived, query ->
        Pair(showArchived, query)
    }.catch { exception ->
        _uiState.value = AccountsUiState.Error(exception.message ?: "Failed to load accounts")
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = emptyList()
    )
    
    init {
        loadAccounts()
    }
    
    /**
     * Load accounts from repository.
     */
    private fun loadAccounts() {
        viewModelScope.launch {
            try {
                combine(
                    if (_showArchived.value) {
                        accountRepository.getAllAccounts()
                    } else {
                        accountRepository.getActiveAccounts()
                    },
                    _searchQuery
                ) { accounts, query ->
                    if (query.isBlank()) {
                        accounts
                    } else {
                        accounts.filter { account ->
                            account.name.contains(query, ignoreCase = true) ||
                            account.institution?.contains(query, ignoreCase = true) == true
                        }
                    }
                }.collect { accountList ->
                    _uiState.value = if (accountList.isEmpty()) {
                        AccountsUiState.Empty
                    } else {
                        AccountsUiState.Success(accountList)
                    }
                }
            } catch (e: Exception) {
                _uiState.value = AccountsUiState.Error(e.message ?: "Failed to load accounts")
            }
        }
    }
    
    /**
     * Create a new account.
     */
    fun createAccount(
        userId: String,
        name: String,
        type: Account.AccountType,
        institution: String?,
        initialBalance: String,
        currency: String = "INR"
    ) {
        // Validate input
        if (name.isBlank()) {
            _uiState.value = AccountsUiState.Error("Account name is required")
            return
        }
        
        val balance = try {
            BigDecimal(initialBalance)
        } catch (e: Exception) {
            _uiState.value = AccountsUiState.Error("Invalid balance amount")
            return
        }
        
        viewModelScope.launch {
            _uiState.value = AccountsUiState.Loading
            
            val result = accountRepository.createAccount(
                userId = userId,
                name = name,
                type = type,
                institution = institution,
                initialBalance = balance,
                currency = currency
            )
            
            if (result.isSuccess) {
                loadAccounts()
            } else {
                _uiState.value = AccountsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to create account"
                )
            }
        }
    }
    
    /**
     * Update an existing account.
     */
    fun updateAccount(account: Account) {
        viewModelScope.launch {
            _uiState.value = AccountsUiState.Loading
            
            val result = accountRepository.updateAccount(account)
            
            if (result.isSuccess) {
                loadAccounts()
            } else {
                _uiState.value = AccountsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to update account"
                )
            }
        }
    }
    
    /**
     * Archive an account.
     */
    fun archiveAccount(accountId: String) {
        viewModelScope.launch {
            val result = accountRepository.archiveAccount(accountId)
            
            if (result.isFailure) {
                _uiState.value = AccountsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to archive account"
                )
            }
        }
    }
    
    /**
     * Unarchive an account.
     */
    fun unarchiveAccount(accountId: String) {
        viewModelScope.launch {
            val result = accountRepository.unarchiveAccount(accountId)
            
            if (result.isFailure) {
                _uiState.value = AccountsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to unarchive account"
                )
            }
        }
    }
    
    /**
     * Delete an account.
     */
    fun deleteAccount(accountId: String) {
        viewModelScope.launch {
            val result = accountRepository.deleteAccount(accountId)
            
            if (result.isFailure) {
                _uiState.value = AccountsUiState.Error(
                    result.exceptionOrNull()?.message ?: "Failed to delete account"
                )
            }
        }
    }
    
    /**
     * Toggle showing archived accounts.
     */
    fun toggleShowArchived() {
        _showArchived.value = !_showArchived.value
        loadAccounts()
    }
    
    /**
     * Update search query.
     */
    fun updateSearchQuery(query: String) {
        _searchQuery.value = query
    }
    
    /**
     * Clear error state.
     */
    fun clearError() {
        if (_uiState.value is AccountsUiState.Error) {
            loadAccounts()
        }
    }
    
    /**
     * Get total balance across all accounts.
     */
    fun getTotalBalance(): StateFlow<BigDecimal> {
        val totalBalance = MutableStateFlow(BigDecimal.ZERO)
        
        viewModelScope.launch {
            try {
                val balance = accountRepository.getTotalBalance()
                totalBalance.value = balance
            } catch (e: Exception) {
                // Handle error silently for total balance
            }
        }
        
        return totalBalance.asStateFlow()
    }
    
    /**
     * UI state sealed class.
     */
    sealed class AccountsUiState {
        object Loading : AccountsUiState()
        object Empty : AccountsUiState()
        data class Success(val accounts: List<Account>) : AccountsUiState()
        data class Error(val message: String) : AccountsUiState()
    }
}
