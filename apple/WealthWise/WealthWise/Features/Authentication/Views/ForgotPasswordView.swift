//
//  ForgotPasswordView.swift
//  WealthWise
//
//  Password reset screen
//

import SwiftUI

struct ForgotPasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager()
    
    @State private var email = ""
    @State private var showSuccess = false
    
    @FocusState private var emailFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if showSuccess {
                    successSection
                } else {
                    formSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .navigationTitle(NSLocalizedString("reset_password", comment: "Reset Password"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
            }
            .disabled(authManager.isLoading)
        }
    }
    
    // MARK: - View Components
    
    private var formSection: some View {
        VStack(spacing: 24) {
            // Icon and Description
            VStack(spacing: 12) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                
                Text(NSLocalizedString("reset_password_instructions", comment: "Enter your email address and we'll send you instructions to reset your password."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 8)
            
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
                    .focused($emailFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        handleResetPassword()
                    }
            }
            
            // Error Message
            if let errorMessage = authManager.errorMessage {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Send Button
            Button {
                handleResetPassword()
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text(NSLocalizedString("send_reset_link", comment: "Send Reset Link"))
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
            
            Spacer()
        }
    }
    
    private var successSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                
                Text(NSLocalizedString("reset_email_sent", comment: "Reset Email Sent"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(NSLocalizedString("reset_email_sent_message", comment: "Check your email for instructions to reset your password."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text(NSLocalizedString("done", comment: "Done"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleResetPassword() {
        emailFocused = false
        
        Task {
            await authManager.resetPassword(email: email)
            
            if authManager.errorMessage == nil {
                showSuccess = true
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !email.isEmpty && authManager.isValidEmail(email)
    }
}

#Preview {
    ForgotPasswordView()
}
