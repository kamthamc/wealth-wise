//
//  SecuritySettingsView.swift
//  WealthWise
//
//  Created by WealthWise Team on 2025-01-21.
//  Security & Authentication Foundation System - Settings UI
//

import SwiftUI
import LocalAuthentication

/// Comprehensive security settings interface with iOS 18.6+ features
@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecuritySettingsView: View {
    let authenticationManager: AuthenticationStateManager
    let securityService: SecurityValidationService
    let onDismiss: () -> Void
    
    @State private var currentSecurityLevel: SecurityLevel = .standard
    @State private var enabledBiometrics: Set<BiometricType> = []
    @State private var sessionTimeout: TimeInterval = 900 // 15 minutes
    @State private var autoLockEnabled = true
    @State private var threatDetectionEnabled = true
    @State private var securityLoggingEnabled = true
    @State private var postQuantumEnabled = false
    
    @State private var showingBiometricSetup = false
    @State private var showingSecurityReport = false
    @State private var showingAdvancedSettings = false
    @State private var isRunningSecurityCheck = false
    @State private var lastSecurityCheck: Date?
    @State private var securityReportResult: ValidationResult?
    
    // Haptic feedback
    private let hapticManager = HapticFeedbackManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // Current Security Status Section
                Section {
                    SecurityStatusCard(
                        securityLevel: currentSecurityLevel,
                        lastCheck: lastSecurityCheck,
                        isHealthy: securityReportResult?.isValid ?? true,
                        onRunSecurityCheck: runSecurityCheck
                    )
                } header: {
                    Text("Security Status")
                }
                
                // Authentication Section
                Section {
                    // Security Level
                    NavigationLink(destination: SecurityLevelSettingsView(currentLevel: $currentSecurityLevel)) {
                        SettingsRow(
                            icon: "slider.horizontal.3",
                            title: "Security Level",
                            value: currentSecurityLevel.displayName,
                            color: currentSecurityLevel.color
                        )
                    }
                    
                    // Biometric Authentication
                    NavigationLink(destination: BiometricSettingsView(enabledBiometrics: $enabledBiometrics)) {
                        SettingsRow(
                            icon: "touchid",
                            title: "Biometric Authentication",
                            value: biometricStatusText,
                            color: .blue
                        )
                    }
                    
                    // Session Settings
                    NavigationLink(destination: SessionSettingsView(timeout: $sessionTimeout, autoLock: $autoLockEnabled)) {
                        SettingsRow(
                            icon: "timer",
                            title: "Session Settings",
                            value: sessionTimeoutText,
                            color: .orange
                        )
                    }
                } header: {
                    Text("Authentication")
                }
                
                // Security Features Section
                Section {
                    // Threat Detection
                    Toggle(isOn: $threatDetectionEnabled) {
                        SettingsRow(
                            icon: "shield.lefthalf.filled.badge.checkmark",
                            title: "Threat Detection",
                            subtitle: "Monitor for security violations and jailbreaks",
                            color: .red
                        )
                    }
                    .onChange(of: threatDetectionEnabled) { _, newValue in
                        hapticManager.impactMedium()
                        updateThreatDetection(newValue)
                    }
                    
                    // Security Logging
                    Toggle(isOn: $securityLoggingEnabled) {
                        SettingsRow(
                            icon: "doc.text.magnifyingglass",
                            title: "Security Logging",
                            subtitle: "Log security events for audit trail",
                            color: .green
                        )
                    }
                    .onChange(of: securityLoggingEnabled) { _, _ in
                        hapticManager.impactMedium()
                    }
                    
                    // Post-Quantum Cryptography
                    if DeviceCapabilities.supportsPostQuantumCrypto {
                        Toggle(isOn: $postQuantumEnabled) {
                            SettingsRow(
                                icon: "atom",
                                title: "Post-Quantum Cryptography",
                                subtitle: "Quantum-resistant encryption algorithms",
                                color: .purple
                            )
                        }
                        .onChange(of: postQuantumEnabled) { _, _ in
                            hapticManager.impactMedium()
                        }
                    }
                } header: {
                    Text("Security Features")
                }
                
                // Security Tools Section
                Section {
                    // Security Report
                    Button(action: { showingSecurityReport = true }) {
                        SettingsRow(
                            icon: "doc.text.below.ecg",
                            title: "Security Report",
                            subtitle: lastSecurityCheck != nil ? "Last check: \(lastSecurityCheck!.formatted(.relative(presentation: .named)))" : "Never run",
                            color: .blue
                        )
                    }
                    .foregroundStyle(.primary)
                    
                    // Export Security Logs
                    Button(action: exportSecurityLogs) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Security Logs",
                            subtitle: "Export encrypted audit logs",
                            color: .indigo
                        )
                    }
                    .foregroundStyle(.primary)
                    
                    // Reset Security Settings
                    Button(action: showResetConfirmation) {
                        SettingsRow(
                            icon: "arrow.clockwise",
                            title: "Reset Security Settings",
                            subtitle: "Reset to default security configuration",
                            color: .orange
                        )
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Security Tools")
                }
                
                // Advanced Section
                Section {
                    NavigationLink(destination: AdvancedSecuritySettingsView()) {
                        SettingsRow(
                            icon: "gearshape.2.fill",
                            title: "Advanced Settings",
                            subtitle: "Hardware security, encryption options",
                            color: .gray
                        )
                    }
                    
                    NavigationLink(destination: SecurityAuditLogView()) {
                        SettingsRow(
                            icon: "list.bullet.clipboard",
                            title: "Security Audit Log",
                            subtitle: "View security events and violations",
                            color: .gray
                        )
                    }
                } header: {
                    Text("Advanced")
                }
                
                // Device Security Info Section
                Section {
                    DeviceSecurityInfoView()
                } header: {
                    Text("Device Security Information")
                }
            }
            .navigationTitle("Security Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .sheet(isPresented: $showingSecurityReport) {
            SecurityReportView(
                result: securityReportResult,
                onRunCheck: runSecurityCheck,
                onDismiss: { showingSecurityReport = false }
            )
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Computed Properties
    
    private var biometricStatusText: String {
        if enabledBiometrics.isEmpty {
            return "Disabled"
        } else if enabledBiometrics.count == 1 {
            return enabledBiometrics.first?.displayName ?? "Enabled"
        } else {
            return "\(enabledBiometrics.count) methods"
        }
    }
    
    private var sessionTimeoutText: String {
        let minutes = Int(sessionTimeout / 60)
        return "\(minutes) minutes"
    }
    
    // MARK: - Settings Actions
    
    private func loadCurrentSettings() {
        currentSecurityLevel = authenticationManager.securityLevel
        enabledBiometrics = DeviceCapabilities.availableBiometricTypes
        // Load other settings from configuration
    }
    
    private func runSecurityCheck() {
        isRunningSecurityCheck = true
        
        Task {
            do {
                let result = try await securityService.performComprehensiveValidation()
                
                await MainActor.run {
                    securityReportResult = result
                    lastSecurityCheck = Date()
                    isRunningSecurityCheck = false
                    
                    if result.isValid {
                        hapticManager.notificationSuccess()
                    } else {
                        hapticManager.notificationWarning()
                    }
                }
            } catch {
                await MainActor.run {
                    isRunningSecurityCheck = false
                    hapticManager.notificationError()
                }
            }
        }
    }
    
    private func updateThreatDetection(_ enabled: Bool) {
        // Update threat detection configuration
        Task {
            // Implementation would update the security service configuration
        }
    }
    
    private func exportSecurityLogs() {
        // Export security logs functionality
        hapticManager.impactMedium()
        
        // Implementation would create encrypted export of audit logs
    }
    
    private func showResetConfirmation() {
        // Show confirmation dialog for resetting security settings
        hapticManager.impactMedium()
    }
}

// MARK: - Security Status Card

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityStatusCard: View {
    let securityLevel: SecurityLevel
    let lastCheck: Date?
    let isHealthy: Bool
    let onRunSecurityCheck: () -> Void
    
    @State private var isRunningCheck = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: isHealthy ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(isHealthy ? .green : .orange)
                        
                        Text(isHealthy ? "Security Status: Healthy" : "Security Needs Attention")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    
                    Text("Current Level: \(securityLevel.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let lastCheck = lastCheck {
                        Text("Last checked: \(lastCheck.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("Security check never run")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                Button(action: onRunSecurityCheck) {
                    HStack {
                        if isRunningCheck {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check")
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue, in: Capsule())
                }
                .disabled(isRunningCheck)
            }
            
            // Security level indicator
            SecurityLevelIndicator(level: securityLevel)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Settings Row

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String?
    let color: Color
    
    init(icon: String, title: String, subtitle: String? = nil, value: String? = nil, color: Color) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Device Security Info

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct DeviceSecurityInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InfoRow(title: "Device Model", value: DeviceInfo.shared.model)
            InfoRow(title: "System Version", value: DeviceInfo.shared.systemVersion)
            InfoRow(title: "Secure Enclave", value: DeviceCapabilities.hasSecureEnclave ? "Available" : "Not Available")
            InfoRow(title: "Neural Engine", value: DeviceCapabilities.hasNeuralEngine ? "Available" : "Not Available")
            InfoRow(title: "Post-Quantum Support", value: DeviceCapabilities.supportsPostQuantumCrypto ? "Supported" : "Not Supported")
            
            let biometrics = DeviceCapabilities.availableBiometricTypes
            InfoRow(title: "Available Biometrics", value: biometrics.isEmpty ? "None" : biometrics.map(\.displayName).joined(separator: ", "))
        }
        .font(.callout)
    }
}

// MARK: - Info Row

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Placeholder Views for Navigation

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityLevelSettingsView: View {
    @Binding var currentLevel: SecurityLevel
    
    var body: some View {
        List {
            ForEach([SecurityLevel.standard, .high, .maximum, .quantum], id: \.self) { level in
                Button(action: { currentLevel = level }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(level.displayName)
                                .foregroundStyle(.primary)
                            Text("Security configuration for \(level.displayName.lowercased()) level")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if currentLevel == level {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Security Level")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct BiometricSettingsView: View {
    @Binding var enabledBiometrics: Set<BiometricType>
    
    var body: some View {
        Text("Biometric Settings")
            .navigationTitle("Biometric Authentication")
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SessionSettingsView: View {
    @Binding var timeout: TimeInterval
    @Binding var autoLock: Bool
    
    var body: some View {
        Text("Session Settings")
            .navigationTitle("Session Settings")
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct AdvancedSecuritySettingsView: View {
    var body: some View {
        Text("Advanced Security Settings")
            .navigationTitle("Advanced Settings")
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityAuditLogView: View {
    var body: some View {
        Text("Security Audit Log")
            .navigationTitle("Audit Log")
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityReportView: View {
    let result: ValidationResult?
    let onRunCheck: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let result = result {
                        SecurityReportContent(result: result)
                    } else {
                        Text("No security report available")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Security Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done", action: onDismiss)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh", action: onRunCheck)
                }
            }
        }
    }
}

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecurityReportContent: View {
    let result: ValidationResult
    
    var body: some View {
        VStack(spacing: 16) {
            // Overall status
            HStack {
                Image(systemName: result.isValid ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(result.isValid ? .green : .orange)
                
                VStack(alignment: .leading) {
                    Text(result.isValid ? "Security Status: Healthy" : "Security Issues Detected")
                        .font(.headline)
                    Text("Risk Score: \(Int(result.riskScore * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Violations
            if !result.violations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Security Violations")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    ForEach(Array(result.violations.enumerated()), id: \.offset) { index, violation in
                        Text("• \(String(describing: violation))")
                            .font(.callout)
                            .foregroundStyle(.primary)
                    }
                }
                .padding()
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Warnings
            if !result.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Warnings")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    
                    ForEach(Array(result.warnings.enumerated()), id: \.offset) { index, warning in
                        Text("• \(warning)")
                            .font(.callout)
                            .foregroundStyle(.primary)
                    }
                }
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            Text("Report generated: \(result.validatedAt.formatted())")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

@available(iOS 18.6, macOS 15.6, watchOS 11.6, *)
struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SecuritySettingsView(
            authenticationManager: AuthenticationStateManager(
                keyManager: MockSecureKeyManager(),
                biometricManager: BiometricAuthenticationManager(keyManager: MockSecureKeyManager()),
                encryptionService: EncryptionService(keyManager: MockSecureKeyManager())
            ),
            securityService: SecurityValidationService(),
            onDismiss: {}
        )
    }
}