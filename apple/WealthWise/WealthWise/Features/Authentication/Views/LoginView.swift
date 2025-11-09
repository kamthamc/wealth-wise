//
//  LoginView.swift
//  WealthWise
//
//  Login screen with email/password authentication
//

import SwiftUI

struct LoginView: View {
    
    @StateObject private var authManager = AuthenticationManager()
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    headerSection
                    
                    // Login Form
                    formSection
                    
                    // Error Message
                    if let errorMessage = authManager.errorMessage {
                        errorSection(errorMessage)
                    }
                    
                    // Login Button
                    loginButton
                    
                    // Forgot Password
                    forgotPasswordButton
                    
                    Spacer(minLength: 40)
                    
                    // Sign Up Link
                    signUpLink
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .navigationBarHidden(true)
            .disabled(authManager.isLoading)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.blue.gradient)
            
            Text("WealthWise")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(NSLocalizedString("login_subtitle", comment: "Manage your finances wisely"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
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
                    .textContentType(.password)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        handleLogin()
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
    
    private var loginButton: some View {
        Button {
            handleLogin()
        } label: {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(NSLocalizedString("login", comment: "Login"))
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
    
    private var forgotPasswordButton: some View {
        Button {
            showForgotPassword = true
        } label: {
            Text(NSLocalizedString("forgot_password", comment: "Forgot Password?"))
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
    }
    
    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text(NSLocalizedString("no_account", comment: "Don't have an account?"))
                .foregroundStyle(.secondary)
            
            NavigationLink {
                SignUpView()
            } label: {
                Text(NSLocalizedString("sign_up", comment: "Sign Up"))
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
        .font(.subheadline)
    }
    
    // MARK: - Actions
    
    private func handleLogin() {
        focusedField = nil
        
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        authManager.isValidEmail(email)
    }
}

#Preview {
    LoginView()
}
