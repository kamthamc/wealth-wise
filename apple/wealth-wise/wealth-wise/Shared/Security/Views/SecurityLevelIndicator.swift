//
//  SecurityLevelIndicator.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - UI Components
//

import SwiftUI

/// Security level visual indicator with modern iOS 18.6+ design
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityLevelIndicator: View {
    let level: SecurityLevel
    
    @State private var animationProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private var levelColor: Color {
        switch level {
        case .minimal:
            return .orange
        case .standard:
            return .blue
        case .high:
            return .green
        case .maximum:
            return .purple
        case .quantum:
            return .indigo.gradient.stops.last?.color ?? .indigo
        }
    }
    
    private var levelText: String {
        switch level {
        case .minimal:
            return "Basic Security"
        case .standard:
            return "Standard Security"
        case .high:
            return "High Security"
        case .maximum:
            return "Maximum Security"
        case .quantum:
            return "Quantum Security"
        }
    }
    
    private var levelDescription: String {
        switch level {
        case .minimal:
            return "Basic encryption and authentication"
        case .standard:
            return "Biometric authentication and secure storage"
        case .high:
            return "Advanced biometrics and hardware security"
        case .maximum:
            return "Multi-factor auth and enhanced protection"
        case .quantum:
            return "Post-quantum cryptography and maximum protection"
        }
    }
    
    private var securityBars: Int {
        switch level {
        case .minimal: return 1
        case .standard: return 2
        case .high: return 3
        case .maximum: return 4
        case .quantum: return 5
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Security level bars
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { bar in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(bar <= securityBars ? levelColor : Color.secondary.opacity(0.3))
                        .frame(width: 24, height: 6)
                        .scaleEffect(y: bar <= securityBars ? pulseScale : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .delay(Double(bar) * 0.1)
                            .repeatCount(3, autoreverses: true),
                            value: animationProgress
                        )
                }
            }
            
            // Security level text
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: securityIconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(levelColor)
                    
                    Text(levelText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                
                Text(levelDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(levelColor.opacity(0.3), lineWidth: 1)
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: level) { _, _ in
            startAnimation()
        }
    }
    
    private var securityIconName: String {
        switch level {
        case .minimal:
            return "shield"
        case .standard:
            return "shield.checkered"
        case .high:
            return "shield.lefthalf.filled"
        case .maximum:
            return "shield.fill"
        case .quantum:
            return "shield.righthalf.filled.badge.checkmark"
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.0)) {
            animationProgress = 1.0
        }
        
        withAnimation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true)) {
            pulseScale = 1.2
        }
    }
}

// MARK: - Session Timer View

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SessionTimerView: View {
    let remainingTime: TimeInterval
    
    @State private var progress: CGFloat = 1.0
    
    private var timeColor: Color {
        switch remainingTime {
        case 0...300: // Last 5 minutes
            return .red
        case 301...600: // Last 10 minutes
            return .orange
        default:
            return .green
        }
    }
    
    private var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Text(formattedTime)
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundStyle(timeColor)
            }
            
            Text("Session expires in")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            updateProgress()
        }
        .onChange(of: remainingTime) { _, _ in
            updateProgress()
        }
    }
    
    private func updateProgress() {
        let totalSessionTime: TimeInterval = SecurityConfiguration.sessionTimeout
        progress = CGFloat(remainingTime / totalSessionTime)
    }
}

// MARK: - Credentials Entry View

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct CredentialsEntryView: View {
    let onAuthenticate: (AuthenticationCredentials) -> Void
    
    @State private var username = ""
    @State private var password = ""
    @State private var twoFactorCode = ""
    @State private var showPassword = false
    @State private var isAuthenticating = false
    
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case username, password, twoFactor
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    
                    Text("Sign In")
                        .font(.title.weight(.semibold))
                    
                    Text("Enter your credentials to continue")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Credentials form
                VStack(spacing: 16) {
                    // Username field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("Enter your username", text: $username)
                            .textFieldStyle(ModernTextFieldStyle())
                            .textContentType(.username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .username)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }
                            }
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                focusedField = .twoFactor
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.tertiary, lineWidth: 1)
                        }
                    }
                    
                    // Two-factor code field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Two-Factor Code (Optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("6-digit code", text: $twoFactorCode)
                            .textFieldStyle(ModernTextFieldStyle())
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .twoFactor)
                            .onChange(of: twoFactorCode) { _, newValue in
                                // Limit to 6 digits
                                twoFactorCode = String(newValue.prefix(6))
                            }
                    }
                }
                
                Spacer()
                
                // Sign in button
                Button(action: handleSignIn) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .disabled(username.isEmpty || password.isEmpty || isAuthenticating)
                
                // Additional options
                VStack(spacing: 12) {
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(.callout)
                    .foregroundStyle(.blue)
                    
                    Button("Use Biometric Authentication Instead") {
                        // Dismiss and use biometric
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Dismiss
                    }
                }
            }
        }
        .onAppear {
            focusedField = .username
        }
    }
    
    private func handleSignIn() {
        isAuthenticating = true
        
        let credentials = AuthenticationCredentials(
            username: username,
            password: password,
            twoFactorCode: twoFactorCode.isEmpty ? nil : twoFactorCode
        )
        
        onAuthenticate(credentials)
        
        isAuthenticating = false
    }
}

// MARK: - Modern Text Field Style

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.tertiary, lineWidth: 1)
            }
    }
}

// MARK: - Glass Morphism View

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct GlassMorphismView: View {
    var body: some View {
        ZStack {
            // Multiple gradient layers for depth
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.pink.opacity(0.08),
                    Color.orange.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Noise texture simulation
            Canvas { context, size in
                for _ in 0..<100 {
                    let x = Double.random(in: 0...size.width)
                    let y = Double.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.01...0.05)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
        .blur(radius: 0.5, opaque: false)
    }
}

// MARK: - Preview

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityLevelIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SecurityLevelIndicator(level: .minimal)
            SecurityLevelIndicator(level: .standard)
            SecurityLevelIndicator(level: .high)
            SecurityLevelIndicator(level: .maximum)
            SecurityLevelIndicator(level: .quantum)
        }
        .padding()
        .background(.regularMaterial)
    }
}