package com.wealthwise.android.features.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseUser
import com.wealthwise.android.data.remote.firebase.FirebaseAuthService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for authentication operations.
 * 
 * Manages authentication state and provides methods for:
 * - Email/password sign in and sign up
 * - Google Sign-In
 * - Password reset
 * - Sign out
 */
@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authService: FirebaseAuthService
) : ViewModel() {
    
    private val _uiState = MutableStateFlow<AuthUiState>(AuthUiState.Initial)
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()
    
    private val _currentUser = MutableStateFlow<FirebaseUser?>(authService.currentUser)
    val currentUser: StateFlow<FirebaseUser?> = _currentUser.asStateFlow()
    
    init {
        checkAuthState()
    }
    
    /**
     * Check current authentication state.
     */
    private fun checkAuthState() {
        _currentUser.value = authService.currentUser
        if (authService.isSignedIn) {
            _uiState.value = AuthUiState.Authenticated(authService.currentUser!!)
        }
    }
    
    /**
     * Sign in with email and password.
     */
    fun signInWithEmail(email: String, password: String) {
        // Validate input
        if (email.isBlank() || password.isBlank()) {
            _uiState.value = AuthUiState.Error("Email and password are required")
            return
        }
        
        if (!isValidEmail(email)) {
            _uiState.value = AuthUiState.Error("Invalid email format")
            return
        }
        
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = authService.signInWithEmailAndPassword(email, password)
            
            _uiState.value = if (result.isSuccess) {
                _currentUser.value = result.getOrNull()
                AuthUiState.Authenticated(result.getOrNull()!!)
            } else {
                AuthUiState.Error(result.exceptionOrNull()?.message ?: "Sign in failed")
            }
        }
    }
    
    /**
     * Create a new account with email and password.
     */
    fun signUpWithEmail(email: String, password: String, confirmPassword: String) {
        // Validate input
        if (email.isBlank() || password.isBlank() || confirmPassword.isBlank()) {
            _uiState.value = AuthUiState.Error("All fields are required")
            return
        }
        
        if (!isValidEmail(email)) {
            _uiState.value = AuthUiState.Error("Invalid email format")
            return
        }
        
        if (password.length < 6) {
            _uiState.value = AuthUiState.Error("Password must be at least 6 characters")
            return
        }
        
        if (password != confirmPassword) {
            _uiState.value = AuthUiState.Error("Passwords do not match")
            return
        }
        
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = authService.createUserWithEmailAndPassword(email, password)
            
            _uiState.value = if (result.isSuccess) {
                _currentUser.value = result.getOrNull()
                AuthUiState.Authenticated(result.getOrNull()!!)
            } else {
                AuthUiState.Error(result.exceptionOrNull()?.message ?: "Sign up failed")
            }
        }
    }
    
    /**
     * Sign in with Google.
     */
    fun signInWithGoogle(idToken: String) {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = authService.signInWithGoogle(idToken)
            
            _uiState.value = if (result.isSuccess) {
                _currentUser.value = result.getOrNull()
                AuthUiState.Authenticated(result.getOrNull()!!)
            } else {
                AuthUiState.Error(result.exceptionOrNull()?.message ?: "Google sign in failed")
            }
        }
    }
    
    /**
     * Send password reset email.
     */
    fun sendPasswordResetEmail(email: String) {
        if (email.isBlank()) {
            _uiState.value = AuthUiState.Error("Email is required")
            return
        }
        
        if (!isValidEmail(email)) {
            _uiState.value = AuthUiState.Error("Invalid email format")
            return
        }
        
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            
            val result = authService.sendPasswordResetEmail(email)
            
            _uiState.value = if (result.isSuccess) {
                AuthUiState.PasswordResetSent
            } else {
                AuthUiState.Error(result.exceptionOrNull()?.message ?: "Failed to send reset email")
            }
        }
    }
    
    /**
     * Sign out the current user.
     */
    fun signOut() {
        authService.signOut()
        _currentUser.value = null
        _uiState.value = AuthUiState.SignedOut
    }
    
    /**
     * Clear error state.
     */
    fun clearError() {
        if (_uiState.value is AuthUiState.Error) {
            _uiState.value = AuthUiState.Initial
        }
    }
    
    /**
     * Validate email format.
     */
    private fun isValidEmail(email: String): Boolean {
        return android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }
    
    /**
     * UI state sealed class.
     */
    sealed class AuthUiState {
        object Initial : AuthUiState()
        object Loading : AuthUiState()
        data class Authenticated(val user: FirebaseUser) : AuthUiState()
        object SignedOut : AuthUiState()
        object PasswordResetSent : AuthUiState()
        data class Error(val message: String) : AuthUiState()
    }
}
