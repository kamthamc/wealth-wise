//
//  SecuritySetupView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Setup UI
//

import SwiftUI
import LocalAuthentication

/// Comprehensive security setup interface with iOS 18.6+ features
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecuritySetupView: View {
    let biometricManager: BiometricAuthenticationManager
    let onComplete: () -> Void
    
    @State private var currentStep: SetupStep = .welcome
    @State private var selectedSecurityLevel: SecurityLevel = .standard
    @State private var availableBiometrics: Set<BiometricType> = []
    @State private var selectedBiometrics: Set<BiometricType> = []
    @State private var enabledPostQuantum = false
    @State private var setupError: AuthenticationError?
    @State private var isProcessing = false
    
    // Haptic feedback
    private let hapticManager = HapticFeedbackManager.shared
    
    private enum SetupStep: CaseIterable {
        case welcome
        case securityLevel
        case biometricSetup
        case advancedOptions
        case completion
        
        var title: String {
            switch self {
            case .welcome:
                return "Welcome to WealthWise Security"
            case .securityLevel:
                return "Choose Security Level"
            case .biometricSetup:
                return "Enable Biometric Authentication"
            case .advancedOptions:
                return "Advanced Security Options"
            case .completion:
                return "Setup Complete"
            }
        }
        
        var subtitle: String {
            switch self {
            case .welcome:
                return "Let's set up your security preferences to protect your financial data"
            case .securityLevel:
                return "Select the level of security that best fits your needs"
            case .biometricSetup:
                return "Choose which biometric methods you'd like to use"
            case .advancedOptions:
                return "Configure additional security features"
            case .completion:
                return "Your security settings have been configured successfully"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(currentStep: currentStep, totalSteps: SetupStep.allCases.count)
                    .padding()
                
                // Content area
                TabView(selection: $currentStep) {
                    ForEach(SetupStep.allCases, id: \.self) { step in
                        stepView(for: step)
                            .tag(step)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.smooth(duration: 0.4), value: currentStep)
                
                // Navigation buttons
                VStack(spacing: 16) {
                    if currentStep != .completion {
                        Button(action: nextStep) {
                            HStack {
                                Text(currentStep == SetupStep.allCases.last ? "Complete Setup" : "Continue")
                                    .font(.body.weight(.semibold))
                                
                                if !isProcessing {
                                    Image(systemName: "arrow.right")
                                        .font(.body.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .overlay {
                                if isProcessing {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                        }
                        .disabled(isProcessing || !canProceed)
                        
                        if currentStep != .welcome {
                            Button("Previous", action: previousStep)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button("Get Started", action: onComplete)
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
                .padding()
            }
            .navigationTitle(currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip Setup") {
                        onComplete()
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            availableBiometrics = DeviceCapabilities.availableBiometricTypes
        }
        .alert("Setup Error", isPresented: .constant(setupError != nil)) {
            Button("OK") {
                setupError = nil
            }
        } message: {
            if let error = setupError {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Step Views
    
    @ViewBuilder
    private func stepView(for step: SetupStep) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Step icon and header
                VStack(spacing: 16) {
                    stepIcon(for: step)
                        .font(.system(size: 60))
                        .foregroundStyle(stepColor(for: step))
                    
                    VStack(spacing: 8) {
                        Text(step.title)
                            .font(.title.weight(.bold))
                            .multilineTextAlignment(.center)
                        
                        Text(step.subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 32)
                
                // Step content
                stepContent(for: step)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func stepContent(for step: SetupStep) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView()
            
        case .securityLevel:
            SecurityLevelSelectionView(
                selectedLevel: $selectedSecurityLevel,
                onSelectionChanged: { level in
                    hapticManager.impactMedium()
                }
            )
            
        case .biometricSetup:
            BiometricSetupStepView(
                availableBiometrics: availableBiometrics,
                selectedBiometrics: $selectedBiometrics,
                biometricManager: biometricManager,
                onTestBiometric: testBiometric
            )
            
        case .advancedOptions:
            AdvancedOptionsStepView(
                securityLevel: selectedSecurityLevel,
                enabledPostQuantum: $enabledPostQuantum
            )
            
        case .completion:
            CompletionStepView(
                securityLevel: selectedSecurityLevel,
                selectedBiometrics: selectedBiometrics,
                postQuantumEnabled: enabledPostQuantum
            )
        }
    }
    
    private func stepIcon(for step: SetupStep) -> Image {
        switch step {
        case .welcome:
            return Image(systemName: "hand.wave.fill")
        case .securityLevel:
            return Image(systemName: "slider.horizontal.3")
        case .biometricSetup:
            return Image(systemName: "touchid")
        case .advancedOptions:
            return Image(systemName: "gearshape.2.fill")
        case .completion:
            return Image(systemName: "checkmark.circle.fill")
        }
    }
    
    private func stepColor(for step: SetupStep) -> Color {
        switch step {
        case .welcome:
            return .blue
        case .securityLevel:
            return .orange
        case .biometricSetup:
            return .green
        case .advancedOptions:
            return .purple
        case .completion:
            return .green
        }
    }
    
    // MARK: - Navigation
    
    private var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .securityLevel:
            return true // Security level always has a default
        case .biometricSetup:
            return true // Can skip biometric setup
        case .advancedOptions:
            return true
        case .completion:
            return true
        }
    }
    
    private func nextStep() {
        guard let currentIndex = SetupStep.allCases.firstIndex(of: currentStep),
              currentIndex < SetupStep.allCases.count - 1 else {
            completeSetup()
            return
        }
        
        withAnimation(.smooth(duration: 0.4)) {
            currentStep = SetupStep.allCases[currentIndex + 1]
        }
        
        hapticManager.impactMedium()
    }
    
    private func previousStep() {
        guard let currentIndex = SetupStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }
        
        withAnimation(.smooth(duration: 0.4)) {
            currentStep = SetupStep.allCases[currentIndex - 1]
        }
        
        hapticManager.impactMedium()
    }
    
    private func completeSetup() {
        isProcessing = true
        
        Task {
            do {
                // Apply security settings
                try await applySecuritySettings()
                
                await MainActor.run {
                    isProcessing = false
                    hapticManager.notificationSuccess()
                    
                    withAnimation(.smooth(duration: 0.4)) {
                        currentStep = .completion
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    setupError = error as? AuthenticationError ?? .unknown(error.localizedDescription)
                    hapticManager.notificationError()
                }
            }
        }
    }
    
    private func testBiometric(_ biometricType: BiometricType) async {
        do {
            let reason = "Test \(biometricType.displayName) authentication"
            let result = try await biometricManager.authenticateWithBiometrics(reason: reason)
            
            if result.success {
                await MainActor.run {
                    selectedBiometrics.insert(biometricType)
                    hapticManager.authenticationSuccess()
                }
            }
        } catch {
            await MainActor.run {
                setupError = error as? AuthenticationError ?? .unknown(error.localizedDescription)
                hapticManager.authenticationFailure()
            }
        }
    }
    
    private func applySecuritySettings() async throws {
        // This would integrate with the actual security system
        // For now, we'll simulate the setup process
        
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Apply security level configuration
        // Configure biometric authentication
        // Enable post-quantum features if selected
        
        print("Security setup completed:")
        print("- Security Level: \(selectedSecurityLevel)")
        print("- Biometrics: \(selectedBiometrics)")
        print("- Post-Quantum: \(enabledPostQuantum)")
    }
}

// MARK: - Progress Bar

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct ProgressBar: View {
    let currentStep: SecuritySetupView.SetupStep
    let totalSteps: Int
    
    private var progress: CGFloat {
        guard let currentIndex = SecuritySetupView.SetupStep.allCases.firstIndex(of: currentStep) else {
            return 0
        }
        return CGFloat(currentIndex + 1) / CGFloat(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 4)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(.blue)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .clipShape(Capsule())
                        .animation(.smooth(duration: 0.4), value: progress)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("Step \(SecuritySetupView.SetupStep.allCases.firstIndex(of: currentStep)! + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Welcome Step

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                SecurityFeatureCard(
                    icon: "lock.shield.fill",
                    title: "Bank-Level Security",
                    description: "AES-256 encryption and biometric authentication protect your data"
                )
                
                SecurityFeatureCard(
                    icon: "eye.slash.fill",
                    title: "Privacy First",
                    description: "All data stays on your device - we never see your information"
                )
                
                SecurityFeatureCard(
                    icon: "cpu.fill",
                    title: "Hardware Security",
                    description: "Secure Enclave integration for maximum protection"
                )
                
                if DeviceCapabilities.supportsPostQuantumCrypto {
                    SecurityFeatureCard(
                        icon: "atom",
                        title: "Quantum-Resistant",
                        description: "Future-proof security with post-quantum cryptography"
                    )
                }
            }
            
            VStack(spacing: 12) {
                Text("This setup will take about 2-3 minutes")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                Text("You can change these settings anytime in Security Settings")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Security Feature Card

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Security Level Selection

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityLevelSelectionView: View {
    @Binding var selectedLevel: SecurityLevel
    let onSelectionChanged: (SecurityLevel) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach([SecurityLevel.standard, .high, .maximum, .quantum], id: \.self) { level in
                SecurityLevelCard(
                    level: level,
                    isSelected: selectedLevel == level,
                    onSelect: {
                        selectedLevel = level
                        onSelectionChanged(level)
                    }
                )
            }
            
            InfoCard(
                icon: "info.circle.fill",
                text: "Higher security levels provide better protection but may require more frequent authentication."
            )
        }
    }
}

// MARK: - Security Level Card

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityLevelCard: View {
    let level: SecurityLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var levelColor: Color {
        switch level {
        case .minimal: return .orange
        case .standard: return .blue
        case .high: return .green
        case .maximum: return .purple
        case .quantum: return .indigo
        }
    }
    
    private var levelDescription: String {
        switch level {
        case .minimal:
            return "Basic encryption and passcode protection"
        case .standard:
            return "Biometric authentication and secure key storage"
        case .high:
            return "Hardware security module and advanced biometrics"
        case .maximum:
            return "Multi-factor authentication and enhanced monitoring"
        case .quantum:
            return "Post-quantum cryptography and maximum protection"
        }
    }
    
    private var sessionTimeout: String {
        let config = SecurityConfiguration.SecurityLevelRequirements.self
        let timeout: TimeInterval
        
        switch level {
        case .minimal: timeout = config.minimal.sessionTimeout
        case .standard: timeout = config.standard.sessionTimeout
        case .high: timeout = config.high.sessionTimeout
        case .maximum: timeout = config.maximum.sessionTimeout
        case .quantum: timeout = config.quantum.sessionTimeout
        }
        
        let minutes = Int(timeout / 60)
        return "\(minutes) min session"
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(level.displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        Text(levelDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                HStack {
                    // Security bars
                    SecurityLevelIndicator(level: level)
                    
                    Spacer()
                    
                    Text(sessionTimeout)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.1), in: Capsule())
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Card

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct InfoCard: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecuritySetupView_Previews: PreviewProvider {
    static var previews: some View {
        SecuritySetupView(
            biometricManager: BiometricAuthenticationManager(
                keyManager: MockSecureKeyManager()
            ),
            onComplete: {}
        )
    }
}

// Mock for preview
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
class MockSecureKeyManager: SecureKeyManagementProtocol {
    func generateSecureKey(identifier: String, accessibility: SecAccessibility) -> SecureKey {
        return SecureKey(keyData: Data(), identifier: identifier, accessibility: accessibility)
    }
    
    func storeKey(_ key: SecureKey, identifier: String, accessibility: SecAccessibility) throws {}
    func retrieveKey(identifier: String) throws -> SecureKey? { return nil }
    func deleteKey(identifier: String) throws {}
    func keyExists(identifier: String) -> Bool { return false }
    func rotateKey(identifier: String) throws -> SecureKey? { return nil }
    func listKeys() throws -> [String] { return [] }
}