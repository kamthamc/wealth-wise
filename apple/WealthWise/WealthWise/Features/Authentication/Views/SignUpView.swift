//
//  SignUpView.swift
//  WealthWise
//
//  Sign up screen for new users
//

import SwiftUI

struct SignUpView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager()
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case displayName, email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Sign Up Form
                formSection
                
                // Password Strength Indicator
                passwordStrengthSection
                
                // Terms and Conditions
                termsSection
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    errorSection(errorMessage)
                }
                
                // Sign Up Button
                signUpButton
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
        .navigationTitle(NSLocalizedString("create_account", comment: "Create Account"))
        .navigationBarTitleDisplayMode(.inline)
        .disabled(authManager.isLoading)
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("join_wealthwise", comment: "Join WealthWise"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(NSLocalizedString("signup_subtitle", comment: "Start managing your finances today"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 12)
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Display Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("display_name", comment: "Display Name"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("", text: $displayName)
                    .textContentType(.name)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($focusedField, equals: .displayName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .email
                    }
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("email", comment: "Email"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("password", comment: "Password"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Group {
                        if showPassword {
                            TextField("", text: $password)
                        } else {
                            SecureField("", text: $password)
                        }
                    }
                    .textContentType(.newPassword)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .confirmPassword
                    }
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("confirm_password", comment: "Confirm Password"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("", text: $confirmPassword)
                        } else {
                            SecureField("", text: $confirmPassword)
                        }
                    }
                    .textContentType(.newPassword)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.go)
                    .onSubmit {
                        handleSignUp()
                    }
                    
                    Button {
                        showConfirmPassword.toggle()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    private var passwordStrengthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let validation = authManager.isValidPassword(password)
            
            if !password.isEmpty && !validation.isValid {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    
                    Text(validation.message ?? "")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    
                    Text(NSLocalizedString("passwords_dont_match", comment: "Passwords don't match"))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var termsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                agreedToTerms.toggle()
            } label: {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundStyle(agreedToTerms ? .blue : .secondary)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("agree_to_terms", comment: "I agree to the"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                + Text(" ")
                + Text(NSLocalizedString("terms_and_conditions", comment: "Terms & Conditions"))
                    .font(.caption)
                    .foregroundStyle(.blue)
                + Text(" ")
                + Text(NSLocalizedString("and", comment: "and"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                + Text(" ")
                + Text(NSLocalizedString("privacy_policy", comment: "Privacy Policy"))
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
            
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var signUpButton: some View {
        Button {
            handleSignUp()
        } label: {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(NSLocalizedString("create_account", comment: "Create Account"))
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || authManager.isLoading)
    }
    
    // MARK: - Actions
    
    private func handleSignUp() {
        focusedField = nil
        
        Task {
            await authManager.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            
            if authManager.isAuthenticated {
                dismiss()
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        authManager.isValidEmail(email) &&
        authManager.isValidPassword(password).isValid &&
        password == confirmPassword &&
        agreedToTerms
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
