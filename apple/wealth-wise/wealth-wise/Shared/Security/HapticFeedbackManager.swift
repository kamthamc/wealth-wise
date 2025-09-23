//
//  HapticFeedbackManager.swift
//  WealthWise
//
//  Cross-platform haptic feedback utility for Security & Authentication Foundation System
//  Created: Part of Issue #4 - Authentication & Security Layer implementation
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Cross-platform haptic feedback manager
/// Provides consistent haptic feedback across iOS, macOS, and other Apple platforms
@MainActor
public final class HapticFeedbackManager: @unchecked Sendable {
    
    // MARK: - Singleton
    public static let shared = HapticFeedbackManager()
    
    #if os(iOS)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    #endif
    
    private init() {
        #if os(iOS)
        // Prepare generators for better performance
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
        selection.prepare()
        #endif
    }
    
    // MARK: - Impact Feedback
    
    /// Trigger light impact haptic feedback
    public func impactLight() {
        #if os(iOS)
        impactLight.impactOccurred()
        impactLight.prepare()
        #elseif os(macOS)
        // macOS doesn't have haptic feedback, could add sound or visual feedback
        NSSound.beep()
        #endif
    }
    
    /// Trigger medium impact haptic feedback
    public func impactMedium() {
        #if os(iOS)
        impactMedium.impactOccurred()
        impactMedium.prepare()
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }
    
    /// Trigger heavy impact haptic feedback
    public func impactHeavy() {
        #if os(iOS)
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }
    
    /// Trigger impact haptic feedback with specified intensity
    public func impact(_ intensity: HapticIntensity) {
        switch intensity {
        case .light:
            impactLight()
        case .medium:
            impactMedium()
        case .heavy:
            impactHeavy()
        }
    }
    
    // MARK: - Notification Feedback
    
    /// Trigger success notification haptic feedback
    public func notificationSuccess() {
        #if os(iOS)
        notification.notificationOccurred(.success)
        notification.prepare()
        #elseif os(macOS)
        // Could play a success sound
        if let soundURL = Bundle.main.url(forResource: "success", withExtension: "aiff") {
            NSSound(contentsOf: soundURL, byReference: false)?.play()
        } else {
            NSSound.beep()
        }
        #endif
    }
    
    /// Trigger warning notification haptic feedback
    public func notificationWarning() {
        #if os(iOS)
        notification.notificationOccurred(.warning)
        notification.prepare()
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }
    
    /// Trigger error notification haptic feedback
    public func notificationError() {
        #if os(iOS)
        notification.notificationOccurred(.error)
        notification.prepare()
        #elseif os(macOS)
        // Could play an error sound
        if let soundURL = Bundle.main.url(forResource: "error", withExtension: "aiff") {
            NSSound(contentsOf: soundURL, byReference: false)?.play()
        } else {
            NSSound.beep()
        }
        #endif
    }
    
    /// Trigger notification haptic feedback with specified type
    public func notification(_ type: HapticNotificationType) {
        switch type {
        case .success:
            notificationSuccess()
        case .warning:
            notificationWarning()
        case .error:
            notificationError()
        }
    }
    
    // MARK: - Selection Feedback
    
    /// Trigger selection haptic feedback
    public func selection() {
        #if os(iOS)
        selection.selectionChanged()
        selection.prepare()
        #elseif os(macOS)
        // Subtle feedback for macOS
        NSSound(named: NSSound.Name("Pop"))?.play()
        #endif
    }
    
    // MARK: - Security-Specific Feedback
    
    /// Trigger haptic feedback for successful authentication
    public func authenticationSuccess() {
        #if os(iOS)
        // Double tap for authentication success
        DispatchQueue.main.async {
            self.impactMedium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactMedium()
            }
        }
        #else
        notificationSuccess()
        #endif
    }
    
    /// Trigger haptic feedback for failed authentication
    public func authenticationFailure() {
        #if os(iOS)
        // Triple tap for authentication failure
        DispatchQueue.main.async {
            self.impactHeavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactHeavy()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.impactHeavy()
                }
            }
        }
        #else
        notificationError()
        #endif
    }
    
    /// Trigger haptic feedback for security threat detection
    public func securityThreat() {
        #if os(iOS)
        // Continuous pattern for security alerts
        DispatchQueue.main.async {
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    self.impactHeavy()
                }
            }
        }
        #else
        notificationError()
        #endif
    }
    
    /// Trigger haptic feedback for biometric prompt
    public func biometricPrompt() {
        #if os(iOS)
        impactLight()
        #else
        selection()
        #endif
    }
}

// MARK: - Supporting Types

/// Haptic feedback intensity levels
public enum HapticIntensity: CaseIterable, Sendable {
    case light
    case medium
    case heavy
    
    /// Display name for the intensity
    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }
}

/// Haptic notification feedback types
public enum HapticNotificationType: CaseIterable, Sendable {
    case success
    case warning
    case error
    
    /// Display name for the notification type
    public var displayName: String {
        switch self {
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

// MARK: - SwiftUI Integration

#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI View extension for easy haptic feedback
@available(iOS 16.0, macOS 13.0, *)
extension View {
    /// Add haptic feedback to button tap
    public func hapticFeedback(_ intensity: HapticIntensity = .medium) -> some View {
        self.onTapGesture {
            HapticFeedbackManager.shared.impact(intensity)
        }
    }
    
    /// Add haptic feedback with custom action
    public func hapticFeedback<T>(_ intensity: HapticIntensity = .medium, value: T) -> some View where T: Equatable {
        self.onChange(of: value) { _, _ in
            HapticFeedbackManager.shared.impact(intensity)
        }
    }
}
#endif