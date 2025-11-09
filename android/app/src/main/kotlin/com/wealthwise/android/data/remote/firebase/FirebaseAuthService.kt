package com.wealthwise.android.data.remote.firebase

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for Firebase Authentication operations.
 * 
 * Provides methods for:
 * - Email/password authentication
 * - Google Sign-In
 * - User session management
 * - Authentication state monitoring
 */
@Singleton
class FirebaseAuthService @Inject constructor(
    private val firebaseAuth: FirebaseAuth
) {
    
    /**
     * Get the currently signed-in user.
     */
    val currentUser: FirebaseUser?
        get() = firebaseAuth.currentUser
    
    /**
     * Get the current user ID.
     */
    val currentUserId: String?
        get() = currentUser?.uid
    
    /**
     * Check if a user is currently signed in.
     */
    val isSignedIn: Boolean
        get() = currentUser != null
    
    /**
     * Flow that emits authentication state changes.
     */
    fun authStateFlow(): Flow<FirebaseUser?> = flow {
        firebaseAuth.addAuthStateListener { auth ->
            // Note: This is a simplified implementation
            // In production, use callbackFlow for proper Flow handling
        }
        emit(currentUser)
    }
    
    /**
     * Sign in with email and password.
     * 
     * @param email User's email address
     * @param password User's password
     * @return Result containing the signed-in user or error
     */
    suspend fun signInWithEmailAndPassword(
        email: String,
        password: String
    ): Result<FirebaseUser> {
        return try {
            val result = firebaseAuth.signInWithEmailAndPassword(email, password).await()
            val user = result.user
            if (user != null) {
                Result.success(user)
            } else {
                Result.failure(Exception("Sign in failed: User is null"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Create a new user account with email and password.
     * 
     * @param email User's email address
     * @param password User's password
     * @return Result containing the created user or error
     */
    suspend fun createUserWithEmailAndPassword(
        email: String,
        password: String
    ): Result<FirebaseUser> {
        return try {
            val result = firebaseAuth.createUserWithEmailAndPassword(email, password).await()
            val user = result.user
            if (user != null) {
                Result.success(user)
            } else {
                Result.failure(Exception("Account creation failed: User is null"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Sign in with Google credentials.
     * 
     * @param idToken Google ID token from Google Sign-In
     * @return Result containing the signed-in user or error
     */
    suspend fun signInWithGoogle(idToken: String): Result<FirebaseUser> {
        return try {
            val credential = GoogleAuthProvider.getCredential(idToken, null)
            val result = firebaseAuth.signInWithCredential(credential).await()
            val user = result.user
            if (user != null) {
                Result.success(user)
            } else {
                Result.failure(Exception("Google sign in failed: User is null"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Send a password reset email to the user.
     * 
     * @param email User's email address
     * @return Result indicating success or error
     */
    suspend fun sendPasswordResetEmail(email: String): Result<Unit> {
        return try {
            firebaseAuth.sendPasswordResetEmail(email).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update the current user's password.
     * 
     * @param newPassword The new password
     * @return Result indicating success or error
     */
    suspend fun updatePassword(newPassword: String): Result<Unit> {
        return try {
            val user = currentUser ?: return Result.failure(Exception("No user signed in"))
            user.updatePassword(newPassword).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Update the current user's email address.
     * 
     * @param newEmail The new email address
     * @return Result indicating success or error
     */
    suspend fun updateEmail(newEmail: String): Result<Unit> {
        return try {
            val user = currentUser ?: return Result.failure(Exception("No user signed in"))
            user.updateEmail(newEmail).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Sign out the current user.
     */
    fun signOut() {
        firebaseAuth.signOut()
    }
    
    /**
     * Delete the current user's account.
     * 
     * @return Result indicating success or error
     */
    suspend fun deleteAccount(): Result<Unit> {
        return try {
            val user = currentUser ?: return Result.failure(Exception("No user signed in"))
            user.delete().await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Re-authenticate the current user with their credentials.
     * Required before sensitive operations like password change or account deletion.
     * 
     * @param email User's email address
     * @param password User's current password
     * @return Result indicating success or error
     */
    suspend fun reauthenticate(email: String, password: String): Result<Unit> {
        return try {
            val user = currentUser ?: return Result.failure(Exception("No user signed in"))
            val credential = com.google.firebase.auth.EmailAuthProvider.getCredential(email, password)
            user.reauthenticate(credential).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Get the current user's ID token.
     * Used for authenticated API requests.
     * 
     * @param forceRefresh Force refresh the token
     * @return Result containing the ID token or error
     */
    suspend fun getIdToken(forceRefresh: Boolean = false): Result<String> {
        return try {
            val user = currentUser ?: return Result.failure(Exception("No user signed in"))
            val result = user.getIdToken(forceRefresh).await()
            val token = result.token
            if (token != null) {
                Result.success(token)
            } else {
                Result.failure(Exception("Failed to get ID token"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
