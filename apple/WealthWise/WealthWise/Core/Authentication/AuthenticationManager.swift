//
//  AuthenticationManager.swift
//  WealthWise
//
//  Manages authentication state and operations
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

/// Manages user authentication state and operations
/// Integrates with FirebaseService for authentication
@MainActor
final class AuthenticationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let firebaseService: FirebaseService
    
    // MARK: - User Model
    
    struct User: Identifiable {
        let id: String
        let email: String
        let displayName: String?
        
        init(id: String, email: String, displayName: String? = nil) {
            self.id = id
            self.email = email
            self.displayName = displayName
        }
    }
    
    // MARK: - Initialization
    
    init(firebaseService: FirebaseService = .shared) {
        self.firebaseService = firebaseService
        self.isAuthenticated = firebaseService.isAuthenticated
        
        if let fbUser = firebaseService.currentUser {
            self.currentUser = User(
                id: fbUser.uid,
                email: fbUser.email ?? "",
                displayName: fbUser.displayName
            )
        }
    }
    
    // MARK: - Authentication Operations
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await firebaseService.signIn(email: email, password: password)
            currentUser = User(
                id: user.uid,
                email: user.email ?? "",
                displayName: user.displayName
            )
            isAuthenticated = true
            
        } catch {
            errorMessage = errorMessageFor(error)
        }
        
        isLoading = false
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await firebaseService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            currentUser = User(
                id: user.uid,
                email: user.email ?? "",
                displayName: user.displayName
            )
            isAuthenticated = true
            
        } catch {
            errorMessage = errorMessageFor(error)
        }
        
        isLoading = false
    }
    
    /// Sign out current user
    func signOut() {
        do {
            try firebaseService.signOut()
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = errorMessageFor(error)
        }
    }
    
    /// Reset password
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.resetPassword(email: email)
        } catch {
            errorMessage = errorMessageFor(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Validation
    
    /// Validate email format
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate password strength
    func isValidPassword(_ password: String) -> (isValid: Bool, message: String?) {
        if password.count < 8 {
            return (false, NSLocalizedString("password_too_short", comment: "Password must be at least 8 characters"))
        }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        if !hasUppercase || !hasLowercase || !hasNumber {
            return (false, NSLocalizedString("password_weak", comment: "Password must contain uppercase, lowercase, and number"))
        }
        
        return (true, nil)
    }
    
    // MARK: - Error Handling
    
    private func errorMessageFor(_ error: Error) -> String {
        // Convert Firebase error to user-friendly message
        let errorCode = (error as NSError).code
        
        switch errorCode {
        case 17007: // ERROR_EMAIL_ALREADY_IN_USE
            return NSLocalizedString("error_email_in_use", comment: "Email already in use")
        case 17008: // ERROR_INVALID_EMAIL
            return NSLocalizedString("error_invalid_email", comment: "Invalid email address")
        case 17009: // ERROR_WEAK_PASSWORD
            return NSLocalizedString("error_weak_password", comment: "Password is too weak")
        case 17010: // ERROR_USER_DISABLED
            return NSLocalizedString("error_user_disabled", comment: "Account has been disabled")
        case 17011: // ERROR_USER_NOT_FOUND
            return NSLocalizedString("error_user_not_found", comment: "User not found")
        case 17012: // ERROR_WRONG_PASSWORD
            return NSLocalizedString("error_wrong_password", comment: "Incorrect password")
        case 17020: // ERROR_NETWORK_ERROR
            return NSLocalizedString("error_network", comment: "Network error occurred")
        default:
            return error.localizedDescription
        }
    }
}
