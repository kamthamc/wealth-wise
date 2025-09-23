//
//  AuthenticationView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - UI Components
//

import SwiftUI
import LocalAuthentication
import CryptoKit

/// Main authentication interface with modern iOS 18.6+ SwiftUI features
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct AuthenticationView: View {
    @State private var authenticationManager: AuthenticationStateManager
    @State private var biometricManager: BiometricAuthenticationManager
    @State private var securityService: SecurityValidationService
    
    @State private var showingSecuritySetup = false
    @State private var showingBiometricSetup = false
    @State private var showingSecuritySettings = false
    @State private var authenticationError: AuthenticationError?
    @State private var isAuthenticating = false
    @State private var securityValidationResult: ValidationResult?
    
    // Haptic feedback
    private let hapticManager = HapticFeedbackManager.shared
    
    // Animation states
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var rotationAngle: Double = 0
    
    private let keyManager: SecureKeyManagementProtocol
    private let encryptionService: EncryptionService
    
    init(
        keyManager: SecureKeyManagementProtocol,
        encryptionService: EncryptionService
    ) {
        self.keyManager = keyManager
        self.encryptionService = encryptionService
        
        self._authenticationManager = State(initialValue: AuthenticationStateManager(
            keyManager: keyManager,
            biometricManager: BiometricAuthenticationManager(keyManager: keyManager),
            encryptionService: encryptionService
        ))
        
        self._biometricManager = State(initialValue: BiometricAuthenticationManager(keyManager: keyManager))
        self._securityService = State(initialValue: SecurityValidationService())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground),
                        Color(UIColor.tertiarySystemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Glass morphism overlay
                GlassMorphismView()
                    .opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // App branding and security status
                    VStack(spacing: 16) {
                        // App icon with security indicator
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Circle()
                                        .stroke(securityIndicatorColor, lineWidth: 3)
                                        .scaleEffect(pulseScale)
                                        .opacity(glowOpacity)
                                }
                            
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 48, weight: .light, design: .rounded))
                                .foregroundStyle(.primary)
                                .rotationEffect(.degrees(rotationAngle))
                        }
                        .onAppear {
                            startSecurityAnimations()
                        }
                        
                        VStack(spacing: 8) {
                            Text("WealthWise")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text("Secure Financial Management")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Security level indicator
                        SecurityLevelIndicator(level: authenticationManager.securityLevel)
                    }
                    
                    Spacer()
                    
                    // Authentication content based on state
                    Group {
                        switch authenticationManager.authenticationState {
                        case .unauthenticated:
                            UnauthenticatedView(
                                onAuthenticate: handleAuthentication,
                                onShowSecuritySetup: { showingSecuritySetup = true },
                                isAuthenticating: isAuthenticating
                            )
                            
                        case .authenticating:
                            AuthenticatingView()
                            
                        case .authenticated:
                            AuthenticatedView(
                                user: authenticationManager.currentUser,
                                remainingTime: authenticationManager.remainingSessionTime,
                                onLogout: handleLogout,
                                onShowSettings: { showingSecuritySettings = true }
                            )
                            
                        case .sessionExpired:
                            SessionExpiredView(
                                onReauthenticate: handleAuthentication
                            )
                            
                        case .locked:
                            LockedView(
                                onUnlock: handleAuthentication
                            )
                            
                        case .compromised:
                            CompromisedView(
                                onSecurityCheck: performSecurityValidation
                            )
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    
                    Spacer()
                    
                    // Footer with security info
                    VStack(spacing: 8) {
                        if let lastAuth = authenticationManager.lastAuthenticationTime {
                            Text("Last authenticated: \(lastAuth.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text("End-to-end encrypted")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .animation(.smooth(duration: 0.6), value: authenticationManager.authenticationState)
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: .constant(authenticationError != nil)) {
                Button("OK") {
                    authenticationError = nil
                }
                if case .biometricFailure = authenticationError {
                    Button("Retry") {
                        Task { await handleAuthentication(.biometric(reason: "Authenticate to access WealthWise")) }
                    }
                }
            } message: {
                if let error = authenticationError {
                    Text(error.localizedDescription)
                }
            }
            .sheet(isPresented: $showingSecuritySetup) {
                SecuritySetupView(
                    biometricManager: biometricManager,
                    onComplete: { showingSecuritySetup = false }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingBiometricSetup) {
                NavigationView {
                    VStack {
                        Text("Biometric Setup")
                            .font(.title)
                        Text("Configure biometric authentication for enhanced security.")
                            .multilineTextAlignment(.center)
                        Button("Done") {
                            showingBiometricSetup = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .navigationTitle("Biometric Setup")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingSecuritySettings) {
                SecuritySettingsView(
                    authenticationManager: authenticationManager,
                    securityService: securityService,
                    onDismiss: { showingSecuritySettings = false }
                )
                .presentationDetents([.large])
            }
        }
        .task {
            await performInitialSecurityValidation()
        }
    }
    
    // MARK: - Computed Properties
    
    private var securityIndicatorColor: Color {
        switch authenticationManager.securityLevel {
        case .minimal:
            return .orange
        case .standard:
            return .blue
        case .high:
            return .green
        case .maximum:
            return .purple
        case .quantum:
            return .indigo
        }
    }
    
    // MARK: - Authentication Methods
    
    private func handleAuthentication(_ method: AuthenticationMethod) async {
        isAuthenticating = true
        hapticManager.impactMedium()
        
        do {
            let result = try await authenticationManager.authenticateUser(using: method)
            
            if result.success {
                hapticManager.authenticationSuccess()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    // Authentication successful - state will update automatically
                }
            } else {
                hapticManager.authenticationFailure()
                authenticationError = .authenticationFailed(result.errorMessage ?? "Authentication failed")
            }
        } catch {
            hapticManager.authenticationFailure()
            authenticationError = error as? AuthenticationError ?? .unknown(error.localizedDescription)
        }
        
        isAuthenticating = false
    }
    
    private func handleLogout() {
        hapticManager.impactMedium()
        
        withAnimation(.smooth(duration: 0.4)) {
            authenticationManager.invalidateSession()
        }
        
        hapticManager.notificationSuccess()
    }
    
    // MARK: - Security Validation
    
    private func performInitialSecurityValidation() async {
        do {
            securityValidationResult = try await securityService.performComprehensiveValidation()
            
            if let result = securityValidationResult, !result.isValid {
                // Handle security violations
                await handleSecurityViolations(result)
            }
        } catch {
            print("Security validation failed: \(error)")
        }
    }
    
    private func performSecurityValidation() async {
        do {
            securityValidationResult = try await securityService.performComprehensiveValidation()
        } catch {
            authenticationError = .securityValidationFailed(error.localizedDescription)
        }
    }
    
    private func handleSecurityViolations(_ result: ValidationResult) async {
        for violation in result.violations {
            switch violation {
            case .jailbreakDetected, .debuggingDetected, .codeInjectionDetected:
                // Critical security violations
                authenticationManager.updateAuthenticationState(.compromised)
                return
            default:
                // Less critical violations - log but continue
                print("Security warning: \(violation)")
            }
        }
    }
    
    // MARK: - Animations
    
    private func startSecurityAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
            glowOpacity = 0.6
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// MARK: - Unauthenticated View

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct UnauthenticatedView: View {
    let onAuthenticate: (AuthenticationMethod) async -> Void
    let onShowSecuritySetup: () -> Void
    let isAuthenticating: Bool
    
    @State private var availableBiometrics: Set<BiometricType> = []
    @State private var showingCredentialsEntry = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome Back")
                .font(.title.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text("Choose your preferred authentication method")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                // Biometric authentication buttons
                ForEach(Array(availableBiometrics), id: \.self) { biometricType in
                    BiometricAuthButton(
                        biometricType: biometricType,
                        isEnabled: !isAuthenticating,
                        onAuthenticate: { method in
                            Task { await onAuthenticate(method) }
                        }
                    )
                }
                
                // Passkey authentication
                if #available(iOS 18.6, *) {
                    PasskeyAuthButton(
                        isEnabled: !isAuthenticating,
                        onAuthenticate: { method in
                            Task { await onAuthenticate(method) }
                        }
                    )
                }
                
                // Apple Watch unlock
                if availableBiometrics.contains(.appleWatch) {
                    AppleWatchAuthButton(
                        isEnabled: !isAuthenticating,
                        onAuthenticate: { method in
                            Task { await onAuthenticate(method) }
                        }
                    )
                }
                
                // Fallback to credentials
                Button(action: { showingCredentialsEntry = true }) {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Use Password")
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isAuthenticating)
            }
            
            // Security setup button
            Button(action: onShowSecuritySetup) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Security Setup")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            availableBiometrics = DeviceCapabilities.availableBiometricTypes
        }
        .sheet(isPresented: $showingCredentialsEntry) {
            CredentialsEntryView { credentials in
                Task { await onAuthenticate(.credentials) }
                showingCredentialsEntry = false
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Biometric Authentication Button

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct BiometricAuthButton: View {
    let biometricType: BiometricType
    let isEnabled: Bool
    let onAuthenticate: (AuthenticationMethod) -> Void
    
    var body: some View {
        Button(action: {
            let method: AuthenticationMethod
            let reason = "Authenticate to access your financial data"
            
            switch biometricType {
            case .faceID, .touchID, .opticID:
                method = .biometric(reason: reason)
            case .voiceID:
                method = .voiceID(reason: reason, profile: nil)
            case .appleWatch:
                method = .appleWatch(reason: reason)
            default:
                method = .biometric(reason: reason)
            }
            
            onAuthenticate(method)
        }) {
            HStack(spacing: 16) {
                Image(systemName: biometricType.systemIconName)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(biometricType.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(biometricType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.tertiary, lineWidth: 0.5)
            }
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Passkey Authentication Button

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct PasskeyAuthButton: View {
    let isEnabled: Bool
    let onAuthenticate: (AuthenticationMethod) -> Void
    
    var body: some View {
        Button(action: {
            onAuthenticate(.passkey(reason: "Sign in with your passkey", relyingParty: "wealthwise.app"))
        }) {
            HStack(spacing: 16) {
                Image(systemName: "person.badge.key.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign in with Passkey")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text("Secure, passwordless authentication")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue.opacity(0.3), lineWidth: 1)
            }
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Apple Watch Authentication Button

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct AppleWatchAuthButton: View {
    let isEnabled: Bool
    let onAuthenticate: (AuthenticationMethod) -> Void
    
    var body: some View {
        Button(action: {
            onAuthenticate(.appleWatch(reason: "Unlock with your Apple Watch"))
        }) {
            HStack(spacing: 16) {
                Image(systemName: "applewatch")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock with Apple Watch")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text("When wearing your unlocked Apple Watch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            }
        }
        .disabled(!isEnabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Custom Button Style

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Supporting Views Stubs

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct AuthenticatingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.primary)
            
            Text("Authenticating...")
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct AuthenticatedView: View {
    let user: AuthenticatedUser?
    let remainingTime: TimeInterval
    let onLogout: () -> Void
    let onShowSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome, \(user?.id ?? "User")!")
                .font(.title.weight(.semibold))
                .foregroundStyle(.primary)
            
            SessionTimerView(remainingTime: remainingTime)
            
            Button("Security Settings", action: onShowSettings)
            Button("Logout", action: onLogout)
        }
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SessionExpiredView: View {
    let onReauthenticate: (AuthenticationMethod) async -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Session Expired")
                .font(.title.weight(.semibold))
            
            Text("Please re-authenticate to continue")
                .font(.body)
                .foregroundStyle(.secondary)
            
            Button("Re-authenticate") {
                Task { await onReauthenticate(.biometric(reason: "Re-authenticate to continue")) }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct LockedView: View {
    let onUnlock: (AuthenticationMethod) async -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text("Account Locked")
                .font(.title.weight(.semibold))
            
            Text("Your account has been locked for security reasons")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Unlock") {
                Task { await onUnlock(.biometric(reason: "Unlock your account")) }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct CompromisedView: View {
    let onSecurityCheck: () async -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text("Security Alert")
                .font(.title.weight(.semibold))
                .foregroundStyle(.red)
            
            Text("A security threat has been detected. Please run a security check.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Run Security Check") {
                Task { await onSecurityCheck() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}

// MARK: - Extension for BiometricType

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
extension BiometricType {
    var systemIconName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "eye.fill"
        case .voiceID:
            return "waveform.badge.mic"
        case .appleWatch:
            return "applewatch"
        case .none:
            return "person.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .voiceID:
            return "Voice ID"
        case .appleWatch:
            return "Apple Watch"
        case .none:
            return "None"
        }
    }
    
    var description: String {
        switch self {
        case .faceID:
            return "Authenticate with your face"
        case .touchID:
            return "Authenticate with your fingerprint"
        case .opticID:
            return "Authenticate with your eyes"
        case .voiceID:
            return "Authenticate with your voice"
        case .appleWatch:
            return "Unlock with your Apple Watch"
        case .none:
            return "No biometric authentication"
        }
    }
}