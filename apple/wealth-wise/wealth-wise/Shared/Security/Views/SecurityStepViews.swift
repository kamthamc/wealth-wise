//
//  SecurityStepViews.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Setup Steps
//

import SwiftUI
import LocalAuthentication

// MARK: - Biometric Setup Step

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct BiometricSetupStepView: View {
    let availableBiometrics: Set<BiometricType>
    @Binding var selectedBiometrics: Set<BiometricType>
    let biometricManager: BiometricAuthenticationManager
    let onTestBiometric: (BiometricType) async -> Void
    
    @State private var testingBiometric: BiometricType?
    
    var body: some View {
        VStack(spacing: 20) {
            if availableBiometrics.isEmpty {
                // No biometrics available
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    
                    Text("No Biometric Authentication Available")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Your device doesn't support biometric authentication. You can still use a secure passcode to protect your data.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                // Available biometrics
                Text("Select the biometric methods you'd like to enable:")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach(Array(availableBiometrics), id: \.self) { biometricType in
                        BiometricOptionCard(
                            biometricType: biometricType,
                            isSelected: selectedBiometrics.contains(biometricType),
                            isTesting: testingBiometric == biometricType,
                            onToggle: {
                                if selectedBiometrics.contains(biometricType) {
                                    selectedBiometrics.remove(biometricType)
                                } else {
                                    Task {
                                        testingBiometric = biometricType
                                        await onTestBiometric(biometricType)
                                        testingBiometric = nil
                                    }
                                }
                            }
                        )
                    }
                }
                
                if !selectedBiometrics.isEmpty {
                    InfoCard(
                        icon: "checkmark.shield.fill",
                        text: "Great! Your selected biometric methods have been tested and are ready to use."
                    )
                }
                
                // Skip option
                VStack(spacing: 8) {
                    Text("You can enable biometric authentication later in Settings")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Skipping will use device passcode for authentication")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Biometric Option Card

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct BiometricOptionCard: View {
    let biometricType: BiometricType
    let isSelected: Bool
    let isTesting: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Biometric icon
                ZStack {
                    Circle()
                        .fill(biometricType.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: biometricType.systemIconName)
                        .font(.title2)
                        .foregroundStyle(biometricType.color)
                }
                
                // Biometric info
                VStack(alignment: .leading, spacing: 4) {
                    Text(biometricType.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(biometricType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Status indicator
                Group {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? biometricType.color : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isTesting)
    }
}

// MARK: - Advanced Options Step

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct AdvancedOptionsStepView: View {
    let securityLevel: SecurityLevel
    @Binding var enabledPostQuantum: Bool
    
    @State private var enableHardwareKeys = true
    @State private var enableSecurityLogging = true
    @State private var enableThreatDetection = true
    @State private var enableAutoLock = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Configure advanced security features based on your \(securityLevel.displayName) security level:")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                // Post-quantum cryptography
                if DeviceCapabilities.supportsPostQuantumCrypto {
                    AdvancedOptionCard(
                        icon: "atom",
                        title: "Post-Quantum Cryptography",
                        description: "Enable quantum-resistant encryption algorithms for future-proof security",
                        isEnabled: $enabledPostQuantum,
                        recommendedForLevel: securityLevel.rawValue >= SecurityLevel.high.rawValue,
                        isAvailable: true
                    )
                }
                
                // Hardware security keys
                AdvancedOptionCard(
                    icon: "key.horizontal.fill",
                    title: "Hardware Security Module",
                    description: "Use Secure Enclave for all cryptographic operations",
                    isEnabled: $enableHardwareKeys,
                    recommendedForLevel: securityLevel.rawValue >= SecurityLevel.standard.rawValue,
                    isAvailable: DeviceCapabilities.hasSecureEnclave
                )
                
                // Security logging
                AdvancedOptionCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Security Event Logging",
                    description: "Log security events for audit and threat detection",
                    isEnabled: $enableSecurityLogging,
                    recommendedForLevel: securityLevel.rawValue >= SecurityLevel.high.rawValue,
                    isAvailable: true
                )
                
                // Threat detection
                AdvancedOptionCard(
                    icon: "shield.lefthalf.filled.badge.checkmark",
                    title: "Advanced Threat Detection",
                    description: "Monitor for jailbreaks, debugging, and security violations",
                    isEnabled: $enableThreatDetection,
                    recommendedForLevel: securityLevel.rawValue >= SecurityLevel.high.rawValue,
                    isAvailable: true
                )
                
                // Auto-lock
                AdvancedOptionCard(
                    icon: "lock.rotation",
                    title: "Automatic Session Lock",
                    description: "Automatically lock the app when in background",
                    isEnabled: $enableAutoLock,
                    recommendedForLevel: true,
                    isAvailable: true
                )
            }
            
            InfoCard(
                icon: "lightbulb.fill",
                text: "These settings can be changed later in Security Settings. Recommended options for your security level are pre-selected."
            )
        }
    }
}

// MARK: - Advanced Option Card

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct AdvancedOptionCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let recommendedForLevel: Bool
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Option icon
            ZStack {
                Circle()
                    .fill(isAvailable ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isAvailable ? .blue : .secondary)
            }
            
            // Option info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isAvailable ? .primary : .secondary)
                    
                    if recommendedForLevel {
                        Text("RECOMMENDED")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green, in: Capsule())
                    }
                    
                    Spacer()
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                if !isAvailable {
                    Text("Not available on this device")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            
            // Toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .disabled(!isAvailable)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(isAvailable ? 1.0 : 0.6)
        .onAppear {
            if recommendedForLevel && isAvailable {
                isEnabled = true
            }
        }
    }
}

// MARK: - Completion Step

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct CompletionStepView: View {
    let securityLevel: SecurityLevel
    let selectedBiometrics: Set<BiometricType>
    let postQuantumEnabled: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Success animation placeholder
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.green)
                }
                
                Text("Security Setup Complete!")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Your financial data is now protected with bank-level security")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Configuration summary
            VStack(spacing: 16) {
                Text("Your Security Configuration:")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 12) {
                    ConfigurationRow(
                        icon: "slider.horizontal.3",
                        title: "Security Level",
                        value: securityLevel.displayName,
                        color: securityLevel.color
                    )
                    
                    ConfigurationRow(
                        icon: selectedBiometrics.isEmpty ? "key.fill" : selectedBiometrics.first?.systemIconName ?? "touchid",
                        title: "Authentication",
                        value: selectedBiometrics.isEmpty ? "Device Passcode" : selectedBiometrics.map(\.displayName).joined(separator: ", "),
                        color: .blue
                    )
                    
                    if postQuantumEnabled {
                        ConfigurationRow(
                            icon: "atom",
                            title: "Post-Quantum",
                            value: "Enabled",
                            color: .purple
                        )
                    }
                    
                    ConfigurationRow(
                        icon: "shield.lefthalf.filled",
                        title: "Hardware Security",
                        value: DeviceCapabilities.hasSecureEnclave ? "Secure Enclave" : "Software",
                        color: .green
                    )
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Next steps
            VStack(spacing: 12) {
                Text("What's Next?")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    NextStepRow(
                        icon: "plus.circle.fill",
                        text: "Start adding your financial accounts"
                    )
                    
                    NextStepRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Set up budgets and financial goals"
                    )
                    
                    NextStepRow(
                        icon: "gearshape.fill",
                        text: "Customize security settings anytime"
                    )
                }
            }
        }
    }
}

// MARK: - Configuration Row

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct ConfigurationRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Next Step Row

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct NextStepRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Extensions

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
extension BiometricType {
    var color: Color {
        switch self {
        case .faceID:
            return .blue
        case .touchID:
            return .red
        case .opticID:
            return .purple
        case .voiceID:
            return .orange
        case .appleWatch:
            return .orange
        case .none:
            return .secondary
        }
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
extension SecurityLevel {
    var color: Color {
        switch self {
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
    
    var displayName: String {
        switch self {
        case .minimal:
            return "Minimal"
        case .standard:
            return "Standard"
        case .high:
            return "High"
        case .maximum:
            return "Maximum"
        case .quantum:
            return "Quantum"
        }
    }
}